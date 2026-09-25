import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Holds app startup until the app's stored data can be read.
///
/// iOS can launch the app in the background -- for a significant location
/// change, which tracking now uses so it resumes after the app is terminated
/// -- after the phone restarts and before it has been unlocked for the first
/// time. Until that first unlock the app's data is encrypted: preferences read
/// as empty and databases fail to open. Startup would take that for a fresh
/// install and mint a new participant id, which a participant who then opens
/// the app would submit surveys under (and which could be saved over the real
/// one). The native side (`ios/Runner/AppDelegate.swift`) answers once the
/// data is readable, which is immediately in every other case.
///
/// Location recording does not depend on Dart: the location plugin resumes a
/// tracking session natively and buffers fixes until Dart drains them. Its
/// saved session and buffer are protected the same way, so after a reboot it,
/// too, resumes only once the device is first unlocked.
class DeviceStorageGuard {
  DeviceStorageGuard._();

  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
      'com.github.activityspacelab.wellbeingmapper/device_storage');

  /// Completes once stored data is readable. Immediate on platforms other
  /// than iOS, which never start the app before the first unlock.
  static Future<void> waitUntilReadable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await channel.invokeMethod<bool>('waitUntilReadable');
    } on MissingPluginException {
      // No native handler (e.g. an older build or a test host): nothing to
      // wait for.
    } on PlatformException catch (e) {
      debugPrint('[DeviceStorageGuard] $e');
    }
  }
}
