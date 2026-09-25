import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' show join;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wellbeing_mapper/db/survey_database.dart';
import 'package:wellbeing_mapper/models/consent_models.dart';
import 'package:wellbeing_mapper/models/survey_models.dart';

/// Host-side tests for the SQLite data layer, run against sqflite's FFI
/// backend. These pin the regressions fixed in the v13 schema work:
/// - biweekly generalHealth / researchSite answers being silently dropped
/// - retention cleanup comparing epoch-millis strings to ISO timestamps
/// - consent_* fields not surviving an insert/read round-trip
/// - the v12 -> v13 migration itself
void main() {
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('wm_db_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
  });

  tearDown(() async {
    await SurveyDatabase.resetForTesting();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  RecurringSurveyResponse buildSurvey() => RecurringSurveyResponse(
        activities: ['Employed full-time', 'Physical activity'],
        livingArrangement: 'with_others',
        relationshipStatus: 'single',
        generalHealth: 'Good',
        cheerfulSpirits: 4,
        calmRelaxed: 3,
        activeVigorous: 2,
        wokeUpFresh: 5,
        dailyLifeInteresting: 4,
        environmentalChallenges: 'Extreme heat',
        challengesStressLevel: 'Somewhat',
        copingHelp: 'Family support',
        researchSite: 'wellbeing_mapper',
        submittedAt: DateTime(2026, 8, 1, 10, 30),
      );

  group('recurring survey persistence', () {
    test('round-trip preserves generalHealth and researchSite', () async {
      final db = SurveyDatabase();
      await db.insertRecurringSurvey(buildSurvey());

      final surveys = await db.getRecurringSurveys();
      expect(surveys, hasLength(1));
      final survey = surveys.first;
      expect(survey.generalHealth, 'Good',
          reason: 'generalHealth must survive insert/read (was silently dropped)');
      expect(survey.researchSite, 'wellbeing_mapper');
      expect(survey.activities, ['Employed full-time', 'Physical activity']);
      expect(survey.cheerfulSpirits, 4);
      expect(survey.environmentalChallenges, 'Extreme heat');
    });

    test('unsynced rows expose the new columns to the upload payload', () async {
      final db = SurveyDatabase();
      await db.insertRecurringSurvey(buildSurvey());

      final rows = await db.getUnsyncedRecurringSurveys();
      expect(rows, hasLength(1));
      expect(rows.first['general_health'], 'Good');
      expect(rows.first['research_site'], 'wellbeing_mapper');
    });
  });

  group('location retention cleanup', () {
    test('deletes rows older than the cutoff and keeps newer ones', () async {
      final db = SurveyDatabase();
      final now = DateTime.utc(2026, 8, 21, 12);

      await db.insertLocationTrack({
        'timestamp': now.subtract(Duration(days: 90)).toIso8601String(),
        'latitude': 45.0,
        'longitude': 12.0,
      });
      await db.insertLocationTrack({
        'timestamp': now.subtract(Duration(days: 1)).toIso8601String(),
        'latitude': 45.1,
        'longitude': 12.1,
      });

      final deleted =
          await db.cleanupOldLocationData(now.subtract(Duration(days: 60)));

      expect(deleted, 1,
          reason: 'exactly the 90-day-old row must be deleted '
              '(with the old epoch-millis comparison this was always 0)');

      final remaining =
          await db.getLocationTracksSince(now.subtract(Duration(days: 365)));
      expect(remaining, hasLength(1));
      expect(remaining.first.latitude, 45.1);
    });
  });

  group('consent persistence', () {
    test('round-trip preserves the site-specific consent answers', () async {
      final db = SurveyDatabase();
      final consent = ConsentResponse(
        participantUuid: 'uuid-123',
        informedConsent: true,
        dataProcessing: true,
        locationData: true,
        surveyData: true,
        dataRetention: true,
        dataSharing: false,
        voluntaryParticipation: true,
        consentedAt: DateTime(2026, 8, 1),
        participantSignature: 'CODE1',
        consentParticipate: true,
        consentQualtricsData: false, // not asked on the Italy site
        consentRaceEthnicity: true,
        consentHealth: true,
        consentSexualOrientation: false, // participant declined
        consentLocationMobility: true,
        consentDataTransfer: false,
        consentPublicReporting: false,
        consentResearcherSharing: false,
        consentFurtherResearch: false,
        consentPublicRepository: false,
        consentFollowupContact: false,
      );

      await db.insertConsent(consent);
      final stored = await db.getConsent();

      expect(stored, isNotNull);
      expect(stored!.participantUuid, 'uuid-123');
      expect(stored.consentQualtricsData, isFalse,
          reason: 'stored answers must not reset to model defaults on read');
      expect(stored.consentSexualOrientation, isFalse);
      expect(stored.consentDataTransfer, isFalse);
      expect(stored.consentParticipate, isTrue);
      expect(stored.consentLocationMobility, isTrue);
      expect(stored.dataSharing, isFalse);
    });
  });

  group('v12 -> v13 migration', () {
    test('keeps existing survey rows, adds columns, drops sync_queue',
        () async {
      final dbPath = join(tempDir.path, 'survey_database.db');

      // Build a database exactly as v12 left it: recurring table without the
      // new columns, plus the legacy sync_queue table.
      final legacy = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 12,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE recurring_survey_responses (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                activities TEXT,
                living_arrangement TEXT,
                relationship_status TEXT,
                cheerful_spirits INTEGER,
                calm_relaxed INTEGER,
                active_vigorous INTEGER,
                woke_up_fresh INTEGER,
                daily_life_interesting INTEGER,
                cooperate_with_people INTEGER,
                improving_skills INTEGER,
                social_situations INTEGER,
                family_support INTEGER,
                family_knows_me INTEGER,
                access_to_food INTEGER,
                people_enjoy_time INTEGER,
                talk_to_family INTEGER,
                friends_support INTEGER,
                belong_in_community INTEGER,
                family_stands_by_me INTEGER,
                friends_stand_by_me INTEGER,
                treated_fairly INTEGER,
                opportunities_responsibility INTEGER,
                secure_with_family INTEGER,
                opportunities_abilities INTEGER,
                enjoy_cultural_traditions INTEGER,
                environmental_challenges TEXT,
                challenges_stress_level TEXT,
                coping_help TEXT,
                voice_note_urls TEXT,
                image_urls TEXT,
                submitted_at TEXT,
                synced INTEGER DEFAULT 0,
                encrypted_location_data TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
              )
            ''');
            await db.execute('''
              CREATE TABLE sync_queue (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                table_name TEXT,
                record_id INTEGER,
                action TEXT,
                data TEXT,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
              )
            ''');
          },
        ),
      );
      await legacy.insert('recurring_survey_responses', {
        'activities': '["Volunteering"]',
        'cheerful_spirits': 3,
        'submitted_at': DateTime(2026, 7, 1).toIso8601String(),
      });
      await legacy.close();

      // Opening through SurveyDatabase runs the v13 migration.
      final db = SurveyDatabase();
      final surveys = await db.getRecurringSurveys();
      expect(surveys, hasLength(1),
          reason: 'existing rows must survive the migration');
      expect(surveys.first.activities, ['Volunteering']);
      expect(surveys.first.generalHealth, isNull);
      // The read-back default applies for pre-migration rows.
      expect(surveys.first.researchSite, 'wellbeing_mapper');

      // New columns are writable now.
      await db.insertRecurringSurvey(buildSurvey());
      final all = await db.getRecurringSurveys();
      expect(all, hasLength(2));

      // sync_queue is gone.
      final raw = await db.database;
      final tables = await raw.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name='sync_queue'");
      expect(tables, isEmpty);
    });
  });

  group('location track de-duplication', () {
    Map<String, dynamic> track(String timestamp, double lat) => {
          'timestamp': timestamp,
          'latitude': lat,
          'longitude': 12.0,
          'accuracy': 8.0,
        };

    test('insertLocationTracks stores new fixes and ignores repeats',
        () async {
      final db = SurveyDatabase();

      final first = await db.insertLocationTracks([
        track('2026-08-01T10:00:00.000Z', 45.0),
        track('2026-08-01T10:01:00.000Z', 45.1),
      ]);
      // A re-delivered fix (same timestamp) plus one new fix.
      final second = await db.insertLocationTracks([
        track('2026-08-01T10:01:00.000Z', 45.1),
        track('2026-08-01T10:02:00.000Z', 45.2),
      ]);

      expect(first, 2);
      expect(second, 1, reason: 'only the genuinely new fix counts');
      final all = await db.getLocationTracksSince(DateTime.utc(2026, 1, 1));
      expect(all, hasLength(3));
    });

    test('insertLocationTracks with nothing to insert is a no-op', () async {
      expect(await SurveyDatabase().insertLocationTracks([]), 0);
    });

    test('v13 -> v14 collapses duplicate fixes and enforces uniqueness',
        () async {
      final dbPath = join(tempDir.path, 'survey_database.db');
      final legacy = await databaseFactory.openDatabase(
        dbPath,
        options: OpenDatabaseOptions(
          version: 13,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE location_tracks (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                timestamp TEXT NOT NULL,
                latitude REAL NOT NULL,
                longitude REAL NOT NULL,
                accuracy REAL,
                altitude REAL,
                speed REAL,
                activity TEXT,
                synced INTEGER DEFAULT 0,
                created_at TEXT DEFAULT CURRENT_TIMESTAMP
              )
            ''');
          },
        ),
      );
      // The same fix stored twice (e.g. by the old double-subscription bug).
      for (final lat in [45.0, 45.0, 46.0]) {
        await legacy.insert('location_tracks', {
          'timestamp': lat == 46.0
              ? '2026-07-01T09:00:00.000Z'
              : '2026-07-01T08:00:00.000Z',
          'latitude': lat,
          'longitude': 12.0,
        });
      }
      await legacy.close();

      final db = SurveyDatabase();
      final tracks = await db.getLocationTracksSince(DateTime.utc(2026, 1, 1));
      expect(tracks, hasLength(2), reason: 'duplicate collapsed to one row');

      // The unique index now makes repeats no-ops.
      expect(
        await db.insertLocationTracks([track('2026-07-01T08:00:00.000Z', 45.0)]),
        0,
      );
    });
  });
}
