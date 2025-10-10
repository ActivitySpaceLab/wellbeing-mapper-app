class ENV {
  /// Primary API base URL for the Barcelona research server
  static const String apiBaseUrl = 'https://barcelona-research.example.com/api';

  /// Endpoint paths used throughout the client
  static const String encryptedSurveyPath = '/surveys/encrypted';
  static const String encryptedConsentPath = '/consent/encrypted';
  static const String encryptedLocationPath = '/locations/encrypted';
  static const String participantValidationPath = '/participants/validate';
  static const String participantRegistrationPath = '/participants/register';

  /// Default study/sample identifier bundled with uploads
  static const String defaultSampleId = 'barcelona_study_2025';

  /// RSA 4096-bit public key used for hybrid encryption on device.
  /// Replace the placeholder below with the real Barcelona public key
  /// generated during server provisioning.
  static const String barcelonaPublicKey = '''-----BEGIN PUBLIC KEY-----
REPLACE_WITH_4096_BIT_RSA_PUBLIC_KEY
-----END PUBLIC KEY-----''';

  // ---------------------------------------------------------------------------
  // Legacy aliases maintained while the rest of the codebase is transitioned.
  // TODO(barcelona-reset): Remove once all call sites use the new camelCase
  // names introduced above.
  // ---------------------------------------------------------------------------
  static const String TRACKER_HOST = apiBaseUrl;
  static const String ENCRYPTED_SURVEY_PATH = encryptedSurveyPath;
  static const String ENCRYPTED_CONSENT_PATH = encryptedConsentPath;
  static const String ENCRYPTED_LOCATION_PATH = encryptedLocationPath;
  static const String PARTICIPANT_VALIDATION_PATH = participantValidationPath;
  static const String PARTICIPANT_REGISTRATION_PATH = participantRegistrationPath;
  static const String DEFAULT_SAMPLE_ID = defaultSampleId;
  static const String RSA_PUBLIC_KEY = barcelonaPublicKey;
}