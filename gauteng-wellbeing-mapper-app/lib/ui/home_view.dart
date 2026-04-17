import 'dart:async';
import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../db/survey_database.dart';
import '../models/app_mode.dart';
import '../services/app_mode_service.dart';
import '../services/consent_tracking_service.dart';
import '../services/geo_location_service.dart';
import '../services/initial_survey_service.dart';
import '../services/ios_location_fix_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/storage_settings_service.dart';
import '../services/survey_navigation_service.dart';
import '../theme/south_african_theme.dart';
import '../util/env.dart';
import '../util/onboarding_helper.dart';
import 'map_view.dart';
import 'side_drawer.dart';

/// Main home screen of the app.
class HomeView extends StatefulWidget {
  const HomeView(this.appName, {Key? key}) : super(key: key);

  final String appName;

  @override
  State<HomeView> createState() => HomeViewState();
}

class HomeViewState extends State<HomeView>
    with TickerProviderStateMixin<HomeView>, WidgetsBindingObserver {
  // -------------------------------------------------------------------------
  // State
  // -------------------------------------------------------------------------

  final GlobalKey<MapViewState> _mapViewKey = GlobalKey<MapViewState>();
  bool _enabled = true;
  DateTime? _lastStationarySave;

  // All timers stored so they can be cancelled in dispose().
  Timer? _surveyPromptTimer;
  Timer? _initialSurveyTimer;
  Timer? _onboardingTimer;

  // -------------------------------------------------------------------------
  // Lifecycle
  // -------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register listeners early so no location events are missed.
    GeoLocationService.instance.addLocationListener(_onLocation);
    GeoLocationService.instance.addEnabledChangeListener(_onEnabledChange);

    initPlatformState();
    _checkForPendingSurveyPrompt();
    _checkForIncompleteInitialSurvey();
    _checkAndShowOnboarding();
  }

  @override
  void dispose() {
    _surveyPromptTimer?.cancel();
    _initialSurveyTimer?.cancel();
    _onboardingTimer?.cancel();

    GeoLocationService.instance.removeLocationListener(_onLocation);
    GeoLocationService.instance.removeEnabledChangeListener(_onEnabledChange);

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshMapAfterSurvey();
    }
  }

  // -------------------------------------------------------------------------
  // Initialisation
  // -------------------------------------------------------------------------

  void initPlatformState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? sampleId = prefs.getString('sample_id');
      String? userUUID = prefs.getString('user_uuid');

      if (sampleId == null || userUUID == null) {
        userUUID = const Uuid().v4();
        sampleId = ENV.DEFAULT_SAMPLE_ID;
        await prefs.setString('user_uuid', userUUID);
        await prefs.setString('sample_id', sampleId);
      }

      // Configure the location plugin once.
      if (!GeoLocationService.instance.isConfigured) {
        if (kIsWeb) {
          debugPrint('[HomeView] Web platform – skipping location configuration.');
        } else {
          try {
            final initialEnabled = await GeoLocationService.instance.configure(
              userId: userUUID,
              sampleId: sampleId,
            );
            if (mounted) setState(() => _enabled = initialEnabled);

            // Request permissions.
            try {
              final granted = await LocationService.initializeLocationServices(
                  context: context);
              if (!granted && mounted) {
                if (Theme.of(context).platform == TargetPlatform.iOS) {
                  try {
                    await IosLocationFixService.initializeNativeLocationManager();
                  } catch (_) {}
                }
              }
            } catch (permError) {
              debugPrint('[HomeView] Permission init error: $permError');
            }
          } catch (geoError) {
            debugPrint('[HomeView] Location config error: $geoError');
          }
        }
      }

      // Configure background services if participation settings are present.
      final participationSettings = prefs.getString('participation_settings');
      if (participationSettings != null && participationSettings.isNotEmpty) {
        try {
          final data = jsonDecode(participationSettings) as Map<String, dynamic>;
          final isResearch = data['isResearchParticipant'] == true;
          _configureBackgroundServicesAsync(userUUID, sampleId, isResearch);
        } catch (e) {
          debugPrint('[HomeView] Error parsing participation settings: $e');
          _configureBackgroundServicesAsync(userUUID, sampleId, false);
        }
      }

      // Periodic auto-cleanup.
      StorageSettingsService.performAutoCleanupIfNeeded().catchError((e) {
        debugPrint('[HomeView] Auto-cleanup error: $e');
      });
    } catch (e) {
      debugPrint('[HomeView] initPlatformState error: $e');
    }
  }

  void _configureBackgroundServicesAsync(
      String? userId, String? sampleId, bool isResearchParticipant) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Future.delayed(const Duration(milliseconds: 100));
      _configureBackgroundFetch();
    });
  }

  void _configureBackgroundFetch() async {
    try {
      BackgroundFetch.configure(
        BackgroundFetchConfig(
          minimumFetchInterval: 15,
          startOnBoot: true,
          stopOnTerminate: false,
          enableHeadless: true,
          requiresStorageNotLow: false,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiredNetworkType: NetworkType.NONE,
        ),
        (String taskId) async {
          debugPrint('[BackgroundFetch] received event $taskId');
          final prefs = await SharedPreferences.getInstance();
          int count = (prefs.getInt('fetch-count') ?? 0) + 1;
          await prefs.setInt('fetch-count', count);

          BackgroundFetch.scheduleTask(TaskConfig(
            taskId: 'com.transistorsoft.wellbeingmapper',
            delay: 5000,
            periodic: false,
            forceAlarmManager: true,
            stopOnTerminate: false,
            enableHeadless: true,
          ));
          BackgroundFetch.finish(taskId);
        },
      );
    } catch (e) {
      debugPrint('[HomeView] _configureBackgroundFetch error: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Tracking toggle
  // -------------------------------------------------------------------------

  void _onClickEnable(bool enabled) async {
    if (kIsWeb) {
      if (mounted) setState(() => _enabled = enabled);
      return;
    }

    if (!GeoLocationService.instance.isConfigured) {
      if (mounted) setState(() => _enabled = false);
      _showPermissionError(
          'Location tracking is not initialised. Please restart the app.');
      return;
    }

    if (enabled) {
      if (mounted) setState(() => _enabled = true);
      try {
        // iOS: try native permission check first.
        if (mounted && Theme.of(context).platform == TargetPlatform.iOS) {
          final hasNative =
              await IosLocationFixService.checkNativeLocationPermission();
          final isRegistered =
              await IosLocationFixService.isAppRegisteredInSettings();

          if (hasNative || isRegistered) {
            final started = await GeoLocationService.instance.start();
            if (mounted) setState(() => _enabled = started);
            if (!started) {
              _showPermissionError(
                  'Failed to start location tracking. Check your location settings.');
            }
            return;
          }

          // Try comprehensive iOS fix.
          final fixed = await IosLocationFixService.performComprehensiveFix(
              context: context);
          if (fixed) {
            final started = await GeoLocationService.instance.start();
            if (mounted) setState(() => _enabled = started);
            if (started) return;
          }
        }

        // Standard permission flow.
        final locationAlways = await Permission.locationAlways.status;
        final locationWhenInUse = await Permission.locationWhenInUse.status;

        bool hasPermission = locationAlways == PermissionStatus.granted ||
            locationWhenInUse == PermissionStatus.granted;

        if (!hasPermission) {
          final result = await Permission.locationWhenInUse.request();
          if (result != PermissionStatus.granted) {
            if (mounted) setState(() => _enabled = false);
            _showPermissionError(
                'Location permission is required. Please grant it in Settings.');
            return;
          }
          await Future.delayed(const Duration(milliseconds: 1000));
          hasPermission = true;
        }

        if (locationAlways != PermissionStatus.granted) {
          final result = await Permission.locationAlways.request();
          if (result != PermissionStatus.granted) {
            _showAlwaysPermissionDialog();
            return;
          }
          await Future.delayed(const Duration(milliseconds: 1000));
        }

        if (mounted && Theme.of(context).platform == TargetPlatform.android) {
          try {
            await Permission.activityRecognition.request();
          } catch (_) {}
        }

        final started = await GeoLocationService.instance.start();
        if (mounted) setState(() => _enabled = started);
        if (!started) {
          _showPermissionError(
              'Failed to start location tracking. Please check your settings.');
        }
      } catch (e) {
        debugPrint('[HomeView] _onClickEnable error: $e');
        if (mounted) setState(() => _enabled = false);
        _showPermissionError('Error setting up location tracking: $e');
      }
    } else {
      // Stop tracking.
      try {
        final newState = await GeoLocationService.instance.stop();
        if (mounted) setState(() => _enabled = newState);
      } catch (e) {
        debugPrint('[HomeView] Error stopping tracking: $e');
        if (mounted) setState(() => _enabled = false);
      }
    }
  }

  void _onClickGetCurrentPosition() async {
    if (kIsWeb) return;
    final location = await GeoLocationService.instance.getCurrentPosition(
      persist: true,
      desiredAccuracy: 40,
      maximumAge: 10000,
      timeout: 30,
      samples: 3,
    );
    debugPrint('[getCurrentPosition] - $location');
  }

  // -------------------------------------------------------------------------
  // Survey prompts
  // -------------------------------------------------------------------------

  void _checkAndShowOnboarding() {
    _onboardingTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final should = await OnboardingHelper.shouldShowOnboarding();
      if (should && mounted) OnboardingHelper.showQuickTour(context);
    });
  }

  void _checkForPendingSurveyPrompt() {
    _surveyPromptTimer = Timer(const Duration(milliseconds: 500), () async {
      if (!mounted) return;
      final hasPending = await NotificationService.hasPendingSurveyPrompt();
      if (hasPending && mounted) {
        await NotificationService.showSurveyPromptDialog(context);
      }
    });
  }

  void _checkForIncompleteInitialSurvey() {
    _initialSurveyTimer = Timer(const Duration(seconds: 2), () async {
      if (!mounted) return;
      final needs = await InitialSurveyService.needsInitialSurvey();
      if (!needs || !mounted) return;

      final isFirstTime = await ConsentTrackingService.hasJustCompletedConsent();
      if (isFirstTime) {
        await ConsentTrackingService.clearJustCompletedFlag();
        _showInitialSurveyOffering();
      } else {
        final reminder = await InitialSurveyService.shouldShowReminder();
        if (reminder != null) _showInitialSurveyReminder(reminder);
      }
    });
  }

  // -------------------------------------------------------------------------
  // Location event handlers
  // -------------------------------------------------------------------------

  void _onLocation(AppLocation location) {
    _processLocationWithMotionFilter(location);
    if (mounted) setState(() {});
  }

  void _onEnabledChange(bool enabled) {
    if (mounted) setState(() => _enabled = enabled);
  }

  Future<void> _saveLocationToDatabase(AppLocation location,
      {bool isFiltered = false, String reason = ''}) async {
    try {
      final timestamp = DateTime.parse(location.timestamp);
      final data = {
        'timestamp': timestamp.toIso8601String(),
        'latitude': location.coords.latitude,
        'longitude': location.coords.longitude,
        'accuracy': location.coords.accuracy,
        'altitude': location.coords.altitude,
        'speed': location.coords.speed,
        'activity': location.activity.type,
      };
      await SurveyDatabase().insertLocationTrack(data);
    } catch (e) {
      debugPrint('[HomeView] Error saving location to database: $e');
    }
  }

  Future<void> _processLocationWithMotionFilter(AppLocation location) async {
    try {
      if (location.coords.accuracy >
          StorageSettingsService.MAX_MAP_ERROR_THRESHOLD_METERS) {
        return;
      }

      if (!location.isMoving) {
        if (await _shouldSaveStationaryLocation(intervalMinutes: 2)) {
          await _saveLocationToDatabase(location,
              isFiltered: true, reason: 'stationary-periodic');
        }
      } else {
        await _saveLocationToDatabase(location,
            isFiltered: true, reason: 'moving-continuity-priority');
      }
    } catch (e) {
      debugPrint('[HomeView] Location filter error: $e');
      await _saveLocationToDatabase(location,
          isFiltered: false, reason: 'filter-error-fallback');
    }
  }

  Future<bool> _shouldSaveStationaryLocation({int intervalMinutes = 5}) async {
    final now = DateTime.now();
    if (_lastStationarySave == null ||
        now.difference(_lastStationarySave!).inMinutes >= intervalMinutes) {
      _lastStationarySave = now;
      return true;
    }
    return false;
  }

  // -------------------------------------------------------------------------
  // Dialogs
  // -------------------------------------------------------------------------

  void _showInitialSurveyOffering() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Complete Initial Survey'),
        content: const Text(
          'Would you like to complete the initial demographic survey now? '
          'This helps us understand our participants better, but you can do it later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("No, I'll do it later"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await SurveyNavigationService.navigateToInitialSurvey(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Yes, complete now',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showInitialSurveyReminder(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Initial Survey'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await SurveyNavigationService.navigateToInitialSurvey(context);
            },
            child: const Text('Complete Now'),
          ),
        ],
      ),
    );
  }

  void _showPermissionError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showAlwaysPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Background Location Required'),
        content: const Text(
          'To track your location continuously, this app needs "Always" location '
          'permission. Go to Settings > Privacy & Security > Location Services > '
          'Wellbeing Mapper and select "Always".',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Map refresh
  // -------------------------------------------------------------------------

  void _refreshMapAfterSurvey() {
    try {
      _mapViewKey.currentState?.refreshMapData();
    } catch (e) {
      debugPrint('[HomeView] Map refresh error: $e');
    }
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.appName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        centerTitle: true,
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: SouthAfricanTheme.pureWhite,
        systemOverlayStyle:
            const SystemUiOverlayStyle(statusBarBrightness: Brightness.light),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            color: SouthAfricanTheme.pureWhite,
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.gps_fixed),
            color: SouthAfricanTheme.accentYellow,
            onPressed: _onClickGetCurrentPosition,
            tooltip: 'Update current position',
          ),
          Switch(
            value: _enabled,
            onChanged: _onClickEnable,
            activeColor: SouthAfricanTheme.accentYellow,
            activeTrackColor:
                SouthAfricanTheme.accentYellow.withValues(alpha: 0.5),
            inactiveThumbColor: Colors.grey[300],
            inactiveTrackColor: Colors.grey[400],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Center(
              child: Text(
                _enabled ? 'ON' : 'OFF',
                style: const TextStyle(
                  color: SouthAfricanTheme.pureWhite,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      drawer: WellbeingMapperSideDrawer(),
      body: MapView(key: _mapViewKey),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          try {
            final mode = await AppModeService.getCurrentMode();
            if (mode == AppMode.research) {
              await Navigator.of(context).pushNamed('/recurring_survey');
            } else {
              await Navigator.of(context).pushNamed('/wellbeing_survey');
            }
            _refreshMapAfterSurvey();
          } catch (e) {
            debugPrint('[HomeView] Survey navigation error: $e');
            await Navigator.of(context).pushNamed('/wellbeing_survey');
            _refreshMapAfterSurvey();
          }
        },
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: SouthAfricanTheme.pureWhite,
        icon: const Icon(Icons.add),
        label: const Text('Survey'),
      ),
    );
  }
}
