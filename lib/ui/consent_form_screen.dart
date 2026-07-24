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

  // Localization helper: returns the string for the active app language,
  // falling back to English for any unsupported locale.
  String _t3(String en, String it, String es) {
    switch (Localizations.localeOf(context).languageCode) {
      case 'it':
        return it;
      case 'es':
        return es;
      default:
        return en;
    }
  }

  // Site-specific content getters
  String get _siteTitle {
    if (widget.researchSite == 'wellbeing_mapper') {
      return _t3(
        'Mental wellbeing in climate and environmental context (Case Study 4 of the PLANET4HEALTH project) – Italy Study Site',
        'Benessere mentale nel contesto climatico e ambientale (Caso di studio 4 del progetto PLANET4HEALTH) – Sito di studio Italia',
        'Bienestar mental en el contexto climático y ambiental (Caso de estudio 4 del proyecto PLANET4HEALTH) – Sede de estudio de Italia',
      );
    }
    return 'Mental wellbeing in climate and environmental context (Case Study 4 of the PLANET4HEALTH project) – Barcelona Study Site';
  }

  String get _inclusionCriteria {
    if (widget.researchSite == 'wellbeing_mapper') {
      return _t3(
        'To participate in this study you must be at least 18 years old and living in Italy.',
        'Per partecipare a questo studio devi avere almeno 18 anni e risiedere in Italia.',
        'Para participar en este estudio debe tener al menos 18 años y residir en Italia.',
      );
    }
    return 'To participate in this study you must be at least 18 years old and living in the Barcelona Metropolitan Area.';
  }

  String get _ethicsContact {
    if (widget.researchSite == 'wellbeing_mapper') {
      return _t3(
        "If you have doubts, complaints, or questions about this study or about your rights as a research participant, you may contact UPF's Institutional Committee for the Ethical Review of Projects (CIREP) by phone (+34 93 542 21 86) or by email (secretaria.cirep@upf.edu). CIREP is not part of the research team and will treat any information you send confidentially.",
        "In caso di dubbi, reclami o domande su questo studio o sui tuoi diritti come partecipante alla ricerca, puoi contattare il Comitato Istituzionale per la Revisione Etica dei Progetti (CIREP) dell'UPF per telefono (+34 93 542 21 86) o via email (secretaria.cirep@upf.edu). Il CIREP non fa parte del gruppo di ricerca e tratterà in modo riservato qualsiasi informazione tu invii.",
        "Si tiene dudas, quejas o preguntas sobre este estudio o sobre sus derechos como participante en la investigación, puede ponerse en contacto con el Comité Institucional para la Revisión Ética de Proyectos (CIREP) de la UPF por teléfono (+34 93 542 21 86) o por correo electrónico (secretaria.cirep@upf.edu). El CIREP no forma parte del equipo de investigación y tratará de forma confidencial cualquier información que envíe.",
      );
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
              ? '🧪 ${_showInformationSheet ? _t3('Information Sheet', 'Foglio informativo', 'Hoja de información') : _t3('Consent Form', 'Modulo di consenso', 'Formulario de consentimiento')} (Testing)'
              : _showInformationSheet ? _t3('Information Sheet', 'Foglio informativo', 'Hoja de información') : _t3('Consent Form', 'Modulo di consenso', 'Formulario de consentimiento'),
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
            Center(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _t3('Information Sheet', 'Foglio informativo', 'Hoja de información'),
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            _buildInfoSection(
              _t3('Title of the project', 'Titolo del progetto', 'Título del proyecto'),
              _siteTitle,
            ),
            _buildInfoSection(
              _t3('Institution', 'Istituzione', 'Institución'),
              'Universitat Pompeu Fabra',
            ),
            _buildInfoSection(
              _t3('Principal Investigators', 'Ricercatori principali', 'Investigadores principales'),
              _t3(
                'John Palmer (john.palmer@upf.edu), Linda Theron (linda.theron@up.ac.za), and Caradee Wright (Caradee.Wright@mrc.ac.za). If you have questions you may contact the principal investigators at the email addresses listed above.',
                'John Palmer (john.palmer@upf.edu), Linda Theron (linda.theron@up.ac.za) e Caradee Wright (Caradee.Wright@mrc.ac.za). In caso di domande puoi contattare i ricercatori principali agli indirizzi email sopra indicati.',
                'John Palmer (john.palmer@upf.edu), Linda Theron (linda.theron@up.ac.za) y Caradee Wright (Caradee.Wright@mrc.ac.za). Si tiene preguntas, puede ponerse en contacto con los investigadores principales en las direcciones de correo electrónico indicadas arriba.',
              ),
            ),
            _buildInfoSection(
              _t3('Ethics review contact', 'Contatto per la revisione etica', 'Contacto de revisión ética'),
              _ethicsContact,
            ),
            _buildInfoSection(
              _t3('Funding body', 'Ente finanziatore', 'Entidad financiadora'),
              _t3(
                'This project is funded by the European Union as part of the PLANET4HEALTH Project (https://planet4health.eu).',
                'Questo progetto è finanziato dall\'Unione Europea nell\'ambito del progetto PLANET4HEALTH (https://planet4health.eu).',
                'Este proyecto está financiado por la Unión Europea como parte del proyecto PLANET4HEALTH (https://planet4health.eu).',
              ),
            ),
            _buildInfoSection(
              _t3('Objectives of the project', 'Obiettivi del progetto', 'Objetivos del proyecto'),
              _t3(
                "The goal of this study is to learn more about how climate change and other changes in the environment affect people's mental wellbeing.",
                'L\'obiettivo di questo studio è capire meglio come il cambiamento climatico e altri cambiamenti ambientali influiscono sul benessere mentale delle persone.',
                'El objetivo de este estudio es conocer mejor cómo el cambio climático y otros cambios en el medio ambiente afectan al bienestar mental de las personas.',
              ),
            ),
            _buildInfoSection(
              _t3('Methodology and participation', 'Metodologia e partecipazione', 'Metodología y participación'),
              _t3(
                'This study involves a mobile phone application called Wellbeing Mapper, which keeps track of where you spend time, and lets you share this information, if you choose to, with the researchers carrying out this study. It also involves a series of surveys. You can participate by installing Wellbeing Mapper on your phone and letting it track your locations for up to six months. You will then be given the option of responding to up to 12 surveys, one every two weeks, in which you will be asked a series of questions about yourself and about your mental wellbeing. The first survey includes additional information about yourself and takes approximately 5 minutes to complete; the subsequent 11 surveys take 2-5 minutes. When you respond to the survey, you will have the opportunity to share the locations tracked by Wellbeing Mapper during the previous two weeks. You can choose which questions you answer and whether to share your locations. The survey will include questions about, among other things, your: race/ethnicity; health; sexual orientation; and location and mobility.',
                'Questo studio prevede un\'app per telefono cellulare chiamata Wellbeing Mapper, che tiene traccia di dove trascorri il tuo tempo e ti consente di condividere queste informazioni, se lo desideri, con i ricercatori che conducono questo studio. Prevede inoltre una serie di questionari. Puoi partecipare installando Wellbeing Mapper sul tuo telefono, consentendogli di tracciare le tue posizioni per un massimo di sei mesi. Avrai poi la possibilità di rispondere fino a 12 questionari, uno ogni due settimane, in cui ti verranno poste alcune domande su di te e sul tuo benessere mentale. Il primo questionario include informazioni aggiuntive su di te e richiede circa 5 minuti; i successivi 11 questionari richiedono 2-5 minuti. Quando rispondi al questionario, avrai la possibilità di condividere le posizioni tracciate da Wellbeing Mapper nelle due settimane precedenti. Puoi scegliere a quali domande rispondere e se condividere le tue posizioni. Il questionario includerà domande, tra le altre cose, su: origine etnica; salute; orientamento sessuale; posizione e mobilità.',
                'Este estudio utiliza una aplicación para teléfono móvil llamada Wellbeing Mapper, que registra dónde pasa su tiempo y le permite compartir esta información, si así lo decide, con el equipo investigador que lleva a cabo este estudio. También incluye una serie de cuestionarios. Puede participar instalando Wellbeing Mapper en su teléfono y permitiendo que registre sus ubicaciones durante un máximo de seis meses. Después tendrá la opción de responder hasta 12 cuestionarios, uno cada dos semanas, en los que se le harán una serie de preguntas sobre usted y sobre su bienestar mental. El primer cuestionario incluye información adicional sobre usted y dura aproximadamente 5 minutos; los 11 cuestionarios siguientes duran de 2 a 5 minutos. Al responder el cuestionario, tendrá la oportunidad de compartir las ubicaciones registradas por Wellbeing Mapper durante las dos semanas anteriores. Puede elegir qué preguntas responde y si comparte sus ubicaciones. El cuestionario incluirá preguntas sobre, entre otras cosas: raza/etnia; salud; orientación sexual; y ubicación y movilidad.',
              ),
            ),
            _buildInfoSection(
              _t3('Inclusion criteria', 'Criteri di inclusione', 'Criterios de inclusión'),
              _inclusionCriteria,
            ),
            _buildInfoSection(
              _t3('Voluntary participation', 'Partecipazione volontaria', 'Participación voluntaria'),
              _t3(
                'Your participation in this study is on a voluntary basis and you may withdraw from the study at any time without having to justify your decision.',
                'La tua partecipazione a questo studio è volontaria e puoi ritirarti dallo studio in qualsiasi momento senza dover giustificare la tua decisione.',
                'Su participación en este estudio es voluntaria y puede retirarse del estudio en cualquier momento sin tener que justificar su decisión.',
              ),
            ),
            _buildInfoSection(
              _t3('Risks and benefits', 'Rischi e benefici', 'Riesgos y beneficios'),
              _t3(
                'It is not expected that anything you will be asked to do while participating in this study will pose a risk to your health. However, it is very important that you not interact with your mobile phone while driving or engaged in any activity that requires your attention. Using a mobile phone while driving can increase your risk of injury or death, and to participate in the mobile phone component of this project, you must agree not to interact with the application or otherwise interact with your phone for this project while driving. Participation also involves some risk to your privacy because you will be asked to share information about where you spend time. However, this information will be kept confidential by the research team using encryption and standard data protection techniques. Participation will involve answering questions about your mental wellbeing and about climate change. In case these make you anxious or uncomfortable in any way, we will recommend a set of resources that you can turn to at the end of the survey. We cannot and do not guarantee that you will receive any benefits from this study.',
                'Non si prevede che nulla di ciò che ti verrà chiesto di fare durante la partecipazione a questo studio comporti un rischio per la tua salute. Tuttavia, è molto importante che tu non interagisca con il telefono cellulare mentre guidi o mentre stai svolgendo una qualsiasi attività che richieda la tua attenzione. Usare il telefono mentre si guida può aumentare il rischio di lesioni o morte e, per partecipare a questo progetto, devi accettare di non interagire con l\'applicazione né con il telefono per le attività di questo progetto mentre guidi. La partecipazione comporta anche un potenziale rischio per la tua privacy, poiché ti verrà chiesto di condividere informazioni su dove trascorri il tuo tempo. Tuttavia, queste informazioni saranno mantenute riservate dal gruppo di ricerca tramite crittografia e tecniche standard di protezione dei dati. La partecipazione prevede di rispondere a domande sul tuo benessere mentale e sul cambiamento climatico. Nel caso queste ti rendano ansioso/a o a disagio in qualunque modo, ti consiglieremo una serie di risorse a cui rivolgerti al termine del questionario. Non possiamo garantire e non garantiamo che riceverai alcun beneficio da questo studio.',
                'No se espera que nada de lo que se le pida hacer durante su participación en este estudio suponga un riesgo para su salud. Sin embargo, es muy importante que no interactúe con su teléfono móvil mientras conduce o realiza cualquier actividad que requiera su atención. Usar el teléfono móvil mientras se conduce puede aumentar el riesgo de lesiones o muerte y, para participar en el componente con teléfono móvil de este proyecto, debe aceptar no interactuar con la aplicación ni con su teléfono para este proyecto mientras conduce. La participación también implica cierto riesgo para su privacidad, ya que se le pedirá que comparta información sobre dónde pasa su tiempo. No obstante, esta información se mantendrá confidencial por el equipo de investigación mediante cifrado y técnicas estándar de protección de datos. La participación implicará responder preguntas sobre su bienestar mental y sobre el cambio climático. En caso de que esto le genere ansiedad o malestar de algún modo, le recomendaremos una serie de recursos a los que podrá acudir al final del cuestionario. No podemos garantizar ni garantizamos que vaya a recibir ningún beneficio de este estudio.',
              ),
            ),
            _buildInfoSection(
              // TODO(john): pending double-check — Italian compensation wording
              // was replaced with the Italian collaborator's suggested text,
              // which describes a company assigned to manage interviews/
              // compensation rather than "the survey panel provider that sent
              // you here" (English/Spanish). Confirm this matches the actual
              // arrangement for the Italy site before this ships.
              _t3('Compensation', 'Compenso', 'Compensación'),
              _t3(
                'Your participation will not be compensated by the research team but it may be compensated by the survey panel provider that sent you here, based on the agreement you have with that provider.',
                'Un compenso potrà essere erogato dalla ditta alla quale abbiamo assegnato la gestione delle interviste, nelle modalità comunicate dalla stessa.',
                'Su participación no será compensada por el equipo de investigación, pero podría ser compensada por el proveedor del panel de encuestas que le envió aquí, según el acuerdo que tenga con dicho proveedor.',
              ),
            ),
            _buildInfoSection(
              _t3('Data protection', 'Protezione dei dati', 'Protección de datos'),
              _t3(
                'In order to protect your privacy, we will not identify your data with your name, but rather with a code that will only be known to the research team members. In order to make your location data only accessible to research team members, this data will be protected using end-to-end encryption and it will be stored with access control systems. In the event of data publication, only anonymous data will be published. Anonymized data may be hosted or published in a public repository and will not be able to be used to identify you. If you would like your data to be deleted, you can request this by emailing the PIs and including in the email your participant UUID, which can be found in the Wellbeing Mapper application on the device you are using to collect it. Please note that the survey is being conducted with the help of the survey panel provider that you are working with, which is not affiliated with UPF and has its own privacy and security policies that you can find at its websites.',
                'Per proteggere la tua privacy, non identificheremo i tuoi dati con il tuo nome, ma con un codice noto solo ai membri del gruppo di ricerca. Per rendere i tuoi dati di posizione accessibili solo ai membri del gruppo di ricerca, questi dati saranno protetti tramite crittografia end-to-end e conservati con sistemi di controllo degli accessi. In caso di pubblicazione dei dati, saranno pubblicati solo dati anonimi. I dati anonimizzati potranno essere ospitati o pubblicati in un repository pubblico e non potranno essere utilizzati per identificarti. Se desideri che i tuoi dati vengano cancellati, puoi richiederlo inviando un\'email ai ricercatori principali e includendo il tuo UUID di partecipante, che puoi trovare nell\'applicazione Wellbeing Mapper sul dispositivo che stai usando. Tieni presente che l\'indagine è condotta con l\'aiuto della ditta che gestisce il panel con cui collabori, che non è affiliato a UPF e ha proprie politiche di privacy e sicurezza consultabili sui suoi siti web.',
                'Para proteger su privacidad, no identificaremos sus datos con su nombre, sino con un código que solo conocerán los miembros del equipo de investigación. Para que sus datos de ubicación solo sean accesibles para los miembros del equipo de investigación, estos datos se protegerán mediante cifrado de extremo a extremo y se almacenarán con sistemas de control de acceso. En caso de publicación de datos, solo se publicarán datos anónimos. Los datos anonimizados podrán alojarse o publicarse en un repositorio público y no podrán utilizarse para identificarle. Si desea que se eliminen sus datos, puede solicitarlo enviando un correo electrónico a los investigadores principales e incluyendo su UUID de participante, que se encuentra en la aplicación Wellbeing Mapper en el dispositivo que está usando. Tenga en cuenta que la encuesta se realiza con la ayuda del proveedor del panel de encuestas con el que trabaja, que no está afiliado a la UPF y tiene sus propias políticas de privacidad y seguridad disponibles en sus sitios web.',
              ),
            ),
            _buildGDPRSection(),
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
              child: Text(_t3('Continue to Consent Form', 'Continua al modulo di consenso', 'Continuar al formulario de consentimiento'), style: TextStyle(fontSize: 16, color: Colors.white)),
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
              ? _t3('Informed Consent Form', 'Modulo di consenso informato', 'Formulario de consentimiento informado')
              : 'Informed Consent Form',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          if (widget.researchSite == 'wellbeing_mapper') ...[
            SizedBox(height: 8),
            Text(
              _siteTitle,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ],
          SizedBox(height: 8),
          Text(
            '${_t3('Participant Code', 'Codice partecipante', 'Código de participante')}: ${widget.participantCode}',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          SizedBox(height: 24),
          
          _buildConsentSection(
            _t3('I HEREBY CONFIRM that:', 'CONFERMO CHE:', 'CONFIRMO QUE:'),
            [
            _buildBulletPoint(_t3(
              'I have read the information sheet regarding the research project,',
              'Ho letto il foglio informativo relativo al progetto di ricerca,',
              'He leído la hoja de información sobre el proyecto de investigación,')),
            _buildBulletPoint(_t3(
              'I have been able to formulate questions and I have received enough information on the project,',
              'Ho potuto formulare domande e ho ricevuto informazioni sufficienti sul progetto,',
              'He podido formular preguntas y he recibido suficiente información sobre el proyecto,')),
            _buildBulletPoint(_t3(
              'I fulfill the inclusion criteria, and I am at least 18 years old.',
              'Soddisfo i criteri di inclusione e ho almeno 18 anni.',
              'Cumplo los criterios de inclusión y tengo al menos 18 años.')),
          ]),

          if (widget.researchSite == 'wellbeing_mapper') ...[
            _buildConsentSection(
              _t3('I UNDERSTAND that:', 'COMPRENDO CHE:', 'ENTIENDO QUE:'),
              [
              _buildBulletPoint(_t3(
                'My participation is voluntary and that I can withdraw from or opt out of the study at any time without any need to justify my decision.',
                'La mia partecipazione è volontaria e posso ritirarmi o uscire dallo studio in qualsiasi momento senza dover giustificare la mia decisione.',
                'Mi participación es voluntaria y puedo retirarme o abandonar el estudio en cualquier momento sin necesidad de justificar mi decisión.')),
            ]),
            _buildConsentSection(
              _t3('I GIVE MY CONSENT:', 'DO IL MIO CONSENSO:', 'DOY MI CONSENTIMIENTO:'),
              [
              _buildCheckbox(_healthConsent, (value) => setState(() => _healthConsent = value!),
                _t3('to participate in this study',
                    'a partecipare a questo studio',
                    'a participar en este estudio')),
              _buildCheckbox(_locationConsent, (value) => setState(() => _locationConsent = value!),
                _t3('to being asked about my race/ethnicity',
                    'a che mi vengano poste domande sulla mia origine etnica',
                    'a que se me pregunte sobre mi raza/etnia')),
              _buildCheckbox(_healthConsent2, (value) => setState(() => _healthConsent2 = value!),
                _t3('to being asked about my health condition',
                    'a che mi vengano poste domande sul mio stato di salute',
                    'a que se me pregunte sobre mi estado de salud')),
              _buildCheckbox(_sexualOrientationConsent2, (value) => setState(() => _sexualOrientationConsent2 = value!),
                _t3('to being asked about my sexual orientation',
                    'a che mi vengano poste domande sul mio orientamento sessuale',
                    'a que se me pregunte sobre mi orientación sexual')),
              _buildCheckbox(_locationConsent2, (value) => setState(() => _locationConsent2 = value!),
                _t3('to being asked about my location and mobility',
                    'a che mi vengano poste domande sulla mia posizione e mobilità',
                    'a que se me pregunte sobre mi ubicación y movilidad')),
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
        ? _healthConsent && _locationConsent &&
          _healthConsent2 && _sexualOrientationConsent2 && _locationConsent2
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
                    _t3('Please check all required consent items (marked with *) to continue.',
                        'Seleziona tutte le voci di consenso obbligatorie (contrassegnate con *) per continuare.',
                        'Marque todos los elementos de consentimiento obligatorios (marcados con *) para continuar.'),
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
                : Text(_t3('Submit', 'Invia', 'Enviar'), style: TextStyle(fontSize: 18, color: Colors.white)),
          ),
        ),
        SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(_t3('Cancel', 'Annulla', 'Cancelar')),
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
        // Italy site no longer asks about third-party (LimeSurvey) processing or
        // transfer outside the EEA, so these are recorded as not-applicable (false).
        consentQualtricsData: widget.researchSite == 'wellbeing_mapper' ? false : _generalConsent,
        consentRaceEthnicity: widget.researchSite == 'wellbeing_mapper' ? _locationConsent : _raceEthnicityConsent,
        consentHealth: widget.researchSite == 'wellbeing_mapper' ? _healthConsent2 : _healthConsent,
        consentSexualOrientation: widget.researchSite == 'wellbeing_mapper' ? _sexualOrientationConsent2 : _sexualOrientationConsent,
        consentLocationMobility: widget.researchSite == 'wellbeing_mapper' ? _locationConsent2 : _locationConsent,
        consentDataTransfer: widget.researchSite == 'wellbeing_mapper' ? false : _dataTransferConsent,
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
        title: Text(_t3('Consent Recorded', 'Consenso registrato', 'Consentimiento registrado')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t3('Thank you for consenting to participate in the research study.',
                'Grazie per aver acconsentito a partecipare allo studio di ricerca.',
                'Gracias por dar su consentimiento para participar en el estudio de investigación.')),
            SizedBox(height: 16),
            Text(_t3('Your Participant UUID:', 'Il tuo UUID di partecipante:', 'Su UUID de participante:'), style: TextStyle(fontWeight: FontWeight.bold)),
            SelectableText(uuid, style: TextStyle(fontFamily: 'monospace')),
            SizedBox(height: 8),
            Text(_t3('Please save this UUID. You will need it if you want to withdraw from the study or request data deletion.',
                'Conserva questo UUID. Ti servirà se vorrai ritirarti dallo studio o richiedere la cancellazione dei dati.',
                'Guarde este UUID. Lo necesitará si desea retirarse del estudio o solicitar la eliminación de sus datos.'),
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
            child: Text(_t3('Continue to App', 'Continua all\'app', 'Continuar a la app')),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_t3('Error', 'Errore', 'Error')),
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
