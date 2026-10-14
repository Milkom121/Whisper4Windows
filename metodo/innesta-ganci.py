#!/usr/bin/env python
"""Mette (o rimette) i ganci del Metodo nelle impostazioni del progetto.

Perche' esiste. I ganci del Metodo (cap. 25) vivono in due posti:
  - `metodo/impostazioni-runner.json`, che il runner passa a Claude Code da solo: si
    distribuisce con tutto il resto del Metodo e non chiede niente a nessuno;
  - `.claude/settings.json` del progetto, che serve per le sessioni con Villa davanti —
    ed e' proprio li' che il problema si e' visto la prima volta.

Il secondo file NON si puo' distribuire come gli altri: appartiene al progetto, contiene le
sue impostazioni, e sovrascriverlo vorrebbe dire cancellarle. Quindi non si copia: si
**innesta** la voce che manca, lasciando tutto il resto dov'e'.

Si puo' rilanciare quante volte si vuole: se il gancio c'e' gia', non fa niente e lo dice.

    python innesta-ganci.py <cartella-del-progetto>
"""

import io
import json
import os
import sys

COMANDO = 'python "$CLAUDE_PROJECT_DIR/metodo/gancio-competenze.py"'
MATCHER = "Write|Edit|NotebookEdit"


def carica(percorso):
    if not os.path.exists(percorso):
        return {}
    try:
        with io.open(percorso, encoding="utf-8") as f:
            testo = f.read().strip()
        return json.loads(testo) if testo else {}
    except Exception:
        # Un file che non si legge non si tocca: meglio dire di no che rovinarlo.
        return None


def main():
    if len(sys.argv) < 2:
        print("Uso: innesta-ganci.py <cartella-del-progetto>", file=sys.stderr)
        return 1
    progetto = sys.argv[1]
    percorso = os.path.join(progetto, ".claude", "settings.json")

    dati = carica(percorso)
    if dati is None:
        print("  ganci: %s non e' leggibile, non lo tocco. Aggiungi il gancio a mano (cap. 25)." % percorso)
        return 0
    if not isinstance(dati, dict):
        print("  ganci: %s ha una forma inattesa, non lo tocco." % percorso)
        return 0

    hooks = dati.setdefault("hooks", {})
    if not isinstance(hooks, dict):
        print("  ganci: la sezione hooks di %s ha una forma inattesa, non la tocco." % percorso)
        return 0
    pre = hooks.setdefault("PreToolUse", [])
    if not isinstance(pre, list):
        print("  ganci: la sezione PreToolUse ha una forma inattesa, non la tocco.")
        return 0

    # C'e' gia'? Si guarda il comando, non il matcher: se qualcuno l'ha adattato, e' suo.
    for voce in pre:
        for h in (voce or {}).get("hooks", []) if isinstance(voce, dict) else []:
            if isinstance(h, dict) and "gancio-competenze.py" in str(h.get("command", "")):
                print("  ganci: gia' a posto (il richiamo delle competenze c'era gia').")
                return 0

    pre.append({"matcher": MATCHER, "hooks": [{"type": "command", "command": COMANDO}]})
    try:
        os.makedirs(os.path.dirname(percorso), exist_ok=True)
        with io.open(percorso, "w", encoding="utf-8", newline="\n") as f:
            f.write(json.dumps(dati, indent=2, ensure_ascii=False) + "\n")
    except Exception as e:
        print("  ganci: non sono riuscito a scrivere %s (%s). Aggiungilo a mano (cap. 25)." % (percorso, type(e).__name__))
        return 0
    print("  ganci: aggiunto il richiamo delle competenze in .claude/settings.json (il resto e' rimasto com'era).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
