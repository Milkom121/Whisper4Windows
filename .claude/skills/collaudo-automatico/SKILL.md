---
name: collaudo-automatico
description: "Skill operativa per LA PROVA DEL LAVORO: il collaudo non presidiato che percorre LAVORI INTERI (piu' schermate, piu' ruoli, piu' momenti nel tempo) e misura se il lavoro e' finito guardando lo STATO DEL SISTEMA, non le schermate che si aprono. Si costruisce in tre stadi: rilievo del prodotto (cosa offre, chi lo usa e con quale VINCOLO, da quali pezzi e' fatto), piano dei lavori interi con tabella di copertura e dichiarazione di cio' che resta scoperto, e corsa che esegue un lavoro per blocco raccogliendo in quale GIUNTURA si e' rotto e perche'. Usa questa skill quando si menziona: prova del lavoro, collaudo automatico, collaudo non presidiato, percorsi end-to-end, flussi utente da provare, verifica prima della consegna o prima di ogni rilascio, «i test passano ma il prodotto non si riesce a usare», copertura dei flussi, test di regressione sui percorsi. Complementare e distinta da: i test L1-L4 (verificano che i PEZZI funzionino; questa che siano ATTACCATI), `collaudo-guidato` (li' l'umano esplora e nota, qui l'agente percorre lavori decisi in anticipo e misura), `caccia-ai-problemi` (quando un lavoro si rompe e il perche' non e' ovvio). English triggers: automated end-to-end QA, user journey testing, workflow coverage, pre-release verification."
user-invocable: true
---

# La prova del lavoro — collaudo per lavori interi

Esegue la sezione «La prova del lavoro» del cap. `04-testing.md`. Il capitolo dice
**cosa** e **perche'**; qui c'e' **come si fa**.

La forma di questa competenza non e' teorica: e' quella che ha retto sul campo la
notte del 2026-08-19 su Fedorius (73 lavori a piano, 21 diventati percorsi
eseguibili). Il rilievo di com'e' andata sta in
`docs/fondamenta/prova-del-lavoro-disegno.md`.

## Stadio 1 — Il rilievo: capire il prodotto

Produce `docs/collaudo/rilievo.md`. Quattro cose:

- **Cosa offre**, viste da fuori: le funzioni, **numerate** (`F1.1`, `F1.2`, …). La
  numerazione non e' burocrazia: senza, la copertura dello stadio 2 e' un'opinione.
- **Chi lo usa**: un ruolo per riga, e per ognuno **il suo vincolo**. Il modo piu'
  rapido di trovarlo: *«perche' questa persona smetterebbe di usare il prodotto?»*.
  Il nome non serve; il vincolo si'.
- **L'oggetto del dominio** attorno a cui ruota il lavoro (una pratica, un paziente,
  una commessa), preso dallo schema dei dati.
- **I pezzi**: schermate, porte di servizio, lavori di sfondo, avvisi, permessi.
  Serve allo stadio 2 per dire cosa resta scoperto.

**Fonti, in quest'ordine**: il codice (e' la verita'),
`docs/fondamenta/mappa-esperienza.md`, la discovery e il concept, lo schema dei
dati. **Cio' che non si ricava si dichiara ignoto, non si inventa.**

## Stadio 2 — Il piano dei lavori interi

Produce `docs/collaudo/piano.md`. Una tabella per gruppo, e ogni riga:

| # | Chi | Cosa si fa | Cosa ci si aspetta | Funzioni | Motore |
|---|---|---|---|---|---|
| 2.3 | il junior | carica un documento scansionato male | ogni fonte dice a che punto e' la lavorazione | F3.1 F3.2 | 🅶 |

- **Le due colonne centrali sono obbligatorie**: *cosa si fa* e *cosa ci si aspetta*.
  Insieme sono la regola «azione + esito osservabile».
- **La colonna delle funzioni** e' la copertura: in fondo al piano si contano quelle
  che **nessun lavoro tocca**, e si scrivono.
