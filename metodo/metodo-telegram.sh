#!/usr/bin/env bash
# metodo-telegram.sh — il canale a DUE SENSI fra il Metodo Villa e Villa, su Telegram.
#
# A COSA SERVE
#   Il runner sa gia' MANDARE notifiche. Questo file aggiunge la meta' che
#   ASCOLTA: il guardiano puo' porre una domanda e restare in attesa della
#   risposta di Villa, cosi' una corsa lunga si ferma invece di morire, e
#   riparte da sola appena Villa risponde dal telefono.
#
# COMANDI
#   manda "<testo>" [--silenzioso]   Invia un messaggio. Non attende nulla.
#   chiedi "<domanda>"               Invia la domanda e ATTENDE la risposta di Villa.
#                                    Stampa la risposta su stdout.
#                                    Uscita 0 = risposta ricevuta, 2 = nessuna risposta,
#                                    3 = canale non configurato.
#   ascolta [secondi]                Attende UN messaggio di Villa e lo stampa.
#   stato                            Dice se il canale e' configurato e raggiungibile.
#   scopri                           Elenca conversazioni e sezioni viste dal bot, con i
#                                    numeri da mettere in configurazione. Serve in fase di
#                                    installazione. Non consuma i messaggi di nessuno.
#
# CONFIGURAZIONE (da .env.runner, mai da file tracciati in git)
#   TELEGRAM_BOT_TOKEN      obbligatorio
#   TELEGRAM_CHAT_ID        obbligatorio — ed e' anche la lista bianca: si accettano
#                           SOLO messaggi che arrivano da questa chat.
#   TELEGRAM_ATTESA_MAX     secondi di attesa prima di arrendersi (default 14400 = 4 ore)
#   TELEGRAM_TRASCRITTORE   comando che trasforma un vocale in testo. Riceve il percorso
#                           del file audio e stampa il testo. Se non c'e', i vocali non
#                           si perdono: si dice a Villa che vanno riscritti.
#
# PRINCIPIO: se manca un pezzo esterno, NON si rompe niente. Senza token il canale
# si dichiara spento e chi lo usa si comporta come oggi; senza trascrittore i vocali
# degradano a una richiesta di riscrivere.
#
# I file ricevuti (foto, vocali) finiscono nella cartella temporanea di SISTEMA, mai
# nel repository: nessun progetto si sporca e non serve nessuna regola di .gitignore.

set -euo pipefail

# ---------------------------------------------------------------------------
# Contesto e configurazione
# ---------------------------------------------------------------------------
PROGETTO="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
NOME_PROGETTO="$(basename "$PROGETTO")"

# La configurazione arriva da due posti, dal piu' generale al piu' specifico: chi viene
# dopo vince.
#   1. CONDIVISA — $HOME/.metodo-villa/condivisa.env, fuori da ogni repository: il bot e
#      il gruppo, che sono gli stessi per tutti i progetti. Si scrive una volta sola.
#   2. DEL PROGETTO — .env.runner, non tracciato da git: la sua sezione del gruppo, e
#      qualunque eccezione voglia fare rispetto alla configurazione condivisa.
# Cosi' un progetto nuovo non copia niente: eredita bot e gruppo, e al primo messaggio
# si crea da solo la sua sezione (vedi assicura_sezione in metodo-telegram.py).
CONFIG_CONDIVISA="${METODO_CONFIG_CONDIVISA:-$HOME/.metodo-villa/condivisa.env}"
if [ -f "$CONFIG_CONDIVISA" ]; then
  # shellcheck disable=SC1091
  set -a; . "$CONFIG_CONDIVISA"; set +a
fi
if [ -f "$PROGETTO/.env.runner" ]; then
  # shellcheck disable=SC1091
  set -a; . "$PROGETTO/.env.runner"; set +a
fi

TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"
TELEGRAM_ATTESA_MAX="${TELEGRAM_ATTESA_MAX:-14400}"
TELEGRAM_TRASCRITTORE="${TELEGRAM_TRASCRITTORE:-}"
# Sezione (topic) del gruppo dedicata a QUESTO progetto. Vuota = chat semplice.
TELEGRAM_TOPIC_ID="${TELEGRAM_TOPIC_ID:-}"

# Cartella di lavoro FUORI dal repository: file ricevuti e segnaposto di lettura.
CARTELLA_TMP="${TMPDIR:-/tmp}/metodo-villa-telegram/$NOME_PROGETTO"
mkdir -p "$CARTELLA_TMP"
FILE_OFFSET="$CARTELLA_TMP/offset"

# ---------------------------------------------------------------------------
# Helper
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Vero (0) se il canale ha tutto il necessario per funzionare.
canale_attivo() {
  [ -n "$TELEGRAM_BOT_TOKEN" ] && [ -n "$TELEGRAM_CHAT_ID" ]
}

# Esegue l'helper Python passando i valori via ambiente.
# I valori NON si interpolano nella stringa Python: percorsi Windows con backslash,
# apici e caratteri speciali romperebbero il codice (stessa ragione documentata nel runner).
python_telegram() {
  # Dove salvare il numero della sezione appena creata. Di norma lo passa il runner
  # (per un monorepo e' sempre la radice); lanciando questo script a mano si intende
  # il progetto corrente, altrimenti la sezione si ricreerebbe a ogni messaggio.
  TG_ENV_RUNNER="${TG_ENV_RUNNER:-$PROGETTO/.env.runner}" \
  TG_TOKEN="$TELEGRAM_BOT_TOKEN" \
  TG_CHAT="$TELEGRAM_CHAT_ID" \
  TG_CARTELLA="$CARTELLA_TMP" \
  TG_TOPIC="$TELEGRAM_TOPIC_ID" \
  PYTHONIOENCODING=utf-8 \
  python "$SCRIPT_DIR/metodo-telegram.py" "$@"
}


