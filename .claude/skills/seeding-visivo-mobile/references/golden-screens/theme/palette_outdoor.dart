// =============================================================================
// PALETTE OUTDOOR ("Alpine Clarity") — skill seeding-visivo-mobile
// -----------------------------------------------------------------------------
// Preset di ESEMPIO: mostra "come si compila uno skin" partendo da una palette
// reale (la "Alpine Clarity" outdoor di un'app modello: verde foresta + terra +
// arancione). Distillato, NON copiato: ricostruito sullo stesso set di token del
// preset default e CORRETTO dove serviva.
//
// CORREZIONI rispetto alla fonte (vedi 18-design-mobile.md, correzioni dal vivo):
//   - UN solo accento: l'arancione NON e' un secondo colore d'azione (il FAB usa
//     il verde `primary`); l'arancione vive in `tertiary` come supporto/decoro.
//   - Severita' rese LEGGIBILI: i verdi/ambra/rossi originali erano troppo chiari
//     per fare da testo/icona su sfondo chiaro (sotto WCAG AA) -> scuriti.
//   - Nota: con un primary verde, `success` (verde) resta distinto perche' il
//     verde foresta e' scuro/desaturo e il verde "ok" e' piu' vivo; comunque
//     l'accento e' per le AZIONI, il verde di stato per l'OK (mai mischiarli).
//
// E' un'istanza di AppPalette: STESSO SET DI TOKEN del default, valori diversi.
// =============================================================================

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Preset outdoor di esempio. Verde foresta come accento, superfici off-white.
const AppPalette kOutdoorPalette = AppPalette(
  name: 'outdoor',

  // Accento unico: verde foresta (azioni, FAB, voce attiva).
  primaryLight: Color(0xFF2D5A27),
  primaryDark: Color(0xFF4A8B42),
  onPrimaryLight: Color(0xFFFFFFFF),
  onPrimaryDark: Color(0xFFFFFFFF),

  // Colore di supporto: arancione Alpine (decoro/evidenza, MAI azione primaria).
  tertiaryLight: Color(0xFFFF6B35),
  tertiaryDark: Color(0xFFFF8C5A),

  // Superfici: off-white caldo + scuro non assoluto.
  backgroundLight: Color(0xFFFAFAFA),
  backgroundDark: Color(0xFF1A1A1A),
  surfaceLight: Color(0xFFFFFFFF),
  surfaceDark: Color(0xFF2D2D2D),

  // Testo: alto + medio (medio scurito per leggibilita' AA all'aperto).
  onSurfaceLight: Color(0xFF212121),
  onSurfaceDark: Color(0xFFFFFFFF),
  onSurfaceVariantLight: Color(0xFF5A5A5A),
  onSurfaceVariantDark: Color(0xFFB0B0B0),

  // Severita' — toni Alpine corretti a WCAG AA (gli originali erano troppo chiari).
  errorLight: Color(0xFFD32F2F),
  errorDark: Color(0xFFEF5350),
  successLight: Color(0xFF2E7D32),
  successDark: Color(0xFF66BB6A),
  warningLight: Color(0xFFB45309),
  warningDark: Color(0xFFFFC107),
  infoLight: Color(0xFF0277BD),
  infoDark: Color(0xFF4FC3F7),

  // Bordi/divisori.
  outlineLight: Color(0xFFE0E0E0),
  outlineDark: Color(0xFF424242),
);
