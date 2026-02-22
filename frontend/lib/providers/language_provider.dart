import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;

class LanguageProvider with ChangeNotifier {
  Locale _locale = const Locale('en');
  bool _isLanguageSelected = false;

  static const String _languageKey = 'app_language';
  static const String _selectionKey = 'language_selected';

  Locale get locale => _locale;
  bool get isLanguageSelected => _isLanguageSelected;

  String get languageCode => _locale.languageCode;

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Future<void> _loadSavedLanguage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLanguage = prefs.getString(_languageKey);
      _isLanguageSelected = prefs.getBool(_selectionKey) ?? false;

      if (savedLanguage != null) {
        _locale = Locale(savedLanguage);
      } else {
        // Detect system language
        final systemLocale = ui.PlatformDispatcher.instance.locale;
        final sysCode = systemLocale.languageCode;
        if (['en', 'ar', 'fr'].contains(sysCode)) {
          _locale = Locale(sysCode);
        }
      }
      notifyListeners();
    } catch (e) {
      // If loading fails, keep default locale
      debugPrint('Error loading saved language: $e');
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _locale = Locale(languageCode);
    _isLanguageSelected = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, languageCode);
      await prefs.setBool(_selectionKey, true);
    } catch (e) {
      debugPrint('Error saving language preference: $e');
    }
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'ar':
        return 'العربية';
      default:
        return code;
    }
  }
}
