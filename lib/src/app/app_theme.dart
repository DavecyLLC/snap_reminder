// lib/app_theme.dart
import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData darkPurple() {
    const bg = Color(0xFF1A1730); // light purple background (dark theme)
    const surface = Color(0xFF23204A);
    const sheet = Color(0xFF201D3D);

    const primary = Color(0xFF7C5CFF);
    const secondary = Color(0xFF8BE9D3);
    const error = Color(0xFFFF6B6B);

    const outline = Color(0xFF3A3670);
    const mutedText = Color(0xFFD6D9FF);

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorSchemeSeed: primary,
    );

    return base.copyWith(
      scaffoldBackgroundColor: bg,
      colorScheme: base.colorScheme.copyWith(
        background: bg,
        surface: surface,
        primary: primary,
        secondary: secondary,
        error: error,
        outline: outline,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 3,
        shadowColor: Colors.black.withOpacity(0.25),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      textTheme: base.textTheme.copyWith(
        titleLarge: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.white),
        bodyMedium: const TextStyle(fontSize: 15, color: mutedText, height: 1.25),
        labelMedium: const TextStyle(fontSize: 13, color: Colors.white70),
      ),
      iconTheme: const IconThemeData(color: mutedText, size: 22),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        hintStyle: const TextStyle(color: Colors.white54),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: sheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: outline, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          side: const BorderSide(color: outline),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
    );
  }
}
