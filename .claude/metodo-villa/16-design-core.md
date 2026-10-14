# 16 — Design Core (cuore comune web + mobile)

> **Cosa contiene questo capitolo**: i principi e i pattern di design che valgono
> **per qualsiasi frontend Villa**, indipendentemente dalla piattaforma. È il
> "cuore comune" condiviso tra la skill `seeding-visivo-web` e la skill
> `seeding-visivo-mobile`.
>
> **Neutro rispetto allo stack**: qui non si parla di librerie, framework o
> linguaggi specifici. Si parla di *come deve apparire e comportarsi* un
> frontend curato. La traduzione tecnica vive nei capitoli specializzati:
> - **`17-design-web.md`** — come applicare questo cuore sul web.
> - **`18-design-mobile.md`** — come applicarlo su mobile.
>
> **Da dove è distillato**: dal system-prompt anti-piattezza della skill web,
> dal design system arricchito dell'ecosistema SenilCare, e dalle calibrazioni
> estetiche fatte dal vivo su prodotti reali (SenilWatch per il web; DOS
> Experience e BottegaLLM per il mobile).

---

## Perché esiste questo capitolo

Un agente AI, lasciato a sé, produce "la media dei layout visti in addestramento":
frontend tecnicamente corretti ma **piatti**. Il problema non è la bravura del
modello, è la mancanza di un riferimento concreto e severo da imitare.

Questo capitolo è quel riferimento, al livello più alto e più stabile: i principi
che non cambiano tra una pagina web e una schermata di telefono. Web e mobile
sono tecnicamente lontani, ma un buon prodotto Villa — sull'uno o sull'altro —
condivide la stessa **ossatura di gusto**. Quella ossatura è qui.

### La regola d'oro

> Tra una scelta "facile e bruttina" e una "stringente e bella", scegli **sempre**
> la seconda.

La qualità visiva è un prerequisito di prodotto, non un di-più. "Funziona" non
basta se è piatto.

---

## Principi universali

Dieci principi. Valgono identici su web e mobile. I capitoli specializzati dicono
*con quali strumenti* rispettarli; qui si dice *cosa* rispettare e *perché*.

### 1. Token semantici, mai valori grezzi

Ogni colore, ogni dimensione, ogni raggio di smusso vive come un **token** —
un nome che descrive la *funzione* ("colore primario", "superficie di sfondo",
"colore di pericolo"), non come un valore numerico sparso nel codice.

- **Perché**: un token si cambia in un posto solo e si propaga ovunque. Valori
  grezzi sparsi (un colore scritto a mano qui, un altro là) rendono impossibile
  mantenere coerenza e cambiare tema.
- **Regola pratica**: se in una schermata compare un colore o una misura scritti
  "a mano" invece di un token, è un errore da correggere.
- **Due temi, sempre**: i token reggono sia il tema **chiaro** sia il tema
  **scuro**. La **dark mode non è opzionale** — ogni prodotto Villa ha *sempre*
  anche il tema scuro, definito accanto al chiaro fin dall'inizio, non aggiunto
  "dopo". Sul web è verificata da un guardrail bloccante; sul mobile il tema
  dichiara entrambi (`lightTheme` + `darkTheme`).

### 2. Un solo accento primario, coerente

Il prodotto ha **un** colore d'accento (il colore della chiamata all'azione, del
"fai questo"). Uno solo, usato con disciplina.

- **Perché**: due accenti forti che competono confondono. Su DOS Experience, dal
  vivo, il verde del brand e il viola/magenta dei punti d'interesse si
  contendevano l'attenzione: l'occhio non sa dove guardare. La versione neutra
  impone un accento primario unico.
- **L'accento è solo per le azioni, mai per gli stati.** Lo stato (ok, attenzione,
  errore) ha i suoi colori dedicati (vedi principio 3). Mischiare accento e stato
  svuota di significato entrambi.

### 3. Severity/status coding sistematico

La **gravità** e lo **stato** si comunicano con il colore, sempre nello stesso
modo. "Severity coding" significa: codificare quanto una cosa è urgente/critica
con un colore costante in tutto il prodotto.

| Significato | Colore | Quando |
|-------------|--------|--------|
| Pericolo / errore / urgenza | rosso | scadenza superata, errore, allarme attivo |
| Attenzione / in attesa | ambra | non urgente ma da notare |
| Ok / successo / online | verde | completato in tempo, attivo, sano |
| Informazione neutra | cyan / azzurro | nota informativa, distinta dall'accento |
| Inattivo / irrilevante | grigio | disabilitato, secondario |

- **Perché**: se il rosso a volte vuol dire "errore" e a volte è solo decorazione,
  l'utente smette di fidarsi del colore. La costanza rende il colore *leggibile*.
- Questi colori di stato sono **diversi** dall'accento primario (principio 2).

### 4. Densità funzionale prima dello spazio decorativo

