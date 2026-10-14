#!/usr/bin/env bash
# Il giro delle schede: raccoglie gli indirizzari dai progetti e li ridistribuisce a tutti.
#
# IL PROBLEMA. L'agente la riga la scrive da solo (la chiusura di blocco gliela chiede), ma
# quella riga resta dentro il progetto dove e' nata. Per farla arrivare agli altri servirebbero
# due comandi per ogni progetto: il rimando e lo scarico. Con venti progetti, non succede mai —
# ed e' esattamente il motivo per cui sette progetti Senil hanno versioni diverse del Metodo.
#
# LA DIFFERENZA CON IL SYNC DEL METODO (cap. 19). Quel rimando e' sorvegliato apposta: le
# regole toccano il comportamento di tutti i progetti, e Villa le approva una per una. Le
# schede no: sono dati che si aggiungono, non regole che cambiano il modo di lavorare. Una
# riga in piu' nell'indirizzario non fa fare niente di diverso a nessuno — dice solo dove
# guardare. Per questo qui il giro puo' essere automatico, e li' no.
#
# COSA FA
#   raccogli     da ogni progetto prende la SUA scheda (un file per progetto: nessuno tocca
#                quella di un altro, quindi non ci sono conflitti) e la porta nella madre
#   distribuisci copia l'indirizzario della madre dentro ogni progetto che ha il Metodo
#   giro         raccogli + distribuisci
#   stato        dice soltanto cosa cambierebbe, senza toccare niente
#
# NON TOCCA GIT. Copia i file e riferisce: il commit lo fa chi guarda. Ed evita i repository
# PUBBLICI (cap. 28): le schede sono la mappa di cosa c'e' dentro i progetti privati.

set -uo pipefail

QUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MADRE="$(dirname "$QUI")"
CARTELLA=".claude/precedenti"
# I progetti stanno accanto alla madre. Si puo' cambiare per le prove.
RADICE_PROGETTI="${METODO_PROGETTI:-$(dirname "$MADRE")}"

azzurro() { printf '%s\n' "$*"; }

# Un progetto conta se ha il Metodo dentro. Gli archivi e le copie non si toccano.
ha_il_metodo() { [ -d "$1/.claude/metodo-villa" ]; }
e_una_copia()  { case "$(basename "$1")" in *" - Copia"|"TEMPORANEA-"*|"["*|*"-archivio") return 0 ;; esac; return 1; }

# I repository pubblici restano fuori: l'indirizzario e' la mappa dei progetti privati.
# Senza lo strumento di GitHub non si puo' sapere: in dubbio si salta, e lo si dice.
e_pubblico() {
    local url; url="$(git -C "$1" remote get-url origin 2>/dev/null)" || return 1
    [ -z "$url" ] && return 1
    command -v gh >/dev/null 2>&1 || return 2
    local slug; slug="$(printf '%s' "$url" | sed 's#.*[:/]\([^/]*/[^/]*\)\.git$#\1#; s#.*[:/]\([^/]*/[^/]*\)$#\1#')"
    [ "$(gh repo view "$slug" --json visibility -q .visibility 2>/dev/null)" = "PUBLIC" ]
}

# La ricevuta di consegna: dentro ogni progetto, l'elenco "nome impronta" di cio' che la madre
# gli ha mandato l'ultima volta.
#
# Serve a distinguere le due cose che altrimenti si confondono: una scheda **nata li'** (da
# raccogliere) e la **copia intatta di una scheda ricevuta** (da lasciar stare). Senza,
# succede il pasticcio visto il 2026-08-15: due schede erano state fuse in una nella madre, e
# al giro dopo sono tornate su dai progetti che ne avevano ancora la copia — cancellate a
# monte e resuscitate a valle, all'infinito.
RICEVUTA=".ricevuto"

impronta() { sha1sum "$1" 2>/dev/null | cut -d' ' -f1; }

# Come era il file quando il progetto l'ha ricevuto (vuoto se non l'ha mai ricevuto).
impronta_ricevuta() {
    local dir="$1" nome="$2"
    [ -f "$dir/$CARTELLA/$RICEVUTA" ] || return 0
    awk -v n="$nome" '$1==n {print $2}' "$dir/$CARTELLA/$RICEVUTA" 2>/dev/null | head -1
}

# Le schede che il progetto ha DAVVERO da dire: quelle nate li', o che ha modificato dopo
# averle ricevute. Le copie intatte non risalgono.
schede_proprie() {
    local dir="$1" f nome ric
    for f in "$dir/$CARTELLA"/*.md; do
        [ -e "$f" ] || continue
        nome="$(basename "$f")"
        [ "$nome" = "README.md" ] && continue
        ric="$(impronta_ricevuta "$dir" "$nome")"
        if [ -z "$ric" ]; then
            printf '%s\n' "$nome"                      # mai ricevuta: e' nata qui
        elif [ "$ric" != "$(impronta "$f")" ]; then
            printf '%s\n' "$nome"                      # ricevuta e poi modificata qui
        fi
    done
}

# Progetti da lasciare stare in questa passata: si dichiarano con --salta nome1,nome2.
# Serve quando su un progetto c'e' un runner al lavoro: copiargli dei file sotto le mani
# significa vederseli comparire dentro il commit di fine blocco, che parla d'altro.
SALTA=""
e_saltato() {
    local nome; nome="$(basename "$1")"
    case ",$SALTA," in *",$nome,"*) return 0 ;; esac
    return 1
}

progetti() {
    local d
    for d in "$RADICE_PROGETTI"/*/; do
        d="${d%/}"
        [ "$d" = "$MADRE" ] && continue
        ha_il_metodo "$d" || continue
        e_una_copia "$d" && continue
        printf '%s\n' "$d"
    done
}

