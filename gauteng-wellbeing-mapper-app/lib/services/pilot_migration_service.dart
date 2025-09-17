import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/db/survey_database.dart';
import 'dart:convert';

/// Service to handle migration from pilot version to production version
/// 
/// This service ensures that existing pilot users can smoothly transition to the
/// production version while:
/// - Preserving their personal location data and happiness surveys
/// - Clearing old research participation data (forcing re-authentication)
/// - Requiring new participant codes, consent, and initial survey for research
/// - Maintaining seamless personal/private use of preserved data
class PilotMigrationService {
  static const String _appVersionKey = 'app_version';
  static const String _migrationCompletedKey = 'pilot_migration_completed';
  static const String _pilotUserFlagKey = 'is_pilot_user';
  static const String _preservedDataKey = 'preserved_pilot_data';
  
  /// Current production version - update this when releasing new versions
  static const String currentProductionVersion = '1.0.7+132';
  
  /// Version that identifies pilot users (any version before production)
  static const String pilotVersionThreshold = '1.0.6';
  
  /// Check if this is a fresh install or an update from pilot
  static Future<MigrationStatus> checkMigrationStatus() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if migration was already completed
    final migrationCompleted = prefs.getBool(_migrationCompletedKey) ?? false;
    if (migrationCompleted) {
      return MigrationStatus.completed;
    }
    
    // Check if this is a fresh install (no previous version recorded)
    final previousVersion = prefs.getString(_appVersionKey);
    if (previousVersion == null) {
      // Fresh install - record current version and proceed normally
      await _recordCurrentVersion();
      return MigrationStatus.freshInstall;
    }
    
    // Check if user is upgrading from pilot version
    if (_isPilotVersion(previousVersion)) {
      // This is a pilot user upgrading to production
      await _markAsPilotUser();
      return MigrationStatus.pilotUpgrade;
    }
    
    // User is upgrading from a previous production version
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
  }
  
  // Private helper methods
  
  static bool _isPilotVersion(String version) {
    // Simple version comparison - any version <= 1.0.6 is considered pilot
    final versionParts = version.split('+')[0].split('.');
    final currentParts = pilotVersionThreshold.split('.');
    
    for (int i = 0; i < 3; i++) {
      final versionNum = int.tryParse(versionParts.length > i ? versionParts[i] : '0') ?? 0;
      final thresholdNum = int.tryParse(currentParts.length > i ? currentParts[i] : '0') ?? 0;
      
      if (versionNum < thresholdNum) return true;
      if (versionNum > thresholdNum) return false;
    }
    return true; // Equal versions are considered pilot
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
    // This would need to integrate with your location tracking service
    // For now, return a placeholder - you'll need to implement this based on your location storage
    return 0; // TODO: Implement actual location data counting
  }
  
  static Future<DateTime?> _getEarliestLocationDate() async {
    // This would need to integrate with your location tracking service
    // For now, return a placeholder - you'll need to implement this based on your location storage
    return null; // TODO: Implement actual earliest location date retrieval
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