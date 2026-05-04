import 'package:wellbeing_mapper/models/app_localizations.dart';
import 'package:wellbeing_mapper/models/app_mode.dart';
import 'package:wellbeing_mapper/services/app_mode_service.dart';
import 'package:wellbeing_mapper/services/initial_survey_service.dart';
import 'package:wellbeing_mapper/services/survey_navigation_service.dart';
import 'package:wellbeing_mapper/theme/south_african_theme.dart';
// import 'package:wellbeing_mapper/debug/ios_location_debug.dart'; // Commented out with iOS Location Debug menu (August 5, 2025)
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
      debugPrint('Error loading app info: $e');
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
      debugPrint('Error loading current mode: $e');
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
      debugPrint('Error checking initial survey status: $e');
    }
  }

  void _navigateToChangeMode() async {
    await Navigator.of(context).pushNamed('/change_mode');
    // Refresh current mode and survey status when returning from change mode
    _loadCurrentMode();
    _checkInitialSurveyStatus();
  }

  _launchProjectURL() async {
    final Uri url = Uri.parse('https://activityspacelab.github.io/wellbeing-mapper-app/');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      throw 'Could not launch $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
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
                    : "Complete your initial survey"
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
                  leading: const Icon(Icons.tune),
                  title: Text("Settings"),
                  subtitle: Text("Manage storage and map display"),
                  onTap: () {
                    Navigator.of(context).pushNamed('/storage_settings');
                  },
                ),
              ),
            ],
            // Export Data feature temporarily removed due to reliability issues
            // across different devices and platforms. Can be re-implemented in future
            // with proper file saving capabilities if needed.
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
                    title: Text("App Mode"),
                    subtitle: Text(currentMode.displayName),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Show indicator icon based on mode
                        Icon(
                          currentMode == AppMode.research 
                              ? Icons.science 
                              : currentMode == AppMode.appTesting 
                                  ? Icons.bug_report 
                                  : Icons.lock,
                          size: 16,
                          color: currentMode == AppMode.research 
                              ? Colors.green 
                              : currentMode == AppMode.appTesting 
                                  ? Colors.orange 
                                  : Colors.grey,
                        ),
                        SizedBox(width: 4),
                        IconButton(
                          icon: Icon(Icons.copy, size: 16),
                          onPressed: () => _copyToClipboard(
                            "App Mode: ${currentMode.displayName}",
                            "App mode"
                          ),
                        ),
                      ],
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
                        "App Version: $appVersion\nBuild Number: $buildNumber\nApp Mode: ${currentMode.displayName}\nUser UUID: $userUuid",
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