- **La colonna del motore** dice se quel lavoro chiama un modello a pagamento.
- **Il materiale e' vero**: documenti, dati, casi presi dal mondo, non inventati.
- **Le trappole si preparano** (o si trovano gia' nel materiale vero): due documenti
  che si contraddicono, un dato sbagliato dentro una pagina illeggibile, una domanda
  che spinge a una conclusione che nessuno ha scritto. Non provano che il prodotto
  faccia: provano che **non menta**.
- **In fondo, la sezione «cosa questo piano NON prova»**: carico, messa in servizio
  vera, tenuta nel tempo, e i lavori che si vedono solo con le mani.

**Elenco largo e sottile; si eseguono cinque lavori profondi prima di allargare.**
Il catalogo da sessanta flussi che nessuno esegue e' la prima trappola.

## Stadio 3 — La corsa

**Il piano diventa una fase di roadmap: un blocco 🤖 per lavoro intero.** Non serve
un secondo motore — il runner ha gia' stato, guardiano, diario e avvisi.

Ogni blocco:

- **Gate di uscita = il comando che esegue quel percorso**, e il verdetto guarda lo
  **stato del sistema** (il record c'e', ha lo stato giusto, l'avviso e' partito).
- ⚠️ **Prova al contrario obbligatoria**: si rompe di proposito la cosa sorvegliata,
  si guarda il rosso, si ripristina. Un percorso scritto da una macchina puo' passare
  senza controllare niente, e qui chi verifica e' chi ha costruito.
- ⚠️ **Freno sul motore a pagamento**: un percorso che chiama un modello porta la sua
  etichetta e resta **spento** finche' non lo si chiama per nome. Senza, una corsa
  notturna brucia denaro in silenzio.
- **Esecuzione mista**: l'interfaccia dove il ruolo tocca davvero, la porta di
  servizio per far avanzare il resto. Tutto dall'interfaccia e' lento e fragile;
  tutto dalle porte di servizio prova il motore e non il prodotto.

## Il limite, dichiarato prima e non scoperto dopo

Si automatizzano i lavori a **esito prevedibile**. I lavori che dipendono dal
**giudizio** — qualita' di un testo, tono, risposta a un caso ambiguo — **non si
automatizzano**: restano all'umano (collaudo guidato) o vanno a un giudice a parte.
Su Fedorius erano 24 su 73.

**Scrivilo nel piano.** Un collaudo che non lo dichiara fa credere di aver provato
il prodotto quando ha provato l'impalcatura.

## Le due cose che il progetto deve offrire

1. **Un ambiente di prova con dati propri** e un'identita' per ogni ruolo.
2. **Il controllo del tempo**: poter spostare l'orologio (dati che invecchiano,
   scadenze, avvisi a giorni di distanza). **Senza, i lavori che vivono nei giorni
   si dichiarano non coperti** — mai verdi per omissione.

Se mancano, si dice **prima** di cominciare: sono un blocco 👤 o un blocco tecnico,
non un dettaglio da scoprire a meta' corsa.

## Il tetto sui percorsi

Si scrivono percorsi **solo sulle giunture** (piu' schermate, piu' ruoli, piu'
momenti). **Mai un percorso per una schermata sola**: quello e' lavoro dei test L1.
Sessanta percorsi diventano un secondo prodotto da mantenere, e ogni schermata che
cambia ne rompe uno.

## Cosa produce

- **Il rilievo** e **il piano** (`docs/collaudo/`).
- **I rilievi dei guasti**: in quale **giuntura** si e' rotto, il passo esatto, la
  causa nel codice con `file:riga`.
- **Le considerazioni**: cio' che funziona ma non si riesce a usare col vincolo di
  quel ruolo (cinque minuti non bastano, sono nove tocchi per una cosa quotidiana).
- **Cosa non e' stato provato**, e perche'.
- Da li', **blocchi di roadmap** dimensionati ed etichettati — stessa chiusura del
  collaudo guidato.

## Anti-pattern

- **Il catalogo che nessuno esegue.** Largo e sottile, poi cinque profondi.
- **Flussi importati da un altro dominio.** Si scrivono contro il rilievo, che viene
  dal codice.
- **Un percorso per schermata.** Solo giunture.
- **Verde per omissione.** Cio' che non si e' potuto provare si dichiara.
- **Fidarsi di un percorso mai visto fallire.** Prova al contrario, sempre.
