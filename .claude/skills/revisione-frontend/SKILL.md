---
name: revisione-frontend
description: "Skill DIRETTORE DEI LAVORI per rimettere a posto il frontend di un progetto GIA' AVVIATO, su tutti i fronti insieme: come funziona (percorsi e schermate), come appare (stile e coerenza), come e' disposto (layout e densita') e se si vede bene sul telefono (responsivita'). NON rifa' il lavoro delle skill specialiste: fa UN SOLO sopralluogo, produce UN SOLO quadro in numeri e UN SOLO piano ordinato per valore, poi CHIAMA le skill giuste per eseguire (`progettazione-ux` modalita' C per i percorsi, `seeding-visivo-web`/`seeding-visivo-mobile` caso riparazione per l'estetica, `collaudo-guidato` per il giro con l'umano). Usa questa skill quando si menziona: sistemare il frontend di un progetto avviato, rimettere a posto l'interfaccia, rivedere UX e grafica insieme, il frontend e' da rifare, l'app e' brutta e confusa, redesign completo, restyling di un prodotto esistente, non si vede bene sul telefono, l'interfaccia e' incoerente, va sistemata l'esperienza e anche l'estetica. E' il punto d'ingresso UNICO quando il problema del frontend e' su piu' fronti insieme e non si sa da dove cominciare. Se il problema e' su UN SOLO fronte, si va diretti alla skill specialista. English triggers: frontend overhaul, full UI/UX revamp of an existing project, redesign existing app, fix the whole frontend."
user-invocable: true
---

# Revisione del frontend — il direttore dei lavori

Rimettere a posto il frontend di un progetto **gia' avviato**, su tutti i fronti insieme.

> **Il principio di questa skill: coordina, non duplica.**
> Le competenze esistono gia' nel Metodo, sparse in tre skill specialiste. Il problema che
> questa skill risolve non e' "manca la funzione", e' che **le tre non si parlano**: ognuna fa
> il suo sopralluogo, ognuna produce il suo piano, e nessuno decide l'ordine.
> Qui si fa **un sopralluogo solo**, si produce **un preventivo solo**, e poi **si chiamano gli
> specialisti**. Non si ricopia mai quello che loro sanno gia' fare: si rimanda a loro.

## Quando si attiva (e quando no)

**Si attiva** quando il frontend di un progetto avviato ha problemi **su piu' fronti insieme** e
non si sa da dove cominciare: percorsi confusi *e* stile incoerente, oppure «e' da rifare» detto
in generale.

**Non si attiva** — si va diretti allo specialista — quando il problema e' su **un fronte solo**:

| Il problema e' solo... | Vai diretto a |
|---|---|
| i percorsi, le schermate, cosa manca | `progettazione-ux` (modalita' C) |
| lo stile, i colori, la piattezza visiva | `seeding-visivo-web` / `-mobile` (caso riparazione) |
| «non so cosa non va, proviamolo» | `collaudo-guidato` |
| un frontend che **non esiste ancora** | `progettazione-ux` (A o B) poi seeding |

---

## Fase 1 — Sopralluogo unico (quattro fronti in una passata)

Si legge il codice del frontend **una volta sola** e si raccolgono i quattro fronti insieme.
Prima individua **tutte** le applicazioni del progetto: spesso ce n'e' piu' di una (l'app
principale + un pannello di amministrazione separato). Si rilevano tutte, tenendole distinte.

### Fronte 1 — Come funziona (esperienza)

Segui la procedura di rilievo della skill `progettazione-ux`, **modalita' C, passo C1**: elenco
delle schermate reali dal codice (rotte, `pages/`, `screens/`), e per ognuna cosa fa, chi ci
arriva, e soprattutto **quali stati NON gestisce** (lista vuota, caricamento, errore, permesso
negato). Non riscrivere qui quella procedura: leggila da li'.

### Fronte 2 — Come appare (estetica e coerenza)

Verifica l'aderenza al design del Metodo (capitoli 16/17/18). Il modo veloce e' **eseguire i
guardrail** della skill di seeding sul codice reale del progetto:

- Web: `.claude/skills/seeding-visivo-web/references/guardrail-web.sh <percorso-src>`
- Mobile: `.claude/skills/seeding-visivo-mobile/references/guardrail-flutter.sh <percorso>`

Registra il punteggio e **quali check falliscono**: dicono in modo oggettivo dove il frontend si
discosta (colori grezzi invece dei token del tema, carattere sbagliato, tema scuro assente…).

