# Plugin esterni e automatismo di proposta

Il Metodo Villa v2 puo' essere arricchito da due risorse esterne
opzionali, scaricabili al bisogno. **Nessuna delle due e' nella
"scatola" del boilerplate** — restano agganciate alla loro sorgente
originale per non invecchiare.

Questo capitolo descrive (1) cosa sono, (2) quando servono, (3) come
installarle e (4) come l'agente deve **proporne l'installazione da
solo** al momento giusto.

---

## 1. SuperPowers

### Cos'e'

Plugin Claude Code di Jesse Vincent
(`https://github.com/obra/superpowers`), licenza MIT. Contiene 14 skill
che si auto-attivano e arricchiscono il modo in cui Claude lavora:

- **brainstorming** — sessione socratica prima di scrivere codice.
- **writing-plans** — pianificazione strutturata di un task.
- **executing-plans** — esecuzione disciplinata del piano.
- **subagent-driven-development** — delega a sub-agenti per task isolati.
- **test-driven-development** — ciclo TDD rosso/verde/refactor.
- **systematic-debugging** — 4 fasi per trovare causa radice prima di
  fixare. **Dal 2026-08-19 non e' piu' il primo posto dove guardare**: la disciplina
  di base vive nel Metodo (cap. `29-caccia-ai-problemi.md`) e viaggia con ogni
  progetto senza installare niente. Questo plugin resta un di piu' per chi lo ha gia'.
- **verification-before-completion** — verifica obbligatoria prima di
  chiudere.
- **requesting-code-review** / **receiving-code-review** — review
  automatica.
- **using-git-worktrees** — gestione branch git con worktree.
- **dispatching-parallel-agents** — lavoro parallelo con piu' agenti.
- **finishing-a-development-branch** — chiusura pulita di un branch.
- **writing-skills** — creazione di nuove skill.
- **using-superpowers** — meta-skill che orchestra le altre.

### Quando serve

In **quasi tutti** i progetti non triviali. Le skill che fanno davvero
la differenza sono: brainstorming (prima di scrivere codice), TDD,
systematic-debugging, verification-before-completion. Le altre sono
utili in scenari specifici.

### Come installarlo

Una volta sola, all'inizio del progetto:

```bash
cd .claude
mkdir -p plugins
cd plugins
git clone https://github.com/obra/superpowers.git
```

Poi le skill sono attivate automaticamente da Claude Code, senza
configurazione.

### Modulazione d'uso (categorie A/B)

I blocchi atomici del Metodo Villa sono spesso piccoli. Applicare il
workflow completo SuperPowers (brainstorming → piano → TDD → review) a
ogni blocco e' sproporzionato per i blocchi di scaffold. Quindi:

**Categoria A — Blocchi di scaffold / setup tecnico** (modalita'
SuperPowers LEGGERA):
- Esempi: creare struttura cartelle, installare dipendenze, configurare
  boilerplate (FastAPI base, Next.js base, Docker Compose, CI), generare
  migrazione vuota, popolare seed di dati statici.
