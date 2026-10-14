// Golden screen GALLERY (showcase) — Metodo Villa mobile · Flutter 3.6+ / Material 3
// Mostra tutti i componenti compositi della libreria "Villa mobile" con dati
// neutri: e' la fonte vivente di riferimento per i blocchi successivi.
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/villa_widgets.dart';

class ComponentsGallery extends StatelessWidget {
  const ComponentsGallery({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    Widget section(String title, Widget child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.lg),
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            child,
          ],
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Componenti')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          section(
            'StatTile',
            Row(
              children: const [
                Expanded(
                  child: StatTile(
                    label: 'OK',
                    value: '128',
                    icon: Icons.check_circle_outline,
                    severity: Severity.success,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: StatTile(
                    label: 'Critici',
                    value: '3',
                    icon: Icons.error_outline,
                    severity: Severity.error,
                  ),
                ),
              ],
            ),
          ),
          section(
            'StatusBanner (3 severita)',
            Column(
              children: const [
                StatusBanner(
                  severity: Severity.error,
                  message: 'Errore: azione richiesta subito.',
                  icon: Icons.error_outline,
                ),
                SizedBox(height: AppSpacing.sm),
                StatusBanner(
                  severity: Severity.warning,
                  message: 'Attenzione: da verificare.',
                  icon: Icons.warning_amber_outlined,
                ),
                SizedBox(height: AppSpacing.sm),
                StatusBanner(
                  severity: Severity.info,
                  message: 'Informazione neutra.',
                ),
              ],
            ),
          ),
          section(
            'StatusChip',
            Wrap(
              spacing: AppSpacing.sm,
              children: const [
                StatusChip(label: 'In regola', severity: Severity.success),
                StatusChip(label: 'In attesa', severity: Severity.warning),
                StatusChip(label: 'Critico', severity: Severity.error),
                StatusChip(label: 'Neutro'),
              ],
            ),
          ),
          section(
            'EntityCard',
            const EntityCard(
              title: 'Elemento di esempio',
              subtitle: 'Sotto-info neutra',
              statusLabel: 'In regola',
              severity: Severity.success,
            ),
          ),
          section(
            'EmptyStateView',
            EmptyStateView(
              title: 'Niente da mostrare',
              description: 'Quando ci saranno elementi, appariranno qui.',
              actionLabel: 'Aggiungi il primo',
              onAction: () {},
            ),
          ),
          section(
            'ActionGroup',
            ActionGroup(
              primaryLabel: 'Azione primaria',
              onPrimary: () {},
              secondaryLabel: 'Azione secondaria',
              onSecondary: () {},
            ),
          ),
        ],
      ),
    );
  }
}
