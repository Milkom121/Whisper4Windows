// Fixture CONFORME — tema minimo. Essendo in /theme/, qui i Color() sono leciti
// (il guardrail esclude i file del tema dai check anti-valore-grezzo).
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  AppTheme._();

  static final ThemeData lightTheme = _build(Brightness.light);
  static final ThemeData darkTheme = _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF2563EB),
      brightness: b,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: GoogleFonts.interTextTheme(),
    );
  }
}
