import 'dart:convert';
import 'dart:io';

/// Script to create new Qualtrics surveys with proper data collection for all questions
/// Based on the working approach from create_consent_survey_blueprint.dart
void main() async {
  print('🔧 Creating New Qualtrics Surveys for Fixed Data Collection...\n');

  const String qualtricsToken = 'WxyQMBmQvkPrL3H9YuKPCGhpCtccT7Z28KKwkMVt';
  const String qualtricsUrl = 'https://pretoria.eu.qualtrics.com';

  final client = HttpClient();
  
  try {
    // Create all three surveys
    final initialSurveyId = await createInitialSurvey(client, qualtricsUrl, qualtricsToken);
    final biweeklySurveyId = await createBiweeklySurvey(client, qualtricsUrl, qualtricsToken);
    final consentSurveyId = await createConsentSurvey(client, qualtricsUrl, qualtricsToken);
    
    print('\n🎉 All surveys created successfully!');
    print('📋 Update these in your app code:');
    print('Initial Survey ID: $initialSurveyId');
    print('Biweekly Survey ID: $biweeklySurveyId');
    print('Consent Survey ID: $consentSurveyId');
    
  } catch (e) {
    print('❌ Error creating surveys: $e');
  } finally {
    client.close();
  }
}

/// Create the Initial Survey with all 34 questions
Future<String> createInitialSurvey(HttpClient client, String qualtricsUrl, String qualtricsToken) async {
  print('📝 Creating Initial Survey (34 questions)...');
  
  final surveyDefinition = {
    "SurveyName": "Gauteng Wellbeing Mapper - Initial Survey (34 Questions)",
    "Language": "EN",
    "ProjectCategory": "CORE"
  };

  // Step 1: Create the survey
  final createRequest = await client.postUrl(Uri.parse('$qualtricsUrl/API/v3/survey-definitions'));
  createRequest.headers.set('X-API-TOKEN', qualtricsToken);
  createRequest.headers.set('Content-Type', 'application/json');
  createRequest.write(jsonEncode(surveyDefinition));
  
  final createResponse = await createRequest.close();
  final createBody = await createResponse.transform(utf8.decoder).join();
  final createData = jsonDecode(createBody);
  
  if (createResponse.statusCode != 200) {
    throw Exception('Failed to create initial survey: $createBody');
  }
  
  final surveyId = createData['result']['SurveyID'];
  print('✅ Initial survey created with ID: $surveyId');
  
  // Step 2: Add all 34 questions
  final questions = _getInitialSurveyQuestions();
  await _addQuestionsToSurvey(client, qualtricsUrl, qualtricsToken, surveyId, questions);
  
  return surveyId;
}

/// Create the Biweekly Survey with all 19 questions
Future<String> createBiweeklySurvey(HttpClient client, String qualtricsUrl, String qualtricsToken) async {
  print('📝 Creating Biweekly Survey (19 questions)...');
  
  final surveyDefinition = {
    "SurveyName": "Gauteng Wellbeing Mapper - Biweekly Survey (19 Questions)",
    "Language": "EN",
    "ProjectCategory": "CORE"
  };

  // Step 1: Create the survey
  final createRequest = await client.postUrl(Uri.parse('$qualtricsUrl/API/v3/survey-definitions'));
  createRequest.headers.set('X-API-TOKEN', qualtricsToken);
  createRequest.headers.set('Content-Type', 'application/json');
  createRequest.write(jsonEncode(surveyDefinition));
  
  final createResponse = await createRequest.close();
  final createBody = await createResponse.transform(utf8.decoder).join();
  final createData = jsonDecode(createBody);
  
  if (createResponse.statusCode != 200) {
    throw Exception('Failed to create biweekly survey: $createBody');
  }
  
  final surveyId = createData['result']['SurveyID'];
  print('✅ Biweekly survey created with ID: $surveyId');
  
  // Step 2: Add all 19 questions
  final questions = _getBiweeklySurveyQuestions();
  await _addQuestionsToSurvey(client, qualtricsUrl, qualtricsToken, surveyId, questions);
  
  return surveyId;
}

