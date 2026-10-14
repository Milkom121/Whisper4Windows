# 29 — La caccia ai problemi

## Perche' esiste questo capitolo

Davanti a un difetto difficile succede sempre la stessa cosa: si legge il codice,
ci si convince di una spiegazione plausibile, si cambia qualcosa, si guarda se e'
passato. A volte funziona. Quando non funziona si cambia altro, e dopo un'ora non
si sa piu' cosa si e' provato ne' cosa si e' escluso.

Di notte e' peggio: il runner non ha nessuno a cui chiedere, e un blocco solo puo'
mangiarsi ore prima che il sorvegliante lo fermi (cap. 27).

Questo capitolo mette una disciplina al posto dell'istinto. Non e' teoria del
debug: sono le poche mosse che cambiano l'esito.

Il capitolo dice **cosa** e **perche'**. L'ordine delle mosse, da seguire mentre si
caccia, sta nella competenza `caccia-ai-problemi` (`.claude/skills/caccia-ai-problemi/SKILL.md`).

## Il tetto: quando questa disciplina si applica

**Solo ai problemi difficili.** Sono difficili i problemi che:

- ricompaiono dopo essere stati "riparati";
- nessuno sa spiegare («funziona sulla mia macchina»);
- non si sanno riprodurre a comando;
- coinvolgono piu' pezzi che da soli funzionano.

Su un problema che si vede a occhio — un nome sbagliato, un campo che manca, un
messaggio d'errore che dice esattamente cosa fare — **si ripara e basta**.
Costruire un comando rosso per un refuso e' burocrazia, e la burocrazia fa
disapplicare la regola anche quando servirebbe.

**E l'indagine non e' senza fondo.** Superati **tre giri di ipotesi** senza
restringere il campo, si smette: si scrive cosa si e' capito e soprattutto **cosa
si e' escluso**, si lascia il problema aperto con il suo comando rosso in eredita',
e si va avanti. Di notte questo evita che un blocco solo si mangi la corsa; di
giorno evita di girare a vuoto quando serve un'altra testa.

## La regola madre: prima il rosso, poi le idee

> **Niente ipotesi finche' non esiste un comando che va ROSSO su quel problema.**

Un comando che, lanciato adesso, fallisce **per il motivo giusto**. Finche' non
esiste, ogni ragionamento e' su un problema che non si e' ancora visto in faccia.

Se ti scopri a leggere il codice per costruire una teoria **prima** che quel
comando esista: fermati e costruisci il comando. E' il momento in cui quasi tutte
le cacce prendono la strada sbagliata.

Il motivo e' semplice: senza il rosso non sai quando hai finito. Con il rosso, la
fine e' un fatto — quel comando diventa verde — e non un'impressione.

### I dieci modi per costruire il rosso, in ordine

Si scende la lista e si prende il **primo** che funziona per quel problema:

1. **Un test che fallisce** — il migliore: resta nel progetto anche dopo.
2. **Una chiamata al servizio** (`curl` o simile) che risponde sbagliato.
3. **Un comando a riga di comando** che stampa il risultato, confrontato con
   quello atteso.
4. **Il browser pilotato** su un percorso corto.
5. **La riproduzione di una traccia registrata** (i dati veri di quando e'
   successo).
6. **Un banchetto di prova minimo**: un file a parte che monta solo i due pezzi
   sospetti.
7. **Mille input a caso** finche' uno rompe.
8. **La bisezione automatica** sulla storia del deposito (`git bisect`).
9. **Il confronto fra la versione vecchia e la nuova** sullo stesso ingresso.
10. **Uno script che guida un umano** a riprodurre (cap. 14, la procedura
    guidata) — **ultima spiaggia**: e' l'unico caso in cui il ciclo non e'
    automatico.

## Il ciclo va **stretto**

Un ciclo di verifica e' stretto quando ha tutte e tre queste cose:

| | Cosa vuol dire | Perche' conta |
|---|---|---|
| **Veloce** | secondi, non minuti | un ciclo lento fa provare due cose insieme, e allora non si sa quale ha funzionato |
| **Deterministico** | stesso verdetto ogni volta | un ciclo ballerino fa scambiare il caso per una scoperta |
| **A segnale netto** | verifica il **sintomo esatto**, non «non e' esploso» | altrimenti si festeggia una riparazione che non ha riparato |

Un ciclo ballerino da trenta secondi vale poco piu' di niente. Uno da due secondi
sempre uguale e' un superpotere: cambia il modo in cui si pensa al problema,
perche' provare costa quanto immaginare.

**Vale la pena spendere per stringerlo.** Dieci minuti per portare il ciclo da
trenta secondi a due sono dieci minuti che si ripagano alla quinta prova.

## Il problema che compare a volte

Con un difetto intermittente l'obiettivo **non e'** una riproduzione pulita: e'
**alzare il tasso**. Al 50% e' cacciabile; all'1% no, perche' ogni verifica dice
"forse".

Si alza il tasso mettendo sotto pressione la cosa che si sospetta: piu' richieste
insieme, macchina piu' lenta, dati piu' grandi, ripetere mille volte in ciclo,
togliere le attese. Quando il tasso e' salito abbastanza, il problema torna
cacciabile come tutti gli altri.

## Minimizzare