### Fronte 3 — Com'e' disposto (layout e densita')

Qui il giudizio e' umano, ma le domande sono fisse. Per le schermate principali:

- La **gerarchia** e' leggibile? Si capisce a colpo d'occhio qual e' la cosa importante?
- La **densita'** e' giusta? (Un prodotto operativo mostra tanto dato utile; una lista che mostra
  12 righe dove ne starebbero 28 spreca spazio — vedi cap. 16, principio 4.)
- C'e' **una sola azione principale** per schermata, o ce ne sono due che competono?
- Gli **spazi** seguono una scala coerente o sono improvvisati schermata per schermata?
- Ricorrono gli **anti-pattern** noti del cap. 16 (blocchi di colore pieno troppo saturi, testi
  secondari illeggibili, due accenti che competono, schermate vuote spoglie)?

### Fronte 4 — Si vede bene sul telefono? (responsivita')

**Il fronte che nessun'altra skill copre**, ed e' il difetto che l'agente non nota da solo:
legge il codice, non guarda lo schermo piccolo. Cerca queste **sonde concrete**:

**Web** (React/Tailwind):
- **Larghezze fisse** su contenitori di pagina (`w-[900px]`, `min-width: 1024px`, `width: 800px`):
  sotto quella soglia la pagina esce dallo schermo.
- **Griglie a colonne fisse** senza variante per schermo piccolo (`grid-cols-4` senza
  `sm:`/`md:`/`lg:` davanti).
- **Tabelle larghe** senza contenitore che scorre in orizzontale (`overflow-x-auto`): sul telefono
  la tabella taglia le colonne.
- **Barra laterale sempre visibile** che non si trasforma (in menu a scomparsa) sotto una certa
  larghezza.
- **Bersagli troppo piccoli** per il dito (linea guida: circa 44×44 punti).
- Segnale generale: **quante schermate usano i prefissi per schermo** (`sm:`, `md:`, `lg:`)? Se
  sono pochissime, il frontend e' stato pensato solo per il monitor.

**Mobile** (Flutter): traboccamenti di riga (`RenderFlex overflow`), misure fisse al posto delle
proporzionali, testi che non reggono l'ingrandimento del carattere di sistema.

**Se il prodotto e' avviabile**, la verifica migliore e' guardarlo davvero: apri le schermate
principali a larghezza telefono e annota cosa si rompe. Vale piu' di dieci deduzioni dal codice.

### Fronte 5 (facoltativo ma prezioso) — Cosa dice chi lo usa

Il codice dice cosa c'e', non cosa da' fastidio. Se il prodotto e' provabile, proponi a Villa un
giro guidato con la skill **`collaudo-guidato`** (lui prova, tu guidi a parole e raccogli i
rilievi). Se in `docs/` esiste gia' un documento di collaudo, **leggilo**: quei rilievi valgono
piu' di qualsiasi deduzione.

---

## Fase 2 — Il quadro in numeri (una schermata, non una relazione)

Villa deve capire la situazione **in trenta secondi**. Niente prosa: numeri.

```markdown
## Quadro — frontend di [Progetto]

Applicazioni rilevate: 2 (app principale, pannello gestore)
Schermate totali: 20

ESPERIENZA     8 vanno bene · 7 da completare · 3 da rifare · 2 da togliere
ESTETICA       guardrail 5/9 — falliscono: colori grezzi, tema scuro assente, carattere
LAYOUT         4 schermate con gerarchia confusa · 2 con doppia azione principale
TELEFONO       5 schermate inguardabili sotto i 768px (tabelle tagliate, barra laterale fissa)
STATI MANCANTI 12 schermate su 20 non gestiscono la lista vuota; 15 non gestiscono l'errore
```

Il verdetto per schermata usa le etichette della `progettazione-ux` modalita' C:
**TIENI / COMPLETA / RIFAI / UNISCI / TOGLI / MANCA**.

---

## Fase 3 — Il piano unico, ordinato per valore

Un solo elenco di lavori, **non tre**. L'ordine non e' l'ordine dei fronti: e' l'ordine della
convenienza — **prima cio' che costa poco e si vede molto**.

Ordine consigliato, salvo motivi contrari:

1. **Stati mancanti** sulle schermate piu' usate — lavoro piccolo, effetto immediato: e' cio' che
   toglie la sensazione di "prodotto fatto a meta'".
2. **Guardrail rossi** (token del tema, tema scuro, carattere) — spesso e' lavoro meccanico e
   rimette in riga la coerenza di tutto il prodotto in un colpo.
