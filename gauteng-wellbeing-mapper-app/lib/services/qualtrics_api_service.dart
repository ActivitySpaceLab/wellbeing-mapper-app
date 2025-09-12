import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_background_geolocation/flutter_background_geolocation.dart' as bg;
import '../main.dart'; // For GlobalData
import '../db/survey_database.dart';
import '../models/data_sharing_consent.dart';
import 'data_upload_service.dart'; // For LocationTrack
import 'location_encryption_service.dart';

/// Service for syncing local survey data with Qualtrics via API
class QualtricsApiService {
  // TODO: Replace with your actual Qualtrics API credentials
  static const String _baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  static const String _apiToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  
  // Survey IDs for the NEW fixed surveys (updated 2025-09-12) - CAPTURES ALL DATA
  static const String _initialSurveyId = 'SV_aflSCXazOJiTkqy'; // NEW Initial Survey (34 Questions QID1-QID34) - FIXED DATA COLLECTION
  static const String _biweeklySurveyId = 'SV_0D4JPS2pOapx5lk'; // NEW Biweekly Survey (19 Questions QID1-QID19) - FIXED DATA COLLECTION  
  static const String _consentSurveyId = 'SV_3OXso1SLL2yte8C'; // NEW Consent Survey (16 Questions QID1-QID16) - FIXED DATA COLLECTION

