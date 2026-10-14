# 25 — I ganci: quando un promemoria non basta

> Motori: `metodo/gancio-competenze.py` e `metodo/filtro-test.py`, agganciati da
> `metodo/impostazioni-runner.json` (corse del runner) e dal `.claude/settings.json` del
> progetto (sessioni con Villa davanti). Prove: `tests/test_gancio_competenze.sh`,
> `tests/test_filtro_test.sh`.

## La lezione che li ha fatti nascere

Villa, provando il Metodo sul campo (2026-08-12): *«il sistema non mi proponeva le skill
giuste al momento giusto — quella della UX, quella del frontend. Gliel'ho dovuta dire io.»*

Andando a guardare: la regola c'era. Era scritta in **otto posti** — quattro volte nel file
operativo, due nel messaggio del runner, due nella chiusura di blocco. E non e' bastato.

Il motivo non e' che il modello disubbidisce. E' che **un promemoria in mezzo ad altri
duecento non ha piu' peso di quei duecento**, e che tre di quegli otto arrivavano a fine
blocco — quando l'interfaccia era gia' scritta male e la domanda utile non era piu' «hai
usato la competenza?» ma «quanto costa rifarla?».

**La regola generale, che vale anche fuori da qui**: una regola importante si tiene in piedi
con un **innesco osservabile**, non con un'esortazione. Se l'innesco e' «l'agente si ricorda
di una riga del manuale», funzionera' quasi sempre — e *quasi* e' la parola che costa le
giornate. Se l'innesco e' un fatto — un file di interfaccia che nasce, un comando di test che
parte — funziona tutte le volte.

## I due ganci che ci sono

| Gancio | Innesco | Cosa fa |
|---|---|---|
| **Competenze** | l'agente sta per scrivere o modificare un file di interfaccia (`.tsx`, `.jsx`, `.vue`, `.css`, `.dart` di schermata…) | gli mette davanti la competenza di seeding visivo giusta (web o mobile); e se manca `docs/fondamenta/mappa-esperienza.md`, gli ricorda che l'esperienza va progettata **prima** di costruire le schermate |
| **Filtro dei test** | parte un comando di test riconosciuto | fa arrivare all'agente le righe che falliscono e il riepilogo, e mette il resto in un file (cap. 23) |

## Le due regole che li rendono innocui

1. **Non bloccano mai.** Il gancio delle competenze usa `additionalContext`: infila il
   richiamo nel contesto e lascia proseguire. Un gancio che blocca la scrittura dei file di
   interfaccia sarebbe un ottimo modo per fermare una corsa notturna.
2. **Parlano una volta sola per sessione e per argomento.** Ripetersi a ogni file sarebbe
   rumore che si paga in token e che si smette di leggere — cioe' il problema di partenza,
   di nuovo.

E, come tutti i pezzi del Metodo: davanti a un caso che non riconoscono, **tacciono**. La
lista dei file di interfaccia e' chiusa; quella dei lanciatori di test pure.

## Cosa NON risolvono

**La progettazione dell'esperienza non ha un innesco vero.** Il gancio se ne accorge solo
quando qualcuno sta gia' scrivendo una schermata — cioe' tardi, anche se non tardissimo.
L'unico posto dove la mappa dell'esperienza puo' comparire **al momento giusto** e' la
roadmap: dev'essere un blocco 🤝 in testa alla fase di frontend, messo li' da chi pianifica
(cap. 11ter e cap. 14). Se in roadmap non c'e', nessun gancio potra' inventarlo.

## Dove si agganciano

- **Corse del runner**: automatico, via `metodo/impostazioni-runner.json` (il runner lo passa
  a Claude Code con `--settings`, che aggiunge senza toccare le impostazioni del progetto).
- **Sessioni con Villa davanti**: serve la voce nel `.claude/settings.json` del progetto —
  ed e' li' che il problema si e' visto la prima volta. Il Metodo la porta nel proprio
  `settings.json`; nei progetti va aggiunta una volta:

```json
{
  "hooks": {
    "PreToolUse": [
      { "matcher": "Write|Edit|NotebookEdit",
        "hooks": [ { "type": "command",
                     "command": "python \"$CLAUDE_PROJECT_DIR/metodo/gancio-competenze.py\"" } ] }
    ]
  }
}
```

Nei monorepo `$CLAUDE_PROJECT_DIR` e' il modulo: se il Metodo sta solo in radice il gancio
non scatta, e tutto funziona come prima — nessun danno, nessun aiuto.
