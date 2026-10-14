# Automazione del Ciclo e Checkpoint

## Esecuzione automatica dei blocchi

Il workflow a blocchi può essere automatizzato con diversi livelli di sofisticazione:

- **Claude Code `/loop`** — comando nativo per scheduling di task ripetitivi dentro la sessione. Utile per ripetere operazioni all'interno di un singolo blocco, non per orchestrare blocchi in sequenza.
- **Ralph Loop** (plugin Claude Code) — intercetta la fine di una sessione e rilancia automaticamente il blocco successivo, mantenendo contesto e storia git. È il livello di automazione più naturale per il Metodo Villa.
- **Continuous Claude v3** — sistema più avanzato con gestione stato persistente tramite "ledger" e orchestrazione multi-agente. Adatto a progetti grandi con blocchi interdipendenti e necessità di parallelismo.

## Decisione: Ciclo semi-automatico

I blocchi si susseguono automaticamente se i test passano. Il ciclo si ferma ai checkpoint obbligatori (fine fase, test falliti, decisioni architetturali non previste) e notifica Villa. Questo preserva il principio del pensiero critico — Claude si ferma quando c'è qualcosa su cui riflettere — senza richiedere a Villa di fare copia-incolla ogni volta.

## Checkpoint obbligatori nel ciclo

Indipendentemente dal livello di automazione scelto, ci sono momenti in cui il ciclo DEVE fermarsi e richiedere validazione umana:

### Stop obbligatorio — il ciclo si ferma e aspetta Villa:

- Prima di commit/push su branch principali (`main`, `develop`)
- Prima di passare da una fase del progetto alla successiva (es. da Loop 1 a Loop 2, da sviluppo a testing)
- Quando un test fallisce e il fix non è banale
- Quando il blocco richiede decisioni architetturali non previste dalla roadmap
- Quando il contesto si avvicina al 60% della finestra (rischio perdita di contesto)
- Quando emergono dubbi che richiedono il pensiero critico

### Avanzamento automatico — il ciclo procede senza intervento:

- Tra blocchi della stessa fase, se tutti i test passano
- Dopo aggiornamento automatico di roadmap e handoff
- Dopo commit su feature branch (se la commit policy del progetto lo permette)

**Principio**: automatizzare il meccanico, fermarsi sull'intelligente. Se il blocco è routine e i test passano, il ciclo avanza. Se serve una decisione, il ciclo si ferma.

## Stop del runner automatico e tetto di sicurezza

Quando i blocchi sono eseguiti dal runner (`metodo-villa-runner.sh`, Villa assente), il runner si ferma **da solo** a uno di questi **stop naturali**:

- **Fine fase** (`PHASE_COMPLETE`) — la fase corrente è completa.
- **Checkpoint** (`CHECKPOINT`) — serve una decisione di Villa o segue un blocco umano (👤).
- **Errore / Bloccato** (`ERROR` / `BLOCKED`) — qualcosa non funziona o mancano accessi.
- **Roadmap esaurita** — non restano più blocchi `[ ]` da fare nella roadmap (il runner conta le checkbox e si ferma da solo).

Il parametro `--max-blocks` **non** è un criterio di stop normale né la quantità di lavoro da fare: è un **tetto di sicurezza** (paracadute anti-runaway) con default **alto** (300). Serve solo a impedire che, in caso di anomalia (Claude che non aggiorna l'handoff, roadmap malformata), il runner giri all'infinito bruciando token mentre Villa non c'è. In funzionamento sano il runner tocca **sempre** uno stop naturale prima del tetto. Se invece raggiunge il tetto, è un **segnale da verificare**, non un "lavoro finito": va letto l'handoff e, se restano blocchi, basta rilanciare. Abbassare il tetto ha senso solo per forzare una corsa breve di prova (es. `--max-blocks 3`).

## Due modalità di corsa: "fino a fine fase" vs "tutte le fasi"

Il runner si lancia in due modalità (due avviatori distinti, oppure il flag `--tutte-le-fasi`):

- **Fino a fine fase** (canonica, default): quando una fase è completa il runner si ferma (`PHASE_COMPLETE`). Dà a Villa un punto di controllo a ogni fine fase (es. per il collaudo guidato prima del pilot).
- **Tutte le fasi di fila** (`--tutte-le-fasi`): a fine fase il runner **non** si ferma se nella roadmap restano blocchi nelle fasi successive — prosegue. Serve quando si sono accumulate **fasi diverse in sessioni diverse** (un argomento in una chat, un altro in un'altra) e si vogliono eseguire tutte in **un'unica corsa**, senza rilanciare il runner a ogni fase.

In **entrambe** le modalità il runner si ferma comunque a `CHECKPOINT`, `ERROR`, `BLOCKED` e davanti ai blocchi umani/collaborativi (👤/🤝): "tutte le fasi" significa "non fermarti *solo* perché è finita una fase", non "non fermarti mai". Nota di sequencing (cap. 14): in modalità "tutte le fasi" un blocco 👤/🤝 a inizio della fase successiva ferma comunque la corsa — è il comportamento voluto.

### Lo stop davanti a un blocco 👤/🤝 avviene *prima* di lanciare la sessione

Quando il blocco successivo porta l'etichetta 👤 (umano) o 🤝 (collaborativo), oppure la parola `CHECKPOINT`, il runner lo riconosce **leggendo la roadmap** e si ferma **senza lanciare la sessione**. Scrive un handoff di stop pulito (`STATUS: CHECKPOINT`, con la riga `PER_VILLA`) e avvisa su Telegram.

Serve perché una sessione lanciata su un blocco che richiede Villa non può concludere nulla: nel caso migliore spreca una sessione per arrivare alla stessa conclusione, nel caso peggiore avvia un server di sviluppo e resta appesa fino al timeout. L'etichetta 🤖 (autonomo) e il traguardo `✅ GATE` **non** fermano il runner.

## Corse su un modulo di un monorepo (`--project`)

Un **monorepo** è un repository che contiene più applicazioni, ciascuna nella sua cartella (es. `apps/console`, `apps/portineria`). Con `--project apps/console` il runner lavora dentro quel modulo — roadmap, handoff, comandi di test e cartella di lavoro sono quelli del modulo — ma **il Metodo continua ad arrivare dalla radice**: un modulo non duplica mai il Metodo, lo eredita, e vi aggiunge il proprio `CLAUDE.md` con le regole sue.

Restano della radice anche il canale Telegram e la sua configurazione: la **sezione del gruppo è una per progetto**, non una per modulo. Senza `--project` il runner lavora sulla radice, che è il caso normale di quasi tutti i progetti.

Opzione affine: `--model NOME` (es. `--model claude-opus-5`) fissa il modello per tutta la corsa. Se omesso vale il default del programma di Claude Code, che può essere più vecchio di quello usato nelle corse precedenti: su una corsa lunga che nessuno rilegge, la differenza si accumula.
