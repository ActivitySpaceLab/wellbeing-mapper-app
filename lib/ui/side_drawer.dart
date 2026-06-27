import 'package:wellbeing_mapper/models/app_localizations.dart';
import 'package:wellbeing_mapper/models/app_mode.dart';
import 'package:wellbeing_mapper/services/app_mode_service.dart';
import 'package:wellbeing_mapper/services/initial_survey_service.dart';
import 'package:wellbeing_mapper/services/locale_service.dart';
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

  bool get _isItalian => Localizations.localeOf(context).languageCode == 'it';
  String _t(String en, String it) => _isItalian ? it : en;

  String _modeLabel(AppMode mode) {
    switch (mode) {
      case AppMode.private:
        return _t('Private', 'Privato');
      case AppMode.research:
        return _t('Research', 'Ricerca');
      case AppMode.appTesting:
        return _t('App Testing', 'Test app');
    }
  }

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
      final uuid = prefs.getString("user_uuid") ?? _t('Not available', 'Non disponibile');
      
      setState(() {
        appVersion = packageInfo.version;
        buildNumber = packageInfo.buildNumber;
        userUuid = uuid;
      });
    } catch (e) {
      debugPrint('Error loading app info: $e');
      setState(() {
        appVersion = _t('Unknown', 'Sconosciuto');
        buildNumber = _t('Unknown', 'Sconosciuto');
        userUuid = _t('Unknown', 'Sconosciuto');
      });
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t('$label copied to clipboard', '$label copiato negli appunti')),
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

  /// Label for the currently active language (override, or device default).
  String _currentLanguageLabel(BuildContext context) {
    final override = LocaleService.localeOverride.value;
    if (override == null) {
      final active = Localizations.localeOf(context).languageCode;
      final defaultLabel =
          AppLocalizations.of(context)?.translate("system_default") ?? "System default";
      return '$defaultLabel (${LocaleService.displayName(active)})';
    }
    return LocaleService.displayName(override.languageCode);
  }

  /// Show a dialog letting the user pick the app language (or follow device).
  void _showLanguagePicker() {
    final override = LocaleService.localeOverride.value;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)?.translate("language") ?? "Language"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String?>(
                value: null,
                groupValue: override?.languageCode,
                title: Text(
                  AppLocalizations.of(context)?.translate("system_default") ?? "System default",
                ),
                onChanged: (_) async {
                  await LocaleService.setLocale(null);
                  if (mounted) setState(() {});
                  Navigator.of(dialogContext).pop();
                },
              ),
              ...LocaleService.supportedLocales.map((locale) {
                return RadioListTile<String?>(
                  value: locale.languageCode,
                  groupValue: override?.languageCode,
                  title: Text(LocaleService.displayName(locale.languageCode)),
                  onChanged: (_) async {
                    await LocaleService.setLocale(locale);
                    if (mounted) setState(() {});
                    Navigator.of(dialogContext).pop();
                  },
                );
              }).toList(),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(AppLocalizations.of(context)?.translate("cancel") ?? "Cancel"),
            ),
          ],
        );
      },
    );
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
                title: Text(_t('Loading...', 'Caricamento...')),
              ),
            )
          else ...[
            // Language picker - first menu option
            Card(
              child: ListTile(
                leading: const Icon(Icons.language),
                title: Text(AppLocalizations.of(context)?.translate("language") ?? _t('Language', 'Lingua')),
                subtitle: Text(_currentLanguageLabel(context)),
                onTap: _showLanguagePicker,
              ),
            ),
            // App Mode - Always visible
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings),
                title: Text(_t('App Mode', 'Modalita app')),
                subtitle: Text(_modeLabel(currentMode)),
                trailing: Text(_t('Change Mode', 'Cambia modalita'), style: TextStyle(color: SouthAfricanTheme.primaryBlue)),
                onTap: () {
                  _navigateToChangeMode();
                },
              ),
            ),
            // Wellbeing Map - Always visible
            Card(
              child: ListTile(
                leading: const Icon(Icons.map_outlined),
                title: Text(_t('Wellbeing Map', 'Mappa del benessere')),
                subtitle: Text(_t('View your wellbeing responses on map', 'Visualizza le risposte sulla mappa')),
                onTap: () {
                  Navigator.of(context).pushNamed('/wellbeing_map');
                },
              ),
            ),
            // Wellbeing Timeline - Always visible
            Card(
              child: ListTile(
                leading: const Icon(Icons.timeline),
                title: Text(_t('Wellbeing Timeline', 'Cronologia del benessere')),
                subtitle: Text(_t('Track your wellbeing trends over time', 'Segui l\'andamento del benessere nel tempo')),
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
                    title: Text(_t('Initial Survey', 'Questionario iniziale')),
                  subtitle: Text(hasCompletedInitialSurvey 
                      ? _t('Completed ✓', 'Completato ✓') 
                      : _t('Complete your initial survey', 'Completa il questionario iniziale')
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
                  title: Text(_t('Wellbeing Survey', 'Questionario sul benessere')),
                  subtitle: Text(_t('Bi-weekly wellbeing check-in', 'Check-in quindicinale sul benessere')),
                  onTap: () async {
                    // Use the survey navigation service to support both Qualtrics and hardcoded surveys
                    await SurveyNavigationService.navigateToBiweeklySurvey(context);
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.history),
                  title: Text(_t('Survey History', 'Cronologia questionari')),
                  subtitle: Text(_t('View completed surveys', 'Visualizza i questionari completati')),
                  onTap: () {
                    Navigator.of(context).pushNamed('/survey_list');
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.notifications_outlined),
                  title: Text(_t('Survey Notifications', 'Notifiche questionari')),
                  onTap: () {
                    Navigator.of(context).pushNamed('/notification_settings');
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.tune),
                  title: Text(_t('Settings', 'Impostazioni')),
                  subtitle: Text(_t('Manage storage and map display', 'Gestisci archivio e visualizzazione mappa')),
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
                title: Text(_t('Help & Guide', 'Aiuto e guida')),
                subtitle: Text(_t('Learn how to use the app', 'Scopri come usare l\'app')),
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
                title: Text(_t('App Information', 'Informazioni app')),
                subtitle: Text(_t('Version & User ID', 'Versione e ID utente')),
                children: [
                  ListTile(
                    dense: true,
                    title: Text(_t('App Version', 'Versione app')),
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
                    title: Text(_t('App Mode', 'Modalita app')),
                    subtitle: Text(_modeLabel(currentMode)),
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
                            "App Mode: ${_modeLabel(currentMode)}",
                            _t('App mode', 'Modalita app')
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(_t('User UUID', 'UUID utente')),
                    subtitle: Text(userUuid.length > 30 ? "${userUuid.substring(0, 30)}..." : userUuid),
                    trailing: IconButton(
                      icon: Icon(Icons.copy, size: 16),
                      onPressed: () => _copyToClipboard(userUuid, _t('User UUID', 'UUID utente')),
                    ),
                  ),
                  ListTile(
                    dense: true,
                    title: Text(_t('Copy All Info', 'Copia tutte le info')),
                    trailing: IconButton(
                      icon: Icon(Icons.copy_all),
                      onPressed: () => _copyToClipboard(
                        "App Version: $appVersion\nBuild Number: $buildNumber\nApp Mode: ${_modeLabel(currentMode)}\nUser UUID: $userUuid",
                        _t('All app information', 'Tutte le informazioni app')
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
