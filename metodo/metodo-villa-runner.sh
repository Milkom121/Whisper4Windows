#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

# ROOT_DIR = la radice del progetto, cioe' la cartella che CONTIENE metodo/ (dove vive
# questo script). Da qui si legge sempre il Metodo: CLAUDE.md, il canale Telegram, la
# configurazione del runner. Ricavarla dallo script invece che da pwd rende il runner
# insensibile alla cartella da cui lo si lancia.
# PROJECT_DIR = dove si LAVORA. Di norma coincide con ROOT_DIR. Con --project DIR punta a
# una sotto-cartella: serve ai monorepo, che tengono piu' applicazioni in un repository
# solo (es. apps/console). In quel caso il Metodo arriva comunque dalla radice, e le
# regole del modulo si sommano — cosi' un modulo non deve duplicare il Metodo.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Configurazione CONDIVISA da tutti i progetti: sta nella cartella personale, fuori da
# ogni repository, e contiene le cose che non cambiano da progetto a progetto (il bot
# Telegram e il gruppo). Cosi' si scrivono una volta nella vita invece che in ogni
# progetto, e un progetto nuovo non ha niente da copiare: eredita, e si crea da solo la
# sua sezione del gruppo al primo messaggio.
METODO_CONFIG_CONDIVISA="${METODO_CONFIG_CONDIVISA:-$HOME/.metodo-villa/condivisa.env}"

# MAX_BLOCKS e' un TETTO DI SICUREZZA (paracadute anti-runaway), NON la quantita' di
# lavoro da fare. Il runner si ferma da solo sugli stop naturali (fine fase, checkpoint,
# errore, roadmap esaurita); questo numero serve solo a evitare che, in caso di anomalia,
# il runner giri all'infinito di notte bruciando token. Tienilo ALTO. Override: --max-blocks N.
MAX_BLOCKS=300; TIMEOUT_MINUTES=30; PROJECT_DIR=""; DRY_RUN=false; VERBOSE=false; NOTIFY=true; RESUME=false; TARGET_PHASE=""; TEST_TELEGRAM=false; ALL_PHASES=false; MODEL_OVERRIDE=""; CORSIA=""; AGENTE=""; OTTIMIZZA=false; MODEL_ESPLICITO=false
CLAUDE_MD="CLAUDE.md"; PROJECT_CONFIG="PROJECT_CONFIG.md"; ROADMAP="ROADMAP.md"; PROGRESS_FILE="docs/diario/progress.json"
HANDOFF_FILE="docs/diario/handoff.md"; SESSION_LOG="docs/diario/session-log.md"; RUNNER_LOG="docs/diario/runner-log.txt"
# Il record del "mentre lavora": chi ci sta lavorando adesso e da quando. Lo legge la
# schermata del runner (Fase 5, momento DURANTE) tramite il servitore — senza, meta'
# schermata mostrerebbe caselle vuote. Una corsa = un file, riscritto a ogni blocco.
DURANTE_FILE="docs/diario/durante.json"
# La richiesta di fermarsi, lasciata dalla schermata: un file che compare e basta. Il
# runner lo guarda FRA un blocco e l'altro, mai dentro — "ferma dopo questo blocco"
# vuol dire che il blocco in corso arriva alla fine, con la sua verifica e il suo commit.
FERMA_FILE="docs/diario/ferma-la-corsa"
# Quante righe del diario precedente entrano nel messaggio del blocco. Il diario e' il
# passaggio di consegne al blocco dopo: 50 righe bastano e avanzano. Chi ne scrive di piu'
# si vede troncare la coda nel messaggio (il file sul disco resta intero).
HANDOFF_MAX_RIGHE=50
# Quanti blocchi la corsa prevedeva di fare quando e' partita (vedi previsione_corsa):
# serve per dire, a ogni blocco, a che punto siamo del percorso previsto.
PREVISTI_ALLA_PARTENZA=0

while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run) DRY_RUN=true; shift;; --max-blocks) MAX_BLOCKS="$2"; shift 2;; --phase) TARGET_PHASE="$2"; shift 2;;
        --timeout) TIMEOUT_MINUTES="$2"; shift 2;; --project) PROJECT_DIR="$2"; shift 2;; --verbose) VERBOSE=true; shift;;
        --no-notify) NOTIFY=false; shift;; --resume) RESUME=true; shift;;
        --tutte-le-fasi) ALL_PHASES=true; shift;;
        # Scegliere il modello a mano SPEGNE l'instradamento: sono due modi alternativi di
        # decidere chi lavora, mai sovrapposti. Cosi' guardando il registro si capisce
        # sempre perche' un blocco e' finito su un motore invece che su un altro.
        --model) MODEL_OVERRIDE="$2"; MODEL_ESPLICITO=true; shift 2;;
        --corsia) CORSIA="$2"; shift 2;;
        --agente) AGENTE="$2"; shift 2;;
        --impegno) IMPEGNO="$2"; shift 2;;
        --liberta|--libertà) LIBERTA_DA_RIGA_DI_COMANDO="$2"; shift 2;;
        --ottimizza) OTTIMIZZA=true; shift;;
        --test-telegram) TEST_TELEGRAM=true; shift;;
        -h|--help) echo "Uso: ./metodo/metodo-villa-runner.sh [--dry-run] [--max-blocks N] [--phase N] [--tutte-le-fasi] [--project DIR] [--corsia NOME] [--model NOME] [--timeout N] [--verbose] [--resume] [--test-telegram]"
            echo "  --tutte-le-fasi : non si ferma a fine fase; prosegue con le fasi successive (si ferma solo a checkpoint, errore o blocco umano)"
            echo "  --corsia NOME   : lavora come corsia NOME di una fase parallela (diario in docs/diario/corsie/NOME/). Se omesso si deduce dal ramo 'corsia/NOME'. Vedi cap. 21."
            echo "  --agente NOME   : quale programma esegue il blocco (claude | opencode). Default claude; si puo' fissare per progetto con METODO_AGENTE in .env.runner. Vedi cap. 22."
            echo "  --project DIR   : lavora su una sotto-cartella (monorepo, es. apps/console). Il Metodo arriva dalla radice, le regole del modulo si sommano."
            echo "  --model NOME    : fissa il modello, nel formato che vuole l'agente scelto (Claude Code: claude-opus-5; OpenCode: fornitore/modello). Si puo' fissare per progetto con METODO_MODELLO in .env.runner. Se omesso usa il default del programma."
            echo "  --impegno LIV   : quanto il modello pensa prima di rispondere (low | medium | high | max). Default high; si puo' fissare per progetto con METODO_IMPEGNO in .env.runner. Vedi cap. 22."
            echo "  --ottimizza     : un motore per ogni peso di blocco (🔴 cruciale -> Opus 5, 🟡 importante -> Kimi K3, 🟢 ordinario -> GLM). I blocchi senza peso restano al motore della corsa. Si spegne da solo se scegli --model. Si puo' fissare con METODO_OTTIMIZZA=si. Vedi cap. 22."
            echo "  --liberta LIV   : quanto si puo' uscire dal seminato (stretto | normale | largo). Default normale: aggiusta cio' che trova rotto intorno, non rifa' cio' che funziona. Sui blocchi di peso 🔴 si stringe da solo. La dichiarazione di cosa e' stato fatto in piu' e' sempre accesa. Si puo' fissare con METODO_LIBERTA in .env.runner. Vedi cap. 05."
            exit 0;;
        *) echo -e "${RED}Opzione sconosciuta: $1${NC}"; exit 1;;
    esac
done
TIMEOUT_SECONDS=$((TIMEOUT_MINUTES * 60))

# Senza --project si lavora sulla radice. Con --project si normalizza a percorso assoluto
# (puo' arrivare relativo, es. "apps/console") risolvendolo rispetto alla radice: cosi'
# funziona anche lanciando il runner da un'altra cartella.
if [[ -z "$PROJECT_DIR" ]]; then
    PROJECT_DIR="$ROOT_DIR"
else
    PROJECT_DIR="$(cd "$ROOT_DIR" && cd "$PROJECT_DIR" 2>/dev/null && pwd)" \
        || { echo -e "${RED}Directory del modulo non trovata (--project)${NC}"; exit 1; }
fi

# CORSIE PARALLELE (cap. 21). Quando piu' agenti lavorano insieme sullo stesso progetto,
# ognuno sta in una corsia e tiene il SUO diario: due corsie che scrivessero nello stesso
# handoff.md si sovrascriverebbero il punto in cui sono arrivate, e ognuna ripartirebbe dal
# blocco dell'altra. Cartelle separate per nome: il conflitto non puo' proprio esistere, ne'
# durante il lavoro ne' quando i rami si uniscono.
# La corsia si dichiara con --corsia; se non lo si fa, si deduce dal ramo (i tavoli aperti da
# metodo-corsie.sh stanno su rami 'corsia/NOME'). Senza corsia tutto resta identico a prima.
if [[ -z "$CORSIA" ]]; then
    _ramo_corrente="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || true)"
    [[ "$_ramo_corrente" == corsia/* ]] && CORSIA="${_ramo_corrente#corsia/}"
fi
if [[ -n "$CORSIA" ]]; then
    HANDOFF_FILE="docs/diario/corsie/$CORSIA/handoff.md"
    PROGRESS_FILE="docs/diario/corsie/$CORSIA/progress.json"
    SESSION_LOG="docs/diario/corsie/$CORSIA/session-log.md"
    RUNNER_LOG="docs/diario/corsie/$CORSIA/runner-log.txt"
    DURANTE_FILE="docs/diario/corsie/$CORSIA/durante.json"
    FERMA_FILE="docs/diario/corsie/$CORSIA/ferma-la-corsa"
fi

# La corsa a vuoto NON deve toccare il segno del lavoro vero. Prima scriveva l'handoff
# finto sopra quello reale: bastava un --dry-run per far perdere al progetto il punto in
# cui era arrivato. Qui si lavora su COPIE, partendo dallo stato vero (cosi' la prova
# comincia davvero dal blocco giusto) e lasciando intatti gli originali.
if $DRY_RUN; then
    _dry_h="$(dirname "$HANDOFF_FILE")/prova-a-vuoto-handoff.md"
    _dry_p="$(dirname "$PROGRESS_FILE")/prova-a-vuoto-progress.json"
    _dry_s="$(dirname "$SESSION_LOG")/prova-a-vuoto-session-log.md"
    mkdir -p "$PROJECT_DIR/$(dirname "$HANDOFF_FILE")"
    [[ -f "$PROJECT_DIR/$HANDOFF_FILE"  ]] && cp "$PROJECT_DIR/$HANDOFF_FILE"  "$PROJECT_DIR/$_dry_h"
    [[ -f "$PROJECT_DIR/$PROGRESS_FILE" ]] && cp "$PROJECT_DIR/$PROGRESS_FILE" "$PROJECT_DIR/$_dry_p"
    HANDOFF_FILE="$_dry_h"; PROGRESS_FILE="$_dry_p"; SESSION_LOG="$_dry_s"
    DURANTE_FILE="$(dirname "$SESSION_LOG")/prova-a-vuoto-durante.json"
    FERMA_FILE="$(dirname "$SESSION_LOG")/prova-a-vuoto-ferma-la-corsa"
fi

# Carica la configurazione, dalla piu' generale alla piu' specifica: chi viene dopo
# vince. Prima quella CONDIVISA fra tutti i progetti (bot e gruppo Telegram, scritti
# una volta sola e fuori dai repository), poi quella della radice del progetto (la
# sua sezione del gruppo), poi l'eventuale override del modulo di un monorepo.
# Cosi' un progetto nuovo eredita bot e gruppo senza copiare niente, e al primo
# messaggio si crea da solo la sua sezione.
[[ -f "$METODO_CONFIG_CONDIVISA" ]] && source "$METODO_CONFIG_CONDIVISA"
[[ -f "$ROOT_DIR/.env.runner" ]] && source "$ROOT_DIR/.env.runner"
[[ "$PROJECT_DIR" != "$ROOT_DIR" && -f "$PROJECT_DIR/.env.runner" ]] && source "$PROJECT_DIR/.env.runner"

# Quale programma esegue davvero i blocchi (cap. 22). La scelta vive in un file suo, caricato
# anche dallo strumento delle corsie: cosi' il Consiglio degli Agenti usa lo stesso programma
# che il progetto ha scelto per i blocchi, invece di chiamare Claude Code a prescindere.
source "$SCRIPT_DIR/metodo-agente.sh"
# Come si legge una roadmap: stesso file dello strumento delle corsie (metodo-roadmap.sh).
source "$SCRIPT_DIR/metodo-roadmap.sh"
risolvi_agente || exit 1

# L'instradamento (un motore per ogni peso di blocco, cap. 22) si accende per progetto con
# METODO_OTTIMIZZA=si in .env.runner, o per una corsa sola con --ottimizza.
# Il messaggio quando si spegne arriva piu' sotto: qui log() non esiste ancora.
[[ "${METODO_OTTIMIZZA:-}" =~ ^(si|sì|yes|true|1)$ ]] && OTTIMIZZA=true

# QUANTO SI PUO' USCIRE DAL SEMINATO (decisione di Villa del 2026-08-18, cap. 05).
#   stretto  solo cio' che il blocco chiede
#   normale  aggiusta anche cio' che trova ROTTO intorno   (default)
#   largo    migliora anche cio' che funziona
# Si fissa per progetto con METODO_LIBERTA in .env.runner, o per una corsa sola con
# --liberta. Un valore inventato non passa in silenzio: si torna al default dicendolo, perche'
# una liberta' letta male sarebbe una liberta' presa senza che nessuno l'abbia concessa.
LIBERTA="${LIBERTA_DA_RIGA_DI_COMANDO:-${METODO_LIBERTA:-normale}}"
case "$LIBERTA" in
    stretto|normale|largo) ;;
    *) LIBERTA_NON_VALIDA="$LIBERTA"; LIBERTA="normale" ;;
esac
# Il motore della corsa, da rimettere quando un blocco senza peso non va instradato.
CORSA_AGENTE="$AGENTE"; CORSA_MODELLO="$MODEL_OVERRIDE"

# Cosa succede quando il runner si ferma: scrive a Villa, aspetta, e se non lo sente decide
# lui secondo le regole (cap. 24). Si carica dopo la configurazione, perche' legge da li'
# quanto aspettare e quante volte puo' rimettere in moto la corsa.
# Se il file non c'e' (progetto aggiornato a meta', copia parziale del Metodo) il runner
# lavora come prima: allo stop si ferma. Meglio senza guardiano che senza runner.
if [[ -f "$SCRIPT_DIR/metodo-guardiano.sh" ]]; then
    source "$SCRIPT_DIR/metodo-guardiano.sh"
else
    guardiano_interviene() { return 1; }
fi

# L'OCCHIO ESTERNO (cap. 05): a fine blocco guarda la differenza qualcuno che non l'ha
# costruita. Stessa regola del guardiano: se il file non c'e', il runner lavora come prima
# e ogni blocco passa. Meglio senza occhio esterno che senza runner.
if [[ -f "$SCRIPT_DIR/metodo-occhio-esterno.sh" ]]; then
    source "$SCRIPT_DIR/metodo-occhio-esterno.sh"
else
    OCCHIO_ESTERNO_ESITO="passa"; OCCHIO_ESTERNO_MOTIVO=""; OCCHIO_ESTERNO_FERMATE=0
    occhio_esterno_guarda() { OCCHIO_ESTERNO_ESITO="passa"; return 0; }
fi

log() { local ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"; echo -e "${CYAN}[$ts]${NC} $1"; echo "[$ts] $(echo -e "$1" | sed 's/\x1b\[[0-9;]*m//g')" >> "$PROJECT_DIR/$RUNNER_LOG"; }

# Chi sceglie il modello a mano ha gia' deciso chi lavora: l'instradamento si spegne, e lo
# dice — un'opzione che si annulla in silenzio e' peggio di un'opzione che non c'e'.
if [[ "$OTTIMIZZA" == true && "$MODEL_ESPLICITO" == true ]]; then
    OTTIMIZZA=false
    log "${YELLOW}Instradamento spento: hai scelto il modello a mano (--model $MODEL_OVERRIDE).${NC}"
fi
log_verbose() { $VERBOSE && log "$1" || true; }
die() { log "${RED}ERRORE FATALE: $1${NC}"; send_notification "Metodo Villa - Errore" "$1"; exit 1; }

# Telegram — configura token e chat_id per ricevere notifiche sul telefono
# Crea un bot con @BotFather, avvialo, e inserisci i dati in .env.runner
# (NON mettere credenziali in chiaro in file tracciati da git)
TELEGRAM_BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-}"
TELEGRAM_CHAT_ID="${TELEGRAM_CHAT_ID:-}"

# L'invio vero sta in metodo/metodo-telegram.sh, che e' il canale del Metodo: qui
# si delega e basta. Prima questa funzione aveva la sua copia dell'invio, e ne
# derivava che il runner non sapeva nulla delle SEZIONI del gruppo (una per
# progetto) ne' del limite di 4096 caratteri di Telegram, oltre il quale la
# notifica non parte affatto. Un punto solo, quindi una correzione sola.
send_telegram() {
    [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]] && return 0
    local msg="$1"
    local silent="${2:-false}"  # se "true" la notifica arriva senza suono/vibrazione
    # Il canale vive accanto a questo script: sono due pezzi della stessa macchina.
    local canale="$SCRIPT_DIR/metodo-telegram.sh"
    if [[ ! -f "$canale" ]]; then
        log_verbose "send_telegram: canale non trovato ($canale), notifica saltata"
        return 0
    fi
    # La sezione del gruppo e' UNA PER PROGETTO, non per modulo: nome e numero della
    # sezione si prendono sempre dalla radice, anche quando si lavora su un modulo di
    # un monorepo. Altrimenti lo stesso progetto si aprirebbe una sezione per modulo.
    # get_project_name e' definita piu' sotto: in bash conta l'ordine di CHIAMATA,
    # non quello di definizione, e qui si arriva sempre a script gia' letto.
    local nome_progetto; nome_progetto="$(get_project_name "$ROOT_DIR")"
    if [[ "$silent" == "true" ]]; then
        TG_NOME_PROGETTO="$nome_progetto" TG_ENV_RUNNER="$ROOT_DIR/.env.runner" \
            bash "$canale" manda "$msg" --silenzioso >> "$PROJECT_DIR/$RUNNER_LOG" 2>&1 \
            || log_verbose "send_telegram: invio fallito (vedi runner-log.txt)"
    else
        TG_NOME_PROGETTO="$nome_progetto" TG_ENV_RUNNER="$ROOT_DIR/.env.runner" \
            bash "$canale" manda "$msg" >> "$PROJECT_DIR/$RUNNER_LOG" 2>&1 \
            || log_verbose "send_telegram: invio fallito (vedi runner-log.txt)"
    fi
}

# Formatta un numero di minuti in "Xmin" oppure "Xh Ymin" se >= 60.
format_minutes() {
    local m="${1:-0}"
    if [[ $m -lt 60 ]]; then
        echo "${m}min"
    else
        local h=$((m / 60))
        local r=$((m % 60))
        echo "${h}h ${r}min"
    fi
}

# Trasforma un testo di summary libero in un elenco puntato leggibile.
# Delega a Python via env var per evitare problemi di escape (vedi send_telegram).
# Strategia di split: ". " seguito da maiuscola o cifra, " — ", ";"/";".
# Se il testo e gia una singola frase, ritorna un unico bullet.
format_summary_as_bullets() {
    local raw="$1"
    if [[ -z "$raw" ]]; then
        echo "• (nessuna descrizione)"
        return
    fi
    # PYTHONIOENCODING=utf-8 garantisce che stdout di python sia UTF-8 anche su
    # Windows Git Bash (dove il default e spesso cp1252). Senza questo, caratteri
    # unicode come il bullet vengono stripped o mangled.
    # Uso \u escape sequence per il bullet cosi il carattere non passa dalla
    # command line (problema encoding) ma viene costruito da Python stesso.
    PYTHONIOENCODING=utf-8 SUMMARY_RAW="$raw" python -c "
import os, re, sys
text = os.environ.get('SUMMARY_RAW', '').strip()
# Normalizza spazi e newline multipli in singolo spazio
text = re.sub(r'\s+', ' ', text)
bullet = '\u2022 '
if not text:
    sys.stdout.write(bullet + '(nessuna descrizione)\n')
else:
    # Split su: fine frase (. seguito da maiuscola o cifra), em dash, punto e virgola
    parts = re.split(r'(?<=\.) (?=[A-Z0-9])| \u2014 | - |; ', text)
    parts = [p.strip() for p in parts if p.strip()]
    if not parts:
        sys.stdout.write(bullet + text + '\n')
    else:
        for p in parts:
            sys.stdout.write(bullet + p + '\n')
" 2>/dev/null || echo "- $raw"
}

send_notification() {
    $NOTIFY || return 0; echo -ne '\a'
    # Notifiche desktop FIRE-AND-FORGET (non bloccanti).
    # Regola d'oro: il runner gira quando Villa NON e' davanti al PC.
    # Niente popup modale che aspetti un click, altrimenti il runner si
    # ferma all'infinito invece di mandare il riepilogo Telegram.
    if command -v notify-send &>/dev/null; then
        notify-send "$1" "$2" 2>/dev/null || true
    elif command -v osascript &>/dev/null; then
        osascript -e "display notification \"$2\" with title \"$1\"" 2>/dev/null || true
    elif command -v powershell.exe &>/dev/null; then
        # BalloonTip vicino all'orologio Windows: auto-scompare dopo 5s,
        # non blocca il focus, niente click richiesto. Lanciata in subshell
        # con & = totalmente staccata dal runner.
        local _ntitle="${1//\'/\'\'}" _ntext="${2//\'/\'\'}"
        (powershell.exe -NoProfile -WindowStyle Hidden -Command \
            "Add-Type -AssemblyName System.Windows.Forms; \$n = New-Object System.Windows.Forms.NotifyIcon; \$n.Icon = [System.Drawing.SystemIcons]::Information; \$n.BalloonTipTitle = '$_ntitle'; \$n.BalloonTipText = '$_ntext'; \$n.Visible = \$true; \$n.ShowBalloonTip(5000); Start-Sleep -Seconds 5; \$n.Dispose();" \
            >/dev/null 2>&1 &) 2>/dev/null || true
    fi
}

# --- Su quale pezzo del progetto si e' lavorato ------------------------------
# In un monorepo (piu' applicazioni dentro un repository solo) sapere che il runner
# sta lavorando su "SenilCare" non basta: cambia tutto se ha messo le mani su
# SenilWatch o su SenilFlow. Il modulo NON si indovina dal testo del blocco — un
# blocco puo' nominarne tre e toccarne uno. Si guarda cosa e' cambiato davvero: i
# file dei commit fatti durante il blocco.
#
# E' modulo la sotto-cartella di primo livello dentro una delle cartelle che i
# monorepo usano per contenerli. In un progetto normale non ne esiste nessuna e il
# messaggio resta identico a prima.
CONTENITORI_MODULI="apps packages services modules"

# HEAD prima che partisse la sessione del blocco. Vuota = non e' stata lanciata
# nessuna sessione (es. stop su un checkpoint letto dalla roadmap): in quel caso
# non si e' lavorato a niente e non si scrive nessun modulo.
HEAD_PRIMA_DEL_BLOCCO=""

moduli_toccati() {
    [[ -z "$HEAD_PRIMA_DEL_BLOCCO" ]] && return 0
    local cambiati; cambiati="$(git -C "$ROOT_DIR" diff --name-only "$HEAD_PRIMA_DEL_BLOCCO" HEAD 2>/dev/null)"
    [[ -z "$cambiati" ]] && return 0
    local trovati=""
    while IFS= read -r f; do
        local contenitore="${f%%/*}" dentro="${f#*/}"
        [[ "$dentro" == "$f" ]] && continue   # file nella radice: non e' di nessun modulo
        case " $CONTENITORI_MODULI " in *" $contenitore "*) ;; *) continue;; esac
        local modulo="${dentro%%/*}"
        [[ -z "$modulo" || "$modulo" == "$dentro" ]] && continue   # file dentro apps/ ma fuori da un modulo
        case " $trovati " in *" $modulo "*) ;; *) trovati="$trovati $modulo";; esac
    done <<< "$cambiati"
    printf '%s' "${trovati# }"
}

