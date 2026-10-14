# 21 — Corsie parallele

## Perche' esiste questo capitolo

Il runner esegue **un blocco alla volta**. E' la scelta giusta quasi
sempre: dopo ogni blocco il progetto e' intero, i test sono verdi, e si
sa esattamente dove si e' arrivati.

Ma quando una fase e' grande e i suoi pezzi non si toccano davvero, la
sequenza diventa uno spreco: tre pezzi indipendenti aspettano il proprio
turno senza nessuna ragione tecnica.

Questo capitolo dice **quando** si puo' lavorare su piu' corsie in
parallelo, **a quali condizioni**, e **come** si rimette insieme il
lavoro senza rompere il progetto.

**Prima regola, sopra tutte le altre: il parallelo non e' il default.**
La sequenza e' piu' semplice, piu' sicura e piu' facile da seguire per
Villa. Si apre il parallelo solo quando le condizioni di questo capitolo
sono soddisfatte, e la decisione finale e' di Villa.

## La forma del lavoro: tronco, rami, riunione

Il parallelo non comincia al primo blocco. Ha sempre questa forma:

```
   TRONCO          si costruisce cio' che sta sotto tutti — IN SEQUENZA
     |
  ---+---
  |  |  |          RAMI: le corsie, ognuna sul suo tavolo
  |  |  |
  ---+---
     |
  RIUNIONE         si ricompone UNA CORSIA PER VOLTA, verificando
```

Il **tronco non e' una fase di sole decisioni**: contiene blocchi
eseguiti davvero. Se tre corsie useranno la stessa base dati, quella
base deve **esistere**, non essere stata concordata. Un accordo scritto
non compila.

## La domanda che apre (o chiude) il parallelo

Prima di aprire i rami, il pianificatore deve saper rispondere a una
domanda sola:

> **Cosa deve gia' esistere, e non cambiare piu', perche' N agenti
> possano lavorare senza mai parlarsi?**

Tutto cio' che rientra nella risposta e' **tronco**. Il resto e' **ramo**.

Se alla domanda non si sa rispondere, il parallelo non si apre: vuol
dire che la fase non e' abbastanza chiara, e il posto giusto per
scoprirlo e' la pianificazione, non la riunione finale.

## Le due specie di "comune"

Non tutto cio' che e' condiviso e' la stessa cosa. Vanno distinte,
perche' si congelano in modo diverso.

| | Cos'e' | Sta | Esempi | Come si congela |
|---|---|---|---|---|
| **Fondamenta** | Cio' su cui tutte le corsie poggiano | *sotto* tutte | schema dati, autenticazione, tema e token visivi, convenzioni di progetto, librerie interne condivise | esiste come **codice funzionante** prima di aprire i rami |
| **Confini** | Cio' che due corsie si scambiano | *tra* due corsie | forma delle richieste e risposte di una API, formato di un file, nomi e tipi dei campi | esiste come **documento esplicito** prima di aprire i rami |

I confini possono essere solo scritti (una corsia produce, l'altra
consuma, e finche' rispettano l'accordo non devono incontrarsi). Le
fondamenta no: devono essere costruite.

## La regola del congelamento

> **Durante il parallelo, tronco e confini sono in SOLA LETTURA.
> Nessuna corsia li modifica.**

Una corsia che scopre di aver bisogno di una modifica al tronco o a un
confine **si ferma** e lo dichiara: `STATUS: CHECKPOINT`, con scritto
cosa vorrebbe cambiare e perche'. Non decide da sola.

Il motivo non e' burocratico. Se una corsia cambia il comune per conto
suo, le altre continuano a lavorare su un'informazione **che non e' piu'
vera, e non lo sanno**. Il danno non si vede subito: emerge alla
riunione, quando ci hanno gia' costruito sopra.

Fermarsi costa un blocco. Cambiare di nascosto costa una fase.

**Questa regola vince sulle 6 regole di autonomia** del capitolo
`12-autonomia-runner.md`. In corsia, "il tronco non si tocca" non ammette
decisione autonoma, per quanto piccola e ovvia sembri la modifica.

## Quando si puo' dividere: le tre condizioni

