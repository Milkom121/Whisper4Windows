# Struttura File Standard di Ogni Progetto

## La regola d'oro della radice (dal 2026-08-07)

**Nella radice c'e' solo roba del progetto.** Tutto il Metodo vive in due posti:

| Dove | Che cos'e' |
|------|-----------|
| `.claude/` | Quello che **legge l'agente**: manuale operativo e skill |
| `metodo/` | La **macchina**: runner, strumento di sync, manifest, spostamenti |
| `runner.bat` (radice) | L'**unica** cosa del Metodo che l'umano tocca a mano |

Perche' esiste questa regola: prima il Metodo teneva in radice 11 file (8 avviatori,
il runner, `.gitattributes`, la cartella `tooling/`) che si alternavano in ordine
alfabetico ai file del progetto. Trovare le proprie cose era un lavoro.

I documenti si dividono in due, per lo stesso motivo:

| Cartella | Che cosa ci va | Come si riconosce |
|----------|----------------|-------------------|
| `docs/fondamenta/` | Concept, brief del cliente, presentazione, schema dati, requisiti | **Si scrive una volta** e poi si consulta |
| `docs/diario/` | Handoff, avanzamento, log, decisioni, scorciatoie, collaudi | **Cresce** a ogni blocco |

Nel dubbio: se un documento verra' ancora modificato mentre si costruisce, e'
`diario/`; se descrive che cos'e' il progetto, e' `fondamenta/`.

## Struttura obbligatoria per ogni progetto Villa

```
progetto/
├── CLAUDE.md                       # Bussola — regole del progetto + rimando al file operativo (OBBLIGATORIO)
├── PROJECT_CONFIG.md               # Configurazione specifica (nome, stack, dominio)
├── ROADMAP.md                      # Piano a blocchi con checkbox (OBBLIGATORIO)
├── README.md                       # Il progetto (NON il Metodo: quello e' in metodo/README.md)
├── runner.bat                      # UNICO avviatore: apri e scegli (runner / aggiorna / rimanda)
│
├── metodo/                         # La macchina del Metodo — si ignora, si aggiorna da sola
│   ├── metodo-villa-runner.sh      # Runner automatico (Bash, Linux/Mac/Git Bash)
│   ├── metodo-sync.sh              # Allineamento col Metodo ufficiale, nei due sensi
│   ├── metodo-manifest.txt         # Lista bianca: che cosa e' Metodo
│   ├── metodo-spostamenti.txt      # Riordini passati: fa migrare da soli i progetti vecchi
│   ├── .env.runner.example         # Esempio di configurazione del runner
│   └── README.md                   # Documentazione del Metodo Villa
│
├── docs/
│   ├── fondamenta/                 # Scritti una volta, poi consultati
│   │   └── (concept, requisiti, schema dati, presentazione…)
│   └── diario/                     # Crescono lavorando
│       ├── dev-shortcuts.md        # Registro scorciatoie di sviluppo (OBBLIGATORIO)
│       ├── handoff.md              # Stato fine blocco (generato da Claude)
│       ├── progress.json           # Stato runner (generato automaticamente)
│       ├── decisioni-da-rivedere.md # Decisioni autonome del runner (se runner attivo)
│       ├── decisions.md            # Log decisioni architetturali (generato da Claude)
│       └── ideas.md                # Idee future emerse durante le sessioni live
│
├── .claude/
│   ├── settings.json               # Configurazione Claude Code
│   ├── handoff-template.md         # Formato handoff (read-only)
│   ├── skills/                     # Tutte le skill del Metodo (auto-caricate da Claude Code)
│   │   ├── chiusura-blocco/        # Operativa: sequenza di chiusura blocco
│   │   │   └── SKILL.md
│   │   ├── collaudo-guidato/       # Operativa: collaudo manuale esplorativo post-sviluppo
│   │   │   └── SKILL.md
│   │   ├── discovery/              # Bootstrap: kickoff progetti nuovi (intervista, concept)
│   │   │   ├── SKILL.md
│   │   │   └── references/
│   │   ├── migrazione/             # Bootstrap: integra il Metodo in progetti esistenti
│   │   │   └── SKILL.md
│   │   ├── progettazione-ux/       # Operativa: mappa delle schermate PRIMA di costruire il frontend
│   │   │   └── SKILL.md
│   │   ├── revisione-frontend/     # Operativa: direttore dei lavori — rimette a posto il frontend di un progetto avviato
│   │   │   └── SKILL.md
│   │   ├── seeding-visivo-web/     # Operativa: frontend web bello al primo colpo (React/Vite)
│   │   │   ├── SKILL.md
│   │   │   └── references/         # manuale stile, skin CSS, golden pages, guardrail
│   │   └── seeding-visivo-mobile/  # Operativa: frontend mobile Flutter bello al primo colpo
│   │       ├── SKILL.md
│   │       └── references/         # tema Dart, golden screens, guardrail Flutter
│   └── metodo-villa/               # Manuale operativo completo
│       ├── README.md
│       ├── 00-CLAUDE-OPERATIVO.md  # Le regole del Metodo (sez. 1-15), richiamate dal CLAUDE.md
│       ├── 01-filosofia.md
│       ├── 02-workflow-blocchi.md
│       ├── 03-ciclo-continuo.md
│       ├── 04-testing.md
│       ├── 05-qualita-sicurezza.md
│       ├── 06-scorciatoie-sviluppo.md
│       ├── 07-gestione-codice.md
│       ├── 08-gestione-progetto.md
│       ├── 09-struttura-file.md
│       ├── 10-sizing-blocchi.md
│       ├── 11-deploy-checkout.md
│       ├── 12-autonomia-runner.md
│       ├── 13-plugin-esterni.md
│       ├── 14-sequencing-blocchi.md
│       ├── 15-validazione-multi-agente.md
│       ├── 16-design-core.md       # cuore comune web+mobile
│       ├── 17-design-web.md        # manuale stile web neutro
│       ├── 18-design-mobile.md     # manuale stile mobile neutro
│       └── 19-sync-metodo.md       # aggiornamento del Metodo a due sensi
│
├── src/                            # Codice sorgente
└── tests/                          # Test
```

