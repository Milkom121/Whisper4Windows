#!/usr/bin/env bash
# CHI ESEGUE IL LAVORO — la scelta del programma, in un posto solo.
# Regole e contratto: .claude/metodo-villa/22-agenti-esecutori.md
#
# Questo file non si lancia: si carica (source) da chi deve far lavorare un agente.
# Oggi lo caricano il runner (per i blocchi) e lo strumento delle corsie (per il Consiglio
# degli Agenti). Prima la scelta viveva solo nel runner, e il Consiglio chiamava Claude Code
# a prescindere: un progetto che aveva scelto un altro programma se lo ritrovava scavalcato
# senza accorgersene — e senza sapere che stava spendendo altrove.

# Ordine di autorita': quello che si scrive sulla riga di comando vince sulla configurazione
# del progetto, che vince sul default. Il default resta Claude Code: chi non fa niente non si
# accorge di nulla. Va chiamata DOPO aver caricato .env.runner.
risolvi_agente() {
    AGENTE="${AGENTE:-${METODO_AGENTE:-claude}}"
    MODEL_OVERRIDE="${MODEL_OVERRIDE:-${METODO_MODELLO:-}}"
    IMPEGNO="${IMPEGNO:-${METODO_IMPEGNO:-high}}"
    case "$AGENTE" in
        claude|opencode) ;;
        *) echo "Agente sconosciuto: '$AGENTE'. Quelli supportati sono: claude, opencode (vedi .claude/metodo-villa/22-agenti-esecutori.md)" >&2; return 1;;
    esac
    # L'impegno si convalida QUI, e non e' pignoleria: OpenCode ingoia in silenzio anche un
    # valore inventato (provato sul campo il 2026-08-15 con --variant pippo, nessun errore).
    # Un impegno scritto male passerebbe inosservato e la corsa girerebbe al livello di
    # default per giorni, senza che niente lo dica.
    case "$IMPEGNO" in
        low|medium|high|max) ;;
        *) echo "Impegno sconosciuto: '$IMPEGNO'. Quelli ammessi sono: low, medium, high, max (vedi .claude/metodo-villa/22-agenti-esecutori.md)" >&2; return 1;;
    esac
    return 0
}

# CHI PRENDE LE DECISIONI CHE CONTANO — architettura, chi-fa-cosa, il guardiano che decide
# di notte, il Consiglio degli Agenti. Non passano dal motore economico del progetto: un
# errore li' non lo prende nessun test e si propaga a tutto il lavoro che viene dopo.
# Prima del 2026-08-15 un progetto con METODO_AGENTE=opencode faceva decidere quelle cose
# al suo modello di corsa, senza che nessuno lo avesse deciso.
TESTA_AGENTE="${METODO_TESTA_AGENTE:-claude}"
TESTA_MODELLO="${METODO_TESTA_MODELLO:-claude-opus-5}"

# Esegue una qualunque delle funzioni qui sotto con la testa invece che col motore di corsa.
# In subshell: le variabili tornano com'erano appena la chiamata finisce.
# Se il programma della testa non e' installato si prosegue col motore del progetto — meglio
# una decisione presa da un modello meno bravo che una corsa che non parte.
con_la_testa() {
    if command -v "$TESTA_AGENTE" >/dev/null 2>&1; then
        ( AGENTE="$TESTA_AGENTE"; MODEL_OVERRIDE="$TESTA_MODELLO"; "$@" )
    else
        "$@"
    fi
}

# --- UN MOTORE PER OGNI PESO (l'instradamento, cap. 22) ---------------------------------
#
# La scala e' una sola e sale: ordinario -> importante -> cruciale. Quello che sbagliare
# costa poco va al motore che costa poco.
#
#   🔴 cruciale   architettura, schema dei dati, sicurezza, blocchi da cui dipende il resto
#   🟡 importante schermate nuove e ridisegni: i test non giudicano la bellezza
#   🟢 ordinario  codice di routine, test, documentazione, configurazione
#
# La mappa vive QUI e in nessun altro posto, e non e' configurabile per progetto: se ogni
# progetto avesse la sua, fra sei mesi nessuno saprebbe piu' dire perche' un blocco e'
# finito su un motore invece che su un altro.
MOTORE_CRUCIALE="claude|claude-opus-5"
MOTORE_IMPORTANTE="opencode|moonshotai/kimi-k3"
MOTORE_ORDINARIO="opencode|zai-coding-plan/glm-5.3"

# Da un peso al motore che gli tocca. Stampa "agente|modello"; stampa vuoto se il peso non
# e' uno dei tre — e allora chi chiama tiene il motore della corsa.
motore_del_peso() {
    case "$1" in
        cruciale)   printf '%s' "$MOTORE_CRUCIALE";;
        importante) printf '%s' "$MOTORE_IMPORTANTE";;
        ordinario)  printf '%s' "$MOTORE_ORDINARIO";;
    esac
}

