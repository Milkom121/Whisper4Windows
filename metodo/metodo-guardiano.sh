#!/usr/bin/env bash
# IL GUARDIANO — cosa succede quando il runner si ferma.
#
# Prima: il runner si fermava, mandava un avviso a senso unico e chiudeva. Se Villa dormiva,
# la corsa restava ferma fino al mattino dopo — spesso per una decisione che si poteva
# prendere in trenta secondi.
#
# Adesso, quando il runner sta per fermarsi, passa di qui. Il guardiano:
#   1. mette insieme la situazione (diario, ultime righe del registro, il blocco in ballo);
#   2. scrive a Villa nella sezione del progetto e ASPETTA la sua risposta — dieci minuti,
#      che ripartono a ogni messaggio: se Villa entra in conversazione si continua a parlare
#      finche' serve, con la risposta anche a voce;
#   3. se Villa risponde, si decide insieme;
#   4. se Villa non c'e', decide da solo — secondo le regole scritte qui sotto, non a caso;
#   5. in tutti i casi scrive cosa ha deciso: nel diario delle decisioni, su Telegram, e nel
#      riepilogo di fine corsa.
#
# Non si lancia a mano: lo chiama il runner. Configurazione in .env.runner:
#   GUARDIANO=si|no            (default si)
#   GUARDIANO_ATTESA=600       (secondi di attesa prima di decidere da solo)
#   GUARDIANO_MAX_INTERVENTI=3 (quante volte puo' rimettere in moto la corsa)
#   GUARDIANO_GIRI_CHAT=3      (quanti scambi al massimo, quando Villa risponde)

GUARDIANO="${GUARDIANO:-si}"
GUARDIANO_ATTESA="${GUARDIANO_ATTESA:-600}"
GUARDIANO_MAX_INTERVENTI="${GUARDIANO_MAX_INTERVENTI:-3}"
GUARDIANO_GIRI_CHAT="${GUARDIANO_GIRI_CHAT:-3}"
GUARDIANO_INTERVENTI=0          # quante volte e' gia' intervenuto in questa corsa
GUARDIANO_DECISIONI=""          # il riassunto per il riepilogo di fine corsa

# Le direttive. Sono la parte che conta: senza, "decide da solo" vuol dire "tira a indovinare".
# Vivono qui e non nel prompt del blocco perche' qui si decide COSA FARE quando ci si e'
# fermati, non come scrivere il codice.
guardiano_direttive() {
    cat << 'EOF'
COME SI DECIDE (in quest'ordine, la prima che si applica vince):

1. SOLIDO, NON SBRIGATIVO. Fra due strade scegli sempre la piu' professionale, robusta e
   duratura, anche se costa piu' lavoro. La scorciatoia si sceglie solo se la strada solida
   e' impossibile, e in quel caso la si registra come scorciatoia (dev-shortcuts.md).

2. MAI SOPRA UN TEST ROSSO. Se qualcosa non passa, si decide COME ripararlo, mai di tirare
   dritto. "Disattiva il test" non e' una riparazione. Se non sai come ripararlo: FERMATI.

3. SICUREZZA E DATI: vale il capitolo 12 del Metodo (le sei regole di autonomia). Massimo
   livello ragionevole, senza chiedere. Se c'entra una legge, si cerca la norma e si cita.

4. DECISIONI DI PRODOTTO E DI DIREZIONE (cosa deve fare il prodotto, per chi, con quali
   priorita', che aspetto ha): NON sono tue. Se la scelta e' di questo tipo:
   - se esiste una strada REVERSIBILE (che non chiude porte e si puo' cambiare dopo senza
     buttare lavoro), prendi quella, marcala DA_CONFERMARE e vai avanti;
   - se ogni strada e' difficile da tornare indietro, FERMATI e lascia decidere a Villa.

5. NON INVENTARE REQUISITI. Se manca un'informazione che solo Villa ha (una password, un
   accesso, un dato del cliente, una preferenza che non si deduce da niente): FERMATI.
   Nessun ragionamento la fa comparire.

6. MINIMO INDISPENSABILE. Decidi solo cio' che serve per sbloccare il blocco fermo. Non
   riprogettare, non anticipare, non allargare il lavoro.

7. SE LA SESSIONE E' STATA INTERROTTA (piantata, o troppo lunga), guarda prima di tutto cosa
   e' rimasto a meta': file scritti a meta', modifiche non committate, test mai lanciati. La
   risposta giusta e' quasi sempre una di queste tre, in quest'ordine:
   - il lavoro fatto e' sano e verificabile -> falla riprendere da li', dicendo da dove;
   - il lavoro e' a meta' e non si capisce -> dillo e fai ricominciare il blocco da capo,
     PULITO: git ha ancora l'ultimo commit buono, quindi niente di verificato va perso;
   - il blocco era semplicemente troppo grosso -> proponi di spezzarlo e FERMATI: ritagliare
     i blocchi e' compito di chi pianifica, non tuo.
   Non far ripartire lo stesso blocco identico se e' gia' stato interrotto una volta: se
   riprovi uguale, si ripianta uguale.
EOF
}

# La situazione, messa insieme dai file: e' cio' che il guardiano guarda prima di parlare.
guardiano_situazione() {
    local bid="$1" stato="$2"
    echo "STATO: $stato — blocco $bid"
    # Se la sessione e' stata interrotta, il PERCHE' cambia completamente la decisione: un
    # agente rimasto fermo dieci minuti e' un altro problema rispetto a uno che ha lavorato
    # per ore. Senza questa riga il guardiano dovrebbe indovinarlo.
    case "${MOTIVO_INTERRUZIONE:-}" in
        appeso) echo "L'ho interrotto io: era fermo da $INATTIVITA_MAX_MINUTI minuti senza scrivere niente nel suo diario. Non stava lavorando: era piantato.";;
        tetto)  echo "L'ho interrotto io: aveva superato il tetto assoluto di $TETTO_ASSOLUTO_MINUTI minuti pur continuando a lavorare. Il blocco e' probabilmente troppo grosso e andrebbe spezzato.";;
    esac
    echo
    echo "--- DIARIO DEL BLOCCO (docs/diario/handoff.md) ---"
    read_file_safe "$HANDOFF_FILE" | head -n 40
    echo
    local titolo; titolo="$(roadmap_block_title "${bid#F}" "${bid##*B}" 2>/dev/null || true)"
    [[ -n "$titolo" ]] && { echo "--- IL BLOCCO IN BALLO ---"; echo "$titolo"; echo; }
    echo "--- ULTIME RIGHE DEL REGISTRO ---"
    tail -n 60 "$PROJECT_DIR/$RUNNER_LOG" 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g' || true
}