Con il rosso in mano, si **toglie un pezzo per volta** dalla riproduzione,
rilanciando ogni volta:

- se resta rosso, quel pezzo non c'entrava: e' fuori per sempre;
- se diventa verde, quel pezzo e' portante: torna dentro.

Si finisce quando ogni pezzo rimasto e' portante. Quella e' la forma piu' piccola
del problema, ed e' quasi sempre il punto in cui la causa si vede a occhio nudo.

## Le ipotesi si scrivono prima, e devono poter essere sbagliate

**Da tre a cinque ipotesi, scritte PRIMA di provarne una.**

Una ipotesi sola ancora il ragionamento alla prima idea plausibile: da li' in poi
si cerca conferma, non verita'. Con cinque sul tavolo si sceglie quale provare per
prima in base a quanto costa provarla, non a quanto ci si e' affezionati.

Ogni ipotesi porta la sua **previsione**: *«se e' questa, allora lanciando X
dovrei vedere Y»*. **Se non sai dire la previsione, non e' un'ipotesi: e' una
sensazione. Buttala.**

Poi si prova quella con il miglior rapporto fra quanto e' probabile e quanto costa
verificarla — e ogni verifica **elimina** qualcosa. Una caccia che va avanti senza
eliminare niente e' una caccia ferma, ed e' quella che il tetto dei tre giri
interrompe.

### Se c'e' Villa, la lista si mostra

Prima di provare, se Villa e' presente, si fa vedere la lista delle ipotesi.
Spesso la riordina in un secondo (*«abbiamo appena cambiato la terza»*) e fa
risparmiare mezz'ora. **Ma non ci si blocca ad aspettarlo**: se non c'e', si
procede e la lista finisce nel diario (cap. 12).

## Le tracce si etichettano, se no restano

Ogni traccia di debug aggiunta al codice porta **un'etichetta unica**, decisa
all'inizio della caccia:

```
[DEBUG-a4f2] valore in ingresso: ...
```

Cosi' la pulizia finale e' **una ricerca sola** invece di una perlustrazione a
memoria. Le tracce senza etichetta sopravvivono alla caccia, e sporcano il codice
per mesi.

**I segreti si nascondono prima di mostrare.** Quando si stampano comandi,
risposte o configurazioni, chiavi e parole d'ordine vanno sostituite (`<NASCOSTO>`).
Meglio ancora: il ciclo si costruisce leggendo le credenziali dalle variabili
d'ambiente, cosi' non finiscono mai in cio' che si mostra (cap. 05).

## Se e' lentezza, si misura prima

Per un problema di lentezza le tracce sono inutili: dicono che il codice e'
passato di li', non quanto e' costato.

Si prende una **misura di partenza**, poi si biseca — si dimezza il lavoro e si
guarda dove va il tempo. **Misura prima, aggiusta dopo**: quasi tutte le
ottimizzazioni fatte a intuito riparano un pezzo che pesava il 2%.

## Il caso in cui il risultato e' che non si puo' inchiodare

Trovata la causa, si mette un test di regressione perche' quel difetto non torni.
A volte **non esiste un punto giusto dove metterlo**: la logica e' sparsa in tre
posti, oppure sta dentro qualcosa che non si puo' chiamare da solo.

**Quello e' il risultato**, e va scritto: e' l'architettura che impedisce di
inchiodare il problema. Si registra fra le decisioni da rivedere
(`docs/diario/decisioni-da-rivedere.md`), si ripara comunque, e si va avanti.
Non si costruisce un'impalcatura per fare finta di avere un test.

## La lista di chiusura

Una caccia e' finita quando **tutte** queste sono vere:

- [ ] la riproduzione **non riproduce piu'**;
- [ ] il test di regressione c'e' ed e' verde (oppure e' scritto perche' non si
      puo' mettere — vedi sopra);
- [ ] **tutte** le tracce `[DEBUG-…]` sono state tolte (una ricerca sola);
- [ ] i banchetti di prova usa e getta sono buttati;
- [ ] **l'ipotesi che si e' rivelata giusta e' scritta nel messaggio del commit**,
      insieme a cosa e' stato escluso.

L'ultimo punto e' quello che si dimentica sempre ed e' quello che vale di piu': il
prossimo che tocca quel codice — fra sei mesi, magari un altro agente — trova
scritto **perche'** succedeva, non solo cosa e' cambiato.

## Dove si incastra col resto del Metodo

- **Cap. 04 (testing)**: il rosso migliore e' un test che fallisce, e resta nel
  progetto come test di regressione.
- **Cap. 05 (qualita e sicurezza)**: le tracce tolte e i segreti nascosti sono
  parte del guardiano di fine blocco.
- **Cap. 12 (autonomia del runner)**: senza Villa, la lista delle ipotesi e cio'
  che si e' escluso vanno nel diario delle decisioni da rivedere.
- **Cap. 24 (guardiano degli stop)** e **cap. 27 (sorvegliante)**: quando il tetto
  dei tre giri scatta, il blocco si chiude dichiarando cosa resta aperto — non si
  lascia morire la sessione per esaurimento del tempo.
- **Cap. 13 (plugin esterni)**: il plugin `systematic-debugging` copre lo stesso
  terreno, ma va installato a mano e quasi mai lo e'. Questo capitolo vale sempre,
  perche' viaggia col Metodo.