/// Create the Consent Survey with all 16 questions
Future<String> createConsentSurvey(HttpClient client, String qualtricsUrl, String qualtricsToken) async {
  print('📝 Creating Consent Survey (16 questions)...');
  
  final surveyDefinition = {
    "SurveyName": "Gauteng Wellbeing Mapper - Consent Survey (16 Questions)",
    "Language": "EN",
    "ProjectCategory": "CORE"
  };

  // Step 1: Create the survey
  final createRequest = await client.postUrl(Uri.parse('$qualtricsUrl/API/v3/survey-definitions'));
  createRequest.headers.set('X-API-TOKEN', qualtricsToken);
  createRequest.headers.set('Content-Type', 'application/json');
  createRequest.write(jsonEncode(surveyDefinition));
  
  final createResponse = await createRequest.close();
  final createBody = await createResponse.transform(utf8.decoder).join();
  final createData = jsonDecode(createBody);
  
  if (createResponse.statusCode != 200) {
    throw Exception('Failed to create consent survey: $createBody');
  }
  
  final surveyId = createData['result']['SurveyID'];
  print('✅ Consent survey created with ID: $surveyId');
  
  // Step 2: Add all 16 questions
  final questions = _getConsentSurveyQuestions();
  await _addQuestionsToSurvey(client, qualtricsUrl, qualtricsToken, surveyId, questions);
  
  return surveyId;
}

/// Add questions to a survey
Future<void> _addQuestionsToSurvey(HttpClient client, String qualtricsUrl, String qualtricsToken, String surveyId, List<Map<String, dynamic>> questions) async {
  for (int i = 0; i < questions.length; i++) {
    final question = questions[i];
    print('  Adding question ${i + 1}/${questions.length}: ${question['DataExportTag']}');
    
    final questionRequest = await client.postUrl(Uri.parse('$qualtricsUrl/API/v3/survey-definitions/$surveyId/questions'));
    questionRequest.headers.set('X-API-TOKEN', qualtricsToken);
    questionRequest.headers.set('Content-Type', 'application/json');
    questionRequest.write(jsonEncode(question));
    
    final questionResponse = await questionRequest.close();
    final questionBody = await questionResponse.transform(utf8.decoder).join();
    
    if (questionResponse.statusCode != 200) {
      throw Exception('Failed to add question ${question['DataExportTag']}: $questionBody');
    }
  }
  print('✅ All questions added successfully');
}

