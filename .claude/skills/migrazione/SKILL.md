---
name: migrazione
description: "Guida l'integrazione del Metodo Villa v2 in un progetto gia' esistente. Diagnostica il progetto, classifica il caso (vergine / con v1 / con sistema proprio), propone una strategia personalizzata di integrazione, esegue su branch separato per safety, verifica con primo blocco di prova. Da invocare quando si vuole portare un progetto esistente nel Metodo Villa v2. Trigger: 'integra il metodo villa nel progetto X', 'questo progetto e' di prima del v2', 'voglio applicare il metodo a un progetto esistente', 'migra al v2'. Complementare alla skill discovery (che gestisce progetti nuovi da zero)."
user-invocable: true
---

# Skill Migrazione — Integrare il Metodo Villa v2 in un progetto esistente

## Quando attivarla

Questa skill si attiva quando Villa vuole portare nel Metodo Villa v2
un progetto che gia' esiste. Trigger tipici:
- "voglio integrare il Metodo Villa v2 nel progetto X"
- "questo progetto e' di prima del v2, come lo aggiorno?"
- "ho un progetto esistente, applica il metodo"
- "migra questo al v2"

Si distingue dalla skill `discovery` (che gestisce progetti **nuovi**,
da zero, con intervista cliente). La `migrazione` invece **scopre** cio'
che c'e' gia' e propone come integrarlo.

## Filosofia della migrazione

**Preserva cio' che ha valore. Aggiungi cio' che manca. Archivia cio'
che il v2 sostituisce.**

Mai distruggere materiale del progetto senza esplicito consenso di
Villa. La migrazione e' un'integrazione delicata, non un reset. In ogni
fase, Villa puo' dire "no, fermati, cambiamo strada".

## Le 4 fasi della migrazione

### Fase 1 — Diagnosi automatica del progetto

L'agente scansiona il progetto e produce un **report di diagnosi**
breve (max ~30 righe) che contiene:

**1.1 Inventario degli asset Metodo Villa gia' presenti**

