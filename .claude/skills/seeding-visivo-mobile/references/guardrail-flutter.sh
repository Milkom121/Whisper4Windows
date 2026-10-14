#!/usr/bin/env bash
# =============================================================================
# Guardrail Flutter — Metodo Villa · skill seeding-visivo-mobile
# -----------------------------------------------------------------------------
# Esegue 8 check deterministici sullo stile mobile (vedi 18-design-mobile.md):
# 6 bloccanti [FAIL] + 2 avvisi [WARN]. E' il gemello mobile di guardrail-web.sh.
#
# SCOPE (importante): i check anti-valore-grezzo (colore, TextStyle) valgono nei
# WIDGET, NON nel file del tema. Il file del tema (path con /theme/ o nome
# *theme*.dart / palette*.dart / tokens.dart) e' dove i Color(0x..) e gli stili
# sono LEGITTIMI: viene quindi ESCLUSO da quei check (come il web esclude
# ui/*.tsx dei componenti base).
#
# USO:
#   ./guardrail-flutter.sh                  # controlla ./golden-screens
#   ./guardrail-flutter.sh /path/to/proj    # controlla un progetto Flutter (lib/)
#
# ESITO: [PASS]/[FAIL] per i 6 bloccanti + punteggio N/6; [WARN] per i 2 avvisi.
#        Exit 0 se 6/6, 1 altrimenti.
# =============================================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$SCRIPT_DIR/golden-screens}"

if [ ! -d "$TARGET" ]; then
  echo "Errore: cartella target non trovata: $TARGET" >&2
  exit 2
fi

# File del TEMA: esclusi dai check anti-valore-grezzo (li' i Color/stili sono ok).
THEME_RX='/theme/|app_theme\.dart|palette[-_].*\.dart|tokens\.dart'

pass=0
echo "== Guardrail Flutter — target: $TARGET =="
echo ""

ok() { echo "[PASS] $1"; pass=$((pass + 1)); }
ko() { echo "[FAIL] $1 — $2"; }

# Conta righe che violano un pattern nei file WIDGET (esclusi i file del tema).
violations_ui() {
  local pattern="$1" exclude="$2"
  local out
  out="$(grep -rnE "$pattern" "$TARGET" --include='*.dart' 2>/dev/null | grep -vE "$THEME_RX")"
  if [ -n "$exclude" ]; then out="$(printf '%s\n' "$out" | grep -vE "$exclude")"; fi
  printf '%s' "$out" | grep -cE '.'
}

# --- 1. [FAIL] Anti-colore hardcoded nei widget ---
# Color(0x..) o Colors.<nome> nei widget. Ammesso Colors.transparent (semantico).
v=$(violations_ui 'Color\(0x|Colors\.[a-zA-Z]' 'Colors\.transparent')
[ "$v" -eq 0 ] && ok "1. Anti-colore hardcoded (widget)" \
  || ko "1. Anti-colore hardcoded (widget)" "$v occorrenze (usa Theme.of(context).colorScheme)"

# --- 2. [FAIL] Anti-TextStyle inline nei widget ---
# TextStyle(...) costruito a mano. Il \b evita falsi positivi su metodi che
# finiscono in ...TextStyle( (es. l'helper dataTextStyle del tema).
v=$(violations_ui '\bTextStyle\(' 'copyWith')
[ "$v" -eq 0 ] && ok "2. Anti-TextStyle inline (widget)" \
  || ko "2. Anti-TextStyle inline (widget)" "$v occorrenze (usa Theme.of(context).textTheme)"

# --- 3. [FAIL] Tema centralizzato presente (lightTheme + darkTheme) ---
hl=$(grep -rcE 'ThemeData light\(|lightTheme' "$TARGET" --include='*.dart' 2>/dev/null | grep -vE ':0$' | grep -cE '.')
hd=$(grep -rcE 'ThemeData dark\(|darkTheme' "$TARGET" --include='*.dart' 2>/dev/null | grep -vE ':0$' | grep -cE '.')
if [ "$hl" -ge 1 ] && [ "$hd" -ge 1 ]; then
  ok "3. Tema centralizzato (light + dark)"
