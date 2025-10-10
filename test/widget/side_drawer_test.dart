import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {

  testWidgets('Drawer opens from scaffold', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Wellbeing Mapper")),
        drawer: Drawer(
          child: ListView(
            children: [
              DrawerHeader(child: Text('Menu')),
              ListTile(title: Text('Item 1')),
            ],
          ),
        ),
        body: Text("Test"),
      ),
    ));

    final menuBtn = find.byIcon(Icons.menu);
    await tester.tap(menuBtn);
    await tester.pumpAndSettle();

    expect(find.byType(ListView), findsOneWidget);
    expect(find.text('Menu'), findsOneWidget);
  });
}