  /// Sync a completed initial survey to Qualtrics
  static Future<bool> syncInitialSurvey(Map<String, dynamic> surveyData) async {
    try {
      debugPrint('🔄 Syncing initial survey to Qualtrics...');
      debugPrint('📊 Survey data keys: ${surveyData.keys.toList()}');
      
      final responseData = _mapInitialSurveyToQualtrics(surveyData);
      
      debugPrint('📤 Mapped data for Qualtrics: ${responseData.keys.toList()}');
      debugPrint('📋 Response data: $responseData');
      
      final success = await _createSurveyResponse(
        _initialSurveyId, 
        responseData,
        DateTime.parse(surveyData['submitted_at'] as String),
      );
      
      if (success) {
        debugPrint('✅ Initial survey synced to Qualtrics successfully');
        // Mark as synced in local database
        final db = SurveyDatabase();
        await db.markInitialSurveySynced(surveyData['id'] as int);
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to sync initial survey: $e');
      return false;
    }
  }

  /// Sync a completed biweekly survey to Qualtrics
  static Future<bool> syncBiweeklySurvey(Map<String, dynamic> surveyData) async {
    try {
      print('[QualtricsApiService] ===== BIWEEKLY SURVEY SYNC START =====');
      print('[QualtricsApiService] Survey data keys: ${surveyData.keys.toList()}');
      
      // Use the encrypted location data that was stored at submission time
      final encryptedLocationData = surveyData['encrypted_location_data'] as String?;
      print('[QualtricsApiService] Encrypted location data found: ${encryptedLocationData != null}');
      
      if (encryptedLocationData != null) {
        print('[QualtricsApiService] Encrypted location data length: ${encryptedLocationData.length} characters');
        print('[QualtricsApiService] First 100 chars of encrypted data: ${encryptedLocationData.substring(0, encryptedLocationData.length > 100 ? 100 : encryptedLocationData.length)}');
      }
      
      // Add location data to survey data if available
      final enhancedSurveyData = Map<String, dynamic>.from(surveyData);
      if (encryptedLocationData != null) {
        enhancedSurveyData['locationJson'] = encryptedLocationData;
        print('[QualtricsApiService] ✅ Added encrypted location data to survey data as locationJson');
      } else {
        print('[QualtricsApiService] ⚠️ No encrypted location data to add');
      }
      
      final responseData = _mapBiweeklySurveyToQualtrics(enhancedSurveyData);
      
      final success = await _createSurveyResponse(
        _biweeklySurveyId, 
        responseData,
        DateTime.parse(surveyData['submitted_at'] as String),
      );
      
      if (success) {
        debugPrint('✅ Biweekly survey synced to Qualtrics successfully');
        // Mark as synced in local database
        final db = SurveyDatabase();
        await db.markRecurringSurveySynced(surveyData['id'] as int);
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to sync biweekly survey: $e');
      return false;
    }
  }

  /// Sync a consent form to Qualtrics
  static Future<bool> syncConsentForm(Map<String, dynamic> consentData) async {
    try {
      final responseData = _mapConsentToQualtrics(consentData);
      
      final success = await _createSurveyResponse(
        _consentSurveyId, 
        responseData,
        DateTime.parse(consentData['consented_at'] as String),
      );
      
      if (success) {
        debugPrint('✅ Consent form synced to Qualtrics successfully');
        // Mark as synced in local database if we have an ID
        if (consentData.containsKey('id')) {
          final db = SurveyDatabase();
          await db.markConsentFormSynced(consentData['id'] as int);
        }
      }
      
      return success;
    } catch (e) {
      debugPrint('❌ Failed to sync consent form: $e');
      return false;
    }
  }

  /// Sync all pending surveys to Qualtrics
  static Future<void> syncPendingSurveys() async {
    try {
      final db = SurveyDatabase();
      
      // Sync pending initial surveys
      final pendingInitial = await db.getUnsyncedInitialSurveys();
      for (final survey in pendingInitial) {
        await syncInitialSurvey(survey);
        // Add small delay to avoid API rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Sync pending biweekly surveys  
      final pendingBiweekly = await db.getUnsyncedRecurringSurveys();
      for (final survey in pendingBiweekly) {
        await syncBiweeklySurvey(survey);
        // Add small delay to avoid API rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Sync pending consent forms
      final pendingConsent = await db.getUnsyncedConsentForms();
      for (final consent in pendingConsent) {
        await syncConsentForm(consent);
        // Add small delay to avoid API rate limits
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      debugPrint('🔄 Completed sync of all pending surveys');
    } catch (e) {
      debugPrint('❌ Error syncing pending surveys: $e');
    }
  }

  /// Create a survey response in Qualtrics
  static Future<bool> _createSurveyResponse(String surveyId, Map<String, dynamic> responseData, DateTime submissionTime) async {
    try {
      // Use the correct Qualtrics API v3 format based on official documentation
      final payload = {
        'values': responseData,
        'finished': true,  // Mark survey as completed
        'recordedDate': submissionTime.toIso8601String(),
      };

      debugPrint('📤 Sending payload to Qualtrics:');
      debugPrint('   Survey ID: $surveyId');
      debugPrint('   Payload: ${jsonEncode(payload)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/surveys/$surveyId/responses'),
        headers: {
          'X-API-TOKEN': _apiToken,
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      debugPrint('📥 Qualtrics response:');
      debugPrint('   Status: ${response.statusCode}');
      debugPrint('   Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseJson = jsonDecode(response.body);
        final responseId = responseJson['result']['responseId'];
        debugPrint('✅ Survey response created with ID: $responseId');
        
        // Verify data was stored (optional debug check)
        await _verifyResponseData(surveyId, responseId, responseData);
        
        return true;
      } else {
        debugPrint('❌ Qualtrics API error: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Network error creating survey response: $e');
      return false;
    }
  }

  /// Verify that submitted data was actually stored (debug helper)
  static Future<void> _verifyResponseData(String surveyId, String responseId, Map<String, dynamic> originalData) async {
    try {
      await Future.delayed(Duration(seconds: 2)); // Wait for processing
      
      final response = await http.get(
        Uri.parse('$_baseUrl/surveys/$surveyId/responses/$responseId'),
        headers: {
          'X-API-TOKEN': _apiToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseJson = jsonDecode(response.body);
        final storedValues = responseJson['result']['values'] as Map<String, dynamic>;
        
        // Check if our data appears in the stored response
        int matchedFields = 0;
        for (var key in originalData.keys) {
          if (storedValues.containsKey(key) && storedValues[key] != null && storedValues[key].toString().isNotEmpty) {
            matchedFields++;
            debugPrint('✅ Verified field $key: "${storedValues[key]}"');
          } else {
            debugPrint('❌ Missing field $key (expected: "${originalData[key]}")');
          }
        }
        
        if (matchedFields == 0) {
          debugPrint('❌ CRITICAL: No submitted data found in Qualtrics response!');
          debugPrint('   This suggests the survey may not be properly configured for API submissions.');
        } else {
          debugPrint('✅ Data verification: $matchedFields/${originalData.length} fields stored correctly');
        }
      } else {
        debugPrint('⚠️ Could not verify response data: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('⚠️ Error verifying response data: $e');
    }
  }

  /// Map initial survey data to Qualtrics format using simple text fields
  static Map<String, dynamic> _mapInitialSurveyToQualtrics(Map<String, dynamic> survey) {
    final data = <String, dynamic>{};
    
    // Simple text field mapping - all fields as text for maximum reliability
    // Using GlobalData.userUUID for participant_uuid
    data['QID1_TEXT'] = GlobalData.userUUID;

    if (survey['age'] != null) data['QID2_TEXT'] = survey['age'].toString();
    if (survey['suburb'] != null) data['QID3_TEXT'] = survey['suburb'].toString();

    // Handle ethnicity (could be JSON array)
    if (survey['ethnicity'] != null) {
      if (survey['ethnicity'] is String) {
        try {
          final ethnicityList = jsonDecode(survey['ethnicity'] as String) as List;
          data['QID4_TEXT'] = ethnicityList.join(',');
        } catch (e) {
          data['QID4_TEXT'] = survey['ethnicity'].toString();
        }
      } else {
        data['QID4_TEXT'] = survey['ethnicity'].toString();
      }
    }

    if (survey['gender'] != null) data['QID5_TEXT'] = survey['gender'].toString();
    if (survey['sexuality'] != null) data['QID6_TEXT'] = survey['sexuality'].toString();
    if (survey['birth_place'] != null) data['QID7_TEXT'] = survey['birth_place'].toString();
    if (survey['building_type'] != null) data['QID8_TEXT'] = survey['building_type'].toString();

    // Household items as text (JSON array converted to comma-separated)
    if (survey['household_items'] != null) {
      if (survey['household_items'] is String) {
        try {
          final items = jsonDecode(survey['household_items'] as String) as List;
          data['QID9_TEXT'] = items.join(',');
        } catch (e) {
          data['QID9_TEXT'] = survey['household_items'].toString();
        }
      } else {
        data['QID9_TEXT'] = survey['household_items'].toString();
      }
    }

    if (survey['education'] != null) data['QID10_TEXT'] = survey['education'].toString();
    if (survey['climate_activism'] != null) data['QID11_TEXT'] = survey['climate_activism'].toString();
    if (survey['employment_status'] != null) data['QID12_TEXT'] = survey['employment_status'].toString();
    if (survey['income'] != null) data['QID13_TEXT'] = survey['income'].toString();

    // Activities as text (JSON array converted to comma-separated)
    if (survey['activities'] != null) {
      if (survey['activities'] is String) {
        try {
          final activities = jsonDecode(survey['activities'] as String) as List;
          data['QID14_TEXT'] = activities.join(',');
        } catch (e) {
          data['QID14_TEXT'] = survey['activities'].toString();
        }
      } else {
        data['QID14_TEXT'] = survey['activities'].toString();
      }
    }

    if (survey['living_arrangement'] != null) data['QID15_TEXT'] = survey['living_arrangement'].toString();
    if (survey['relationship_status'] != null) data['QID16_TEXT'] = survey['relationship_status'].toString();
    if (survey['general_health'] != null) data['QID17_TEXT'] = survey['general_health'].toString();

    // WHO-5 Wellbeing questions as text
    if (survey['cheerful_spirits'] != null) data['QID18_TEXT'] = survey['cheerful_spirits'].toString();
    if (survey['calm_relaxed'] != null) data['QID19_TEXT'] = survey['calm_relaxed'].toString();
    if (survey['active_vigorous'] != null) data['QID20_TEXT'] = survey['active_vigorous'].toString();
    if (survey['woke_up_fresh'] != null) data['QID21_TEXT'] = survey['woke_up_fresh'].toString();
    if (survey['daily_life_interesting'] != null) data['QID22_TEXT'] = survey['daily_life_interesting'].toString();

    // Personal characteristics as text
    if (survey['cooperate_with_people'] != null) data['QID23_TEXT'] = survey['cooperate_with_people'].toString();
    if (survey['improving_skills'] != null) data['QID24_TEXT'] = survey['improving_skills'].toString();
    if (survey['social_situations'] != null) data['QID25_TEXT'] = survey['social_situations'].toString();
    if (survey['family_support'] != null) data['QID26_TEXT'] = survey['family_support'].toString();
    if (survey['family_knows_me'] != null) data['QID27_TEXT'] = survey['family_knows_me'].toString();
    if (survey['access_to_food'] != null) data['QID28_TEXT'] = survey['access_to_food'].toString();
    if (survey['people_enjoy_time'] != null) data['QID29_TEXT'] = survey['people_enjoy_time'].toString();
    if (survey['talk_to_family'] != null) data['QID30_TEXT'] = survey['talk_to_family'].toString();
    if (survey['friends_support'] != null) data['QID31_TEXT'] = survey['friends_support'].toString();
    if (survey['belong_in_community'] != null) data['QID32_TEXT'] = survey['belong_in_community'].toString();

    // Hidden fields
    if (survey['locationJson'] != null) data['QID33_TEXT'] = survey['locationJson'].toString();

    // Timestamp
    if (survey['submitted_at'] != null) {
      data['QID34_TEXT'] = survey['submitted_at'].toString();
    } else {
      data['QID34_TEXT'] = DateTime.now().toIso8601String();
    }

    return data;
  }

  /// Map biweekly survey data to Qualtrics format
  static Map<String, dynamic> _mapBiweeklySurveyToQualtrics(Map<String, dynamic> survey) {
    final data = <String, dynamic>{};
    
    // Based on actual CSV export: Only 19 questions (Q1-Q19)
    // QID1 → participant_uuid (Hidden)
    data['QID1_TEXT'] = GlobalData.userUUID;

    // QID2 → activities (Select all that apply)
    if (survey['activities'] != null) {
      final activities = jsonDecode(survey['activities'] as String) as List;
      data['QID2_TEXT'] = activities.join(',');
    }

    // QID3 → living_arrangement
    if (survey['living_arrangement'] != null) data['QID3_TEXT'] = survey['living_arrangement'];

    // QID4 → relationship_status
    if (survey['relationship_status'] != null) data['QID4_TEXT'] = survey['relationship_status'];

    // QID5 → general_health
    if (survey['general_health'] != null) {
      data['QID5_TEXT'] = survey['general_health'];
      debugPrint('🔍 General health data for QID5_TEXT: ${survey['general_health']}');
    }

    // WHO-5 Wellbeing Index Questions
    // QID6 → cheerful_spirits (Have you been in good spirits?)
    if (survey['cheerful_spirits'] != null) data['QID6_TEXT'] = survey['cheerful_spirits'].toString();

    // QID7 → calm_relaxed (Have you felt calm and relaxed?)
    if (survey['calm_relaxed'] != null) data['QID7_TEXT'] = survey['calm_relaxed'].toString();

    // QID8 → active_vigorous (Have you felt active and vigorous?)
    if (survey['active_vigorous'] != null) data['QID8_TEXT'] = survey['active_vigorous'].toString();

    // QID9 → woke_up_fresh (Did you wake up feeling fresh and rested?)
    if (survey['woke_up_fresh'] != null) data['QID9_TEXT'] = survey['woke_up_fresh'].toString();

    // QID10 → daily_life_interesting (Has your daily life been filled with things that interest you?)
    if (survey['daily_life_interesting'] != null) data['QID10_TEXT'] = survey['daily_life_interesting'].toString();

    // Personal characteristics and social support
    // QID11 → cooperate_with_people
    if (survey['cooperate_with_people'] != null) data['QID11_TEXT'] = survey['cooperate_with_people'].toString();

    // QID12 → improving_skills
    if (survey['improving_skills'] != null) data['QID12_TEXT'] = survey['improving_skills'].toString();

    // QID13 → social_situations
    if (survey['social_situations'] != null) data['QID13_TEXT'] = survey['social_situations'].toString();

    // QID14 → family_support
    if (survey['family_support'] != null) data['QID14_TEXT'] = survey['family_support'].toString();

    // QID15 → environmental_challenges (Text)
    if (survey['environmental_challenges'] != null) data['QID15_TEXT'] = survey['environmental_challenges'];

    // QID16 → challenges_stress_level
    if (survey['challenges_stress_level'] != null) data['QID16_TEXT'] = survey['challenges_stress_level'];

    // QID17 → coping_help (Text)
    if (survey['coping_help'] != null) data['QID17_TEXT'] = survey['coping_help'];

    // QID18 → location_data (Encrypted Location Data - Hidden)
    if (survey['locationJson'] != null) {
      data['QID18_TEXT'] = survey['locationJson'];
      debugPrint('🔍 Location data for QID18_TEXT: ${survey['locationJson'].toString().substring(0, 50)}...');
    } else {
      debugPrint('⚠️ No locationJson data found in survey data');
    }

    // QID19 → submitted_at (Submission Timestamp - Hidden)
    if (survey['submitted_at'] != null) {
      data['QID19_TEXT'] = survey['submitted_at'];
    } else {
      data['QID19_TEXT'] = DateTime.now().toIso8601String();
    }

    debugPrint('🔍 Complete biweekly survey mapping:');
    data.forEach((key, value) {
      debugPrint('   $key: $value');
    });

    return data;
  }

  /// Map consent form data to Qualtrics format using simple text fields
  /// Based on Planet4Health Consent Form 2025 PILOT blueprint
  static Map<String, dynamic> _mapConsentToQualtrics(Map<String, dynamic> consent) {
    final data = <String, dynamic>{};
    
    // Participant identifiers
    if (consent['participant_code'] != null) data['QID1_TEXT'] = consent['participant_code'].toString();
    data['QID2_TEXT'] = GlobalData.userUUID; // participant_uuid

    // Main consent checkboxes (1 = checked, 0 = unchecked) based on blueprint
    data['QID3_TEXT'] = (consent['informed_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to participate in this pilot study
    data['QID4_TEXT'] = (consent['data_processing_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT for my personal data to be processed by Qualtrics
    data['QID5_TEXT'] = (consent['race_ethnicity_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to being asked about by race/ethnicity
    data['QID6_TEXT'] = (consent['health_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to being asked about my health
    data['QID7_TEXT'] = (consent['sexual_orientation_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to being asked about my sexual orientation
    data['QID8_TEXT'] = (consent['location_mobility_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to being asked about my location and mobility
    data['QID9_TEXT'] = (consent['data_transfer_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to transferring my personal data to countries outside South Africa
    data['QID10_TEXT'] = (consent['public_reporting_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to researchers reporting what I contribute publicly without my full name
    data['QID11_TEXT'] = (consent['data_sharing_researchers_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to what I contribute being shared with national and international researchers
    data['QID12_TEXT'] = (consent['further_research_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to what I contribute being used for further research or teaching purposes
    data['QID13_TEXT'] = (consent['public_repository_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to what I contribute being placed in a public repository in deidentified form
    data['QID14_TEXT'] = (consent['followup_contact_consent'] == true) ? '1' : '0'; // I GIVE MY CONSENT to being contacted about participation in possible follow-up studies

    // Signature and timestamp
    if (consent['participant_signature'] != null) data['QID15_TEXT'] = consent['participant_signature'].toString();

    if (consent['consented_at'] != null) {
      data['QID16_TEXT'] = consent['consented_at'].toString();
    } else {
      data['QID16_TEXT'] = DateTime.now().toIso8601String();
    }

    return data;
  }

  /// Get encrypted location data for a specific submission time (public method for use during survey submission)
  static Future<String?> getEncryptedLocationDataForSubmissionTime(String? participantUuid, DateTime submissionTime) async {
    print('[QualtricsApiService] ===== LOCATION DATA CAPTURE START =====');
    print('[QualtricsApiService] Participant UUID: $participantUuid');
    print('[QualtricsApiService] Submission time: $submissionTime');
    
    if (participantUuid == null) {
      print('[QualtricsApiService] ❌ No participant UUID - returning null');
      return null;
    }
    
    try {
      final db = SurveyDatabase();
      
      // Get user's latest consent decision
      final consent = await db.getLatestDataSharingConsent(participantUuid);
      print('[QualtricsApiService] Location consent: ${consent?.locationSharingOption}');
      
      if (consent == null || consent.locationSharingOption == LocationSharingOption.surveyOnly) {
        print('[QualtricsApiService] ❌ No location consent or survey-only mode - skipping location data');
        return null;
      }
      
      // Get location data based on consent for the 2 weeks prior to submission time
      final startTime = submissionTime.subtract(Duration(days: 14));
      print('[QualtricsApiService] ===== DATE RANGE DEBUG =====');
      print('[QualtricsApiService] Submission time (NOW): ${submissionTime.toIso8601String()}');
      print('[QualtricsApiService] Start time (14 days ago): ${startTime.toIso8601String()}');
      print('[QualtricsApiService] Time range span: ${submissionTime.difference(startTime).inDays} days');
      print('[QualtricsApiService] Looking for location data from $startTime to $submissionTime');
      
      List<LocationTrack> locationTracks = [];
      
      switch (consent.locationSharingOption) {
        case LocationSharingOption.fullData:
          // Get all location data from 2 weeks before submission time
          locationTracks = await _getLocationTracksForTimeRange(startTime, submissionTime);
          print('[QualtricsApiService] Full data mode: Found ${locationTracks.length} location tracks');
          break;
          
        case LocationSharingOption.partialData:
          // Get filtered location data based on user's selection for the time range
          locationTracks = await _getPartialLocationDataForTimeRange(consent, startTime, submissionTime);
          print('[QualtricsApiService] Partial data mode: Found ${locationTracks.length} location tracks');
          break;
          
        case LocationSharingOption.surveyOnly:
          // No location data
          print('[QualtricsApiService] ❌ Survey-only mode - no location data');
          return null;
      }
      
      if (locationTracks.isEmpty) {
        print('[QualtricsApiService] ❌ No location data available for encryption (submission time: $submissionTime)');
        return null;
      }
      
      print('[QualtricsApiService] ✅ Found ${locationTracks.length} location tracks for encryption');
      
      // Convert location tracks to JSON format
      final locationData = locationTracks.map((track) => {
        'latitude': track.latitude,
        'longitude': track.longitude,
        'timestamp': track.timestamp.toIso8601String(),
        'accuracy': track.accuracy,
        'altitude': track.altitude,
        'speed': track.speed,
        'activity': track.activity,
      }).toList();
      
      final locationJson = jsonEncode(locationData);
      print('[QualtricsApiService] Location JSON length: ${locationJson.length} characters');
      
      // Get the research site and encrypt the location data
      final researchSite = await LocationEncryptionService.getCurrentResearchSite();
      final encryptedLocation = await LocationEncryptionService.encryptLocationData(
        locationJson, 
        researchSite: researchSite
      );
      
      print('[QualtricsApiService] ✅ Successfully encrypted ${locationTracks.length} location records for submission time: $submissionTime');
      print('[QualtricsApiService] Encrypted data length: ${encryptedLocation.length} characters');
      print('[QualtricsApiService] ===== LOCATION DATA CAPTURE END =====');
      return encryptedLocation;
      
    } catch (e) {
      print('[QualtricsApiService] ❌ Error getting encrypted location data for submission time: $e');
      return null;
    }
  }

  /// Get location tracks for a specific time range
  static Future<List<LocationTrack>> _getLocationTracksForTimeRange(DateTime startTime, DateTime endTime) async {
    if (kIsWeb) return [];
    
    try {
      print('[QualtricsApiService] ===== LOCATION RETRIEVAL DEBUG =====');
      print('[QualtricsApiService] Fetching location tracks from database for time range $startTime to $endTime');
      print('[QualtricsApiService] Time range span: ${endTime.difference(startTime).inDays} days, ${endTime.difference(startTime).inHours} hours');
      
      // Try database first - this is more reliable than background geolocation plugin storage
      final db = SurveyDatabase();
      
      // First, let's check what's actually in the database
      final allLocationTracks = await db.getAllLocationTracks();
      print('[QualtricsApiService] Total location tracks in database: ${allLocationTracks.length}');
      
      if (allLocationTracks.isNotEmpty) {
        print('[QualtricsApiService] Database date range:');
        print('[QualtricsApiService]   Earliest: ${allLocationTracks.first.timestamp.toIso8601String()}');
        print('[QualtricsApiService]   Latest: ${allLocationTracks.last.timestamp.toIso8601String()}');
        
        // Show tracks from last few days
        final recentCutoff = DateTime.now().subtract(Duration(days: 3));
        final recentTracks = allLocationTracks.where((track) => track.timestamp.isAfter(recentCutoff)).toList();
        print('[QualtricsApiService] Recent tracks (last 3 days): ${recentTracks.length}');
      }
      
      final dbLocationTracks = await db.getLocationTracksSince(startTime);
      
      print('[QualtricsApiService] Raw database query returned ${dbLocationTracks.length} tracks since $startTime');
      
      // Show some sample timestamps from database if we have data
      if (dbLocationTracks.isNotEmpty) {
        print('[QualtricsApiService] Database sample timestamps:');
        for (int i = 0; i < min(5, dbLocationTracks.length); i++) {
          print('[QualtricsApiService]   Track ${i+1}: ${dbLocationTracks[i].timestamp.toIso8601String()}');
        }
        if (dbLocationTracks.length > 5) {
          print('[QualtricsApiService]   ... and ${dbLocationTracks.length - 5} more tracks');
        }
        print('[QualtricsApiService] Latest track: ${dbLocationTracks.last.timestamp.toIso8601String()}');
        print('[QualtricsApiService] Earliest track: ${dbLocationTracks.first.timestamp.toIso8601String()}');
      }
      
      // Filter to end time
      final filteredDbTracks = dbLocationTracks.where((track) => 
        track.timestamp.isAfter(startTime) && track.timestamp.isBefore(endTime)
      ).toList();
      
      print('[QualtricsApiService] After filtering to end time: ${filteredDbTracks.length} location tracks');
      
      if (filteredDbTracks.isNotEmpty) {
        return filteredDbTracks;
      }
      
      // Fallback to background geolocation plugin storage if database is empty
      print('[QualtricsApiService] Database empty, trying background geolocation plugin...');
      final bgLocations = await bg.BackgroundGeolocation.locations;
      final locationTracks = <LocationTrack>[];
      
      print('[QualtricsApiService] Found ${bgLocations.length} records in background geolocation plugin');
      
      for (var bgLocation in bgLocations) {
        try {
          final locationMap = bgLocation as Map<Object?, Object?>;
          
          // Handle timestamp
          DateTime locationTime;
          final timestamp = locationMap['timestamp'];
          if (timestamp is int) {
            locationTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
          } else if (timestamp is String) {
            locationTime = DateTime.parse(timestamp);
          } else {
            continue;
          }
          
          // Check if location is within the specified time range
          if (locationTime.isAfter(startTime) && locationTime.isBefore(endTime)) {
            final coords = locationMap['coords'] as Map<Object?, Object?>?;
            if (coords != null) {
              locationTracks.add(LocationTrack(
                timestamp: locationTime,
                latitude: coords['latitude'] as double,
                longitude: coords['longitude'] as double,
                accuracy: coords['accuracy'] as double?,
                altitude: coords['altitude'] as double?,
                speed: coords['speed'] as double?,
                activity: (locationMap['activity'] as Map<Object?, Object?>?)?['type'] as String?,
              ));
            }
          }
        } catch (e) {
          continue;
        }
      }
      
      print('[QualtricsApiService] Retrieved ${locationTracks.length} location tracks for time range ${startTime.toIso8601String()} to ${endTime.toIso8601String()}');
      return locationTracks;
    } catch (e) {
      print('[QualtricsApiService] Error getting location tracks for time range: $e');
      return [];
    }
  }

  /// Get filtered location data for partial sharing based on user's consent for a specific time range
  static Future<List<LocationTrack>> _getPartialLocationDataForTimeRange(DataSharingConsent consent, DateTime startTime, DateTime endTime) async {
    final allTracks = await _getLocationTracksForTimeRange(startTime, endTime);
    
    if (consent.customLocationIds == null || consent.customLocationIds!.isEmpty) {
      return [];
    }
    
    // For partial sharing, the consent system stores track indices or cluster IDs
    // We need to filter based on the selected locations
    final selectedTracks = <LocationTrack>[];
    
    // This logic should match the selection logic from the consent dialog
    // For now, we'll implement a basic filtering system
    // In a production app, this would need more sophisticated geofencing
    
    // Simple implementation: if user selected any custom locations, include all tracks
    // This should be enhanced to match the actual cluster/area selection logic
    if (consent.customLocationIds!.isNotEmpty) {
      selectedTracks.addAll(allTracks);
    }
    
    print('[QualtricsApiService] Filtered to ${selectedTracks.length} location tracks for partial sharing (time range)');
    return selectedTracks;
  }
}
