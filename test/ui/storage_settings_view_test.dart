import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wellbeing_mapper/services/device_backup_service.dart';
import 'package:wellbeing_mapper/ui/storage_settings_view.dart';

Widget _app({Locale? locale}) {
  return MaterialApp(
    locale: locale,
    supportedLocales: const [Locale('en'), Locale('it'), Locale('es')],
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    home: StorageSettingsView(),
  );
}

void main() {
  const switchKey = Key('includeHistoryInBackupsSwitch');

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('phone-backup switch is off by default and saves the choice',
      (WidgetTester tester) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    final toggle = find.byKey(switchKey);
    expect(tester.widget<Switch>(toggle).value, isFalse);

    await tester.ensureVisible(toggle);
    await tester.tap(toggle);
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(toggle).value, isTrue);
    expect(await DeviceBackupService.isHistoryIncluded(), isTrue);
  });

  testWidgets('a saved choice is shown when the screen opens',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(
        {DeviceBackupService.includeHistoryKey: true});

    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(tester.widget<Switch>(find.byKey(switchKey)).value, isTrue);
  });

  testWidgets('the setting is shown in Italian and Spanish',
      (WidgetTester tester) async {
    await tester.pumpWidget(_app(locale: const Locale('it')));
    await tester.pumpAndSettle();
    expect(find.text('Includi i miei dati nei backup del telefono'),
        findsOneWidget);

    await tester.pumpWidget(_app(locale: const Locale('es')));
    await tester.pumpAndSettle();
    expect(find.text('Incluir mis datos en las copias de seguridad del teléfono'),
        findsOneWidget);
  });
}
