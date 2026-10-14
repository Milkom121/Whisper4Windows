#!/usr/bin/env bash
# L'OCCHIO ESTERNO — chi controlla il blocco non e' chi l'ha fatto.
#
# PERCHE' ESISTE. Fino a qui, alla fine di ogni blocco, lo stesso agente scriveva il codice,
# scriveva le prove, eseguiva le prove e si dava il verde. 1.468 blocchi su quattro progetti,
# tutti chiusi cosi'. Poi su Fedorium, dopo 394 blocchi tutti verdi, sei giri fatti a mano
# hanno trovato 148 difetti, 66 dei quali meccanici — cose rotte, non questioni di gusto.
# Il capitolo 15 del Metodo lo dice gia' a chiare lettere ("chi ha scritto l'artefatto e'
# cieco ai propri errori") e poi esenta proprio il blocco, cioe' il posto da cui passa tutto
# il lavoro. Questo file toglie l'esenzione.
#
# QUANTO COSTA. Guarda solo il compito e la differenza, mai il progetto: la differenza
# mediana di un blocco e' 337 righe, circa 4.000 unita' di testo, contro i 17,5 milioni che
# un blocco consuma. Sotto lo 0,2%. E' il gate piu' economico che il Metodo abbia.
#
# COSA NON FA. Non scrive codice, non apre file, non giudica lo stile ne' l'architettura.
# In dubbio lascia passare: un blocco fermato a torto costa un blocco intero rifatto.
#
# Non si lancia a mano: lo chiama il runner. Configurazione in .env.runner:
#   OCCHIO_ESTERNO=si|no          (default si)
#   OCCHIO_ESTERNO_MAX_RIGHE=1200 (oltre, la differenza si manda tagliata + il riepilogo)
#   OCCHIO_ESTERNO_MAX_FERMATE=3  (quante volte puo' riaprire un blocco in una corsa)
#   OCCHIO_ESTERNO_MINUTI=5       (quanto aspettare la sua risposta)

OCCHIO_ESTERNO="${OCCHIO_ESTERNO:-si}"
OCCHIO_ESTERNO_MAX_RIGHE="${OCCHIO_ESTERNO_MAX_RIGHE:-1200}"
OCCHIO_ESTERNO_MAX_FERMATE="${OCCHIO_ESTERNO_MAX_FERMATE:-3}"
OCCHIO_ESTERNO_MINUTI="${OCCHIO_ESTERNO_MINUTI:-5}"

OCCHIO_ESTERNO_ESITO="passa"     # passa | riapri | al_guardiano
OCCHIO_ESTERNO_MOTIVO=""         # l'obiezione per il prompt del giro dopo (vuota se passa)
OCCHIO_ESTERNO_RIGA=""           # una riga sola, per il diario e per Telegram
OCCHIO_ESTERNO_FERMATE=0         # quante volte ha riaperto un blocco in questa corsa
OCCHIO_ESTERNO_GIA_VISTI=""      # i blocchi che ha gia' riaperto una volta

# --- COSA GUARDA -------------------------------------------------------------------------

