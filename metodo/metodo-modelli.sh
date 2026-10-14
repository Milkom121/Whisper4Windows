#!/usr/bin/env bash
# Quali modelli si possono davvero usare con OpenCode, su QUESTA macchina.
#
# "opencode models" elenca tutto il catalogo, comprese centinaia di modelli di fornitori
# per cui non c'e' nessuna chiave: sceglierne uno significa lanciare una corsa che muore al
# primo blocco. Qui si tengono SOLO i modelli dei fornitori per cui OpenCode ha una
# credenziale registrata — quelli e nient'altro.
#
# Nemmeno i modelli "opencode/..." fanno eccezione, anche se il catalogo li segna come
# gratuiti: senza un accesso registrato (`opencode providers login`) non partono, e un
# modello che sembra disponibile ma non lo e' e' peggio di un modello che non compare.
# Il giorno in cui quell'accesso viene fatto, il fornitore compare fra le credenziali e i
# suoi modelli si presentano da soli: qui non c'e' niente da aggiornare a mano.
#
# Due modi di chiamarlo, perche' i modelli utilizzabili sono decine e un elenco unico non si
# legge:
#   metodo-modelli.sh fornitori          -> "numero|fornitore (quanti modelli)"
#   metodo-modelli.sh modelli <fornitore> -> "numero|modello" di quel fornitore soltanto
# Senza argomenti si comporta come "modelli" senza filtro (elenco intero).
#
# Le credenziali non si leggono e non si stampano mai: dal file di autenticazione si prendono
# soltanto i NOMI dei fornitori.
#
# Se OpenCode non e' installato, o l'elenco non arriva, esce senza stampare niente: chi
# chiama deve permettere di scrivere il nome del modello a mano.

set -uo pipefail

AUTH="${OPENCODE_AUTH:-$HOME/.local/share/opencode/auth.json}"
[[ -f "$AUTH" ]] || AUTH="${XDG_DATA_HOME:-$HOME/.local/share}/opencode/auth.json"

command -v opencode >/dev/null 2>&1 || { echo "OpenCode non e' installato su questa macchina." >&2; exit 1; }

# I fornitori per cui c'e' una credenziale. Solo le chiavi del file, mai i valori.
fornitori=""
if [[ -f "$AUTH" ]] && command -v python >/dev/null 2>&1; then
    fornitori="$(python -c "
import json,io,sys
try:
    d=json.load(io.open(sys.argv[1],encoding='utf-8'))
    print(' '.join(sorted(k for k in d if isinstance(k,str))))
except Exception:
    pass
" "$AUTH" 2>/dev/null)"
fi

catalogo="$(timeout 60 opencode models 2>/dev/null)" || catalogo=""
[[ -n "$catalogo" ]] || { echo "Non sono riuscito a farmi dare l'elenco dei modelli da OpenCode." >&2; exit 1; }

modo="${1:-modelli}"; filtro="${2:-}"
utilizzabili=""
while IFS= read -r riga; do
    riga="${riga%%[[:space:]]}"
    [[ -n "$riga" ]] || continue
    fornitore="${riga%%/*}"
    [[ "$fornitore" != "$riga" ]] || continue          # righe senza "/" non sono modelli
    tenere="no"
    for f in $fornitori; do [[ "$fornitore" == "$f" ]] && tenere="si"; done
    [[ "$tenere" == "si" ]] || continue
    utilizzabili+="$riga"$'\n'
done <<< "$catalogo"

[[ -n "$utilizzabili" ]] || { echo "Nessun modello utilizzabile: in OpenCode non risulta nessuna chiave registrata (opencode providers)." >&2; exit 1; }

n=0
if [[ "$modo" == "fornitori" ]]; then
    while IFS= read -r f; do
        [[ -n "$f" ]] || continue
        quanti="$(grep -c "^${f}/" <<< "$utilizzabili" || true)"
        n=$((n+1))
        echo "${n}|${f}|${quanti} modelli, con la tua chiave"
    done <<< "$(cut -d/ -f1 <<< "$utilizzabili" | sort -u)"
else
    while IFS= read -r m; do
        [[ -n "$m" ]] || continue
        [[ -z "$filtro" || "${m%%/*}" == "$filtro" ]] || continue
        n=$((n+1)); echo "${n}|${m}"
    done <<< "$utilizzabili"
fi
[[ "$n" -gt 0 ]] || exit 1
exit 0
