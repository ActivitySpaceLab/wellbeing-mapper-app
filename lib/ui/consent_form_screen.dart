import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
import '../models/consent_models.dart';
import '../db/survey_database.dart';
import '../services/app_mode_service.dart';
import '../models/app_mode.dart';
import '../services/participant_validation_service.dart';
import '../services/research_server_service.dart';
import '../main.dart'; // For GlobalData
import '../services/consent_tracking_service.dart';

class ConsentFormScreen extends StatefulWidget {
  final String participantCode;
  final String researchSite; // 'barcelona' or 'wellbeing_mapper'
  final bool isTestingMode; // Whether this is for app testing mode

  ConsentFormScreen({
    required this.participantCode, 
    required this.researchSite,
    this.isTestingMode = false,
  });

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
  
  // Additional site-specific consent variables
  bool _healthConsent2 = false;
  bool _sexualOrientationConsent2 = false;
  bool _locationConsent2 = false;
  bool _dataTransferConsent2 = false;
  bool _publicReportingConsent = false;
  bool _dataShareConsent = false;
  bool _futureResearchConsent = false;
  bool _repositoryConsent = false;
  bool _followUpConsent = false;

  @override
  void initState() {
    super.initState();
    _checkExistingConsent();
  }

  /// Check if user has already consented and bypass the form if they have
  Future<void> _checkExistingConsent() async {
    debugPrint('[ConsentForm] Checking for existing consent...');
    
    // Check if consent has already been completed
    final hasConsent = await ConsentTrackingService.hasCompletedCurrentConsent();
    
    if (hasConsent) {
      debugPrint('[ConsentForm] User has already completed consent - bypassing form');
      
      // User has already consented, navigate them past the consent form
      if (mounted) {
        // Navigate to the initial survey or main app depending on context
        if (widget.isTestingMode) {
          // For testing mode, go to home
          Navigator.of(context).pushReplacementNamed('/');
        } else {
          // For research mode, go to initial survey
          Navigator.of(context).pushReplacementNamed('/initial_survey');
        }
      }
      return;
    }
    
    debugPrint('[ConsentForm] No existing consent found - showing consent form');
  }

  // Site-specific content getters
  String get _siteTitle {
    if (widget.researchSite == 'wellbeing_mapper') {
      return 'Mental wellbeing in climate and environmental context (Case Study 4 of the PLANET4HEALTH project) – Southern Europe Study Site';
    }
    return 'Mental wellbeing in climate and environmental context (Case Study 4 of the PLANET4HEALTH project) – Barcelona Study Site';
  }

  String get _inclusionCriteria {
    if (widget.researchSite == 'wellbeing_mapper') {
      return 'To participate in this study you must be at least 18 years old and living in the Southern Europe.';
    }
    return 'To participate in this study you must be at least 18 years old and living in the Barcelona Metropolitan Area.';
  }

