import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:wellbeing_mapper/models/route_generator.dart';
import 'package:wellbeing_mapper/ui/home_view.dart';
import 'package:wellbeing_mapper/ui/participation_selection_screen.dart';

void main() {
  group('Route Generator Navigation Tests', () {
    setUp(() async {
      // Initialize SharedPreferences for testing
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('RouteGenerator should handle / route', (WidgetTester tester) async {
      // Test the RouteGenerator directly
      const settings = RouteSettings(name: '/');
      final route = RouteGenerator.generateRoute(settings);
      
      expect(route, isA<MaterialPageRoute>());
      expect(route.settings.name, equals('/'));
      
      // Verify the route builds without error
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) => RouteGenerator.generateRoute(settings),
        initialRoute: '/',
      ));
      
      // Should show some kind of scaffold (InitialRouteDecider or error)
      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('RouteGenerator should handle /home route', (WidgetTester tester) async {
      // Test the /home route specifically
      const settings = RouteSettings(name: '/home');
      final route = RouteGenerator.generateRoute(settings);
      
      expect(route, isA<MaterialPageRoute>());
      
      // Build a test app with this route
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) => RouteGenerator.generateRoute(settings),
        initialRoute: '/home',
      ));
      
      await tester.pumpAndSettle();
      
      // Should create HomeView
      expect(find.byType(HomeView), findsOneWidget);
    });

    testWidgets('RouteGenerator should handle /participation_selection route', (WidgetTester tester) async {
      // Test the participation selection route
      const settings = RouteSettings(name: '/participation_selection');
      final route = RouteGenerator.generateRoute(settings);
      
      expect(route, isA<MaterialPageRoute>());
      expect(route.settings.name, equals('/participation_selection'));
      
      // Build a test app with this route directly (bypassing InitialRouteDecider)
      await tester.pumpWidget(MaterialApp(
        home: ParticipationSelectionScreen(),
      ));
      
      await tester.pumpAndSettle();
      
      expect(find.byType(ParticipationSelectionScreen), findsOneWidget);
    });

    testWidgets('Navigation calls should trigger onGenerateRoute', (WidgetTester tester) async {
      final List<String> routeHistory = [];

      // Create a test app with route logging
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          routeHistory.add(settings.name ?? 'null');
          print('[TEST] Route generated: ${settings.name}');
          
          // Return a simple route for testing
          return MaterialPageRoute(
            settings: settings,
            builder: (_) => Scaffold(
              appBar: AppBar(title: Text('Route: ${settings.name}')),
              body: Center(
                child: Column(
                  children: [
                    Text('Current route: ${settings.name}'),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(_).pushNamedAndRemoveUntil('/home', (route) => false);
                      },
                      child: Text('Navigate to /home'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
        initialRoute: '/test',
      ));

      await tester.pumpAndSettle();

      // Verify initial route was generated
      expect(routeHistory, contains('/test'));

      // Tap the navigation button
      final navButton = find.text('Navigate to /home');
      await tester.tap(navButton);
      await tester.pumpAndSettle();

      // Verify /home route was generated
      expect(routeHistory, contains('/home'));
      print('[TEST] Final route history: $routeHistory');
    });

    testWidgets('Full app navigation should work with RouteGenerator', (WidgetTester tester) async {
      final List<String> routeHistory = [];

      // Test that the RouteGenerator can create routes properly
      // instead of testing complex navigation flows that depend on app state
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          routeHistory.add(settings.name ?? 'null');
          print('[TEST] Route generated: ${settings.name}');
          return RouteGenerator.generateRoute(settings);
        },
        initialRoute: '/',
      ));

      await tester.pumpAndSettle();

      // Verify that routes were generated 
      expect(routeHistory, contains('/'));
      
      // Should navigate to HomeView via InitialRouteDecider logic
      expect(find.byType(HomeView), findsOneWidget);
      
      print('[TEST] Route history after initial load: $routeHistory');
    });

    test('RouteGenerator should handle unknown routes', () {
      // Test unknown route handling
      const settings = RouteSettings(name: '/unknown');
      final route = RouteGenerator.generateRoute(settings);
      
      expect(route, isA<MaterialPageRoute>());
      // Should return some kind of error or fallback route
    });
  });

  group('Navigation Context Tests', () {
    testWidgets('pushNamedAndRemoveUntil should trigger route generation', (WidgetTester tester) async {
      final List<String> routeHistory = [];
      
      await tester.pumpWidget(MaterialApp(
        onGenerateRoute: (settings) {
          routeHistory.add(settings.name ?? 'null');
          return MaterialPageRoute(
            settings: settings,
            builder: (context) => Scaffold(
              appBar: AppBar(title: Text('Route: ${settings.name}')),
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    print('[TEST] About to call pushNamedAndRemoveUntil');
                    Navigator.of(context).pushNamedAndRemoveUntil('/target', (route) => false);
                    print('[TEST] pushNamedAndRemoveUntil call completed');
                  },
                  child: Text('Navigate'),
                ),
              ),
            ),
          );
        },
        initialRoute: '/start',
      ));

      await tester.pumpAndSettle();
      expect(routeHistory, contains('/start'));

      // Test the navigation call
      final button = find.text('Navigate');
      expect(button, findsOneWidget);
      
      await tester.tap(button);
      await tester.pumpAndSettle();
      
      // Should have triggered route generation for /target
      expect(routeHistory, contains('/target'));
      print('[TEST] Navigation test route history: $routeHistory');
    });
  });
}