# ---------------------------------------------------------------------------
# Comando: manda
# ---------------------------------------------------------------------------
cmd_manda() {
  local testo="${1:-}"
  local silenzioso="false"
  [ "${2:-}" = "--silenzioso" ] && silenzioso="true"
  if [ -z "$testo" ]; then echo "ERRORE: manda vuole un testo." >&2; exit 1; fi
  if ! canale_attivo; then
    echo "Canale Telegram spento (manca token o chat): non mando niente." >&2
    exit 3
  fi
  TG_MSG="$testo" TG_SILENT="$silenzioso" python_telegram manda
}

# ---------------------------------------------------------------------------
# Comando: chiedi — manda la domanda e ASPETTA la risposta
# ---------------------------------------------------------------------------
cmd_chiedi() {
  local domanda="${1:-}"
  local attesa="${2:-$TELEGRAM_ATTESA_MAX}"
  if [ -z "$domanda" ]; then echo "ERRORE: chiedi vuole una domanda." >&2; exit 1; fi
  if ! canale_attivo; then
    echo "Canale Telegram spento (manca token o chat): non posso chiedere niente." >&2
    exit 3
  fi
  TG_MSG="$domanda" \
  TG_ATTESA="$attesa" \
  TG_TRASCRITTORE="$TELEGRAM_TRASCRITTORE" \
  TG_OFFSET_FILE="$FILE_OFFSET" \
  python_telegram chiedi
}

# ---------------------------------------------------------------------------
# Comando: ascolta — aspetta un messaggio senza averne mandato uno
# ---------------------------------------------------------------------------
cmd_ascolta() {
  local attesa="${1:-$TELEGRAM_ATTESA_MAX}"
  if ! canale_attivo; then
    echo "Canale Telegram spento (manca token o chat)." >&2
    exit 3
  fi
  TG_ATTESA="$attesa" \
  TG_TRASCRITTORE="$TELEGRAM_TRASCRITTORE" \
  TG_OFFSET_FILE="$FILE_OFFSET" \
  python_telegram ascolta
}

# ---------------------------------------------------------------------------
# Comando: stato — diagnosi leggibile, senza mandare niente a nessuno
# ---------------------------------------------------------------------------
cmd_stato() {
  echo "CANALE TELEGRAM — $NOME_PROGETTO"
  if ! canale_attivo; then
    echo "  stato        : SPENTO"
    [ -z "$TELEGRAM_BOT_TOKEN" ] && echo "  manca        : TELEGRAM_BOT_TOKEN"
    [ -z "$TELEGRAM_CHAT_ID" ]   && echo "  manca        : TELEGRAM_CHAT_ID"
    echo "  dove metterli: $PROGETTO/.env.runner (modello in metodo/.env.runner.example)"
    echo
    echo "Il Metodo funziona lo stesso: senza canale, il runner si ferma come sempre."
    return 0
  fi
  echo "  stato        : configurato"
  echo "  attesa max   : ${TELEGRAM_ATTESA_MAX}s ($((TELEGRAM_ATTESA_MAX / 3600))h circa)"
  if [ -n "$TELEGRAM_TRASCRITTORE" ]; then
    echo "  vocali       : trascritti con '$TELEGRAM_TRASCRITTORE'"
  else
    echo "  vocali       : NON trascrivibili (manca TELEGRAM_TRASCRITTORE) — si chiede di riscrivere"
  fi
  echo "  file ricevuti: $CARTELLA_TMP  (fuori dal repository)"
  echo
  python_telegram stato
}

# ---------------------------------------------------------------------------
# Comando: scopri — a che gruppo/sezione sto parlando?
# ---------------------------------------------------------------------------
# Non pretende TELEGRAM_CHAT_ID: e' il comando che serve proprio a scoprirlo.
# ---------------------------------------------------------------------------
# Comando: crea-sezione — una sezione del gruppo per questo progetto
# ---------------------------------------------------------------------------
# Si fa UNA volta per progetto. Telegram non offre un modo per rileggere l'elenco
# delle sezioni, quindi il numero va conservato in .env.runner.
cmd_crea_sezione() {
  local nome="${1:-$NOME_PROGETTO}"
  if [ -z "$TELEGRAM_BOT_TOKEN" ] || [ -z "$TELEGRAM_CHAT_ID" ]; then
    echo "Servono TELEGRAM_BOT_TOKEN e TELEGRAM_CHAT_ID (il numero del gruppo)." >&2
    exit 3
  fi
  TG_MSG="$nome" python_telegram crea-sezione
}

cmd_scopri() {
  if [ -z "$TELEGRAM_BOT_TOKEN" ]; then
    echo "Serve almeno TELEGRAM_BOT_TOKEN in .env.runner." >&2
    exit 3
  fi
  python_telegram scopri
}

# ---------------------------------------------------------------------------
# Dispatch
# ---------------------------------------------------------------------------
uso() {
  sed -n '2,30p' "$0" | sed 's/^# \{0,1\}//'
}

cmd="${1:-}"; shift || true
case "$cmd" in
  manda)   cmd_manda "$@" ;;
  chiedi)  cmd_chiedi "$@" ;;
  ascolta) cmd_ascolta "$@" ;;
  stato)   cmd_stato "$@" ;;
  scopri)       cmd_scopri "$@" ;;
  crea-sezione) cmd_crea_sezione "$@" ;;
  ""|-h|--help|aiuto) uso ;;
  *) echo "Comando sconosciuto: $cmd" >&2; echo; uso; exit 1 ;;
esac
