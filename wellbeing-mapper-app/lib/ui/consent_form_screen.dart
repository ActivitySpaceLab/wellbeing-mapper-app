import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:convert';
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
  
  // Additional Gauteng consent variables
  bool _healthConsent2 = false;
  bool _sexualOrientationConsent2 = false;
  bool _locationConsent2 = false;
  bool _dataTransferConsent2 = false;
  bool _publicReportingConsent = false;
  bool _dataShareConsent = false;
  bool _futureResearchConsent = false;
  bool _repositoryConsent = false;
  bool _followUpConsent = false;

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
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _showInformationSheet ? 'Information Sheet' : 'Consent Form',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
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
          if (widget.researchSite == 'gauteng') ...[
            Card(
              margin: EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Information Sheet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text('Hello', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('We invite you to take part in a project called Mental wellbeing in climate and environmental context (Case Study 4 of the PLANET4HEALTH project) – Gauteng Study Site.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('This project has been approved by the Research Ethics Committee of the Faculty of Education, University of Pretoria with clearance number EDU092/24.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Institutions involved in this project: University of Pretoria (UP, South Africa), the South African Medical Research Council (SAMRC), the Universitat Pompeu Fabra (UPF, Spain) and Institut Za Medicinska Istra Ivanja (Serbia)', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Principal researchers: Linda Theron (linda.theron@up.ac.za), Caradee Wright (Caradee.Wright@mrc.ac.za), John Palmer (john.palmer@upf.edu) and Suzana Blesic (blesic.suzana@gmail.com)', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Research Assistant: Mudalo Ndou (planet4health.research@gmail.com) and +27 64 898 6212)', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Funding body: This project is funded by the European Union as part of the PLANET4HEALTH Project (https://planet4health.eu).', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('The purpose of this project: We want to learn how climate change and the environment affect the mental wellbeing of people living in Gauteng (South Africa) and what might support human resilience to climate change-related challenges.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Voluntary participation: In South Africa, we are inviting 300 participants to join the study. Participation is on a voluntary basis; participants may withdraw from the study at any time without having to justify their decision.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Who can participate: Anyone who (i) is 18 years old or older; (ii) lives in Gauteng; (iii) has a smart mobile device and regular access to the internet; (iv) is OK reading and writing basic English; and (v) can install the Space Mapper App onto their smart mobile device.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('What participants will be asked to do: This study involves a mobile phone application called Space Mapper, which keeps track of where participants spend time, and lets participants share this information, if they choose to, with the researchers. It also involves a series of surveys. Participants can participate by installing Space Mapper on their mobile phone and letting it track their locations for up to six months. They will receive surveys (questions and digital diary prompts) every two weeks, in which they will be asked a series of questions about themselves and about their mental wellbeing. When responding to the survey, they will have the opportunity to share the locations tracked by Space Mapper during the previous two weeks. Participants can choose which questions they wish to answer and whether they wish to share their locations. Among other things, the surveys will ask about participants\' race/ethnicity, health, sexual orientation, location and mobility, wellbeing, environmental challenges in the past two weeks, and supports that help them cope with challenges.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('What the data will be used for: The data will be used to better understand how to protect the wellbeing of people who experience environmental and climate change challenges (e.g., exposure to air pollution or extreme heat events). This understanding will inform various products (e.g., resilience toolkits or early warning systems) that can be used by mental health professionals, service providers and policy makers.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('The aggregate or anonymised results of this study may be presented at academic conferences, used for academic publications and lecture content, and when reporting the study on the study website (https://planet4health.eu/), in the popular press, or on social media. A similar project is being done in Barcelona, Spain, and we could compare the South African and Spanish results.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('We request participant permission to use the data, confidentially and anonymously, for further research purposes, as the data sets are the intellectual property of the University of Pretoria and partner institutions. Further research will focus on climate challenges and human wellbeing and what enables wellbeing when environmental conditions are challenging and may include secondary data analysis and using the data for teaching purposes. The confidentiality and privacy applicable to this study will be binding on future research studies (i.e., secondary analyses of the data to further investigate climate challenges and human wellbeing, and what enables wellbeing when environmental conditions are challenging).', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Data protection: We will keep the data for 10 years. To protect participants\' privacy, we will not identify their data with their name, but rather with a code (a participant number) that will only be known to the research team members. Only the researcher team and partners directly involved in this project (see names at the beginning of this information sheet) will have access to the survey responses. We will use a participant number to identify data (i.e., no data can be linked to someone\'s name). To make participants\' location data only accessible to research team members, this data will be protected using end-to-end encryption and it will be stored with access control systems. In the event of data publication, only anonymous data will be published. Anonymized data may be hosted or published in a public repository. If you would like your data to be deleted, you can request this by emailing the PIs and including in the email your participant UUID, which can be found in the Space Mapper application on the device you are using to collect it. Please note that the survey is being conducted with the help of Qualtrics (they have their own privacy and security policies that you can read about at https://www.qualtrics.com/privacy-statement/).', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Possible risks and benefits of participation: It is not expected that anything that participants will be asked to do in this study will pose a risk to their health. However, it is very important that participants do not interact with their mobile phone while driving or engaged in any activity that requires their attention. Using a mobile phone while driving can increase risk of injury or death.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Participation also involves some risk to participant privacy because you will be asked to share information about where you spend time. However, you can choose not to. If you choose to share this information, it will be kept confidential by the research team using encryption and standard data protection techniques.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Participation will involve answering questions about your mental wellbeing and about climate change. In case these make you anxious or uncomfortable in any way, we will recommend a set of resources that you can turn to at the end of every survey. These include: South African Depression and Anxiety Group (SADAG; SMS: 31393 or 32312, WhatsApp Chat: 076 882 2775, or Call: 0800 21 22 23 or 0800 70 80 90 or 0800 456 789, or Suicide Helpline: 0800 567 567) or Lifeline (Pretoria: 012 804 3619 or 0861 322 322; Johannesburg: 011 728 1347 or 0861 322 322; Alexandra: 011 443 3555; Soweto: 011 988 0155 or 0861 322 322; Vaal Triangle: 016 428 1740 or 016 428 5959; WhatsApp counselling: 065 989 9238 or 072 677 9090).', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('We cannot and do not guarantee that you will receive any benefits from this study, but we are hopeful that that the project will help us better understand how climate change is impacting mental wellbeing and what can be done to support human resilience to climate change and environmental challenges. We will disseminate our results broadly. Participants can follow the progress of the study and read a summary of the results on the study website (https://planet4health.eu/).', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Token of appreciation for study participation: We offer participants a Shoprite | Checkers shopping voucher after every two surveys completed – meaning one voucher per month of completed research activity. The voucher is sent electronically to the cellular phone number that participants register with the study. The value of the vouchers will be R100 (Month 1), R 150 (Month 2), R 200 (Month 3), R 250 (Month 4), R 300 (Month 5) and R 500 (Month 6). These vouchers are not redeemable for cash and cannot be replaced if lost or stolen.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Further information about the project: If participants have any questions, they are encouraged to contact Mudalo Ndou at (planet4health.research@gmail.com) or +27 64 898 6212)', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Alternatively, contact the project leader, Professor Linda Theron, at Linda.theron@up.ac.za or phone her on 012 420 6211.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Questions relating to ethics of this project: If participants have any concerns or complaints regarding the ethical procedures of this study, they are welcome to contact the Chair of the Faculty of Education Research Ethics Committee: Prof Funke Omidire at Funke.omidire@up.ac.za.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 16),
                    Text('Thank you for considering our invitation.', style: TextStyle(fontSize: 15, height: 1.4)),
                    SizedBox(height: 8),
                    Text('Yours sincerely,', style: TextStyle(fontSize: 15, height: 1.4)),
                    Text('Linda Theron, Mudalo Ndou and Research Team', style: TextStyle(fontSize: 15, height: 1.4)),
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
          if (widget.researchSite != 'gauteng') _buildGDPRSection(),
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
            widget.researchSite == 'gauteng' 
              ? 'Participant Informed Consent'
              : 'Informed Consent Form',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (widget.researchSite == 'gauteng') ...[
            SizedBox(height: 8),
            Text(
              'Mental wellbeing in climate and environmental context (Case Study 4 of the PLANET4HEALTH project) – Gauteng Study Site.',
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
            _buildCheckbox(_hasReadInformation, (value) => setState(() => _hasReadInformation = value!),
              'I have read the information sheet regarding the research project'),
            _buildCheckbox(_understands, (value) => setState(() => _understands = value!),
              widget.researchSite == 'gauteng' 
                ? 'The information sheet is written in a language with which I am fluent enough to understand all content'
                : 'I have been able to formulate questions and I have received enough information on the project'),
            if (widget.researchSite == 'gauteng') ...[
              _buildCheckbox(_generalConsent, (value) => setState(() => _generalConsent = value!),
                'I have been able to ask questions and I have received enough information on the project'),
            ],
            _buildCheckbox(_fulfillsCriteria, (value) => setState(() => _fulfillsCriteria = value!),
              widget.researchSite == 'gauteng'
                ? 'I fulfill the inclusion criteria, and I am between at least 18 years old'
                : 'I fulfill the inclusion criteria, and I am at least 18 years old'),
            _buildCheckbox(_voluntaryParticipation, (value) => setState(() => _voluntaryParticipation = value!),
              'I understand that my participation is voluntary and that I can withdraw from or opt out of the study at any time without any need to justify my decision'),
            if (widget.researchSite == 'gauteng') ...[
              _buildCheckbox(_dataTransferConsent, (value) => setState(() => _dataTransferConsent = value!),
                'I understand that once researchers start to analyse the data (e.g., add what I answered to what everybody else answered) and/or the findings of the study are in the process of publication, I cannot withdraw the information that I contributed to the study'),
              _buildCheckbox(_limeSurveyConsent, (value) => setState(() => _limeSurveyConsent = value!),
                'I understand that I could be asked to leave the study before it has finished, if the researcher thinks it is in my best interests'),
              _buildCheckbox(_raceEthnicityConsent, (value) => setState(() => _raceEthnicityConsent = value!),
                'I understand that I can follow the project\'s progress on the study website (https://planet4health.eu) and that I will be able to access a summary of the findings on that website when the study is complete'),
            ],
          ]),

          if (widget.researchSite == 'gauteng') ...[
            _buildConsentSection('I GIVE MY CONSENT:', [
              _buildCheckbox(_healthConsent, (value) => setState(() => _healthConsent = value!),
                'to participate in this study'),
              _buildCheckbox(_sexualOrientationConsent, (value) => setState(() => _sexualOrientationConsent = value!),
                'for my personal data to be processed by Qualtrics, under their terms and conditions (https://www.qualtrics.com/privacy-statement/)'),
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
                'to being contacted about participation in possible follow-up studies', isRequired: false),
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
          if (widget.researchSite != 'gauteng') _buildGDPRSection(),
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
    final bool allRequired = widget.researchSite == 'gauteng'
        ? _hasReadInformation && _understands && _generalConsent && _fulfillsCriteria && 
          _voluntaryParticipation && _dataTransferConsent && _limeSurveyConsent && 
          _raceEthnicityConsent && _healthConsent && _sexualOrientationConsent && 
          _locationConsent && _healthConsent2 && _sexualOrientationConsent2 && 
          _locationConsent2 && _dataTransferConsent2 && _publicReportingConsent && 
          _dataShareConsent && _futureResearchConsent && _repositoryConsent
        : _hasReadInformation && _understands && _fulfillsCriteria && 
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
      await prefs.setString('participation_settings', jsonEncode(settings.toJson()));

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
