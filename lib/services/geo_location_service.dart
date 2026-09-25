import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:open_background_locator/open_background_locator.dart' as obl;

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
///
/// OBL does not surface OS activity recognition, so the abstraction reports
/// `unknown` as the activity type. Speed is still available on
/// [AppLocationCoords] for callers that want a lightweight motion signal.
class AppActivityData {
  final String type;
  final int confidence;

  const AppActivityData({required this.type, required this.confidence});
}

/// A single location sample from the underlying location plugin.
/// This type decouples the rest of the app from the concrete plugin
/// implementation so the underlying library can be swapped without touching
/// UI code.
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

/// Singleton facade over the background-location plugin.
///
/// All location-related operations in the app go through this service. The
/// public surface (configure/start/stop, listeners, [AppLocation]) is stable
/// across plugin swaps; only this file changes when the underlying plugin
/// changes.
///
/// Backed by `open_background_locator`.
class GeoLocationService {
  // ---------- singleton ----------------------------------------------------
  static final GeoLocationService _instance = GeoLocationService._();
  GeoLocationService._();
  static GeoLocationService get instance => _instance;

  // ---------- state --------------------------------------------------------
  bool _isConfigured = false;
  bool _isEnabled = false;

  StreamSubscription<obl.LocationUpdate>? _updatesSub;
  StreamSubscription<obl.LocatorState>? _lifecycleSub;
  StreamSubscription<obl.LocatorError>? _errorsSub;

  bool get isConfigured => _isConfigured;
  bool get isEnabled => _isEnabled;

  // ---------- listener lists -----------------------------------------------
  final List<void Function(AppLocation)> _locationListeners = [];
  final List<void Function(bool)> _enabledListeners = [];

  // ---------- public API ---------------------------------------------------

  /// Guards against concurrent configure() calls: without it, two callers
  /// interleaving across the awaits would both subscribe to the OBL streams,
  /// and every location fix would be delivered (and persisted) twice.
  Future<bool>? _configureFuture;

  /// Configure the underlying plugin. Idempotent — safe to call more than once,
  /// including concurrently.
  ///
  /// Returns the initial tracking-enabled state (derived from OBL's
  /// [obl.LocatorState] at the moment of configuration).
  Future<bool> configure({
    required String userId,
    required String sampleId,
  }) async {
    if (_isConfigured) return _isEnabled;
    final pending = _configureFuture;
    if (pending != null) return pending;
    final future = _doConfigure(userId: userId, sampleId: sampleId);
    _configureFuture = future;
    try {
      return await future;
    } finally {
      _configureFuture = null;
    }
  }

