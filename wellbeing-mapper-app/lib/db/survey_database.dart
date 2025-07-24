import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/survey_models.dart';
import '../models/consent_models.dart';
import '../services/data_upload_service.dart';

class SurveyDatabase {
  static final SurveyDatabase _instance = SurveyDatabase._internal();
  factory SurveyDatabase() => _instance;
  SurveyDatabase._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'survey_database.db');
    return await openDatabase(
      path,
      version: 2, // Bumped version to trigger migration
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create consent responses table
    await db.execute('''
      CREATE TABLE consent_responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        participant_uuid TEXT NOT NULL UNIQUE,
        informed_consent INTEGER NOT NULL,
        data_processing INTEGER NOT NULL,
        location_data INTEGER NOT NULL,
        survey_data INTEGER NOT NULL,
        data_retention INTEGER NOT NULL,
        data_sharing INTEGER NOT NULL,
        voluntary_participation INTEGER NOT NULL,
        consented_at TEXT NOT NULL,
        participant_signature TEXT NOT NULL,
        synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create initial survey responses table
    await db.execute('''
      CREATE TABLE initial_survey_responses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        age INTEGER,
        ethnicity TEXT,
        gender TEXT,
        sexuality TEXT,
        birth_place TEXT,
        lives_in_barcelona TEXT,
        building_type TEXT,
        household_items TEXT,
        education TEXT,
        climate_activism TEXT,
        submitted_at TEXT,
        synced INTEGER DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create recurring survey responses table
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
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Create location tracks table
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

    // Create sync queue table for offline functionality
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
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Migrate consent_responses table to new schema
      // First, check if the table exists and if it has the old structure
      final List<Map<String, dynamic>> tableInfo = await db.rawQuery(
        "PRAGMA table_info(consent_responses)"
      );
      
      // Check if table has old column names
      bool hasOldSchema = tableInfo.any((column) => column['name'] == 'participant_code');
      
      if (hasOldSchema) {
        // Create new table with correct schema
        await db.execute('''
          CREATE TABLE consent_responses_new (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            participant_uuid TEXT NOT NULL UNIQUE,
            informed_consent INTEGER NOT NULL,
            data_processing INTEGER NOT NULL,
            location_data INTEGER NOT NULL,
            survey_data INTEGER NOT NULL,
            data_retention INTEGER NOT NULL,
            data_sharing INTEGER NOT NULL,
            voluntary_participation INTEGER NOT NULL,
            consented_at TEXT NOT NULL,
            participant_signature TEXT NOT NULL,
            synced INTEGER DEFAULT 0,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');
        
        // Migrate data from old table to new table (mapping old columns to new ones)
        await db.execute('''
          INSERT INTO consent_responses_new (
            participant_uuid, informed_consent, data_processing, location_data,
            survey_data, data_retention, data_sharing, voluntary_participation,
            consented_at, participant_signature, synced, created_at
          )
          SELECT 
            participant_uuid,
            has_read_information,
            general_consent,
            location_consent,
            general_consent,
            general_consent,
            data_transfer_consent,
            voluntary_participation,
            consented_at,
            participant_code,
            synced,
            created_at
          FROM consent_responses
        ''');
        
        // Drop old table and rename new table
        await db.execute('DROP TABLE consent_responses');
        await db.execute('ALTER TABLE consent_responses_new RENAME TO consent_responses');
      }
    }
  }

  // Initial Survey Methods
  Future<int> insertInitialSurvey(InitialSurveyResponse survey) async {
    final db = await database;
    final id = await db.insert('initial_survey_responses', {
      'age': survey.age,
      'ethnicity': jsonEncode(survey.ethnicity),
      'gender': survey.gender,
      'sexuality': survey.sexuality,
      'birth_place': survey.birthPlace,
      'lives_in_barcelona': survey.livesInBarcelona,
      'building_type': survey.buildingType,
      'household_items': jsonEncode(survey.householdItems),
      'education': survey.education,
      'climate_activism': survey.climateActivism,
      'submitted_at': survey.submittedAt.toIso8601String(),
    });

    // Add to sync queue
    await _addToSyncQueue('initial_survey_responses', id, 'INSERT', survey.toJson());
    return id;
  }

  Future<List<InitialSurveyResponse>> getInitialSurveys() async {
    final db = await database;
    final maps = await db.query('initial_survey_responses', orderBy: 'submitted_at DESC');
    
    return List.generate(maps.length, (i) {
      return InitialSurveyResponse(
        age: maps[i]['age'] as int?,
        ethnicity: List<String>.from(jsonDecode(maps[i]['ethnicity'] as String)),
        gender: maps[i]['gender'] as String?,
        sexuality: maps[i]['sexuality'] as String?,
        birthPlace: maps[i]['birth_place'] as String?,
        livesInBarcelona: maps[i]['lives_in_barcelona'] as String?,
        suburb: maps[i]['suburb'] as String?,
        buildingType: maps[i]['building_type'] as String?,
        householdItems: List<String>.from(jsonDecode(maps[i]['household_items'] as String)),
        education: maps[i]['education'] as String?,
        climateActivism: maps[i]['climate_activism'] as String?,
        generalHealth: maps[i]['general_health'] as String?,
        researchSite: maps[i]['research_site'] as String? ?? 'barcelona',
        submittedAt: DateTime.parse(maps[i]['submitted_at'] as String),
      );
    });
  }

  // Recurring Survey Methods
  Future<int> insertRecurringSurvey(RecurringSurveyResponse survey) async {
    final db = await database;
    final id = await db.insert('recurring_survey_responses', {
      'activities': jsonEncode(survey.activities),
      'living_arrangement': survey.livingArrangement,
      'relationship_status': survey.relationshipStatus,
      'cheerful_spirits': survey.cheerfulSpirits,
      'calm_relaxed': survey.calmRelaxed,
      'active_vigorous': survey.activeVigorous,
      'woke_up_fresh': survey.wokeUpFresh,
      'daily_life_interesting': survey.dailyLifeInteresting,
      'cooperate_with_people': survey.cooperateWithPeople,
      'improving_skills': survey.improvingSkills,
      'social_situations': survey.socialSituations,
      'family_support': survey.familySupport,
      'family_knows_me': survey.familyKnowsMe,
      'access_to_food': survey.accessToFood,
      'people_enjoy_time': survey.peopleEnjoyTime,
      'talk_to_family': survey.talkToFamily,
      'friends_support': survey.friendsSupport,
      'belong_in_community': survey.belongInCommunity,
      'family_stands_by_me': survey.familyStandsByMe,
      'friends_stand_by_me': survey.friendsStandByMe,
      'treated_fairly': survey.treatedFairly,
      'opportunities_responsibility': survey.opportunitiesResponsibility,
      'secure_with_family': survey.secureWithFamily,
      'opportunities_abilities': survey.opportunitiesAbilities,
      'enjoy_cultural_traditions': survey.enjoyCulturalTraditions,
      'environmental_challenges': survey.environmentalChallenges,
      'challenges_stress_level': survey.challengesStressLevel,
      'coping_help': survey.copingHelp,
      'voice_note_urls': survey.voiceNoteUrls != null ? jsonEncode(survey.voiceNoteUrls) : null,
      'image_urls': survey.imageUrls != null ? jsonEncode(survey.imageUrls) : null,
      'submitted_at': survey.submittedAt.toIso8601String(),
    });

    // Add to sync queue
    await _addToSyncQueue('recurring_survey_responses', id, 'INSERT', survey.toJson());
    return id;
  }

  Future<List<RecurringSurveyResponse>> getRecurringSurveys() async {
    final db = await database;
    final maps = await db.query('recurring_survey_responses', orderBy: 'submitted_at DESC');
    
    return List.generate(maps.length, (i) {
      return RecurringSurveyResponse(
        activities: List<String>.from(jsonDecode(maps[i]['activities'] as String)),
        livingArrangement: maps[i]['living_arrangement'] as String?,
        relationshipStatus: maps[i]['relationship_status'] as String?,
        generalHealth: maps[i]['general_health'] as String?,
        cheerfulSpirits: maps[i]['cheerful_spirits'] as int?,
        calmRelaxed: maps[i]['calm_relaxed'] as int?,
        activeVigorous: maps[i]['active_vigorous'] as int?,
        wokeUpFresh: maps[i]['woke_up_fresh'] as int?,
        dailyLifeInteresting: maps[i]['daily_life_interesting'] as int?,
        cooperateWithPeople: maps[i]['cooperate_with_people'] as int?,
        improvingSkills: maps[i]['improving_skills'] as int?,
        socialSituations: maps[i]['social_situations'] as int?,
        familySupport: maps[i]['family_support'] as int?,
        familyKnowsMe: maps[i]['family_knows_me'] as int?,
        accessToFood: maps[i]['access_to_food'] as int?,
        peopleEnjoyTime: maps[i]['people_enjoy_time'] as int?,
        talkToFamily: maps[i]['talk_to_family'] as int?,
        friendsSupport: maps[i]['friends_support'] as int?,
        belongInCommunity: maps[i]['belong_in_community'] as int?,
        familyStandsByMe: maps[i]['family_stands_by_me'] as int?,
        friendsStandByMe: maps[i]['friends_stand_by_me'] as int?,
        treatedFairly: maps[i]['treated_fairly'] as int?,
        opportunitiesResponsibility: maps[i]['opportunities_responsibility'] as int?,
        secureWithFamily: maps[i]['secure_with_family'] as int?,
        opportunitiesAbilities: maps[i]['opportunities_abilities'] as int?,
        enjoyCulturalTraditions: maps[i]['enjoy_cultural_traditions'] as int?,
        environmentalChallenges: maps[i]['environmental_challenges'] as String?,
        challengesStressLevel: maps[i]['challenges_stress_level'] as String?,
        copingHelp: maps[i]['coping_help'] as String?,
        voiceNoteUrls: maps[i]['voice_note_urls'] != null 
            ? List<String>.from(jsonDecode(maps[i]['voice_note_urls'] as String))
            : null,
        imageUrls: maps[i]['image_urls'] != null 
            ? List<String>.from(jsonDecode(maps[i]['image_urls'] as String))
            : null,
        researchSite: maps[i]['research_site'] as String? ?? 'barcelona',
        submittedAt: DateTime.parse(maps[i]['submitted_at'] as String),
      );
    });
  }

  // Sync functionality
  Future<void> _addToSyncQueue(String tableName, int recordId, String action, Map<String, dynamic> data) async {
    final db = await database;
    await db.insert('sync_queue', {
      'table_name': tableName,
      'record_id': recordId,
      'action': action,
      'data': jsonEncode(data),
    });
  }

  Future<List<Map<String, dynamic>>> getPendingSyncItems() async {
    final db = await database;
    return await db.query('sync_queue', orderBy: 'created_at ASC');
  }

  Future<void> markSynced(int syncId) async {
    final db = await database;
    await db.delete('sync_queue', where: 'id = ?', whereArgs: [syncId]);
  }

  Future<void> markSurveyAsSynced(String tableName, int recordId) async {
    final db = await database;
    await db.update(
      tableName,
      {'synced': 1},
      where: 'id = ?',
      whereArgs: [recordId],
    );
  }

  // Utility methods
  Future<bool> hasCompletedInitialSurvey() async {
    final db = await database;
    final result = await db.query('initial_survey_responses', limit: 1);
    return result.isNotEmpty;
  }

  Future<DateTime?> getLastRecurringSurveyDate() async {
    final db = await database;
    final result = await db.query(
      'recurring_survey_responses',
      orderBy: 'submitted_at DESC',
      limit: 1,
    );
    
    if (result.isNotEmpty) {
      return DateTime.parse(result.first['submitted_at'] as String);
    }
    return null;
  }

  Future<int> getRecurringSurveyCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) FROM recurring_survey_responses');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Consent methods
  Future<int> insertConsent(ConsentResponse consent) async {
    final db = await database;
    return await db.insert(
      'consent_responses',
      {
        'participant_uuid': consent.participantUuid,
        'informed_consent': consent.informedConsent ? 1 : 0,
        'data_processing': consent.dataProcessing ? 1 : 0,
        'location_data': consent.locationData ? 1 : 0,
        'survey_data': consent.surveyData ? 1 : 0,
        'data_retention': consent.dataRetention ? 1 : 0,
        'data_sharing': consent.dataSharing ? 1 : 0,
        'voluntary_participation': consent.voluntaryParticipation ? 1 : 0,
        'consented_at': consent.consentedAt.toIso8601String(),
        'participant_signature': consent.participantSignature,
        'synced': 0,
      },
    );
  }

  Future<ConsentResponse?> getConsent() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'consent_responses',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    
    if (maps.isNotEmpty) {
      final map = maps.first;
      return ConsentResponse(
        participantUuid: map['participant_uuid'],
        informedConsent: map['informed_consent'] == 1,
        dataProcessing: map['data_processing'] == 1,
        locationData: map['location_data'] == 1,
        surveyData: map['survey_data'] == 1,
        dataRetention: map['data_retention'] == 1,
        dataSharing: map['data_sharing'] == 1,
        voluntaryParticipation: map['voluntary_participation'] == 1,
        consentedAt: DateTime.parse(map['consented_at']),
        participantSignature: map['participant_signature'] ?? '',
      );
    }
    return null;
  }

  // Location Tracking Methods
  Future<int> insertLocationTrack(Map<String, dynamic> locationData) async {
    final db = await database;
    final id = await db.insert('location_tracks', {
      'timestamp': locationData['timestamp'] ?? DateTime.now().toIso8601String(),
      'latitude': locationData['latitude'],
      'longitude': locationData['longitude'],
      'accuracy': locationData['accuracy'],
      'altitude': locationData['altitude'],
      'speed': locationData['speed'],
      'activity': locationData['activity'],
    });

    return id;
  }

  Future<List<LocationTrack>> getLocationTracksSince(DateTime since) async {
    final db = await database;
    final maps = await db.query(
      'location_tracks',
      where: 'timestamp >= ?',
      whereArgs: [since.toIso8601String()],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) {
      return LocationTrack(
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
        latitude: maps[i]['latitude'] as double,
        longitude: maps[i]['longitude'] as double,
        accuracy: maps[i]['accuracy'] as double?,
        altitude: maps[i]['altitude'] as double?,
        speed: maps[i]['speed'] as double?,
        activity: maps[i]['activity'] as String?,
      );
    });
  }

  Future<List<LocationTrack>> getAllLocationTracks() async {
    final db = await database;
    final maps = await db.query('location_tracks', orderBy: 'timestamp DESC');

    return List.generate(maps.length, (i) {
      return LocationTrack(
        timestamp: DateTime.parse(maps[i]['timestamp'] as String),
        latitude: maps[i]['latitude'] as double,
        longitude: maps[i]['longitude'] as double,
        accuracy: maps[i]['accuracy'] as double?,
        altitude: maps[i]['altitude'] as double?,
        speed: maps[i]['speed'] as double?,
        activity: maps[i]['activity'] as String?,
      );
    });
  }

  Future<void> markLocationTracksAsSynced(List<int> ids) async {
    final db = await database;
    await db.update(
      'location_tracks',
      {'synced': 1},
      where: 'id IN (${ids.map((_) => '?').join(',')})',
      whereArgs: ids,
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
