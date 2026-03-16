import 'package:flutter/material.dart';

class AppTheme {
  // Color Palette
  static const navyBlue = Color(0xFF1A237E);
  static const lightBlue = Color(0xFF4FC3F7);
  static const deepSkyBlue = Color(0xFF0288D1);
  static const backgroundGrey = Color(0xFFF5F7FA);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: navyBlue,
        primary: navyBlue,
        secondary: lightBlue,
        tertiary: deepSkyBlue,
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: backgroundGrey,

      // Professional Card Styling (FIXED: CardThemeData instead of CardTheme)
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: navyBlue,
        foregroundColor: Colors.white,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),

      // Text Theme
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: navyBlue, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Colors.black87),
      ),
    );
  }
}
