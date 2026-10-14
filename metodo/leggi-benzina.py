#!/usr/bin/env python
"""Quanta benzina resta: quota e saldo dei fornitori per cui c'e' una credenziale.

Il conto di una corsa (leggi-conto.py) dice quanto si e' SPESO; questo strumento dice
quanto RESTA, prima di partire — la differenza fra il contachilometri e la spia della
benzina. Serve alla schermata del runner (fase 5): una corsa notturna fermata per quota
finita e' una notte buttata, e la quota si sa solo chiedendola al fornitore.

    python leggi-benzina.py    -> un oggetto JSON su stdout, sempre

    {"aggiornato_il": "...", "fornitori": [
        {"fornitore": "zai-coding-plan", "stato": "ok", "regime": "abbonamento",
         "finestre": [{"etichetta": "5 ore", "percentuale": 0, "rimasti": 28000,
                       "totali": 28000, "reset_epoch": null}, ...]},
        {"fornitore": "moonshotai", "stato": "ok", "regime": "a consumo",
         "saldo": 68.51, "valuta": "USD"},
        {"fornitore": "anthropic", "stato": "non_disponibile", "motivo": "..."},
        {"fornitore": "...", "stato": "errore", "motivo": "..."}]}

Regole tenute ferme:
- si interrogano SOLO i fornitori con una credenziale registrata (OpenCode auth.json,
  stessa fonte di metodo-modelli.sh; Anthropic si riconosce dalla chiave d'ambiente o
  dalle credenziali di Claude Code). Un fornitore senza chiave non esiste, per la spia.
- Anthropic non espone la quota degli abbonamenti: si dice "non_disponibile", non si
  mostra una barra inventata.
- la chiave NON si stampa mai: esce dal computer solo dentro l'intestazione della
  richiesta. I motivi di errore li costruiamo noi, mai dal corpo della risposta.
- un fornitore che non risponde non diventa uno zero: zero vorrebbe dire "finita",
  e sarebbe un allarme falso. Si dice "errore" e perche'.

Per le prove (e per chi sviluppa senza le chiavi): la variabile d'ambiente
METODO_BENZINA_RISPOSTE indica un file JSON {url: {"status": N, "body": "..."}} e le
risposte vengono da li', senza rete. OPENCODE_AUTH sposta il file delle credenziali.
"""

import json
import os
import sys
import time
import urllib.error
import urllib.request

TIMEOUT_SECONDI = 15

# Gli unici sportelli che conosciamo davvero, verificati dal vivo il 2026-08-15/16.
# Chi non c'e' qui dentro non e' "sbagliato": e' che chiedergli il saldo in un modo
# inventato darebbe un numero inventato, e un numero inventato e' peggio di un silenzio.
SPORTELLI = {
    "zai-coding-plan": {"tipo": "quota", "regime": "abbonamento",
                        "url": "https://api.z.ai/api/monitor/usage/quota/limit"},
    "moonshotai": {"tipo": "saldo", "regime": "a consumo", "valuta": "USD",
                   "url": "https://api.moonshot.ai/v1/users/me/balance"},
    "moonshotai-cn": {"tipo": "saldo", "regime": "a consumo", "valuta": "CNY",
                      "url": "https://api.moonshot.cn/v1/users/me/balance"},
}

# Z.ai risponde con le finestre di quota espresse come (unita', numero): la coppia
# (3, 5) e' la finestra di 5 ore, (6, 1) la settimana — osservato nelle risposte vere.
# Una coppia mai vista resta senza etichetta: meglio una casella senza nome che un nome
# attaccato alla finestra sbagliata.
FINESTRE_NOTE = {(3, 5): "5 ore", (6, 1): "settimana"}


class SportelloChiuso(Exception):
    """Il fornitore non ha risposto come si deve. Il messaggio lo scriviamo noi:
    mai il corpo della risposta, che non si sa cosa contiene."""


def file_credenziali():
    percorso = os.environ.get("OPENCODE_AUTH")
    if percorso:
        return percorso
    return os.path.join(os.environ.get("XDG_DATA_HOME") or
                        os.path.expanduser("~/.local/share"), "opencode", "auth.json")


def credenziali():
    """I nomi dei fornitori con una chiave, e la chiave — che da qui in poi serve solo
    a firmare la richiesta. Non finisce mai nell'uscita."""
    try:
        with open(file_credenziali(), encoding="utf-8") as f:
            d = json.load(f)
    except Exception:
        return {}
    out = {}
    for nome, voce in d.items():
        if isinstance(voce, dict) and isinstance(voce.get("key"), str) and voce["key"]:
            out[nome] = voce["key"]
    return out


def credenziali_claude():
    """Dove Claude Code tiene le sue. La variabile d'ambiente serve alle prove: su
    Windows il ~ non si sposta da fuori, e una prova non deve dipendere da com'e'
    fatto il computer su cui gira."""
    return os.environ.get("METODO_BENZINA_CREDENZIALI_CLAUDE") or \
        os.path.expanduser("~/.claude/.credentials.json")