`.gitattributes` sta anch'esso in radice, ma per obbligo: git lo legge solo da la'.
E' l'unica eccezione alla regola d'oro, e non da' fastidio perche' e' un file nascosto.

## Struttura centralizzata a livello utente

A livello di home utente, Villa mantiene file globali (NON specifici di
un singolo progetto):

```
C:\Users\Mario\Documents\
└── ideas.md               # Idee cross-progetto (intuizioni che toccano piu' progetti o il metodo stesso)

C:\Users\Mario\.claude\
└── CLAUDE.md              # Stile di comunicazione + disciplina di collaborazione globale di Villa
                          # (letto automaticamente da Claude Code per ogni progetto)
```

## Come attivare il sistema in un nuovo progetto

1. Clonare il boilerplate `Metodo-Villa-UFFICIALE` nella nuova cartella progetto.
2. Compilare `PROJECT_CONFIG.md` con stack, comandi, deployment.
3. Compilare `ROADMAP.md` (manualmente, oppure tramite la skill
   `.claude/skills/discovery/SKILL.md` che la genera dopo intervista cliente).
4. Aggiungere le regole specifiche del progetto in fondo a `CLAUDE.md`
   (nella sezione "Regole specifiche progetto").
5. Lanciare la prima sessione live con Claude Code.

Il `CLAUDE.md` globale di Villa (`~/.claude/CLAUDE.md`) viene letto
automaticamente da Claude Code e contiene stile di comunicazione +
disciplina di collaborazione. Il `CLAUDE.md` di ogni progetto contiene
le regole del Metodo Villa + le regole specifiche di quel progetto.

## File obbligatori per ogni progetto

| File | Scopo | Compilato da |
|------|-------|--------------|
| `CLAUDE.md` | Metodo Villa + regole specifiche progetto | Villa + Claude |
| `PROJECT_CONFIG.md` | Stack, comandi, deployment | Villa |
| `ROADMAP.md` | Piano fasi e blocchi | Villa + Claude |
| `docs/diario/dev-shortcuts.md` | Scorciatoie attive in sviluppo | Claude |
| `docs/diario/handoff.md` | Stato fine blocco | Claude (skill chiusura-blocco) |

## File generati automaticamente

| File | Quando |
|------|--------|
| `docs/diario/progress.json` | Aggiornato dal runner ad ogni blocco completato |
| `docs/diario/session-log.md` | Log sintetico per esecuzione del runner |
| `docs/diario/runner-log.txt` | Log completo con output Claude |
| `docs/diario/handoff.md` | Fine di ogni blocco |
| `docs/diario/decisioni-da-rivedere.md` | Solo se il runner gira in autonomia, vedi capitolo 12 |
| `docs/diario/decisions.md` | Quando vengono prese decisioni architetturali |
| `docs/diario/ideas.md` | Quando emergono idee fuori-blocco da non perdere |
| `docs/collaudo-<contesto>.md` | Quando si esegue un collaudo guidato (rilievi classificati + indice) |