# Il gradino sopra, per la promozione: un blocco che fallisce non si rifa' con lo stesso
# motore che l'ha appena sbagliato. Sopra "cruciale" non c'e' niente: si resta li'.
peso_promosso() {
    case "$1" in
        ordinario)  printf 'importante';;
        importante) printf 'cruciale';;
        *)          printf 'cruciale';;
    esac
}

# Imposta AGENTE e MODEL_OVERRIDE per il peso indicato. Non fa niente — e lo dice tacendo —
# se il peso e' ignoto o se il programma di quel motore non e' installato: in dubbio si
# lavora col motore della corsa, che e' il comportamento di sempre.
instrada_per_peso() {
    local coppia; coppia="$(motore_del_peso "$1")"
    [[ -n "$coppia" ]] || return 1
    local ag="${coppia%%|*}" mo="${coppia#*|}"
    command -v "$ag" >/dev/null 2>&1 || return 1
    AGENTE="$ag"; MODEL_OVERRIDE="$mo"
    return 0
}

# Le impostazioni della corsa (oggi: il filtro dell'output dei test). Vivono accanto a questo
# file, che e' la macchina del Metodo: si trovano da soli anche quando il runner lavora dentro
# un modulo di monorepo.
METODO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
IMPOSTAZIONI_RUNNER="$METODO_DIR/impostazioni-runner.json"

# Il nome del programma come lo direbbe una persona, per i messaggi e per il quadro della
# corsa: "claude" da solo non dice a Villa chi sta lavorando.
nome_agente_leggibile() {
    case "${AGENTE:-claude}" in
        claude)   echo "Claude Code";;
        opencode) echo "OpenCode";;
        *)        echo "${AGENTE:-sconosciuto}";;
    esac
}


# Quanto il modello deve pensare prima di rispondere. I due programmi lo chiamano in modo
# diverso — Claude Code '--effort', OpenCode '--variant' — e il livello piu' basso ha due
# nomi: 'low' per Claude Code, 'minimal' per OpenCode. E' l'unico punto in cui il Metodo
# traduce, e traduce un LIVELLO, non un identificativo di modello (cap. 22).
# Misurato il 2026-08-15 su GLM-5.3: a impegno minimo ragiona 305 unita', ad alto 800.
impegno_per_agente() {
    local livello="${IMPEGNO:-high}"
    case "${AGENTE:-claude}" in
        claude)   printf -- '--effort %s' "$livello";;
        opencode) [[ "$livello" == "low" ]] && livello="minimal"; printf -- '--variant %s' "$livello";;
    esac
}

