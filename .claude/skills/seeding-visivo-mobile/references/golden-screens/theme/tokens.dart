// =============================================================================
// TOKEN DI MISURA — Metodo Villa · skill seeding-visivo-mobile
// -----------------------------------------------------------------------------
// Materializzazione in Dart dei token documentati in stack-e-libreria-mobile.md
// (Blocco 2.2). Sono l'unica fonte delle misure: spaziature, raggi, elevazioni,
// durate, bersagli toccabili. MAI valori a mano nei widget — sempre questi token.
//
// COME SI USA: copiare questo file in `lib/theme/tokens.dart` del progetto e
// importarlo dove servono misure (`padding: EdgeInsets.all(AppSpacing.md)`).
// =============================================================================

import 'package:flutter/animation.dart';

/// Spaziature centralizzate. Scala a multipli di 4.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4; // micro-gap, padding interni stretti
  static const double sm = 8; // gap tra elementi vicini
  static const double md = 16; // padding standard delle card, gap di sezione
  static const double lg = 24; // separazione tra blocchi
  static const double xl = 32; // margini ampi
  static const double xxl = 48; // spazi molto ampi (raro)
}

/// Raggi di smusso centralizzati.
class AppRadius {
  AppRadius._();

  static const double sm = 4; // chip, badge, checkbox
  static const double md = 8; // bottoni, input, card piccole
  static const double lg = 12; // card standard
  static const double xl = 16; // bottom sheet, card grandi
}

/// Elevazioni centralizzate. Basse e coerenti, mai scenografiche.
class AppElevation {
  AppElevation._();

  static const double none = 0; // app bar piatta, elementi a filo
  static const double low = 2; // card
  static const double medium = 4; // FAB, elementi attivi
  static const double high = 8; // bottom sheet, dialog, bottom nav
}

/// Durate e curve centralizzate. Brevi e sobrie.
class AppMotion {
  AppMotion._();

  static const Duration short = Duration(milliseconds: 150); // micro-feedback
  static const Duration standard = Duration(milliseconds: 200); // transizioni normali
  static const Duration medium = Duration(milliseconds: 300); // transizioni grandi (raro)

  static const Curve standardCurve = Curves.easeInOut; // default
  static const Curve enterCurve = Curves.easeOut; // ingressi
}

/// Dimensioni minime dei bersagli toccabili (accessibilità: >= 48dp).
class AppTouchTarget {
  AppTouchTarget._();

  static const double minimum = 48; // minimo assoluto (WCAG/Material)
  static const double comfortable = 56; // azioni frequenti
  static const double large = 64; // azioni primarie ampie
}
