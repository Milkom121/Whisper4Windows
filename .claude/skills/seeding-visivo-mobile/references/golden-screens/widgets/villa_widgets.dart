// =============================================================================
// LIBRERIA "VILLA MOBILE" (golden) — Metodo Villa · Flutter 3.6+ / Material 3
// -----------------------------------------------------------------------------
// Implementazione di riferimento dei componenti compositi (vedi 18-design-mobile
// sez. 7 e stack-e-libreria-mobile.md sez. 3). Tutti leggono SOLO dal tema e dai
// token: nessun Color()/Colors a mano, nessun TextStyle inline -> passano il
// guardrail Flutter. Da copiare in `lib/widgets/` e adattare al progetto.
// =============================================================================

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';

const double _iconBox = 40; // lato dell'icon box delle StatTile
const double _icon = 20; // dimensione icona standard nei compositi
const double _pill = 999; // raggio "pillola" per chip/badge

/// Marchio del prodotto: icon box nell'accento + nome. (`vedi BrandMark`)
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, required this.name, this.icon = Icons.layers, this.large = false});

  final String name;
  final IconData icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double box = large ? 64 : 36;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Icon(icon, color: theme.colorScheme.onPrimary, size: large ? 32 : _icon),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(name, style: large ? theme.textTheme.headlineSmall : theme.textTheme.titleMedium),
      ],
    );
  }
}

/// Tile statistico: etichetta + icon box semantico + numero in monospazio.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.severity = Severity.neutral,
  });

  final String label;
  final String value;
  final IconData icon;
  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        theme.extension<AppStatusColors>()!.resolve(severity, theme.colorScheme);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label.toUpperCase(), style: theme.textTheme.labelMedium),
                Container(
                  width: _iconBox,
                  height: _iconBox,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(icon, color: color, size: _icon),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              value,
              style: AppTheme.dataTextStyle(context)
                  .copyWith(fontSize: 28, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

/// Banner di stato: sfondo tenue + bordo + icona/testo nel colore (mai pieno).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.severity,
    required this.message,
    this.icon = Icons.info_outline,
  });

  final Severity severity;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        theme.extension<AppStatusColors>()!.resolve(severity, theme.colorScheme);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.30)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: _icon),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Etichetta di stato a colpo d'occhio (variante tenue).
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.label, this.severity = Severity.neutral});

  final String label;
  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        theme.extension<AppStatusColors>()!.resolve(severity, theme.colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(_pill),
      ),
      child: Text(label, style: theme.textTheme.labelSmall?.copyWith(color: color)),
    );
  }
}

/// Card di un'entita': titolo + sotto-info + chip di stato + bordo solo se serve.
class EntityCard extends StatelessWidget {
  const EntityCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.statusLabel,
    this.severity = Severity.neutral,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String statusLabel;
  final Severity severity;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool hasState = severity != Severity.neutral;
    final Color color =
        theme.extension<AppStatusColors>()!.resolve(severity, theme.colorScheme);
    return Card(
      // Bordo colorato SOLO se l'entita' ha davvero uno stato.
      shape: hasState
          ? RoundedRectangleBorder(
              side: BorderSide(color: color.withValues(alpha: 0.40)),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            )
          : null,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        title: Text(title, style: theme.textTheme.titleMedium),
        subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
        trailing: StatusChip(label: statusLabel, severity: severity),
        onTap: onTap,
      ),
    );
  }
}

/// Stato vuoto ricco: icon box + titolo + descrizione + azione opzionale.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
    this.severity = Severity.info,
  });

  final String title;
  final String description;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Severity severity;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color =
        theme.extension<AppStatusColors>()!.resolve(severity, theme.colorScheme);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: theme.textTheme.titleMedium, textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xs),
            Text(
              description,
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Gruppo di azioni: un solo primario (pieno) + secondario (testo). Stack mobile.
class ActionGroup extends StatelessWidget {
  const ActionGroup({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(onPressed: onPrimary, child: Text(primaryLabel)),
        if (secondaryLabel != null) ...[
          const SizedBox(height: AppSpacing.sm),
          TextButton(onPressed: onSecondary, child: Text(secondaryLabel!)),
        ],
      ],
    );
  }
}
