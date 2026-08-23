import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:med_intel/theme/app_theme.dart';

/// Keeps the app's active [Locale] in sync with the 'Language' choice on the
/// Settings screen, which is persisted under [prefsKey] as 'English' or 'اردو'.
class LocaleProvider extends ChangeNotifier {
  static const prefsKey = 'settings_language';

  static const englishLabel = 'English';
  static const urduLabel = 'اردو';

  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  bool get isUrdu => _locale.languageCode == 'ur';

  String get languageLabel => isUrdu ? urduLabel : englishLabel;

  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(prefsKey) ?? englishLabel;
    _locale = saved == urduLabel ? const Locale('ur') : const Locale('en');
    AppFonts.isUrdu = isUrdu;
    notifyListeners();
  }

  Future<void> setLanguage(String label) async {
    final newLocale = label == urduLabel ? const Locale('ur') : const Locale('en');
    if (newLocale == _locale) return;
    _locale = newLocale;
    AppFonts.isUrdu = isUrdu;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, label);
  }
}
