import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:wellbeing_mapper/db/survey_database.dart';
import 'package:wellbeing_mapper/main.dart';
import 'package:wellbeing_mapper/models/app_mode.dart';
import 'package:wellbeing_mapper/services/app_mode_service.dart';
import 'package:wellbeing_mapper/services/consent_tracking_service.dart';
import 'package:wellbeing_mapper/ui/consent_form_screen.dart';

/// End-to-end test of the Italy-site consent submission: walks the real
/// widget flow and then checks the ConsentResponse actually stored in the
/// database, pinning the checkbox-to-field mapping and the separation
/// between practice (testing-mode) consent and real research consent.
void main() {
  late Directory tempDir;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('wm_consent_test_');
    await databaseFactory.setDatabasesPath(tempDir.path);
    SharedPreferences.setMockInitialValues({});
    GlobalData.userUUID = 'test-uuid-42';
  });

  tearDown(() async {
    await SurveyDatabase.resetForTesting();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('submitting the Italy form stores a faithful consent record',
      (WidgetTester tester) async {
    tester.view.physicalSize = Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: ConsentFormScreen(
          participantCode: 'TEST001',
          researchSite: 'wellbeing_mapper',
          isTestingMode: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Info sheet -> consent form.
    final continueButton = find.text('Continue to Consent Form');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pumpAndSettle();

    // Check all five required boxes.
    for (final text in [
      'to participate in this study',
      'to being asked about my race/ethnicity',
      'to being asked about my health condition',
      'to being asked about my sexual orientation',
      'to being asked about my location and mobility',
    ]) {
      final finder = find.textContaining(text);
      await tester.ensureVisible(finder);
      await tester.tap(finder);
      await tester.pump();
    }
    await tester.pumpAndSettle();

    // Submit. The save does real (FFI) database IO, which cannot complete
    // while the test clock is fake — give it real time via runAsync.
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();
    await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)));
    await tester.pump();
    expect(find.textContaining('Consent Recorded'), findsOneWidget);

    // The stored record reflects what was asked and answered.
    final stored =
        await tester.runAsync(() => SurveyDatabase().getConsent());
    expect(stored, isNotNull);
    expect(stored!.participantUuid, 'test-uuid-42');
    expect(stored.participantSignature, 'TEST001');
    expect(stored.informedConsent, isTrue);
    expect(stored.consentParticipate, isTrue);
    expect(stored.consentRaceEthnicity, isTrue);
    expect(stored.consentHealth, isTrue);
    expect(stored.consentSexualOrientation, isTrue);
    expect(stored.consentLocationMobility, isTrue);
    expect(stored.locationData, isTrue);
    // Questions the Italy form does not ask are recorded as not-applicable.
    expect(stored.consentQualtricsData, isFalse);
    expect(stored.consentDataTransfer, isFalse);
    expect(stored.consentPublicReporting, isFalse);
    expect(stored.consentResearcherSharing, isFalse);
    expect(stored.consentFurtherResearch, isFalse);
    expect(stored.consentPublicRepository, isFalse);
    expect(stored.consentFollowupContact, isFalse);
    expect(stored.dataSharing, isFalse);

    // Testing-mode practice consent must set the testing flag only: it must
    // never open the real research-consent gate on the same device.
    expect(
        await ConsentTrackingService.hasCompletedCurrentConsent(
            testingMode: true),
        isTrue);
    expect(await ConsentTrackingService.hasCompletedCurrentConsent(), isFalse,
        reason: 'practice consent must not satisfy the research gate');

    // The consent flow put the app into testing mode.
    expect(await AppModeService.getCurrentMode(), AppMode.private,
        reason: 'production-flavor test build refuses to store appTesting; '
            'the safe fallback is private');
  });
}
