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
  ///
  /// Can be overridden at build/run time with
  /// `--dart-define=SERVER_BASE_URL=https://my-server.example/api/v1`. This
  /// is how local-dev builds point at the data-collection server running on
  /// `http://localhost:3000/api/v1` (iOS sim) or `http://10.0.2.2:3000/api/v1`
  /// (Android emulator).
  static const String apiBaseUrl = String.fromEnvironment(
    'SERVER_BASE_URL',
    defaultValue: 'https://research-server.example.com/api/v1',
  );

  /// Endpoint paths (appended to [apiBaseUrl]); the server implements exactly
  /// these. Location history travels inside the biweekly survey payload.
  static const String encryptedSurveyPath = '/surveys/encrypted';
  static const String encryptedConsentPath = '/consent/encrypted';
  static const String participantValidationPath = '/participants/validate';

  /// Default study/sample identifier bundled with uploads when no participant
  /// code has been entered.
  // ignore: constant_identifier_names
  static const String DEFAULT_SAMPLE_ID = 'default_sample';

  /// Slug used for the `research_site` column on uploads and locally-stored
  /// rows. This is the canonical identifier for this app/study.
  static const String researchSite = 'wellbeing_mapper';

  /// Returns true when [apiBaseUrl] points to a real (non-placeholder) host.
  static bool get isServerConfigured => !apiBaseUrl.contains('example.com');

  /// The study's RSA public key; every upload is encrypted with it on the
  /// device (AES-256-GCM, key wrapped with RSA-OAEP-SHA-256).
  ///
  /// The matching private key stays offline with the research team and is
  /// never on the server; only it can decrypt submissions
  /// (wellbeing-mapper-server/tools/decrypt_received.py).
  ///
  /// The study's key pair, generated 2026-09-28 (RSA-4096). SHA-256 of this
  /// key in DER form: 9a3e44f9cb187deb18a6a2b18685515f11d7b8c59b75b0577da328cd2a395568.
  /// To check that a private key is its partner:
  /// `openssl pkey -in private.pem -pubout -outform DER | shasum -a 256`.
  /// Replacing the key is a new app release, and data encrypted with the old
  /// key still needs the old private key.
  static const String researchPublicKey = '''-----BEGIN PUBLIC KEY-----
MIICIjANBgkqhkiG9w0BAQEFAAOCAg8AMIICCgKCAgEAxYlWAfL1SeCDTVHyeYH+
JSnlfD1PzanCIIbUOyEaX7l5a7i/lz7Vg2uWUmB6d08JR9HusogG5EzLUn7Oogef
qqZ1nRt6NXKPQai4chnj5gPpMEn0DALuXgyaTdZW47c1NTPQ5B2+WoDWcfyHnCUC
sMECepKgwx1eORJZMoxvNWLuJYjcJgRgHrnRmwipkZ0amB4x+qGU2OsULSCWhG7z
rxH5ud2YH7mRW0N/cLNyhtR+BWbYvLNeeA+/kDpmvTSZDhFI2PV6GhPy8hP9YF6a
JxT44oUMkmPT4q/ZzHhfjjXoFhtFUpCDUaYvSD6SvrUU6Zg7jZ7k4+VVA8wLcPL4
jhWC4kffd0MpcmrtTblVZIT0q/3Uvvlzka77S2QXSgQGKDdvOUbeCd9u7Ei5tGyB
UsGDRTexQ0mNhkZajjTCKY0oVdlr3+kAVUrwT6EYtzCaxZC+JJT7hFweqjVIfV1F
mZd+8jWjgfP9ehwykA7bAC7m/t7HzOFNURsDXZhc6N4/LQL90+xpOVt2h+yBI96h
hpwHFJp4x1Y47vB50hjVWRdPZRh5u5Q4qKFbFq0PU6fvQInPlNPmsUNGtLNq7q4u
85NF0cqMz3Ddi5uMfFtC5SL1FkCX2u86z0pCKnaNxEvtl0jEaJ5aArvDqse9HMbX
Ae5fhYf39X9qQM+GRNeuEx0CAwEAAQ==
-----END PUBLIC KEY-----''';

  // Legacy alias retained until call sites migrate; remove once unused.
  @Deprecated('Use ResearchServerService for network calls')
  // ignore: constant_identifier_names
  static const TRACKER_HOST = '';
}
