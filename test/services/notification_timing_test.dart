import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/services/notification_service.dart';

/// Pins the due-boundary arithmetic behind the biweekly reminder.
///
/// Regression context: the reminder due-check used to compare "now" against
/// the NEXT notification date, which by construction is always in the future,
/// so reminders never fired. The check now fires when a boundary
/// (consent date + k * interval) has passed that is newer than the last
/// notification shown.
void main() {
  const interval = Duration(days: 14);
  final consent = DateTime(2026, 1, 1, 12);

  group('lastDueBoundaryFromConsent', () {
    test('is null before the first interval has elapsed', () {
      expect(
        NotificationService.lastDueBoundaryFromConsent(
            consent, interval, consent.add(Duration(days: 13, hours: 23))),
        isNull,
      );
    });

    test('returns the first boundary exactly at consent + interval', () {
      expect(
        NotificationService.lastDueBoundaryFromConsent(
            consent, interval, consent.add(interval)),
        consent.add(interval),
      );
    });

    test('returns the most recent passed boundary, not the next one', () {
      // 30 days after consent: boundaries at day 14 and 28 have passed.
      final now = consent.add(Duration(days: 30));
      expect(
        NotificationService.lastDueBoundaryFromConsent(consent, interval, now),
        consent.add(Duration(days: 28)),
      );
    });

    test('boundary is never in the future', () {
      for (final daysAfter in [14, 15, 27, 28, 29, 100, 365]) {
        final now = consent.add(Duration(days: daysAfter));
        final boundary = NotificationService.lastDueBoundaryFromConsent(
            consent, interval, now);
        expect(boundary, isNotNull);
        expect(boundary!.isAfter(now), isFalse,
            reason: 'boundary must be <= now for daysAfter=$daysAfter');
      }
    });

    test('handles a non-positive interval without dividing by zero', () {
      expect(
        NotificationService.lastDueBoundaryFromConsent(
            consent, Duration.zero, consent.add(interval)),
        isNull,
      );
    });
  });
}