Due blocchi possono stare in corsie diverse **solo se valgono tutte e
tre**:

1. **Nessun file in comune.** Le due corsie non scrivono mai lo stesso
   file. (Leggere lo stesso file va benissimo.)
2. **Nessuna dipendenza di risultato.** Nessuna delle due deve aspettare
   cio' che l'altra produce per poter cominciare o per poter verificare.
3. **Confini congelati.** Se si scambiano qualcosa, l'accordo e' gia'
   scritto e non cambia durante la corsa.

Se **anche una sola** manca, quei blocchi stanno nella stessa corsia.
Non si negozia: la condizione mancante e' esattamente il punto dove il
parallelo si rompera'.

## Quando NON conviene, anche se si potrebbe

Le tre condizioni dicono se e' **possibile**. Non dicono se e'
**vantaggioso**. Il parallelo si lascia perdere quando:

- **Le corsie sono piccole.** Sotto i **3 blocchi per corsia**, il costo
  di preparare, sorvegliare e riunire si mangia il guadagno. Si accorpa.
- **La fase e' esplorativa.** Se non si sa ancora quali file si
  toccheranno, la condizione 1 non e' verificabile: si va in sequenza.
- **Serve una risorsa locale unica — e nessuno l'ha ancora sdoppiata.**
  Un solo emulatore, un solo database di prova, una sola porta di
  anteprima. Due corsie che hanno bisogno della stessa risorsa unica
  **non sono indipendenti**, anche se i file sono diversi. Ma attenzione:
  questo e' uno **stato di fatto rimuovibile**, non una legge di natura.
  Quasi sempre si sdoppia — come si fa sta due sezioni piu' sotto.
- **Il guadagno atteso e' piccolo.** E' il motivo che chiude la questione
  piu' spesso di tutti gli altri messi insieme, ed e' un **conto**, non
  un'impressione: si fa per primo, e ha la sezione qui sotto.

## Il conto del guadagno — si fa per primo

Prima di chiedersi *se* si puo' dividere, si guarda **quanto si
guadagna**. Va fatto per primo perche', se il guadagno e' piccolo, tutto
il resto — sdoppiare le risorse, congelare i confini, sorvegliare tre
tavoli — e' lavoro buttato.

Il conto e' questo, e l'unita' di misura e' il blocco:

```
tempo in parallelo = tronco + corsia piu' lunga + riunione
guadagno           = blocchi della fase − tempo in parallelo
```

**Il tronco non si parallelizza.** E' la parte che sta sotto tutte le
corsie e si fa in sequenza, sempre. Dimenticarlo e' l'errore di conto
piu' comune: si guarda la corsia piu' lunga e ci si scorda di tutto cio'
che viene prima.

Caso vero, fase da **27 blocchi** di un progetto in corso:

| Voce | Blocchi |
|---|---|
| Tronco (si fa prima, in fila) | 8 |
| Corsia piu' lunga delle due | 10 |
| Riunione | 2 |
| **Totale in parallelo** | **20** |
| In fila | 27 |
| **Guadagno** | **7 blocchi — il 26%** |

Sette blocchi su ventisette, pagati con due tavoli da preparare, due
diari da seguire, un archivio di prova da sdoppiare e una riunione da
fare senza sbagliare. **Non ripaga.** Ed e' il caso normale, non
l'eccezione: appena il tronco e' grosso, o una corsia e' una **catena**
di blocchi che si aspettano l'un l'altro, il guadagno si sgonfia.

**Regola pratica: sotto il 30% di guadagno si va in fila.** Sopra, si
passa alle tre condizioni.

Il parallelo rende quando il tronco e' **piccolo** e le corsie sono
**lunghe e pari fra loro**: tre corsie da 8 blocchi con un tronco da 2
fanno 26 → 12, cioe' meno della meta'. Quella e' una fase che vale la
pena dividere.

## Le risorse uniche si tolgono di mezzo

Quasi ogni progetto serio ha almeno **una risorsa di prova condivisa**:
un database, un emulatore, una porta. Letta come un muro, il parallelo
non si apre mai in nessun progetto — e questo capitolo diventa una bella
teoria che non si applica.