# Resoconto Telegram con dettagli.
# Parametri posizionali:
#   1 status          — BLOCCO_OK / CHECKPOINT / PHASE_COMPLETE / ERROR / BLOCKED / MISSING / FAILED / LIMITE_RAGGIUNTO
#   2 bid             — identificativo del blocco (es. F1B3)
#   3 blocks_run      — numero blocchi eseguiti in questa esecuzione del runner (contatore interno)
#   4 elapsed_total   — minuti dall'inizio dell'esecuzione del runner
#   5 summary         — testo del SUMMARY dal handoff
#   6 next            — testo del NEXT dal handoff
#   7 elapsed_block   — minuti di durata del singolo blocco appena chiuso (default 0)
#
# Comportamento:
# - BLOCCO_OK → notifica SILENZIOSA (disable_notification=true), senza sezione Dispatch
# - Tutti gli altri stati di STOP → notifica SONORA e include la sezione Dispatch con istruzioni
# Il nome del modello come lo direbbe una persona: "claude-opus-4-6[1m]" -> "Opus 4.6".
# Sul telefono deve dire chi ha lavorato, non l'identificativo interno del programma.
modello_leggibile() {
    local m="${1:-}"; [[ -n "$m" ]] || { echo ""; return 0; }
    m="${m%%[*}"                       # via il suffisso tra parentesi quadre
    m="${m#claude-}"                   # via il prefisso del fornitore
    m="${m%-[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]}"   # via la data in coda (…-20251001)
    local nome="${m%%-*}" resto="${m#*-}"
    [[ "$resto" == "$nome" ]] && resto=""
    # "opus" -> "Opus", "4-6" -> "4.6"
    printf '%s' "$(tr '[:lower:]' '[:upper:]' <<< "${nome:0:1}")${nome:1}${resto:+ ${resto//-/.}}"
}

# Il telefono non e' il posto per i muri di testo: si tengono le prime righe e si taglia.
# Il testo intero resta nel diario e nel registro, per chi lo vuole.
taglia_per_telefono() {
    local t="$1" max_righe=6 max_car=700
    local tagliato; tagliato="$(printf '%s' "$t" | head -n "$max_righe")"
    if [[ "${#tagliato}" -gt $max_car ]]; then tagliato="${tagliato:0:$max_car}"; fi
    [[ "${#tagliato}" -lt "${#t}" ]] && tagliato="${tagliato}…"
    printf '%s' "$tagliato"
}

