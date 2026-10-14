---
name: seeding-visivo-web
description: "Skill per la generazione di frontend WEB (React/Vite) belli e coerenti al primo colpo. Usa questa skill ogni volta che si lavora sul WEB e si menziona: seeda questo progetto web, applica il seme visivo, frontend web bello al primo colpo, refactor visivo web, riparazione UI web piatta, generazione UI web, prima volta che si crea il frontend web di un progetto, creazione pagine showcase, allineamento visivo a una famiglia di prodotti. Anche quando si vuole sostituire un frontend web esistente piatto/boilerplate con uno curato, o quando si avvia un nuovo progetto web e si vuole partire con uno stack opinato e curato (React + Vite + TypeScript + Tailwind + shadcn/ui + Lucide + Inter). Sempre quando si parla di 'qualita visiva' web, 'UI premium', 'livello SenilWatch', 'stile coerente', 'design system applicato'. IMPORTANTE: questa skill e' SOLO per il WEB; per app MOBILE in Flutter usa invece la skill seeding-visivo-mobile. English triggers: seed visual web, beautiful web UI generation, frontend scaffolding with curated style, UI quality bootstrap."
---

# Seeding Visivo — Frontend curato al primo colpo

Questa skill risolve un problema strutturale del Metodo Villa: il runner produce frontend **tecnicamente corretti ma esteticamente piatti**. La causa non è il modello AI (Claude è bravo), è il fatto che il runner lavora a **blocchi isolati** senza un seme visivo concreto da imitare.

La skill applica la stessa ricetta di Bolt/Lovable/v0 — **stack opinato + system prompt anti-bruttezza + repo template + pattern golden** — ma in casa, sui gusti specifici Villa, senza dipendere da servizi esterni.

## Filosofia

**Tre principi guida** (gli stessi che fanno funzionare Lovable):

1. **Stack cementato**: ogni progetto frontend web Villa usa lo stesso stack (React + Vite + TS + Tailwind + shadcn/ui + Lucide + Inter). Niente discussioni stack-per-progetto. (Per il mobile c'e' la skill sorella `seeding-visivo-mobile`, stack Flutter + Material — non forui.)
2. **System prompt anti-bruttezza**: documento stringente che vieta le scelte stilistiche pigre (hex hardcoded, table HTML grezza, gradient flashy, font di sistema, ecc.) e obbliga lo stile cementato. Caricato automaticamente quando l'agente tocca file frontend.
3. **Seme visivo concreto**: un repo template pre-pronto con shadcn/ui già scaffoldato + un set di pagine showcase + un sistema di "skin" (palette + tipografia + brand mark) per famiglia di prodotti.

**Lingua di default**: italiano. Lo stack tecnico è in inglese, ma la skill comunica con l'utente in italiano.

**Quando usare questa skill**:
- (a) **Nuovo progetto**: dopo `discovery`, prima dei blocchi tecnici. Genera il seme frontend.
- (b) **Riparazione di progetto piatto**: progetto esistente con UI boilerplate/piatta, da re-seedare. Caso d'uso scuola: SenilCure 2026-05.
- (c) **Nuova fase visiva** di progetto maturo: aggiunta di moduli con esigenze visive nuove.

**Quando NON usare**:
- Progetti senza frontend (API only, batch, CLI tools).
- Refactor puramente funzionale (cambio business logic senza tocchi UI).

---

## Stato e persistenza

Per non perdere il filo tra messaggi/sessioni, mantieni un file **`seeding-state.md`** nella cartella di lavoro del progetto target. Struttura:

```markdown
# Seeding Visivo State — [Nome Progetto]
## Fase corrente: [1-7]
## Stack scelto: web | mobile
## Skin scelto: default | senilcare | [altro]
## Pagine generate finora:
- [elenco con path]
## Guardrail check (7 totali):
- [✓/✗ con dettaglio]
## File modificati:
- [lista]
## Prossimo passo:
- [cosa fare]
```

Se la sessione si interrompe, leggi questo file per riprendere.

---

## Workflow completo

Il processo è in 7 fasi. Per progetti riparazione (caso b), salta direttamente alla Fase 3.

### Fase 1 — Identifica contesto e stack

Verifica e raccogli:
1. **Tipo di app**: gestionale interno (es. SenilCure), B2C consumer, dashboard reportistica, app mobile, sito vetrina, tool ammin.
2. **Stack scelto**: web o mobile (default web salvo richiesta).
3. **Stile di partenza**: NON scegliere qui i colori. La palette e lo stile si
   decidono nella **Fase 4 — Styling co-progettato** (un momento 🤝 con Villa).
   Qui annota soltanto se esiste già un brand/preset di riferimento o un'ispirazione.

Salva le scelte in `seeding-state.md`.

### Fase 2 — Carica il system prompt anti-piattezza

Leggi e applica il documento `references/system-prompt-anti-piattezza.md`. Da questo punto in poi, ogni file frontend che produci deve rispettare le regole VIETATO/OBBLIGATORIO/PRINCIPI di quel documento.

