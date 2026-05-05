import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'app_mode_service.dart';

/// Validates participant codes against the research server.
///
/// Codes are never transmitted in plain text – only their SHA-256 hash is
/// sent over the network or stored locally.
class ParticipantValidationService {
  // TODO: Update this URL when the research server is built.
  static const String _baseUrl =
      'https://research-server.example.com';
  static const String _validateEndpoint = '/api/v1/participants/validate';

  static bool get _isServerConfigured =>
      !_baseUrl.contains('example.com');

  // SharedPreferences keys
  static const String _validatedParticipantKey = 'validated_participant_code';
  static const String _validationTimestampKey = 'validation_timestamp';
  static const String _consentRecordedKey = 'consent_recorded';
  static const String _codeTypeKey = 'participant_code_type';
  static const String _lastApiValidationKey = 'last_api_validation';

  static const String _apiValidationSource = 'api';
  static const String _localValidationSource = 'local_fallback';

  // -------------------------------------------------------------------------
  // Public API
  // -------------------------------------------------------------------------

  /// Returns `true` if a validated participant hash is stored locally.
  static Future<bool> isParticipantValidated() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_validatedParticipantKey);
    return stored != null && stored.isNotEmpty;
  }

  /// Returns the stored SHA-256 hash of the validated participant code, or
  /// `null` if the user has not yet been validated.
  static Future<String?> getValidatedParticipantCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_validatedParticipantKey);
  }

  /// Registers an anonymous participant who has not been recruited through
  /// a survey panel and therefore has no compensation code.
  ///
  /// Generates a random `ANON-XXXXXXXX` identifier, stores its SHA-256 hash
  /// locally just like a normal validated code, and tags `code_type` as
  /// `anonymous` so the server (and downstream analyses) can distinguish
  /// these participants from panel-recruited ones.
  static Future<ValidationResult> registerAnonymousParticipant() async {
    try {
      final random = Random.secure();
      final chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
      final suffix = List.generate(
        8,
        (_) => chars[random.nextInt(chars.length)],
      ).join();
      final anonCode = 'ANON-$suffix';
      final hashedCode = _hashCode(anonCode);
      await _store(hashedCode);
      await _storeValidationSource('anonymous_self_registration');
      await _storeCodeType('anonymous');
      debugPrint(
          '[ParticipantValidation] Registered anonymous participant: $anonCode');
      return ValidationResult(isValid: true);
    } catch (e) {
      debugPrint(
          '[ParticipantValidation] Error registering anonymous participant: $e');
      return ValidationResult(
        isValid: false,
        error: 'Could not register without a code. Please try again.',
      );
    }
  }

  /// Validates [participantCode] against the research server.
  ///
  /// Falls back to debug-only local codes when the server is unreachable and
  /// the app is running in debug mode.
  static Future<ValidationResult> validateParticipantCode(
      String participantCode) async {
    try {
      if (participantCode.trim().isEmpty) {
        return ValidationResult(
            isValid: false, error: 'Participant code cannot be empty');
      }

      final cleanCode = participantCode.trim().toUpperCase();
      final hashedCode = _hashCode(cleanCode);

      // Demo builds should allow any code without contacting the server so
      // colleagues can explore the full research flow safely.
      if (AppModeService.isDemoBuild) {
        await _store(hashedCode);
        await _storeValidationSource('demo_auto');
        await _storeCodeType('demo');
        debugPrint('[ParticipantValidation] Demo build auto-validated code: ${cleanCode.substring(0, min(3, cleanCode.length))}***');
        return ValidationResult(isValid: true);
      }

      if (_isServerConfigured) {
        try {
          final response = await http
              .post(
                Uri.parse('$_baseUrl$_validateEndpoint'),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
                body: jsonEncode({
                  'hashed_code': hashedCode,
                  'timestamp': DateTime.now().toIso8601String(),
                }),
              )
              .timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            if (data['valid'] == true) {
              await _store(hashedCode);
              await _storeValidationSource(_apiValidationSource);
              await _storeCodeType(data['code_type']?.toString() ?? 'unknown');
              debugPrint('[ParticipantValidation] Server validation successful.');
              return ValidationResult(isValid: true);
            }
            debugPrint('[ParticipantValidation] Server rejected code.');
            return ValidationResult(
              isValid: false,
              error: 'Invalid participant code. Please check your code and '
                  'contact the research team if you continue to have issues.',
            );
          } else if (response.statusCode == 404) {
            debugPrint('[ParticipantValidation] Code not found on server.');
            return ValidationResult(
              isValid: false,
              error: 'Participant code not found. Please check your code and try again.',
            );
          } else {
            debugPrint(
                '[ParticipantValidation] Server error ${response.statusCode}, falling back.');
            return _localFallback(cleanCode, hashedCode);
          }
        } catch (networkError) {
          debugPrint(
              '[ParticipantValidation] Network error, falling back: $networkError');
          return _localFallback(cleanCode, hashedCode);
        }
      } else {
        // Server not yet configured – use local fallback.
        return _localFallback(cleanCode, hashedCode);
      }
    } catch (e) {
      debugPrint('[ParticipantValidation] Unexpected error: $e');
      return ValidationResult(
          isValid: false, error: 'Validation error. Please try again.');
    }
  }

  /// Records consent for a validated participant (stored locally until the
  /// research server is ready to accept consent submissions).
  static Future<ConsentResult> recordConsent(
      String participantCode, DateTime consentTimestamp) async {
    try {
      final isValidated = await isParticipantValidated();
      if (!isValidated) {
        return ConsentResult(
          success: false,
          error: 'Participant must be validated before recording consent',
        );
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentRecordedKey, true);
      await prefs.setString(
          'consent_timestamp', consentTimestamp.toIso8601String());
      debugPrint('[ParticipantValidation] Consent recorded locally.');
      return ConsentResult(success: true);
    } catch (e) {
      debugPrint('[ParticipantValidation] Error recording consent: $e');
      return ConsentResult(
        success: false,
        error: 'Error while recording consent. Please try again.',
      );
    }
  }

  /// Returns `true` if consent has been recorded for the current participant.
  static Future<bool> hasConsentBeenRecorded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentRecordedKey) ?? false;
  }

  /// Removes all validation data (for testing or sign-out).
  static Future<void> clearValidation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_validatedParticipantKey);
    await prefs.remove(_validationTimestampKey);
    await prefs.remove(_consentRecordedKey);
    await prefs.remove(_codeTypeKey);
    await prefs.remove(_lastApiValidationKey);
    await prefs.remove('consent_timestamp');
  }

  /// Returns the timestamp of the last successful validation, or `null`.
  static Future<DateTime?> getValidationTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getString(_validationTimestampKey);
    return ts != null ? DateTime.tryParse(ts) : null;
  }

  // -------------------------------------------------------------------------
  // Private helpers
  // -------------------------------------------------------------------------

  /// Local fallback validation – in debug builds only, a handful of test
  /// codes are accepted. In release builds this always fails, requiring the
  /// real server.
  static Future<ValidationResult> _localFallback(
      String cleanCode, String hashedCode) async {
    debugPrint('[ParticipantValidation] Using local fallback (server unavailable).');

    if (kDebugMode &&
        (cleanCode == 'TESTER' ||
            cleanCode == 'TEST123' ||
            cleanCode == 'DEV001' ||
            cleanCode == 'PRODTEST')) {
      await _store(hashedCode);
      await _storeValidationSource(_localValidationSource);
      await _storeCodeType('test');
      debugPrint('[ParticipantValidation] Debug test code accepted.');
      return ValidationResult(isValid: true);
    }

    return ValidationResult(
      isValid: false,
      error: 'Unable to validate participant code. '
          'Please check your internet connection and try again.',
    );
  }

  static String _hashCode(String code) {
    final bytes = utf8.encode(code);
    return sha256.convert(bytes).toString();
  }

  /// Stores [hashedCode] (already SHA-256 hashed by callers) in SharedPreferences.
  ///
  /// The raw participant code is NEVER written to storage – only its hash.
  /// All call sites compute the hash via [_hashCode] before calling [_store].
  static Future<void> _store(String hashedCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_validatedParticipantKey, hashedCode);
    await prefs.setString(
        _validationTimestampKey, DateTime.now().toIso8601String());
  }

  static Future<void> _storeValidationSource(String source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastApiValidationKey, source);
  }

  static Future<void> _storeCodeType(String codeType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codeTypeKey, codeType);
  }
}

/// Result of participant code validation.
class ValidationResult {
  final bool isValid;
  final String? error;

  const ValidationResult({required this.isValid, this.error});
}

/// Result of consent recording.
class ConsentResult {
  final bool success;
  final String? error;

  const ConsentResult({required this.success, this.error});
}