# La differenza vera del blocco: da dov'era il progetto quando il blocco e' cominciato a
# dov'e' adesso, cartella di lavoro compresa (un blocco che non ha committato ha comunque
# lasciato qualcosa, e va guardato lo stesso). I diari della corsa restano fuori: ci
# finiscono sempre e non dicono niente su cio' che e' stato costruito.
occhio_esterno_differenza() {
    local da="$1"
    local d; d="$(git -C "$ROOT_DIR" diff "$da" -- . ':(exclude)docs/diario' 2>/dev/null || true)"
    if [[ -z "${d//[[:space:]]/}" ]]; then
        printf 'IL BLOCCO NON HA CAMBIATO NIENTE fuori dai diari.'
        return 0
    fi
    local righe; righe="$(printf '%s\n' "$d" | wc -l | tr -d ' ')"
    if [[ "$righe" -le "$OCCHIO_ESTERNO_MAX_RIGHE" ]]; then
        printf '%s' "$d"
        return 0
    fi
    # Differenza enorme (succede in un blocco su dieci): si manda il riepilogo per intero,
    # cosi' cio' che e' stato toccato si vede tutto, e poi le prime righe. Meglio una vista
    # parziale dichiarata che una domanda da mezzo milione di unita'.
    printf 'DIFFERENZA GRANDE: %s righe, qui sotto ne trovi le prime %s. Prima, il riepilogo completo dei file toccati.\n\n' \
        "$righe" "$OCCHIO_ESTERNO_MAX_RIGHE"
    git -C "$ROOT_DIR" diff --stat "$da" -- . ':(exclude)docs/diario' 2>/dev/null || true
    printf '\n--- le prime %s righe ---\n' "$OCCHIO_ESTERNO_MAX_RIGHE"
    printf '%s\n' "$d" | head -n "$OCCHIO_ESTERNO_MAX_RIGHE"
}

# La domanda. E' la parte che conta: un occhio da fuori senza una lista precisa di cose da
# cercare diventa un secondo parere sullo stile, cioe' rumore.
occhio_esterno_domanda() {
    local bid="$1" compito="$2" tesi="$3" prove="$4" differenza="$5"
    # I valori di riserva si calcolano QUI e non dentro il testo: un apostrofo dentro
    # ${x:-...} apre una virgoletta e la sostituzione non si chiude piu' (bad substitution).
    [[ -n "${compito//[[:space:]]/}" ]] || compito="(la roadmap non dice altro oltre al numero del blocco)"
    [[ -n "${tesi//[[:space:]]/}" ]]    || tesi="(non lo ha scritto)"
    [[ -n "${prove//[[:space:]]/}" ]]   || prove="(non dichiarata)"
    cat << EOF
Sei L'OCCHIO ESTERNO di una corsa automatica del Metodo Villa.

Un agente ha appena dichiarato chiuso il blocco $bid. Quell'agente ha scritto il codice, ha
scritto le prove, ha eseguito le prove e si e' dato il verde da solo. Tu sei l'unico che
guarda quel lavoro senza averlo fatto.

Non scrivi codice, non tocchi niente, non apri altri file: guardi solo cio' che sta qui
sotto e rispondi a una domanda sola — IL BLOCCO E' DAVVERO FINITO?

--- CHE COSA IL BLOCCO DOVEVA FARE (dalla roadmap) ---
$compito

--- CHE COSA DICE DI AVER FATTO ---
Questa e' la TESI di chi ha lavorato, non una prova. Serve a sapere cosa cercare nella
differenza, non a decidere se e' vero.
$tesi
Verifica dichiarata: $prove

--- LA DIFFERENZA VERA: cio' che e' cambiato nel progetto ---
$differenza

--- LE QUATTRO COSE CHE DEVI CERCARE, E NESSUN'ALTRA ---

1. PROMESSA NON MANTENUTA — il blocco prometteva qualcosa che nella differenza non c'e'.

2. PROVE INDEBOLITE — una prova che esisteva e' stata tolta, saltata, resa piu' permissiva,
   o riscritta perche' passasse. E' il difetto piu' grave di tutti, ed e' esattamente quello
   che da dentro nessuno vede: chi non riesce a far passare una prova puo' cambiare la prova
   invece del codice, e il verde arriva lo stesso.

3. FINTA — un valore fisso al posto di un calcolo, una risposta preparata, un ramo che
   ritorna sempre vero, un segnaposto lasciato li' (TODO, pass, NotImplemented, "per ora")
   su una strada che il prodotto percorre davvero.

4. ROTTURA VISIBILE — la differenza chiama qualcosa che non esiste, oppure cambia un patto
   (nome, argomenti, formato, campo) e lascia indietro chi lo usava.

NON giudicare: stile, nomi, eleganza, architettura, cio' che si poteva fare meglio, cio'
che il blocco non prometteva. Quello non e' compito tuo e fermerebbe la corsa per niente.

IN DUBBIO: PASSA. Un blocco fermato a torto costa un blocco intero rifatto. Fermalo solo se
sai indicare il punto preciso — il file, e la riga se ce l'hai — in cui la cosa si vede.

--- COME RISPONDERE ---
Rispondi SOLO con questi campi, uno per riga, senza altro testo:

VERDETTO: PASSA | NON PASSA
TIPO: promessa | prove | finta | rottura | nessuno
DOVE: file:riga del punto in cui si vede (oppure "-")
MANCA: cosa non c'e', cosa e' finto o cosa e' rotto, una o due righe (oppure "-")
PERCHE: la ragione, una riga
PER_CHI_RIPARA: cosa deve fare l'agente che riprende il blocco, 1-3 righe (oppure "-")
EOF
}

