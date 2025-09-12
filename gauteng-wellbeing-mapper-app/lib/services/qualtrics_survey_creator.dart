import 'dart:convert';
import 'package:http/http.dart' as http;
import 'secure_config.dart';

/// Service for creating Qualtrics surveys that match the Flutter app structure
class QualtricsSurveyCreator {
  static const String _baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  
  /// Create all three surveys needed for the app
  static Future<Map<String, String>> createAllSurveys() async {
    // Validate token is available
    try {
      final apiToken = SecureConfig.qualtricsApiToken;
      print('Using secure API token configuration');
    } catch (e) {
      throw Exception('Qualtrics API token not configured: $e');
    }
    
    try {
      final initialSurveyId = await createInitialSurvey();
      final biweeklySurveyId = await createBiweeklySurvey();
      final consentSurveyId = await createConsentSurvey();
      
      return {
        'initial': initialSurveyId,
        'biweekly': biweeklySurveyId,
        'consent': consentSurveyId,
      };
    } catch (e) {
      print('Error creating surveys: $e');
      rethrow;
    }
  }

  /// Create the Initial Survey in Qualtrics
  static Future<String> createInitialSurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Initial Survey',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
      'Questions': _getInitialSurveyQuestions(),
    };

    return await _createSurvey(surveyDefinition);
  }

  /// Create the Biweekly Survey in Qualtrics
  static Future<String> createBiweeklySurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Biweekly Survey',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
      'Questions': _getBiweeklySurveyQuestions(),
    };

    return await _createSurvey(surveyDefinition);
  }

  /// Create the Consent Form Survey in Qualtrics
  static Future<String> createConsentSurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Consent Form',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
      'Questions': _getConsentSurveyQuestions(),
    };

    return await _createSurvey(surveyDefinition);
  }

  /// Update the existing consent survey with all consent questions
  static Future<void> updateConsentSurveyQuestions() async {
    const String consentSurveyId = 'SV_eYdj4iL3W8ydWJ0';
    
    print('🔄 Updating consent survey with complete consent questions...');
    
    try {
      // First, clear existing questions (except required ones)
      await _clearSurveyQuestions(consentSurveyId);
      
      // Add all the consent questions
      await addQuestionsToSurvey(consentSurveyId, _getConsentSurveyQuestions());
      
      print('✅ Consent survey updated successfully with all ${_getConsentSurveyQuestions().length} questions');
    } catch (e) {
      print('❌ Error updating consent survey: $e');
      rethrow;
    }
  }

  /// Clear existing questions from a survey (keeping required system questions)
  static Future<void> _clearSurveyQuestions(String surveyId) async {
    try {
      // Get existing questions
      final url = Uri.parse('$_baseUrl/surveys/$surveyId/questions');
      final response = await http.get(
        url,
        headers: {
          'X-API-TOKEN': SecureConfig.qualtricsApiToken,
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final questions = data['result']['elements'] as List;
        
        // Delete non-system questions
        for (var question in questions) {
          final questionId = question['QuestionID'];
          // Keep system questions, delete custom ones
          if (!questionId.startsWith('QID_')) {
            await _deleteQuestion(surveyId, questionId);
          }
        }
        
        print('🧹 Cleared existing questions from survey $surveyId');
      }
    } catch (e) {
      print('⚠️ Warning: Could not clear existing questions: $e');
      // Continue anyway - we'll just add new questions
    }
  }

  /// Delete a specific question from a survey
  static Future<void> _deleteQuestion(String surveyId, String questionId) async {
    try {
      final url = Uri.parse('$_baseUrl/surveys/$surveyId/questions/$questionId');
      await http.delete(
        url,
        headers: {
          'X-API-TOKEN': SecureConfig.qualtricsApiToken,
          'Content-Type': 'application/json',
        },
      );
    } catch (e) {
      print('⚠️ Warning: Could not delete question $questionId: $e');
    }
  }

  /// Generic method to create a survey in Qualtrics
  static Future<String> _createSurvey(Map<String, dynamic> surveyDefinition) async {
    final url = Uri.parse('$_baseUrl/survey-definitions');
    
    print('🔄 Creating survey: ${surveyDefinition['SurveyName']}');
    print('📡 Sending request to: $url');
    
    final response = await http.post(
      url,
      headers: {
        'X-API-TOKEN': SecureConfig.qualtricsApiToken,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(surveyDefinition),
    );

    print('📥 Response status: ${response.statusCode}');
    print('📄 Response body: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      print('📊 Parsed response: $responseData');
      
      // Try different possible response structures
      String? surveyId;
      if (responseData['result'] != null && responseData['result']['id'] != null) {
        surveyId = responseData['result']['id'];
      } else if (responseData['result'] != null && responseData['result']['SurveyID'] != null) {
        surveyId = responseData['result']['SurveyID'];
      } else if (responseData['result'] != null) {
        // Sometimes the survey ID is directly in result
        surveyId = responseData['result'].toString();
      } else if (responseData['id'] != null) {
        surveyId = responseData['id'];
      }
      
      if (surveyId != null && surveyId.isNotEmpty) {
        print('✅ Created survey: ${surveyDefinition['SurveyName']} with ID: $surveyId');
        return surveyId;
      } else {
        throw Exception('Survey created but could not extract ID from response: $responseData');
      }
    } else {
      throw Exception('Failed to create survey: ${response.statusCode} - ${response.body}');
    }
  }

  /// Add questions to an existing survey
  static Future<void> addQuestionsToSurvey(String surveyId, List<Map<String, dynamic>> questions) async {
    print('📝 Adding ${questions.length} questions to survey $surveyId');
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      try {
        await _addSingleQuestion(surveyId, question);
        print('✅ Added question ${i + 1}/${questions.length}: ${question['QuestionText']}');
      } catch (e) {
        print('❌ Failed to add question ${i + 1}: ${question['QuestionText']} - Error: $e');
        // Continue with other questions even if one fails
      }
    }
  }

  /// Add a single question to a survey
  static Future<void> _addSingleQuestion(String surveyId, Map<String, dynamic> questionData) async {
    final url = Uri.parse('$_baseUrl/survey-definitions/$surveyId/questions');
    
    final response = await http.post(
      url,
      headers: {
        'X-API-TOKEN': SecureConfig.qualtricsApiToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(questionData),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add question: ${response.statusCode} - ${response.body}');
    }
  }

  /// Complete setup: Create survey and add all questions
  static Future<String> createCompleteSurvey(String surveyType) async {
    try {
      // Step 1: Create the basic survey
      String surveyId;
      List<Map<String, dynamic>> questions;
      
      switch (surveyType.toLowerCase()) {
        case 'initial':
          surveyId = await createInitialSurvey();
          questions = _getInitialSurveyQuestions();
          break;
        case 'biweekly':
          surveyId = await createBiweeklySurvey();
          questions = _getBiweeklySurveyQuestions();
          break;
        case 'consent':
          surveyId = await createConsentSurvey();
          questions = _getConsentSurveyQuestions();
          break;
        default:
          throw Exception('Unknown survey type: $surveyType');
      }
      
      // Step 2: Add all questions to the survey
      await addQuestionsToSurvey(surveyId, questions);
      
      print('🎉 Complete survey created successfully: $surveyId');
      return surveyId;
      
    } catch (e) {
      print('❌ Error creating complete survey: $e');
      rethrow;
    }
  }

  /// Fix existing surveys by adding questions to them
  static Future<void> fixExistingSurveys() async {
    print('🔧 Fixing existing surveys by adding questions...');
    
    // Use the survey IDs that were previously created
    const String initialSurveyId = 'SV_74i4mEa6ZTwCGQm';
    const String biweeklySurveyId = 'SV_baxJiGnctafu1TM';
    const String consentSurveyId = 'SV_bqtbNF1KVmujr9A';
    
    try {
      // Fix Initial Survey
      print('🔧 Adding questions to Initial Survey...');
      await addQuestionsToSurvey(initialSurveyId, _getInitialSurveyQuestions());
      
      // Fix Biweekly Survey  
      print('🔧 Adding questions to Biweekly Survey...');
      await addQuestionsToSurvey(biweeklySurveyId, _getBiweeklySurveyQuestions());
      
      // Fix Consent Survey
      print('🔧 Adding questions to Consent Survey...');
      await addQuestionsToSurvey(consentSurveyId, _getConsentSurveyQuestions());
      
      print('✅ All surveys have been fixed with proper questions!');
      
    } catch (e) {
      print('❌ Error fixing surveys: $e');
      rethrow;
    }
  }

  /// Create simple surveys with basic text questions that work with Qualtrics API
  static Future<String> createSimpleInitialSurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Initial Survey (Complete)',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
    };
    
    final surveyId = await _createSurvey(surveyDefinition);
    
    // Add simplified questions
    final questions = [
      {'QuestionText': 'Participant UUID', 'QuestionType': 'TE', 'DataExportTag': 'participant_uuid'},
      {'QuestionText': 'Age', 'QuestionType': 'TE', 'DataExportTag': 'age'},
      {'QuestionText': 'Ethnicity', 'QuestionType': 'TE', 'DataExportTag': 'ethnicity'},
      {'QuestionText': 'Gender', 'QuestionType': 'TE', 'DataExportTag': 'gender'},
      {'QuestionText': 'Sexuality', 'QuestionType': 'TE', 'DataExportTag': 'sexuality'},
      {'QuestionText': 'Birth Place', 'QuestionType': 'TE', 'DataExportTag': 'birth_place'},
      {'QuestionText': 'Suburb', 'QuestionType': 'TE', 'DataExportTag': 'suburb'},
      {'QuestionText': 'Years in Gauteng', 'QuestionType': 'TE', 'DataExportTag': 'years_in_gauteng'},
      {'QuestionText': 'Income', 'QuestionType': 'TE', 'DataExportTag': 'income'},
      {'QuestionText': 'Education', 'QuestionType': 'TE', 'DataExportTag': 'education'},
      {'QuestionText': 'Employment', 'QuestionType': 'TE', 'DataExportTag': 'employment'},
      {'QuestionText': 'Household Size', 'QuestionType': 'TE', 'DataExportTag': 'household_size'},
      {'QuestionText': 'Housing Type', 'QuestionType': 'TE', 'DataExportTag': 'housing_type'},
      {'QuestionText': 'Transport Mode', 'QuestionType': 'TE', 'DataExportTag': 'transport_mode'},
      // Baseline wellbeing questions
      {'QuestionText': 'Life Satisfaction (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'life_satisfaction'},
      {'QuestionText': 'Happiness Level (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'happiness_level'},
      {'QuestionText': 'Stress Level (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'stress_level'},
      {'QuestionText': 'Physical Health (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'physical_health'},
      {'QuestionText': 'Mental Health (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'mental_health'},
      {'QuestionText': 'Social Connections (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'social_connections'},
      {'QuestionText': 'Activities and Interests', 'QuestionType': 'TE', 'DataExportTag': 'activities'},
      {'QuestionText': 'Research Site', 'QuestionType': 'TE', 'DataExportTag': 'research_site'},
      {'QuestionText': 'Submitted At', 'QuestionType': 'TE', 'DataExportTag': 'submitted_at'},
      {'QuestionText': 'Location Data', 'QuestionType': 'TE', 'DataExportTag': 'location_data'},
    ];
    
    await addQuestionsToSurvey(surveyId, questions);
    return surveyId;
  }

  static Future<String> createSimpleBiweeklySurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Biweekly Survey (Complete)',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
    };
    
    final surveyId = await _createSurvey(surveyDefinition);
    
    // Add simplified questions
    final questions = [
      {'QuestionText': 'Participant UUID', 'QuestionType': 'TE', 'DataExportTag': 'participant_uuid'},
      {'QuestionText': 'Life Satisfaction (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'life_satisfaction'},
      {'QuestionText': 'Happiness Level (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'happiness_level'},
      {'QuestionText': 'Stress Level (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'stress_level'},
      {'QuestionText': 'Physical Health (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'physical_health'},
      {'QuestionText': 'Mental Health (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'mental_health'},
      {'QuestionText': 'Social Connections (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'social_connections'},
      {'QuestionText': 'Sleep Quality (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'sleep_quality'},
      {'QuestionText': 'Energy Level (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'energy_level'},
      {'QuestionText': 'Opportunities and Abilities (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'opportunities_abilities'},
      {'QuestionText': 'Enjoy Cultural Traditions (1-10)', 'QuestionType': 'TE', 'DataExportTag': 'enjoy_cultural_traditions'},
      {'QuestionText': 'Environmental Challenges', 'QuestionType': 'TE', 'DataExportTag': 'environmental_challenges'},
      {'QuestionText': 'Challenges Stress Level', 'QuestionType': 'TE', 'DataExportTag': 'challenges_stress_level'},
      {'QuestionText': 'Coping Help', 'QuestionType': 'TE', 'DataExportTag': 'coping_help'},
      {'QuestionText': 'Research Site', 'QuestionType': 'TE', 'DataExportTag': 'research_site'},
      {'QuestionText': 'Submitted At', 'QuestionType': 'TE', 'DataExportTag': 'submitted_at'},
      {'QuestionText': 'Location Data', 'QuestionType': 'TE', 'DataExportTag': 'location_data'},
    ];
    
    await addQuestionsToSurvey(surveyId, questions);
    return surveyId;
  }

  static Future<String> createSimpleConsentSurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Consent Survey (Complete)',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
    };
    
    final surveyId = await _createSurvey(surveyDefinition);
    
    // Add simplified questions
    final questions = [
      {'QuestionText': 'Participant UUID', 'QuestionType': 'TE', 'DataExportTag': 'participant_uuid'},
      {'QuestionText': 'Data Sharing Consent', 'QuestionType': 'TE', 'DataExportTag': 'data_sharing_consent'},
      {'QuestionText': 'Location Sharing Consent', 'QuestionType': 'TE', 'DataExportTag': 'location_sharing_consent'},
      {'QuestionText': 'Participant Signature', 'QuestionType': 'TE', 'DataExportTag': 'participant_signature'},
      {'QuestionText': 'Consented At', 'QuestionType': 'TE', 'DataExportTag': 'consented_at'},
    ];
    
    await addQuestionsToSurvey(surveyId, questions);
    return surveyId;
  }

  /// Define Initial Survey questions - now includes all biweekly questions for baseline measurement
  static List<Map<String, dynamic>> _getInitialSurveyQuestions() {
    return [
      // Demographics section (original initial survey)
      {
        'QuestionText': 'Participant UUID',
        'QuestionType': 'TE',
        'DataExportTag': 'participant_uuid',
      },
      {
        'QuestionText': 'What is your age?',
        'QuestionType': 'TE',
        'DataExportTag': 'age',
      },
      {
        'QuestionText': 'How do you describe your ethnicity? (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'DataExportTag': 'ethnicity',
        'Choices': {
          '1': {'Display': 'African'},
          '2': {'Display': 'Coloured'},
          '3': {'Display': 'Indian/Asian'},
          '4': {'Display': 'White'},
          '5': {'Display': 'Other'},
        },
      },
      {
        'QuestionText': 'How do you describe your gender?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'gender',
        'Choices': {
          '1': 'Male',
          '2': 'Female',
          '3': 'Non-binary',
          '4': 'Prefer not to say',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_SEXUALITY',
        'QuestionText': 'How do you describe your sexuality?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Heterosexual',
          '2': 'Gay/Lesbian',
          '3': 'Bisexual',
          '4': 'Prefer not to say',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_BIRTH_PLACE',
        'QuestionText': 'Where were you born?',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_SUBURB',
        'QuestionText': 'What suburb do you live in?',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_BUILDING_TYPE',
        'QuestionText': 'What type of building do you live in?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'House',
          '2': 'Apartment/Flat',
          '3': 'Townhouse',
          '4': 'Informal settlement',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_HOUSEHOLD_ITEMS',
        'QuestionText': 'Which of the following items does your household have? (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'Choices': {
          '1': 'Electricity',
          '2': 'Running water',
          '3': 'Flush toilet',
          '4': 'Refrigerator',
          '5': 'Television',
          '6': 'Computer/Laptop',
          '7': 'Internet access',
          '8': 'Car',
        },
      },
      {
        'QuestionID': 'QID_EDUCATION',
        'QuestionText': 'What is your highest level of education?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'No formal education',
          '2': 'Primary school',
          '3': 'High school (incomplete)',
          '4': 'High school (complete)',
          '5': 'Technical/Vocational training',
          '6': 'University degree',
          '7': 'Postgraduate degree',
        },
      },
      {
        'QuestionID': 'QID_CLIMATE_ACTIVISM',
        'QuestionText': 'How involved are you in climate activism?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Not involved at all',
          '2': 'Slightly involved',
          '3': 'Moderately involved',
          '4': 'Very involved',
          '5': 'Extremely involved',
        },
      },
      {
        'QuestionID': 'QID_GENERAL_HEALTH',
        'QuestionText': 'How would you describe your general health?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Excellent',
          '2': 'Very good',
          '3': 'Good',
          '4': 'Fair',
          '5': 'Poor',
        },
      },
      
      // Baseline lifestyle questions (from biweekly survey)
      {
        'QuestionID': 'QID_ACTIVITIES_BASELINE',
        'QuestionText': 'What activities have you done recently? (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'Choices': {
          '1': 'Work',
          '2': 'Study',
          '3': 'Exercise',
          '4': 'Shopping',
          '5': 'Socializing',
          '6': 'Entertainment',
          '7': 'Travel',
          '8': 'Other',
        },
      },
      {
        'QuestionID': 'QID_LIVING_ARRANGEMENT',
        'QuestionText': 'Who do you currently live with?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Alone',
          '2': 'With family',
          '3': 'With friends/roommates',
          '4': 'With partner',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_RELATIONSHIP_STATUS',
        'QuestionText': 'What is your relationship status?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Single',
          '2': 'In a relationship',
          '3': 'Married',
          '4': 'Divorced',
          '5': 'Widowed',
        },
      },
      
      // Baseline wellbeing questions (0-5 scale)
      {
        'QuestionID': 'QID_CHEERFUL_SPIRITS_BASELINE',
        'QuestionText': 'Have you been in good spirits?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_CALM_RELAXED_BASELINE',
        'QuestionText': 'Have you felt calm and relaxed?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_ACTIVE_VIGOROUS_BASELINE',
        'QuestionText': 'Have you felt active and vigorous?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_WOKE_UP_FRESH_BASELINE',
        'QuestionText': 'Have you woken up feeling fresh and rested?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_DAILY_LIFE_INTERESTING_BASELINE',
        'QuestionText': 'Has your daily life been filled with things that interest you?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      
      // Baseline personal characteristics questions (1-5 scale)
      {
        'QuestionID': 'QID_COOPERATE_WITH_PEOPLE_BASELINE',
        'QuestionText': 'I am able to cooperate well with other people',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_IMPROVING_SKILLS_BASELINE',
        'QuestionText': 'I am always improving my skills',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_SOCIAL_SITUATIONS_BASELINE',
        'QuestionText': 'I feel comfortable in social situations',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_SUPPORT_BASELINE',
        'QuestionText': 'My family really tries to help me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_KNOWS_ME_BASELINE',
        'QuestionText': 'My family knows me well',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_ACCESS_TO_FOOD_BASELINE',
        'QuestionText': 'I have access to the food I need',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_PEOPLE_ENJOY_TIME_BASELINE',
        'QuestionText': 'People enjoy spending time with me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_TALK_TO_FAMILY_BASELINE',
        'QuestionText': 'I can talk about my problems with my family',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FRIENDS_SUPPORT_BASELINE',
        'QuestionText': 'My friends really try to help me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_BELONG_IN_COMMUNITY_BASELINE',
        'QuestionText': 'I feel like I belong in my community',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_STANDS_BY_ME_BASELINE',
        'QuestionText': 'My family stands by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FRIENDS_STAND_BY_ME_BASELINE',
        'QuestionText': 'My friends stand by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_TREATED_FAIRLY_BASELINE',
        'QuestionText': 'I am treated fairly in my community',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_OPPORTUNITIES_RESPONSIBILITY_BASELINE',
        'QuestionText': 'I have opportunities to take on responsibility',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_SECURE_WITH_FAMILY_BASELINE',
        'QuestionText': 'I feel secure with my family',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_OPPORTUNITIES_ABILITIES_BASELINE',
        'QuestionText': 'I have opportunities to show my abilities',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_ENJOY_CULTURAL_TRADITIONS_BASELINE',
        'QuestionText': 'I enjoy my cultural traditions',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      
      // Baseline digital diary questions (no location data for initial survey)
      {
        'QuestionID': 'QID_ENVIRONMENTAL_CHALLENGES_BASELINE',
        'QuestionText': 'What environmental challenges have you experienced recently?',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_CHALLENGES_STRESS_LEVEL_BASELINE',
        'QuestionText': 'How stressful were these environmental challenges?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Not stressful at all',
          '2': 'Slightly stressful',
          '3': 'Moderately stressful',
          '4': 'Very stressful',
          '5': 'Extremely stressful',
        },
      },
      {
        'QuestionID': 'QID_COPING_HELP_BASELINE',
        'QuestionText': 'What has helped you cope with these challenges?',
        'QuestionType': 'TE',
      },
      
      // TODO: MULTIMEDIA DISABLED - Uncomment to re-enable multimedia support
      // {
      //   'QuestionID': 'QID_VOICE_NOTE_URLS_BASELINE',
      //   'QuestionText': 'Voice Note URLs (Internal - Baseline)',
      //   'QuestionType': 'TE',
      // },
      // {
      //   'QuestionID': 'QID_IMAGE_URLS_BASELINE',
      //   'QuestionText': 'Image URLs (Internal - Baseline)',
      //   'QuestionType': 'TE',
      // },
      
      // Metadata
      {
        'QuestionID': 'QID_RESEARCH_SITE',
        'QuestionText': 'Research Site',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_SUBMITTED_AT',
        'QuestionText': 'Submission Timestamp',
        'QuestionType': 'TE',
      },
    ];
  }

  /// Define Biweekly Survey questions based on Flutter RecurringSurveyResponse model
  static List<Map<String, dynamic>> _getBiweeklySurveyQuestions() {
    return [
      {
        'QuestionID': 'QID_PARTICIPANT_UUID',
        'QuestionText': 'Participant UUID',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_ACTIVITIES',
        'QuestionText': 'What activities have you done in the past two weeks? (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'Choices': {
          '1': 'Work',
          '2': 'Study',
          '3': 'Exercise',
          '4': 'Shopping',
          '5': 'Socializing',
          '6': 'Entertainment',
          '7': 'Travel',
          '8': 'Other',
        },
      },
      {
        'QuestionID': 'QID_LIVING_ARRANGEMENT',
        'QuestionText': 'Who do you currently live with?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Alone',
          '2': 'With family',
          '3': 'With friends/roommates',
          '4': 'With partner',
          '5': 'Other',
        },
      },
      {
        'QuestionID': 'QID_RELATIONSHIP_STATUS',
        'QuestionText': 'What is your relationship status?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Single',
          '2': 'In a relationship',
          '3': 'Married',
          '4': 'Divorced',
          '5': 'Widowed',
        },
      },
      {
        'QuestionID': 'QID_GENERAL_HEALTH',
        'QuestionText': 'How would you describe your general health?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Excellent',
          '2': 'Very good',
          '3': 'Good',
          '4': 'Fair',
          '5': 'Poor',
        },
      },
      // Wellbeing questions (0-5 scale)
      {
        'QuestionID': 'QID_CHEERFUL_SPIRITS',
        'QuestionText': 'Have you been in good spirits?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_CALM_RELAXED',
        'QuestionText': 'Have you felt calm and relaxed?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_ACTIVE_VIGOROUS',
        'QuestionText': 'Have you felt active and vigorous?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_WOKE_UP_FRESH',
        'QuestionText': 'Have you woken up feeling fresh and rested?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      {
        'QuestionID': 'QID_DAILY_LIFE_INTERESTING',
        'QuestionText': 'Has your daily life been filled with things that interest you?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '0': 'At no time',
          '1': 'Some of the time',
          '2': 'Less than half the time',
          '3': 'More than half the time',
          '4': 'Most of the time',
          '5': 'All of the time',
        },
      },
      // Personal characteristics questions (1-5 scale)
      {
        'QuestionID': 'QID_COOPERATE_WITH_PEOPLE',
        'QuestionText': 'I am able to cooperate well with other people',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_IMPROVING_SKILLS',
        'QuestionText': 'I am always improving my skills',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_SOCIAL_SITUATIONS',
        'QuestionText': 'I feel comfortable in social situations',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_SUPPORT',
        'QuestionText': 'My family really tries to help me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_KNOWS_ME',
        'QuestionText': 'My family knows me well',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_ACCESS_TO_FOOD',
        'QuestionText': 'I have access to the food I need',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_PEOPLE_ENJOY_TIME',
        'QuestionText': 'People enjoy spending time with me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_TALK_TO_FAMILY',
        'QuestionText': 'I can talk about my problems with my family',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FRIENDS_SUPPORT',
        'QuestionText': 'My friends really try to help me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_BELONG_IN_COMMUNITY',
        'QuestionText': 'I feel like I belong in my community',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FAMILY_STANDS_BY_ME',
        'QuestionText': 'My family stands by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_FRIENDS_STAND_BY_ME',
        'QuestionText': 'My friends stand by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_TREATED_FAIRLY',
        'QuestionText': 'I am treated fairly in my community',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_OPPORTUNITIES_RESPONSIBILITY',
        'QuestionText': 'I have opportunities to take on responsibility',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_SECURE_WITH_FAMILY',
        'QuestionText': 'I feel secure with my family',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_OPPORTUNITIES_ABILITIES',
        'QuestionText': 'I have opportunities to show my abilities',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      {
        'QuestionID': 'QID_ENJOY_CULTURAL_TRADITIONS',
        'QuestionText': 'I enjoy my cultural traditions',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Strongly disagree',
          '2': 'Disagree',
          '3': 'Neutral',
          '4': 'Agree',
          '5': 'Strongly agree',
        },
      },
      // Digital diary questions
      {
        'QuestionID': 'QID_ENVIRONMENTAL_CHALLENGES',
        'QuestionText': 'What environmental challenges have you experienced in the past two weeks?',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_CHALLENGES_STRESS_LEVEL',
        'QuestionText': 'How stressful were these environmental challenges?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'Choices': {
          '1': 'Not stressful at all',
          '2': 'Slightly stressful',
          '3': 'Moderately stressful',
          '4': 'Very stressful',
          '5': 'Extremely stressful',
        },
      },
      {
        'QuestionID': 'QID_COPING_HELP',
        'QuestionText': 'What has helped you cope with these challenges?',
        'QuestionType': 'TE',
      },
      
      // TODO: MULTIMEDIA DISABLED - Uncomment to re-enable multimedia support
      // {
      //   'QuestionID': 'QID_VOICE_NOTE_URLS',
      //   'QuestionText': 'Voice Note URLs (Internal)',
      //   'QuestionType': 'TE',
      // },
      // {
      //   'QuestionID': 'QID_IMAGE_URLS',
      //   'QuestionText': 'Image URLs (Internal)',
      //   'QuestionType': 'TE',
      // },
      {
        'QuestionID': 'QID_RESEARCH_SITE',
        'QuestionText': 'Research Site',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_SUBMITTED_AT',
        'QuestionText': 'Submission Timestamp',
        'QuestionType': 'TE',
      },
      {
        'QuestionID': 'QID_LOCATION_DATA',
        'QuestionText': 'Encrypted Location Data',
        'QuestionType': 'TE',
      },
    ];
  }

  /// Define Consent Form questions based on Flutter ConsentResponse model
  static List<Map<String, dynamic>> _getConsentSurveyQuestions() {
    return [
      {
        'QuestionID': 'QID1',
        'QuestionText': 'Participant Code',
        'QuestionType': 'TE',
        'DataExportTag': 'PARTICIPANT_CODE',
      },
      {
        'QuestionID': 'QID2',
        'QuestionText': 'Participant UUID',
        'QuestionType': 'TE',
        'DataExportTag': 'PARTICIPANT_UUID',
      },
      {
        'QuestionID': 'QID3',
        'QuestionText': 'I GIVE MY CONSENT to participate in this study.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_PARTICIPATE',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID4',
        'QuestionText': 'I GIVE MY CONSENT for my personal data to be processed by Qualtrics, under their terms and conditions (https://www.qualtrics.com/privacy-statement/).',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_QUALTRICS_DATA',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID5',
        'QuestionText': 'I GIVE MY CONSENT to being asked about my race/ethnicity.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_RACE_ETHNICITY',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID6',
        'QuestionText': 'I GIVE MY CONSENT to being asked about my health.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_HEALTH',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID7',
        'QuestionText': 'I GIVE MY CONSENT to being asked about my sexual orientation.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_SEXUAL_ORIENTATION',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID8',
        'QuestionText': 'I GIVE MY CONSENT to being asked about my location and mobility.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_LOCATION_MOBILITY',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID9',
        'QuestionText': 'I GIVE MY CONSENT to transferring my personal data to countries outside South Africa.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_DATA_TRANSFER',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID10',
        'QuestionText': 'I GIVE MY CONSENT to researchers reporting what I contribute (what I answer) publicly (e.g., in reports, books, magazines, websites) without my full name being included.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_PUBLIC_REPORTING',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID11',
        'QuestionText': 'I GIVE MY CONSENT to what I contribute being shared with national and international researchers and partners involved in this project.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_RESEARCHER_SHARING',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID12',
        'QuestionText': 'I GIVE MY CONSENT to what I contribute being used for further research or teaching purposes by the University of Pretoria and project partners.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_FURTHER_RESEARCH',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID13',
        'QuestionText': 'I GIVE MY CONSENT to what I contribute being placed in a public repository in a deidentified or anonymised form once the project is complete.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_PUBLIC_REPOSITORY',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID14',
        'QuestionText': 'I GIVE MY CONSENT to being contacted about participation in possible follow-up studies.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'CONSENT_FOLLOWUP_CONTACT',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID15',
        'QuestionText': 'Consent Timestamp',
        'QuestionType': 'TE',
        'DataExportTag': 'CONSENTED_AT',
      },
    ];
  }

  /// Method to print survey creation instructions
  static void printSetupInstructions() {
    print('''
=== QUALTRICS SURVEY SETUP INSTRUCTIONS ===

1. Replace 'YOUR_QUALTRICS_API_TOKEN_HERE' with your actual Qualtrics API token
2. Ensure your Qualtrics account has API access enabled
3. Run: QualtricsSurveyCreator.createAllSurveys()
4. Copy the returned survey IDs to your QualtricsApiService constants

Example usage:
```dart
final surveyIds = await QualtricsSurveyCreator.createAllSurveys();
print('Initial Survey ID: \${surveyIds['initial']}');
print('Biweekly Survey ID: \${surveyIds['biweekly']}');
print('Consent Survey ID: \${surveyIds['consent']}');
```

This will create three surveys in Qualtrics that exactly match your Flutter app structure:
- Initial Survey (demographics and baseline data)
- Biweekly Survey (wellbeing and location data)
- Consent Form (audit trail of consent decisions)
''');
  }
}
