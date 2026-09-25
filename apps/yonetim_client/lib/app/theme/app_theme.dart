import 'package:flutter/material.dart';

import '../services/secure_storage.dart';

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

/// Kullanici temasi: acik paletler + sistem takibi. Kartlar tum temalarda
/// acik tutulur, boylece sabit yazi renkleri her yerde okunur.
enum AppThemeId { system, bordo, okyanus, orman, gece }

extension AppThemeLabel on AppThemeId {
  String get label {
    switch (this) {
      case AppThemeId.system:
        return 'Sistem';
      case AppThemeId.bordo:
        return 'Bordo';
      case AppThemeId.okyanus:
        return 'Okyanus';
      case AppThemeId.orman:
        return 'Orman';
      case AppThemeId.gece:
        return 'Gece';
    }
  }
}

class ThemeController {
  static final ValueNotifier<AppThemeId> current = ValueNotifier(AppThemeId.system);

  static Future<void> restore(SecureStoragePort storage) async {
    final raw = await storage.read(key: 'theme_id');
    if (raw == null) {
      AppInk.apply(AppThemeId.system);
      return;
    }
    final id = AppThemeId.values.firstWhere(
      (entry) => entry.name == raw,
      orElse: () => AppThemeId.system,
    );
    current.value = id;
    AppInk.apply(id);
  }

  static Future<void> select(AppThemeId id, SecureStoragePort storage) async {
    current.value = id;
    AppInk.apply(id);
    await storage.write(key: 'theme_id', value: id.name);
  }
}

/// Sabit marka renklerinin disinda, temaya gore degisen yazi/cizgi renkleri.
/// Koyu temada okunurluk bununla saglanir; kullanimda `const` kaldirilir.
abstract final class AppInk {
  static Color text = AppColors.charcoal;
  static Color subtle = AppColors.muted;
  static Color divider = AppColors.creamDark;

  static void apply(AppThemeId id) {
    if (id == AppThemeId.gece) {
      text = const Color(0xFFF0EAE6);
      subtle = const Color(0xFFB9AEAC);
      divider = const Color(0xFF3A3340);
    } else {
      text = AppColors.charcoal;
      subtle = AppColors.muted;
      divider = AppColors.creamDark;
    }
  }
}

class _Palette {
  const _Palette({
    required this.primary,
    required this.surface,
    required this.card,
    required this.navBar,
    required this.appBarForeground,
    required this.inputFill,
    required this.border,
    required this.snackBar,
    required this.brightness,
  });

  final Color primary;
  final Color surface;
  final Color card;
  final Color navBar;
  final Color appBarForeground;
  final Color inputFill;
  final Color border;
  final Color snackBar;
  final Brightness brightness;
}

_Palette _paletteFor(AppThemeId id) {
  switch (id) {
    case AppThemeId.okyanus:
      return const _Palette(
        primary: Color(0xFF0E7C7B),
        surface: Color(0xFFEAF4F3),
        card: Colors.white,
        navBar: Colors.white,
        appBarForeground: AppColors.charcoal,
        inputFill: Colors.white,
        border: Color(0xFFD3E6E4),
        snackBar: Color(0xFF123B3B),
        brightness: Brightness.light,
      );
    case AppThemeId.orman:
      return const _Palette(
        primary: Color(0xFF3F7A44),
        surface: Color(0xFFEFF4EA),
        card: Colors.white,
        navBar: Colors.white,
        appBarForeground: AppColors.charcoal,
        inputFill: Colors.white,
        border: Color(0xFFD9E5CF),
        snackBar: Color(0xFF1E3320),
        brightness: Brightness.light,
      );
    case AppThemeId.gece:
      return const _Palette(
        primary: AppColors.burgundy,
        surface: Color(0xFF211C24),
        card: Colors.white,
        navBar: Color(0xFF262027),
        appBarForeground: Colors.white,
        inputFill: Color(0xFF2C2631),
        border: Color(0xFF3A3340),
        snackBar: Color(0xFF332C38),
        brightness: Brightness.dark,
      );
    case AppThemeId.system:
    case AppThemeId.bordo:
      return const _Palette(
        primary: AppColors.burgundy,
        surface: AppColors.cream,
        card: Colors.white,
        navBar: Colors.white,
        appBarForeground: AppColors.charcoal,
        inputFill: Colors.white,
        border: AppColors.creamDark,
        snackBar: AppColors.charcoal,
        brightness: Brightness.light,
      );
  }
}

ThemeData buildAppTheme({bool monochrome = false, AppThemeId id = AppThemeId.bordo}) {
  if (monochrome) return _monochromeTheme();
  final palette = _paletteFor(id);
  final scheme = ColorScheme.fromSeed(
    seedColor: palette.primary,
    brightness: palette.brightness,
    primary: palette.primary,
    secondary: AppColors.gold,
    surface: palette.surface,
    error: AppColors.error,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: palette.surface,
    fontFamily: 'Avenir',
    appBarTheme: AppBarTheme(
      backgroundColor: palette.surface,
      foregroundColor: palette.appBarForeground,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: palette.inputFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: palette.primary, width: 1.5),
      ),
      labelStyle: const TextStyle(color: AppColors.muted),
    ),
    cardTheme: CardThemeData(
      color: palette.card,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: palette.border,
      selectedColor: palette.primary,
      labelStyle: const TextStyle(color: AppColors.charcoal),
      secondaryLabelStyle: const TextStyle(color: Colors.white),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: palette.navBar,
      indicatorColor: palette.border,
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: palette.snackBar,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );
}

ThemeData _monochromeTheme() {
  const primary = Colors.black;
  const surface = Color(0xFFF5F5F5);
  final scheme = ColorScheme.fromSeed(
    seedColor: primary,
    brightness: Brightness.dark,
    primary: primary,
    secondary: Colors.black87,
    surface: surface,
    error: Colors.black,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: surface,
    fontFamily: 'Avenir',
    appBarTheme: const AppBarTheme(
      backgroundColor: surface,
      foregroundColor: Colors.black,
      elevation: 0,
      centerTitle: false,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.creamDark),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
        borderSide: BorderSide(color: Colors.black, width: 1.5),
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
