import 'dart:convert';
import 'package:http/http.dart' as http;

/// Comprehensive Qualtrics Survey Creator with Exact Question Text from Flutter App
/// This creates surveys with the exact question text that users see in the app
void main() async {
  import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  print('� Creating proper Qualtrics surveys with exact Flutter app question text...');
  print('');

  // Check if API token is set
  final apiToken = Platform.environment['QUALTRICS_API_TOKEN'] ?? '';
  if (apiToken.isEmpty) {
    print('❌ QUALTRICS_API_TOKEN environment variable not set');
    print('Please set it with: export QUALTRICS_API_TOKEN=your_token_here');
    return;
  }

  try {
    final creator = ProperQualtricsSurveyCreator(apiToken);
    
    final initialSurveyId = await creator.createInitialSurvey();
    print('✅ Initial Survey Created: $initialSurveyId');
  
  try {
    final creator = ProperQualtricsSurveyCreator();
    
    // Create all three surveys
    final initialSurveyId = await creator.createInitialSurvey();
    print('✅ Initial Survey Created: $initialSurveyId');
    
    final biweeklySurveyId = await creator.createBiweeklySurvey();
    print('✅ Biweekly Survey Created: $biweeklySurveyId');
    
    final consentSurveyId = await creator.createConsentSurvey();
    print('✅ Consent Survey Created: $consentSurveyId');
    
    print('');
    print('🎉 SUCCESS! All surveys created with proper question text');
    print('');
    print('📋 UPDATE YOUR API SERVICE:');
    print('Replace these constants in lib/services/qualtrics_api_service.dart:');
    print('  static const String _initialSurveyId = \'$initialSurveyId\';');
    print('  static const String _biweeklySurveyId = \'$biweeklySurveyId\';');
    print('  static const String _consentSurveyId = \'$consentSurveyId\';');
    
  } catch (e) {
    print('❌ Error creating surveys: $e');
  }
}

class ProperQualtricsSurveyCreator {
  static const String _baseUrl = 'https://pretoria.eu.qualtrics.com/API/v3';
  final String _apiToken;
  
  ProperQualtricsSurveyCreator(this._apiToken);
  
  /// Create Initial Survey with exact question text from Flutter app
  Future<String> createInitialSurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Initial Survey (Proper)',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
    };
    
    final surveyId = await _createSurvey(surveyDefinition);
    await _addQuestionsToSurvey(surveyId, _getInitialSurveyQuestions());
    await _publishSurvey(surveyId);
    
    return surveyId;
  }
  
  /// Create Biweekly Survey with exact question text from Flutter app
  Future<String> createBiweeklySurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Biweekly Survey (Proper)',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
    };
    
    final surveyId = await _createSurvey(surveyDefinition);
    await _addQuestionsToSurvey(surveyId, _getBiweeklySurveyQuestions());
    await _publishSurvey(surveyId);
    
    return surveyId;
  }
  
  /// Create Consent Survey with exact question text from Flutter app
  Future<String> createConsentSurvey() async {
    final surveyDefinition = {
      'SurveyName': 'Gauteng Wellbeing Mapper - Consent Form (Proper)',
      'Language': 'EN',
      'ProjectCategory': 'CORE',
    };
    
    final surveyId = await _createSurvey(surveyDefinition);
    await _addQuestionsToSurvey(surveyId, _getConsentSurveyQuestions());
    await _publishSurvey(surveyId);
    
    return surveyId;
  }
  
  /// Initial Survey Questions - Exact text from Flutter UI
  List<Map<String, dynamic>> _getInitialSurveyQuestions() {
    return [
      // Hidden field for participant UUID
      {
        'QuestionID': 'QID1',
        'QuestionText': 'Participant UUID (Hidden)',
        'QuestionType': 'TE',
        'DataExportTag': 'participant_uuid',
      },
      
      // Demographics Section - Exact text from initial_survey_screen.dart
      {
        'QuestionID': 'QID2',
        'QuestionText': 'How old are you?',
        'QuestionType': 'TE',
        'DataExportTag': 'age',
      },
      {
        'QuestionID': 'QID3',
        'QuestionText': 'In which suburb or community in Gauteng do you live?',
        'QuestionType': 'TE',
        'DataExportTag': 'suburb',
      },
      {
        'QuestionID': 'QID4',
        'QuestionText': 'Ethnicity (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'SubSelector': 'TX',
        'DataExportTag': 'ethnicity',
        'Choices': {
          '1': {'Display': 'Black'},
          '2': {'Display': 'Coloured'},
          '3': {'Display': 'Indian'},
          '4': {'Display': 'White'},
          '5': {'Display': 'Other'},
        },
      },
      {
        'QuestionID': 'QID5',
        'QuestionText': 'Gender Identity',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'gender',
        'Choices': {
          '1': {'Display': 'Woman'},
          '2': {'Display': 'Man'},
          '3': {'Display': 'Non-binary'},
          '4': {'Display': 'Other'},
          '5': {'Display': 'Prefer not to say'},
        },
      },
      {
        'QuestionID': 'QID6',
        'QuestionText': 'Sexual Orientation',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'sexuality',
        'Choices': {
          '1': {'Display': 'Heterosexual'},
          '2': {'Display': 'Gay'},
          '3': {'Display': 'Lesbian'},
          '4': {'Display': 'Bisexual'},
          '5': {'Display': 'Pansexual'},
          '6': {'Display': 'Asexual'},
          '7': {'Display': 'Other'},
          '8': {'Display': 'Prefer not to say'},
        },
      },
      {
        'QuestionID': 'QID7',
        'QuestionText': 'Place of Birth',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'birth_place',
        'Choices': {
          '1': {'Display': 'South Africa'},
          '2': {'Display': 'Other African country'},
          '3': {'Display': 'Outside Africa'},
          '4': {'Display': 'Prefer not to say'},
        },
      },
      {
        'QuestionID': 'QID8',
        'QuestionText': 'Building Type',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'building_type',
        'Choices': {
          '1': {'Display': 'RDP house'},
          '2': {'Display': 'Brick house'},
          '3': {'Display': 'Flat/apartment'},
          '4': {'Display': 'Backyard dwelling'},
          '5': {'Display': 'Informal settlement/shack'},
          '6': {'Display': 'Other'},
        },
      },
      {
        'QuestionID': 'QID9',
        'QuestionText': 'Household Items (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'SubSelector': 'TX',
        'DataExportTag': 'household_items',
        'Choices': {
          '1': {'Display': 'Television'},
          '2': {'Display': 'Radio'},
          '3': {'Display': 'Computer/Laptop'},
          '4': {'Display': 'Smartphone'},
          '5': {'Display': 'Internet access'},
          '6': {'Display': 'Car'},
          '7': {'Display': 'Bicycle'},
          '8': {'Display': 'Washing machine'},
          '9': {'Display': 'Refrigerator'},
          '10': {'Display': 'None of these'},
        },
      },
      {
        'QuestionID': 'QID10',
        'QuestionText': 'Education',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'education',
        'Choices': {
          '1': {'Display': 'No formal education'},
          '2': {'Display': 'Some primary school'},
          '3': {'Display': 'Completed primary school'},
          '4': {'Display': 'Some secondary school'},
          '5': {'Display': 'Completed secondary school'},
          '6': {'Display': 'Some tertiary education'},
          '7': {'Display': 'Completed tertiary education'},
          '8': {'Display': 'Prefer not to say'},
        },
      },
      {
        'QuestionID': 'QID11',
        'QuestionText': 'Climate Activism',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'climate_activism',
        'Choices': {
          '1': {'Display': 'Not involved at all'},
          '2': {'Display': 'Slightly involved'},
          '3': {'Display': 'Moderately involved'},
          '4': {'Display': 'Very involved'},
          '5': {'Display': 'Extremely involved'},
        },
      },
      {
        'QuestionID': 'QID12',
        'QuestionText': 'How would you describe your general health?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'general_health',
        'Choices': {
          '1': {'Display': 'Excellent'},
          '2': {'Display': 'Very good'},
          '3': {'Display': 'Good'},
          '4': {'Display': 'Fair'},
          '5': {'Display': 'Poor'},
        },
      },
      
      // Baseline Lifestyle Questions
      {
        'QuestionID': 'QID13',
        'QuestionText': 'What activities have you done recently? (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'SubSelector': 'TX',
        'DataExportTag': 'activities',
        'Choices': {
          '1': {'Display': 'Work'},
          '2': {'Display': 'Study'},
          '3': {'Display': 'Household chores'},
          '4': {'Display': 'Childcare'},
          '5': {'Display': 'Shopping'},
          '6': {'Display': 'Exercise/sport'},
          '7': {'Display': 'Socializing'},
          '8': {'Display': 'Recreation'},
          '9': {'Display': 'Healthcare visits'},
          '10': {'Display': 'Religious activities'},
          '11': {'Display': 'Other'},
        },
      },
      {
        'QuestionID': 'QID14',
        'QuestionText': 'Living Arrangement',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'living_arrangement',
        'Choices': {
          '1': {'Display': 'Living alone'},
          '2': {'Display': 'Living with partner/spouse'},
          '3': {'Display': 'Living with family'},
          '4': {'Display': 'Living with roommates'},
          '5': {'Display': 'Other'},
        },
      },
      {
        'QuestionID': 'QID15',
        'QuestionText': 'Relationship Status',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'relationship_status',
        'Choices': {
          '1': {'Display': 'Single'},
          '2': {'Display': 'In a relationship'},
          '3': {'Display': 'Married'},
          '4': {'Display': 'Divorced'},
          '5': {'Display': 'Widowed'},
          '6': {'Display': 'Prefer not to say'},
        },
      },
      
      // Wellbeing Questions - Exact text from recurring_survey_screen.dart
      {
        'QuestionID': 'QID16',
        'QuestionText': 'Have you been in good spirits?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'cheerful_spirits',
        'Choices': {
          '0': {'Display': 'At no time'},
          '1': {'Display': 'Some of the time'},
          '2': {'Display': 'Less than half of the time'},
          '3': {'Display': 'More than half of the time'},
          '4': {'Display': 'Most of the time'},
          '5': {'Display': 'All of the time'},
        },
      },
      {
        'QuestionID': 'QID17',
        'QuestionText': 'Have you felt calm and relaxed?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'calm_relaxed',
        'Choices': {
          '0': {'Display': 'At no time'},
          '1': {'Display': 'Some of the time'},
          '2': {'Display': 'Less than half of the time'},
          '3': {'Display': 'More than half of the time'},
          '4': {'Display': 'Most of the time'},
          '5': {'Display': 'All of the time'},
        },
      },
      {
        'QuestionID': 'QID18',
        'QuestionText': 'Have you felt active and vigorous?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'active_vigorous',
        'Choices': {
          '0': {'Display': 'At no time'},
          '1': {'Display': 'Some of the time'},
          '2': {'Display': 'Less than half of the time'},
          '3': {'Display': 'More than half of the time'},
          '4': {'Display': 'Most of the time'},
          '5': {'Display': 'All of the time'},
        },
      },
      {
        'QuestionID': 'QID19',
        'QuestionText': 'Did you wake up feeling fresh and rested?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'woke_up_fresh',
        'Choices': {
          '0': {'Display': 'At no time'},
          '1': {'Display': 'Some of the time'},
          '2': {'Display': 'Less than half of the time'},
          '3': {'Display': 'More than half of the time'},
          '4': {'Display': 'Most of the time'},
          '5': {'Display': 'All of the time'},
        },
      },
      {
        'QuestionID': 'QID20',
        'QuestionText': 'Has your daily life been filled with things that interest you?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'daily_life_interesting',
        'Choices': {
          '0': {'Display': 'At no time'},
          '1': {'Display': 'Some of the time'},
          '2': {'Display': 'Less than half of the time'},
          '3': {'Display': 'More than half of the time'},
          '4': {'Display': 'Most of the time'},
          '5': {'Display': 'All of the time'},
        },
      },
      
      // Personal Characteristics - Exact text from recurring_survey_screen.dart
      {
        'QuestionID': 'QID21',
        'QuestionText': 'I find it easy to cooperate with people',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'cooperate_with_people',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID22',
        'QuestionText': 'I am always improving my skills',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'improving_skills',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID23',
        'QuestionText': 'I feel comfortable in social situations',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'social_situations',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID24',
        'QuestionText': 'There is always someone in my family who can give me support',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'family_support',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID25',
        'QuestionText': 'There is always someone in my family who really knows me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'family_knows_me',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID26',
        'QuestionText': 'I have access to the food I need',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'access_to_food',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID27',
        'QuestionText': 'There are people who enjoy spending time with me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'people_enjoy_time',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID28',
        'QuestionText': 'I can talk to my family about problems',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'talk_to_family',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID29',
        'QuestionText': 'I have friends who can give me support',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'friends_support',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID30',
        'QuestionText': 'I feel like I belong in my community',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'belong_in_community',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID31',
        'QuestionText': 'My family stands by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'family_stands_by_me',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID32',
        'QuestionText': 'My friends stand by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'friends_stand_by_me',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID33',
        'QuestionText': 'I feel that I am treated fairly by others',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'treated_fairly',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID34',
        'QuestionText': 'I have opportunities to show how responsible I am',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'opportunities_responsibility',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID35',
        'QuestionText': 'I feel secure when I am with my family',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'secure_with_family',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID36',
        'QuestionText': 'I have opportunities to show my abilities',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'opportunities_abilities',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID37',
        'QuestionText': 'I enjoy my community\'s traditions',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'enjoy_cultural_traditions',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      
      // Digital Diary - Baseline
      {
        'QuestionID': 'QID38',
        'QuestionText': 'What environmental challenges have you experienced recently?',
        'QuestionType': 'TE',
        'DataExportTag': 'environmental_challenges',
      },
      {
        'QuestionID': 'QID39',
        'QuestionText': 'How stressful were these challenges?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'challenges_stress_level',
        'Choices': {
          '1': {'Display': 'Not stressful at all'},
          '2': {'Display': 'Slightly stressful'},
          '3': {'Display': 'Moderately stressful'},
          '4': {'Display': 'Very stressful'},
          '5': {'Display': 'Extremely stressful'},
        },
      },
      {
        'QuestionID': 'QID40',
        'QuestionText': 'Who or what helped you to manage/cope with these environmental challenges?',
        'QuestionType': 'TE',
        'DataExportTag': 'coping_help',
      },
      
      // Metadata
      {
        'QuestionID': 'QID41',
        'QuestionText': 'Submission Timestamp (Hidden)',
        'QuestionType': 'TE',
        'DataExportTag': 'submitted_at',
      },
    ];
  }
  
  /// Biweekly Survey Questions - Same as initial but with location data
  List<Map<String, dynamic>> _getBiweeklySurveyQuestions() {
    return [
      // Hidden field for participant UUID
      {
        'QuestionID': 'QID1',
        'QuestionText': 'Participant UUID (Hidden)',
        'QuestionType': 'TE',
        'DataExportTag': 'participant_uuid',
      },
      
      // Lifestyle Questions (no demographics)
      {
        'QuestionID': 'QID2',
        'QuestionText': 'What activities have you done recently? (Select all that apply)',
        'QuestionType': 'MC',
        'Selector': 'MAVR',
        'SubSelector': 'TX',
        'DataExportTag': 'activities',
        'Choices': {
          '1': {'Display': 'Work'},
          '2': {'Display': 'Study'},
          '3': {'Display': 'Household chores'},
          '4': {'Display': 'Childcare'},
          '5': {'Display': 'Shopping'},
          '6': {'Display': 'Exercise/sport'},
          '7': {'Display': 'Socializing'},
          '8': {'Display': 'Recreation'},
          '9': {'Display': 'Healthcare visits'},
          '10': {'Display': 'Religious activities'},
          '11': {'Display': 'Other'},
        },
      },
      {
        'QuestionID': 'QID3',
        'QuestionText': 'Living Arrangement',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'living_arrangement',
        'Choices': {
          '1': {'Display': 'Living alone'},
          '2': {'Display': 'Living with partner/spouse'},
          '3': {'Display': 'Living with family'},
          '4': {'Display': 'Living with roommates'},
          '5': {'Display': 'Other'},
        },
      },
      {
        'QuestionID': 'QID4',
        'QuestionText': 'Relationship Status',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'relationship_status',
        'Choices': {
          '1': {'Display': 'Single'},
          '2': {'Display': 'In a relationship'},
          '3': {'Display': 'Married'},
          '4': {'Display': 'Divorced'},
          '5': {'Display': 'Widowed'},
          '6': {'Display': 'Prefer not to say'},
        },
      },
      {
        'QuestionID': 'QID5',
        'QuestionText': 'How would you describe your general health?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'general_health',
        'Choices': {
          '1': {'Display': 'Excellent'},
          '2': {'Display': 'Very good'},
          '3': {'Display': 'Good'},
          '4': {'Display': 'Fair'},
          '5': {'Display': 'Poor'},
        },
      },
      
      // Wellbeing Questions
      {
        'QuestionID': 'QID6',
        'QuestionText': 'Have you been in good spirits?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'cheerful_spirits',
        'Choices': {
          '0': {'Display': 'At no time'},
          '1': {'Display': 'Some of the time'},
          '2': {'Display': 'Less than half of the time'},
          '3': {'Display': 'More than half of the time'},
          '4': {'Display': 'Most of the time'},
          '5': {'Display': 'All of the time'},
        },
      },
      {
        'QuestionID': 'QID7',
        'QuestionText': 'Have you felt calm and relaxed?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'calm_relaxed',
        'Choices': {
          '0': {'Display': 'At no time'},
          '1': {'Display': 'Some of the time'},
          '2': {'Display': 'Less than half of the time'},
          '3': {'Display': 'More than half of the time'},
          '4': {'Display': 'Most of the time'},
          '5': {'Display': 'All of the time'},
        },
      },
      {
        'QuestionID': 'QID8',
        'QuestionText': 'Have you felt active and vigorous?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'active_vigorous',
        'Choices': {
          '0': {'Display': 'At no time'},
          '1': {'Display': 'Some of the time'},
          '2': {'Display': 'Less than half of the time'},
          '3': {'Display': 'More than half of the time'},
          '4': {'Display': 'Most of the time'},
          '5': {'Display': 'All of the time'},
        },
      },
      {
        'QuestionID': 'QID9',
        'QuestionText': 'Did you wake up feeling fresh and rested?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'woke_up_fresh',
        'Choices': {
          '0': {'Display': 'At no time'},
          '1': {'Display': 'Some of the time'},
          '2': {'Display': 'Less than half of the time'},
          '3': {'Display': 'More than half of the time'},
          '4': {'Display': 'Most of the time'},
          '5': {'Display': 'All of the time'},
        },
      },
      {
        'QuestionID': 'QID10',
        'QuestionText': 'Has your daily life been filled with things that interest you?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'daily_life_interesting',
        'Choices': {
          '0': {'Display': 'At no time'},
          '1': {'Display': 'Some of the time'},
          '2': {'Display': 'Less than half of the time'},
          '3': {'Display': 'More than half of the time'},
          '4': {'Display': 'Most of the time'},
          '5': {'Display': 'All of the time'},
        },
      },
      
      // Personal Characteristics (continuing from QID11)
      {
        'QuestionID': 'QID11',
        'QuestionText': 'I find it easy to cooperate with people',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'cooperate_with_people',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID12',
        'QuestionText': 'I am always improving my skills',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'improving_skills',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID13',
        'QuestionText': 'I feel comfortable in social situations',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'social_situations',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID14',
        'QuestionText': 'There is always someone in my family who can give me support',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'family_support',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID15',
        'QuestionText': 'There is always someone in my family who really knows me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'family_knows_me',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID16',
        'QuestionText': 'I have access to the food I need',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'access_to_food',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID17',
        'QuestionText': 'There are people who enjoy spending time with me',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'people_enjoy_time',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID18',
        'QuestionText': 'I can talk to my family about problems',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'talk_to_family',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID19',
        'QuestionText': 'I have friends who can give me support',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'friends_support',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID20',
        'QuestionText': 'I feel like I belong in my community',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'belong_in_community',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID21',
        'QuestionText': 'My family stands by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'family_stands_by_me',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID22',
        'QuestionText': 'My friends stand by me during difficult times',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'friends_stand_by_me',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID23',
        'QuestionText': 'I feel that I am treated fairly by others',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'treated_fairly',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID24',
        'QuestionText': 'I have opportunities to show how responsible I am',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'opportunities_responsibility',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID25',
        'QuestionText': 'I feel secure when I am with my family',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'secure_with_family',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID26',
        'QuestionText': 'I have opportunities to show my abilities',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'opportunities_abilities',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      {
        'QuestionID': 'QID27',
        'QuestionText': 'I enjoy my community\'s traditions',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'enjoy_cultural_traditions',
        'Choices': {
          '1': {'Display': 'Not at all'},
          '2': {'Display': 'Slightly'},
          '3': {'Display': 'Moderately'},
          '4': {'Display': 'Very much'},
          '5': {'Display': 'Completely'},
        },
      },
      
      // Digital Diary
      {
        'QuestionID': 'QID28',
        'QuestionText': 'What environmental challenges have you experienced recently?',
        'QuestionType': 'TE',
        'DataExportTag': 'environmental_challenges',
      },
      {
        'QuestionID': 'QID29',
        'QuestionText': 'How stressful were these challenges?',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'challenges_stress_level',
        'Choices': {
          '1': {'Display': 'Not stressful at all'},
          '2': {'Display': 'Slightly stressful'},
          '3': {'Display': 'Moderately stressful'},
          '4': {'Display': 'Very stressful'},
          '5': {'Display': 'Extremely stressful'},
        },
      },
      {
        'QuestionID': 'QID30',
        'QuestionText': 'Who or what helped you to manage/cope with these environmental challenges?',
        'QuestionType': 'TE',
        'DataExportTag': 'coping_help',
      },
      
      // Location data and metadata
      {
        'QuestionID': 'QID31',
        'QuestionText': 'Encrypted Location Data (Hidden)',
        'QuestionType': 'TE',
        'DataExportTag': 'location_data',
      },
      {
        'QuestionID': 'QID32',
        'QuestionText': 'Submission Timestamp (Hidden)',
        'QuestionType': 'TE',
        'DataExportTag': 'submitted_at',
      },
    ];
  }
  
  /// Consent Survey Questions - Exact text from consent form
  List<Map<String, dynamic>> _getConsentSurveyQuestions() {
    return [
      {
        'QuestionID': 'QID1',
        'QuestionText': 'Participant UUID (Hidden)',
        'QuestionType': 'TE',
        'DataExportTag': 'participant_uuid',
      },
      {
        'QuestionID': 'QID2',
        'QuestionText': 'I GIVE MY CONSENT to participate in this study.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_participate',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID3',
        'QuestionText': 'I GIVE MY CONSENT for my personal data to be processed by Qualtrics, under their terms and conditions.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_qualtrics_data',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID4',
        'QuestionText': 'I GIVE MY CONSENT to being asked about my race/ethnicity.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_race_ethnicity',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID5',
        'QuestionText': 'I GIVE MY CONSENT to being asked about my health.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_health',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID6',
        'QuestionText': 'I GIVE MY CONSENT to being asked about my sexual orientation.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_sexual_orientation',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID7',
        'QuestionText': 'I GIVE MY CONSENT to being asked about my location and mobility.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_location_mobility',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID8',
        'QuestionText': 'I GIVE MY CONSENT to transferring my personal data to countries outside South Africa.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_data_transfer',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID9',
        'QuestionText': 'I GIVE MY CONSENT to researchers reporting what I contribute (what I answer) publicly (e.g., in reports, books, magazines, websites) without my full name being included.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_public_reporting',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID10',
        'QuestionText': 'I GIVE MY CONSENT to what I contribute being shared with national and international researchers and partners involved in this project.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_researcher_sharing',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID11',
        'QuestionText': 'I GIVE MY CONSENT to what I contribute being used for further research or teaching purposes by the University of Pretoria and project partners.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_further_research',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID12',
        'QuestionText': 'I GIVE MY CONSENT to what I contribute being placed in a public repository in a deidentified or anonymised form once the project is complete.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_public_repository',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID13',
        'QuestionText': 'I GIVE MY CONSENT to being contacted about participation in possible follow-up studies.',
        'QuestionType': 'MC',
        'Selector': 'SAVR',
        'DataExportTag': 'consent_followup_contact',
        'Choices': {
          '1': {'Display': 'I give my consent'},
          '0': {'Display': 'I do not give my consent'},
        },
      },
      {
        'QuestionID': 'QID14',
        'QuestionText': 'Consent Timestamp (Hidden)',
        'QuestionType': 'TE',
        'DataExportTag': 'consented_at',
      },
    ];
  }
  
  /// Helper Methods
  Future<String> _createSurvey(Map<String, dynamic> surveyDefinition) async {
    final url = Uri.parse('$_baseUrl/survey-definitions');
    
    print('📡 Creating survey: ${surveyDefinition['SurveyName']}');
    
    final response = await http.post(
      url,
      headers: {
        'X-API-TOKEN': _apiToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(surveyDefinition),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      final responseJson = jsonDecode(response.body);
      final surveyId = responseJson['result']['SurveyID'];
      print('✅ Survey created with ID: $surveyId');
      return surveyId;
    } else {
      throw Exception('Failed to create survey: ${response.statusCode} ${response.body}');
    }
  }
  
  Future<void> _addQuestionsToSurvey(String surveyId, List<Map<String, dynamic>> questions) async {
    print('📝 Adding ${questions.length} questions to survey $surveyId');
    
    for (int i = 0; i < questions.length; i++) {
      final question = questions[i];
      try {
        await _addSingleQuestion(surveyId, question);
        print('  ✅ Added question ${i + 1}/${questions.length}: ${question['QuestionText']}');
        
        // Small delay to avoid API rate limits
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('  ❌ Failed to add question ${i + 1}: ${question['QuestionText']} - Error: $e');
      }
    }
  }
  
  Future<void> _addSingleQuestion(String surveyId, Map<String, dynamic> questionData) async {
    final url = Uri.parse('$_baseUrl/survey-definitions/$surveyId/questions');
    
    final response = await http.post(
      url,
      headers: {
        'X-API-TOKEN': _apiToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode(questionData),
    );
    
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('Failed to add question: ${response.statusCode} ${response.body}');
    }
  }
  
  Future<void> _publishSurvey(String surveyId) async {
    final url = Uri.parse('$_baseUrl/survey-definitions/$surveyId/versions');
    
    final response = await http.post(
      url,
      headers: {
        'X-API-TOKEN': _apiToken,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'Published': true,
        'Description': 'Published via API',
      }),
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      print('🚀 Survey $surveyId published successfully');
    } else {
      print('⚠️ Warning: Could not publish survey $surveyId: ${response.statusCode} ${response.body}');
    }
  }
}
