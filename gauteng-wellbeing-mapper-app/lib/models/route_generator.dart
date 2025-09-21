import 'package:wellbeing_mapper/ui/notification_settings_view.dart';
import 'package:wellbeing_mapper/ui/storage_settings_view.dart';
import 'package:flutter/material.dart';

import '../ui/home_view.dart';
import '../ui/list_view.dart';
import '../ui/report_issues.dart';
import '../ui/web_view.dart';
import '../ui/initial_survey_screen.dart';
import '../ui/recurring_survey_screen.dart';
import '../ui/survey_list_screen.dart';
import '../ui/participation_selection_screen.dart';
import '../ui/consent_form_screen.dart';
import '../ui/data_sharing_preferences_screen.dart';
import '../ui/wellbeing_survey_screen.dart';
import '../ui/wellbeing_map_view.dart';
import '../ui/wellbeing_timeline_view.dart';
import '../ui/change_mode_screen.dart';
import '../ui/help_screen.dart';
import '../ui/participant_code_entry_screen.dart';

// Survey URLs for direct access
class SurveyUrls {
  static const String initialSurvey = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_bsb8iq0UiATXRJQ';
  static const String biweeklySurvey = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_eUJstaSWQeKykBM';
  static const String consentSurvey = 'https://pretoria.eu.qualtrics.com/jfe/form/SV_4I7j91aabspz5YO';
}

class GlobalRouteData {
  static String? user_route = "brown";
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;
    GlobalRouteData.user_route = settings.name;
    print('[route_generator.dart] generateRoute called for: ${settings.name}');
    switch (settings.name) {
      case '/':
        print('[route_generator.dart] Creating HomeView route');
        return MaterialPageRoute(builder: (_) {
          print('[route_generator.dart] About to create HomeView');
          try {
            return HomeView('Wellbeing Mapper');
          } catch (e) {
            print('[route_generator.dart] ERROR creating HomeView: $e');
            return Scaffold(
              appBar: AppBar(title: Text('Error')),
              body: Center(child: Text('Error loading home screen: $e')),
            );
          }
        });
      case '/locations_history':
        return MaterialPageRoute(builder: (_) => STOListView());
      case '/report_an_issue':
        return MaterialPageRoute(builder: (_) => ReportAnIssue());
//      case '/my_statistics':
      //       return MaterialPageRoute(builder: (_) => MyStatistics());
      case '/navigation_to_webview':
        if (args is Map<String, String>) {
          return MaterialPageRoute(
              builder: (_) => MyWebView(
                  args['selectedUrl'] ?? '',
                  args['locationHistoryJSON'] ?? '',
                  args['locationSharingMethod'] ?? '',
                  args['surveyElementCode'] ?? ''));
        }
        return _errorRoute();
      case '/notification_settings':
        return MaterialPageRoute(builder: (_) => NotificationSettingsView());
      case '/storage_settings':
        return MaterialPageRoute(builder: (_) => StorageSettingsView());
      case '/initial_survey':
        return MaterialPageRoute(builder: (_) => InitialSurveyScreen());
      case '/recurring_survey':
        return MaterialPageRoute(builder: (_) => RecurringSurveyScreen());
      case '/qualtrics_initial_survey':
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (_) => MyWebView(
              SurveyUrls.initialSurvey,
              args['locationHistoryJSON'] ?? '',
              args['locationSharingMethod'] ?? '',
              '', // surveyElementCode not used for Qualtrics
              surveyType: SurveyType.initial,
              isQualtricsSurvey: true,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => MyWebView(
            SurveyUrls.initialSurvey,
            '', '', '',
            surveyType: SurveyType.initial,
            isQualtricsSurvey: true,
          ),
        );
      case '/qualtrics_biweekly_survey':
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (_) => MyWebView(
              SurveyUrls.biweeklySurvey,
              args['locationHistoryJSON'] ?? '',
              args['locationSharingMethod'] ?? '',
              '', // surveyElementCode not used for Qualtrics
              surveyType: SurveyType.biweekly,
              isQualtricsSurvey: true,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => MyWebView(
            SurveyUrls.biweeklySurvey,
            '', '', '',
            surveyType: SurveyType.biweekly,
            isQualtricsSurvey: true,
          ),
        );
      case '/survey_list':
        return MaterialPageRoute(builder: (_) => SurveyListScreen());
      case '/participation_selection':
        return MaterialPageRoute(builder: (_) => ParticipationSelectionScreen());
      case '/consent_form':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ConsentFormScreen(
              participantCode: args['participantCode'] ?? '',
              researchSite: args['researchSite'] ?? 'gauteng',
              isTestingMode: args['isTestingMode'] ?? false,
            ),
          );
        }
        return _errorRoute();
      case '/data_sharing_preferences':
        return MaterialPageRoute(builder: (_) => DataSharingPreferencesScreen());
      case '/wellbeing_survey':
        return MaterialPageRoute(builder: (_) => WellbeingSurveyScreen());
      case '/wellbeing_map':
        return MaterialPageRoute(builder: (_) => WellbeingMapView());
      case '/wellbeing_timeline':
        return MaterialPageRoute(builder: (_) => WellbeingTimelineView());
      case '/change_mode':
        return MaterialPageRoute(builder: (_) => ChangeModeScreen());
      case '/help':
        return MaterialPageRoute(builder: (_) => HelpScreen());
      case '/participant_code_entry':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => ParticipantCodeEntryScreen(
              researchSite: args['researchSite'] ?? 'gauteng',
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => ParticipantCodeEntryScreen());
      default:
        // If there is no such named route in the switch statement, e.g. /third
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
          appBar: AppBar(
            title: Text('Error 404'),
          ),
          body: Center(
            child: Text("ERROR 404: named route doesn't exist"),
          ));
    });
  }
}
