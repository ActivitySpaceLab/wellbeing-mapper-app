import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:wellbeing_mapper/main.dart' as app;

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  
  group('Wellbeing Mapper Screenshots', () {
    testWidgets('01 - App Launch and Home Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 3));
      
      // Take screenshot of the home screen
      await binding.takeScreenshot('01_home_screen');
      
      // Add some debug info to help understand the app state
      print('Widgets found: ${find.byType(Widget).evaluate().length}');
    });

    testWidgets('02 - Participation Selection Screen', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for participation selection elements
      final participationText = find.textContaining('participation');
      final modeText = find.textContaining('mode');
      final privateText = find.textContaining('Private');
      final barcelonaText = find.textContaining('Barcelona');
      final gautengText = find.textContaining('Gauteng');
      
      print('Found participation text: ${participationText.evaluate().length}');
      print('Found mode text: ${modeText.evaluate().length}');
      print('Found private text: ${privateText.evaluate().length}');
      print('Found Barcelona text: ${barcelonaText.evaluate().length}');
      print('Found Gauteng text: ${gautengText.evaluate().length}');
      
      await binding.takeScreenshot('02_participation_selection');
    });

    testWidgets('03 - Navigate to Private Mode', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Try to find and interact with private mode option
      final privateButtons = find.textContaining('Private');
      if (privateButtons.evaluate().isNotEmpty) {
        await tester.tap(privateButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('03_private_mode_selected');
      } else {
        // Look for radio buttons or other selection widgets
        final radioButtons = find.byType(Radio);
        if (radioButtons.evaluate().isNotEmpty) {
          await tester.tap(radioButtons.first);
          await tester.pumpAndSettle();
          await binding.takeScreenshot('03_radio_selection');
        } else {
          await binding.takeScreenshot('03_current_state');
        }
      }
    });

    testWidgets('04 - Navigate to Barcelona Research', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for Barcelona research option
      final barcelonaButtons = find.textContaining('Barcelona');
      if (barcelonaButtons.evaluate().isNotEmpty) {
        await tester.tap(barcelonaButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('04_barcelona_research_mode');
      } else {
        // Try second radio button if available
        final radioButtons = find.byType(Radio);
        if (radioButtons.evaluate().length > 1) {
          await tester.tap(radioButtons.at(1));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('04_second_option_selected');
        } else {
          await binding.takeScreenshot('04_barcelona_fallback');
        }
      }
    });

    testWidgets('05 - Navigate to Gauteng Research', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for Gauteng research option
      final gautengButtons = find.textContaining('Gauteng');
      if (gautengButtons.evaluate().isNotEmpty) {
        await tester.tap(gautengButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('05_gauteng_research_mode');
      } else {
        // Try third radio button if available
        final radioButtons = find.byType(Radio);
        if (radioButtons.evaluate().length > 2) {
          await tester.tap(radioButtons.at(2));
          await tester.pumpAndSettle();
          await binding.takeScreenshot('05_third_option_selected');
        } else {
          await binding.takeScreenshot('05_gauteng_fallback');
        }
      }
    });

    testWidgets('06 - Main App Navigation', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for navigation elements
      final bottomNavBar = find.byType(BottomNavigationBar);
      final navDrawer = find.byType(Drawer);
      
      if (bottomNavBar.evaluate().isNotEmpty) {
        await binding.takeScreenshot('06_bottom_navigation');
      } else if (navDrawer.evaluate().isNotEmpty) {
        // Try to open drawer
        final menuButton = find.byIcon(Icons.menu);
        if (menuButton.evaluate().isNotEmpty) {
          await tester.tap(menuButton);
          await tester.pumpAndSettle();
          await binding.takeScreenshot('06_navigation_drawer');
        }
      } else {
        await binding.takeScreenshot('06_main_navigation');
      }
    });

    testWidgets('07 - Survey Interface', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for survey-related elements
      final surveyButtons = find.textContaining('Survey');
      final addButtons = find.byIcon(Icons.add);
      final formElements = find.byType(Form);
      
      if (surveyButtons.evaluate().isNotEmpty) {
        await tester.tap(surveyButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('07_survey_interface');
      } else if (addButtons.evaluate().isNotEmpty) {
        await tester.tap(addButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('07_add_survey');
      } else if (formElements.evaluate().isNotEmpty) {
        await binding.takeScreenshot('07_form_interface');
      } else {
        await binding.takeScreenshot('07_survey_fallback');
      }
    });

    testWidgets('08 - Map Interface', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for map-related elements
      final mapButtons = find.textContaining('Map');
      final mapIcons = find.byIcon(Icons.map);
      
      if (mapButtons.evaluate().isNotEmpty) {
        await tester.tap(mapButtons.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        await binding.takeScreenshot('08_map_interface');
      } else if (mapIcons.evaluate().isNotEmpty) {
        await tester.tap(mapIcons.first);
        await tester.pumpAndSettle(const Duration(seconds: 3));
        await binding.takeScreenshot('08_map_via_icon');
      } else {
        await binding.takeScreenshot('08_map_fallback');
      }
    });

    testWidgets('09 - Settings Interface', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for settings elements
      final settingsButtons = find.byIcon(Icons.settings);
      final menuButtons = find.byIcon(Icons.menu);
      
      if (settingsButtons.evaluate().isNotEmpty) {
        await tester.tap(settingsButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('09_settings_interface');
      } else if (menuButtons.evaluate().isNotEmpty) {
        await tester.tap(menuButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('09_menu_interface');
      } else {
        await binding.takeScreenshot('09_settings_fallback');
      }
    });

    testWidgets('10 - Data Upload Interface', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle(const Duration(seconds: 2));
      
      // Look for upload-related elements
      final uploadButtons = find.textContaining('Upload');
      final dataButtons = find.textContaining('Data');
      
      if (uploadButtons.evaluate().isNotEmpty) {
        await tester.tap(uploadButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('10_upload_interface');
      } else if (dataButtons.evaluate().isNotEmpty) {
        await tester.tap(dataButtons.first);
        await tester.pumpAndSettle();
        await binding.takeScreenshot('10_data_interface');
      } else {
        // Try to navigate through settings to find upload
        final settingsButtons = find.byIcon(Icons.settings);
        if (settingsButtons.evaluate().isNotEmpty) {
          await tester.tap(settingsButtons.first);
          await tester.pumpAndSettle();
          
          final uploadInSettings = find.textContaining('Upload');
          if (uploadInSettings.evaluate().isNotEmpty) {
            await tester.tap(uploadInSettings.first);
            await tester.pumpAndSettle();
            await binding.takeScreenshot('10_upload_from_settings');
          } else {
            await binding.takeScreenshot('10_settings_with_no_upload');
          }
        } else {
          await binding.takeScreenshot('10_upload_fallback');
        }
      }
    });
  });
}