Non e' un muro: e' una **precondizione da soddisfare**, e sta nel tronco.
Le tre vie, dalla piu' economica alla piu' cara:

| Via | Come si fa | Quando conviene |
|---|---|---|
| **Un archivio per corsia** | la connessione si sceglie gia' da configurazione: un file di ambiente per corsia, porte diverse | quasi sempre — e' la prima da provare |
| **Un prefisso per corsia** | ogni corsia marca i suoi dati di prova (`prova-a-`, `prova-b-`) e la pulizia di fine test cancella **solo i propri** | quando l'archivio non si sdoppia facilmente |
| **Archivio usa e getta** | nasce e muore con la suite di test (un contenitore per esecuzione) | quando le prime due non bastano, o si vuole chiudere la questione per sempre |

Tre avvertenze, tutte imparate rompendosi:

- **Si fa PRIMA di aprire le corsie, ed e' tronco.** E' esattamente cio'
  che deve gia' esistere e non cambiare piu'.
- **Si fa per ogni modulo coinvolto**, non una volta sola. Un progetto
  con otto moduli ha otto suite di test: sdoppiarne una non serve a
  niente se le altre continuano a pestarsi.
- **Guarda la pulizia di fine test.** Il caso classico: la suite cancella
  *tutti* i dati che cominciano per «prova», non solo i suoi. Due corsie
  si cancellano i dati a vicenda mentre lavorano, e il guasto si presenta
  come **test rosso a caso** — si cerca il difetto nel codice, che e' il
  posto sbagliato.

E la cosa che conta piu' di tutte: **si fa solo se il conto del guadagno
lo giustifica.** Sdoppiare gli archivi per risparmiare il 26% di una fase
e' lavoro speso male.

## L'etichetta di corsia nella roadmap

Ogni blocco porta gia' l'etichetta di **natura** (🤖 / 👤 / 🤝, capitolo
`14-sequencing-blocchi.md`). Quando la fase e' parallela, porta anche
l'etichetta di **corsia**, fra doppie parentesi quadre:

```
## Fase 4 — Portale famiglie
> Corsie: [[TRONCO]] fondamenta · [[BE]] servizi · [[FE]] interfaccia · [[DOC]] manuali
> Confini congelati in: docs/fondamenta/confini-fase-4.md

- [x] **F4B1** Schema dati ospiti e parenti          🤖 [[TRONCO]]
- [x] **F4B2** Accesso e permessi                    🤖 [[TRONCO]]
- [x] **F4B3** Confini fra servizi e interfaccia     🤝 [[TRONCO]]
--- apertura corsie ---
- [ ] **F4B4** Servizi elenco e dettaglio ospite     🤖 [[BE]]
- [ ] **F4B5** Servizio notifiche ai parenti         🤖 [[BE]]
- [ ] **F4B6** Schermata elenco                      🤖 [[FE]]
- [ ] **F4B7** Schermata dettaglio                   🤖 [[FE]]
- [ ] **F4B8** Manuale per le famiglie               🤖 [[DOC]]
--- riunione ---
- [ ] **F4B9** Riunione corsie e verifica d'insieme  🤖 [[TRONCO]]
```

Regole di scrittura:

- La riga `--- apertura corsie ---` e' **obbligatoria**: e' li' che finisce
  il tronco e cominciano i rami. Senza, nessuno — ne' un agente ne' lo
  strumento — puo' sapere quali blocchi devono essere finiti prima di
  aprire le corsie. Lo strumento `metodo/metodo-corsie.sh` si rifiuta di
  aprirle se manca.
- I blocchi di **tronco** portano `[[TRONCO]]` e stanno **tutti prima**
  di quella riga. Unica eccezione: il **blocco di riunione**, che porta
  anch'esso `[[TRONCO]]` ma sta in fondo — per definizione non e' ancora
  fatto quando le corsie si aprono.
- La riga `--- riunione ---` e il blocco di riunione **non si omettono
  mai**. Una fase parallela senza blocco di riunione e' una fase
  incompleta.
- I nomi di corsia sono **brevi e maiuscoli**, dichiarati in cima alla
  fase. Non si inventano per blocco.

