---
name: chiusura-blocco
description: "Chiude il blocco di lavoro corrente: test L1, guardiano di blocco, aggiorna ROADMAP.md, docs/diario/handoff.md (compreso PER_VILLA: la riga per Villa, in italiano di tutti i giorni), ideas, commit + push, prompt handoff per prossima sessione. Da invocare automaticamente alla fine di ogni blocco, SENZA che l'utente lo chieda."
user-invocable: false
---

# Chiusura blocco di lavoro — Metodo Villa v2

Questa skill viene invocata **automaticamente** quando il lavoro del
blocco corrente e' completato. Villa NON deve chiederla esplicitamente.

## Quando si attiva

Quando l'agente ritiene di aver finito il lavoro previsto dal blocco
corrente (il "gate di uscita" del blocco e' soddisfatto, oppure si e'
arrivati a un punto naturale di chiusura).

## Sequenza obbligatoria

I passi seguenti vanno eseguiti **in ordine**. Saltarne uno e' un
errore.

### 1. Test L1 (obbligatorio)

Eseguire i test pertinenti al lavoro svolto. Consultare
`PROJECT_CONFIG.md` per i comandi specifici del progetto.

- Se i test **passano**: prosegui al punto 2.
- Se i test **falliscono**: **NON chiudere il blocco**. Correggi i
  problemi prima di procedere. Se i problemi sono fuori scope del
  blocco corrente (es. test rotti da un altro pezzo del codebase),
  ferma e descrivi a Villa con CHECKPOINT.
- Se i test **non esistono ancora** per il pezzo appena scritto:
  scrivili **adesso**, prima di chiudere. Il blocco non e' completo
  senza una verifica.

Annota il risultato: quanti test passati, falliti, saltati.

### 2. Guardiano di blocco (due occhi, esiti separati)

Due passaggi distinti. **Gli esiti non si fondono**: nel diario vanno due
righe, una per occhio, anche quando sono tutt'e due verdi — un riepilogo
unico lascia che il verde copra il rosso.

#### Primo occhio — lo standard

Checklist obbligatoria. Rispondi a ciascuna voce **prima** di
procedere:

- [ ] Input utente sanitizzati dove serve?
- [ ] Errori gestiti con try/catch dove l'esecuzione puo' fallire?
- [ ] Nessun segreto hardcoded (chiavi, password, token)?
- [ ] Se hai usato scorciatoie (credenziali fittizie, CORS aperti,
  mock), le hai registrate in `docs/diario/dev-shortcuts.md`?
- [ ] Funzioni lunghe ≤50 righe (o, se piu' lunghe, hai aggiunto un
  commento che spiega perche')?
- [ ] Nessuna duplicazione evidente di codice?
- [ ] Nomi di variabili/funzioni/classi chiari e in inglese?
- [ ] Commenti in italiano e spiegano il **perche'**, non il **cosa**?
- [ ] **Se il blocco ha toccato l'interfaccia (UI, web o mobile)**: hai
  attivato la skill di seeding visivo (`seeding-visivo-web` /
  `seeding-visivo-mobile`)? Hai usato i **token del tema** invece di
  colori e misure grezzi, e i **guardrail** passano? Dark mode presente?
- [ ] **Se il blocco ha deciso una parola del dominio** (un nome nuovo per una
  cosa, o la scelta fra due sinonimi): l'hai scritta in
  `docs/fondamenta/vocabolario.md`, con le parole scartate nella colonna di
  quelle vietate? Si aggiorna adesso, non a fine fase (cap. 30). Solo sui
  progetti che hanno un vocabolario.
- [ ] **Se il blocco ha costruito qualcosa che un altro progetto potrebbe
  volere** (accesso, notifiche, registro, importazione, un modello dati
  ricorrente): hai aggiunto la riga alla scheda del progetto in
  `.claude/precedenti/`? Cinque colonne, e nella colonna delle parole
  **anche i termini inglesi** — altrimenti la voce esiste ma nessuno la
  trova (cap. 28). Se invece hai *usato* un precedente e l'hai trovato
  sbagliato, correggilo subito e aggiorna la data di verifica.

#### Secondo occhio — la consegna

Rileggi il blocco della roadmap e confrontalo con cio' che e' cambiato davvero:

- [ ] **Manca** qualcosa di quello che il blocco chiedeva? Se si', il blocco non
  e' finito: si finisce, non si chiude.
- [ ] **C'e' qualcosa in piu'**? Elencalo file per file, una riga l'uno.

⚠️ Questo occhio **dichiara, non boccia**: cio' che il livello di liberta' in
vigore permette (`stretto` / `normale` / `largo`) va **elencato**, non respinto —
finisce nella riga «chiesto: X. Fatto: X, piu' A, B, C» del diario, e in un commit
separato. Si toglie solo cio' che **supera** il livello: migliorie di comodo a
livello `normale`, o qualunque extra su un blocco di peso 🔴.

Perche' separato dal primo: fatti insieme, la seconda domanda diventa una riga di
cortesia — stai gia' guardando il codice con gli occhi di chi l'ha scritto, e cio'
che e' entrato di troppo sembra sempre sensato. Con la roadmap davanti, no.

Base minima dei difetti classici da tenere d'occhio (sono giudizi, non violazioni;
una regola scritta del progetto vince sempre): nome misterioso, duplicazione,
invidia di funzionalita', grappolo di dati, ossessione dei tipi primitivi,
interruttori ripetuti, chirurgia col fucile, cambiamento divergente, **generalita'
speculativa**, catena di messaggi, intermediario inutile, eredita' rifiutata —
spiegati uno per uno nel cap. `05-qualita-sicurezza.md`.

