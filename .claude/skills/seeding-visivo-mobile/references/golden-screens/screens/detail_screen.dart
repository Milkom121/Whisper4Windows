// Golden screen DETTAGLIO — Metodo Villa mobile · Flutter 3.6+ / Material 3
// Singola entita': intestazione ricca (icona grande + titolo + chip stato),
// metriche, una sezione, azione primaria. Tutto dal tema.
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/villa_widgets.dart';

class DetailScreen extends StatelessWidget {
  const DetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Elemento A')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Intestazione ricca.
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(Icons.inventory_2_outlined,
                    color: theme.colorScheme.primary, size: 32),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Elemento A', style: theme.textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    const StatusChip(label: 'In regola', severity: Severity.success),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: const [
              Expanded(
                child: StatTile(
                  label: 'Quantita',
                  value: '342',
                  icon: Icons.numbers,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: 'Giacenza',
                  value: '87%',
                  icon: Icons.trending_up,
                  severity: Severity.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Informazioni', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          const Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.category_outlined),
                  title: Text('Categoria'),
                  subtitle: Text('Categoria di esempio'),
                ),
                ListTile(
                  leading: Icon(Icons.place_outlined),
                  title: Text('Posizione'),
                  subtitle: Text('Posizione di esempio'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ActionGroup(
            primaryLabel: 'Modifica',
            onPrimary: () {},
            secondaryLabel: 'Elimina',
            onSecondary: () {},
          ),
        ],
      ),
    );
  }
}
