# 20 — Progettazione dell'esperienza (UX): schermate e flussi

> **Cosa contiene questo capitolo**: il passaggio in cui, **prima** di costruire un
> frontend, si progetta l'esperienza — *quali* schermate servono, *come* si collegano,
> *cosa* contiene ognuna e *in quali stati* può trovarsi. Sta **tra** la `discovery`
> (che raccoglie i requisiti) e il seeding/costruzione (che li esegue).
>
> **Come si esegue**: questo capitolo dice *cosa* e *perché*. Il *come*, passo per passo,
> vive nella skill operativa **`.claude/skills/progettazione-ux/SKILL.md`** — che si attiva
> da sola al momento giusto e conduce entrambe le modalità (manuale e automatica).
>
> **Vale solo per i progetti con un frontend** (interfaccia utente). Per progetti senza
> UI (API, batch, CLI, libreria) si salta del tutto.

## Perché esiste (il buco che riempie)

Il Metodo, sul frontend, faceva bene due cose e ne saltava una:

- **Raccoglieva** i flussi critici (skill `discovery`), ma **a parole**, in un documento
  pensato per il cliente.
- **Eseguiva** schermate belle e coerenti nello stile (skill `seeding-visivo-*`).
- **Ma non aveva** un passaggio in cui si progetta, schermata per schermata, quali
  schermate servono, come si collegano, cosa contengono e in quali stati.

Conseguenza: costruendo il frontend a blocchi, ogni schermata nasceva bella **da sola**
ma l'insieme poteva risultare **scollegato** — navigazione che non tiene, stati (vuoto,
errore, caricamento) dimenticati, componenti incoerenti. Osservato dal vivo su un
progetto reale (una fase frontend di 23 blocchi autonomi senza disegno d'insieme). Questo
capitolo chiude quel buco.

## Cosa produce: `mappa-esperienza.md`

Un documento **leggero e scritto** (non disegnato), che l'agente costruisce e poi
*rilegge* mentre realizza le schermate. Quattro sezioni:

1. **Elenco delle schermate** — la lista piatta di tutte le schermate dell'app.
2. **Mappa di navigazione** — come si passa da una schermata all'altra (diagramma
   semplice, es. Mermaid, che Claude scrive nativamente) + il modello di navigazione
   (menu laterale? schede in basso? a livelli?).
3. **I flussi che contano** — solo i **2-4** percorsi utente più importanti, passo per
   passo (da dove entri → cosa tocchi → dove arrivi), con le biforcazioni segnate.
4. **Scheda per schermata** — una tabella, una riga per schermata:

   | Schermata | Da dove ci arrivi | Azione principale | Cosa mostra | Componenti | Stati | Dove ti porta |

La colonna **Stati** è **obbligatoria** (vuoto, in caricamento, errore, successo, primo
uso): è il punto dove l'AI lasciata sola sbaglia di più, costruendo solo il caso "tutto
va bene". Vedi anche `16-design-core.md`, sezione "gli stati che non devono mai mancare".

## Le due modalità (le sceglie Villa, progetto per progetto)

### A) Manuale (🤝 collaborativa)

Una schermata / un flusso alla volta, stile intervista (come la `discovery`): Claude fa
le domande chiave — da dove si entra, qual è l'azione principale, cosa si vede, quali
stati, dove si va — e **Villa risponde e decide**. In sessione live. Per quando Villa
vuole plasmare l'esperienza con le proprie mani (prodotto importante, visione precisa).

### B) Automatica (🤖 con revisione)

Claude ragiona su **tutti i dati del progetto** (requisiti, concept, funzionalità, ruoli
utente, schema dati) e si **immedesima nell'utente** per progettare **in autonomia**
l'intera mappa — schermate, navigazione, flussi, stati — in modo coerente, tutta in un
colpo. Produce `mappa-esperienza.md` completo.

Come si immedesima, in concreto (procedura, non "a naso"): per ogni **ruolo utente**
elenca i suoi **compiti** (cosa vuole fare, di cosa ha bisogno, cosa lo preoccupa), poi
**cammina** ogni compito passo per passo e da lì ricava le schermate e gli stati.

Le due modalità **si combinano**: bozza in automatico → rifinitura manuale dei soli punti
che contano.

### C) Revisione di un frontend che esiste già (🤖/🤝)

Quando il prodotto **ha già un frontend** e l'esperienza va rivista, non si ridisegna a
memoria: si parte dal **rilievo**. Questa modalità non sostituisce A e B — le **avvolge**:

1. **Rilievo** — si mappa ciò che esiste **leggendo il codice** (rotte, pagine, navigazione),
   annotando per ogni schermata cosa fa e soprattutto **quali stati NON gestisce**. Il codice è
   la verità, il ricordo no: ridisegnare a memoria fa dimenticare schermate che esistono.
   Fonte complementare preziosa: un giro guidato del prodotto vivo (skill `collaudo-guidato`),
   che dice cosa funziona male per chi lo usa — cosa che il codice non sa dire.
2. **Bersaglio** — si disegna la mappa di come *dovrebbe* essere, con A o B, partendo dai
   compiti degli utenti e **non** dalle schermate esistenti (altrimenti si eredita l'impianto
   sbagliato che si voleva cambiare).
