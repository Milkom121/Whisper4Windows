#!/usr/bin/env bash
# cosa-serve.sh — dice cosa serve per far partire QUESTO progetto, e cosa manca su questa
# macchina. Si lancia da dentro un progetto qualsiasi:
#
#   ./metodo/cosa-serve.sh [cartella-del-progetto]
#
# PERCHE' ESISTE (2026-08-28)
#   Villa voleva una lista delle necessita' dei suoi progetti. Scritta a mano sarebbe
#   invecchiata subito: dieci progetti su sedici dichiarano gia' stack e comandi dentro di
#   se'. Questo strumento non tiene niente scritto: guarda i file veri del progetto e i
#   programmi veri della macchina, ogni volta. Non puo' dire il falso.
#   Cio' che dai file NON si ricava (chiavi dei servizi esterni, mappa delle porte) sta in
#   un foglio a parte, scritto a mano: e' l'altra meta', e sono due cose diverse.
#
# NON installa niente e non tocca niente: legge, confronta e stampa i comandi da lanciare.
# L'installazione la lancia Villa, perche' tocca la macchina (cap. 05: mai globali di
# nascosto, mai PATH/runtime di sistema senza che lo sappia).

set -euo pipefail

PROGETTO="${1:-$(git rev-parse --show-toplevel 2>/dev/null || pwd)}"
PROGETTO="$(cd "$PROGETTO" && pwd)"
NOME="$(basename "$PROGETTO")"

MANCANTI=()   # righe "descrizione|comando per risolvere"

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

ce_la_ha()  { command -v "$1" >/dev/null 2>&1; }
versione()  { "$1" ${2:---version} 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1; }
riga_ok()   { printf "  OK   %-24s %s\n" "$1" "${2:-}"; }
riga_no()   { printf "  !!   %-24s %s\n" "$1" "${2:-}"; }
riga_info() { printf "  ..   %-24s %s\n" "$1" "${2:-}"; }
manca()     { MANCANTI+=("$1|$2"); }

# Cerca un file segnaposto nel progetto, fino a tre livelli, saltando le dipendenze.
# Quello in RADICE esce per primo: in un monorepo e' quello che comanda, e leggere la
# versione richiesta da un sotto-modulo qualsiasi darebbe una risposta sbagliata.
trova() {
  [ -f "$PROGETTO/$1" ] && printf '%s\n' "$PROGETTO/$1"
  find "$PROGETTO" -mindepth 2 -maxdepth 4 -name "$1" \
       -not -path "*/node_modules/*" -not -path "*/.git/*" \
       -not -path "*/build/*" -not -path "*/.dart_tool/*" 2>/dev/null | head -5
}

# Primo valore di una chiave in un package.json, senza dipendere da jq.
da_package() {
  python - "$1" "$2" <<'PY' 2>/dev/null || true
import json, sys
try:
    d = json.load(open(sys.argv[1], encoding="utf-8"))
except Exception:
    sys.exit()
v = d
for k in sys.argv[2].split("."):
    v = (v or {}).get(k) if isinstance(v, dict) else None
if v:
    print(v)
PY
}

# ---------------------------------------------------------------------------
# Rilievo
# ---------------------------------------------------------------------------

echo
echo "Cosa serve a $NOME per partire"
echo "  (letto adesso dai file del progetto e dai programmi installati)"
echo

trovato_qualcosa=0

