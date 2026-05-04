import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../lib/main.dart' as app;

// TODO: Fix this function to avoid code repetition in the tests below.
// Uncommenting this will make the integration tests fail
// Finds and presses go back button
/*void goBack(WidgetTester tester) async {
  final Finder arrowBackBtn = find.byIcon(Icons.arrow_back);
  await tester.tap(arrowBackBtn);
  await tester.pumpAndSettle();
}*/

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('Integration test. Navigate through all screens',
        (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // TODO: Add tests for wellbeing-related features

      // Open the menu and start going through all screens
      final Finder menuBtn = find.byIcon(Icons.menu);
      await tester.tap(menuBtn);
      await tester.pumpAndSettle();

      // ListView Element => Location History (removed project functionality)
      final Finder locationHistoryBtn = find.byIcon(Icons.list);
      await tester.tap(locationHistoryBtn);
      await tester.pumpAndSettle();
      // Finds and presses go back button
      final Finder arrowBackBtn1 = find.byIcon(Icons.arrow_back);
      await tester.tap(arrowBackBtn1);
      await tester.pumpAndSettle();

      // ListView Element => Report an Issue
      final Finder reportIssueBtn = find.byIcon(Icons.report_problem_outlined);
      await tester.tap(reportIssueBtn);
      await tester.pumpAndSettle();
      // Finds and presses go back button
      final Finder arrowBackBtn2 = find.byIcon(Icons.arrow_back);
      await tester.tap(arrowBackBtn2);
      await tester.pumpAndSettle();

      // ListView Element => Statistics
      final Finder statisticsBtn = find.byIcon(Icons.bar_chart);
      await tester.tap(statisticsBtn);
      await tester.pumpAndSettle();
      // Finds and presses go back button
      final Finder arrowBackBtn3 = find.byIcon(Icons.arrow_back);
      await tester.tap(arrowBackBtn3);
      await tester.pumpAndSettle();
    });
  });
}