/// Define all 34 questions for the Initial Survey
List<Map<String, dynamic>> _getInitialSurveyQuestions() {
  return [
    // Q1: Participant UUID (hidden)
    {
      "QuestionText": "Participant UUID (Hidden)",
      "DataExportTag": "QID1",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Participant UUID (hidden field)",
      "DisplayLogic": {
        "0": {
          "0": {
            "LogicType": "Question",
            "QuestionID": "QID1",
            "QuestionIsInLoop": "no",
            "ChoiceLocator": "q://QID1/SelectedChoicesTextEntry",
            "Operator": "EqualTo",
            "RightOperand": "NEVER_SHOW_THIS",
            "Type": "Expression"
          },
          "Type": "BooleanExpression"
        },
        "Type": "BooleanExpression",
        "inPage": false
      }
    },
    // Q2: Age
    {
      "QuestionText": "What is your age?",
      "DataExportTag": "QID2",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Age in years"
    },
    // Q3: Suburb
    {
      "QuestionText": "What suburb or community do you live in?",
      "DataExportTag": "QID3",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Suburb or community in Gauteng"
    },
    // Q4: Ethnicity
    {
      "QuestionText": "How do you describe your race/ethnicity? (comma-separated if multiple)",
      "DataExportTag": "QID4",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Race/ethnicity (comma-separated)"
    },
    // Q5: Gender
    {
      "QuestionText": "How do you describe your gender identity?",
      "DataExportTag": "QID5",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Gender identity"
    },
    // Q6: Sexuality
    {
      "QuestionText": "How do you describe your sexual orientation?",
      "DataExportTag": "QID6",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Sexual orientation"
    },
    // Q7: Birth place
    {
      "QuestionText": "Where were you born?",
      "DataExportTag": "QID7",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Place of birth"
    },
    // Q8: Building type
    {
      "QuestionText": "What type of building do you live in?",
      "DataExportTag": "QID8",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Building type"
    },
    // Q9: Household items
    {
      "QuestionText": "What household items do you have? (comma-separated)",
      "DataExportTag": "QID9",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Household items (comma-separated)"
    },
    // Q10: Education
    {
      "QuestionText": "What is your highest level of education?",
      "DataExportTag": "QID10",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Education level"
    },
    // Q11: Climate activism
    {
      "QuestionText": "How often are you involved in climate activism?",
      "DataExportTag": "QID11",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Climate activism involvement"
    },
    // Q12: Employment status
    {
      "QuestionText": "What is your employment status?",
      "DataExportTag": "QID12",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Employment status"
    },
    // Q13: Income
    {
      "QuestionText": "What is your income level?",
      "DataExportTag": "QID13",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Income level"
    },
    // Q14: Activities
    {
      "QuestionText": "What activities have you done in the last two weeks? (comma-separated)",
      "DataExportTag": "QID14",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Activities in last two weeks"
    },
    // Q15: Living arrangement
    {
      "QuestionText": "Do you live alone or with others?",
      "DataExportTag": "QID15",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Living arrangement"
    },
    // Q16: Relationship status
    {
      "QuestionText": "What is your relationship status?",
      "DataExportTag": "QID16",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Relationship status"
    },
    // Q17: General health
    {
      "QuestionText": "How would you rate your general health? (1=Excellent, 2=Very good, 3=Good, 4=Fair, 5=Poor)",
      "DataExportTag": "QID17",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "General health (1-5)"
    },
    // Q18-Q22: WHO-5 Wellbeing questions
    {
      "QuestionText": "WHO-5: Over the last two weeks, have you been in good spirits? (0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time)",
      "DataExportTag": "QID18",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "WHO-5: Cheerful spirits (0-5)"
    },
    {
      "QuestionText": "WHO-5: Over the last two weeks, have you felt calm and relaxed? (0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time)",
      "DataExportTag": "QID19",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "WHO-5: Calm and relaxed (0-5)"
    },
    {
      "QuestionText": "WHO-5: Over the last two weeks, have you felt active and vigorous? (0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time)",
      "DataExportTag": "QID20",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "WHO-5: Active and vigorous (0-5)"
    },
    {
      "QuestionText": "WHO-5: Over the last two weeks, did you wake up feeling fresh and rested? (0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time)",
      "DataExportTag": "QID21",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "WHO-5: Woke up fresh and rested (0-5)"
    },
    {
      "QuestionText": "WHO-5: Over the last two weeks, has your daily life been filled with things that interest you? (0=At no time, 1=Some of the time, 2=Less than half, 3=More than half, 4=Most of the time, 5=All of the time)",
      "DataExportTag": "QID22",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "WHO-5: Daily life filled with interesting things (0-5)"
    },
    // Q23-Q27: Personal characteristics (currently working)
    {
      "QuestionText": "Personal: I cooperate with people (1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot)",
      "DataExportTag": "QID23",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: I cooperate with people (1-5)"
    },
    {
      "QuestionText": "Personal: Improving qualifications/skills is important to me (1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot)",
      "DataExportTag": "QID24",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Improving qualifications/skills important (1-5)"
    },
    {
      "QuestionText": "Personal: I know how to behave in social situations (1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot)",
      "DataExportTag": "QID25",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Know how to behave in social situations (1-5)"
    },
    {
      "QuestionText": "Personal: My family have supported me (1=Not at all, 2=A little, 3=Somewhat, 4=Quite a bit, 5=A lot)",
      "DataExportTag": "QID26",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Family have supported me (1-5)"
    },
    {
      "QuestionText": "Personal: My family knows me well",
      "DataExportTag": "QID27",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Family knows me (scale)"
    },
    // Q28-Q32: MISSING QUESTIONS - Currently not captured!
    {
      "QuestionText": "Personal: I have access to food when I need it",
      "DataExportTag": "QID28",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Access to food (scale)"
    },
    {
      "QuestionText": "Personal: People enjoy spending time with me",
      "DataExportTag": "QID29",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: People enjoy time with me (scale)"
    },
    {
      "QuestionText": "Personal: I can talk to my family about my problems",
      "DataExportTag": "QID30",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Talk to family about problems (scale)"
    },
    {
      "QuestionText": "Personal: My friends support me",
      "DataExportTag": "QID31",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Friends support me (scale)"
    },
    {
      "QuestionText": "Personal: I feel like I belong in my community",
      "DataExportTag": "QID32",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Belong in community (scale)"
    },
    // Q33: Location data (hidden)
    {
      "QuestionText": "Location Data (Hidden)",
      "DataExportTag": "QID33",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Encrypted location data (hidden field)",
      "DisplayLogic": {
        "0": {
          "0": {
            "LogicType": "Question",
            "QuestionID": "QID33",
            "QuestionIsInLoop": "no",
            "ChoiceLocator": "q://QID33/SelectedChoicesTextEntry",
            "Operator": "EqualTo",
            "RightOperand": "NEVER_SHOW_THIS",
            "Type": "Expression"
          },
          "Type": "BooleanExpression"
        },
        "Type": "BooleanExpression",
        "inPage": false
      }
    },
    // Q34: Submission timestamp (hidden)
    {
      "QuestionText": "Submission Timestamp (Hidden)",
      "DataExportTag": "QID34",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Submission timestamp (hidden field)",
      "DisplayLogic": {
        "0": {
          "0": {
            "LogicType": "Question",
            "QuestionID": "QID34",
            "QuestionIsInLoop": "no",
            "ChoiceLocator": "q://QID34/SelectedChoicesTextEntry",
            "Operator": "EqualTo",
            "RightOperand": "NEVER_SHOW_THIS",
            "Type": "Expression"
          },
          "Type": "BooleanExpression"
        },
        "Type": "BooleanExpression",
        "inPage": false
      }
    }
  ];
}