send_telegram_report() {
    local status="$1" bid="$2" blocks_run="$3" elapsed_total="$4" summary="$5" next="$6" elapsed_block="${7:-0}"
    # Le etichette sono scritte per VILLA, che legge dal telefono: dicono cosa e'
    # successo e se deve fare qualcosa, non in che stato interno si trova la
    # macchina. "CHECKPOINT" e "PHASE_COMPLETE" non vogliono dire niente a chi
    # non ha il manuale sotto mano.
    local icon label serve_te silent="false"
    serve_te=""
    case "$status" in
        CONTINUE) return 0;;  # nessuna notifica su CONTINUE generico — usa BLOCCO_OK
        BLOCCO_OK)       icon="✔️"; label="Un pezzo di lavoro finito";      silent="true";;
        CHECKPOINT)      icon="⏸️"; label="Mi sono fermato: serve una tua decisione"
                         serve_te="Sì — devi decidere tu qualcosa prima che possa andare avanti.";;
        PHASE_COMPLETE)  icon="✅"; label="Finita un'intera fase del progetto"
                         serve_te="Puoi dare un'occhiata quando vuoi. Il lavoro e' a un punto pulito.";;
        ERROR)           icon="❌"; label="Qualcosa e' andato storto e mi sono fermato"
                         serve_te="Sì — c'e' un problema che non ho potuto risolvere da solo.";;
        BLOCKED)         icon="🚧"; label="Non posso proseguire da solo"
                         serve_te="Sì — mi manca qualcosa che solo tu puoi darmi o fare.";;
        MISSING)         icon="⚠️"; label="Ho perso il filo e mi sono fermato"
                         serve_te="Sì — il lavoro e' salvo, ma va guardato prima di ripartire.";;
        FAILED)          icon="💥"; label="La sessione si e' interrotta"
                         serve_te="Sì — il lavoro fatto finora e' salvo, ma il pezzo in corso no.";;
        "LIMITE RAGGIUNTO") icon="🏁"; label="Mi sono fermato per prudenza, non perche' ho finito"
                         serve_te="Sì — basta rilanciarmi se resta lavoro da fare.";;
        FERMATO)         icon="🛑"; label="Mi hai chiesto di fermarmi, e mi sono fermato"
                         serve_te="No — l'hai chiesto tu. Riparto da dove siamo quando vuoi.";;
        *)               icon="❓"; label="$status";;
    esac

    # Il nome buono, quello scritto in PROJECT_CONFIG.md: sul telefono "senilcare-backend"
    # non dice niente, "SenilCare" si'. Si guarda sempre la radice, perche' il progetto e'
    # uno anche quando si lavora dentro un suo modulo (il modulo lo dice "su_cosa").
    local project_name; project_name="$(get_project_name "$ROOT_DIR")"
    # In un monorepo, accanto al nome del progetto va il pezzo su cui si e' lavorato.
    # Se e' lo stesso su cui si sta gia' lavorando (--project) non si ripete due volte.
    local su_cosa=""
    local moduli; moduli="$(moduli_toccati)"
    if [[ -n "$moduli" && "$moduli" != "$project_name" ]]; then
        # Un blocco trasversale puo' toccarne otto: sul telefono diventerebbe una riga
        # illeggibile. Se ne mostrano tre e si dice quanti sono gli altri.
        local -a elenco; read -r -a elenco <<< "$moduli"
        if [[ ${#elenco[@]} -gt 3 ]]; then
            su_cosa=" · ${elenco[0]}, ${elenco[1]}, ${elenco[2]} e altri $(( ${#elenco[@]} - 3 ))"
        else
            su_cosa=" · ${moduli// /, }"
        fi
    fi
    local total_fmt block_fmt
    total_fmt="$(format_minutes "$elapsed_total")"
    block_fmt="$(format_minutes "$elapsed_block")"

    # Sezione tempo: per BLOCCO_OK mostra entrambi (blocco + totale), per stop solo il totale
    local time_section
    if [[ "$status" == "BLOCCO_OK" ]]; then
        time_section="⏱ Questo pezzo: ${block_fmt}   ·   Lavoro da stamattina: ${total_fmt}"
    else
        time_section="⏱ Ho lavorato in tutto: ${total_fmt}"
    fi

    # Formatta summary in elenco puntato per leggibilita
    local summary_bullets
    summary_bullets="$(format_summary_as_bullets "$summary")"

    # Avanzamento reale della fase corrente (dalla roadmap): piu' utile del contatore run/tetto.
    local _ph; _ph="$(read_progress_field current_phase)"
    local _pc; _pc="$(phase_counts "${_ph:-0}")"
    local _pd _pt _px; read -r _pd _pt _px <<< "$_pc"
    local progress_line
    if [[ "${_pt:-0}" -gt 0 ]]; then
        local _mancano=$(( _pt - _pd ))
        if [[ "$_mancano" -le 0 ]]; then
            progress_line="📊 Fase ${_ph}: finita, tutti i ${_pt} pezzi fatti"
        elif [[ "$_mancano" -eq 1 ]]; then
            progress_line="📊 Fase ${_ph}: manca l'ultimo pezzo (${_pd} su ${_pt} fatti)"
        else
            progress_line="📊 Fase ${_ph}: ne mancano ${_mancano} (${_pd} su ${_pt} fatti)"
        fi
    else
        progress_line="📊 Pezzo n. ${blocks_run} da quando sono partito"
    fi

    # Il corpo del messaggio e' la riga che l'agente ha scritto PER VILLA, e basta: il
    # riassunto tecnico NON va su Telegram (e' scritto per l'agente del blocco dopo, e a
    # Villa arrivava come mezzo schermo di roba illeggibile). Se PER_VILLA manca — handoff
    # vecchio, o agente che non l'ha compilata — si ripiega sul tecnico: meglio qualcosa di
    # brutto che il silenzio.
    local racconto; racconto="$(parse_handoff_per_villa)"
    [[ -n "$racconto" ]] || racconto="$summary_bullets"
    racconto="$(taglia_per_telefono "$racconto")"

    # Con piu' corsie in parallelo, i messaggi arrivano interlacciati nella stessa sezione
    # del gruppo: senza il nome della corsia in cima non si capisce chi sta parlando.
    local dove_corsia=""; [[ -n "$CORSIA" ]] && dove_corsia=" · corsia ${CORSIA}"

    local msg="${icon} ${project_name}${su_cosa}${dove_corsia}
${label}

${racconto}"

    # "Ti serve?" e' la prima domanda che si fa Villa quando gli vibra il telefono.
    if [[ -n "$serve_te" ]]; then
        msg+="

👉 Devi fare qualcosa?
${serve_te}"
    fi

    # Il prossimo passo. Si toglie il codice del blocco in testa ("Blocco 4.4 — "):
    # a Villa dice solo che c'e' un codice, e la descrizione dopo il trattino e'
    # l'unica parte che gli serve davvero.
    if [[ -n "$next" && "$next" != "Nessuna indicazione" ]]; then
        local next_pulito
        next_pulito="$(printf '%s' "$next" | sed -E 's/^[Bb]locco[[:space:]]+[0-9]+(\.[0-9]+)*[[:space:]]*[-—:]*[[:space:]]*//')"
        msg+="

➡️ Adesso vado a:
${next_pulito}"
    fi

    # A che punto siamo, senza codici: tempo e avanzamento.
    msg+="

${progress_line}
${time_section}"

    # Il conto. Il costo e' quello calcolato dal programma ai prezzi di listino: con
    # l'abbonamento non e' un addebito, e' il valore di quello che si e' consumato.
    if [[ "${TOKEN_CORSA:-0}" -gt 0 ]]; then
        if [[ "$status" == "BLOCCO_OK" && "${TOKEN_BLOCCO:-0}" -gt 0 ]]; then
            msg+="
💰 Questo pezzo: $(formatta_conto "$TOKEN_BLOCCO" "$COSTO_BLOCCO")   ·   da stamattina: $(formatta_conto "$TOKEN_CORSA" "$COSTO_CORSA")"
        else
            msg+="
💰 Consumo di tutta la corsa: $(formatta_conto "$TOKEN_CORSA" "$COSTO_CORSA")"
        fi
    fi

    # Se durante la corsa il guardiano ha deciso qualcosa al posto di Villa, nel messaggio
    # di chiusura si ricorda: le singole decisioni gli sono gia' arrivate una per una, ma
    # quando la corsa finisce deve poterle contare in un colpo d'occhio.
    if [[ -n "${GUARDIANO_DECISIONI:-}" && "$status" != "BLOCCO_OK" ]]; then
        msg+="

🧭 Mentre non c'eri ho deciso io ${GUARDIANO_INTERVENTI} volte per non fermare tutto:
${GUARDIANO_DECISIONI}Le trovi tutte scritte, col perche', nel diario delle decisioni."
    fi

    # Chi ha lavorato. Una riga, in fondo: e' la risposta a una domanda che non ci si fa
    # spesso, ma quando ci si chiede "chi me l'ha scritto?" deve esserci.
    if [[ -n "${MODELLO_AL_LAVORO:-}" ]]; then
        msg+="
🤖 $(nome_agente_leggibile) · $(modello_leggibile "$MODELLO_AL_LAVORO")"
    fi

    # Come riprendere dal telefono. Due righe: le istruzioni passo-passo occupavano mezzo
    # schermo e si ripetevano a ogni stop. Chi vuole il testo da incollare lo trova qui
    # sotto, chi no scorre oltre.
    if [[ "$status" != "BLOCCO_OK" ]]; then
        local project_label; project_label="$(basename "$PROJECT_DIR")"
        msg+="

💡 Per riprendere dal telefono: apri l'app Claude, modalita Dispatch, progetto ${project_label}, e scrivi:
\"Fammi il punto della situazione e dimmi cosa serve per procedere.\""
    fi

    send_telegram "$msg" "$silent"
}

read_file_safe() { local f="$PROJECT_DIR/$1"; [[ -f "$f" ]] && cat "$f" || echo ""; }
# Come read_file_safe, ma dalla RADICE: serve per i file del Metodo, che nei monorepo
# stanno solo in radice e non vanno duplicati in ogni modulo.
read_root_file_safe() { local f="$ROOT_DIR/$1"; [[ -f "$f" ]] && cat "$f" || echo ""; }

# Nome leggibile del progetto, per il banner e il titolo della finestra (distingue piu' runner
# aperti in contemporanea). Lo legge da PROJECT_CONFIG.md ("Nome progetto"); se non lo trova,
# ripiega sul nome della cartella. Senza argomento guarda dove si lavora (PROJECT_DIR);
# il canale Telegram lo chiama sulla radice, perche' la sezione e' una per progetto.
get_project_name() {
    local dir="${1:-$PROJECT_DIR}"
    local n="" cfg="$dir/$PROJECT_CONFIG"
    if [[ -f "$cfg" ]]; then
        n="$(grep -i 'nome progetto' "$cfg" 2>/dev/null | head -1 | sed 's/.*: *//; s/[[:space:]]*$//' || true)"
    fi
    [[ -n "$n" ]] || n="$(basename "$dir")"
    printf '%s' "$n"
}

# --- Avanzamento dalla ROADMAP (checkbox dei blocchi) ---
# Il Metodo Villa marca ogni blocco con "- [ ]" (da fare) o "- [x]" (fatto).
# Le fasi segnaposto (elenco puntato senza checkbox) NON vengono conteggiate.

# Estrae le righe della sezione di una fase fino alla fase successiva (o fine file).
# Il come — le due forme di intestazione, la regola della prima parola — sta in
# `metodo-roadmap.sh` insieme alle corsie: qui si lega soltanto il file del progetto.
extract_phase_section() {
    roadmap_sezione_fase "$PROJECT_DIR/$ROADMAP" "$1"
}

# Quanti blocchi con la casella nello stato richiesto ("todo" o "done").
#
# Quali righe siano un blocco lo decide `metodo-roadmap.sh`, insieme alle corsie. Qui
# resta il conto, e la ragione per cui il conto e' delicato: contare le caselle di una
# forma sola voleva dire, su una roadmap scritta nell'altra, non contare NIENTE — da li'
# usciva un "-1" che spegneva in silenzio due protezioni, lo stop naturale di fine roadmap
# e la rete di sicurezza di --tutte-le-fasi, che senza un numero smetteva di proseguire
# alla fase successiva.
count_boxes() {
    printf '%s\n' "$1" | roadmap_righe_casella "$2" | grep -c . || true
}

# Ritorna "done total todo" contando le caselle nella sezione della fase indicata.
phase_counts() {
    local section; section="$(extract_phase_section "$1")"
    local d t
    d="$(count_boxes "$section" done)"; d="${d:-0}"
    t="$(count_boxes "$section" todo)"; t="${t:-0}"
    echo "$d $((d + t)) $t"
}

# La ROADMAP entra nel messaggio del blocco, ma di utile c'e' solo la fase in corso: le fasi
# chiuse sono zavorra e quelle future non riguardano questo blocco. Il runner riapre l'agente
# da capo ogni volta e il commit di fine blocco impedisce alla cache di agganciare, quindi
# ogni riga di troppo si ripaga per intero tante volte quanti sono i blocchi della corsa.
# Qui si passa: l'intestazione (obiettivo, legenda, convenzioni), la fase in corso per
# intero, e una riga per ciascuna delle altre. Il file resta al suo posto: se all'agente
# serve il resto, lo apre. Se la roadmap non usa "## Fase N" non si indovina: si passa
# tutta, come prima.
estratto_roadmap() {
    local fase="$1" r="$PROJECT_DIR/$ROADMAP"
    [[ -f "$r" ]] || return 0
    local sezione; sezione="$(extract_phase_section "$fase")"
    if [[ -z "$sezione" ]]; then cat "$r"; return 0; fi
    # Le intestazioni si riconoscono nelle due forme, come in extract_phase_section:
    # se qui si guardasse solo "## Fase N", su una roadmap scritta "# 🚧 FASE 49" il
    # risparmio non si spegnerebbe con un errore — passerebbe la roadmap intera a ogni
    # blocco, cioe' il contrario di quello che questo estratto serve a fare.
    awk -v cerca="$ROADMAP_INTESTAZIONE" 'tolower($0) ~ cerca {exit} {print}' "$r"   # tutto cio' che precede la prima fase
    # Della fase in corso si manda tutto, tranne il corpo dei blocchi gia' chiusi: quelli
    # restano col loro titolo. E' la parte piu' grossa del messaggio nei progetti maturi,
    # e non serve a chi deve fare il blocco successivo (vedi roadmap_comprimi_fatti).
    printf '%s\n' "$sezione" | roadmap_comprimi_fatti "$ROADMAP"
    printf '\n'
    echo "--- LE ALTRE FASI (titoli soltanto; se ti servono, apri $ROADMAP) ---"
    local titolo ph d t x
    while IFS= read -r titolo; do
        ph="$(sed -nE 's/^#+[^0-9]*[Ff][Aa][Ss][Ee] ([0-9.]+).*/\1/p' <<< "$titolo")"
        [[ -n "$ph" && "$ph" != "$fase" ]] || continue
        read -r d t x <<< "$(phase_counts "$ph")"
        local nudo; nudo="$(sed -E 's/^#+ *//' <<< "$titolo")"
        if [[ "${t:-0}" -gt 0 ]]; then echo "$nudo — $d/$t fatti"; else echo "$nudo"; fi
    done < <(grep -iE "$ROADMAP_INTESTAZIONE_GREP" "$r")
}

# Conta i blocchi "[ ]" ancora da fare. Con TARGET_PHASE conta solo quella fase,
# altrimenti tutta la roadmap. Ritorna -1 se la roadmap non usa il formato checkbox
# (in quel caso non possiamo dedurre il completamento, quindi non fermiamo il ciclo).
count_remaining_blocks() {
    local r="$PROJECT_DIR/$ROADMAP" content
    [[ -f "$r" ]] || { echo "-1"; return 0; }
    if [[ -n "$TARGET_PHASE" ]]; then content="$(extract_phase_section "$TARGET_PHASE")"; else content="$(cat "$r")"; fi
    local todo done_
    todo="$(count_boxes "$content" todo)"; todo="${todo:-0}"
    done_="$(count_boxes "$content" done)"; done_="${done_:-0}"
    if [[ $((todo + done_)) -eq 0 ]]; then echo "-1"; else echo "$todo"; fi
}

# Quanti blocchi la corsa prevede di fare: la regola e' condivisa, sta in
# metodo-roadmap.sh (previsione_corsa) perche' la usa anche la schermata del runner —
# lo strumento che la contava per conto suo l'avrebbe raccontata diversa, e un annuncio
# sbagliato e' peggio di nessun annuncio.

# "fatti totali" di tutta la roadmap, per il quadro di partenza.
roadmap_counts() {
    local r="$PROJECT_DIR/$ROADMAP"
    [[ -f "$r" ]] || { echo "0 0"; return 0; }
    local content d t
    content="$(cat "$r")"
    d="$(count_boxes "$content" done)"; d="${d:-0}"
    t="$(count_boxes "$content" todo)"; t="${t:-0}"
    echo "$d $((d + t))"
}

# --- Riconoscere un blocco di stop PRIMA di lanciare la sessione ---
# Un blocco 👤 (umano) o 🤝 (collaborativo) non puo' essere eseguito dal runner: serve
# Villa. Accorgersene solo dopo aver lanciato la sessione costa una sessione a vuoto —
# che nel caso peggiore avvia un server di sviluppo e resta appesa fino al timeout.
# Queste tre funzioni leggono l'etichetta dalla ROADMAP e permettono di fermarsi prima.

# Riga della roadmap che descrive il blocco (es. "- [ ] **F4B2** ... 🤝").
roadmap_block_line() {
    local phase="$1" block="$2"; local rm="$PROJECT_DIR/$ROADMAP"
    [[ -f "$rm" ]] || return 0
    # Primo formato: l'identificativo in grassetto sulla riga della casella — "- [ ] **F4B2** ... 🤝"
    local l; l="$(grep -E "\*\*(F${phase})?B${block}\b" "$rm" 2>/dev/null | head -1)"
    [[ -n "$l" ]] && { printf '%s\n' "$l"; return 0; }
    # Secondo formato, quello che usano le roadmap scritte a mano: l'etichetta sta
    # nell'intestazione — "### Blocco 4.2 — titolo 🤝" — e la casella e' la riga dopo.
    # Senza questo, un blocco che chiede Villa veniva eseguito lo stesso: la riga non si
    # trovava, e "in dubbio si prosegue" faceva il resto.
    local id="$block"; [[ "$id" == *.* ]] || id="${phase}.${block}"
    # "|| true": lo script gira con set -e, e un grep che non trova nulla lo farebbe morire
    # in silenzio. Qui "non trovato" e' una risposta legittima, non un errore.
    grep -E "^#+[[:space:]]*Blocco[[:space:]]+${id//./\\.}([^0-9.]|$)" "$rm" 2>/dev/null | head -1 || true
}

# "yes" se il blocco risulta gia' spuntato [x] in roadmap. In dubbio (riga assente) si
# risponde "no": la roadmap e' l'unica fonte, e senza riga non si puo' affermare nulla.
block_is_done() {
    local line; line="$(roadmap_block_line "$1" "$2")"
    [[ -z "$line" ]] && { echo "no"; return; }
    if printf '%s' "$line" | grep -qiE '\[x\]'; then echo "yes"; else echo "no"; fi
}

# "yes" se il blocco e' uno stop per Villa, "no" altrimenti. In dubbio (riga assente) si
# lascia proseguire: meglio una sessione in piu' che una corsa autonoma bloccata a torto.
block_is_checkpoint() {
    # Tutte e due le righe. Il 2026-08-15 si e' visto che un blocco 🤝 con la casella in
    # grassetto NON veniva riconosciuto come stop: l'etichetta stava sull'intestazione e qui
    # si leggeva solo la casella. Il runner se lo sarebbe eseguito da solo — che e'
    # esattamente il caso che il commento qui sotto dichiarava di coprire, e copriva a meta'.
    local line; line="$(roadmap_block_context "$1" "$2")"
    [[ -z "${line//[[:space:]]/}" ]] && { echo "no"; return; }
    # Discriminante: la parola CHECKPOINT oppure le etichette 🤝 / 👤.
    # NB: 🤖 (autonomo) e "✅ GATE" NON fermano il runner.
    if printf '%s' "$line" | grep -qiE 'CHECKPOINT' \
        || printf '%s' "$line" | grep -qF '🤝' \
        || printf '%s' "$line" | grep -qF '👤'; then
        echo "yes"
    else
        echo "no"
    fi
}

# Quanto si puo' uscire dal seminato su UN blocco (cap. 05): il livello della corsa, tranne
# sui blocchi di peso cruciale, dove si stringe da solo — li' una cosa in piu' non vista
# costa troppo. Sta in una funzione sua per poterla provare senza far girare il ciclo.
liberta_del_blocco() {
    local peso="$1" liv="$2"
    [[ "$peso" == "cruciale" ]] && { echo "stretto"; return; }
    echo "$liv"
}

# Il peso del blocco: "cruciale", "importante", "ordinario", oppure vuoto se non c'e'
# scritto. Vuoto NON e' un errore ed e' il caso normale: nessuna roadmap scritta prima del
# 2026-08-15 ha i pesi, e quelle roadmap devono continuare a lavorare come hanno sempre
# fatto — col motore scelto per la corsa.
# Si accetta l'emoji (come per la natura del blocco) oppure la parola scritta: le roadmap
# le scrivono anche i modelli, e farsi capire costa meno che farsi ubbidire.
# TUTTE le righe che parlano di un blocco: la casella E l'intestazione.
# roadmap_block_line ne restituisce UNA sola, e quando la casella porta l'identificativo in
# grassetto restituisce quella — ma le etichette (natura e peso) chi scrive le roadmap le
# mette sull'INTESTAZIONE. Chi cerca un'etichetta deve guardarle tutte e due: su una roadmap
# che ha entrambe le forme, cercarne una sola vuol dire non trovarla e non dirlo a nessuno.
roadmap_block_context() {
    local righe; righe="$(roadmap_block_line "$1" "$2")"
    local id="$2"; [[ "$id" == *.* ]] || id="${1}.${2}"
    local rm="$PROJECT_DIR/$ROADMAP"
    [[ -f "$rm" ]] && righe+=$'\n'"$(grep -E "^#+[[:space:]]*Blocco[[:space:]]+${id//./\\.}([^0-9.]|$)" "$rm" 2>/dev/null | head -1 || true)"
    printf '%s' "$righe"
}

block_peso() {
    local line; line="$(roadmap_block_context "$1" "$2")"
    [[ -z "${line//[[:space:]]/}" ]] && return 0
    if   printf '%s' "$line" | grep -qF '🔴' || printf '%s' "$line" | grep -qiE '\bcruciale\b';   then echo "cruciale"
    elif printf '%s' "$line" | grep -qF '🟡' || printf '%s' "$line" | grep -qiE '\bimportante\b'; then echo "importante"
    elif printf '%s' "$line" | grep -qF '🟢' || printf '%s' "$line" | grep -qiE '\bordinario\b';  then echo "ordinario"
    fi
    return 0
}

# Titolo leggibile del blocco (il testo tra i primi **...**), per i messaggi di notifica.
roadmap_block_title() {
    local phase="$1" block="$2"; local rm="$PROJECT_DIR/$ROADMAP"
    [[ -f "$rm" ]] || { echo ""; return 0; }
    local t; t="$(grep -oE "\*\*(F${phase})?B${block}\b[^*]*\*\*" "$rm" 2>/dev/null | head -1 | sed 's/\*\*//g' || true)"
    # Se l'identificativo non e' in grassetto, il titolo sta nell'intestazione:
    # "### Blocco 4.2 — questo lo vede Villa 🤝" -> "questo lo vede Villa 🤝".
    if [[ -z "$t" ]]; then
        local l; l="$(roadmap_block_line "$phase" "$block" || true)"
        t="$(printf '%s' "$l" | sed -E 's/^#+[[:space:]]*//; s/^Blocco[[:space:]]+[0-9.]+[[:space:]]*[—–-]*[[:space:]]*//' || true)"
    fi
    printf '%s' "$t"
    return 0   # "titolo non trovato" e' una risposta, non un errore: con set -e lo diventava
}

# Scrive un handoff di stop pulito al checkpoint, cosi' handoff e progress.json restano
# coerenti (e un --resume successivo riparte da uno stato sensato). Sostituisce l'handoff
# del blocco precedente, che diceva CONTINUE: ora lo stato reale e' "fermo, tocca a Villa".
write_checkpoint_handoff() {
    local phase="$1" block="$2" title="$3"; local h="$PROJECT_DIR/$HANDOFF_FILE"
    mkdir -p "$(dirname "$h")"
    {
        echo "STATUS: CHECKPOINT"
        echo "PHASE: $phase"
        echo "BLOCK: $block"
        echo "SUMMARY: Il runner si e' fermato PRIMA di lanciare la sessione: il blocco $block e' marcato come checkpoint nella ROADMAP (serve l'occhio o la decisione di Villa). Nessun codice eseguito, nessun processo lasciato attivo."
        echo "NEXT: ${title:-Blocco $block (checkpoint)}"
        echo "PER_VILLA: Mi sono fermato prima di cominciare questo pezzo, perche' e' uno di quelli che devi guardare tu. Non ho toccato niente. Quando gli hai dato un'occhiata, fammelo sapere e riparto."
        echo "DECISIONS_NEEDED: Villa valida il blocco in sessione live. Alla chiusura, aggiornare BLOCK al blocco successivo prima di rilanciare il runner."
        echo "TESTS: SKIPPED"
    } > "$h"
}

init_progress() {
    local p="$PROJECT_DIR/$PROGRESS_FILE"
    [[ -f "$p" ]] && return; mkdir -p "$(dirname "$p")"
    cat > "$p" << 'EOF'
{
  "current_phase": 0,
  "current_block": 0,
  "blocks_completed": [],
  "total_blocks_run": 0,
  "status": "ready",
  "last_run": null
}
EOF
}

read_progress_field() {
    local p="$PROJECT_DIR/$PROGRESS_FILE"
    if [[ ! -f "$p" ]]; then echo ""; return; fi
    # Estrae il valore del campo usando il nome come ancora (non greedy)
    local val
    val="$(sed -n "s/.*\"$1\" *: *\([^,}]*\).*/\1/p" "$p" | head -1 | sed 's/[" ]//g')"
    # Se il valore è "null" o vuoto, restituisci stringa vuota
    if [[ "$val" == "null" || -z "$val" ]]; then
        echo ""
    else
        echo "$val"
    fi
}

update_progress() {
    local p="$PROJECT_DIR/$PROGRESS_FILE" ts; ts="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"; local t; t="$(read_progress_field total_blocks_run)"; t="${t:-0}"; t=$((t+1))
    local summary; summary="$(echo "$4" | head -1 | sed 's/"/\\"/g')"
    printf '{\n  "current_phase": "%s",\n  "current_block": "%s",\n  "total_blocks_run": %s,\n  "status": "%s",\n  "last_run": "%s",\n  "last_summary": "%s"\n}\n' \
        "$1" "$2" "$t" "$3" "$ts" "$summary" > "$p"
}

append_session_log() {
    local l="$PROJECT_DIR/$SESSION_LOG" ts; ts="$(date '+%Y-%m-%d %H:%M:%S')"; mkdir -p "$(dirname "$l")"
    [[ -f "$l" ]] || echo -e "# Session Log — Metodo Villa Runner\n---\n" > "$l"
    echo -e "\n## $ts — Blocco $1\n- **Status**: $2\n- **Summary**: $3" >> "$l"
    # La riga in italiano di tutti i giorni resta scritta anche qui. Su Telegram la
    # sovrascrive il blocco dopo, e nell'archivio resterebbe solo il riassunto tecnico —
    # che serve all'agente della corsa successiva, non a chi ripercorre una notte di lavoro.
    # Arriva come argomento e NON si rilegge da sola dall'handoff: quando un blocco fallisce
    # l'handoff non e' stato riscritto, e si archivierebbe il racconto del blocco precedente
    # sotto il blocco sbagliato. Chi non ce l'ha (fallimenti, diari vecchi) non stampa niente.
    [[ -n "${4:-}" ]] && echo "- **Per Villa**: $4" >> "$l"
    # Il conto del blocco resta scritto qui: e' cosi' che, a fine fase, si possono guardare
    # i tre blocchi piu' cari e chiedersi perche' (di solito erano tagliati male).
    [[ "${TOKEN_BLOCCO:-0}" -gt 0 ]] && echo "- **Consumo**: $(formatta_conto "$TOKEN_BLOCCO" "$COSTO_BLOCCO")${MODELLO_AL_LAVORO:+ · $(modello_leggibile "$MODELLO_AL_LAVORO")}" >> "$l"
    # Quinto argomento (facoltativo): le righe di dettaglio gia' formate — motore, durata,
    # file toccati, esito della verifica. Le costruisce dettagli_chiusura_blocco, che sa
    # COSA va scritto; qui si scrive e basta. Vuoto = la voce resta come e' sempre stata.
    [[ -n "${5:-}" ]] && printf '%s\n' "$5" >> "$l"
    echo "---" >> "$l"
}

parse_handoff_status() { local h="$PROJECT_DIR/$HANDOFF_FILE"; [[ -f "$h" ]] && grep -i "^STATUS:" "$h" | head -1 | sed 's/^STATUS: *//; s/ *$//' | tr '[:lower:]' '[:upper:]' || echo "MISSING"; }
parse_handoff_summary() { local h="$PROJECT_DIR/$HANDOFF_FILE"; [[ -f "$h" ]] && sed -n '/^SUMMARY:/,/^\(NEXT:\|DECISIONS_NEEDED:\|FILES_MODIFIED:\|TESTS:\|---\)/p' "$h" | head -5 | sed '1s/^SUMMARY: *//; $d' || echo "Nessun handoff"; }
parse_handoff_phase() { local h="$PROJECT_DIR/$HANDOFF_FILE"; [[ -f "$h" ]] && grep -i "^PHASE:" "$h" | head -1 | sed 's/^PHASE: *//; s/ *$//' || echo ""; }
parse_handoff_block() { local h="$PROJECT_DIR/$HANDOFF_FILE"; [[ -f "$h" ]] && grep -i "^BLOCK:" "$h" | head -1 | sed 's/^BLOCK: *//; s/ *$//' || echo ""; }
parse_handoff_next() { local h="$PROJECT_DIR/$HANDOFF_FILE"; [[ -f "$h" ]] && grep -i "^NEXT:" "$h" | head -1 | sed 's/^NEXT: *//; s/ *$//' || echo ""; }
# La riga scritta PER VILLA, in italiano di tutti i giorni. E' quella che finisce
# su Telegram: SUMMARY e NEXT restano per l'agente della corsa successiva, che ha
# bisogno di nomi di file e codici di blocco — Villa no.
parse_handoff_per_villa() { local h="$PROJECT_DIR/$HANDOFF_FILE"; [[ -f "$h" ]] && sed -n '/^PER_VILLA:/,/^[A-Z_]*:/p' "$h" | sed '1s/^PER_VILLA: *//; ${/^[A-Z_]*:/d}' | sed '/^$/d' | head -4 || echo ""; }
# Com'e' andata la verifica di fine blocco (PASS | FAIL | SKIPPED), scritta dall'agente.
parse_handoff_tests() { local h="$PROJECT_DIR/$HANDOFF_FILE"; [[ -f "$h" ]] && grep -i "^TESTS:" "$h" | head -1 | sed 's/^TESTS: *//; s/ *$//' || echo ""; }

# --- IL RECORD DEL "MENTRE LAVORA" ------------------------------------------------------
# La schermata del runner ha un momento DURANTE (blocco in corso + cronologia della
# corsa), ma quelle informazioni esistevano solo nella testa del runner: la pagina le
# avrebbe cercate invano. Qui vengono lasciate scritte in un file che il servitore legge
# senza interpretare niente (regola del 5.4: chi sta in mezzo non decide). Una corsa = un
# file, riscritto a ogni giro: chi lo legge trova sempre e solo la fotografia di adesso.

_json_escape() { printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g' | tr '\n' ' '; }

# Quando la corsa e' partita, detto una volta sola: tutte le riscritture del file (a ogni
# blocco, a fine blocco) devono portare la STESSA data, o la cronologia non saprebbe piu'
# da dove comincia questa corsa.
DURANTE_CORSA_INIZIATA=""

# Chi legge il record deve poter rispondere a una domanda sola: questa corsa sta ancora
# girando? La data di fine non basta — un runner ucciso di forza non fa in tempo a
# scriverla. Serve il numero del processo, e serve quello che conosce il sistema
# operativo: dentro Git for Windows il numero della shell e' un altro, e chi guarda da
# fuori (la schermata, che e' un programma Python) cercherebbe un processo inesistente.
_numero_di_processo() {
    local n=""
    [[ -r "/proc/$$/winpid" ]] && n="$(cat "/proc/$$/winpid" 2>/dev/null)"
    printf '%s' "${n:-$$}"
}

# All'avvio della corsa: quando parte, chi la sta facendo girare e quanti blocchi prevede.
# Di blocco in corso non c'e' ancora niente — e il file lo dice, invece di non esserci.
# $1 = data di fine, se la corsa e' finita ("" finche' sta girando).
scrivi_durante_corsa() {
    [[ -z "$DURANTE_CORSA_INIZIATA" ]] && DURANTE_CORSA_INIZIATA="$(date '+%Y-%m-%d %H:%M:%S')"
    local finita="${1:-}" fine="null"
    [[ -n "$finita" ]] && fine="\"$finita\""
    local f="$PROJECT_DIR/$DURANTE_FILE" prev="null"
    mkdir -p "$(dirname "$f")"
    [[ "${PREVISTI_ALLA_PARTENZA:-}" =~ ^[0-9]+$ ]] && prev="$PREVISTI_ALLA_PARTENZA"
    printf '{\n  "corsa": {"iniziata_il": "%s", "previsti": %s, "pid": %s, "finita_il": %s},\n  "in_corso": null\n}\n' \
        "$DURANTE_CORSA_INIZIATA" "$prev" "$(_numero_di_processo)" "$fine" > "$f"
    return 0
}

# All'avvio del blocco: chi ci lavora, con che impegno, da quando, dov'e' nella previsione
# e quanto si e' speso finora. $3 = posizione nella previsione ("" se oltre o ignota:
# meglio un buco che un numero senza senso, regola gia' del quadro a schermo).
scrivi_durante_blocco() {
    local bid="$1" titolo="$2" posizione="${3:-}"
    local f="$PROJECT_DIR/$DURANTE_FILE" prev="null" pos="null"
    mkdir -p "$(dirname "$f")"
    [[ "${PREVISTI_ALLA_PARTENZA:-}" =~ ^[0-9]+$ ]] && prev="$PREVISTI_ALLA_PARTENZA"
    [[ "$posizione" =~ ^[0-9]+$ ]] && pos="$posizione"
    local modello="null" peso="null" promosso="false"
    [[ -n "${MODEL_OVERRIDE:-}" ]] && modello="\"$(_json_escape "$MODEL_OVERRIDE")\""
    [[ -n "${BLOCCO_PESO:-}" ]] && peso="\"$BLOCCO_PESO\""
    [[ -n "${BLOCCO_PROMOSSO:-}" ]] && promosso="true"
    [[ -z "$DURANTE_CORSA_INIZIATA" ]] && DURANTE_CORSA_INIZIATA="$(date '+%Y-%m-%d %H:%M:%S')"
    # Niente heredoc: il JSON finirebbe con una graffa a colonna zero, e chi estrae le
    # funzioni per le prove (sed fino alla prima graffa) taglierebbe la funzione a meta'.
    printf '{\n  "corsa": {"iniziata_il": "%s", "previsti": %s, "pid": %s, "finita_il": null},\n  "in_corso": {\n    "blocco": "%s",\n    "titolo": "%s",\n    "motore": "%s",\n    "agente": "%s",\n    "modello": %s,\n    "impegno": "%s",\n    "peso": %s,\n    "promosso": %s,\n    "iniziato_il": "%s",\n    "posizione": %s,\n    "previsti": %s,\n    "speso_token": %s,\n    "speso_costo": %s\n  }\n}\n' \
        "$DURANTE_CORSA_INIZIATA" "$prev" "$(_numero_di_processo)" \
        "$(_json_escape "$bid")" "$(_json_escape "$titolo")" "$(_json_escape "$(nome_agente_leggibile)")" \
        "${AGENTE:-claude}" "$modello" "${IMPEGNO:-high}" "$peso" "$promosso" \
        "$(date '+%Y-%m-%d %H:%M:%S')" "$pos" "$prev" "${TOKEN_CORSA:-0}" "${COSTO_CORSA:-0}" > "$f"
    return 0
}

# A blocco finito nessun blocco e' piu' in corso: il record resta (la corsa c'e' ancora),
# ma dice la verita' — adesso non sta girando niente. E' la stessa scrittura dell'avvio:
# un file solo, una forma sola.
scrivi_durante_pausa() {
    [[ -n "$DURANTE_CORSA_INIZIATA" ]] || return 0
    scrivi_durante_corsa
}

# La corsa e' finita: da adesso il record non deve piu' far credere a nessuno che qui
# stia girando qualcosa. Si chiama anche quando il runner viene interrotto (trap), che e'
# il caso in cui serve davvero: senza, la schermata rifiuterebbe di lanciarne un'altra.
scrivi_durante_fine() {
    [[ -n "$DURANTE_CORSA_INIZIATA" ]] || return 0
    scrivi_durante_corsa "$(date '+%Y-%m-%d %H:%M:%S')"
}

# --- LA RICHIESTA DI FERMARSI -----------------------------------------------------------
# La schermata non uccide il runner: lascia un file, e il runner lo trova FRA un blocco e
# l'altro. Cosi' "ferma" non vuol mai dire "tronca a meta'": il blocco in corso arriva
# alla sua verifica e al suo commit, e la corsa si chiude su un progetto intero.

# Un file rimasto li' da una corsa di ieri fermerebbe quella di oggi prima ancora che
# cominci: si toglie di mezzo alla partenza, non alla fine (una corsa uccisa di forza non
# arriva alla fine).
dimentica_richiesta_di_fermarsi() { rm -f "$PROJECT_DIR/$FERMA_FILE" 2>/dev/null || true; }

# Vero UNA SOLA VOLTA: la richiesta si consuma leggendola, cosi' la corsa successiva
# parte pulita anche se questa muore prima di poterlo fare.
fermarsi_e_stato_chiesto() {
    [[ -f "$PROJECT_DIR/$FERMA_FILE" ]] || return 1
    rm -f "$PROJECT_DIR/$FERMA_FILE" 2>/dev/null || true
    return 0
}

# Cosa il diario di sessione non sapeva dire di un blocco chiuso: con che motore si e'
# lavorato, quanto e' durato, quali file sono cambiati, com'e' andata la verifica. Sono
# le righe che la cronologia della schermata mostrera' nel dettaglio di un riquadro —
# e intanto le legge chi riapre il diario. Stampa le righe gia' formate ("- **X**: ..."),
# una per riga; quello che non c'e' non lascia un'etichetta a vuoto.
# $1 = minuti di durata (vuoto = non si sa); $2 = "si" se l'handoff si puo' leggere —
# quando un blocco FALLISCE l'handoff non e' stato riscritto, e leggerci la verifica
# vorrebbe dire attribuire a questo blocco l'esito di un altro (stessa trappola della
# riga per Villa, vedi append_session_log).
dettagli_chiusura_blocco() {
    local durata="${1:-}" leggi_handoff="${2:-si}"
    local righe="" motore; motore="$(nome_agente_leggibile)"
    [[ -n "${MODELLO_AL_LAVORO:-}" ]] && motore="$motore · $(modello_leggibile "$MODELLO_AL_LAVORO")"
    motore="$motore · impegno ${IMPEGNO:-high}"
    # Il peso entra solo se ha davvero deciso il motore (instradamento acceso e riuscito):
    # altrimenti dire "peso tanto" accanto al motore della corsa spiegherebbe una scelta
    # che non c'e' stata. "Promosso" vuol dire: questo blocco aveva gia' sbagliato una
    # volta, e rifarlo e' salito di un gradino (cap. 22).
    [[ -n "${BLOCCO_PESO:-}" ]] && motore="$motore · peso ${BLOCCO_PESO}"
    [[ -n "${BLOCCO_PROMOSSO:-}" ]] && motore="$motore · promosso dopo l'errore"
    righe="- **Motore**: $motore"
    [[ "$durata" =~ ^[0-9]+$ ]] && righe="$righe"$'\n'"- **Durata**: ${durata} min"
    # I file toccati si contano da dove era il progetto a dove e' arrivato: dedurli dal
    # testo del blocco vorrebbe dire indovinare. I diari della corsa ci finiscono sempre
    # e non dicono niente su cosa e' stato costruito: fuori.
    if [[ -n "${HEAD_PRIMA_DEL_BLOCCO:-}" ]]; then
        local tutti n
        tutti="$(git -C "$ROOT_DIR" diff --name-only "$HEAD_PRIMA_DEL_BLOCCO..HEAD" 2>/dev/null | grep -v '^docs/diario/' || true)"
        n="$(printf '%s\n' "$tutti" | sed '/^$/d' | wc -l | tr -d ' ')"
        if [[ "$n" -gt 0 ]]; then
            local elenco="$tutti" extra=""
            if [[ "$n" -gt 8 ]]; then
                elenco="$(printf '%s\n' "$tutti" | head -8)"; extra=", +$(( n - 8 )) altri"
            fi
            righe="$righe"$'\n'"- **File**: $(printf '%s\n' "$elenco" | tr '\n' ',' | sed 's/,$//; s/,/, /g')$extra"
        fi
    fi
    if [[ "$leggi_handoff" == "si" ]]; then
        local v; v="$(parse_handoff_tests)"
        [[ -n "$v" ]] && righe="$righe"$'\n'"- **Verifica**: $v"
    fi
    printf '%s' "$righe"
    return 0
}

check_git_branch() {
    git -C "$PROJECT_DIR" rev-parse --git-dir &>/dev/null || { log "${YELLOW}Non è un repo git${NC}"; return 0; }
    local b; b="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)"
    [[ "$b" == "main" || "$b" == "master" ]] && die "Sei su '$b'! Lavora su 'develop' o branch di blocco."
    log_verbose "Branch: ${GREEN}$b${NC}"
    local d; d="$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null)"; if [[ -n "$d" ]]; then log "${YELLOW}Modifiche non committate${NC}"; fi
}

# Pusha il branch corrente su origin. Usa -u al primo push (upstream non configurato).
# Protezione: rifiuta main/master. Non fatale in caso di errore (logga e prosegue).
# Da chiamare SOLO dopo un blocco completato con test verdi (stato stabile).
push_current_branch() {
    git -C "$PROJECT_DIR" rev-parse --git-dir &>/dev/null || return 0
    local b; b="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null)"
    if [[ -z "$b" ]]; then
        log "${YELLOW}Push saltato: detached HEAD${NC}"
        return 0
    fi
    if [[ "$b" == "main" || "$b" == "master" ]]; then
        log "${YELLOW}Push saltato: branch protetto ($b)${NC}"
        return 0
    fi
    # Verifica se il branch ha gia un upstream configurato
    local has_upstream=false
    if git -C "$PROJECT_DIR" rev-parse --abbrev-ref --symbolic-full-name "@{u}" &>/dev/null; then
        has_upstream=true
    fi
    log "${BLUE}Push $b -> origin...${NC}"
    local push_out push_ec=0
    if $has_upstream; then
        push_out="$(git -C "$PROJECT_DIR" push origin "$b" 2>&1)" || push_ec=$?
    else
        push_out="$(git -C "$PROJECT_DIR" push -u origin "$b" 2>&1)" || push_ec=$?
    fi
    if [[ $push_ec -eq 0 ]]; then
        log "${GREEN}Push OK ($b)${NC}"
        log_verbose "$push_out"
    else
        log "${YELLOW}Push fallito (ec=$push_ec) — runner prosegue, lavoro salvo in locale${NC}"
        log_verbose "$push_out"
        # Notifica Telegram solo se configurata, non blocca
        send_telegram "⚠️ Runner: push $b fallito (ec=$push_ec). Lavoro salvo in locale, verifica al risveglio."
    fi
    return 0
}

# Le competenze del Metodo (.claude/skills/) sono file di istruzioni che Claude Code apre da
# solo quando servono. Gli altri agenti non sanno nemmeno che esistono: senza questo elenco
# eseguirebbero i blocchi di frontend ignorando il seeding visivo, e chiuderebbero i blocchi
# senza la checklist di chiusura. Si passa l'ELENCO, non il contenuto: i file interi
# gonfierebbero il messaggio a dismisura, e l'agente sa leggere da solo.
# Nei monorepo le competenze stanno nella radice, non nel modulo: si guarda sempre ROOT_DIR.
elenco_competenze() {
    local d="$ROOT_DIR/.claude/skills" f nome desc
    [[ -d "$d" ]] || return 0
    for f in "$d"/*/SKILL.md; do
        [[ -f "$f" ]] || continue
        nome="$(basename "$(dirname "$f")")"
        desc="$(grep -m1 '^description:' "$f" 2>/dev/null | sed 's/^description: *//; s/^"//; s/"[[:space:]]*$//' | cut -c1-200)"
        echo "- ${nome}: ${desc}"
        echo "  istruzioni complete in .claude/skills/${nome}/SKILL.md"
    done
}

# Cerca nell'indirizzario dei precedenti (cap. 28) qualcosa che somigli a questo blocco.
# Il momento e' questo: all'apertura si e' ancora in tempo a decidere di non riscrivere un
# pezzo che esiste gia' altrove. A file scritti non servirebbe piu'. Se non c'e' python,
# se manca la cartella o se nessuna voce combacia, non stampa niente e il messaggio resta
# identico a prima.
precedenti_del_blocco() {
    local phase="$1" block="$2" titolo
    titolo="$(roadmap_block_title "$phase" "$block" 2>/dev/null || true)"
    [[ -z "$titolo" ]] && return 0
    METODO_RADICE="$ROOT_DIR" python "$ROOT_DIR/metodo/cerca-precedenti.py" "$titolo" 2>/dev/null || true
}

build_prompt() {
    local phase="$1" block="$2" handoff="$3" first="$4" prompt=""
    # RIPARAZIONE NELLA STESSA SESSIONE (cap. 05). Il blocco che l'agente ha appena chiuso
    # non e' finito, ma l'agente e' ancora li' con tutto il lavoro in testa e il codice e'
    # gia' committato: non si butta niente e non si ricomincia. Si ripara UN punto.
    if [[ -n "${OCCHIO_ESTERNO_MOTIVO:-}" && -n "${SESSIONE_DA_RIPRENDERE:-}" ]]; then
        occhio_esterno_messaggio_di_riparazione "$phase" "$block"
        return 0
    fi
    # STESSA SESSIONE: regole, contesto del progetto e roadmap sono GIA' nella conversazione.
    # Ripeterli sarebbe esattamente la spesa che questo meccanismo esiste per evitare (~30.000
    # unita' a blocco). Si passa solo cio' che e' cambiato: quale blocco tocca adesso, e
    # quanto spazio resta nella memoria di lavoro.
    if [[ -n "${SESSIONE_DA_RIPRENDERE:-}" ]]; then
        prompt+="--- BLOCCO SUCCESSIVO, STESSA SESSIONE ---"$'\n'
        prompt+="Hai appena chiuso un blocco con i test verdi. Le regole del Metodo, il contesto del progetto e la roadmap li hai GIA' davanti in questa conversazione: non rileggerli e non ripartire da capo."$'\n\n'
        prompt+="Adesso esegui il blocco $block della fase $phase."$'\n'
        local _t; _t="$(roadmap_block_title "$phase" "$block")"
        [[ -n "$_t" ]] && prompt+="Di che si tratta: $_t"$'\n'
        local _p; _p="$(precedenti_del_blocco "$phase" "$block")"
        [[ -n "$_p" ]] && prompt+=$'\n'"$_p"$'\n'
        prompt+=$'\n'"MEMORIA DI LAVORO: sei al ${CONTESTO_PERCENTO}% della finestra, il tetto e' ${CONTESTO_SOGLIA_TETTO}%. Se lavorando lo superi, porta a termine quello che hai in mano e chiudi il blocco al PRIMO punto pulito — test verdi, diario aggiornato, commit fatto. Non cominciarne un altro."$'\n\n'
        prompt+="Resta valido tutto il resto: la verifica obbligatoria prima di chiudere, l'aggiornamento di $HANDOFF_FILE (compreso PER_VILLA) e della ROADMAP, il commit. Il formato dell'handoff e' quello di prima."$'\n'
        echo "$prompt"
        return 0
    fi
    # Il Metodo si legge SEMPRE dalla radice: un modulo di monorepo non lo duplica, lo eredita.
    # Claude Code il CLAUDE.md della cartella di lavoro lo carica da se' (e con lui l'@import
    # del file operativo): riscriverlo qui vorrebbe dire mandarlo due volte, e con lui tutte
    # le regole del Metodo. Nei monorepo si lavora dentro un modulo e non e' scontato che il
    # CLAUDE.md della radice arrivi: li' si passa, come prima. Gli altri programmi non
    # caricano niente da soli, quindi lo ricevono sempre.
    local c
    if [[ "$AGENTE" != "claude" || "$PROJECT_DIR" != "$ROOT_DIR" ]]; then
        c="$(read_root_file_safe "$CLAUDE_MD")"; [[ -n "$c" ]] && prompt+="$c"$'\n\n'
    fi
    # Regole specifiche del modulo: si sommano a quelle della radice, solo se si lavora su un modulo.
    if [[ "$PROJECT_DIR" != "$ROOT_DIR" ]]; then
        c="$(read_file_safe "$CLAUDE_MD")"; [[ -n "$c" ]] && prompt+="--- REGOLE SPECIFICHE DEL MODULO ($(basename "$PROJECT_DIR")) ---"$'\n'"$c"$'\n\n'
    fi
    c="$(read_file_safe "$PROJECT_CONFIG")"; [[ -n "$c" ]] && prompt+="--- CONTESTO PROGETTO ---"$'\n'"$c"$'\n\n'
    # L'ORDINE DI QUESTO MESSAGGIO NON E' CASUALE — e non si rimescola.
    # I fornitori tengono da parte il testo gia' visto e lo fanno pagare una frazione, ma solo
    # finche' resta un PREFISSO identico: appena una virgola cambia, tutto cio' che segue e'
    # perduto. Percio' da qui in giu' viene prima cio' che non cambia mai (competenze e
    # istruzioni del runner), poi cio' che cambia a ogni blocco (roadmap, stato, handoff).
    # Prima del 2026-08-16 era il contrario: le due parti piu' lunghe stavano in fondo e si
    # ripagavano intere ogni volta. Sulla console di Moonshot si vedeva il risultato: 652 $
    # di memoria contro 203 $ di ragionamento in un mese, su un progetto solo.
    # Solo per gli agenti che non le caricano da soli: Claude Code le trova per conto suo e
    # riceverebbe l'elenco due volte.
    if [[ "$AGENTE" != "claude" ]]; then
        local competenze; competenze="$(elenco_competenze)"
        if [[ -n "$competenze" ]]; then
            prompt+="--- LE COMPETENZE DEL METODO (leggile quando servono) ---"$'\n'
            prompt+="Questo progetto porta con se' delle competenze: procedure gia' scritte per lavori ricorrenti."$'\n'
            prompt+="Quando il blocco che stai eseguendo rientra in una di queste, APRI il file indicato e SEGUILO."$'\n'
            prompt+="Non sono suggerimenti: dove esiste una competenza, quella e' la procedura del Metodo."$'\n\n'
            prompt+="$competenze"$'\n\n'
        fi
    fi
    prompt+="--- ISTRUZIONI RUNNER (OBBLIGATORIE) ---"$'\n'
    prompt+="Sei in sessione automatizzata Metodo Villa. Villa NON è un programmatore e NON verificherà il tuo codice."$'\n'
    prompt+="La qualità e la correttezza sono INTERAMENTE responsabilità tua."$'\n\n'
    prompt+="WORKFLOW BLOCCO:"$'\n'
    # Le regole sono gia' in questo messaggio (o caricate all'avvio da Claude Code): ordinare
    # di rileggerle significava farsi ripagare gli stessi file due volte, a ogni blocco.
    if [[ "$AGENTE" == "claude" ]]; then
        prompt+="1. Le regole del Metodo e del progetto (CLAUDE.md, .claude/metodo-villa/00-CLAUDE-OPERATIVO.md, PROJECT_CONFIG.md) sono GIA' davanti a te: applicale, NON rileggerle. Del manuale .claude/metodo-villa/ apri solo il capitolo che serve a QUESTO blocco, e solo se serve. Poi guarda l'handoff precedente e i file del blocco."$'\n'
    else
        prompt+="1. Leggi .claude/metodo-villa/00-CLAUDE-OPERATIVO.md (le regole del Metodo, sez. 1-14): il tuo programma non lo carica da solo. CLAUDE.md e PROJECT_CONFIG.md li hai gia' qui sopra: non rileggerli. Del resto del manuale apri solo il capitolo che serve a QUESTO blocco."$'\n'
    fi
    prompt+="2. Esegui UN blocco dalla roadmap"$'\n'
    prompt+="2bis. SE il blocco riguarda il FRONTEND (interfaccia utente, web o mobile): PRIMA di generare o modificare codice UI, attiva la skill di seeding visivo adatta — seeding-visivo-web per il web (React/Vite/Tailwind/shadcn), seeding-visivo-mobile per Flutter (Material 3) — e rispettane il system-prompt anti-piattezza, i token del tema e le golden pages/screens. Cosi i frontend nascono curati, non piatti. Se la palette NON e' ancora stata co-progettata con Villa (fase 🤝), applica lo skin/preset DEFAULT neutro e NON inventare colori in autonomia (regola di autonomia)."$'\n'
    prompt+="2ter. SE per verificare devi ACCENDERE UN PROGRAMMA CHE RESTA ACCESO (un servitore, un'anteprima, un emulatore): NON lanciarlo a mano. Un comando che non torna indietro ferma il blocco, e un processo che sopravvive tiene la porta occupata e fa fallire il blocco dopo. Usa: bash metodo/con-servitore.sh <porta> <secondi> -- <comando che accende> -- <comando di prova>. Accende, aspetta che la porta risponda, esegue la prova e spegne sempre, anche se la prova fallisce."$'\n'
    prompt+="3. VERIFICA OBBLIGATORIA prima di chiudere il blocco:"$'\n'
    prompt+="   a) Esegui TUTTI i test del progetto (non solo quelli nuovi)"$'\n'
    prompt+="   b) Verifica che il build compili senza errori"$'\n'
    prompt+="   c) Rileggi ogni file che hai modificato e verifica: logica corretta? edge case gestiti? coerente col resto della codebase?"$'\n'
    prompt+="   d) Controlla che le regole di sicurezza del progetto siano rispettate"$'\n'
    prompt+="   e) Se hai toccato aree critiche: attenzione doppia, verifica incrociata"$'\n'
    prompt+="   f) Se QUALSIASI test fallisce o il build non compila: STATUS: ERROR, descrivi il problema, NON scrivere CONTINUE"$'\n'
    prompt+="4. CHIUSURA BLOCCO OBBLIGATORIA: alla fine di OGNI invocazione del runner, DEVI aggiornare $HANDOFF_FILE con il nuovo stato (puoi farlo manualmente o invocando la skill chiusura-blocco se disponibile). IMPORTANTE: il file di handoff vive in $HANDOFF_FILE (NON in .claude/handoff.md, spostato per evitare la protezione hardcoded di Claude Code sui file di .claude/). Scrivilo direttamente con il tool Write."$'\n'
    prompt+="5. Cosa scrivere in $HANDOFF_FILE: (a) STATUS: CONTINUE/CHECKPOINT/PHASE_COMPLETE/ERROR/BLOCKED, (b) BLOCK: il prossimo blocco da eseguire (NON quello appena chiuso), (c) SUMMARY: cosa hai appena completato, (d) NEXT: descrizione breve del prossimo blocco. Devi anche (f) aggiornare ROADMAP.md marcando il blocco corrente come [x], (g) fare un commit git che INCLUDE $HANDOFF_FILE e ROADMAP.md. Il runner legge questo file dal disco per decidere il prossimo blocco, se non lo aggiorni tu non si aggiorna."$'\n\n'
    # In corsia le regole cambiano: si lavora accanto ad altri agenti che non si vedono e
    # non si sentono. Cio' che hanno in comune non si tocca — chi lo tocca rompe il lavoro
    # degli altri senza che nessuno se ne accorga fino alla riunione (cap. 21).
    if [[ -n "$CORSIA" ]]; then
        prompt+="--- SEI NELLA CORSIA $CORSIA (LAVORO PARALLELO) ---"$'\n'
        prompt+="Altri agenti stanno lavorando ADESSO su altre corsie dello stesso progetto, in cartelle e rami separati. Non li vedi e non puoi parlarci."$'\n'
        prompt+="- Esegui SOLO i blocchi marcati [[$CORSIA]] nella ROADMAP. Gli altri non ti riguardano: non toccarli, non marcarli, non anticiparli."$'\n'
        prompt+="- Il TRONCO (cio' che sta sotto tutte le corsie: schema dati, autenticazione, tema, convenzioni, librerie condivise) e i CONFINI (la forma di cio' che le corsie si scambiano) sono in SOLA LETTURA. Leggili quanto vuoi, non modificarli mai."$'\n'
        prompt+="- Se per finire il tuo blocco ti servisse una modifica al tronco o a un confine: FERMATI con STATUS: CHECKPOINT e scrivi in DECISIONS_NEEDED cosa vorresti cambiare e perche'. NON farlo da solo, nemmeno se la modifica ti sembra piccola e ovvia: le altre corsie stanno costruendo sopra quello che c'e' adesso, e non saprebbero che e' cambiato."$'\n'
        prompt+="- Questa regola VINCE sulle 6 regole di autonomia: in corsia, sul comune non c'e' autonomia."$'\n'
        prompt+="- Il tuo diario e' $HANDOFF_FILE (non quello principale, che appartiene alla riunione finale)."$'\n\n'
    fi
    prompt+="FORMATO HANDOFF (tutto l'handoff sta in ${HANDOFF_MAX_RIGHE} righe: e' il passaggio di consegne al blocco dopo, non il verbale della fase. SUMMARY max 10 righe. Oltre il tetto la coda viene tagliata dal messaggio del blocco successivo):"$'\n'
    prompt+="STATUS: CONTINUE|CHECKPOINT|PHASE_COMPLETE|ERROR|BLOCKED"$'\n'
    # UNA VOCE PER RIGA, e non e' questione di ordine: chi rilegge l'handoff cerca le righe
    # che COMINCIANO con PHASE:, BLOCK:, TESTS: e prende tutto fino a fine riga (le
    # parse_handoff_* poco sopra). Con due voci sulla stessa riga il campo della fase si
    # mangia il riassunto intero e lo stato di marcia nasce corrotto — successo il 2026-08-19
    # sulla Fase 16 di Fedorius, dove current_phase conteneva mille caratteri di riassunto e
    # il nome del blocco se li portava dietro a ogni riga di registro. Il difetto era latente
    # da sempre: gli agenti scrivevano le voci separate per abitudine, non perche' il modello
    # lo chiedesse. Chi volesse ricompattarle per risparmiare righe rompe questo.
    # La prova che lo inchioda: tests/test_messaggio_del_blocco.sh, sezione 6.
    prompt+="PHASE: [num]"$'\n'
    prompt+="BLOCK: [num]"$'\n'
    prompt+="SUMMARY: [fatto]"$'\n'
    prompt+="NEXT: [prossimo]"$'\n'
    prompt+="DECISIONS_NEEDED: [se checkpoint/blocked]"$'\n'
    prompt+="OLTRE_IL_CHIESTO: [cosa hai fatto oltre a quanto chiedeva il blocco, una riga per cosa; 'nessuno' se non hai fatto altro]"$'\n'
    prompt+="PER_VILLA: [OBBLIGATORIO — vedi le regole qui sotto]"$'\n'
    prompt+="FILES_MODIFIED: [lista]"$'\n'
    prompt+="TESTS: PASS|FAIL|SKIPPED"$'\n\n'
    prompt+="COME SI SCRIVE PER_VILLA (e' la riga che gli arriva sul telefono, e la legge lui, non un agente):"$'\n'
    prompt+="- 1-3 righe, in italiano di tutti i giorni, come lo diresti a voce a qualcuno che non ha letto niente."$'\n'
    prompt+="- Dici COSA HAI FATTO in termini di RISULTATO, non di lavoro svolto: non 'implementata la classe X con test', ma 'adesso chi usa l'app puo' salvare la scheda e ritrovarla domani'."$'\n'
    prompt+="- VIETATI: nomi di file, percorsi, codici di blocco (F3B12), nomi di funzioni o classi, sigle, numeri di test, termini inglesi tecnici. Se una parola non la userebbe un direttore di RSA, non entra."$'\n'
    prompt+="- Se ti sei fermato, la cosa piu' importante e' PERCHE' e COSA SERVE DA LUI, detto in modo che possa rispondere con una frase."$'\n'
    prompt+="- Niente elenchi puntati, niente grassetti: e' un paragrafino parlato."$'\n'
    prompt+="- Prova prima di scrivere: se Villa leggesse SOLO questa riga, saprebbe cos'e' successo e se deve fare qualcosa? Se no, riscrivila piu' semplice."$'\n'
    prompt+="- SUMMARY resta com'e', tecnico: serve all'agente della corsa dopo. PER_VILLA serve a Villa. Non sono la stessa frase riscritta: sono due cose diverse."$'\n'
    prompt+="VERIFICATION: [risultato della verifica — quanti test passano, build ok/ko, problemi trovati]"$'\n\n'
    prompt+="REGOLE:"$'\n'
    prompt+="- CONTINUE solo se TUTTI i test passano e il build compila. Mai CONTINUE con test rotti."$'\n'
    prompt+="- CHECKPOINT se serve una decisione di Villa (es. scelta architetturale, trade-off)"$'\n'
    prompt+="- ERROR se qualcosa non funziona e non riesci a fixarlo"$'\n'
    prompt+="- BLOCKED se mancano informazioni o accessi"$'\n'
    prompt+="- Commit atomici in italiano (o secondo le convenzioni del progetto)"$'\n'
    prompt+="- NON procedere al blocco successivo"$'\n'
    prompt+="- Se hai dubbi su qualcosa, è meglio CHECKPOINT che CONTINUE"$'\n'
    if $ALL_PHASES; then
        prompt+="- MODALITA TUTTE-LE-FASI ATTIVA: quando completi l'ULTIMO blocco di una fase ma nella roadmap restano blocchi non fatti in fasi successive, NON usare PHASE_COMPLETE (fermerebbe il runner): usa CONTINUE e metti in BLOCK il primo blocco non fatto della fase successiva. Usa PHASE_COMPLETE solo se non resta davvero piu' nulla da fare. Usa CHECKPOINT se il prossimo blocco richiede una decisione di Villa o e' un blocco umano/collaborativo (etichette 👤/🤝)."$'\n'
    fi
    c="$(estratto_roadmap "$phase")"; [[ -n "$c" ]] && prompt+="--- ROADMAP (fase in corso; il file intero e' in $ROADMAP) ---"$'\n'"$c"$'\n\n'
    prompt+="--- STATO ATTUALE ---"$'\n'"Fase: $phase | Blocco: $block"$'\n'
    local _prec; _prec="$(precedenti_del_blocco "$phase" "$block")"
    [[ -n "$_prec" ]] && prompt+=$'\n'"$_prec"$'\n'
    local _pc; _pc="$(phase_counts "$phase")"; local _pd _pt _px; read -r _pd _pt _px <<< "$_pc"
    if [[ "${_pt:-0}" -gt 0 ]]; then
        prompt+="Avanzamento Fase $phase (da ROADMAP): $_pd/$_pt blocchi completati, $_px da fare"$'\n\n'
    else
        prompt+="Blocchi eseguiti finora (lifetime, inclusi rifacimenti): $(read_progress_field total_blocks_run)"$'\n\n'
    fi
    # QUESTO BLOCCO E' GIA' PASSATO DI QUI. Rifarlo allo stesso modo e' il modo piu' rapido di
    # sbagliarlo di nuovo: al secondo giro si cambia disciplina, non velocita' (cap. 29). Sta
    # qui in fondo, fra le cose che cambiano a ogni blocco, e non in cima fra le istruzioni
    # fisse: in cima romperebbe il prefisso stabile del messaggio e si ripagherebbe tutto a
    # ogni blocco della corsa (cap. 23).
    # QUANTO PUOI USCIRE DAL SEMINATO (cap. 05). La dichiarazione e' accesa a tutti e tre i
    # livelli: senza, il livello largo non e' una liberta' ma una benda sugli occhi — quelle
    # cose entrerebbero e nessuno lo saprebbe mai.
    local _lib="${LIBERTA_DEL_BLOCCO:-${LIBERTA:-normale}}"
    prompt+="--- QUANTO PUOI USCIRE DAL SEMINATO: $_lib ---"$'\n'
    case "$_lib" in
        stretto) prompt+="Fai SOLO cio' che il blocco chiede. Se intorno trovi qualcosa di rotto, NON ripararlo: scrivilo nell'handoff e vai avanti."$'\n' ;;
        largo)   prompt+="Oltre al blocco puoi aggiustare cio' che trovi rotto intorno E migliorare cio' che funziona ma e' scritto male."$'\n' ;;
        *)       prompt+="Oltre al blocco puoi aggiustare cio' che trovi ROTTO intorno. NON rifare cio' che funziona: migliorare una cosa che funziona e' una scelta di design, e non si prende di notte."$'\n' ;;
    esac
    prompt+="In ogni caso, a fine blocco DICHIARA nell'handoff (voce OLTRE_IL_CHIESTO) cosa hai fatto oltre a quanto chiesto, una riga per cosa; scrivi 'nessuno' se non hai fatto altro. E cio' che e' in piu' va in un COMMIT SEPARATO dentro lo stesso blocco, cosi' domani si puo' buttare da solo senza toccare il resto."$'\n\n'
    # L'OBIEZIONE DEL OCCHIO ESTERNO (cap. 05). Sta qui in fondo, fra le cose che cambiano a
    # ogni blocco: in cima romperebbe il prefisso stabile del messaggio (cap. 23). E' la
    # prima cosa da riparare, e nell'handoff va dichiarato cosa se n'e' fatto — altrimenti
    # il giro dopo l'occhio esterno la ritrova identica.
    if [[ -n "${OCCHIO_ESTERNO_MOTIVO:-}" ]]; then
        prompt+="--- L'OCCHIO ESTERNO HA RIAPERTO QUESTO BLOCCO ---"$'\n'
        prompt+="Un controllo indipendente ha guardato la differenza che il blocco aveva lasciato e dice che il blocco NON e' finito. Non e' un parere sullo stile: e' una cosa che manca, che e' finta o che e' rotta."$'\n'
        prompt+="Riparala PRIMA di qualunque altra cosa. Non allargare il lavoro: si chiude questo, non se ne apre un altro."$'\n'
        prompt+="Nell'handoff, alla voce OCCHIO_ESTERNO, scrivi cosa hai fatto dell'obiezione — riparata come, oppure perche' non era un difetto."$'\n\n'
        prompt+="$OCCHIO_ESTERNO_MOTIVO"$'\n\n'
    fi
    if [[ -n "${BLOCCO_RITENTATO:-}" ]]; then
        prompt+="--- QUESTO BLOCCO E' GIA' FALLITO UNA VOLTA ---"$'\n'
        prompt+="Non riprovare a naso. Apri la competenza 'caccia-ai-problemi' (.claude/skills/caccia-ai-problemi/SKILL.md) e seguila: prima costruisci un comando che va ROSSO sul problema, poi scrivi 3-5 ipotesi ognuna con la sua previsione, poi provi. Se dopo tre giri di ipotesi non hai ristretto il campo, scrivi nell'handoff cosa hai capito e cosa hai ESCLUSO, lascia il problema aperto col suo comando rosso, e chiudi il blocco: un blocco solo non deve mangiarsi la corsa."$'\n\n'
    fi
    # Rete di sicurezza sul diario: e' il passaggio di consegne al blocco dopo, non il verbale
    # della fase. Il tetto vero e' dichiarato piu' sotto, nel formato che l'agente deve
    # scrivere; qui si taglia solo se qualcuno l'ha ignorato, perche' un diario che ingrassa
    # si ripaga a ogni blocco della corsa. Il file completo resta sul disco.
    if [[ -n "$handoff" && "$first" == "false" ]]; then
        local righe; righe="$(printf '%s\n' "$handoff" | wc -l)"
        if [[ "$righe" -gt "$HANDOFF_MAX_RIGHE" ]]; then
            handoff="$(printf '%s\n' "$handoff" | head -n "$HANDOFF_MAX_RIGHE")"$'\n'"[...diario troncato a $HANDOFF_MAX_RIGHE righe su $righe: se ti serve il resto, apri $HANDOFF_FILE]"
        fi
        prompt+="--- HANDOFF PRECEDENTE ---"$'\n'"$handoff"$'\n\n'
    elif [[ "$first" == "true" ]]; then prompt+="--- PRIMO BLOCCO ---"$'\n'"Analizza roadmap e progetto, esegui il primo blocco."$'\n\n'; fi
    echo "$prompt"
}

