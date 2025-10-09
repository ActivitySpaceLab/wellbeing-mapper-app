import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../util/env.dart';

/// Thin client for communicating with the Barcelona research server.
///
/// All endpoints expect encrypted payloads that are generated on-device using
/// the RSA public key provided in [ENV.barcelonaPublicKey]. This service is
/// responsible for composing the correct request envelopes and handling the
/// shared retry/backoff behaviour.
class BarcelonaServerService {
  BarcelonaServerService._();

  static final http.Client _client = http.Client();

  static Uri _resolve(String path) {
    final normalised = path.startsWith('/') ? path : '/$path';
    return Uri.parse('${ENV.apiBaseUrl}$normalised');
  }

  static Map<String, String> _defaultHeaders() {
    final headers = <String, String>{
      HttpHeaders.contentTypeHeader: 'application/json',
      HttpHeaders.acceptHeader: 'application/json',
      HttpHeaders.userAgentHeader: 'BarcelonaWellbeingMapper/1.0',
    };

    if (Platform.isIOS) {
      headers[HttpHeaders.connectionHeader] = 'keep-alive';
      headers[HttpHeaders.acceptEncodingHeader] = 'gzip, deflate';
    }

    return headers;
  }

  /// Generic helper that POSTs an already encrypted payload to the server.
  static Future<bool> _postEncrypted({
    required String path,
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 30),
    int maxRetries = 3,
  }) async {
    Duration effectiveTimeout = timeout;
    if (Platform.isIOS && timeout.inSeconds < 45) {
      effectiveTimeout = const Duration(seconds: 45);
    }

    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final response = await _client
            .post(
              _resolve(path),
              headers: _defaultHeaders(),
              body: jsonEncode(body),
            )
            .timeout(effectiveTimeout);

        if (response.statusCode >= 200 && response.statusCode < 300) {
          if (response.body.isEmpty) {
            return true;
          }

          try {
            final payload = jsonDecode(response.body) as Map<String, dynamic>;
            if (payload['success'] == true || payload['status'] == 'ok') {
              return true;
            }
          } catch (_) {
            // If the server returns non-JSON success, treat 2xx as success.
            return true;
          }

          // Non-success payload despite 2xx - fall through to retry logic.
          print('[BarcelonaServerService] Unexpected response body: ${response.body}');
        } else {
          print('[BarcelonaServerService] HTTP ${response.statusCode} while POSTing to $path');
          if (response.statusCode >= 400 && response.statusCode < 500) {
            return false; // client errors shouldn't be retried
          }
        }
      } catch (error) {
        print('[BarcelonaServerService] Network error (attempt $attempt/$maxRetries): $error');
        if (error.toString().contains('certificate') ||
            error.toString().contains('format exception')) {
          return false;
        }
      }

      if (attempt < maxRetries) {
        final baseDelay = Duration(seconds: 2 * (1 << (attempt - 1)));
        final jitterMillis = DateTime.now().millisecondsSinceEpoch % 1500;
        final delay = baseDelay + Duration(milliseconds: jitterMillis);
        print('[BarcelonaServerService] Retrying in ${delay.inMilliseconds / 1000}s');
        await Future.delayed(delay);
      }
    }

    return false;
  }

  static Future<bool> submitEncryptedSurvey({
    required String surveyType,
    required String encryptedBlob,
  }) {
    return _postEncrypted(
      path: ENV.encryptedSurveyPath,
      body: {
        'survey_type': surveyType,
        'encrypted_payload': encryptedBlob,
        'submitted_at': DateTime.now().toIso8601String(),
        'sample_id': ENV.defaultSampleId,
      },
    );
  }

  static Future<bool> submitEncryptedConsent({
    required String encryptedBlob,
  }) {
    return _postEncrypted(
      path: ENV.encryptedConsentPath,
      body: {
        'encrypted_payload': encryptedBlob,
        'submitted_at': DateTime.now().toIso8601String(),
        'sample_id': ENV.defaultSampleId,
      },
    );
  }

  static Future<bool> submitEncryptedLocations({
    required String encryptedBlob,
  }) {
    return _postEncrypted(
      path: ENV.encryptedLocationPath,
      body: {
        'encrypted_payload': encryptedBlob,
        'sample_id': ENV.defaultSampleId,
      },
      timeout: const Duration(seconds: 60),
    );
  }

  static Future<http.Response> registerParticipant(Map<String, dynamic> payload) {
    return _client.post(
      _resolve(ENV.participantRegistrationPath),
      headers: _defaultHeaders(),
      body: jsonEncode(payload),
    );
  }

  static Future<http.Response> validateParticipant(Map<String, dynamic> payload) {
    return _client.post(
      _resolve(ENV.participantValidationPath),
      headers: _defaultHeaders(),
      body: jsonEncode(payload),
    );
  }
}
