import 'package:flutter/foundation.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart'
    as bg;

/// Coordinates included in a location fix.
class AppLocationCoords {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;

  const AppLocationCoords({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.altitude = 0.0,
    this.speed = 0.0,
  });
}

/// Activity data associated with a location fix.
class AppActivityData {
  final String type;
  final int confidence;

  const AppActivityData({required this.type, required this.confidence});
}

/// A single location sample from the underlying location plugin.
/// This type decouples the rest of the app from `flutter_background_geolocation`
/// so that the underlying library can be swapped without touching UI code.
class AppLocation {
  final AppLocationCoords coords;
  final bool isMoving;
  final String timestamp;
  final AppActivityData activity;

  const AppLocation({
    required this.coords,
    required this.isMoving,
    required this.timestamp,
    required this.activity,
  });

  @override
  String toString() =>
      'AppLocation(lat=${coords.latitude}, lng=${coords.longitude}, '
      'accuracy=${coords.accuracy}, isMoving=$isMoving, ts=$timestamp)';
}

/// Singleton facade over `flutter_background_geolocation`.
///
/// All location-related operations in the app go through this service.
/// When the project replaces `flutter_background_geolocation` with its own
/// library, only this file needs to change — the rest of the app is
/// unaffected.
class GeoLocationService {
  // ---------- singleton ----------------------------------------------------
  static final GeoLocationService _instance = GeoLocationService._();
  GeoLocationService._();
  static GeoLocationService get instance => _instance;

  // ---------- state --------------------------------------------------------
  bool _isConfigured = false;
  bool _isEnabled = false;

  bool get isConfigured => _isConfigured;
  bool get isEnabled => _isEnabled;

  // ---------- listener lists -----------------------------------------------
  final List<void Function(AppLocation)> _locationListeners = [];
  final List<void Function(bool)> _enabledListeners = [];

  // ---------- public API ---------------------------------------------------

  /// Configure the underlying plugin. Idempotent – safe to call more than once.
  ///
  /// Returns the initial tracking-enabled state (persisted from previous run).
  Future<bool> configure({
    required String userId,
    required String sampleId,
  }) async {
    if (_isConfigured) return _isEnabled;

    // Register a single set of FBG listeners. All UI code uses addXxxListener
    // so that there are no duplicate bg listener registrations.
    bg.BackgroundGeolocation.onLocation(_handleLocation, _handleLocationError);
    bg.BackgroundGeolocation.onMotionChange(_handleMotionChange);
    bg.BackgroundGeolocation.onActivityChange(_handleActivityChange);
    bg.BackgroundGeolocation.onProviderChange(_handleProviderChange);
    bg.BackgroundGeolocation.onEnabledChange(_handleEnabledChange);

    // Initialise the plugin with production-appropriate defaults.
    final state = await bg.BackgroundGeolocation.ready(bg.Config(
      reset: false,
      debug: kDebugMode,
      logLevel: kDebugMode
          ? bg.Config.LOG_LEVEL_VERBOSE
          : bg.Config.LOG_LEVEL_OFF,
      desiredAccuracy: bg.Config.DESIRED_ACCURACY_HIGH,
      stopTimeout: 5,
      minimumActivityRecognitionConfidence: 75,
      activityType: bg.Config.ACTIVITY_TYPE_FITNESS,
      autoSync: false,
      persistMode: bg.Config.PERSIST_MODE_ALL,
      maxDaysToPersist: 1,
      maxRecordsToPersist: -1,
      stopOnTerminate: false,
      startOnBoot: true,
      enableHeadless: true,
      preventSuspend: true,
      pausesLocationUpdatesAutomatically: false,
      disableElasticity: true,
      enableTimestampMeta: true,
      disableLocationAuthorizationAlert: false,
    ));

    _isEnabled = state.enabled;
    _isConfigured = true;

    if (state.schedule != null && state.schedule!.isNotEmpty) {
      bg.BackgroundGeolocation.startSchedule();
    }

    debugPrint('[GeoLocationService] Configured. enabled=$_isEnabled');
    return _isEnabled;
  }

  /// Start location tracking. Returns `true` if tracking is now active.
  Future<bool> start() async {
    if (!_isConfigured) {
      debugPrint('[GeoLocationService] start() called before configure()');
      return false;
    }
    try {
      final state = await bg.BackgroundGeolocation.state;
      if (state.trackingMode == 1) {
        await bg.BackgroundGeolocation.start();
      } else {
        await bg.BackgroundGeolocation.startGeofences();
      }
      final finalState = await bg.BackgroundGeolocation.state;
      _isEnabled = finalState.enabled;
      return _isEnabled;
    } catch (e) {
      debugPrint('[GeoLocationService] Error starting tracking: $e');
      return false;
    }
  }

