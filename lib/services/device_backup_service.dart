import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import '../db/database_unpushed_locations.dart';
import '../db/survey_database.dart';

/// Whether the participant's history is included in the phone's own backups
/// (iCloud, or Google on Android). A choice in Settings, off by default.
///
/// History means the survey database: survey answers and location_tracks.
/// Off, it stays only on this phone, as the app's privacy texts promise
/// ("data stays on your phone"). On, it goes into the backups the phone makes
/// to the participant's own Apple or Google account, and to a new phone when
/// they switch. Backups are never sent to researchers.
///
/// Enforced natively:
/// * iOS: [apply] sets or clears the "excluded from backup" flag on the
///   database files (ios/Runner/AppDelegate.swift).
/// * Android: the backup rules always exclude the database, and
///   HistoryBackupAgent adds it back when a backup runs, if this setting is
///   on. It reads the same shared preference ([includeHistoryKey] with the
///   plugin's "flutter." prefix).
///
/// Never backed up either way: the location plugin's buffer and the legacy
/// unpushed-locations database.
class DeviceBackupService {
  DeviceBackupService._();

  /// Stored with shared_preferences; the Android backup agent reads it as
  /// `flutter.include_history_in_device_backups` in FlutterSharedPreferences.
  static const String includeHistoryKey = 'include_history_in_device_backups';

  @visibleForTesting
  static const MethodChannel channel = MethodChannel(
      'com.github.activityspacelab.wellbeingmapper/device_storage');

  /// Directory holding the app's databases; replaceable in tests.
  @visibleForTesting
  static Future<String> Function() databasesPath = getDatabasesPath;

  /// Whether the participant chose to include their history (default off).
  static Future<bool> isHistoryIncluded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(includeHistoryKey) ?? false;
  }

  /// Saves the participant's choice and applies it.
  static Future<void> setHistoryIncluded(bool include) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(includeHistoryKey, include);
    await apply();
  }

  /// At startup: makes sure the survey database exists, so a newly created
  /// one is flagged too, then applies the setting. Never throws.
  static Future<void> applyAtStartup() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      await SurveyDatabase().database;
    } catch (e) {
      debugPrint('[DeviceBackupService] Could not open the database: $e');
      return;
    }
    await apply();
  }

  /// Brings the iOS backup flags in line with the setting. Android needs
  /// nothing here: its backup agent checks the setting when a backup runs.
  /// Never throws.
  static Future<void> apply() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) return;
    try {
      final bool include = await isHistoryIncluded();
      final String directory = await databasesPath();
      await _setExcluded(
          _withSidecars(p.join(directory, SurveyDatabase.fileName)), !include);
      await _setExcluded(
          _withSidecars(p.join(directory, UnPushedLocationsDatabase.fileName)),
          true);
    } on MissingPluginException {
      // No native handler (e.g. a test host): nothing to flag.
    } catch (e) {
      debugPrint('[DeviceBackupService] Could not update backup flags: $e');
    }
  }

  static Future<void> _setExcluded(List<String> paths, bool excluded) {
    return channel.invokeMethod<int>('setExcludedFromBackup', <String, Object>{
      'paths': paths,
      'excluded': excluded,
    });
  }

  /// A SQLite database plus the journal files SQLite may create next to it.
  /// The native side skips files that do not exist.
  static List<String> _withSidecars(String path) =>
      <String>[path, '$path-journal', '$path-wal', '$path-shm'];
}