# Lancia l'agente scelto sul file di messaggio indicato, nella cartella CARTELLA_DI_LAVORO.
# Va chiamata dentro una subshell: 'exec' sostituisce il processo della subshell con
# l'agente, cosi' il PID che il chiamante ha in mano e' quello vero e il cane da guardia
# puo' ucciderne l'intero albero.
avvia_agente() {
    local pf="$1"
    cd "${CARTELLA_DI_LAVORO:-$PWD}" || exit 1
    # $m non e' quotato apposta: si divide in due argomenti quando valorizzato e sparisce
    # del tutto quando vuoto (default del programma).
    local m=""; [[ -n "${MODEL_OVERRIDE:-}" ]] && m="--model $MODEL_OVERRIDE"
    # Come $m: non quotato apposta, si divide nei due argomenti del flag.
    local i; i="$(impegno_per_agente)"
    case "${AGENTE:-claude}" in
        claude)
            # --settings AGGIUNGE impostazioni per questa corsa e basta: il settings.json del
            # progetto resta com'e'. Dentro c'e' il filtro dell'output dei test. Se il file
            # manca (progetto vecchio, Metodo non aggiornato) il flag sparisce e non cambia
            # niente. In array perche' un percorso puo' contenere spazi.
            local extra=()
            [[ -f "$IMPOSTAZIONI_RUNNER" ]] && extra+=(--settings "$IMPOSTAZIONI_RUNNER")
            # RIPRENDERE invece di ricominciare: quando il blocco precedente e' finito bene e
            # nella memoria di lavoro c'e' ancora spazio, il blocco dopo continua nella stessa
            # sessione. Cosi' le regole e il contesto del progetto si pagano UNA volta invece
            # di una per blocco (cap. 26). Vuoto = sessione nuova, come sempre.
            if [[ -n "${SESSIONE_DA_RIPRENDERE:-}" ]]; then
                extra+=(--resume "$SESSIONE_DA_RIPRENDERE")
            elif [[ -n "${SESSIONE_IMPOSTA:-}" ]]; then
                # L'id della sessione lo decide il runner PRIMA di partire, invece di
                # scoprirlo alla fine: cosi' sa da subito dove Claude Code scrive il suo
                # diario, e puo' guardare se sta ancora lavorando (cap. 27). Senza questo,
                # l'unico modo di sapere se e' vivo sarebbe aspettare che finisca.
                extra+=(--session-id "$SESSIONE_IMPOSTA")
            fi
            # --output-format json: l'uscita diventa un oggetto che contiene la risposta E il
            # conto (token consumati, costo, modello che ha davvero lavorato). Serve al
            # contatore del runner; chi legge il registro ritrova il testo di sempre, perche'
            # il runner estrae la risposta e scrive quella. Se qualcosa va storto e l'uscita
            # non e' leggibile, il runner ripiega e scrive tutto cosi' com'e'.
            exec claude -p --output-format json --dangerously-skip-permissions $m $i ${extra[@]+"${extra[@]}"} < "$pf"
            ;;
        opencode)
            # IL MESSAGGIO PASSA DA STANDARD INPUT, COME PER CLAUDE CODE. Non si torna
            # all'allegato (--file), e il motivo e' misurato, non teorico: OpenCode rende il
            # file allegato come l'uscita di uno strumento e la TRONCA a 50 KB, scrivendo in
            # coda "Output capped at 50 KB". Sul messaggio di un progetto grande (Fedorium,
            # 250.000 caratteri) arrivava il 20%: si perdevano il grosso della roadmap, la
            # riga che dice QUALE blocco fare e il diario del blocco precedente. Misurato il
            # 2026-08-16 su 110 consegne troncate su 119. L'agente non lavorava alla cieca —
            # si accorgeva del taglio e si rileggeva il file a pagine, arrivando al 100% —
            # ma pagava 5-12 giri a vuoto per blocco, cioe' un decimo del tempo, ogni volta.
            # Provato che da standard input passa intero: 245.018 caratteri con una parola
            # nascosta in fondo, riportata correttamente.
            # --auto salta le richieste di permesso.
            # --format json: come per Claude Code, l'uscita porta con se' il conto (token e
            # costo, un evento per ogni passo). Senza, il consumo di OpenCode risultava zero
            # e meta' del contatore era cieca. Il registro non ci perde niente: il runner
            # rimette in fila il testo della risposta e scrive quello.
            exec opencode run --auto --format json $m $i < "$pf"
            ;;
        *)
            echo "Agente non gestito: ${AGENTE:-}" >&2; exit 1
            ;;
    esac
}

# Come sopra, ma per chi vuole l'uscita invece del PID: la subshell assorbe l'exec.
esegui_agente() { ( avvia_agente "$1" ); }

# Una domanda secca all'agente, fuori dal giro dei blocchi: si passa un testo, si riceve la
# risposta. La usa il guardiano (metodo-guardiano.sh) quando il runner si ferma e serve
# qualcuno che ragioni sulla situazione. Niente permessi da saltare e nessuna impostazione
# della corsa: qui non si tocca il progetto, si pensa e basta.
# Restituisce il testo della risposta; vuoto se qualcosa va storto (chi chiama decide).
chiedi_all_agente() {
    local testo="$1" minuti="${2:-5}"
    local pf; pf="$(mktemp)"; printf '%s' "$testo" > "$pf"
    local of; of="$(mktemp)"; local ec=0
    case "${AGENTE:-claude}" in
        claude)
            timeout "$(( minuti * 60 ))" claude -p --output-format json \
                ${MODEL_OVERRIDE:+--model "$MODEL_OVERRIDE"} $(impegno_per_agente) < "$pf" > "$of" 2>/dev/null || ec=$?
            [[ $ec -eq 0 ]] && python "$METODO_DIR/leggi-conto.py" testo < "$of"
            ;;
        opencode)
            # Da standard input, per la stessa ragione di avvia_agente: l'allegato viene
            # troncato a 50 KB e una domanda al guardiano si porta dietro il contesto dello
            # stop, che grande non e' ma nemmeno garantito piccolo.
            timeout "$(( minuti * 60 ))" opencode run ${MODEL_OVERRIDE:+--model "$MODEL_OVERRIDE"} $(impegno_per_agente) \
                < "$pf" > "$of" 2>/dev/null || ec=$?
            [[ $ec -eq 0 ]] && cat "$of"
            ;;
    esac
    rm -f "$pf" "$of"
    return 0
}

# L'agente scelto e' davvero installato? Messaggio che dice cosa fare, non solo cosa manca.
verifica_agente_installato() {
    command -v "${AGENTE:-claude}" >/dev/null 2>&1 && return 0
    case "${AGENTE:-claude}" in
        claude)   echo "Claude Code non e' installato (comando 'claude' non trovato).";;
        opencode) echo "OpenCode non e' installato (comando 'opencode' non trovato). Installalo da https://opencode.ai, oppure lancia senza --agente per usare Claude Code.";;
        *)        echo "Il programma '${AGENTE:-}' non e' installato.";;
    esac
    return 1
}
