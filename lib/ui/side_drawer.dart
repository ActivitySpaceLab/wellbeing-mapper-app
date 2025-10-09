import 'dart:convert';
import 'package:wellbeing_mapper/main.dart';
import 'package:wellbeing_mapper/models/app_localizations.dart';
import 'package:wellbeing_mapper/models/app_mode.dart';
import 'package:wellbeing_mapper/services/app_mode_service.dart';
import 'package:wellbeing_mapper/services/wellbeing_survey_service.dart';
import 'package:wellbeing_mapper/services/initial_survey_service.dart';
import 'package:wellbeing_mapper/services/survey_navigation_service.dart';
import 'package:wellbeing_mapper/theme/south_african_theme.dart';
import 'package:wellbeing_mapper/db/survey_database.dart';
// import 'package:wellbeing_mapper/debug/ios_location_debug.dart'; // Commented out with iOS Location Debug menu (August 5, 2025)
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WellbeingMapperSideDrawer extends StatefulWidget {
  @override
  _WellbeingMapperSideDrawerState createState() => _WellbeingMapperSideDrawerState();
}

class _WellbeingMapperSideDrawerState extends State<WellbeingMapperSideDrawer> {
  AppMode currentMode = AppMode.private; // Default to private mode
  bool isLoading = true;
  bool hasCompletedInitialSurvey = false;
  String appVersion = '';
  String buildNumber = '';
  String userUuid = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentMode();
    _checkInitialSurveyStatus();
    _loadAppInfo();
  }

  Future<void> _loadAppInfo() async {
    try {
      // Get package info for version and build number
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      
      // Get user UUID from shared preferences
      final prefs = await SharedPreferences.getInstance();
      final uuid = prefs.getString("user_uuid") ?? 'Not available';
      
      setState(() {
        appVersion = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
        userUuid = uuid;
      });
    } catch (e) {
      print('Error loading app info: $e');
      setState(() {
        appVersion = 'Unknown';
        buildNumber = 'Unknown';
        userUuid = 'Unknown';
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _loadCurrentMode() async {
    try {
      final mode = await AppModeService.getCurrentMode();
      setState(() {
        currentMode = mode;
        isLoading = false;
      });
    } catch (e) {
      print('Error loading current mode: $e');
      setState(() {
        currentMode = AppMode.private; // Default to private on error
        isLoading = false;
      });
    }
  }

  Future<void> _checkInitialSurveyStatus() async {
    try {
      final completed = await InitialSurveyService.hasCompletedInitialSurvey();
      setState(() {
        hasCompletedInitialSurvey = completed;
      });
    } catch (e) {
      print('Error checking initial survey status: $e');
    }
  }

  void _navigateToChangeMode() async {
    await Navigator.of(context).pushNamed('/change_mode');
    // Refresh current mode and survey status when returning from change mode
    _loadCurrentMode();
    _checkInitialSurveyStatus();
  }

  Future<void> _exportData() async {
    try {
      print('[SideDrawer] Starting data export...');
      var now = DateTime.now();
      
      // Check if this is a demo build
      final isDemoMode = currentMode == AppMode.appTesting;
      
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            content: Row(
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Preparing data export..."),
              ],
            ),
          );
        },
      );

      // Get location data from app database (source of truth)
      List<Map<String, dynamic>> customLocation = [];
      
      if (kIsWeb) {
        print('[SideDrawer] Web platform detected - skipping location data export');
      } else {
        try {
          // Load from app database instead of FBG to ensure consistency with map
          final db = SurveyDatabase();
          final locationTracks = await db.getAllLocationTracks();
          print('[SideDrawer] 🗃️ Retrieved ${locationTracks.length} location records from app database');
          
          // Convert LocationTrack objects to export format
          for (var track in locationTracks) {
            Map<String, dynamic> locationData = {
              'timestamp': track.timestamp.toIso8601String(),
              'latitude': track.latitude,
              'longitude': track.longitude,
              'accuracy': track.accuracy ?? 0.0,
              'uuid': GlobalData.userUUID,
            };
            customLocation.add(locationData);
          }
          
          print('[SideDrawer] ✅ Converted ${customLocation.length} location tracks for export');
        } catch (e) {
          print('[SideDrawer] ❌ Error getting location data from database: $e');
          // Continue with empty location list
        }
      }

      // Get wellbeing survey data
      List wellbeingSurveys = [];
      try {
        final surveys = await WellbeingSurveyService().getWellbeingSurveysForExport();
        wellbeingSurveys = surveys.map((survey) => survey.toJson()).toList();
        print('[SideDrawer] Retrieved ${wellbeingSurveys.length} wellbeing surveys');
      } catch (e) {
        print('[SideDrawer] Error getting wellbeing surveys for export: $e');
        // Continue with empty survey list
      }

      // Get initial survey data if available
      Map<String, dynamic>? initialSurveyData;
      try {
        final hasCompleted = await InitialSurveyService.hasCompletedInitialSurvey();
        if (hasCompleted) {
          // Try to get initial survey data if available
          initialSurveyData = {
            'completed': true,
            'completion_date': 'Available in database',
            'note': 'Initial survey data can be retrieved from local database'
          };
        }
      } catch (e) {
        print('[SideDrawer] Error getting initial survey data: $e');
      }

      // Create comprehensive export data
      Map<String, dynamic> exportData = {
        'export_info': {
          'timestamp': now.toIso8601String(),
          'app_version': '0.1.11+1',
          'export_format_version': '1.0',
          'app_mode': currentMode.displayName,
          'user_id': GlobalData.userUUID,
        },
        'data_summary': {
          'location_records': customLocation.length,
          'wellbeing_surveys': wellbeingSurveys.length,
          'initial_survey_completed': hasCompletedInitialSurvey,
          'export_date_range': customLocation.isNotEmpty 
            ? {
                'total_location_records': customLocation.length,
                'note': 'Location data available - see location_data section for details',
              }
            : {
                'total_location_records': 0,
                'note': 'No location data available',
              },
        },
        'location_data': customLocation,
        'wellbeing_surveys': wellbeingSurveys,
        'initial_survey': initialSurveyData,
        'privacy_note': currentMode == AppMode.private 
          ? 'This data was collected in Private Mode - no data has been shared with research servers.'
          : currentMode == AppMode.appTesting
            ? 'This data was collected in App Testing Mode - data is stored locally for testing purposes only.'
            : 'This data was collected in Research Mode - data may have been shared with research servers based on your consent preferences.',
      };

      // Close loading dialog
      Navigator.of(context).pop();

      // Format the JSON nicely
      String prettyString = JsonEncoder.withIndent('  ').convert(exportData);
      
      // Show export options dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Export Data'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('• Location records: ${customLocation.length}'),
                Text('• Wellbeing surveys: ${wellbeingSurveys.length}'),
                Text('• Initial survey: ${hasCompletedInitialSurvey ? "Completed" : "Not completed"}'),
                Text('• App mode: ${currentMode.displayName}'),
                SizedBox(height: 16),
                Text('This will share your data as formatted JSON text that you can save or share as needed.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Share.share(
                    prettyString,
                    subject: 'Wellbeing Mapper Data Export - ${now.toIso8601String().split('T')[0]}',
                  );
                },
                child: Text('Export Data'),
              ),
            ],
          );
        },
      );
      
      print('[SideDrawer] Data export completed successfully');
      
    } catch (e) {
      // Close loading dialog if it's open
      Navigator.of(context, rootNavigator: true).pop();
      
      print('[SideDrawer] Error during data export: $e');
      
      // Show error dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Export Error'),
            content: Text('Sorry, there was an error preparing your data for export. Please try again.\n\nError: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('OK'),
              ),
            ],
          );
        },
      );
    }
  }

  _launchProjectURL() async {
    final Uri url = Uri.parse('https://activityspacelab.github.io/gauteng-wellbeing-mapper-app/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return new Drawer(
      child: ListView(
        // Important: Remove any padding from the ListView.
        padding: EdgeInsets.zero,
        children: <Widget>[
          Container(
            height: 100,
            child: DrawerHeader(
              child: Text(
                  AppLocalizations.of(context)
                          ?.translate("side_drawer_title") ??
                      "",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
              decoration: BoxDecoration(
                color: Colors.blueGrey[200],
              ),
            ),
          ),
          if (isLoading)
            Card(
              child: ListTile(
                leading: const Icon(Icons.refresh),
                title: Text("Loading..."),
              ),
            )
          else ...[
            // App Mode - Always visible (moved to first position)
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: Text("App Mode"),
                subtitle: Text(currentMode.displayName),
                trailing: Text("Change Mode", style: TextStyle(color: SouthAfricanTheme.primaryBlue)),
                onTap: () {
                  _navigateToChangeMode();
                },
              ),
            ),
            // Wellbeing Map - Always visible
            Card(
              child: ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text("Wellbeing Map"),
                subtitle: Text("View your wellbeing responses on map"),
                onTap: () {
                  Navigator.of(context).pushNamed('/wellbeing_map');
                },
              ),
            ),
            // Wellbeing Timeline - Always visible
            Card(
              child: ListTile(
                leading: const Icon(Icons.timeline),
                title: Text("Wellbeing Timeline"),
                subtitle: Text("Track your wellbeing trends over time"),
                onTap: () {
                  Navigator.of(context).pushNamed('/wellbeing_timeline');
                },
              ),
            ),
            // Research and App Testing mode menu items
            if (currentMode != AppMode.private) ...[
              Card(
                child: ListTile(
                  leading: Icon(
                    hasCompletedInitialSurvey ? Icons.assignment_turned_in : Icons.assignment,
                    color: hasCompletedInitialSurvey ? Colors.green : null,
                  ),
                  title: Text("Initial Survey"),
                  subtitle: Text(hasCompletedInitialSurvey 
                    ? "Completed ✓" 
                    : "Complete your initial demographics survey"
                  ),
                  trailing: hasCompletedInitialSurvey 
                    ? Icon(Icons.check_circle, color: Colors.green)
                    : Icon(Icons.warning, color: Colors.orange),
                  onTap: () async {
                    // Use the survey navigation service to support both Qualtrics and hardcoded surveys
                    await SurveyNavigationService.navigateToInitialSurvey(context);
                    // Note: Survey completion tracking will need to be updated for Qualtrics
                    // For now, we'll keep the existing logic for hardcoded surveys
                    // TODO: Implement Qualtrics survey completion tracking
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.assignment_turned_in),
                  title: Text("Wellbeing Survey"),
                  subtitle: Text("Bi-weekly wellbeing check-in"),
                  onTap: () async {
                    // Use the survey navigation service to support both Qualtrics and hardcoded surveys
                    await SurveyNavigationService.navigateToBiweeklySurvey(context);
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text("Survey History"),
                  subtitle: Text("View completed surveys"),
                  onTap: () {
                    Navigator.of(context).pushNamed('/survey_list');
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text("Survey Notifications"),
                  onTap: () {
                    Navigator.of(context).pushNamed('/notification_settings');
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.storage),
                  title: Text("Storage Settings"),
                  subtitle: Text("Manage location data storage"),
                  onTap: () {
                    Navigator.of(context).pushNamed('/storage_settings');
                  },
                ),
              ),
            ],
            // Export Data - Always visible (renamed from Share Locations)
            Card(
              child: ListTile(
                leading: const Icon(Icons.share),
                title: Text("Export Data"),
                onTap: () {
                  _exportData();
                },
              ),
            ),
            // iOS Location Debug - Debug tool for diagnosing iOS location permission issues
            // NOTE: Commented out as iOS location issues have been resolved (August 5, 2025)
            // Uncomment if iOS location debugging is needed again in the future
            /*
            Card(
              child: ListTile(
                leading: const Icon(Icons.bug_report, color: Colors.orange),
                title: Text("iOS Location Debug"),
                subtitle: Text("Diagnose location permission issues"),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => IosLocationDebugScreen(),
                    ),
                  );
                },
              ),
            ),
            */
            // Help & Guide - Always visible
            Card(
              child: ListTile(
                leading: const Icon(Icons.help),
                title: Text("Help & Guide"),
                subtitle: Text("Learn how to use the app"),
                onTap: () {
                  Navigator.of(context).pushNamed('/help');
                },
              ),
            ),
            // Visit Project Website - Second to last
            Card(
              child: ListTile(
                leading: const Icon(Icons.web),
                title: Text(AppLocalizations.of(context)
                        ?.translate("visit_project_website") ??
                    ""),
                onTap: () {
                  _launchProjectURL();
                },
              ),
            ),
            // Report an Issue - Last
            Card(
              child: ListTile(
                leading: const Icon(Icons.report_problem_outlined),
                title: Text(
                    AppLocalizations.of(context)?.translate("report_an_issue") ??
                        ""),
                onTap: () {
                  Navigator.of(context).pushNamed('/report_an_issue');
                },
              ),
            ),
            // App Version & User Info - For testing and support
            Card(
              color: Colors.grey[50],
              child: ExpansionTile(
                leading: const Icon(Icons.info_outline),
                title: Text("App Information"),
                subtitle: Text("Version & User ID"),
                children: [
                  ListTile(
                    dense: true,
                    title: Text("App Version"),
                    subtitle: Text("$appVersion ($buildNumber)"),
                    trailing: IconButton(
                      icon: Icon(Icons.copy, size: 16),
                      onPressed: () => _copyToClipboard(
                        "Version: $appVersion\nBuild: $buildNumber",
                        "Version info"
                      ),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text("User UUID"),
                    subtitle: Text(userUuid.length > 30 ? "${userUuid.substring(0, 30)}..." : userUuid),
                    trailing: IconButton(
                      icon: Icon(Icons.copy, size: 16),
                      onPressed: () => _copyToClipboard(userUuid, "User UUID"),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text("Copy All Info"),
                    trailing: IconButton(
                      icon: Icon(Icons.copy_all),
                      onPressed: () => _copyToClipboard(
                        "App Version: $appVersion\nBuild Number: $buildNumber\nUser UUID: $userUuid",
                        "All app information"
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
