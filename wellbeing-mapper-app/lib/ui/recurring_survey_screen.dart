import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/survey_models.dart';
import '../db/survey_database.dart';

class RecurringSurveyScreen extends StatefulWidget {
  @override
  _RecurringSurveyScreenState createState() => _RecurringSurveyScreenState();
}

class _RecurringSurveyScreenState extends State<RecurringSurveyScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isSubmitting = false;
  List<File> _selectedImages = [];
  List<String> _voiceNoteUrls = [];
  final ImagePicker _picker = ImagePicker();

  final List<String> _activityOptions = [
    'Employed',
    'Unemployed',
    'Student',
    'Homemaker',
    'Retired',
    'Unable to work',
    'Other'
  ];

  final List<String> _livingArrangementOptions = [
    'Living alone',
    'Living with family',
    'Living with friends/roommates',
    'Living with partner/spouse',
    'Other'
  ];

  final List<String> _relationshipOptions = [
    'Single',
    'In a relationship',
    'Married',
    'Divorced',
    'Widowed',
    'Prefer not to say'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bi-weekly Wellbeing Survey'),
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
              _buildWellbeingSection(),
              SizedBox(height: 24),
              _buildPersonalCharacteristicsSection(),
              SizedBox(height: 24),
              _buildDigitalDiarySection(),
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
              'Bi-weekly Wellbeing Check-in',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Please take a few minutes to reflect on your wellbeing over the past two weeks.',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitiesSection() {
    return _buildSectionCard(
      title: 'Current Activities',
      subtitle: 'Select all that apply',
      child: FormBuilderCheckboxGroup<String>(
        name: 'activities',
        decoration: InputDecoration(border: InputBorder.none),
        options: _activityOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        validator: FormBuilderValidators.required(errorText: 'Please select at least one activity'),
      ),
    );
  }

  Widget _buildLivingArrangementSection() {
    return _buildSectionCard(
      title: 'Living Arrangement',
      child: FormBuilderRadioGroup<String>(
        name: 'livingArrangement',
        decoration: InputDecoration(border: InputBorder.none),
        options: _livingArrangementOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        validator: FormBuilderValidators.required(errorText: 'Please select an option'),
      ),
    );
  }

  Widget _buildRelationshipSection() {
    return _buildSectionCard(
      title: 'Relationship Status',
      child: FormBuilderRadioGroup<String>(
        name: 'relationshipStatus',
        decoration: InputDecoration(border: InputBorder.none),
        options: _relationshipOptions.map((option) => 
          FormBuilderFieldOption(value: option, child: Text(option))
        ).toList(),
        validator: FormBuilderValidators.required(errorText: 'Please select an option'),
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

  Widget _buildDigitalDiarySection() {
    return _buildSectionCard(
      title: 'Digital Diary',
      subtitle: 'Please share your thoughts and experiences',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextQuestion(
            'environmentalChallenges',
            'What environmental challenges have you faced in the past two weeks? (e.g., extreme weather, air pollution, noise)',
          ),
          SizedBox(height: 16),
          _buildTextQuestion(
            'challengesStressLevel',
            'How would you rate the stress level of these challenges? Please explain.',
          ),
          SizedBox(height: 16),
          _buildTextQuestion(
            'copingHelp',
            'What has helped you cope with these challenges?',
          ),
          SizedBox(height: 16),
          _buildVoiceNotesSection(),
          SizedBox(height: 16),
          _buildImageSection(),
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
          Text(question, style: TextStyle(fontSize: 16)),
          SizedBox(height: 8),
          FormBuilderSlider(
            name: name,
            min: min.toDouble(),
            max: max.toDouble(),
            initialValue: min.toDouble(),
            divisions: max - min,
            decoration: InputDecoration(
              border: InputBorder.none,
              helperText: '$min = ${min == 0 ? 'Never' : 'Not at all'}, $max = ${max == 5 ? 'All the time' : 'Completely'}',
            ),
          ),
          Divider(),
        ],
      ),
    );
  }

  Widget _buildTextQuestion(String name, String question) {
    return FormBuilderTextField(
      name: name,
      decoration: InputDecoration(
        labelText: question,
        border: OutlineInputBorder(),
        alignLabelWithHint: true,
      ),
      maxLines: 3,
      minLines: 2,
    );
  }

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
          'Record voice notes to share additional thoughts or experiences.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 12),
        if (_voiceNoteUrls.isNotEmpty) ...[
          ...(_voiceNoteUrls.map((url) => ListTile(
            leading: Icon(Icons.mic),
            title: Text('Voice Note ${_voiceNoteUrls.indexOf(url) + 1}'),
            trailing: IconButton(
              icon: Icon(Icons.delete),
              onPressed: () => _removeVoiceNote(url),
            ),
          ))),
          SizedBox(height: 8),
        ],
        ElevatedButton.icon(
          onPressed: _recordVoiceNote,
          icon: Icon(Icons.mic),
          label: Text('Record Voice Note'),
        ),
      ],
    );
  }

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
          'Add photos that relate to your environmental experiences.',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
        SizedBox(height: 12),
        if (_selectedImages.isNotEmpty) ...[
          Container(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: EdgeInsets.only(right: 8.0),
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
                            padding: EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.close, color: Colors.white, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 8),
        ],
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: Icon(Icons.camera_alt),
              label: Text('Take Photo'),
            ),
            SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _selectFromGallery,
              icon: Icon(Icons.photo_library),
              label: Text('Gallery'),
            ),
          ],
        ),
      ],
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
          backgroundColor: Colors.green,
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

  void _recordVoiceNote() async {
    // TODO: Implement voice recording functionality
    // This would use a package like flutter_sound or record
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Voice Recording'),
        content: Text('Voice recording functionality will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _removeVoiceNote(String url) {
    setState(() {
      _voiceNoteUrls.remove(url);
    });
  }

  void _takePhoto() async {
    try {
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

  void _submitSurvey() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final formData = _formKey.currentState!.value;
        
        final surveyResponse = RecurringSurveyResponse(
          activities: List<String>.from(formData['activities'] ?? []),
          livingArrangement: formData['livingArrangement'],
          relationshipStatus: formData['relationshipStatus'],
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
          challengesStressLevel: formData['challengesStressLevel'],
          copingHelp: formData['copingHelp'],
          voiceNoteUrls: _voiceNoteUrls.isNotEmpty ? _voiceNoteUrls : null,
          imageUrls: _selectedImages.isNotEmpty ? _selectedImages.map((f) => f.path).toList() : null,
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

  Future<void> _saveSurveyResponse(RecurringSurveyResponse response) async {
    try {
      final db = SurveyDatabase();
      await db.insertRecurringSurvey(response);
      print('Recurring survey saved to local database');
    } catch (e) {
      print('Error saving recurring survey: $e');
      rethrow;
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Survey Submitted!'),
        content: Text('Thank you for completing the wellbeing survey. Your responses have been saved.'),
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