3. **Verdetto per schermata** — una sola etichetta ciascuna: **TIENI / COMPLETA / RIFAI /
   UNISCI / TOGLI / MANCA**. Regola di misura: si **RIFÀ solo se il problema è strutturale**
   (percorso sbagliato, due azioni principali che competono); se mancano stati o rifiniture si
   **COMPLETA** — molto meno lavoro, e spesso è ciò che risolve la sensazione di "prodotto
   fatto male". Buttare e rifare tutto è quasi sempre la scelta sbrigativa travestita da
   coraggiosa.
4. **Piano di revisione** — ordinato **per valore**: prima i COMPLETA (poco lavoro, molto
   effetto), poi UNISCI/TOGLI (semplificano), poi i RIFAI (i più costosi), infine i MANCA. Con
   quest'ordine, se il lavoro si ferma a metà il prodotto è comunque migliorato.

Il piano diventa blocchi di roadmap. **La decisione è di Villa**: rivedere l'esperienza di un
prodotto già avviato è una scelta di priorità (mentre si rivede, il prodotto non avanza su
altro), quindi gli si presenta il quadro in numeri e decide lui se farla adesso, dopo, o solo
in parte. Si può applicare anche a **una sola area** (es. il solo pannello di amministrazione).

## La verifica di Villa: chiesta, non imposta — e passa dal canale Telegram

Finito il disegno (modalità automatica), Claude **chiede** a Villa: «Vuoi verificare la
mappa prima di costruire? sì / no». Se **sì**, la rivedono insieme; se **no**, si procede.
Il controllo c'è ma non è un peso obbligato.

Dove Villa non è al computer, la domanda passa dal **guardiano** sul canale Telegram
(vedi `metodo/.env.runner.example` e `metodo/metodo-telegram.*`): il runner **manda la
domanda** e **aspetta la risposta** di Villa — testo **o vocale** (il vocale è trascritto
in **locale**, nessun audio esce dal computer). Villa risponde dal telefono e il runner
prosegue senza che debba tornare al PC. Se non arriva risposta entro il tempo previsto
(`TELEGRAM_ATTESA_MAX`, di base 4 ore), il runner **si ferma pulito**, senza forzare nulla.

Motivo del passaggio: l'esperienza incarna decisioni che sono di **Villa** (cosa conta,
cosa è primario); l'automatico fa il lavoro pesante, ma la parola su "sono le schermate
giuste?" resta sua. Villa può comunque pre-autorizzare «vai avanti da solo» per un
progetto e ridurre la revisione al minimo.

## Dove si incastra nel Metodo

- **Dopo** la `discovery` (Fase 9: file di avvio) — che ha già dato funzionalità + flussi
  critici a parole.
- **Prima** del seeding visivo e della costruzione.
- **Alimenta**: (a) i blocchi frontend della `ROADMAP.md` (quali schermate, in che
  ordine), (b) il runner (ogni blocco frontend costruisce *contro* la mappa), (c) il
  seeding (che stila le schermate che la mappa ha già definito).

## Cosa NON è (i paletti anti-ingrasso)

Per non trasformare una cosa leggera in burocrazia da agenzia di design:

- **Niente** personas, mappe emotive del viaggio utente, card sorting.
- **Niente prova delle REGOLE**: qui si decide quali schermate servono e come si
  collegano. Se il dubbio e' su una **regola del mestiere** (quando una pratica si
  puo' chiudere, cosa succede se due documenti si contraddicono), quella si prova
  cliccandola: competenza `prototipo-cliccabile`.
- **Niente** disegni ad alta definizione fatti a mano: il "bello" lo fa già il seeding
  (l'AI *è* lo strumento di alta definizione).
- **Niente** processo Figma obbligatorio.
- Solo **bassa definizione, scritta, minima**. La cura di dettaglio cresce **solo** dove
  il percorso si biforca o dove "girano soldi".

## Sequencing (importante per il runner)

Questa fase è un **punto di decisione di Villa** (🤝, o 🤖 con revisione). Come tutti i
punti 🤝, va messa **in testa** alla fase frontend della roadmap — mai in mezzo a una
sequenza di blocchi autonomi — così il runner non si ferma a metà (vedi
`14-sequencing-blocchi.md`). I blocchi frontend successivi (🤖) costruiscono contro la
`mappa-esperienza.md`.

## In sintesi (lista di controllo)

- [ ] Il progetto ha un frontend → questa fase si fa (altrimenti si salta).
- [ ] Prodotta la `mappa-esperienza.md`: elenco schermate + navigazione + 2-4 flussi +
      tabella per-schermata.
- [ ] La colonna **Stati** è compilata per ogni schermata.
- [ ] Scelta la modalità (manuale 🤝 / automatica 🤖 + revisione).
- [ ] In automatica: Villa ha dato l'ok (di persona o via Telegram), oppure ha
      pre-autorizzato «vai avanti».
- [ ] La fase sta **in testa** alla fase frontend della roadmap (sequencing).
- [ ] I blocchi frontend costruiscono contro la mappa; il seeding la stila.