/// Define all 19 questions for the Biweekly Survey  
List<Map<String, dynamic>> _getBiweeklySurveyQuestions() {
  return [
    // Q1: Participant UUID (hidden)
    {
      "QuestionText": "Participant UUID (Hidden)",
      "DataExportTag": "QID1",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Participant UUID (hidden field)",
      "DisplayLogic": {
        "0": {
          "0": {
            "LogicType": "Question",
            "QuestionID": "QID1",
            "QuestionIsInLoop": "no",
            "ChoiceLocator": "q://QID1/SelectedChoicesTextEntry", 
            "Operator": "EqualTo",
            "RightOperand": "NEVER_SHOW_THIS",
            "Type": "Expression"
          },
          "Type": "BooleanExpression"
        },
        "Type": "BooleanExpression",
        "inPage": false
      }
    },
    // Q2-Q19: All biweekly questions
    {
      "QuestionText": "What activities have you done in the last two weeks? (comma-separated)",
      "DataExportTag": "QID2",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Activities in last two weeks"
    },
    {
      "QuestionText": "Do you live alone or with others?",
      "DataExportTag": "QID3",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Living arrangement"
    },
    {
      "QuestionText": "What is your relationship status?",
      "DataExportTag": "QID4",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Relationship status"
    },
    {
      "QuestionText": "How would you rate your general health? (1=Excellent, 2=Very good, 3=Good, 4=Fair, 5=Poor)",
      "DataExportTag": "QID5",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "General health (1-5)"
    },
    {
      "QuestionText": "WHO-5: Over the last two weeks, have you been in good spirits? (0-5)",
      "DataExportTag": "QID6",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "WHO-5: Have you been in good spirits? (0-5)"
    },
    {
      "QuestionText": "WHO-5: Over the last two weeks, have you felt calm and relaxed? (0-5)",
      "DataExportTag": "QID7",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "WHO-5: Have you felt calm and relaxed? (0-5)"
    },
    {
      "QuestionText": "WHO-5: Over the last two weeks, have you felt active and vigorous? (0-5)",
      "DataExportTag": "QID8",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "WHO-5: Have you felt active and vigorous? (0-5)"
    },
    {
      "QuestionText": "WHO-5: Over the last two weeks, did you wake up feeling fresh and rested? (0-5)",
      "DataExportTag": "QID9",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "WHO-5: Did you wake up feeling fresh and rested? (0-5)"
    },
    {
      "QuestionText": "WHO-5: Over the last two weeks, has your daily life been filled with things that interest you? (0-5)",
      "DataExportTag": "QID10",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "WHO-5: Has your daily life been filled with things that interest you? (0-5)"
    },
    {
      "QuestionText": "Personal: I cooperate with people (1-5)",
      "DataExportTag": "QID11",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: I cooperate with people (1-5)"
    },
    {
      "QuestionText": "Personal: Improving qualifications/skills is important to me (1-5)",
      "DataExportTag": "QID12",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Improving qualifications/skills important (1-5)"
    },
    {
      "QuestionText": "Personal: I know how to behave in social situations (1-5)",
      "DataExportTag": "QID13",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Know how to behave in social situations (1-5)"
    },
    {
      "QuestionText": "Personal: My family have supported me (1-5)",
      "DataExportTag": "QID14",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Personal: Family have supported me (1-5)"
    },
    {
      "QuestionText": "What environmental challenges have you experienced? (text)",
      "DataExportTag": "QID15",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Environmental challenges experienced (text)"
    },
    {
      "QuestionText": "What was your stress level from these challenges?",
      "DataExportTag": "QID16",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Stress level from challenges"
    },
    {
      "QuestionText": "What helped you cope with these challenges? (text)",
      "DataExportTag": "QID17",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "What helped cope with challenges (text)"
    },
    // Q18: Location data (hidden)
    {
      "QuestionText": "Location Data (Hidden)",
      "DataExportTag": "QID18",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Encrypted location data (hidden field)",
      "DisplayLogic": {
        "0": {
          "0": {
            "LogicType": "Question",
            "QuestionID": "QID18",
            "QuestionIsInLoop": "no",
            "ChoiceLocator": "q://QID18/SelectedChoicesTextEntry",
            "Operator": "EqualTo",
            "RightOperand": "NEVER_SHOW_THIS",
            "Type": "Expression"
          },
          "Type": "BooleanExpression"
        },
        "Type": "BooleanExpression",
        "inPage": false
      }
    },
    // Q19: Submission timestamp (hidden)
    {
      "QuestionText": "Submission Timestamp (Hidden)",
      "DataExportTag": "QID19",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Submission timestamp (hidden field)",
      "DisplayLogic": {
        "0": {
          "0": {
            "LogicType": "Question",
            "QuestionID": "QID19",
            "QuestionIsInLoop": "no",
            "ChoiceLocator": "q://QID19/SelectedChoicesTextEntry",
            "Operator": "EqualTo",
            "RightOperand": "NEVER_SHOW_THIS",
            "Type": "Expression"
          },
          "Type": "BooleanExpression"
        },
        "Type": "BooleanExpression",
        "inPage": false
      }
    }
  ];
}