## Descrizione dei file principali

### `CLAUDE.md`

La bussola del progetto. Contiene:
- Versione compressa del Metodo Villa (sezioni 1-14)
- Riferimenti puntuali ai capitoli dettagliati in `.claude/metodo-villa/`
- Regole specifiche del progetto in fondo (sezione "Regole specifiche")

Va letto da Claude all'apertura di ogni sessione live o invocazione del
runner.

### `ROADMAP.md`

Piano a blocchi con checkbox `[ ]`, `[>]`, `[x]`. Ogni blocco ha:
- Titolo descrittivo
- Descrizione concreta di cosa deve essere fatto
- Gate di uscita (criteri verificabili per considerare il blocco
  completato)
- Una sola suite di verifica (vedi `10-sizing-blocchi.md`)

Esempio:
```markdown
### Blocco 4.1: Autenticazione JWT
- [ ] **Stato**: da fare
- **Complessita'**: media
- **Descrizione**: Implementare JWT token generation + middleware su route protette
- **Gate di uscita**: pytest backend verde su tests/test_auth.py
```

### `docs/diario/dev-shortcuts.md`

Registro obbligatorio delle scorciatoie di sviluppo prese durante i
blocchi. Si aggiorna **durante** lo sviluppo, non a fine blocco.

### `docs/diario/handoff.md`

Nota storica: spostato da `.claude/handoff.md` nel 2026-04-09 per
evitare la protezione hardcoded di Claude Code sui file di `.claude/`
(che blocca la scrittura anche con `--dangerously-skip-permissions`).

Generato dalla skill `chiusura-blocco` a fine blocco. Contiene:
- Blocco appena completato
- File modificati/creati nel blocco
- Risultati dei test
- Problemi aperti (se any)
- Decisioni prese
- Prossimo passo — il prompt di handoff che Villa puo' incollare per
  riavviare

### `docs/diario/decisioni-da-rivedere.md`

Generato solo se il runner gira in autonomia (Villa non presente). Ogni
decisione tecnica presa dall'agente in base alle 6 regole di autonomia
(`12-autonomia-runner.md`) viene annotata qui per revisione successiva.

### `docs/diario/decisions.md`

Log strutturato di tutte le decisioni architetturali prese durante il
progetto. Formato a 4 colonne (Data, Decisione, Motivazione,
Alternative scartate). Generato da Claude, sempre in crescita.

### `docs/diario/ideas.md`

File libero dove Claude raccoglie idee interessanti che emergono
durante il lavoro ma che non fanno parte del blocco corrente. Inclusa
data e contesto.

### `.claude/skills/` (le skill del Metodo)

Tutte le skill vivono qui e Claude Code le carica automaticamente (anche
in modalita' headless, vedi nota del Blocco 0.2). Si dividono in due
famiglie:
- **Operative** — usate ripetutamente nella vita del progetto, quindi
  copiate dentro ogni progetto che ne ha bisogno: `chiusura-blocco`
  (chiusura blocco), `collaudo-guidato` (collaudo manuale esplorativo
  post-sviluppo, vedi cap. 04), `progettazione-ux` (mappa delle schermate
  prima di costruire il frontend, vedi cap. 20), `revisione-frontend`
  (direttore dei lavori: rimette a posto il frontend di un progetto gia'
  avviato su tutti i fronti, coordinando le altre), `seeding-visivo-web` e
  `seeding-visivo-mobile` (generazione frontend bello al primo colpo,
  vedi cap. 16/17/18).
- **Bootstrap** — usate una volta sola per avviare un progetto, quindi
  restano nel boilerplate del Metodo e si invocano da li': `discovery`
  (progetti nuovi) e `migrazione` (progetti esistenti). Vedi
  `docs/fondamenta/distribuzione-skill.md` per il meccanismo di distribuzione.

`chiusura-blocco` e' la skill auto-attivata che esegue la sequenza di
chiusura blocco (test + guardiano + aggiornamenti file + commit +
handoff). Vedi `02-workflow-blocchi.md` per il flusso completo.

### `.claude/metodo-villa/` (manuale)

Manuale operativo completo del Metodo Villa. Da leggere **una volta
sola** all'inizio del progetto, poi consultato per sezioni specifiche.
Indice e descrizione di ogni capitolo in `.claude/metodo-villa/README.md`.
