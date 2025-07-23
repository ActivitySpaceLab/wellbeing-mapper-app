import 'package:wellbeing_mapper/ui/notification_settings_view.dart';
import 'package:flutter/material.dart';

import '../ui/home_view.dart';
import '../ui/list_view.dart';
import '../ui/report_issues.dart';
import '../ui/web_view.dart';

class GlobalRouteData {
  static String? user_route = "brown";
}

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;
    GlobalRouteData.user_route = settings.name;
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => HomeView('Space Mapper'));
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