raccogli() {
    local solo_stato="${1:-no}" n=0
    azzurro "== raccolgo le schede dai progetti =="
    local d nome scheda
    while IFS= read -r d; do
        nome="$(basename "$d")"
        e_saltato "$d" && { azzurro "  .. $nome : saltato su richiesta"; continue; }
        while IFS= read -r scheda; do
            [ -n "$scheda" ] || continue
            azzurro "  <- $nome : $scheda"
            [ "$solo_stato" = "no" ] && cp "$d/$CARTELLA/$scheda" "$MADRE/$CARTELLA/$scheda"
            n=$((n+1))
        done < <(schede_proprie "$d")
    done < <(progetti)
    [ "$n" -eq 0 ] && azzurro "  (niente di nuovo)"
    return 0
}

distribuisci() {
    local solo_stato="${1:-no}" n=0 saltati=0
    azzurro "== distribuisco l'indirizzario ai progetti =="
    local d nome
    while IFS= read -r d; do
        nome="$(basename "$d")"
        e_saltato "$d" && { azzurro "  .. $nome : saltato su richiesta"; saltati=$((saltati+1)); continue; }
        e_pubblico "$d"
        case "$?" in
            0) azzurro "  !! $nome : PUBBLICO, saltato (cap. 28)"; saltati=$((saltati+1)); continue ;;
            2) azzurro "  ?? $nome : impossibile sapere se e' pubblico (manca gh), saltato"; saltati=$((saltati+1)); continue ;;
        esac
        # Divergenza dichiarata dal progetto: si rispetta, come per il resto del Metodo.
        if [ -f "$d/.metodo-sync-ignore" ] && grep -qF "$CARTELLA" "$d/.metodo-sync-ignore" 2>/dev/null; then
            azzurro "  -- $nome : escluso dal suo .metodo-sync-ignore"; saltati=$((saltati+1)); continue
        fi
        if [ "$solo_stato" = "no" ]; then
            mkdir -p "$d/$CARTELLA"
            # Le schede si RINOMINANO e si FONDONO (un modulo che entra in un monorepo smette
            # di avere una scheda sua). Copiare e basta lascerebbe nel progetto la versione
            # vecchia col nome vecchio: peggio che non averla, perche' manda l'agente a cercare
            # un repository che non esiste piu'. Si toglie solo cio' che il progetto AVEVA
            # RICEVUTO e la madre non ha piu' — mai quello che e' nato li'.
            # NB: non chiamare queste variabili "n", e' il contatore della funzione.
            local f nomefile
            for f in "$d/$CARTELLA"/*.md; do
                [ -e "$f" ] || continue
                nomefile="$(basename "$f")"
                [ -f "$MADRE/$CARTELLA/$nomefile" ] && continue
                [ -n "$(impronta_ricevuta "$d" "$nomefile")" ] || continue
                rm -f "$f"; azzurro "     (tolta la scheda superata: $nomefile)"
            done
            cp "$MADRE/$CARTELLA"/*.md "$d/$CARTELLA/" 2>/dev/null
            # La ricevuta: cosa gli ho mandato e com'era. E' cio' che al prossimo giro
            # distinguera' le sue schede dalle copie.
            : > "$d/$CARTELLA/$RICEVUTA"
            for f in "$MADRE/$CARTELLA"/*.md; do
                [ -e "$f" ] || continue
                printf '%s %s\n' "$(basename "$f")" "$(impronta "$f")" >> "$d/$CARTELLA/$RICEVUTA"
            done
        fi
        azzurro "  -> $nome"
        n=$((n+1))
    done < <(progetti)
    azzurro "  ($n serviti, $saltati saltati)"
    return 0
}

CMD="${1:-giro}"; shift 2>/dev/null || true
while [ $# -gt 0 ]; do
    case "$1" in
        --salta) SALTA="${2:-}"; shift 2 ;;
        *) echo "opzione sconosciuta: $1" >&2; exit 1 ;;
    esac
done

case "$CMD" in
    raccogli)     raccogli no ;;
    distribuisci) distribuisci no ;;
    giro)         raccogli no; echo; distribuisci no ;;
    stato)        raccogli si; echo; distribuisci si; echo; azzurro "(nessun file toccato: era solo un'occhiata)" ;;
    *) echo "uso: metodo-precedenti.sh [giro|raccogli|distribuisci|stato] [--salta nome1,nome2]" >&2; exit 1 ;;
esac
