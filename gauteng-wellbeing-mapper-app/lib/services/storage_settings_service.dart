import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../db/survey_database.dart';
import 'geo_location_service.dart';

class StorageSettingsService {
  // Default values - balanced for research usage and performance
  static const int DEFAULT_LOCATION_RETENTION_DAYS = 60; // 2 months for research
  static const int DEFAULT_MAP_DISPLAY_DAYS = UNLIMITED_VALUE; // Feature effectively disabled
  static const int DEFAULT_MAX_MAP_MARKERS = 2000; // Optimized for three-layer system
  static const double DEFAULT_MAP_ERROR_THRESHOLD_METERS = 500.0; // Filter out extremely inaccurate fixes by default
  static const double MIN_MAP_ERROR_THRESHOLD_METERS = 10.0;
  static const double MAX_MAP_ERROR_THRESHOLD_METERS = 500.0; // Matches storage filter threshold
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
  static const String PREF_MAP_ERROR_THRESHOLD_METERS = 'map_error_threshold_meters';

  /// Get how many days to retain location data in local storage
  static Future<int> getLocationRetentionDays() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(PREF_LOCATION_RETENTION_DAYS) ?? DEFAULT_LOCATION_RETENTION_DAYS;
  }

  /// Set how many days to retain location data in local storage
  static Future<void> setLocationRetentionDays(int days) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(PREF_LOCATION_RETENTION_DAYS, days);
    
    // Propagate to the location plugin if it has been configured.
    if (!kIsWeb) {
      await GeoLocationService.instance.updateRetentionDays(days);
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

  /// Get maximum acceptable accuracy (error) for markers displayed on the map (in meters)
  static Future<double> getMapErrorThresholdMeters() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(PREF_MAP_ERROR_THRESHOLD_METERS) ?? DEFAULT_MAP_ERROR_THRESHOLD_METERS;
  }

  /// Set maximum acceptable accuracy (error) for markers displayed on the map (in meters)
  static Future<void> setMapErrorThresholdMeters(double meters) async {
    final prefs = await SharedPreferences.getInstance();
  final clamped = meters
    .clamp(MIN_MAP_ERROR_THRESHOLD_METERS, MAX_MAP_ERROR_THRESHOLD_METERS)
    .toDouble();
    await prefs.setDouble(PREF_MAP_ERROR_THRESHOLD_METERS, clamped);
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
      debugPrint('[StorageSettingsService] Skipping cleanup - unlimited retention enabled');
      return;
    }
    
    final cutoffDate = DateTime.now().subtract(Duration(days: retentionDays));
    
    debugPrint('[StorageSettingsService] Performing cleanup - removing data older than $retentionDays days (cutoff: ${cutoffDate.toIso8601String()})');
    
    try {
      // Clean up app database location data (FBG handles its own minimal 1-day retention)
      final database = SurveyDatabase();
      await database.cleanupOldLocationData(cutoffDate);
      
      debugPrint('[StorageSettingsService] ✅ App database cleanup completed');
      
    } catch (e) {
      debugPrint('[StorageSettingsService] ❌ Error during cleanup: $e');
    }
  }

  /// Get filtered location data for map display
  /// Now loads from app database instead of FBG internal storage to prevent auto-purge issues
  static Future<List<dynamic>> getFilteredLocationDataForMap() async {
    if (kIsWeb) return [];
    
    final displayDays = await getMapDisplayDays();
  final retentionDays = await getLocationRetentionDays();
  final maxMarkers = await getMaxMapMarkers();
  final maxErrorThreshold = await getMapErrorThresholdMeters();
    
  debugPrint('[StorageSettingsService] Map filtering - Display days: $displayDays, Retention days: $retentionDays, Max markers: $maxMarkers, Max error: ${maxErrorThreshold.toStringAsFixed(1)}m');
    
    try {
      // FIXED: Load from app's database instead of FBG's internal storage that auto-purges
      final db = SurveyDatabase();
      final locationTracks = await db.getAllLocationTracks();
      
      debugPrint('[StorageSettingsService] 🗃️ Loaded ${locationTracks.length} location tracks from app database');
      
      // Convert LocationTrack objects to FBG-compatible format for map
      List<Map<String, dynamic>> allLocations = [];
      for (final track in locationTracks) {
        final accuracy = track.accuracy ?? 0.0;
        if (accuracy > maxErrorThreshold) {
          if (kDebugMode) {
            debugPrint('[StorageSettingsService] 🚫 Skipping LocationTrack at ${track.timestamp.toIso8601String()} due to accuracy ${accuracy.toStringAsFixed(1)}m');
          }
          continue;
        }

        allLocations.add({
          'timestamp': track.timestamp.toIso8601String(),
          'coords': {
            'latitude': track.latitude,
            'longitude': track.longitude,
            'accuracy': accuracy,
            'altitude': track.altitude ?? 0.0,
            'speed': track.speed ?? 0.0,
          },
          'activity': {
            'type': track.activity ?? 'unknown',
          },
        });
      }
      
      // If unlimited display, just limit by max markers
      if (displayDays == UNLIMITED_VALUE) {
        // Sort by timestamp (newest first) - already sorted by DB query
        
        // Limit to max markers
        if (allLocations.length > maxMarkers) {
          return allLocations.take(maxMarkers).toList();
        }
        
        return allLocations;
      }
      
      // Filter by date
      final cutoffDate = DateTime.now().subtract(Duration(days: displayDays));
      final recentLocations = allLocations.where((location) {
        final locationDate = DateTime.parse(location['timestamp']);
        return locationDate.isAfter(cutoffDate);
      }).toList();
      
      debugPrint('[StorageSettingsService] 📍 Filtered to ${recentLocations.length} recent locations (last $displayDays days)');
      
      // Limit to max markers
      if (recentLocations.length > maxMarkers) {
        final limited = recentLocations.take(maxMarkers).toList();
        debugPrint('[StorageSettingsService] 🎯 Limited to ${limited.length} markers for performance');
        return limited;
      }
      
      return recentLocations;
      
    } catch (e) {
      debugPrint('[StorageSettingsService] ❌ Error getting filtered location data from database: $e');
      return [];
    }
  }
}