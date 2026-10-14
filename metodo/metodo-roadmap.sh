#!/usr/bin/env bash
# COME SI LEGGE UNA ROADMAP — in un posto solo.
# Regole del formato: .claude/metodo-villa/09-struttura-file.md e 21-corsie-parallele.md
#
# Questo file non si lancia: si carica (source) da chi deve leggere una ROADMAP.md.
# Oggi lo caricano il runner (per sapere a che punto e' la fase) e lo strumento delle
# corsie (per il Consiglio degli Agenti e per aprire i tavoli).
#
# Perche' esiste: le stesse due regole — come si riconosce l'intestazione di una fase e
# come si riconosce la casella di un blocco — vivevano scritte a mano in tutti e due gli
# strumenti. Il runner ha imparato a riconoscere le due forme di roadmap; le corsie no, e
# per mesi hanno risposto «Nessuna fase con blocchi da fare» su fasi piene di lavoro,
# senza dare nessun errore. Nelle corsie c'era perfino un commento che diceva «stessa
# logica del runner»: non lo era piu' da un pezzo. Due copie della stessa regola divergono
# sempre — e quando divergono qui, il danno non si vede: gli strumenti non si rompono,
# dicono con calma che non c'e' niente da fare.
#
# Chi aggiunge un terzo strumento che legge la roadmap carica questo file. Non ricopia.

# --- Le due forme di roadmap, che esistono tutte e due nei progetti veri ---------------
#
# INTESTAZIONE DI FASE:  "## Fase 4 — Portale famiglie"
#                        "# 🚧 FASE 51 — Assistente — DA COSTRUIRE"
# CASELLA DEL BLOCCO:    "- [ ] **F4B2** — titolo"            (in testa)
#                        "- **F51B3 — titolo** · 🤖 · **[ ]**" (in coda)
#
# "fase" dev'essere la PRIMA parola dopo i cancelletti — prima si ammettono solo segni,
# emoji e spazi. Cosi' "### Fase 2 del collaudo" scritto dentro una fase non spezza la
# sezione in due, e "## La fase 3 spiegata" non viene scambiata per un'intestazione.
#
# Le due scritture della stessa regola servono perche' awk la applica dopo tolower() e
# grep con -i: la classe da escludere e' [^a-z] nel primo caso e [^A-Za-z] nel secondo.
#
# IL NOME DI UNA FASE NON E' SEMPRE UN NUMERO. Le roadmap vere hanno fasi chiamate con una
# lettera — "## Fase S — le prove sul campo", "## Fase E", "## Fase V" — e pretendere una
# cifra vuol dire non riconoscerle: la sezione della fase precedente non finisce piu' e se le
# ingoia. Su una roadmap vera l'ultima fase numerata risultava di settanta blocchi invece di
# sessanta, perche' si portava dentro le due fasi con la lettera che le stavano sotto.
# Si ammette quindi un numero (anche di piu' cifre) OPPURE una singola lettera, e si pretende
# che dopo finisca: "## Fase di collaudo" non e' una fase, "## Fase E —" si'.
ROADMAP_INTESTAZIONE='^#+[^a-z]*fase ([0-9]+|[a-z])([^0-9a-z]|$)'
ROADMAP_INTESTAZIONE_GREP='^#+[^A-Za-z]*fase ([0-9]+|[A-Za-z])([^0-9A-Za-z]|$)'

# Righe della sezione di una fase, fino alla fase successiva o alla fine del file.
#   roadmap_sezione_fase <file> <numero di fase>
roadmap_sezione_fase() {
    local r="$1" ph="$2"
    [[ -f "$r" ]] || return 0
    local ph_min="$(printf '%s' "$ph" | tr '[:upper:]' '[:lower:]')"   # awk confronta dopo tolower()
    awk -v cerca="$ROADMAP_INTESTAZIONE" -v questa="^#+[^a-z]*fase $ph_min"'([^0-9a-z]|$)' '
        tolower($0) ~ questa { inph=1; print; next }
        tolower($0) ~ cerca  { inph=0 }
        inph { print }
    ' "$r"
}

# Filtro su standard input: tiene le sole righe di blocco con la casella nello stato
# chiesto — "dafare" (o "todo"), "fatto" (o "done"), "qualsiasi".
#
# La casella si riconosce in quelle due posizioni SOLTANTO, non "ovunque nella riga": una
# sotto-voce descrittiva («- *Verifica*: la casella [ ] resta vuota finche' non si firma»)
# verrebbe contata come un blocco. Le caselle in altri stati ([~] a meta', [→] spostato)
# non sono ne' da fare ne' fatte, e restano fuori da tutti e due i conti.
roadmap_righe_casella() {
    local box
    case "$1" in
        fatto|done)     box='[xX]' ;;
        qualsiasi|tutte) box='[ xX]' ;;
        *)              box=' ' ;;
    esac
    grep -E '^[[:space:]]*-[[:space:]]' \
        | grep -E "(^[[:space:]]*-[[:space:]]*\[${box}\])|(\*\*\[${box}\]\*\*)"
}

