import 'package:flutter/material.dart';

/// "Quest" look: deep midnight-blue ground, parchment-gold accents, an
/// elegant serif for display text and quotes. Dark-only by design – the
/// atmosphere is the point.
class AppTheme {
  const AppTheme._();

  // Gold family (XP, level, rewards, primary actions).
  static const Color gold = Color(0xFFD4A94A);
  static const Color goldBright = Color(0xFFEBC978);
  static const Color goldDim = Color(0xFF8A7434);

  // Backwards-compatible accent aliases used across the app.
  static const Color xpAccent = gold;
  static const Color streakAccent = Color(0xFFF08A3C);
  static const Color successAccent = Color(0xFF54D08A);

  // Surfaces.
  static const Color bg = Color(0xFF0A0E18);
  static const Color bgRaised = Color(0xFF0E1524);
  static const Color card = Color(0xFF121A2C);
  static const Color cardInset = Color(0xFF0C121F);
  static const Color border = Color(0xFF243350);
  static const Color hairline = Color(0xFF1B2740);

  static const Color textHigh = Color(0xFFEAEEF7);
  static const Color textMid = Color(0xFF97A2B8);
  static const Color textLow = Color(0xFF63708A);

  /// Serif stack for headings and quotes; browsers/desktop all ship one.
  static const List<String> serif = [
    'Georgia',
    'Iowan Old Style',
    'Times New Roman',
    'serif',
  ];

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFB98A2E), gold, goldBright],
  );

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: gold,
      brightness: Brightness.dark,
    );
    final colorScheme = base.copyWith(
      primary: gold,
      onPrimary: const Color(0xFF231A05),
      secondary: goldBright,
      surface: card,
      onSurface: textHigh,
      surfaceContainerHighest: const Color(0xFF1B2740),
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      textTheme: _textTheme(),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        foregroundColor: textHigh,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: gold.withValues(alpha: 0.14),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        selectedIconTheme: const IconThemeData(color: goldBright),
        unselectedIconTheme: const IconThemeData(color: textLow),
        selectedLabelTextStyle: const TextStyle(
          color: goldBright,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelTextStyle: const TextStyle(color: textMid),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgRaised,
        elevation: 0,
        indicatorColor: gold.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      dividerTheme: const DividerThemeData(color: hairline, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: gold,
          foregroundColor: const Color(0xFF231A05),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: goldBright,
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: goldBright),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? gold.withValues(alpha: 0.16)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? goldBright
                : textMid,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardInset,
        side: const BorderSide(color: border),
        shape: const StadiumBorder(),
        labelStyle: const TextStyle(color: textHigh),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardInset,
        hintStyle: const TextStyle(color: textLow),
        labelStyle: const TextStyle(color: textMid),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: gold, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: border),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: border,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: border),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: gold,
        inactiveTrackColor: Color(0xFF1B2740),
        thumbColor: goldBright,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: card,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: gold,
        linearTrackColor: Color(0xFF1B2740),
        circularTrackColor: Color(0xFF1B2740),
      ),
    );
  }

  static TextTheme _textTheme() {
    const display = TextStyle(
      fontFamilyFallback: serif,
      color: textHigh,
      fontWeight: FontWeight.w600,
    );
    return const TextTheme(
      displaySmall: display,
      headlineLarge: TextStyle(
        fontFamilyFallback: serif,
        color: textHigh,
        fontWeight: FontWeight.w600,
      ),
      headlineMedium: TextStyle(
        fontFamilyFallback: serif,
        color: textHigh,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: TextStyle(
        fontFamilyFallback: serif,
        color: textHigh,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: TextStyle(color: textHigh, fontWeight: FontWeight.w700),
      titleMedium: TextStyle(color: textHigh, fontWeight: FontWeight.w600),
      titleSmall: TextStyle(color: textHigh, fontWeight: FontWeight.w600),
      bodyLarge: TextStyle(color: textHigh),
      bodyMedium: TextStyle(color: textMid),
      bodySmall: TextStyle(color: textLow),
      labelLarge: TextStyle(color: textHigh, fontWeight: FontWeight.w600),
      labelMedium: TextStyle(color: textMid),
      labelSmall: TextStyle(color: textLow),
    );
  }

  /// Italic serif style for the motivational quotes sprinkled around the UI.
  static const TextStyle quote = TextStyle(
    fontFamilyFallback: serif,
    fontStyle: FontStyle.italic,
    color: textMid,
    height: 1.5,
  );
}