3. **Responsivita'** sulle schermate che si usano davvero in mobilita'.
4. **UNISCI / TOGLI** — semplificano e riducono il codice da mantenere.
5. **Layout** delle schermate con gerarchia confusa.
6. **RIFAI** — i piu' costosi, per ultimi.
7. **MANCA** — schermate nuove.

Con quest'ordine, **se il lavoro si ferma a meta' il prodotto e' comunque migliorato**. E' la
proprieta' piu' importante del piano.

**Freno al rifacimento facile** (vale come nella `progettazione-ux`): si **RIFA'** solo se il
problema e' **strutturale**; se mancano stati o rifiniture si **COMPLETA**. Buttare e rifare
tutto e' quasi sempre la scelta sbrigativa travestita da coraggiosa.

Il piano va scritto in **`docs/fondamenta/revisione-frontend.md`**, insieme al quadro.

---

## Fase 4 — Villa decide (🤝, non saltabile)

Rivedere il frontend di un prodotto avviato e' una **scelta di priorita'**: mentre si rivede, il
prodotto non avanza su altro. Presenta a Villa il quadro in numeri e la dimensione del lavoro, e
**lascia decidere a lui**:

- **tutto** il piano,
- **solo la prima parte** (tipicamente stati + guardrail + telefono: poco lavoro, molto effetto),
- **solo un'area** (es. il solo pannello di amministrazione),
- **piu' avanti** (e allora il documento resta li', pronto).

Se Villa non e' al computer, la domanda passa dal canale Telegram
(`./metodo/metodo-telegram.sh chiedi "..."`), risposta anche vocale; se non risponde entro il
tempo previsto ci si ferma pulito con `STATUS: CHECKPOINT`.

---

## Fase 5 — Esecuzione: chiama gli specialisti

Il direttore dei lavori **non esegue**: assegna. Traduci il piano approvato in blocchi di
roadmap (1 blocco = 1 verifica, etichette 🤖/👤/🤝, i 🤝 in testa) e per ognuno indica **quale
skill lo esegue**:

| Tipo di lavoro | Skill che esegue |
|---|---|
| Ridisegno di percorsi e schermate, stati mancanti | `progettazione-ux` (modalita' C) |
| Rifacimento visivo, token, tema, coerenza | `seeding-visivo-web` / `-mobile` (caso riparazione) |
| Verifica finale col prodotto vivo | `collaudo-guidato` |

**Regola di sicurezza ereditata dal seeding**: sui rifacimenti visivi **non si sovrascrive** il
frontend esistente. Si costruisce la versione nuova **accanto** a quella vecchia e si sostituisce
solo dopo l'approvazione di Villa. Vale anche qui.

---

## Cosa NON fare

- **Non ricopiare** dentro questa skill le procedure delle specialiste: si rimanda a loro. Due
  posti che dicono la stessa cosa, col tempo, divergono.
- **Non fare tre sopralluoghi** separati: la passata sul codice e' una sola.
- **Non produrre tre piani**: il valore di questa skill e' il piano unico.
- **Non partire a rifare** prima che Villa abbia deciso (Fase 4).
- **Non usarla** se il problema e' su un fronte solo: e' peso inutile, vai allo specialista.

## Lista di controllo prima di chiudere

- [ ] Rilevate **tutte** le applicazioni del progetto, non solo la principale.
- [ ] Quattro fronti coperti: esperienza, estetica (guardrail eseguiti davvero), layout, telefono.
- [ ] Quadro in numeri scritto, leggibile in trenta secondi.
- [ ] Piano **unico**, ordinato per valore, con la proprieta' "se ci si ferma a meta', il prodotto
      e' comunque migliorato".
- [ ] Ogni voce del piano dice **quale skill la esegue**.
- [ ] Villa ha deciso cosa fare e quanto (o e' stato messo un CHECKPOINT).
- [ ] `docs/fondamenta/revisione-frontend.md` scritto.

## Riferimenti

- `.claude/skills/progettazione-ux/SKILL.md` — modalita' C: rilievo dell'esperienza e verdetti
- `.claude/skills/seeding-visivo-web/SKILL.md` e `-mobile` — caso (b) riparazione, e i guardrail
- `.claude/skills/collaudo-guidato/SKILL.md` — il giro del prodotto vivo con l'umano
- `.claude/metodo-villa/16-design-core.md` — principi, anti-pattern, stati che non devono mancare
- `.claude/metodo-villa/20-progettazione-ux.md` — il capitolo della progettazione dell'esperienza
