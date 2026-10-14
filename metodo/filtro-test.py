#!/usr/bin/env python
"""Filtro dell'output dei test — riduce cio' che l'agente si porta in memoria.

Il Metodo fa girare TUTTI i test a ogni blocco (cap. 04). Su un progetto maturo sono
centinaia di righe di "passed" che l'agente si rilegge per intero, a ogni blocco, per
trovarci dentro le tre righe che contano. Siccome il runner riapre l'agente da capo ogni
volta, quelle righe non si pagano una volta: si pagano a ogni blocco della corsa.

Questo filtro si mette davanti al comando (gancio PreToolUse di Claude Code) e lo riscrive
perche' mostri solo cio' che serve: le righe di fallimento e la coda del riepilogo. Il resto
finisce in un file, il cui percorso viene stampato: se all'agente serve, lo apre.

REGOLA DI SICUREZZA, non negoziabile: il filtro puo' solo far vedere MENO output. Non puo'
mai cambiare l'esito di una prova. Percio':
  - il codice di uscita del comando vero viene restituito tale e quale (`exit $ec`);
  - le righe di fallimento passano SEMPRE;
  - davanti a qualunque dubbio (comando non riconosciuto, gia' composto con pipe o &&,
    JSON che non si legge, errore imprevisto) il filtro NON tocca niente.
Il caso peggiore, quindi, e' "nessun risparmio". Mai un verde falso.

Si aggancia da metodo/impostazioni-runner.json, che il runner passa a Claude Code con
--settings: vale nelle corse del runner, non tocca le impostazioni del progetto.
"""

import json
import re
import sys

# Lista CHIUSA di lanciatori di test. Ancorata all'inizio del comando: se non e' uno di
# questi, non si tocca niente. Allargarla e' una decisione, non un dettaglio.
# Il lookahead in coda non e' un vezzo: senza, "pytest-cov --help" e "pytest.sh" passerebbero
# per lanciatori di test, perche' il confine di parola cade anche prima di un trattino.
LANCIATORI = re.compile(
    r"""^\s*(
        (python\s+-m\s+)?pytest | py\.test
      | (npm|pnpm|yarn|bun)\s+(run\s+)?test
      | (npx\s+)?(vitest|jest)
      | go\s+test
      | (flutter|dart)\s+test
      | cargo\s+test
      | dotnet\s+test
      | (mvn|gradle)\s+test
    )(?![-\w.])""",
    re.VERBOSE,
)

# Se il comando fa gia' qualcosa di suo con l'output o incatena piu' comandi, e' meglio
# lasciarlo stare: chi l'ha scritto sapeva cosa voleva, e mettersi in mezzo qui vuol dire
# rompere qualcosa senza accorgersene.
GIA_COMPOSTO = re.compile(r"[|>&;]|\btee\b|\$\(")

# Cosa si mostra sempre. Largo apposta: nel dubbio si fa vedere una riga in piu'.
# Solo caratteri ASCII: il comando riscritto attraversa la console di Windows, che con i
# simboli tipo "✗" si pianta a meta' strada. Le parole bastano.
FALLIMENTI = r"FAIL|FAILED|ERROR|ERRORI|Error:|error\[|assert|Traceback|panic:|ROTTO"

MAX_RIGHE_FALLIMENTO = 60   # quante righe di fallimento passano
MAX_RIGHE_CODA = 25         # quante righe finali (il riepilogo dei lanciatori sta li')


def non_toccare():
    print("{}")
    sys.exit(0)


def main():
    try:
        dati = json.load(sys.stdin)
        comando = dati["tool_input"]["command"]
    except Exception:
        non_toccare()

    if not isinstance(comando, str) or not LANCIATORI.match(comando) or GIA_COMPOSTO.search(comando):
        non_toccare()

    # $$ e' il numero del processo: due corsie che girano in parallelo non si pestano il file.
    nuovo = (
        'f="${TMPDIR:-/tmp}/metodo-output-test-$$.txt"; '
        f'{comando} > "$f" 2>&1; ec=$?; '
        f'grep -nEi "{FALLIMENTI}" "$f" | head -n {MAX_RIGHE_FALLIMENTO}; '
        f'tail -n {MAX_RIGHE_CODA} "$f"; '
        'echo "[output completo dei test: $f]"; '
        "exit $ec"
    )

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "permissionDecision": "allow",
            "updatedInput": {"command": nuovo},
        }
    }))


if __name__ == "__main__":
    main()
