// ignore_for_file: deprecated_member_useimport 'package:flutter/material.dart';
class AppTheme {
  static const Color primary = Color(0xFF4FA38D);
  static const Color background = Color(0xFFF8F9F2);
  static const Color accent = Color(0xFFFFB900);
  static const Color card = Color(0xFFFFFFFF);
  static const Color text = Color(0xFF414331);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        surface: background,
      ),
      scaffoldBackgroundColor: background,

      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(40),
          ),
        ),
      ),

      cardTheme: CardThemeData(
        color: card,
        elevation: 2,
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 7,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),

      floatingActionButtonTheme:
          const FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: text,
        elevation: 5,
      ),

      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: background,
        indicatorColor: Color(0xFFD7EDE3),
      ),
    );
  }
}