Conferma a Villa: "System prompt anti-piattezza caricato. Da ora in poi opero in modalità Lovable-like: stack cementato, no scelte mediocri."

### Fase 3 — Clona o adatta il template starter

**Stato attuale**: il repo template `metodo-villa-frontend-starter-web` non è ancora pubblicato. **Workaround**: scaffolda manualmente lo stack nel progetto target.

Comandi base:
```bash
# Web
npm create vite@latest frontend -- --template react-ts
cd frontend
npm install
npm install -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
npx shadcn@latest init  # scegli "Default", "Slate", CSS variables: yes
# Aggiungi componenti shadcn essenziali
npx shadcn@latest add button input textarea select checkbox switch badge avatar card tabs dialog sheet dropdown-menu tooltip alert-dialog skeleton table form sonner
# Lucide React
npm install lucide-react
# Inter font (via Google Fonts in index.html o self-hosted)
```

Per **progetti riparazione (caso b)**: NON sovrascrivere il `frontend/` esistente. Crea `frontend-v2/` parallelo per validare side-by-side, sostituisci solo dopo approvazione Villa.

Salva i file creati in `seeding-state.md`.

### Fase 4 — Styling co-progettato (🤝 COLLABORATIVO)

Questa è la fase in cui si decide l'aspetto del prodotto. È **intrinsecamente
🤝 collaborativa**: le scelte estetiche (palette, tono, brand) le fa **Villa**,
non l'agente da solo. Va eseguita in **sessione live, PRIMA** dei blocchi
autonomi che generano le pagine.

> **Fallback neutro per il runner (regola di autonomia)**: se questa fase NON è
> stata fatta — per esempio il runner sta girando in autonomia con Villa assente
> — **NON inventare una palette**. Applica lo **skin-default neutro**
> (`references/skin-default.css`) e annota in `seeding-state.md`:
> «skin: default (fallback, styling non co-progettato)». **Mai far scegliere i
> colori al runner da solo.**

**Il dialogo di co-progettazione** (con Villa presente). Si parte da un preset e
lo si adatta insieme. Preset disponibili come punto di partenza:
- `skin-default` — palette neutra slate (`references/skin-default.css`). La base
  da vestire.
- `skin-senilcare` — esempio con palette blu in stile SenilWatch
  (`references/skin-senilcare.css`). Mostra come si compila uno skin.

Domande da porre a Villa (testo libero, **non** a scelta multipla):
1. **Colore del brand** (il primario / CTA): c'è già un colore aziendale? Un logo
   da cui partire? Un'ispirazione (un prodotto che piace)?
2. **Tono**: più sobrio/istituzionale o più caldo/consumer?
3. **Modalità di default**: la dark mode c'è **sempre** (regola permanente di Villa, non è opzionale) — qui si decide solo quale sia la modalità predefinita all'avvio: chiara o scura?
4. **Brand mark**: nome del prodotto + un'icona Lucide che lo rappresenti.
5. **Densità**: gestionale denso (molti dati) o vetrina più ariosa?

Da queste risposte si fissano i **token** (vedi `17-design-web.md`, sezione
Token): il primario, l'eventuale accento, il raggio; si conferma Inter.

**Applicazione tecnica**: copiare il preset scelto in `index.css` (blocco
`:root`/`.dark`) e cambiare i valori concordati — soprattutto `--primary` e
`--ring`. Gli altri token (superfici, severità) restano quelli del preset salvo
richiesta esplicita. Caricare Inter. Mostrare a Villa la palette applicata
(i colori) e farsi confermare prima di procedere.

Salva in `seeding-state.md`: preset di partenza, colore primario scelto,
modalità (light/dark), brand mark.

### Fase 5 — Genera le 5-6 pagine "scheletro" core

Basandoti sui requisiti del progetto (raccolti via `discovery` o leggendo `PROJECT_CONFIG.md` se esistono), genera lo scheletro di queste pagine canoniche:

1. **Login** (pattern `Login` — DESIGN-SYSTEM SenilCare sez. 10.4)
2. **Dashboard** (pattern `Dashboard` — sez. 10.1)
3. **Lista entità principale** (es. ospiti, clienti, ordini — pattern `Lista` — sez. 10.2)
4. **Dettaglio entità** (pattern `Dettaglio` — sez. 10.3)
5. **Gestione utenti** (se progetto multi-utente — pattern `Gestione` — sez. 10.5)
6. **`/dev/components-pattern`** (showcase di tutti i pattern compositi — sezione 9 al completo, renderizzata)

Per ogni pagina, applica rigorosamente i pattern di pagina canonici. NIENTE composizioni libere.

### Fase 6 — Genera il file `/dev/components-pattern`

Pagina showcase con TUTTI i pattern compositi della sezione 9 del DESIGN-SYSTEM SenilCare renderizzati con dati finti coerenti col dominio del progetto:

