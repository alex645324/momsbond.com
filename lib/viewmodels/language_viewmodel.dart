import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Database_logic/simple_auth_manager.dart';

class LanguageViewModel extends ChangeNotifier {
  static const _prefsKey = 'pref_language';

  String _currentLanguage = 'en';
  String get currentLanguage => _currentLanguage;

  // Load saved preference on startup
  Future<void> loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _currentLanguage = prefs.getString(_prefsKey) ?? 'en';
    print('LanguageViewModel: Loaded language from prefs -> \\$_currentLanguage');
    notifyListeners();
  }

  // Persist new language selection
  Future<void> setLanguage(String languageCode) async {
    _currentLanguage = languageCode;
    print('LanguageViewModel: Language set to \\$_currentLanguage');
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, languageCode);

    // Persist to user profile if authenticated
    await SimpleAuthManager().saveUserData('language', languageCode);
  }
} 