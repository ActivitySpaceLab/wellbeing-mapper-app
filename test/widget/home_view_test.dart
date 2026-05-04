import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic scaffold with title', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Wellbeing Mapper")),
        body: Center(child: Text("Welcome")),
      ),
    ));
    expect(find.text("Wellbeing Mapper"), findsOneWidget);
  });

  testWidgets('Basic icons test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: Text("Test"),
          leading: Icon(Icons.menu),
          actions: [Icon(Icons.gps_fixed)],
        ),
        body: Text("Test"),
      ),
    ));

    expect(find.byIcon(Icons.menu), findsOneWidget);
    expect(find.byIcon(Icons.gps_fixed), findsOneWidget);
  });

  // TODO: Add tests for wellbeing-related functionality when HomeView is more stable
}
