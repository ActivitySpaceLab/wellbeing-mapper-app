import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/db/database_unpushed_locations.dart';
import 'package:wellbeing_mapper/db/survey_database.dart';
import 'package:wellbeing_mapper/services/device_backup_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final calls = <MethodCall>[];
  final originalDatabasesPath = DeviceBackupService.databasesPath;

  List<String> withSidecars(String path) =>
      [path, '$path-journal', '$path-wal', '$path-shm'];

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    calls.clear();
    DeviceBackupService.databasesPath = () async => '/app/Documents';
    messenger.setMockMethodCallHandler(DeviceBackupService.channel,
        (MethodCall call) async {
      calls.add(call);
      return 1;
    });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    DeviceBackupService.databasesPath = originalDatabasesPath;
    messenger.setMockMethodCallHandler(DeviceBackupService.channel, null);
  });

  test('history is kept out of phone backups by default', () async {
    expect(await DeviceBackupService.isHistoryIncluded(), isFalse);
  });

  test('the choice is saved', () async {
    await DeviceBackupService.setHistoryIncluded(true);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(DeviceBackupService.includeHistoryKey), isTrue);
    expect(await DeviceBackupService.isHistoryIncluded(), isTrue);
  });

  test('iOS: the survey database is flagged "excluded from backup" by default',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await DeviceBackupService.apply();

    expect(calls.map((c) => c.method),
        ['setExcludedFromBackup', 'setExcludedFromBackup']);
    expect(calls[0].arguments, {
      'paths': withSidecars('/app/Documents/${SurveyDatabase.fileName}'),
      'excluded': true,
    });
    expect(calls[1].arguments, {
      'paths':
          withSidecars('/app/Documents/${UnPushedLocationsDatabase.fileName}'),
      'excluded': true,
    });
  });

  test('iOS: opting in clears the flag on the survey database only', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    await DeviceBackupService.setHistoryIncluded(true);

    expect(calls[0].arguments['excluded'], isFalse);
    // The legacy database is stale location data: never backed up.
    expect(calls[1].arguments['excluded'], isTrue);
  });

  test('Android: nothing to flag; the backup agent reads the setting',
      () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    await DeviceBackupService.setHistoryIncluded(true);

    expect(calls, isEmpty);
  });

  test('a failing native call does not throw', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(DeviceBackupService.channel,
        (MethodCall call) async {
      throw PlatformException(code: 'backup-flag-failed');
    });

    await DeviceBackupService.apply();
  });

  group('native side agrees with the Dart names', () {
    // The Android agent, backup rules and iOS channel handler are not
    // exercised by Dart tests; these checks catch a rename on one side only.
    String read(String path) => File(path).readAsStringSync();
    const android = 'android/app/src/main';

    test('Android backup agent reads this setting and knows the database',
        () {
      final agent = read(
          '$android/kotlin/com/github/activityspacelab/wellbeingmapper/HistoryBackupAgent.kt');
      expect(agent,
          contains('"flutter.${DeviceBackupService.includeHistoryKey}"'));
      expect(agent, contains('"${SurveyDatabase.fileName}"'));
    });

    test('Android manifest uses the agent for full backups', () {
      final manifest = read('$android/AndroidManifest.xml');
      expect(manifest, contains('android:backupAgent=".HistoryBackupAgent"'));
      expect(manifest, contains('android:fullBackupOnly="true"'));
    });

    test('Android backup rules exclude the databases everywhere', () {
      for (final file in ['backup_rules.xml', 'data_extraction_rules.xml']) {
        final rules = read('$android/res/xml/$file');
        final sections = file == 'backup_rules.xml' ? 1 : 2;
        for (final name in [
          SurveyDatabase.fileName,
          'open_background_locator_buffer.db',
          UnPushedLocationsDatabase.fileName,
        ]) {
          expect(
            '<exclude domain="database" path="$name" />'
                .allMatches(rules)
                .length,
            sections,
            reason: '$file must exclude $name',
          );
        }
      }
    });

    test('iOS handles the backup-flag call', () {
      expect(read('ios/Runner/AppDelegate.swift'),
          contains('case "setExcludedFromBackup":'));
    });
  });
}
