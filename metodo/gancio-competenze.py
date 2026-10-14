#!/usr/bin/env python
"""Il gancio delle competenze: ricorda la procedura giusta nel momento in cui serve.

Il problema che risolve. Il Metodo scrive in otto posti diversi che davanti a un lavoro di
interfaccia si deve aprire la competenza del seeding visivo, e che l'esperienza utente va
progettata PRIMA di costruire le schermate. Sono otto promemoria, e un promemoria funziona
quasi sempre: "quasi" e' la parola che costa le giornate. Per giunta tre di quegli otto
arrivano a fine blocco, quando l'interfaccia e' gia' scritta male.

Questo gancio non e' un promemoria: e' un'interruzione. Scatta nell'istante in cui l'agente
sta per creare o modificare un file di interfaccia — quando ha gia' la mano sul file — e gli
mette davanti la competenza giusta.

REGOLA DI PROGETTO: non blocca mai. Usa additionalContext, che infila il richiamo nel
contesto dell'agente lasciandolo proseguire. Un gancio che blocca la scrittura dei file di
interfaccia sarebbe un ottimo modo per rompere una corsa notturna.

Parla UNA VOLTA SOLA per sessione e per argomento: ripetersi a ogni file sarebbe rumore che
si paga in token e che si smette di leggere.

Si aggancia da metodo/impostazioni-runner.json (corse del runner) e dal .claude/settings.json
del progetto (sessioni con Villa davanti — dove il problema si e' visto la prima volta).
"""

import json
import os
import re
import sys
import tempfile

# Cosa conta come interfaccia. Lista chiusa: davanti a un file che non riconosce, tace.
WEB = re.compile(r"\.(tsx|jsx|vue|svelte|css|scss|sass|less|html)$", re.I)
MOBILE = re.compile(r"\.dart$", re.I)
# Un .dart puo' essere logica pura: il richiamo parte solo se il file sta dove stanno le
# schermate, o se si chiama come una schermata.
MOBILE_UI = re.compile(r"(screen|page|widget|view|component|ui)", re.I)

MAPPA_ESPERIENZA = os.path.join("docs", "fondamenta", "mappa-esperienza.md")


def gia_detto(session_id, argomento):
    """Vero se in questa sessione il richiamo e' gia' partito. Il segno sta in un file
    temporaneo: se sparisce, al massimo il richiamo torna una volta."""
    if not session_id:
        return False
    segno = os.path.join(tempfile.gettempdir(), "metodo-gancio-%s-%s" % (argomento, re.sub(r"\W", "", session_id)[:40]))
    if os.path.exists(segno):
        return True
    try:
        with open(segno, "w") as f:
            f.write("detto")
    except Exception:
        return False
    return False


def richiamo_seeding(dove):
    competenza = "seeding-visivo-web" if dove == "web" else "seeding-visivo-mobile"
    return (
        "REGOLA DEL METODO (cap. 11quater) — stai toccando l'interfaccia. Prima di scrivere "
        "codice di interfaccia apri e segui `.claude/skills/%s/SKILL.md`: non e' un "
        "suggerimento, e' la procedura. In concreto: token del tema e mai colori o misure "
        "grezzi, dark mode sempre, guardrail verdi prima di chiudere il blocco. Se la palette "
        "non e' ancora stata co-progettata con Villa, applica il preset DEFAULT neutro e non "
        "inventare colori da solo." % competenza
    )


def richiamo_esperienza():
    return (
        "REGOLA DEL METODO (cap. 11ter) — stai costruendo schermate, ma in questo progetto "
        "manca `%s`: l'esperienza non e' stata progettata. Il Metodo chiede di decidere PRIMA "
        "quali schermate servono, come si collegano, cosa contengono e in quali stati possono "
        "trovarsi: senza, nascono frontend belli ma scollegati. Apri "
        "`.claude/skills/progettazione-ux/SKILL.md`. Se questo blocco e' solo una modifica "
        "puntuale a una schermata che gia' esiste, prosegui; se stai creando schermate nuove, "
        "la mappa va fatta prima — e se non puoi farla ora, dillo nell'handoff." % MAPPA_ESPERIENZA
    )


def main():
    try:
        d = json.loads(sys.stdin.read())
    except Exception:
        return
    if d.get("tool_name") not in ("Write", "Edit", "NotebookEdit"):
        return
    percorso = (d.get("tool_input") or {}).get("file_path") or ""
    if not isinstance(percorso, str) or not percorso:
        return

    if WEB.search(percorso):
        dove = "web"
    elif MOBILE.search(percorso) and MOBILE_UI.search(percorso):
        dove = "mobile"
    else:
        return

    sid = d.get("session_id") or ""
    pezzi = []
    if not gia_detto(sid, dove):
        pezzi.append(richiamo_seeding(dove))
    # La mappa dell'esperienza si cerca dalla cartella di lavoro dichiarata dal gancio.
    cwd = d.get("cwd") or os.getcwd()
    if not os.path.exists(os.path.join(cwd, MAPPA_ESPERIENZA)) and not gia_detto(sid, "esperienza"):
        pezzi.append(richiamo_esperienza())
    if not pezzi:
        return

    print(json.dumps({
        "hookSpecificOutput": {
            "hookEventName": "PreToolUse",
            "additionalContext": "\n\n".join(pezzi),
        }
    }))


if __name__ == "__main__":
    main()
