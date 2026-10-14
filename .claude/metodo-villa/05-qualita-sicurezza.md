# Standard di Qualità e Sicurezza del Codice + Sicurezza di Sistema

## Regole preventive — come Claude deve scrivere il codice

### Sicurezza:

- Mai inserire credenziali, API key o segreti nel codice sorgente — usare variabili d'ambiente via `.env`. **ECCEZIONE**: in fase di sviluppo attivo è permesso per velocità, ma DEVE essere registrato nel file `docs/diario/dev-shortcuts.md`
- Sempre sanitizzare gli input dell'utente prima di processarli
- Sempre usare query parametrizzate per il database (mai concatenare stringhe SQL)
- Gestire autenticazione e autorizzazione in modo esplicito — mai assumere che il client sia affidabile
- Mai fidarsi dei dati che arrivano dal client/browser
- Validare i dati sia lato client che lato server

SQL injection: solo query parametrizzate, mai concatenazione stringhe.

Input Mai Fidato.

### Robustezza:

- Ogni funzione deve gestire i casi di errore (input nullo, rete assente, timeout, dati malformati)
- Funzioni corte e con un solo scopo
- Nomi di variabili e funzioni autoesplicativi (in inglese, come da convenzione)
- Nessuna duplicazione di codice — se una logica si ripete, estrarre in funzione riutilizzabile
- Gestione esplicita delle Promise/async con try-catch
- Placeholder espliciti per funzionalità non ancora implementate: signature + docstring + `raise NotImplementedError` (o equivalente nel linguaggio), mai implementazioni vuote silenziose

Signature + docstring + `raise NotImplementedError`, mai implementazioni vuote silenziose.

Mai `unwrap()` o `expect()` nel codice di produzione — usare `?` o match.

### Manutenibilità:

- Le funzioni dovrebbero tendenzialmente stare sotto le 50 righe. Se una funzione supera questa soglia, Claude deve valutare se è ragionevolmente spezzabile in sotto-funzioni. Se lo è, la spezza. Se non lo è (perché il flusso è intrinsecamente sequenziale e spezzarlo peggiorerebbe la leggibilità), la mantiene così ma aggiunge un commento che spiega perché la funzione è più lunga del normale.
- Separazione chiara tra logica, dati e interfaccia (vedi architettura a layer)
- Commenti in italiano che spiegano il "perché", non il "cosa"
- Struttura del codice coerente con il resto del progetto — leggere i file esistenti PRIMA di scrivere codice nuovo
- Se un file supera le 500 righe, valutare se spezzarlo (ma solo se fa parte del blocco corrente)

## L'occhio esterno — chi controlla il blocco non è chi l'ha fatto

