import 'package:flutter/material.dart';
import 'package:wellbeing_mapper/theme/south_african_theme.dart';

class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Help'),
        backgroundColor: SouthAfricanTheme.primaryBlue,
        foregroundColor: SouthAfricanTheme.pureWhite,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeSection(),
            SizedBox(height: 20),
            _buildMainScreenSection(),
            SizedBox(height: 20),
            _buildPermissionsSection(),
            SizedBox(height: 20),
            _buildMenuOptionsSection(),
            SizedBox(height: 20),
            _buildSettingsSection(),
            SizedBox(height: 20),
            _buildAppModesSection(),
            SizedBox(height: 20),
            _buildPrivacySection(),
            SizedBox(height: 20),
            _buildTroubleshootingSection(),
            SizedBox(height: 20),
            _buildContactSection(),
          ],
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
            Row(
              children: [
                Icon(Icons.help_outline, color: SouthAfricanTheme.primaryBlue, size: 28),
                SizedBox(width: 12),
                Text(
                  'Welcome',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: SouthAfricanTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'Wellbeing Mapper helps people learn more about the ways in which mental wellbeing depends on environmental conditions. You can use it privately to study your own movements and wellbeing. If you have been selected for the Planet4Health study on mental wellbeing in Southern Europe, and given a participant code, then you can use the app to participate in that study.',
              style: TextStyle(fontSize: 16, height: 1.4),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainScreenSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.home, color: SouthAfricanTheme.primaryGreen, size: 24),
                SizedBox(width: 8),
                Text(
                  'Main Screen Controls',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Location tracking switch
            _buildFeatureItem(
              Icons.toggle_on,
              'Location Tracking Switch',
              'The switch in the top-right corner controls location tracking:',
              [
                '• Yellow switch = Tracking ON (recording your movements)',
                '• Grey switch = Tracking OFF (not recording)',
                '• When ON, the app tracks your location in the background' 
              ],
            ),
            
            SizedBox(height: 16),
            
            // GPS button
            _buildFeatureItem(
              Icons.gps_fixed,
              'GPS Fix Button',
              'The GPS icon next to the switch:',
              [
                '• Tap to get your current precise location',
                '• Useful if the map seems outdated',
                '• Forces the app to check your exact position',
                '• The icon turns yellow when active'
              ],
            ),
            
            SizedBox(height: 16),
            
            // Survey button
            // Survey button
            _buildFeatureItem(
              Icons.add_circle,
              'Survey Button (Blue Oval)',
              'The floating blue button in the bottom-right:',
              [
                '• In private mode: triggers a private happiness survey',
                '• In research mode: triggers the biweekly wellbeing survey',
                '• Available to all users in both modes'
              ],
            ),            SizedBox(height: 16),
            
            // Menu button
            _buildFeatureItem(
              Icons.menu,
              'Menu Button',
              'The hamburger menu (three lines) in the top-left:',
              [
                '• Opens the main navigation menu',
                '• Access all app features and settings',
                '• Different options based on your app mode',
                '• Tap anywhere outside menu to close'
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: SouthAfricanTheme.accentYellow, size: 24),
                SizedBox(width: 8),
                Text(
                  'App Permissions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            _buildFeatureItem(
              Icons.location_on,
              'Location Permission',
              'Required for the core functionality of tracking your movements:',
              [
                '• Allows the app to record where you spend time',
                '• Needed for wellbeing mapping and research features',
                '• You control whether location data is shared or kept private',
                '• The app will request this permission when you first choose your participation mode'
              ],
            ),
            
            SizedBox(height: 16),
            
            _buildFeatureItem(
              Icons.notifications,
              'Notification Permission',
              'Optional but recommended for research participants:',
              [
                '• Sends bi-weekly survey reminders',
                '• Helps you stay engaged with the study',
                '• You can disable notifications anytime in phone settings',
                '• Private mode users won\'t receive research reminders'
              ],
            ),
            
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SouthAfricanTheme.softYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: SouthAfricanTheme.darkGrey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can manage all permissions in your phone\'s Settings app. The app will guide you through granting necessary permissions when you first set up your participation mode.',
                      style: TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildMenuOptionsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.list, color: SouthAfricanTheme.accentYellow, size: 24),
                SizedBox(width: 8),
                Text(
                  'Menu Options',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            Text(
              'Available to Everyone:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            SizedBox(height: 8),
            
            _buildMenuOptionItem(
              Icons.settings,
              'App Mode',
              'Switch between Private Mode (data stays on your phone) and Research Mode (if you have been selected for the Planet4Health mental wellbeing study in Southern Europe).',
            ),

            _buildMenuOptionItem(
              Icons.tune,
              'Settings',
              'Adjust data retention, map marker limits, and accuracy thresholds. See the Settings section below for more details.',
            ),
            
            _buildMenuOptionItem(
              Icons.help,
              'Help',
              'Opens this help screen with detailed instructions for using the app.',
            ),
            
            _buildMenuOptionItem(
              Icons.web,
              'Visit Project Website',
              'Opens the Planet4Health project website to learn more about the mental wellbeing study.',
            ),
            
            _buildMenuOptionItem(
              Icons.report_problem_outlined,
              'Report an Issue',
              'Contact the research team if you experience technical problems or have questions.',
            ),
            
            SizedBox(height: 16),
            
            Text(
              'Research Mode:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: SouthAfricanTheme.researchMode),
            ),
            SizedBox(height: 8),
            
            _buildMenuOptionItem(
              Icons.assignment,
              'Initial Survey',
              'Complete a one-time survey when you first join the research study.',
            ),
            
            _buildMenuOptionItem(
              Icons.assignment_turned_in,
              'Wellbeing Survey',
              'Take the bi-weekly wellbeing check-in survey. You\'ll also be reminded with notifications.',
            ),
            
            _buildMenuOptionItem(
              Icons.history,
              'Survey History',
              'View all surveys you\'ve completed, including dates and your responses.',
            ),
            
            _buildMenuOptionItem(
              Icons.notifications_outlined,
              'Survey Notifications',
              'Manage when and how often you receive survey reminder notifications (research mode only).',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune, color: SouthAfricanTheme.primaryBlue, size: 28),
                SizedBox(width: 12),
                Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: SouthAfricanTheme.primaryBlue,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Text(
              'Manage how your location data is kept on the device and how it appears on the map.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            
            _buildMenuOptionItem(
              Icons.history,
              'Location Data Retention',
              'Control how long location data is kept on your device before being automatically deleted. Default is 60 days, but you can set it to unlimited or a custom period.',
            ),
            
            _buildMenuOptionItem(
              Icons.map_outlined,
              'Map Display Markers',
              'Set the maximum number of location points to show on the map (up to 10,000). More markers provide more detail but may impact performance on older devices.',
            ),

            _buildMenuOptionItem(
              Icons.my_location,
              'Maximum GPS Error',
              'Choose the highest GPS error (in meters) that should be shown on the map. Points with worse accuracy are hidden to keep the map clean.',
            ),
            
            _buildMenuOptionItem(
              Icons.cleaning_services,
              'Automatic Cleanup',
              'Enable automatic deletion of old location data based on your retention settings. Helps keep your device storage optimized.',
            ),
            
            _buildMenuOptionItem(
              Icons.info_outline,
              'Storage Information',
              'View how much storage space your location data is using and get recommendations for optimal settings.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppModesSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.settings_applications, color: SouthAfricanTheme.primaryBlue, size: 24),
                SizedBox(width: 8),
                Text(
                  'App Modes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            
            // Private Mode
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SouthAfricanTheme.privateMode.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SouthAfricanTheme.privateMode.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock, color: SouthAfricanTheme.privateMode),
                      SizedBox(width: 8),
                      Text(
                        'Private Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: SouthAfricanTheme.privateMode,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• All data stays on your phone only\n'
                    '• No automatic data sharing with researchers\n'
                    '• You control all data sharing and privacy\n'
                    '• Perfect for personal movement tracking\n'
                    '• Can still take wellbeing surveys for yourself',
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            // Research Mode
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SouthAfricanTheme.researchMode.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SouthAfricanTheme.researchMode.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.school, color: SouthAfricanTheme.researchMode),
                      SizedBox(width: 8),
                      Text(
                        'Research Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: SouthAfricanTheme.researchMode,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    '• Encrypted data shared with research team\n'
                    '• Contribute to important wellbeing studies\n'
                    '• Regular survey reminders every 2 weeks\n'
                    '• All participation is voluntary and anonymous\n'
                    '• Currently in development for future release',
                    style: TextStyle(height: 1.4),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 12),
            
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SouthAfricanTheme.softYellow,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: SouthAfricanTheme.darkGrey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'You can switch between Private and Research modes. Research mode allows you to contribute to the Planet4Health study with encrypted data sharing.',
                      style: TextStyle(fontWeight: FontWeight.w500),
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

  Widget _buildPrivacySection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.security, color: SouthAfricanTheme.primaryGreen, size: 24),
                SizedBox(width: 8),
                Text(
                  'Privacy & Data Security',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            _buildFeatureItem(
              Icons.lock,
              'Data Protection',
              '',
              [
                '• No data from this app is shared when in Private Mode',
                '• In Research Mode, you control what data to share and when, and anything you choose to share is encrypted before being sent from you device'
              ],
            ),
            
            SizedBox(height: 12),
            
            _buildFeatureItem(
              Icons.visibility_off,
              'Your Privacy Rights',
              '',
              [
                '• You can stop participating in Research Mode at anytime',
                '• You can request that any data you sent to the research server be deleted by contacting the researchers with this request and including your user UUID (which can be found and copied from the bottom of the side drawer menu'
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.build, color: SouthAfricanTheme.accentRed, size: 24),
                SizedBox(width: 8),
                Text(
                  'Troubleshooting',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            
            _buildTroubleshootItem(
              'Location permission issues?',
              [
                '• Check that location permission is granted in phone settings',
                '• Some phones have "precise location" settings - enable this',
                '• Try restarting the app after granting permissions',
                '• On Android, ensure "Allow all the time" location access is enabled'
              ],
            ),
            
            _buildTroubleshootItem(
              'Location not updating?',
              [
                '• Check that location tracking switch is ON (yellow)',
                '• Tap the GPS button to force a location update',
                '• Ensure location permissions are enabled in phone settings',
                '• Try restarting the app if problems persist'
              ],
            ),
            
            _buildTroubleshootItem(
              'App running slowly?',
              [
                '• Close other apps running in the background',
                '• Restart your phone if needed',
                '• Clear some storage space on your device',
                '• Update to the latest version of the app'
              ],
            ),
            
            _buildTroubleshootItem(
              'Survey notifications not working?',
              [
                '• Check notification settings in your phone',
                '• Open "Survey Notifications" in the menu',
                '• Ensure the app has permission to send notifications',
                '• Try triggering a test notification'
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.contact_support, color: SouthAfricanTheme.primaryBlue, size: 24),
                SizedBox(width: 8),
                Text(
                  'Need More Help?',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text(
              'If you have questions or need assistance:',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              '• Use "Report an Issue" in the menu\n'
              '• Visit the project website for more information\n'
              '• Contact the research team directly\n'
              '• Check for app updates in your app store',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SouthAfricanTheme.lightGrey,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Thank you for using Wellbeing Mapper! Your participation helps researchers understand how communities and environments affect wellbeing in South Africa.',
                style: TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description, List<String> points) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: SouthAfricanTheme.primaryBlue, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  if (description.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(description, style: TextStyle(fontSize: 14)),
                  ],
                  SizedBox(height: 4),
                  ...points.map((point) => Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Text(point, style: TextStyle(fontSize: 14, height: 1.3)),
                  )).toList(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMenuOptionItem(IconData icon, String title, String description) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: SouthAfricanTheme.mediumGrey, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(fontSize: 13, color: SouthAfricanTheme.darkGrey, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(String problem, List<String> solutions) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            problem,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          SizedBox(height: 6),
          ...solutions.map((solution) => Padding(
            padding: EdgeInsets.only(bottom: 2, left: 8),
            child: Text(solution, style: TextStyle(fontSize: 14, height: 1.3)),
          )).toList(),
        ],
      ),
    );
  }
}
