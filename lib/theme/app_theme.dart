import 'package:flutter/material.dart';

class AppTheme {
  // Monochromatic color palette
  static const _primaryColor = Color(0xFF000000); // Pure black
  static const _backgroundColor = Color(0xFFFFFFFF); // Pure white
  static const _darkBackgroundColor = Color(0xFF000000); // Pure black
  static const _surfaceColor = Color(0xFFF5F5F5); // Light gray
  static const _darkSurfaceColor = Color(0xFF1A1A1A); // Dark gray
  static const _textColor = Color(0xFF000000); // Black text
  static const _darkTextColor = Color(0xFFFFFFFF); // White text

  static final lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'JosefinSans',
    colorScheme: ColorScheme.light(
      primary: _primaryColor,
      secondary: _primaryColor,
      surface: _surfaceColor,
      error: const Color(0xFF000000),
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _textColor,
      primaryContainer: _surfaceColor,
      onPrimaryContainer: _textColor,
    ),
    scaffoldBackgroundColor: _backgroundColor,
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _textColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _textColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _textColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _textColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _textColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _textColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: _textColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: _textColor.withOpacity(0.8),
        height: 1.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _textColor.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _textColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: const BorderSide(color: _primaryColor),
      ),
    ),
    cardTheme: CardTheme(
      color: _surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'JosefinSans',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.dark(
      primary: Colors.white,
      secondary: Colors.white,
      surface: _darkSurfaceColor,
      error: const Color(0xFFFFFFFF),
      onSurface: _darkTextColor,
      onPrimary: Colors.black,
      onSecondary: Colors.black,
      primaryContainer: _darkSurfaceColor,
      onPrimaryContainer: _darkTextColor,
    ),
    scaffoldBackgroundColor: _darkBackgroundColor,
    textTheme: TextTheme(
      displayLarge: TextStyle(
        fontSize: 32,
        fontWeight: FontWeight.bold,
        color: _darkTextColor,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: _darkTextColor,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: _darkTextColor,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: _darkTextColor,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: _darkTextColor,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: _darkTextColor,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: _darkTextColor,
        height: 1.5,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: _darkTextColor.withOpacity(0.8),
        height: 1.5,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _darkSurfaceColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkTextColor.withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _darkTextColor.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 44),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, 48),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        side: const BorderSide(color: Color(0xFF30363D)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _primaryColor,
        minimumSize: const Size(88, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    ),
    cardTheme: CardTheme(
      color: _surfaceColor,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFF30363D), width: 1),
      ),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF30363D),
      thickness: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _surfaceColor,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
