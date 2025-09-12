import 'dart:io';

/// Secure configuration management for sensitive credentials
/// Reads from environment variables instead of hardcoded values
class SecureConfig {
  
  static String? _qualtricsToken;
  static String? _qualtricsBaseUrl;
  
  /// Get Qualtrics API token from environment variable
  static String get qualtricsApiToken {
    _qualtricsToken ??= _getEnvVar('QUALTRICS_API_TOKEN');
    if (_qualtricsToken == null || _qualtricsToken!.isEmpty) {
      throw Exception(
        'SECURITY ERROR: QUALTRICS_API_TOKEN not found in environment variables. '
        'Please set this environment variable or create a .env file with the token.'
      );
    }
    return _qualtricsToken!;
  }
  
  /// Get Qualtrics base URL from environment variable
  static String get qualtricsBaseUrl {
    _qualtricsBaseUrl ??= _getEnvVar('QUALTRICS_BASE_URL') ?? 'https://pretoria.eu.qualtrics.com';
    return _qualtricsBaseUrl!;
  }
  
  /// Get environment variable with optional .env file fallback
  static String? _getEnvVar(String key) {
    // First try system environment variable
    String? value = Platform.environment[key];
    if (value != null && value.isNotEmpty) {
      return value;
    }
    
    // Fallback to .env file (for development)
    try {
      final envFile = File('.env');
      if (envFile.existsSync()) {
        final contents = envFile.readAsStringSync();
        final lines = contents.split('\n');
        for (final line in lines) {
          if (line.startsWith('$key=')) {
            return line.substring(key.length + 1).trim();
          }
        }
      }
    } catch (e) {
      // Ignore .env file errors in production
    }
    
    return null;
  }
  
  /// Validate that all required environment variables are set
  static void validateConfiguration() {
    try {
      qualtricsApiToken; // This will throw if not found
      print('✅ Qualtrics configuration validated');
    } catch (e) {
      print('❌ Configuration error: $e');
      rethrow;
    }
  }
}