  /// Stop location tracking. Returns `false` (tracking is now inactive).
  Future<bool> stop() async {
    try {
      await bg.BackgroundGeolocation.stop();
      final finalState = await bg.BackgroundGeolocation.state;
      _isEnabled = finalState.enabled;
      return _isEnabled;
    } catch (e) {
      debugPrint('[GeoLocationService] Error stopping tracking: $e');
      _isEnabled = false;
      return false;
    }
  }

  /// Fetch a single current position, or `null` on error.
  Future<AppLocation?> getCurrentPosition({
    bool persist = false,
    int desiredAccuracy = 40,
    int maximumAge = 10000,
    int timeout = 30,
    int samples = 3,
  }) async {
    try {
      final location = await bg.BackgroundGeolocation.getCurrentPosition(
        persist: persist,
        desiredAccuracy: desiredAccuracy,
        maximumAge: maximumAge,
        timeout: timeout,
        samples: samples,
      );
      return _convert(location);
    } catch (e) {
      debugPrint('[GeoLocationService] getCurrentPosition error: $e');
      return null;
    }
  }

  /// Update the maximum number of days for which the plugin retains fixes.
  Future<void> updateRetentionDays(int days) async {
    if (!_isConfigured) return;
    try {
      await bg.BackgroundGeolocation.setConfig(
        bg.Config(maxDaysToPersist: days == -1 ? 999999 : days),
      );
    } catch (e) {
      debugPrint('[GeoLocationService] updateRetentionDays error: $e');
    }
  }

  // ---------- listener registration ----------------------------------------

  void addLocationListener(void Function(AppLocation) listener) {
    if (!_locationListeners.contains(listener)) {
      _locationListeners.add(listener);
    }
  }

  void removeLocationListener(void Function(AppLocation) listener) {
    _locationListeners.remove(listener);
  }

  void addEnabledChangeListener(void Function(bool) listener) {
    if (!_enabledListeners.contains(listener)) {
      _enabledListeners.add(listener);
    }
  }

  void removeEnabledChangeListener(void Function(bool) listener) {
    _enabledListeners.remove(listener);
  }

  // ---------- headless task ------------------------------------------------

  /// Register the FBG headless task handler. Call once from `main()`.
  static void registerHeadlessTask() {
    try {
      bg.BackgroundGeolocation.registerHeadlessTask(_headlessEventHandler);
    } catch (e) {
      debugPrint('[GeoLocationService] registerHeadlessTask error: $e');
    }
  }

  static void _headlessEventHandler(bg.HeadlessEvent headlessEvent) async {
    debugPrint('[GeoLocationService] Headless event: ${headlessEvent.name}');
  }

  // ---------- FBG internal handlers ----------------------------------------

  void _handleLocation(bg.Location location) {
    final appLocation = _convert(location);
    for (final listener in List.of(_locationListeners)) {
      try {
        listener(appLocation);
      } catch (e) {
        debugPrint('[GeoLocationService] Location listener error: $e');
      }
    }
  }

  void _handleLocationError(bg.LocationError error) {
    debugPrint('[GeoLocationService] Location error: $error');
  }

  void _handleMotionChange(bg.Location location) {
    // Motion changes are forwarded as location updates to all listeners.
    _handleLocation(location);
  }

  void _handleActivityChange(bg.ActivityChangeEvent event) {
    debugPrint(
        '[GeoLocationService] Activity: ${event.activity} (${event.confidence}%)');
  }

  void _handleProviderChange(bg.ProviderChangeEvent event) {
    debugPrint('[GeoLocationService] Provider changed: $event');
  }

  void _handleEnabledChange(bool enabled) {
    _isEnabled = enabled;
    debugPrint('[GeoLocationService] Enabled changed: $enabled');
    for (final listener in List.of(_enabledListeners)) {
      try {
        listener(enabled);
      } catch (e) {
        debugPrint('[GeoLocationService] EnabledChange listener error: $e');
      }
    }
  }

  // ---------- conversion ---------------------------------------------------

  AppLocation _convert(bg.Location location) {
    return AppLocation(
      coords: AppLocationCoords(
        latitude: location.coords.latitude,
        longitude: location.coords.longitude,
        accuracy: location.coords.accuracy,
        altitude: location.coords.altitude,
        speed: location.coords.speed,
      ),
      isMoving: location.isMoving,
      timestamp: location.timestamp,
      activity: AppActivityData(
        type: location.activity.type,
        confidence: location.activity.confidence,
      ),
    );
  }
}
