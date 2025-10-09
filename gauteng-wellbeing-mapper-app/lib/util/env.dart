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
}