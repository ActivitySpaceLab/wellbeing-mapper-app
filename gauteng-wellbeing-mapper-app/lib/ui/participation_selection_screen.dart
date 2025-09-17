import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:convert';
import '../models/consent_models.dart';
import '../models/app_mode.dart';
import '../services/app_mode_service.dart';
import '../services/location_service.dart';
import '../services/ios_location_fix_service.dart';
import '../services/pilot_migration_service.dart';
import '../theme/south_african_theme.dart';
import '../services/participant_validation_service.dart';

class ParticipationSelectionScreen extends StatefulWidget {
  @override
  _ParticipationSelectionScreenState createState() => _ParticipationSelectionScreenState();
}

class _ParticipationSelectionScreenState extends State<ParticipationSelectionScreen> {
  // Note: _participantCodeController kept for future research mode restoration
  final _participantCodeController = TextEditingController();
  String _selectedMode = 'private'; // Default to private mode
  bool _isLoading = false;
  List<AppMode> _availableModes = [];
  bool _isPilotUser = false;
  Map<String, dynamic>? _preservedData;

  @override
  void initState() {
    super.initState();
    _loadAvailableModes();
    _checkPilotStatus();
  }

  void _loadAvailableModes() {
    // Get available modes based on build flavor
    _availableModes = AppModeService.getAvailableModes();
    
    // Ensure selected mode is available in current build
    if (!_availableModes.any((mode) => mode.toString().split('.').last == _selectedMode)) {
      _selectedMode = _availableModes.first.toString().split('.').last;
    }
  }