Il guardiano di blocco qui sotto è **auto-review**: lo stesso agente che ha scritto il
codice, scritto le prove ed eseguito le prove si dà il verde. Su 1.468 blocchi eseguiti fra
SenilCare, Fedorium, BottegaLLM e la madre, è andata così **tutte le volte**. Poi su
Fedorium, dopo 394 blocchi tutti verdi, sei giri fatti a mano con Villa hanno trovato **148
difetti, 66 dei quali meccanici** — cose rotte, non questioni di gusto. Il capitolo 15 lo
diceva già («chi ha scritto l'artefatto è cieco ai propri errori») e poi esentava proprio il
blocco. L'occhio esterno toglie l'esenzione.

**Come funziona.** Quando un blocco si dichiara finito (CONTINUE o PHASE_COMPLETE), prima
del push e prima dell'avviso «blocco ok», il runner apre una sessione nuova che **non ha
costruito niente** e le dà tre cose sole: il compito scritto in roadmap, la tesi di chi ha
lavorato, e la differenza vera del blocco. Non il progetto: la differenza mediana di un
blocco è 337 righe (misurato su 150 commit veri di Fedorium).

**Quanto costa, misurato e non stimato.** Su una differenza vera di 372 righe, con Opus 5:
**$0,10 quando non trova niente, $0,29-0,32 quando trova qualcosa.** Contro un blocco che
costa in media $4,63 (Fedorium, Kimi K3) o $6,71 (SenilCare, Opus 5), sono **2-7% del costo
del blocco**. Su una corsa da 30 blocchi: **circa 3-9 dollari.** Provato anche con Sonnet 5
per spendere meno: **non spende meno** ($0,16-0,52 sugli stessi tre casi, perché scrive più
ragionamento). Resta Opus 5, che è anche il più sicuro.

**Cosa cerca, e nient'altro** — quattro cose falsificabili, tutte visibili nella differenza:

1. **Promessa non mantenuta** — il blocco prometteva qualcosa che non c'è.
2. **Prove indebolite** — una prova tolta, saltata, resa permissiva o riscritta perché
   passasse. È il difetto più grave: chi non riesce a far passare una prova può cambiare la
   prova invece del codice, e il verde arriva lo stesso. Da dentro non lo vede nessuno.
3. **Finta** — un valore fisso al posto di un calcolo, un ramo sempre vero, un segnaposto
   lasciato su una strada che il prodotto percorre davvero.
4. **Rottura visibile** — si chiama qualcosa che non esiste, o si cambia un patto e si
   lascia indietro chi lo usava.

**Non giudica** stile, nomi, eleganza, architettura, né cose che il blocco non prometteva:
quello fermerebbe la corsa per niente. **In dubbio passa**, e boccia solo indicando il punto.

**Cosa succede se boccia — si ripara, non si rifà.** Il lavoro fatto **non si butta**: il
commit resta, e se la sessione che ha lavorato è ancora viva e sotto il tetto della finestra,
l'obiezione le arriva **lì dentro**, dove l'agente ha già tutto in testa. Riceve un messaggio
corto: «c'è UN punto che non va, ripara quello e nient'altro». Solo se quella sessione non è
più utilizzabile si riapre da fuori. La casella in roadmap torna vuota (altrimenti il runner
rifiuterebbe di tornarci), il diario di sessione scrive `RIAPERTO` col motivo, e l'agente la
rimette lui quando ha finito.

L'agente può anche **rispondere che non era un difetto**: lo scrive alla voce `OCCHIO_ESTERNO`
dell'handoff e chiude lo stesso. Chi ha guardato aveva davanti solo la differenza e può
sbagliare — e un controllo che non ammette replica diventa un tiranno.

Si riapre **una volta sola**: alla seconda bocciatura decide il **guardiano** (cap. 24), che sa
anche chiedere a Villa. Massimo 3 riaperture per corsa.

**Non blocca mai la corsa per malfunzionamento proprio**: se non risponde, se manca il punto
di partenza o se il file non c'è, il blocco passa come prima. Meglio senza occhio esterno che
senza runner.

**Chi lo esegue**: sempre la testa (Opus 5), qualunque motore abbia la corsa — stessa regola
del guardiano e del Consiglio, per lo stesso motivo: nessun test controlla questa risposta.
La via economica è stata provata e misurata: non è economica (vedi sopra).

### Che cosa vede e che cosa NON vede — provato con differenze avvelenate apposta

Quattro casi costruiti su una differenza vera di un blocco di Fedorium:

| Caso | Verdetto | |
|---|---|---|
| Differenza sana | PASSA | ✅ nessun falso allarme |
| Una prova esistente ammorbidita (`assert x == "..."` → `is not None`) | NON PASSA | ✅ nomina la riga |
| Il valore atteso riscritto per combaciare con l'uscita sbagliata | NON PASSA | ✅ nomina la riga |
| Il codice che il gate chiedeva **non c'è affatto** (solo prove nel diff) | PASSA | ❌ **non lo vede** |

**Il limite è strutturale e va conosciuto**: l'occhio esterno vede la differenza, non il
progetto, quindi **non sa distinguere «non è stato fatto» da «c'era già prima»**. È il prezzo
di guardare 337 righe invece di tutto il repository — cioè il prezzo per cui il gate costa
il 5% invece del 100%. Quel buco lo copre la prova dei percorsi interi a fine fase (cap. 04),
che il prodotto lo fa girare davvero.

Quello che l'occhio esterno copre bene è la cosa che nessun altro copre: **il verde ottenuto
cambiando la prova invece del codice.**

**Si spegne** con `OCCHIO_ESTERNO=no` in `.env.runner`. Le altre manopole:
`OCCHIO_ESTERNO_MAX_RIGHE` (1200), `OCCHIO_ESTERNO_MAX_FERMATE` (3), `OCCHIO_ESTERNO_MINUTI` (5).

Motore: `metodo/metodo-occhio-esterno.sh`. Prove: `tests/test_occhio_esterno.sh`.

## Guardiano di blocco — due occhi, e non si fondono

Prima di chiudere ogni blocco si fa un'auto-review. Gli occhi sono **due**, e
guardano cose diverse. Sono **due occhi di chi ha costruito**: quello che guarda da fuori è
l'occhio esterno, qui sopra, e arriva dopo.

- **Primo occhio — lo standard**: il codice e' fatto bene?
- **Secondo occhio — la consegna**: fa quello che il blocco chiedeva, e cosa
  **in piu'** e' entrato?

**I due esiti restano separati e non si fondono mai.** Un riepilogo unico
(«blocco a posto») lascia che l'occhio verde copra quello rosso: e' proprio il
caso che si vuole vedere. Nel diario di fine blocco vanno due righe, una per
occhio, anche quando sono tutt'e due verdi.

### Primo occhio — lo standard

- [ ] Input sanitizzati dove necessario
- [ ] Errori gestiti (try-catch, error handling, fallback)
- [ ] Nessun segreto hardcoded non registrato in `docs/diario/dev-shortcuts.md`
- [ ] Funzioni tendenzialmente sotto le 50 righe (se superano, giustificato con commento)
- [ ] Nessuna duplicazione introdotta
- [ ] Nomi chiari e coerenti con il resto del progetto
- [ ] Nessuna traccia di debug rimasta (`[DEBUG-…]`, vedi cap. 29)
- [ ] **Se il blocco ha toccato l'interfaccia**: skill di seeding visivo attivata (`seeding-visivo-web` / `seeding-visivo-mobile`), token del tema al posto di valori grezzi, guardrail verdi, dark mode presente (vedi sez. 11quater del file operativo e cap. 16)

### Secondo occhio — ha fatto quello che il blocco chiedeva, e cosa c'e' in piu'?

Si rilegge il blocco della roadmap e si confronta con cio' che e' cambiato
davvero. Due domande:

1. **Manca qualcosa** di quello che il blocco chiedeva? Se si', il blocco non e'
   finito, punto.
2. **C'e' qualcosa in piu'** di quello che chiedeva? Se si', si elenca — file per
   file, in una riga l'uno.

⚠️ **Il secondo occhio DICHIARA, non boccia.** Uscire dal seminato e' una liberta'
regolabile (decisione di Villa del 2026-08-18): il livello in vigore dice quanto
si puo' uscire, questo occhio dice **cosa** e' uscito. Cio' che il livello permette
non viene respinto: viene **elencato**, e finisce nella riga di dichiarazione di
fine blocco.

### I tre livelli, e dove si scelgono

| Livello | Cosa puoi fare oltre al blocco |
|---|---|
| **stretto** | solo cio' che il blocco chiede; se trovi qualcosa di rotto lo **scrivi**, non lo ripari |
| **normale** *(default)* | aggiusti anche cio' che trovi **rotto** intorno |
| **largo** | migliori anche cio' che funziona ma e' scritto male |

Si fissa per progetto con `METODO_LIBERTA` in `.env.runner`, o per una corsa sola
con `--liberta`. **Sui blocchi di peso 🔴 cruciale si stringe da solo**: li' una cosa
in piu' non vista costa troppo.

**La dichiarazione e' accesa a tutti e tre i livelli**: a fine blocco il diario porta
la voce `OLTRE_IL_CHIESTO` («chiesto: X. Fatto: X, piu' A, B, C», oppure «nessuno»),
e cio' che e' in piu' va in un **commit separato** dentro lo stesso blocco — cosi'
domani si butta da solo senza toccare il resto. Senza la dichiarazione il livello
largo non sarebbe una liberta' ma una benda sugli occhi.

Respinge in un caso solo: quando cio' che e' in piu' **supera il livello in
vigore** — per esempio migliorie di comodo a livello `normale` (che permette di
aggiustare cio' che e' rotto, non di rifare cio' che funziona), o qualunque extra
su un blocco di peso 🔴. In quel caso l'extra si toglie, e il blocco chiude con
quello che era stato chiesto.

**Perche' due passaggi separati e non uno solo.** Fatti insieme, il secondo si
riduce a una riga di cortesia in fondo al primo: si sta gia' guardando il codice
con gli occhi di chi l'ha scritto, e cio' che e' entrato di troppo sembra sempre
sensato — l'ha appena deciso la stessa testa. Separandoli, la seconda domanda
arriva a mente sgombra, con la roadmap davanti invece del codice.

### La base minima dei difetti classici

Questi sono **giudizi, non violazioni**: si segnalano, si spiegano, e una regola
scritta del progetto vince sempre su questa lista.

| Difetto | Cos'e' | Come si aggiusta |
|---|---|---|
| **Nome misterioso** | il nome non dice cosa fa la cosa | si rinomina; se non sai come chiamarla, non hai ancora capito cosa fa |
| **Duplicazione** | la stessa logica in due posti | si estrae dove appartiene, non «da qualche parte in comune» |
| **Invidia di funzionalita'** | un pezzo usa i dati di un altro piu' dei propri | si sposta il pezzo dove stanno i dati |
| **Grappolo di dati** | gli stessi tre-quattro valori viaggiano sempre insieme | diventano una cosa sola, con un nome |
| **Ossessione dei tipi primitivi** | tutto e' testo o numero, anche cio' che ha regole sue | il concetto del dominio diventa un tipo suo |
| **Interruttori ripetuti** | lo stesso `if` sul tipo in cinque posti | il comportamento va dentro la cosa su cui si commuta |
| **Chirurgia col fucile** | un cambiamento piccolo tocca dieci file | cio' che cambia insieme si mette vicino |
| **Cambiamento divergente** | lo stesso file cambia per ragioni scollegate | si divide per ragione di cambiamento |
| **Generalita' speculativa** | astrazioni «per il futuro» che nessuno usa | si cancella: e' il contrario di codice pulito, ed e' gia' vietato dalle regole di Villa |
| **Catena di messaggi** | `a.b().c().d()` per arrivare al dato | si chiede la cosa a chi ce l'ha |
| **Intermediario inutile** | una classe che gira le chiamate e basta | si parla direttamente a chi lavora |
| **Eredita' rifiutata** | eredita cose che poi non usa o disattiva | si compone invece di ereditare |

La **generalita' speculativa** merita un'occhiata in piu': e' gia' vietata dalle
regole permanenti di Villa (astrazioni premature, livelli di indirezione «per il
futuro», generalizzazioni non richieste), ma finora nessuno la controllava.

Il risultato dei due occhi va nel diario di fine blocco. Se una voce non passa, si
scrive esplicitamente nell'handoff — non si nascondono i problemi.

## Guardiano di fase — review approfondita prima della PR su main

Prima della PR da `develop` verso `main`, Claude deve fare una review completa e strutturata:

- **Architettura**: il codice rispetta il design iniziale? I layer comunicano correttamente?
- **Sicurezza**: superficie di attacco, flussi di autenticazione, gestione dati sensibili, `docs/diario/dev-shortcuts.md` pulito
- **Coerenza**: il nuovo codice si integra bene col resto della codebase? Naming, stile, pattern rispettati?
- **Performance**: query N+1, memory leak, operazioni bloccanti sul thread principale
- **Usare `/security-review`** integrato in Claude Code (gratuito) per un'analisi automatizzata

Il report del guardiano di fase va nella PR come commento, in modo che Villa possa leggerlo prima di autorizzare il merge.

## Sicurezza di sistema — Non installare NULLA a livello di sistema

**Non installare NULLA a livello di sistema.** Tutto deve essere isolato e rimovibile cancellando una singola cartella.

### Cosa NON fare MAI (universale):

- NON fare `pip install` globali — usare sempre un venv locale
- NON modificare variabili d'ambiente di sistema (PATH, CUDA_HOME, ecc.)
- NON installare o aggiornare driver
- NON toccare il Python/Node/runtime di sistema
- NON installare pacchetti npm globali
- NON modificare il registry di Windows
- NON creare servizi Windows o task schedulati di sistema

### Cosa fare SEMPRE:

- Usare versioni portable/standalone quando possibile
- Tenere tutto dentro la cartella del progetto
- Se servono dipendenze, creare un venv locale dentro la repo
- Verificare i prerequisiti in modo **read-only** — solo controllare, mai modificare

Questa regola è eccellente e dovrebbe essere copiata verbatim nel Metodo Villa globale. Si applica a QUALSIASI progetto.

## Compressione contesto e sessioni lunghe

**Configurazione**: compressione automatica al 50% della context window.
Se il contesto si avvicina al limite, dare priorità al mantenere: il blocco corrente, i file modificati, i risultati dei test.

**IMPORTANT**: Quando compatti o il contesto viene compresso, preserva SEMPRE:
- Numero del blocco corrente e cosa stai facendo
- Lista dei file modificati/creati nella sessione
- Problemi aperti e decisioni prese con l'utente

**Regola unificata per la compattazione** — preservare SEMPRE:

1. Numero del blocco corrente e obiettivo
2. Lista dei file modificati/creati nella sessione
3. Risultati dei test (passano? falliscono? quali?)
4. Problemi aperti e decisioni prese con l'utente
5. Stack tecnologico e vincoli hard del progetto
