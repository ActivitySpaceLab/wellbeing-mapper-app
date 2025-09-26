import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/db/survey_database.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'dart:convert';

/// Service to handle universal fresh start migration for ALL users
/// 
/// This service ensures that ALL users (existing and new) go through the
/// new consent process and start fresh with surveys, while preserving
/// their personal location data for continued personal use.
/// 
/// Universal Fresh Start Migration:
/// - Preserves location data for personal use
/// - Clears ALL consent responses (everyone must re-consent)
/// - Clears ALL initial survey responses (everyone must retake)
/// - Clears ALL biweekly survey responses (fresh research start)
/// - Resets onboarding flags to force new consent flow
/// - No version-based logic - everyone gets same treatment
class FreshStartMigrationService {
  static const String _appVersionKey = 'app_version';
  static const String _freshStartCompletedKey = 'fresh_start_migration_completed';
  static const String _preservedDataKey = 'preserved_user_data';
  
  /// Check if fresh start migration needs to be performed
  /// Returns true if migration is needed, false if already completed
  static Future<bool> needsFreshStartMigration() async {
    final prefs = await SharedPreferences.getInstance();
    
    print('[FreshStartMigration] Checking if fresh start migration is needed...');
    
    // Check if this specific fresh start migration was already completed
    final migrationCompleted = prefs.getBool(_freshStartCompletedKey) ?? false;
    print('[FreshStartMigration] Fresh start migration completed: $migrationCompleted');
    
    if (migrationCompleted) {
      print('[FreshStartMigration] Fresh start migration already completed');
      return false;
    }
    
    // IMPORTANT: Don't run migration if user is currently in active research mode
    // This prevents clearing their state if the app crashes and restarts
    final currentAppMode = prefs.getString('app_mode');
    final consentCompleted = prefs.getBool('consent_completed') ?? false;
    
    if (currentAppMode == 'research' && consentCompleted) {
      print('[FreshStartMigration] User is actively using research mode - marking migration as complete to preserve state');
      // Mark migration as completed to prevent future runs
      await prefs.setBool(_freshStartCompletedKey, true);
      return false;
    }
    
    // Migration needed - either fresh install or existing user who hasn't set up research mode
    final previousVersion = prefs.getString(_appVersionKey);
    if (previousVersion == null) {
      print('[FreshStartMigration] Fresh install - will perform fresh start setup');
    } else {
      print('[FreshStartMigration] Existing user ($previousVersion) - will perform fresh start migration');
    }
    
    return true;
  }
  
  /// Execute universal fresh start migration for ALL users
  /// This ensures everyone goes through the new consent process
  static Future<void> executeFreshStartMigration() async {
    final prefs = await SharedPreferences.getInstance();
    
    try {
      print('[FreshStartMigration] Starting universal fresh start migration...');
      
      // 1. Preserve location data for continued personal use
      await _preserveLocationData();
      
      // 2. Clear ALL research participation data (no exceptions)
      await _clearAllResearchData();
      
      // 3. Reset ALL onboarding flags to force new consent flow
      await _resetAllOnboardingFlags();
      
      // 4. Mark this fresh start migration as completed
      await prefs.setBool(_freshStartCompletedKey, true);
      await _recordMigrationCompletion();
      
      print('[FreshStartMigration] ✅ Fresh start migration completed successfully');
      print('[FreshStartMigration] All users will now go through new consent process');
      
    } catch (e) {
      print('[FreshStartMigration] ❌ Error during fresh start migration: $e');
      throw MigrationException('Failed to perform fresh start migration: $e');
    }
  }
  
  /// Get preserved data summary for user information
  static Future<Map<String, dynamic>?> getPreservedDataSummary() async {
    final prefs = await SharedPreferences.getInstance();
    final preservedDataJson = prefs.getString(_preservedDataKey);
    
    if (preservedDataJson != null) {
      return jsonDecode(preservedDataJson);
    }
    return null;
  }
  