validate_environment() {
    log "${BOLD}Validazione...${NC}"
    # Si verifica l'agente SCELTO, non Claude Code a prescindere.
    if ! _errore_agente="$(verifica_agente_installato)"; then die "$_errore_agente"; fi
    [[ -d "$PROJECT_DIR" ]] || die "Directory non trovata: $PROJECT_DIR"
    # Il CLAUDE.md che conta e' quello della radice: e' li' che vive il Metodo.
    [[ -f "$ROOT_DIR/$CLAUDE_MD" ]] || die "CLAUDE.md mancante nella radice: $ROOT_DIR/$CLAUDE_MD"
    [[ "$PROJECT_DIR" != "$ROOT_DIR" ]] && log "${BLUE}Modalita' modulo: Metodo dalla radice ($(basename "$ROOT_DIR")), lavoro su $(basename "$PROJECT_DIR")${NC}"
    [[ -f "$PROJECT_DIR/$PROJECT_CONFIG" ]] || log "${YELLOW}PROJECT_CONFIG.md mancante${NC}"
    mkdir -p "$PROJECT_DIR/$(dirname "$HANDOFF_FILE")" "$PROJECT_DIR/.claude"; init_progress
    [[ -f "$PROJECT_DIR/$RUNNER_LOG" ]] || echo -e "# Metodo Villa Runner Log\n# $(date)\n" > "$PROJECT_DIR/$RUNNER_LOG"
    check_git_branch; log "${GREEN}Ambiente OK${NC}"
}

