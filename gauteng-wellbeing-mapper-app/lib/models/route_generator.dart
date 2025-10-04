import 'package:wellbeing_mapper/ui/notification_settings_view.dart';
import 'package:wellbeing_mapper/ui/storage_settings_view.dart';
import 'package:flutter/material.dart';

import '../ui/home_view.dart';
import '../ui/report_issues.dart';
import '../main.dart';

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



class GlobalRouteData {
  static String? user_route = "brown";
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;
    GlobalRouteData.user_route = settings.name;
    print('[RouteGenerator] ===============================');
    print('[RouteGenerator] ===============================');
    print('[RouteGenerator] ===============================');
    print('[RouteGenerator] generateRoute called for: ${settings.name}');
    print('[RouteGenerator] Arguments: $args');
    print('[RouteGenerator] ===============================');
    print('[RouteGenerator] ===============================');
    print('[RouteGenerator] ===============================');
    switch (settings.name) {
      case '/':
        print('[route_generator.dart] Creating InitialRouteDecider route');
        return MaterialPageRoute(
          settings: settings, // Preserve route settings for tests
          builder: (_) {
          print('[route_generator.dart] About to create InitialRouteDecider');
          try {
            return InitialRouteDecider();
          } catch (e) {
            print('[route_generator.dart] ERROR creating InitialRouteDecider: $e');
            return Scaffold(
              appBar: AppBar(title: Text('Error')),
              body: Center(child: Text('Error loading initial route: $e')),
            );
          }
        });
      case '/home':
        print('[route_generator.dart] Creating HomeView route');
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomeView('Wellbeing Mapper')
        );
      case '/report_an_issue':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ReportAnIssue()
        );
//      case '/my_statistics':
      //       return MaterialPageRoute(builder: (_) => MyStatistics());

      case '/notification_settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => NotificationSettingsView()
        );
      case '/storage_settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => StorageSettingsView()
        );
      case '/initial_survey':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => InitialSurveyScreen()
        );
      case '/recurring_survey':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RecurringSurveyScreen()
        );

      case '/survey_list':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SurveyListScreen()
        );
      case '/participation_selection':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ParticipationSelectionScreen()
        );
      case '/consent_form':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ConsentFormScreen(
              participantCode: args['participantCode'] ?? '',
              researchSite: args['researchSite'] ?? 'gauteng',
              isTestingMode: args['isTestingMode'] ?? false,
            ),
          );
        }
        return _errorRoute();
      case '/data_sharing_preferences':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DataSharingPreferencesScreen()
        );
      case '/wellbeing_survey':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => WellbeingSurveyScreen()
        );
      case '/wellbeing_map':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => WellbeingMapView()
        );
      case '/wellbeing_timeline':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => WellbeingTimelineView()
        );
      case '/change_mode':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeModeScreen()
        );
      case '/help':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HelpScreen()
        );
      case '/participant_code_entry':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ParticipantCodeEntryScreen(
              researchSite: args['researchSite'] ?? 'gauteng',
            ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ParticipantCodeEntryScreen()
        );
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
