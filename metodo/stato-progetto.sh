#!/usr/bin/env bash
# LO STATO DEL PROGETTO come lo vede il Metodo, in una forma che una macchina legge.
#
# Serve al servitore della schermata (servitore-gui.py). Per mostrare "a che punto siamo"
# e "con che impostazioni si parte" bisogna sapere due cose che il Metodo sa gia':
#   - come si conta una roadmap                -> metodo-roadmap.sh (regole condivise)
#   - come si risolvono le impostazioni della corsa -> metodo-agente.sh + .env.runner,
#     nello stesso ordine di autorita' del runner (condivisa -> progetto -> modulo)
# Riscriverle in un altro linguaggio vorrebbe dire farle divergere: la schermata direbbe
# "impegno alto" mentre la corsa parte a medio, e nessuno se ne accorgerebbe. Qui non si
# decide niente e non si esegue niente: si legge e si stampa.
#
#   metodo/stato-progetto.sh [cartella-del-progetto] [modalita] [tetto] [fase]
#
# Stampa righe "chiave|valore" (una informazione per riga, come metodo-modelli.sh):
#
#   progetto|Metodo-Villa-v2          nome della cartella del progetto
#   cartella|/c/Users/.../progetto    percorso assoluto
#   ramo|blocco/gui-fase5             ramo git corrente (vuoto se non e' un repository)
#   agente|claude                     chi eseguirebbe i blocchi, gia' risolto
#   modello|                          modello fissato (vuoto = default del programma)
#   impegno|high                      quanto pensa prima di rispondere
#   ottimizza|no                      un motore per ogni peso di blocco: si|no
#   tetto|300                         tetto di sicurezza (blocchi massimi per corsa)
#   timeout|30                        minuti massimi per blocco
#   roadmap|si                        la roadmap esiste ed e' leggibile: si|no
#   roadmap_fatti|57                  caselle [x] su tutta la roadmap
#   roadmap_da_fare|6                 caselle [ ] su tutta la roadmap
#   fase|5|3|6                        una riga per fase: nome, fatti, da fare
#   previsione|4|poi finisce la fase 5  quanto manca a QUESTA corsa, e perche' si ferma
#
# La previsione dipende da come la corsa e' impostata: gli argomenti 2-4 sono la modalita'
# (fase|tutte), il tetto e la fase da cui si conta (la sa il servitore, da progress.json;
# vuota = prima fase con lavoro, come fa il runner). La regola del conto non e' qui: e' in
# metodo-roadmap.sh, condivisa col runner — la stessa che annuncia la corsa a terminale.
#
# I valori di 'tetto' e 'timeout' sono i default del runner: qui si ripetono perche' la
# schermata deve presentarli gia' compilati. Se cambiano nel runner vanno cambiati anche
# qui — sono due numeri, e l'alternativa (far stampare i default al runner) vorrebbe dire
# lanciarlo per sapere come sarebbe partito.

set -uo pipefail

QUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RADICE_METODO="$(cd "$QUI/.." && pwd)"
PROGETTO="${1:-$RADICE_METODO}"
PROGETTO="$(cd "$PROGETTO" 2>/dev/null && pwd)" || { echo "Cartella del progetto non trovata: ${1:-}" >&2; exit 1; }

# Stessa catena del runner, dalla piu' generale alla piu' specifica: chi viene dopo vince.
METODO_CONFIG_CONDIVISA="${METODO_CONFIG_CONDIVISA:-$HOME/.metodo-villa/condivisa.env}"
[[ -f "$METODO_CONFIG_CONDIVISA" ]] && source "$METODO_CONFIG_CONDIVISA"
[[ -f "$RADICE_METODO/.env.runner" ]] && source "$RADICE_METODO/.env.runner"
[[ "$PROGETTO" != "$RADICE_METODO" && -f "$PROGETTO/.env.runner" ]] && source "$PROGETTO/.env.runner"

# risolvi_agente legge queste tre variabili prima di scriverle: con 'set -u' vanno
# esistenti. Vuote = "nessuna scelta sulla riga di comando", che e' il caso di qui.
AGENTE=""; MODEL_OVERRIDE=""; IMPEGNO=""
source "$QUI/metodo-agente.sh"
source "$QUI/metodo-roadmap.sh"
# Se la configurazione del progetto contiene un valore sbagliato (impegno inventato,
# agente sconosciuto) risolvi_agente lo dice su stderr e fallisce: la schermata deve
# mostrare quell'errore invece di partire con dei valori a caso.
risolvi_agente || exit 1

ottimizza="no"
[[ "${METODO_OTTIMIZZA:-}" =~ ^(si|sì|yes|true|1)$ ]] && ottimizza="si"

echo "progetto|$(basename "$PROGETTO")"
echo "cartella|$PROGETTO"
echo "ramo|$(git -C "$PROGETTO" branch --show-current 2>/dev/null || true)"
echo "agente|$AGENTE"
echo "modello|$MODEL_OVERRIDE"
echo "impegno|$IMPEGNO"
echo "ottimizza|$ottimizza"
echo "tetto|300"
echo "timeout|30"

ROADMAP="$PROGETTO/ROADMAP.md"
if [[ ! -f "$ROADMAP" ]]; then
    echo "roadmap|no"
    exit 0
fi
echo "roadmap|si"
echo "roadmap_fatti|$(roadmap_righe_casella fatto < "$ROADMAP" | wc -l | tr -d ' ')"
echo "roadmap_da_fare|$(roadmap_righe_casella dafare < "$ROADMAP" | wc -l | tr -d ' ')"

while IFS= read -r fase; do
    [[ -n "$fase" ]] || continue
    sezione="$(roadmap_sezione_fase "$ROADMAP" "$fase")"
    fatti="$(printf '%s\n' "$sezione" | roadmap_righe_casella fatto | wc -l | tr -d ' ')"
    da_fare="$(printf '%s\n' "$sezione" | roadmap_righe_casella dafare | wc -l | tr -d ' ')"
    echo "fase|$fase|$fatti|$da_fare"
done < <(roadmap_nomi_di_fase "$ROADMAP")

# Quanto manca a QUESTA corsa. La regola (previsione_corsa) vive in metodo-roadmap.sh e
# legge tre variabili d'ambiente di lavoro: qui si preparano dagli argomenti, cosi' la
# schermata e il runner contano allo stesso modo senza che nessuno riscriva la regola.
MODALITA="${2:-fase}"
case "$MODALITA" in
    fase)   ALL_PHASES=false ;;
    tutte)  ALL_PHASES=true ;;
    *) echo "Modalita' sconosciuta: $MODALITA (ammesse: fase, tutte)." >&2; exit 1 ;;
esac
TETTO="${3:-300}"
[[ "$TETTO" =~ ^[0-9]+$ ]] || { echo "Il tetto dev'essere un numero (arrivato: $TETTO)." >&2; exit 1; }
PROJECT_DIR="$PROGETTO"
echo "previsione|$(previsione_corsa "${4:-}" "$TETTO")"
