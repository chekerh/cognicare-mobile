import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';

const String _themeIdKey = 'app_theme_id';
const String _defaultThemeId = 'amour';

/// Fournit le thème actuel de l'app (sauvegardé en SharedPreferences).
/// Quand l'utilisateur choisit un thème dans l'écran Thème, on appelle
/// [setThemeId] et toute l'app se met à jour.
class ThemeProvider extends ChangeNotifier {
  String? _themeId;
  bool _loaded = false;

  String? get themeId => _themeId;
  bool get loaded => _loaded;

  ThemeData get currentTheme =>
      AppTheme.themeForId(_themeId ?? _defaultThemeId);

  ThemeProvider({String? initialThemeId}) {
    _themeId = initialThemeId ?? _defaultThemeId;
    _loaded = true;
  }

  Future<void> setThemeId(String id) async {
    if (_themeId == id) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeIdKey, id);
    _themeId = id;
    notifyListeners();
  }
}
