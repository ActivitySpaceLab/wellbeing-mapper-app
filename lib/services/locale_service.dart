import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages an in-app language override so users can switch the app language
/// without changing their device settings (useful for testing translations
/// and for participants who prefer a different language).
///
/// When [localeOverride] is null, the app follows the device locale (resolved
/// against the supported locales). Otherwise the chosen locale is used.
class LocaleService {
  static const String _prefsKey = 'app_locale_override';

  /// Languages the user can choose from in the picker.
  /// Keep in sync with `MyApp.supportedLocales` and the `lang/*.json` files.
  static const List<Locale> supportedLocales = [
    Locale('en', ''),
    Locale('es', ''),
    Locale('it', ''),
  ];

  /// Human-readable names for the picker (shown in each language's own name).
  static const Map<String, String> languageNames = {
    'en': 'English',
    'es': 'Español',
    'it': 'Italiano',
  };

  /// Current override. `null` means "follow device language".
  static final ValueNotifier<Locale?> localeOverride =
      ValueNotifier<Locale?>(null);

  /// Load any persisted override at startup. Call before `runApp`.
  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final code = prefs.getString(_prefsKey);
      if (code != null && code.isNotEmpty) {
        localeOverride.value = Locale(code, '');
      }
    } catch (_) {
      // Ignore – fall back to device locale.
    }
  }

  /// Set (or clear, when [locale] is null) the language override and persist it.
  static Future<void> setLocale(Locale? locale) async {
    localeOverride.value = locale;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (locale == null) {
        await prefs.remove(_prefsKey);
      } else {
        await prefs.setString(_prefsKey, locale.languageCode);
      }
    } catch (_) {
      // Persisting is best-effort; the in-memory value still applies.
    }
  }

  static String displayName(String code) => languageNames[code] ?? code;
}
