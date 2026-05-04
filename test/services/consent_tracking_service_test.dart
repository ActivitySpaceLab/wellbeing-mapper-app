import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/services/consent_tracking_service.dart';

void main() {
  group('ConsentTrackingService', () {
    setUp(() async {
      // Clear all shared preferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('should return false for hasCompletedCurrentConsent when no consent recorded', () async {
      final hasConsent = await ConsentTrackingService.hasCompletedCurrentConsent();
      expect(hasConsent, isFalse);
    });

    test('should return true for needsConsent when no consent recorded', () async {
      final needsConsent = await ConsentTrackingService.needsConsent();
      expect(needsConsent, isTrue);
    });

    test('should correctly mark and retrieve consent completion', () async {
      // Initially no consent
      expect(await ConsentTrackingService.hasCompletedCurrentConsent(), isFalse);
      expect(await ConsentTrackingService.needsConsent(), isTrue);

      // Mark consent as completed
      await ConsentTrackingService.markConsentCompleted();

      // Should now have consent
      expect(await ConsentTrackingService.hasCompletedCurrentConsent(), isTrue);
      expect(await ConsentTrackingService.needsConsent(), isFalse);
    });

    test('should set fresh_consent_completion flag when marking consent complete', () async {
      await ConsentTrackingService.markConsentCompleted();
      
      // Check that backward compatibility flag was set
      expect(await ConsentTrackingService.hasJustCompletedConsent(), isTrue);
    });

    test('should clear just completed flag correctly', () async {
      await ConsentTrackingService.markConsentCompleted();
      expect(await ConsentTrackingService.hasJustCompletedConsent(), isTrue);

      await ConsentTrackingService.clearJustCompletedFlag();
      expect(await ConsentTrackingService.hasJustCompletedConsent(), isFalse);

      // But main consent should still be marked complete
      expect(await ConsentTrackingService.hasCompletedCurrentConsent(), isTrue);
    });

    test('should correctly reset consent status', () async {
      await ConsentTrackingService.markConsentCompleted();
      expect(await ConsentTrackingService.hasCompletedCurrentConsent(), isTrue);

      await ConsentTrackingService.resetConsentStatus();
      expect(await ConsentTrackingService.hasCompletedCurrentConsent(), isFalse);
      expect(await ConsentTrackingService.needsConsent(), isTrue);
    });
  });
}