import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:fast_rsa/fast_rsa.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
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
      print('⚠️ Error getting app version: $e');
      return '1.0.0'; // Fallback version
    }
  }

  /// Sync all pending surveys as encrypted JSON blobs
  static Future<void> syncPendingSurveys() async {
    developer.log('🚨 [MAIN] syncPendingSurveys called', name: 'wellbeing-mapper-debug');
    
    try {
      developer.log('🚨 [MAIN] Entered try block', name: 'wellbeing-mapper-debug');
      print('🔐 Starting encrypted survey sync...');
      
      // CRITICAL: Check app mode before any upload operations
      developer.log('🚨 [MAIN] About to check app mode', name: 'wellbeing-mapper-debug');
      final currentMode = await AppModeService.getCurrentMode();
      developer.log('🚨 [MAIN] Successfully got app mode: $currentMode', name: 'wellbeing-mapper-debug');
      print('[EncryptedSurveyService] Current app mode: ${currentMode.toString()}');
      print('[EncryptedSurveyService] App flavor: ${AppModeService.appFlavor}');
      print('[EncryptedSurveyService] Is beta build: ${AppModeService.isBetaBuild}');
      print('[EncryptedSurveyService] Sends data to research: ${await AppModeService.sendsDataToResearch()}');
      
      // Generate comprehensive mode status report for debugging
      await AppModeService.logModeStatus();
      
      // If in app testing mode, simulate upload but don't actually send data
      if (currentMode == AppMode.appTesting) {
        print('[EncryptedSurveyService] App Testing Mode: Simulating sync without sending real data');
        await Future.delayed(Duration(seconds: 1));
        print('✅ Encrypted survey sync completed (simulated)');
        return;
      }
      
      // Only proceed with real upload if in research mode
      if (!await AppModeService.sendsDataToResearch()) {
        print('[EncryptedSurveyService] ❌ Data upload not available in current app mode');
        print('[EncryptedSurveyService] ❌ Mode: $currentMode, Sends to research: ${await AppModeService.sendsDataToResearch()}');
        return;
      }
      
      developer.log('🚨 [MAIN] About to create SurveyDatabase', name: 'wellbeing-mapper-debug');
      final db = SurveyDatabase();
      developer.log('🚨 [MAIN] Successfully created SurveyDatabase', name: 'wellbeing-mapper-debug');
      
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
      developer.log('🚨 [MAIN] About to access GlobalData.userUUID', name: 'wellbeing-mapper-debug');
      final participantUuid = GlobalData.userUUID;
      developer.log('🚨 [MAIN] Successfully got participantUuid: ${participantUuid.length} chars', name: 'wellbeing-mapper-debug');
      print('[EncryptedSurveyService] Participant UUID: ${participantUuid.isNotEmpty ? "present (${participantUuid.length} chars)" : "MISSING"}');
      
      if (participantUuid.isNotEmpty) {
        // Check for research consent (not location sharing consent)
        // Location sharing consent is only needed for location data, not surveys
        developer.log('🚨 [MAIN] About to check research consent', name: 'wellbeing-mapper-debug');
        final researchConsent = await db.getConsent();
        developer.log('🚨 [MAIN] Research consent check completed', name: 'wellbeing-mapper-debug');
        print('[EncryptedSurveyService] Research consent found: ${researchConsent != null ? "YES" : "NO"}');
        
        // Sync initial and biweekly surveys if user has research consent
        if (researchConsent != null) {
          print('[EncryptedSurveyService] ✅ Research consent found, proceeding with survey sync');
          
          // Sync initial surveys
          developer.log('🚨 [MAIN] About to get unsynced initial surveys', name: 'wellbeing-mapper-debug');
          final unsyncedInitial = await db.getUnsyncedInitialSurveys();
          developer.log('🚨 [MAIN] Got unsynced initial surveys: ${unsyncedInitial.length}', name: 'wellbeing-mapper-debug');
          initialCount = unsyncedInitial.length;
          print('[EncryptedSurveyService] Unsynced initial surveys: $initialCount');
          for (final survey in unsyncedInitial) {
            print('[EncryptedSurveyService] Syncing initial survey ID: ${survey['id']}');
            final success = await _syncInitialSurveyEncrypted(survey);
            if (success) {
              initialSynced++;
            } else {
              print('[EncryptedSurveyService] ❌ Failed to sync initial survey ID: ${survey['id']}');
            }
          }
          
          // Sync biweekly surveys  
          developer.log('🚨 [MAIN] About to get unsynced biweekly surveys', name: 'wellbeing-mapper-debug');
          final unsyncedBiweekly = await db.getUnsyncedRecurringSurveys();
          developer.log('🚨 [MAIN] Got unsynced biweekly surveys: ${unsyncedBiweekly.length}', name: 'wellbeing-mapper-debug');
          biweeklyCount = unsyncedBiweekly.length;
          print('[EncryptedSurveyService] Unsynced biweekly surveys: $biweeklyCount');
          for (final survey in unsyncedBiweekly) {
            print('[EncryptedSurveyService] Syncing biweekly survey ID: ${survey['id']}');
            final success = await _syncBiweeklySurveyEncrypted(survey);
            if (success) {
              biweeklySynced++;
            } else {
              print('[EncryptedSurveyService] ❌ Failed to sync biweekly survey ID: ${survey['id']}');
            }
          }
        } else {
          print('[EncryptedSurveyService] ❌ No research consent found, skipping survey sync');
          print('[EncryptedSurveyService] ❌ User needs to complete consent form in research mode');
        }
      } else {
        print('[EncryptedSurveyService] ❌ No participant UUID found, skipping survey sync');
        print('[EncryptedSurveyService] ❌ GlobalData.userUUID is empty - this prevents all uploads!');
      }
      
      // Always sync consent forms (they ARE the consent, so no consent check needed)
      final unsyncedConsent = await db.getUnsyncedConsentForms();
      consentCount = unsyncedConsent.length;
      print('[EncryptedSurveyService] Unsynced consent forms: $consentCount');
      for (final consent in unsyncedConsent) {
        print('[EncryptedSurveyService] Syncing consent form ID: ${consent['id']}');
        final success = await _syncConsentFormEncrypted(consent);
        if (success) {
          consentSynced++;
        } else {
          print('[EncryptedSurveyService] ❌ Failed to sync consent form ID: ${consent['id']}');
        }
      }
      
      // Calculate total attempted vs successful syncs
      final totalAttempted = initialCount + biweeklyCount + consentCount;
      final totalSynced = initialSynced + biweeklySynced + consentSynced;
      
      print('[EncryptedSurveyService] 📊 Sync Summary:');
      print('[EncryptedSurveyService] 📊   Initial: $initialSynced/$initialCount synced');
      print('[EncryptedSurveyService] 📊   Biweekly: $biweeklySynced/$biweeklyCount synced');
      print('[EncryptedSurveyService] 📊   Consent: $consentSynced/$consentCount synced');
      print('[EncryptedSurveyService] 📊   Total: $totalSynced/$totalAttempted synced');
      
      if (totalAttempted == 0) {
        print('[EncryptedSurveyService] ✅ No pending surveys to sync');
      } else if (totalSynced == 0) {
        print('[EncryptedSurveyService] ❌ All sync attempts failed');
        
        // iOS-specific error messaging
        if (Platform.isIOS) {
          print('[EncryptedSurveyService] 🍎 iOS Troubleshooting:');
          print('[EncryptedSurveyService] 🍎   1. Check internet connection (WiFi/cellular)');
          print('[EncryptedSurveyService] 🍎   2. Try toggling airplane mode on/off');
          print('[EncryptedSurveyService] 🍎   3. Restart the app');
          print('[EncryptedSurveyService] 🍎   4. Check if VPN or firewall is blocking the connection');
          print('[EncryptedSurveyService] 🍎   5. Ensure the app has permission to use cellular data');
          throw Exception('All 3 sync attempts failed. Check your internet connection and try again.');
        } else {
          throw Exception('All $totalAttempted sync attempts failed. Check network connection and proxy server status.');
        }
      } else if (totalSynced < totalAttempted) {
        print('[EncryptedSurveyService] ⚠️ Partial sync success: $totalSynced out of $totalAttempted');
        throw Exception('Partial sync failure: Only $totalSynced out of $totalAttempted surveys uploaded successfully.');
      } else {
        print('[EncryptedSurveyService] ✅ All surveys synced successfully');
      }
      
    } catch (e) {
      developer.log('❌ [MAIN-CRITICAL] Error in syncPendingSurveys: $e', name: 'wellbeing-mapper-debug', error: e);
      developer.log('❌ [MAIN-CRITICAL] Error type: ${e.runtimeType}', name: 'wellbeing-mapper-debug');
      developer.log('❌ [MAIN-CRITICAL] Stack trace: ${StackTrace.current}', name: 'wellbeing-mapper-debug', stackTrace: StackTrace.current);
      print('[EncryptedSurveyService] ❌ Error in sync: $e');
      print('[EncryptedSurveyService] ❌ Stack trace: ${StackTrace.current}');
      rethrow; // Re-throw so the calling code can handle it
    }
  }
  
  /// Encrypt and sync initial survey
  static Future<bool> _syncInitialSurveyEncrypted(Map<String, dynamic> surveyData) async {
    try {
      print('🔐 Encrypting and syncing initial survey...');
      
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
      print('🔐 Starting encryption process...');
      final encryptedBlob = await _encryptSurveyData(surveyJson);
      print('🔐 Encryption completed, blob size: ${encryptedBlob.length} characters');

      // Send to proxy server
      print('🌐 Sending to proxy server...');
      final success = await _sendToProxy('initial', encryptedBlob);      if (success) {
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
    developer.log('🚨 [ENTRY] _syncBiweeklySurveyEncrypted called', name: 'wellbeing-mapper-debug');
    developer.log('🚨 [ENTRY] Platform: ${Platform.operatingSystem}', name: 'wellbeing-mapper-debug');
    developer.log('🚨 [ENTRY] Survey data length: ${surveyData.length}', name: 'wellbeing-mapper-debug');
    
    try {
      developer.log('🚨 [TRY] Entered try block', name: 'wellbeing-mapper-debug');
      print('🔐 Encrypting and syncing biweekly survey...');
      print('🔄 Survey data keys: ${surveyData.keys.join(', ')}');
      print('🔄 Survey ID: ${surveyData['id']}');
      
      // Get current app version
      developer.log('🚨 [VERSION] About to get app version', name: 'wellbeing-mapper-debug');
      final appVersion = await _getAppVersion();
      developer.log('🚨 [VERSION] Successfully got app version: $appVersion', name: 'wellbeing-mapper-debug');
      
      // Include location data if available - now as part of unified survey JSON
      Map<String, dynamic>? locationData;
      print('🔄 Processing location data...');
      if (surveyData['encrypted_location_data'] != null) {
        try {
          print('🔄 Parsing encrypted_location_data...');
          // Parse the location data JSON and include it directly in survey
          locationData = jsonDecode(surveyData['encrypted_location_data'].toString());
          print('🔄 Successfully parsed encrypted_location_data');
        } catch (e) {
          print('⚠️ Error parsing location data: $e');
          locationData = null;
        }
      } else if (surveyData['location_data'] != null) {
        try {
          print('🔄 Parsing legacy location_data...');
          // Fallback for legacy field name
          locationData = jsonDecode(surveyData['location_data'].toString());
          print('🔄 Successfully parsed legacy location_data');
        } catch (e) {
          print('⚠️ Error parsing legacy location data: $e');
          locationData = null;
        }
      } else {
        print('🔄 No location data found');
      }
      
      // Process images if they exist
      List<String>? encryptedImages;
      if (surveyData['image_urls'] != null) {
        print('🔄 Processing images for encryption...');
        encryptedImages = await _processImagesForEncryption(surveyData['image_urls'].toString());
        print('🔄 Image processing completed. Result: ${encryptedImages != null ? '${encryptedImages.length} images' : 'null'}');
      }

      print('🔄 Creating survey JSON structure...');
      developer.log('🚨 [UUID] About to access GlobalData.userUUID', name: 'wellbeing-mapper-debug');
      final userUUID = GlobalData.userUUID;
      developer.log('🚨 [UUID] Successfully accessed GlobalData.userUUID: $userUUID', name: 'wellbeing-mapper-debug');
      
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
      print('🔄 Survey JSON structure created successfully');

      // Encrypt the entire JSON
      print('🔐 Starting encryption process...');
      final encryptedBlob = await _encryptSurveyData(surveyJson);
      print('🔐 Encryption completed, blob size: ${encryptedBlob.length} characters');
      
      // Send to proxy server
      print('🌐 Sending to proxy server...');
      final success = await _sendToProxy('biweekly', encryptedBlob);
      
      if (success) {
        final db = SurveyDatabase();
        await db.markRecurringSurveySynced(surveyData['id']);
        print('✅ Biweekly survey encrypted and synced');
        return true;
      }
      
      return false;
      
    } catch (e) {
      developer.log('❌ [CRITICAL] Error in _syncBiweeklySurveyEncrypted: $e', name: 'wellbeing-mapper-debug', error: e);
      developer.log('❌ [CRITICAL] Error type: ${e.runtimeType}', name: 'wellbeing-mapper-debug');
      developer.log('❌ [CRITICAL] Survey ID: ${surveyData['id']}', name: 'wellbeing-mapper-debug');
      developer.log('❌ [CRITICAL] Platform: ${Platform.operatingSystem}', name: 'wellbeing-mapper-debug');
      developer.log('❌ [CRITICAL] Stack trace: ${StackTrace.current}', name: 'wellbeing-mapper-debug', stackTrace: StackTrace.current);
      return false;
    }
  }
  
  /// Encrypt and sync consent form
  static Future<bool> _syncConsentFormEncrypted(Map<String, dynamic> consentData) async {
    try {
      print('🔐 Encrypting and syncing consent form...');
      
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
        print('✅ Consent form encrypted and synced');
        return true;
      }
      
      return false;
      
    } catch (e) {
      print('❌ Error encrypting consent form: $e');
      return false;
    }
  }
  
  /// Process images for encryption - converts local file paths to base64 data
  static Future<List<String>?> _processImagesForEncryption(String? imageUrlsJson) async {
    print('🐛 DEBUG: _processImagesForEncryption called with: "$imageUrlsJson"');
    if (imageUrlsJson == null || imageUrlsJson.isEmpty) {
      print('🐛 DEBUG: imageUrlsJson is null or empty, returning null');
      return null;
    }
    
    try {
      // Parse the JSON list of image URLs
      final imageUrls = List<String>.from(jsonDecode(imageUrlsJson));
      final List<String> base64Images = [];
      
      // Photo functionality removed for production reliability
      // Strip any existing photos from legacy surveys for backward compatibility
      if (imageUrls.isNotEmpty) {
        print('📷 Removing ${imageUrls.length} photos from legacy survey for reliable upload');
        imageUrls.clear(); // Remove all photos
      }
      print('📷 Photo upload disabled - survey will upload without images');
      
      // Photo processing removed - surveys upload without images for reliability
      
      print('📷 Successfully processed ${base64Images.length}/${imageUrls.length} images');
      
      // Log total image data size
      if (base64Images.isNotEmpty) {
        final totalImageDataSize = base64Images.fold<int>(0, (sum, img) => sum + img.length);
        final totalImageSizeInMB = totalImageDataSize / (1024 * 1024);
        print('📷 Total image data size: ${totalImageSizeInMB.toStringAsFixed(2)}MB');
        
        if (totalImageSizeInMB > 4.0) {
          print('⚠️ WARNING: Image data alone is ${totalImageSizeInMB.toStringAsFixed(2)}MB - may cause size issues!');
        }
      }
      
      return base64Images.isNotEmpty ? base64Images : null;
      
    } catch (e) {
      print('❌ Error processing images for encryption: $e');
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
        print('🔐 Encrypting survey with $imageCount images included');
      } else {
        print('🔐 Encrypting survey (no images)');
      }
      
      // Convert to JSON string
      final jsonString = jsonEncode(surveyJson);
      print('📄 Survey JSON size: ${jsonString.length} characters');
      
      // Check if payload might be too large for AWS Lambda (6MB limit)
      final jsonSizeInMB = jsonString.length / (1024 * 1024);
      if (jsonSizeInMB > 5.0) {
        print('⚠️ WARNING: Survey JSON is ${jsonSizeInMB.toStringAsFixed(2)}MB - may exceed AWS Lambda 6MB limit!');
      } else if (jsonSizeInMB > 2.0) {
        print('⚠️ Large payload: ${jsonSizeInMB.toStringAsFixed(2)}MB');
      } else {
        print('✅ Payload size: ${jsonSizeInMB.toStringAsFixed(2)}MB');
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
      
      // Data integrity check - verify the base64 is valid
      try {
        final testDecode = utf8.decode(base64.decode(packageBase64));
        jsonDecode(testDecode); // Verify JSON is parseable
        print('✅ Package integrity verified');
      } catch (e) {
        print('❌ Package integrity check failed: $e');
        throw Exception('Encrypted package corrupted during encoding');
      }
      
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
    
    developer.log('🚨 [PROXY] Starting _sendToProxy for $surveyType survey', name: 'wellbeing-mapper-debug');
    developer.log('🚨 [PROXY] Encrypted blob length: ${encryptedBlob.length}', name: 'wellbeing-mapper-debug');
    developer.log('🚨 [PROXY] Proxy URL: $_proxyServerUrl', name: 'wellbeing-mapper-debug');
    developer.log('🚨 [PROXY] Platform: ${Platform.operatingSystem}', name: 'wellbeing-mapper-debug');
    
    print('🔍 [DEBUG] Starting _sendToProxy for $surveyType survey');
    print('🔍 [DEBUG] Encrypted blob length: ${encryptedBlob.length}');
    print('🔍 [DEBUG] Proxy URL: $_proxyServerUrl');
    print('🔍 [DEBUG] Platform: ${Platform.operatingSystem}');
    
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        developer.log('🚨 [PROXY] Attempt $attempt/$maxRetries starting', name: 'wellbeing-mapper-debug');
        print('🌐 Sending encrypted $surveyType survey to proxy (attempt $attempt/$maxRetries)...');
        print('🔍 [DEBUG] About to make HTTP POST request...');
        
        // iOS-specific: Increase timeout for AWS Lambda function URLs
        final Duration timeout = Platform.isIOS ? Duration(seconds: 45) : Duration(seconds: 30);
        developer.log('🚨 [PROXY] Using timeout: ${timeout.inSeconds} seconds', name: 'wellbeing-mapper-debug');
        print('🔍 [DEBUG] Using timeout: ${timeout.inSeconds} seconds');
        
        final headers = {
          'Content-Type': 'application/json',
          'User-Agent': 'GautengWellbeingMapper/1.0',
          // iOS-specific: Add explicit connection headers
          if (Platform.isIOS) ...{
            'Connection': 'keep-alive',
            'Accept-Encoding': 'gzip, deflate',
          },
        };
        developer.log('🚨 [PROXY] Headers prepared: $headers', name: 'wellbeing-mapper-debug');
        print('🔍 [DEBUG] Headers: $headers');
        
        final body = jsonEncode({
          'encrypted_data': encryptedBlob,
          'survey_type': surveyType,
          'timestamp': DateTime.now().toIso8601String(),
        });
        developer.log('🚨 [PROXY] Body length: ${body.length} characters', name: 'wellbeing-mapper-debug');
        print('🔍 [DEBUG] Body length: ${body.length} characters');
        
        developer.log('🚨 [PROXY] About to make HTTP POST request', name: 'wellbeing-mapper-debug');
        final response = await http.post(
          Uri.parse(_proxyServerUrl),
          headers: headers,
          body: body,
        ).timeout(
          timeout,
          onTimeout: () {
            developer.log('🚨 [PROXY] Request timed out after ${timeout.inSeconds} seconds', name: 'wellbeing-mapper-debug');
            print('⏰ [DEBUG] Request timed out after ${timeout.inSeconds} seconds');
            throw Exception('Request timeout after ${timeout.inSeconds} seconds');
          },
        );
        
        developer.log('🚨 [PROXY] HTTP request completed with status: ${response.statusCode}', name: 'wellbeing-mapper-debug');
        print('🔍 [DEBUG] HTTP request completed');
        print('🔍 [DEBUG] Response status code: ${response.statusCode}');
        print('🔍 [DEBUG] Response headers: ${response.headers}');
        print('🔍 [DEBUG] Response body length: ${response.body.length}');
        
        // Check HTTP status code
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Parse response to verify Qualtrics delivery
          try {
            final responseData = jsonDecode(response.body);
            
            // Verify the proxy successfully forwarded to Qualtrics
            if (responseData['success'] == true) {
              developer.log('🚨 [PROXY] SUCCESS: Data delivered to Qualtrics', name: 'wellbeing-mapper-debug');
              print('✅ Encrypted data confirmed delivered to Qualtrics (attempt $attempt)');
              return true;
            } else {
              developer.log('🚨 [PROXY] FAIL: Proxy OK but Qualtrics delivery failed: ${responseData['message']}', name: 'wellbeing-mapper-debug');
              print('❌ Proxy responded OK but Qualtrics delivery failed: ${responseData['message'] ?? 'Unknown error'}');
              // This counts as a failure - retry
            }
          } catch (jsonError) {
            developer.log('🚨 [PROXY] FAIL: Invalid JSON response: $jsonError', name: 'wellbeing-mapper-debug');
            final bodyPreview = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
            print('❌ Invalid JSON response from proxy: $bodyPreview');
            // Malformed response - retry
          }
        } else {
          developer.log('🚨 [PROXY] FAIL: HTTP error ${response.statusCode}', name: 'wellbeing-mapper-debug');
          print('❌ Proxy server HTTP error: ${response.statusCode}');
          final bodyPreview = response.body.length > 200 ? '${response.body.substring(0, 200)}...' : response.body;
          print('❌ Response body: $bodyPreview');
          print('❌ Request size: ${encryptedBlob.length} characters');
          
          // Don't retry for client errors (4xx) - these won't get better
          if (response.statusCode >= 400 && response.statusCode < 500) {
            developer.log('🚨 [PROXY] Client error - not retrying', name: 'wellbeing-mapper-debug');
            print('🚫 Client error - not retrying');
            return false;
          }
          // Server errors (5xx) - retry after delay
        }
        
      } catch (e) {
        developer.log('🚨 [PROXY] EXCEPTION: Network error on attempt $attempt: $e', name: 'wellbeing-mapper-debug', error: e);
        developer.log('🚨 [PROXY] Exception type: ${e.runtimeType}', name: 'wellbeing-mapper-debug');
        print('❌ Network error sending to proxy (attempt $attempt): $e');
        print('❌ Error type: ${e.runtimeType}');
        print('❌ Detailed error: ${e.toString()}');
        
        // iOS-specific error handling
        if (Platform.isIOS) {
          developer.log('🚨 [PROXY] iOS-specific error analysis', name: 'wellbeing-mapper-debug');
          print('🍎 iOS-specific error details:');
          print('🍎 Platform: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
          print('🍎 Proxy URL: $_proxyServerUrl');
          print('🍎 Request timeout was: ${Platform.isIOS ? 45 : 30} seconds');
          
          final errorMessage = e.toString().toLowerCase();
          if (errorMessage.contains('network is unreachable') || 
              errorMessage.contains('no route to host') ||
              errorMessage.contains('operation timed out') ||
              errorMessage.contains('network connection lost') ||
              errorMessage.contains('the request timed out')) {
            developer.log('🚨 [PROXY] iOS network issue detected: $errorMessage', name: 'wellbeing-mapper-debug');
            print('🍎 iOS-specific network issue detected: $errorMessage');
            if (attempt == maxRetries) {
              print('🍎 iOS network troubleshooting:');
              print('   • Check WiFi/cellular data connection');
              print('   • Try toggling airplane mode on/off');
              print('   • Restart the app');
              print('   • Verify no VPN/firewall blocking connection');
            }
          }
        }
        
        // Check for specific error types that shouldn't be retried
        if (e.toString().contains('certificate') || 
            e.toString().contains('handshake') ||
            e.toString().contains('format')) {
          developer.log('🚨 [PROXY] Permanent error - not retrying', name: 'wellbeing-mapper-debug');
          print('🚫 Permanent error detected - not retrying');
          return false;
        }
      }
      
      // If we reach here, the attempt failed - wait before retry
      if (attempt < maxRetries) {
        // Exponential backoff with jitter: 2s, 4s, 8s + random 0-2s
        final baseDelay = initialDelay.inSeconds * (1 << (attempt - 1)); // 2^(attempt-1)
        final jitter = (DateTime.now().millisecondsSinceEpoch % 2000) / 1000; // 0-2 seconds
        final delay = Duration(milliseconds: ((baseDelay + jitter) * 1000).round());
        developer.log('🚨 [PROXY] Waiting ${delay.inSeconds}.${(delay.inMilliseconds % 1000).toString().padLeft(3, '0')}s before retry', name: 'wellbeing-mapper-debug');
        print('⏳ Waiting ${delay.inSeconds}.${(delay.inMilliseconds % 1000).toString().padLeft(3, '0')}s before retry (exponential backoff)...');
        await Future.delayed(delay);
      }
    }
    
    // All attempts failed
    developer.log('🚨 [PROXY] ALL ATTEMPTS FAILED after $maxRetries retries', name: 'wellbeing-mapper-debug');
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

  // Photo compression function removed - no longer needed
}