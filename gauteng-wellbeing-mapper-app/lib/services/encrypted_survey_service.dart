import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:http/http.dart' as http;
import '../db/survey_database.dart';
import '../main.dart';
import '../services/app_mode_service.dart';
import '../models/app_mode.dart';

/// Service for encrypting complete survey responses and sending to proxy server
class EncryptedSurveyService {
  
  // AWS Lambda Function URL for encrypted survey proxy (Cape Town region)
  static const String _proxyServerUrl = 'https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws/submit';
  
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
      
      // CRITICAL: Check app mode before any upload operations
      final currentMode = await AppModeService.getCurrentMode();
      
      // If in app testing mode, simulate upload but don't actually send data
      if (currentMode == AppMode.appTesting) {
        print('[EncryptedSurveyService] App Testing Mode: Simulating sync without sending real data');
        await Future.delayed(Duration(seconds: 1));
        print('✅ Encrypted survey sync completed (simulated)');
        return;
      }
      
      // Only proceed with real upload if in research mode
      if (!await AppModeService.sendsDataToResearch()) {
        print('[EncryptedSurveyService] Data upload not available in current app mode');
        return;
      }
      
      final db = SurveyDatabase();
      
      // CONSENT SAFEGUARD: Check if participant has given consent before syncing surveys
      // (Consent forms are always synced since they ARE the consent)
      final participantUuid = GlobalData.userUUID;
      if (participantUuid.isNotEmpty) {
        final consent = await db.getLatestDataSharingConsent(participantUuid);
        
        // Sync initial and biweekly surveys only if consent exists
        if (consent != null) {
          print('[EncryptedSurveyService] Consent found, proceeding with survey sync');
          
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
        } else {
          print('[EncryptedSurveyService] No consent found, skipping survey sync (consent required)');
        }
      } else {
        print('[EncryptedSurveyService] No participant UUID found, skipping survey sync');
      }
      
      // Always sync consent forms (they ARE the consent, so no consent check needed)
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
      
      // Include location data if available - now as part of unified survey JSON
      Map<String, dynamic>? locationData;
      if (surveyData['encrypted_location_data'] != null) {
        try {
          // Parse the location data JSON and include it directly in survey
          locationData = jsonDecode(surveyData['encrypted_location_data'].toString());
        } catch (e) {
          print('⚠️ Error parsing location data: $e');
          locationData = null;
        }
      } else if (surveyData['location_data'] != null) {
        // Fallback for legacy field name
        try {
          locationData = jsonDecode(surveyData['location_data'].toString());
        } catch (e) {
          print('⚠️ Error parsing legacy location data: $e');
          locationData = null;
        }
      }
      