  String get _ethicsContact {
    if (widget.researchSite == 'wellbeing_mapper') {
      return 'If you have doubts, complaints, or questions about this study or about your rights as a research participant, you may contact the University of Pretoria\'s Faculty of Health Sciences Research Ethics Committee or the South African Medical Research Council\'s Ethics Committee.';
    }
    return 'If you have doubts, complaints, or questions about this study or about your rights as a research participant, you may contact UPF\'s Institutional Committee for the Ethical Review of Projects (CIREP) by phone (+34 93 542 21 86) or by email (secretaria.cirep@upf.edu).';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.isTestingMode 
              ? '🧪 ${_showInformationSheet ? 'Information Sheet' : 'Consent Form'} (Testing)'
              : _showInformationSheet ? 'Information Sheet' : 'Consent Form',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: widget.isTestingMode ? Colors.orange : Colors.blue,
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
          // Beta Testing Mode Notice
          if (widget.isTestingMode) ...[
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.science, color: Colors.orange, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '🧪 APP TESTING MODE',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'You are experiencing the consent process in testing mode. This allows you to:',
                    style: TextStyle(fontSize: 14, color: Colors.orange.shade700),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Practice the full research consent experience\n'
                    '• Understand what real research participation involves\n'
                    '• Test all app features safely\n'
                    '• NO real research data will be collected',
                    style: TextStyle(fontSize: 14, color: Colors.orange.shade700),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'This is for testing purposes only. Your responses will stay on your device.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (widget.researchSite == 'wellbeing_mapper') ...[
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // University of Pretoria Logo
                    Center(
                      child: Container(
                        height: 80,
                        margin: EdgeInsets.only(bottom: 20),
                        child: Image.asset(
                          'assets/images/up_ed_logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 80,
                              child: Icon(Icons.school, size: 60, color: Colors.blue),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Title
                    Center(
                      child: Text(
                        'Information Sheet',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Greeting
                    Text('Hello', style: TextStyle(fontSize: 16, height: 1.5)),
                    SizedBox(height: 12),
                    
                    // Introduction
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'We invite you to take part in a project called '),
                          TextSpan(text: 'Mental wellbeing in climate and environmental context', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: ' (Case Study 4 of the PLANET4HEALTH project) -- Southern Europe Study Site.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    Text(
                      'This project has been approved by the Research Ethics Committee of the Faculty of Education, University of Pretoria with clearance number EDU092/24.',
                      style: TextStyle(fontSize: 16, height: 1.5),
                    ),
                    SizedBox(height: 16),
                    
                    // Institutions
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Institutions involved in this project: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'University of Pretoria (UP, South Africa), the South African Medical Research Council (SAMRC), the Universitat Pompeu Fabra (UPF, Spain) and Institut Za Medicinska Istra Ivanja (Serbia)'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Principal researchers
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Principal researchers: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'Linda Theron (linda.theron@up.ac.za), Caradee Wright (Caradee.Wright@mrc.ac.za), John Palmer (john.palmer@upf.edu) and Suzana Blesic (blesic.suzana@gmail.com)'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Research Assistant
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Research Assistant: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'Mudalo Ndou (planet4health.research@gmail.com) and +27 64 898 6212)'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    // Funding body
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Funding body: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'This project is funded by the European Union as part of the PLANET4HEALTH Project (https://planet4health.eu).'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Purpose
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'The purpose of this project: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'We want to learn how climate change and the environment affect the mental wellbeing of people living in Southern Europe and what might support human resilience to climate change-related challenges.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Voluntary participation
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Voluntary participation: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'In South Africa, we are inviting 300 participants to join the study. Participation is on a voluntary basis; participants may withdraw from the study at any time without having to justify their decision.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Who can participate
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Who can participate: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'Anyone who (i) is 18 years old or older; (ii) lives in Southern Europe; (iii) has a smart mobile device and regular access to the internet; (iv) is OK reading and writing basic English; and (v) can install the Space Mapper App onto their smart mobile device.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // What participants will be asked to do
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'What participants will be asked to do: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'This study involves a mobile phone application called Space Mapper, which keeps track of where participants spend time, and lets participants share this information, '),
                          TextSpan(text: 'if they choose to', style: TextStyle(fontStyle: FontStyle.italic)),
                          TextSpan(text: ', with the researchers. It also involves a series of surveys. Participants can participate by installing Space Mapper on their mobile phone and letting it track their locations for up to six months. They will receive surveys (questions and digital diary prompts) every two weeks, in which they will be asked a series of questions about themselves and about their mental wellbeing. When responding to the survey, they will have the opportunity to share the locations tracked by Space Mapper during the previous two weeks. Participants can choose which questions they wish to answer and whether they wish to share their locations. Among other things, the surveys will ask about participants\' race/ethnicity, health, sexual orientation, location and mobility, wellbeing, environmental challenges in the past two weeks, and supports that help them cope with challenges.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // What the data will be used for
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'What the data will be used for: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'The data will be used to better understand how to protect the wellbeing of people who experience environmental and climate change challenges (e.g., exposure to air pollution or extreme heat events). This understanding will inform various products (e.g., resilience toolkits or early warning systems) that can be used by mental health professionals, service providers and policy makers.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'The aggregate or anonymised results of this study may be presented at academic conferences, used for academic publications and lecture content, and when reporting the study on the study website ('),
                          TextSpan(text: 'https://planet4health.eu/', style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                          TextSpan(text: '), in the popular press, or on social media. A similar project is being done in Barcelona, Spain, and we could compare the South African and Spanish results.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'We request participant permission to use the data, confidentially and anonymously, for further research purposes, as the data sets are the intellectual property of the University of Pretoria and partner institutions. Further research will focus on climate challenges and human wellbeing and what enables wellbeing when environmental conditions are challenging and may include secondary data analysis and using the data for teaching purposes. The confidentiality and privacy applicable to this study will be binding on future research studies (i.e., secondary analyses of the data to further investigate climate challenges and human wellbeing, and what enables wellbeing when environmental conditions are challenging).'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    
                    // Data protection
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Data protection: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'We will keep the data for 10 years. To protect participants\' privacy, we will not identify their data with their name, but rather with a code (a participant number) that will only be known to the research team members. Only the researcher team and partners directly involved in this project (see names at the beginning of this information sheet) will have access to the survey responses. We will use a participant number to identify data (i.e., no data can be linked to someone\'s name). To make participants\' location data only accessible to research team members, this data will be protected using end-to-end encryption and it will be stored with access control systems. In the event of data publication, only anonymous data will be published. Anonymized data may be hosted or published in a public repository. If you would like your data to be deleted, you can request this by emailing the PIs and including in the email your participant UUID, which can be found in the Space Mapper application on the device you are using to collect it. Please note that the survey is being conducted with the help of Qualtrics (they have their own privacy and security policies that you can read about at https://www.qualtrics.com/privacy-statement/).'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Possible risks and benefits
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Possible risks and benefits of participation: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'It is not expected that anything that participants will be asked to do in this study will pose a risk to their health. However, it is very important that participants do not interact with their mobile phone while driving or engaged in any activity that requires their attention. Using a mobile phone while driving can increase risk of injury or death.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Participation also involves some risk to participant privacy because you will be asked to share information about where you spend time. However, you can choose not to. If you choose to share this information, it will be kept confidential by the research team using encryption and standard data protection techniques.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Participation will involve answering questions about your mental wellbeing and about climate change. In case these make you anxious or uncomfortable in any way, we will recommend a set of resources that you can turn to at the end of every survey. These include: '),
                          TextSpan(text: 'South African Depression and Anxiety Group (SADAG; SMS: 31393 or 32312, WhatsApp Chat: 076 882 2775, or Call: 0800 21 22 23 or 0800 70 80 90 or 0800 456 789, or Suicide Helpline: 0800 567 567)', style: TextStyle(fontWeight: FontWeight.w500)),
                          TextSpan(text: ' or '),
                          TextSpan(text: 'Lifeline (Pretoria: 012 804 3619 or 0861 322 322; Johannesburg: 011 728 1347 or 0861 322 322; Alexandra: 011 443 3555; Soweto: 011 988 0155 or 0861 322 322; Vaal Triangle: 016 428 1740 or 016 428 5959; WhatsApp counselling: 065 989 9238 or 072 677 9090)', style: TextStyle(fontWeight: FontWeight.w500)),
                          TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'We cannot and do not guarantee that you will receive any benefits from this study, but we are hopeful that that the project will help us better understand how climate change is impacting mental wellbeing and what can be done to support human resilience to climate change and environmental challenges. We will disseminate our results broadly. Participants can follow the progress of the study and read a summary of the results on the study website ('),
                          TextSpan(text: 'https://planet4health.eu/', style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue)),
                          TextSpan(text: ').'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    // Token of appreciation
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Token of appreciation for study participation: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'We offer participants a Shoprite | Checkers shopping voucher after every two surveys completed – meaning one voucher per month of completed research activity. The voucher is sent electronically to the cellular phone number that participants register with the study. The value of the vouchers will be R100 (Month 1), R 150 (Month 2), R 200 (Month 3), R 250 (Month 4), R 300 (Month 5) and R 500 (Month 6). These vouchers are not redeemable for cash and cannot be replaced if lost or stolen.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Further information
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Further information about the project: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'If participants have any questions, they are encouraged to contact Mudalo Ndou at (planet4health.research@gmail.com) or +27 64 898 6212)'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Alternatively, contact the project leader, Professor Linda Theron, at Linda.theron@up.ac.za or phone her on 012 420 6211.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    // Ethics contact
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Questions relating to ethics of this project: ', style: TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(text: 'If participants have any concerns or complaints regarding the ethical procedures of this study, they are welcome to contact the Chair of the Faculty of Education Research Ethics Committee: Prof Funke Omidire at Funke.omidire@up.ac.za.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 16),
                    // Closing
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Thank you for considering our invitation.'),
                        ],
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87),
                        children: [
                          TextSpan(text: 'Yours sincerely,'),
                        ],
                      ),
                    ),
                    SizedBox(height: 4),
                    
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 16, height: 1.5, color: Colors.black87, fontWeight: FontWeight.w500),
                        children: [
                          TextSpan(text: 'Linda Theron, Mudalo Ndou and Research Team'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else ...[
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
          ],
          if (widget.researchSite != 'wellbeing_mapper') _buildGDPRSection(),
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
          // Beta Testing Mode Notice for Consent Form
          if (widget.isTestingMode) ...[
            Container(
              width: double.infinity,
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                border: Border.all(color: Colors.orange),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.science, color: Colors.orange),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'TESTING MODE: Practice consent - no real data collection',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          Text(
            widget.researchSite == 'wellbeing_mapper' 
              ? 'Participant Informed Consent'
              : 'Informed Consent Form',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (widget.researchSite == 'wellbeing_mapper') ...[
            SizedBox(height: 8),
            Text(
              'Mental wellbeing in climate and environmental context (Case Study 4 of the PLANET4HEALTH project) – Southern Europe Study Site.',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
          SizedBox(height: 8),
          Text(
            'Participant Code: ${widget.participantCode}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          
          _buildConsentSection('I HEREBY CONFIRM that:', [
            _buildBulletPoint('I have read the information sheet regarding the research project,'),
            _buildBulletPoint('The information sheet is written in a language with which I am fluent enough to understand all content,'),
            _buildBulletPoint('I have been able to ask questions and I have received enough information on the project,'),
            _buildBulletPoint('I fulfill the inclusion criteria, and I am at least 18 years old,'),
            _buildBulletPoint('I understand that my participation is voluntary and that I can withdraw from or opt out of the study at any time without any need to justify my decision,'),
            _buildBulletPoint('I understand that once researchers start to analyse the data (e.g., add what I answered to what everybody else answered) and/or the findings of the study are in the process of publication, I cannot withdraw the information that I contributed to the study'),
            _buildBulletPoint('I understand that I could be asked to leave the study before it has finished, if the researcher thinks it is in my best interests'),
            _buildBulletPoint('I understand that I can follow the project\'s progress on the study website (https://planet4health.eu) and that I will be able to access a summary of the findings on that website when the study is complete'),
          ]),

          if (widget.researchSite == 'wellbeing_mapper') ...[
            _buildConsentSection('I GIVE MY CONSENT:', [
              _buildCheckbox(_healthConsent, (value) => setState(() => _healthConsent = value!),
                'to participate in this study'),
              _buildCheckbox(_sexualOrientationConsent, (value) => setState(() => _sexualOrientationConsent = value!),
                'for my personal data to be processed by Qualtrics, under their terms and conditions'),
              _buildCheckbox(_locationConsent, (value) => setState(() => _locationConsent = value!),
                'to being asked about by race/ethnicity'),
              _buildCheckbox(_healthConsent2, (value) => setState(() => _healthConsent2 = value!),
                'to being asked about my health'),
              _buildCheckbox(_sexualOrientationConsent2, (value) => setState(() => _sexualOrientationConsent2 = value!),
                'to being asked about my sexual orientation'),
              _buildCheckbox(_locationConsent2, (value) => setState(() => _locationConsent2 = value!),
                'to being asked about my location and mobility'),
              _buildCheckbox(_dataTransferConsent2, (value) => setState(() => _dataTransferConsent2 = value!),
                'to transferring my personal data to countries outside South Africa'),
              _buildCheckbox(_publicReportingConsent, (value) => setState(() => _publicReportingConsent = value!),
                'to researchers reporting what I contribute (what I answer) publicly (e.g., in reports, books, magazines, websites) without my full name being included'),
              _buildCheckbox(_dataShareConsent, (value) => setState(() => _dataShareConsent = value!),
                'to what I contribute being shared with national and international researchers and partners involved in this project'),
              _buildCheckbox(_futureResearchConsent, (value) => setState(() => _futureResearchConsent = value!),
                'to what I contribute being used for further research or teaching purposes by the University of Pretoria and project partners'),
              _buildCheckbox(_repositoryConsent, (value) => setState(() => _repositoryConsent = value!),
                'to what I contribute being placed in a public repository in a deidentified or anonymised form once the project is complete'),
              _buildCheckbox(_followUpConsent, (value) => setState(() => _followUpConsent = value!),
                'to being contacted about participation in possible follow-up studies',
                isRequired: false),
            ]),
          ] else ...[
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
          ],

          SizedBox(height: 24),
          if (widget.researchSite != 'wellbeing_mapper') _buildGDPRSection(),
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
      padding: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2),
            child: Checkbox(value: value, onChanged: onChanged),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(!value),
              child: Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  text + (isRequired ? ' *' : ''),
                  style: TextStyle(fontSize: 15, height: 1.4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 6, right: 8),
            child: Icon(
              Icons.circle,
              size: 6,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 15, height: 1.4),
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
    final bool allRequired = widget.researchSite == 'wellbeing_mapper'
        ? _healthConsent && _sexualOrientationConsent && _locationConsent && 
          _healthConsent2 && _sexualOrientationConsent2 && _locationConsent2 && 
          _dataTransferConsent2 && _publicReportingConsent && _dataShareConsent && 
          _futureResearchConsent && _repositoryConsent
          // Note: _followUpConsent is now optional as requested
        : _voluntaryParticipation && _generalConsent && _raceEthnicityConsent && 
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
                : Text('Submit', style: TextStyle(fontSize: 18, color: Colors.white)),
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
      // Use the existing app UUID for consistency across all surveys
      final uuid = GlobalData.userUUID;
      
      // Create consent response
      final consent = ConsentResponse(
        participantUuid: uuid,
        // For Southern Europe, since all checkboxes must be checked to submit, these should be true
        informedConsent: widget.researchSite == 'wellbeing_mapper' ? 
          true : // All Southern Europe checkboxes must be checked to reach this point
          (_hasReadInformation && _understands && _fulfillsCriteria),
        dataProcessing: widget.researchSite == 'wellbeing_mapper' ? 
          true : // All Southern Europe checkboxes must be checked to reach this point
          _generalConsent,
        locationData: widget.researchSite == 'wellbeing_mapper' ? _locationConsent2 : _locationConsent,
        surveyData: widget.researchSite == 'wellbeing_mapper' ? true : _generalConsent,
        dataRetention: widget.researchSite == 'wellbeing_mapper' ? true : _generalConsent,
        dataSharing: widget.researchSite == 'wellbeing_mapper' ? _dataShareConsent : _dataTransferConsent,
        voluntaryParticipation: widget.researchSite == 'wellbeing_mapper' ? true : _voluntaryParticipation,
        consentedAt: DateTime.now(),
        participantSignature: widget.participantCode, // Using participant code as signature
        // Map site-specific consent questions correctly - FIX CRITICAL BUG
        consentParticipate: widget.researchSite == 'wellbeing_mapper' ? _healthConsent : _generalConsent,
        consentQualtricsData: widget.researchSite == 'wellbeing_mapper' ? _sexualOrientationConsent : _generalConsent,
        consentRaceEthnicity: widget.researchSite == 'wellbeing_mapper' ? _locationConsent : _raceEthnicityConsent,
        consentHealth: widget.researchSite == 'wellbeing_mapper' ? _healthConsent2 : _healthConsent,
        consentSexualOrientation: widget.researchSite == 'wellbeing_mapper' ? _sexualOrientationConsent2 : _sexualOrientationConsent,
        consentLocationMobility: widget.researchSite == 'wellbeing_mapper' ? _locationConsent2 : _locationConsent,
        consentDataTransfer: widget.researchSite == 'wellbeing_mapper' ? _dataTransferConsent2 : _dataTransferConsent,
        consentPublicReporting: widget.researchSite == 'wellbeing_mapper' ? _publicReportingConsent : false,
        consentResearcherSharing: widget.researchSite == 'wellbeing_mapper' ? _dataShareConsent : false,
        consentFurtherResearch: widget.researchSite == 'wellbeing_mapper' ? _futureResearchConsent : false,
        consentPublicRepository: widget.researchSite == 'wellbeing_mapper' ? _repositoryConsent : false,
        consentFollowupContact: widget.researchSite == 'wellbeing_mapper' ? _followUpConsent : false,
      );

      // Save consent to database
      final db = SurveyDatabase();
      await db.insertConsent(consent);

      // Sync consent form to Qualtrics (if not in testing mode)
      if (!widget.isTestingMode) {
        try {
          debugPrint('[ConsentForm] Syncing consent with encrypted service...');
          
          // SECURITY: Using encrypted survey service for secure consent data transmission
          ResearchServerService.syncPendingSurveys().catchError((e) {
            debugPrint('[ConsentForm] ⚠️ Encrypted sync will retry later: $e');
          });
          
          debugPrint('[ConsentForm] ✅ Consent form saved and encrypted sync initiated');
        } catch (e) {
          debugPrint('[ConsentForm] ❌ Error with encrypted sync: $e');
          // Don't fail the whole process - consent is still saved locally
        }
      } else {
        debugPrint('[ConsentForm] Skipping sync in testing mode');
      }

      // Record consent with participant validation service (for research participants)
      if (!widget.isTestingMode && widget.participantCode.isNotEmpty) {
        final consentResult = await ParticipantValidationService.recordConsent(
          widget.participantCode,
          DateTime.now(),
        );
        if (!consentResult.success) {
          debugPrint('[ConsentForm] Warning: Failed to record consent on server: ${consentResult.error}');
          // Don't fail the whole process - consent is still saved locally
        } else {
          debugPrint('[ConsentForm] Consent successfully recorded on server');
        }
      }

      // Save participation settings based on mode
      final prefs = await SharedPreferences.getInstance();
      
      if (widget.isTestingMode) {
        // For app testing mode, use research participant settings for full experience
        // but mark it as testing so data stays local
        final settings = ParticipationSettings.researchParticipant(widget.participantCode, widget.researchSite);
        await prefs.setString('participation_settings', jsonEncode(settings.toJson()));
        debugPrint('[ConsentForm] Saved research participant settings for testing mode (data stays local)');
        
        // CRITICAL FIX: Set the app mode to appTesting after consent completion
        await AppModeService.setCurrentMode(AppMode.appTesting);
        debugPrint('[ConsentForm] Set app mode to appTesting after consent completion');
      } else {
        // For research participation, use research participant settings
        final settings = ParticipationSettings.researchParticipant(widget.participantCode, widget.researchSite);
        await prefs.setString('participation_settings', jsonEncode(settings.toJson()));
        debugPrint('[ConsentForm] Saved research participant settings');
        
        // Set the app mode to research for real research participation
        await AppModeService.setCurrentMode(AppMode.research);
        debugPrint('[ConsentForm] Set app mode to research after consent completion');
      }
      
      // Mark consent as completed using new tracking service (also sets fresh_consent_completion flag)
      await ConsentTrackingService.markConsentCompleted();
      debugPrint('[ConsentForm] Marked consent as completed using ConsentTrackingService');

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
            onPressed: () async {
              try {
                Navigator.of(context).pop(); // Close dialog
                
                if (widget.isTestingMode) {
                  // For testing mode, return true to the change mode screen to indicate success
                  debugPrint('[ConsentForm] Testing mode consent completed - returning to change mode screen');
                  Navigator.of(context).pop(true);
                } else {
                  // For research participation, go directly to main app
                  debugPrint('[ConsentForm] Research consent completed - navigating directly to main app');
                  Navigator.of(context).pushReplacementNamed('/');
                }
                
              } catch (e) {
                debugPrint('[ConsentForm] Error in navigation: $e');
                // Fallback navigation
                if (widget.isTestingMode) {
                  Navigator.of(context).pop(true);
                } else {
                  Navigator.of(context).pushReplacementNamed('/');
                }
              }
            },
            child: Text('Continue to App'),
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
