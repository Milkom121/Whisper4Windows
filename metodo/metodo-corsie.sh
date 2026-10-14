#!/usr/bin/env bash
# Strumento delle CORSIE PARALLELE del Metodo Villa.
# Regole e motivazioni: .claude/metodo-villa/21-corsie-parallele.md
#
# Apre, mostra e smonta i "tavoli di lavoro" separati che permettono a piu' agenti di
# lavorare contemporaneamente sullo stesso progetto senza pestarsi i piedi. Ogni corsia
# ha una cartella sua (git worktree), un ramo suo e un diario suo: due corsie non possono
# sovrascriversi il punto in cui sono arrivate, perche' scrivono in file diversi.
#
#   consiglio [--fase N] il Consiglio degli Agenti: dice SE conviene dividere, e come
#   prepara [--fase N]   apre le corsie della fase (rifiuta se il tronco non e' finito)
#   stato                mostra a che punto e' ogni corsia, in una schermata
#   smonta               rimuove i tavoli (i rami restano, il lavoro non si perde)
#   riunisci [--test C]  rimette insieme il lavoro UNA CORSIA PER VOLTA, verificando
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROADMAP="$ROOT_DIR/ROADMAP.md"
# Il passaggio di consegne: dice a che fase si sta lavorando adesso. E' la stessa fonte
# che usa il runner per scegliere il blocco, e vale anche qui — vedi `fase_corrente`.
HANDOFF="$ROOT_DIR/docs/diario/handoff.md"
# I tavoli stanno FUORI dal repository, in una cartella sorella: se stessero dentro,
# comparirebbero come roba non tracciata a ogni `git status` del tavolo principale.
CORSIE_DIR="$(dirname "$ROOT_DIR")/$(basename "$ROOT_DIR")-corsie"
# Sotto questa soglia il costo di preparare, sorvegliare e riunire una corsia supera il
# guadagno (cap. 21, "quando non conviene"). Si avvisa, non si blocca: la decisione e' di Villa.
MIN_BLOCCHI_CORSIA=3

# Chi esegue il lavoro: stessa logica del runner, caricata dallo stesso file. Il Consiglio
# degli Agenti deve girare con il programma che il progetto ha scelto — altrimenti un
# progetto configurato per un altro programma si ritroverebbe a spendere su Claude Code
# senza saperlo. La configurazione del progetto non sta in git, quindi si carica qui.
[[ -f "$ROOT_DIR/.env.runner" ]] && source "$ROOT_DIR/.env.runner"
source "$SCRIPT_DIR/metodo-agente.sh"
# Come si legge una roadmap: stesso file del runner, cosi' i due strumenti non possono
# avere due idee diverse su quali fasi e quali blocchi esistono (vedi metodo-roadmap.sh).
source "$SCRIPT_DIR/metodo-roadmap.sh"
risolvi_agente || exit 1

msg() { echo -e "$1"; }
die() { echo -e "${RED}$1${NC}" >&2; exit 1; }

# --- Lettura della roadmap ---------------------------------------------------
# Le corsie non si dichiarano da nessuna parte se non nella roadmap stessa: l'etichetta
# [[NOME]] sulla riga del blocco e' l'unica fonte di verita'. Cosi' non esiste un secondo
# elenco da tenere allineato a mano.

# Righe della sezione di una fase. Il come sta in `metodo-roadmap.sh`, insieme al runner:
# qui si lega soltanto il file, che e' sempre lo stesso, per non ripeterlo otto volte.
sezione_fase() { roadmap_sezione_fase "$ROADMAP" "$1"; }

# Il numero di fase dichiarato nel passaggio di consegne, o "" se non c'e'. Stessa lettura
# del runner (`parse_handoff_phase`): la riga `PHASE:`, la prima che compare.
fase_dal_passaggio_di_consegne() {
    [[ -f "$HANDOFF" ]] || { echo ""; return; }
    grep -i '^PHASE:' "$HANDOFF" | head -1 | grep -oE '[0-9]+' | head -1
}

# La fase su cui si sta lavorando adesso.
#
# La dice il passaggio di consegne (`PHASE:`), che e' la stessa fonte da cui il runner
# prende il blocco da eseguire: due strumenti dello stesso Metodo non possono avere due
# idee diverse su dove siamo. Si ripiega sulla roadmap solo se il passaggio di consegne
# manca, non e' leggibile, o indica una fase che non ha piu' niente da fare.
#
# Il ripiego prende la PRIMA fase con blocchi aperti nell'ordine del file, e su una roadmap
# lunga non e' quasi mai quella giusta: le fasi vecchie si trascinano dietro code di blocchi
# 👤 e 🤝 che aspettano Villa e restano aperte per sempre (su un progetto molto avanti sono
# una dozzina). Per questo la fonte buona e' il passaggio di consegne, e questo resta
# l'ultima spiaggia.
fase_corrente() {
    local n
    n="$(fase_dal_passaggio_di_consegne)"
    if [[ -n "$n" ]] && sezione_fase "$n" | roadmap_righe_casella dafare >/dev/null 2>&1; then
        echo "$n"; return
    fi

    for n in $(roadmap_nomi_di_fase "$ROADMAP"); do
        if sezione_fase "$n" | roadmap_righe_casella dafare >/dev/null 2>&1; then echo "$n"; return; fi
    done
    echo ""
}