- Approccio: salta brainstorming pesante e TDD esagerato. Esegui i
  comandi di scaffold, verifica che parta, scrivi un test minimo (es. "il
  server risponde 200 su /health"), aggiorna handoff. Punto.
- Resta sempre attiva: `verification-before-completion`.

**Categoria B — Blocchi di logica di business / sicurezza /
architettura** (modalita' SuperPowers PIENA):
- Esempi: schema dati con decisioni di modello, Row-Level Security,
  autenticazione, OAuth, integrazione tra componenti critici,
  checkpoint adattivi, voice input, payment integration.
- Approccio: workflow completo. Parti con brainstorming breve sulla
  soluzione, scrivi un piano sintetico, applica TDD vero (test che
  fallisce → codice → test verde), debug sistematico se qualcosa non
  torna, verifica esplicita prima di chiudere.

**Criterio rapido per decidere**: se il blocco produce solo
"infrastruttura tecnica" senza logica decisionale → Categoria A. Se il
blocco produce regole, calcoli, decisioni runtime, o tocca sicurezza →
Categoria B.

In caso di dubbio: Categoria B (meglio fare un po' di lavoro in piu'
che rilasciare codice non testato su scelte critiche).

---

## 2. AwesomeDesign

### Cos'e'

Collezione di 61 file `DESIGN.md` di siti famosi (Linear, Vercel,
Stripe, Notion, Apple, Airbnb, Coinbase, Cohere, Claude, e altri 50+).
Solo testo Markdown. Licenza MIT, di VoltAgent
(`https://github.com/VoltAgent/awesome-design-md`).

### Quando serve

Solo nei progetti che hanno una **interfaccia utente da disegnare**
(webapp, dashboard, app mobile). Non serve per: API senza UI, librerie,
strumenti CLI, script.

### Come scaricarlo

Una volta sola, quando si arriva a un blocco di UI:

```bash
cd reference
git clone https://github.com/VoltAgent/awesome-design-md.git
```

### Come usarlo

Quando il progetto richiede una UI, l'agente:
1. Sfoglia `reference/awesome-design-md/design-md/` per identificare 3-4
   stili plausibili per il progetto.
2. Propone a Villa una rosa breve (es. "per una dashboard sviluppatore
   raccomando Linear o Vercel; per un sito vetrina elegante Stripe o
   Apple").
3. Quando Villa sceglie, copia il `DESIGN.md` dello stile selezionato in
   `webapp/DESIGN.md` (o equivalente nella struttura del progetto).
4. Tailwind/shadcn/ui (o lo stack UI in uso) producono UI coerenti con
   quella estetica.
5. Annota la scelta in `docs/diario/decisioni-da-rivedere.md` per traccia.

---

## 3. Automatismo: proposta di installazione al momento giusto

**Principio**: Villa NON deve ricordarsi di installare questi
strumenti. E' il sistema che li propone quando servono.

### Cosa fa l'agente all'apertura di sessione

Dopo aver letto `CLAUDE.md`, `PROJECT_CONFIG.md`, `ROADMAP.md` e
`docs/diario/handoff.md`, l'agente esegue questi controlli:

1. **Controllo SuperPowers**:
   - Verifica se esiste la cartella `.claude/plugins/superpowers/`.
   - Se NON esiste, e il blocco corrente o uno dei prossimi 2-3
     coinvolge logica di business / sicurezza / architettura
     (Categoria B), propone a Villa di installarlo prima di iniziare:
     > "Vedo che il prossimo blocco riguarda [es. autenticazione]. Il
     > plugin SuperPowers aiuta molto su questo tipo di lavoro (TDD,
     > debug sistematico, verifica). Vuoi che lo installi? Sono 30
     > secondi."
   - Se il prossimo blocco e' di scaffold puro (Categoria A): NON
     propone, e' superfluo.

2. **Controllo AwesomeDesign**:
   - Verifica se esiste la cartella `reference/awesome-design-md/`.
   - Se NON esiste, e il blocco corrente o uno dei prossimi 2-3
     coinvolge UI/design (parole chiave nel titolo del blocco: "UI",
     "frontend", "design", "dashboard", "webapp", "mobile", "app",
     "interfaccia", "schermata"), propone a Villa di scaricarlo:
     > "Vedo che presto lavoreremo sulla UI. C'e' una collezione di
     > stili di siti famosi (AwesomeDesign) molto utile per decidere
     > l'estetica. Vuoi che la scarichi adesso? Cosi quando arriviamo
     > al blocco la abbiamo gia' pronta."
   - Se il progetto non ha UI: NON propone mai.

### Cosa fa l'agente durante la sessione

Se durante un blocco emerge un bisogno specifico:
- "Sto facendo debugging difficile, mi servirebbe systematic-debugging"
  → propone install SuperPowers se non c'e'.
- "Sto per scrivere la prima schermata, mi servirebbe scegliere uno
  stile" → propone download AwesomeDesign se non c'e'.

### Trigger semantici (parole chiave da intercettare)

Per **SuperPowers**:
- "autenticazione", "auth", "OAuth", "JWT", "sessioni"
- "pagamenti", "payment", "stripe", "fatturazione"
- "schema database", "migrazione complessa", "modello dati"
- "permessi", "RBAC", "Row-Level Security"
- "debug difficile", "non riesco a capire perche'"
- "code review", "vorrei un secondo parere"

Per **AwesomeDesign**:
- "UI", "design", "stile", "estetica", "frontend"
- "dashboard", "webapp", "interfaccia"
- "che colori uso", "che font", "che layout"
- "voglio un look come [sito]"

### Se Villa rifiuta

L'agente NON insiste. Annota in `docs/diario/decisions.md` che e' stato
proposto e Villa ha detto di no (con la data), e non lo ripropone nella
stessa sessione. Lo riproporra' al massimo una volta a sessione
successiva, se il bisogno torna evidente.

---

## 4. Aggiornamento del plugin nel tempo

Entrambe le risorse sono progetti vivi su GitHub. Per aggiornarle:

```bash
# SuperPowers
cd .claude/plugins/superpowers
git pull

# AwesomeDesign
cd reference/awesome-design-md
git pull
```

L'agente puo' proporlo a Villa una volta a sessione, all'apertura, se
l'ultimo `git pull` e' "vecchio" (controllo opzionale, non obbligatorio).
