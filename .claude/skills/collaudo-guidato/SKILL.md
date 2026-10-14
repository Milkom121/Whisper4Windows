---
name: collaudo-guidato
description: "Skill per la fase di COLLAUDO post-sviluppo / pre-pilot: girare a fondo il prodotto vivo insieme all'umano, raccogliere i problemi che emergono (difetti + migliorie), diagnosticarli, classificarli e trasformarli in una roadmap eseguibile pronta per il runner. Principio cardine: l'UMANO esegue le azioni (tocca, clicca, naviga, manda screenshot) e Claude GUIDA a parole UNA task alla volta, NON pilota l'app al posto suo; MA Claude esegue da solo le VERIFICHE tecniche (legge il codice, interroga API/DB) e riferisce. Usa questa skill quando si menziona: collaudo guidato, collaudo mobile o web, raccolta feedback, test pre-pilot, giro dell'app segnando i problemi, 'proviamo l'app e annotiamo cosa non va', test esplorativo, collaudo di fine fase, verifica end-to-end con l'occhio umano. Da PROPORRE automaticamente a fine fase di sviluppo, prima del pilot. Complementare e distinta da: i test automatici (vedi 04-testing, livelli L1-L4, che verificano il codice in automatico), dalla skill discovery (requisiti PRIMA di sviluppare) e dalla chiusura-blocco (che chiude un singolo blocco di sviluppo). English triggers: guided QA, feedback collection, pre-pilot testing, exploratory testing, end-to-end manual testing."
user-invocable: true
---

# Collaudo guidato — raccolta test & feedback sul prodotto vivo

> Skill **v1**, distillata da una sessione reale ed efficace (collaudo pre-pilot
> di Big Mama Crew Planning, 2026-06-06). E' una **v1 da affinare sul campo**:
> dopo i prossimi uno-due collaudi reali, rivederla e correggere cio' che la
> pratica avra' mostrato. La **sorella** `collaudo-automatico` (la prova del lavoro,
> non presidiata) **esiste dal 2026-08-19**: li' l'agente percorre lavori interi
> decisi in anticipo e misura lo stato del sistema; qui l'umano esplora e nota.

## A cosa serve

Quando lo sviluppo ha prodotto qualcosa di provabile (un prodotto, o un suo
pezzo grosso), questa skill **conduce un giro di collaudo manuale esplorativo**
insieme a Villa, raccoglie tutto cio' che non va o si puo' migliorare, lo
diagnostica e lo classifica, e infine **trasforma i rilievi in una roadmap
eseguibile**, proponendo di lanciare il runner sui blocchi automatici.

I test automatici dicono "il codice fa quel che dice il test". Il collaudo
guidato dice **"l'uso reale rivela cose che i test non vedono"**: incoerenze di
UX, bug di sessione, dati irrealistici, comportamenti strani che solo l'occhio
umano nota mentre prova davvero.

## Quando attivarla (e quando no)

**SI'**, attivala quando:
- Villa chiede un collaudo / una raccolta feedback / un giro dell'app segnando i
  problemi (vedi i trigger nel frontmatter).
- Si e' chiusa una **fase** di sviluppo e si va verso il pilot: in questo caso
  **proponila tu**, anche se Villa non l'ha chiesta esplicitamente (vedi
  "Promemoria automatico a fine fase").

**NO**, non e' questa la skill:
- Per i **test automatici del codice** (unitari, integrazione, smoke, E2E): quelli
  sono i livelli L1-L4 del capitolo `04-testing.md`, eseguiti in automatico.
- Per raccogliere i **requisiti prima** di sviluppare: quella e' la skill
  `discovery`.
- Per **chiudere un singolo blocco** di sviluppo: quella e' `chiusura-blocco`.

## Dove sta nel ciclo di vita