# Parte della fase che precede l'apertura delle corsie. E' li' che vive il tronco da
# finire: il blocco di RIUNIONE e' anch'esso [[TRONCO]] ma sta in fondo e per definizione
# non e' ancora fatto quando si aprono le corsie. Senza questa distinzione il guardiano
# qui sotto rifiuterebbe sempre di aprirle.
sezione_pre_apertura() {
    sezione_fase "$1" | awk '/^--- apertura corsie ---/ { exit } { print }'
}

# Nomi di corsia presenti nella fase, in ordine di apparizione, senza TRONCO.
corsie_della_fase() {
    sezione_fase "$1" | grep -oE '\[\[[A-Z0-9_-]+\]\]' | tr -d '[]' | grep -v '^TRONCO$' | awk '!visto[$0]++'
}

# Blocchi ancora da fare di una corsia (o del tronco).
blocchi_da_fare() { sezione_fase "$1" | roadmap_righe_casella dafare    | grep -c "\[\[$2\]\]" || true; }
blocchi_totali()  { sezione_fase "$1" | roadmap_righe_casella qualsiasi | grep -c "\[\[$2\]\]" || true; }

# --- prepara -----------------------------------------------------------------

prepara() {
    local fase="${1:-}"
    [[ -f "$ROADMAP" ]] || die "ROADMAP.md non trovata in $ROOT_DIR"
    [[ -n "$fase" ]] || fase="$(fase_corrente)"
    [[ -n "$fase" ]] || die "Nessuna fase con blocchi da fare: non c'e' niente da parallelizzare."

    local corsie; corsie="$(corsie_della_fase "$fase")"
    [[ -n "$corsie" ]] || die "La Fase $fase non ha etichette di corsia [[NOME]]. Falla dividere dal pianificatore prima (cap. 21)."

    # Il confine fra tronco e rami e' scritto nella roadmap, non indovinato: senza quella
    # riga non si puo' sapere dove finiscono le fondamenta (cap. 21).
    if ! sezione_fase "$fase" | grep -q '^--- apertura corsie ---'; then
        die "La Fase $fase non ha la riga '--- apertura corsie ---': non posso sapere dove finisce il tronco. Vedi cap. 21."
    fi

    # GUARDIANO: il tronco viene prima dei rami, sempre. Aprire le corsie mentre le
    # fondamenta non ci sono e' l'anti-pattern numero 1 del capitolo: ogni corsia se le
    # inventerebbe per conto suo e alla riunione ci sarebbero tre versioni diverse.
    local tronco_mancante
    tronco_mancante="$(sezione_pre_apertura "$fase" | roadmap_righe_casella dafare | grep -c '\[\[TRONCO\]\]' || true)"
    if [[ "$tronco_mancante" -gt 0 ]]; then
        msg "${RED}${BOLD}Non apro le corsie: il tronco non e' finito.${NC}"
        msg "Restano ${BOLD}${tronco_mancante}${NC} blocchi [[TRONCO]] da fare nella Fase $fase:"
        sezione_pre_apertura "$fase" | roadmap_righe_casella dafare | grep '\[\[TRONCO\]\]' | sed 's/^/  /'
        msg "\n${YELLOW}Le fondamenta si costruiscono prima di dividere il lavoro (cap. 21).${NC}"
        exit 1
    fi

    msg "${BOLD}${CYAN}Preparo le corsie della Fase $fase${NC}\n"
    mkdir -p "$CORSIE_DIR"
    local n=0
    while IFS= read -r corsia; do
        [[ -z "$corsia" ]] && continue
        n=$((n+1))
        local ramo="corsia/$corsia" tavolo="$CORSIE_DIR/$corsia"
        local totali; totali="$(blocchi_totali "$fase" "$corsia")"

        if [[ -d "$tavolo" ]]; then
            msg "${YELLOW}[$corsia]${NC} tavolo gia' presente ($tavolo) — lo lascio com'e'"
            continue
        fi
        # Il ramo puo' esistere gia' (corsia smontata e riaperta): in quel caso ci si
        # riattacca invece di ricrearlo, cosi' il lavoro fatto prima non si perde.
        if git -C "$ROOT_DIR" show-ref --verify --quiet "refs/heads/$ramo"; then
            git -C "$ROOT_DIR" worktree add "$tavolo" "$ramo" >/dev/null 2>&1 || die "Non riesco ad aprire il tavolo di $corsia sul ramo $ramo"
        else
            git -C "$ROOT_DIR" worktree add -b "$ramo" "$tavolo" HEAD >/dev/null 2>&1 || die "Non riesco a creare il ramo $ramo"
        fi

        # Diario della corsia: cartella dedicata, cosi' due corsie non si sovrascrivono
        # e i loro rami si uniscono senza conflitti (file con percorsi diversi).
        local diario="$tavolo/docs/diario/corsie/$corsia"
        mkdir -p "$diario"
        if [[ ! -f "$diario/handoff.md" ]]; then
            cat > "$diario/handoff.md" << EOF
STATUS: CONTINUE
PHASE: $fase
BLOCK: (primo blocco [[$corsia]] della Fase $fase)
SUMMARY: Corsia $corsia appena aperta. Nessun blocco eseguito.
NEXT: primo blocco [[$corsia]] non ancora fatto nella ROADMAP.
PER_VILLA: Ho aperto la corsia $corsia e sto per cominciare.
TESTS: SKIPPED
EOF
        fi

        # Il diario nasce salvato, non lasciato per aria: altrimenti il tavolo risulta
        # "sporco" fin dal primo istante e non si potrebbe piu' smontare.
        if [[ -n "$(git -C "$tavolo" status --porcelain "docs/diario/corsie/$corsia" 2>/dev/null)" ]]; then
            git -C "$tavolo" add "docs/diario/corsie/$corsia" >/dev/null
            git -C "$tavolo" commit -qm "Apertura corsia $corsia" >/dev/null
        fi

        # La configurazione che non sta in git (bot Telegram, chiavi) non arriva da sola
        # nel tavolo nuovo: senza, la corsia lavorerebbe muta. Non deve finire in un commit,
        # quindi si pretende che il progetto la ignori gia'.
        if [[ -f "$ROOT_DIR/.env.runner" ]]; then
            cp "$ROOT_DIR/.env.runner" "$tavolo/.env.runner"
            git -C "$tavolo" check-ignore -q .env.runner 2>/dev/null || \
                msg "         ${YELLOW}attenzione: .env.runner non e' ignorato da git — aggiungilo a .gitignore${NC}"
        fi

        msg "${GREEN}[$corsia]${NC} tavolo pronto — ramo ${BOLD}$ramo${NC}, $totali blocchi"
        [[ "$totali" -lt "$MIN_BLOCCHI_CORSIA" && "$totali" -gt 0 ]] && \
            msg "         ${YELLOW}solo $totali blocchi: sotto i $MIN_BLOCCHI_CORSIA conviene accorparla (cap. 21)${NC}"
    done <<< "$corsie"

    msg "\n${BOLD}$n corsie pronte in${NC} $CORSIE_DIR"
    msg "Avviale tutte insieme dal menu di ${BOLD}runner.bat${NC}, oppure guarda ${BOLD}./metodo/metodo-corsie.sh stato${NC}"
}