## Il diario in parallelo

Ogni corsia tiene il **suo** diario, in una cartella sua:

```
docs/diario/corsie/BE/handoff.md      docs/diario/corsie/BE/progress.json
docs/diario/corsie/FE/handoff.md      docs/diario/corsie/FE/progress.json
```

Cosi' due corsie non si sovrascrivono il punto in cui sono arrivate:
sono file diversi, il conflitto non puo' proprio esistere.

Il diario principale (`docs/diario/handoff.md`) **non si tocca durante il
parallelo**: si aggiorna alla riunione, con il quadro d'insieme.

## La riunione — una corsia per volta

Questa e' la parte dove si perde tutto se si va di fretta.

1. Si sceglie l'**ordine**: dalla corsia che ha toccato di piu' le zone
   comuni alla piu' periferica. La piu' invasiva per prima, cosi' le
   altre si adattano a lei e non il contrario.
2. Si unisce **una sola** corsia.
3. Si eseguono **tutti** i test del progetto, non solo quelli della
   corsia appena unita. Il senso della riunione e' proprio verificare
   cio' che nessuna corsia poteva verificare da sola.
4. Se e' rosso: **si aggiusta prima di unire la successiva.** Mai
   accumulare.
5. Solo quando e' verde si passa alla corsia dopo.

**Mai unire tutte le corsie insieme.** Se il risultato e' rotto non si sa
quale corsia l'ha rotto, e si finisce a smontare tutto.

Sui conflitti vale il capitolo `07-gestione-codice.md`: quelli sul
**codice** non si risolvono da soli, si descrivono a Villa. Sul diario non
possono esserci (file separati per costruzione). Sulla roadmap sono
attesi, riguardano righe diverse dello stesso elenco, e si risolvono
tenendo entrambe le marcature.

## Chi decide che cosa

| Decisione | Chi |
|---|---|
| Se la fase e' divisibile e in quante corsie | Il **Consiglio degli Agenti** propone, **Villa** approva |
| Cosa e' tronco e cosa e' ramo | Il **pianificatore**, rispondendo alla domanda di apertura |
| Congelare i confini | Blocco 🤝 in testa alla fase, con **Villa** |
| Fermarsi perche' serve toccare il tronco | L'**agente in corsia**, con `CHECKPOINT` — mai da solo |
| Ordine di riunione | Il **pianificatore** |
| Merge finale verso `develop` / `main` | **Villa** (capitoli 07 e 08) |

## Il Consiglio degli Agenti

Decidere se una fase si puo' dividere non e' un conto che si fa contando i
blocchi: due blocchi possono toccare gli stessi file senza che la roadmap
lo dica, e il titolo di un blocco non basta a saperlo. E' **giudizio** — e
il giudizio di uno solo, su questa domanda, vale poco: chi si mette a
cercare un modo di dividere lo trova sempre.

Per questo la proposta la fa un **organo**, non un agente:

| Membro | Incarico |
|---|---|
| **divisore** | trova il modo migliore di dividere, se esiste; guarda i file veri, non i titoli |
| **scettico** | parte dal presupposto che dividere sia sbagliato e cerca le prove: file contesi, dipendenze nascoste, risorse uniche. Distingue «impossibile» da «impossibile **finche'** non si prepara X» |
| **costruttore** | risponde alla domanda di apertura: cosa deve gia' esistere e cosa va congelato |
| **presidente** | non partecipa al dibattito: legge i tre pareri e tira le somme. In dubbio sceglie IN FILA |

**Le risposte possibili sono tre, non due**, e la differenza conta:

| Risposta | Vuol dire |
|---|---|
| **DIVIDERE** | si puo' aprire adesso: il guadagno c'e' e non manca niente |
| **DIVIDERE DOPO PREPARAZIONE** | il guadagno c'e', ma prima va tolto un ostacolo (tipicamente: sdoppiare l'archivio di prova). L'ostacolo diventa **tronco**, e si apre dopo |
| **IN FILA** | non conviene, o non si puo' — e non basta preparare qualcosa per cambiarlo |

Senza la risposta di mezzo, un ostacolo **rimuovibile** viene scritto
come se fosse un muro, e nessuno lo mette in discussione: il Consiglio
finisce per dire IN FILA quasi sempre.

Ogni parere dichiara anche il **guadagno atteso** con i numeri (blocchi
totali, tronco, corsia piu' lunga, riunione). Senza quel conto, dividere
o non dividere resta un'opinione — e la sezione "Il conto del guadagno"
dice perche' e' quasi sempre il numero a decidere.

Gli incarichi sono **in contrasto di proposito**: se tre agenti con
mandati opposti arrivano alla stessa conclusione, quella conclusione e'
solida. Se non ci arrivano, il disaccordo e' scritto nero su bianco nel
documento — ed e' l'informazione piu' utile che il Consiglio produce.

Si convoca con `./metodo/metodo-corsie.sh consiglio` (o dal menu di
`runner.bat`). Produce `docs/fondamenta/consiglio-agenti-fase-N.md`.

**Il Consiglio propone, non dispone**: non tocca la roadmap. Le etichette
`[[CORSIA]]` le mette Villa, se e' d'accordo. E' la stessa idea del
capitolo `15-validazione-multi-agente.md`, applicata alla decisione di
aprire le corsie.

## Anti-pattern

**1. Aprire le corsie senza tronco.**
Tre agenti si trovano davanti alla stessa mancanza (lo schema dati, il
tema, l'autenticazione) e ognuno se la inventa. Alla riunione ci sono tre
versioni diverse della stessa cosa e nessuna e' buttabile senza rifare il
lavoro di qualcun altro.

**2. La corsia che "si aggiusta" il confine.**
Il caso piu' comune e piu' costoso. La corsia servizi cambia il nome di
un campo perche' "era sbagliato". La corsia interfaccia continua per otto
blocchi a usare il nome vecchio. Si scopre alla riunione.

**3. Riunire tutto insieme alla fine.**
Verde, verde, verde... poi rosso. Con tre corsie unite in un colpo solo,
capire chi ha rotto cosa costa piu' del parallelo che si e' guadagnato.

**4. Corsie da un blocco.**
Preparare un tavolo, un quaderno e un ramo per un blocco solo e' puro
costo. Sotto i 3 blocchi si accorpa.

## Rapporto con gli altri capitoli

- `10-sizing-blocchi.md` — il sizing non cambia: un blocco resta **una
  modifica con una sola verifica**, anche dentro una corsia.
- `14-sequencing-blocchi.md` — la regola resta: i blocchi 👤 e 🤝 stanno in
  testa o in coda. Dentro una corsia, un blocco 👤 la ferma tutta (le
  altre proseguono).
- `12-autonomia-runner.md` — le 6 regole di autonomia valgono, **tranne**
  sul tronco e sui confini, dove non c'e' autonomia (vedi
  "La regola del congelamento").
- `07-gestione-codice.md` — ogni corsia lavora sul suo ramo; i conflitti
  di codice restano di Villa.

## Se un parere del Consiglio non arriva (2026-08-12)

Il messaggio adesso dice **perche'**: l'errore dell'agente, oppure che e' finito il tempo.
Un «non pervenuto» secco non si poteva rimediare.

Due cose da sapere, imparate rompendosi:

- **Il parere e' TESTO.** L'agente restituisce la risposta dentro un oggetto (serve al
  contatore, cap. 23): `raccogli_testo_agente` ne estrae il contenuto. Senza quel passaggio
  nel file finiva la scatola invece del parere — e siccome quell'oggetto arriva tutto insieme
  alla fine, un membro interrotto lasciava il file **vuoto**, mentre col testo che arrivava
  man mano restava almeno un parere monco. Da qui il difetto che sembrava capriccioso: un
  parere su tre mancante, ogni volta uno diverso.
- **Il tempo di attesa e' 25 minuti**, non piu' 10: su una fase grossa un membro deve leggerla
  tutta prima di poter dire qualcosa, e chi arrivava per ultimo veniva ucciso. Si allunga con
  `CONSIGLIO_TIMEOUT_MIN`.

Prove: `tests/test_consiglio_pareri.sh`.