```
discovery            → raccoglie i BISOGNI, prima di costruire
sviluppo + 04-testing → produce e verifica il CODICE in automatico (L1-L4)
collaudo-guidato     → raccoglie i DIFETTI dopo, con l'occhio umano, sul prodotto vivo
pilot                → mette il prodotto in mano al cliente
```

### Promemoria automatico a fine fase

Alla **chiusura di una fase** di sviluppo (lo stato `PHASE_COMPLETE` del Metodo,
quando una tappa grossa e' completa e ci si avvia verso il rilascio), **ricorda a
Villa** che conviene un collaudo guidato prima di mandare il prodotto al cliente.
E' un suggerimento, non un automatismo: il collaudo richiede Villa presente che
prova, quindi parte solo se lui vuole. Lo scopo del promemoria e' che il collaudo
non venga dimenticato proprio quando si va di fretta.

## Principio cardine — l'umano ESEGUE, Claude GUIDA e VERIFICA

Questo e' il cuore della skill, non negoziabile:

- **L'umano esegue** le azioni concrete (tocca, clicca, naviga, manda screenshot).
  Conosce il prodotto dal lato di chi lo usa, e il valore del collaudo sta proprio
  nel suo occhio.
- **Claude guida a parole**, UNA task alla volta. **NON** pilota l'emulatore o il
  web al posto dell'umano (niente clic automatici, niente `adb`, niente
  automazioni del browser): se Claude pilotasse l'app, si perderebbe l'occhio
  umano e la fiducia del decisore.
- **MA Claude esegue da solo le verifiche tecniche**: legge il codice, interroga
  l'API o il database, e riferisce l'esito in linguaggio umano. Serve a dare
  risposte **fondate**, non teoriche, quando l'umano chiede "ma questo funziona?"
  oppure quando un difetto e' invisibile a video (es. un dato che trapela tra
  utenti).

## Come si conduce — struttura rigida nel passo, libera nel percorso

Questa skill codifica **principi flessibili, non un copione rigido**. La regola e':

- **Rigido il ritmo del singolo passo.** Ogni task guidata ha sempre la stessa
  micro-struttura: (a) **cosa fare** (azione concreta), (b) **cosa aspettarsi**
  (risultato atteso), (c) **quante tappe restano** (orientamento). Poi si
  **attende l'evidenza** (screenshot/feedback) prima di procedere.
- **Libero il percorso.** Quando scendere nel codice, quando interrogare i dati,
  quando fare un test diagnostico, da quale area partire: si decide sul momento,
  adattandosi a cio' che emerge. Le fasi qui sotto sono un **arco tipico**, non
  una gabbia da seguire alla lettera.

## I principi operativi

1. **Una task alla volta, micro-struttura fissa.** Cosa fare / cosa aspettarsi /
   quante tappe restano. Poi attendere l'evidenza prima del passo successivo.
2. **Passi concreti, niente teoria.** "Tocca l'icona X in basso a destra", non
   spiegazioni astratte.
3. **Mostra il percorso.** All'inizio una lista numerata delle aree/tappe da
   girare; durante, il senso di "dove siamo / cosa abbiamo / quanto manca".
4. **Documento vivo dei rilievi**, con un **indice riepilogativo in cima** (ID,
   area, gravita', tipo). Si aggiorna man mano, non alla fine.
5. **Diagnosi prima dell'etichetta.** Se un comportamento e' ambiguo, fare un
   **test diagnostico mirato** (es. un refresh, un logout pulito, un cambio
   utente) per capire la causa PRIMA di assegnare la gravita'. Per i bug
   invisibili a video, scendere nel **codice** e dare la causa radice con
   riferimenti `file:riga`.
6. **Distinguere prodotto vs dati di test.** Molti "problemi" sono i **dati finti**
   di prova (nomi duplicati, record fantasma), non il codice. Separarli: il
   prodotto puo' essere giusto e i dati sbagliati.
7. **Confermare i rilievi non ovvi con l'umano.** Claude propone con
   **ragionamento + raccomandazione**; l'umano decide se registrare e come
   classificare. Le scelte di design restano all'umano.
8. **Cross-canale + proteggere le cose buone.** Se ci sono piu' canali (es. mobile
   e web), confrontarli: coerenza, sincronizzazione. Registrare anche cio' che e'
   **PROMOSSO** (funziona bene, da non rompere), non solo i difetti.
