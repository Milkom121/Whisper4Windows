#!/usr/bin/env bash
# ACCENDI UN PROGRAMMA CHE RESTA ACCESO, FAI LA TUA PROVA, SPEGNILO. Sempre.
#
#   metodo/con-servitore.sh <porta> <secondi-di-attesa> -- <comando che accende> -- <comando di prova>
#
# Esempio:
#   metodo/con-servitore.sh 8799 20 \
#       -- python metodo/servitore-gui.py --porta 8799 --cartella . \
#       -- curl -sf http://127.0.0.1:8799/api/stato
#
# PERCHE' ESISTE. Il 2026-08-16 il blocco 5.6 si e' piantato e ha fermato la corsa. L'ultima
# mossa dell'agente era accendere il servitore della schermata:
#     Start-Process python -ArgumentList 'metodo/servitore-gui.py','--porta','8799' ...
# Il comando non e' mai tornato indietro. Il blocco e' rimasto fermo dieci minuti, il
# sorvegliante l'ha interrotto, e il python e' rimasto acceso lo stesso: venti minuti dopo
# teneva ancora la porta, perche' era nato FUORI dall'albero del blocco e l'uccisione
# dell'albero non lo raggiungeva.
#
# Non e' distrazione di quell'agente: e' una trappola che scatta sempre. Chi accende un
# programma che non finisce ha due modi di sbagliare, e sono tutti e due invisibili:
#   1. lo lascia attaccato alla propria uscita — chi lo ha lanciato aspetta la fine di
#      qualcosa che per definizione non finisce;
#   2. lo stacca cosi' bene da metterlo fuori dall'albero — e allora sopravvive al blocco,
#      tiene la porta occupata e fa fallire il blocco dopo, che non capisce perche'.
#
# Qui si fanno tutte e due le cose giuste insieme: l'uscita va in un file (non resta
# attaccata), il processo resta figlio (quindi l'albero lo comprende), e SI SPEGNE SEMPRE —
# anche se la prova fallisce, anche se questo script viene interrotto.
#
# Cosa restituisce: l'esito del comando di prova. Se il servitore non si accende entro il
# tempo, esce 1 e stampa le ultime righe del suo registro: e' li' che c'e' il motivo.

set -uo pipefail

if [[ $# -lt 5 ]]; then
    cat >&2 <<'USO'
Uso: con-servitore.sh <porta> <secondi> -- <comando che accende...> -- <comando di prova...>
  <porta>   la porta su cui il servitore si mette in ascolto (si aspetta che risponda li')
  <secondi> quanto si aspetta al massimo che si accenda
USO
    exit 2
fi

PORTA="$1"; ATTESA="$2"; shift 2
[[ "$1" == "--" ]] || { echo "manca il '--' prima del comando che accende" >&2; exit 2; }
shift

AVVIO=(); while [[ $# -gt 0 && "$1" != "--" ]]; do AVVIO+=("$1"); shift; done
[[ $# -gt 0 ]] || { echo "manca il '--' prima del comando di prova" >&2; exit 2; }
shift
PROVA=("$@")
[[ ${#AVVIO[@]} -gt 0 && ${#PROVA[@]} -gt 0 ]] || { echo "comando che accende o comando di prova vuoto" >&2; exit 2; }

REGISTRO="$(mktemp -t servitore-XXXXXX.log)"
PID=""

# Lo spegnimento vive in un trap: cosi' vale su TUTTE le uscite — prova andata bene, prova
# fallita, servitore che non parte, e anche interruzione dall'esterno. E' l'unico modo di
# garantire che non resti niente acceso: un "kill" scritto in fondo allo script non viene
# eseguito proprio nei casi in cui servirebbe di piu'.
spegni() {
    local codice=$?
    if [[ -n "$PID" ]] && kill -0 "$PID" 2>/dev/null; then
        kill "$PID" 2>/dev/null || true
        # Mezzo secondo per chiudere con garbo, poi si insiste. Senza il secondo colpo un
        # servitore che ignora il primo segnale resterebbe acceso, cioe' il difetto di prima.
        for _ in 1 2 3 4 5 6; do kill -0 "$PID" 2>/dev/null || break; sleep 0.5; done
        kill -9 "$PID" 2>/dev/null || true
    fi
    rm -f "$REGISTRO"
    exit $codice
}
trap spegni EXIT INT TERM

# L'uscita va nel registro e l'ingresso viene chiuso: cosi' chi lancia non resta appeso ad
# aspettare che il servitore chiuda i suoi canali. Il processo resta comunque FIGLIO di
# questa shell, quindi chi uccide l'albero lo prende.
"${AVVIO[@]}" > "$REGISTRO" 2>&1 < /dev/null &
PID=$!

# Si aspetta che la porta risponda davvero, non che siano passati N secondi: un'attesa a
# tempo fisso o e' troppo corta (prova rossa su un servitore sano) o troppo lunga (secondi
# regalati a ogni blocco).
acceso=1
fine=$(( SECONDS + ATTESA ))
while (( SECONDS < fine )); do
    if ! kill -0 "$PID" 2>/dev/null; then
        echo "Il servitore e' morto durante l'accensione. Ultime righe del suo registro:" >&2
        tail -20 "$REGISTRO" >&2
        exit 1
    fi
    # Si prova a bussare. Con python, perche' c'e' ovunque nel Metodo: curl e nc no.
    if python -c "
import socket, sys
s = socket.socket(); s.settimeout(1)
sys.exit(0 if s.connect_ex(('127.0.0.1', $PORTA)) == 0 else 1)
" 2>/dev/null; then acceso=0; break; fi
    sleep 0.5
done

if [[ "$acceso" -ne 0 ]]; then
    echo "Il servitore non risponde sulla porta $PORTA dopo $ATTESA secondi. Ultime righe del suo registro:" >&2
    tail -20 "$REGISTRO" >&2
    exit 1
fi

"${PROVA[@]}"