# --- stato -------------------------------------------------------------------

stato() {
    [[ -d "$CORSIE_DIR" ]] || { msg "${YELLOW}Nessuna corsia aperta.${NC}"; return 0; }
    local fase; fase="$(fase_corrente)"
    msg "${BOLD}${CYAN}Corsie aperte${NC}  (Fase ${fase:-?})\n"
    local trovata=false
    local tavolo
    for tavolo in "$CORSIE_DIR"/*; do
        [[ -d "$tavolo" ]] || continue
        trovata=true
        local corsia; corsia="$(basename "$tavolo")"
        local h="$tavolo/docs/diario/corsie/$corsia/handoff.md"
        local st="(nessun diario)" blocco=""
        if [[ -f "$h" ]]; then
            st="$(grep -i '^STATUS:' "$h" | head -1 | sed 's/^[Ss][Tt][Aa][Tt][Uu][Ss]: *//')"
            blocco="$(grep -i '^BLOCK:' "$h" | head -1 | sed 's/^[Bb][Ll][Oo][Cc][Kk]: *//')"
        fi
        local fatti=0 totali=0
        if [[ -n "$fase" ]]; then
            totali="$(blocchi_totali "$fase" "$corsia")"
            fatti=$(( totali - $(blocchi_da_fare "$fase" "$corsia") ))
        fi
        local colore="$GREEN"
        case "$st" in *CHECKPOINT*|*BLOCKED*) colore="$YELLOW";; *ERROR*) colore="$RED";; esac
        printf "  ${BOLD}%-10s${NC} ${colore}%-12s${NC} %s/%s blocchi   %s\n" "$corsia" "$st" "$fatti" "$totali" "$blocco"
        # Lavoro non salvato: e' l'unica cosa che si perderebbe davvero smontando.
        local sporco; sporco="$(git -C "$tavolo" status --porcelain 2>/dev/null | wc -l | tr -d ' ')"
        [[ "$sporco" -gt 0 ]] && msg "             ${YELLOW}$sporco file non ancora salvati${NC}"
    done
    $trovata || msg "${YELLOW}Nessuna corsia aperta.${NC}"
}

# --- smonta ------------------------------------------------------------------