Controlla la presenza di:
- `CLAUDE.md` (dimensione, contiene gia' regole del Metodo Villa?)
- `PROJECT_CONFIG.md`
- `ROADMAP.md`
- `.claude/metodo-villa/` (quanti capitoli? quale versione?)
- `metodo-villa-runner.sh`
- `.claude/skills/chiusura-blocco/`
- `docs/diario/dev-shortcuts.md`
- `docs/diario/handoff.md`
- `.claude/handoff-template.md`

**1.2 Inventario di sistemi alternativi**

Controlla la presenza di:
- `_cursor/` o `.cursorrules` (sistema Cursor)
- `AGENTS.md` (sistema OpenCode)
- `.windsurfrules` (sistema Windsurf)
- `.github/copilot-instructions.md`
- Altri sistemi non-standard

**1.3 Documentazione di dominio rilevante**

Identifica file `.md` significativi (>5 KB, non `README.md`) che
contengono informazioni di dominio da preservare. Esempi: documenti di
specifica, handoff legacy, roadmap legacy molto grandi, API reference.

**1.4 Stack tecnologico**

Rileva:
- Linguaggi prevalenti (analisi estensioni dei file)
- Framework (`package.json`, `pyproject.toml`, `Cargo.toml`, ecc.)
- Sistema di deploy (Docker, Caddyfile, kubernetes manifest, ecc.)
- **Frontend e suo stato**: c'è un'interfaccia utente? Con quale stack — web
  (React/Vite, Next, Vue…) o mobile (Flutter)? Sembra **piatto/boilerplate**
  (UI di default, colori a mano, nessun tema centralizzato)? Questo serve per la
  proposta di re-seeding visivo nella Fase 4.4.

**1.5 Stato del progetto**

Esegui (read-only):
- `git branch --show-current` — branch corrente
- `git log -1 --format='%h %ci %s'` — ultimo commit
- `git status --short` — lavoro non committato
- `git branch | grep wip/` — eventuali branch wip aperti

**1.6 Classificazione del caso**

Sulla base di 1.1-1.5, l'agente classifica:
- **Caso A — Progetto vergine**: nessun asset Metodo Villa, nessun
  sistema alternativo. Migrazione = installazione pulita del v2.
- **Caso B — Progetto con Metodo Villa v1 attivo**: presente
  `.claude/metodo-villa/` con capitoli del v1 (mancano 10, 12, 13).
  Migrazione = aggiornamento ai capitoli nuovi + skill rivista.
- **Caso C — Progetto con sistema proprio**: ha `CLAUDE.md`
  customizzato grande o sistema alternativo (Cursor, OpenCode, ecc.).
  Migrazione = integrazione delicata che preserva il know-how
  esistente.

**Output della fase 1**: report breve a Villa con classificazione +
elenco asset trovati. Villa conferma di voler procedere.

### Fase 2 — Proposta di migrazione

L'agente mostra a Villa un **piano in formato tabella**, per chiarezza:

```
| File del v2                              | Azione              | Note                                                        |
|------------------------------------------|---------------------|-------------------------------------------------------------|
| CLAUDE.md (magro)                        | Crea magro          | Rimando @00-CLAUDE-OPERATIVO.md + regole-progetto SOTTO il marcatore; mai le sez. 1-14 del Metodo |
| PROJECT_CONFIG.md                        | Aggiungi/Unisci     | Se esiste, fondi i contenuti                                |
| ROADMAP.md                               | Sostituisci         | Vecchio in docs/storico/                                    |
| .claude/metodo-villa/ (manuale completo) | Aggiungi/Aggiorna   | Copia i capitoli mancanti; aggiorna quelli evoluti (caso B). Include 00-CLAUDE-OPERATIVO.md (regole del Metodo) + 18 capitoli (01-18) |
| .claude/skills/chiusura-blocco/          | Aggiungi/Sostituisci| Operativa: versione v2 (file-based). Sempre                 |
| .claude/skills/collaudo-guidato/         | Aggiungi/Sostituisci| Operativa: collaudo manuale esplorativo post-sviluppo. Sempre |
| .claude/skills/progettazione-ux/         | Aggiungi se frontend | Operativa: mappa delle schermate PRIMA di costruire (cap. 20). Copiala se il progetto ha (o avra') un frontend, web o mobile |
| .claude/skills/revisione-frontend/       | Aggiungi se frontend | Operativa: direttore dei lavori — sistema il frontend di un progetto avviato su tutti i fronti (esperienza, estetica, layout, telefono) coordinando le altre skill. Particolarmente utile proprio nei progetti migrati |
| .claude/skills/seeding-visivo-web/       | Aggiungi se frontend web | Operativa: copiala se il progetto ha (o avra') un frontend web (React/Vite…). Vedi diagnosi 1.4 e re-seeding 4.4 |
| .claude/skills/seeding-visivo-mobile/    | Aggiungi se frontend Flutter | Operativa: copiala se il progetto ha (o avra') un frontend mobile Flutter. Vedi diagnosi 1.4 e re-seeding 4.4 |
| docs/diario/dev-shortcuts.md                    | Aggiungi se manca   |                                                             |
| .claude/handoff-template.md                 | Aggiungi se manca   |                                                             |
| docs/diario/decisioni-da-rivedere.md            | Aggiungi se manca   | Template per runner automatico                              |
| metodo/metodo-villa-runner.sh            | Aggiungi se manca   | La macchina sta tutta in metodo/ (cap. 09)                  |
| metodo/metodo-sync.sh + manifest + spostamenti | Aggiungi se manca | Allineamento col Metodo ufficiale (cap. 19)             |
| runner.bat                               | Aggiungi se manca   | UNICO avviatore, in radice: menu con runner / aggiorna / rimanda |
| .claude/skills/discovery/                | Skip                | Bootstrap: vive nel boilerplate, si invoca da li' per i progetti NUOVI. Non serve dentro un progetto migrato |
| .claude/skills/migrazione/               | Skip                | Bootstrap (e' questa skill): vive nel boilerplate, non si auto-copia nel progetto migrato |
```

**Skill operative vs bootstrap.** Le skill *operative* (`chiusura-blocco`,
`collaudo-guidato`, e — se c'e' un frontend — `progettazione-ux` e
`seeding-visivo-web`/`seeding-visivo-mobile`) servono durante tutta la vita
del progetto, quindi vivono **dentro** il progetto e si copiano nella
migrazione. Le skill *bootstrap* (`discovery`, `migrazione`)
servono solo per avviare o convertire un progetto: restano nel boilerplate del
Metodo e si invocano da li', per questo sono a **"Skip"**. Le due skill di
seeding si copiano **solo se** il progetto ha (o avra') un frontend; il
re-seeding vero e proprio resta un blocco separato (Fase 4.4). Meccanismo
completo in `docs/fondamenta/distribuzione-skill.md`.

Per ogni file con azione **"Unisci"**, l'agente mostra:
- Un **estratto del contenuto vecchio** che propone di preservare
- Dove andra' nel nuovo file (es. "nel CLAUDE.md magro, SOTTO la riga
  '--- REGOLE SPECIFICHE PROGETTO ---'; le regole del Metodo NON si copiano,
  stanno gia' in `.claude/metodo-villa/00-CLAUDE-OPERATIVO.md`")

Per il **caso C** specificamente, l'agente identifica:
- **Sistemi alternativi**: proposta per ognuno (archiviazione vs
  preservazione vs eliminazione). Es. `_cursor/patterns/` → estrarre
  patterns utili in `docs/diario/decisions.md`, archiviare il resto in
  `docs/storico/_cursor/`.
- **Documenti grossi legacy**: proposta di trasformazione. Es.
  `DEVELOPMENT_ROADMAP.md` di 48 KB → estrai i blocchi non ancora fatti
  per la nuova `ROADMAP.md`, archivia il vecchio in `docs/storico/`.
- **Handoff legacy** (es. `HANDOFF_PROGETTO_RSA_COMPLETO.md`): proposta
  di archiviazione in `docs/storico/`. Il nuovo handoff partira' dalla
  prossima sessione live.

**Plugin esterni opzionali** (SuperPowers / AwesomeDesign):
Se la diagnosi indica componenti che ne beneficiano (logica complessa →
SuperPowers; UI/frontend → AwesomeDesign), l'agente propone
l'installazione in questa fase. Vedi
`.claude/metodo-villa/13-plugin-esterni.md` per trigger semantici.

**Villa legge il piano, modifica se serve, approva.** Senza approvazione
esplicita non si passa alla fase 3.

### Fase 3 — Esecuzione su branch separato

**Mai modificare `main` o `develop` direttamente durante la
migrazione.** Procedura:

1. Crea un branch dedicato:
   ```bash
   git checkout -b metodo-villa-v2-migration
   ```

2. Esegui le azioni del piano approvato **una alla volta**, con commit
   incrementali atomici. Suggerimento di sequenza:
   - Commit 1: "Migrazione v2 — manuale base (capitoli identici al v1: 01-09, 11)"
   - Commit 2: "Migrazione v2 — capitoli nuovi del v2 (10, 12-18)"
   - Commit 3: "Migrazione v2 — skill operative (chiusura-blocco, collaudo-guidato; + seeding-visivo-web/-mobile se c'e' un frontend)"
   - Commit 4: "Migrazione v2 — unisci CLAUDE.md con regole esistenti"
   - Commit 5: "Migrazione v2 — archivia documenti legacy in docs/storico/"
   - Commit 6: "Migrazione v2 — runner e launcher"
   - Commit 7: "Migrazione v2 — pulizia sistemi alternativi (se richiesto)"

3. Ogni commit deve essere:
   - **Atomico** (un solo tema)
   - **Descrittivo** in italiano
   - **Verificabile** (chi guarda il diff capisce cosa e' cambiato)

4. Push del branch su `origin` dopo ogni commit (backup).
   **MAI** merge su `main` o `develop` durante la migrazione.

5. **Se durante l'esecuzione emerge un problema** (es. un file e' piu'
   complesso del previsto, un'unione non si fa pulitamente): FERMA,
   descrivi a Villa, attendi decisione. Non improvvisare.

### Fase 4 — Verifica e primo blocco di prova

Dopo l'esecuzione completa del piano:

**4.1 Sanita' del progetto**:
- Il progetto **compila ancora**? Esegui i comandi di build elencati in
  `PROJECT_CONFIG.md`.
- I **test passano** ancora? Esegui i comandi di test.
- Se qualcosa si e' rotto: rollback al branch precedente
  (`git checkout main`), analizza, ricomincia da fase 2 con piano
  rivisto.

**4.2 Verifica integrazione del v2**:
- Apri una nuova sessione live: l'agente legge correttamente
  `CLAUDE.md` → `PROJECT_CONFIG.md` → `ROADMAP.md` → `docs/diario/handoff.md`?
- I file del manuale `.claude/metodo-villa/` sono coerenti tra loro?
  (verifica con grep dei riferimenti incrociati)
- La skill `chiusura-blocco` e' presente e attivabile?

**4.3 Primo blocco di prova** (test sul campo):
- Inventare un blocco **minimo** per testare la chiusura. Esempi:
  - "Aggiungi una stringa di commento nel file README.md"
  - "Aggiorna la data di 'ultima sessione' in PROJECT_CONFIG.md"
- Eseguire il blocco
- Lasciare che la skill `chiusura-blocco` chiuda
- **Verificare**:
  - `ROADMAP.md` viene aggiornato (blocco segnato `[x]`)
  - `docs/diario/handoff.md` viene generato con il formato giusto
  - Commit + push avvengono
  - Il prompt handoff per la prossima sessione viene mostrato a Villa

Se il blocco di prova fallisce in qualche modo, capire perche' e
sistemare prima di mergiare la migrazione.

**4.4 Output finale**:
- Branch `metodo-villa-v2-migration` con tutta la migrazione tracciata
  in commit puliti
- Report finale a Villa: cosa e' stato fatto, cosa archiviato, eventuali
  decisioni residue da rivedere
- **Suggerimento di merge**: "Se tutto OK, fai merge su `develop` (o
  direttamente su `main`) con tuo via libera". Il merge NON viene fatto
  automaticamente.
- **Proposta di re-seeding visivo** (se in Fase 1.4 è emerso un frontend
  piatto/boilerplate): suggerisci a Villa, come **blocco di lavoro successivo e
  separato** dalla migrazione, di re-seedare il frontend con la skill giusta —
  `seeding-visivo-web` per il web, `seeding-visivo-mobile` per Flutter. Chiarisci
  che NON fa parte di questa migrazione (che tocca solo i file del Metodo, non il
  codice del progetto — vedi "Cosa la skill NON fa"): è un intervento estetico a
  sé, da lanciare a parte quando Villa vuole. Caso scuola: SenilCure, frontend
  piatto re-seedato dopo l'adozione del Metodo.

## Cosa la skill NON fa

- **Non installa dipendenze del progetto** (npm, pip, ecc.). La
  migrazione e' del METODO, non dello stack tecnico.
- **Non riformatta il codice** (no linter, no prettier). Il codice
  resta com'e'.
- **Non rinomina file di codice o cartelle del progetto** (es. non
  cambia `src/` o `lib/`). Tocca solo file del Metodo Villa.
- **Non risolve bug** del progetto esistente. Quelli sono blocchi di
  lavoro separati, dopo la migrazione.

## Fallback se qualcosa va male

Se durante una delle 4 fasi emerge un problema serio:
- FERMA con CHECKPOINT
- Descrivi il problema a Villa
- Proponi 2-3 strade per risolvere
- Aspetta decisione

Se Villa decide "torna indietro":
```bash
git checkout main          # o branch di partenza
git branch -D metodo-villa-v2-migration   # cancella il branch di lavoro
```
Il progetto torna identico a prima. Niente perso.

## Aggiornamento di `docs/diario/decisions.md` post-migrazione

A migrazione completata, aggiungi voce in `docs/diario/decisions.md`:

```
## YYYY-MM-DD — Migrazione al Metodo Villa v2

- Decisione: integrato il Metodo Villa v2 nel progetto (caso A/B/C)
- Motivazione: [breve]
- Alternative scartate: [es. continuare con sistema proprio, restare al v1]
- Documenti archiviati: [lista breve]
- Branch della migrazione: metodo-villa-v2-migration (commit: [hash range])
```

## Output di questa skill

Una volta che il branch di migrazione e' validato e mergiato:
- Il progetto ha `CLAUDE.md`, `PROJECT_CONFIG.md`, `ROADMAP.md`,
  `docs/diario/handoff.md`, `.claude/metodo-villa/`, `.claude/skills/`,
  tutti in formato v2
- Vecchi documenti significativi in `docs/storico/`
- La prossima sessione live parte normalmente come qualsiasi progetto v2
- L'integrazione e' tracciata in `docs/diario/decisions.md`
