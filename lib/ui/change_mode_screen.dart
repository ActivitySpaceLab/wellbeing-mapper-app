import 'package:flutter/material.dart';
import '../services/consent_service.dart';
import '../services/app_mode_service.dart';
import '../models/app_mode.dart';

class ChangeModeScreen extends StatefulWidget {
  @override
  _ChangeModeScreenState createState() => _ChangeModeScreenState();
}

class _ChangeModeScreenState extends State<ChangeModeScreen> {
  AppMode currentMode = AppMode.private;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
  }

  Future<void> _loadCurrentMode() async {
    try {
      final mode = await AppModeService.getCurrentMode();
      setState(() {
        currentMode = mode;
        isLoading = false;
      });
    } catch (e) {
      print('[ChangeModeScreen] Error loading current mode: $e');
      setState(() {
        currentMode = AppMode.private;
        isLoading = false;
      });
    }
  }

  Future<void> _switchToMode(AppMode newMode) async {
    if (newMode == currentMode) return;

    final confirmed = await _showModeChangeDialog(newMode);
    if (!confirmed) return;

    try {
      await AppModeService.setCurrentMode(newMode);
      
      // Handle legacy consent service for research mode
      if (newMode == AppMode.research) {
        // Navigate to participation selection for real research
        Navigator.of(context).pushNamed('/participation_selection');
        return;
      } else if (newMode == AppMode.appTesting) {
        // App testing mode - require consent form reading like research participants
        final result = await Navigator.of(context).pushNamed(
          '/consent_form',
          arguments: {
            'participantCode': 'TESTING_MODE', // Special code for testing
            'researchSite': 'gauteng', // Use Gauteng site for testing
            'isTestingMode': true, // Flag to indicate this is testing
          },
        );

        if (result == true) {
          // Consent completed in testing mode
          setState(() {
            currentMode = newMode;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully switched to ${newMode.displayName} Mode'),
              backgroundColor: newMode.themeColor,
            ),
          );
          
          // Go back to main screen
          Navigator.of(context).pop();
        } else {
          // Consent was cancelled - revert mode change
          await AppModeService.setCurrentMode(currentMode);
        }
        return;
      } else {
        // Clear any existing research participation for other modes
        await ConsentService.clearConsentData();
      }
      
      setState(() {
        currentMode = newMode;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully switched to ${newMode.displayName} Mode'),
          backgroundColor: newMode.themeColor,
        ),
      );
      
      // Go back to main screen
      Navigator.of(context).pop();
      
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error switching modes: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showModeChangeDialog(AppMode newMode) async {
    return await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Switch to ${newMode.displayName} Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(newMode.description),
              SizedBox(height: 16),
              if (newMode == AppMode.appTesting) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Testing Mode Notice',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Text(
                        '• You can test all research features safely\n'
                        '• NO real research data will be collected\n'
                        '• Your responses will NOT be sent to researchers\n'
                        '• This is for app testing purposes only',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
              if (newMode == AppMode.private) ...[
                Text('• Your data will stay on your device\n'
                     '• No data sharing with researchers\n'
                     '• Perfect for personal tracking'),
              ],
              if (newMode == AppMode.research) ...[
                Text('• You will participate in real research\n'
                     '• Anonymous data shared with researchers\n'
                     '• Help advance scientific knowledge'),
              ],
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: newMode.themeColor,
                foregroundColor: Colors.white,
              ),
              child: Text('Switch Mode'),
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ],
        );
      },
    ) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App Mode'),
        backgroundColor: currentMode.themeColor,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Mode Display
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: currentMode.themeColor,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  currentMode.icon,
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Current Mode: ${currentMode.displayName}',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      currentMode.description,
                                      style: TextStyle(color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (currentMode == AppMode.appTesting) ...[
                            SizedBox(height: 16),
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                border: Border.all(color: Colors.orange),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.info, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text(
                                        'Testing Mode Active',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'You can safely test all app features. No real research data is being collected.',
                                    style: TextStyle(color: Colors.orange.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  
                  SizedBox(height: 24),
                  
                  // Available Modes
                  Text(
                    'Available Modes',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  
                  ...AppModeService.getAvailableModes().map((mode) => _buildModeCard(mode)),
                ],
              ),
            ),
    );
  }

  Widget _buildModeCard(AppMode mode) {
    final isCurrentMode = mode == currentMode;
    
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: isCurrentMode ? 4 : 2,
      child: InkWell(
        onTap: isCurrentMode ? null : () => _switchToMode(mode),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCurrentMode ? mode.themeColor : mode.themeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      mode.icon,
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              '${mode.displayName} Mode',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCurrentMode ? mode.themeColor : null,
                              ),
                            ),
                            if (isCurrentMode) ...[
                              SizedBox(width: 8),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: mode.themeColor,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'ACTIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          mode.description,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (mode == AppMode.appTesting && !isCurrentMode) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '🧪 Safe testing environment - no real data collection',
                    style: TextStyle(
                      color: Colors.orange.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