# Uccide un processo e TUTTI i suoi discendenti (figli, nipoti...). Serve al timeout:
# L'agente puo' aver avviato un server di sviluppo (es. `npm run dev` -> vite) che, se non
# ucciso con tutto l'albero, resterebbe appeso a una porta come processo fantasma — e il
# blocco dopo, che prova ad avviare lo stesso server, fallirebbe senza motivo apparente.
kill_tree() {
    local pid="$1"
    # Windows (Git Bash/MSYS): taskkill //T uccide l'intero albero. taskkill ragiona in PID
    # Windows; /proc/<pid>/winpid traduce il PID MSYS in quello Windows.
    if command -v taskkill >/dev/null 2>&1; then
        local winpid=""
        [[ -r "/proc/$pid/winpid" ]] && winpid="$(cat "/proc/$pid/winpid" 2>/dev/null)"
        winpid="${winpid:-$pid}"
        taskkill //T //F //PID "$winpid" >/dev/null 2>&1 && return 0
    fi
    # POSIX (Linux/Mac) o fallback: prima i figli diretti, poi il processo stesso.
    command -v pkill >/dev/null 2>&1 && pkill -TERM -P "$pid" 2>/dev/null || true
    kill -TERM "$pid" 2>/dev/null || true
    sleep 1
    command -v pkill >/dev/null 2>&1 && pkill -KILL -P "$pid" 2>/dev/null || true
    kill -KILL "$pid" 2>/dev/null || true
    return 0
}