Se anche una sola voce e' "no" e non e' giustificata, sistemala prima
di chiudere.

### 3. Aggiornare ROADMAP.md

Trova il blocco corrente nel file e:
- Cambia `[ ]` o `[>]` in `[x]`.
- Aggiungi la data di completamento.
- Aggiungi 1-2 righe di descrizione di cosa e' stato fatto.
- Se ci sono note o problemi residui, annotali.
- Se aggiungi blocchi successivi, mettici l'etichetta di natura (🤖/👤/🤝) e —
  se la fase e' divisa in corsie — anche quella di corsia (`[[BE]]`, `[[FE]]`…).
  La regola delle corsie sta in `.claude/metodo-villa/21-corsie-parallele.md`:
  qui si applica soltanto, non si ridefinisce.

### 3bis. Aggiornare la mappa strategica (a fine scenario/ondata)

`ROADMAP.md` contiene i blocchi di dettaglio. Ma se il progetto ha anche
un **documento-bussola di livello superiore** (inventario degli scenari,
macro-roadmap delle fasi/ondate — es. in SenilCure `dominio/scenari-fase-5.md`),
quel documento va aggiornato **alla chiusura di ogni scenario/ondata**, non
solo la roadmap di dettaglio.

- Segna come completati gli scenari/ondate appena chiusi nella bussola.
- Tieni **una sola** bussola come fonte di verita' dello stato (evita
  numerazioni doppie tra documenti diversi: divergono e si contraddicono).
- Motivo: senza questo passo la bussola "si congela" e smette di riflettere
  dove sei davvero — disorienta invece di orientare.

> Difetto che ha originato questa regola (SenilCure, 2026-05-29):
> l'inventario degli scenari era fermo a **due ondate indietro** rispetto al
> lavoro reale, perche' l'aggiornamento della bussola non era in questa
> checklist. Aggiornare la sola `ROADMAP.md` non basta.

Se il progetto non ha una bussola separata (solo `ROADMAP.md`), questo passo
coincide col punto 3.

### 4. Aggiornare `docs/diario/handoff.md`

**Nota importante (dal 2026-04-09)**: l'handoff vive in `docs/`, NON in
`.claude/`. La cartella `.claude/` ha una protezione hardcoded di
Claude Code che impedisce la scrittura. Il template di riferimento
resta in `.claude/handoff-template.md` come read-only.

Formato obbligatorio:

```
STATUS: CONTINUE | CHECKPOINT | PHASE_COMPLETE | ERROR | BLOCKED
PHASE: [numero fase]
BLOCK: [prossimo blocco da eseguire]
SUMMARY: [cosa hai fatto in questo blocco]
NEXT: [descrizione concreta del prossimo blocco]
DECISIONS_NEEDED: [solo se STATUS = CHECKPOINT o BLOCKED]
FILES_MODIFIED: [lista file toccati]
TESTS: PASS | FAIL | SKIPPED
```

Sotto `---`, aggiungi contesto dettagliato sufficiente perche' la
prossima sessione possa partire senza dover rileggere tutto il
codice.

### 5. Aggiornare `docs/diario/decisions.md` (se servito)

Se durante il blocco sono state prese **decisioni architetturali**
(scelta tra alternative, vincoli imposti, trade-off importanti),
aggiungile al log con:

```
## YYYY-MM-DD — [Titolo breve]
- Decisione: [cosa hai deciso]
- Motivazione: [perche']
- Alternative scartate: [cosa NON hai scelto e perche']
```

### 6. Aggiornare `docs/diario/decisioni-da-rivedere.md` (se runner automatico)

**Solo se il blocco e' stato eseguito dal runner automatico** (Villa
non presente): se durante il blocco hai preso decisioni autonome
secondo le 6 regole di autonomia (vedi
`.claude/metodo-villa/12-autonomia-runner.md`), annotale qui.

