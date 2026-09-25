import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:open_background_locator/open_background_locator.dart' as obl;
// ignore: implementation_imports
import 'package:open_background_locator/src/platform_interface.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wellbeing_mapper/db/survey_database.dart';
import 'package:wellbeing_mapper/services/geo_location_service.dart';
import 'package:wellbeing_mapper/services/location_persistence_service.dart';

AppLocation fix(
  String timestamp, {
  double lat = 45.0,
  double accuracy = 10.0,
  bool moving = true,
}) {
  return AppLocation(
    coords: AppLocationCoords(latitude: lat, longitude: 9.0, accuracy: accuracy),
    isMoving: moving,
    timestamp: timestamp,
    activity: const AppActivityData(type: 'unknown', confidence: 100),
  );
}

/// Fake native buffer: ordered ids, acknowledge deletes through an id.
class _FakeBufferPlatform extends OpenBackgroundLocatorPlatform {
  final List<obl.BufferedLocationUpdate> buffer = <obl.BufferedLocationUpdate>[];
  int _nextId = 1;

  void add(String timestamp, {double lat = 45.0, double accuracy = 10.0, double speed = 2.0}) {
    buffer.add(obl.BufferedLocationUpdate(
      id: _nextId++,
      update: obl.LocationUpdate(
        timestamp: DateTime.parse(timestamp),
        lat: lat,
        lon: 9.0,
        accuracyMeters: accuracy,
        speedMetersPerSecond: speed,
      ),
    ));
  }

  @override
  Future<List<obl.BufferedLocationUpdate>> getBufferedLocations({int limit = 500}) async =>
      List<obl.BufferedLocationUpdate>.of(buffer.take(limit));

  @override
  Future<int> acknowledgeBufferedLocations(int throughId) async {
    final int before = buffer.length;
    buffer.removeWhere((obl.BufferedLocationUpdate b) => b.id <= throughId);
    return before - buffer.length;
  }

  @override
  Future<int> getBufferedLocationCount() async => buffer.length;

  @override
  Future<void> clearBufferedLocations() async => buffer.clear();

  // Tracking API is not exercised here.
  @override
  Future<void> initialize(obl.LocatorConfig config) async {}
  @override
  Future<void> start({bool restart = false}) async {}
  @override
  Future<void> stop({String? reason}) async {}
  @override
  Future<obl.LocatorState> getState() async =>
      const obl.LocatorState(status: obl.LocatorStatus.stopped);
  @override
  Stream<obl.LocationUpdate> get updates => const Stream<obl.LocationUpdate>.empty();
  @override
  Stream<obl.LocatorState> get lifecycle => const Stream<obl.LocatorState>.empty();
  @override
  Stream<obl.LocatorError> get errors => const Stream<obl.LocatorError>.empty();
  @override
  Future<void> setGeofence(obl.Geofence geofence) async {}
  @override
  Stream<obl.GeofenceEvent> get geofenceEvents => const Stream<obl.GeofenceEvent>.empty();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('selectFixesToStore', () {
    test('keeps moving fixes and drops inaccurate ones', () {
      final selection = LocationPersistenceService.selectFixesToStore([
        fix('2026-08-01T10:00:00.000Z'),
        fix('2026-08-01T10:00:30.000Z', accuracy: 900),
        fix('2026-08-01T10:01:00.000Z'),
      ]);

      expect(selection.rows.map((r) => r['timestamp']), [
        '2026-08-01T10:00:00.000Z',
        '2026-08-01T10:01:00.000Z',
      ]);
    });

    test('thins stationary fixes to one per two minutes by fix time', () {
      // Fix times, not wall-clock: a drained backlog spans hours.
      final selection = LocationPersistenceService.selectFixesToStore([
        fix('2026-08-01T10:00:00.000Z', moving: false),
        fix('2026-08-01T10:01:00.000Z', moving: false),
        fix('2026-08-01T10:02:00.000Z', moving: false),
        fix('2026-08-01T10:03:00.000Z', moving: false),
        fix('2026-08-01T10:04:30.000Z', moving: false),
      ]);

      expect(selection.rows.map((r) => r['timestamp']), [
        '2026-08-01T10:00:00.000Z',
        '2026-08-01T10:02:00.000Z',
        '2026-08-01T10:04:30.000Z',
      ]);
      expect(selection.lastStationarySavedAt, DateTime.utc(2026, 8, 1, 10, 4, 30));
    });

    test('continues thinning from the cursor of the previous batch', () {
      final selection = LocationPersistenceService.selectFixesToStore(
        [fix('2026-08-01T10:01:00.000Z', moving: false)],
        lastStationarySavedAt: DateTime.utc(2026, 8, 1, 10, 0),
      );

      expect(selection.rows, isEmpty);
    });

    test('skips fixes older than the retention cutoff', () {
      final selection = LocationPersistenceService.selectFixesToStore(
        [fix('2026-06-01T10:00:00.000Z'), fix('2026-08-01T10:00:00.000Z')],
        retentionCutoff: DateTime.utc(2026, 7, 1),
      );

      expect(selection.rows.single['timestamp'], '2026-08-01T10:00:00.000Z');
    });

    test('produces location_tracks rows', () {
      final row = LocationPersistenceService.selectFixesToStore(
        [fix('2026-08-01T10:00:00.000Z', lat: 41.39, accuracy: 7.5)],
      ).rows.single;

      expect(row['timestamp'], '2026-08-01T10:00:00.000Z');
      expect(row['latitude'], 41.39);
      expect(row['longitude'], 9.0);
      expect(row['accuracy'], 7.5);
      expect(row['activity'], 'unknown');
    });
  });

