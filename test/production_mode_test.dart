import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/services/app_mode_service.dart';
import 'package:wellbeing_mapper/models/app_mode.dart';

/// Tests run with the default flavor ('production', not a demo/beta build)
/// and without FLUTTER_TEST_MODE, so AppModeService applies the same mode
/// restrictions a production build does.
void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AppModeService Production Tests', () {
    test('getAvailableModes returns only private and research for production',
        () {
      final availableModes = AppModeService.getAvailableModes();

      expect(availableModes, contains(AppMode.private));
      expect(availableModes, contains(AppMode.research));
      expect(availableModes, isNot(contains(AppMode.appTesting)));
    });

    test('defaults to private mode with nothing stored', () async {
      expect(await AppModeService.getCurrentMode(), AppMode.private);
      expect(await AppModeService.sendsDataToResearch(), isFalse);
    });

    test('research mode sends data to research', () async {
      await AppModeService.setCurrentMode(AppMode.research);

      expect(await AppModeService.getCurrentMode(), AppMode.research);
      expect(await AppModeService.sendsDataToResearch(), isTrue);
    });

    test('refuses to store appTesting mode in a production build', () async {
      await AppModeService.setCurrentMode(AppMode.appTesting);

      // The mode must not be persisted, and data must not flow to research.
      expect(await AppModeService.getCurrentMode(), AppMode.private);
      expect(await AppModeService.sendsDataToResearch(), isFalse);
    });

    test('stored appTesting mode falls back to private in production',
        () async {
      // Simulates a device that stored appTesting under a beta build and then
      // upgraded to a production build: the stored mode is not available and
      // must degrade safely.
      SharedPreferences.setMockInitialValues({'app_mode': 'appTesting'});

      expect(await AppModeService.getCurrentMode(), AppMode.private);
      expect(await AppModeService.sendsDataToResearch(), isFalse);
    });

    test('unknown stored mode string falls back to private', () async {
      SharedPreferences.setMockInitialValues({'app_mode': 'garbage_value'});

      expect(await AppModeService.getCurrentMode(), AppMode.private);
      expect(await AppModeService.sendsDataToResearch(), isFalse);
    });
  });
}
