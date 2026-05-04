import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simple service to track if user has completed consent for the current app version
/// This replaces the complex migration system with a clean, simple approach
class ConsentTrackingService {
  // New consent flag name - everyone needs to consent once with the new version
  static const String _consentV2CompletedKey = 'consent_v2_completed';
  
  /// Check if user has completed consent for the current app version
  static Future<bool> hasCompletedCurrentConsent() async {
    final prefs = await SharedPreferences.getInstance();
    final completed = prefs.getBool(_consentV2CompletedKey) ?? false;
    debugPrint('[ConsentTracking] Current consent completed: $completed');
    return completed;
  }
  
  /// Mark consent as completed for the current app version
  static Future<void> markConsentCompleted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_consentV2CompletedKey, true);
    // Also set the backward compatibility flag for immediate survey prompt
    await prefs.setBool('fresh_consent_completion', true);
    debugPrint('[ConsentTracking] Consent marked as completed for current version');
  }
  
  /// Reset consent status (for testing/debugging)
  static Future<void> resetConsentStatus() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_consentV2CompletedKey);
    debugPrint('[ConsentTracking] Consent status reset - user will need to consent again');
  }
  
  /// Check if user needs to provide consent
  static Future<bool> needsConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_consentV2CompletedKey) ?? false);
  }

  /// Check if user has just completed consent (for immediate survey prompt)
  static Future<bool> hasJustCompletedConsent() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('fresh_consent_completion') ?? false;
  }

  /// Clear the "just completed" flag
  static Future<void> clearJustCompletedFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fresh_consent_completion');
  }
}