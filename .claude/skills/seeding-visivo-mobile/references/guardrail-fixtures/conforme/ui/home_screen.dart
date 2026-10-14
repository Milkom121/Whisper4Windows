// Fixture CONFORME — widget che legge TUTTO dal tema e dai token.
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Titolo della sezione', style: theme.textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text('Testo di corpo neutro.', style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
      // FAB senza backgroundColor: eredita il primary dal tema (un solo accento).
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
    );
  }
}
