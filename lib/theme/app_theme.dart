import 'package:flutter/material.dart';

/// Quest's terminal look: near-black ground, monospace type,
/// amber accent, GitHub-green contribution heatmap. Dark-only by design.
class AppTheme {
  const AppTheme._();

  // Amber accent family (primary actions, progress, streak flame).
  static const Color amber = Color(0xFFE3A64F);
  static const Color amberBright = Color(0xFFF5C77E);
  static const Color amberDim = Color(0xFF8A6A3A);

  // Backwards-compatible aliases used across the app.
  static const Color gold = amber;
  static const Color goldBright = amberBright;
  static const Color goldDim = amberDim;
  static const Color xpAccent = amber;
  static const Color streakAccent = Color(0xFFE07850);
  static const Color successAccent = Color(0xFF3FB973);

  // GitHub-style contribution heatmap levels (0..4).
  static const List<Color> heatLevels = [
    Color(0xFF16202E),
    Color(0xFF0E4429),
    Color(0xFF186B3B),
    Color(0xFF26A641),
    Color(0xFF39D353),
  ];

  // Surfaces.
  static const Color bg = Color(0xFF0A0E17);
  static const Color bgRaised = Color(0xFF0D1320);
  static const Color card = Color(0xFF0F1622);
  static const Color cardInset = Color(0xFF0B111C);
  static const Color border = Color(0xFF232F42);
  static const Color hairline = Color(0xFF19212F);

  static const Color textHigh = Color(0xFFE7ECF5);
  static const Color textMid = Color(0xFF8B96AA);
  static const Color textLow = Color(0xFF5C6577);

  /// Monospace stack — every mainstream OS ships at least one of these.
  static const List<String> mono = [
    'JetBrains Mono',
    'Fira Code',
    'Cascadia Code',
    'SF Mono',
    'Consolas',
    'Menlo',
    'monospace',
  ];

  static const LinearGradient goldGradient = LinearGradient(
    colors: [amberDim, amber, amberBright],
  );

  /// Italic-free, comment-style caption used for `//` subtitles and quotes.
  static const TextStyle comment = TextStyle(
    fontFamilyFallback: mono,
    color: textMid,
    height: 1.5,
  );

  static ThemeData dark() {
    final base = ColorScheme.fromSeed(
      seedColor: amber,
      brightness: Brightness.dark,
    );
    final colorScheme = base.copyWith(
      primary: amber,
      onPrimary: const Color(0xFF1C1305),
      secondary: amberBright,
      surface: card,
      onSurface: textHigh,
      surfaceContainerHighest: const Color(0xFF19212F),
      outline: border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      fontFamily: 'monospace',
      textTheme: _textTheme(),
      cardTheme: CardThemeData(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
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
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgRaised,
        elevation: 0,
        indicatorColor: amber.withValues(alpha: 0.16),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
      dividerTheme: const DividerThemeData(color: hairline, thickness: 1),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: amber,
          foregroundColor: const Color(0xFF1C1305),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontFamilyFallback: mono,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: amberBright,
          textStyle: const TextStyle(fontFamilyFallback: mono),
          side: const BorderSide(color: border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: amberBright,
          textStyle: const TextStyle(fontFamilyFallback: mono),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: const WidgetStatePropertyAll(
            TextStyle(fontFamilyFallback: mono, fontSize: 12.5),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: border)),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? amber.withValues(alpha: 0.16)
                : Colors.transparent,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? amberBright : textMid,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: cardInset,
        side: const BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        labelStyle: const TextStyle(color: textHigh, fontFamilyFallback: mono),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardInset,
        hintStyle: const TextStyle(color: textLow, fontFamilyFallback: mono),
        labelStyle: const TextStyle(color: textMid, fontFamilyFallback: mono),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: amber, width: 1.4),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
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
        textStyle: const TextStyle(color: textHigh, fontFamilyFallback: mono, fontSize: 13),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: border),
        ),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: amber,
        inactiveTrackColor: Color(0xFF19212F),
        thumbColor: amberBright,
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: card,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: amber,
        linearTrackColor: Color(0xFF19212F),
        circularTrackColor: Color(0xFF19212F),
      ),
    );
  }

  static TextTheme _textTheme() {
    const base = TextStyle(fontFamilyFallback: mono, color: textHigh);
    return const TextTheme(
      displaySmall: base,
      headlineLarge: TextStyle(
        fontFamilyFallback: mono,
        color: textHigh,
        fontWeight: FontWeight.w700,
      ),
      headlineMedium: TextStyle(
        fontFamilyFallback: mono,
        color: textHigh,
        fontWeight: FontWeight.w700,
      ),
      headlineSmall: TextStyle(
        fontFamilyFallback: mono,
        color: textHigh,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: TextStyle(
          color: textHigh, fontWeight: FontWeight.w700, fontFamilyFallback: mono),
      titleMedium: TextStyle(
          color: textHigh, fontWeight: FontWeight.w600, fontFamilyFallback: mono),
      titleSmall: TextStyle(
          color: textHigh, fontWeight: FontWeight.w600, fontFamilyFallback: mono),
      bodyLarge: TextStyle(color: textHigh, fontFamilyFallback: mono),
      bodyMedium: TextStyle(color: textMid, fontFamilyFallback: mono),
      bodySmall: TextStyle(color: textLow, fontFamilyFallback: mono),
      labelLarge: TextStyle(
          color: textHigh, fontWeight: FontWeight.w600, fontFamilyFallback: mono),
      labelMedium: TextStyle(color: textMid, fontFamilyFallback: mono),
      labelSmall: TextStyle(color: textLow, fontFamilyFallback: mono),
    );
  }

  /// The `//` comment style used for subtitles and quotes.
  static const TextStyle quote = comment;
}
