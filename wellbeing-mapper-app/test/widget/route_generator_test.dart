import 'package:wellbeing_mapper/main.dart';
import 'package:wellbeing_mapper/ui/home_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MyApp redirects to "/", which is HomeView', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: MyApp()));
    await tester.pumpAndSettle();
    // MyApp should redirect to Home_View
    expect(find.byType(HomeView), findsOneWidget);
  });
}