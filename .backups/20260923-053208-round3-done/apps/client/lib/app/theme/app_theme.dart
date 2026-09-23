import 'package:flutter/material.dart';

abstract final class AppColors {
  static const burgundy = Color(0xFF7A1F3D);
  static const burgundyDark = Color(0xFF4D1228);
  static const cream = Color(0xFFFFF8EE);
  static const creamDark = Color(0xFFF4E9D7);
  static const charcoal = Color(0xFF272329);
  static const muted = Color(0xFF5F555A);
  static const gold = Color(0xFFC89B3C);
  static const sage = Color(0xFF6D8A78);
  static const error = Color(0xFFB3261E);
}

ThemeData buildAppTheme({bool monochrome = false}) {
  final primary = monochrome ? Colors.black : AppColors.burgundy;
  final surface = monochrome ? const Color(0xFFF5F5F5) : AppColors.cream;
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: monochrome ? Brightness.dark : Brightness.light,
    primary: primary,
    secondary: monochrome ? Colors.black87 : AppColors.gold,
    surface: surface,
    error: monochrome ? Colors.black : AppColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    fontFamily: 'Avenir',
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: monochrome ? Colors.black : AppColors.charcoal,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: monochrome ? Colors.white : Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.creamDark),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.burgundy, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.creamDark,
      selectedColor: AppColors.burgundy,
      labelStyle: const TextStyle(color: AppColors.charcoal),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.creamDark,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.charcoal,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}