Formato:

```
## YYYY-MM-DD — Blocco X.Y
- Categoria: sicurezza / schema-DB / libreria / norma-di-legge / scope-esteso / errore-blocco / altro
- Cosa ho deciso: [descrizione]
- Perche': [motivazione]
- Facilita di cambiarla in futuro: facile / medio / difficile
- Riferimento: [file, riga, o blocco interessato]
```

### 7. Commit e push

- Committa tutto il lavoro con un messaggio **in italiano**, chiaro e
  descrittivo (no Conventional Commits stile "feat:", "fix:" — vedi
  `.claude/metodo-villa/07-gestione-codice.md`).
- Push su `origin` sul branch corrente (di solito `blocco/...` o
  `develop`).
- **MAI** pushare su `main` senza autorizzazione esplicita di Villa.
- Se il push fallisce: logga e prosegui, non fermarti — il lavoro e'
  comunque salvo in locale.

### 8. Riassunto + prompt prossima sessione

Comunica a Villa, in modo chiaro e conciso:
- **Cosa e' stato fatto** (1-3 righe).
- **Test passati?** (si/no).
- **Eventuali decisioni** da rivedere (se hai annotato qualcosa nel
  file di revisione).
- **Qual e' il prossimo passo**.

Poi **sempre**, scrivi in chat il prompt handoff per la prossima
sessione (Villa lo copia e lo incolla per riavviare):

```
[NomeProgetto] — Sessione SX — Blocco BY — [titolo]

PRIMA DI SCRIVERE CODICE, leggi questi file in ordine:
1. CLAUDE.md (regole-progetto + rimando al Metodo)
2. .claude/metodo-villa/00-CLAUDE-OPERATIVO.md (regole del Metodo)
3. PROJECT_CONFIG.md
4. ROADMAP.md
5. docs/diario/handoff.md

COSA FARE in questa sessione:
- Blocco Y: [descrizione concreta]

GATE DI USCITA:
- [criteri specifici e verificabili che dichiarano il blocco "fatto"]

NON fare:
- [lista esplicita di cose da non toccare per restare in scope]
```

### 9. Se il blocco chiude una FASE: proponi il collaudo guidato

Se l'handoff di questo blocco ha `STATUS: PHASE_COMPLETE` (la fase e'
completa e ci si avvia verso il pilot/rilascio), **proponi a Villa** un
**collaudo guidato** del prodotto prima di metterlo in mano al cliente —
skill `.claude/skills/collaudo-guidato/SKILL.md`. E' un suggerimento, non un
automatismo: il collaudo richiede Villa presente che prova, quindi parte
solo se lui vuole. Serve perche' i test automatici (L1-L4) non vedono cio'
che solo l'occhio umano nota (UX, incoerenze, bug di sessione, dati
irrealistici). Non vale per i blocchi normali (STATUS diverso da
PHASE_COMPLETE).

### 10. Se hai migliorato il Metodo: proponi il rimando alla madre

Se nel blocco hai toccato file del **Metodo** (manuale `.claude/metodo-villa/`,
skill `.claude/skills/`, runner, o lo strumento in `metodo/`) — cioe' hai migliorato
il *Metodo*, non il *progetto* — **proponi a Villa** di rimandare la miglioria al
repository madre, cosi' arriva a tutti gli altri progetti:
`metodo/metodo-sync.sh rimanda` (anteprima; per inviare davvero serve `--tutti` e
l'ok di Villa). E' un suggerimento, non un automatismo: il rimando tocca **tutti** i
progetti, quindi passa sempre da Villa (vedi `docs/fondamenta/sistema-aggiornamento-metodo.md`).
Non vale se hai toccato solo file del progetto.

## Cosa NON fare

- NON saltare i test (anche se "sei sicuro che funziona").
- NON pushare su `main` senza ok di Villa.
- NON estendere lo scope del blocco "gia' che ci siamo" (vedi regola 4
  di autonomia).
- NON chiudere il blocco se la checklist guardiano ha voci non
  giustificate.
- NON rinominare/spostare file fuori dallo scope del blocco.

## Se qualcosa va storto

- **Test falliscono e non riesci a capire perche'**: ferma con
  CHECKPOINT in handoff. Descrivi cosa hai provato.
- **Commit fallisce per hook pre-commit**: fixa il problema sollevato
  dall'hook, NON usare `--no-verify` salvo permesso esplicito.
- **Push fallisce per conflitto**: non fare merge automatico, descrivi a
  Villa la situazione.
- **Hai scoperto che il blocco era mal scritto**: vedi regola 5 di
  autonomia (`12-autonomia-runner.md`). Se l'errore e' minore,
  risolvi e annota. Se e' grave, CHECKPOINT.
