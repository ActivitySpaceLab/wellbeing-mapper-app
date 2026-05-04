import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import '../db/survey_database.dart';
import '../main.dart';
import '../services/app_mode_service.dart';
import '../models/app_mode.dart';
import '../util/env.dart';

/// Service for encrypting complete survey responses and sending to proxy server
class EncryptedSurveyService {
  
  // AWS Lambda Function URL for encrypted survey proxy (Cape Town region)
  static const String _proxyServerUrl = 'https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws/submit';
  
  // Use the same public key as location encryption for consistency
  static const String _publicKey = '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvzeHQfOYDT8XgiDyHsTG
80/lQY1+AQa2NLIJERK6WuYxVrveDoY5V99V9rlFTRXdYcD5iBDL3WGHQmkOUDQL
PMZ6YjTlU5ACcBf43+yo09Nyt1g7Ib3E95USml2jws7vjZMydhaEcJcBJXb0ty99
EQvis5gJ1GI99BDRzJIArvFTCwsPCm7zan+ai5QPz78SE5RuDwrXloR1vYkf54hN
eyMpUKXFlp3PHKudoE1XlPh9yKkVPPmJkWkl9wECHG+fF8ia/c0/d7IIr1gUWLM1
/IAm6EFnRJLruBOjPK8/3fry9FcDIRv3I8WxVXar8qfVN2mbNtInJ3T2MPXVizqh
VWEWZTYqXiQHQkWjKpbzpVLXzIT7fs3ABk4oBbkH563JSeZHVuv6Xt3DgN7ZzL/Z
QeBb1Gt2dHHGpApT64TTFPv/DFC8CvCauyWEFaAcr3yUr0ah9uGzFtWg/fOWFkDs
lhxw98hOu+mhHVCitzGjLp54zmUASnQfjQLaOEPJITXlX5UYbgbCiH0B4w9NE6o6
F9XaMHUHsRDFZccRlM8AR5fkUVZqiBrI7eHl4e0aSUmc7I8wX3DCA0L16sQQQl18
ZOidCTGzOD8p7DghyDZfnsyBce1qVqJi4bMc05lJSib30DQGMaxbv3hzc/rhmz87
64BAgUuyskUvkMsgsgzf7NcCAwEAAQ==
-----END PUBLIC KEY-----''';

  /// Get current app version from package info
  static Future<String> _getAppVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return '${packageInfo.version}+${packageInfo.buildNumber}';
    } catch (e) {
      debugPrint('⚠️ Error getting app version: $e');
      return '1.0.0'; // Fallback version
    }
  }

  /// Sync all pending surveys as encrypted JSON blobs
  static Future<void> syncPendingSurveys() async {
    try {
      debugPrint('🔐 Starting encrypted survey sync...');
      
      // CRITICAL: Check app mode before any upload operations
      final currentMode = await AppModeService.getCurrentMode();
      debugPrint('[EncryptedSurveyService] Current app mode: ${currentMode.toString()}');
      debugPrint('[EncryptedSurveyService] App flavor: ${AppModeService.appFlavor}');
      debugPrint('[EncryptedSurveyService] Is beta build: ${AppModeService.isBetaBuild}');
      debugPrint('[EncryptedSurveyService] Sends data to research: ${await AppModeService.sendsDataToResearch()}');
      
      // Generate comprehensive mode status report for debugging
      await AppModeService.logModeStatus();
      
      // If in app testing mode, simulate upload but don't actually send data
      if (currentMode == AppMode.appTesting) {
        debugPrint('[EncryptedSurveyService] App Testing Mode: Simulating sync without sending real data');
        await Future.delayed(Duration(seconds: 1));
        debugPrint('✅ Encrypted survey sync completed (simulated)');
        return;
      }
      
      // Only proceed with real upload if in research mode
      if (!await AppModeService.sendsDataToResearch()) {
        debugPrint('[EncryptedSurveyService] ❌ Data upload not available in current app mode');
        debugPrint('[EncryptedSurveyService] ❌ Mode: $currentMode, Sends to research: ${await AppModeService.sendsDataToResearch()}');
        return;
      }
      
      final db = SurveyDatabase();
      
      // Track counts for summary
      int initialCount = 0;
      int biweeklyCount = 0; 
      int consentCount = 0;
      
      // Track successful syncs
      int initialSynced = 0;
      int biweeklySynced = 0;
      int consentSynced = 0;
      
      // CONSENT SAFEGUARD: Check if participant has given consent before syncing surveys
      // (Consent forms are always synced since they ARE the consent)
      final participantUuid = GlobalData.userUUID;
      debugPrint('[EncryptedSurveyService] Participant UUID: ${participantUuid.isNotEmpty ? "present (${participantUuid.length} chars)" : "MISSING"}');
      
      if (participantUuid.isNotEmpty) {
        // Check for research consent (not location sharing consent)
        // Location sharing consent is only needed for location data, not surveys
        final researchConsent = await db.getConsent();
        debugPrint('[EncryptedSurveyService] Research consent found: ${researchConsent != null ? "YES" : "NO"}');
        
        // Sync initial and biweekly surveys if user has research consent
        if (researchConsent != null) {
          debugPrint('[EncryptedSurveyService] ✅ Research consent found, proceeding with survey sync');
          
          // Sync initial surveys
          final unsyncedInitial = await db.getUnsyncedInitialSurveys();
          initialCount = unsyncedInitial.length;
          debugPrint('[EncryptedSurveyService] Unsynced initial surveys: $initialCount');
          for (final survey in unsyncedInitial) {
            debugPrint('[EncryptedSurveyService] Syncing initial survey ID: ${survey['id']}');
            final success = await _syncInitialSurveyEncrypted(survey);
            if (success) {
              initialSynced++;
            } else {
              debugPrint('[EncryptedSurveyService] ❌ Failed to sync initial survey ID: ${survey['id']}');
            }
          }
          
          // Sync biweekly surveys  
          final unsyncedBiweekly = await db.getUnsyncedRecurringSurveys();
          biweeklyCount = unsyncedBiweekly.length;
          debugPrint('[EncryptedSurveyService] Unsynced biweekly surveys: $biweeklyCount');
          for (final survey in unsyncedBiweekly) {
            debugPrint('[EncryptedSurveyService] Syncing biweekly survey ID: ${survey['id']}');
            final success = await _syncBiweeklySurveyEncrypted(survey);
            if (success) {
              biweeklySynced++;
            } else {
              debugPrint('[EncryptedSurveyService] ❌ Failed to sync biweekly survey ID: ${survey['id']}');
            }
          }
        } else {
          debugPrint('[EncryptedSurveyService] ❌ No research consent found, skipping survey sync');
          debugPrint('[EncryptedSurveyService] ❌ User needs to complete consent form in research mode');
        }
      } else {
        debugPrint('[EncryptedSurveyService] ❌ No participant UUID found, skipping survey sync');
        debugPrint('[EncryptedSurveyService] ❌ GlobalData.userUUID is empty - this prevents all uploads!');
      }
      
      // Always sync consent forms (they ARE the consent, so no consent check needed)
      final unsyncedConsent = await db.getUnsyncedConsentForms();
      consentCount = unsyncedConsent.length;
      debugPrint('[EncryptedSurveyService] Unsynced consent forms: $consentCount');
      for (final consent in unsyncedConsent) {
        debugPrint('[EncryptedSurveyService] Syncing consent form ID: ${consent['id']}');
        final success = await _syncConsentFormEncrypted(consent);
        if (success) {
          consentSynced++;
        } else {
          debugPrint('[EncryptedSurveyService] ❌ Failed to sync consent form ID: ${consent['id']}');
        }
      }
      
      // Calculate total attempted vs successful syncs
      final totalAttempted = initialCount + biweeklyCount + consentCount;
      final totalSynced = initialSynced + biweeklySynced + consentSynced;
      
      debugPrint('[EncryptedSurveyService] 📊 Sync Summary:');
      debugPrint('[EncryptedSurveyService] 📊   Initial: $initialSynced/$initialCount synced');
      debugPrint('[EncryptedSurveyService] 📊   Biweekly: $biweeklySynced/$biweeklyCount synced');
      debugPrint('[EncryptedSurveyService] 📊   Consent: $consentSynced/$consentCount synced');
      debugPrint('[EncryptedSurveyService] 📊   Total: $totalSynced/$totalAttempted synced');
      
      if (totalAttempted == 0) {
        debugPrint('[EncryptedSurveyService] ✅ No pending surveys to sync');
      } else if (totalSynced == 0) {
        debugPrint('[EncryptedSurveyService] ❌ All sync attempts failed');
        
        // iOS-specific error messaging
        if (Platform.isIOS) {
          debugPrint('[EncryptedSurveyService] 🍎 iOS Troubleshooting:');
          debugPrint('[EncryptedSurveyService] 🍎   1. Check internet connection (WiFi/cellular)');
          debugPrint('[EncryptedSurveyService] 🍎   2. Try toggling airplane mode on/off');
          debugPrint('[EncryptedSurveyService] 🍎   3. Restart the app');
          debugPrint('[EncryptedSurveyService] 🍎   4. Check if VPN or firewall is blocking the connection');
          debugPrint('[EncryptedSurveyService] 🍎   5. Ensure the app has permission to use cellular data');
          throw Exception('All 3 sync attempts failed. Check your internet connection and try again.');
        } else {
          throw Exception('All $totalAttempted sync attempts failed. Check network connection and proxy server status.');
        }
      } else if (totalSynced < totalAttempted) {
        debugPrint('[EncryptedSurveyService] ⚠️ Partial sync success: $totalSynced out of $totalAttempted');
        throw Exception('Partial sync failure: Only $totalSynced out of $totalAttempted surveys uploaded successfully.');
      } else {
        debugPrint('[EncryptedSurveyService] ✅ All surveys synced successfully');
      }
      
    } catch (e) {
      debugPrint('[EncryptedSurveyService] ❌ Error in sync: $e');
      rethrow;
    }
  }
  
  /// Encrypt and sync initial survey
  static Future<bool> _syncInitialSurveyEncrypted(Map<String, dynamic> surveyData) async {
    try {
      debugPrint('🔐 Encrypting and syncing initial survey...');
      
      // Get current app version
      final appVersion = await _getAppVersion();
      
      // Process images if they exist
      List<String>? encryptedImages;
      if (surveyData['image_urls'] != null) {
        encryptedImages = await _processImagesForEncryption(surveyData['image_urls'].toString());
      }
      
      // Create complete survey JSON
      final surveyJson = {
        'type': 'initial_survey',
        'participant_uuid': GlobalData.userUUID,
        'survey_id': surveyData['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'data': surveyData,
        'encrypted_images': encryptedImages, // Include encrypted image data
        'metadata': {
          'app_version': appVersion,
          'submission_method': 'encrypted_proxy',
          'has_images': encryptedImages != null && encryptedImages.isNotEmpty,
        }
      };
      
      // Encrypt the entire JSON
      debugPrint('🔐 Starting encryption process...');
      final encryptedBlob = await _encryptSurveyData(surveyJson);
      debugPrint('🔐 Encryption completed, blob size: ${encryptedBlob.length} characters');

      // Send to proxy server
      debugPrint('🌐 Sending to proxy server...');
      final success = await _sendToProxy('initial', encryptedBlob);      if (success) {
        final db = SurveyDatabase();
        await db.markInitialSurveySynced(surveyData['id']);
        debugPrint('✅ Initial survey encrypted and synced');
        return true;
      }
      
      return false;
      
    } catch (e) {
      debugPrint('❌ Error encrypting initial survey: $e');
      return false;
    }
  }
  
  /// Encrypt and sync biweekly survey
  static Future<bool> _syncBiweeklySurveyEncrypted(Map<String, dynamic> surveyData) async {
    try {
      debugPrint('🔐 Encrypting and syncing biweekly survey...');
      debugPrint('🔄 Survey data keys: ${surveyData.keys.join(', ')}');
      debugPrint('🔄 Survey ID: ${surveyData['id']}');
      
      // Get current app version
      final appVersion = await _getAppVersion();
      
      // Include location data if available - now as part of unified survey JSON
      Map<String, dynamic>? locationData;
      if (surveyData['encrypted_location_data'] != null) {
        try {
          // Parse the location data JSON and include it directly in survey
          locationData = jsonDecode(surveyData['encrypted_location_data'].toString());
        } catch (e) {
          debugPrint('⚠️ Error parsing location data: $e');
          locationData = null;
        }
      } else if (surveyData['location_data'] != null) {
        try {
          // Fallback for legacy field name
          locationData = jsonDecode(surveyData['location_data'].toString());
        } catch (e) {
          debugPrint('⚠️ Error parsing legacy location data: $e');
          locationData = null;
        }
      }
      
      // Process images if they exist
      List<String>? encryptedImages;
      if (surveyData['image_urls'] != null) {
        encryptedImages = await _processImagesForEncryption(surveyData['image_urls'].toString());
      }
      // Create complete survey JSON
      final userUUID = GlobalData.userUUID;
      
      final surveyJson = {
        'type': 'biweekly_survey',
        'participant_uuid': userUUID,
        'survey_id': surveyData['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'data': surveyData,
        'encrypted_images': encryptedImages, // Include encrypted image data
        'location_data': locationData, // Include parsed location data directly
        'metadata': {
          'app_version': appVersion,
          'submission_method': 'encrypted_proxy',
          'encryption_unified': true, // Flag to indicate unified encryption approach
          'has_images': encryptedImages != null && encryptedImages.isNotEmpty,
        }
      };
      debugPrint('🔄 Survey JSON structure created successfully');

      // Encrypt the entire JSON
      debugPrint('🔐 Starting encryption process...');
      final encryptedBlob = await _encryptSurveyData(surveyJson);
      debugPrint('🔐 Encryption completed, blob size: ${encryptedBlob.length} characters');
      
      // Send to proxy server
      debugPrint('🌐 Sending to proxy server...');
      final success = await _sendToProxy('biweekly', encryptedBlob);
      
      if (success) {
        final db = SurveyDatabase();
        await db.markRecurringSurveySynced(surveyData['id']);
        debugPrint('✅ Biweekly survey encrypted and synced');
        return true;
      }
      
      return false;
      
    } catch (e) {
      debugPrint('[EncryptedSurveyService] ❌ Error syncing biweekly survey: $e');
      return false;
    }
  }
  
  /// Encrypt and sync consent form
  static Future<bool> _syncConsentFormEncrypted(Map<String, dynamic> consentData) async {
    try {
      debugPrint('🔐 Encrypting and syncing consent form...');
      
      // Get current app version
      final appVersion = await _getAppVersion();
      
      final consentJson = {
        'type': 'consent_form',
        'participant_uuid': GlobalData.userUUID,
        'consent_id': consentData['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'data': consentData,
        'metadata': {
          'app_version': appVersion,
          'submission_method': 'encrypted_proxy',
        }
      };
      
      final encryptedBlob = await _encryptSurveyData(consentJson);
      final success = await _sendToProxy('consent', encryptedBlob);
      
      if (success) {
        final db = SurveyDatabase();
        await db.markConsentFormSynced(consentData['id']);
        debugPrint('✅ Consent form encrypted and synced');
        return true;
      }
      
      return false;
      
    } catch (e) {
      debugPrint('❌ Error encrypting consent form: $e');
      return false;
    }
  }
  
  /// Process images for encryption - converts local file paths to base64 data
  static Future<List<String>?> _processImagesForEncryption(String? imageUrlsJson) async {
    debugPrint('🐛 DEBUG: _processImagesForEncryption called with: "$imageUrlsJson"');
    if (imageUrlsJson == null || imageUrlsJson.isEmpty) {
      debugPrint('🐛 DEBUG: imageUrlsJson is null or empty, returning null');
      return null;
    }
    
    try {
      // Parse the JSON list of image URLs
      final imageUrls = List<String>.from(jsonDecode(imageUrlsJson));
      final List<String> base64Images = [];
      
      // Photo functionality removed for production reliability
      // Strip any existing photos from legacy surveys for backward compatibility
      if (imageUrls.isNotEmpty) {
        debugPrint('📷 Removing ${imageUrls.length} photos from legacy survey for reliable upload');
        imageUrls.clear(); // Remove all photos
      }
      debugPrint('📷 Photo upload disabled - survey will upload without images');
      
      // Photo processing removed - surveys upload without images for reliability
      
      debugPrint('📷 Successfully processed ${base64Images.length}/${imageUrls.length} images');
      
      // Log total image data size
      if (base64Images.isNotEmpty) {
        final totalImageDataSize = base64Images.fold<int>(0, (sum, img) => sum + img.length);
        final totalImageSizeInMB = totalImageDataSize / (1024 * 1024);
        debugPrint('📷 Total image data size: ${totalImageSizeInMB.toStringAsFixed(2)}MB');
        
        if (totalImageSizeInMB > 4.0) {
          debugPrint('⚠️ WARNING: Image data alone is ${totalImageSizeInMB.toStringAsFixed(2)}MB - may cause size issues!');
        }
      }
      
      return base64Images.isNotEmpty ? base64Images : null;
      
    } catch (e) {
      debugPrint('❌ Error processing images for encryption: $e');
      return null;
    }
  }
  
  /// Encrypt survey data using hybrid AES/RSA encryption
  static Future<String> _encryptSurveyData(Map<String, dynamic> surveyJson) async {
    try {
      // Log whether images are included
      final hasImages = surveyJson['encrypted_images'] != null && (surveyJson['encrypted_images'] as List).isNotEmpty;
      if (hasImages) {
        final imageCount = (surveyJson['encrypted_images'] as List).length;
        debugPrint('🔐 Encrypting survey with $imageCount images included');
      } else {
        debugPrint('🔐 Encrypting survey (no images)');
      }
      
      // Convert to JSON string
      final jsonString = jsonEncode(surveyJson);
      debugPrint('📄 Survey JSON size: ${jsonString.length} characters');
      
      // Check if payload might be too large for AWS Lambda (6MB limit)
      final jsonSizeInMB = jsonString.length / (1024 * 1024);
      if (jsonSizeInMB > 5.0) {
        debugPrint('⚠️ WARNING: Survey JSON is ${jsonSizeInMB.toStringAsFixed(2)}MB - may exceed AWS Lambda 6MB limit!');
      } else if (jsonSizeInMB > 2.0) {
        debugPrint('⚠️ Large payload: ${jsonSizeInMB.toStringAsFixed(2)}MB');
      } else {
        debugPrint('✅ Payload size: ${jsonSizeInMB.toStringAsFixed(2)}MB');
      }
      
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
      
      String encryptedKey;
      try {
        encryptedKey = await RSA.encryptPKCS1v15(aesKeyBase64, _publicKey);
      } catch (rsaError) {
        debugPrint('❌ RSA encryption failed: $rsaError');
        rethrow;
      }
      
      if (encryptedKey.isEmpty) {
        throw Exception('RSA encryption failed: encryptedKey is empty');
      }
      
      // Create encrypted package
      final encryptedPackage = {
        'encryptedData': base64.encode(encryptedData),
        'encryptedKey': encryptedKey,
        'algorithm': 'AES-256-GCM + RSA-PKCS1',
        'researchSite': ENV.researchSite,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      // Convert the entire package to base64 for transmission
      final packageJson = jsonEncode(encryptedPackage);
      final packageBase64 = base64.encode(utf8.encode(packageJson));
      
      debugPrint('🔐 Hybrid encrypted package created');
      debugPrint('   Data: ${encryptedData.length} bytes');  
      debugPrint('   Package: ${packageJson.length} chars');
      debugPrint('   Base64: ${packageBase64.length} chars');
      
      // Data integrity check - verify the base64 is valid
      try {
        final testDecode = utf8.decode(base64.decode(packageBase64));
        jsonDecode(testDecode); // Verify JSON is parseable
        debugPrint('✅ Package integrity verified');
      } catch (e) {
        debugPrint('❌ Package integrity check failed: $e');
        throw Exception('Encrypted package corrupted during encoding');
      }
      
      return packageBase64;
      
    } catch (e) {
      debugPrint('❌ Encryption failed: $e');
      rethrow;
    }
  }
  
    /// Send encrypted blob to proxy server with enhanced error handling
  static Future<bool> _sendToProxy(String surveyType, String encryptedBlob) async {
    const int maxRetries = 3;
    const Duration initialDelay = Duration(seconds: 2);
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('🌐 Sending encrypted $surveyType survey to proxy (attempt $attempt/$maxRetries)...');
        
        // iOS-specific: Increase timeout for AWS Lambda function URLs
        final Duration timeout = Platform.isIOS ? Duration(seconds: 45) : Duration(seconds: 30);
        
        final headers = {
          'Content-Type': 'application/json',
          'User-Agent': 'WellbeingMapper/1.0',
          // iOS-specific: Add explicit connection headers
          if (Platform.isIOS) ...{
            'Connection': 'keep-alive',
            'Accept-Encoding': 'gzip, deflate',
          },
        };
        
        final body = jsonEncode({
          'encrypted_data': encryptedBlob,
          'survey_type': surveyType,
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        final response = await http.post(
          Uri.parse(_proxyServerUrl),
          headers: headers,
          body: body,
        ).timeout(
          timeout,
          onTimeout: () {
            debugPrint('⏰ Request timed out after ${timeout.inSeconds} seconds');
            throw Exception('Request timeout after ${timeout.inSeconds} seconds');
          },
        );
        
        // Check HTTP status code
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Parse response to verify Qualtrics delivery
          try {
            final responseData = jsonDecode(response.body);
            
            // Verify the proxy successfully forwarded to Qualtrics
            if (responseData['success'] == true) {
              debugPrint('✅ Encrypted data confirmed delivered to Qualtrics (attempt $attempt)');
              return true;
            } else {
              debugPrint('❌ Proxy responded OK but Qualtrics delivery failed: ${responseData['message'] ?? 'Unknown error'}');
              // This counts as a failure - retry
            }
          } catch (jsonError) {
            final bodyPreview = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
            debugPrint('❌ Invalid JSON response from proxy: $bodyPreview');
            // Malformed response - retry
          }
        } else {
          debugPrint('❌ Proxy server HTTP error: ${response.statusCode}');
          final bodyPreview = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
          debugPrint('❌ Response body: $bodyPreview');
          debugPrint('❌ Request size: ${encryptedBlob.length} characters');
          
          // Don't retry for client errors (4xx) - these won't get better
          if (response.statusCode >= 400 && response.statusCode < 500) {
            debugPrint('🚫 Client error - not retrying');
            return false;
          }
          // Server errors (5xx) - retry after delay
        }
        
      } catch (e) {
        debugPrint('❌ Network error sending to proxy (attempt $attempt): $e');
        
        // Check for specific error types that shouldn't be retried
        if (e.toString().contains('certificate') || 
            e.toString().contains('handshake') ||
            e.toString().contains('format')) {
          debugPrint('🚫 Permanent error detected - not retrying');
          return false;
        }
      }
      
      // If we reach here, the attempt failed - wait before retry
      if (attempt < maxRetries) {
        // Exponential backoff with jitter: 2s, 4s, 8s + random 0-2s
        final baseDelay = initialDelay.inSeconds * (1 << (attempt - 1)); // 2^(attempt-1)
        final jitter = (DateTime.now().millisecondsSinceEpoch % 2000) / 1000; // 0-2 seconds
        final delay = Duration(milliseconds: ((baseDelay + jitter) * 1000).round());
        debugPrint('⏳ Waiting ${delay.inSeconds}.${(delay.inMilliseconds % 1000).toString().padLeft(3, '0')}s before retry (exponential backoff)...');
        await Future.delayed(delay);
      }
    }
    
    // All attempts failed
    debugPrint('💀 All $maxRetries attempts failed - marking as failed for later retry');
    return false;
  }
  
  /// Enhanced sync method with better error tracking
  static Future<void> syncPendingSurveysEnhanced() async {
    try {
      debugPrint('🔐 Starting enhanced encrypted survey sync...');
      
      final db = SurveyDatabase();
      
      // Get unsynced data
      final unsyncedInitial = await db.getUnsyncedInitialSurveys();
      final unsyncedBiweekly = await db.getUnsyncedRecurringSurveys();
      final unsyncedConsent = await db.getUnsyncedConsentForms();
      
      final totalToSync = unsyncedInitial.length + unsyncedBiweekly.length + unsyncedConsent.length;
      int successCount = 0;
      int failureCount = 0;
      
      debugPrint('📊 Found $totalToSync surveys to sync (Initial: ${unsyncedInitial.length}, Biweekly: ${unsyncedBiweekly.length}, Consent: ${unsyncedConsent.length})');
      
      if (totalToSync == 0) {
        debugPrint('✅ No surveys to sync');
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
      
      debugPrint('📊 Sync completed: $successCount successful, $failureCount failed out of $totalToSync total');
      
      if (failureCount > 0) {
        debugPrint('⚠️ $failureCount surveys failed to sync and will be retried later');
      } else {
        debugPrint('✅ All surveys synced successfully');
      }
      
    } catch (e) {
      debugPrint('❌ Critical error in enhanced survey sync: $e');
    }
  }

  // Photo compression function removed - no longer needed
}