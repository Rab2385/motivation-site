import 'package:flutter/material.dart';

/// Playful, gamified look: a vibrant indigo/violet seed, generously rounded
/// cards, and a warm XP accent used for progress and rewards.
class AppTheme {
  const AppTheme._();

  static const Color seed = Color(0xFF6C4BF4);
  static const Color xpAccent = Color(0xFFFFB020);
  static const Color streakAccent = Color(0xFFFF6B6B);
  static const Color successAccent = Color(0xFF3DD68C);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );
    final isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF12111A) : const Color(0xFFF6F5FB),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isDark ? const Color(0xFF1C1A28) : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isDark ? const Color(0xFF2C2A3C) : const Color(0xFFE7E4F2),
          ),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? const Color(0xFF12111A) : const Color(0xFFF6F5FB),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:
            isDark ? const Color(0xFF161522) : Colors.white,
        indicatorColor: colorScheme.primaryContainer,
        selectedIconTheme: IconThemeData(color: colorScheme.onPrimaryContainer),
        selectedLabelTextStyle: TextStyle(
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(0xFF161522) : Colors.white,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? const Color(0xFF201E2E) : const Color(0xFFF1EFFA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
      chipTheme: const ChipThemeData(
        shape: StadiumBorder(),
        side: BorderSide.none,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
