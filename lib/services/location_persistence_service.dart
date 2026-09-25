import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../db/survey_database.dart';
import 'geo_location_service.dart';
import 'storage_settings_service.dart';

/// Moves location fixes from the location plugin's native on-device buffer
/// into the app database (`location_tracks`).
///
/// This is the only code path that persists fixes. The plugin writes every
/// fix to its native buffer as it is recorded -- including while no Dart code
/// is running: after the UI was closed while the Android foreground service
/// kept tracking, after Android restarted that service following process
/// death, and while iOS relaunched the app in the background for a location
/// event. Persisting only from the live stream (as the app used to) lost all
/// of those fixes.
///
/// The buffer is drained when [start] runs (at app startup), whenever the app
/// resumes, a few seconds after live fixes, and by anything about to read
/// `location_tracks` for a survey or upload (call [drainNow] first). Delivery
/// is at-least-once: a batch leaves the buffer only after it is stored, and
/// `location_tracks.timestamp` is unique, so a fix delivered twice is stored
/// once.
///
/// The same filters as before apply: fixes less accurate than
/// [maxAccuracyMeters] are dropped, stationary fixes are thinned to one per
/// [stationarySaveInterval] (by fix time, since drained fixes can be hours
/// old), and fixes older than the user's retention setting are skipped.
class LocationPersistenceService with WidgetsBindingObserver {
  LocationPersistenceService._({
    required Future<int> Function(
            Future<void> Function(List<AppLocation> batch) handle)
        drainSource,
    required Future<int> Function(List<Map<String, dynamic>> rows) storeRows,
    required Future<DateTime?> Function() retentionCutoff,
  })  : _drainSource = drainSource,
        _storeRows = storeRows,
        _retentionCutoff = retentionCutoff;

  /// The app-wide instance, wired to the plugin buffer and the app database.
  static final LocationPersistenceService instance = LocationPersistenceService._(
    drainSource: GeoLocationService.instance.drainBufferedLocations,
    storeRows: (rows) => SurveyDatabase().insertLocationTracks(rows),
    retentionCutoff: _userRetentionCutoff,
  );

  /// An instance with injected collaborators, for tests.
  @visibleForTesting
  factory LocationPersistenceService.forTesting({
    required Future<int> Function(
            Future<void> Function(List<AppLocation> batch) handle)
        drainSource,
    required Future<int> Function(List<Map<String, dynamic>> rows) storeRows,
    Future<DateTime?> Function()? retentionCutoff,
  }) {
    return LocationPersistenceService._(
      drainSource: drainSource,
      storeRows: storeRows,
      retentionCutoff: retentionCutoff ?? () async => null,
    );
  }

  /// Fixes with a larger accuracy radius are not stored.
  static const double maxAccuracyMeters =
      StorageSettingsService.MAX_MAP_ERROR_THRESHOLD_METERS;

  /// While stationary, store at most one fix per this interval.
  static const Duration stationarySaveInterval = Duration(minutes: 2);

  /// Delay between a live fix and the drain that stores it, so bursts of
  /// fixes are stored together.
  static const Duration liveFixDrainDelay = Duration(seconds: 5);

  final Future<int> Function(
      Future<void> Function(List<AppLocation> batch) handle) _drainSource;
  final Future<int> Function(List<Map<String, dynamic>> rows) _storeRows;
  final Future<DateTime?> Function() _retentionCutoff;

  bool _started = false;
  Future<int>? _inFlight;
  bool _rerunRequested = false;
  Timer? _liveFixTimer;

  /// Fix time of the last stationary fix stored (thinning cursor).
  DateTime? _lastStationarySavedAt;

