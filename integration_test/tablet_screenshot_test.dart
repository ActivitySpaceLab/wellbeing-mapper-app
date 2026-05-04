import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wellbeing_mapper/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  // Configure screenshot directory based on device type
  String getScreenshotPath(String screenName) {
    final size = binding.platformDispatcher.views.first.physicalSize;
    final devicePixelRatio = binding.platformDispatcher.views.first.devicePixelRatio;
    final logicalSize = size / devicePixelRatio;
    
    String deviceType;
    if (logicalSize.shortestSide >= 600) {
      if (logicalSize.shortestSide >= 900) {
        deviceType = '10inch_tablet';
      } else {
        deviceType = '7inch_tablet';
      }
    } else {
      deviceType = 'phone';
    }
    
    return '${deviceType}_${screenName}';
  }
  
  // Helper to wait for app to be ready
  Future<void> waitForAppReady(WidgetTester tester) async {
    await tester.pumpAndSettle(const Duration(seconds: 3));
    // Wait for MaterialApp to be ready
    expect(find.byType(MaterialApp), findsOneWidget);
  }
  
  // Helper to take screenshot with retry logic
  Future<void> takeScreenshotSafely(String screenName, {int retries = 3}) async {
    for (int i = 0; i < retries; i++) {
      try {
        await binding.takeScreenshot(getScreenshotPath(screenName));
        print('✅ Screenshot taken: ${getScreenshotPath(screenName)}');
        return;
      } catch (e) {
        print('⚠️  Screenshot attempt ${i + 1} failed: $e');
        if (i == retries - 1) rethrow;
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }
  }
  
  group('Tablet Screenshots for Google Play Store', () {
    testWidgets('01 - App Launch and Participation Selection', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Print device info for debugging
      final view = tester.view;
      final screenSize = view.physicalSize;
      final devicePixelRatio = view.devicePixelRatio;
      final logicalSize = screenSize / devicePixelRatio;
      
      print('Tablet mode screenshot test');
      print('   Physical size: ${screenSize.width} x ${screenSize.height}');
      print('   Device pixel ratio: $devicePixelRatio');
      print('   Logical size: ${logicalSize.width} x ${logicalSize.height}');
      print('   Shortest side: ${logicalSize.shortestSide}');
      
      // Take screenshot of the initial screen (participation selection)
      await takeScreenshotSafely('01_participation_selection');
    });

    testWidgets('02 - Private Mode Selection and Main App', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Find and tap private mode
      final privateModeOptions = find.textContaining('Private');
      if (privateModeOptions.evaluate().isNotEmpty) {
        await tester.tap(privateModeOptions.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await takeScreenshotSafely('02_private_mode_main');
        
        // Wait for main app to load
        await tester.pumpAndSettle(const Duration(seconds: 2));
        await takeScreenshotSafely('02_main_app_home');
      } else {
        print('⚠️  Private mode option not found');
        await takeScreenshotSafely('02_fallback_screen');
      }
    });

    testWidgets('03 - Map Interface Navigation', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Navigate to private mode first
      final privateModeOptions = find.textContaining('Private');
      if (privateModeOptions.evaluate().isNotEmpty) {
        await tester.tap(privateModeOptions.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Look for map navigation elements
        final mapButton = find.textContaining('Map');
        final mapIcon = find.byIcon(Icons.map);
        final bottomNav = find.byType(BottomNavigationBar);
        
        if (mapButton.evaluate().isNotEmpty) {
          await tester.tap(mapButton.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          await takeScreenshotSafely('03_map_interface');
        } else if (mapIcon.evaluate().isNotEmpty) {
          await tester.tap(mapIcon.first);
          await tester.pumpAndSettle(const Duration(seconds: 3));
          await takeScreenshotSafely('03_map_via_icon');
        } else if (bottomNav.evaluate().isNotEmpty) {
          // Try tapping on different tabs to find map
          await tester.tap(bottomNav.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('03_bottom_nav_tab1');
          
          // Try second tab if exists
          final tabs = find.descendant(of: bottomNav, matching: find.byType(GestureDetector));
          if (tabs.evaluate().length > 1) {
            await tester.tap(tabs.at(1));
            await tester.pumpAndSettle(const Duration(seconds: 2));
            await takeScreenshotSafely('03_bottom_nav_tab2');
          }
        } else {
          await takeScreenshotSafely('03_main_interface_overview');
        }
      }
    });

    testWidgets('04 - Survey Interface and Forms', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Navigate to private mode
      final privateModeOptions = find.textContaining('Private');
      if (privateModeOptions.evaluate().isNotEmpty) {
        await tester.tap(privateModeOptions.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Look for survey-related elements
        final surveyButton = find.textContaining('Survey');
        final addButton = find.byIcon(Icons.add);
        final floatingActionButton = find.byType(FloatingActionButton);
        
        if (surveyButton.evaluate().isNotEmpty) {
          await tester.tap(surveyButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('04_survey_interface');
        } else if (floatingActionButton.evaluate().isNotEmpty) {
          await tester.tap(floatingActionButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('04_fab_survey_form');
        } else if (addButton.evaluate().isNotEmpty) {
          await tester.tap(addButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('04_add_survey_form');
        } else {
          await takeScreenshotSafely('04_main_screen_features');
        }
      }
    });

    testWidgets('05 - Barcelona Research Mode Flow', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Navigate to Barcelona research mode
      final barcelonaOption = find.textContaining('Barcelona');
      if (barcelonaOption.evaluate().isNotEmpty) {
        await tester.tap(barcelonaOption.first);
        await tester.pumpAndSettle();
        await takeScreenshotSafely('05_barcelona_research_selection');
        
        // Look for consent form or next step
        final continueButton = find.textContaining('Continue');
        final nextButton = find.textContaining('Next');
        final agreeButton = find.textContaining('Agree');
        
        if (continueButton.evaluate().isNotEmpty) {
          await takeScreenshotSafely('05_barcelona_consent_step1');
          await tester.tap(continueButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('05_barcelona_consent_step2');
        } else if (nextButton.evaluate().isNotEmpty) {
          await takeScreenshotSafely('05_barcelona_next_step');
        } else if (agreeButton.evaluate().isNotEmpty) {
          await takeScreenshotSafely('05_barcelona_consent_form');
        } else {
          await takeScreenshotSafely('05_barcelona_research_mode');
        }
      } else {
        print('⚠️  Barcelona research option not found');
        await takeScreenshotSafely('05_research_options_fallback');
      }
    });

    testWidgets('06 - Settings and Configuration', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Navigate to private mode first
      final privateModeOptions = find.textContaining('Private');
      if (privateModeOptions.evaluate().isNotEmpty) {
        await tester.tap(privateModeOptions.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Look for settings or menu
        final settingsIcon = find.byIcon(Icons.settings);
        final menuIcon = find.byIcon(Icons.menu);
        final moreIcon = find.byIcon(Icons.more_vert);
        
        if (settingsIcon.evaluate().isNotEmpty) {
          await tester.tap(settingsIcon.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('06_settings_interface');
        } else if (menuIcon.evaluate().isNotEmpty) {
          await tester.tap(menuIcon.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('06_navigation_drawer');
        } else if (moreIcon.evaluate().isNotEmpty) {
          await tester.tap(moreIcon.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('06_more_options_menu');
        } else {
          // Try to access settings through app bar or other means
          final appBar = find.byType(AppBar);
          if (appBar.evaluate().isNotEmpty) {
            await takeScreenshotSafely('06_app_interface_with_appbar');
          } else {
            await takeScreenshotSafely('06_main_interface_complete');
          }
        }
      }
    });

    testWidgets('07 - Data Visualization and Reports', (WidgetTester tester) async {
      app.main();
      await waitForAppReady(tester);
      
      // Navigate to private mode
      final privateModeOptions = find.textContaining('Private');
      if (privateModeOptions.evaluate().isNotEmpty) {
        await tester.tap(privateModeOptions.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));
        
        // Look for data visualization elements
        final dataButton = find.textContaining('Data');
        final reportsButton = find.textContaining('Reports');
        final chartButton = find.textContaining('Chart');
        final analyticsButton = find.textContaining('Analytics');
        
        if (dataButton.evaluate().isNotEmpty) {
          await tester.tap(dataButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('07_data_visualization');
        } else if (reportsButton.evaluate().isNotEmpty) {
          await tester.tap(reportsButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('07_reports_interface');
        } else if (chartButton.evaluate().isNotEmpty) {
          await tester.tap(chartButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('07_chart_interface');
        } else if (analyticsButton.evaluate().isNotEmpty) {
          await tester.tap(analyticsButton.first);
          await tester.pumpAndSettle();
          await takeScreenshotSafely('07_analytics_interface');
        } else {
          // Navigate through bottom tabs to find data screens
          final bottomNav = find.byType(BottomNavigationBar);
          if (bottomNav.evaluate().isNotEmpty) {
            final tabs = find.descendant(of: bottomNav, matching: find.byType(GestureDetector));
            if (tabs.evaluate().length > 2) {
              await tester.tap(tabs.at(2));
              await tester.pumpAndSettle(const Duration(seconds: 2));
              await takeScreenshotSafely('07_third_tab_interface');
            }
          } else {
            await takeScreenshotSafely('07_app_features_overview');
          }
        }
      }
    });
  });
}
