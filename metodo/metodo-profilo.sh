#!/usr/bin/env bash
# metodo-profilo.sh — tiene allineato il profilo personale di Villa fra il repo madre
# (dove vive l'originale, sotto controllo di versione) e la cartella di sistema
# ~/.claude/ (dove Claude Code lo legge davvero a ogni sessione).
#
# PERCHE' ESISTE
#   Il 2026-08-28 il computer principale di Villa si e' guastato e il profilo e' andato
#   perso: era l'unico pezzo del sistema senza copia da nessuna parte. Ora l'originale
#   sta in personale/ dentro il Metodo, versionato; qui c'e' il pezzo che lo porta dove
#   serve senza doversene ricordare.
#
# COMANDI
#   stato [madre]      Dice se le due copie divergono e quale e' piu' recente. Sola lettura.
#   installa [madre]   Porta l'originale dalla madre in ~/.claude/ (fa il backup di cio' che c'era).
#   raccogli [madre]   Porta in madre le modifiche fatte direttamente in ~/.claude/.
#   allinea [madre]    Modalita' automatica, usata dall'aggiornamento del Metodo: installa
#                      quando e' sicuro, AVVISA e non tocca niente quando il locale e' piu'
#                      recente. Non perde mai dati e non chiede niente.
#
# PRINCIPIO: nessun comando sovrascrive silenziosamente una versione piu' recente.
# In dubbio si avvisa e ci si ferma: perdere una correzione di Villa e' il difetto che
# questo strumento esiste per impedire.

set -euo pipefail

DEFAULT_MADRE="C:/Users/Mario/Documents/GitHub/Metodo-Villa-v2"
DEST="${HOME}/.claude"
FILE_PROFILO=("CLAUDE.md" "parlare-con-villa.md")

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

risolvi_madre() {
  local m="${1:-${METODO_VILLA_HOME:-$DEFAULT_MADRE}}"
  if [ ! -d "$m" ]; then
    echo "ERRORE: repo madre non trovato: $m" >&2
    echo "Passa il percorso come argomento o imposta METODO_VILLA_HOME." >&2
    exit 1
  fi
  (cd "$m" && pwd)
}

# Confronto che ignora i fine-riga (CRLF vs LF), come fa lo scarico del Metodo.
identici_ignora_cr() {
  [ -f "$1" ] && [ -f "$2" ] || return 1
  diff -q <(tr -d '\r' < "$1") <(tr -d '\r' < "$2") >/dev/null 2>&1
}

# Stampa l'ora di ultima modifica in secondi. 0 se il file non c'e'.
quando() {
  [ -f "$1" ] || { echo 0; return; }
  stat -c '%Y' "$1" 2>/dev/null || echo 0
}

# Copia con backup datato del file di destinazione, se c'era ed era diverso.
copia_con_backup() {
  local src="$1" dst="$2" marca
  mkdir -p "$(dirname "$dst")"
  if [ -f "$dst" ] && ! identici_ignora_cr "$src" "$dst"; then
    marca="$(date +%Y%m%d-%H%M%S)"
    cp -f "$dst" "$dst.bak.$marca"
    echo "    backup del precedente: $(basename "$dst").bak.$marca"
  fi
  cp -f "$src" "$dst"
}

# ---------------------------------------------------------------------------
# Comandi
# ---------------------------------------------------------------------------

cmd_stato() {
  local madre; madre="$(risolvi_madre "${1:-}")"
  local origine copia to tc divergenze=0

  echo "Profilo personale di Villa"
  echo "  originale: $madre/personale/"
  echo "  in uso:    $DEST/"
  echo

  for f in "${FILE_PROFILO[@]}"; do
    origine="$madre/personale/$f"; copia="$DEST/$f"
    if [ ! -f "$origine" ]; then
      echo "  ! $f — manca nella madre"; divergenze=1; continue
    fi
    if [ ! -f "$copia" ]; then
      echo "  - $f — non installato (in uso non c'e')"; divergenze=1; continue
    fi
    if identici_ignora_cr "$origine" "$copia"; then
      echo "  = $f — allineato"
    else
      to="$(quando "$origine")"; tc="$(quando "$copia")"
      if [ "$tc" -gt "$to" ]; then
        echo "  > $f — DIVERGE, la copia in uso e' piu' recente (usa: raccogli)"
      else
        echo "  < $f — diverge, l'originale e' piu' recente (usa: installa)"
      fi
      divergenze=1
    fi
  done

  [ "$divergenze" -eq 0 ] && echo && echo "Tutto allineato."
  return 0
}

cmd_installa() {
  local madre; madre="$(risolvi_madre "${1:-}")"
  echo "Installo il profilo in $DEST/"
  for f in "${FILE_PROFILO[@]}"; do
    if [ ! -f "$madre/personale/$f" ]; then
      echo "  ! assente nella madre, salto: $f"; continue
    fi
    copia_con_backup "$madre/personale/$f" "$DEST/$f"
    echo "  + $f"
  done
  echo "Fatto."
}

cmd_raccogli() {
  local madre; madre="$(risolvi_madre "${1:-}")"
  echo "Riporto nell'originale le modifiche fatte in $DEST/"
  local cambiati=0
  for f in "${FILE_PROFILO[@]}"; do
    if [ ! -f "$DEST/$f" ]; then
      echo "  - non presente in uso, salto: $f"; continue
    fi
    if identici_ignora_cr "$DEST/$f" "$madre/personale/$f"; then
      echo "  = $f — gia' uguale"; continue
    fi
    mkdir -p "$madre/personale"
    cp -f "$DEST/$f" "$madre/personale/$f"
    echo "  + $f — aggiornato nella madre"
    cambiati=1
  done
  echo
  if [ "$cambiati" -eq 1 ]; then
    echo "Ora committa nella madre: le modifiche non sono ancora in versione."
  else
    echo "Niente da riportare."
  fi
}

# Modalita' automatica del gancio. Non chiede, non perde, avvisa quando si ferma.
cmd_allinea() {
  local madre; madre="$(risolvi_madre "${1:-}")"
  local origine copia to tc fermato=0

  for f in "${FILE_PROFILO[@]}"; do
    origine="$madre/personale/$f"; copia="$DEST/$f"
    [ -f "$origine" ] || continue

    if [ ! -f "$copia" ]; then
      mkdir -p "$DEST"; cp -f "$origine" "$copia"
      echo "  profilo: installato $f (non c'era)"
      continue
    fi

    identici_ignora_cr "$origine" "$copia" && continue

    to="$(quando "$origine")"; tc="$(quando "$copia")"
    if [ "$tc" -gt "$to" ]; then
      echo "  ATTENZIONE profilo: $f in uso e' piu' RECENTE dell'originale: non lo tocco."
      echo "                      Per non perdere quella modifica: ./metodo/metodo-profilo.sh raccogli"
      fermato=1
    else
      copia_con_backup "$origine" "$copia"
      echo "  profilo: aggiornato $f"
    fi
  done

  [ "$fermato" -eq 1 ] && return 0
  return 0
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
uso() { sed -n '2,22p' "$0" | sed 's/^# \{0,1\}//'; }

cmd="${1:-}"; shift || true
case "$cmd" in
  stato)              cmd_stato "$@" ;;
  installa)           cmd_installa "$@" ;;
  raccogli)           cmd_raccogli "$@" ;;
  allinea)            cmd_allinea "$@" ;;
  ""|-h|--help|aiuto) uso ;;
  *) echo "Comando sconosciuto: $cmd" >&2; echo; uso; exit 1 ;;
esac
