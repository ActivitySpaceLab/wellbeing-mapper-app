import 'package:flutter/material.dart';

class SurveyNavigationService {
  /// Navigate to initial survey (native Flutter surveys only)
  static Future<void> navigateToInitialSurvey(BuildContext context, {String? locationJson}) async {
    debugPrint('[SurveyNavigation] Using native Flutter initial survey...');
    Navigator.of(context).pushNamed('/initial_survey');
  }
  
  /// Navigate to biweekly/recurring survey (native Flutter surveys only)
  static Future<void> navigateToBiweeklySurvey(BuildContext context, {String? locationJson}) async {
    debugPrint('[SurveyNavigation] Using native Flutter biweekly survey...');
    Navigator.of(context).pushNamed('/recurring_survey');
  }
}