def anthropic_configurato(chiavi):
    """Anthropic sta fuori da OpenCode (Claude Code ha le sue credenziali), quindi si
    riconosce per conto suo: una voce nell'archivio, la chiave d'ambiente, o il file
    delle credenziali di Claude Code."""
    if "anthropic" in chiavi or os.environ.get("ANTHROPIC_API_KEY"):
        return True
    return os.path.isfile(credenziali_claude())


def scarica(url, chiave):
    """Il corpo della risposta, come testo. Solleva SportelloChiuso altrimenti."""
    finte = os.environ.get("METODO_BENZINA_RISPOSTE")
    if finte:
        try:
            with open(finte, encoding="utf-8") as f:
                tabella = json.load(f)
        except Exception:
            raise SportelloChiuso("il file delle risposte finte non si legge")
        voce = tabella.get(url)
        if voce is None:
            raise SportelloChiuso("il fornitore non e' raggiungibile")
        if int(voce.get("status", 0)) != 200:
            raise SportelloChiuso("il fornitore risponde male (HTTP %d)" % voce["status"])
        return str(voce.get("body", ""))
    richiesta = urllib.request.Request(
        url, headers={"Authorization": "Bearer " + chiave, "Accept": "application/json"})
    try:
        with urllib.request.urlopen(richiesta, timeout=TIMEOUT_SECONDI) as r:
            return r.read().decode("utf-8", "replace")
    except urllib.error.HTTPError as e:
        raise SportelloChiuso("il fornitore risponde male (HTTP %d)" % e.code)
    except Exception:
        raise SportelloChiuso("il fornitore non e' raggiungibile")


def quota_zai(corpo):
    """Le finestre di quota di Z.ai: percentuale usata, crediti rimasti e azzeramento.

    L'azzeramento arriva in millisecondi e manca quando la finestra non e' mai stata
    toccata: None, non una data inventata."""
    try:
        dati = json.loads(corpo)
        limiti = (dati.get("data") or {}).get("limits")
    except Exception:
        raise SportelloChiuso("la risposta non e' come quella conosciuta")
    if not isinstance(limiti, list):
        raise SportelloChiuso("la risposta non e' come quella conosciuta")
    finestre = []
    for voce in limiti:
        if not isinstance(voce, dict):
            continue
        reset = voce.get("nextResetTime")
        finestre.append({
            "etichetta": FINESTRE_NOTE.get((voce.get("unit"), voce.get("number"))),
            "percentuale": voce.get("percentage"),
            "rimasti": voce.get("remaining"),
            "totali": voce.get("usage"),
            "reset_epoch": int(reset / 1000) if isinstance(reset, (int, float)) else None,
        })
    if not finestre:
        raise SportelloChiuso("la risposta non e' come quella conosciuta")
    return finestre


def saldo_moonshot(corpo, valuta):
    """Il saldo disponibile, arrotondato al centesimo: i millesimi in piu' sarebbero
    precisione finta, non informazione."""
    try:
        dati = json.loads(corpo)
        saldo = (dati.get("data") or {}).get("available_balance")
    except Exception:
        raise SportelloChiuso("la risposta non e' come quella conosciuta")
    if not isinstance(saldo, (int, float)):
        raise SportelloChiuso("la risposta non e' come quella conosciuta")
    return round(float(saldo), 2), valuta


def chiedi_al_fornitore(nome, chiave):
    """La voce per un fornitore conosciuto: quota o saldo veri, oppure l'errore."""
    sportello = SPORTELLI[nome]
    try:
        corpo = scarica(sportello["url"], chiave)
        if sportello["tipo"] == "quota":
            risultato = {"finestre": quota_zai(corpo)}
        else:
            saldo, valuta = saldo_moonshot(corpo, sportello["valuta"])
            risultato = {"saldo": saldo, "valuta": valuta}
    except SportelloChiuso as e:
        return {"fornitore": nome, "stato": "errore", "motivo": str(e)}
    voce = {"fornitore": nome, "stato": "ok", "regime": sportello["regime"]}
    voce.update(risultato)
    return voce


def main():
    chiavi = credenziali()
    fornitori = []
    # Prima chi ha uno sportello conosciuto, in ordine fisso; poi Anthropic; poi tutti
    # gli altri in ordine alfabetico. Cosi' l'uscita e' stabile e la pagina non balla.
    for nome in SPORTELLI:
        if nome in chiavi:
            fornitori.append(chiedi_al_fornitore(nome, chiavi[nome]))
    if anthropic_configurato(chiavi):
        fornitori.append({
            "fornitore": "anthropic", "stato": "non_disponibile",
            "motivo": "Anthropic non dice quanta quota resta: il consumo si vede solo a corsa finita."})
    for nome in sorted(chiavi):
        if nome not in SPORTELLI and nome != "anthropic":
            fornitori.append({
                "fornitore": nome, "stato": "non_disponibile",
                "motivo": "per questo fornitore non c'e' un modo conosciuto di chiedere quanto resta."})
    print(json.dumps({
        "aggiornato_il": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "fornitori": fornitori,
    }, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
