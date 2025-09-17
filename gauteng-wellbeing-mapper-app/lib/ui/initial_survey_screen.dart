import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/survey_models.dart';
import '../models/consent_models.dart';
import '../models/app_mode.dart';
import '../services/app_mode_service.dart';
import '../services/encrypted_survey_service.dart';
import '../db/survey_database.dart';

class InitialSurveyScreen extends StatefulWidget {
  @override
  _InitialSurveyScreenState createState() => _InitialSurveyScreenState();
}

class _InitialSurveyScreenState extends State<InitialSurveyScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;
  String _researchSite = 'gauteng'; // Default to Gauteng
  
  // Track slider values for better UX - starts with no selection
  final Map<String, double?> _sliderValues = {};

  @override
  void initState() {
    super.initState();
    _loadResearchSite();
  }

  Future<void> _loadResearchSite() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final participationJson = prefs.getString('participation_settings');
      if (participationJson != null) {
        // Parse the JSON to get research site
        final Map<String, dynamic> participationData = Map<String, dynamic>.from(
          jsonDecode(participationJson)
        );
        
        final settings = ParticipationSettings.fromJson(participationData);
        setState(() {
          _researchSite = settings.researchSite ?? 'gauteng';
        });
      }
    } catch (e) {
      // Default to Gauteng if any error
      setState(() {
        _researchSite = 'gauteng';
      });
    }
  }

  // Barcelona-specific options
  final List<String> _barcelonaEthnicityOptions = [
    'South Asian',
    'East or Southeast Asian',
    'White',
    'Latina/o',
    'Maghrebi or Arab',
    'Black',
    'Romani or Gypsy',
    'Other',
    'Prefer not to say'
  ];

  final List<String> _barcelonaBirthPlaceOptions = [
    'Spain',
    'Other country',
    'Prefer not to say'
  ];

  final List<String> _barcelonaBuildingTypeOptions = [
    'It is a detached single-family home',
    'It is a semi-detached or terraced single-family home',
    'It is a two housing-unit building',
    'The housing unit is in a building with 3 or more units but less than 10',
    'The housing unit is in a building with 10 or more housing units',
    'The housing unit is a building that is used for other uses (even though it includes one or more housing units, for example, housing for porters, guards or security staff of the building)',
    'Other'
  ];

  final List<String> _barcelonaEducationOptions = [
    'Less than high school',
    'High school',
    'Bachelor\'s degree',
    'Graduate or professional degree',
    'Prefer not to say'
  ];

  // Gauteng-specific options
  final List<String> _gautengEthnicityOptions = [
    'Black',
    'Coloured',
    'Indian',
    'White',
    'Other',
    'Prefer not to say'
  ];

  final List<String> _gautengBirthPlaceOptions = [
    'South Africa',
    'Other African country',
    'Other country',
    'Prefer not to say'
  ];

  final List<String> _gautengBuildingTypeOptions = [
    'A brick house',
    'A townhouse in a complex of townhouses',
    'An RDP house',
    'A flat or apartment in an apartment building',
    'A backyard room',
    'Informal dwelling',
    'Other'
  ];

  final List<String> _gautengEducationOptions = [
    'Less than high school',
    'High school',
    'TVET college',
    'Bachelor\'s degree',
    'Professional degree',
    'Post-graduate degree (e.g., honours, masters or doctorate)',
    'Prefer not to say'
  ];

  // Common options for both sites
  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Transmale',
    'Transfemale',
    'Non-binary',
    'Prefer not to say'
  ];

  final List<String> _sexualityOptions = [
    'Heterosexual/straight',
    'Lesbian',
    'Gay',
    'Bisexual',
    'Queer',
    'Other',
    'Prefer not to say'
  ];

  final List<String> _livesInBarcelonaOptions = [
    'Yes',
    'No',
    'Don\'t know / Prefer not to say'
  ];

  final List<String> _generalHealthOptions = [
    'Excellent',
    'Very good',
    'Good',
    'Fair',
    'Poor'
  ];

  final List<String> _householdItemOptions = [
    'radio',
    'television',
    'refrigerator',
    'microwave',
    'internet access (e.g., fibre)',
    'computer',
    'cellular smartphone',
    'car',
    'electric cooling devices (e.g. fan or air-conditioning)'
  ];

  final List<String> _climateActivismOptions = [
    'all the time',
    'often',
    'sometimes',
    'occasionally',
    'never'
  ];

  // Getters for site-specific options
  List<String> get _ethnicityOptions => _researchSite == 'gauteng' 
      ? _gautengEthnicityOptions 
      : _barcelonaEthnicityOptions;
      
  List<String> get _birthPlaceOptions => _researchSite == 'gauteng' 
      ? _gautengBirthPlaceOptions 
      : _barcelonaBirthPlaceOptions;
      
  List<String> get _buildingTypeOptions => _researchSite == 'gauteng' 
      ? _gautengBuildingTypeOptions 
      : _barcelonaBuildingTypeOptions;
      
  List<String> get _educationOptions => _researchSite == 'gauteng' 
      ? _gautengEducationOptions 
      : _barcelonaEducationOptions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Initial Survey',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: Colors.blue,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: FormBuilder(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              SizedBox(height: 24),
              _buildAgeField(),
              SizedBox(height: 24),
              if (_researchSite == 'gauteng') ...[
                _buildSuburbField(),
                SizedBox(height: 24),
              ],
              _buildEthnicityField(),
              SizedBox(height: 24),
              _buildGenderField(),
              SizedBox(height: 24),
              _buildSexualityField(),
              SizedBox(height: 24),
              _buildBirthPlaceField(),
              SizedBox(height: 24),
              if (_researchSite == 'barcelona') ...[
                _buildLivesInBarcelonaField(),
                SizedBox(height: 24),
              ],
              _buildBuildingTypeField(),
              SizedBox(height: 24),
              _buildHouseholdItemsField(),
              SizedBox(height: 24),
              _buildEducationField(),
              SizedBox(height: 24),
              if (_researchSite == 'gauteng') ...[
                _buildGeneralHealthField(),
                SizedBox(height: 24),
              ],
              _buildClimateActivismField(),
              SizedBox(height: 24),
              // Add wellbeing questions (from biweekly survey)
              _buildWellbeingSection(),
              SizedBox(height: 24),
              _buildPersonalCharacteristicsSection(),
              SizedBox(height: 32),
              _buildActionButtons(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Welcome to the Wellbeing Mapping Study!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'This initial survey will help us understand your background. All responses are confidential and will be used only for research purposes.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeField() {
    return _buildSectionCard(
      title: 'Age',
      child: FormBuilderTextField(
        name: 'age',
        decoration: InputDecoration(
          labelText: 'How old are you?',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        // validator: FormBuilderValidators.compose([ // Removed - now optional
        //   FormBuilderValidators.integer(errorText: 'Please enter a valid age'),
        //   FormBuilderValidators.min(13, errorText: 'You must be at least 13 years old'),
        //   FormBuilderValidators.max(120, errorText: 'Please enter a valid age'),
        // ]),
      ),
    );
  }

  Widget _buildSuburbField() {
    return _buildSectionCard(
      title: 'Location',
      child: FormBuilderTextField(
        name: 'suburb',
        decoration: InputDecoration(
          labelText: 'In which suburb or community in Gauteng do you live?',
          border: OutlineInputBorder(),
        ),
        // validator: FormBuilderValidators.required(errorText: 'Please enter your suburb or community'), // Removed - now optional
      ),
    );
  }

  Widget _buildEthnicityField() {
    return _buildSectionCard(
      title: 'Ethnicity',
      subtitle: 'Select all that apply',
      child: FormBuilderCheckboxGroup<String>(
        name: 'ethnicity',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _ethnicityOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        orientation: OptionsOrientation.vertical,
        // validator: FormBuilderValidators.compose([ // Removed - now optional
        //   FormBuilderValidators.required(errorText: 'Please select at least one option'),
        // ]),
      ),
    );
  }

  Widget _buildGenderField() {
    return _buildSectionCard(
      title: 'Gender Identity',
      child: FormBuilderRadioGroup<String>(
        name: 'gender',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _genderOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildSexualityField() {
    return _buildSectionCard(
      title: 'Sexual Orientation',
      child: FormBuilderRadioGroup<String>(
        name: 'sexuality',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _sexualityOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildBirthPlaceField() {
    return _buildSectionCard(
      title: 'Place of Birth',
      child: FormBuilderRadioGroup<String>(
        name: 'birthPlace',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _birthPlaceOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildLivesInBarcelonaField() {
    return _buildSectionCard(
      title: 'Current Residence',
      subtitle: 'Do you currently live in Barcelona?',
      child: FormBuilderRadioGroup<String>(
        name: 'livesInBarcelona',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _livesInBarcelonaOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildBuildingTypeField() {
    return _buildSectionCard(
      title: 'Housing Type',
      subtitle: 'What best describes the type of building that you live in?',
      child: FormBuilderRadioGroup<String>(
        name: 'buildingType',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _buildingTypeOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildHouseholdItemsField() {
    return _buildSectionCard(
      title: 'Household Items',
      subtitle: 'Does the household that you live in have any of the following? (mark all that apply)',
      child: FormBuilderCheckboxGroup<String>(
        name: 'householdItems',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _householdItemOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
      ),
    );
  }

  Widget _buildEducationField() {
    return _buildSectionCard(
      title: 'Education',
      subtitle: 'What is your highest level of completed education?',
      child: FormBuilderRadioGroup<String>(
        name: 'education',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _educationOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildClimateActivismField() {
    return _buildSectionCard(
      title: 'Climate Activism',
      subtitle: 'Are you involved in climate activism?',
      child: FormBuilderRadioGroup<String>(
        name: 'climateActivism',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _climateActivismOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildGeneralHealthField() {
    return _buildSectionCard(
      title: 'General Health',
      subtitle: 'How would you describe your general health?',
      child: FormBuilderRadioGroup<String>(
        name: 'generalHealth',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _generalHealthOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildSectionCard({required String title, String? subtitle, required Widget child}) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (subtitle != null) ...[
              SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
            SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary submit button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _submitSurvey,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              padding: EdgeInsets.symmetric(vertical: 16),
            ),
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    'Submit Survey',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ),
        SizedBox(height: 12),
        // Skip button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isSubmitting ? null : _showSkipDialog,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Colors.grey),
            ),
            child: Text(
              'Skip for Now - Enter App',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ),
        SizedBox(height: 8),
        // Informational text
        Text(
          'You can complete this survey later from the app menu.\nWe\'ll send gentle reminders to help you complete it.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            height: 1.3,
          ),
        ),
      ],
    );
  }

  void _showSkipDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Skip Initial Survey?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to skip the initial survey for now?'),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue, size: 16),
                      SizedBox(width: 6),
                      Text(
                        'What happens next:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• You can access the app immediately\n'
                    '• Find "Initial Survey" in the app menu\n'
                    '• We\'ll send periodic reminders\n'
                    '• Complete it when convenient for you',
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Go Back'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(false); // Return to previous screen indicating survey was skipped
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              'Skip & Enter App',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _submitSurvey() async {
    // Always save and allow submission - no validation required
    _formKey.currentState?.save();
    
    setState(() {
      _isSubmitting = true;
    });

    try {
      final formData = _formKey.currentState!.value;
      
      final surveyResponse = InitialSurveyResponse(
        age: formData['age'] != null ? int.tryParse(formData['age'].toString()) : null,
        ethnicity: List<String>.from(formData['ethnicity'] ?? []),
        gender: formData['gender'],
        sexuality: formData['sexuality'],
        birthPlace: formData['birthPlace'],
        livesInBarcelona: formData['livesInBarcelona'],
        suburb: formData['suburb'],
        buildingType: formData['buildingType'],
        householdItems: List<String>.from(formData['householdItems'] ?? []),
        education: formData['education'],
        climateActivism: formData['climateActivism'],
        generalHealth: formData['generalHealth'],
        // Add empty baseline activities for now - TODO: collect from form if needed
        activities: <String>[],
        researchSite: _researchSite,
        submittedAt: DateTime.now(),
      );

      // Save to local database
      await _saveSurveyResponse(surveyResponse);

      // Check if we're in app testing mode and show appropriate message
      final currentMode = await AppModeService.getCurrentMode();
      if (currentMode == AppMode.appTesting) {
        _showBetaTestingSuccessDialog();
      } else {
        _showSuccessDialog();
      }
    } catch (e) {
      _showErrorDialog(e.toString());
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _saveSurveyResponse(InitialSurveyResponse response) async {
    try {
      final db = SurveyDatabase();
      final surveyId = await db.insertInitialSurvey(response);
      print('Initial survey saved to local database with ID: $surveyId');
      
      // Mark initial survey as completed to prevent re-prompting
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('initial_survey_completed', true);
      print('Marked initial survey as completed');
      
      // SECURITY: Using encrypted survey service - no API tokens exposed
      // Trigger background sync when connectivity is available
      EncryptedSurveyService.syncPendingSurveys().catchError((e) {
        print('Background sync will retry later: $e');
      });
      
      print('✅ Survey saved locally. Encrypted background sync initiated.');
    } catch (e) {
      print('Error saving initial survey: $e');
      rethrow;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Survey Submitted!'),
        content: Text('Thank you for completing the initial survey. Your responses have been saved.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); // Go to main app and clear stack
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showBetaTestingSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('🧪 Beta Testing Mode'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your initial survey responses have been saved locally for testing purposes.',
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Beta Testing Info',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'If this had been research mode, your data would have been submitted to researchers. Since this is beta testing, no data was transmitted.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                '💙 Thank you for beta testing the Wellbeing Mapper!',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false); // Go to main app and clear stack
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('Got it!', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text('Failed to submit survey: $error'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildWellbeingSection() {
    return _buildSectionCard(
      title: 'Wellbeing Questions',
      subtitle: 'Over the past two weeks, how much of the time... (Scale: 0=Never, 5=All the time)',
      child: Column(
        children: [
          _buildRatingQuestion('cheerfulSpirits', 'Have you been in good spirits?', 0, 5),
          _buildRatingQuestion('calmRelaxed', 'Have you felt calm and relaxed?', 0, 5),
          _buildRatingQuestion('activeVigorous', 'Have you felt active and vigorous?', 0, 5),
          _buildRatingQuestion('wokeUpFresh', 'Did you wake up feeling fresh and rested?', 0, 5),
          _buildRatingQuestion('dailyLifeInteresting', 'Has your daily life been filled with things that interest you?', 0, 5),
        ],
      ),
    );
  }

  Widget _buildPersonalCharacteristicsSection() {
    return _buildSectionCard(
      title: 'Personal Characteristics',
      subtitle: 'Please rate how well each statement describes you (Scale: 1=Not at all, 5=Completely)',
      child: Column(
        children: [
          _buildRatingQuestion('cooperateWithPeople', 'I find it easy to cooperate with people', 1, 5),
          _buildRatingQuestion('improvingSkills', 'I am always improving my skills', 1, 5),
          _buildRatingQuestion('socialSituations', 'I feel comfortable in social situations', 1, 5),
          _buildRatingQuestion('familySupport', 'There is always someone in my family who can give me support', 1, 5),
          _buildRatingQuestion('familyKnowsMe', 'There is always someone in my family who really knows me', 1, 5),
          _buildRatingQuestion('accessToFood', 'I have access to the food I need', 1, 5),
          _buildRatingQuestion('peopleEnjoyTime', 'There are people with whom I enjoy spending time', 1, 5),
          _buildRatingQuestion('talkToFamily', 'I can talk about my problems with my family', 1, 5),
          _buildRatingQuestion('friendsSupport', 'My friends really try to help me', 1, 5),
          _buildRatingQuestion('belongInCommunity', 'I really feel like I belong in my community', 1, 5),
          _buildRatingQuestion('familyStandsByMe', 'My family really tries to stand by me', 1, 5),
          _buildRatingQuestion('friendsStandByMe', 'My friends really try to stand by me', 1, 5),
          _buildRatingQuestion('treatedFairly', 'I am treated fairly in my community', 1, 5),
          _buildRatingQuestion('opportunitiesResponsibility', 'I have opportunities to take responsibility', 1, 5),
          _buildRatingQuestion('secureWithFamily', 'I feel secure with my family', 1, 5),
          _buildRatingQuestion('opportunitiesAbilities', 'I have opportunities to show my abilities', 1, 5),
          _buildRatingQuestion('enjoyCulturalTraditions', 'I enjoy my community\'s cultural and traditional events', 1, 5),
        ],
      ),
    );
  }

  Widget _buildRatingQuestion(String name, String question, int min, int max) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(question, style: TextStyle(fontSize: 16)),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Text(
                  'Optional',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.orange[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 4),
          Text(
            'Move the slider to provide your rating (starts at default position)',
            style: TextStyle(fontSize: 11, color: Colors.blue[600], fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          _buildCustomSlider(name, min, max),
        ],
      ),
    );
  }

  Widget _buildCustomSlider(String name, int min, int max) {
    // Use a map to track slider states
    if (!_sliderValues.containsKey(name)) {
      _sliderValues[name] = null; // Start with no selection
    }

    return FormBuilderField<double>(
      name: name,
      builder: (FormFieldState<double?> field) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _sliderValues[name] == null ? Colors.red[300]! : Colors.grey[300]!,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(8),
                color: _sliderValues[name] == null ? Colors.red[50] : Colors.grey[50],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$min', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      Text(
                        _sliderValues[name] == null 
                          ? 'Not selected' 
                          : '${_sliderValues[name]!.round()}',
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold,
                          color: _sliderValues[name] == null ? Colors.red[600] : Colors.blue[600],
                        ),
                      ),
                      Text('$max', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                  SizedBox(height: 8),
                  Slider(
                    value: _sliderValues[name] ?? ((min + max) / 2).toDouble(),
                    min: min.toDouble(),
                    max: max.toDouble(),
                    divisions: max - min,
                    onChanged: (value) {
                      setState(() {
                        _sliderValues[name] = value;
                      });
                      field.didChange(value);
                    },
                    activeColor: _sliderValues[name] == null ? Colors.red[300] : Colors.blue,
                    inactiveColor: Colors.grey[300],
                  ),
                ],
              ),
            ),
            if (_sliderValues[name] == null)
              Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Please move the slider to select a rating',
                  style: TextStyle(fontSize: 11, color: Colors.red[600]),
                ),
              ),
          ],
        );
      },
    );
  }
}
