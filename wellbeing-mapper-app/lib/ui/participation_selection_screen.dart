import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/consent_models.dart';

class ParticipationSelectionScreen extends StatefulWidget {
  @override
  _ParticipationSelectionScreenState createState() => _ParticipationSelectionScreenState();
}

class _ParticipationSelectionScreenState extends State<ParticipationSelectionScreen> {
  final _participantCodeController = TextEditingController();
  String _selectedMode = 'private'; // 'private', 'barcelona', 'gauteng'
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome to Wellbeing Mapper'),
        backgroundColor: Colors.blue,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeSection(),
            SizedBox(height: 32),
            _buildChoiceSection(),
            if (_selectedMode != 'private') ...[
              SizedBox(height: 24),
              _buildParticipantCodeSection(),
            ],
            SizedBox(height: 32),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20.0),
        child: Column(
          children: [
            Icon(Icons.favorite, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text(
              'Wellbeing Mapper',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold), // Reduced font size
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 8),
            Text(
              'A privacy-focused app for mapping your mental wellbeing',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]), // Reduced font size
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChoiceSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How would you like to use this app?',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 16),
        Card(
          child: RadioListTile<String>(
            value: 'private',
            groupValue: _selectedMode,
            onChanged: (value) {
              setState(() {
                _selectedMode = value!;
              });
            },
            title: Text('Personal Use Only'),
            subtitle: Text('Use the app privately for your own wellbeing tracking. No data will be shared.'),
            secondary: Icon(Icons.lock, color: Colors.green),
          ),
        ),
        SizedBox(height: 8),
        Card(
          child: RadioListTile<String>(
            value: 'barcelona',
            groupValue: _selectedMode,
            onChanged: (value) {
              setState(() {
                _selectedMode = value!;
              });
            },
            title: Text('Barcelona Research Study'),
            subtitle: Text('Participate in the PLANET4HEALTH research study in Barcelona, Spain. Requires participant code and consent.'),
            secondary: Icon(Icons.school, color: Colors.blue),
          ),
        ),
        SizedBox(height: 8),
        Card(
          child: RadioListTile<String>(
            value: 'gauteng',
            groupValue: _selectedMode,
            onChanged: (value) {
              setState(() {
                _selectedMode = value!;
              });
            },
            title: Text('Gauteng Research Study'),
            subtitle: Text('Participate in the PLANET4HEALTH research study in Gauteng, South Africa. Requires participant code and consent.'),
            secondary: Icon(Icons.school, color: Colors.orange),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantCodeSection() {
    String studySite = _selectedMode == 'barcelona' ? 'Barcelona, Spain' : 'Gauteng, South Africa';
    String exampleCode = _selectedMode == 'barcelona' ? 'BCN2024-001' : 'GP2024-001';
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Research Participation - $studySite',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Enter the participant code provided by the research team:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 12),
            TextField(
              controller: _participantCodeController,
              decoration: InputDecoration(
                labelText: 'Participant Code',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.vpn_key),
                hintText: 'e.g., $exampleCode',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your participant code was provided when you were recruited for the study. If you don\'t have a code, please contact the research team.',
                      style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedMode == 'private' ? Colors.green : 
                              _selectedMode == 'barcelona' ? Colors.blue : Colors.orange,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    _selectedMode == 'private' ? 'Start Using App' : 'Continue to Consent Form',
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ),
        SizedBox(height: 12),
        TextButton(
          onPressed: _showContactInfo,
          child: Text('Contact Research Team'),
        ),
      ],
    );
  }

  void _handleContinue() async {
    if (_selectedMode != 'private') {
      // Research participation flow
      if (_participantCodeController.text.trim().isEmpty) {
        _showErrorDialog('Please enter your participant code');
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Navigate to consent form with research site info
        final result = await Navigator.of(context).pushNamed(
          '/consent_form',
          arguments: {
            'participantCode': _participantCodeController.text.trim().toUpperCase(),
            'researchSite': _selectedMode,
          },
        );

        if (result == true) {
          // Consent completed, go to main app
          _navigateToMainApp();
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      // Private use flow
      await _savePrivateUserSettings();
      _navigateToMainApp();
    }
  }

  Future<void> _savePrivateUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = ParticipationSettings.privateUser();
    await prefs.setString('participation_settings', jsonEncode(settings.toJson()));
  }

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  void _showContactInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Contact Research Team'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Principal Investigators:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('• John Palmer: john.palmer@upf.edu'),
            Text('• Linda Theron: linda.theron@up.ac.za'),
            Text('• Caradee Wright: Caradee.Wright@mrc.ac.za'),
            SizedBox(height: 16),
            Text('Ethics Committee:', style: TextStyle(fontWeight: FontWeight.bold)),
            Text('Phone: +34 93 542 21 86'),
            Text('Email: secretaria.cirep@upf.edu'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close'),
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

  @override
  void dispose() {
    _participantCodeController.dispose();
    super.dispose();
  }
}
