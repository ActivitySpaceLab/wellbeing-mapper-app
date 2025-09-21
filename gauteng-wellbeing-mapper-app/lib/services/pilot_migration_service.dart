import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/db/survey_database.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'dart:convert';

/// Service to handle migration from pre-production versions to production version
/// 
/// This service ensures that existing users can smoothly transition to the
/// production version (1.1.0+) while:
/// - Preserving their personal location data and happiness surveys
/// - Clearing old research participation data (forcing re-authentication)
/// - Requiring new participant codes, consent, and initial survey for research
/// - Maintaining seamless personal/private use of preserved data
/// 
/// Treats any version before 1.1.0 as pre-production (including pilot versions
/// 1.0.6 and below, and early production versions 1.0.7 and below)
class PilotMigrationService {
  static const String _appVersionKey = 'app_version';
  static const String _migrationCompletedKey = 'pilot_migration_completed';
  static const String _pilotUserFlagKey = 'is_pilot_user';
  static const String _preservedDataKey = 'preserved_pilot_data';
  
  /// Current production version - update this when releasing new versions
  static const String currentProductionVersion = '1.1.0+2134';
  
  /// Build number threshold for production - any build number below this needs migration
  static const int productionBuildThreshold = 2134;
  
  /// Check if this is a fresh install or an update from pilot
  static Future<MigrationStatus> checkMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    print('[PilotMigration] Checking migration status...');
    
    // Check if migration was already completed
    final migrationCompleted = prefs.getBool(_migrationCompletedKey) ?? false;
    print('[PilotMigration] Migration completed flag: $migrationCompleted');
    
    if (migrationCompleted) {
      print('[PilotMigration] Migration already completed - treating as production user');
      return MigrationStatus.completed;
    }
    
    // Check if this is a fresh install (no previous version recorded)
    final previousVersion = prefs.getString(_appVersionKey);
    print('[PilotMigration] Previous version: $previousVersion');
    print('[PilotMigration] Current version: $currentProductionVersion');
    
    if (previousVersion == null) {
      // Fresh install - record current version and proceed normally
      print('[PilotMigration] Fresh install detected');
      await _recordCurrentVersion();
      return MigrationStatus.freshInstall;
    }
    
    // Check if user is upgrading from pre-production version (build number < 2134)
    final isPilot = _isPilotVersion(previousVersion);
    print('[PilotMigration] Is pre-production version ($previousVersion): $isPilot');
    
    if (isPilot) {
      // This is a user upgrading from pre-production to production
      print('[PilotMigration] Pre-production user upgrade detected - migration required');
      await _markAsPilotUser();
      return MigrationStatus.pilotUpgrade;
    }
    
