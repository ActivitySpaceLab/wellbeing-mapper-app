import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wellbeing_mapper/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Store Screenshots', () {
    testWidgets('Capture key app screens for App Store', (WidgetTester tester) async {
      // Launch the app
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Helper function to take screenshot with proper naming
      Future<void> takeScreenshot(String name) async {
        await tester.pumpAndSettle();
        
        // Take screenshot using integration test binding
        await binding.takeScreenshot(name);
        
        // Add a small delay to ensure screenshot is processed
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }

      // Screenshot 1: App Mode Selection (first screen users see)
      print('📸 Capturing App Mode Selection screen...');
      await takeScreenshot('01_app_mode_selection');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Select Private Mode to continue
      final privateModeButton = find.text('Private Mode');
      if (privateModeButton.evaluate().isNotEmpty) {
        await tester.tap(privateModeButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Screenshot 2: Main Home Screen with location tracking
      print('📸 Capturing Main Home screen...');
      await takeScreenshot('02_main_home_screen');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Open side drawer to show app features
      final drawerButton = find.byIcon(Icons.menu);
      if (drawerButton.evaluate().isNotEmpty) {
        await tester.tap(drawerButton);
        await tester.pumpAndSettle(const Duration(seconds: 1));

        // Screenshot 3: Side Drawer with app features
        print('📸 Capturing Side Drawer menu...');
        await takeScreenshot('03_side_drawer_menu');
        await tester.pumpAndSettle();

        // Navigate to Wellbeing Map
        final wellbeingMapTile = find.text('Wellbeing Map');
        if (wellbeingMapTile.evaluate().isNotEmpty) {
          await tester.tap(wellbeingMapTile);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Screenshot 4: Wellbeing Map View
          print('📸 Capturing Wellbeing Map...');
          await takeScreenshot('04_wellbeing_map');
          await tester.pumpAndSettle();

          // Go back to main menu
          final backButton = find.byIcon(Icons.arrow_back);
          if (backButton.evaluate().isNotEmpty) {
            await tester.tap(backButton);
            await tester.pumpAndSettle(const Duration(seconds: 1));
          }
        }

        // Open drawer again if needed
        final drawerButton2 = find.byIcon(Icons.menu);
        if (drawerButton2.evaluate().isNotEmpty) {
          await tester.tap(drawerButton2);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }

        // Navigate to Wellbeing Timeline
        final wellbeingTimelineTile = find.text('Wellbeing Timeline');
        if (wellbeingTimelineTile.evaluate().isNotEmpty) {
          await tester.tap(wellbeingTimelineTile);
          await tester.pumpAndSettle(const Duration(seconds: 3));

          // Screenshot 5: Wellbeing Timeline
          print('📸 Capturing Wellbeing Timeline...');
          await takeScreenshot('05_wellbeing_timeline');
          await tester.pumpAndSettle();

          // Go back to main menu
          final backButton2 = find.byIcon(Icons.arrow_back);
          if (backButton2.evaluate().isNotEmpty) {
            await tester.tap(backButton2);
            await tester.pumpAndSettle(const Duration(seconds: 1));
          }
        }

        // Open drawer one more time for app mode demonstration
        final drawerButton3 = find.byIcon(Icons.menu);
        if (drawerButton3.evaluate().isNotEmpty) {
          await tester.tap(drawerButton3);
          await tester.pumpAndSettle(const Duration(seconds: 1));

          // Navigate to App Mode change
          final appModeTile = find.text('App Mode');
          if (appModeTile.evaluate().isNotEmpty) {
            await tester.tap(appModeTile);
            await tester.pumpAndSettle(const Duration(seconds: 2));

            // Screenshot 6: App Mode Selection showing research features
            print('📸 Capturing App Mode selection with research features...');
            await takeScreenshot('06_app_modes_research');
            await tester.pumpAndSettle();

            // Select Research Mode to show research features
            final researchModeButton = find.text('Research Mode');
            if (researchModeButton.evaluate().isNotEmpty) {
              await tester.tap(researchModeButton);
              await tester.pumpAndSettle(const Duration(seconds: 2));

              // Confirm if there's a confirmation dialog
              final confirmButton = find.text('Continue');
              if (confirmButton.evaluate().isNotEmpty) {
                await tester.tap(confirmButton);
                await tester.pumpAndSettle(const Duration(seconds: 2));
              }

              // Go back to home screen
              final backButton3 = find.byIcon(Icons.arrow_back);
              if (backButton3.evaluate().isNotEmpty) {
                await tester.tap(backButton3);
                await tester.pumpAndSettle(const Duration(seconds: 1));
              }

              // Open drawer to show research features
              final drawerButton4 = find.byIcon(Icons.menu);
              if (drawerButton4.evaluate().isNotEmpty) {
                await tester.tap(drawerButton4);
                await tester.pumpAndSettle(const Duration(seconds: 1));

                // Screenshot 7: Side Drawer with Research Mode features
                print('📸 Capturing Side Drawer in Research Mode...');
                await takeScreenshot('07_research_mode_features');
                await tester.pumpAndSettle();
              }
            }
          }
        }
      }

      print('📸 Screenshot capture completed!');
      print('Screenshots saved for App Store submission');
    });
  });
}
