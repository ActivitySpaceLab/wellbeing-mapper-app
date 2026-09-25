import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/services/device_storage_guard.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <String>[];

  setUp(calls.clear);

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(DeviceStorageGuard.channel, null);
  });

  test('on iOS, startup waits until the native side says data is readable',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    final readable = Completer<bool>();
    messenger.setMockMethodCallHandler(DeviceStorageGuard.channel,
        (MethodCall call) {
      calls.add(call.method);
      return readable.future;
    });

    var done = false;
    final waiting =
        DeviceStorageGuard.waitUntilReadable().then((_) => done = true);
    await pumpEventQueue();
    // E.g. a background launch before the first unlock after a restart.
    expect(done, isFalse);

    readable.complete(true);
    await waiting;
    expect(done, isTrue);
    expect(calls, <String>['waitUntilReadable']);
  });

  test('on iOS, a missing native handler does not block startup', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await DeviceStorageGuard.waitUntilReadable();
  });

  test('on Android nothing waits (apps never start before the first unlock)',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    messenger.setMockMethodCallHandler(DeviceStorageGuard.channel,
        (MethodCall call) async {
      calls.add(call.method);
      return true;
    });

    await DeviceStorageGuard.waitUntilReadable();

    expect(calls, isEmpty);
  });
}
