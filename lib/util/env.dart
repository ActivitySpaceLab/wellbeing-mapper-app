/// Application-wide configuration constants.
///
/// All endpoint paths and credentials live here so that swapping research
/// backends only requires editing this file. The actual network calls are
/// performed by [ResearchServerService].
class ENV {
  /// Base URL for the research server.
  ///
  /// While this is set to a placeholder, [ResearchServerService] keeps survey
  /// data in the local database and skips network calls. Replace this with the
  /// real URL once the research server is provisioned.
  static const String apiBaseUrl =
      'https://research-server.example.com/api/v1';

  /// Endpoint paths (appended to [apiBaseUrl]).
  static const String encryptedSurveyPath = '/surveys/encrypted';
  static const String encryptedConsentPath = '/consent/encrypted';
  static const String encryptedLocationPath = '/locations/encrypted';
  static const String participantValidationPath = '/participants/validate';
  static const String participantRegistrationPath = '/participants/register';

  /// Default study/sample identifier bundled with uploads when no participant
  /// code has been entered.
  // ignore: constant_identifier_names
  static const String DEFAULT_SAMPLE_ID = 'default_sample';

  /// Slug used for the `research_site` column on uploads and locally-stored
  /// rows. This is the canonical identifier for this app/study.
  static const String researchSite = 'wellbeing_mapper';

  /// Returns true when [apiBaseUrl] points to a real (non-placeholder) host.
  static bool get isServerConfigured => !apiBaseUrl.contains('example.com');

  /// RSA-2048 public key used for hybrid encryption on device.
  ///
  /// The matching private key is held by the research server and is required
  /// to decrypt incoming submissions. Replace this with the production key
  /// before shipping.
  static const String researchPublicKey = '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAvzeHQfOYDT8XgiDyHsTG
80/lQY1+AQa2NLIJERK6WuYxVrveDoY5V99V9rlFTRXdYcD5iBDL3WGHQmkOUDQL
PMZ6YjTlU5ACcBf43+yo09Nyt1g7Ib3E95USml2jws7vjZMydhaEcJcBJXb0ty99
EQvis5gJ1GI99BDRzJIArvFTCwsPCm7zan+ai5QPz78SE5RuDwrXloR1vYkf54hN
eyMpUKXFlp3PHKudoE1XlPh9yKkVPPmJkWkl9wECHG+fF8ia/c0/d7IIr1gUWLM1
/IAm6EFnRJLruBOjPK8/3fry9FcDIRv3I8WxVXar8qfVN2mbNtInJ3T2MPXVizqh
VWEWZTYqXiQHQkWjKpbzpVLXzIT7fs3ABk4oBbkH563JSeZHVuv6Xt3DgN7ZzL/Z
QeBb1Gt2dHHGpApT64TTFPv/DFC8CvCauyWEFaAcr3yUr0ah9uGzFtWg/fOWFkDs
lhxw98hOu+mhHVCitzGjLp54zmUASnQfjQLaOEPJITXlX5UYbgbCiH0B4w9NE6o6
F9XaMHUHsRDFZccRlM8AR5fkUVZqiBrI7eHl4e0aSUmc7I8wX3DCA0L16sQQQl18
ZOidCTGzOD8p7DghyDZfnsyBce1qVqJi4bMc05lJSib30DQGMaxbv3hzc/rhmz87
64BAgUuyskUvkMsgsgzf7NcCAwEAAQ==
-----END PUBLIC KEY-----''';

  // Legacy alias retained until call sites migrate; remove once unused.
  @Deprecated('Use ResearchServerService for network calls')
  // ignore: constant_identifier_names
  static const TRACKER_HOST = '';
}
