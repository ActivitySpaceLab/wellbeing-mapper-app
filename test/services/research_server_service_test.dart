import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/services/research_server_service.dart';

void main() {
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