# Il primo messaggio a Villa. Non lo scrive un modello: usa quello che l'agente ha gia'
# messo nel diario (la riga per Villa e la decisione che chiedeva). Costa zero e parte subito.
guardiano_messaggio_a_villa() {
    local bid="$1" stato="$2"
    local per_villa; per_villa="$(parse_handoff_per_villa)"
    local serve; serve="$(read_file_safe "$HANDOFF_FILE" | sed -n 's/^DECISIONS_NEEDED: *//p' | head -3)"
    local minuti=$(( GUARDIANO_ATTESA / 60 ))
    printf '⏸️ %s\nMi sono fermato e mi servirebbe una tua parola.\n\n' "$(get_project_name "$ROOT_DIR")"
    [[ -n "$per_villa" ]] && printf '%s\n\n' "$(taglia_per_telefono "$per_villa")"
    [[ -n "$serve" ]] && printf 'Il punto e questo:\n%s\n\n' "$serve"
    printf '👉 Rispondi qui (anche a voce) e decidiamo insieme.\nSe entro %s minuti non ti sento, decido io per la strada piu solida e ti dico cosa ho fatto.\n' "$minuti"
}

# Il ragionamento vero. Riceve la situazione e cio' che Villa ha detto (se ha detto qualcosa),
# e torna una decisione nel formato a campi che il runner sa leggere.
guardiano_chiedi_decisione() {
    local bid="$1" stato="$2" conversazione="$3"
    local prompt; prompt="$(cat << EOF
Sei il guardiano di una corsa automatica del Metodo Villa. Il runner si e' fermato e tu devi
decidere che cosa si fa adesso. Non scrivi codice e non tocchi niente: decidi, e basta.

$(guardiano_direttive)

--- LA SITUAZIONE ---
$(guardiano_situazione "$bid" "$stato")

$(if [[ -n "$conversazione" ]]; then
    echo "--- COSA HA DETTO VILLA ---"
    echo "$conversazione"
    echo
    echo "La parola di Villa vince su qualunque tua preferenza. Se ti ha risposto in modo"
    echo "chiaro, applica quello che ha detto. Se ti ha risposto ma resta un dubbio che gli"
    echo "impedisce di procedere, chiedi UNA cosa sola con ESITO: CHIEDI_ANCORA."
else
    echo "--- VILLA NON HA RISPOSTO ---"
    echo "Sono passati i minuti previsti senza risposta. Decidi tu, secondo le regole."
fi)

--- COME RISPONDERE ---
Rispondi SOLO con questi campi, uno per riga, senza altro testo:

ESITO: PROCEDI | FERMATI | CHIEDI_ANCORA
DECISIONE: cosa si fa, in una o due righe (se ESITO e' CHIEDI_ANCORA, scrivi qui la domanda)
PERCHE: la ragione, una riga
COME_PROCEDERE: le istruzioni per l'agente che eseguira' il prossimo blocco, 1-4 righe
DA_CONFERMARE: si | no  (si = era una scelta che spetta a Villa e l'hai presa reversibile)
RISCHIO: cosa potrebbe andare storto, una riga (oppure "nessuno rilevante")
PER_VILLA: 2-3 righe in italiano di tutti i giorni, come lo diresti a voce a chi non ha
letto niente. Niente nomi di file, niente codici di blocco, niente termini tecnici.

Usa FERMATI quando le regole te lo impongono: manca un'informazione che solo Villa ha,
oppure ogni strada e' difficile da annullare, oppure non sai come riparare cio' che e' rotto.
Fermarsi non e' un fallimento: e' la scelta giusta quando le altre sono peggio.
EOF
)"
    # Con la testa, non col motore di corsa: qui si decide da soli, di notte, e nessun test
    # controlla la decisione. Vedi con_la_testa() in metodo-agente.sh.
    con_la_testa chiedi_all_agente "$prompt" 5
}

# Legge un campo dalla risposta del guardiano.
guardiano_campo() { printf '%s\n' "$1" | sed -n "s/^$2: *//p" | head -1; }

# Scrive la decisione dove va scritta: nel diario delle decisioni da rivedere (che e' il
# posto dove Villa le ritrova tutte insieme) e nel riepilogo della corsa.
guardiano_registra() {
    local bid="$1" stato="$2" risposta="$3" con_villa="$4"
    local f="$PROJECT_DIR/docs/diario/decisioni-da-rivedere.md"
    mkdir -p "$(dirname "$f")"
    [[ -f "$f" ]] || printf '# Decisioni da rivedere\n\n> Prese dall%s agente durante le corse automatiche. Villa le rilegge quando vuole.\n' "'" > "$f"
    {
        echo
        echo "## $(date '+%Y-%m-%d %H:%M') — il guardiano, allo stop del blocco $bid ($stato)"
        echo "- **Decisa** $( [[ "$con_villa" == "si" ]] && echo "insieme a Villa su Telegram" || echo "da solo (Villa non ha risposto entro il tempo)" )"
        echo "- **Decisione**: $(guardiano_campo "$risposta" DECISIONE)"
        echo "- **Perche'**: $(guardiano_campo "$risposta" PERCHE)"
        echo "- **Rischio**: $(guardiano_campo "$risposta" RISCHIO)"
        [[ "$(guardiano_campo "$risposta" DA_CONFERMARE)" == "si" ]] && \
            echo "- ⚠️ **DA CONFERMARE**: era una scelta di Villa, presa in forma reversibile."
    } >> "$f"
    GUARDIANO_DECISIONI+="• blocco $bid: $(guardiano_campo "$risposta" DECISIONE)"$'\n'
}

# Rimette in moto il runner: scrive nel diario del blocco cosa si e' deciso, cosi' l'agente
# del blocco successivo lo trova davanti a se' e non ricomincia dal dubbio di prima.
guardiano_sblocca_handoff() {
    local risposta="$1"
    local h="$PROJECT_DIR/$HANDOFF_FILE"
    local prossimo; prossimo="$(parse_handoff_block)"
    {
        echo "STATUS: CONTINUE"
        echo "PHASE: $(parse_handoff_phase)"
        echo "BLOCK: ${prossimo:-0}"
        echo "SUMMARY: $(guardiano_campo "$risposta" DECISIONE)"
        echo "NEXT: $(guardiano_campo "$risposta" COME_PROCEDERE)"
        echo "DECISIONE_DEL_GUARDIANO: $(guardiano_campo "$risposta" DECISIONE) — $(guardiano_campo "$risposta" PERCHE)"
        echo "COME_PROCEDERE: $(guardiano_campo "$risposta" COME_PROCEDERE)"
        echo "PER_VILLA: $(guardiano_campo "$risposta" PER_VILLA)"
        echo "TESTS: SKIPPED"
    } > "$h"
}

# --- IL GIRO COMPLETO --------------------------------------------------------------------
# Torna 0 se la corsa puo' riprendere, 1 se ci si ferma davvero.
guardiano_interviene() {
    local bid="$1" stato="$2"
    [[ "$GUARDIANO" == "si" ]] || return 1
    # Su questi stati non c'e' niente da decidere: la fase e' finita, o il lavoro e' finito.
    [[ "$stato" == "PHASE_COMPLETE" ]] && return 1
    if [[ "$GUARDIANO_INTERVENTI" -ge "$GUARDIANO_MAX_INTERVENTI" ]]; then
        log "${YELLOW}Guardiano: gia' intervenuto $GUARDIANO_INTERVENTI volte in questa corsa, mi fermo davvero.${NC}"
        send_telegram "🛑 $(get_project_name "$ROOT_DIR")
Mi sono fermato per la $(( GUARDIANO_INTERVENTI + 1 ))ª volta e non provo piu' a cavarmela da solo: qui serve che ci guardi tu."
        return 1
    fi
    GUARDIANO_INTERVENTI=$(( GUARDIANO_INTERVENTI + 1 ))
    log "${BLUE}Guardiano: il runner si e' fermato ($stato). Scrivo a Villa e aspetto $(( GUARDIANO_ATTESA / 60 )) minuti...${NC}"

    local conversazione="" risposta="" con_villa="no" giro=0
    local domanda; domanda="$(guardiano_messaggio_a_villa "$bid" "$stato")"

    while :; do
        giro=$(( giro + 1 ))
        local detto; detto="$(guardiano_parla_con_villa "$domanda")"
        if [[ -n "$detto" ]]; then
            con_villa="si"
            conversazione+="Villa: $detto"$'\n'
            log "${GREEN}Guardiano: Villa ha risposto.${NC}"
        else
            log "${YELLOW}Guardiano: nessuna risposta entro il tempo. Decido io.${NC}"
        fi
        risposta="$(guardiano_chiedi_decisione "$bid" "$stato" "$conversazione")"
        [[ -n "$risposta" ]] || { log "${RED}Guardiano: nessuna risposta dall'agente. Mi fermo.${NC}"; return 1; }
        local esito; esito="$(guardiano_campo "$risposta" ESITO)"
        if [[ "$esito" == "CHIEDI_ANCORA" && -n "$detto" && "$giro" -lt "$GUARDIANO_GIRI_CHAT" ]]; then
            domanda="$(guardiano_campo "$risposta" DECISIONE)"
            conversazione+="Guardiano: $domanda"$'\n'
            continue
        fi
        break
    done

    guardiano_registra "$bid" "$stato" "$risposta" "$con_villa"
    local esito; esito="$(guardiano_campo "$risposta" ESITO)"
    local per_villa; per_villa="$(guardiano_campo "$risposta" PER_VILLA)"

    if [[ "$esito" == "PROCEDI" ]]; then
        guardiano_sblocca_handoff "$risposta"
        log "${GREEN}Guardiano: si riparte — $(guardiano_campo "$risposta" DECISIONE)${NC}"
        send_telegram "▶️ $(get_project_name "$ROOT_DIR")
$( [[ "$con_villa" == "si" ]] && echo "Deciso insieme, riparto." || echo "Non ti ho sentito, ho deciso io e sono ripartito." )

${per_villa}

$( [[ "$(guardiano_campo "$risposta" DA_CONFERMARE)" == "si" ]] && echo "⚠️ Questa era una scelta tua: ho preso la strada che si puo' cambiare dopo senza buttare lavoro. Quando vuoi me lo confermi." )" "true"
        return 0
    fi

    log "${YELLOW}Guardiano: si ferma davvero — $(guardiano_campo "$risposta" DECISIONE)${NC}"
    send_telegram "⏸️ $(get_project_name "$ROOT_DIR")
Mi fermo qui: questa non posso deciderla io.

${per_villa}"
    return 1
}

# Manda la domanda a Villa e aspetta. Torna cio' che ha detto, vuoto se non ha risposto.
# Il tempo riparte a ogni scambio: se Villa entra in conversazione, si continua a parlare.
guardiano_parla_con_villa() {
    local domanda="$1"
    local canale="$SCRIPT_DIR/metodo-telegram.sh"
    [[ -f "$canale" ]] || return 0
    local detto="" ec=0
    detto="$(TG_NOME_PROGETTO="$(get_project_name "$ROOT_DIR")" TG_ENV_RUNNER="$ROOT_DIR/.env.runner" \
        bash "$canale" chiedi "$domanda" "$GUARDIANO_ATTESA" 2>/dev/null)" || ec=$?
    # 3 = canale spento (manca il bot o la chat). Non e' un imprevisto da nascondere: senza
    # canale il guardiano decide SEMPRE da solo, e chi legge il registro deve saperlo.
    if [[ $ec -eq 3 ]]; then
        log "${YELLOW}Guardiano: il canale Telegram non e' configurato — non posso chiedere niente a Villa, decido da solo.${NC}"
    fi
    printf '%s' "$detto"
}
