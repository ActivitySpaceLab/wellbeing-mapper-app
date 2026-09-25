import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:encrypt/encrypt.dart' as enc;
import 'package:fast_rsa/fast_rsa.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../db/survey_database.dart';
import '../main.dart';
import '../services/app_mode_service.dart';
import '../services/consent_tracking_service.dart';
import '../util/env.dart';

/// Outcome of a [ResearchServerService.syncPendingSurveys] call, so callers
/// can distinguish "uploaded" from "nothing to do" from "skipped by a guard"
/// instead of unconditionally reporting success.
class SyncOutcome {
  /// Non-null when sync did not run at all (guard tripped); human-readable.
  final String? skippedReason;
  final int attempted;
  final int uploaded;

  const SyncOutcome.skipped(this.skippedReason)
      : attempted = 0,
        uploaded = 0;
  const SyncOutcome.ran({required this.attempted, required this.uploaded})
      : skippedReason = null;

  bool get didRun => skippedReason == null;
}

/// Sends encrypted survey data directly to the research server.
///
/// Encryption scheme:
///   – AES-256-GCM  (symmetric, random key per submission)
///   – RSA-OAEP-SHA-256 (asymmetric key encapsulation)
///
/// The server endpoint is a placeholder until the research server is built.
/// While the endpoint is unconfigured, surveys are kept in the local database
/// and will be automatically uploaded once the URL is set.
class ResearchServerService {
  // Endpoint URLs are sourced from ENV so swapping research backends only
  // requires editing a single file.
  static String get _surveyUrl =>
      '${ENV.apiBaseUrl}${ENV.encryptedSurveyPath}';
  static String get _consentUrl =>
      '${ENV.apiBaseUrl}${ENV.encryptedConsentPath}';

  static bool get _isServerConfigured => ENV.isServerConfigured;

  // RSA public key used for key encapsulation.
  static String get _publicKey => ENV.researchPublicKey;

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// True while a sync is running, so overlapping calls (e.g. a manual
  /// "Sync Now" during the automatic post-submission sync) cannot upload
  /// the same rows twice. The server has no idempotency key, so this
  /// client-side guard is the only duplicate protection.
  static bool _syncInFlight = false;

  /// Sync all locally-stored, unsynced surveys to the research server.
  ///
  /// This is a no-op while the server URL is unconfigured. Surveys are
  /// retained in the local database and will be uploaded automatically once
  /// a valid URL is set.
  ///
  /// Uploads happen only when [AppModeService.sendsDataToResearch] is true
  /// (research mode, non-demo build) and the participant has completed the
  /// consent flow ([ConsentTrackingService.hasCompletedCurrentConsent]).
  /// The consent form itself is uploaded under the same gate: the local
  /// consent record is only created when the consent flow completes, which
  /// is also the moment the gate opens.
  static Future<SyncOutcome> syncPendingSurveys() async {
    if (!_isServerConfigured) {
      debugPrint(
          '[ResearchServerService] Server not yet configured – surveys '
          'retained locally for future upload.');
      return const SyncOutcome.skipped('Research server not configured');
    }

    // Only sync when the user has given research consent.
    final participantUUID = GlobalData.userUUID;
    if (participantUUID.isEmpty) {
      debugPrint('[ResearchServerService] No participant UUID – skipping sync.');
      return const SyncOutcome.skipped('No participant UUID');
    }

    // Only research mode uploads; demo builds never do, regardless of mode.
    if (!await AppModeService.sendsDataToResearch()) {
      debugPrint('[ResearchServerService] Mode does not upload – skipping sync.');
      return const SyncOutcome.skipped('Not in research mode');
    }

    if (!await ConsentTrackingService.hasCompletedCurrentConsent()) {
      debugPrint('[ResearchServerService] Consent not completed – skipping sync.');
      return const SyncOutcome.skipped('Consent not completed');
    }

    if (_syncInFlight) {
      debugPrint('[ResearchServerService] Sync already running – skipping.');
      return const SyncOutcome.skipped('Sync already in progress');
    }
    _syncInFlight = true;

    try {
      debugPrint('[ResearchServerService] Starting survey sync…');

      int initialSynced = 0, biweeklySynced = 0, consentSynced = 0;

      final db = SurveyDatabase();
      final unsyncedInitial = await db.getUnsyncedInitialSurveys();
      for (final survey in unsyncedInitial) {
        if (await _syncInitialSurvey(survey)) initialSynced++;
      }

      final unsyncedBiweekly = await db.getUnsyncedRecurringSurveys();
      for (final survey in unsyncedBiweekly) {
        if (await _syncBiweeklySurvey(survey)) biweeklySynced++;
      }

      final unsyncedConsent = await db.getUnsyncedConsentForms();
      for (final consent in unsyncedConsent) {
        if (await _syncConsentForm(consent)) consentSynced++;
      }

      final total = unsyncedInitial.length +
          unsyncedBiweekly.length +
          unsyncedConsent.length;
      final synced = initialSynced + biweeklySynced + consentSynced;

      debugPrint('[ResearchServerService] Sync done: $synced/$total uploaded.');

      if (total > 0 && synced == 0) {
        throw Exception(
            'All $total sync attempts failed. Check network connection.');
      }
      if (synced < total) {
        throw Exception(
            'Partial sync: only $synced of $total surveys uploaded.');
      }
      return SyncOutcome.ran(attempted: total, uploaded: synced);
    } catch (e) {
      debugPrint('[ResearchServerService] Sync error: $e');
      rethrow;
    } finally {
      _syncInFlight = false;
    }
  }

