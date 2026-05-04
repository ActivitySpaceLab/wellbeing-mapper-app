import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/ui/consent_form_screen.dart';

void main() {
  group('Consent Form Tests', () {
    // tearDown(() {
    //   // Reset screen size after each test - deprecated API removed
    // });

    testWidgets('Should require all consent checkboxes for Gauteng research site', (WidgetTester tester) async {
      // Set a larger surface size to accommodate the long consent form
      tester.view.physicalSize = Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      // Build the consent form for Gauteng research site
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentFormScreen(
            participantCode: 'TEST001',
            researchSite: 'gauteng',
            isTestingMode: true,
          ),
        ),
      );

      // Wait for the widget to build
      await tester.pumpAndSettle();

      // Scroll to find the Continue button and tap it
      await tester.scrollUntilVisible(
        find.text('Continue to Consent Form'),
        500.0, // scroll distance
      );
      await tester.tap(find.text('Continue to Consent Form'));
      await tester.pumpAndSettle();

      // Try to find the submit button - it should be disabled initially
      expect(find.byType(ElevatedButton), findsOneWidget);
      
      // The button should be disabled when no consents are checked
      final ElevatedButton button = tester.widget(find.byType(ElevatedButton));
      expect(button.onPressed, isNull); // Disabled button has null onPressed

      // Check that we can find all the required consent checkboxes for Gauteng
      final requiredConsentTexts = [
        'to participate in this study',
        'for my personal data to be processed by Qualtrics',
        'to being asked about by race/ethnicity',
        'to being asked about my health',
        'to being asked about my sexual orientation', 
        'to being asked about my location and mobility',
        'to transferring my personal data to countries outside South Africa',
        'to researchers reporting what I contribute',
        'to what I contribute being shared with national and international researchers',
        'to what I contribute being used for further research',
        'to what I contribute being placed in a public repository',
      ];

      // Verify all required consent texts are present
      for (String consentText in requiredConsentTexts) {
        expect(find.textContaining(consentText), findsOneWidget);
      }

      // Find and check all required consent checkboxes
      for (String consentText in requiredConsentTexts) {
        // Scroll to make sure the checkbox is visible
        await tester.scrollUntilVisible(
          find.textContaining(consentText),
          200.0,
        );
        
        // Find the text widget first
        final textWidget = find.textContaining(consentText);
        expect(textWidget, findsOneWidget);
        
        // Tap the text to check the associated checkbox (they are in the same GestureDetector)
        await tester.tap(textWidget);
        await tester.pump();
      }

      // After checking all required boxes, the submit button should be enabled
      await tester.pumpAndSettle();
      final ElevatedButton enabledButton = tester.widget(find.byType(ElevatedButton));
      expect(enabledButton.onPressed, isNotNull); // Enabled button has non-null onPressed
    });

    testWidgets('Should allow optional follow-up consent to remain unchecked', (WidgetTester tester) async {
      // Set a larger surface size to accommodate the long consent form
      tester.view.physicalSize = Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      // Build the consent form for Gauteng research site
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentFormScreen(
            participantCode: 'TEST002',
            researchSite: 'gauteng',
            isTestingMode: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to find the Continue button and tap it
      await tester.scrollUntilVisible(
        find.text('Continue to Consent Form'),
        500.0, // scroll distance
      );
      await tester.tap(find.text('Continue to Consent Form'));
      await tester.pumpAndSettle();

      // Check all required consent boxes (same as previous test)
      final requiredConsentTexts = [
        'to participate in this study',
        'for my personal data to be processed by Qualtrics',
        'to being asked about by race/ethnicity',
        'to being asked about my health',
        'to being asked about my sexual orientation', 
        'to being asked about my location and mobility',
        'to transferring my personal data to countries outside South Africa',
        'to researchers reporting what I contribute',
        'to what I contribute being shared with national and international researchers',
        'to what I contribute being used for further research',
        'to what I contribute being placed in a public repository',
      ];

      for (String consentText in requiredConsentTexts) {
        // Scroll to make sure the checkbox is visible
        await tester.scrollUntilVisible(
          find.textContaining(consentText),
          200.0,
        );
        
        // Tap the text to check the associated checkbox
        await tester.tap(find.textContaining(consentText));
        await tester.pump();
      }

      // Verify the optional follow-up consent checkbox exists but is NOT required
      expect(find.textContaining('to being contacted about participation in possible follow-up studies'), findsOneWidget);

      // The submit button should be enabled even without checking the follow-up consent
      await tester.pumpAndSettle();
      final ElevatedButton enabledButton = tester.widget(find.byType(ElevatedButton));
      expect(enabledButton.onPressed, isNotNull);
    });

    testWidgets('Should disable submit button if any required consent is unchecked', (WidgetTester tester) async {
      // Set a larger surface size to accommodate the long consent form
      tester.view.physicalSize = Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: ConsentFormScreen(
            participantCode: 'TEST003',
            researchSite: 'gauteng',
            isTestingMode: true,
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Scroll to find the Continue button and tap it
      await tester.scrollUntilVisible(
        find.text('Continue to Consent Form'),
        500.0, // scroll distance
      );
      await tester.tap(find.text('Continue to Consent Form'));
      await tester.pumpAndSettle();

      // Check all required consent boxes except one
      final requiredConsentTexts = [
        'to participate in this study',
        'for my personal data to be processed by Qualtrics',
        'to being asked about by race/ethnicity',
        'to being asked about my health',
        'to being asked about my sexual orientation', 
        'to being asked about my location and mobility',
        'to transferring my personal data to countries outside South Africa',
        'to researchers reporting what I contribute',
        'to what I contribute being shared with national and international researchers',
        'to what I contribute being used for further research',
        // Intentionally skip 'to what I contribute being placed in a public repository'
      ];

      for (String consentText in requiredConsentTexts) {
        // Scroll to make sure the checkbox is visible
        await tester.scrollUntilVisible(
          find.textContaining(consentText),
          200.0,
        );
        
        // Tap the text to check the associated checkbox
        await tester.tap(find.textContaining(consentText));
        await tester.pump();
      }

      // The submit button should be disabled because we intentionally skipped one required consent
      await tester.pumpAndSettle();
      final ElevatedButton disabledButton = tester.widget(find.byType(ElevatedButton));
      expect(disabledButton.onPressed, isNull); // Disabled button has null onPressed
    });
  });
}
