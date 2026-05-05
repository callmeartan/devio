import 'package:flutter/material.dart';

class AppTheme {
  static const _ink = Color(0xFF211F1C);
  static const _mutedInk = Color(0xFF6F6A61);
  static const _canvas = Color(0xFFF7F2EA);
  static const _panel = Color(0xFFFFFCF6);
  static const _softPanel = Color(0xFFEFE7DB);
  static const _line = Color(0xFFE1D8CA);
  static const _ember = Color(0xFFB85F3A);
  static const _sage = Color(0xFF586F62);
  static const _danger = Color(0xFFB3261E);

  static const _darkInk = Color(0xFFF4F4F4);
  static const _darkMutedInk = Color(0xFFA8A8A8);
  static const _darkCanvas = Color(0xFF151515);
  static const _darkPanel = Color(0xFF242424);
  static const _darkSoftPanel = Color(0xFF303030);
  static const _darkLine = Color(0xFF3A3A3A);
  static const _darkEmber = Color(0xFFD0D0D0);

  static final lightTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'JosefinSans',
    colorScheme: ColorScheme.fromSeed(
      seedColor: _ember,
      brightness: Brightness.light,
    ).copyWith(
      primary: _ink,
      secondary: _ember,
      tertiary: _sage,
      surface: _panel,
      surfaceContainerHighest: _softPanel,
      error: _danger,
      onPrimary: _panel,
      onSecondary: _panel,
      onSurface: _ink,
      onSurfaceVariant: _mutedInk,
      primaryContainer: _softPanel,
      onPrimaryContainer: _ink,
      outline: _line,
      outlineVariant: _line,
    ),
    scaffoldBackgroundColor: _canvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: _canvas,
      foregroundColor: _ink,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: _panel,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: _line,
      thickness: 1,
      space: 1,
    ),
    textTheme: _textTheme(_ink, _mutedInk),
    inputDecorationTheme: _inputDecorationTheme(
      fillColor: _panel,
      mutedColor: _mutedInk,
      lineColor: _line,
      focusColor: _ink,
      errorColor: _danger,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _ink,
        foregroundColor: _panel,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _ink,
        foregroundColor: _panel,
        minimumSize: const Size(48, 44),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _ink,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: _line),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _ink,
        minimumSize: const Size(44, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _ink,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: _panel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _line),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _panel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _ink,
      contentTextStyle: const TextStyle(color: _panel),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'JosefinSans',
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: _darkEmber,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _darkInk,
      secondary: _darkEmber,
      tertiary: const Color(0xFFB6B6B6),
      surface: _darkPanel,
      surfaceContainerHighest: _darkSoftPanel,
      error: const Color(0xFFFFB4AB),
      onPrimary: _darkCanvas,
      onSecondary: _darkCanvas,
      onSurface: _darkInk,
      onSurfaceVariant: _darkMutedInk,
      primaryContainer: _darkSoftPanel,
      onPrimaryContainer: _darkInk,
      outline: _darkLine,
      outlineVariant: _darkLine,
    ),
    scaffoldBackgroundColor: _darkCanvas,
    appBarTheme: const AppBarTheme(
      backgroundColor: _darkCanvas,
      foregroundColor: _darkInk,
      elevation: 0,
      centerTitle: false,
      surfaceTintColor: Colors.transparent,
    ),
    drawerTheme: const DrawerThemeData(
      backgroundColor: _darkPanel,
      surfaceTintColor: Colors.transparent,
    ),
    dividerTheme: const DividerThemeData(
      color: _darkLine,
      thickness: 1,
      space: 1,
    ),
    textTheme: _textTheme(_darkInk, _darkMutedInk),
    inputDecorationTheme: _inputDecorationTheme(
      fillColor: _darkPanel,
      mutedColor: _darkMutedInk,
      lineColor: _darkLine,
      focusColor: _darkInk,
      errorColor: const Color(0xFFFFB4AB),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: _darkInk,
        foregroundColor: _darkCanvas,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: _darkInk,
        foregroundColor: _darkCanvas,
        minimumSize: const Size(48, 44),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: _darkInk,
        minimumSize: const Size(48, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        side: const BorderSide(color: _darkLine),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: _darkInk,
        minimumSize: const Size(44, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: _darkInk,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    ),
    cardTheme: CardThemeData(
      color: _darkPanel,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: _darkLine),
      ),
      margin: EdgeInsets.zero,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: _darkPanel,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _darkInk,
      contentTextStyle: const TextStyle(color: _darkCanvas),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  );

  static TextTheme _textTheme(Color textColor, Color mutedColor) {
    return TextTheme(
      displayLarge: TextStyle(
        fontSize: 34,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.05,
        letterSpacing: 0,
      ),
      displayMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.08,
        letterSpacing: 0,
      ),
      displaySmall: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.12,
        letterSpacing: 0,
      ),
      headlineMedium: TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.2,
        letterSpacing: 0,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.25,
        letterSpacing: 0,
      ),
      titleMedium: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.25,
        letterSpacing: 0,
      ),
      titleSmall: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: textColor,
        height: 1.25,
        letterSpacing: 0,
      ),
      bodyLarge: TextStyle(
        fontSize: 16,
        color: textColor,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: mutedColor,
        height: 1.45,
        letterSpacing: 0,
      ),
      bodySmall: TextStyle(
        fontSize: 12,
        color: mutedColor,
        height: 1.35,
        letterSpacing: 0,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        color: mutedColor,
        fontWeight: FontWeight.w700,
        letterSpacing: 0,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({
    required Color fillColor,
    required Color mutedColor,
    required Color lineColor,
    required Color focusColor,
    required Color errorColor,
  }) {
    return InputDecorationTheme(
      filled: true,
      fillColor: fillColor,
      labelStyle: TextStyle(color: mutedColor),
      hintStyle: TextStyle(color: mutedColor.withOpacity(0.72)),
      prefixIconColor: mutedColor,
      suffixIconColor: mutedColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lineColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: lineColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: focusColor, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: errorColor, width: 1.4),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }
}
