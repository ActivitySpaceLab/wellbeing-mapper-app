import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/survey_models.dart';
import '../models/consent_models.dart';
import '../models/data_sharing_consent.dart';
import '../models/app_mode.dart';
import '../services/research_server_service.dart';
import '../services/global_notification_service.dart';
import '../db/survey_database.dart';
import '../services/app_mode_service.dart';
import 'interactive_location_privacy_map.dart';
import '../theme/south_african_theme.dart';
import '../main.dart'; // For GlobalData

class RecurringSurveyScreen extends StatefulWidget {
  @override
  _RecurringSurveyScreenState createState() => _RecurringSurveyScreenState();
}

class _RecurringSurveyScreenState extends State<RecurringSurveyScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;
  // Photo functionality removed - _selectedImages not needed
  
  // Track slider values for better UX - starts with no selection
  final Map<String, double?> _sliderValues = {};
  // Photo functionality removed - ImagePicker not needed
  String _researchSite = 'wellbeing_mapper'; // Default to Southern Europe
  
  // Voice recording state
  // bool _isRecording = false;
  // bool _isPaused = false;
  
  // Audio playback state
  // Map<String, bool> _playingStates = {};
  
  // Location sharing state
  LocationSharingOption _locationSharingOption = LocationSharingOption.fullData;
  List<LocationTrack> _recentLocationTracks = [];
  Set<int> _erasedLocationIndices = Set<int>(); // Track which locations user removed
  int _totalLocationCount = 0;

  @override
  void initState() {
    super.initState();
    _loadResearchSite();
    _loadLocationData(); // Load location data for status display
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

  // site-specific activity options based on survey_questions_gp.md
  final List<String> _siteActivityOptions = [
    'Unemployed, looking for work',
    'Unemployed but NOT looking for work',
    'Temporary/seasonal labour',
    'Part-time employed',
    'Full-time employed',
    'Self employed',
    'Skills development course (e.g. learnership)',
    'Student',
    'Retired',
    'Homemaker',
    'Caring for children/ill relatives',
    'Volunteered',
    'Exercised',
    'Vacation',
    'Other'
  ];

  // Barcelona activity options (original)
  final List<String> _barcelonaActivityOptions = [
    'Employed',
    'Unemployed',
    'Student',
    'Homemaker',
    'Retired',
    'Unable to work',
    'Other'
  ];

  // site-specific living arrangement options
  final List<String> _siteLivingArrangementOptions = [
    'alone',
    'others'
  ];

  // Barcelona living arrangement options (original)
  final List<String> _barcelonaLivingArrangementOptions = [
    'Living alone',
    'Living with family',
    'Living with friends/roommates',
    'Living with partner/spouse',
    'Other'
  ];

  // site-specific relationship options  
  final List<String> _siteRelationshipOptions = [
    'Single',
    'In a committed relationship/married',
    'Separated',
    'Divorced',
    'Widowed'
  ];

  // Barcelona relationship options (original)
  final List<String> _barcelonaRelationshipOptions = [
    'Single',
    'In a relationship',
    'Married',
    'Divorced',
    'Widowed',
    'Prefer not to say'
  ];

  // Getters for site-specific options
  List<String> get _activityOptions => _researchSite == 'wellbeing_mapper' 
      ? _siteActivityOptions 
      : _barcelonaActivityOptions;
      
  List<String> get _livingArrangementOptions => _researchSite == 'wellbeing_mapper' 
      ? _siteLivingArrangementOptions 
      : _barcelonaLivingArrangementOptions;
      
  List<String> get _relationshipOptions => _researchSite == 'wellbeing_mapper' 
      ? _siteRelationshipOptions 
      : _barcelonaRelationshipOptions;

  // ---------------------------------------------------------------------------
  // Localization helpers (see initial_survey_screen.dart for rationale).
  // Survey shows Italian when the app locale is Italian; stored answer values
  // remain canonical English so research data is language-stable.
  // ---------------------------------------------------------------------------

  bool get _isItalian => Localizations.localeOf(context).languageCode == 'it';

  String _t(String en, String it) => _isItalian ? it : en;

  static const Map<String, String> _itOptionLabels = {
    // Activities
    'Unemployed, looking for work': 'Disoccupato/a, in cerca di lavoro',
    'Unemployed but NOT looking for work': 'Disoccupato/a ma NON in cerca di lavoro',
    'Temporary/seasonal labour': 'Lavoro temporaneo/stagionale',
    'Part-time employed': 'Occupato/a part-time',
    'Full-time employed': 'Occupato/a a tempo pieno',
    'Self employed': 'Lavoratore/trice autonomo/a',
    'Skills development course (e.g. learnership)':
        'Corso di formazione professionale (es. apprendistato)',
    'Student': 'Studente/ssa',
    'Retired': 'In pensione',
    'Homemaker': 'Casalingo/a',
    'Caring for children/ill relatives': 'Cura di figli/parenti malati',
    'Volunteered': 'Volontariato',
    'Exercised': 'Attività fisica',
    'Vacation': 'Vacanza',
    'Other': 'Altro',
    // Living arrangement
    'alone': 'da solo/a',
    'others': 'con altri',
    // Relationship status
    'Single': 'Single',
    'In a committed relationship/married': 'In una relazione stabile/sposato/a',
    'Separated': 'Separato/a',
    'Divorced': 'Divorziato/a',
    'Widowed': 'Vedovo/a',
    // General health
    'Excellent': 'Eccellente',
    'Very good': 'Molto buona',
    'Good': 'Buona',
    'Fair': 'Discreta',
    'Poor': 'Scarsa',
  };

  String _optLabel(String value) =>
      _isItalian ? (_itOptionLabels[value] ?? value) : value;

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
            _t('Bi-weekly Wellbeing Survey', 'Questionario quindicinale sul benessere'),
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: Colors.green,
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
              _buildActivitiesSection(),
              SizedBox(height: 24),
              _buildLivingArrangementSection(),
              SizedBox(height: 24),
              _buildRelationshipSection(),
              SizedBox(height: 24),
              if (_researchSite == 'wellbeing_mapper') ...[
                _buildHealthSection(),
                SizedBox(height: 24),
              ],
              _buildWellbeingSection(),
              SizedBox(height: 24),
              _buildPersonalCharacteristicsSection(),
              SizedBox(height: 24),
              _buildDigitalDiarySection(),
              SizedBox(height: 24),
              _buildLocationSharingSection(),
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
              _t('Bi-weekly Wellbeing Check-in', 'Check-in quindicinale sul benessere'),
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              _t('Please take a few minutes to reflect on your wellbeing over the past two weeks.',
                  'Prenditi qualche minuto per riflettere sul tuo benessere nelle ultime due settimane.'),
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return _buildSectionCard(
      title: _researchSite == 'wellbeing_mapper' 
          ? _t('What did you do with your time in the last two weeks?',
              'Cosa hai fatto del tuo tempo nelle ultime due settimane?') 
          : _t('Current Activities', 'Attività attuali'),
      subtitle: _t('Mark ALL the choices that apply', 'Seleziona TUTTE le opzioni pertinenti'),
      child: FormBuilderCheckboxGroup<String>(
        name: 'activities',
        decoration: InputDecoration(border: InputBorder.none),
        options: _opts(_activityOptions),
        // validator: FormBuilderValidators.required(errorText: 'Please select at least one activity'), // Removed - now optional
      ),
    );
  }

  Widget _buildLivingArrangementSection() {
    return _buildSectionCard(
      title: _researchSite == 'wellbeing_mapper'
          ? _t('In the last two weeks, did you live alone or with others?',
              'Nelle ultime due settimane hai vissuto da solo/a o con altri?')
          : _t('Living Arrangement', 'Situazione abitativa'),
      child: FormBuilderRadioGroup<String>(
        name: 'livingArrangement',
        decoration: InputDecoration(border: InputBorder.none),
        options: _opts(_livingArrangementOptions),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildRelationshipSection() {
    return _buildSectionCard(
      title: _researchSite == 'wellbeing_mapper'
          ? _t('What is your current relationship status? (Select the single best option)',
              'Qual è il tuo stato sentimentale attuale? (Seleziona la sola opzione migliore)')
          : _t('Relationship Status', 'Stato sentimentale'),
      child: FormBuilderRadioGroup<String>(
        name: 'relationshipStatus',
        decoration: InputDecoration(border: InputBorder.none),
        options: _opts(_relationshipOptions),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
      ),
    );
  }

  Widget _buildHealthSection() {
    return _buildSectionCard(
      title: _t('General Health', 'Salute generale'),
      child: FormBuilderRadioGroup<String>(
        name: 'generalHealth',
        decoration: InputDecoration(border: InputBorder.none),
        options: _opts(const ['Excellent', 'Very good', 'Good', 'Fair', 'Poor']),
        // validator: FormBuilderValidators.required(errorText: 'Please select an option'), // Removed - now optional
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

  Widget _buildDigitalDiarySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _t('Digital Diary', 'Diario digitale'),
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            // First prompt as a wrapped paragraph
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
            
            // Second prompt as a slider question
            _buildRatingQuestion('challengesStressLevel', _t('How stressful were these environmental challenges for you?', 'Quanto sono state stressanti per te queste sfide ambientali?'), 1, 5),
            
            SizedBox(height: 20),
            
            // Third prompt as a wrapped paragraph
            Text(
              _researchSite == 'wellbeing_mapper'
                  ? _t('Who or what helped you to manage/cope with these environmental challenges?',
                      'Chi o cosa ti ha aiutato a gestire/affrontare queste sfide ambientali?')
                  : _t('What has helped you cope with these challenges?',
                      'Cosa ti ha aiutato ad affrontare queste sfide?'),
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
            
            SizedBox(height: 20),
            // TODO: Voice notes and photos sections temporarily disabled
            // _buildVoiceNotesSection(),
            // SizedBox(height: 16),
            // _buildImageSection(),
          ],
        ),
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
          Divider(),
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
                  SizedBox(height: 4),
                  Text(
                    '$min = ${min == 0 ? _t('Never', 'Mai') : _t('Not at all', 'Per niente')}, $max = ${max == 5 ? _t('All the time', 'Sempre') : _t('Completely', 'Completamente')}',
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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

  // TODO: Implement voice notes functionality
  /*
  Widget _buildVoiceNotesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice Notes (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Text(
          'Record voice notes to share additional thoughts or experiences about environmental challenges.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 12),
        
        // Display existing voice notes
        if (_voiceNoteFiles.isNotEmpty) ...[
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: _voiceNoteFiles.asMap().entries.map((entry) {
                final index = entry.key;
                final file = entry.value;
                final fileName = file.path.split('/').last;
                final isPlaying = _playingStates[file.path] ?? false;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.mic, color: Colors.blue[700]),
                  ),
                  title: Text('Voice Note ${index + 1}'),
                  subtitle: Text(fileName, style: TextStyle(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                        onPressed: () => _togglePlayback(file.path),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _removeVoiceNote(index),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 12),
        ],
        
        // Recording controls
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Column(
            children: [
              if (_isRecording) ...[
                Row(
                  children: [
                    Icon(Icons.fiber_manual_record, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Recording...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    Spacer(),
                    Text('Tap to stop', style: TextStyle(fontSize: 12)),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pauseResumeRecording,
                      icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                      label: Text(_isPaused ? 'Resume' : 'Pause'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                    ),
                    ElevatedButton.icon(
                      onPressed: _stopRecording,
                      icon: Icon(Icons.stop),
                      label: Text('Stop & Save'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    ),
                    ElevatedButton.icon(
                      onPressed: _cancelRecording,
                      icon: Icon(Icons.cancel),
                      label: Text('Cancel'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                    ),
                  ],
                ),
              ] else ...[
                ElevatedButton.icon(
                  onPressed: _startRecording,
                  icon: Icon(Icons.mic),
                  label: Text('Record Voice Note'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  */

  /*
  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Photos (Optional)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        SizedBox(height: 8),
        Text(
          'Add a photo that relates to your environmental experiences (max 1 photo).',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 12),
        if (_selectedImages.isNotEmpty) ...[
          Container(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: 12.0),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: InkWell(
                          onTap: () => _removeImage(index),
                          child: Container(
                            padding: EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.9),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 4,
                        left: 4,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 12),
          Text(
            '${_selectedImages.length}/1 photo selected',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
        ],
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _selectedImages.length >= 1 ? null : _selectFromGallery,
              icon: Icon(Icons.photo_library),
              label: Text('Add Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        if (_selectedImages.length >= 1)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Maximum of 1 photo reached.',
              style: TextStyle(fontSize: 12, color: Colors.orange[700]),
            ),
          ),
      ],
    );
  }
  */

  Widget _buildLocationSharingSection() {
    // Check if user is a research participant
    return FutureBuilder<bool>(
      future: _isResearchParticipant(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!) {
          return SizedBox.shrink(); // Don't show for non-research participants
        }

        return Card(
          margin: EdgeInsets.all(0),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: SouthAfricanTheme.primaryBlue),
                    SizedBox(width: 8),
                    Text(
                      _t('Location Data Sharing', 'Condivisione dei dati di posizione'),
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  _t('Choose how much location data to share with your survey responses:',
                      'Scegli quanti dati di posizione condividere insieme alle tue risposte:'),
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                
                // Status indicator
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _getLocationStatusText(),
                          style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16),
                
                // Sharing option buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _setLocationSharingOption(LocationSharingOption.fullData),
                        icon: Icon(
                          Icons.location_on, 
                          size: 18,
                          color: _locationSharingOption == LocationSharingOption.fullData 
                              ? Colors.white 
                              : Colors.grey[700],
                        ),
                        label: Text(_t('Share All', 'Condividi tutto'), style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _locationSharingOption == LocationSharingOption.fullData 
                              ? SouthAfricanTheme.primaryBlue 
                              : Colors.grey[300],
                          foregroundColor: _locationSharingOption == LocationSharingOption.fullData 
                              ? Colors.white 
                              : Colors.grey[700],
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _openLocationSelection,
                        icon: Icon(
                          Icons.edit_location, 
                          size: 18,
                          color: _locationSharingOption == LocationSharingOption.partialData 
                              ? Colors.white 
                              : Colors.grey[700],
                        ),
                        label: Text(_t('Select', 'Seleziona'), style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _locationSharingOption == LocationSharingOption.partialData 
                              ? SouthAfricanTheme.primaryBlue 
                              : Colors.grey[300],
                          foregroundColor: _locationSharingOption == LocationSharingOption.partialData 
                              ? Colors.white 
                              : Colors.grey[700],
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _setLocationSharingOption(LocationSharingOption.surveyOnly),
                        icon: Icon(
                          Icons.location_off, 
                          size: 18,
                          color: _locationSharingOption == LocationSharingOption.surveyOnly 
                              ? Colors.white 
                              : Colors.grey[700],
                        ),
                        label: Text(_t('None', 'Nessuno'), style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _locationSharingOption == LocationSharingOption.surveyOnly 
                              ? SouthAfricanTheme.primaryBlue 
                              : Colors.grey[300],
                          foregroundColor: _locationSharingOption == LocationSharingOption.surveyOnly 
                              ? Colors.white 
                              : Colors.grey[700],
                          padding: EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _isResearchParticipant() async {
    try {
      final db = SurveyDatabase();
      final consent = await db.getConsent();
      return consent != null;
    } catch (e) {
      return false;
    }
  }

  String _getLocationStatusText() {
    switch (_locationSharingOption) {
      case LocationSharingOption.fullData:
        if (_totalLocationCount > 0) {
          return _t('Sharing all $_totalLocationCount location records from the last 2 weeks',
              'Condivisione di tutti i $_totalLocationCount record di posizione delle ultime 2 settimane');
        }
        return _t('Sharing complete location data (analyzing available data...)',
            'Condivisione completa dei dati di posizione (analisi dei dati disponibili...)');
      case LocationSharingOption.partialData:
        final selectedCount = _totalLocationCount - _erasedLocationIndices.length;
        if (_totalLocationCount > 0 && _erasedLocationIndices.isNotEmpty) {
          return _t('Sharing $selectedCount of $_totalLocationCount location records (custom selection)',
              'Condivisione di $selectedCount su $_totalLocationCount record di posizione (selezione personalizzata)');
        } else if (_totalLocationCount > 0) {
          return _t('Sharing all $_totalLocationCount location records (no locations removed)',
              'Condivisione di tutti i $_totalLocationCount record di posizione (nessuna posizione rimossa)');
        }
        return _t('Custom location selection (open map to choose locations)',
            'Selezione personalizzata delle posizioni (apri la mappa per scegliere le posizioni)');
      case LocationSharingOption.surveyOnly:
        return _t('No location data will be shared - survey responses only',
            'Nessun dato di posizione verrà condiviso - solo le risposte al questionario');
    }
  }

  void _setLocationSharingOption(LocationSharingOption option) {
    setState(() {
      _locationSharingOption = option;
      if (option != LocationSharingOption.partialData) {
        _erasedLocationIndices.clear(); // Reset custom selection
      }
    });
  }

  Future<void> _openLocationSelection() async {
    // Load location data if not already loaded
    if (_recentLocationTracks.isEmpty) {
      await _loadLocationData();
    }

    if (_recentLocationTracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('No location data available for selection',
              'Nessun dato di posizione disponibile per la selezione')),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Show help dialog first
    final shouldProceed = await _showMapHelpDialog();
    if (!shouldProceed) {
      return;
    }

    // Get participant UUID from consent
    String participantUuid = '';
    try {
      final db = SurveyDatabase();
      final consent = await db.getConsent();
      participantUuid = consent?.participantUuid ?? '';
    } catch (e) {
      debugPrint('Error getting participant UUID: $e');
    }

    // Open the interactive map
    final result = await Navigator.of(context).push<Set<int>>(
      MaterialPageRoute(
        builder: (context) => InteractiveLocationPrivacyMap(
          locationTracks: _recentLocationTracks,
          participantUuid: participantUuid,
          isSelectionMode: true, // Enable selection mode
          onSelectionChanged: (Set<int> erasedIndices) {
            // Selection callback will be handled by the result
          },
          onConfirmSelection: () {
            // This callback is not used in selection mode
          },
          onCancel: () {
            Navigator.of(context).pop();
          },
          onUploadProceed: () {
            // Not needed for selection mode
          },
        ),
      ),
    );

    // Update the selection based on result
    if (result != null) {
      setState(() {
        _locationSharingOption = LocationSharingOption.partialData;
        _erasedLocationIndices = result;
      });
    }
  }

  Future<void> _loadLocationData() async {
    try {
      List<LocationTrack> locationTracks = [];
      
      if (!kIsWeb) {
        try {
          // Get location data from app database (same source as map)
          final db = SurveyDatabase();
          final allLocationTracks = await db.getAllLocationTracks();
          debugPrint('[RecurringSurvey] 🗃️ Found ${allLocationTracks.length} total location tracks in app database');
          
          // Filter for last 2 weeks for survey interaction
          final twoWeeksAgo = DateTime.now().subtract(Duration(days: 14));
          locationTracks = allLocationTracks.where((track) {
            return track.timestamp.isAfter(twoWeeksAgo);
          }).toList();
          
          debugPrint('[RecurringSurvey] 📍 Filtered to ${locationTracks.length} recent location tracks (last 2 weeks)');
        } catch (e) {
          debugPrint('[RecurringSurvey] ❌ Error getting location data from app database: $e');
        }
      }
      
      setState(() {
        _recentLocationTracks = locationTracks;
        _totalLocationCount = locationTracks.length;
      });
    } catch (e) {
      debugPrint('[RecurringSurvey] ❌ Error loading location data: $e');
    }
  }

  Future<bool> _showMapHelpDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            _t('Location Selection Guide', 'Guida alla selezione delle posizioni'),
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('You can choose exactly which locations to share:',
                      'Puoi scegliere esattamente quali posizioni condividere:'),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 16),
                
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.remove, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t('Remove Mode: Tap or drag to exclude locations from sharing',
                            'Modalità Rimuovi: tocca o trascina per escludere le posizioni dalla condivisione'),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t('Restore Mode: Tap or drag to restore locations for sharing',
                            'Modalità Ripristina: tocca o trascina per ripristinare le posizioni da condividere'),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[600],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(Icons.navigation, color: Colors.white, size: 20),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _t('Navigate Mode: Pan, zoom, and explore the map freely',
                            'Modalità Naviga: sposta, ingrandisci ed esplora liberamente la mappa'),
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                Text(
                  _t('When done, tap Submit to return to the survey form.',
                      'Al termine, tocca Invia per tornare al modulo del questionario.'),
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(_t('Cancel', 'Annulla')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: SouthAfricanTheme.primaryBlue,
              ),
              child: Text(
                _t('Got It!', 'Ho capito!'),
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    ) ?? false;
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
        onPressed: _isSubmitting ? null : _submitSurveyWithLocationSharing,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          padding: EdgeInsets.symmetric(vertical: 16),
        ),
        child: _isSubmitting
            ? CircularProgressIndicator(color: Colors.white)
            : Text(
                _t('Submit Survey', 'Invia questionario'),
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
      ),
    );
  }

  // Voice recording methods
  /*
  Future<void> _startRecording() async {
    try {
      // For now, show a placeholder dialog since we need to add the recording packages
      await _showRecordingDialog();
    } catch (e) {
      _showErrorDialog('Failed to start recording: $e');
    }
  }
  */

  /*
  Future<void> _showRecordingDialog() async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.mic, color: Colors.red),
            SizedBox(width: 8),
            Text('Voice Recording'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Voice recording functionality is being implemented.'),
            SizedBox(height: 16),
            Text('For now, you can use the text fields to describe your environmental experiences.'),
            SizedBox(height: 16),
            LinearProgressIndicator(),
            SizedBox(height: 8),
            Text('Recording simulation...', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _simulateVoiceNote();
            },
            child: Text('Add Sample Voice Note'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _simulateVoiceNote() {
    // Add a simulated voice note for testing
    final now = DateTime.now();
    final fileName = 'voice_note_${now.millisecondsSinceEpoch}.m4a';
    
    setState(() {
      // Create a temporary file reference (in real implementation, this would be the actual recording)
      final tempFile = File('/tmp/$fileName'); // This won't actually exist, just for UI testing
      _voiceNoteFiles.add(tempFile);
      _voiceNoteUrls.add(tempFile.path);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sample voice note added (actual recording will be implemented)'),
        backgroundColor: Colors.green,
      ),
    );
  }
  */

  /*
  Future<void> _pauseResumeRecording() async {
    setState(() {
      _isPaused = !_isPaused;
    });
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
    
    // In real implementation, save the recording file here
    _simulateVoiceNote();
  }

  Future<void> _cancelRecording() async {
    setState(() {
      _isRecording = false;
      _isPaused = false;
    });
  }
  */

  /*
  void _togglePlayback(String filePath) {
    setState(() {
      final isCurrentlyPlaying = _playingStates[filePath] ?? false;
      
      // Stop all other playbacks
      _playingStates.clear();
      
      // Toggle this one
      _playingStates[filePath] = !isCurrentlyPlaying;
    });

    // In real implementation, use audioplayers package to play/pause
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_playingStates[filePath]! ? 'Playing voice note...' : 'Stopped playback'),
        duration: Duration(seconds: 1),
      ),
    );

    // Simulate playback finishing after 3 seconds
    if (_playingStates[filePath]!) {
      Future.delayed(Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _playingStates[filePath] = false;
          });
        }
      });
    }
  }
  */

  /*
  void _removeVoiceNote(dynamic indexOrUrl) {
    if (indexOrUrl is int) {
      // Remove by index
      setState(() {
        if (indexOrUrl < _voiceNoteFiles.length) {
          final file = _voiceNoteFiles[indexOrUrl];
          _voiceNoteFiles.removeAt(indexOrUrl);
          _voiceNoteUrls.remove(file.path);
          _playingStates.remove(file.path);
        }
      });
    } else if (indexOrUrl is String) {
      // Remove by URL (legacy support)
      final index = _voiceNoteUrls.indexOf(indexOrUrl);
      if (index != -1) {
        _removeVoiceNote(index);
      }
    }
  }
  */

  /*
  void _takePhoto() async {
    try {
      // Request camera permission first
      PermissionStatus cameraStatus = await Permission.camera.request();
      
      if (cameraStatus != PermissionStatus.granted) {
        _showErrorDialog(
          'Camera permission is required to take photos. Please grant camera permission in your device settings and try again.'
        );
        return;
      }

      // If we're on Android, also check storage permissions
      if (Platform.isAndroid) {
        PermissionStatus storageStatus = await Permission.storage.request();
        if (storageStatus != PermissionStatus.granted) {
          _showErrorDialog(
            'Storage permission is required to save photos. Please grant storage permission in your device settings and try again.'
          );
          return;
        }
      }

      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (photo != null) {
        setState(() {
          _selectedImages.add(File(photo.path));
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to take photo: $e');
    }
  }

  void _selectFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images.map((image) => File(image.path)));
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to select images: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }
  */

  Future<void> _submitSurveyWithLocationSharing() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Save the regular survey data
      await _submitSurveyData();

      // Check if user is a research participant
      final isResearchParticipant = await _isResearchParticipant();
      
      if (isResearchParticipant && _locationSharingOption != LocationSharingOption.surveyOnly) {
        await _saveLocationSharingConsent();
      }

      // Check app mode to determine what kind of success message to show
      final currentMode = await AppModeService.getCurrentMode();
      
      if (currentMode == AppMode.appTesting) {
        // Beta testing mode - show mock success
        _showBetaTestingSuccessMessage();
      } else if (isResearchParticipant) {
        // Research participant - show research success with upload option
        _showResearchParticipantSuccessMessage();
      } else {
        // Regular user - show simple success
        _showRegularUserSuccessMessage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t('Error saving survey: ', 'Errore nel salvataggio del questionario: ') + '$e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _saveLocationSharingConsent() async {
    try {
      // Get participant UUID from consent
      final db = SurveyDatabase();
      final consent = await db.getConsent();
      final participantUuid = consent?.participantUuid ?? '';

      if (participantUuid.isEmpty) {
        throw Exception('No participant UUID found');
      }

      // Create location cluster IDs based on sharing option
      List<String> customLocationIds = [];
      
      if (_locationSharingOption == LocationSharingOption.partialData) {
        // Get the selected location tracks (those not erased)
        final selectedTracks = _recentLocationTracks
            .asMap()
            .entries
            .where((entry) => !_erasedLocationIndices.contains(entry.key))
            .map((entry) => entry.value)
            .toList();
        
        for (int i = 0; i < selectedTracks.length; i++) {
          customLocationIds.add('track_${i}');
        }
      }

      // Save location sharing consent
      final locationConsent = DataSharingConsent(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        locationSharingOption: _locationSharingOption,
        decisionTimestamp: DateTime.now(),
        participantUuid: participantUuid,
        customLocationIds: customLocationIds,
      );

      await db.insertDataSharingConsent(locationConsent);
    } catch (e) {
      debugPrint('Error saving location sharing consent: $e');
      throw e;
    }
  }

  Future<void> _submitSurveyData() async {
    // Extract survey data and save it
    final formData = _formKey.currentState!.value;
    final submissionTime = DateTime.now();
    
    // Collect location data for inclusion in survey JSON
    Map<String, dynamic>? locationDataMap;
    
    try {
      // Collect location data based on user's sharing preference
      if (_locationSharingOption != LocationSharingOption.surveyOnly && !kIsWeb) {
        debugPrint('[RecurringSurvey] Collecting location data for survey...');
        
        // Get filtered location tracks based on user's erasure preferences
        List<LocationTrack> locationsToShare = [];
        
        for (int i = 0; i < _recentLocationTracks.length; i++) {
          if (!_erasedLocationIndices.contains(i)) {
            locationsToShare.add(_recentLocationTracks[i]);
          }
        }
        
        if (locationsToShare.isNotEmpty) {
          // Include location data directly in survey JSON (no separate encryption)
          locationDataMap = {
            'locations': locationsToShare.map((loc) => loc.toJson()).toList(),
            'sharing_option': _locationSharingOption.toString(),
            'total_locations_available': _totalLocationCount,
            'user_erased_count': _erasedLocationIndices.length,
            'locations_shared_count': locationsToShare.length,
            'collection_period_days': 14,
            'submitted_at': submissionTime.toIso8601String(),
          };
          
          debugPrint('[RecurringSurvey] Prepared ${locationsToShare.length} location points for survey');
        } else {
          debugPrint('[RecurringSurvey] No location data to share (user removed all locations)');
        }
      } else {
        debugPrint('[RecurringSurvey] Location sharing disabled by user or web platform');
      }
    } catch (e) {
      debugPrint('[RecurringSurvey] Error collecting location data: $e');
      locationDataMap = null;
    }
      
    final surveyResponse = RecurringSurveyResponse(
      activities: List<String>.from(formData['activities'] ?? []),
      livingArrangement: formData['livingArrangement'],
      relationshipStatus: formData['relationshipStatus'],
      generalHealth: formData['generalHealth'],
      cheerfulSpirits: formData['cheerfulSpirits']?.round(),
      calmRelaxed: formData['calmRelaxed']?.round(),
      activeVigorous: formData['activeVigorous']?.round(),
      wokeUpFresh: formData['wokeUpFresh']?.round(),
      dailyLifeInteresting: formData['dailyLifeInteresting']?.round(),
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
      environmentalChallenges: formData['environmentalChallenges'],
      challengesStressLevel: formData['challengesStressLevel'] != null ? formData['challengesStressLevel'].round().toString() : null,
      copingHelp: formData['copingHelp'],
      // TODO: MULTIMEDIA ENCRYPTION - Images are stored locally, encryption to be implemented
      // voiceNoteUrls: null, // Voice notes not implemented yet
      imageUrls: null, // Photo functionality removed
      researchSite: _researchSite,
      submittedAt: submissionTime,
      encryptedLocationData: locationDataMap != null ? jsonEncode(locationDataMap) : null, // Store as JSON for unified encryption
    );

    final db = SurveyDatabase();
    await db.insertRecurringSurvey(surveyResponse);
    
    // SECURITY: API sync disabled - using secure web-based submission instead
    // The web-based survey approach is more secure as it doesn't expose API tokens
    debugPrint('✅ Biweekly survey saved locally. Participants will complete web survey for secure submission.');
    
    // Note: API sync removed for security - web surveys provide secure data collection
    // without exposing API tokens that could compromise all participant data
  }

  void _showBetaTestingSuccessMessage() {
    setState(() {
      _isSubmitting = false;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_t('Survey Submitted!', 'Questionario inviato!')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_t('Thank you for completing the wellbeing survey. Your responses have been saved locally.',
                  'Grazie per aver completato il questionario sul benessere. Le tue risposte sono state salvate localmente.')),
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
                      _t('🧪 Beta Testing Mode', '🧪 Modalità beta testing'),
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _t('Your data is stored locally for testing purposes. No data was transmitted to research servers.',
                          'I tuoi dati sono salvati localmente a scopo di test. Nessun dato è stato trasmesso ai server di ricerca.'),
                      style: TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false); // Go directly to home screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showResearchParticipantSuccessMessage() {
    setState(() {
      _isSubmitting = false;
    });
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(_t('Survey Submitted!', 'Questionario inviato!')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_t('Thank you for completing the wellbeing survey. Your responses and location preferences have been saved.',
                'Grazie per aver completato il questionario sul benessere. Le tue risposte e le preferenze di posizione sono state salvate.')),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _t('Research Participation', 'Partecipazione alla ricerca'),
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue[700]),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _t('Your data will be securely uploaded to research servers. This helps contribute to scientific research while protecting your privacy.',
                        'I tuoi dati saranno caricati in modo sicuro sui server di ricerca. Questo contribuisce alla ricerca scientifica proteggendo al contempo la tua privacy.'),
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false); // Go directly to home screen
              _uploadDataToResearchServer(); // Upload data in background
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRegularUserSuccessMessage() {
    setState(() {
      _isSubmitting = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('Survey submitted successfully!', 'Questionario inviato con successo!')),
        backgroundColor: Colors.green,
      ),
    );
    
    // Navigate directly to home screen
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  Future<void> _uploadDataToResearchServer() async {
    try {
      final participantUuid = _getParticipantUuid();
      
      if (participantUuid == null || participantUuid.isEmpty) {
        // Show error - user already navigated back so show in context of main app
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Missing participant information - data saved locally only'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Try to upload in background - user already navigated away
      try {
        debugPrint('[RecurringSurveyScreen] 🚀 Starting background upload...');
        
        // Use the same encrypted survey service as consent and initial surveys
        await ResearchServerService.syncPendingSurveys();
        
        debugPrint('[RecurringSurveyScreen] ✅ Background upload completed successfully!');
        
        // Show success notification using global service
        GlobalNotificationService.showSuccess('✅ Research data uploaded successfully!');
        
      } catch (uploadError) {
        debugPrint('[RecurringSurveyScreen] ❌ Background upload failed: $uploadError');
        
        // Show error notification using global service
        GlobalNotificationService.showWarning('Upload failed - data saved locally for retry');
      }
    } catch (e) {
      // Show error if still mounted
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload error: $e - data saved locally'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String? _getParticipantUuid() {
    return GlobalData.userUUID.isEmpty ? null : GlobalData.userUUID;
  }

  /// Build the image upload section for the digital diary
  // Photo functionality removed for production reliability

  /*
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
  */
}
