import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkPurple() {
    const background = Color(0xffd4c0fa); // light purple background
    const card = Color(0xFFFFFFFF); // white cards
    const accent = Color(0xFF7C5CFF); // purple accent
    const textPrimary = Color(0xFF1F1F2E);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: ColorScheme.fromSeed(
        seedColor: accent,
        brightness: Brightness.light,
        surface: card,
        background: background,
      ),

      scaffoldBackgroundColor: background,

      appBarTheme: const AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textPrimary,
      ),

      // ✅ FIX: use CardThemeData (not CardTheme)
      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
        ),
      ),

      textTheme: const TextTheme(
        titleLarge: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyMedium: TextStyle(color: textPrimary),
        labelMedium: TextStyle(color: Colors.black54),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8F6FF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: Colors.black45),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),

      listTileTheme: const ListTileThemeData(
        iconColor: accent,
        textColor: textPrimary,
      ),

      dividerTheme: const DividerThemeData(
        color: Colors.black12,
      ),
    );
  }
}
