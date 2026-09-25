import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wellbeing_mapper/models/app_localizations.dart';
import 'package:wellbeing_mapper/services/locale_service.dart';

/// Enforces the "keep in sync" invariant the code comments ask for:
/// every locale offered in the in-app language picker must be accepted by
/// the AppLocalizations delegate and backed by a lang/<code>.json file whose
/// keys match English exactly. A locale failing any of these shows raw keys
/// or silently falls back to English.
void main() {
  test('picker locales are supported by the delegate', () {
    for (final locale in LocaleService.supportedLocales) {
      expect(
        AppLocalizations.delegate.isSupported(locale),
        isTrue,
        reason:
            '${locale.languageCode} is offered in the picker but rejected by '
            'AppLocalizations.delegate.isSupported — its translations would '
            'never load',
      );
    }
  });

  test('every picker locale has a language name', () {
    for (final locale in LocaleService.supportedLocales) {
      expect(LocaleService.languageNames, contains(locale.languageCode));
    }
  });

  test('lang/<code>.json exists and matches en.json keys for every locale',
      () {
    final enKeys = (jsonDecode(File('lang/en.json').readAsStringSync())
            as Map<String, dynamic>)
        .keys
        .toSet();
    expect(enKeys, isNotEmpty);

    for (final locale in LocaleService.supportedLocales) {
      final file = File('lang/${locale.languageCode}.json');
      expect(file.existsSync(), isTrue,
          reason: 'missing translation file for ${locale.languageCode}');

      final keys = (jsonDecode(file.readAsStringSync()) as Map<String, dynamic>)
          .keys
          .toSet();
      expect(enKeys.difference(keys), isEmpty,
          reason: '${locale.languageCode}.json is missing keys present in '
              'en.json — those strings would render as raw keys or English');
    }
  });

  test('delegate does not silently accept locales without a lang file', () {
    // Guards against adding a language code to isSupported() without adding
    // the picker entry and translation file.
    for (final code in ['en', 'it', 'es', 'ca', 'fr', 'de']) {
      final supported = AppLocalizations.delegate.isSupported(Locale(code, ''));
      final hasFile = File('lang/$code.json').existsSync();
      if (supported) {
        expect(hasFile, isTrue,
            reason: 'delegate accepts "$code" but lang/$code.json is missing');
      }
    }
  });
}