9. **Comunicazione per decisore non tecnico.** Linguaggio umano, ogni termine
   tecnico spiegato con un'analogia, frasi brevi, numeri/esempi. **Riassuntino** a
   fine messaggio (contesto / decisione / opzioni). E le domande, una alla volta
   (vedi la regola permanente del Metodo).
10. **Dal feedback all'azione.** A fine collaudo i rilievi non restano una lista:
    diventano una **roadmap eseguibile** (vedi sezione dedicata).

## Formato di un rilievo

Documento dei rilievi (es. `docs/collaudo-<contesto>.md`), con in cima una
tabella-indice `ID | Area | Sintesi | Gravita' | Tipo` + conteggi. Ogni rilievo:

```
### R<n> — <Area>: <titolo sintetico>
- Schermata / canale: <dove>
- Problema: <cosa non va, in concreto>
- Diagnosi (se fatta): <esito del test diagnostico>
- Causa (se trovata nel codice): <meccanismo + file:riga>
- Proposta / Fix: <cosa fare>
- Gravita': alta (blocca il pilot) / media (da fare prima) / bassa (nice-to-have)
- Tipo: MECCANICO (-> roadmap runner) | DESIGN (-> sessione UX dedicata)
- Notato da: <umano | Claude, confermato dall'umano>
```

## Il flusso (arco tipico, flessibile)

1. **Preparazione.** Leggi brief/stato/scope del prodotto; verifica che l'ambiente
   sia attivo e provabile; mostra a Villa il **piano numerato** delle aree da
   girare.
2. **Giro guidato.** Una task alla volta (cosa fare / cosa aspettarsi / quante
   restano); l'umano esegue e manda l'evidenza. Si attende prima di procedere.
