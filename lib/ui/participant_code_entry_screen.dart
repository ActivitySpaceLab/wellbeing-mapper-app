import 'package:flutter/material.dart';
import 'package:wellbeing_mapper/services/participant_validation_service.dart';
import 'package:wellbeing_mapper/theme/south_african_theme.dart';

class ParticipantCodeEntryScreen extends StatefulWidget {
  final String researchSite;

  const ParticipantCodeEntryScreen({
    Key? key,
    this.researchSite = 'gauteng',
  }) : super(key: key);

  @override
  _ParticipantCodeEntryScreenState createState() => _ParticipantCodeEntryScreenState();
}

class _ParticipantCodeEntryScreenState extends State<ParticipantCodeEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Research Participation'),
        backgroundColor: SouthAfricanTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header section
                Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: SouthAfricanTheme.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SouthAfricanTheme.primaryGreen.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 48,
                        color: SouthAfricanTheme.primaryGreen,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Research Participant Access',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: SouthAfricanTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please enter your participant code to access research mode',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Participant code input
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Participant Code',
                    hintText: 'Enter your unique participant code',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _errorMessage,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter your participant code';
                    }
                    if (value.trim().length < 3) {
                      return 'Participant code must be at least 3 characters';
                    }
                    return null;
                  },
                  onChanged: (value) {
                    if (_errorMessage != null) {
                      setState(() {
                        _errorMessage = null;
                      });
                    }
                  },
                ),
                
                SizedBox(height: 24),
                
                // Validation button
                ElevatedButton(
                  onPressed: _isLoading ? null : _validateCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: SouthAfricanTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text('Validating...'),
                          ],
                        )
                      : Text(
                          'Validate Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                
                SizedBox(height: 32),
                
                // Information section
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.blue.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Information',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• Your participant code was provided by the research team\n'
                        '• Codes are case-insensitive\n'
                        '• Once validated, you won\'t need to enter it again\n'
                        '• Contact the research team if you have issues',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Contact information
                Text(
                  'Need help? Contact the research team at\nresearch@gauteng-wellbeing.org',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 16), // Add some bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _validateCode() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ParticipantValidationService.validateParticipantCode(
        _codeController.text.trim(),
      );

      if (result.isValid) {
        // Validation successful - proceed to consent form
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/consent_form',
            arguments: {
              'participantCode': _codeController.text.trim().toUpperCase(),
              'researchSite': widget.researchSite,
              'isTestingMode': false,
            },
          );
        }
      } else {
        // Validation failed - show error
        setState(() {
          _errorMessage = result.error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      print('[ParticipantCodeEntry] Error validating code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
