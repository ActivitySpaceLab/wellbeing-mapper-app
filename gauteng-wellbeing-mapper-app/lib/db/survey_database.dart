import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/survey_models.dart';
import '../models/consent_models.dart';
import '../models/data_sharing_consent.dart';

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
      version: 10, // Fixed consent_responses schema inconsistencies
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
        suburb TEXT,
        building_type TEXT,
        household_items TEXT,
        education TEXT,
        climate_activism TEXT,
        general_health TEXT,
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
        research_site TEXT,
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
        encrypted_location_data TEXT,
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

    // Create wellbeing survey responses table
    await db.execute('''
      CREATE TABLE wellbeing_survey_responses (
        id TEXT PRIMARY KEY,
        timestamp TEXT NOT NULL,
        happiness_score REAL,
        latitude REAL,
        longitude REAL,
        accuracy REAL,
        location_timestamp TEXT,
        is_synced INTEGER DEFAULT 0
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

    // Create data sharing consent table
    await db.execute('''
      CREATE TABLE data_sharing_consent (
        id TEXT PRIMARY KEY,
        participant_uuid TEXT NOT NULL,
        location_sharing_option INTEGER NOT NULL,
        decision_timestamp TEXT NOT NULL,
        custom_location_ids TEXT,
        reason_for_partial_sharing TEXT,
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
    
    if (oldVersion < 3) {
      // Add wellbeing survey responses table
      await db.execute('''
        CREATE TABLE wellbeing_survey_responses (
          id TEXT PRIMARY KEY,
          timestamp TEXT NOT NULL,
          cheerful_spirits INTEGER NOT NULL,
          calm_relaxed INTEGER NOT NULL,
          active_vigorous INTEGER NOT NULL,
          woke_rested INTEGER NOT NULL,
          interesting_life INTEGER NOT NULL,
          is_synced INTEGER DEFAULT 0
        )
      ''');
    }
    
    if (oldVersion < 4) {
      // Add location fields to wellbeing survey responses table
      await db.execute('ALTER TABLE wellbeing_survey_responses ADD COLUMN latitude REAL');
      await db.execute('ALTER TABLE wellbeing_survey_responses ADD COLUMN longitude REAL');
      await db.execute('ALTER TABLE wellbeing_survey_responses ADD COLUMN accuracy REAL');
      await db.execute('ALTER TABLE wellbeing_survey_responses ADD COLUMN location_timestamp TEXT');
    }
    
    if (oldVersion < 5) {
      // Add data sharing consent table
      await db.execute('''
        CREATE TABLE data_sharing_consent (
          id TEXT PRIMARY KEY,
          participant_uuid TEXT NOT NULL,
          location_sharing_option INTEGER NOT NULL,
          decision_timestamp TEXT NOT NULL,
          custom_location_ids TEXT,
          reason_for_partial_sharing TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
    }
    
    if (oldVersion < 6) {
      // Migrate wellbeing survey responses to single happiness question
      // First backup existing data
      await db.execute('''
        CREATE TEMPORARY TABLE wellbeing_backup AS 
        SELECT * FROM wellbeing_survey_responses
      ''');
      
      // Drop old table
      await db.execute('DROP TABLE wellbeing_survey_responses');
      
      // Create new table with happiness_score field
      await db.execute('''
        CREATE TABLE wellbeing_survey_responses (
          id TEXT PRIMARY KEY,
          timestamp TEXT NOT NULL,
          happiness_score REAL,
          latitude REAL,
          longitude REAL,
          accuracy REAL,
          location_timestamp TEXT,
          is_synced INTEGER DEFAULT 0
        )
      ''');
      
      // Migrate existing data by calculating average happiness from old questions
      // This converts the old Yes/No questions to a 0-10 happiness scale
      await db.execute('''
        INSERT INTO wellbeing_survey_responses (
          id, timestamp, happiness_score, latitude, longitude, accuracy, location_timestamp, is_synced
        )
        SELECT 
          id, 
          timestamp,
          CASE 
            WHEN (COALESCE(cheerful_spirits, 0) + COALESCE(calm_relaxed, 0) + 
                  COALESCE(active_vigorous, 0) + COALESCE(woke_rested, 0) + 
                  COALESCE(interesting_life, 0)) > 0 
            THEN ((COALESCE(cheerful_spirits, 0) + COALESCE(calm_relaxed, 0) + 
                   COALESCE(active_vigorous, 0) + COALESCE(woke_rested, 0) + 
                   COALESCE(interesting_life, 0)) * 2.0) -- Scale 0-5 to 0-10
            ELSE NULL 
          END as happiness_score,
          latitude,
          longitude,
          accuracy,
          location_timestamp,
          is_synced
        FROM wellbeing_backup
      ''');
      
      // Drop backup table
      await db.execute('DROP TABLE wellbeing_backup');
    }
    
    if (oldVersion < 7) {
      // Add encrypted location data column to recurring survey responses
      await db.execute('ALTER TABLE recurring_survey_responses ADD COLUMN encrypted_location_data TEXT');
    }
    
    if (oldVersion < 8) {
      // Expand initial survey to include all biweekly questions for baseline measurement
      // First, backup existing data
      await db.execute('''
        CREATE TEMPORARY TABLE initial_survey_backup AS 
        SELECT * FROM initial_survey_responses
      ''');
      
      // Drop old table
      await db.execute('DROP TABLE initial_survey_responses');
      
      // Create new expanded table
      await db.execute('''
        CREATE TABLE initial_survey_responses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          age INTEGER,
          ethnicity TEXT,
          gender TEXT,
          sexuality TEXT,
          birth_place TEXT,
          lives_in_barcelona TEXT,
          suburb TEXT,
          building_type TEXT,
          household_items TEXT,
          education TEXT,
          climate_activism TEXT,
          general_health TEXT,
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
          research_site TEXT,
          submitted_at TEXT,
          synced INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      
      // Migrate existing data with default values for new fields
      await db.execute('''
        INSERT INTO initial_survey_responses (
          age, ethnicity, gender, sexuality, birth_place, lives_in_barcelona,
          building_type, household_items, education, climate_activism,
          submitted_at, synced, created_at, research_site
        )
        SELECT 
          age, ethnicity, gender, sexuality, birth_place, lives_in_barcelona,
          building_type, household_items, education, climate_activism,
          submitted_at, synced, created_at, 'gauteng'
        FROM initial_survey_backup
      ''');
      
      // Drop backup table
      await db.execute('DROP TABLE initial_survey_backup');
    }
    
    if (oldVersion < 9) {
      // Add Gauteng-specific consent fields to consent_responses table
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_participate INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_qualtrics_data INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_race_ethnicity INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_health INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_sexual_orientation INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_location_mobility INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_data_transfer INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_public_reporting INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_researcher_sharing INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_further_research INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_public_repository INTEGER DEFAULT 1');
      await db.execute('ALTER TABLE consent_responses ADD COLUMN consent_followup_contact INTEGER DEFAULT 0');
    }
    
    if (oldVersion < 10) {
      // Fix any schema inconsistencies with consent_responses table
      // Check if all required columns exist and add them if missing
      try {
        final List<Map<String, dynamic>> columns = await db.rawQuery("PRAGMA table_info(consent_responses)");
        final Set<String> existingColumns = columns.map((col) => col['name'] as String).toSet();
        
        final Map<String, String> requiredColumns = {
          'consent_participate': 'ALTER TABLE consent_responses ADD COLUMN consent_participate INTEGER DEFAULT 1',
          'consent_qualtrics_data': 'ALTER TABLE consent_responses ADD COLUMN consent_qualtrics_data INTEGER DEFAULT 1',
          'consent_race_ethnicity': 'ALTER TABLE consent_responses ADD COLUMN consent_race_ethnicity INTEGER DEFAULT 1',
          'consent_health': 'ALTER TABLE consent_responses ADD COLUMN consent_health INTEGER DEFAULT 1',
          'consent_sexual_orientation': 'ALTER TABLE consent_responses ADD COLUMN consent_sexual_orientation INTEGER DEFAULT 1',
          'consent_location_mobility': 'ALTER TABLE consent_responses ADD COLUMN consent_location_mobility INTEGER DEFAULT 1',
          'consent_data_transfer': 'ALTER TABLE consent_responses ADD COLUMN consent_data_transfer INTEGER DEFAULT 1',
          'consent_public_reporting': 'ALTER TABLE consent_responses ADD COLUMN consent_public_reporting INTEGER DEFAULT 1',
          'consent_researcher_sharing': 'ALTER TABLE consent_responses ADD COLUMN consent_researcher_sharing INTEGER DEFAULT 1',
          'consent_further_research': 'ALTER TABLE consent_responses ADD COLUMN consent_further_research INTEGER DEFAULT 1',
          'consent_public_repository': 'ALTER TABLE consent_responses ADD COLUMN consent_public_repository INTEGER DEFAULT 1',
          'consent_followup_contact': 'ALTER TABLE consent_responses ADD COLUMN consent_followup_contact INTEGER DEFAULT 0',
        };
        
        for (final entry in requiredColumns.entries) {
          if (!existingColumns.contains(entry.key)) {
            await db.execute(entry.value);
            print('[Database] Added missing column: ${entry.key}');
          }
        }
      } catch (e) {
        print('[Database] Error checking consent_responses schema: $e');
        // If there's an error, try to recreate the table
        await _recreateConsentResponsesTable(db);
      }
    }
  }
  
  Future<void> _recreateConsentResponsesTable(Database db) async {
    print('[Database] Recreating consent_responses table with correct schema');
    
    // Backup existing data
    List<Map<String, dynamic>> existingData = [];
    try {
      existingData = await db.query('consent_responses');
    } catch (e) {
      print('[Database] No existing consent data to backup: $e');
    }
    
    // Drop and recreate table
    await db.execute('DROP TABLE IF EXISTS consent_responses');
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
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        consent_participate INTEGER DEFAULT 1,
        consent_qualtrics_data INTEGER DEFAULT 1,
        consent_race_ethnicity INTEGER DEFAULT 1,
        consent_health INTEGER DEFAULT 1,
        consent_sexual_orientation INTEGER DEFAULT 1,
        consent_location_mobility INTEGER DEFAULT 1,
        consent_data_transfer INTEGER DEFAULT 1,
        consent_public_reporting INTEGER DEFAULT 1,
        consent_researcher_sharing INTEGER DEFAULT 1,
        consent_further_research INTEGER DEFAULT 1,
        consent_public_repository INTEGER DEFAULT 1,
        consent_followup_contact INTEGER DEFAULT 0
      )
    ''');
    
    // Restore data if any existed
    for (final row in existingData) {
      try {
        await db.insert('consent_responses', row);
      } catch (e) {
        print('[Database] Could not restore consent row: $e');
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
      'suburb': survey.suburb,
      'building_type': survey.buildingType,
      'household_items': jsonEncode(survey.householdItems),
      'education': survey.education,
      'climate_activism': survey.climateActivism,
      'general_health': survey.generalHealth,
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
      // TODO: MULTIMEDIA ENCRYPTION - Images are stored as local file paths, encryption to be implemented
      // 'voice_note_urls': survey.voiceNoteUrls != null ? jsonEncode(survey.voiceNoteUrls) : null,
      'image_urls': survey.imageUrls != null ? jsonEncode(survey.imageUrls) : null,
      'research_site': survey.researchSite,
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
        ethnicity: List<String>.from(jsonDecode(maps[i]['ethnicity'] as String? ?? '[]')),
        gender: maps[i]['gender'] as String?,
        sexuality: maps[i]['sexuality'] as String?,
        birthPlace: maps[i]['birth_place'] as String?,
        livesInBarcelona: maps[i]['lives_in_barcelona'] as String?,
        suburb: maps[i]['suburb'] as String?,
        buildingType: maps[i]['building_type'] as String?,
        householdItems: List<String>.from(jsonDecode(maps[i]['household_items'] as String? ?? '[]')),
        education: maps[i]['education'] as String?,
        climateActivism: maps[i]['climate_activism'] as String?,
        generalHealth: maps[i]['general_health'] as String?,
        activities: List<String>.from(jsonDecode(maps[i]['activities'] as String? ?? '[]')),
        livingArrangement: maps[i]['living_arrangement'] as String?,
        relationshipStatus: maps[i]['relationship_status'] as String?,
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
        // TODO: MULTIMEDIA ENCRYPTION - Images are stored as local file paths, encryption to be implemented
        // voiceNoteUrls: maps[i]['voice_note_urls'] != null ? List<String>.from(jsonDecode(maps[i]['voice_note_urls'] as String)) : null,
        imageUrls: maps[i]['image_urls'] != null ? List<String>.from(jsonDecode(maps[i]['image_urls'] as String)) : null,
        researchSite: maps[i]['research_site'] as String? ?? 'gauteng',
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
      // TODO: MULTIMEDIA ENCRYPTION - Images are stored as local file paths, encryption to be implemented
      // 'voice_note_urls': survey.voiceNoteUrls != null ? jsonEncode(survey.voiceNoteUrls) : null,
      'image_urls': survey.imageUrls != null ? jsonEncode(survey.imageUrls) : null,
      'submitted_at': survey.submittedAt.toIso8601String(),
      'encrypted_location_data': survey.encryptedLocationData,
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
        // TODO: MULTIMEDIA ENCRYPTION - Images are stored as local file paths, encryption to be implemented
        // voiceNoteUrls: maps[i]['voice_note_urls'] != null 
        //     ? List<String>.from(jsonDecode(maps[i]['voice_note_urls'] as String))
        //     : null,
        imageUrls: maps[i]['image_urls'] != null 
            ? List<String>.from(jsonDecode(maps[i]['image_urls'] as String))
            : null,
        researchSite: maps[i]['research_site'] as String? ?? 'gauteng',
        submittedAt: DateTime.parse(maps[i]['submitted_at'] as String),
        encryptedLocationData: maps[i]['encrypted_location_data'] as String?,
        synced: (maps[i]['synced'] as int? ?? 0) == 1,
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
    return result.first.values.first as int? ?? 0;
  }

  // Consent methods
  Future<int> insertConsent(ConsentResponse consent) async {
    final db = await database;
    
    try {
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
          // New Gauteng-specific consent fields
          'consent_participate': consent.consentParticipate ? 1 : 0,
          'consent_qualtrics_data': consent.consentQualtricsData ? 1 : 0,
          'consent_race_ethnicity': consent.consentRaceEthnicity ? 1 : 0,
          'consent_health': consent.consentHealth ? 1 : 0,
          'consent_sexual_orientation': consent.consentSexualOrientation ? 1 : 0,
          'consent_location_mobility': consent.consentLocationMobility ? 1 : 0,
          'consent_data_transfer': consent.consentDataTransfer ? 1 : 0,
          'consent_public_reporting': consent.consentPublicReporting ? 1 : 0,
          'consent_researcher_sharing': consent.consentResearcherSharing ? 1 : 0,
          'consent_further_research': consent.consentFurtherResearch ? 1 : 0,
          'consent_public_repository': consent.consentPublicRepository ? 1 : 0,
          'consent_followup_contact': consent.consentFollowupContact ? 1 : 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      print('[Database] Error inserting consent, attempting to fix schema: $e');
      
      // If the insert fails due to missing columns, recreate the table
      if (e.toString().contains('no column named') || e.toString().contains('SQLITE_ERROR')) {
        print('[Database] Recreating consent_responses table due to schema error');
        await _recreateConsentResponsesTable(db);
        
        // Retry the insert after fixing the schema
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
            // New Gauteng-specific consent fields
            'consent_participate': consent.consentParticipate ? 1 : 0,
            'consent_qualtrics_data': consent.consentQualtricsData ? 1 : 0,
            'consent_race_ethnicity': consent.consentRaceEthnicity ? 1 : 0,
            'consent_health': consent.consentHealth ? 1 : 0,
            'consent_sexual_orientation': consent.consentSexualOrientation ? 1 : 0,
            'consent_location_mobility': consent.consentLocationMobility ? 1 : 0,
            'consent_data_transfer': consent.consentDataTransfer ? 1 : 0,
            'consent_public_reporting': consent.consentPublicReporting ? 1 : 0,
            'consent_researcher_sharing': consent.consentResearcherSharing ? 1 : 0,
            'consent_further_research': consent.consentFurtherResearch ? 1 : 0,
            'consent_public_repository': consent.consentPublicRepository ? 1 : 0,
            'consent_followup_contact': consent.consentFollowupContact ? 1 : 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      } else {
        // Re-throw the error if it's not schema-related
        rethrow;
      }
    }
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

  // Data Sharing Consent Methods
  Future<int> insertDataSharingConsent(DataSharingConsent consent) async {
    final db = await database;
    return await db.insert(
      'data_sharing_consent',
      {
        'id': consent.id,
        'participant_uuid': consent.participantUuid,
        'location_sharing_option': consent.locationSharingOption.index,
        'decision_timestamp': consent.decisionTimestamp.toIso8601String(),
        'custom_location_ids': consent.customLocationIds != null 
            ? jsonEncode(consent.customLocationIds) 
            : null,
        'reason_for_partial_sharing': consent.reasonForPartialSharing,
      },
    );
  }

  Future<DataSharingConsent?> getLatestDataSharingConsent(String participantUuid) async {
    final db = await database;
    final result = await db.query(
      'data_sharing_consent',
      where: 'participant_uuid = ?',
      whereArgs: [participantUuid],
      orderBy: 'decision_timestamp DESC',
      limit: 1,
    );

    if (result.isNotEmpty) {
      final map = result.first;
      return DataSharingConsent(
        id: map['id'] as String,
        participantUuid: map['participant_uuid'] as String,
        locationSharingOption: LocationSharingOption.values[map['location_sharing_option'] as int],
        decisionTimestamp: DateTime.parse(map['decision_timestamp'] as String),
        customLocationIds: map['custom_location_ids'] != null
            ? List<String>.from(jsonDecode(map['custom_location_ids'] as String))
            : null,
        reasonForPartialSharing: map['reason_for_partial_sharing'] as String?,
      );
    }
    return null;
  }

  Future<List<DataSharingConsent>> getAllDataSharingConsents(String participantUuid) async {
    final db = await database;
    final maps = await db.query(
      'data_sharing_consent',
      where: 'participant_uuid = ?',
      whereArgs: [participantUuid],
      orderBy: 'decision_timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      final map = maps[i];
      return DataSharingConsent(
        id: map['id'] as String,
        participantUuid: map['participant_uuid'] as String,
        locationSharingOption: LocationSharingOption.values[map['location_sharing_option'] as int],
        decisionTimestamp: DateTime.parse(map['decision_timestamp'] as String),
        customLocationIds: map['custom_location_ids'] != null
            ? List<String>.from(jsonDecode(map['custom_location_ids'] as String))
            : null,
        reasonForPartialSharing: map['reason_for_partial_sharing'] as String?,
      );
    });
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }

  // Methods for Qualtrics API sync
  Future<List<Map<String, dynamic>>> getUnsyncedInitialSurveys() async {
    final db = await database;
    return await db.query(
      'initial_survey_responses', 
      where: 'synced = ?', 
      whereArgs: [0],
      orderBy: 'submitted_at ASC'
    );
  }

  Future<List<Map<String, dynamic>>> getUnsyncedRecurringSurveys() async {
    final db = await database;
    return await db.query(
      'recurring_survey_responses', 
      where: 'synced = ?', 
      whereArgs: [0],
      orderBy: 'submitted_at ASC'
    );
  }

  Future<void> markInitialSurveySynced(int surveyId) async {
    await markSurveyAsSynced('initial_survey_responses', surveyId);
  }

  Future<void> markRecurringSurveySynced(int surveyId) async {
    await markSurveyAsSynced('recurring_survey_responses', surveyId);
  }

  Future<List<Map<String, dynamic>>> getUnsyncedConsentForms() async {
    final db = await database;
    return await db.query(
      'consent_responses',
      where: 'synced = 0',
      orderBy: 'consented_at ASC'
    );
  }

  Future<void> markConsentFormSynced(int consentId) async {
    await markSurveyAsSynced('consent_responses', consentId);
  }

  // Location data management methods
  Future<void> cleanupOldLocationData(DateTime cutoffDate) async {
    final db = await database;
    final cutoffTimestamp = cutoffDate.millisecondsSinceEpoch.toString();
    
    print('[SurveyDatabase] Cleaning up location data older than $cutoffDate');
    
    try {
      // Clean up location tracks table
      int tracksDeleted = await db.delete(
        'location_tracks',
        where: 'timestamp < ?',
        whereArgs: [cutoffTimestamp]
      );
      
      print('[SurveyDatabase] Deleted $tracksDeleted old location tracks');
      
    } catch (e) {
      print('[SurveyDatabase] Error during location data cleanup: $e');
    }
  }

  Future<Map<String, dynamic>> getLocationDataStats() async {
    final db = await database;
    final stats = <String, dynamic>{};
    
    try {
      // Get location tracks count
      final tracksResult = await db.rawQuery('SELECT COUNT(*) as count FROM location_tracks');
      stats['totalLocationTracks'] = tracksResult.first['count'] as int? ?? 0;
      
      // Get oldest and newest location tracks
      final oldestResult = await db.rawQuery(
        'SELECT MIN(timestamp) as oldest FROM location_tracks WHERE timestamp IS NOT NULL'
      );
      final newestResult = await db.rawQuery(
        'SELECT MAX(timestamp) as newest FROM location_tracks WHERE timestamp IS NOT NULL'
      );
      
      final oldestTimestamp = oldestResult.first['oldest'];
      final newestTimestamp = newestResult.first['newest'];
      
      if (oldestTimestamp != null) {
        // Handle different timestamp formats safely
        int? timestampInt;
        if (oldestTimestamp is int) {
          timestampInt = oldestTimestamp;
        } else if (oldestTimestamp is String) {
          timestampInt = int.tryParse(oldestTimestamp);
        } else if (oldestTimestamp is double) {
          timestampInt = oldestTimestamp.toInt();
        }
        
        if (timestampInt != null) {
          stats['oldestLocationDate'] = DateTime.fromMillisecondsSinceEpoch(timestampInt);
        }
      }
      
      if (newestTimestamp != null) {
        // Handle different timestamp formats safely
        int? timestampInt;
        if (newestTimestamp is int) {
          timestampInt = newestTimestamp;
        } else if (newestTimestamp is String) {
          timestampInt = int.tryParse(newestTimestamp);
        } else if (newestTimestamp is double) {
          timestampInt = newestTimestamp.toInt();
        }
        
        if (timestampInt != null) {
          stats['newestLocationDate'] = DateTime.fromMillisecondsSinceEpoch(timestampInt);
        }
      }
      
      // Calculate data span in days
      if (stats['oldestLocationDate'] != null && stats['newestLocationDate'] != null) {
        stats['locationDataSpanDays'] = (stats['newestLocationDate'] as DateTime)
            .difference(stats['oldestLocationDate'] as DateTime)
            .inDays;
      }
      
    } catch (e) {
      print('[SurveyDatabase] Error getting location data stats: $e');
      stats['error'] = e.toString();
    }
    
    return stats;
  }
}
