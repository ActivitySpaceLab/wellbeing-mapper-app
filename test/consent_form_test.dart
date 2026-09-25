import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../lib/ui/consent_form_screen.dart';

/// Tests for [ConsentFormScreen].
///
/// The live app always passes researchSite 'wellbeing_mapper' (the Italy /
/// Southern Europe site); 'barcelona' is a legacy fallback that is only
/// reachable when route arguments omit the site. Both branches are covered
/// here so a regression in either shows up.
void main() {
  setUp(() {
    // ConsentFormScreen checks ConsentTrackingService on init; give it an
    // empty prefs store so no prior consent is found and the form renders.
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> pumpConsentScreen(
    WidgetTester tester, {
    String researchSite = 'wellbeing_mapper',
  }) async {
    tester.view.physicalSize = Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ConsentFormScreen(
          participantCode: 'TEST001',
          researchSite: researchSite,
          isTestingMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Taps the info sheet's continue button to reach the consent checkboxes.
  Future<void> continueToConsentForm(WidgetTester tester) async {
    final continueButton = find.text('Continue to Consent Form');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();
  }

  /// Checks a consent checkbox by tapping its label text.
  Future<void> tapConsentText(WidgetTester tester, String text) async {
    final finder = find.textContaining(text);
    expect(finder, findsOneWidget, reason: 'consent item "$text" should exist');
    await tester.ensureVisible(finder);
    await tester.tap(finder);
    await tester.pump();
  }

  ElevatedButton submitButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(find.byType(ElevatedButton));

  // The five required consent items on the Italy-site form (English locale).
  const italyConsentTexts = [
    'to participate in this study',
    'to being asked about my race/ethnicity',
    'to being asked about my health condition',
    'to being asked about my sexual orientation',
    'to being asked about my location and mobility',
  ];

  group('Italy site (wellbeing_mapper)', () {
    testWidgets('information sheet shows key sections and leads to the form',
        (WidgetTester tester) async {
      await pumpConsentScreen(tester);

      // Info sheet first.
      expect(find.text('Continue to Consent Form'), findsOneWidget);
      expect(find.textContaining('Universitat Pompeu Fabra'), findsWidgets);
      expect(find.textContaining('Compensation'), findsOneWidget);
      expect(find.textContaining('Data protection'), findsOneWidget);

      await continueToConsentForm(tester);

      expect(find.text('Informed Consent Form'), findsOneWidget);
      expect(find.textContaining('Participant Code: TEST001'), findsOneWidget);
    });

    testWidgets('submit stays disabled until all five consents are checked',
        (WidgetTester tester) async {
      await pumpConsentScreen(tester);
      await continueToConsentForm(tester);

      expect(submitButton(tester).onPressed, isNull,
          reason: 'submit must be disabled with nothing checked');

      for (final text in italyConsentTexts) {
        await tapConsentText(tester, text);
      }
      await tester.pumpAndSettle();

      expect(submitButton(tester).onPressed, isNotNull,
          reason: 'submit must be enabled once every item is checked');
    });

    testWidgets('submit stays disabled when one consent is left unchecked',
        (WidgetTester tester) async {
      await pumpConsentScreen(tester);
      await continueToConsentForm(tester);

      // Check all but the last item.
      for (final text
          in italyConsentTexts.sublist(0, italyConsentTexts.length - 1)) {
        await tapConsentText(tester, text);
      }
      await tester.pumpAndSettle();

      expect(submitButton(tester).onPressed, isNull);
      expect(
        find.textContaining('Please check all required consent items'),
        findsOneWidget,
      );
    });

    testWidgets('unchecking a consent disables submit again',
        (WidgetTester tester) async {
      await pumpConsentScreen(tester);
      await continueToConsentForm(tester);

      for (final text in italyConsentTexts) {
        await tapConsentText(tester, text);
      }
      await tester.pumpAndSettle();
      expect(submitButton(tester).onPressed, isNotNull);

      await tapConsentText(tester, italyConsentTexts.first);
      await tester.pumpAndSettle();
      expect(submitButton(tester).onPressed, isNull);
    });
  });

  group('Legacy site fallback (barcelona)', () {
    // The seven required consent items on the legacy form.
    const legacyConsentTexts = [
      'My participation is voluntary',
      'To participate in this study',
      'To being asked about my race/ethnicity',
      'To being asked about my health condition',
      'To being asked about my sexual orientation',
      'To being asked about my location and mobility',
      'To transferring my personal data to countries outside the European Economic Area',
    ];

    testWidgets('requires all seven consents; LimeSurvey item stays optional',
        (WidgetTester tester) async {
      await pumpConsentScreen(tester, researchSite: 'barcelona');
      await continueToConsentForm(tester);

      expect(submitButton(tester).onPressed, isNull);

      // The LimeSurvey processing consent is optional (no trailing *).
      expect(
        find.textContaining('LimeSurvey GmbH'),
        findsOneWidget,
      );

      for (final text in legacyConsentTexts) {
        await tapConsentText(tester, text);
      }
      await tester.pumpAndSettle();

      expect(submitButton(tester).onPressed, isNotNull,
          reason: 'all required items checked; optional item left unchecked');
    });
  });
}