  Future<void> _checkPilotStatus() async {
    try {
      final isPilot = await PilotMigrationService.isPilotUser();
      final preservedData = await PilotMigrationService.getPreservedDataSummary();
      
      setState(() {
        _isPilotUser = isPilot;
        _preservedData = preservedData;
      });
    } catch (e) {
      print('[ParticipationSelection] Error checking pilot status: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            'Welcome to Wellbeing Mapper',
            style: TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        backgroundColor: SouthAfricanTheme.primaryBlue,
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeSection(),
            if (_isPilotUser) _buildPilotUserInfo(),
            SizedBox(height: 32),
            _buildChoiceSection(),
            // Note: Participant code section removed for beta testing phase
            // Research participation will be re-enabled in future release
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
            Icon(Icons.handshake, size: 64, color: Colors.blueGrey),
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
            SizedBox(height: 12),
            // Beta testing notice - only show for beta builds
            if (AppModeService.isBetaBuild)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '🧪 BETA VERSION',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPilotUserInfo() {
    return Card(
      elevation: 4,
      color: Colors.blue.shade50,
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade700, size: 24),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Welcome Back, Pilot User!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'We\'ve updated the app for the full research study. Your personal data has been preserved:',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            if (_preservedData != null) ...[
              SizedBox(height: 8),
              _buildPreservedDataSummary(),
            ],
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                border: Border.all(color: Colors.amber.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'To continue participating in research:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '• Use your NEW participant code\n'
                    '• Review and sign the updated consent form\n'
                    '• Retake the initial survey',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreservedDataSummary() {
    if (_preservedData == null) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border.all(color: Colors.green.shade200),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_preservedData!['locationRecords'] != null && _preservedData!['locationRecords'] > 0)
            Text(
              '📍 ${_preservedData!['locationRecords']} location records preserved',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
            ),
          if (_preservedData!['happinessSurveys'] != null && _preservedData!['happinessSurveys'] > 0)
            Text(
              '😊 ${_preservedData!['happinessSurveys']} happiness surveys preserved',
              style: TextStyle(fontSize: 12, color: Colors.green.shade700),
            ),
          Text(
            '✅ All your personal data remains available for private use',
            style: TextStyle(fontSize: 11, color: Colors.green.shade600, fontStyle: FontStyle.italic),
          ),
        ],
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
        ..._availableModes.map((mode) => _buildModeOption(mode)).toList(),
      ],
    );
  }

  Widget _buildModeOption(AppMode mode) {
    final modeString = mode.toString().split('.').last;
    
    return Column(
      children: [
        Card(
          child: RadioListTile<String>(
            value: modeString,
            groupValue: _selectedMode,
            onChanged: (value) {
              setState(() {
                _selectedMode = value!;
              });
            },
            title: Text(_getModeTitle(mode)),
            subtitle: _getModeSubtitle(mode),
            secondary: Icon(_getModeIcon(mode), color: _getModeColor(mode)),
          ),
        ),
        SizedBox(height: 8),
      ],
    );
  }

  String _getModeTitle(AppMode mode) {
    switch (mode) {
      case AppMode.private:
        return 'Personal Use Only';
      case AppMode.research:
        return 'Gauteng Study';
      case AppMode.appTesting:
        return 'App Testing';
    }
  }

  Widget _getModeSubtitle(AppMode mode) {
    switch (mode) {
      case AppMode.private:
        return Text('Use the app privately for your own wellbeing tracking. No data will be shared.');
      case AppMode.research:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('For selected research participants in Gauteng Province, South Africa only.'),
            SizedBox(height: 4),
            Text(
              '• Use only if you have been recruited for this study\n• Requires valid participant code',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
      case AppMode.appTesting:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Test all app features safely. No real research data is collected or shared.'),
            SizedBox(height: 4),
            Text(
              '• Experience all research features\n• Practice with surveys and mapping\n• All data stays local - nothing sent to servers',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        );
    }
  }

  IconData _getModeIcon(AppMode mode) {
    switch (mode) {
      case AppMode.private:
        return Icons.lock;
      case AppMode.research:
        return Icons.science;
      case AppMode.appTesting:
        return Icons.bug_report;
    }
  }

  Color _getModeColor(AppMode mode) {
    switch (mode) {
      case AppMode.private:
        return Colors.green;
      case AppMode.research:
        return Colors.blue;
      case AppMode.appTesting:
        return Colors.orange;
    }
  }

  // BETA TESTING: Research participation section disabled
  // This will be re-enabled in the full release for actual research participation
  /*
  Widget _buildParticipantCodeSection() {
    String studySite = 'Gauteng, South Africa';
    String exampleCode = 'GP2024-001';
    
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
  */

  Widget _buildActionButtons() {
    final selectedAppMode = _availableModes.firstWhere(
      (mode) => mode.toString().split('.').last == _selectedMode,
      orElse: () => AppMode.private,
    );

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _handleContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedAppMode.themeColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: _isLoading
                ? CircularProgressIndicator(color: Colors.white)
                : Text(
                    _getButtonText(selectedAppMode),
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ),
        ),
        SizedBox(height: 12),
        // TextButton(
        //   onPressed: _showContactInfo,
        //   child: Text('Contact Development Team'),
        // ),
      ],
    );
  }

  String _getButtonText(AppMode mode) {
    switch (mode) {
      case AppMode.private:
        return 'Start Using App';
      case AppMode.research:
        return 'Continue as Participant';
      case AppMode.appTesting:
        return 'Start App Testing';
    }
  }

  void _handleContinue() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Convert selected mode string to AppMode enum
      final selectedAppMode = _availableModes.firstWhere(
        (mode) => mode.toString().split('.').last == _selectedMode,
        orElse: () => AppMode.private,
      );

      // Request location permissions first for all modes
      print('[ParticipationSelection] Requesting location permissions...');
      bool hasLocationPermission = await LocationService.initializeLocationServices(context: context);
      
      // For iOS, add extra validation with retry logic
      if (!hasLocationPermission && !kIsWeb) {
        try {
          final platform = Theme.of(context).platform;
          if (platform == TargetPlatform.iOS) {
            print('[ParticipationSelection] iOS permission check failed, adding delay and retry...');
            
            // Wait a bit longer for iOS to propagate permission changes
            await Future.delayed(Duration(milliseconds: 1000));
            
            // Check native iOS permissions as fallback
            final nativePermission = await IosLocationFixService.checkNativeLocationPermission();
            final isRegistered = await IosLocationFixService.isAppRegisteredInSettings();
            
            if (nativePermission || isRegistered) {
              print('[ParticipationSelection] iOS native permissions available, proceeding...');
              hasLocationPermission = true;
            } else {
              // Final check with permission_handler after longer delay
              final whenInUseStatus = await Permission.locationWhenInUse.status;
              final alwaysStatus = await Permission.locationAlways.status;
              
              if (whenInUseStatus == PermissionStatus.granted || alwaysStatus == PermissionStatus.granted) {
                print('[ParticipationSelection] Permission handler now shows granted after delay');
                hasLocationPermission = true;
              }
            }
          }
        } catch (e) {
          print('[ParticipationSelection] Error during iOS permission retry: $e');
        }
      }
      
      if (!hasLocationPermission) {
        _showErrorDialog('Location permission is required for this app to function properly. Please grant location permission and try again.');
        return;
      }

      // Handle different modes
      if (selectedAppMode == AppMode.private) {
        // Private use flow - skip consent, go directly to main app
        await AppModeService.setCurrentMode(AppMode.private);
        await _savePrivateUserSettings();
        _navigateToMainApp();
      } else if (selectedAppMode == AppMode.appTesting) {
        // App testing flow - go through consent process like research participants
        await AppModeService.setCurrentMode(AppMode.appTesting);
        
        // Navigate to consent form with testing parameters
        final result = await Navigator.of(context).pushNamed(
          '/consent_form',
          arguments: {
            'participantCode': 'TESTING_MODE', // Special code for testing
            'researchSite': 'gauteng', // Use Gauteng site for testing
            'isTestingMode': true, // Flag to indicate this is testing
          },
        );

        if (result == true) {
          // Consent completed in testing mode - settings already saved by consent form
          _navigateToMainApp();
        }
        // If consent was cancelled or failed, do nothing (stay on current screen)
      } else if (selectedAppMode == AppMode.research) {
        // Research participation flow - check if already validated
        await AppModeService.setCurrentMode(AppMode.research);
        
        // Check if participant is already validated
        final isValidated = await ParticipantValidationService.isParticipantValidated();
        
        if (isValidated) {
          // Already validated - go directly to consent form
          final participantCode = await ParticipantValidationService.getValidatedParticipantCode();
          final result = await Navigator.of(context).pushNamed(
            '/consent_form',
            arguments: {
              'participantCode': participantCode ?? '',
              'researchSite': 'gauteng',
              'isTestingMode': false,
            },
          );

          if (result == true) {
            _navigateToMainApp();
          }
        } else {
          // Not validated - go to participant code entry screen
          final result = await Navigator.of(context).pushNamed(
            '/participant_code_entry',
            arguments: {
              'researchSite': 'gauteng',
            },
          );

          if (result == true) {
            _navigateToMainApp();
          }
        }
        // If validation/consent was cancelled or failed, do nothing (stay on current screen)
      }
    } catch (error) {
      _showErrorDialog('Error setting up app mode: $error');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePrivateUserSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = ParticipationSettings.privateUser();
    await prefs.setString('participation_settings', jsonEncode(settings.toJson()));
  }

  // Note: App testing mode uses same participation settings as private mode
  // since both modes keep data local and don't upload to research servers

  void _navigateToMainApp() {
    Navigator.of(context).pushReplacementNamed('/');
  }

  // void _showContactInfo() {
  //   showDialog(
  //     context: context,
  //     builder: (context) => AlertDialog(
  //       title: Text('Contact Development Team'),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           // Beta notice - only show for beta builds
  //           if (AppModeService.isBetaBuild) ...[
  //             Container(
  //               padding: EdgeInsets.all(12),
  //               decoration: BoxDecoration(
  //                 color: Colors.orange.shade50,
  //                 border: Border.all(color: Colors.orange),
  //                 borderRadius: BorderRadius.circular(8),
  //               ),
  //               child: Row(
  //                 children: [
  //                   Icon(Icons.info, color: Colors.orange),
  //                   SizedBox(width: 8),
  //                   Expanded(
  //                     child: Text(
  //                       'This is a beta testing version. For questions about the app:',
  //                       style: TextStyle(
  //                         fontWeight: FontWeight.bold,
  //                         color: Colors.orange.shade800,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //             SizedBox(height: 16),
  //           ],
  //           Text('Development Team:', style: TextStyle(fontWeight: FontWeight.bold)),
  //           SizedBox(height: 8),
  //           Text('• John Palmer: john.palmer@upf.edu'),
  //           SizedBox(height: 16),
  //           Text(
  //             'For future research participation information:',
  //             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
  //           ),
  //           Text('• Linda Theron: linda.theron@up.ac.za', style: TextStyle(fontSize: 12)),
  //           Text('• Caradee Wright: Caradee.Wright@mrc.ac.za', style: TextStyle(fontSize: 12)),
  //         ],
  //       ),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: Text('Close'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

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
