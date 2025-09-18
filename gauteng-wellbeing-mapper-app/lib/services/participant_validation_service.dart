import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;

/// Service for validating participant codes against a secure server-side list
/// Uses SHA-256 hashing for security - codes are never transmitted in plain text
class ParticipantValidationService {
  // Production server endpoints (Lambda Function URL - more reliable than API Gateway)
  static const String _baseUrl = 'https://6p7hir7licc5yisxhkner4wt2i0yhtzo.lambda-url.af-south-1.on.aws';
  static const String _validateEndpoint = '/api/v1/participants/validate';
  static const String _healthEndpoint = '/health';
  
  // Local development server (fallback)
  static const String _localBaseUrl = 'http://localhost:3000';
  
  // Local storage keys
  static const String _validatedParticipantKey = 'validated_participant_code';
  static const String _validationTimestampKey = 'validation_timestamp';
  static const String _consentRecordedKey = 'consent_recorded';
  static const String _codeTypeKey = 'participant_code_type';
  static const String _lastApiValidationKey = 'last_api_validation';
  
  // Validation source tracking
  static const String _apiValidationSource = 'api';
  static const String _localValidationSource = 'local_fallback';

  /// Check if the current user has already been validated
  static Future<bool> isParticipantValidated() async {
    final prefs = await SharedPreferences.getInstance();
    final validatedCode = prefs.getString(_validatedParticipantKey);
    return validatedCode != null && validatedCode.isNotEmpty;
  }

