// Golden screen HOME/DASHBOARD — Metodo Villa mobile · Flutter 3.6+ / Material 3
// "Stato del mondo" a colpo d'occhio: banner condizionale, riga di StatTile,
// elementi recenti, FAB sul primary, bottom navigation. Tutto dal tema.
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.dart';
import '../widgets/villa_widgets.dart';
import 'list_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Panoramica')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Banner di stato: appare solo se c'e' qualcosa da segnalare.
          const StatusBanner(
            severity: Severity.warning,
            message: '2 elementi richiedono attenzione.',
            icon: Icons.warning_amber_outlined,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: const [
              Expanded(
                child: StatTile(
                  label: 'Attivi',
                  value: '128',
                  icon: Icons.check_circle_outline,
                  severity: Severity.success,
                ),
              ),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: 'In attesa',
                  value: '12',
                  icon: Icons.schedule,
                  severity: Severity.warning,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Recenti', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          EntityCard(
            title: 'Elemento A',
            subtitle: 'Aggiornato 3 minuti fa',
            statusLabel: 'In regola',
            severity: Severity.success,
            onTap: () => _openList(context),
          ),
          EntityCard(
            title: 'Elemento B',
            subtitle: 'Scadenza superata',
            statusLabel: 'Critico',
            severity: Severity.error,
            onTap: () => _openList(context),
          ),
        ],
      ),
      // FAB senza colore esplicito: eredita il primary (un solo accento).
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        onTap: (_) {},
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Elementi'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profilo'),
        ],
      ),
    );
  }

  void _openList(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ListScreen()),
    );
  }
}
