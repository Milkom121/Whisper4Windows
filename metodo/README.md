# Metodo Villa v2 — Boilerplate

> Punto di partenza per ogni nuovo progetto condotto con il Metodo Villa.
> **Versione 2**: distillata dalla v1 originale + lezioni apprese durante
> lo sviluppo di Creation Machine (157 blocchi, 2026-04 → 2026-05).

## Cos'e' il Metodo Villa

Il Metodo Villa e' un sistema di sviluppo software semi-automatizzato
condotto da Claude (Anthropic). Il lavoro e' organizzato in **blocchi
atomici**: ogni blocco produce un risultato concreto, testato,
committato. Un runner automatico puo' eseguire blocchi in sequenza
senza intervento umano continuo, fermandosi solo per checkpoint,
errori o decisioni architetturali.

Distinzione terminologica importante (vedi capitolo 02 del manuale):
- **Blocco** = unita atomica (1 modifica, 1 verifica).
- **Sessione live** = momento di lavoro umano con Villa davanti
  all'interfaccia; puo' contenere piu' blocchi in sequenza.
- **Invocazione del runner** = lancio automatico di Claude su 1
  blocco, senza Villa presente.

Principi chiave:
- **Solido > Sbrigativo** — si consegna codice pulito; davanti a un bivio vince
  la scelta piu solida ed efficace, non la piu rapida.
- **Un blocco alla volta** — nessuna divagazione, nessun refactoring
  non richiesto.
- **Un blocco = una verifica** — sizing rigoroso (vedi capitolo 10).
- **Handoff obbligatorio** — ogni blocco termina con `docs/diario/handoff.md`
  che descrive stato e prossimo passo.
- **Commit in italiano** — descrittivi, atomici, senza Conventional
  Commits.

## Cosa c'e' di nuovo nel v2 (rispetto al v1)

- **Capitolo 10 — Sizing dei blocchi**: regola fondamentale "1 blocco =
  1 verifica", nata dopo un caso scuola di blocco da 50+ minuti che
  andava spezzato in 3.
- **Capitolo 12 — Autonomia decisionale durante runner automatico**:
  5 regole permanenti (sicurezza, DB, librerie, scope, errori roadmap)
  che permettono all'agente di lavorare in autonomia quando Villa non
  e' presente, annotando ogni scelta in `docs/diario/decisioni-da-rivedere.md`.
- **Capitolo 13 — Plugin esterni opzionali**: SuperPowers (disciplina
  di sviluppo) e AwesomeDesign (stili UI di riferimento). **L'agente
  propone automaticamente l'installazione** quando serve, all'apertura
  di sessione o durante il blocco.
- **Skill `chiusura-blocco` rivista**: sequenza piu' esplicita,
  gestione test falliti, supporto opzionale a runner automatico.
- **Skill `migrazione`**: nuova skill (complementare a `discovery`) per
  integrare il Metodo Villa v2 in progetti **esistenti**. Diagnosi
  automatica, classificazione del caso, piano di migrazione, esecuzione
  su branch separato, verifica con primo blocco di prova.

I capitoli 01-09 e 11 del manuale sono **identici al v1**: la filosofia
e le regole base restano valide.

## Come usare il boilerplate

### 1. Clona e configura

```bash
# Clona il boilerplate
git clone https://github.com/Milkom121/Metodo-Villa-UFFICIALE.git nome-progetto
cd nome-progetto

# Rimuovi il remote del boilerplate e aggiungi il tuo
git remote remove origin
git remote add origin https://github.com/[utente]/[nome-progetto].git
```

### 2. Compila i file di configurazione

- **`PROJECT_CONFIG.md`** — stack tecnologico, comandi essenziali,
  deployment.
- **`ROADMAP.md`** — fasi e blocchi del progetto (se non usi la skill
  discovery).
- **`CLAUDE.md`** — aggiungi le regole specifiche del progetto nella
  sezione dedicata in fondo al file.

**Le notifiche su Telegram non si configurano per progetto.** Bot e gruppo
sono gli stessi ovunque e stanno in un file solo, fuori da ogni repository:

```
~/.metodo-villa/condivisa.env

    TELEGRAM_BOT_TOKEN=...
    TELEGRAM_CHAT_ID=-100...      <- il gruppo, non la chat privata
```

Scritto quello **una volta nella vita**, ogni progetto nuovo non ha niente da
fare: eredita bot e gruppo, e al primo messaggio **si crea da solo la sua
sezione** del gruppo, salvandone il numero nel proprio `.env.runner`. Il file
`.env.runner` del progetto serve solo per le eccezioni (un altro bot, un'altra
conversazione) — vedi `metodo/.env.runner.example`, che spiega anche come si
prepara il gruppo la prima volta.

