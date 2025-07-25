import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/survey_models.dart';
import '../models/consent_models.dart';
import '../db/survey_database.dart';

class InitialSurveyScreen extends StatefulWidget {
  @override
  _InitialSurveyScreenState createState() => _InitialSurveyScreenState();
}

class _InitialSurveyScreenState extends State<InitialSurveyScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;
  String _researchSite = 'barcelona'; // Default to Barcelona

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
          _researchSite = settings.researchSite ?? 'barcelona';
        });
      }
    } catch (e) {
      // Default to Barcelona if any error
      setState(() {
        _researchSite = 'barcelona';
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
              SizedBox(height: 32),
              _buildSubmitButton(),
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
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.integer(errorText: 'Please enter a valid age'),
          FormBuilderValidators.min(13, errorText: 'You must be at least 13 years old'),
          FormBuilderValidators.max(120, errorText: 'Please enter a valid age'),
        ]),
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
        validator: FormBuilderValidators.required(errorText: 'Please enter your suburb or community'),
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
        validator: FormBuilderValidators.compose([
          FormBuilderValidators.required(errorText: 'Please select at least one option'),
        ]),
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
        validator: FormBuilderValidators.required(errorText: 'Please select an option'),
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
        validator: FormBuilderValidators.required(errorText: 'Please select an option'),
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
        validator: FormBuilderValidators.required(errorText: 'Please select an option'),
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
        validator: FormBuilderValidators.required(errorText: 'Please select an option'),
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
        validator: FormBuilderValidators.required(errorText: 'Please select an option'),
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
        validator: FormBuilderValidators.required(errorText: 'Please select an option'),
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
        validator: FormBuilderValidators.required(errorText: 'Please select an option'),
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
        validator: FormBuilderValidators.required(errorText: 'Please select an option'),
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

  Widget _buildSubmitButton() {
    return SizedBox(
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
    );
  }

  void _submitSurvey() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
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
          researchSite: _researchSite,
          submittedAt: DateTime.now(),
        );

        // TODO: Save to local database and sync when online
        await _saveSurveyResponse(surveyResponse);

        _showSuccessDialog();
      } catch (e) {
        _showErrorDialog(e.toString());
      } finally {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _saveSurveyResponse(InitialSurveyResponse response) async {
    try {
      final db = SurveyDatabase();
      await db.insertInitialSurvey(response);
      print('Initial survey saved to local database');
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
              Navigator.of(context).pop(); // Go back to previous screen
            },
            child: Text('OK'),
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
}