else
  ko "3. Tema centralizzato (light + dark)" "manca lightTheme e/o darkTheme in un file di tema"
fi

# --- 4. [FAIL] MaterialApp aggancia theme + darkTheme ---
has_ma=$(grep -rlE 'MaterialApp\(' "$TARGET" --include='*.dart' 2>/dev/null | grep -cE '.')
has_theme=$(grep -rcE '[^k]theme:' "$TARGET" --include='*.dart' 2>/dev/null | grep -vE ':0$' | grep -cE '.')
has_dark=$(grep -rcE 'darkTheme:' "$TARGET" --include='*.dart' 2>/dev/null | grep -vE ':0$' | grep -cE '.')
if [ "$has_ma" -ge 1 ] && [ "$has_theme" -ge 1 ] && [ "$has_dark" -ge 1 ]; then
  ok "4. MaterialApp aggancia theme + darkTheme"
else
  ko "4. MaterialApp aggancia theme + darkTheme" "MaterialApp senza theme:/darkTheme:"
fi

# --- 5. [FAIL] google_fonts presente (import/uso reale, non una menzione) ---
if grep -rqE "GoogleFonts\.|import ['\"]package:google_fonts" "$TARGET" --include='*.dart' 2>/dev/null \
   || grep -qE '^[[:space:]]*google_fonts:' "$TARGET"/pubspec.yaml 2>/dev/null; then
  ok "5. google_fonts presente"
else
  ko "5. google_fonts presente" "Inter non caricato via google_fonts (font di sistema vietato)"
fi

# --- 6. [FAIL] Un solo accento: il FAB non e' ricolorato a mano ---
# Cerca un backgroundColor/Colors entro 3 righe da FloatingActionButton nei widget.
fab=$(grep -rA3 'FloatingActionButton' "$TARGET" --include='*.dart' 2>/dev/null \
      | grep -vE "$THEME_RX" | grep -cE 'backgroundColor:|Colors\.')
if [ "$fab" -eq 0 ]; then
  ok "6. Un accento coerente (FAB eredita il primary)"
else
  ko "6. Un accento coerente (FAB eredita il primary)" "$fab FAB ricolorati (il FAB usi il primary del tema)"
fi

echo ""
echo "Punteggio guardrail bloccanti: $pass/6"

# --- Avvisi non bloccanti ---
echo ""
echo "-- Avvisi anti-piattezza (non contano nel punteggio) --"

# 7. [WARN] Spaziatura magica: numero letterale come argomento di EdgeInsets/
# SizedBox sulla stessa riga (es. EdgeInsets.all(17)), escluso chi usa AppSpacing.
# Il numero deve essere adiacente al costrutto: cosi' non si conta il line number
# ne' le righe di apertura multilinea (i cui valori sono token sulle righe interne).
w=$(grep -rnoE 'EdgeInsets\.(all|symmetric|only)\([^)]*[0-9][^)]*\)|SizedBox\([^)]*[0-9][^)]*\)' "$TARGET" --include='*.dart' 2>/dev/null \
    | grep -vE "$THEME_RX" | grep -v 'AppSpacing' | grep -cE '.')
[ "$w" -eq 0 ] && echo "[ok]   7. Nessuna spaziatura magica evidente" \
  || echo "[WARN] 7. $w spaziature con numeri magici (preferisci AppSpacing.*)"

# 8. [WARN] Material 3 attivo.
if grep -rqE 'useMaterial3:\s*true' "$TARGET" --include='*.dart' 2>/dev/null; then
  echo "[ok]   8. useMaterial3: true"
else
  echo "[WARN] 8. useMaterial3 non trovato (atteso true nel tema)"
fi

echo ""
[ "$pass" -eq 6 ] && echo "OK: 6/6, blocco frontend mobile chiudibile." && exit 0
echo "INCOMPLETO: $pass/6 bloccanti." && exit 1