# Filtro su standard input: dei blocchi GIA' CHIUSI resta il titolo, il corpo se ne va.
#   roadmap_comprimi_fatti <nome del file di roadmap, per la nota finale>
#
# Perche' esiste. La sezione della fase in corso si spedisce all'agente a OGNI blocco, e
# dentro un blocco l'agente fa circa cento domande al modello, ognuna delle quali si riporta
# dietro tutto il messaggio: una riga di troppo in apertura non si paga una volta, si paga
# cento. Misurato il 2026-08-16 su Fedorium: i blocchi gia' chiusi erano 154.851 caratteri,
# il 73% della roadmap spedita e il 62% del messaggio intero. Il dettaglio di un lavoro
# finito non serve a chi deve fare il lavoro dopo: se gli serve, il file e' li'.
#
# Cosa NON si tocca: le intestazioni (sono l'ossatura della fase e dicono cosa c'e' stato),
# la riga di stato del blocco chiuso (dice che e' chiuso, e quando), e tutto cio' che
# riguarda i blocchi ancora da fare o in corso. Su una roadmap senza caselle non cambia
# niente: non c'e' niente da riconoscere, e il testo esce com'e' entrato.
roadmap_comprimi_fatti() {
    awk -v file="${1:-ROADMAP.md}" '
        # Le intestazioni passano sempre e chiudono il blocco precedente: sono il confine.
        /^#/ { salta=0; print; next }
        # Una casella qualunque (fatta, da fare, in corso) apre un blocco nuovo. Si stampa
        # sempre; da li in poi si taglia solo se quel blocco e chiuso. Il riconoscimento e
        # ancorato come in roadmap_righe_casella: una casella citata dentro una frase non
        # deve aprire niente.
        /^[[:space:]]*-[[:space:]]*\[[^]]\]/ || /\*\*\[[^]]\]\*\*/ {
            salta = ($0 ~ /^[[:space:]]*-[[:space:]]*\[[xX]\]/ || $0 ~ /\*\*\[[xX]\]\*\*/) ? 1 : 0
            print; next
        }
        salta { tagliate++; next }
        { print }
        END {
            if (tagliate > 0)
                printf "\n[Dei blocchi gia chiusi qui sopra resta il titolo: il dettaglio (%d righe) e nel file %s, aprilo se ti serve.]\n", tagliate, file
        }
    '
}

# --- Le stesse due regole, riga per riga --------------------------------------------
#
# Chi deve scorrere la roadmap tenendo il contesto (l'intestazione sopra il blocco, la
# fase in cui si trova) non puo' passarla attraverso i filtri qui sopra: gli servono le
# regole applicate a UNA riga alla volta. Queste due funzioni fanno esattamente quello.
#
# Sono scritte in bash puro — nessun grep, nessun sed, nessuna sostituzione di comando —
# perche' vengono chiamate una volta per riga: su Windows aprire un processo per riga di
# una roadmap da diecimila righe costa piu' di leggere il file intero.

