import 'package:flutter/material.dart';

import '../models/flood_level.dart';

/// Colours and icons for each level.
///
/// Every level is shown with colour AND an icon AND a word, so the app still
/// works for colour-blind users. Text colours were chosen for at least
/// 4.5:1 contrast on their backgrounds (WCAG AA).
class LevelStyle {
  const LevelStyle(this.background, this.foreground, this.icon);
  final Color background;
  final Color foreground;
  final IconData icon;

  static LevelStyle of(FloodLevel l) => switch (l) {
        FloodLevel.normal => const LevelStyle(
            Color(0xFF1565C0), Colors.white, Icons.check_circle_rounded),
        FloodLevel.alert => const LevelStyle(
            Color(0xFFFDD835), Color(0xFF1A1A1A), Icons.notifications_active_rounded),
        FloodLevel.warning => const LevelStyle(
            Color(0xFFF57C00), Color(0xFF1A1A1A), Icons.warning_rounded),
        FloodLevel.danger => const LevelStyle(
            Color(0xFFC62828), Colors.white, Icons.dangerous_rounded),
      };
}

class AppTheme {
  static const ink = Color(0xFF14202B);
  static const inkSoft = Color(0xFF46576A);
  static const surface = Color(0xFFF4F7FA);
  static const primary = Color(0xFF0D47A1);

  static ThemeData build() {
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      primary: primary,
      surface: Colors.white,
    );
    const minTap = Size(64, 56); // larger than the 48dp minimum
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: surface,
      // Bigger base sizes than Material defaults, for older users.
      textTheme: const TextTheme(
        displaySmall: TextStyle(fontSize: 40, fontWeight: FontWeight.w800, color: ink),
        headlineMedium: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: ink),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: ink),
        titleLarge: TextStyle(fontSize: 21, fontWeight: FontWeight.w700, color: ink),
        titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: ink),
        bodyLarge: TextStyle(fontSize: 18, height: 1.4, color: ink),
        bodyMedium: TextStyle(fontSize: 16, height: 1.4, color: ink),
        bodySmall: TextStyle(fontSize: 15, height: 1.35, color: inkSoft),
        labelLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: ink),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFFDCE3EA)),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minTap,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minTap,
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          side: const BorderSide(color: primary, width: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 76,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFD6E4F7),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
              fontSize: 15,
              fontWeight: states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
              color: ink,
            )),
        iconTheme: WidgetStateProperty.all(const IconThemeData(size: 30, color: ink)),
      ),
      switchTheme: SwitchThemeData(
        materialTapTargetSize: MaterialTapTargetSize.padded,
      ),
    );
  }
}
