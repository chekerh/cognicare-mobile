import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const Color primary = Color(0xFFA4D7E1);
  static const Color secondary = Color(0xFFA7E9A4);
  static const Color accent = Color(0xFFF9D51C);
  static const Color text = Color(0xFF5A5A5A);
  static const Color background = Color(0xFFF6F6F6);

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primary,
      scaffoldBackgroundColor: background,
      fontFamily: 'Roboto', // Sans-serif font

      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: text,
        elevation: 0,
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: text,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primary),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary.withOpacity(0.5)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        labelStyle: const TextStyle(color: text),
        hintStyle: TextStyle(color: text.withOpacity(0.6)),
      ),

      // Text Themes
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: text,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: text,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: TextStyle(
          color: text,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: TextStyle(
          color: text,
          fontSize: 16,
          fontWeight: FontWeight.normal,
        ),
        bodyMedium: TextStyle(
          color: text,
          fontSize: 14,
          fontWeight: FontWeight.normal,
        ),
      ),

      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primary,
        secondary: secondary,
        surface: Colors.white,
        onPrimary: text,
        onSecondary: text,
        onSurface: text,
      ),
    );
  }

  /// Couleur principale associée à chaque thème (écran de sélection).
  static Color primaryForThemeId(String? id) {
    switch (id) {
      case 'amour':
        return const Color(0xFF9B3D7A);
      case 'saint_valentin':
        return const Color(0xFF9B59B6);
      case 'simpsons':
        return const Color(0xFFFFD93D);
      case 'football':
        return const Color(0xFF2D5016);
      case 'brat':
        return const Color(0xFF39FF14);
      case 'je_taime':
        return const Color(0xFFFF69B4);
      case 'cool_crew':
        return const Color(0xFF1E3A5F);
      case 'hivernal':
        return const Color(0xFF2C3E50);
      case 'shape_friends':
        return const Color(0xFF74B9FF);
      default:
        return primary;
    }
  }

  /// Fond de la zone de discussion (comme Messenger) selon le thème choisi.
  /// À utiliser comme decoration du Container qui contient la liste des messages.
  static BoxDecoration chatBackgroundForThemeId(String? id) {
    switch (id) {
      case 'amour':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF6B2D5C).withOpacity(0.25),
              const Color(0xFF9B3D7A).withOpacity(0.2),
            ],
          ),
        );
      case 'saint_valentin':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF9B59B6).withOpacity(0.22),
              const Color(0xFFE8DAEF),
            ],
          ),
        );
      case 'simpsons':
        return BoxDecoration(
          color: const Color(0xFFFFD93D).withOpacity(0.2),
        );
      case 'football':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2D5016).withOpacity(0.2),
              const Color(0xFFD5F5E3),
            ],
          ),
        );
      case 'brat':
        return BoxDecoration(
          color: const Color(0xFF0D0D0D).withOpacity(0.08),
        );
      case 'je_taime':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFFFF69B4).withOpacity(0.2),
              const Color(0xFFFFB6C1).withOpacity(0.3),
            ],
          ),
        );
      case 'cool_crew':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF1E3A5F).withOpacity(0.2),
              const Color(0xFFEBF5FB),
            ],
          ),
        );
      case 'hivernal':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF2C3E50).withOpacity(0.18),
              const Color(0xFFEDF2F7),
            ],
          ),
        );
      case 'shape_friends':
        return BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF74B9FF).withOpacity(0.2),
              const Color(0xFF81ECEC).withOpacity(0.2),
              const Color(0xFF55EFC4).withOpacity(0.15),
            ],
          ),
        );
      default:
        return BoxDecoration(
          color: const Color(0xFFF8FAFC),
        );
    }
  }

  /// Thème Material complet pour un id (appliqué à toute l'app).
  static ThemeData themeForId(String? id) {
    final primaryColor = primaryForThemeId(id);
    final bg = primaryColor.withOpacity(0.08);
    return ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: bg,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor.withOpacity(0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        secondary: secondary,
        surface: Colors.white,
        onPrimary: Colors.white,
        onSecondary: text,
        onSurface: text,
      ),
    );
  }
}