    // User is upgrading from a previous production version
    print('[PilotMigration] Production upgrade detected - no migration needed');
    await prefs.setBool(_migrationCompletedKey, true); // Mark migration as completed so it doesn't run again
    await _recordCurrentVersion();
    return MigrationStatus.productionUpgrade;
  }
  
  /// Execute migration for pilot users
  static Future<void> executePilotMigration() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      print('[PilotMigration] Starting pilot user migration...');
      
      // 1. Preserve location data and personal happiness surveys
      await _preservePersonalData();
      
      // 2. Clear research-related data (participation settings, consent, etc.)
      await _clearResearchData();
      
      // 3. Set app to require new onboarding for research participation
      await _resetOnboardingFlags();
      
      // 4. Mark migration as completed
      await prefs.setBool(_migrationCompletedKey, true);
      await _recordCurrentVersion();
      
      print('[PilotMigration] ✅ Pilot migration completed successfully');
      
    } catch (e) {
      print('[PilotMigration] ❌ Error during migration: $e');
      throw MigrationException('Failed to migrate pilot user data: $e');
    }
  }
  
  /// Check if user is a migrated pilot user
  static Future<bool> isPilotUser() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pilotUserFlagKey) ?? false;
  }
  
  /// Get preserved pilot data summary for user information
  static Future<Map<String, dynamic>?> getPreservedDataSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final preservedDataJson = prefs.getString(_preservedDataKey);
    
    if (preservedDataJson != null) {
      return jsonDecode(preservedDataJson);
    }
    return null;
  }
  
  /// Clear pilot user flag (for testing or manual reset)
  static Future<void> clearPilotFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pilotUserFlagKey);
    await prefs.remove(_preservedDataKey);
    await prefs.remove(_migrationCompletedKey);
    print('[PilotMigration] ✅ Cleared all migration flags - user will be treated as fresh install');
  }
  
  /// Mark current installation as production (for testing with new test codes)
  static Future<void> markAsProductionUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_migrationCompletedKey, true);
    await _recordCurrentVersion();
    await prefs.remove(_pilotUserFlagKey);
    await prefs.remove(_preservedDataKey);
    print('[PilotMigration] ✅ Marked as production user - future updates will not trigger migration');
  }
  
  // Private helper methods
  
  static bool _isPilotVersion(String version) {
    // Use build number for more reliable version comparison
    // Any build number below 2134 is considered pre-production and needs migration
    try {
      // Extract build number from version string (format: "1.0.7+132" -> 132)
      if (!version.contains('+')) {
        // No build number means very old version, definitely pre-production
        return true;
      }
      
      final buildNumberStr = version.split('+')[1];
      final buildNumber = int.tryParse(buildNumberStr);
      
      if (buildNumber == null) {
        // Invalid build number, treat as pre-production for safety
        return true;
      }
      
      return buildNumber < productionBuildThreshold;
    } catch (e) {
      // Any parsing error means we can't determine version safely, treat as pre-production
      print('[PilotMigration] Error parsing version "$version": $e');
      return true;
    }
  }
  
  static Future<void> _recordCurrentVersion() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_appVersionKey, currentProductionVersion);
  }
  
  static Future<void> _markAsPilotUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pilotUserFlagKey, true);
  }
  
  static Future<void> _preservePersonalData() async {
    final prefs = await SharedPreferences.getInstance();
    final db = SurveyDatabase();
    
    // Count and preserve location data and happiness surveys
    final locationCount = await _getLocationDataCount();
    final happinessCount = await db.getRecurringSurveyCount();
    final earliestLocation = await _getEarliestLocationDate();
    final latestHappiness = await db.getLastRecurringSurveyDate();
    
    final preservedData = {
      'migrationDate': DateTime.now().toIso8601String(),
      'locationRecords': locationCount,
      'happinessSurveys': happinessCount,
      'earliestLocationDate': earliestLocation?.toIso8601String(),
      'latestHappinessDate': latestHappiness?.toIso8601String(),
      'preservationNote': 'Your personal location tracks and happiness surveys have been preserved for your continued personal use.',
    };
    
    await prefs.setString(_preservedDataKey, jsonEncode(preservedData));
    print('[PilotMigration] Preserved $locationCount location records and $happinessCount happiness surveys');
  }
  
  static Future<void> _clearResearchData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear research participation settings
    await prefs.remove('participation_settings');
    await prefs.remove('consent_response');
    
    // Clear app mode (will default to private)
    await prefs.remove('app_mode');
    
    // Clear any research-specific survey responses (but keep happiness surveys)
    final db = SurveyDatabase();
    await db._clearResearchSurveys();
    
    print('[PilotMigration] Cleared research participation data');
  }
  
  static Future<void> _resetOnboardingFlags() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove any "first run" or "onboarding completed" flags
    // This will force users to go through participation selection again
    await prefs.remove('first_run_completed');
    await prefs.remove('onboarding_completed');
    await prefs.remove('setup_completed');
    
    print('[PilotMigration] Reset onboarding flags - user will see participation selection');
  }
  
  static Future<int> _getLocationDataCount() async {
    try {
      // Get all location data from flutter_background_geolocation
      final allLocations = await bg.BackgroundGeolocation.locations;
      print('[PilotMigration] Found ${allLocations.length} location records to preserve');
      return allLocations.length;
    } catch (e) {
      print('[PilotMigration] Error getting location data count: $e');
      return 0;
    }
  }
  
  static Future<DateTime?> _getEarliestLocationDate() async {
    try {
      // Get all location data from flutter_background_geolocation
      final allLocations = await bg.BackgroundGeolocation.locations;
      
      if (allLocations.isEmpty) {
        print('[PilotMigration] No location data found');
        return null;
      }
      
      // Find the earliest timestamp
      DateTime? earliest;
      for (final location in allLocations) {
        final locationDate = DateTime.fromMillisecondsSinceEpoch(location.timestamp.toInt());
        if (earliest == null || locationDate.isBefore(earliest)) {
          earliest = locationDate;
        }
      }
      
      print('[PilotMigration] Earliest location data: $earliest');
      return earliest;
    } catch (e) {
      print('[PilotMigration] Error getting earliest location date: $e');
      return null;
    }
  }
}

/// Extension to SurveyDatabase for migration-specific operations
extension MigrationDatabase on SurveyDatabase {
  /// Clear research-specific surveys while preserving personal happiness surveys
  Future<void> _clearResearchSurveys() async {
    final db = await database;
    
    // Clear initial survey responses (research participants will retake)
    await db.delete('initial_survey_responses');
    
    // Clear consent responses (research participants will re-consent)
    await db.delete('consent_responses');
    
    // Clear data sharing consent (research participants will re-decide)
    await db.delete('data_sharing_consent');
    
    // NOTE: We keep recurring_survey_responses (happiness surveys) for personal use
    
    print('[PilotMigration] Cleared research survey data, preserved happiness surveys');
  }
}

/// Status of migration process
enum MigrationStatus {
  freshInstall,       // Brand new user
  pilotUpgrade,       // Pilot user upgrading to production
  productionUpgrade,  // Production user upgrading to newer version
  completed,          // Migration already completed
}

/// Exception thrown during migration
class MigrationException implements Exception {
  final String message;
  MigrationException(this.message);
  
  @override
  String toString() => 'MigrationException: $message';
}