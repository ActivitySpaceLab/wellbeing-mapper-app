import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/consent_models.dart';
import '../db/survey_database.dart';

class ConsentFormScreen extends StatefulWidget {
  final String participantCode;
  final String researchSite; // 'barcelona' or 'gauteng'

  ConsentFormScreen({required this.participantCode, required this.researchSite});

  @override
  _ConsentFormScreenState createState() => _ConsentFormScreenState();
}

class _ConsentFormScreenState extends State<ConsentFormScreen> {
  final _scrollController = ScrollController();
  bool _hasReadInformation = false;
  bool _understands = false;
  bool _fulfillsCriteria = false;
  bool _voluntaryParticipation = false;
  bool _generalConsent = false;
  bool _limeSurveyConsent = false;
  bool _raceEthnicityConsent = false;
  bool _healthConsent = false;
  bool _sexualOrientationConsent = false;
  bool _locationConsent = false;
  bool _dataTransferConsent = false;
  bool _isSubmitting = false;
  bool _showInformationSheet = true;

  // Site-specific content getters
  String get _siteTitle {
    if (widget.researchSite == 'gauteng') {
      return 'Mental wellbeing in climate and environmental context (Case Study 4 of the PLANET4HEALTH project) – Gauteng Study Site';
    }
    return 'Mental wellbeing in climate and environmental context (Case Study 4 of the PLANET4HEALTH project) – Barcelona Study Site';
  }

  String get _inclusionCriteria {
    if (widget.researchSite == 'gauteng') {
      return 'To participate in this study you must be at least 18 years old and living in the Gauteng Province.';
    }
    return 'To participate in this study you must be at least 18 years old and living in the Barcelona Metropolitan Area.';
  }

