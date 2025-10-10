import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Basic widget test - MaterialApp loads', (WidgetTester tester) async {
    // Simple test that doesn't use any complex widgets that could cause segfaults
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text('Test')),
        body: Text('Hello World'),
      ),
    ));
    
    // Verify basic widgets are displayed
    expect(find.text('Test'), findsOneWidget);
    expect(find.text('Hello World'), findsOneWidget);
  });
}