occhio_esterno_campo() { printf '%s\n' "$1" | sed -n "s/^$2: *//p" | head -1; }

# Il messaggio della RIPARAZIONE, quando la sessione che ha lavorato e' ancora viva. E' corto
# apposta: l'agente ha gia' tutto davanti, e ripetergli le regole e il contesto costerebbe
# come aprire un blocco nuovo — cioe' esattamente il lavoro che non si vuole rifare.
occhio_esterno_messaggio_di_riparazione() {
    local phase="$1" block="$2"
    cat << EOF
--- IL BLOCCO NON E' FINITO: UN CONTROLLO INDIPENDENTE HA GUARDATO LA TUA DIFFERENZA ---
Non ricominciare niente e non rileggere niente: il lavoro che hai fatto resta dov'e', ed e'
gia' davanti a te in questa conversazione. C'e' UN punto che non va. Ripara quello, e nient'altro.

$OCCHIO_ESTERNO_MOTIVO

Poi chiudi il blocco come sempre: test tutti verdi, la spunta rimessa in $ROADMAP (il
controllo l'ha tolta), $HANDOFF_FILE riscritto con PHASE: $phase e BLOCK: $block, e il commit.
Alla voce OCCHIO_ESTERNO dell'handoff scrivi cosa hai fatto dell'obiezione: riparata come,
oppure perche' non era un difetto.
Se dopo averla guardata sei convinto che NON sia un difetto, dillo li' e chiudi lo stesso:
chi ha guardato aveva davanti solo la differenza, e puo' sbagliare.
EOF
}

# --- IL GIRO -----------------------------------------------------------------------------

# Guarda il blocco appena chiuso. Non torna mai un errore: fissa OCCHIO_ESTERNO_ESITO.
#   passa        il blocco e' finito (o non c'era modo di guardarlo)
#   riapri       il blocco non e' finito e va rifatto, con l'obiezione in mano
#   al_guardiano il blocco e' gia' stato riaperto una volta e non basta: non si insiste da soli
occhio_esterno_guarda() {
    local bid="$1" phase="$2" block="$3"
    OCCHIO_ESTERNO_ESITO="passa"; OCCHIO_ESTERNO_MOTIVO=""; OCCHIO_ESTERNO_RIGA=""
    [[ "$OCCHIO_ESTERNO" == "si" ]] || return 0
    [[ "${DRY_RUN:-false}" == "true" ]] && return 0
    # Senza il punto di partenza non c'e' una differenza da guardare, e guardare il progetto
    # intero sarebbe un'altra cosa (e un altro costo). Si dice e si passa.
    if [[ -z "${HEAD_PRIMA_DEL_BLOCCO:-}" ]]; then
        log_verbose "Occhio esterno: non so da dove era partito il blocco, non guardo."
        return 0
    fi
    if [[ "$OCCHIO_ESTERNO_FERMATE" -ge "$OCCHIO_ESTERNO_MAX_FERMATE" ]]; then
        log "${YELLOW}Occhio esterno: ha gia' riaperto $OCCHIO_ESTERNO_FERMATE blocchi in questa corsa, da qui in poi guarda e basta.${NC}"
        return 0
    fi

    log "${BLUE}Occhio esterno: guardo $bid con occhi che non l'hanno costruito...${NC}"
    local domanda; domanda="$(occhio_esterno_domanda "$bid" \
        "$(roadmap_block_context "$phase" "$block")" \
        "$(parse_handoff_summary)" \
        "$(parse_handoff_tests)" \
        "$(occhio_esterno_differenza "$HEAD_PRIMA_DEL_BLOCCO")")"

    # Con la testa, non col motore di corsa: qui non c'e' nessun test che controlli la
    # risposta, ed e' lo stesso motivo per cui ci vanno il guardiano e il Consiglio (cap. 22).
    local risposta; risposta="$(con_la_testa chiedi_all_agente "$domanda" "$OCCHIO_ESTERNO_MINUTI")"
    if [[ -z "${risposta//[[:space:]]/}" ]]; then
        # Meglio senza occhio esterno che senza runner: se non risponde, non blocca niente.
        log "${YELLOW}Occhio esterno: nessuna risposta, il blocco passa senza controllo.${NC}"
        return 0
    fi

    local verdetto; verdetto="$(occhio_esterno_campo "$risposta" VERDETTO)"
    if [[ "$verdetto" != "NON PASSA" ]]; then
        log "${GREEN}Occhio esterno: $bid passa.${NC}"
        return 0
    fi

    local tipo dove manca perche riparo
    tipo="$(occhio_esterno_campo "$risposta" TIPO)"
    dove="$(occhio_esterno_campo "$risposta" DOVE)"
    manca="$(occhio_esterno_campo "$risposta" MANCA)"
    perche="$(occhio_esterno_campo "$risposta" PERCHE)"
    riparo="$(occhio_esterno_campo "$risposta" PER_CHI_RIPARA)"
    OCCHIO_ESTERNO_RIGA="${tipo:-difetto}${dove:+ · $dove} — ${manca:-$perche}"
    OCCHIO_ESTERNO_MOTIVO="TIPO: ${tipo:--}
DOVE: ${dove:--}
COSA MANCA O E' FINTO: ${manca:--}
PERCHE': ${perche:--}
DA DOVE RIPARTIRE: ${riparo:--}"

    if occhio_esterno_gia_visto "$bid"; then
        log "${RED}Occhio esterno: $bid non passa nemmeno al secondo giro — non insisto da solo.${NC}"
        OCCHIO_ESTERNO_ESITO="al_guardiano"
        return 0
    fi
    OCCHIO_ESTERNO_GIA_VISTI="$OCCHIO_ESTERNO_GIA_VISTI $bid"
    OCCHIO_ESTERNO_FERMATE=$(( OCCHIO_ESTERNO_FERMATE + 1 ))
    log "${YELLOW}Occhio esterno: $bid NON e' finito — $OCCHIO_ESTERNO_RIGA${NC}"
    OCCHIO_ESTERNO_ESITO="riapri"
    return 0
}

occhio_esterno_gia_visto() {
    [[ " $OCCHIO_ESTERNO_GIA_VISTI " == *" $1 "* ]]
}

# --- RIAPRIRE IL BLOCCO ------------------------------------------------------------------

# La casella della roadmap torna a dire la verita': il blocco non e' fatto. Se la roadmap
# tiene l'etichetta nell'intestazione invece che nella casella, la riga non ha nessuna
# spunta da togliere e non si tocca niente — e va bene, perche' in quel formato il runner
# non considera comunque il blocco chiuso.
occhio_esterno_riapri_casella() {
    local phase="$1" block="$2"
    local riga; riga="$(roadmap_block_line "$phase" "$block")"
    [[ -n "$riga" ]] || return 0
    printf '%s' "$riga" | grep -qiE '\[x\]' || return 0
    PYTHONIOENCODING=utf-8 SO_RIGA="$riga" SO_ROADMAP="$PROJECT_DIR/$ROADMAP" python -c "
import os, re, io
percorso = os.environ['SO_ROADMAP']
bersaglio = os.environ['SO_RIGA']
with io.open(percorso, encoding='utf-8') as f: righe = f.readlines()
for i, r in enumerate(righe):
    if r.rstrip('\n') == bersaglio.rstrip('\n'):
        righe[i] = re.sub(r'\[[xX]\]', '[ ]', r, count=1)
        break
with io.open(percorso, 'w', encoding='utf-8', newline='') as f: f.writelines(righe)
" 2>/dev/null || log_verbose "Occhio esterno: la casella della roadmap non si e' potuta riaprire."
}

# L'handoff rimanda allo STESSO blocco, con l'obiezione. Del giro precedente resta una riga
# sola: cio' che diceva di aver fatto. Il resto sarebbe la relazione di un lavoro che il
# l'occhio esterno ha appena dichiarato non finito.
occhio_esterno_riscrivi_handoff() {
    local phase="$1" block="$2" tesi_vecchia="$3"
    local h="$PROJECT_DIR/$HANDOFF_FILE"
    {
        echo "STATUS: CONTINUE"
        echo "PHASE: $phase"
        echo "BLOCK: $block"
        echo "SUMMARY: Blocco riaperto dall'occhio esterno — $OCCHIO_ESTERNO_RIGA"
        echo "NEXT: Ripara cio' che l'occhio esterno ha rilevato, poi richiudi il blocco."
        echo "OCCHIO_ESTERNO: $OCCHIO_ESTERNO_RIGA"
        echo "COSA_DICEVA_IL_GIRO_PRIMA: ${tesi_vecchia:-(non dichiarato)}"
        echo "TESTS: DA RIFARE"
    } > "$h"
}

# Il giro completo del "si riapre": casella, diario, handoff. Il runner chiama questa.
# Torna 1 se la casella e' rimasta spuntata: rimandare il runner su un blocco che la roadmap
# dichiara fatto lo farebbe fermare con un errore ("risulta gia' fatto, non lo riapro"), e
# una riapertura che uccide la corsa e' peggio del difetto che voleva far riparare.
occhio_esterno_riapri() {
    local bid="$1" phase="$2" block="$3"
    local tesi_vecchia; tesi_vecchia="$(parse_handoff_summary | tr '\n' ' ')"
    occhio_esterno_riapri_casella "$phase" "$block"
    if [[ "$(block_is_done "$phase" "$block")" == "yes" ]]; then
        log "${YELLOW}Occhio esterno: la casella di $bid e' rimasta spuntata, non posso rimandarci il runner.${NC}"
        return 1
    fi
    # Il diario di sessione aveva gia' scritto CONTINUE per questo blocco: senza questa riga
    # il registro direbbe che e' andato bene, e fra un mese nessuno saprebbe che il secondo
    # occhio esiste. E' anche l'unico modo di misurare, dopo, se serve davvero.
    append_session_log "$bid" "RIAPERTO" "L'occhio esterno ha riaperto il blocco: $OCCHIO_ESTERNO_RIGA"
    # Lo stato di marcia era gia' avanzato al blocco dopo: se la corsa morisse adesso,
    # riprenderebbe da un blocco che non e' il suo.
    update_progress "$phase" "$block" "riaperto" "$OCCHIO_ESTERNO_RIGA"
    occhio_esterno_riscrivi_handoff "$phase" "$block" "$tesi_vecchia"
    send_telegram "🔎 $(get_project_name "$ROOT_DIR")
Un controllo indipendente ha guardato il pezzo appena finito e dice che non e' finito davvero.
Lo sto rifacendo io, tu non devi fare niente.

${OCCHIO_ESTERNO_RIGA}" "true"
}