  /// Clear migration flags for testing/debugging
  static Future<void> resetMigrationFlags() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_freshStartCompletedKey);
    await prefs.remove(_preservedDataKey);
    print('[FreshStartMigration] ✅ Reset migration flags - will trigger fresh start migration on next app launch');
  }
  
  // Private helper methods
  
  /// Preserve location data for personal use
  static Future<void> _preserveLocationData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Count location data to inform user what's being preserved
    final locationCount = await _getLocationDataCount();
    final earliestLocation = await _getEarliestLocationDate();
    
    final preservedData = {
      'migrationDate': DateTime.now().toIso8601String(),
      'migrationType': 'fresh_start_universal',
      'locationRecords': locationCount,
      'earliestLocationDate': earliestLocation?.toIso8601String(),
      'preservationNote': 'Your personal location history has been preserved for continued personal use. All research data has been cleared to ensure you go through the new consent process.',
    };
    
    await prefs.setString(_preservedDataKey, jsonEncode(preservedData));
    print('[FreshStartMigration] Preserved $locationCount location records for personal use');
  }
  
  /// Clear ALL research-related data (consent, surveys, settings)
  static Future<void> _clearAllResearchData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Clear all research participation settings
    await prefs.remove('participation_settings');
    await prefs.remove('consent_response');
    await prefs.remove('participant_code');
    await prefs.remove('researcher_contact');
    
    // PRESERVE app_mode if user has already successfully set up research mode
    // Only clear app_mode for users who haven't properly configured research participation
    final currentAppMode = prefs.getString('app_mode');
    final consentCompleted = prefs.getBool('consent_completed') ?? false;
    
    if (currentAppMode != 'research' || !consentCompleted) {
      // Clear app mode only if user hasn't successfully set up research mode
      await prefs.remove('app_mode');
      print('[FreshStartMigration] Cleared app_mode (user had not completed research setup)');
    } else {
      print('[FreshStartMigration] Preserved app_mode (user had completed research setup)');
    }
    
    // Clear ALL survey responses from database
    final db = SurveyDatabase();
    await db._clearAllSurveyData();
    
    print('[FreshStartMigration] Cleared research participation data and surveys');
  }
  
  /// Reset ALL onboarding flags to force complete re-onboarding
  static Future<void> _resetAllOnboardingFlags() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Remove all onboarding completion flags
    await prefs.remove('first_run_completed');
    await prefs.remove('onboarding_completed');
    await prefs.remove('setup_completed');
    await prefs.remove('consent_completed');
    await prefs.remove('initial_survey_completed');
    
    // Remove any tutorial or intro flags
    await prefs.remove('tutorial_shown');
    await prefs.remove('intro_seen');
    
    print('[FreshStartMigration] Reset ALL onboarding flags - users will see complete onboarding flow');
  }
  
  /// Record that this migration has completed
  static Future<void> _recordMigrationCompletion() async {
    final prefs = await SharedPreferences.getInstance();
    final completionDate = DateTime.now().toIso8601String();
    await prefs.setString(_appVersionKey, 'fresh_start_completed_$completionDate');
    print('[FreshStartMigration] Recorded migration completion at: $completionDate');
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

/// Extension to SurveyDatabase for fresh start migration operations
extension FreshStartMigrationDatabase on SurveyDatabase {
  /// Clear ALL survey data for fresh start (both research and personal)
  Future<void> _clearAllSurveyData() async {
    final db = await database;
    
    // Clear ALL survey responses - fresh start for everyone
    await db.delete('initial_survey_responses');
    await db.delete('recurring_survey_responses'); // This includes biweekly/happiness surveys
    await db.delete('consent_responses');
    await db.delete('data_sharing_consent');
    
    // Clear any other survey-related tables
    await db.delete('survey_metadata');
    await db.delete('survey_schedule');
    
    print('[FreshStartMigration] Cleared ALL survey data - complete fresh start');
  }
}

/// Status of migration process
enum MigrationStatus {
  freshInstall,       // Brand new user (still relevant for initial setup)
  migrationNeeded,    // User needs fresh start migration
  completed,          // Fresh start migration already completed
}

/// Exception thrown during migration
class MigrationException implements Exception {
  final String message;
  MigrationException(this.message);
  
  @override
  String toString() => 'MigrationException: $message';
}