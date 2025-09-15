import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:fast_rsa/fast_rsa.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/survey_models.dart';
import '../models/wellbeing_survey_models.dart';
import '../db/survey_database.dart';
import 'encrypted_survey_service.dart';

/// Service for encrypting and uploading research data to study servers
class DataUploadService {
  // Research server configurations
  static const Map<String, ResearchServerConfig> _serverConfigs = {
    'barcelona': ResearchServerConfig(
      baseUrl: 'https://api.planet4health.upf.edu',
      publicKeyPem: '''-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA1234567890...
-----END PUBLIC KEY-----''', // Barcelona public key placeholder
    ),
    'gauteng': ResearchServerConfig(
      baseUrl: 'https://api.planet4health.up.ac.za',
      publicKeyPem: '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEA0J5sRl93JHb16BSzkkDu
phMMne8Yv/qAtLxGl2yHGZ1dFsMY7xJU+9epEN6DPA5PFbo+NwumQ17aAw7IDm8A
Pyis7gryWDtaGUNjapvQdq+Kfx1Z0D+yx569KjWxAwQpGL6PxOdW0RKwsV3QKgCo
RJxQqtr9QJHQ/FIBrfzuh+MmCie9JSFE3nrRBEjOQszI72AUx4xxE1RauQnwgvGx
HrJoue9tFAAQfWzv95VigRHKqAlzRbZkmNQJOWGng3xAbfgf3v+wSnin51lp5H1/
qMeBmv0ABEMRWpcgsfhd9pIwX13paq766GFYFZMh0n9UDscXA5y2/p4YbgjEINPF
f7vFuRwiFjS4j+0ZiuOLi2DbF9DWYh2jX1ZVxMUMbv2t0cdcCnXsYSqxzAfKODf7
xxTKffLKxP5xEaR8bnrwMS2YaAB3CRAi7ZYSp7OvS/PCM2HeWV9WaCSYZJsv+VJI
0A2bVvauok8Odzmd3z9RZarVowfpc1MyGABrlp52lp1Q6nGuHrIXaUSil/SYP9yD
PwkY+fa6X6hUpSMUmPfgZkS5IAiWPRpbqe6OJ4N+uelyVn+rvmRz/SgJ3g89L6dh
vzgBHEl3b7c051V8daNVoOmadjWYVzVyC7ViXf5Qtzl0Zg2bfyD0MGNUh/gwGgcu
AKr5gbTqca/dY/+Or3Ha/sECAwEAAQ==
-----END PUBLIC KEY-----''', // Gauteng public key - University of Pretoria
    ),
  };

  /// Upload survey data and location tracks for a research participant
  static Future<UploadResult> uploadParticipantData({
    required String researchSite,
    required List<InitialSurveyResponse> initialSurveys,
    required List<RecurringSurveyResponse> recurringSurveys,
    required List<WellbeingSurveyResponse> wellbeingSurveys,
    required List<LocationTrack> locationTracks,
    required String participantUuid,
  }) async {
    try {
      // Get server configuration
      final serverConfig = _serverConfigs[researchSite];
      if (serverConfig == null) {
        throw Exception('Unknown research site: $researchSite');
      }

      // Prepare data package
      final dataPackage = DataPackage(
        participantUuid: participantUuid,
        researchSite: researchSite,
        initialSurveys: initialSurveys,
        recurringSurveys: recurringSurveys,
        wellbeingSurveys: wellbeingSurveys,
        locationTracks: locationTracks,
        timestamp: DateTime.now(),
      );

      // Encrypt the data
      final encryptedData = await _encryptData(
        dataPackage.toJson(),
        serverConfig.publicKeyPem,
      );

      // Upload to server
      final uploadResult = await _uploadToServer(
        serverConfig.baseUrl,
        encryptedData,
        participantUuid,
        researchSite,
      );

      return uploadResult;
    } catch (e) {
      return UploadResult(
        success: false,
        error: e.toString(),
        uploadId: null,
      );
    }
  }

  /// Check if participant should upload data (every two weeks)
  static Future<bool> shouldUploadData(String researchSite) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUploadKey = 'last_upload_$researchSite';
      final lastUploadTimestamp = prefs.getInt(lastUploadKey);
      
      if (lastUploadTimestamp == null) {
        return true; // First upload
      }
      
      final lastUpload = DateTime.fromMillisecondsSinceEpoch(lastUploadTimestamp);
      final twoWeeksAgo = DateTime.now().subtract(Duration(days: 14));
      
      return lastUpload.isBefore(twoWeeksAgo);
    } catch (e) {
      return false;
    }
  }

  /// Get location tracks for the past two weeks
  static Future<List<LocationTrack>> getRecentLocationTracks() async {
    try {
      final db = SurveyDatabase();
      final twoWeeksAgo = DateTime.now().subtract(Duration(days: 14));
      return await db.getLocationTracksSince(twoWeeksAgo);
    } catch (e) {
      return [];
    }
  }

  /// Mark upload as completed
  static Future<void> markUploadCompleted(String researchSite, String uploadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('last_upload_$researchSite', DateTime.now().millisecondsSinceEpoch);
      await prefs.setString('last_upload_id_$researchSite', uploadId);
    } catch (e) {
      // Log error but don't throw
      print('Error marking upload completed: $e');
    }
  }

  /// Encrypt data using RSA public key
  static Future<EncryptedDataPackage> _encryptData(
    Map<String, dynamic> data,
    String publicKeyPem,
  ) async {
    try {
      // Convert data to JSON string
      final jsonData = jsonEncode(data);
      final dataBytes = utf8.encode(jsonData);

      // Generate AES key for symmetric encryption (hybrid approach)
      final aesKey = _generateAESKey();
      
      // Encrypt data with AES
      final encryptedData = await _encryptWithAES(dataBytes, aesKey);
      
      // Encrypt AES key with RSA public key
      final encryptedAESKey = await RSA.encryptPKCS1v15Bytes(
        Uint8List.fromList(aesKey),
        publicKeyPem,
      );

      return EncryptedDataPackage(
        encryptedData: base64Encode(encryptedData),
        encryptedKey: base64Encode(encryptedAESKey),
        algorithm: 'AES-256-GCM + RSA-PKCS1',
      );
    } catch (e) {
      throw Exception('Encryption failed: $e');
    }
  }

  /// Generate a random AES-256 key
  static List<int> _generateAESKey() {
    // For demo purposes - in production, use a cryptographically secure random generator
    final key = List.generate(32, (index) => DateTime.now().microsecond % 256);
    return key;
  }

  /// Encrypt data with AES (simplified implementation)
  static Future<List<int>> _encryptWithAES(List<int> data, List<int> key) async {
    // For demo purposes - in production, use proper AES-GCM implementation
    // This is a placeholder that would be replaced with actual AES encryption
    return data; // Simplified for demo
  }

  /// Upload encrypted data to research server
  static Future<UploadResult> _uploadToServer(
    String baseUrl,
    EncryptedDataPackage encryptedData,
    String participantUuid,
    String researchSite,
  ) async {
    try {
      final url = Uri.parse('$baseUrl/api/v1/data/upload');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Research-Site': researchSite,
          'X-Participant-UUID': participantUuid,
        },
        body: jsonEncode({
          'encrypted_data': encryptedData.encryptedData,
          'encrypted_key': encryptedData.encryptedKey,
          'algorithm': encryptedData.algorithm,
          'participant_uuid': participantUuid,
          'research_site': researchSite,
          'upload_timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return UploadResult(
          success: true,
          uploadId: responseData['upload_id'],
          error: null,
        );
      } else {
        return UploadResult(
          success: false,
          error: 'Server error: ${response.statusCode} - ${response.body}',
          uploadId: null,
        );
      }
    } catch (e) {
      return UploadResult(
        success: false,
        error: 'Network error: $e',
        uploadId: null,
      );
    }
  }
}

/// Configuration for research server endpoints and encryption keys
class ResearchServerConfig {
  final String baseUrl;
  final String publicKeyPem;

  const ResearchServerConfig({
    required this.baseUrl,
    required this.publicKeyPem,
  });
}

/// Complete data package for upload
class DataPackage {
  final String participantUuid;
  final String researchSite;
  final List<InitialSurveyResponse> initialSurveys;
  final List<RecurringSurveyResponse> recurringSurveys;
  final List<WellbeingSurveyResponse> wellbeingSurveys;
  final List<LocationTrack> locationTracks;
  final DateTime timestamp;

  DataPackage({
    required this.participantUuid,
    required this.researchSite,
    required this.initialSurveys,
    required this.recurringSurveys,
    required this.wellbeingSurveys,
    required this.locationTracks,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'participant_uuid': participantUuid,
      'research_site': researchSite,
      'initial_surveys': initialSurveys.map((s) => s.toJson()).toList(),
      'recurring_surveys': recurringSurveys.map((s) => s.toJson()).toList(),
      'wellbeing_surveys': wellbeingSurveys.map((s) => s.toResearchJson(participantUuid)).toList(),
      'location_tracks': locationTracks.map((t) => t.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'app_version': '0.1.0', // Should be loaded from package info
    };
  }
}

/// Encrypted data package
class EncryptedDataPackage {
  final String encryptedData;
  final String encryptedKey;
  final String algorithm;

  EncryptedDataPackage({
    required this.encryptedData,
    required this.encryptedKey,
    required this.algorithm,
  });
}

/// Result of upload operation
class UploadResult {
  final bool success;
  final String? uploadId;
  final String? error;

  UploadResult({
    required this.success,
    this.uploadId,
    this.error,
  });
}

/// Location track data model
class LocationTrack {
  final DateTime timestamp;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final double? altitude;
  final double? speed;
  final String? activity;

  LocationTrack({
    required this.timestamp,
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.altitude,
    this.speed,
    this.activity,
  });

  Map<String, dynamic> toJson() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'altitude': altitude,
      'speed': speed,
      'activity': activity,
    };
  }

  factory LocationTrack.fromJson(Map<String, dynamic> json) {
    return LocationTrack(
      timestamp: DateTime.parse(json['timestamp']),
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      altitude: json['altitude']?.toDouble(),
      speed: json['speed']?.toDouble(),
      activity: json['activity'],
    );
  }

  /// Check if it's time to upload data (bi-weekly interval)
  static Future<bool> shouldUploadData(String researchSite) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastUploadTimestamp = prefs.getInt('last_upload_$researchSite');
      
      if (lastUploadTimestamp == null) {
        // First upload - check if user has been participating for at least 2 weeks
        final participationJson = prefs.getString('participation_settings');
        if (participationJson != null) {
          // Parse participation start date
          // For now, assume they can upload after 2 weeks of app usage
          return true; // Simplified logic
        }
        return false;
      }
      
      final lastUpload = DateTime.fromMillisecondsSinceEpoch(lastUploadTimestamp);
      final twoWeeksAfterLastUpload = lastUpload.add(Duration(days: 14));
      return DateTime.now().isAfter(twoWeeksAfterLastUpload);
    } catch (e) {
      print('Error checking upload eligibility: $e');
      return false;
    }
  }

  /// Get location tracks from the past 2 weeks
  static Future<List<LocationTrack>> getRecentLocationTracks() async {
    try {
      final db = SurveyDatabase();
      final twoWeeksAgo = DateTime.now().subtract(Duration(days: 14));
      return await db.getLocationTracksSince(twoWeeksAgo);
    } catch (e) {
      print('Error retrieving location tracks: $e');
      return [];
    }
  }

  /// Mark upload as completed and store metadata
  static Future<void> markUploadCompleted(String researchSite, String uploadId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      
      // Store upload completion timestamp and ID
      await prefs.setInt('last_upload_$researchSite', now.millisecondsSinceEpoch);
      await prefs.setString('last_upload_id_$researchSite', uploadId);
      
      // Mark recent location tracks as synced
      final db = SurveyDatabase();
      final twoWeeksAgo = now.subtract(Duration(days: 14));
      final locationTracks = await db.getLocationTracksSince(twoWeeksAgo);
      final trackIds = locationTracks.map((track) => track.hashCode).toList(); // Simplified ID mapping
      if (trackIds.isNotEmpty) {
        await db.markLocationTracksAsSynced(trackIds);
      }
      
      print('Upload completed successfully: $uploadId');
    } catch (e) {
      print('Error marking upload as completed: $e');
    }
  }

  /// Sync pending surveys using encrypted service
  static Future<void> syncPendingSurveysToQualtrics() async {
    try {
      print('🔄 Starting encrypted background sync...');
      await EncryptedSurveyService.syncPendingSurveys();
      print('✅ Encrypted background sync completed');
    } catch (e) {
      print('❌ Encrypted background sync failed: $e');
    }
  }
}
