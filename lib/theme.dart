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
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