  /// Starts persisting fixes: drains now, after every app resume, and after
  /// live fixes. Idempotent.
  void start() {
    if (_started || kIsWeb) return;
    _started = true;
    GeoLocationService.instance.addLocationListener(handleLiveFix);
    WidgetsBinding.instance.addObserver(this);
    drainNow();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      drainNow();
    }
  }

  /// Schedules a drain [liveFixDrainDelay] after a live fix arrives.
  @visibleForTesting
  void handleLiveFix(AppLocation _) {
    // Arm once per burst, not per fix: restarting the timer on every fix
    // would postpone the drain for as long as fixes kept arriving.
    if (_liveFixTimer?.isActive ?? false) return;
    _liveFixTimer = Timer(liveFixDrainDelay, drainNow);
  }

  /// Moves everything currently buffered into the database and returns how
  /// many new rows were stored. Concurrent calls share one drain; a call made
  /// while a drain is running makes it run once more, so a fix recorded
  /// mid-drain is not left waiting for the next trigger. Never throws: on
  /// failure the remaining fixes simply stay buffered for the next drain.
  Future<int> drainNow() {
    if (kIsWeb) return Future<int>.value(0);
    final Future<int>? running = _inFlight;
    if (running != null) {
      _rerunRequested = true;
      return running;
    }
    final Future<int> drain = _drainUntilSettled();
    _inFlight = drain;
    return drain.whenComplete(() => _inFlight = null);
  }

  Future<int> _drainUntilSettled() async {
    int stored = 0;
    do {
      _rerunRequested = false;
      stored += await _drainOnce();
    } while (_rerunRequested);
    return stored;
  }

  Future<int> _drainOnce() async {
    int stored = 0;
    try {
      final DateTime? cutoff = await _retentionCutoff();
      await _drainSource((List<AppLocation> batch) async {
        final selection = selectFixesToStore(
          batch,
          lastStationarySavedAt: _lastStationarySavedAt,
          retentionCutoff: cutoff,
        );
        stored += await _storeRows(selection.rows);
        // Advance the thinning cursor only once the batch is safely stored;
        // if storing threw, the batch is re-delivered and re-evaluated.
        _lastStationarySavedAt = selection.lastStationarySavedAt;
      });
    } catch (error) {
      debugPrint('[LocationPersistence] Drain stopped; remaining fixes stay '
          'buffered for the next attempt: $error');
    }
    return stored;
  }

  /// Picks the fixes of [batch] to store and returns them as
  /// `location_tracks` rows, plus the updated thinning cursor. Pure, so the
  /// caller can commit the cursor only after the rows are stored.
  @visibleForTesting
  static FixSelection selectFixesToStore(
    List<AppLocation> batch, {
    DateTime? lastStationarySavedAt,
    DateTime? retentionCutoff,
  }) {
    final List<Map<String, dynamic>> rows = <Map<String, dynamic>>[];
    DateTime? cursor = lastStationarySavedAt;
    for (final AppLocation location in batch) {
      final DateTime? fixTime = DateTime.tryParse(location.timestamp)?.toUtc();
      if (fixTime == null) continue;
      if (retentionCutoff != null && fixTime.isBefore(retentionCutoff)) {
        continue;
      }
      if (location.coords.accuracy > maxAccuracyMeters) continue;
      if (!location.isMoving) {
        if (cursor != null &&
            fixTime.difference(cursor) < stationarySaveInterval) {
          continue;
        }
        cursor = fixTime;
      }
      rows.add(<String, dynamic>{
        'timestamp': fixTime.toIso8601String(),
        'latitude': location.coords.latitude,
        'longitude': location.coords.longitude,
        'accuracy': location.coords.accuracy,
        'altitude': location.coords.altitude,
        'speed': location.coords.speed,
        'activity': location.activity.type,
      });
    }
    return FixSelection(rows, cursor);
  }

  /// Fixes older than this are past the user's retention setting and would
  /// be deleted by the next cleanup anyway, so they are not stored.
  static Future<DateTime?> _userRetentionCutoff() async {
    if (!await StorageSettingsService.getLocationRetentionLimited()) return null;
    final int days = await StorageSettingsService.getLocationRetentionDays();
    if (days == StorageSettingsService.UNLIMITED_VALUE) return null;
    return DateTime.now().toUtc().subtract(Duration(days: days));
  }
}

/// Result of [LocationPersistenceService.selectFixesToStore].
@visibleForTesting
class FixSelection {
  const FixSelection(this.rows, this.lastStationarySavedAt);

  /// `location_tracks` rows to insert.
  final List<Map<String, dynamic>> rows;

  /// Updated thinning cursor: fix time of the last stationary fix selected.
  final DateTime? lastStationarySavedAt;
}