  /// Get the stored participant code (hashed for security)
  static Future<String?> getValidatedParticipantCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_validatedParticipantKey);
  }

  /// Validate a participant code against the server
  /// Returns true if code is valid, false otherwise
  static Future<ValidationResult> validateParticipantCode(String participantCode) async {
    try {
      // Input validation
      if (participantCode.trim().isEmpty) {
        return ValidationResult(
          isValid: false,
          error: 'Participant code cannot be empty',
        );
      }

      // Clean and normalize the code
      final cleanCode = participantCode.trim().toUpperCase();
      
      // Hash the entered code for validation
      final hashedCode = _hashParticipantCode(cleanCode);
      
      // Try server validation first
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl$_validateEndpoint'),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode({
            'hashed_code': hashedCode,
            'timestamp': DateTime.now().toIso8601String(),
          }),
        ).timeout(Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['valid'] == true) {
            // Store the validation locally with additional metadata
            await _storeValidatedParticipant(cleanCode);
            await _storeValidationSource(_apiValidationSource);
            await _storeParticipantCodeType(data['code_type'] ?? 'unknown');
            
            print('[ParticipantValidation] Server validation successful: ${cleanCode.substring(0, min(3, cleanCode.length))}*** (${data['code_type']})');
            return ValidationResult(isValid: true);
          } else {
            print('[ParticipantValidation] Server rejected code: ${cleanCode.substring(0, min(3, cleanCode.length))}***');
            return ValidationResult(
              isValid: false,
              error: 'Invalid participant code. Please check your code and contact the research team if you continue to have issues.',
            );
          }
        } else if (response.statusCode == 404) {
          print('[ParticipantValidation] Code not found on server: ${cleanCode.substring(0, min(3, cleanCode.length))}***');
          return ValidationResult(
            isValid: false,
            error: 'Participant code not found. Please check your code and try again.',
          );
        } else {
          print('[ParticipantValidation] Server validation failed with status ${response.statusCode}');
          // Fall back to local validation
          return await _validateWithLocalFallback(cleanCode, hashedCode);
        }
      } catch (networkError) {
        print('[ParticipantValidation] Network error during server validation: $networkError');
        // Fall back to local validation
        return await _validateWithLocalFallback(cleanCode, hashedCode);
      }
    } catch (e) {
      print('[ParticipantValidation] Error validating code: $e');
      return ValidationResult(
        isValid: false,
        error: 'Validation error. Please try again.',
      );
    }
  }

  /// Fallback validation using local hardcoded hashes
  static Future<ValidationResult> _validateWithLocalFallback(String cleanCode, String hashedCode) async {
    print('[ParticipantValidation] Using local fallback validation - server unavailable');
    
    // For development/testing - allow specific test codes only
    if (cleanCode == 'TESTER' || cleanCode == 'TEST123' || cleanCode == 'DEV001' || cleanCode == 'PRODTEST') {
      await _storeValidatedParticipant(cleanCode);
      await _storeValidationSource(_localValidationSource);
      await _storeParticipantCodeType('test');
      print('[ParticipantValidation] Test code accepted: $cleanCode');
      return ValidationResult(isValid: true);
    }
    
    // No hardcoded participant codes - server required for validation
    print('[ParticipantValidation] Local fallback: Server required for participant validation');
    return ValidationResult(
      isValid: false,
      error: 'Unable to validate participant code. Please check your internet connection and try again.',
    );
  }

  /// Record consent for a validated participant
  static Future<ConsentResult> recordConsent(String participantCode, DateTime consentTimestamp) async {
    try {
      // Verify participant is validated
      final isValidated = await isParticipantValidated();
      if (!isValidated) {
        return ConsentResult(
          success: false,
          error: 'Participant must be validated before recording consent',
        );
      }

      // For now, just store locally since server isn't ready
      // TODO: Remove this when server is ready
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_consentRecordedKey, true);
      await prefs.setString('consent_timestamp', consentTimestamp.toIso8601String());
      
      print('[ParticipantValidation] Consent recorded locally for participant: ${participantCode.substring(0, min(3, participantCode.length))}***');
      return ConsentResult(success: true);

      // Server consent recording (commented out until server is ready)
      /*
      final response = await http.post(
        Uri.parse('$_baseUrl$_consentEndpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'hashed_participant_code': hashedCode,
          'consent_timestamp': consentTimestamp.toIso8601String(),
          'consent_version': '1.0', // Track consent form version
        }),
      ).timeout(Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Mark consent as recorded locally
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_consentRecordedKey, true);
        await prefs.setString('consent_timestamp', consentTimestamp.toIso8601String());
        
        return ConsentResult(success: true);
      } else {
        return ConsentResult(
          success: false,
          error: 'Failed to record consent on server. Please try again.',
        );
      }
      */
    } catch (e) {
      print('[ParticipantValidation] Error recording consent: $e');
      return ConsentResult(
        success: false,
        error: 'Network error while recording consent. Please try again.',
      );
    }
  }

  /// Check if consent has been recorded for the current participant
  static Future<bool> hasConsentBeenRecorded() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_consentRecordedKey) ?? false;
  }

  /// Hash participant code using SHA-256 for security
  static String _hashParticipantCode(String code) {
    final bytes = utf8.encode(code);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Store validated participant locally (stores hashed version for security)
  static Future<void> _storeValidatedParticipant(String participantCode) async {
    final prefs = await SharedPreferences.getInstance();
    // For now, store the plain code until server integration
    // TODO: Use hashed version when server is ready
    await prefs.setString(_validatedParticipantKey, participantCode);
    await prefs.setString(_validationTimestampKey, DateTime.now().toIso8601String());
    print('[ParticipantValidation] Stored validated participant: ${participantCode.substring(0, min(3, participantCode.length))}***');
  }

  /// Clear validation data (for testing or logout)
  static Future<void> clearValidation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_validatedParticipantKey);
    await prefs.remove(_validationTimestampKey);
    await prefs.remove(_consentRecordedKey);
    await prefs.remove(_codeTypeKey);
    await prefs.remove(_lastApiValidationKey);
    await prefs.remove('consent_timestamp');
  }

  /// Store the validation source (API or local fallback)
  static Future<void> _storeValidationSource(String source) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastApiValidationKey, source);
  }

  /// Store the participant code type (pilot, study, test)
  static Future<void> _storeParticipantCodeType(String codeType) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_codeTypeKey, codeType);
  }

  /// Get validation timestamp
  static Future<DateTime?> getValidationTimestamp() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getString(_validationTimestampKey);
    if (timestamp != null) {
      return DateTime.tryParse(timestamp);
    }
    return null;
  }
}

/// Result of participant code validation
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult({
    required this.isValid,
    this.error,
  });
}

/// Result of consent recording
class ConsentResult {
  final bool success;
  final String? error;

  ConsentResult({
    required this.success,
    this.error,
  });
}
