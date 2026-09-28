import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/main.dart';
import 'package:wellbeing_mapper/models/app_mode.dart';
import 'package:wellbeing_mapper/services/app_mode_service.dart';
import 'package:wellbeing_mapper/services/consent_tracking_service.dart';
import 'package:wellbeing_mapper/services/research_server_service.dart';

void main() {
  group('uploadBlockedReason', () {
    // How ParticipantValidationService records who accepted the code.
    Map<String, Object> validatedBy(String source) => {
          'validated_participant_code': 'a' * 64,
          'last_api_validation': source,
        };

    /// A participant in research mode who completed consent, with their
    /// code accepted by [source].
    Future<void> participant({required String source}) async {
      SharedPreferences.setMockInitialValues(validatedBy(source));
      GlobalData.userUUID = 'test-participant';
      await AppModeService.setCurrentMode(AppMode.research);
      await ConsentTrackingService.markConsentCompleted();
    }

    Future<String?> reason() =>
        ResearchServerService.uploadBlockedReason(serverConfigured: true);

    tearDown(() => GlobalData.userUUID = '');

    test('allows uploads for a consented participant the server accepted',
        () async {
      await participant(source: 'api');
      expect(await reason(), isNull);
    });

    test('blocks a participant whose code was only accepted offline',
        () async {
      // E.g. TESTER typed into a build without a server URL, then the app
      // updated to a build that has one.
      await participant(source: 'local_fallback');
      expect(await reason(), 'Participant code not confirmed by the research server');
    });

    test('blocks a code auto-accepted by a demo build', () async {
      await participant(source: 'demo_auto');
      expect(await reason(), 'Participant code not confirmed by the research server');
    });

    test('blocks when there is no validated code at all', () async {
      await participant(source: 'api');
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('validated_participant_code');
      expect(await reason(), 'Participant code not confirmed by the research server');
    });

    test('blocks outside research mode and before consent', () async {
      await participant(source: 'api');
      await AppModeService.setCurrentMode(AppMode.private);
      expect(await reason(), 'Not in research mode');

      SharedPreferences.setMockInitialValues(validatedBy('api'));
      GlobalData.userUUID = 'test-participant';
      await AppModeService.setCurrentMode(AppMode.research);
      expect(await reason(), 'Consent not completed');
    });

    test('blocks without a participant UUID or a server URL', () async {
      await participant(source: 'api');
      GlobalData.userUUID = '';
      expect(await reason(), 'No participant UUID');
      expect(await ResearchServerService.uploadBlockedReason(),
          'Research server not configured',
          reason: 'test builds carry no SERVER_BASE_URL');
    });
  });

  group('submissionIdFor', () {
    const uuid = '0b1f5e1e-4a7c-4d3a-9d2b-1c3e5f7a9b0d';

    test('is a SHA-256 hex digest the server accepts as a submission_id', () {
      final id = ResearchServerService.submissionIdFor(
          participantUuid: uuid, recordType: 'initial_survey', recordId: 7);
      expect(id, matches(RegExp(r'^[a-f0-9]{64}$')));
    });

    test('is the same for the same record, so a retry is not stored twice',
        () {
      String id() => ResearchServerService.submissionIdFor(
          participantUuid: uuid, recordType: 'biweekly_survey', recordId: 3);
      expect(id(), id());
    });

    test('differs between records, record types and participants', () {
      final ids = <String>{
        ResearchServerService.submissionIdFor(
            participantUuid: uuid, recordType: 'biweekly_survey', recordId: 3),
        ResearchServerService.submissionIdFor(
            participantUuid: uuid, recordType: 'biweekly_survey', recordId: 4),
        ResearchServerService.submissionIdFor(
            participantUuid: uuid, recordType: 'consent_form', recordId: 3),
        ResearchServerService.submissionIdFor(
            participantUuid: 'other', recordType: 'biweekly_survey', recordId: 3),
      };
      expect(ids, hasLength(4));
    });

    test('does not reveal the participant id', () {
      final id = ResearchServerService.submissionIdFor(
          participantUuid: uuid, recordType: 'initial_survey', recordId: 42);
      expect(id, isNot(contains(uuid)));
      expect(id, isNot(contains(uuid.substring(0, 8))));
    });
  });
}
