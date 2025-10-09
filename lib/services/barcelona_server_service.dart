import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:fast_rsa/fast_rsa.dart';
import '../util/env.dart';
import '../models/survey_models.dart';
import '../models/consent_models.dart';
import '../models/locations_to_push.dart';

/// Barcelona Server Service
/// 
/// Handles all data synchronization with the Barcelona research server.
/// Replaces the Qualtrics integration for the Barcelona study.
/// 
/// Features:
/// - End-to-end encrypted data transmission
/// - Survey response submission  
/// - Location data upload
/// - Consent tracking
/// - Research participant management
/// - GDPR-compliant data handling
class BarcelonaServerService {
  static const String _baseUrl = ENV.API_BASE_URL;
  static const Duration _timeout = Duration(seconds: 30);

  // Authentication headers (to be configured based on server setup)
  static const Map<String, String> _defaultHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    // Add authentication headers as needed:
    // 'Authorization': 'Bearer ${your_api_key}',
    // 'X-Study-ID': ENV.DEFAULT_SAMPLE_ID,
  };

  /// Encrypt data using Barcelona public key
  /// 
  /// [data] - The data to encrypt (will be JSON encoded)
  /// Returns base64-encoded encrypted data
  static Future<String> _encryptData(Map<String, dynamic> data) async {
    try {
      final jsonString = jsonEncode(data);
      final encrypted = await RSA.encryptPKCS1v15(jsonString, ENV.BARCELONA_PUBLIC_KEY);
      return encrypted;
    } catch (e) {
      print('❌ Error encrypting data for Barcelona server: $e');
      throw Exception('Failed to encrypt data: $e');
    }
  }

  /// Submit initial survey response to Barcelona server (encrypted)
  /// 
  /// [surveyResponse] - The initial survey response data to submit
  /// [participantId] - The participant UUID (obtained from app state)
  /// Returns true if successful, false otherwise
  static Future<bool> submitInitialSurveyResponse(
    InitialSurveyResponse surveyResponse, 
    String participantId
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/survey-responses/initial');
      
      // Prepare data for encryption
      final dataToEncrypt = {
        'participant_id': participantId,
        'survey_type': 'initial',
        'responses': surveyResponse.toJson(),
        'timestamp': surveyResponse.submittedAt.toIso8601String(),
        'study_id': ENV.DEFAULT_SAMPLE_ID,
        'app_version': '1.0.0', // TODO: Get from package info
      };

      // Encrypt the data
      final encryptedData = await _encryptData(dataToEncrypt);
      
      final body = jsonEncode({
        'encrypted_payload': encryptedData,
        'study_id': ENV.DEFAULT_SAMPLE_ID, // Unencrypted for server routing
        'data_type': 'initial_survey',
      });

      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Initial survey response submitted successfully to Barcelona server (encrypted)');
        return true;
      } else {
        print('❌ Failed to submit initial survey response: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error submitting initial survey response to Barcelona server: $e');
      return false;
    }
  }

  /// Submit recurring survey response to Barcelona server
  /// 
  /// [surveyResponse] - The recurring survey response data to submit
  /// [participantId] - The participant UUID (obtained from app state)
  /// Returns true if successful, false otherwise
  static Future<bool> submitRecurringSurveyResponse(
    RecurringSurveyResponse surveyResponse,
    String participantId
  ) async {
    try {
      final url = Uri.parse('$_baseUrl/survey-responses/recurring');
      
      final body = jsonEncode({
        'participant_id': participantId,
        'survey_type': 'recurring',
        'responses': surveyResponse.toJson(),
        'timestamp': surveyResponse.submittedAt.toIso8601String(),
        'study_id': ENV.DEFAULT_SAMPLE_ID,
        'app_version': '1.0.0', // TODO: Get from package info
      });

      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Recurring survey response submitted successfully to Barcelona server');
        return true;
      } else {
        print('❌ Failed to submit recurring survey response: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error submitting recurring survey response to Barcelona server: $e');
      return false;
    }
  }

  /// Submit consent response to Barcelona server
  /// 
  /// [consentResponse] - The consent data to submit
  /// Returns true if successful, false otherwise  
  static Future<bool> submitConsentResponse(ConsentResponse consentResponse) async {
    try {
      final url = Uri.parse('$_baseUrl/consent-responses');
      
      final body = jsonEncode({
        'participant_id': consentResponse.participantUuid,
        'informed_consent': consentResponse.informedConsent,
        'data_processing': consentResponse.dataProcessing,
        'location_data': consentResponse.locationData,
        'survey_data': consentResponse.surveyData,
        'data_retention': consentResponse.dataRetention,
        'data_sharing': consentResponse.dataSharing,
        'voluntary_participation': consentResponse.voluntaryParticipation,
        'consent_qualtrics_data': consentResponse.consentQualtricsData, // Keep for compatibility
        'timestamp': consentResponse.consentedAt.toIso8601String(),
        'study_id': ENV.DEFAULT_SAMPLE_ID,
      });

      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Consent response submitted successfully to Barcelona server');
        return true;
      } else {
        print('❌ Failed to submit consent response: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error submitting consent response to Barcelona server: $e');
      return false;
    }
  }

  /// Submit location data batch to Barcelona server
  /// 
  /// [locationData] - List of location points to submit
  /// Returns true if successful, false otherwise
  static Future<bool> submitLocationData(List<LocationToPush> locationData) async {
    try {
      final url = Uri.parse('$_baseUrl/location-data');
      
      final body = jsonEncode({
        'participant_id': locationData.isNotEmpty ? locationData.first.userUUID : 'unknown',
        'study_id': ENV.DEFAULT_SAMPLE_ID,
        'location_points': locationData.map((loc) => loc.toJson()).toList(),
        'upload_timestamp': DateTime.now().toIso8601String(),
      });

      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Location data batch (${locationData.length} points) submitted successfully');
        return true;
      } else {
        print('❌ Failed to submit location data: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error submitting location data to Barcelona server: $e');
      return false;
    }
  }

  /// Register new participant with Barcelona server
  /// 
  /// [participantId] - Unique participant identifier
  /// Returns true if successful, false otherwise
  static Future<bool> registerParticipant(String participantId) async {
    try {
      final url = Uri.parse('$_baseUrl/participants');
      
      final body = jsonEncode({
        'participant_id': participantId,
        'study_id': ENV.DEFAULT_SAMPLE_ID,
        'registration_timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.0.0', // TODO: Get from package info
        'platform': Platform.isAndroid ? 'android' : 'ios',
      });

      final response = await http.post(
        url,
        headers: _defaultHeaders,
        body: body,
      ).timeout(_timeout);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Participant registered successfully with Barcelona server');
        return true;
      } else {
        print('❌ Failed to register participant: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error registering participant with Barcelona server: $e');
      return false;
    }
  }

  /// Check server connectivity and authentication
  /// 
  /// Returns true if server is reachable and authenticated, false otherwise
  static Future<bool> checkServerConnection() async {
    try {
      final url = Uri.parse('$_baseUrl/health');
      
      final response = await http.get(
        url,
        headers: _defaultHeaders,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        print('✅ Barcelona server connection successful');
        return true;
      } else {
        print('❌ Barcelona server returned: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Cannot connect to Barcelona server: $e');
      return false;
    }
  }

  /// Get study configuration from Barcelona server
  /// 
  /// Returns study configuration map, or null if failed
  static Future<Map<String, dynamic>?> getStudyConfiguration() async {
    try {
      final url = Uri.parse('$_baseUrl/study-config/${ENV.DEFAULT_SAMPLE_ID}');
      
      final response = await http.get(
        url,
        headers: _defaultHeaders,
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final config = jsonDecode(response.body) as Map<String, dynamic>;
        print('✅ Study configuration retrieved from Barcelona server');
        return config;
      } else {
        print('❌ Failed to get study configuration: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error getting study configuration: $e');
      return null;
    }
  }
}