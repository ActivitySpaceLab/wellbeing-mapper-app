import 'package:wellbeing_mapper/ui/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeView has a title', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeView("Space Mapper")));
    expect(find.text("Space Mapper"), findsOneWidget);
  });

  testWidgets('Find icons on home view', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: HomeView("Space Mapper")));

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
    // TODO: Update this test for wellbeing app features
  });

  // TODO: Add tests for wellbeing-related functionality
}
