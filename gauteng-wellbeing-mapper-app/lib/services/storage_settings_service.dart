import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import 'package:flutter/foundation.dart';
import '../db/survey_database.dart';

class StorageSettingsService {
  // Default values - balanced for research usage and performance
  static const int DEFAULT_LOCATION_RETENTION_DAYS = 60; // 2 months for research
  static const int DEFAULT_MAP_DISPLAY_DAYS = 21; // 3 weeks display for good overview
  static const int DEFAULT_MAX_MAP_MARKERS = 750; // Balanced performance
  static const bool DEFAULT_AUTO_CLEANUP_ENABLED = true; // Re-enabled with fix
  static const int MINIMUM_LOCATION_RETENTION_DAYS = 14; // Minimum for survey requirements
  
  // Unlimited constants
  static const int UNLIMITED_VALUE = -1;
  
  // SharedPreferences keys
  static const String PREF_LOCATION_RETENTION_DAYS = 'location_retention_days';
  static const String PREF_MAP_DISPLAY_DAYS = 'map_display_days';
  static const String PREF_MAX_MAP_MARKERS = 'max_map_markers';
  static const String PREF_AUTO_CLEANUP_ENABLED = 'auto_cleanup_enabled';
  static const String PREF_LAST_CLEANUP_DATE = 'last_cleanup_date';
  static const String PREF_LOCATION_RETENTION_LIMITED = 'location_retention_limited';
  static const String PREF_MAP_DISPLAY_LIMITED = 'map_display_limited';

