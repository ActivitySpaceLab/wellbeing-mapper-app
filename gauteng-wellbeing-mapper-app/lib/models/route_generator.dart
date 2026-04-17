import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../main.dart';
import '../ui/change_mode_screen.dart';
import '../ui/consent_form_screen.dart';
import '../ui/data_sharing_preferences_screen.dart';
import '../ui/help_screen.dart';
import '../ui/home_view.dart';
import '../ui/initial_survey_screen.dart';
import '../ui/notification_settings_view.dart';
import '../ui/participant_code_entry_screen.dart';
import '../ui/participation_selection_screen.dart';
import '../ui/recurring_survey_screen.dart';
import '../ui/report_issues.dart';
import '../ui/storage_settings_view.dart';
import '../ui/survey_list_screen.dart';
import '../ui/wellbeing_map_view.dart';
import '../ui/wellbeing_survey_screen.dart';
import '../ui/wellbeing_timeline_view.dart';

class GlobalRouteData {
  static String? userRoute;
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    GlobalRouteData.userRoute = settings.name;
    debugPrint('[RouteGenerator] generateRoute: ${settings.name}');

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => InitialRouteDecider(),
        );
      case '/home':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HomeView('Wellbeing Mapper'),
        );
      case '/report_an_issue':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ReportAnIssue(),
        );
      case '/notification_settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => NotificationSettingsView(),
        );
      case '/storage_settings':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => StorageSettingsView(),
        );
      case '/initial_survey':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => InitialSurveyScreen(),
        );
      case '/recurring_survey':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => RecurringSurveyScreen(),
        );
      case '/survey_list':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => SurveyListScreen(),
        );
      case '/participation_selection':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ParticipationSelectionScreen(),
        );
      case '/consent_form':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ConsentFormScreen(
              participantCode: args['participantCode'] as String? ?? '',
              researchSite: args['researchSite'] as String? ?? 'barcelona',
              isTestingMode: args['isTestingMode'] as bool? ?? false,
            ),
          );
        }
        return _errorRoute();
      case '/data_sharing_preferences':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => DataSharingPreferencesScreen(),
        );
      case '/wellbeing_survey':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => WellbeingSurveyScreen(),
        );
      case '/wellbeing_map':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => WellbeingMapView(),
        );
      case '/wellbeing_timeline':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => WellbeingTimelineView(),
        );
      case '/change_mode':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ChangeModeScreen(),
        );
      case '/help':
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => HelpScreen(),
        );
      case '/participant_code_entry':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => ParticipantCodeEntryScreen(
              researchSite: args['researchSite'] as String? ?? 'barcelona',
            ),
          );
        }
        return MaterialPageRoute(
          settings: settings,
          builder: (_) => ParticipantCodeEntryScreen(),
        );
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error 404')),
        body: const Center(
          child: Text("ERROR 404: named route doesn't exist"),
        ),
      );
    });
  }
}
