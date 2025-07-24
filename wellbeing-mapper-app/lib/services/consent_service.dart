import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/models/consent_models.dart';
import 'dart:convert';

class ConsentService {
  static const String _participationSettingsKey = 'participation_settings';
  static const String _consentResponseKey = 'consent_response';

  /// Save participation settings
  static Future<void> saveParticipationSettings(ParticipationSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = jsonEncode(settings.toJson());
    await prefs.setString(_participationSettingsKey, settingsJson);
  }

  /// Get participation settings
  static Future<ParticipationSettings?> getParticipationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_participationSettingsKey);
    print('[consent_service.dart] getParticipationSettings raw: '
        '${settingsJson ?? 'null'}');
    if (settingsJson == null) {
      return null;
    }
    try {
      final settingsMap = jsonDecode(settingsJson);
      print('[consent_service.dart] getParticipationSettings decoded: $settingsMap');
      return ParticipationSettings.fromJson(settingsMap);
    } catch (e) {
      print('[consent_service.dart] ERROR decoding participation_settings: $e');
      return null;
    }
  }

  /// Save consent response
  static Future<void> saveConsentResponse(ConsentResponse consentResponse) async {
    final prefs = await SharedPreferences.getInstance();
    final consentJson = jsonEncode(consentResponse.toJson());
    await prefs.setString(_consentResponseKey, consentJson);
  }

  /// Get consent response
  static Future<ConsentResponse?> getConsentResponse() async {
    final prefs = await SharedPreferences.getInstance();
    final consentJson = prefs.getString(_consentResponseKey);
    
    if (consentJson == null) {
      return null;
    }
    
    final consentMap = jsonDecode(consentJson);
    return ConsentResponse.fromJson(consentMap);
  }

  /// Check if user has completed setup (either private or research)
  static Future<bool> hasCompletedSetup() async {
    final settings = await getParticipationSettings();
    return settings != null;
  }

  /// Check if user is research participant
  static Future<bool> isResearchParticipant() async {
    final settings = await getParticipationSettings();
    return settings?.isResearchParticipant ?? false;
  }

  /// Check if research participant has completed consent
  static Future<bool> hasCompletedConsent() async {
    final settings = await getParticipationSettings();
    if (settings?.isResearchParticipant != true) {
      return true; // Private users don't need consent
    }
    
    final consent = await getConsentResponse();
    return consent != null && consent.hasGivenValidConsent();
  }

  /// Clear all consent data (for testing or reset)
  static Future<void> clearConsentData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_participationSettingsKey);
    await prefs.remove(_consentResponseKey);
  }

  /// Get participant ID for research participants
  static Future<String?> getParticipantId() async {
    final settings = await getParticipationSettings();
    return settings?.participantCode;
  }
}