  String get _ethicsContact {
    if (widget.researchSite == 'gauteng') {
      return 'If you have doubts, complaints, or questions about this study or about your rights as a research participant, you may contact the University of Pretoria\'s Faculty of Health Sciences Research Ethics Committee or the South African Medical Research Council\'s Ethics Committee.';
    }
    return 'If you have doubts, complaints, or questions about this study or about your rights as a research participant, you may contact UPF\'s Institutional Committee for the Ethical Review of Projects (CIREP) by phone (+34 93 542 21 86) or by email (secretaria.cirep@upf.edu).';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_showInformationSheet ? 'Information Sheet' : 'Consent Form'),
        backgroundColor: Colors.blue,
      ),
      body: _showInformationSheet ? _buildInformationSheet() : _buildConsentForm(),
    );
  }

  Widget _buildInformationSheet() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoSection('Study Title', _siteTitle),
          _buildInfoSection('Institution', 
            'Universitat Pompeu Fabra, University of Pretoria and South African Medical Research Council'
          ),
          _buildInfoSection('Principal Investigators', 
            '• John Palmer (john.palmer@upf.edu)\n• Linda Theron (linda.theron@up.ac.za)\n• Caradee Wright (Caradee.Wright@mrc.ac.za)'
          ),
          _buildInfoSection('Ethics Committee', _ethicsContact),
          _buildInfoSection('Funding', 
            'This project is funded by the European Union as part of the PLANET4HEALTH Project (https://planet4health.eu).'
          ),
          _buildInfoSection('Study Objectives', 
            'The goal of this study is to learn more about how climate change and other changes in the environment affect people\'s mental wellbeing.'
          ),
          _buildInfoSection('What You\'ll Do', 
            'This study involves a mobile phone application called Wellbeing Mapper, which keeps track of where you spend time, and lets you share this information, if you chose to, with the researchers carrying out this study. It also involves a series of surveys.\n\n'
            'You can participate by installing Wellbeing Mapper on your phone and letting it track your locations for up to six months. You will then be given surveys every two weeks, in which you will be asked a series of questions about yourself and about your mental wellbeing.\n\n'
            'The survey will include questions about:\n• Race/ethnicity\n• Health\n• Sexual orientation\n• Location and mobility'
          ),
          _buildInfoSection('Who Can Participate', _inclusionCriteria),
          _buildInfoSection('Risks and Benefits', 
            'It is not expected that anything you will be asked to do while participating in this study will pose a risk to your health. However, it is very important that you not interact with your mobile phone while driving or engaged in any activity that requires your attention.\n\n'
            'Participation involves some risk to your privacy because you will be asked to share information about where you spend time. However, this information will be kept confidential by the research team using encryption and standard data protection techniques.\n\n'
            'We cannot and do not guarantee that you will receive any benefits from this study.'
          ),
          _buildInfoSection('Data Protection', 
            'In order to protect your privacy, we will not identify your data with your name, but rather with a code that will only be known to the research team members. Your location data will be protected using end-to-end encryption.\n\n'
            'In the event of data publication, only anonymous data will be published. Anonymized data may be hosted or published in a public repository.'
          ),
          _buildGDPRSection(),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _showInformationSheet = false;
                });
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
              child: Text('Continue to Consent Form', style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildConsentForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informed Consent Form',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Participant Code: ${widget.participantCode}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          
          _buildConsentSection('I HEREBY CONFIRM that:', [
            _buildCheckbox(_hasReadInformation, (value) => setState(() => _hasReadInformation = value!),
              'I have read the information sheet regarding the research project'),
            _buildCheckbox(_understands, (value) => setState(() => _understands = value!),
              'I have been able to formulate questions and I have received enough information on the project'),
            _buildCheckbox(_fulfillsCriteria, (value) => setState(() => _fulfillsCriteria = value!),
              'I fulfill the inclusion criteria, and I am at least 18 years old'),
          ]),

          _buildConsentSection('I UNDERSTAND that:', [
            _buildCheckbox(_voluntaryParticipation, (value) => setState(() => _voluntaryParticipation = value!),
              'My participation is voluntary and that I can withdraw from or opt out of the study at any time without any need to justify my decision'),
          ]),

          _buildConsentSection('I GIVE MY CONSENT:', [
            _buildCheckbox(_generalConsent, (value) => setState(() => _generalConsent = value!),
              'To participate in this study'),
            _buildCheckbox(_limeSurveyConsent, (value) => setState(() => _limeSurveyConsent = value!),
              'For my personal data to be processed by LimeSurvey GmbH, Survey Services & Consulting, a German company, under their terms and conditions',
              isRequired: false),
            _buildCheckbox(_raceEthnicityConsent, (value) => setState(() => _raceEthnicityConsent = value!),
              'To being asked about my race/ethnicity'),
            _buildCheckbox(_healthConsent, (value) => setState(() => _healthConsent = value!),
              'To being asked about my health condition'),
            _buildCheckbox(_sexualOrientationConsent, (value) => setState(() => _sexualOrientationConsent = value!),
              'To being asked about my sexual orientation'),
            _buildCheckbox(_locationConsent, (value) => setState(() => _locationConsent = value!),
              'To being asked about my location and mobility'),
            _buildCheckbox(_dataTransferConsent, (value) => setState(() => _dataTransferConsent = value!),
              'To transferring my personal data to countries outside the European Economic Area'),
          ]),

          SizedBox(height: 24),
          _buildGDPRSection(),
          SizedBox(height: 32),
          _buildSubmitButton(),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(content, style: TextStyle(fontSize: 15, height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildConsentSection(String title, List<Widget> items) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            ...items,
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox(bool value, ValueChanged<bool?> onChanged, String text, {bool isRequired = true}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(value: value, onChanged: onChanged),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Text(
                text + (isRequired ? ' *' : ''),
                style: TextStyle(fontSize: 15, height: 1.3),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGDPRSection() {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GDPR Information',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 14, color: Colors.black, height: 1.4),
                children: [
                  TextSpan(text: 'Data controller: '),
                  TextSpan(text: 'Universitat Pompeu Fabra. C. de la Mercè, 12. 08002 Barcelona. Tel. +34 93 542 20 00. ', style: TextStyle(fontWeight: FontWeight.w500)),
                  TextSpan(text: 'Contact Data Protection Officer: '),
                  TextSpan(
                    text: 'dpd@upf.edu',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()..onTap = () => _launchEmail('dpd@upf.edu'),
                  ),
                  TextSpan(text: '\n\n'),
                  TextSpan(text: 'Your rights: '),
                  TextSpan(text: 'You can request the deletion of your data and you may object to their processing. For deletion, you must provide the participant UUID found in the app. '),
                  TextSpan(text: 'Visit '),
                  TextSpan(
                    text: 'www.upf.edu/web/proteccio-dades/drets',
                    style: TextStyle(color: Colors.blue, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()..onTap = () => _launchUrl('https://www.upf.edu/web/proteccio-dades/drets'),
                  ),
                  TextSpan(text: ' for more information.'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    final bool allRequired = _hasReadInformation && _understands && _fulfillsCriteria && 
                            _voluntaryParticipation && _generalConsent && _raceEthnicityConsent && 
                            _healthConsent && _sexualOrientationConsent && _locationConsent && 
                            _dataTransferConsent;

    return Column(
      children: [
        if (!allRequired)
          Container(
            padding: EdgeInsets.all(12),
            margin: EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: Colors.orange),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Please check all required consent items (marked with *) to continue.',
                    style: TextStyle(color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: (allRequired && !_isSubmitting) ? _submitConsent : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isSubmitting
                ? CircularProgressIndicator(color: Colors.white)
                : Text('Submit Consent & Continue', style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
        SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('Cancel'),
        ),
      ],
    );
  }

  void _submitConsent() async {
    setState(() {
      _isSubmitting = true;
    });

    try {
      // Generate UUID for participant
      final uuid = Uuid().v4();
      
      // Create consent response
      final consent = ConsentResponse(
        participantUuid: uuid,
        informedConsent: _hasReadInformation && _understands && _fulfillsCriteria,
        dataProcessing: _generalConsent,
        locationData: _locationConsent,
        surveyData: _generalConsent,
        dataRetention: _generalConsent,
        dataSharing: _dataTransferConsent,
        voluntaryParticipation: _voluntaryParticipation,
        consentedAt: DateTime.now(),
        participantSignature: widget.participantCode, // Using participant code as signature
      );

      // Save consent to database
      final db = SurveyDatabase();
      await db.insertConsent(consent);

      // Save participation settings
      final prefs = await SharedPreferences.getInstance();
      final settings = ParticipationSettings.researchParticipant(widget.participantCode, widget.researchSite);
      await prefs.setString('participation_settings', settings.toJson().toString());

      // Show success and navigate
      _showSuccessDialog(uuid);
      
    } catch (e) {
      _showErrorDialog('Failed to save consent: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _showSuccessDialog(String uuid) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Consent Recorded'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Thank you for consenting to participate in the research study.'),
            SizedBox(height: 16),
            Text('Your Participant UUID:', style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(uuid, style: TextStyle(fontFamily: 'monospace')),
            SizedBox(height: 8),
            Text('Please save this UUID. You will need it if you want to withdraw from the study or request data deletion.', 
                 style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(true); // Return to selection screen with success
            },
            child: Text('Continue to Survey'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _launchEmail(String email) async {
    final Uri uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