### 3. (Opzionale) Skill Discovery — Fase pre-sviluppo

Se il progetto e' nuovo e i requisiti non sono ancora definiti, usa la
**skill discovery** prima di iniziare a sviluppare. Lancia Claude Code
e descrivi il progetto — la skill guida l'intero processo da brief a
ROADMAP pronta.

La skill si trova in `.claude/skills/discovery/SKILL.md` ed e' attivata
automaticamente da Claude Code quando menzioni: nuovo progetto, brief,
discovery, kickoff, ecc.

### 4. (Opzionale) Plugin esterni — Installa al bisogno

Il boilerplate v2 NON include SuperPowers e AwesomeDesign per non
appesantirsi. **L'agente propone l'installazione quando serve**
all'apertura di sessione (vedi `.claude/metodo-villa/13-plugin-esterni.md`).

Per installarli manualmente prima:

```bash
# SuperPowers (disciplina di sviluppo, 14 skill)
cd .claude && mkdir -p plugins && cd plugins
git clone https://github.com/obra/superpowers.git

# AwesomeDesign (stili UI di riferimento, solo se il progetto ha UI)
cd ../../reference
git clone https://github.com/VoltAgent/awesome-design-md.git
```

### 5. Avvia il runner

**Windows (doppio click)** — un solo avviatore, `runner.bat` nella radice, che apre
un menù:
```
1. Avvia il runner — si ferma a fine fase      (normale)
2. Avvia il runner — tutte le fasi di fila
3. Aggiorna il Metodo dalla fonte ufficiale
4. Proponi una miglioria al Metodo (anteprima)
```
Prima erano otto file: due modalità × due formati `.bat`/`.ps1`, più i due comandi di
allineamento, ognuno duplicato. Erano due comandi riscritti quattro volte.

**Linux/Mac/Git Bash**:
```bash
chmod +x metodo/metodo-villa-runner.sh
./metodo/metodo-villa-runner.sh --timeout 30                 # fino a fine fase
./metodo/metodo-villa-runner.sh --timeout 30 --tutte-le-fasi # tutte le fasi di fila
```

**Opzioni runner**:
```
--max-blocks N    Tetto di sicurezza: max blocchi per esecuzione, paracadute
                  anti-runaway (default: 300). NON e' la quantita' di lavoro:
                  il runner si ferma prima da solo sugli stop naturali
                  (fine fase, checkpoint, errore, roadmap esaurita). Abbassalo
                  solo se vuoi forzare una corsa breve di prova (es. --max-blocks 3).
--tutte-le-fasi   Non fermarti a fine fase: prosegui con le fasi successive finche'
                  restano blocchi (stop solo a checkpoint, errore o blocco umano).
--timeout N       Timeout minuti per blocco (default: 30)
--phase N         Forza la fase di partenza
--dry-run         Simula senza eseguire Claude
--verbose         Output dettagliato
--resume          Riprendi dall'ultimo handoff
```

## Struttura File