- StatCard (4 varianti)
- PageHeader (3 varianti)
- AlarmCenter / AlertContainer (3 severity)
- EmptyState ricco (4 sentiment)
- EntityCard (3 varianti)
- NavGroup (sample sidebar)
- NavBadge (4 stati)
- BrandMark (4 varianti)
- HeroBanner (1 esempio)
- CTA Group (3 layout)

Questa pagina diventa la **fonte vivente di riferimento** per i blocchi successivi del runner. Il runner la consulta prima di scrivere qualunque nuovo componente.

### Fase 7 — Esegui i 9 guardrail e chiudi il seeding

Esegui i check deterministici del documento `references/system-prompt-anti-piattezza.md` sezione 7:

1. Anti-hex hardcoded
2. Anti-table HTML
3. Anti-button nativo
4. Anti-svg inline non lucide
5. Anti-alert/confirm/prompt browser
6. Check font Inter caricato
7. Check shadcn installato
8. Check dark mode definita (blocco `.dark` nei CSS) — **la dark mode è obbligatoria**

Score minimo per chiudere il seeding: **9/9** (guardrail bloccanti, responsivita inclusa). I 3 guardrail aggiuntivi (7.9 Card con ombre, 7.10 KPI con IconBox, 7.12 layout pensato solo per il monitor) sono WARNING: se falliscono, il seeding tecnicamente passa ma l'UI sarà piatta — correggerli prima di chiudere per raggiungere il livello visivo di prodotto. Consulta `references/pattern-design-rich.md` per i 9 pattern obbligatori da applicare.

Aggiorna `seeding-state.md` con stato finale: ✓ Completato.

Comunica a Villa:
- Pagine generate (con path)
- Punteggio guardrail 9/9
- Link locale alla pagina `/dev/components-pattern` per ispezione visiva
- Prossimo passo: il runner Metodo Villa puo' ora estendere il frontend, mantenendo lo stile per coerenza implicita.

---

## Stato della skill: cosa è pronto e cosa è in costruzione

**Pronto**:
- `references/system-prompt-anti-piattezza.md` — documento stringente con regole VIETATO/OBBLIGATORIO/PRINCIPI + 9 guardrail deterministici (dark mode e responsivita incluse).
- `references/skin-default.css` (neutro slate) + `references/skin-senilcare.css` (esempio blu SenilWatch-style).
- `references/golden-pages/` — 5 pagine (login/dashboard/lista/dettaglio/gestione) + showcase `/dev/components-pattern`, già rese.
- `references/guardrail-web.sh` — i 9 check eseguibili (9/9 sulle golden pages, dark mode e responsivita incluse).
- `references/pattern-design-rich.md` — i 9 pattern di UI ricca.
- Manuale interno: `.claude/metodo-villa/17-design-web.md` (+ `16-design-core.md`).
- Workflow 7 fasi sopra documentato.

**Da costruire** (roadmap immediata):
- `references/template-starter-web/` — repo template scaffoldato (o repo separato GitHub). Non ancora pubblicato: per ora si scaffolda manualmente (Fase 3).

> Il **mobile** non fa più parte di questa skill: è coperto dalla skill sorella
> `seeding-visivo-mobile` (stack Flutter + Material), con i suoi temi, golden
> screens e guardrail dedicati.

**Banco di prova (validazione)**: applicare la skill **a SenilCure** rigenerando 1 pagina (es. Login) e confrontare la qualita visiva con il livello SenilWatch. È la validazione prevista dalla Fase 1 della roadmap (Blocco 1.10).

---

## Riferimenti

- **Manuale Metodo Villa**: `.claude/metodo-villa/` — manuale di stile web in `17-design-web.md`, cuore comune web+mobile in `16-design-core.md`.
- **Specifica di pattern**: `SenilCare/dominio/DESIGN-SYSTEM.md` (fonte di verita' dei pattern compositi e di pagina — 16 capitoli, 2063 righe).
- **System prompt anti-piattezza**: `references/system-prompt-anti-piattezza.md` (in questa cartella). v1.1 con sezione 5bis e guardrail 7.8-7.9.
- **Pattern design rich**: `references/pattern-design-rich.md` — i 9 pattern obbligatori per UI di prodotto (IconBox, HeroBanner, InfoBox, Card severity, Badge tinted, ombre semantiche, avatar colorato, tipografia bold, microinterazioni + KPI card). Validati su SenilCure 2026-05-25. Consultare SEMPRE quando si costruiscono pagine di prodotto con componenti in evidenza (dashboard, liste, dettagli).
- **Skill complementari**: `discovery` (per nuovi progetti, attiva `seeding-visivo-web` dopo l'analisi), `migrazione` (per progetti esistenti su Metodo Villa v2).

---

*Skill creata il 2026-05-24 in seguito alla discussione "perche Bolt/Lovable fanno UI bella e Claude Code no" + decisione strategica Villa di costruire un sistema interno al Metodo Villa che replica gli asset core di queste piattaforme (system prompt + stack opinato + pattern golden) senza dipendere da servizi esterni. Affinata sul caso reale SenilCure (riparazione frontend, 2026-05).*