# --- LA MEMORIA DI LAVORO: quando conviene continuare invece di ricominciare -------------
# Ogni sessione nuova ripaga da zero il preambolo del blocco — misurato, circa 30.000 unita'.
# Se il blocco e' finito bene e nella finestra c'e' ancora spazio buono, il blocco dopo
# continua nella STESSA sessione: il preambolo si paga una volta ogni tre o quattro blocchi
# invece che ogni volta. La soglia non e' avarizia: la ricerca dice che oltre meta' finestra
# il modello ragiona peggio, quindi si lavora dove lavora meglio. Cap. 26.
#
# Due numeri, decisi da Villa: si accetta un blocco nuovo solo se si e' entro il 35%; il 50%
# resta il tetto che non si vuole superare (il margine fra i due e' lo spazio per il blocco).
CONTESTO_SOGLIA_NUOVO="${CONTESTO_SOGLIA_NUOVO:-35}"
CONTESTO_SOGLIA_TETTO="${CONTESTO_SOGLIA_TETTO:-50}"
CONTESTO_FINESTRA="${CONTESTO_FINESTRA:-200000}"
CONCATENA="${CONCATENA:-si}"
SESSIONE_DA_RIPRENDERE=""     # se valorizzata, il prossimo blocco continua qui
SESSIONE_CORRENTE=""          # l'id della sessione appena conclusa
CONTESTO_PERCENTO=0           # quanto e' occupata la memoria dopo il blocco appena chiuso
BLOCCHI_DI_FILA=0             # quanti blocchi ha fatto la sessione in corso
SESSIONI_RIUSATE=0            # quante volte un blocco e' partito senza ripagare il preambolo

# Legge dall'uscita dell'agente l'id della sessione, e da quello quanta memoria e' occupata.
# Se non si riesce a sapere, si lascia tutto a zero: nel dubbio si ricomincia pulito.
leggi_memoria_di_lavoro() {
    local of="$1"
    SESSIONE_CORRENTE=""; CONTESTO_PERCENTO=0
    [[ -s "$of" ]] || return 0
    SESSIONE_CORRENTE="$(python "$SCRIPT_DIR/leggi-conto.py" sessione < "$of" 2>/dev/null || true)"
    [[ -n "$SESSIONE_CORRENTE" ]] || return 0
    local m; m="$(python "$SCRIPT_DIR/leggi-contesto.py" "$SESSIONE_CORRENTE" "$CONTESTO_FINESTRA" 2>/dev/null || true)"
    [[ -n "$m" ]] || return 0
    local _occ _fin _pct; IFS='|' read -r _occ _fin _pct <<< "$m"
    CONTESTO_PERCENTO="${_pct:-0}"
    log "    ${CYAN}memoria di lavoro: ${CONTESTO_PERCENTO}% di $(( _fin / 1000 ))k occupata${NC}"
    return 0
}

# Il blocco dopo puo' continuare in questa sessione? Solo se: la cosa e' accesa, il blocco
# appena chiuso e' andato bene, si sa quanta memoria e' occupata, e siamo entro la soglia.
si_puo_continuare() {
    [[ "$CONCATENA" == "si" ]] || return 1
    [[ -n "$SESSIONE_CORRENTE" ]] || return 1
    [[ "${CONTESTO_PERCENTO:-0}" -gt 0 ]] || return 1
    [[ "${CONTESTO_PERCENTO}" -le "${CONTESTO_SOGLIA_NUOVO}" ]] || return 1
    return 0
}

# RIPARARE nella stessa sessione e' un'altra cosa dal CONCATENARE blocchi diversi: li' si
# comincia un lavoro nuovo, qui si finisce quello che si ha in mano. Ricominciare da fuori
# vorrebbe dire far rileggere all'agente il codice che ha appena scritto, e ripagare il
# preambolo per una correzione di poche righe. Percio' non guarda CONCATENA (che regola i
# blocchi nuovi) e usa il TETTO invece della soglia: una riparazione e' piccola.
si_puo_riparare_qui() {
    [[ -n "$SESSIONE_CORRENTE" ]] || return 1
    [[ "${CONTESTO_PERCENTO:-0}" -gt 0 ]] || return 1
    [[ "${CONTESTO_PERCENTO}" -le "${CONTESTO_SOGLIA_TETTO}" ]] || return 1
    return 0
}

# --- IL SORVEGLIANTE: guarda se sta lavorando, non l'orologio ----------------------------
# Prima c'era un cane da guardia che allo scadere del tempo uccideva l'agente e basta. Un
# blocco grosso che stava lavorando bene veniva troncato a meta' — lavoro perso, e per giunta
# gia' pagato. Il tempo, da solo, non dice niente: dice quanto e' passato, non se sta
# succedendo qualcosa.
#
# Adesso si guarda il DIARIO DI SESSIONE che Claude Code scrive mentre lavora: ogni scambio
# aggiunge righe. Se cresce, sta lavorando e lo si lascia andare, anche a lungo. Se non cresce
# piu' da un po', e' appeso: allora si interviene. E resta un tetto assoluto, molto alto, per
# non restare in ostaggio in eterno.
# Cap. 27.
INATTIVITA_MAX_MINUTI="${INATTIVITA_MAX_MINUTI:-10}"   # fermo da tanto = appeso
TETTO_ASSOLUTO_MINUTI="${TETTO_ASSOLUTO_MINUTI:-240}"  # oltre questo si chiude comunque
SESSIONE_IMPOSTA=""      # l'id deciso dal runner prima di partire, per sapere dove guardare
MOTIVO_INTERRUZIONE=""   # "appeso" | "tetto" | "" (finito da solo)

# Dove Claude Code scrive il diario di questa sessione. Si cerca per nome: la regola con cui
# il nome del progetto diventa cartella non e' nostra e potrebbe cambiare.
diario_di_sessione() {
    local id="$1"; [[ -n "$id" ]] || return 0
    find "$HOME/.claude/projects" -name "${id}.jsonl" 2>/dev/null | head -1
}

# Il sorvegliante vero e proprio, da lanciare in background accanto all'agente. Uccide
# l'albero solo quando c'e' motivo, e scrive PERCHE' in un file che il chiamante legge.
sorveglia_agente() {
    local pid="$1" id="$2" flag="$3" uscita="${4:-}"
    local inattivo=0 passati=0
    local ultima_dim=-1 dim d_diario d_uscita diario=""
    while kill -0 "$pid" 2>/dev/null; do
        sleep 30
        passati=$(( passati + 30 ))
        [[ -n "$diario" ]] || diario="$(diario_di_sessione "$id")"
        d_diario=0; [[ -n "$diario" && -f "$diario" ]] && d_diario="$(wc -c < "$diario" 2>/dev/null || echo 0)"
        # IL SEGNO VITALE NON E' UNO SOLO, e non puo' esserlo: il diario di sessione lo scrive
        # Claude Code, e l'agente non e' per forza Claude Code (cap. 22). Con un altro agente quel
        # file non nasce mai: il sorvegliante legge zero byte per sempre e allo scoccare del
        # decimo minuto dichiara appeso un agente che sta lavorando benissimo. E' successo
        # davvero, e dal registro si vede: dieci letture di file e una ricerca in corso, e subito
        # sotto «Fermo da 10 minuti senza scrivere niente: l'ho interrotto».
        # Cio' che cresce per QUALUNQUE agente e' la sua uscita, che il runner sta gia'
        # raccogliendo in un file suo: si guardano tutt'e due, e basta che cresca una.
        d_uscita=0; [[ -n "$uscita" && -f "$uscita" ]] && d_uscita="$(wc -c < "$uscita" 2>/dev/null || echo 0)"
        dim=$(( d_diario + d_uscita ))
        if [[ "$dim" -gt "$ultima_dim" ]]; then
            ultima_dim="$dim"; inattivo=0        # ha scritto qualcosa: sta lavorando
        else
            inattivo=$(( inattivo + 30 ))
        fi
        if [[ "$inattivo" -ge $(( INATTIVITA_MAX_MINUTI * 60 )) ]]; then
            echo "appeso" > "$flag"; kill_tree "$pid"; return 0
        fi
        if [[ "$passati" -ge $(( TETTO_ASSOLUTO_MINUTI * 60 )) ]]; then
            echo "tetto" > "$flag"; kill_tree "$pid"; return 0
        fi
    done
    return 0
}

# --- IL CONTATORE -----------------------------------------------------------------------
# Quanto consuma ogni blocco, e quanto la corsa intera. Il conto lo dice l'agente stesso:
# Claude Code con --output-format json e OpenCode con --format json restituiscono la risposta
# insieme a token e costo. Serve a due cose: far vedere dove va la spesa, e poter
# MISURARE le prossime scelte invece di stimarle — finora due stime su tre erano sbagliate
# (vedi docs/fondamenta/risparmio-token.md).
#
# Il costo e' quello calcolato da Claude Code ai prezzi di listino: con l'abbonamento NON e'
# un addebito, e' il valore di quello che si e' consumato. Va detto cosi' anche a Villa.
TOKEN_CORSA=0; COSTO_CORSA=0; TOKEN_BLOCCO=0; COSTO_BLOCCO=0; CONTO_BLOCCO=""; MODELLO_AL_LAVORO=""

# "12.3k token · ~$0.42" — il conto come lo leggerebbe una persona.
formatta_conto() {
    awk -v t="${1:-0}" -v c="${2:-0}" 'BEGIN{
        if (t >= 1000) printf "%.1fk token", t/1000; else printf "%d token", t;
        printf " · ~$%.2f", c;
    }'
}

# Legge il conto dall'uscita dell'agente e travasa la risposta nel registro. Se l'uscita non
# si capisce (agente non previsto, sessione uccisa dal sorvegliante, errore) non si inventa
# niente: nel registro finisce tutto com'era e il conto resta vuoto.
leggi_conto_blocco() {
    local of="$1"
    TOKEN_BLOCCO=0; COSTO_BLOCCO=0; CONTO_BLOCCO=""
    [[ -s "$of" ]] || return 0
    local testo; testo="$(python "$SCRIPT_DIR/leggi-conto.py" testo < "$of" 2>/dev/null || true)"
    if [[ -n "$testo" ]]; then printf '%s\n' "$testo" >> "$PROJECT_DIR/$RUNNER_LOG"
    else cat "$of" >> "$PROJECT_DIR/$RUNNER_LOG"; fi
    # Il modello si passa perche' OpenCode, nei suoi eventi, non dice quale ha lavorato: lo
    # sa solo chi lo ha lanciato. Per Claude Code l'argomento si ignora (lo dice lui).
    local numeri; numeri="$(python "$SCRIPT_DIR/leggi-conto.py" numeri "${MODEL_OVERRIDE:-}" < "$of" 2>/dev/null || true)"
    [[ -n "$numeri" ]] || return 0
    IFS='|' read -r TOKEN_BLOCCO COSTO_BLOCCO MODELLO_AL_LAVORO <<< "$numeri"
    TOKEN_CORSA=$(( TOKEN_CORSA + ${TOKEN_BLOCCO:-0} ))
    COSTO_CORSA="$(awk -v a="$COSTO_CORSA" -v b="${COSTO_BLOCCO:-0}" 'BEGIN{printf "%.6f", a+b}')"
    CONTO_BLOCCO="$(formatta_conto "$TOKEN_BLOCCO" "$COSTO_BLOCCO")"
    return 0
}

run_agent_session() {
    local prompt="$1" bid="$2"; log "${BLUE}Lancio sessione per blocco $bid...${NC}"
    if $DRY_RUN; then log "${YELLOW}[DRY RUN] Prompt: ${#prompt} char per blocco $bid${NC}"
        mkdir -p "$PROJECT_DIR/$(dirname "$HANDOFF_FILE")" "$PROJECT_DIR/.claude"
        # In dry-run salviamo il prompt COMPLETO su file, cosi e' ispezionabile senza
        # lanciare Claude (verifica Blocco 3.2: il nudge frontend deve comparire qui).
        printf '%s\n' "$prompt" > "$PROJECT_DIR/docs/diario/dry-run-prompt.txt"
        log "${YELLOW}[DRY RUN] Prompt completo salvato in docs/diario/dry-run-prompt.txt${NC}"
        echo -e "STATUS: CONTINUE\nPHASE: 0\nBLOCK: 0\nSUMMARY: [DRY RUN]\nNEXT: [DRY RUN]\nTESTS: SKIPPED" > "$PROJECT_DIR/$HANDOFF_FILE"; return 0; fi
    local pf; pf="$(mktemp)"; echo "$prompt" > "$pf"; local ec=0
    # L'agente parte in BACKGROUND (exec: il processo di background E' l'agente) cosi' se ne
    # tiene il PID. La cartella di lavoro e' PROJECT_DIR, cosi' i percorsi relativi della
    # roadmap (src/, package.json) e i comandi npm risolvono nel posto giusto anche quando
    # si lavora su un modulo. Un cane da guardia lo sorveglia: allo scadere del tempo
    # uccide l'INTERO albero mentre l'agente e' ancora vivo, cosi' taskkill //T lo vede tutto.
    # Il vecchio `timeout claude` uccideva solo il programma e lasciava i figli appesi.
    # $model_arg non e' quotato apposta: si divide in due argomenti quando valorizzato e
    # sparisce del tutto quando vuoto (default del CLI).
    # L'uscita dell'agente va prima in un file suo, non dritta nel registro: e' li' dentro che
    # sta il conto del blocco (token, costo, modello). Il registro lo riempie leggi_conto_blocco
    # con la risposta vera, cosi' chi lo apre ritrova quello che trovava prima.
    local of; of="$(mktemp)"
    # L'id della sessione lo decide il runner PRIMA di partire: e' cosi' che il sorvegliante
    # sa dove guardare per capire se l'agente sta ancora lavorando. Se si sta riprendendo una
    # sessione, l'id e' gia' noto.
    SESSIONE_IMPOSTA=""
    if [[ -z "${SESSIONE_DA_RIPRENDERE:-}" ]]; then
        SESSIONE_IMPOSTA="$(python -c "import uuid; print(uuid.uuid4())" 2>/dev/null || true)"
    fi
    local id_sorvegliato="${SESSIONE_DA_RIPRENDERE:-$SESSIONE_IMPOSTA}"
    ( CARTELLA_DI_LAVORO="$PROJECT_DIR" SESSIONE_IMPOSTA="$SESSIONE_IMPOSTA" avvia_agente "$pf" ) > "$of" 2>&1 &
    local cpid=$!
    local to_flag; to_flag="$(mktemp)"; rm -f "$to_flag"   # dentro ci finisce il PERCHE' dell'interruzione
    ( sorveglia_agente "$cpid" "$id_sorvegliato" "$to_flag" "$of" ) >/dev/null 2>&1 &
    local wpid=$!
    wait "$cpid" 2>/dev/null || ec=$?            # blocca finche' l'agente finisce (da solo o interrotto)
    MOTIVO_INTERRUZIONE=""
    [[ -s "$to_flag" ]] && { MOTIVO_INTERRUZIONE="$(cat "$to_flag")"; ec=124; }
    kill_tree "$wpid" >/dev/null 2>&1 || true    # se l'agente ha finito da solo, ferma il sorvegliante
    wait "$wpid" 2>/dev/null || true
    leggi_conto_blocco "$of"
    leggi_memoria_di_lavoro "$of"
    rm -f "$pf" "$to_flag" "$of"
    if [[ $ec -eq 124 ]]; then
        if [[ "$MOTIVO_INTERRUZIONE" == "appeso" ]]; then
            log "${RED}Fermo da $INATTIVITA_MAX_MINUTI minuti senza scrivere niente: l'ho interrotto.${NC}"
        else
            log "${RED}Raggiunto il tetto assoluto di $TETTO_ASSOLUTO_MINUTI minuti: l'ho interrotto.${NC}"
        fi
        return 1
    fi
    [[ $ec -ne 0 ]] && { log "${RED}Errore (exit: $ec)${NC}"; return 1; }
    log "${GREEN}Sessione OK${NC}${CONTO_BLOCCO:+ — $CONTO_BLOCCO}"; return 0
}

