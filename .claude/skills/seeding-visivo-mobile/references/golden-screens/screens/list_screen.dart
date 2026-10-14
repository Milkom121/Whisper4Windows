// Golden screen LISTA — Metodo Villa mobile · Flutter 3.6+ / Material 3
// "Tutti i [X]": ricerca in cima, filtri a chip, lista di EntityCard.
// Lo stato vuoto e' ricco (vedi EmptyStateView), mai un'area grigia muta.
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/villa_widgets.dart';
import 'detail_screen.dart';

class ListScreen extends StatelessWidget {
  const ListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Elementi')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                const TextField(
                  decoration: InputDecoration(
                    hintText: 'Cerca',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  children: [
                    FilterChip(label: const Text('Tutti'), selected: true, onSelected: (_) {}),
                    FilterChip(label: const Text('Critici'), selected: false, onSelected: (_) {}),
                    FilterChip(label: const Text('In attesa'), selected: false, onSelected: (_) {}),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              children: [
                EntityCard(
                  title: 'Elemento A',
                  subtitle: 'Categoria · aggiornato oggi',
                  statusLabel: 'In regola',
                  severity: Severity.success,
                  onTap: () => _openDetail(context),
                ),
                EntityCard(
                  title: 'Elemento B',
                  subtitle: 'Categoria · scadenza superata',
                  statusLabel: 'Critico',
                  severity: Severity.error,
                  onTap: () => _openDetail(context),
                ),
                EntityCard(
                  title: 'Elemento C',
                  subtitle: 'Categoria · in attesa di conferma',
                  statusLabel: 'In attesa',
                  severity: Severity.warning,
                  onTap: () => _openDetail(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const DetailScreen()),
    );
  }
}
