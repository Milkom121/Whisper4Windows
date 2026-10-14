#!/usr/bin/env python
"""Legge il conto di un blocco dall'uscita dell'agente.

Claude Code, lanciato con --output-format json, non restituisce solo la risposta: restituisce
anche quanto ha consumato (token in ingresso, in uscita e di cache), quanto sarebbe costato a
listino, e quale modello ha davvero lavorato. OpenCode, lanciato con --format json, dice le
stesse cose in un'altra forma: una riga per evento, e il conto negli eventi di fine passo.
Questo script conosce tutt'e due le forme e separa le due cose:

    python leggi-conto.py numeri [modello] < uscita -> "token|costo|modello"  (niente, se non si legge)
    python leggi-conto.py testo            < uscita -> la risposta dell'agente (niente, se non si legge)
    python leggi-conto.py sessione         < uscita -> l'id della sessione, per riprenderla

Il runner usa i numeri per il contatore e il testo per il registro, cosi' chi apre il
registro ritrova quello che ci trovava prima che il contatore esistesse.

Il modello si passa come secondo argomento perche' OpenCode, nei suoi eventi, non lo dice:
lo sa solo chi lo ha lanciato. Claude Code invece lo dice, e in quel caso l'argomento si
ignora — cosi' si vede il modello che ha DAVVERO lavorato, non quello chiesto.

Regola: davanti a un'uscita che non si capisce (un altro agente, una sessione uccisa a meta',
un errore) NON si inventa niente. Si stampa il vuoto e il runner ripiega su cio' che c'era.
"""

import json
import os
import sys

# Il listino di OpenCode, dal suo stesso archivio: prezzi in dollari per milione di token.
# I prezzi NON si scrivono qui dentro: invecchierebbero in silenzio, e nessun test se ne
# accorgerebbe. La variabile d'ambiente serve alle prove, che devono girare anche su un
# computer dove OpenCode non e' installato.
LISTINO_OPENCODE = os.environ.get("METODO_LISTINO_OPENCODE") or os.path.expanduser(
    "~/.cache/opencode/models.json")


def leggi():
    """Torna ("claude", oggetto) o ("opencode", [eventi]); (None, None) se non si capisce.

    Claude Code restituisce UN oggetto con dentro tutto. OpenCode restituisce un evento per
    riga: il conto sta negli eventi di fine passo, e i passi sono tanti quanti i giri di
    attrezzi che ha fatto — quindi vanno sommati, non presi l'ultimo.
    """
    grezzo = sys.stdin.read()
    # Prima si cercano gli eventi, non l'oggetto solo: un blocco andato liscio in un colpo
    # lascia UNA riga sola, che come oggetto si leggerebbe benissimo — e verrebbe scambiata
    # per un'uscita di Claude Code senza conto, cioe' per niente. Il segno che distingue e' la
    # "part": gli eventi ce l'hanno tutti, l'uscita di Claude Code non ce l'ha mai.
    eventi = []
    for riga in grezzo.splitlines():
        riga = riga.strip()
        if not riga.startswith("{"):
            continue
        try:
            e = json.loads(riga)
        except Exception:
            continue          # una riga rotta non butta via le altre
        if isinstance(e, dict) and isinstance(e.get("part"), dict):
            eventi.append(e)
    if eventi:
        return "opencode", eventi
    try:
        d = json.loads(grezzo)
        if isinstance(d, dict):
            return "claude", d
    except Exception:
        pass
    return None, None


def parti(eventi, tipo):
    """Le parti degli eventi di un certo tipo, in ordine."""
    for e in eventi:
        if e.get("type") == tipo:
            yield e["part"]


def token_totali(u):
    """Tutto cio' che e' passato dal modello: ingresso, cache (scritta e riletta), uscita.

    Si sommano anche i token di cache perche' sono consumo reale — sono scontati, non
    gratuiti — e nel runner sono la voce piu' grossa di tutte.
    """
    if not isinstance(u, dict):
        return 0
    campi = ("input_tokens", "cache_creation_input_tokens", "cache_read_input_tokens", "output_tokens")
    return sum(int(u.get(c) or 0) for c in campi)