/// Define all 16 questions for the Consent Survey
List<Map<String, dynamic>> _getConsentSurveyQuestions() {
  return [
    {
      "QuestionText": "Participant Code",
      "DataExportTag": "QID1",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Participant code"
    },
    {
      "QuestionText": "Participant UUID (Hidden)",
      "DataExportTag": "QID2",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Participant UUID (hidden field)",
      "DisplayLogic": {
        "0": {
          "0": {
            "LogicType": "Question",
            "QuestionID": "QID2",
            "QuestionIsInLoop": "no",
            "ChoiceLocator": "q://QID2/SelectedChoicesTextEntry",
            "Operator": "EqualTo",
            "RightOperand": "NEVER_SHOW_THIS",
            "Type": "Expression"
          },
          "Type": "BooleanExpression"
        },
        "Type": "BooleanExpression",
        "inPage": false
      }
    },
    // QID3-QID14: All consent questions (1=yes, 0=no)
    {
      "QuestionText": "I GIVE MY CONSENT to participate in this pilot study",
      "DataExportTag": "QID3",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to participate in this pilot study (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT for my personal data to be processed by Qualtrics",
      "DataExportTag": "QID4",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT for my personal data to be processed by Qualtrics (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT to being asked about by race/ethnicity",
      "DataExportTag": "QID5",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to being asked about by race/ethnicity (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT to being asked about my health",
      "DataExportTag": "QID6",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to being asked about my health (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT to being asked about my sexual orientation",
      "DataExportTag": "QID7",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to being asked about my sexual orientation (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT to being asked about my location and mobility",
      "DataExportTag": "QID8",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to being asked about my location and mobility (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT to transferring my personal data to countries outside South Africa",
      "DataExportTag": "QID9",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to transferring my personal data to countries outside South Africa (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT to researchers reporting what I contribute publicly without my full name",
      "DataExportTag": "QID10",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to researchers reporting what I contribute publicly without my full name (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT to what I contribute being shared with national and international researchers",
      "DataExportTag": "QID11",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to what I contribute being shared with national and international researchers (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT to what I contribute being used for further research or teaching purposes",
      "DataExportTag": "QID12",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to what I contribute being used for further research or teaching purposes (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT to what I contribute being placed in a public repository in deidentified form",
      "DataExportTag": "QID13",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to what I contribute being placed in a public repository in deidentified form (1/0)"
    },
    {
      "QuestionText": "I GIVE MY CONSENT to being contacted about participation in possible follow-up studies",
      "DataExportTag": "QID14",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "I GIVE MY CONSENT to being contacted about participation in possible follow-up studies (1/0)"
    },
    {
      "QuestionText": "Participant signature",
      "DataExportTag": "QID15",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Participant signature"
    },
    {
      "QuestionText": "Consent timestamp",
      "DataExportTag": "QID16",
      "QuestionType": "TE",
      "Selector": "SL",
      "Configuration": {"QuestionDescriptionOption": "UseText"},
      "QuestionDescription": "Consent timestamp"
    }
  ];
}