3. **Rilevazione.** Per ogni problema: diagnosi -> classificazione (gravita' +
   meccanico/design) -> registrazione nel documento vivo (e aggiorna l'indice).
4. **Verifica tecnica autonoma.** Quando serve, Claude legge il codice o interroga
   API/DB per la causa radice, e la riferisce in linguaggio umano.
5. **Conferma con l'umano.** Per i casi non ovvi e per ogni scelta di design.
6. **Chiusura.** Consolida i rilievi, completa l'indice, e costruisci il ponte
   verso l'azione (sezione seguente).

## Dal collaudo alla roadmap — la chiusura

A fine collaudo, i rilievi vanno trasformati in lavoro concreto. Questo e' il
punto in cui la skill si aggancia al resto del Metodo, con **due regole ferme**:

**1. I blocchi della roadmap si scrivono a regola d'arte.** Non si buttano giu' a
caso: si applicano le regole di pianificazione del Metodo —
- ogni blocco = **una modifica coerente con UNA sola verifica** (cap.
  `10-sizing-blocchi.md`);
- ogni blocco **etichettato** per natura: 🤖 autonomo (lo fa il runner da solo),
  👤 umano (serve Villa o un tecnico presente), 🤝 collaborativo (sessione live
  con Claude che assiste — tipicamente le scelte di design);
- blocchi **ordinati** col sequencing giusto: i 👤 e 🤝 in testa o in coda, mai in
  mezzo a una sequenza autonoma (cap. `14-sequencing-blocchi.md`).

**2. Al runner solo i blocchi automatici.** Il runner (il sistema che esegue i
blocchi da solo, senza Villa presente) prende **solo i blocchi 🤖**. I rilievi di
**design** (🤝) e quelli che richiedono la presenza umana (👤) **non** vanno al
runner: si affrontano in sessione live con Villa. Separa quindi nettamente il
mucchio **meccanico** (-> runner) dal mucchio **design** (-> sessione UX
dedicata).

**Prima di lanciare il runner**, se la lista di blocchi e' **corposa**, conviene
una rilettura di controllo (la **validazione multi-agente** del cap.
`15-validazione-multi-agente.md`): piu' agenti freschi rileggono la roadmap a
contesto pulito, cosi' il runner non lavora per ore partendo da una base
sbagliata. Per liste piccole basta il giudizio dell'autore.

Infine **proponi a Villa di lanciare il runner** sui blocchi automatici. La
decisione di lanciarlo resta sua.

## Output della skill

- **Documento dei rilievi** classificato, con indice (es.
  `docs/collaudo-<contesto>.md`). E' anche ottimo materiale per il "diario di
  bordo" del progetto, se presente.
- **Blocchi di roadmap** derivati dai rilievi meccanici, dimensionati, etichettati
  e ordinati, pronti per il runner.
- **Brief dei punti di design** (i rilievi 🤝) per la sessione UX dedicata.

## Anti-pattern da evitare

- **Pilotare l'app al posto dell'umano** — si perde l'occhio umano e la fiducia
  del decisore. (Le verifiche tecniche nel codice/API, invece, falle tu.)
- **Spiegazioni teoriche** invece di passi concreti.
- **Etichettare la gravita' di un bug senza il test diagnostico** — rischio di
  sopra/sottostimare.
- **Confondere un problema di dati di test con un difetto di prodotto.**
- **Registrare senza classificare** (meccanico vs design) — i rilievi non
  diventano azione.
- **Buttare tutto al runner** — design e blocchi umani vanno gestiti con Villa,
  non dati in pasto al runner.
- **Gergo tecnico "nudo"** verso un decisore non tecnico.

## Confine con le altre risorse del Metodo

- `discovery`: requisiti **prima** dello sviluppo. Qui: difetti **dopo**, sul
  prodotto vivo.
- `04-testing` (L1-L4): verifica **automatica** del codice. Qui: collaudo
  **manuale esplorativo** con l'occhio umano.
- `chiusura-blocco`: chiude un **blocco** di sviluppo. Qui: chiude un **giro di
  collaudo** producendo rilievi + roadmap.
- `10-sizing-blocchi`, `14-sequencing-blocchi`, `15-validazione-multi-agente`: le
  regole di pianificazione che la chiusura del collaudo applica quando scrive la
  roadmap.

## Esempio reale da cui e' distillata

Sessione Big Mama Crew Planning, 2026-06-06 (mobile + web): **16 rilievi**
raccolti, classificati e indicizzati (1 grave, ~10 medi, ~5 minori; 15 meccanici,
1 design). Casi che illustrano i principi:
- **Messaggio chat duplicato**: diagnosi col refresh -> era solo come veniva
  disegnato a schermo, dati integri -> gravita' ridotta correttamente (principio 5).
- **Cambio utente che mostrava dati altrui**: bug di privacy invisibile a video,
  trovato scendendo nel codice (una "cache" di sessione non svuotata al logout)
  con `file:riga` e fix (principi 2/5/cardine).
- **Tre omonimi "Camille Durand"**: distinto come problema dei dati finti, non del
  prodotto; identita' reale risolta interrogando l'API (principi 6 e cardine).
- **Notifica di riassegnazione**: nata da una domanda dell'umano ("le arriva la
  notifica?"), verificata nel codice -> difetto del collegamento (principio
  cardine).
- **Flusso completo della task** (assegna -> esegui -> concludi + monitoraggio in
  tempo reale): promosso e registrato come "da non rompere" (principio 8).
- **Chiusura**: i rilievi sono diventati una fase della roadmap (blocchi
  etichettati, dimensionati, ordinati) pronta per il runner (principio 10).
