import 'dart:convert';
import 'package:fast_rsa/fast_rsa.dart';
import '../db/survey_database.dart';
import '../main.dart';

/// Service for encrypting complete survey responses and sending to proxy server
class EncryptedSurveyService {
  
  // Use the same public key as location encryption for consistency
  static const String _publicKey = '''-----BEGIN PUBLIC KEY-----
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
-----END PUBLIC KEY-----''';

  /// Sync all pending surveys as encrypted JSON blobs
  static Future<void> syncPendingSurveys() async {
    try {
      print('🔐 Starting encrypted survey sync...');
      
      final db = SurveyDatabase();
      
      // Sync initial surveys
      final unsyncedInitial = await db.getUnsyncedInitialSurveys();
      for (final survey in unsyncedInitial) {
        await _syncInitialSurveyEncrypted(survey);
      }
      
      // Sync biweekly surveys  
      final unsyncedBiweekly = await db.getUnsyncedRecurringSurveys();
      for (final survey in unsyncedBiweekly) {
        await _syncBiweeklySurveyEncrypted(survey);
      }
      
      // Sync consent forms
      final unsyncedConsent = await db.getUnsyncedConsentForms();
      for (final consent in unsyncedConsent) {
        await _syncConsentFormEncrypted(consent);
      }
      
      print('✅ Encrypted survey sync completed');
      
    } catch (e) {
      print('❌ Error in encrypted survey sync: $e');
    }
  }
  
  /// Encrypt and sync initial survey
  static Future<bool> _syncInitialSurveyEncrypted(Map<String, dynamic> surveyData) async {
    try {
      print('🔐 Encrypting and syncing initial survey...');
      
      // Create complete survey JSON
      final surveyJson = {
        'type': 'initial_survey',
        'participant_uuid': GlobalData.userUUID,
        'survey_id': surveyData['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'data': surveyData,
        'metadata': {
          'app_version': '1.0.0', // TODO: Get from package info
          'submission_method': 'encrypted_proxy',
        }
      };
      
      // Encrypt the entire JSON
      final encryptedBlob = await _encryptSurveyData(surveyJson);
      
      // Send to proxy server
      final success = await _sendToProxy('initial', encryptedBlob);
      
      if (success) {
        final db = SurveyDatabase();
        await db.markInitialSurveySynced(surveyData['id']);
        print('✅ Initial survey encrypted and synced');
        return true;
      }
      
      return false;
      
    } catch (e) {
      print('❌ Error encrypting initial survey: $e');
      return false;
    }
  }
  
  /// Encrypt and sync biweekly survey
  static Future<bool> _syncBiweeklySurveyEncrypted(Map<String, dynamic> surveyData) async {
    try {
      print('🔐 Encrypting and syncing biweekly survey...');
      
      // Include location data if available
      String? locationData;
      if (surveyData['location_data'] != null) {
        locationData = surveyData['location_data'].toString();
      }
      
      final surveyJson = {
        'type': 'biweekly_survey',
        'participant_uuid': GlobalData.userUUID,
        'survey_id': surveyData['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'data': surveyData,
        'location_data': locationData,
        'metadata': {
          'app_version': '1.0.0',
          'submission_method': 'encrypted_proxy',
        }
      };
      
      final encryptedBlob = await _encryptSurveyData(surveyJson);
      final success = await _sendToProxy('biweekly', encryptedBlob);
      
      if (success) {
        final db = SurveyDatabase();
        await db.markRecurringSurveySynced(surveyData['id']);
        print('✅ Biweekly survey encrypted and synced');
        return true;
      }
      
      return false;
      
    } catch (e) {
      print('❌ Error encrypting biweekly survey: $e');
      return false;
    }
  }
  
  /// Encrypt and sync consent form
  static Future<bool> _syncConsentFormEncrypted(Map<String, dynamic> consentData) async {
    try {
      print('🔐 Encrypting and syncing consent form...');
      
      final consentJson = {
        'type': 'consent_form',
        'participant_uuid': GlobalData.userUUID,
        'consent_id': consentData['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'data': consentData,
        'metadata': {
          'app_version': '1.0.0',
          'submission_method': 'encrypted_proxy',
        }
      };
      
      final encryptedBlob = await _encryptSurveyData(consentJson);
      final success = await _sendToProxy('consent', encryptedBlob);
      
      if (success) {
        final db = SurveyDatabase();
        await db.markConsentFormSynced(consentData['id']);
        print('✅ Consent form encrypted and synced');
        return true;
      }
      
      return false;
      
    } catch (e) {
      print('❌ Error encrypting consent form: $e');
      return false;
    }
  }
  
  /// Encrypt survey data using RSA public key
  static Future<String> _encryptSurveyData(Map<String, dynamic> surveyJson) async {
    try {
      // Convert to JSON string
      final jsonString = jsonEncode(surveyJson);
      
      print('📄 Survey JSON size: ${jsonString.length} characters');
      
      // Encrypt using RSA public key
      final encryptedData = await RSA.encryptPKCS1v15(jsonString, _publicKey);
      
      print('🔐 Encrypted blob size: ${encryptedData.length} characters');
      
      return encryptedData;
      
    } catch (e) {
      print('❌ Encryption failed: $e');
      rethrow;
    }
  }
  
  /// Send encrypted blob to proxy server
  static Future<bool> _sendToProxy(String surveyType, String encryptedBlob) async {
    try {
      print('🌐 Sending encrypted $surveyType survey to proxy...');
      
      // TODO: Replace with actual HTTP call to your proxy server
      // For now, just simulate success
      
      /* 
      final response = await http.post(
        Uri.parse(_proxyServerUrl),
        headers: {
          'Content-Type': 'application/json',
          'X-Survey-Type': surveyType,
        },
        body: jsonEncode({
          'encrypted_data': encryptedBlob,
          'survey_type': surveyType,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      
      return response.statusCode >= 200 && response.statusCode < 300;
      */
      
      // Simulate successful transmission
      await Future.delayed(Duration(milliseconds: 500));
      print('✅ Encrypted data sent to proxy (simulated)');
      return true;
      
    } catch (e) {
      print('❌ Error sending to proxy: $e');
      return false;
    }
  }
}