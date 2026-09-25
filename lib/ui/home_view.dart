import 'dart:async';
import 'dart:convert';

import 'package:background_fetch/background_fetch.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_mode.dart';
import '../services/app_mode_service.dart';
import '../services/consent_tracking_service.dart';
import '../services/geo_location_service.dart';
import '../services/initial_survey_service.dart';
import '../services/ios_location_fix_service.dart';
import '../services/location_service.dart';
import '../services/location_persistence_service.dart';
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

  bool get _isItalian => Localizations.localeOf(context).languageCode == 'it';
  bool get _isSpanish => Localizations.localeOf(context).languageCode == 'es';

  /// Bilingual helper with optional Spanish; Spanish falls back to English
  /// where no [es] string has been provided yet.
  String _t(String en, String it, [String? es]) {
    if (_isItalian) return it;
    if (_isSpanish && es != null) return es;
    return en;
  }

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
      // Fixes recorded while the app was in the background (or terminated)
      // were never shown live; store them and redraw once they are stored.
      _storeBufferedFixesAndRefreshMap();
    }
  }

  /// Moves fixes from the plugin's native buffer into the database (see
  /// LocationPersistenceService) and redraws the map if any were new.
  Future<void> _storeBufferedFixesAndRefreshMap() async {
    final stored = await LocationPersistenceService.instance.drainNow();
    if (stored > 0 && mounted) _refreshMapAfterSurvey();
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

      // Persist fixes from the plugin's native buffer from now on, including
      // any recorded while the app was not running.
      LocationPersistenceService.instance.start();
      _storeBufferedFixesAndRefreshMap();

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
          // While the app process is alive, ALL background_fetch events land
          // here (the headless task in main.dart only runs when terminated),
          // so the survey-notification task must be dispatched explicitly or
          // reminders never fire for users who keep the app running.
          debugPrint('[BackgroundFetch] received event $taskId');
          try {
            if (taskId == 'com.wellbeingmapper.survey_notification') {
              await NotificationService.checkNotificationTiming();
            }
          } catch (e) {
            debugPrint('[BackgroundFetch] task $taskId error: $e');
          } finally {
            BackgroundFetch.finish(taskId);
          }
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
          // Only the native authorization check proves permission; being
          // registered in the iOS Settings list also happens when the user
          // chose "Never".
          final hasNative =
              await IosLocationFixService.checkNativeLocationPermission();

          if (hasNative) {
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

  // Live fixes only update the UI here. Persisting them is the job of
  // LocationPersistenceService, which stores every fix from the plugin's
  // native buffer -- including fixes recorded while this screen, or the whole
  // app, was not running.
  void _onLocation(AppLocation location) {
    if (mounted) setState(() {});
  }

  void _onEnabledChange(bool enabled) {
    if (mounted) setState(() => _enabled = enabled);
  }

  // -------------------------------------------------------------------------
  // Dialogs
  // -------------------------------------------------------------------------

  void _showInitialSurveyOffering() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_t('Complete Initial Survey', 'Completa il questionario iniziale')),
        content: Text(
          _t('Would you like to complete the initial demographic survey now? '
                  'This helps us understand our participants better, but you can do it later.',
              'Vuoi completare ora il questionario demografico iniziale? '
                  'Ci aiuta a conoscere meglio i partecipanti, ma puoi farlo anche più tardi.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t("No, I'll do it later", 'No, lo farò più tardi')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await SurveyNavigationService.navigateToInitialSurvey(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text(_t('Yes, complete now', 'Sì, completa ora'),
                style: const TextStyle(color: Colors.white)),
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
        title: Text(_t('Initial Survey', 'Questionario iniziale')),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t('Later', 'Più tardi')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await SurveyNavigationService.navigateToInitialSurvey(context);
            },
            child: Text(_t('Complete Now', 'Completa ora')),
          ),
        ],
      ),
    );
  }

  void _showPermissionError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t('Permission Required', 'Autorizzazione necessaria')),
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
        title: Text(_t('Background Location Required',
            'Posizione in background necessaria')),
        content: Text(
          _t('To track your location continuously, this app needs "Always" location '
                  'permission. Go to Settings > Privacy & Security > Location Services > '
                  'Wellbeing Mapper and select "Always".',
              'Per tracciare la tua posizione in modo continuo, questa app ha bisogno '
                  'dell\'autorizzazione alla posizione "Sempre". Vai su Impostazioni > '
                  'Privacy e sicurezza > Localizzazione > Wellbeing Mapper e seleziona "Sempre".'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t('Cancel', 'Annulla')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              openAppSettings();
            },
            child: Text(_t('Open Settings', 'Apri Impostazioni')),
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
            tooltip: _t('Update current position', 'Aggiorna posizione attuale'),
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
          String route = '/wellbeing_survey';
          try {
            final mode = await AppModeService.getCurrentMode();
            // appTesting mode mirrors the research experience (data stays
            // local), so it gets the research survey too.
            route = mode.hasResearchFeatures ? '/recurring_survey' : '/wellbeing_survey';
            await Navigator.of(context).pushNamed(route);
            _refreshMapAfterSurvey();
          } catch (e) {
            debugPrint('[HomeView] Survey navigation error: $e');
            await Navigator.of(context).pushNamed(route);
            _refreshMapAfterSurvey();
          }
        },
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: SouthAfricanTheme.pureWhite,
        icon: const Icon(Icons.add),
        label: Text(_t('Survey', 'Questionario')),
      ),
    );
  }
}