  /// Get how many days to retain location data in local storage
  static Future<int> getLocationRetentionDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PREF_LOCATION_RETENTION_DAYS) ?? DEFAULT_LOCATION_RETENTION_DAYS;
  }

  /// Set how many days to retain location data in local storage
  static Future<void> setLocationRetentionDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_LOCATION_RETENTION_DAYS, days);
    
    // Update background geolocation plugin settings
    if (!kIsWeb) {
      await bg.BackgroundGeolocation.setConfig(
        bg.Config(maxDaysToPersist: days == UNLIMITED_VALUE ? 999999 : days)
      );
    }
  }

  /// Get whether location retention is limited
  static Future<bool> getLocationRetentionLimited() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREF_LOCATION_RETENTION_LIMITED) ?? true;
  }

  /// Set whether location retention is limited
  static Future<void> setLocationRetentionLimited(bool limited) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_LOCATION_RETENTION_LIMITED, limited);
    
    if (!limited) {
      // Set to unlimited
      await setLocationRetentionDays(UNLIMITED_VALUE);
    } else {
      // Set to default limited value
      await setLocationRetentionDays(DEFAULT_LOCATION_RETENTION_DAYS);
    }
  }

  /// Get how many days of location data to display on map
  static Future<int> getMapDisplayDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PREF_MAP_DISPLAY_DAYS) ?? DEFAULT_MAP_DISPLAY_DAYS;
  }

  /// Set how many days of location data to display on map
  static Future<void> setMapDisplayDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_MAP_DISPLAY_DAYS, days);
  }

  /// Get whether map display is limited
  static Future<bool> getMapDisplayLimited() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREF_MAP_DISPLAY_LIMITED) ?? true;
  }

  /// Set whether map display is limited
  static Future<void> setMapDisplayLimited(bool limited) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_MAP_DISPLAY_LIMITED, limited);
    
    if (!limited) {
      // Set to unlimited
      await setMapDisplayDays(UNLIMITED_VALUE);
    } else {
      // Set to default limited value
      await setMapDisplayDays(DEFAULT_MAP_DISPLAY_DAYS);
    }
  }

  /// Get maximum number of markers to display on map
  static Future<int> getMaxMapMarkers() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PREF_MAX_MAP_MARKERS) ?? DEFAULT_MAX_MAP_MARKERS;
  }

  /// Set maximum number of markers to display on map
  static Future<void> setMaxMapMarkers(int maxMarkers) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_MAX_MAP_MARKERS, maxMarkers);
  }

  /// Get whether automatic cleanup is enabled
  static Future<bool> getAutoCleanupEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(PREF_AUTO_CLEANUP_ENABLED) ?? DEFAULT_AUTO_CLEANUP_ENABLED;
  }

  /// Set whether automatic cleanup is enabled
  static Future<void> setAutoCleanupEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PREF_AUTO_CLEANUP_ENABLED, enabled);
  }

  /// Get last cleanup date
  static Future<DateTime?> getLastCleanupDate() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt(PREF_LAST_CLEANUP_DATE);
    return timestamp != null ? DateTime.fromMillisecondsSinceEpoch(timestamp) : null;
  }

  /// Set last cleanup date
  static Future<void> setLastCleanupDate(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_LAST_CLEANUP_DATE, date.millisecondsSinceEpoch);
  }

  /// Perform automatic cleanup if needed (daily check)
  static Future<void> performAutoCleanupIfNeeded() async {
    final autoCleanupEnabled = await getAutoCleanupEnabled();
    if (!autoCleanupEnabled) return;

    final lastCleanup = await getLastCleanupDate();
    final now = DateTime.now();
    
    // Only run cleanup once per day
    if (lastCleanup != null && now.difference(lastCleanup).inDays < 1) {
      return;
    }

    // Only cleanup if retention is limited
    final isLimited = await getLocationRetentionLimited();
    if (isLimited) {
      await performCleanup();
      await setLastCleanupDate(now);
    }
  }

  /// Perform cleanup of old location data
  static Future<void> performCleanup() async {
    final retentionDays = await getLocationRetentionDays();
    
    // Don't cleanup if unlimited
    if (retentionDays == UNLIMITED_VALUE) {
      print('[StorageSettingsService] Skipping cleanup - unlimited retention enabled');
      return;
    }
    
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    
    print('[StorageSettingsService] Performing cleanup - removing data older than $retentionDays days (cutoff: ${cutoffDate.toIso8601String()})');
    
    try {
      // Clean up background geolocation plugin data
      if (!kIsWeb) {
        final allLocations = await bg.BackgroundGeolocation.locations;
        int removedCount = 0;
        
        print('[StorageSettingsService] Found ${allLocations.length} total location records to check');
        
        for (var location in allLocations) {
          // FIXED: location['timestamp'] is an ISO string, not milliseconds
          final locationDate = DateTime.parse(location['timestamp']);
          
          if (locationDate.isBefore(cutoffDate)) {
            print('[StorageSettingsService] Removing old location: ${location['timestamp']} (${locationDate.toIso8601String()})');
            await bg.BackgroundGeolocation.destroyLocation(location['uuid']);
            removedCount++;
          }
        }
        
        print('[StorageSettingsService] Removed $removedCount old location records from plugin storage');
      }
      
      // Clean up database location data
      final database = SurveyDatabase();
      await database.cleanupOldLocationData(cutoffDate);
      
    } catch (e) {
      print('[StorageSettingsService] Error during cleanup: $e');
    }
  }

  /// Get filtered location data for map display
  static Future<List<dynamic>> getFilteredLocationDataForMap() async {
    if (kIsWeb) return [];
    
    final displayDays = await getMapDisplayDays();
    final retentionDays = await getLocationRetentionDays();
    final maxMarkers = await getMaxMapMarkers();
    
    print('[StorageSettingsService] Map filtering - Display days: $displayDays, Retention days: $retentionDays, Max markers: $maxMarkers');
    
    try {
      final allLocations = await bg.BackgroundGeolocation.locations;
      
      // If unlimited display, just limit by max markers
      if (displayDays == UNLIMITED_VALUE) {
        // Sort by timestamp (newest first)
        allLocations.sort((a, b) => 
          (b['timestamp'] as num).compareTo(a['timestamp'] as num));
        
        // Limit to max markers
        if (allLocations.length > maxMarkers) {
          return allLocations.take(maxMarkers).toList();
        }
        
        return allLocations;
      }
      
      // Filter by date
      final cutoffDate = DateTime.now().subtract(Duration(days: displayDays));
      final recentLocations = allLocations.where((location) {
        // FIXED: location['timestamp'] is an ISO string, not milliseconds
        final locationDate = DateTime.parse(location['timestamp']);
        return locationDate.isAfter(cutoffDate);
      }).toList();
      
      // Sort by timestamp (newest first)
      recentLocations.sort((a, b) => 
        (b['timestamp'] as num).compareTo(a['timestamp'] as num));
      
      // Limit to max markers
      if (recentLocations.length > maxMarkers) {
        return recentLocations.take(maxMarkers).toList();
      }
      
      return recentLocations;
      
    } catch (e) {
      print('[StorageSettingsService] Error getting filtered location data: $e');
      return [];
    }
  }
}