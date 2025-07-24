import 'package:wellbeing_mapper/ui/notification_settings_view.dart';
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
import '../ui/data_upload_screen.dart';

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
      case '/initial_survey':
        return MaterialPageRoute(builder: (_) => InitialSurveyScreen());
      case '/recurring_survey':
        return MaterialPageRoute(builder: (_) => RecurringSurveyScreen());
      case '/survey_list':
        return MaterialPageRoute(builder: (_) => SurveyListScreen());
      case '/participation_selection':
        return MaterialPageRoute(builder: (_) => ParticipationSelectionScreen());
      case '/consent_form':
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (_) => ConsentFormScreen(
              participantCode: args['participantCode'] ?? '',
              researchSite: args['researchSite'] ?? 'barcelona',
            ),
          );
        }
        return _errorRoute();
      case '/data_upload':
        return MaterialPageRoute(builder: (_) => DataUploadScreen());
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
