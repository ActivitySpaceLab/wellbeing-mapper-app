import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:open_background_locator/open_background_locator.dart' as obl;
// ignore: implementation_imports
import 'package:open_background_locator/src/platform_interface.dart';
import 'package:wellbeing_mapper/services/geo_location_service.dart';

/// Fake plugin for one-off position requests: records any tracking calls,
/// which getCurrentPosition must never make.
class _FakeLocatorPlatform extends OpenBackgroundLocatorPlatform {
  obl.LocationUpdate? cachedFix;
  obl.LocationUpdate? oneOffFix;
  Object? oneOffError;
  int oneOffRequests = 0;
  Duration? requestedTimeout;
  final List<String> trackingCalls = <String>[];

  @override
  Future<obl.LocatorState> getState() async => obl.LocatorState(
        status: obl.LocatorStatus.stopped,
        lastUpdate: cachedFix,
      );

  @override
  Future<obl.LocationUpdate?> getCurrentLocation({
    obl.LocationAccuracyLevel accuracy = obl.LocationAccuracyLevel.high,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    oneOffRequests++;
    requestedTimeout = timeout;
    final Object? error = oneOffError;
    if (error != null) throw error;
    return oneOffFix;
  }

  @override
  Future<void> start({bool restart = false}) async => trackingCalls.add('start');
  @override
  Future<void> stop({String? reason}) async => trackingCalls.add('stop');
  @override
  Future<void> initialize(obl.LocatorConfig config) async =>
      trackingCalls.add('initialize');
  @override
  Stream<obl.LocationUpdate> get updates => const Stream<obl.LocationUpdate>.empty();
  @override
  Stream<obl.LocatorState> get lifecycle => const Stream<obl.LocatorState>.empty();
  @override
  Stream<obl.LocatorError> get errors => const Stream<obl.LocatorError>.empty();
  @override
  Future<void> setGeofence(obl.Geofence geofence) async {}
  @override
  Stream<obl.GeofenceEvent> get geofenceEvents =>
      const Stream<obl.GeofenceEvent>.empty();
}

obl.LocationUpdate _fixAt(DateTime timestamp, double lat) {
  return obl.LocationUpdate(
    timestamp: timestamp,
    lat: lat,
    lon: 2.17,
    accuracyMeters: 8,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final OpenBackgroundLocatorPlatform original =
      OpenBackgroundLocatorPlatform.instance;
  late _FakeLocatorPlatform platform;

  setUp(() {
    platform = _FakeLocatorPlatform();
    OpenBackgroundLocatorPlatform.instance = platform;
  });

  tearDown(() => OpenBackgroundLocatorPlatform.instance = original);

  group('getCurrentPosition', () {
    test('returns a recent tracking fix without a new request', () async {
      platform.cachedFix = _fixAt(DateTime.now().toUtc(), 41.1);

      final location = await GeoLocationService.instance
          .getCurrentPosition(maximumAge: 60000);

      expect(location?.coords.latitude, 41.1);
      expect(platform.oneOffRequests, 0);
      expect(platform.trackingCalls, isEmpty);
    });

    test('requests a one-off fix, and never starts or stops tracking',
        () async {
      // Stale tracking fix; tracking is off.
      platform.cachedFix = _fixAt(
          DateTime.now().toUtc().subtract(const Duration(hours: 1)), 41.1);
      platform.oneOffFix = _fixAt(DateTime.now().toUtc(), 41.2);

      final location = await GeoLocationService.instance
          .getCurrentPosition(maximumAge: 60000, timeout: 75);

      expect(location?.coords.latitude, 41.2);
      expect(platform.requestedTimeout, const Duration(seconds: 75));
      // Starting tracking to take one fix could leave it running if the app
      // were killed before the matching stop.
      expect(platform.trackingCalls, isEmpty);
    });

    test('falls back to a recent tracking fix when no one-off fix arrives',
        () async {
      platform.cachedFix = _fixAt(
          DateTime.now().toUtc().subtract(const Duration(minutes: 10)), 41.1);
      platform.oneOffFix = null;

      final location = await GeoLocationService.instance
          .getCurrentPosition(maximumAge: 60000);

      expect(location?.coords.latitude, 41.1);
    });

    test('does not fall back to an old tracking fix', () async {
      // E.g. tracking was switched off hours ago: tagging a survey answer
      // with that position would place it where the participant was then.
      platform.cachedFix = _fixAt(
          DateTime.now().toUtc().subtract(const Duration(hours: 1)), 41.1);
      platform.oneOffFix = null;

      final location = await GeoLocationService.instance
          .getCurrentPosition(maximumAge: 60000);

      expect(location, isNull);
    });

    test('falls back to a recent tracking fix when the request fails',
        () async {
      platform.cachedFix = _fixAt(
          DateTime.now().toUtc().subtract(const Duration(minutes: 10)), 41.1);
      platform.oneOffError = PlatformException(code: 'location-error');

      final location = await GeoLocationService.instance
          .getCurrentPosition(maximumAge: 60000);

      expect(location?.coords.latitude, 41.1);
      expect(platform.trackingCalls, isEmpty);
    });

    for (final code in <String>[
      'permission-denied',
      'location-services-disabled',
    ]) {
      test('returns no location at all after $code', () async {
        // The participant has just turned location off: no fallback.
        platform.cachedFix = _fixAt(
            DateTime.now().toUtc().subtract(const Duration(minutes: 2)), 41.1);
        platform.oneOffError = PlatformException(code: code);

        final location = await GeoLocationService.instance
            .getCurrentPosition(maximumAge: 60000);

        expect(location, isNull);
      });
    }

    test('returns null when there is no fix at all', () async {
      platform.oneOffFix = null;

      expect(await GeoLocationService.instance.getCurrentPosition(), isNull);
    });
  });
}
