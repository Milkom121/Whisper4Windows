#!/usr/bin/env bash
# =============================================================================
# Guardrail web — Metodo Villa · skill seeding-visivo-web
# -----------------------------------------------------------------------------
# Esegue i 9 guardrail deterministici (bloccanti) + 3 warning anti-piattezza
# definiti in references/system-prompt-anti-piattezza.md (sez. 7).
#
# USO:
#   ./guardrail-web.sh                 # controlla le golden-pages della skill
#   ./guardrail-web.sh /path/to/src    # controlla il src/ di un progetto reale
#
# ESITO: stampa [PASS]/[FAIL] per ognuno dei 9 e il punteggio N/9.
#        Exit 0 se 9/9 (blocco chiudibile), 1 altrimenti.
#        I check 7.9/7.10/7.12 sono [WARN] e NON entrano nel punteggio /9.
#
# Note sui check d'ambiente (7.6 Inter, 7.7 shadcn, 7.8 dark): sulle golden-pages
# isolate Inter e il blocco .dark vivono negli skin (references/skin-*.css) e
# shadcn si riconosce dagli import "@/components/ui/"; in un progetto reale si
# trovano in index.css / tailwind.config e nella cartella src/components/ui/.
# =============================================================================

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="${1:-$SCRIPT_DIR/golden-pages}"   # cosa controllare
SKIN_DIR="$SCRIPT_DIR"                     # dove vivono gli skin di riferimento
PROJ_ROOT="$(dirname "$TARGET")"          # root presunta del progetto

if [ ! -d "$TARGET" ]; then
  echo "Errore: cartella target non trovata: $TARGET" >&2
  exit 2
fi

pass=0
echo "== Guardrail web — target: $TARGET =="
echo ""

ok()  { echo "[PASS] $1"; pass=$((pass + 1)); }
ko()  { echo "[FAIL] $1 — $2"; }

# Conta le righe che violano un pattern (con esclusione opzionale).
violations() {
  local pattern="$1" exclude="$2"
  local out
  out="$(grep -rnE "$pattern" "$TARGET" --include="*.tsx" --include="*.ts" 2>/dev/null)"
  if [ -n "$exclude" ]; then out="$(printf '%s\n' "$out" | grep -vE "$exclude")"; fi
  printf '%s' "$out" | grep -cE '.'
}

# --- 7.1 Anti-hex hardcoded ---
v=$(violations 'bg-\[#|text-\[#|border-\[#|fill-\[#|stroke-\[#' '')
[ "$v" -eq 0 ] && ok "7.1 Anti-hex hardcoded" || ko "7.1 Anti-hex hardcoded" "$v occorrenze (usa token semantici)"

# --- 7.2 Anti-table HTML grezza ---
v=$(violations '<table[ >]' '/ui/table\.tsx')
[ "$v" -eq 0 ] && ok "7.2 Anti-table HTML" || ko "7.2 Anti-table HTML" "$v <table> (usa DataTable/Table shadcn)"

# --- 7.3 Anti-button nativo ---
v=$(violations '<button[ >]' '/ui/button\.tsx')
[ "$v" -eq 0 ] && ok "7.3 Anti-button nativo" || ko "7.3 Anti-button nativo" "$v <button> (usa Button shadcn)"

# --- 7.4 Anti-svg inline non-lucide ---
v=$(violations '<svg[ >]' 'lucide|/assets/')
[ "$v" -eq 0 ] && ok "7.4 Anti-svg inline" || ko "7.4 Anti-svg inline" "$v <svg> (usa icone Lucide)"

# --- 7.5 Anti-alert/confirm/prompt ---
v=$(violations '(window\.)?(alert|confirm|prompt)\(' '')
[ "$v" -eq 0 ] && ok "7.5 Anti-alert/confirm/prompt" || ko "7.5 Anti-alert/confirm/prompt" "$v occorrenze (usa Dialog/AlertDialog/toast)"

# --- 7.6 Font Inter caricato ---
if grep -rqE 'Inter' "$TARGET" "$SKIN_DIR" 2>/dev/null \
   || grep -qE 'Inter' "$PROJ_ROOT"/tailwind.config.* "$PROJ_ROOT"/index.css "$PROJ_ROOT"/index.html "$PROJ_ROOT"/src/index.css 2>/dev/null; then
  ok "7.6 Font Inter caricato"
else
  ko "7.6 Font Inter caricato" "Inter non trovato (caricalo in index.css/tailwind.config)"
fi

# --- 7.7 shadcn/ui presente ---
if [ -d "$PROJ_ROOT/components/ui" ] || [ -d "$PROJ_ROOT/src/components/ui" ] || [ -d "$TARGET/components/ui" ] \
   || grep -rqE '@/components/ui/' "$TARGET" --include="*.tsx" 2>/dev/null; then
  ok "7.7 shadcn/ui presente"
