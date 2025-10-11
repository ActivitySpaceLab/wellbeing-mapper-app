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

import '../theme/south_african_theme.dart';
import '../services/participant_validation_service.dart';
import '../services/consent_tracking_service.dart';

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
  @override
  void initState() {
    super.initState();
    _loadAvailableModes();
    _validateStoredMode(); // Add validation for stored mode
  }

  void _loadAvailableModes() {
    // Get available modes based on build flavor
    _availableModes = AppModeService.getAvailableModes();
    
    // Ensure selected mode is available in current build
    if (!_availableModes.any((mode) => mode.toString().split('.').last == _selectedMode)) {
      _selectedMode = _availableModes.first.toString().split('.').last;
    }
  }

  // Add validation to clear incompatible stored modes
  Future<void> _validateStoredMode() async {
    try {
      final currentMode = await AppModeService.getCurrentMode();
      final currentModeString = currentMode.toString().split('.').last;
      
      // Check if stored mode is available in current build
      if (!_availableModes.any((mode) => mode.toString().split('.').last == currentModeString)) {
        print('[ParticipationSelection] Stored mode $currentModeString not available in current build, clearing...');
        await AppModeService.clearModeData();
        _selectedMode = 'private'; // Reset to default
      } else {
        _selectedMode = currentModeString;
      }
      
      setState(() {}); // Refresh UI with validated mode
    } catch (e) {
      print('[ParticipationSelection] Error validating stored mode: $e');
      // Clear all mode data on error to prevent further issues
      await AppModeService.clearModeData();
      _selectedMode = 'private';
      setState(() {});
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
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () async {
            print('[ParticipationSelection] Back button pressed - escaping to mode selection');
            // Allow user to go back to mode selection if they're trapped
            // Reset to Private mode as a safe default
            print('[ParticipationSelection] Setting mode to Private as safe default');
            await AppModeService.setCurrentMode(AppMode.private);
            print('[ParticipationSelection] Navigating to change_mode screen');
            Navigator.of(context).pushReplacementNamed('/change_mode');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildWelcomeSection(),
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
        if (AppModeService.isDemoBuild) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Explore the full research experience safely in this demo build.'),
              SizedBox(height: 4),
              Text(
                '• Enter any participant code to continue\n• No data leaves this device in demo mode',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          );
        }
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
      // Convert selected mode string to AppMode enum with safety check
      final selectedAppMode = _availableModes.firstWhere(
        (mode) => mode.toString().split('.').last == _selectedMode,
        orElse: () => AppMode.private,
      );

      // Validate mode is still available (double-check to prevent conflicts)
      if (!AppModeService.getAvailableModes().contains(selectedAppMode)) {
        print('[ParticipationSelection] Selected mode $selectedAppMode not available, defaulting to private');
        await AppModeService.setCurrentMode(AppMode.private);
        await _savePrivateUserSettings();
        _navigateToMainApp();
        return;
      }

      // Request location permissions first for all modes
      print('[ParticipationSelection] Requesting location permissions...');
      
      // For iOS, run the comprehensive fix FIRST before attempting standard permissions
      if (!kIsWeb) {
        try {
          final platform = Theme.of(context).platform;
          if (platform == TargetPlatform.iOS) {
            print('[ParticipationSelection] iOS detected - running comprehensive location fix first...');
            
            // Initialize native location manager immediately
            await IosLocationFixService.initializeNativeLocationManager();
            
            // Perform comprehensive fix
            final iosFixResult = await IosLocationFixService.performComprehensiveFix(context: context);
            print('[ParticipationSelection] iOS comprehensive fix result: $iosFixResult');
            
            // Give iOS time to propagate the changes
            await Future.delayed(Duration(milliseconds: 1500));
          }
        } catch (e) {
          print('[ParticipationSelection] Error during iOS comprehensive fix: $e');
        }
      }
      
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
        // Show iOS-specific error message with instructions
        if (!kIsWeb) {
          final platform = Theme.of(context).platform;
          if (platform == TargetPlatform.iOS) {
            _showErrorDialog(
              'iOS Location Setup Required\n\n'
              'Please follow these steps:\n\n'
              '1. Go to iPhone Settings > Privacy & Security > Location Services\n'
              '2. Make sure Location Services is ON\n'
              '3. Find "Wellbeing Mapper" in the app list\n'
              '4. Select "While Using App" or "Ask Next Time"\n'
              '5. Return to this app and try again\n\n'
              'If the app doesn\'t appear in settings, please restart the app.',
            );
          } else {
            _showErrorDialog('Location permission is required for this app to function properly. Please grant location permission and try again.');
          }
        } else {
          _showErrorDialog('Location permission is required for this app to function properly. Please grant location permission and try again.');
        }
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
        print('[ParticipationSelection] === PROCESSING RESEARCH MODE ===');
        // Research participation flow - check if already validated and consented
        // DON'T set mode to research yet - only after successful completion
        
        // Check if participant is already validated
        print('[ParticipationSelection] Checking if participant is already validated');
        final isValidated = await ParticipantValidationService.isParticipantValidated();
        print('[ParticipationSelection] Is validated: $isValidated');
        
        if (isValidated) {
          print('[ParticipationSelection] User is validated, checking consent status');
          // Already validated - check if consent is also completed
          final hasConsent = await ConsentTrackingService.hasCompletedCurrentConsent();
          print('[ParticipationSelection] Has current consent: $hasConsent');
          
          if (hasConsent) {
            // Both validation and consent completed - set mode and go to main app
            print('[ParticipationSelection] User already validated and consented - setting research mode');
            await AppModeService.setCurrentMode(AppMode.research);
            print('[ParticipationSelection] Research mode set successfully, navigating to main app');
            _navigateToMainApp();
          } else {
            // Validated but no consent - go to consent form
            print('[ParticipationSelection] User validated but needs consent - navigating to consent form');
            final participantCode = await ParticipantValidationService.getValidatedParticipantCode();
            print('[ParticipationSelection] Participant code: $participantCode');
            final result = await Navigator.of(context).pushNamed(
              '/consent_form',
              arguments: {
                'participantCode': participantCode ?? '',
                'researchSite': 'gauteng',
                'isTestingMode': false,
              },
            );
            print('[ParticipationSelection] Consent form result: $result');

            if (result == true) {
              // Consent completed - NOW set research mode
              print('[ParticipationSelection] Consent completed - setting Research mode');
              await AppModeService.setCurrentMode(AppMode.research);
              print('[ParticipationSelection] Research mode set successfully after consent');
              _navigateToMainApp();
            } else {
              print('[ParticipationSelection] Consent was cancelled or failed');
            }
          }
        } else {
          // Not validated - go to participant code entry screen
          print('[ParticipationSelection] User not validated - navigating to participant code entry');
          final result = await Navigator.of(context).pushNamed(
            '/participant_code_entry',
            arguments: {
              'researchSite': 'gauteng',
            },
          );
          print('[ParticipationSelection] Participant code entry result: $result');

          if (result == true) {
            // Validation completed - NOW set research mode
            print('[ParticipationSelection] Validation completed - setting Research mode');
            await AppModeService.setCurrentMode(AppMode.research);
            print('[ParticipationSelection] Research mode set successfully after validation');
            _navigateToMainApp();
          } else {
            print('[ParticipationSelection] Participant validation was cancelled or failed');
          }
        }
        // If validation/consent was cancelled or failed, do nothing (stay on current screen)
        print('[ParticipationSelection] Research mode processing completed');
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
    print('[ParticipationSelection] === NAVIGATING TO MAIN APP ===');
    print('[ParticipationSelection] Context: $context');
    print('[ParticipationSelection] Navigator.canPop: ${Navigator.canPop(context)}');
    try {
      print('[ParticipationSelection] Using pushNamedAndRemoveUntil to route: /home (bypassing InitialRouteDecider)');
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
      print('[ParticipationSelection] Navigation call completed successfully');
    } catch (e) {
      print('[ParticipationSelection] ERROR during navigation: $e');
    }
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