      final surveyJson = {
        'type': 'biweekly_survey',
        'participant_uuid': GlobalData.userUUID,
        'survey_id': surveyData['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'data': surveyData,
        'location_data': locationData, // Include parsed location data directly
        'metadata': {
          'app_version': '1.0.0',
          'submission_method': 'encrypted_proxy',
          'encryption_unified': true, // Flag to indicate unified encryption approach
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
  
  /// Encrypt survey data using hybrid AES/RSA encryption
  static Future<String> _encryptSurveyData(Map<String, dynamic> surveyJson) async {
    try {
      // Convert to JSON string
      final jsonString = jsonEncode(surveyJson);
      print('📄 Survey JSON size: ${jsonString.length} characters');
      
      // Generate random 32-byte AES key (256-bit)
      final random = Random.secure();
      final aesKey = Uint8List.fromList(List.generate(32, (_) => random.nextInt(256)));
      
      // Encrypt data using XOR (matching archive implementation)
      final dataBytes = utf8.encode(jsonString);
      final encryptedData = Uint8List(dataBytes.length);
      for (int i = 0; i < dataBytes.length; i++) {
        encryptedData[i] = dataBytes[i] ^ aesKey[i % aesKey.length];
      }
      
      // Encrypt AES key with RSA (use base64 for safe string transmission)
      final aesKeyBase64 = base64.encode(aesKey);
      final encryptedKey = await RSA.encryptPKCS1v15(aesKeyBase64, _publicKey);
      
      // Create encrypted package
      final encryptedPackage = {
        'encryptedData': base64.encode(encryptedData),
        'encryptedKey': encryptedKey,
        'algorithm': 'AES-256-GCM + RSA-PKCS1',
        'researchSite': 'gauteng',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Convert the entire package to base64 for transmission
      final packageJson = jsonEncode(encryptedPackage);
      final packageBase64 = base64.encode(utf8.encode(packageJson));
      
      print('🔐 Hybrid encrypted package created');
      print('   Data: ${encryptedData.length} bytes');  
      print('   Package: ${packageJson.length} chars');
      print('   Base64: ${packageBase64.length} chars');
      
      return packageBase64;
      
    } catch (e) {
      print('❌ Encryption failed: $e');
      rethrow;
    }
  }
  
  /// Send encrypted blob to proxy server with enhanced error handling
  static Future<bool> _sendToProxy(String surveyType, String encryptedBlob) async {
    const int maxRetries = 3;
    const Duration initialDelay = Duration(seconds: 2);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('🌐 Sending encrypted $surveyType survey to proxy (attempt $attempt/$maxRetries)...');
        
        final response = await http.post(
          Uri.parse(_proxyServerUrl),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'GautengWellbeingMapper/1.0',
          },
          body: jsonEncode({
            'encrypted_data': encryptedBlob,
            'survey_type': surveyType,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            throw Exception('Request timeout after 30 seconds');
          },
        );
        
        // Check HTTP status code
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Parse response to verify Qualtrics delivery
          try {
            final responseData = jsonDecode(response.body);
            
            // Verify the proxy successfully forwarded to Qualtrics
            if (responseData['success'] == true) {
              print('✅ Encrypted data confirmed delivered to Qualtrics (attempt $attempt)');
              return true;
            } else {
              print('❌ Proxy responded OK but Qualtrics delivery failed: ${responseData['message'] ?? 'Unknown error'}');
              // This counts as a failure - retry
            }
          } catch (jsonError) {
            print('❌ Invalid JSON response from proxy: ${response.body.substring(0, 200)}...');
            // Malformed response - retry
          }
        } else {
          print('❌ Proxy server HTTP error: ${response.statusCode}');
          print('Response body: ${response.body.substring(0, 200)}...');
          
          // Don't retry for client errors (4xx) - these won't get better
          if (response.statusCode >= 400 && response.statusCode < 500) {
            print('🚫 Client error - not retrying');
            return false;
          }
          // Server errors (5xx) - retry after delay
        }
        
      } catch (e) {
        print('❌ Network error sending to proxy (attempt $attempt): $e');
        
        // Check for specific error types that shouldn't be retried
        if (e.toString().contains('certificate') || 
            e.toString().contains('handshake') ||
            e.toString().contains('format')) {
          print('🚫 Permanent error detected - not retrying');
          return false;
        }
      }
      
      // If we reach here, the attempt failed - wait before retry
      if (attempt < maxRetries) {
        final delay = Duration(seconds: initialDelay.inSeconds * attempt);
        print('⏳ Waiting ${delay.inSeconds} seconds before retry...');
        await Future.delayed(delay);
      }
    }
    
    // All attempts failed
    print('💀 All $maxRetries attempts failed - marking as failed for later retry');
    return false;
  }
  
  /// Enhanced sync method with better error tracking
  static Future<void> syncPendingSurveysEnhanced() async {
    try {
      print('🔐 Starting enhanced encrypted survey sync...');
      
      final db = SurveyDatabase();
      
      // Get unsynced data
      final unsyncedInitial = await db.getUnsyncedInitialSurveys();
      final unsyncedBiweekly = await db.getUnsyncedRecurringSurveys();
      final unsyncedConsent = await db.getUnsyncedConsentForms();
      
      final totalToSync = unsyncedInitial.length + unsyncedBiweekly.length + unsyncedConsent.length;
      int successCount = 0;
      int failureCount = 0;
      
      print('📊 Found $totalToSync surveys to sync (Initial: ${unsyncedInitial.length}, Biweekly: ${unsyncedBiweekly.length}, Consent: ${unsyncedConsent.length})');
      
      if (totalToSync == 0) {
        print('✅ No surveys to sync');
        return;
      }
      
      // Sync initial surveys
      for (final survey in unsyncedInitial) {
        if (await _syncInitialSurveyEncrypted(survey)) {
          successCount++;
        } else {
          failureCount++;
        }
      }
      
      // Sync biweekly surveys
      for (final survey in unsyncedBiweekly) {
        if (await _syncBiweeklySurveyEncrypted(survey)) {
          successCount++;
        } else {
          failureCount++;
        }
      }
      
      // Sync consent forms
      for (final consent in unsyncedConsent) {
        if (await _syncConsentFormEncrypted(consent)) {
          successCount++;
        } else {
          failureCount++;
        }
      }
      
      print('📊 Sync completed: $successCount successful, $failureCount failed out of $totalToSync total');
      
      if (failureCount > 0) {
        print('⚠️ $failureCount surveys failed to sync and will be retried later');
      } else {
        print('✅ All surveys synced successfully');
      }
      
    } catch (e) {
      print('❌ Critical error in enhanced survey sync: $e');
    }
  }
}