Lo spazio bianco serve la leggibilità, non l'estetica. Un prodotto operativo
(usato da chi lavora, ogni giorno) deve mostrare **tanto dato utile** senza far
scorrere a vuoto.

- **Perché**: chi usa il prodotto vuole vedere l'informazione, non incorniciarla.
  Una lista che mostra 12 righe dove ne starebbero 28 ha sprecato spazio.
- **Equilibrio**: denso non vuol dire ammassato. La densità si regge sulla
  gerarchia (principio 5), non sulla compressione cieca.

### 5. Gerarchia per superfici e contrasto, non per decorazione

La struttura visiva nasce da **livelli di superficie** (sfondo → superficie →
superficie in rilievo) e da **linee sottili** di separazione, non da ombre pesanti
o cornici vistose.

- **Perché**: pochi livelli di profondità ben distinti guidano l'occhio senza
  rumore. Le ombre profonde e gli effetti pesanti invecchiano male e appesantiscono.
- L'elevazione (ombra/rilievo) si usa con parsimonia e in modo coerente: serve a
  dire "questo galleggia sopra", non a fare scena.

### 6. Scala di spaziature coerente

Margini e spazi seguono una **scala** (tipicamente multipli di 4 o 8), non valori
improvvisati schermata per schermata.

- **Perché**: spazi coerenti = ritmo visivo. Spazi a caso (7 qui, 15 là) si
  notano come stonature anche da chi non sa spiegare perché.
- Vale anche per i raggi di smusso e per le dimensioni delle icone: pochi valori
  standard, applicati ovunque.

### 7. Tipografia con scala definita

Un solo carattere di qualità (caricato dal prodotto, **mai** un font di sistema
generico) e una **scala** di dimensioni con nomi di ruolo (titolo, sottotitolo,
corpo, didascalia), non misure a caso.

- I **numeri che si confrontano** in colonna (dati, importi, quantità, misure)
  usano cifre a **larghezza fissa** ("tabular"), così le colonne restano allineate.
- I titoli sono **decisi** (peso forte), non anonimi. Un titolo timido fa
  sembrare tutta la pagina timida.

### 8. Microinterazioni discrete, mai gratuite

Il prodotto reagisce al tocco e al passaggio: un cambio di sfondo, una leggera
compressione alla pressione, una transizione breve. Mai animazioni decorative.

- **Perché**: il feedback dice all'utente "ti ho sentito". Ma un'animazione che
  non comunica nulla distrae e fa sembrare il prodotto un giocattolo.
- Le transizioni sono **brevi e specifiche** (cambia il colore, non "tutto").
  Niente effetti rimbalzanti, niente parallax, niente video in autoplay.
- Su mobile il feedback include il **ritorno tattile** (vibrazione breve) sulle
  azioni importanti, usato con misura.

### 9. Accessibilità di base

Quattro minimi non negoziabili:

- **Contrasto sufficiente** tra testo e sfondo (standard WCAG). I testi secondari
  (orari, etichette, note) sono il punto debole tipico: vanno tenuti leggibili,
  non sbiaditi.
- **Stato di focus visibile** per chi naviga da tastiera o controllo esterno.
- **Bersagli toccabili abbastanza grandi** (linea guida ~44×44 punti) perché si
  colpiscano col dito senza errori.
- **Etichette per le icone** che stanno da sole, così chi usa lettori di schermo
  capisce cosa fanno.

### 10. Italiano e tono professionale

Tutto il testo visibile all'utente è in **italiano**. Il tono è professionale e
diretto.

- Niente paternalismi ("Sei sicuro di voler davvero...?"), niente esclamativi
  gratuiti, niente emoji nell'interfaccia di produzione.