# --- Node ------------------------------------------------------------------
mapfile -t PKG < <(trova "package.json")
if [ "${#PKG[@]}" -gt 0 ]; then
  trovato_qualcosa=1
  chiede_node=""; gestore=""
  for p in "${PKG[@]}"; do
    [ -z "$chiede_node" ] && chiede_node="$(da_package "$p" "engines.node")"
    [ -z "$gestore" ]     && gestore="$(da_package "$p" "packageManager")"
  done

  if ce_la_ha node; then
    riga_ok "Node $(versione node)" "${chiede_node:+chiede $chiede_node}"
  else
    riga_no "Node" "non installato"
    manca "Node" "installa Node dal sito ufficiale (serve la versione ${chiede_node:->=20})"
  fi

  # Il gestore di pacchetti: si rispetta quello DICHIARATO dal progetto, non quello a mano.
  if [ -n "$gestore" ]; then
    nome_gestore="${gestore%%@*}"
    if ce_la_ha "$nome_gestore"; then
      riga_ok "$nome_gestore" "il progetto chiede $gestore"
    else
      riga_no "$nome_gestore" "manca — il progetto chiede $gestore"
      # corepack e' il modo di Node: attiva la versione dichiarata SENZA installazioni globali.
      manca "$nome_gestore per $NOME" "corepack enable"
    fi
  elif [ -n "$(trova 'pnpm-lock.yaml')" ] && ! ce_la_ha pnpm; then
    riga_no "pnpm" "il progetto ha un blocco pnpm ma pnpm non c'e'"
    manca "pnpm" "corepack enable"
  elif [ -n "$(trova 'yarn.lock')" ] && ! ce_la_ha yarn; then
    riga_no "yarn" "il progetto ha un blocco yarn ma yarn non c'e'"
    manca "yarn" "corepack enable"
  else
    riga_ok "npm $(versione npm)" ""
  fi
fi

# --- Python ----------------------------------------------------------------
mapfile -t PY < <(trova "pyproject.toml"; trova "requirements.txt")
if [ "${#PY[@]}" -gt 0 ]; then
  trovato_qualcosa=1
  # Si prende il valore FRA VIRGOLETTE: cercare il primo ">=" nella riga intera
  # pescherebbe l'uguale dell'assegnazione e stamperebbe "chiede =".
  chiede_py="$(grep -hoE 'requires-python[[:space:]]*=[[:space:]]*"[^"]+"' "${PY[@]}" 2>/dev/null \
               | head -1 | sed -E 's/.*"([^"]+)".*/\1/' || true)"
  if ce_la_ha python; then
    riga_ok "Python $(versione python)" "${chiede_py:+chiede $chiede_py}"
  else
    riga_no "Python" "non installato"
    manca "Python" "installa Python ${chiede_py:-3.12} dal sito ufficiale"
  fi
  # Trappola nota su Windows: python3 finisce sullo stub del Microsoft Store.
  if ! python3 --version >/dev/null 2>&1; then
    riga_info "python3" "non funziona (stub del Microsoft Store) — usa 'python'"
  fi
fi

# --- Go --------------------------------------------------------------------
mapfile -t GO < <(trova "go.mod")
if [ "${#GO[@]}" -gt 0 ]; then
  trovato_qualcosa=1
  chiede_go="$(grep -hoE '^go [0-9.]+' "${GO[@]}" 2>/dev/null | head -1 | awk '{print $2}' || true)"
  if ce_la_ha go; then
    riga_ok "Go $(go version 2>&1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)" "${chiede_go:+chiede $chiede_go}"
  else
    riga_no "Go" "non installato"
    manca "Go" "installa Go ${chiede_go:-} dal sito ufficiale"
  fi
fi

# --- Flutter / telefono ----------------------------------------------------
mapfile -t FL < <(trova "pubspec.yaml")
if [ "${#FL[@]}" -gt 0 ]; then
  trovato_qualcosa=1
  if ce_la_ha flutter; then
    riga_ok "Flutter $(versione flutter)" ""
    # Le licenze Android non accettate bloccano la compilazione. Vale la pena aspettare
    # i pochi secondi di flutter doctor: e' l'intoppo piu' frequente su una macchina nuova.
    doc="$(flutter doctor 2>&1 || true)"
    if echo "$doc" | grep -qiE "license status unknown|licenses not accepted"; then
      riga_no "licenze Android" "non accettate — la compilazione per telefono si ferma"
      manca "licenze Android" "flutter doctor --android-licenses"
    else
      riga_ok "licenze Android" "accettate"
    fi
  else
    riga_no "Flutter" "non installato"
    manca "Flutter" "installa Flutter dal sito ufficiale"
  fi
