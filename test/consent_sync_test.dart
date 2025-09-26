import 'package:flutter_test/flutter_test.dart';
import '../lib/models/consent_models.dart';

void main() {
  group('Consent Data Sync Tests', () {
    test('Should sync all 12 consent questions to Qualtrics correctly', () async {
      // Create a sample consent response with all Gauteng fields
      final consent = ConsentResponse(
        participantUuid: 'test-uuid-123',
        informedConsent: true,
        dataProcessing: true,
        locationData: true,
        surveyData: true,
        dataRetention: true,
        dataSharing: true,
        voluntaryParticipation: true,
        consentedAt: DateTime.now(),
        participantSignature: 'TEST001',
        // Gauteng-specific consent fields
        consentParticipate: true,
        consentQualtricsData: true,
        consentRaceEthnicity: true,
        consentHealth: true,
        consentSexualOrientation: true,
        consentLocationMobility: true,
        consentDataTransfer: true,
        consentPublicReporting: true,
        consentResearcherSharing: true,
        consentFurtherResearch: true,
        consentPublicRepository: true,
        consentFollowupContact: false, // Optional one set to false
      );

      // Convert consent to Qualtrics format and verify structure
      final qualtricsData = consent.toQualtricsJson();
      
      // Verify all 12 consent questions are included in the sync data
      expect(qualtricsData['CONSENT_PARTICIPATE'], equals('1'));
      expect(qualtricsData['CONSENT_QUALTRICS_DATA'], equals('1'));
      expect(qualtricsData['CONSENT_RACE_ETHNICITY'], equals('1'));
      expect(qualtricsData['CONSENT_HEALTH'], equals('1'));
      expect(qualtricsData['CONSENT_SEXUAL_ORIENTATION'], equals('1'));
      expect(qualtricsData['CONSENT_LOCATION_MOBILITY'], equals('1'));
      expect(qualtricsData['CONSENT_DATA_TRANSFER'], equals('1'));
      expect(qualtricsData['CONSENT_PUBLIC_REPORTING'], equals('1'));
      expect(qualtricsData['CONSENT_RESEARCHER_SHARING'], equals('1'));
      expect(qualtricsData['CONSENT_FURTHER_RESEARCH'], equals('1'));
      expect(qualtricsData['CONSENT_PUBLIC_REPOSITORY'], equals('1'));
      expect(qualtricsData['CONSENT_FOLLOWUP_CONTACT'], equals('0')); // This one is false

      // Verify participant metadata is included
      expect(qualtricsData['PARTICIPANT_CODE'], equals('TEST001'));
      expect(qualtricsData['PARTICIPANT_UUID'], equals('test-uuid-123'));
      expect(qualtricsData['CONSENTED_AT'], isNotNull);
    });

    test('Should correctly map false consent values', () async {
      // Create a consent response where some consents are denied
      final consent = ConsentResponse(
        participantUuid: 'test-uuid-456',
        informedConsent: true,
        dataProcessing: true,
        locationData: true,
        surveyData: true,
        dataRetention: true,
        dataSharing: true,
        voluntaryParticipation: true,
        consentedAt: DateTime.now(),
        participantSignature: 'TEST002',
        // Mixed consent responses
        consentParticipate: true,
        consentQualtricsData: true,
        consentRaceEthnicity: false, // Denied
        consentHealth: true,
        consentSexualOrientation: false, // Denied
        consentLocationMobility: true,
        consentDataTransfer: false, // Denied
        consentPublicReporting: true,
        consentResearcherSharing: true,
        consentFurtherResearch: true,
        consentPublicRepository: true,
        consentFollowupContact: false,
      );

      final qualtricsData = consent.toQualtricsJson();
      
      // Verify that denied consents are mapped to '0'
      expect(qualtricsData['CONSENT_RACE_ETHNICITY'], equals('0'));
      expect(qualtricsData['CONSENT_SEXUAL_ORIENTATION'], equals('0'));
      expect(qualtricsData['CONSENT_DATA_TRANSFER'], equals('0'));
      
      // Verify that granted consents are mapped to '1'
      expect(qualtricsData['CONSENT_PARTICIPATE'], equals('1'));
      expect(qualtricsData['CONSENT_HEALTH'], equals('1'));
      expect(qualtricsData['CONSENT_LOCATION_MOBILITY'], equals('1'));
    });

    test('Should validate that all required consents are given for Gauteng', () {
      // Test the validation method for Gauteng consent requirements
      final validConsent = ConsentResponse(
        participantUuid: 'test-uuid-789',
        informedConsent: true,
        dataProcessing: true,
        locationData: true,
        surveyData: true,
        dataRetention: true,
        dataSharing: true,
        voluntaryParticipation: true,
        consentedAt: DateTime.now(),
        participantSignature: 'TEST003',
        // All required Gauteng consents given
        consentParticipate: true,
        consentQualtricsData: true,
        consentRaceEthnicity: true,
        consentHealth: true,
        consentSexualOrientation: true,
        consentLocationMobility: true,
        consentDataTransfer: true,
        consentPublicReporting: true,
        consentResearcherSharing: true,
        consentFurtherResearch: true,
        consentPublicRepository: true,
        consentFollowupContact: false, // Optional - can be false
      );

      expect(validConsent.hasGivenValidGautengConsent(), isTrue);

      // Test invalid consent (missing one required consent)
      final invalidConsent = ConsentResponse(
        participantUuid: 'test-uuid-999',
        informedConsent: true,
        dataProcessing: true,
        locationData: true,
        surveyData: true,
        dataRetention: true,
        dataSharing: true,
        voluntaryParticipation: true,
        consentedAt: DateTime.now(),
        participantSignature: 'TEST004',
        consentParticipate: true,
        consentQualtricsData: true,
        consentRaceEthnicity: false, // This is required but set to false
        consentHealth: true,
        consentSexualOrientation: true,
        consentLocationMobility: true,
        consentDataTransfer: true,
        consentPublicReporting: true,
        consentResearcherSharing: true,
        consentFurtherResearch: true,
        consentPublicRepository: true,
        consentFollowupContact: false,
      );

      expect(invalidConsent.hasGivenValidGautengConsent(), isFalse);
    });
  });
}
