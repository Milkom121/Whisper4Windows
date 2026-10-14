---
name: caccia-ai-problemi
description: "Skill operativa per CACCIARE UN DIFETTO DIFFICILE con metodo invece che a istinto: prima si costruisce un comando che va ROSSO su quel problema, poi si stringe il ciclo, si scrivono 3-5 ipotesi falsificabili con la loro previsione, si minimizza la riproduzione e si chiude con la lista (tracce tolte, test di regressione, ipotesi giusta nel messaggio del commit). Usa questa skill quando: un test fallisce e il perche' non e' ovvio, un difetto ricompare dopo essere stato riparato, qualcosa funziona 'a volte', un blocco e' fallito due volte di fila, «non riesco a capire perche'», «funziona sulla mia macchina», una lentezza inspiegabile, un difetto che nessuna prova aveva visto. NON serve per i problemi che si vedono a occhio (un refuso, un campo che manca, un errore che dice gia' cosa fare): li' si ripara e basta. Complementare a: `chiusura-blocco` (chiude il blocco quando la caccia e' finita) e `collaudo-guidato` (trova i difetti; questa li spiega). English triggers: systematic debugging, root cause hunt, flaky test investigation, reproduce before theorizing."
user-invocable: true
---

# Caccia ai problemi — la disciplina, applicata

Questa competenza esegue il capitolo
`.claude/metodo-villa/29-caccia-ai-problemi.md`. Il capitolo dice **cosa** e
**perche'**; qui c'e' l'ordine delle mosse.

## Prima domanda: e' un problema difficile?

| Se... | Allora |
|---|---|
| l'errore dice gia' cosa fare, il campo manca, il nome e' sbagliato | **ripara e basta.** Questa competenza non serve |
| ricompare dopo essere stato riparato, nessuno sa spiegarlo, non si riproduce a comando, coinvolge piu' pezzi che da soli funzionano | **caccia**, con l'ordine qui sotto |

Costruire un comando rosso per un refuso e' burocrazia, e la burocrazia fa
disapplicare la regola anche quando servirebbe.

## L'ordine delle mosse

### 1. Il rosso, prima di tutto

**Non leggere il codice per costruire una teoria.** Costruisci prima un comando
che, lanciato adesso, fallisce **per il motivo giusto**.

Scendi questa lista e prendi il primo che funziona: test che fallisce → chiamata
al servizio → comando che stampa e confronta → browser pilotato → traccia
registrata → banchetto minimo → mille input a caso → bisezione sulla storia →
confronto vecchia/nuova versione → script che guida un umano (ultima spiaggia).

Se dopo qualche tentativo il rosso non c'e': **quello e' gia' un risultato**.
Scrivi cosa hai provato e perche' non si riproduce, e portalo a chi decide.

### 2. Stringi il ciclo

Prima di usarlo venti volte, rendilo **veloce** (secondi), **deterministico**
(stesso verdetto ogni volta) e a **segnale netto** (verifica il sintomo esatto,
non «non e' esploso»). Dieci minuti spesi qui si ripagano alla quinta prova.

Se il problema **compare a volte**: non inseguire la riproduzione pulita, **alza
il tasso** (piu' richieste insieme, dati piu' grandi, ripetizione in ciclo, attese
tolte). Sotto il 50% non e' ancora cacciabile.

### 3. Scrivi le ipotesi PRIMA di provarne una

Da tre a cinque, ognuna con la sua **previsione**:

```
IPOTESI 1 — La sessione non viene svuotata al cambio utente.
  Previsione: entrando come B dopo A, la chiamata /api/miei-dati risponde
              con i dati di A anche a memoria del browser pulita.
IPOTESI 2 — ...
```

**Senza previsione non e' un'ipotesi, e' una sensazione: buttala.**

Poi provi quella col miglior rapporto fra quanto e' probabile e quanto costa
verificarla. Ogni verifica deve **eliminare** qualcosa: segna cosa hai escluso,
non solo cosa hai trovato.

**Se Villa e' presente, mostragli la lista prima di provare** — spesso la riordina
in un secondo e ti risparmia mezz'ora. Se non c'e', vai avanti e scrivila nel
diario.

### 4. Minimizza

Con il rosso in mano, togli un pezzo per volta e rilancia: se resta rosso quel
pezzo e' fuori per sempre, se diventa verde e' portante e torna dentro. Quando
tutto cio' che resta e' portante, la causa di solito si vede a occhio.

### 5. Il tetto: tre giri e si consegna

Se dopo **tre giri di ipotesi** non hai ristretto il campo, **fermati**. Scrivi:

- il comando rosso (che resta in eredita' a chi riprende);
- le ipotesi escluse, e come le hai escluse;
- cosa proveresti con piu' tempo o con un'altra testa.

Poi vai avanti. Una caccia che non elimina niente non migliora restandoci dentro,
e di notte un blocco solo non deve mangiarsi la corsa.

### 6. Chiudi con la lista

- [ ] la riproduzione **non riproduce piu'**;
- [ ] il test di regressione c'e' ed e' verde;
- [ ] **tutte** le tracce `[DEBUG-…]` tolte (le hai etichettate all'inizio: e' una
      ricerca sola);
- [ ] i banchetti usa e getta buttati;
- [ ] **l'ipotesi giusta nel messaggio del commit**, con cosa e' stato escluso.

## Le due regole che si dimenticano sempre

**Se non esiste un posto giusto dove mettere il test di regressione, quello E' il
risultato.** Vuol dire che la logica e' sparsa, o che quel pezzo non si puo'
chiamare da solo: e' l'architettura che impedisce di inchiodare il problema. Lo
scrivi in `docs/diario/decisioni-da-rivedere.md`, ripari lo stesso e vai avanti.
**Non** costruire un'impalcatura per fare finta di avere un test.

**I segreti si nascondono prima di mostrare.** Quando stampi comandi, risposte o
configurazioni, chiavi e parole d'ordine diventano `<NASCOSTO>`. Meglio ancora: il
ciclo legge le credenziali dall'ambiente, cosi' non entrano mai in cio' che mostri.

## Se e' lentezza

Le tracce non servono: dicono che il codice e' passato di li', non quanto e'
costato. Prendi una **misura di partenza**, poi dimezza il lavoro e guarda dove va
il tempo. Misura prima, aggiusta dopo: quasi tutte le ottimizzazioni a intuito
riparano un pezzo che pesava il 2%.

## Cosa lasci scritto

- Nel **commit**: l'ipotesi giusta e cosa e' stato escluso.
- Nel **diario del blocco** (`handoff.md`): se la caccia ha cambiato la stima del
  lavoro o ha lasciato qualcosa di aperto.
- In **`decisioni-da-rivedere.md`**: le scelte prese senza Villa, e il caso «non
  c'e' posto per il test di regressione».
