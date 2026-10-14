// Fixture CONFORME — mini-app di prova per guardrail-flutter.sh (deve dare 6/6).
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'ui/home_screen.dart';

void main() => runApp(const DemoApp());

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Demo conforme',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const HomeScreen(),
    );
  }
}
