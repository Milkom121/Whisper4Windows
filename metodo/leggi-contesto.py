#!/usr/bin/env python
"""Quanta memoria di lavoro ha occupato una sessione.

A che serve. Il runner, finito un blocco, deve decidere se il blocco dopo puo' andare nella
STESSA sessione — risparmiando le ~30.000 unita' di preambolo che ogni sessione nuova ripaga
da zero — oppure se conviene ricominciare pulito. La decisione si prende su un numero solo:
quanta parte della finestra e' occupata adesso.

Attenzione a non confondere due cose diverse:
  - i TOKEN CONSUMATI da una sessione: crescono a ogni scambio, e dopo un blocco lungo sono
    molti piu' della finestra (ogni scambio ripaga il contesto di prima). Li legge
    leggi-conto.py, e servono per il costo.
  - la MEMORIA OCCUPATA in questo momento: e' l'ingresso dell'ULTIMA richiesta, e non puo'
    superare la finestra. E' questa che dice se c'e' ancora spazio, ed e' questa che si legge
    qui.

Dove si legge: nel diario di sessione che Claude Code tiene per conto suo
(~/.claude/projects/<progetto>/<sessione>.jsonl). Si prende l'ultimo scambio che riporta un
consumo e si sommano i suoi token in ingresso.

    python leggi-contesto.py <id-sessione> [finestra]

Stampa "occupato|finestra|percentuale". Se non riesce a leggere niente, non stampa nulla:
chi chiama deve trattare il silenzio come "non lo so", e nel dubbio ricominciare pulito.
"""

import io
import json
import os
import sys

FINESTRA_DEFAULT = 200000


def trova_diario(sessione):
    """Cerca <sessione>.jsonl fra i diari di Claude Code. Si cerca per nome invece di
    ricostruire il percorso dal nome del progetto: la regola con cui quel nome viene
    trasformato in cartella non e' nostra e potrebbe cambiare."""
    radice = os.path.join(os.path.expanduser("~"), ".claude", "projects")
    atteso = "%s.jsonl" % sessione
    if not os.path.isdir(radice):
        return None
    for cartella, _sotto, file in os.walk(radice):
        if atteso in file:
            return os.path.join(cartella, atteso)
    return None


def occupato(percorso):
    """I token in ingresso dell'ultimo scambio: e' la memoria occupata adesso."""
    ultimo = 0
    try:
        with io.open(percorso, encoding="utf-8", errors="replace") as f:
            for riga in f:
                try:
                    d = json.loads(riga)
                except Exception:
                    continue
                u = (d.get("message") or {}).get("usage")
                if not isinstance(u, dict):
                    continue
                somma = 0
                for c in ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens"):
                    somma += int(u.get(c) or 0)
                if somma:
                    ultimo = somma
    except Exception:
        return 0
    return ultimo


def main():
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        return
    sessione = sys.argv[1].strip()
    try:
        finestra = int(sys.argv[2]) if len(sys.argv) > 2 and sys.argv[2].strip() else FINESTRA_DEFAULT
    except ValueError:
        finestra = FINESTRA_DEFAULT
    if finestra <= 0:
        finestra = FINESTRA_DEFAULT

    diario = trova_diario(sessione)
    if not diario:
        return
    quanto = occupato(diario)
    if quanto <= 0:
        return
    # Se l'occupato supera la finestra dichiarata, la dichiarazione e' sbagliata (di solito un
    # modello con finestra piu' grande). Meglio adattarsi che dare una percentuale assurda.
    if quanto > finestra:
        finestra = 1000000 if quanto <= 1000000 else quanto
    print("%d|%d|%d" % (quanto, finestra, round(quanto * 100.0 / finestra)))


if __name__ == "__main__":
    main()
