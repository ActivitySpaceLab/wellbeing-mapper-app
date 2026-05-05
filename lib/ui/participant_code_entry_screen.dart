import 'package:flutter/material.dart';
import 'package:wellbeing_mapper/services/app_mode_service.dart';
import 'package:wellbeing_mapper/services/participant_validation_service.dart';
import 'package:wellbeing_mapper/theme/south_african_theme.dart';

class ParticipantCodeEntryScreen extends StatefulWidget {
  final String researchSite;

  const ParticipantCodeEntryScreen({
    Key? key,
    this.researchSite = 'wellbeing_mapper',
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
                        'If you were recruited through a survey panel and have a participant code, enter it below so the panel can compensate you. Otherwise, continue without a code.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (AppModeService.isDemoBuild) ...[
                        SizedBox(height: 12),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            'Demo build: any code will work here and no data will be uploaded.',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Participant code input (optional)
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Participant Code (optional)',
                    hintText: 'Only if provided by a survey panel',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    errorText: _errorMessage,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  validator: (value) {
                    // Only validate if the user actually typed something.
                    if (value == null || value.trim().isEmpty) {
                      return null;
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

                SizedBox(height: 12),

                // Continue without a code
                OutlinedButton(
                  onPressed: _isLoading ? null : _continueWithoutCode,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: SouthAfricanTheme.primaryGreen,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    side: BorderSide(color: SouthAfricanTheme.primaryGreen),
                  ),
                  child: Text(
                    'Continue without a code',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                        '• Codes are only needed if a survey panel recruited you and will compensate you\n'
                        '• If you were recruited through ads or in person, just continue without a code\n'
                        '• Codes are case-insensitive\n'
                        '• Once registered, you won\'t need to do this again\n'
                        '• Contact the research team if you have issues',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                      if (AppModeService.isDemoBuild) ...[
                        SizedBox(height: 8),
                        Text(
                          'Demo reminder: validation happens locally so you can explore without sending data.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Contact information
                Text(
                  'Need help? Contact the research team at\nresearch@wellbeing-mapper.org',
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
    final entered = _codeController.text.trim();
    if (entered.isEmpty) {
      // Empty field on the "Validate Code" button means the user probably
      // wanted to skip — route them through the anonymous flow instead of
      // showing a confusing validation error.
      await _continueWithoutCode();
      return;
    }
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await ParticipantValidationService.validateParticipantCode(
        entered,
      );

      if (result.isValid) {
        // Validation successful - proceed to consent form
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(
            '/consent_form',
            arguments: {
              'participantCode': entered.toUpperCase(),
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
      debugPrint('[ParticipantCodeEntry] Error validating code: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _continueWithoutCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final result =
          await ParticipantValidationService.registerAnonymousParticipant();
      if (!mounted) return;
      if (result.isValid) {
        Navigator.of(context).pushReplacementNamed(
          '/consent_form',
          arguments: {
            'participantCode': '',
            'researchSite': widget.researchSite,
            'isTestingMode': false,
          },
        );
      } else {
        setState(() {
          _errorMessage = result.error;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      debugPrint('[ParticipantCodeEntry] Error in anonymous flow: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
