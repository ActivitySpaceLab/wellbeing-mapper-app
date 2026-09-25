import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/services/research_server_service.dart';
import 'package:wellbeing_mapper/util/env.dart';

/// Pins the collaborator-safety invariant promised in the README: while
/// SERVER_BASE_URL is the placeholder (i.e. no --dart-define was passed,
/// which is always the case for `flutter test`), every upload path must
/// refuse to send data anywhere.
void main() {
  group('Upload guard (placeholder server URL)', () {
    test('builds without --dart-define=SERVER_BASE_URL are unconfigured', () {
      expect(ENV.apiBaseUrl, contains('example.com'),
          reason: 'test builds must never carry a real server URL');
      expect(ENV.isServerConfigured, isFalse);
    });

    test('syncPendingSurveys is a complete no-op when unconfigured', () async {
      // The guard must fire before any database or platform-plugin access:
      // in a unit test any such access would throw MissingPluginException,
      // so completing normally proves the early return comes first.
      await ResearchServerService.syncPendingSurveys();
    });
  });
}
