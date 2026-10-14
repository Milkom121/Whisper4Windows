// Golden screen LOGIN — Metodo Villa mobile · Flutter 3.6+ / Material 3
// Porta d'ingresso: BrandMark prominente, campi con icona, azione a piena
// larghezza, link secondario. Tutto dal tema (conforme al guardrail).
import 'package:flutter/material.dart';

import '../theme/tokens.dart';
import '../widgets/villa_widgets.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: BrandMark(name: 'Prodotto', large: true)),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Accedi',
                  style: theme.textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.lg),
                const TextField(
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.mail_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                const TextField(
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                ActionGroup(
                  primaryLabel: 'Accedi',
                  onPrimary: () {},
                  secondaryLabel: 'Password dimenticata?',
                  onSecondary: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