- Gli errori sono **specifici** e dicono cosa fare ("Connessione assente: riprova
  tra poco"), mai generici ("Si è verificato un problema").
- Numeri concreti invece di vaghezze: "3 scadenze in ritardo", non "alcune
  scadenze".

---

## Pattern universali

Questi elementi compaiono — con la stessa **funzione** — sia sul web sia su mobile.
Cambia la *forma* per adattarsi alla piattaforma, non lo scopo. La conferma viene
dal vivo: gli stessi pattern si ritrovano in SenilWatch (web) e in DOS/BottegaLLM
(mobile).

| Pattern | Funzione | Forma sul web | Forma su mobile |
|---------|----------|---------------|------------------|
| **Brand mark** | far sapere "in che prodotto sono" | marchio in alto a sinistra, sempre presente | marchio nell'intestazione / splash |
| **Tile statistico (StatCard)** | un numero chiave in evidenza | riga di 4-6 tile in dashboard | riga di 2-3 tile in cima alla schermata |
| **Contenitore di stato** | raggruppare avvisi per gravità | "centro avvisi" in pagina | banner / scheda di stato |
| **Intestazione di sezione** | titolo + azioni della schermata | header di pagina | barra superiore (app bar) |
| **Card entità / riga** | un elemento di una collezione | card in griglia o riga di tabella | card in lista verticale |
| **Gruppo di azioni (CTA group)** | azione primaria + secondaria | bottoni affiancati | bottone pieno + azione testuale |
| **Empty state ricco** | spiegare una lista vuota | illustrazione + testo + azione | idem, adattato allo schermo |
| **Badge di stato** | etichetta di stato a colpo d'occhio | badge colorato tenue | badge / pill |
| **Icona in evidenza** | icona dentro un contenitore colorato | "icon box" nelle card chiave | idem |
| **Navigazione primaria** | spostarsi tra le aree | barra laterale (sidebar) | barra inferiore (bottom navigation) |

Due regole trasversali su questi pattern:

- **L'icona importante non va mai "nuda".** Quando un'icona ha un ruolo chiave
  (intestazione di una card statistica, voce attiva, stato vuoto), sta dentro un
  contenitore colorato coerente con la sua semantica.
- **La card con uno stato semantico lo mostra** (per esempio con un bordo colorato
  sul lato), ma **solo** se quello stato esiste davvero. Aggiungere colore a una
  card senza stato è rumore.

---

## UX di base: gli stati che non devono mai mancare

Una schermata non è "il caso in cui tutto va bene". Ogni vista che carica o mostra
dati prevede **sempre** questi stati:

1. **Caricamento** — un'attesa visibile e dignitosa (scheletro della pagina o
   indicatore), non una pagina bianca.
2. **Vuoto** — quando non c'è (ancora) nulla: spiega *perché* è vuoto e *cosa fare*
   per riempirlo. Mai un freddo "Nessun dato".
3. **Errore** — messaggio specifico + via d'uscita (riprova, torna indietro).
4. **Successo** — conferma breve e non invadente di un'azione andata a buon fine.
5. **Primo uso** — la prima volta merita un minimo di accompagnamento, non lo
   stesso schermo vuoto di sempre.

Trascurare questi stati è la causa più comune di un frontend che "sembra una demo".

---

## Anti-pattern: errori che la versione neutra deve prevenire

Questi difetti sono stati **osservati dal vivo** su prodotti reali. La dottrina
neutra esiste anche per evitarli:

- **Blocco di colore pieno troppo saturo e dominante.** Un contenitore critico
  tutto rosso pieno (visto su SenilWatch) o un banner tutto viola pieno (visto su
  DOS) si mangia la pagina. → Preferire **bordo + accenti** colorati su sfondo
  tenue, non il blocco pieno.
- **Testi secondari a basso contrasto.** Orari, etichette, note, riquadri d'aiuto
  resi troppo chiari. → Rispettare il contrasto (principio 9).
- **Due accenti che competono.** → Un solo accento primario (principio 2).
- **Empty state spogli.** → Empty state ricchi (sezione UX di base).
- **Icone chiave lasciate nude e titoli timidi.** → Icona in evidenza + titoli
  decisi (pattern universali, principio 7).

---

## Come web e mobile specializzano questo cuore

Questo capitolo dice il *cosa*. I capitoli specializzati dicono il *come*:

- **`17-design-web.md`** traduce questi principi nello stack web (token come
  variabili di tema, libreria di componenti standard, pattern di pagina come
  login/dashboard/lista/dettaglio/gestione).
- **`18-design-mobile.md`** li traduce nello stack mobile (tema centralizzato,
  libreria di componenti, pattern come barra superiore/inferiore, foglio
  inferiore scorrevole, feedback tattile).

La differenza tra le due è **la forma, non la sostanza**: sidebar contro barra
inferiore, pagina contro schermata, passaggio del mouse contro tocco. La sostanza
— densità, gerarchia, severity coding, un accento, stati curati, italiano — è
quella di questo capitolo, identica su entrambi.

---

## In sintesi (lista di controllo del cuore comune)

Un frontend Villa, web o mobile, rispetta tutti questi punti:

- [ ] Colori e misure sono **token**, non valori grezzi.
- [ ] Esistono **entrambi i temi**, chiaro e scuro: la dark mode è obbligatoria.
- [ ] C'è **un solo accento** primario; gli stati hanno colori propri.
- [ ] La gravità è codificata col **colore in modo costante** (severity coding).
- [ ] La schermata è **densa di dato utile**, con gerarchia chiara.
- [ ] Spaziature, raggi e dimensioni seguono una **scala**.
- [ ] Un **carattere di qualità** con scala tipografica; numeri tabulari per i dati.
- [ ] **Microinterazioni discrete** con feedback; niente decorazione gratuita.
- [ ] Contrasto, focus, bersagli toccabili ed etichette: **accessibilità di base**.
- [ ] Testo in **italiano**, tono professionale, errori specifici.
- [ ] Gli **stati** (caricamento, vuoto, errore, successo, primo uso) ci sono tutti.
- [ ] Nessuno degli **anti-pattern** osservati dal vivo è presente.