  static Future<String> _appVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return '1.0.0';
    }
  }

  static Future<bool> _syncInitialSurvey(Map<String, dynamic> data) async {
    try {
      final payload = {
        'type': 'initial_survey',
        'participant_uuid': GlobalData.userUUID,
        'survey_id': data['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
        'metadata': {
          'app_version': await _appVersion(),
          'submission_method': 'research_server_direct',
        },
      };
      final blob = await _encrypt(payload);
      final ok = await _post('initial', blob);
      if (ok) await SurveyDatabase().markInitialSurveySynced(data['id']);
      return ok;
    } catch (e) {
      debugPrint('[ResearchServerService] Error syncing initial survey: $e');
      return false;
    }
  }

  static Future<bool> _syncBiweeklySurvey(Map<String, dynamic> data) async {
    try {
      Map<String, dynamic>? locationData;
      final rawLoc =
          data['encrypted_location_data'] ?? data['location_data'];
      if (rawLoc != null) {
        try {
          locationData = jsonDecode(rawLoc.toString());
        } catch (_) {}
      }

      final payload = {
        'type': 'biweekly_survey',
        'participant_uuid': GlobalData.userUUID,
        'survey_id': data['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
        'location_data': locationData,
        'metadata': {
          'app_version': await _appVersion(),
          'submission_method': 'research_server_direct',
        },
      };
      final blob = await _encrypt(payload);
      final ok = await _post('biweekly', blob);
      if (ok) await SurveyDatabase().markRecurringSurveySynced(data['id']);
      return ok;
    } catch (e) {
      debugPrint('[ResearchServerService] Error syncing biweekly survey: $e');
      return false;
    }
  }

  static Future<bool> _syncConsentForm(Map<String, dynamic> data) async {
    try {
      final payload = {
        'type': 'consent_form',
        'participant_uuid': GlobalData.userUUID,
        'consent_id': data['id'],
        'timestamp': DateTime.now().toIso8601String(),
        'data': data,
        'metadata': {
          'app_version': await _appVersion(),
          'submission_method': 'research_server_direct',
        },
      };
      final blob = await _encrypt(payload);
      final ok = await _post('consent', blob);
      if (ok) await SurveyDatabase().markConsentFormSynced(data['id']);
      return ok;
    } catch (e) {
      debugPrint('[ResearchServerService] Error syncing consent form: $e');
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // Encryption: AES-256-GCM + RSA-OAEP-SHA-256 key encapsulation
  // -------------------------------------------------------------------------

  /// Encrypt [payload] and return a base64-encoded package string.
  ///
  /// The package format is:
  /// ```json
  /// {
  ///   "encryptedData": "<base64(ciphertext+gcm_tag)>",
  ///   "iv":            "<base64(16-byte IV)>",
  ///   "encryptedKey":  "<base64(RSA-OAEP-SHA256(base64_text_of_aes_key))>",
  ///   "algorithm":     "AES-256-GCM+RSA-OAEP-SHA256",
  ///   "researchSite":  "<ENV.researchSite>",
  ///   "timestamp":     "<ISO-8601>"
  /// }
  /// ```
  ///
  /// Note for the server implementation: the RSA plaintext is the *base64
  /// string* of the AES key (fast_rsa encrypts text), so after RSA-OAEP
  /// decryption the result must be base64-decoded to recover the 32 raw
  /// key bytes.
  static Future<String> _encrypt(Map<String, dynamic> payload) async {
    final jsonString = jsonEncode(payload);
    final dataBytes = Uint8List.fromList(utf8.encode(jsonString));

    // Generate a random 256-bit AES key and a random 128-bit IV.
    final aesKey = enc.Key.fromSecureRandom(32);
    final iv = enc.IV.fromSecureRandom(16);

    // Encrypt with AES-256-GCM. The `Encrypted.bytes` includes the GCM tag.
    final encrypter = enc.Encrypter(enc.AES(aesKey, mode: enc.AESMode.gcm));
    final encrypted = encrypter.encryptBytes(dataBytes, iv: iv);

    // Wrap the AES key with RSA-OAEP-SHA-256.
    final aesKeyBase64 = base64.encode(aesKey.bytes);
    final encryptedKey = await RSA.encryptOAEP(
      aesKeyBase64,
      '',
      Hash.SHA256,
      _publicKey,
    );

    final package = {
      'encryptedData': base64.encode(encrypted.bytes),
      'iv': iv.base64,
      'encryptedKey': encryptedKey,
      'algorithm': 'AES-256-GCM+RSA-OAEP-SHA256',
      'researchSite': ENV.researchSite,
      'timestamp': DateTime.now().toIso8601String(),
    };

    return base64.encode(utf8.encode(jsonEncode(package)));
  }

  // -------------------------------------------------------------------------
  // HTTP with exponential-backoff retry
  // -------------------------------------------------------------------------

  static Future<bool> _post(String surveyType, String encryptedBlob) async {
    const maxRetries = 3;
    final Duration baseDelay = const Duration(seconds: 2);

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint(
            '[ResearchServerService] POST $surveyType (attempt $attempt/$maxRetries)');

        final timeout =
            Platform.isIOS ? const Duration(seconds: 45) : const Duration(seconds: 30);

        final response = await http
            .post(
              Uri.parse(
                  surveyType == 'consent' ? _consentUrl : _surveyUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'User-Agent': 'WellbeingMapper/1.0',
              },
              body: jsonEncode({
                'encrypted_data': encryptedBlob,
                'survey_type': surveyType,
                'timestamp': DateTime.now().toIso8601String(),
              }),
            )
            .timeout(timeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          try {
            final body = jsonDecode(response.body);
            if (body['success'] == true) {
              debugPrint(
                  '[ResearchServerService] ✓ $surveyType uploaded (attempt $attempt)');
              return true;
            }
            debugPrint(
                '[ResearchServerService] Server returned success=false: ${body['message']}');
          } catch (_) {
            debugPrint(
                '[ResearchServerService] Malformed response body, retrying.');
          }
        } else if (response.statusCode >= 400 && response.statusCode < 500) {
          // Client errors will not improve with retries.
          debugPrint(
              '[ResearchServerService] Client error ${response.statusCode}, aborting.');
          return false;
        } else {
          debugPrint(
              '[ResearchServerService] Server error ${response.statusCode}, will retry.');
        }
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('certificate') ||
            msg.contains('handshake') ||
            msg.contains('format')) {
          debugPrint('[ResearchServerService] Permanent network error: $e');
          return false;
        }
        debugPrint(
            '[ResearchServerService] Network error (attempt $attempt): $e');
      }

      if (attempt < maxRetries) {
        // Exponential backoff with random jitter.
        final jitterMs = Random().nextInt(2000);
        final delay = Duration(
          milliseconds: baseDelay.inMilliseconds * (1 << (attempt - 1)) +
              jitterMs,
        );
        debugPrint(
            '[ResearchServerService] Waiting ${delay.inSeconds}s before retry…');
        await Future.delayed(delay);
      }
    }

    debugPrint(
        '[ResearchServerService] All $maxRetries attempts failed for $surveyType.');
    return false;
  }
}