fi

# --- Docker e i servizi ----------------------------------------------------
mapfile -t DC < <(trova "docker-compose.yml"; trova "docker-compose.yaml"; trova "compose.yml")
if [ "${#DC[@]}" -gt 0 ]; then
  trovato_qualcosa=1
  servizi="$(grep -hoE '^\s+image:\s*\S+' "${DC[@]}" 2>/dev/null | awk '{print $2}' | sort -u | tr '\n' ' ' || true)"
  if ce_la_ha docker; then
    if docker info >/dev/null 2>&1; then
      riga_ok "Docker $(versione docker)" "acceso"
    else
      riga_no "Docker" "installato ma SPENTO — i servizi non partono"
      manca "Docker acceso" "apri Docker Desktop e aspetta che dica in esecuzione"
    fi
    [ -n "$servizi" ] && riga_info "servizi del progetto" "$servizi"
  else
    riga_no "Docker" "non installato"
    manca "Docker" "installa Docker Desktop"
  fi
fi

# --- Le chiavi (qui finisce cio' che i file sanno dire) --------------------
mapfile -t EXAMPLES < <(trova ".env.example")
for ex in "${EXAMPLES[@]:-}"; do
  [ -z "$ex" ] && continue
  trovato_qualcosa=1
  vero="${ex%.example}"
  rel="${ex#$PROGETTO/}"
  # Il modello che il Metodo mette in ogni progetto nuovo porta i suoi segnaposto
  # (APP_NAME=NomeProgetto). Se sono ancora li', quel modello non e' mai stato
  # personalizzato: nessuno legge quelle chiavi, e copiarlo in un file vero
  # scriverebbe "nome_database" dentro una configurazione. Non e' una mancanza.
  if grep -q '^APP_NAME=NomeProgetto' "$ex" 2>/dev/null; then
    riga_info "chiavi: ${rel}" "modello del Metodo mai personalizzato — non serve il file vero"
    continue
  fi
  if [ ! -f "$vero" ]; then
    riga_no "chiavi: ${rel}" "manca il file vero accanto al modello"
    manca "le chiavi di ${rel%.example}" "copia il modello e riempi i valori — i valori li sai solo tu"
  else
    # Chiavi presenti nel modello e assenti nel file vero.
    mancanti="$(comm -23 \
      <(grep -oE '^[A-Z_][A-Z0-9_]*' "$ex" 2>/dev/null | sort -u) \
      <(grep -oE '^[A-Z_][A-Z0-9_]*' "$vero" 2>/dev/null | sort -u) | tr '\n' ' ')"
    if [ -n "${mancanti// /}" ]; then
      riga_no "chiavi: ${rel%.example}" "mancano: $mancanti"
      manca "chiavi in ${rel%.example}" "aggiungi: $mancanti"
    else
      riga_ok "chiavi: ${rel%.example}" "complete"
    fi
  fi
done

# ---------------------------------------------------------------------------
# Verdetto
# ---------------------------------------------------------------------------

echo
if [ "$trovato_qualcosa" -eq 0 ]; then
  echo "  Questo progetto non dichiara niente da installare."
  echo "  Se invece qualcosa serve, non e' scritto da nessuna parte: vale la pena scriverlo"
  echo "  in PROJECT_CONFIG.md, cosi' la prossima volta questo comando lo sa."
  echo
  exit 0
fi

if [ "${#MANCANTI[@]}" -eq 0 ]; then
  echo "  Non manca niente: il progetto puo' partire."
  echo
  exit 0
fi

echo "  DA FARE — ${#MANCANTI[@]} $([ "${#MANCANTI[@]}" -eq 1 ] && echo cosa || echo cose):"
echo
for m in "${MANCANTI[@]}"; do
  echo "  * ${m%%|*}"
  echo "      ${m#*|}"
done
echo
echo "  Nessun comando e' stato lanciato: toccano la macchina, li lanci tu."
echo
exit 0