```
[NomeProgetto]/
├── CLAUDE.md                    Regole del progetto + rimando al file operativo
├── PROJECT_CONFIG.md            Configurazione progetto
├── ROADMAP.md                   Piano sviluppo a blocchi
├── README.md                    Il progetto (questo file descrive il Metodo)
├── runner.bat                   UNICO avviatore: menù (runner / aggiorna / rimanda)
│
├── metodo/                      La macchina del Metodo — si ignora, si aggiorna da sola
│   ├── metodo-villa-runner.sh   Runner automatico
│   ├── metodo-sync.sh           Allineamento col Metodo ufficiale, nei due sensi
│   ├── metodo-manifest.txt      Lista bianca: che cosa è Metodo
│   ├── metodo-spostamenti.txt   Riordini passati: fa migrare da soli i progetti vecchi
│   ├── metodo-telegram.sh/.py   Canale a due sensi con Villa (notifiche e risposte)
│   ├── trascrivi-vocale.py      Trasforma in testo i vocali di Villa, senza uscire dal PC
│   ├── .env.runner.example      Eccezioni del progetto (bot e gruppo stanno in ~/.metodo-villa/)
│   └── README.md                Questo file
│
├── docs/
│   ├── fondamenta/              Scritti una volta, poi consultati (concept, requisiti, schema)
│   └── diario/                  Crescono lavorando (handoff, progress, log, decisions, ideas)
│
├── .claude/
│   ├── settings.json            Configurazione Claude Code
│   ├── handoff-template.md      Formato handoff (read-only)
│   ├── skills/                  Tutte le skill del Metodo (auto-caricate)
│   │   ├── chiusura-blocco/        Operativa: chiusura blocco
│   │   ├── discovery/              Bootstrap: progetti nuovi (intervista, concept)
│   │   ├── migrazione/             Bootstrap: progetti esistenti (novita' v2)
│   │   ├── progettazione-ux/       Operativa: mappa schermate prima di costruire il frontend
│   │   ├── revisione-frontend/     Operativa: direttore dei lavori — sistema il frontend di un progetto avviato
│   │   ├── seeding-visivo-web/     Operativa: frontend web bello al primo colpo
│   │   └── seeding-visivo-mobile/  Operativa: frontend mobile Flutter
│   ├── metodo-villa/            Manuale operativo completo (18 capitoli)
│   │   ├── 01-filosofia.md
│   │   ├── 02-workflow-blocchi.md
│   │   ├── ... (03-15)
│   │   ├── 16-design-core.md       ⭐ cuore comune web+mobile
│   │   ├── 17-design-web.md        ⭐ stile web neutro
│   │   └── 18-design-mobile.md     ⭐ stile mobile neutro
│   └── plugins/                 (vuoto, SuperPowers si installa al bisogno)
│
├── docs/
│   ├── progress.json            Stato runner (fase, blocco, status)
│   ├── dev-shortcuts.md         Scorciatoie sviluppo attive
│   ├── handoff.md               Stato sessione corrente (generato)
│   └── decisioni-da-rivedere.md Decisioni autonome del runner (generato)
│
├── reference/
│   └── (vuoto, AwesomeDesign si scarica al bisogno)
│
├── src/                         Codice sorgente
└── tests/                       Test
```

## Skill di avvio progetto

Due skill complementari, a seconda della situazione di partenza:

### Skill `discovery` — per progetti **nuovi**

Gestisce la fase **pre-sviluppo** in 9 fasi:

1. **Input** — lettura documenti cliente
2. **Analisi** — identificazione gap e requisiti mancanti
3. **Intervista** — domande strutturate una alla volta
4. **Concept Document** — Word `.docx` per il cliente
5. **Presentazione** — PowerPoint `.pptx` di sintesi
6. **Feedback** — raccolta revisioni cliente
7. **Impatti a cascata** — analisi delle modifiche strutturali
8. **Aggiornamento** — revisione documenti
9. **Output sviluppo** — `PROJECT_CONFIG.md`, `ROADMAP.md`, `CLAUDE.md`,
   schema DB

Documentazione: `.claude/skills/discovery/SKILL.md`

### Skill `migrazione` — per progetti **esistenti** (novita' v2)

Gestisce l'integrazione del Metodo Villa v2 in un progetto che gia'
esiste, in **4 fasi**:

1. **Diagnosi automatica** — l'agente scansiona il progetto e classifica
   il caso (vergine / con v1 attivo / con sistema proprio).
2. **Proposta di migrazione** — piano in formato tabella (cosa
   aggiungere, cosa unire, cosa archiviare). Villa approva.
3. **Esecuzione su branch separato** — `metodo-villa-v2-migration`,
   commit incrementali atomici. Mai merge automatico su main/develop.
4. **Verifica + primo blocco di prova** — il progetto compila ancora?
   La chiusura blocco funziona? Solo se OK, suggerisce merge.

La skill preserva il know-how gia' presente (regole specifiche di
dominio, patterns, decisioni) e archivia in `docs/storico/` i documenti
legacy sostituiti dal v2.

Documentazione: `.claude/skills/migrazione/SKILL.md`

## Runner Automatico

Il runner esegue blocchi di sviluppo in sequenza, leggendo lo stato da
`docs/diario/progress.json` e il handoff da `docs/diario/handoff.md`. Si ferma
automaticamente a:

- `CHECKPOINT` — richiede decisione umana
- `PHASE_COMPLETE` — fase completata, pronta per review
- `ERROR` — errore nel blocco
- `BLOCKED` — mancano informazioni per procedere

Durante l'esecuzione automatica, Villa non e' presente. L'agente prende
decisioni tecniche da solo seguendo le **5 regole di autonomia**
(`.claude/metodo-villa/12-autonomia-runner.md`) e annota tutto in
`docs/diario/decisioni-da-rivedere.md` per revisione successiva.

Log in `docs/diario/session-log.md` e `docs/diario/runner-log.txt`.

## Riferimenti

- Manuale operativo completo: `.claude/metodo-villa/README.md`
- Boilerplate v1 (legacy): `https://github.com/Milkom121/metodo-villa-boilerplate`

---

*Metodo Villa v2 — distillato il 2026-05-22 dal progetto Creation Machine.*
