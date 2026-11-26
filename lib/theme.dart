import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Safety orange on dark charcoal, a nod to job-site colors.
const safetyOrange = Color(0xFFFF7A1A);
const charcoal = Color(0xFF1C1F24);

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: safetyOrange,
    brightness: Brightness.dark,
    surface: charcoal,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: charcoal,
    appBarTheme: const AppBarTheme(
      backgroundColor: charcoal,
      centerTitle: false,
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        // Start from the platform's label style so the button keeps the
        // system font (Roboto, Segoe UI, ...) and only changes size/weight.
        textStyle: Typography.material2021(platform: defaultTargetPlatform)
            .white
            .labelLarge!
            .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
