# 28 — L'indirizzario dei precedenti: non riscrivere cio' che esiste gia'

> Motore: `metodo/cerca-precedenti.py`. Dati: `.claude/precedenti/` (un file per progetto,
> formato nel README di quella cartella). Prova: `tests/test_cerca_precedenti.sh`.

## Il problema, e cosa NON e'

Villa ha una ventina di progetti. Le stesse cose sono state risolte piu' volte: l'accesso con
i ruoli, le notifiche che salgono di livello, il registro immodificabile, il modello a piu'
clienti sullo stesso impianto. Ogni volta si riparte da zero.

La tentazione e' costruire **un archivio di componenti riusabili**. E' una delle idee piu'
vecchie e piu' fallite del mestiere, per tre motivi che valgono ancora:

1. **Rendere un pezzo riusabile costa circa tre volte scriverlo per un caso solo.** Con un
   agente che scrive, riscrivere da zero e' quasi gratis; generalizzare, versionare e
   mantenere no — quel costo e' rimasto identico. Il conto e' peggiorato, non migliorato.
2. **Un archivio di codice copiato diverge dal giorno dopo.** Lo stesso pezzo in N progetti
   piu' una copia nell'archivio, e nessuno che sa quale sia quella buona. E' lo stesso
   problema che il capitolo 19 ha dovuto risolvere per il Metodo, ma sul codice, dove e'
   molto peggio.
3. **Quasi tutto quello che un archivio del genere scriverebbe, l'agente lo capisce da solo**
   guardando il codice — e lo capisce meglio, perche' legge la versione di oggi.

## Cosa l'agente non puo' capire da solo

Tre cose, e non e' questione di quanto sia bravo:

- **Che un altro progetto esiste.** Chi lavora dentro Foodlet vede Foodlet. Che a due
  cartelle di distanza ci sia gia' un sistema di notifiche con scalata non e' deducibile:
  manca l'indirizzo, non l'intelligenza.
- **Dove guardare senza aprirne venti.** Anche sapendo di dover cercare, leggere venti
  progetti costa piu' che riscrivere il pezzo. Una riga che porta al file giusto vale quanto
  tutta l'intelligenza che ci vorrebbe.
- **Com'e' andata davvero.** Se quel pezzo in produzione ha retto, o quali strade sono state
  provate e abbandonate. Il codice mostra il risultato finale, mai le strade scartate.

**L'indirizzario tiene solo queste tre cose.** E' un indirizzario, non un archivio: la
differenza non e' di stile, e' quella che lo tiene vivo. Cio' che non descrive il codice non
puo' invecchiare male, e una scheda vecchia sarebbe peggio di nessuna scheda — farebbe
costruire sopra una cosa falsa.

## Le regole

1. **Un file per progetto** in `.claude/precedenti/`, cinque colonne fisse: sigla · cosa e'
   gia' risolto · parole per cercarlo · dove · **esito sul campo**. Formato completo nel
   README della cartella.
2. **La colonna delle parole non e' decorazione.** Un agente non sfoglia, cerca: una voce
   senza sinonimi esiste ma non si trova.
3. **La colonna dell'esito e' quella che vale.** E' l'unica che dal codice non si ricava, e
   spesso la sa solo Villa. Vuota (`?`) la voce vale comunque: l'indirizzo c'e'.
4. **Si consulta prima di costruire, non dopo.** A cose scritte non serve piu' a niente.
5. **Una voce sbagliata si corregge o si toglie subito**, e si aggiorna la data di verifica.
   «Tanto e' solo un indirizzo» e' il modo in cui questi strumenti muoiono.

## Come arriva davanti all'agente

Vale la lezione del capitolo 25: **una regola si tiene in piedi con un innesco osservabile,
non con un'esortazione.** Due inneschi, uno buono e uno di riserva:

| Quando | Cosa succede |
|---|---|
| **Apertura di un blocco** (runner) | il titolo e la descrizione del blocco vengono cercati nell'indirizzario; se c'e' un riscontro, finisce nel messaggio del blocco. E' il momento **giusto**: si e' ancora in tempo a decidere di non riscrivere. |
| **Creazione di un file nuovo** (gancio) | se il nome del file somiglia a un precedente noto (`auth.ts`, `notifications/`), il richiamo arriva. E' **tardi ma non tardissimo**: la rete di sicurezza per la sessione live. |

Come tutti i ganci del Metodo: non blocca mai, e parla una volta sola per sessione e
argomento.

## Chi lo riempie

- **A fine blocco**, se il blocco ha costruito qualcosa che un altro progetto potrebbe
  volere: si aggiunge la riga. Lo chiede la chiusura di blocco.
- **Il primo riempimento** dei progetti gia' esistenti e' un lavoro a se': un blocco per
  progetto, gate «la scheda c'e' e la ricerca trova le sue voci».
### La riga si scrive da sola, il giro si lancia

Sono due cose diverse, e vale la pena tenerle distinte:

| | Chi lo fa | Quando |
|---|---|---|
| **Scrivere la riga** nel progetto dove la cosa e' nata | l'agente, da solo | a fine blocco, glielo chiede la `chiusura-blocco` |
| **Farla girare** fino agli altri progetti | un comando solo, dalla madre | quando si vuole: `metodo/metodo-precedenti.sh giro` |

`raccogli` prende da ogni progetto **la sua** scheda e la porta nella madre; `distribuisci`
copia l'indirizzario completo dentro ogni progetto che ha il Metodo; `giro` fa entrambe le
cose; `stato` dice soltanto cosa cambierebbe. Non tocca git: copia e riferisce, il commit lo
fa chi guarda. Salta le copie e gli archivi, chi si e' escluso col proprio
`.metodo-sync-ignore`, e i repository pubblici.

**Perche' qui il giro puo' essere automatico e nel capitolo 19 no.** Il rimando del Metodo e'
sorvegliato apposta: le regole cambiano il comportamento di tutti i progetti, e Villa le
approva una per una. Le schede no — sono **dati che si aggiungono**, non regole. Una riga in
piu' non fa fare niente di diverso a nessuno: dice solo dove guardare. E' questa differenza,
non la comodita', che rende legittimo l'automatismo.

Il perche' esista un comando dedicato invece di appoggiarsi al sync: con venti progetti,
«rimanda dal progetto e poi scarica negli altri diciannove» e' una cosa che nella pratica non
si fa mai. E' lo stesso meccanismo per cui sette progetti Senil hanno finito per avere
versioni diverse del Metodo.

> ## Nei progetti PUBBLICI l'indirizzario non entra
>
> Le schede non contengono codice, ma sono **la mappa di cosa c'e' dentro tutti gli altri
> progetti**, con i percorsi. In un repository pubblico quella mappa diventa pubblica anche
> per i progetti privati che descrive.
>
> **Prima di uno scarico su un progetto pubblico**, si mette `.claude/precedenti/` nel suo
> `.metodo-sync-ignore`. Il resto del Metodo continua ad arrivare normalmente: si esclude la
> mappa, non le regole.
>
> Caso reale al 2026-08-14: fra i progetti censiti, `Dydat_V1_2026` e' pubblico e tutti gli
> altri sono privati.

## Dove finisce, e cosa resta a mano

L'indirizzario dice **dove**. Non dice se conviene copiare: quello lo decide chi costruisce,
guardando il codice vero. E non sostituisce la libreria condivisa — quella ha senso solo dove
piu' progetti vivi condividono davvero lo stesso codice, cioe' dentro un monorepo
(`packages/` di SenilCare e di Big Mama Crew). Fra repository separati, il riuso passa dal
copiare con la testa, non dal dipendere.
