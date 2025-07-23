import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:wellbeing_mapper/models/consent_models.dart';
import 'package:wellbeing_mapper/services/consent_service.dart';
import 'package:wellbeing_mapper/ui/initial_survey_screen.dart';

class ConsentFormScreen extends StatefulWidget {
  @override
  _ConsentFormScreenState createState() => _ConsentFormScreenState();
}

class _ConsentFormScreenState extends State<ConsentFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isLoading = false;

  Future<void> _submitConsent() async {
    if (!_formKey.currentState!.saveAndValidate()) {
      return;
    }

    final formData = _formKey.currentState!.value;

    // Check that all required consents are given
    final requiredConsents = [
      'informedConsent',
      'dataProcessing',
      'locationData',
      'surveyData',
      'dataRetention',
      'dataSharing',
      'voluntaryParticipation',
    ];

    for (String consent in requiredConsents) {
      if (formData[consent] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All consent items must be agreed to participate in the research.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final consentResponse = ConsentResponse(
        participantUuid: DateTime.now().millisecondsSinceEpoch.toString(),
        informedConsent: formData['informedConsent'] ?? false,
        dataProcessing: formData['dataProcessing'] ?? false,
        locationData: formData['locationData'] ?? false,
        surveyData: formData['surveyData'] ?? false,
        dataRetention: formData['dataRetention'] ?? false,
        dataSharing: formData['dataSharing'] ?? false,
        voluntaryParticipation: formData['voluntaryParticipation'] ?? false,
        consentedAt: DateTime.now(),
        participantSignature: formData['participantName']?.toString() ?? '',
      );

      await ConsentService.saveConsentResponse(consentResponse);

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => InitialSurveyScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving consent: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildConsentItem({
    required String name,
    required String title,
    required String description,
  }) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 12),
            FormBuilderCheckbox(
              name: name,
              title: Text('I consent to this'),
              validator: FormBuilderValidators.equal(
                true,
                errorText: 'This consent is required to participate.',
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Research Consent Form'),
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : FormBuilder(
              key: _formKey,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue),
                                SizedBox(width: 8),
                                Text(
                                  'Barcelona Wellbeing Study',
                                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[800],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              'You are being invited to participate in a research study exploring the relationship between urban environments and personal wellbeing. This study is conducted by researchers at the University of Barcelona.',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Please read each consent item carefully and confirm your agreement by checking the box below each section.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    SizedBox(height: 24),

                    _buildConsentItem(
                      name: 'informedConsent',
                      title: 'Informed Consent',
                      description: 'I understand that my participation in this research is voluntary and that I am free to withdraw at any time without giving any reason and without any negative consequences. I understand the nature of the study and agree to participate.',
                    ),

                    _buildConsentItem(
                      name: 'dataProcessing',
                      title: 'Data Processing',
                      description: 'I consent to the processing of my personal data for the purposes of this research study. I understand that data will be processed in accordance with applicable data protection laws and regulations.',
                    ),

                    _buildConsentItem(
                      name: 'locationData',
                      title: 'Location Data Collection',
                      description: 'I consent to the collection of my location data through GPS tracking for the duration of the study. I understand this data will be used to understand my movement patterns and activity spaces.',
                    ),

                    _buildConsentItem(
                      name: 'surveyData',
                      title: 'Survey Data Collection',
                      description: 'I consent to providing survey responses about my wellbeing, demographics, and experiences in urban environments. I understand these surveys may include questions about my mood, activities, and perceptions.',
                    ),

                    _buildConsentItem(
                      name: 'dataRetention',
                      title: 'Data Retention',
                      description: 'I understand that my data will be stored securely for up to 5 years after the completion of the study for research and potential follow-up analyses, after which it will be permanently deleted.',
                    ),

                    _buildConsentItem(
                      name: 'dataSharing',
                      title: 'Data Sharing for Research',
                      description: 'I consent to my anonymized data being shared with other researchers and potentially made available in anonymized research datasets, provided that no personally identifiable information is included.',
                    ),

                    _buildConsentItem(
                      name: 'voluntaryParticipation',
                      title: 'Voluntary Participation',
                      description: 'I confirm that I am participating in this study voluntarily and that I have been given adequate time to consider my participation. I understand I can contact the research team with any questions or concerns.',
                    ),

                    SizedBox(height: 24),

                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Participant Information',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 12),
                            FormBuilderTextField(
                              name: 'participantName',
                              decoration: InputDecoration(
                                labelText: 'Your Full Name',
                                hintText: 'Enter your full name as signature',
                                border: OutlineInputBorder(),
                              ),
                              validator: FormBuilderValidators.required(
                                errorText: 'Please enter your full name',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 24),

                    Card(
                      color: Colors.green[50],
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(Icons.security, color: Colors.green[700], size: 32),
                            SizedBox(height: 8),
                            Text(
                              'Your Privacy is Protected',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green[800],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'All data is encrypted and stored securely. You can withdraw from the study at any time, and your data will be deleted upon request.',
                              style: Theme.of(context).textTheme.bodyMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: Text('Cancel'),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: _submitConsent,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 16),
                            ),
                            child: Text('I Consent to Participate'),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16),

                    Text(
                      'By clicking "I Consent to Participate", you confirm that you have read, understood, and agree to all the terms above.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