main() {
    local PROJECT_NAME; PROJECT_NAME="$(get_project_name)"
    # Titolo della finestra/terminale: con piu' runner aperti si distinguono dalla barra applicazioni
    printf '\033]0;%s - Metodo Villa Runner\007' "$PROJECT_NAME"
    # Nome del progetto BELLO GRANDE in cima: si capisce a colpo d'occhio quale runner e' questo
    echo -e "\n${BOLD}${CYAN}════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}${GREEN}   ▶  ${PROJECT_NAME}${NC}"
    echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════${NC}"
    # Chi lavora si dice solo se NON e' il solito: cosi' la riga in piu' significa qualcosa.
    [[ "$AGENTE" != "claude" ]] && echo -e "${BOLD}${YELLOW}      esegue: ${AGENTE} (non Claude Code — cap. 22)${NC}"
    [[ -n "$CORSIA" ]] && echo -e "${BOLD}${YELLOW}      corsia ${CORSIA} — lavoro parallelo (cap. 21)${NC}"
    echo -e "${BOLD}      Metodo Villa Runner v1.0${NC}\n"
    log "Config: tetto-sicurezza=$MAX_BLOCKS timeout=${TIMEOUT_MINUTES}min phase=${TARGET_PHASE:-tutte} modello=${MODEL_OVERRIDE:-default} agente=${AGENTE}${CORSIA:+ corsia=$CORSIA}"
    $DRY_RUN && log "${YELLOW}DRY RUN${NC}"

    # Modalita TEST TELEGRAM: invia 3 messaggi di prova e esci.
    # Utile per validare il formato dei messaggi senza eseguire un ciclo di sviluppo vero.
    # Salta la validazione ambiente (non servono Claude CLI, git, progress.json).
    if $TEST_TELEGRAM; then
        mkdir -p "$PROJECT_DIR/$(dirname "$HANDOFF_FILE")" "$PROJECT_DIR/.claude"
        [[ -f "$PROJECT_DIR/$RUNNER_LOG" ]] || echo -e "# Metodo Villa Runner Log\n# $(date)\n" > "$PROJECT_DIR/$RUNNER_LOG"
        log "${BOLD}=== MODALITA TEST TELEGRAM ===${NC}"
        if [[ -z "$TELEGRAM_BOT_TOKEN" || -z "$TELEGRAM_CHAT_ID" ]]; then
            log "${RED}Credenziali Telegram non configurate in .env.runner${NC}"
            log "${RED}Configura TELEGRAM_BOT_TOKEN e TELEGRAM_CHAT_ID prima di testare.${NC}"
            exit 1
        fi
        log "Credenziali Telegram trovate. Invio 3 messaggi di prova..."
        echo

        log "${BLUE}[1/3] BLOCCO_OK (notifica silenziosa, senza dispatch)${NC}"
        send_telegram_report "BLOCCO_OK" "F1B2" "2" "15" \
            "Esempio blocco completato — Feature X implementata. 3 file modificati, 8 nuovi test verdi. Build pulito, zero warning." \
            "F1B3 — Prossimo blocco di esempio (estensione Y)" \
            "5"
        log "${GREEN}Test 1 inviato${NC}"
        sleep 3

        log "${BLUE}[2/3] PHASE_COMPLETE (notifica sonora, con dispatch)${NC}"
        send_telegram_report "PHASE_COMPLETE" "F1B10" "10" "240" \
            "Esempio fase completata — Fase 1 del progetto finita. Tutti i blocchi della fase eseguiti con successo, test verdi, build stabile. Pronto per il test manuale del fondatore o per passare alla fase successiva." \
            "" \
            "10"
        log "${GREEN}Test 2 inviato${NC}"
        sleep 3

        log "${BLUE}[3/3] ERROR (notifica sonora, con dispatch)${NC}"
        send_telegram_report "ERROR" "F1B5" "5" "45" \
            "Esempio errore bloccante — Manca una dipendenza o un segreto in configurazione. Il runner non riesce a proseguire senza intervento manuale. Verifica il log per dettagli." \
            "" \
            "7"
        log "${GREEN}Test 3 inviato${NC}"
        echo
        log "${BOLD}${GREEN}Tutti i test inviati. Controlla Telegram.${NC}"
        log "Verifica: Test 1 dovrebbe arrivare senza suono (silenzioso)."
        log "Verifica: Test 2 e Test 3 dovrebbero suonare e contenere la sezione Dispatch."
        exit 0
    fi

    validate_environment
    local cp cb; cp="$(read_progress_field current_phase)"; cb="$(read_progress_field current_block)"; cp="${cp:-0}"; cb="${cb:-0}"
    [[ -n "$TARGET_PHASE" ]] && cp="$TARGET_PHASE"

    # All'avvio le due fonti possono divergere, e finora vinceva quella indietro. Se una corsa
    # muore per timeout, progress.json resta fermo al blocco che stava girando mentre l'handoff
    # — scritto dall'agente a lavoro finito, commit compreso — e' gia' avanti. Il 2026-08-10 il
    # runner ha cosi' riaperto un blocco chiuso, committato e pushato sei ore prima. Vince
    # l'handoff: e' l'unico dei due che l'agente scrive apposta per il turno successivo.
    # (Con --phase N comanda la richiesta esplicita, e questa riconciliazione non si applica.)
    if [[ -z "$TARGET_PHASE" ]]; then
        local _hp _hb; _hp="$(parse_handoff_phase)"; _hb="$(parse_handoff_block)"
        if [[ -n "$_hp" && -n "$_hb" ]] && [[ "$_hp" != "$cp" || "$_hb" != "$cb" ]]; then
            log "${YELLOW}progress.json dice F${cp}B${cb}, l'handoff dice F${_hp}B${_hb}: vince l'handoff.${NC}"
            cp="$_hp"; cb="$_hb"
        fi
    fi

    # Notifica Telegram: runner avviato (salta in dry-run per non sporcare le notifiche)
    if ! $DRY_RUN; then
        local _start_branch; _start_branch="$(git -C "$PROJECT_DIR" branch --show-current 2>/dev/null || echo 'unknown')"
        local _start_project; _start_project="$(basename "$PROJECT_DIR")"
        send_telegram "▶️ ${_start_project} — comincio a lavorare

Riprendo dalla fase ${cp}. Vado avanti da solo finche' posso.

Ti scrivero' qui: in silenzio quando finisco un pezzo, con la suoneria se mi
fermo perche' serve una tua decisione o perche' qualcosa non torna.

Puoi chiudere tutto quando vuoi: il lavoro fatto resta salvato."
    fi

    local hc="" fb="true"
    if $RESUME && [[ -f "$PROJECT_DIR/$HANDOFF_FILE" ]]; then hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
    elif [[ -f "$PROJECT_DIR/$HANDOFF_FILE" ]] && [[ "$(read_progress_field total_blocks_run)" != "0" ]]; then hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"; fi
    local br=0 st; st="$(date +%s)"
    # Protezione loop: se lo stesso bid si ripete >= 2 volte consecutive con CONTINUE,
    # vuol dire che Claude non sta aggiornando BLOCK nell'handoff e il runner ciclerebbe
    # all'infinito. Fermiamo tutto con ERROR automatico.
    local last_bid="" consecutive_same=0
    # Totale blocchi da fare al momento del lancio: e' il denominatore del "quadro completo"
    # della corsa, mostrato in modalita --tutte-le-fasi. count_remaining_blocks puo' dare "-1"
    # se la roadmap non usa le checkbox: in quel caso azzeriamo e il quadro non viene mostrato.
    local initial_todo; initial_todo="$(count_remaining_blocks)"; [[ "${initial_todo}" =~ ^[0-9]+$ ]] || initial_todo=0
    if $ALL_PHASES; then
        log "${BOLD}Modalita: TUTTE LE FASI di fila${NC} (non si ferma a fine fase; solo a checkpoint, errore o blocco umano)"
    else
        log "${BOLD}Modalita: FINO A FINE FASE${NC} (canonica)"
    fi
    # Il quadro della corsa, in chiaro e prima di partire: chi lavora, con quale motore e
    # quale modello, quanti blocchi sono previsti e perche' la corsa finira'.
    local _pv _pv_n _pv_perche
    _pv="$(previsione_corsa "$cp" "$MAX_BLOCKS")"; _pv_n="${_pv%%|*}"; _pv_perche="${_pv#*|}"
    PREVISTI_ALLA_PARTENZA="$_pv_n"
    # Il record del "mentre lavora" nasce qui: da questo momento la schermata puo' dire
    # che una corsa e' partita, anche prima che il primo blocco cominci. E da questo
    # momento deve anche poter dire quando finisce, comunque finisca: il richiamo qui
    # sotto scrive la data di fine anche se il runner viene interrotto a meta'.
    dimentica_richiesta_di_fermarsi
    scrivi_durante_corsa
    trap 'scrivi_durante_fine' EXIT
    log "\n━━━ ${BOLD}LA CORSA${NC} ━━━"
    log "Progetto : ${BOLD}${PROJECT_NAME}${NC}"
    log "Motore   : ${BOLD}$(nome_agente_leggibile)${NC} · modello: ${BOLD}${MODEL_OVERRIDE:-quello predefinito}${NC}"
    log "Si parte : Fase $cp, blocco $cb"
    # Quanti sono, quanti fatti, quanti mancano — prima di partire e non solo blocco per
    # blocco. E' la domanda che Villa fa ogni volta che lancia una corsa.
    local _rd _rt _pd _pt _px
    read -r _rd _rt <<< "$(roadmap_counts)"
    read -r _pd _pt _px <<< "$(phase_counts "$cp")"
    if [[ "${_rt:-0}" -gt 0 ]]; then
        log "Roadmap  : ${BOLD}${_rt}${NC} in tutto · ${BOLD}${_rd}${NC} fatti · ${BOLD}$(( _rt - _rd ))${NC} da fare  ${CYAN}(tutto il progetto, non questa corsa)${NC}"
    fi
    if [[ "${_pt:-0}" -gt 0 ]]; then
        log "Fase $cp   : ${BOLD}${_pt}${NC} in tutto · ${BOLD}${_pd}${NC} fatti · ${BOLD}$(( _pt - _pd ))${NC} da fare"
    fi
    # L'ULTIMA RIGA E' LA RISPOSTA ALLA DOMANDA VERA: quanto manca a QUESTA corsa. Le due
    # righe sopra sono contesto — sono numeri del progetto e della fase, e da soli
    # rispondevano a una domanda che nessuno aveva fatto.
    if [[ "$_pv_n" == "?" ]]; then
        log "${BOLD}QUESTA CORSA${NC}: non so dire quanti blocchi — $_pv_perche"
    elif [[ "$_pv_n" == "0" && "$_pv_perche" == "poi tocca a Villa" ]]; then
        log "${BOLD}QUESTA CORSA${NC}: ${BOLD}nessun blocco${NC} — il primo da fare chiede Villa, mi fermo subito"
    elif [[ "$_pv_n" == "0" ]]; then
        log "${BOLD}QUESTA CORSA${NC}: ${BOLD}nessun blocco${NC} — non risulta niente da fare ($_pv_perche)"
    elif [[ "$_pv_n" == "1" ]]; then
        log "${BOLD}QUESTA CORSA${NC}: ${BOLD}1 blocco${NC}, $_pv_perche"
    else
        log "${BOLD}QUESTA CORSA${NC}: ${BOLD}${_pv_n} blocchi${NC}, $_pv_perche"
    fi
    log "${BOLD}=== Inizio ciclo ===${NC}\n"
    while [[ $br -lt $MAX_BLOCKS ]]; do
        # Fermarsi si chiede dalla schermata e si esaudisce QUI, fra un blocco e l'altro:
        # il blocco appena chiuso e' arrivato in fondo, il prossimo non comincia. Non e'
        # uno stop da guardiano — non c'e' niente da rimettere in moto, l'ha deciso Villa.
        if fermarsi_e_stato_chiesto; then
            log "${YELLOW}Fermata chiesta dalla schermata: il blocco in corso e' finito, non ne comincio altri.${NC}"
            local el_ferma; el_ferma="$(( ($(date +%s) - st) / 60 ))"
            send_telegram_report "FERMATO" "F${cp}B${cb}" "$br" "$el_ferma" \
                "Corsa fermata dalla schermata del runner dopo il blocco appena chiuso. Niente e' rimasto a meta': l'handoff e la roadmap sono aggiornati, e la corsa riparte da F${cp}B${cb}." \
                "$(parse_handoff_next)" "0"
            break
        fi
        br=$((br+1)); local bid="F${cp}B${cb}"
        # Fase e blocco di QUESTO giro, tenuti da parte: dopo la sessione cp/cb avanzano
        # leggendo l'handoff, e per riaprire il blocco appena chiuso servono quelli di prima.
        local bfase="$cp" bblocco="$cb"
        # Loop detection: confronta con il bid precedente
        if [[ "$bid" == "$last_bid" ]]; then
            consecutive_same=$((consecutive_same + 1))
        else
            consecutive_same=0
        fi
        last_bid="$bid"
        if [[ $consecutive_same -ge 2 ]]; then
            log "${RED}LOOP RILEVATO: blocco $bid ripetuto per la ${consecutive_same}a volta consecutiva.${NC}"
            log "${RED}Claude non sta aggiornando il campo BLOCK in handoff.md. Interruzione automatica.${NC}"
            local el_now; el_now="$(( ($(date +%s) - st) / 60 ))"
            if guardiano_interviene "$bid" "GIRO A VUOTO (stesso blocco ripetuto $consecutive_same volte)"; then
                hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                last_bid=""; consecutive_same=0; SESSIONE_DA_RIPRENDERE=""; BLOCCHI_DI_FILA=0
                [[ $br -lt $MAX_BLOCKS ]] && sleep 5
                continue
            fi
            send_telegram_report "ERROR" "$bid" "$br" "$el_now" "Loop rilevato: blocco $bid ripetuto $consecutive_same volte consecutive. Il runner si e fermato per evitare iterazioni a vuoto. Verifica manualmente docs/diario/handoff.md e aggiorna BLOCK al prossimo sub-blocco reale." "" "0"
            break
        fi
        # Stop naturale: se la roadmap non ha piu' blocchi "[ ]" da fare, abbiamo finito.
        # (Paracadute aggiuntivo: di norma e' Claude a emettere PHASE_COMPLETE prima.)
        local remaining; remaining="$(count_remaining_blocks)"
        if [[ "$remaining" == "0" ]]; then
            br=$((br - 1))  # questo giro non esegue nulla: non contarlo
            log "${GREEN}Roadmap completata: nessun blocco [ ] rimasto. Stop naturale.${NC}"
            local el_done; el_done="$(( ($(date +%s) - st) / 60 ))"
            send_telegram_report "PHASE_COMPLETE" "$bid" "$br" "$el_done" "Roadmap completata: tutti i blocchi pianificati risultano fatti. Il runner si e fermato da solo perche non c'e altro da eseguire." "$(parse_handoff_next)" "0"
            break
        fi
        local block_st; block_st="$(date +%s)"  # tempo inizio blocco per metrica per-block
        HEAD_PRIMA_DEL_BLOCCO=""   # il blocco comincia adesso: cio' che ha toccato quello prima non lo riguarda
        local _pc; _pc="$(phase_counts "$cp")"; local _pd _pt _px; read -r _pd _pt _px <<< "$_pc"
        # Quadro completo della corsa: solo in --tutte-le-fasi e se conosciamo il totale iniziale.
        # "remaining" e' gia stato calcolato sopra (blocchi [ ] ancora da fare in tutta la roadmap).
        local _run_progress=""
        if $ALL_PHASES && [[ "${initial_todo:-0}" -gt 0 ]] && [[ "${remaining}" =~ ^[0-9]+$ ]]; then
            local _done_run=$(( initial_todo - remaining )); [[ "$_done_run" -lt 0 ]] && _done_run=0
            _run_progress="Corsa: ${_done_run}/${initial_todo} fatti, ${remaining} mancano — "
        fi
        if [[ "${_pt:-0}" -gt 0 ]]; then
            log "━━━ ${BOLD}${PROJECT_NAME}${NC} · ${BOLD}Blocco $bid${NC} — ${_run_progress}Fase $cp: ${_pd}/${_pt} fatti, ${_px} da fare ${CYAN}(run #$br, tetto $MAX_BLOCKS)${NC} ━━━"
        else
            log "━━━ ${BOLD}${PROJECT_NAME}${NC} · ${BOLD}Blocco $bid${NC} — ${_run_progress}${CYAN}(run #$br, tetto $MAX_BLOCKS)${NC} ━━━"
        fi
        # A che punto siamo della corsa, e quanto e' costata finora. Due numeri per volta:
        # dove siamo arrivati e quanto abbiamo speso. Il modello e' quello che ha lavorato
        # davvero nel blocco precedente, non quello chiesto: se c'e' stato un ripiego, si vede.
        local _pvb _restano _in_corso
        local _tetto_res=$(( MAX_BLOCKS - br + 1 )); [[ "$_tetto_res" -lt 0 ]] && _tetto_res=0
        _pvb="$(previsione_corsa "$cp" "$_tetto_res")"; _restano="${_pvb%%|*}"
        if [[ "${PREVISTI_ALLA_PARTENZA:-0}" -gt 0 && "$_restano" =~ ^[0-9]+$ ]]; then
            _in_corso=$(( PREVISTI_ALLA_PARTENZA - _restano + 1 ))
            [[ "$_in_corso" -lt 1 ]] && _in_corso=1
            # Oltre la previsione non si dice piu' "3° di 2": o ci si sta fermando qui
            # (il blocco chiede Villa), o la previsione era sbagliata. In entrambi i casi
            # meglio tacere che dare un numero senza senso.
            [[ "$_in_corso" -le "$PREVISTI_ALLA_PARTENZA" ]] && \
                log "    ${CYAN}${_in_corso}° blocco di ${PREVISTI_ALLA_PARTENZA} previsti · dopo questo ne restano $(( _restano - 1 ))${NC}"
        fi
        if [[ "${TOKEN_CORSA:-0}" -gt 0 ]]; then
            log "    ${CYAN}speso finora: $(formatta_conto "$TOKEN_CORSA" "$COSTO_CORSA")${MODELLO_AL_LAVORO:+ · modello: $(modello_leggibile "$MODELLO_AL_LAVORO")}${NC}"
        fi
        # STOP PULITO: se il prossimo blocco e' marcato come checkpoint nella ROADMAP
        # (parola CHECKPOINT, oppure etichetta 👤 umano / 🤝 collaborativo), NON si lancia
        # nemmeno la sessione. Serve Villa: una sessione lanciata qui non potrebbe fare
        # nulla, e nel caso peggiore avvierebbe un server restando appesa fino al timeout.
        # Un blocco gia' spuntato [x] non si riapre in silenzio: rifarlo vorrebbe dire riscrivere
        # in modo diverso codice gia' provato e gia' usato dai blocchi successivi. Con la
        # riconciliazione all'avvio questo caso non dovrebbe piu' capitare: se capita lo stesso,
        # le due fonti sono rotte in un modo che il runner non sa raddrizzare da solo, e si ferma.
        if [[ "$(block_is_done "$cp" "$cb")" == "yes" ]]; then
            br=$((br - 1))
            log "${RED}$bid risulta gia' fatto [x] in roadmap: non lo riapro.${NC}"
            local el_dn; el_dn="$(( ($(date +%s) - st) / 60 ))"
            append_session_log "$bid" "ERROR" "Blocco gia' spuntato [x]: handoff e roadmap non concordano"
            update_progress "$cp" "$cb" "error" "Blocco gia' fatto"
            send_telegram_report "ERROR" "$bid" "$br" "$el_dn" "Il blocco $bid risulta gia' fatto in roadmap ma l'handoff ci manda li. Il runner si e fermato invece di rifarlo: controlla docs/diario/handoff.md e ROADMAP.md." "$(parse_handoff_next)" "0"
            break
        fi
        if [[ "$(block_is_checkpoint "$cp" "$cb")" == "yes" ]]; then
            br=$((br - 1))  # questo giro non esegue nulla: non contarlo
            local cp_title; cp_title="$(roadmap_block_title "$cp" "$cb")"
            log "${YELLOW}CHECKPOINT (da ROADMAP): $bid e' un punto di stop per Villa. Sessione NON lanciata.${NC}"
            write_checkpoint_handoff "$cp" "$cb" "$cp_title"
            local sm_cp sn_cp; sm_cp="$(parse_handoff_summary)"; sn_cp="$(parse_handoff_next)"
            append_session_log "$bid" "CHECKPOINT" "$sm_cp" "$(parse_handoff_per_villa)"; update_progress "$cp" "$cb" "checkpoint" "$sm_cp"
            local el_cp; el_cp="$(( ($(date +%s) - st) / 60 ))"
            send_notification "Metodo Villa" "Checkpoint $bid — serve Villa"
            send_telegram_report "CHECKPOINT" "$bid" "$br" "$el_cp" "$sm_cp" "$sn_cp" "0"
            break
        fi
        check_git_branch
        # Punto di partenza per sapere, a fine blocco, su quale pezzo del progetto si e'
        # lavorato: si confronta con dove si e' arrivati. Va preso qui, prima della
        # sessione, ed e' l'unico modo onesto — dedurlo dal testo del blocco vorrebbe
        # dire indovinare.
        HEAD_PRIMA_DEL_BLOCCO="$(git -C "$ROOT_DIR" rev-parse HEAD 2>/dev/null || true)"
        # L'INSTRADAMENTO — chi lavora a QUESTO blocco (cap. 22). Si riparte sempre dal
        # motore della corsa: un blocco instradato altrove non deve lasciare la sua scelta
        # in eredita' al blocco dopo. Fuori dalla modalita' ottimizzata, o su un blocco che
        # non ha il peso scritto, non cambia niente rispetto a prima.
        AGENTE="$CORSA_AGENTE"; MODEL_OVERRIDE="$CORSA_MODELLO"
        BLOCCO_PESO=""; BLOCCO_PROMOSSO=""
        # LA CACCIA AL SECONDO GIRO (cap. 29). Vale sempre, anche a instradamento spento: e'
        # disciplina, non scelta del motore. Al primo tentativo non si dice niente — costruire
        # un comando rosso per un problema che si vede a occhio e' burocrazia.
        BLOCCO_RITENTATO=""
        [[ "${consecutive_same:-0}" -ge 1 ]] && BLOCCO_RITENTATO="si"
        # QUANTO SI PUO' USCIRE DAL SEMINATO SU QUESTO BLOCCO (cap. 05). Il livello e' quello
        # della corsa, ma sui blocchi di peso 🔴 si stringe da solo: li' un extra non visto
        # costa troppo. Si legge il peso anche a instradamento spento, perche' questa non e'
        # una scelta di motore.
        LIBERTA_DEL_BLOCCO="$(liberta_del_blocco "$(block_peso "$cp" "$cb")" "$LIBERTA")"
        [[ "$LIBERTA_DEL_BLOCCO" != "$LIBERTA" ]] && \
            log "${BLUE}Blocco cruciale: liberta' stretta per questo blocco (era '$LIBERTA').${NC}"
        # Una sessione che si riprende appartiene al programma che l'ha aperta: mandarla a un
        # motore diverso vorrebbe dire chiedere a qualcuno di continuare una conversazione che
        # non ha mai avuto. Finche' si riprende, l'instradamento sta fermo.
        if $OTTIMIZZA && [[ -n "${SESSIONE_DA_RIPRENDERE:-}" ]]; then
            log_verbose "Instradamento fermo: si riprende una sessione gia' aperta."
        elif $OTTIMIZZA; then
            local peso; peso="$(block_peso "$cp" "$cb")"
            # Un blocco che torna una seconda volta ha gia' sbagliato una volta: rifarlo con
            # lo stesso motore che l'ha appena sbagliato e' il modo piu' rapido di sbagliarlo
            # di nuovo. L'errore promuove, cosi' nessuno deve indovinare in anticipo.
            if [[ -n "$peso" && "${consecutive_same:-0}" -ge 1 ]]; then
                peso="$(peso_promosso "$peso")"; BLOCCO_PROMOSSO="si"
                log "${YELLOW}Blocco $bid gia' passato di qui: promosso a '$peso'.${NC}"
            fi
            if [[ -n "$peso" ]]; then
                # Il peso si segna solo se ha davvero scelto il motore: altrimenti il
                # record spiegherebbe una scelta che non c'e' stata.
                if instrada_per_peso "$peso"; then
                    BLOCCO_PESO="$peso"
                    log "${BLUE}Instradamento: $bid e' '$peso' → $(nome_agente_leggibile) ($MODEL_OVERRIDE)${NC}"
                else
                    log "${YELLOW}Instradamento: per '$peso' servirebbe un programma non installato — resta il motore della corsa.${NC}"
                fi
            fi
        fi
        local pr; pr="$(build_prompt "$cp" "$cb" "$hc" "$fb")"
        # L'obiezione dell'occhio esterno e' entrata nel messaggio: da qui in poi non vale
        # piu' per nessuno. Se restasse, il blocco DOPO se la ritroverebbe addosso.
        OCCHIO_ESTERNO_MOTIVO=""
        # Il record del "mentre lavora": da qui in poi la schermata vede il blocco in corso.
        scrivi_durante_blocco "$bid" "$(roadmap_block_title "$cp" "$cb")" "${_in_corso:-}"
        local _sessione_andata="no"
        if run_agent_session "$pr" "$bid"; then _sessione_andata="si"; fi
        scrivi_durante_pausa
        if [[ "$_sessione_andata" != "si" ]]; then
            # Una sessione puo' morire DOPO aver finito: il 2026-08-10 un blocco e' stato
            # committato e pushato alle 04:49 e la sessione e' rimasta viva altri 87 minuti,
            # finche' il timeout l'ha uccisa e la corsa si e' fermata a due blocchi dalla fine.
            # Il lavoro c'era: a non arrivare era la fine del processo. Se sul disco il blocco
            # risulta spuntato e l'handoff e' gia' avanti, il timeout non ferma la corsa.
            local _hp2 _hb2; _hp2="$(parse_handoff_phase)"; _hb2="$(parse_handoff_block)"
            if [[ "$(block_is_done "$cp" "$cb")" == "yes" ]] && [[ -n "$_hp2" && -n "$_hb2" ]] \
                && [[ "$_hp2" != "$cp" || "$_hb2" != "$cb" ]]; then
                log "${YELLOW}$bid risulta chiuso e l'handoff e' gia' a F${_hp2}B${_hb2}: la sessione e' morta dopo il lavoro, proseguo.${NC}"
                cp="$_hp2"; cb="$_hb2"
                continue
            fi
            local el_now; el_now="$(( ($(date +%s) - st) / 60 ))"
            local el_block; el_block=$(( ($(date +%s) - block_st) / 60 ))
            # Handoff NON riscritto: la verifica non si legge (sarebbe quella di un altro
            # blocco); motore e durata invece sono di questa sessione e si dicono.
            append_session_log "$bid" "FAILED" "Errore o timeout" "" "$(dettagli_chiusura_blocco "$el_block" "no")"; update_progress "$cp" "$cb" "error" "Fallito"
            send_notification "Metodo Villa" "Blocco $bid fallito"
            # Anche qui si passa dal guardiano: una sessione crollata o rimasta appesa e' uno
            # stop NON programmato, e sono proprio quelli per cui esiste (cap. 24 e 27).
            if guardiano_interviene "$bid" "FAILED"; then
                hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                last_bid=""; consecutive_same=0; SESSIONE_DA_RIPRENDERE=""; BLOCCHI_DI_FILA=0
                [[ $br -lt $MAX_BLOCKS ]] && sleep 5
                continue
            fi
            send_telegram_report "FAILED" "$bid" "$br" "$el_now" "Sessione crashata o timeout" "" "$el_block"; break; fi
        local s; s="$(parse_handoff_status)"; local sm; sm="$(parse_handoff_summary)"; local sn; sn="$(parse_handoff_next)"
        # Aggiorna fase/blocco dall'handoff (sono stringhe, non numeri)
        local np nb; np="$(parse_handoff_phase)"; nb="$(parse_handoff_block)"
        [[ -n "$np" ]] && cp="$np"
        [[ -n "$nb" ]] && cb="$nb"
        log "Status: ${BOLD}$s${NC} — $sm"
        local el_now; el_now="$(( ($(date +%s) - st) / 60 ))"
        local el_block; el_block=$(( ($(date +%s) - block_st) / 60 ))
        append_session_log "$bid" "$s" "$sm" "$(parse_handoff_per_villa)" "$(dettagli_chiusura_blocco "$el_block")"; update_progress "$cp" "$cb" "$s" "$sm"
        # L'OCCHIO ESTERNO (cap. 05). Vale sui due stati che dichiarano il blocco finito, e
        # sta PRIMA di deciderne le conseguenze: un blocco non finito non si annuncia finito,
        # non si spinge sul deposito e non chiude una fase. Un punto solo per tutti e due.
        if [[ "$s" == "CONTINUE" || "$s" == "PHASE_COMPLETE" ]]; then
            occhio_esterno_guarda "$bid" "$bfase" "$bblocco"
            if [[ "$OCCHIO_ESTERNO_ESITO" == "riapri" ]]; then
                if occhio_esterno_riapri "$bid" "$bfase" "$bblocco"; then
                    cp="$bfase"; cb="$bblocco"
                    # Si RIPARA dov'e' il lavoro, non si rifa' da fuori: se la sessione che ha
                    # appena lavorato e' ancora buona, l'obiezione le arriva li' dentro e il
                    # contesto non si butta. Solo se non si puo' si riapre da zero.
                    if si_puo_riparare_qui; then
                        SESSIONE_DA_RIPRENDERE="$SESSIONE_CORRENTE"
                        log "    ${CYAN}riparazione nella stessa sessione (${CONTESTO_PERCENTO}% della finestra): il lavoro fatto resta${NC}"
                    else
                        SESSIONE_DA_RIPRENDERE=""
                        log "    ${CYAN}sessione nuova per la riparazione (${CONTESTO_PERCENTO:-0}% della finestra)${NC}"
                    fi
                    BLOCCHI_DI_FILA=0
                    hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                    [[ $br -lt $MAX_BLOCKS ]] && sleep 5
                    continue
                fi
                # La roadmap non si e' lasciata riaprire: rimandarci il runner lo fermerebbe
                # con un errore. Non si tira dritto e non si insiste: decide il guardiano.
                OCCHIO_ESTERNO_ESITO="al_guardiano"
            fi
            if [[ "$OCCHIO_ESTERNO_ESITO" == "al_guardiano" ]]; then
                # Bocciato due volte (o non riapribile): non si insiste da soli e non si tira
                # dritto. Chi decide e' il guardiano, che sa anche chiedere a Villa (cap. 24).
                if guardiano_interviene "$bid" "OCCHIO ESTERNO ($OCCHIO_ESTERNO_RIGA)"; then
                    cp="$(parse_handoff_phase)"; cb="$(parse_handoff_block)"
                    hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                    last_bid=""; consecutive_same=0; SESSIONE_DA_RIPRENDERE=""; BLOCCHI_DI_FILA=0
                    [[ $br -lt $MAX_BLOCKS ]] && sleep 5
                    continue
                fi
                send_telegram_report "CHECKPOINT" "$bid" "$br" "$el_now" \
                    "L'occhio esterno ha bocciato $bid e il guardiano non ha sbloccato: $OCCHIO_ESTERNO_RIGA" \
                    "$sn" "$el_block"
                break
            fi
        fi
        case "$s" in
            CONTINUE) log "${GREEN}Continuo${NC}"; hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                push_current_branch
                send_telegram_report "BLOCCO_OK" "$bid" "$br" "$el_now" "$sm" "$sn" "$el_block"
                # Il blocco dopo continua qui, o si ricomincia pulito? Si concatena SOLO dopo
                # un blocco andato bene (siamo nel ramo CONTINUE) e solo se nella memoria di
                # lavoro c'e' ancora spazio: il margine fra la soglia e il tetto e' lo spazio
                # in cui il blocco nuovo deve stare.
                if si_puo_continuare; then
                    BLOCCHI_DI_FILA=$(( BLOCCHI_DI_FILA + 1 )); SESSIONI_RIUSATE=$(( SESSIONI_RIUSATE + 1 ))
                    SESSIONE_DA_RIPRENDERE="$SESSIONE_CORRENTE"
                    log "    ${GREEN}stessa sessione per il prossimo blocco (${CONTESTO_PERCENTO}% ≤ ${CONTESTO_SOGLIA_NUOVO}%): il preambolo non si ripaga${NC}"
                else
                    if [[ -n "$SESSIONE_DA_RIPRENDERE" ]]; then
                        log "    ${CYAN}sessione chiusa dopo $(( BLOCCHI_DI_FILA + 1 )) blocchi di fila${NC}"
                    elif [[ "${CONTESTO_PERCENTO:-0}" -gt 0 ]]; then
                        log "    ${CYAN}sessione nuova per il prossimo blocco (${CONTESTO_PERCENTO}% > ${CONTESTO_SOGLIA_NUOVO}%)${NC}"
                    fi
                    SESSIONE_DA_RIPRENDERE=""; BLOCCHI_DI_FILA=0
                fi;;
            CHECKPOINT) log "${YELLOW}CHECKPOINT — decisione umana${NC}"; send_notification "Metodo Villa" "Checkpoint $bid"
                push_current_branch
                # Prima di chiudere la corsa si passa dal guardiano: scrive a Villa, aspetta,
                # e se non lo sente decide lui secondo le regole. Se se la cava, si riparte.
                if guardiano_interviene "$bid" "CHECKPOINT"; then
                    hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                    last_bid=""; consecutive_same=0; SESSIONE_DA_RIPRENDERE=""; BLOCCHI_DI_FILA=0
                    [[ $br -lt $MAX_BLOCKS ]] && sleep 5
                    continue
                fi
                send_telegram_report "CHECKPOINT" "$bid" "$br" "$el_now" "$sm" "$sn" "$el_block"; break;;
            PHASE_COMPLETE) log "${GREEN}FASE $cp COMPLETATA${NC}"; send_notification "Metodo Villa" "Fase $cp completata!"
                push_current_branch
                send_telegram_report "PHASE_COMPLETE" "$bid" "$br" "$el_now" "$sm" "$sn" "$el_block"
                # Modalita --tutte-le-fasi: rete di sicurezza. Se Claude emette comunque
                # PHASE_COMPLETE ma restano blocchi da fare nelle fasi successive, NON ci si ferma:
                # si prosegue con la fase successiva. Lo stop per checkpoint/errore/blocco resta
                # garantito dagli altri rami del case (Claude segnala CHECKPOINT per i blocchi umani).
                if $ALL_PHASES; then
                    local _rem_after; _rem_after="$(count_remaining_blocks)"
                    if [[ "$_rem_after" =~ ^[0-9]+$ ]] && [[ "$_rem_after" -gt 0 ]]; then
                        log "${BOLD}Modalita tutte-le-fasi: restano ${_rem_after} blocchi, proseguo con la fase successiva.${NC}"
                        hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                        last_bid=""; consecutive_same=0; SESSIONE_DA_RIPRENDERE=""; BLOCCHI_DI_FILA=0   # sessione pulita al cambio fase
                        [[ $br -lt $MAX_BLOCKS ]] && sleep 5
                        continue
                    fi
                    log "${GREEN}Modalita tutte-le-fasi: nessun altro blocco da fare. Stop.${NC}"
                fi
                break;;
            ERROR) log "${RED}ERRORE $bid${NC}"; send_notification "Metodo Villa" "Errore $bid"
                # E' il caso in cui il guardiano serve di piu': un occhio nuovo su un errore
                # che l'agente non ha saputo risolvere spesso lo risolve.
                if guardiano_interviene "$bid" "ERROR"; then
                    hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                    last_bid=""; consecutive_same=0; SESSIONE_DA_RIPRENDERE=""; BLOCCHI_DI_FILA=0
                    [[ $br -lt $MAX_BLOCKS ]] && sleep 5
                    continue
                fi
                send_telegram_report "ERROR" "$bid" "$br" "$el_now" "$sm" "$sn" "$el_block"; break;;
            BLOCKED) log "${YELLOW}BLOCCATO${NC}"; send_notification "Metodo Villa" "Bloccato $bid"
                push_current_branch
                if guardiano_interviene "$bid" "BLOCKED"; then
                    hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                    last_bid=""; consecutive_same=0; SESSIONE_DA_RIPRENDERE=""; BLOCCHI_DI_FILA=0
                    [[ $br -lt $MAX_BLOCKS ]] && sleep 5
                    continue
                fi
                send_telegram_report "BLOCKED" "$bid" "$br" "$el_now" "$sm" "$sn" "$el_block"; break;;
            MISSING) log "${RED}Handoff mancante${NC}"; send_notification "Metodo Villa" "Handoff mancante"
                if guardiano_interviene "$bid" "MISSING"; then
                    hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                    last_bid=""; consecutive_same=0; SESSIONE_DA_RIPRENDERE=""; BLOCCHI_DI_FILA=0
                    [[ $br -lt $MAX_BLOCKS ]] && sleep 5
                    continue
                fi
                send_telegram_report "MISSING" "$bid" "$br" "$el_now" "Handoff non trovato" "" "$el_block"; break;;
            *) log "${YELLOW}Status ignoto: $s${NC}"
                if guardiano_interviene "$bid" "STATO IGNOTO ($s)"; then
                    hc="$(cat "$PROJECT_DIR/$HANDOFF_FILE")"; fb="false"
                    last_bid=""; consecutive_same=0; SESSIONE_DA_RIPRENDERE=""; BLOCCHI_DI_FILA=0
                    [[ $br -lt $MAX_BLOCKS ]] && sleep 5
                    continue
                fi
                break;;
        esac
        [[ $br -lt $MAX_BLOCKS ]] && sleep 5
    done
    # La corsa e' finita (bene o male): il record non deve continuare a dire che qualcuno
    # sta lavorando, ne' che la corsa e' ancora aperta. La cronologia resta dov'e', nel
    # diario di sessione.
    scrivi_durante_fine
    local et; et="$(date +%s)"; local el=$(((et-st)/60))
    log "\n━━━ ${BOLD}RIEPILOGO${NC} ━━━"
    log "Progetto : ${BOLD}${PROJECT_NAME}${NC} · motore: $(nome_agente_leggibile)${MODELLO_AL_LAVORO:+ · modello: $(modello_leggibile "$MODELLO_AL_LAVORO")}"
    log "Blocchi  : $br eseguiti${PREVISTI_ALLA_PARTENZA:+ (ne erano previsti $PREVISTI_ALLA_PARTENZA)} | Tempo: ${el}min | Status: $(parse_handoff_status)"
    if [[ "${SESSIONI_RIUSATE:-0}" -gt 0 ]]; then
        log "Sessioni : il preambolo del blocco NON e' stato ripagato ${SESSIONI_RIUSATE} volte su $br"
        log "           ${CYAN}(blocchi partiti dentro una sessione gia' calda: e' il risparmio piu' grosso)${NC}"
    fi
    if [[ "${OCCHIO_ESTERNO_FERMATE:-0}" -gt 0 ]]; then
        log "Occhio esterno: ha riaperto ${OCCHIO_ESTERNO_FERMATE} blocchi che si erano dichiarati finiti"
        log "           ${CYAN}(li trovi nel diario di sessione come RIAPERTO, con il motivo)${NC}"
    fi
    if [[ -n "${GUARDIANO_DECISIONI:-}" ]]; then
        log "Guardiano: ha rimesso in moto la corsa ${GUARDIANO_INTERVENTI} volte —"
        while IFS= read -r _r; do [[ -n "$_r" ]] && log "           $_r"; done <<< "$GUARDIANO_DECISIONI"
        log "           ${CYAN}(tutte in docs/diario/decisioni-da-rivedere.md, con il perche')${NC}"
    fi
    if [[ "${TOKEN_CORSA:-0}" -gt 0 ]]; then
        log "Consumo  : ${BOLD}$(formatta_conto "$TOKEN_CORSA" "$COSTO_CORSA")${NC} in tutta la corsa$( [[ $br -gt 0 ]] && echo " · $(formatta_conto $((TOKEN_CORSA / br)) "$(awk -v c="$COSTO_CORSA" -v n="$br" 'BEGIN{printf "%.6f", c/n}')") a blocco, in media")"
        log "           ${CYAN}(costo a listino calcolato dal programma: con l'abbonamento non e' un addebito)${NC}"
    fi
    if [[ $br -ge $MAX_BLOCKS ]]; then
        log "${YELLOW}Tetto di sicurezza ($MAX_BLOCKS) raggiunto — paracadute anti-runaway, NON fine lavoro. Controlla docs/diario/handoff.md e rilancia se restano blocchi.${NC}"
        send_notification "Metodo Villa" "Tetto sicurezza $MAX_BLOCKS raggiunto in ${el}min"
        send_telegram_report "LIMITE RAGGIUNTO" "$bid" "$br" "$el" "Raggiunto il tetto di sicurezza di $MAX_BLOCKS blocchi in una sola esecuzione: e un paracadute anti-runaway, NON la fine del lavoro pianificato. Controlla l'handoff e rilancia il runner se restano blocchi da fare." "$(parse_handoff_next)" "0"
    fi
    echo -ne '\a'
}
# Esegui main solo se lo script e' lanciato direttamente, non quando viene "sourced" (es.
# da uno script di test che verifica le singole funzioni in isolamento). Gli avviatori
# lanciano lo script direttamente, quindi main parte regolarmente.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