  group('drainNow', () {
    test('stores each batch and returns the number of new rows', () async {
      final stored = <List<Map<String, dynamic>>>[];
      final service = LocationPersistenceService.forTesting(
        drainSource: (handle) async {
          await handle([fix('2026-08-01T10:00:00.000Z')]);
          await handle([fix('2026-08-01T10:01:00.000Z'), fix('2026-08-01T10:02:00.000Z')]);
          return 3;
        },
        storeRows: (rows) async {
          stored.add(rows);
          return rows.length;
        },
      );

      expect(await service.drainNow(), 3);
      expect(stored.map((b) => b.length), [1, 2]);
    });

    test('never throws; a failed store leaves the thinning cursor alone',
        () async {
      var failNext = true;
      final service = LocationPersistenceService.forTesting(
        drainSource: (handle) async {
          await handle([fix('2026-08-01T10:00:00.000Z', moving: false)]);
          return 1;
        },
        storeRows: (rows) async {
          if (failNext) {
            failNext = false;
            throw StateError('database is locked');
          }
          return rows.length;
        },
      );

      expect(await service.drainNow(), 0);
      // The same stationary fix is re-delivered and must still be stored:
      // the failed attempt must not have advanced the cursor past it.
      expect(await service.drainNow(), 1);
    });

    test('concurrent calls share one drain, which then runs once more',
        () async {
      var drains = 0;
      final gate = Completer<void>();
      final service = LocationPersistenceService.forTesting(
        drainSource: (handle) async {
          drains++;
          if (drains == 1) await gate.future;
          return 0;
        },
        storeRows: (rows) async => rows.length,
      );

      final first = service.drainNow();
      final second = service.drainNow();
      gate.complete();
      await Future.wait([first, second]);

      // One drain for both callers, plus one re-run for the call that
      // arrived mid-drain (it may have been triggered by a new fix).
      expect(drains, 2);
    });

    testWidgets('live fixes arriving faster than the delay still get drained',
        (WidgetTester tester) async {
      var drains = 0;
      final service = LocationPersistenceService.forTesting(
        drainSource: (handle) async {
          drains++;
          return 0;
        },
        storeRows: (rows) async => rows.length,
      );

      // A fix every 3 s for 12 s; the drain delay is 5 s. Restarting the
      // timer on every fix would never drain while fixes kept coming.
      for (var second = 0; second < 12; second += 3) {
        service.handleLiveFix(fix('2026-08-01T10:00:${second.toString().padLeft(2, '0')}.000Z'));
        await tester.pump(const Duration(seconds: 3));
      }

      // Drains at 5 s (burst from 0 s) and 11 s (burst from 6 s).
      expect(drains, 2);
    });
  });

  group('end to end: native buffer -> location_tracks', () {
    late Directory tempDir;
    late OpenBackgroundLocatorPlatform originalPlatform;
    late _FakeBufferPlatform platform;

    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('wm_persistence_test_');
      await databaseFactory.setDatabasesPath(tempDir.path);
      originalPlatform = OpenBackgroundLocatorPlatform.instance;
      platform = _FakeBufferPlatform();
      OpenBackgroundLocatorPlatform.instance = platform;
    });

    tearDown(() async {
      OpenBackgroundLocatorPlatform.instance = originalPlatform;
      await SurveyDatabase.resetForTesting();
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    LocationPersistenceService realService() => LocationPersistenceService.forTesting(
          drainSource: GeoLocationService.instance.drainBufferedLocations,
          storeRows: (rows) => SurveyDatabase().insertLocationTracks(rows),
        );

    test('fixes buffered while the app was not running end up stored',
        () async {
      platform.add('2026-08-01T10:00:00.000Z', lat: 45.0);
      platform.add('2026-08-01T10:05:00.000Z', lat: 45.1);
      platform.add('2026-08-01T10:10:00.000Z', lat: 45.2, accuracy: 900);

      final stored = await realService().drainNow();

      expect(stored, 2, reason: 'the inaccurate fix is filtered out');
      expect(platform.buffer, isEmpty, reason: 'everything was acknowledged');
      final tracks = await SurveyDatabase().getLocationTracksSince(DateTime.utc(2026, 1, 1));
      expect(tracks.map((t) => t.latitude).toList()..sort(), [45.0, 45.1]);
    });

    test('a re-delivered fix is stored only once', () async {
      platform.add('2026-08-01T10:00:00.000Z', lat: 45.0);
      await realService().drainNow();
      // Simulate a crash between storing and acknowledging: the same fix is
      // delivered again.
      platform.add('2026-08-01T10:00:00.000Z', lat: 45.0);

      final storedAgain = await realService().drainNow();

      expect(storedAgain, 0);
      final tracks = await SurveyDatabase().getLocationTracksSince(DateTime.utc(2026, 1, 1));
      expect(tracks, hasLength(1));
    });
  });
}
