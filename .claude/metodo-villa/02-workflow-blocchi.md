# Workflow a Blocchi — Il Cuore del Metodo

## Glossario (terminologia v2)

Distinguere bene questi tre termini, in ordine crescente di durata:

- **Blocco** — unita atomica di lavoro verificabile. 1 modifica coerente
  + 1 sola suite di verifica (vedi capitolo `10-sizing-blocchi.md`). E'
  l'unita di misura del Metodo Villa.

- **Invocazione del runner** — quando Claude viene lanciato dal runner
  automatico (Villa NON e' presente). Ogni invocazione fa
  **esattamente un blocco**. Il runner concatena N invocazioni in
  un'esecuzione. Le regole di autonomia decisionale per le invocazioni
  del runner sono nel capitolo `12-autonomia-runner.md`.

- **Sessione live** — quando Villa e' davanti all'interfaccia di
  Claude Code e chatta in modo interattivo. Puo' contenere **piu'
  blocchi in sequenza**, se i test passano e non emergono checkpoint
  (vedi capitolo `03-ciclo-continuo.md`). Si chiude quando Villa
  decide.

Il blocco e' sempre l'unita atomica, indipendentemente da chi lo
esegue (Villa in sessione live o il runner in invocazione automatica).

## Regola fondamentale di sizing

Un blocco corrisponde a UNA modifica coerente con UNA sola verifica.
Se per chiudere il blocco servono 2+ suite di verifica diverse, va
spezzato. Il sizing si fa **in fase di pianificazione della ROADMAP**,
non durante l'esecuzione.

Dettagli, test di applicazione, caso scuola: vedi capitolo
`10-sizing-blocchi.md`.

## Etichette di natura del blocco

Oltre al sizing, ogni blocco della roadmap deve portare un'etichetta
che ne descrive la **natura esecutiva**, cioe' chi puo' eseguirlo. Le
etichette sono tre:

- **🤖 AUTONOMO** — il runner puo' eseguirlo da solo. Tipico:
  modifiche al codice, scrittura di documenti, test automatici,
  configurazione di file.

- **👤 UMANO** — richiede Villa o un tecnico fisicamente presente.
  Tipico: deploy fisico su un server in casa o ufficio, telefonate
  al cliente, riunioni, operazioni su sistemi protetti da MFA via SMS
  o token fisico.

- **🤝 COLLABORATIVO** — Villa apre una sessione live e Claude assiste
  in tempo reale. Tipico: decisioni di design importanti, kickoff
  cliente, test esplorativi insieme, revisione del piano di una fase.

**Regola di marcatura**: il pianificatore della roadmap (Claude, in
sessione di discovery o di pianificazione fase) DEVE apporre
l'etichetta a ogni blocco **prima del lancio del runner**. Senza
etichetta, il blocco non e' pronto a entrare in coda al runner.

**Regola di sequencing**: in una sequenza pensata per il runner, se
compaiono pattern come 🤖 → 👤 → 🤖 e' un campanello rosso. I blocchi
👤 e 🤝 vanno in testa o in coda alla fase, NON in mezzo. Dettagli,
anti-pattern del progetto Melo, eccezione del "punto di stop
pianificato": vedi capitolo `14-sequencing-blocchi.md`.

## Apertura — Protocollo standard

Sia in sessione live sia in invocazione del runner, il flusso di
apertura e' lo stesso:

1. **Leggere `CLAUDE.md`** del progetto (convenzioni, regole specifiche)
2. **Leggere `PROJECT_CONFIG.md`** (stack, stato, comandi, deployment)
3. **Leggere la `ROADMAP.md`** per individuare il blocco corrente
4. **Leggere `docs/diario/handoff.md`** se esiste (handoff vive in `docs/`,
   NON in `.claude/` — dal 2026-04-09 a causa della protezione
   hardcoded di Claude Code sui file di `.claude/`)
5. **Leggere documenti di riferimento** indicati nel "prossimo passo"
6. **Solo dopo**, iniziare a scrivere codice

Leggere i file esistenti che il blocco corrente deve usare o estendere.

### All'apertura di sessione: check automatismi plugin esterni

In sessione live, all'apertura, l'agente controlla anche se SuperPowers
e/o AwesomeDesign servono per il blocco corrente o per i prossimi 2-3,
e propone l'installazione a Villa se mancano. Dettagli in
`13-plugin-esterni.md`.

## Durante il blocco

Regole comuni a tutti i progetti:

- **Focalizzarsi sul blocco corrente** — non divagare
- **Leggere un file PRIMA di modificarlo**
- **Verificare che compili** dopo ogni modifica significativa
- **Non creare sistemi non richiesti dal blocco corrente**
- **Non inseguire la perfezione** — il progetto deve funzionare, non
  essere perfetto

## Chiusura di blocco — Eseguita dalla skill automatica

La chiusura del blocco e' gestita dalla skill
`.claude/skills/chiusura-blocco/SKILL.md`, che si attiva
**automaticamente** quando il lavoro del blocco e' completato. Villa
NON deve chiederla esplicitamente.

La sequenza obbligatoria (eseguita dalla skill) e':

1. **Test L1** — se falliscono, NON chiudere il blocco
2. **Guardiano di blocco** — auto-review (capitolo `05-qualita-sicurezza.md`)
3. **Aggiornare `ROADMAP.md`** — segnare il blocco come completato `[x]`
4. **Aggiornare `docs/diario/handoff.md`** — stato + prossimo passo
5. **Aggiornare `docs/diario/decisions.md`** — se sono state prese decisioni
   architetturali
6. **Aggiornare `docs/diario/decisioni-da-rivedere.md`** — solo se invocazione
   del runner (vedi `12-autonomia-runner.md`)
7. **Commit + push** — su branch corrente, MAI su main senza ok Villa
8. **Riassunto + prompt prossima sessione** — copia-incolla pronto

Dettagli completi, fallback per errori, e formato dell'handoff: vedi
`.claude/skills/chiusura-blocco/SKILL.md`.

## Avanzamento al blocco successivo

Dopo la chiusura di un blocco, il comportamento dipende dal contesto:

- **In sessione live**: Villa puo' decidere di proseguire col blocco
  successivo (la sessione continua) oppure di fermarsi. Se decide di
  proseguire, ricomincia dal punto "Apertura" sopra. Si avanza di
  default se i test sono verdi e non emergono checkpoint.

- **In invocazione del runner**: il runner valuta lo `STATUS`
  dell'handoff. Se `CONTINUE`, lancia la prossima invocazione sul
  blocco successivo. Se `CHECKPOINT`, `PHASE_COMPLETE`, `ERROR` o
  `BLOCKED`, si ferma e attende Villa.

In entrambi i casi, il limite di stop e' definito nel capitolo
`03-ciclo-continuo.md`.

## Il prompt di handoff — Formato standard

Generato a fine blocco dalla skill chiusura-blocco, e' la cosa che
Villa incolla per riavviare:

```
[NomeProgetto] — Sessione SX — Blocco BY — [titolo]

PRIMA DI SCRIVERE CODICE, leggi questi file in ordine:
1. CLAUDE.md
2. PROJECT_CONFIG.md
3. ROADMAP.md
4. docs/diario/handoff.md

COSA FARE in questa sessione:
- Blocco Y: [descrizione concreta]

GATE DI USCITA:
- [criteri specifici e verificabili]

NON fare: [lista esplicita di cose da non toccare]
```

## Test manuali — Quando servono

Se a fine blocco l'agente ritiene che serva un test manuale (es. UI da
verificare a occhio), lo comunica a Villa con questo formato:

```
---------------------------------------------
FONDATORE: SERVE TEST MANUALE
---------------------------------------------
Cosa testare:
1. [azione concreta]
2. [azione concreta]

Cosa mi aspetto:
- [risultato atteso per ogni punto]

Se qualcosa non funziona:
- Mandami uno screenshot o descrivi cosa vedi
---------------------------------------------
```

Non procedere al blocco successivo finche' Villa non conferma l'esito
del test.
