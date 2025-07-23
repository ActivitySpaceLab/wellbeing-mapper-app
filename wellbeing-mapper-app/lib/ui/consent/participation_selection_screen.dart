import 'package:flutter/material.dart';
import 'package:wellbeing_mapper/models/consent_models.dart';
import 'package:wellbeing_mapper/ui/consent/consent_form_screen.dart';
import 'package:wellbeing_mapper/ui/initial_survey_screen.dart';
import 'package:wellbeing_mapper/services/consent_service.dart';

class ParticipationSelectionScreen extends StatefulWidget {
  @override
  _ParticipationSelectionScreenState createState() => _ParticipationSelectionScreenState();
}

class _ParticipationSelectionScreenState extends State<ParticipationSelectionScreen> {
  final TextEditingController _participantCodeController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _participantCodeController.dispose();
    super.dispose();
  }

  Future<void> _selectPrivateUse() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Create private user settings
      ParticipationSettings settings = ParticipationSettings.privateUser();
      await ConsentService.saveParticipationSettings(settings);
      
      // Navigate to initial survey
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => InitialSurveyScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting up private use: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _joinResearch() async {
    final String participantCode = _participantCodeController.text.trim();
    
    if (participantCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter your participant code')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create research participant settings
      ParticipationSettings settings = ParticipationSettings.researchParticipant(participantCode);
      await ConsentService.saveParticipationSettings(settings);
      
      // Navigate to consent form
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ConsentFormScreen(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error setting up research participation: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wellbeing Mapper'),
        centerTitle: true,
        backgroundColor: Colors.blueGrey,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 40), // Top spacing
                    Icon(
                      Icons.map,
                      size: 80,
                      color: Colors.blueGrey,
                    ),
                    SizedBox(height: 32),
                    Text(
                      'Welcome to Wellbeing Mapper',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blueGrey[800],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Track your wellbeing and explore your activity spaces',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 48),
                  
                  // Private Use Section
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Personal Use',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Use the app for your personal wellbeing tracking. Your data stays on your device and is not shared.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _selectPrivateUse,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Use Privately'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Research Participation Section
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.school, color: Colors.blue),
                              SizedBox(width: 8),
                              Text(
                                'Join Research',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 12),
                          Text(
                            'Participate in our research study. You\'ll need a participant code provided by the research team.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _participantCodeController,
                            decoration: InputDecoration(
                              labelText: 'Participant Code',
                              hintText: 'Enter your code here',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.code),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _joinResearch,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text('Join Research Study'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 32),
                  Text(
                    'You can change this choice later in the app settings.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                    SizedBox(height: 40), // Bottom spacing
                  ],
                ),
              ),
            ),
    );
  }
}
