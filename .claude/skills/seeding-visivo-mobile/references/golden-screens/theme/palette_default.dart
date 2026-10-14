// =============================================================================
// PALETTE DEFAULT (neutra "slate/blu") — skill seeding-visivo-mobile
// -----------------------------------------------------------------------------
// Preset di partenza, NEUTRO, per qualsiasi app mobile del Metodo Villa. E' il
// punto zero: superfici slate sobrie + accento blu standard. Pensato per essere
// PERSONALIZZATO nella fase di styling co-progettata (vedi SKILL.md).
//
// Allineato cromaticamente allo skin-default WEB (skin-default.css), cosi' un
// prodotto con app web + mobile parte coerente su entrambe le piattaforme.
//
// E' un'istanza di AppPalette: ha lo STESSO SET DI TOKEN del preset outdoor,
// cambiano solo i valori. Uso:
//   MaterialApp(theme: AppTheme.light(kDefaultPalette),
//               darkTheme: AppTheme.dark(kDefaultPalette));
// =============================================================================

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Preset neutro. PERSONALIZZARE `primary` col colore del brand nella fase di
/// styling; gli altri token restano salvo richiesta esplicita.
const AppPalette kDefaultPalette = AppPalette(
  name: 'default',

  // Accento unico: blu standard (azioni, FAB, voce attiva).
  primaryLight: Color(0xFF2563EB),
  primaryDark: Color(0xFF3B82F6),
  onPrimaryLight: Color(0xFFFFFFFF),
  onPrimaryDark: Color(0xFF0B1220),

  // Colore di supporto neutro (parsimonia; mai secondo bottone d'azione).
  tertiaryLight: Color(0xFF64748B),
  tertiaryDark: Color(0xFF94A3B8),

  // Superfici: sfondo + card.
  backgroundLight: Color(0xFFFFFFFF),
  backgroundDark: Color(0xFF0F172A),
  surfaceLight: Color(0xFFF8FAFC),
  surfaceDark: Color(0xFF1E293B),

  // Testo: alto + medio (leggibile, non sbiadito, WCAG AA).
  onSurfaceLight: Color(0xFF0F172A),
  onSurfaceDark: Color(0xFFF1F5F9),
  onSurfaceVariantLight: Color(0xFF475569),
  onSurfaceVariantDark: Color(0xFF94A3B8),

  // Severita' (severity coding) — toni calibrati e leggibili.
  errorLight: Color(0xFFDC2626),
  errorDark: Color(0xFFEF4444),
  successLight: Color(0xFF16A34A),
  successDark: Color(0xFF22C55E),
  warningLight: Color(0xFFD97706),
  warningDark: Color(0xFFF59E0B),
  infoLight: Color(0xFF0891B2),
  infoDark: Color(0xFF06B6D4),

  // Bordi/divisori (hairline).
  outlineLight: Color(0xFFE2E8F0),
  outlineDark: Color(0xFF334155),
);