smonta() {
    [[ -d "$CORSIE_DIR" ]] || { msg "${YELLOW}Nessuna corsia da smontare.${NC}"; return 0; }
    msg "${BOLD}Smonto i tavoli${NC} (i rami restano: il lavoro non si perde)\n"
    local tavolo
    for tavolo in "$CORSIE_DIR"/*; do
        [[ -d "$tavolo" ]] || continue
        local corsia; corsia="$(basename "$tavolo")"
        # Niente --force di proposito: se c'e' lavoro non salvato git si rifiuta, e fa bene.
        if git -C "$ROOT_DIR" worktree remove "$tavolo" 2>/dev/null; then
            msg "${GREEN}[$corsia]${NC} tavolo rimosso — ramo ${BOLD}corsia/$corsia${NC} conservato"
        else
            msg "${RED}[$corsia]${NC} NON rimosso: c'e' lavoro non salvato. Salvalo, poi rilancia."
        fi
    done
    git -C "$ROOT_DIR" worktree prune
    rmdir "$CORSIE_DIR" 2>/dev/null || true
}

# --- Consiglio degli Agenti --------------------------------------------------
# Dire se una fase si puo' dividere NON e' un conto che si fa contando le righe: bisogna
# capire se due blocchi toccheranno gli stessi file, se uno aspetta il risultato dell'altro,
# se condividono un pezzo di dominio che nella roadmap non e' nemmeno nominato. E' giudizio,
# e il giudizio di uno solo su questa domanda vale poco: chi cerca di dividere trova sempre
# un modo di dividere.
# Per questo il Consiglio e' fatto di piu' agenti con incarichi DIVERSI e in contrasto fra
# loro (chi divide, chi cerca le ragioni per non dividere, chi guarda cosa deve esistere
# prima), e solo dopo si tirano le somme. E' la stessa idea del cap. 15 (validazione
# multi-agente) applicata alla decisione di aprire le corsie.
# Il Consiglio PROPONE. Decide Villa: non tocca la roadmap, scrive un documento.
# Quanto si aspetta un parere. Dieci minuti erano pochi: su una roadmap grossa un membro del
# Consiglio deve leggere una fase intera prima di poter dire qualcosa, e chi arrivava per
# secondo veniva ucciso a meta' — sempre uno diverso, che e' il modo peggiore di rompersi
# (sembra un caso, e invece era il tempo). Si puo' cambiare con CONSIGLIO_TIMEOUT_MIN.
CONSIGLIO_TIMEOUT_MIN="${CONSIGLIO_TIMEOUT_MIN:-25}"

# Tutto cio' che serve per giudicare: le regole, la fase, il progetto. Uguale per tutti i
# membri del Consiglio — cambia solo l'incarico.
dossier_fase() {
    local fase="$1"
    echo "--- LE REGOLE PER DECIDERE (capitolo 21 del Metodo Villa) ---"
    cat "$ROOT_DIR/.claude/metodo-villa/21-corsie-parallele.md" 2>/dev/null
    echo
    echo "--- LA FASE DA GIUDICARE (Fase $fase) ---"
    sezione_fase "$fase"
    echo
    if [[ -f "$ROOT_DIR/PROJECT_CONFIG.md" ]]; then
        echo "--- IL PROGETTO ---"
        cat "$ROOT_DIR/PROJECT_CONFIG.md"
    fi
}

# L'incarico di ciascun membro. Sono di proposito in contrasto: se tutti e tre dicono la
# stessa cosa, quella cosa e' solida davvero.
incarico() {
    case "$1" in
        divisore)
            echo "SEI IL DIVISORE. Il tuo compito e' trovare il modo MIGLIORE di dividere questa fase in corsie parallele, se esiste. Cerca i gruppi di blocchi che possono procedere senza mai parlarsi. Sii concreto: guarda i file e le aree del progetto che ogni blocco andrebbe a toccare (leggi il codice se serve), non fermarti al titolo del blocco.";;
        scettico)
            echo "SEI LO SCETTICO. Il tuo compito e' trovare tutte le ragioni per cui questa fase NON si puo' dividere: file che due blocchi si contenderebbero, blocchi che aspettano il risultato di altri, pezzi di dominio condivisi che nella roadmap non sono nominati, risorse locali uniche (una sola porta di anteprima, un solo database di prova, un solo emulatore). Parti dal presupposto che dividere sia sbagliato e cerca le prove. Se non ne trovi, dillo onestamente. Per OGNI ostacolo che trovi dichiara di quale delle due specie e': un MURO (non si toglie: la fase e' fatta cosi') oppure una PREPARAZIONE (si toglie prima di aprire le corsie, e allora scrivi come). Le risorse di prova condivise sono quasi sempre della seconda specie: dirle muro quando sono preparazione chiude una porta che era aperta.";;
        costruttore)
            echo "SEI IL COSTRUTTORE. Il tuo compito e' rispondere a una domanda sola: cosa deve GIA' ESISTERE, e non cambiare piu', perche' piu' agenti possano lavorare senza mai parlarsi? Elenca cosa va costruito prima (il tronco) e cosa va messo per iscritto e congelato prima di aprire le corsie (i confini). Distingui cio' che va COSTRUITO da cio' che basta SCRIVERE.";;
    esac
}

# Formato chiesto a tutti: senza, tre risposte in prosa non si possono confrontare.
formato_parere() {
    cat << 'EOF'
PRIMA DI RISPONDERE, FAI IL CONTO DEL GUADAGNO. E' quello che decide piu' spesso, e va
fatto prima di tutto il resto: se il guadagno e' piccolo, sdoppiare risorse e sorvegliare
tre tavoli e' lavoro buttato.

    tempo in parallelo = tronco + corsia piu' lunga + riunione
    guadagno           = blocchi della fase − tempo in parallelo

Il TRONCO NON SI PARALLELIZZA: si fa in sequenza prima delle corsie, e dimenticarlo nel
conto e' l'errore piu' comune. Una corsia fatta di blocchi che si aspettano l'un l'altro
(una catena) non si comprime. Sotto il 30% di guadagno si va IN FILA.

LE RISPOSTE SONO TRE, NON DUE. Un ostacolo che si puo' togliere PRIMA di aprire le corsie
non e' un motivo per dire IN FILA: e' PREPARAZIONE, diventa tronco, e il verdetto e'
DIVIDERE DOPO PREPARAZIONE. Un solo archivio di prova condiviso di solito si sdoppia (un
archivio per corsia, o un prefisso per corsia, o un archivio usa e getta). Si dice IN FILA
quando il guadagno non c'e', o quando l'ostacolo e' un muro che nessuna preparazione toglie.

Rispondi SOLO in questo formato, senza premesse e senza conclusioni:

VERDETTO: DIVIDERE oppure DIVIDERE DOPO PREPARAZIONE oppure IN FILA
GUADAGNO: blocchi della fase, tronco, corsia piu' lunga, riunione, risparmio in blocchi e in percentuale
CORSIE: nome breve maiuscolo = codici dei blocchi (una riga per corsia; vuoto se IN FILA)
TRONCO: i blocchi che devono essere finiti PRIMA di aprire le corsie (o "niente")
PREPARAZIONE: cio' che oggi impedisce di dividere ma si toglie prima di aprire, e come (o "niente")
CONFINI: cosa va congelato per iscritto prima di aprire (o "niente")
RISCHI: cio' che potrebbe andare storto, uno per riga
PERCHE': 2-3 righe, in italiano semplice, senza termini tecnici
EOF
}

# Un membro del Consiglio. Gira nella cartella del progetto: puo' leggere il codice vero,
# che e' l'unico modo per sapere se due blocchi si contenderanno gli stessi file.
# Fa parlare un agente e ne raccoglie il TESTO.
#
# Serve perche' l'agente restituisce la risposta dentro un oggetto strutturato (lo vuole il
# contatore del runner, cap. 23) mentre qui di quell'oggetto interessa una cosa sola: cosa ha
# detto. Senza questo passaggio, nel file del parere finiva l'oggetto intero — e il presidente
# si trovava a tirare le somme leggendo la scatola invece del contenuto.
#
# Se l'uscita non e' leggibile (un altro programma, una sessione interrotta a meta') si tiene
# cio' che c'e': un parere monco e' meglio di un parere perso. Se non c'e' proprio niente, il
# perche' resta scritto accanto, in un file .errore che il chiamante puo' mostrare.
raccogli_testo_agente() {
    local prompt_file="$1" uscita="$2"
    local grezzo="$uscita.grezzo"
    # Con la testa: il Consiglio decide come dividere una fase intera: sbagliare qui costa
    # tutto il lavoro delle corsie. Vedi con_la_testa() in metodo-agente.sh.
    CARTELLA_DI_LAVORO="$ROOT_DIR" con_la_testa esegui_agente "$prompt_file" > "$grezzo" 2>"$uscita.errore" || true
    local testo=""
    [[ -s "$grezzo" ]] && testo="$(python "$SCRIPT_DIR/leggi-conto.py" testo < "$grezzo" 2>/dev/null || true)"
    if [[ -n "$testo" ]]; then printf '%s
' "$testo" > "$uscita"
    elif [[ -s "$grezzo" ]]; then cp "$grezzo" "$uscita"
    fi
    rm -f "$grezzo"
}

chiedi_parere() {
    local ruolo="$1" fase="$2" uscita="$3"
    {
        dossier_fase "$fase"
        echo
        echo "--- IL TUO INCARICO ---"
        incarico "$ruolo"
        echo
        echo "Non ti occupi di eseguire nulla: solo di giudicare. Non modificare nessun file."
        echo
        formato_parere
    } > "$uscita.prompt"
    raccogli_testo_agente "$uscita.prompt" "$uscita"
}

# Le somme le tira un membro che non ha partecipato al dibattito: legge i tre pareri e
# decide. Cosi' chi sintetizza non difende la propria tesi.
sintesi_del_consiglio() {
    local fase="$1" dir="$2" uscita="$3"
    {
        echo "Sei il PRESIDENTE del Consiglio degli Agenti del Metodo Villa."
        echo "Tre agenti hanno giudicato la stessa fase con incarichi diversi e in contrasto."
        echo "Il tuo compito e' tirare le somme per Villa, che NON e' un tecnico e decidera' lui."
        echo
        dossier_fase "$fase"
        echo
        local r
        for r in divisore scettico costruttore; do
            echo "--- PARERE DEL $(echo "$r" | tr '[:lower:]' '[:upper:]') ---"
            cat "$dir/$r.txt" 2>/dev/null || echo "(nessun parere)"
            echo
        done
        cat << 'EOF'
--- COME DEVI RISPONDERE ---
Regole:
- Se i pareri sono in disaccordo, dillo apertamente e spiega chi ha ragione e perche'.
- PARTI DAL CONTO DEL GUADAGNO, e rifallo tu: tempo in parallelo = tronco + corsia piu'
  lunga + riunione; guadagno = blocchi della fase meno quel totale. Il tronco NON si
  parallelizza. Sotto il 30% di guadagno si va IN FILA, e non serve discutere altro.
- Distingui il MURO dalla PREPARAZIONE. Se l'unico ostacolo si toglie prima di aprire le
  corsie (tipico: un solo archivio di prova condiviso, che si sdoppia), il verdetto e'
  DIVIDERE DOPO PREPARAZIONE, non IN FILA — e la preparazione diventa tronco. Si dice IN
  FILA quando il guadagno non c'e', o quando l'ostacolo non lo toglie nessuna preparazione.
- In dubbio, scegli IN FILA: il parallelo non e' il default, e una fase divisa male costa
  piu' di una fase fatta in sequenza.
- Se una corsia avrebbe meno di 3 blocchi, accorpala.

Rispondi SOLO in questo formato:

VERDETTO: DIVIDERE oppure DIVIDERE DOPO PREPARAZIONE oppure IN FILA
FIDUCIA: alta oppure media oppure bassa
GUADAGNO: una riga sola coi numeri — blocchi della fase, tronco, corsia piu' lunga,
riunione, risparmio in blocchi e in percentuale
CORSIE: nome breve maiuscolo = codici dei blocchi (una riga per corsia; vuoto se IN FILA)
TRONCO: i blocchi da finire prima di aprire le corsie (o "niente")
PREPARAZIONE: cosa va tolto di mezzo prima di aprire, e come (o "niente")
CONFINI: cosa congelare per iscritto prima di aprire (o "niente")
DISACCORDI: dove i tre non erano d'accordo (o "nessuno")
PER_VILLA: 3-5 righe in italiano di tutti i giorni, come lo diresti a voce a qualcuno che
non ha letto niente. Niente nomi di file, niente codici di blocco, niente termini inglesi.
Dev'essere chiaro cosa conviene fare e perche'.
EOF
    } > "$uscita.prompt"
    raccogli_testo_agente "$uscita.prompt" "$uscita"
}

# La riga del verdetto come la vede Villa.
#
# E' una funzione a se' per una ragione sola: la risposta di mezzo — DIVIDERE DOPO
# PREPARAZIONE — contiene la parola DIVIDERE, e se venisse riconosciuta dopo le altre
# comparirebbe a schermo come un via libera che non e'. E' un errore che guardando lo
# schermo non si vede (la riga sembra giusta), quindi lo guardano le prove.
riga_del_verdetto() {
    local verdetto="$1" fiducia="${2:-}"
    local coda="   (fiducia: ${fiducia:-non dichiarata})"
    case "$verdetto" in
        *PREPARAZIONE*) msg "${CYAN}${BOLD}  DIVIDERE, ma prima va preparato quello che segue${NC}$coda";;
        *DIVIDERE*)     msg "${GREEN}${BOLD}  DIVIDERE in corsie${NC}$coda";;
        *IN\ FILA*)     msg "${YELLOW}${BOLD}  IN FILA, un blocco per volta${NC}$coda";;
        *)              msg "${YELLOW}  verdetto non riconosciuto: leggi il documento${NC}";;
    esac
}

# Estrae un campo dalla risposta (dalla riga "CAMPO:" fino al campo successivo).
campo_del_verdetto() {
    awk -v c="$1" '
        $0 ~ ("^" c ":") { trovato=1; sub("^" c ": *", ""); if (NF) print; next }
        trovato && /^[A-Z_]+:/ { exit }
        trovato { print }
    ' "$2"
}

consiglio() {
    local fase="${1:-}"
    if ! _errore_agente="$(verifica_agente_installato)"; then die "$_errore_agente"; fi
    [[ -f "$ROADMAP" ]] || die "ROADMAP.md non trovata in $ROOT_DIR"
    [[ -n "$fase" ]] || fase="$(fase_corrente)"
    [[ -n "$fase" ]] || die "Nessuna fase con blocchi da fare."
    local quanti; quanti="$(sezione_fase "$fase" | roadmap_righe_casella dafare | grep -c . || true)"
    [[ "${quanti:-0}" -gt 0 ]] || die "La Fase $fase non ha blocchi da fare."

    msg "${BOLD}${CYAN}Consiglio degli Agenti — Fase $fase${NC}  ($quanti blocchi da fare)\n"
    if [[ "$quanti" -lt 4 ]]; then
        msg "${YELLOW}Solo $quanti blocchi: quasi sicuramente conviene farli in fila."
        msg "Convoco lo stesso il Consiglio, ma aspettati un IN FILA.${NC}\n"
    fi

    local dir; dir="$(mktemp -d)"
    trap 'rm -rf "$dir"' RETURN

    msg "Tre agenti stanno esaminando la fase, ognuno con un incarico diverso:"
    msg "  ${BOLD}divisore${NC}    cerca il modo migliore di dividere"
    msg "  ${BOLD}scettico${NC}    cerca le ragioni per NON dividere"
    msg "  ${BOLD}costruttore${NC} guarda cosa deve esistere prima"
    msg "\n(fino a ${CONSIGLIO_TIMEOUT_MIN} minuti)\n"

    # I tre pareri si formano in parallelo: sono indipendenti, e uno per volta sarebbe
    # tre volte l'attesa senza nessun guadagno.
    local ruoli="divisore scettico costruttore" pids="" r
    for r in $ruoli; do
        chiedi_parere "$r" "$fase" "$dir/$r.txt" &
        pids="$pids $!"
    done
    # Cane da guardia: qui gli agenti leggono e scrivono un file, non avviano server, quindi
    # non serve l'artiglieria del runner (che uccide interi alberi di processi). Lascia un
    # segno di essere scattato: cosi' un parere mancante si sa se e' morto o se e' finito il
    # tempo — prima erano indistinguibili, e sembrava che il Consiglio si rompesse a caso.
    ( sleep $((CONSIGLIO_TIMEOUT_MIN * 60))
      for _r in $ruoli; do : > "$dir/$_r.txt.scaduto"; done
      kill $pids 2>/dev/null ) >/dev/null 2>&1 &
    local guardia=$!
    wait $pids 2>/dev/null || true
    kill "$guardia" 2>/dev/null || true

    local arrivati=0
    for r in $ruoli; do
        if [[ -s "$dir/$r.txt" ]]; then
            arrivati=$((arrivati+1)); msg "${GREEN}  parere del $r: arrivato${NC}"
        else
            # "Non pervenuto" da solo non dice niente e non si puo' rimediare. Il perche' c'e'
            # sempre: o l'agente ha detto qualcosa nell'errore, o e' finito il tempo.
            local perche="non so perche'"
            if [[ -s "$dir/$r.txt.errore" ]]; then
                perche="$(tail -c 200 "$dir/$r.txt.errore" | tr '\n' ' ')"
            elif [[ -e "$dir/$r.txt.scaduto" ]]; then
                perche="e' finito il tempo (${CONSIGLIO_TIMEOUT_MIN} minuti). Rilancia con CONSIGLIO_TIMEOUT_MIN piu' alto."
            fi
            msg "${YELLOW}  parere del $r: non pervenuto — ${perche}${NC}"
        fi
    done
    [[ "$arrivati" -gt 0 ]] || die "Nessun parere e' arrivato. Riprova, o guarda se 'claude' funziona."

    msg "\nIl presidente tira le somme..."
    sintesi_del_consiglio "$fase" "$dir" "$dir/verdetto.txt"
    [[ -s "$dir/verdetto.txt" ]] || die "La sintesi non e' arrivata. I pareri singoli erano $arrivati."

    # Il documento resta: la decisione di dividere una fase va ritrovata fra un mese.
    local doc="docs/fondamenta/consiglio-agenti-fase-$fase.md"
    mkdir -p "$ROOT_DIR/docs/fondamenta"
    {
        echo "# Consiglio degli Agenti — Fase $fase"
        echo
        echo "> Convocato il $(date '+%Y-%m-%d %H:%M'). Pareri arrivati: $arrivati su 3."
        echo "> Il Consiglio **propone**: la decisione e' di Villa. Regole: \`.claude/metodo-villa/21-corsie-parallele.md\`"
        echo
        echo "## Verdetto"
        echo
        cat "$dir/verdetto.txt"
        echo
        echo "---"
        echo
        echo "## I pareri, per esteso"
        for r in $ruoli; do
            echo
            echo "### $r"
            echo '```'
            cat "$dir/$r.txt" 2>/dev/null || echo "(non pervenuto)"
            echo '```'
        done
    } > "$ROOT_DIR/$doc"

    # A schermo solo cio' che serve per decidere.
    local verdetto fiducia
    verdetto="$(campo_del_verdetto VERDETTO "$dir/verdetto.txt" | head -1)"
    fiducia="$(campo_del_verdetto FIDUCIA "$dir/verdetto.txt" | head -1)"
    msg "\n${BOLD}${CYAN}════ VERDETTO ════${NC}"
    riga_del_verdetto "$verdetto" "$fiducia"
    # Il guadagno e' il numero su cui si decide: se resta dentro al documento, Villa vede
    # un si'/no senza sapere quanto vale. Va a schermo sempre, anche quando e' piccolo —
    # anzi, soprattutto quando e' piccolo (cap. 21, "Il conto del guadagno").
    local guadagno; guadagno="$(campo_del_verdetto GUADAGNO "$dir/verdetto.txt")"
    [[ -n "$guadagno" ]] && { msg "\n${BOLD}Guadagno atteso:${NC}"; printf '%s\n' "$guadagno" | sed 's/^/  /'; }
    local preparazione; preparazione="$(campo_del_verdetto PREPARAZIONE "$dir/verdetto.txt")"
    if [[ -n "$preparazione" && ! "$preparazione" =~ ^[[:space:]]*[Nn]iente ]]; then
        msg "\n${BOLD}Da preparare prima di aprire le corsie:${NC}"
        printf '%s\n' "$preparazione" | sed 's/^/  /'
    fi
    local per_villa; per_villa="$(campo_del_verdetto PER_VILLA "$dir/verdetto.txt")"
    [[ -n "$per_villa" ]] && { msg ""; printf '%s\n' "$per_villa" | sed 's/^/  /'; }
    local corsie_proposte; corsie_proposte="$(campo_del_verdetto CORSIE "$dir/verdetto.txt")"
    [[ -n "$corsie_proposte" ]] && { msg "\n${BOLD}Corsie proposte:${NC}"; printf '%s\n' "$corsie_proposte" | sed 's/^/  /'; }
    msg "\nTutto il resto (pareri per esteso, rischi, disaccordi): ${BOLD}$doc${NC}"
    msg "${YELLOW}Il Consiglio non ha toccato la ROADMAP: le etichette [[CORSIA]] le metti tu se sei d'accordo.${NC}"
}

# --- riunisci ----------------------------------------------------------------
# La parte dove si perde tutto se si va di fretta (cap. 21). Le corsie si uniscono UNA
# PER VOLTA, con la verifica dopo ognuna: se qualcosa si rompe si sa subito quale corsia
# l'ha rotto. Unendole tutte insieme, davanti a un test rosso non si saprebbe da dove
# cominciare a guardare.

# Comando di verifica del progetto: si legge da PROJECT_CONFIG.md, sotto "Esecuzione test".
# Se non c'e', NON si finge che vada tutto bene: si dice a chiare lettere che nessuno ha
# verificato niente.
comando_test_dal_config() {
    local cfg="$ROOT_DIR/PROJECT_CONFIG.md"
    [[ -f "$cfg" ]] || return 0
    awk '
        /[Ee]secuzione test/ { cerca=1; next }
        cerca && /^```/ { exit }
        cerca && /^[[:space:]]*#/ { next }
        cerca && NF { print; exit }
    ' "$cfg"
}

riunisci() {
    local cmd_test="${1:-}"
    [[ -f "$ROADMAP" ]] || die "ROADMAP.md non trovata in $ROOT_DIR"
    local fase; fase="$(fase_corrente)"
    [[ -n "$fase" ]] || die "Nessuna fase con blocchi da fare."

    local ramo; ramo="$(git -C "$ROOT_DIR" branch --show-current)"
    [[ "$ramo" == "main" || "$ramo" == "master" ]] && die "Sei su '$ramo': la riunione si fa su un ramo di lavoro, mai sul ramo principale."
    [[ -z "$(git -C "$ROOT_DIR" status --porcelain)" ]] || die "Ci sono modifiche non salvate qui: salvale prima di rimettere insieme il lavoro."

    local corsie; corsie="$(corsie_della_fase "$fase")"
    [[ -n "$corsie" ]] || die "La Fase $fase non ha corsie da riunire."

    [[ -z "$cmd_test" ]] && cmd_test="$(comando_test_dal_config)"

    msg "${BOLD}${CYAN}Rimetto insieme il lavoro della Fase $fase${NC}"
    msg "Ramo di arrivo: ${BOLD}$ramo${NC}"
    if [[ -n "$cmd_test" ]]; then
        msg "Verifica dopo ogni corsia: ${BOLD}$cmd_test${NC}\n"
    else
        msg "${YELLOW}Nessun comando di verifica trovato in PROJECT_CONFIG.md: unisco senza verificare."
        msg "Passalo con --test \"comando\" se vuoi che controlli davvero.${NC}\n"
    fi

    # L'ordine e' quello in cui le corsie compaiono nella roadmap: l'ha deciso il
    # pianificatore, che sa quale ha toccato di piu' le zone comuni (cap. 21).
    local unite=0
    while IFS= read -r corsia; do
        [[ -z "$corsia" ]] && continue
        local ramo_corsia="corsia/$corsia"
        if ! git -C "$ROOT_DIR" show-ref --verify --quiet "refs/heads/$ramo_corsia"; then
            msg "${YELLOW}[$corsia]${NC} nessun ramo $ramo_corsia: salto"
            continue
        fi
        # Lavoro non salvato in una corsia ancora aperta: unirla adesso vorrebbe dire
        # lasciarne fuori un pezzo senza accorgersene.
        local tavolo="$CORSIE_DIR/$corsia"
        if [[ -d "$tavolo" && -n "$(git -C "$tavolo" status --porcelain 2>/dev/null)" ]]; then
            die "[$corsia] ha lavoro non ancora salvato. Salvalo, poi rilancia la riunione."
        fi

        msg "${BLUE}[$corsia]${NC} unisco $ramo_corsia..."
        if ! git -C "$ROOT_DIR" merge --no-ff "$ramo_corsia" -m "Riunione corsia $corsia (Fase $fase)" >/dev/null 2>&1; then
            msg "\n${RED}${BOLD}Conflitto unendo la corsia $corsia.${NC}"
            msg "File in conflitto:"
            git -C "$ROOT_DIR" diff --name-only --diff-filter=U | sed 's/^/  /'
            msg "\n${YELLOW}Non lo risolvo da solo (cap. 07): decide Villa."
            msg "Il conflitto e' rimasto aperto qui. Risolvilo, poi rilancia la riunione."
            msg "Per annullare tutto: git merge --abort${NC}"
            exit 1
        fi
        unite=$((unite+1))
        msg "${GREEN}[$corsia]${NC} unita"

        # La verifica gira su TUTTO il progetto, non solo sulla corsia appena unita: e'
        # esattamente cio' che nessuna corsia poteva controllare da sola.
        if [[ -n "$cmd_test" ]]; then
            msg "         verifico l'insieme..."
            if ( cd "$ROOT_DIR" && eval "$cmd_test" >/dev/null 2>&1 ); then
                msg "${GREEN}         verifica passata${NC}"
            else
                msg "\n${RED}${BOLD}La verifica non passa dopo aver unito la corsia $corsia.${NC}"
                msg "${YELLOW}Mi fermo qui: le corsie che restano NON sono state unite."
                msg "Cosi' sai con certezza che il problema arriva da questa corsia."
                msg "Sistema, poi rilancia la riunione.${NC}"
                exit 1
            fi
        fi
    done <<< "$corsie"

    msg "\n${BOLD}${GREEN}$unite corsie rimesse insieme.${NC}"
    [[ -n "$cmd_test" ]] || msg "${YELLOW}Ricorda: nessuna verifica e' stata eseguita.${NC}"
    msg "Ora chiudi i tavoli con ${BOLD}./metodo/metodo-corsie.sh smonta${NC} e marca il blocco di riunione nella ROADMAP."
}

# --- ingresso ----------------------------------------------------------------

# Il dispatch parte solo se lo script e' lanciato davvero. Facendone il "source" si
# ottengono le sole funzioni, che e' come le prove le verificano una per una senza
# aprire corsie vere (stessa convenzione del runner).
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then return 0; fi

comando="${1:-}"; shift || true
fase_arg=""; test_arg=""
while [[ $# -gt 0 ]]; do
    case "$1" in
        --fase) fase_arg="$2"; shift 2;;
        --test) test_arg="$2"; shift 2;;
        *) die "Opzione sconosciuta: $1";;
    esac
done

case "$comando" in
    consiglio) consiglio "$fase_arg";;
    prepara)  prepara "$fase_arg";;
    stato)    stato;;
    smonta)   smonta;;
    riunisci) riunisci "$test_arg";;
    *) echo "Uso: ./metodo/metodo-corsie.sh {consiglio [--fase N] | prepara [--fase N] | stato | smonta | riunisci [--test \"comando\"]}"
       echo "  consiglio il Consiglio degli Agenti: dice se conviene dividere la fase, e come"
       echo "  prepara   apre un tavolo di lavoro separato per ogni corsia della fase"
       echo "  stato     mostra a che punto e' ogni corsia"
       echo "  smonta    rimuove i tavoli, conserva i rami"
       echo "  riunisci  rimette insieme il lavoro una corsia per volta, verificando dopo ognuna"
       echo "Regole: .claude/metodo-villa/21-corsie-parallele.md"
       exit 1;;
esac
