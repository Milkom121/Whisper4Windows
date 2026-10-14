// Golden app — Metodo Villa mobile · Flutter 3.6+ / Material 3
// Mini-progetto di riferimento: aggancia il tema centralizzato e apre la Home.
// In un progetto reale gli import diventano 'package:tua_app/...'.
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'theme/palette_default.dart';
import 'screens/home_screen.dart';

void main() => runApp(const GoldenApp());

class GoldenApp extends StatelessWidget {
  const GoldenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Metodo Villa — Golden mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(kDefaultPalette),
      darkTheme: AppTheme.dark(kDefaultPalette),
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