  Future<bool> _doConfigure({
    required String userId,
    required String sampleId,
  }) async {
    // Subscribe to OBL's three streams. All UI code uses addXxxListener so
    // there are no duplicate subscriptions.
    _updatesSub = obl.OpenBackgroundLocator.updates.listen(
      _handleLocationUpdate,
      onError: (Object error, StackTrace _) {
        debugPrint('[GeoLocationService] Updates stream error: $error');
      },
    );
    _lifecycleSub = obl.OpenBackgroundLocator.lifecycle.listen(
      _handleLifecycleChange,
      onError: (Object error, StackTrace _) {
        debugPrint('[GeoLocationService] Lifecycle stream error: $error');
      },
    );
    _errorsSub = obl.OpenBackgroundLocator.errors.listen(
      _handleLocatorError,
      onError: (Object error, StackTrace _) {
        debugPrint('[GeoLocationService] Errors stream error: $error');
      },
    );

    // Initialise OBL with production-appropriate defaults. The app manages
    // its own retention/persistence in SQLite, so we keep OBL focused on
    // low-overhead background sampling.
    try {
      await obl.OpenBackgroundLocator.initialize(
        const obl.LocatorConfig(
          accuracy: obl.LocationAccuracyLevel.high,
          distanceFilterMeters: 10,
          intervalSeconds: 60,
          ios: obl.IosConfig(
            activityType: obl.IosActivityType.fitness,
            allowBackgroundLocationUpdates: true,
            showBackgroundIndicator: true,
            pausesLocationUpdatesAutomatically: false,
          ),
          android: obl.AndroidConfig(
            foregroundNotificationConfig: obl.ForegroundNotificationConfig(
              channelId: 'wellbeing_mapper_location',
              channelName: 'Background location',
              title: 'Wellbeing Mapper',
              text: 'Recording location for your wellbeing study.',
            ),
            serviceRestartStrategy:
                obl.AndroidServiceRestartStrategy.workManager,
            batteryOptimizationPolicy:
                obl.AndroidBatteryOptimizationPolicy.compromise,
          ),
        ),
      );

      final state = await obl.OpenBackgroundLocator.getState();
      _isEnabled = _statusIsActive(state.status);
    } catch (e) {
      debugPrint('[GeoLocationService] OBL initialize/getState error: $e');
      _isEnabled = false;
    }

    _isConfigured = true;
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
      await obl.OpenBackgroundLocator.start();
      final state = await obl.OpenBackgroundLocator.getState();
      _isEnabled = _statusIsActive(state.status);
      _notifyEnabledChange(_isEnabled);
      return _isEnabled;
    } catch (e) {
      debugPrint('[GeoLocationService] Error starting tracking: $e');
      return false;
    }
  }

  /// Stop location tracking. Returns `false` (tracking is now inactive).
  Future<bool> stop() async {
    try {
      await obl.OpenBackgroundLocator.stop(reason: 'user-requested');
      _isEnabled = false;
      _notifyEnabledChange(false);
      return false;
    } catch (e) {
      debugPrint('[GeoLocationService] Error stopping tracking: $e');
      _isEnabled = false;
      return false;
    }
  }

  /// Oldest tracking fix [getCurrentPosition] falls back to when no fresh fix
  /// can be obtained; an older one would place a survey answer wherever the
  /// participant happened to be when tracking last ran.
  static const Duration staleFixFallbackMaxAge = Duration(minutes: 15);

  /// Fetch a single current position, or `null` on error / timeout.
  ///
  /// Returns the most recent tracking fix from
  /// [obl.OpenBackgroundLocator.getState] if it is younger than [maximumAge]
  /// milliseconds; otherwise requests a one-off fix with
  /// [obl.OpenBackgroundLocator.getCurrentLocation], waiting up to [timeout]
  /// seconds. If none arrives, falls back to the tracking fix only if it is
  /// within [staleFixFallbackMaxAge] -- and never when location permission or
  /// Location Services are off, since the participant has just said not to
  /// record where they are.
  ///
  /// Never starts tracking: the one-off request is independent of the
  /// tracking session. (Starting tracking just to take one fix is unsafe: the
  /// plugin now keeps a tracking session alive across app termination, so a
  /// kill before the matching stop would leave tracking running for a user
  /// who has it switched off.) The fix is not stored in `location_tracks`.
  /// Does not need [configure].
  ///
  /// Parameters [persist], [desiredAccuracy], and [samples] are accepted for
  /// API compatibility with the previous (FBG-backed) implementation; fixes
  /// are always requested at high accuracy.
  Future<AppLocation?> getCurrentPosition({
    bool persist = false,
    int desiredAccuracy = 40,
    int maximumAge = 10000,
    int timeout = 30,
    int samples = 3,
  }) async {
    obl.LocationUpdate? lastUpdate;
    try {
      lastUpdate = (await obl.OpenBackgroundLocator.getState()).lastUpdate;
      if (lastUpdate != null) {
        final ageMs = _ageOf(lastUpdate).inMilliseconds;
        if (ageMs >= 0 && ageMs <= maximumAge) {
          return _convert(lastUpdate);
        }
      }

      final update = await obl.OpenBackgroundLocator.getCurrentLocation(
        accuracy: obl.LocationAccuracyLevel.high,
        timeout: Duration(seconds: timeout),
      );
      if (update != null) return _convert(update);
      debugPrint(
          '[GeoLocationService] getCurrentPosition: no fix within ${timeout}s');
    } on PlatformException catch (e) {
      debugPrint('[GeoLocationService] getCurrentPosition error: $e');
      if (e.code == 'permission-denied' ||
          e.code == 'location-services-disabled') {
        return null;
      }
    } catch (e) {
      debugPrint('[GeoLocationService] getCurrentPosition error: $e');
    }
    // Prefer a recent tracking fix over no location for map-linked survey
    // entries, but not an old one.
    if (lastUpdate != null &&
        _ageOf(lastUpdate).abs() <= staleFixFallbackMaxAge) {
      return _convert(lastUpdate);
    }
    return null;
  }

  static Duration _ageOf(obl.LocationUpdate update) =>
      DateTime.now().toUtc().difference(update.timestamp.toUtc());

  /// Update the maximum number of days for which the plugin retains fixes.
  ///
  /// OBL does not store fixes itself — the app manages its own retention in
  /// SQLite (see `StorageSettingsService`), so this is a no-op kept for
  /// API compatibility.
  Future<void> updateRetentionDays(int days) async {
    debugPrint(
        '[GeoLocationService] updateRetentionDays($days): no-op (handled by app storage layer).');
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

  /// Register the headless task handler. Call once from `main()`.
  ///
  /// OBL does not currently expose a Dart-side headless task hook (its
  /// foreground-service / `BGTaskScheduler` integration runs natively).
  /// Background work that needs to fire when the app is terminated is
  /// already handled by `background_fetch` in [main.dart], so this is a
  /// no-op kept for API compatibility.
  static void registerHeadlessTask() {
    debugPrint(
        '[GeoLocationService] registerHeadlessTask(): no-op for OBL backend.');
  }

  // ---------- internal -----------------------------------------------------

  bool _statusIsActive(obl.LocatorStatus status) {
    return status == obl.LocatorStatus.running ||
        status == obl.LocatorStatus.starting;
  }

  void _handleLocationUpdate(obl.LocationUpdate update) {
    final appLocation = _convert(update);
    for (final listener in List.of(_locationListeners)) {
      try {
        listener(appLocation);
      } catch (e) {
        debugPrint('[GeoLocationService] Location listener error: $e');
      }
    }
  }

  void _handleLifecycleChange(obl.LocatorState state) {
    final active = _statusIsActive(state.status);
    if (active != _isEnabled) {
      _isEnabled = active;
      debugPrint('[GeoLocationService] Lifecycle changed: status=${state.status}'
          ', enabled=$active');
      _notifyEnabledChange(active);
    }
  }

  void _handleLocatorError(obl.LocatorError error) {
    debugPrint('[GeoLocationService] Locator error: ${error.code} '
        '— ${error.message}');
  }

  void _notifyEnabledChange(bool enabled) {
    for (final listener in List.of(_enabledListeners)) {
      try {
        listener(enabled);
      } catch (e) {
        debugPrint('[GeoLocationService] EnabledChange listener error: $e');
      }
    }
  }

  /// Sentinel for a fix that reports no accuracy: treat it as very poor so
  /// accuracy-based filters reject it. Using 0.0 would make an invalid fix
  /// look like a perfect one and bypass every filter.
  static const double _unknownAccuracyMeters = 9999.0;

  AppLocation _convert(obl.LocationUpdate update) {
    final speed = update.speedMetersPerSecond ?? 0.0;
    return AppLocation(
      coords: AppLocationCoords(
        latitude: update.lat,
        longitude: update.lon,
        accuracy: update.accuracyMeters ?? _unknownAccuracyMeters,
        altitude: update.altitudeMeters ?? 0.0,
        speed: speed,
      ),
      // OBL doesn't surface OS motion-state directly; derive a coarse flag
      // from speed so the rest of the app keeps a useful `isMoving` value.
      isMoving: speed > 1.0,
      timestamp: update.timestamp.toUtc().toIso8601String(),
      activity: AppActivityData(
        type: 'unknown',
        confidence: _confidenceToPercent(update.confidence),
      ),
    );
  }

  int _confidenceToPercent(obl.LocationConfidence confidence) {
    switch (confidence) {
      case obl.LocationConfidence.high:
        return 100;
      case obl.LocationConfidence.medium:
        return 75;
      case obl.LocationConfidence.low:
        return 25;
    }
  }

  /// Tear down stream subscriptions. Primarily used by tests.
  @visibleForTesting
  Future<void> disposeForTesting() async {
    await _updatesSub?.cancel();
    await _lifecycleSub?.cancel();
    await _errorsSub?.cancel();
    _updatesSub = null;
    _lifecycleSub = null;
    _errorsSub = null;
    _locationListeners.clear();
    _enabledListeners.clear();
    _isConfigured = false;
    _isEnabled = false;
  }
}