# Vero se la riga e' l'intestazione di una fase; in quel caso mette il nome in ROADMAP_FASE.
# Ammette gli stessi nomi di ROADMAP_INTESTAZIONE — un numero o una singola lettera — e
# pretende che il nome finisca li'. Devono ammettere gli stessi: se questa riconoscesse solo
# i numeri, chi scorre riga per riga vedrebbe "## Fase S" come una riga qualunque e
# continuerebbe a contarne i blocchi dentro la fase precedente, mentre chi estrae la sezione
# la vedrebbe come una fase a se'. Due letture della stessa roadmap che non concordano sono
# il difetto che questo file esiste per impedire.
roadmap_fase_della_riga() {
    [[ "$1" =~ ^#+[^A-Za-z]*[Ff][Aa][Ss][Ee][[:space:]]+([0-9]+|[A-Za-z])([^0-9A-Za-z]|$) ]] || return 1
    ROADMAP_FASE="${BASH_REMATCH[1]}"
}

# Vero se la riga e' un blocco ancora da fare, in una qualunque delle due forme.
roadmap_riga_da_fare() {
    [[ "$1" =~ ^[[:space:]]*-[[:space:]] ]] || return 1
    [[ "$1" =~ ^[[:space:]]*-[[:space:]]*\[\ \] ]] || [[ "$1" =~ \*\*\[\ \]\*\* ]]
}

# Quanti blocchi il runner prevede di eseguire prima di fermarsi da solo, e perche' si
# fermera'. Scorre i blocchi ancora da fare e conta finche' non incontra il primo che chiede
# Villa (👤 umano, 🤝 collaborativo, o la parola CHECKPOINT).
#
#   previsione_corsa <fase di partenza> [tetto]
#
# Legge la roadmap da ${PROJECT_DIR:-.}/${ROADMAP:-ROADMAP.md} e la modalita' da
# ${ALL_PHASES:-false}: chi la carica senza essere il runner (stato-progetto.sh per la
# schermata) le prepara prima di chiamarla. La regola resta UNA e sta qui: il giorno in
# cui la schermata contasse diversamente dal runner, mostrerebbe "mancano 12 blocchi" a
# una corsa che ne farebbe 5, e nessuno se ne accorgerebbe.
#
# SI COMINCIA A CONTARE DALLA FASE IN CORSO, non dall'inizio del file. Contare dall'inizio
# sembra la stessa cosa e non lo e': le fasi gia' chiuse si trascinano dietro blocchi 👤
# rimasti aperti per sempre in attesa di Villa, e il primo di quelli faceva annunciare
# «nessuno — il primo blocco da fare chiede Villa, mi fermo subito» a una corsa che poi ne
# eseguiva cento. Un annuncio sbagliato e' peggio di nessun annuncio: si smette di leggerlo.
#
# Stampa "quanti|perche' si fermera'", oppure "?|perche' non lo so".
previsione_corsa() {
    local fase_corrente="$1"
    # ROADMAP puo' arrivare gia' come percorso intero (stato-progetto.sh la usa cosi')
    # o come solo nome (il runner): in quel caso sta dentro PROJECT_DIR.
    local r="${ROADMAP:-ROADMAP.md}"
    [[ "$r" == /* || "$r" == [A-Za-z]:* ]] || r="${PROJECT_DIR:-.}/$r"
    local all_phases="${ALL_PHASES:-false}"
    [[ -f "$r" ]] || { echo "?|roadmap non trovata"; return 0; }
    local fase="" intest="" n=0 motivo="" riga dentro="false"
    # Alla partenza il runner puo' non sapere ancora in che fase si trova (progress.json
    # assente, o fase 0): solo in quel caso si guarda la prima fase che ha ancora blocchi da
    # fare. Se invece la fase e' dichiarata ma nella roadmap non c'e', NON si indovina: si
    # dice che non si sa. Indovinare vorrebbe dire annunciare i blocchi di un'altra fase.
    if [[ -z "$fase_corrente" || "$fase_corrente" == "0" ]]; then
        while IFS= read -r riga; do
            roadmap_fase_della_riga "$riga" && { fase="$ROADMAP_FASE"; continue; }
            if roadmap_riga_da_fare "$riga" && [[ -n "$fase" ]]; then fase_corrente="$fase"; break; fi
        done < "$r"
        fase=""
        [[ -n "$fase_corrente" ]] || { echo "0|non risulta piu' niente da fare"; return 0; }
    fi
    while IFS= read -r riga; do
        if roadmap_fase_della_riga "$riga"; then
            fase="$ROADMAP_FASE"; intest=""
            [[ "$fase" == "$fase_corrente" ]] && dentro="true"
            continue
        fi
        # Tutto cio' che sta prima della fase in corso e' passato: non si conta.
        [[ "$dentro" == "true" ]] || continue
        case "$riga" in '### '*) intest="$riga"; continue;; esac
        roadmap_riga_da_fare "$riga" || continue
        [[ "$all_phases" != "true" && "$fase" != "$fase_corrente" ]] && continue
        if [[ "$intest$riga" == *"🤝"* || "$intest$riga" == *"👤"* || "$intest$riga" == *CHECKPOINT* ]]; then
            motivo="poi tocca a Villa"; break
        fi
        n=$((n+1))
    done < "$r"
    # La fase da cui si parte non compare nella roadmap: qualunque numero sarebbe inventato.
    [[ "$dentro" == "true" ]] || { echo "?|la Fase $fase_corrente non si trova nella roadmap"; return 0; }
    if [[ -z "$motivo" ]]; then
        if [[ "$all_phases" == "true" ]]; then motivo="poi la roadmap e' finita"
        else motivo="poi finisce la fase $fase_corrente"; fi
    fi
    # IL TETTO FA PARTE DELLA PREVISIONE. Senza, il runner annunciava i blocchi rimasti in
    # roadmap anche quando la corsa si sarebbe fermata molto prima per via di --max-blocks:
    # un numero vero, che pero' rispondeva a un'altra domanda. Quello che serve sapere e'
    # quanto manca a QUESTA corsa, non quanto manca al progetto.
    local tetto="${2:-}"
    if [[ "$tetto" =~ ^[0-9]+$ && "$n" -gt "$tetto" ]]; then
        n="$tetto"; motivo="poi si tocca il tetto di sicurezza ($tetto)"
    fi
    echo "$n|$motivo"
}

# I nomi delle fasi presenti nella roadmap, in ordine di file: numeri e lettere insieme.
#   roadmap_nomi_di_fase <file>
# Un giro solo di awk invece di due grep in cascata, perche' il secondo grep ('[0-9]+')
# buttava via proprio le fasi chiamate con una lettera.
roadmap_nomi_di_fase() {
    [[ -f "$1" ]] || return 0
    awk -v cerca="$ROADMAP_INTESTAZIONE" '
        tolower($0) ~ cerca {
            nome = tolower($0)
            sub(/^#+[^a-z]*fase /, "", nome)
            sub(/[^0-9a-z].*$/, "", nome)
            print nome
        }' "$1"
}
