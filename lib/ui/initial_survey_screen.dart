import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/survey_models.dart';
import '../models/consent_models.dart';
import '../models/app_mode.dart';
import '../services/app_mode_service.dart';
import '../services/research_server_service.dart';
import '../db/survey_database.dart';

class InitialSurveyScreen extends StatefulWidget {
  @override
  _InitialSurveyScreenState createState() => _InitialSurveyScreenState();
}

class _InitialSurveyScreenState extends State<InitialSurveyScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;
  String _researchSite = 'wellbeing_mapper'; // Default to Southern Europe
  // Photo functionality removed - _selectedImages not needed
  
  // Track slider values for better UX - starts with no selection
  final Map<String, double?> _sliderValues = {};
  // Photo functionality removed - ImagePicker not needed

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
          _researchSite = settings.researchSite ?? 'wellbeing_mapper';
        });
      }
    } catch (e) {
      // Default to Southern Europe if any error
      setState(() {
        _researchSite = 'wellbeing_mapper';
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

  // site-specific options (Italy / "wellbeing_mapper" study site).
  // Values are the canonical English strings stored with the response; Italian
  // display labels are provided via [_optLabel]. Content matches the canonical
  // Italy survey (Assets/survey_text/5_annex_survey_questions_Italy.docx).
  final List<String> _siteEthnicityOptions = [
    'South Asian',
    'East or Southeast Asian',
    'White',
    'Latin American',
    'North African or Arab',
    'Black / Sub-Saharan African origin',
    'Roma, Sinti or Caminanti',
    'Other',
    'Prefer not to say'
  ];

  final List<String> _siteBirthPlaceOptions = [
    'Italy',
    'Other country',
    'Prefer not to say'
  ];

  final List<String> _siteBuildingTypeOptions = [
    'It is a detached single-family home',
    'It is a semi-detached or terraced single-family home',
    'It is a two housing-unit building',
    'The housing unit is in a building with 3 or more units but less than 10',
    'The housing unit is in a building with 10 or more housing units',
    'The housing unit is a building that is used for other uses (even though it includes one or more housing units, for example, housing for porters, guards or security staff of the building)',
    'Other'
  ];

  final List<String> _siteEducationOptions = [
    'Less than high school',
    'High school',
    'Bachelor\'s degree',
    'Graduate or professional degree',
    'Prefer not to say'
  ];

  // Italy "lives in" question options (shown for the wellbeing_mapper site).
  final List<String> _livesInItalyOptions = [
    'Yes',
    'No',
    'Don\'t know / Prefer not to say'
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
  List<String> get _ethnicityOptions => _researchSite == 'wellbeing_mapper' 
      ? _siteEthnicityOptions 
      : _barcelonaEthnicityOptions;
      
  List<String> get _birthPlaceOptions => _researchSite == 'wellbeing_mapper' 
      ? _siteBirthPlaceOptions 
      : _barcelonaBirthPlaceOptions;
      
  List<String> get _buildingTypeOptions => _researchSite == 'wellbeing_mapper' 
      ? _siteBuildingTypeOptions 
      : _barcelonaBuildingTypeOptions;
      
  List<String> get _educationOptions => _researchSite == 'wellbeing_mapper' 
      ? _siteEducationOptions 
      : _barcelonaEducationOptions;

  // ---------------------------------------------------------------------------
  // Localization helpers
  //
  // The survey is shown in Italian when the app locale is Italian, otherwise in
  // English. Answer *values* stored with the response stay in canonical English
  // (see [_optLabel]) so research data remains language-stable regardless of the
  // language the participant sees.
  // ---------------------------------------------------------------------------

  bool get _isItalian =>
      Localizations.localeOf(context).languageCode == 'it';

  /// Pick the English or Italian variant of a UI string based on app locale.
  String _t(String en, String it) => _isItalian ? it : en;

  /// Italian display labels for canonical English answer values.
  static const Map<String, String> _itOptionLabels = {
    // Ethnicity
    'South Asian': 'Sud-asiatico/a',
    'East or Southeast Asian': 'Est o Sud-est asiatico/a',
    'White': 'Bianco/a',
    'Latin American': 'Latinoamericano/a',
    'North African or Arab': 'Nordafricano/a o arabo/a',
    'Black / Sub-Saharan African origin': 'Nero/a / di origine subsahariana',
    'Roma, Sinti or Caminanti': 'Rom, Sinti o Caminanti',
    'Other': 'Altro',
    'Prefer not to say': 'Preferisco non rispondere',
    // Gender
    'Male': 'Uomo',
    'Female': 'Donna',
    'Transmale': 'Transmaschio',
    'Transfemale': 'Transfemmina',
    'Non-binary': 'Non binario',
    // Sexual orientation
    'Heterosexual/straight': 'Eterosessuale',
    'Lesbian': 'Lesbica',
    'Gay': 'Gay',
    'Bisexual': 'Bisessuale',
    'Queer': 'Queer',
    // Place of birth
    'Italy': 'Italia',
    'Other country': 'Altro paese',
    // Lives in Italy
    'Yes': 'Sì',
    'No': 'No',
    "Don't know / Prefer not to say": 'Non so / Preferisco non rispondere',
    // Building type
    'It is a detached single-family home':
        'È una casa unifamiliare isolata',
    'It is a semi-detached or terraced single-family home':
        'È una casa unifamiliare bifamiliare o a schiera',
    'It is a two housing-unit building':
        'È un edificio con due unità abitative',
    'The housing unit is in a building with 3 or more units but less than 10':
        "L'abitazione si trova in un edificio con 3 o più unità ma meno di 10",
    'The housing unit is in a building with 10 or more housing units':
        "L'abitazione si trova in un edificio con 10 o più unità abitative",
    'The housing unit is a building that is used for other uses (even though it includes one or more housing units, for example, housing for porters, guards or security staff of the building)':
        "L'abitazione è in un edificio destinato ad altri usi (anche se comprende una o più unità abitative, ad esempio alloggi per portieri, custodi o personale di sicurezza dell'edificio)",
    // Household items
    'radio': 'radio',
    'television': 'televisione',
    'refrigerator': 'frigorifero',
    'microwave': 'forno a microonde',
    'internet access (e.g., fibre)': 'accesso a internet (es. fibra)',
    'computer': 'computer',
    'cellular smartphone': 'smartphone',
    'car': 'automobile',
    'electric cooling devices (e.g. fan or air-conditioning)':
        'dispositivi di raffrescamento elettrici (es. ventilatore o aria condizionata)',
    // Education
    'Less than high school': 'Meno del diploma di scuola superiore',
    'High school': 'Diploma di scuola superiore',
    "Bachelor's degree": 'Laurea triennale',
    'Graduate or professional degree': 'Laurea magistrale o titolo professionale',
    // Climate activism
    'all the time': 'sempre',
    'often': 'spesso',
    'sometimes': 'a volte',
    'occasionally': 'occasionalmente',
    'never': 'mai',
    // General health
    'Excellent': 'Eccellente',
    'Very good': 'Molto buona',
    'Good': 'Buona',
    'Fair': 'Discreta',
    'Poor': 'Scarsa',
  };

  /// Localized display label for an answer option, keeping the stored value in
  /// canonical English.
  String _optLabel(String value) =>
      _isItalian ? (_itOptionLabels[value] ?? value) : value;

  /// Build localized [FormBuilderFieldOption]s whose values stay canonical
  /// English while the visible label follows the app locale.
  List<FormBuilderFieldOption<String>> _opts(List<String> values) =>
      values
          .map((v) => FormBuilderFieldOption<String>(
                value: v,
                child: Text(_optLabel(v)),
              ))
          .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _t('Initial Survey', 'Questionario iniziale'),
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
              // Note: the free-text suburb/location field is intentionally not
              // shown for the Italy (wellbeing_mapper) site, per the canonical
              // Italy survey.
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
              if (_researchSite == 'wellbeing_mapper') ...[
                _buildLivesInItalyField(),
                SizedBox(height: 24),
              ],
              _buildBuildingTypeField(),
              SizedBox(height: 24),
              _buildHouseholdItemsField(),
              SizedBox(height: 24),
              _buildEducationField(),
              SizedBox(height: 24),
              if (_researchSite == 'wellbeing_mapper') ...[
                _buildGeneralHealthField(),
                SizedBox(height: 24),
              ],
              _buildClimateActivismField(),
              SizedBox(height: 24),
              // Add wellbeing questions (from biweekly survey)
              _buildWellbeingSection(),
              SizedBox(height: 24),
              _buildPersonalCharacteristicsSection(),
              SizedBox(height: 24),
              _buildDigitalDiarySection(),
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
              _t('Welcome to the Wellbeing Mapping Study!',
                  'Benvenuto/a allo studio Wellbeing Mapper!'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _t(
                  'This initial survey will help us understand your background. All responses are confidential and will be used only for research purposes.',
                  'Questo questionario iniziale ci aiuterà a conoscere il tuo profilo. Tutte le risposte sono riservate e saranno utilizzate esclusivamente per scopi di ricerca.'),
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAgeField() {
    return _buildSectionCard(
      title: _t('Age', 'Età'),
      child: FormBuilderTextField(
        name: 'age',
        decoration: InputDecoration(
          labelText: _t('How old are you?', 'Quanti anni hai?'),
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

  Widget _buildEthnicityField() {
    return _buildSectionCard(
      title: _t('Ethnicity', 'Origine etnica'),
      subtitle: _t('Select all that apply', 'Seleziona tutte le opzioni pertinenti'),
      child: FormBuilderCheckboxGroup<String>(
        name: 'ethnicity',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_ethnicityOptions),
        orientation: OptionsOrientation.vertical,
        // validator: FormBuilderValidators.compose([ // Removed - now optional
        //   FormBuilderValidators.required(errorText: 'Please select at least one option'),
        // ]),
      ),
    );
  }

  Widget _buildGenderField() {
    return _buildSectionCard(
      title: _t('Gender Identity', 'Identità di genere'),
      child: FormBuilderRadioGroup<String>(
        name: 'gender',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_genderOptions),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildSexualityField() {
    return _buildSectionCard(
      title: _t('Sexual Orientation', 'Orientamento sessuale'),
      child: FormBuilderRadioGroup<String>(
        name: 'sexuality',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_sexualityOptions),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildBirthPlaceField() {
    return _buildSectionCard(
      title: _t('Place of Birth', 'Luogo di nascita'),
      child: FormBuilderRadioGroup<String>(
        name: 'birthPlace',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_birthPlaceOptions),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildLivesInBarcelonaField() {
    return _buildSectionCard(
      title: _t('Current Residence', 'Residenza attuale'),
      subtitle: _t('Do you currently live in Barcelona?', 'Vivi attualmente a Barcellona?'),
      child: FormBuilderRadioGroup<String>(
        name: 'livesInBarcelona',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_livesInBarcelonaOptions),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  /// "Do you currently live in Italy?" for the wellbeing_mapper (Italy) site.
  ///
  /// Reuses the existing `livesInBarcelona` response field to store the answer
  /// so no data-model/schema change is required; for Italy-site submissions this
  /// field carries the "lives in study area" answer.
  Widget _buildLivesInItalyField() {
    return _buildSectionCard(
      title: _t('Current Residence', 'Residenza attuale'),
      subtitle: _t('Do you currently live in Italy?', 'Vivi attualmente in Italia?'),
      child: FormBuilderRadioGroup<String>(
        name: 'livesInBarcelona',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_livesInItalyOptions),
      ),
    );
  }

  Widget _buildBuildingTypeField() {
    return _buildSectionCard(
      title: _t('Housing Type', 'Tipo di abitazione'),
      subtitle: _t('What best describes the type of building that you live in?',
          'Quale descrizione corrisponde meglio al tipo di edificio in cui vivi?'),
      child: FormBuilderRadioGroup<String>(
        name: 'buildingType',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_buildingTypeOptions),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildHouseholdItemsField() {
    return _buildSectionCard(
      title: _t('Household Items', 'Beni in casa'),
      subtitle: _t('Does the household that you live in have any of the following? (mark all that apply)',
          'La casa in cui vivi dispone di uno o più dei seguenti beni? (seleziona tutte le opzioni pertinenti)'),
      child: FormBuilderCheckboxGroup<String>(
        name: 'householdItems',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_householdItemOptions),
      ),
    );
  }

  Widget _buildEducationField() {
    return _buildSectionCard(
      title: _t('Education', 'Istruzione'),
      subtitle: _t('What is your highest level of completed education?',
          'Qual è il titolo di studio più alto che hai conseguito?'),
      child: FormBuilderRadioGroup<String>(
        name: 'education',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_educationOptions),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildClimateActivismField() {
    return _buildSectionCard(
      title: _t('Climate Activism', 'Attivismo climatico'),
      subtitle: _t('Are you involved in climate activism?',
          'Sei coinvolto/a in attività di attivismo climatico?'),
      child: FormBuilderRadioGroup<String>(
        name: 'climateActivism',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_climateActivismOptions),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildGeneralHealthField() {
    return _buildSectionCard(
      title: _t('General Health', 'Salute generale'),
      subtitle: _t('How would you describe your general health?',
          'Come descriveresti la tua salute generale?'),
      child: FormBuilderRadioGroup<String>(
        name: 'generalHealth',
        decoration: InputDecoration(
          border: InputBorder.none,
        ),
        options: _opts(_generalHealthOptions),
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
                    _t('Submit Survey', 'Invia questionario'),
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
              _t('Skip for Now - Enter App', 'Salta per ora - Entra nell\'app'),
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
            ),
          ),
        ),
        SizedBox(height: 8),
        // Informational text
        Text(
          _t(
              'You can complete this survey later from the app menu.\nWe\'ll send gentle reminders to help you complete it.',
              'Puoi completare questo questionario in seguito dal menu dell\'app.\nTi invieremo promemoria delicati per aiutarti a completarlo.'),
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
        title: Text(_t('Skip Initial Survey?', 'Saltare il questionario iniziale?')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Are you sure you want to skip the initial survey for now?',
                'Sei sicuro/a di voler saltare il questionario iniziale per ora?')),
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
                        _t('What happens next:', 'Cosa succede dopo:'),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    _t(
                        '• You can access the app immediately\n'
                        '• Find "Initial Survey" in the app menu\n'
                        '• We\'ll send periodic reminders\n'
                        '• Complete it when convenient for you',
                        '• Puoi accedere subito all\'app\n'
                        '• Trovi "Questionario iniziale" nel menu dell\'app\n'
                        '• Ti invieremo promemoria periodici\n'
                        '• Completalo quando ti è comodo'),
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
            child: Text(_t('Go Back', 'Indietro')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(false); // Return to previous screen indicating survey was skipped
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text(
              _t('Skip & Enter App', 'Salta ed entra nell\'app'),
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
        livingArrangement: null, // Not collected in initial survey
        relationshipStatus: null, // Not collected in initial survey
        // Wellbeing questions (0-5 scale)
        cheerfulSpirits: formData['cheerfulSpirits']?.round(),
        calmRelaxed: formData['calmRelaxed']?.round(),
        activeVigorous: formData['activeVigorous']?.round(),
        wokeUpFresh: formData['wokeUpFresh']?.round(),
        dailyLifeInteresting: formData['dailyLifeInteresting']?.round(),
        // Personal characteristics (1-5 scale)
        cooperateWithPeople: formData['cooperateWithPeople']?.round(),
        improvingSkills: formData['improvingSkills']?.round(),
        socialSituations: formData['socialSituations']?.round(),
        familySupport: formData['familySupport']?.round(),
        familyKnowsMe: formData['familyKnowsMe']?.round(),
        accessToFood: formData['accessToFood']?.round(),
        peopleEnjoyTime: formData['peopleEnjoyTime']?.round(),
        talkToFamily: formData['talkToFamily']?.round(),
        friendsSupport: formData['friendsSupport']?.round(),
        belongInCommunity: formData['belongInCommunity']?.round(),
        familyStandsByMe: formData['familyStandsByMe']?.round(),
        friendsStandByMe: formData['friendsStandByMe']?.round(),
        treatedFairly: formData['treatedFairly']?.round(),
        opportunitiesResponsibility: formData['opportunitiesResponsibility']?.round(),
        secureWithFamily: formData['secureWithFamily']?.round(),
        opportunitiesAbilities: formData['opportunitiesAbilities']?.round(),
        enjoyCulturalTraditions: formData['enjoyCulturalTraditions']?.round(),
        // Digital diary
        environmentalChallenges: formData['environmentalChallenges'],
        challengesStressLevel: formData['challengesStressLevel'] != null ? formData['challengesStressLevel'].round().toString() : null,
        copingHelp: formData['copingHelp'],
        // TODO: MULTIMEDIA ENCRYPTION - Images are stored locally, encryption to be implemented
        // voiceNoteUrls: null, // Voice notes not implemented yet
        imageUrls: null, // Photo functionality removed
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
      debugPrint('Initial survey saved to local database with ID: $surveyId');
      
      // Mark initial survey as completed to prevent re-prompting
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('initial_survey_completed', true);
      debugPrint('Marked initial survey as completed');
      
      // SECURITY: Using encrypted survey service - no API tokens exposed
      // Trigger background sync when connectivity is available
      ResearchServerService.syncPendingSurveys().catchError((e) {
        debugPrint('Background sync will retry later: $e');
      });
      
      debugPrint('✅ Survey saved locally. Encrypted background sync initiated.');
    } catch (e) {
      debugPrint('Error saving initial survey: $e');
      rethrow;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_t('Survey Submitted!', 'Questionario inviato!')),
        content: Text(_t(
            'Thank you for completing the initial survey. Your responses have been saved.',
            'Grazie per aver completato il questionario iniziale. Le tue risposte sono state salvate.')),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false); // Go to main app and clear stack
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
        title: Text(_t('🧪 Beta Testing Mode', '🧪 Modalità beta testing')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _t('Your initial survey responses have been saved locally for testing purposes.',
                    'Le tue risposte al questionario iniziale sono state salvate localmente a scopo di test.'),
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
                      _t('Beta Testing Info', 'Informazioni sul beta testing'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _t(
                          'If this had been research mode, your data would have been submitted to researchers. Since this is beta testing, no data was transmitted.',
                          'Se questa fosse stata la modalità di ricerca, i tuoi dati sarebbero stati inviati ai ricercatori. Trattandosi di beta testing, nessun dato è stato trasmesso.'),
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                _t('💙 Thank you for beta testing the Wellbeing Mapper!',
                    '💙 Grazie per aver partecipato al beta testing di Wellbeing Mapper!'),
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
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false); // Go to main app and clear stack
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
        title: Text(_t('Error', 'Errore')),
        content: Text(_t('Failed to submit survey: ', 'Invio del questionario non riuscito: ') + error),
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
      title: _t('Wellbeing Questions', 'Domande sul benessere'),
      subtitle: _t(
          'Over the past two weeks, how much of the time... (Scale: 0=Never, 5=All the time)',
          'Nelle ultime due settimane, per quanto tempo... (Scala: 0=Mai, 5=Sempre)'),
      child: Column(
        children: [
          _buildRatingQuestion('cheerfulSpirits', _t('Have you been in good spirits?', 'Ti sei sentito/a di buon umore?'), 0, 5),
          _buildRatingQuestion('calmRelaxed', _t('Have you felt calm and relaxed?', 'Ti sei sentito/a calmo/a e rilassato/a?'), 0, 5),
          _buildRatingQuestion('activeVigorous', _t('Have you felt active and vigorous?', 'Ti sei sentito/a attivo/a e pieno/a di energia?'), 0, 5),
          _buildRatingQuestion('wokeUpFresh', _t('Did you wake up feeling fresh and rested?', 'Ti sei svegliato/a fresco/a e riposato/a?'), 0, 5),
          _buildRatingQuestion('dailyLifeInteresting', _t('Has your daily life been filled with things that interest you?', 'La tua vita quotidiana è stata ricca di cose che ti interessano?'), 0, 5),
        ],
      ),
    );
  }

  Widget _buildPersonalCharacteristicsSection() {
    return _buildSectionCard(
      title: _t('Personal Characteristics', 'Caratteristiche personali'),
      subtitle: _t(
          'Please rate how well each statement describes you (Scale: 1=Not at all, 5=Completely)',
          'Indica quanto ciascuna affermazione ti descrive (Scala: 1=Per niente, 5=Completamente)'),
      child: Column(
        children: [
          _buildRatingQuestion('cooperateWithPeople', _t('I find it easy to cooperate with people', 'Trovo facile collaborare con le persone'), 1, 5),
          _buildRatingQuestion('improvingSkills', _t('I am always improving my skills', 'Miglioro costantemente le mie competenze'), 1, 5),
          _buildRatingQuestion('socialSituations', _t('I feel comfortable in social situations', 'Mi sento a mio agio nelle situazioni sociali'), 1, 5),
          _buildRatingQuestion('familySupport', _t('There is always someone in my family who can give me support', 'C\'è sempre qualcuno nella mia famiglia che può sostenermi'), 1, 5),
          _buildRatingQuestion('familyKnowsMe', _t('There is always someone in my family who really knows me', 'C\'è sempre qualcuno nella mia famiglia che mi conosce davvero'), 1, 5),
          _buildRatingQuestion('accessToFood', _t('I have access to the food I need', 'Ho accesso al cibo di cui ho bisogno'), 1, 5),
          _buildRatingQuestion('peopleEnjoyTime', _t('There are people with whom I enjoy spending time', 'Ci sono persone con cui mi piace passare il tempo'), 1, 5),
          _buildRatingQuestion('talkToFamily', _t('I can talk about my problems with my family', 'Posso parlare dei miei problemi con la mia famiglia'), 1, 5),
          _buildRatingQuestion('friendsSupport', _t('My friends really try to help me', 'I miei amici cercano davvero di aiutarmi'), 1, 5),
          _buildRatingQuestion('belongInCommunity', _t('I really feel like I belong in my community', 'Sento davvero di appartenere alla mia comunità'), 1, 5),
          _buildRatingQuestion('familyStandsByMe', _t('My family really tries to stand by me', 'La mia famiglia cerca davvero di starmi vicino'), 1, 5),
          _buildRatingQuestion('friendsStandByMe', _t('My friends really try to stand by me', 'I miei amici cercano davvero di starmi vicino'), 1, 5),
          _buildRatingQuestion('treatedFairly', _t('I am treated fairly in my community', 'Sono trattato/a in modo equo nella mia comunità'), 1, 5),
          _buildRatingQuestion('opportunitiesResponsibility', _t('I have opportunities to take responsibility', 'Ho opportunità di assumermi delle responsabilità'), 1, 5),
          _buildRatingQuestion('secureWithFamily', _t('I feel secure with my family', 'Mi sento al sicuro con la mia famiglia'), 1, 5),
          _buildRatingQuestion('opportunitiesAbilities', _t('I have opportunities to show my abilities', 'Ho opportunità di mostrare le mie capacità'), 1, 5),
          _buildRatingQuestion('enjoyCulturalTraditions', _t('I enjoy my community\'s cultural and traditional events', 'Mi piacciono gli eventi culturali e tradizionali della mia comunità'), 1, 5),
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
                  _t('Optional', 'Facoltativo'),
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
            _t('Move the slider to provide your rating (starts at default position)',
                'Sposta il cursore per indicare la tua valutazione (parte dalla posizione predefinita)'),
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
                          ? _t('Not selected', 'Non selezionato')
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
                  _t('Please move the slider to select a rating',
                      'Sposta il cursore per selezionare una valutazione'),
                  style: TextStyle(fontSize: 11, color: Colors.red[600]),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Build the digital diary section for baseline environmental challenges data
  Widget _buildDigitalDiarySection() {
    return _buildSectionCard(
      title: _t('Digital Diary', 'Diario digitale'),
      subtitle: _t('Tell us about your recent environmental experiences',
          'Raccontaci le tue recenti esperienze ambientali'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // First prompt - environmental challenges
          Text(
            _t(
                'What environmental challenges have you experienced recently? Please share as much detail as you can. Feel free to upload 1 image, along with an explanation of what it means.',
                'Quali sfide ambientali hai affrontato di recente? Condividi più dettagli possibile. Se vuoi, puoi caricare 1 immagine insieme a una spiegazione del suo significato.'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          FormBuilderTextField(
            name: 'environmentalChallenges',
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: _t('Please describe any environmental challenges...',
                  'Descrivi eventuali sfide ambientali...'),
            ),
            maxLines: 3,
            minLines: 2,
          ),
          
          SizedBox(height: 20),
          
          // Second prompt - stress level as slider
          _buildRatingQuestion('challengesStressLevel', _t('How stressful were these environmental challenges for you?', 'Quanto sono state stressanti per te queste sfide ambientali?'), 1, 5),
          
          SizedBox(height: 20),
          
          // Third prompt - coping help
          Text(
            _t('Who or what helped you to manage/cope with these environmental challenges?',
                'Chi o cosa ti ha aiutato a gestire/affrontare queste sfide ambientali?'),
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          SizedBox(height: 8),
          FormBuilderTextField(
            name: 'copingHelp',
            decoration: InputDecoration(
              border: OutlineInputBorder(),
              hintText: _t('Please describe what helped you cope...',
                  'Descrivi cosa ti ha aiutato ad affrontarle...'),
            ),
            maxLines: 3,
            minLines: 2,
          ),
        ],
      ),
    );
  }

  /// Build the image upload section for the digital diary
  // Photo functionality removed for production reliability
}