else
  ko "7.7 shadcn/ui presente" "ne' cartella components/ui ne' import @/components/ui/"
fi

# --- 7.8 Dark mode definita (blocco .dark nei CSS) ---
# La dark mode e' OBBLIGATORIA su ogni prodotto Villa (regola permanente): ogni
# prodotto deve avere SEMPRE anche il tema scuro, non solo il chiaro. Cerca un
# blocco `.dark { ... }` (token del tema scuro) nei CSS del progetto (PROJ_ROOT)
# o del target. NB: si guarda il progetto, NON gli skin di riferimento della
# skill (che hanno sempre .dark) — altrimenti il check sarebbe finto sui progetti
# reali. node_modules escluso per evitare falsi positivi da librerie terze.
# Sulle golden-pages PROJ_ROOT coincide con references/, dove vivono gli skin.
if [ -n "$(grep -rlE '\.dark[[:space:]{]' "$PROJ_ROOT" "$TARGET" --include='*.css' --exclude-dir=node_modules 2>/dev/null | head -1)" ]; then
  ok "7.8 Dark mode definita (blocco .dark)"
else
  ko "7.8 Dark mode definita (blocco .dark)" "manca il blocco .dark nei CSS del progetto — la dark mode e' obbligatoria"
fi

# --- 7.11 Responsivita': niente larghezze fisse sui contenitori ---
# Una larghezza fissa in pixel su un contenitore di pagina rende la pagina piu' larga
# dello schermo del telefono: il contenuto esce e l'utente scorre in orizzontale.
# E' un difetto OGGETTIVO, per questo e' bloccante (il segnale indiziario "poche classi
# responsive" e' invece un semplice avviso, sotto). Esclusi i casi legittimi: le misure
# piccole (max 3 cifre sotto 640, tipiche di icone/avatar) NON sono contenitori di pagina,
# e max-w-* e' un limite superiore, non una larghezza imposta.
v=$(violations 'className="[^"]*\b(w|min-w)-\[[0-9]{3,}px\]|style=\{\{[^}]*\b(width|minWidth):[^}]*[0-9]{3,}px' '')
[ "$v" -eq 0 ] && ok "7.11 Responsivita' (niente larghezze fisse)" || ko "7.11 Responsivita' (niente larghezze fisse)" "$v contenitori a larghezza fissa (usa w-full/max-w-* e i prefissi sm:/md:/lg:)"

echo ""
echo "Punteggio guardrail: $pass/9"

# --- Warning anti-piattezza (non bloccanti) ---
echo ""
echo "-- Avvisi anti-piattezza (non contano nel punteggio) --"
# 7.9 Card con ombre
CARD="$PROJ_ROOT/src/components/ui/card.tsx"
if [ -f "$CARD" ]; then
  grep -q 'shadow' "$CARD" || echo "[WARN] 7.9 card.tsx senza shadow: le Card risultano piatte"
fi
# 7.10 KPI grandi senza IconBox
while IFS= read -r f; do
  [ -z "$f" ] && continue
  grep -qE 'IconBox|rounded-lg bg-(primary|success|warning|info|destructive)/' "$f" \
    || echo "[WARN] 7.10 $(basename "$f"): KPI grande senza IconBox (icona in evidenza)"
done < <(grep -rlE 'text-3xl[^"]*font-bold|font-bold[^"]*text-3xl' "$TARGET" --include="*.tsx" 2>/dev/null)

# 7.12 Frontend pensato solo per il monitor (segnale indiziario, non certezza)
# Se quasi nessun file usa i prefissi per schermo, il layout non e' mai stato adattato
# agli schermi piccoli. E' un indizio, non una prova (una pagina puo' essere fluida
# senza prefissi), per questo e' un avviso e non blocca.
tot_tsx=$(find "$TARGET" -name '*.tsx' -not -path '*/node_modules/*' 2>/dev/null | grep -cE '.')
resp_tsx=$(grep -rlE '\b(sm|md|lg|xl):' "$TARGET" --include='*.tsx' 2>/dev/null | grep -cE '.')
if [ "$tot_tsx" -gt 0 ] && [ "$((resp_tsx * 3))" -lt "$tot_tsx" ]; then
  echo "[WARN] 7.12 solo $resp_tsx file su $tot_tsx usano i prefissi per schermo (sm:/md:/lg:): il layout sembra pensato solo per il monitor — verifica le schermate a larghezza telefono"
fi

[ "$pass" -eq 9 ] && echo "" && echo "OK: 9/9, blocco frontend chiudibile."

[ "$pass" -eq 9 ] && exit 0 || exit 1
