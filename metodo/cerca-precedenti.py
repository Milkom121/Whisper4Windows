#!/usr/bin/env python
"""Cerca nell'indirizzario dei precedenti: «questa cosa l'abbiamo gia' risolta da qualche parte?»

Il problema che risolve. Un agente che lavora dentro un progetto vede quel progetto e basta.
Che in un altro repository ci sia gia' un sistema di notifiche con scalata, o un registro
immodificabile gia' scritto e testato, non puo' saperlo: non gli manca l'intelligenza per
capirlo, gli manca l'indirizzo. E aprire venti progetti per scoprirlo costa piu' che
riscrivere il pezzo.

Cosa NON fa. Non descrive il codice e non lo copia. L'indirizzario tiene solo cio' che
leggendo il codice non si puo' deduRre: che la cosa esiste, dove sta, se e' prendibile,
com'e' andata sul campo. Il resto l'agente lo scopre andando a guardare — ed e' anche
l'unico modo di non leggere informazioni vecchie.

DUE MODI D'USO
  1. riga di comando:  python metodo/cerca-precedenti.py "notifiche push escalation"
     stampa le voci che combaciano. Lo usa il runner all'apertura del blocco.
  2. gancio:           riceve il JSON di PreToolUse su standard input
     scatta quando l'agente crea un file nuovo il cui nome somiglia a un precedente noto.
     Non blocca mai, parla una volta sola per argomento (stessa regola del cap. 25).

Le schede vivono in .claude/precedenti/*.md. Formato di una riga: vedi il README di quella
cartella. Se la cartella non c'e', questo strumento tace: nessun danno, nessun aiuto.
"""

import json
import os
import re
import sys
import tempfile

CARTELLA = os.path.join(".claude", "precedenti")
# Sotto le 4 lettere sono quasi tutte parole di servizio: cercarle produce solo falsi positivi.
LUNGHEZZA_MINIMA = 4
MAX_VOCI = 5


def _schede(radice):
    """I file delle schede, in ordine stabile. Il README non e' una scheda."""
    cartella = os.path.join(radice, CARTELLA)
    if not os.path.isdir(cartella):
        return []
    return [os.path.join(cartella, n) for n in sorted(os.listdir(cartella))
            if n.endswith(".md") and n.upper() != "README.MD"]


def _righe(percorso):
    """Le voci di una scheda: righe di tabella a 5 colonne, saltata l'intestazione.

    Ritorna dizionari {id, cosa, parole, dove, esito, progetto}."""
    voci = []
    progetto = os.path.splitext(os.path.basename(percorso))[0]
    try:
        with open(percorso, encoding="utf-8") as f:
            testo = f.read()
    except Exception:
        return voci
    for riga in testo.splitlines():
        riga = riga.strip()
        if not riga.startswith("|") or not riga.endswith("|"):
            continue
        celle = [c.strip() for c in riga.strip("|").split("|")]
        if len(celle) != 5:
            continue
        # Intestazione e riga di separazione della tabella markdown.
        if set(celle[0]) <= set("-: ") or celle[0].lower() in ("#", "id"):
            continue
        voci.append({
            "id": celle[0], "cosa": celle[1], "parole": celle[2],
            "dove": celle[3], "esito": celle[4], "progetto": progetto,
        })
    return voci


def cerca(domanda, radice="."):
    """Le voci che combaciano con la domanda, dalla piu' pertinente. Nessun match -> lista vuota."""
    termini = {p for p in re.findall(r"\w+", domanda.lower()) if len(p) >= LUNGHEZZA_MINIMA}
    if not termini:
        return []
    trovate = []
    for scheda in _schede(radice):
        for voce in _righe(scheda):
            testo = ("%s %s" % (voce["cosa"], voce["parole"])).lower()
            punteggio = sum(1 for t in termini if t in testo)
            if punteggio:
                trovate.append((punteggio, voce))
    trovate.sort(key=lambda x: -x[0])
    return [v for _, v in trovate[:MAX_VOCI]]


def formatta(voci):
    """Il messaggio per l'agente. Dice dove guardare, non cosa fare: la scelta resta sua."""
    # Solo ASCII: questo testo finisce anche su console Windows in codepage 1252.
    righe = ["PRECEDENTI - cose gia' risolte altrove che somigliano a quello che stai per fare.",
             "Vai a guardarle PRIMA di scrivere: se sono buone si copiano, se non lo sono almeno",
             "sai come e' andata. La scheda dice solo dove: il codice vero e' la fonte.",
             ""]
    for v in voci:
        riga = "  - [%s/%s] %s  ->  %s" % (v["progetto"], v["id"], v["cosa"], v["dove"])
        if v["esito"] and v["esito"] not in ("?", "-", ""):
            riga += "  (sul campo: %s)" % v["esito"]
        righe.append(riga)
    return "\n".join(righe)


def _gia_detto(session_id, chiave):
    """Stessa regola del gancio delle competenze: una volta sola per sessione e argomento."""
    if not session_id:
        return False
    segno = os.path.join(tempfile.gettempdir(),
                         "metodo-precedenti-%s-%s" % (chiave, re.sub(r"\W", "", session_id)[:40]))
    if os.path.exists(segno):
        return True
    try:
        with open(segno, "w") as f:
            f.write("detto")
    except Exception:
        return False
    return False


def _modo_gancio():
    try:
        d = json.loads(sys.stdin.read())
    except Exception:
        return
    if d.get("tool_name") != "Write":
        return
    percorso = (d.get("tool_input") or {}).get("file_path") or ""
    if not isinstance(percorso, str) or not percorso:
        return
    # Un file di documentazione non e' una funzionalita' che si costruisce: se parlasse anche
    # li', il gancio scatterebbe mentre si scrivono le schede stesse. Visto sul campo il
    # 2026-08-14, scrivendo l'indirizzario: il richiamo e' arrivato su una scheda.
    if percorso.lower().endswith((".md", ".txt", ".rst")) or re.search(r"[\\/]\.claude[\\/]", percorso):
        return
    radice = d.get("cwd") or os.getcwd()
    # Il nome del file e la cartella che lo contiene: e' li' che si legge l'intenzione
    # ("auth.ts", "notifications/", "audit-log.py").
    nome = re.sub(r"[-_/\\.]", " ", os.path.join(os.path.basename(os.path.dirname(percorso)),
                                                 os.path.basename(percorso)))
    voci = cerca(nome, radice)
    if not voci:
        return
    if _gia_detto(d.get("session_id") or "", voci[0]["id"]):
        return
    print(json.dumps({"hookSpecificOutput": {
        "hookEventName": "PreToolUse",
        "additionalContext": formatta(voci),
    }}))


def main():
    if len(sys.argv) > 1:
        voci = cerca(" ".join(sys.argv[1:]), os.environ.get("METODO_RADICE", "."))
        if voci:
            print(formatta(voci))
        return
    _modo_gancio()


if __name__ == "__main__":
    main()