def token_del_passo(t):
    """I token di un passo di OpenCode, divisi per voce (servono anche al calcolo del costo).

    Il conto lo rifacciamo dalle voci invece di prendere il campo "total": e' la stessa somma
    che si fa per Claude Code — cache compresa — quindi i due motori restano confrontabili,
    che e' l'unica ragione per cui il contatore esiste.
    """
    voci = {"input": 0, "output": 0, "reasoning": 0, "cache_read": 0, "cache_write": 0}
    if not isinstance(t, dict):
        return voci
    for v in ("input", "output", "reasoning"):
        voci[v] = int(t.get(v) or 0)
    cache = t.get("cache")
    if isinstance(cache, dict):
        voci["cache_read"] = int(cache.get("read") or 0)
        voci["cache_write"] = int(cache.get("write") or 0)
    return voci


def prezzi_del_modello(modello):
    """Il listino di quel modello, in dollari per milione di token. None se non si sa.

    Il modello arriva nella forma che vuole OpenCode, "fornitore/modello". Se l'archivio non
    c'e' o il modello non c'e' dentro, si torna None: meglio nessun costo che uno inventato.
    """
    if "/" not in (modello or ""):
        return None
    fornitore, nome = modello.split("/", 1)
    try:
        with open(LISTINO_OPENCODE, encoding="utf-8") as f:
            archivio = json.load(f)
    except Exception:
        return None
    if not isinstance(archivio, dict):
        return None
    costo = archivio.get(fornitore, {}).get("models", {}).get(nome, {}).get("cost")
    return costo if isinstance(costo, dict) else None


def costo_da_listino(voci, modello):
    """Quanto varrebbe a listino quello che si e' consumato. Zero se il listino non si sa.

    Serve quando OpenCode non mette il costo negli eventi. Con un abbonamento a quota fissa
    il listino e' zero davvero — non e' un buco: non c'e' nessun addebito per blocco.
    """
    prezzi = prezzi_del_modello(modello)
    if not prezzi:
        return 0.0
    # Il ragionamento si paga come l'uscita: e' uscita che non si vede.
    quantita = {
        "input": voci["input"],
        "output": voci["output"] + voci["reasoning"],
        "cache_read": voci["cache_read"],
        "cache_write": voci["cache_write"],
    }
    return sum(float(prezzi.get(v) or 0) * q / 1_000_000 for v, q in quantita.items())


def conto_claude(d):
    token = token_totali(d.get("usage"))
    costo = d.get("total_cost_usd")
    costo = float(costo) if isinstance(costo, (int, float)) else 0.0
    # Il modello che ha DAVVERO lavorato, non quello chiesto: se c'e' stato un ripiego
    # automatico su un altro modello, e' qui che si vede.
    uso = d.get("modelUsage")
    modello = next(iter(uso), "") if isinstance(uso, dict) and uso else (d.get("model") or "")
    return token, costo, modello


def conto_opencode(eventi, modello):
    totali = {"input": 0, "output": 0, "reasoning": 0, "cache_read": 0, "cache_write": 0}
    costo = 0.0
    for p in parti(eventi, "step_finish"):
        for voce, quanti in token_del_passo(p.get("tokens")).items():
            totali[voce] += quanti
        c = p.get("cost")
        if isinstance(c, (int, float)):
            costo += float(c)
    token = sum(totali.values())
    if not costo:
        costo = costo_da_listino(totali, modello)
    return token, costo, modello


def main():
    modo = sys.argv[1] if len(sys.argv) > 1 else "numeri"
    modello_chiesto = sys.argv[2] if len(sys.argv) > 2 else ""
    forma, d = leggi()
    if forma is None:
        return

    if modo == "sessione":
        # L'id serve al runner per RIPRENDERE questa sessione col blocco dopo, invece di
        # aprirne una nuova e ripagare da zero le ~30.000 unita' di preambolo.
        s = d.get("session_id") if forma == "claude" else None
        if isinstance(s, str) and s:
            print(s)
        return

    if modo == "testo":
        if forma == "claude":
            r = d.get("result")
        else:
            # OpenCode sputa un evento per ogni pezzo di risposta: si rimettono in fila.
            r = "\n".join(p.get("text", "") for p in parti(d, "text") if p.get("text"))
        if isinstance(r, str) and r:
            print(r)
        return

    if forma == "claude":
        token, costo, modello = conto_claude(d)
    else:
        token, costo, modello = conto_opencode(d, modello_chiesto)
    if not token and not costo:
        return
    print("%d|%.6f|%s" % (token, costo, modello))


if __name__ == "__main__":
    main()
