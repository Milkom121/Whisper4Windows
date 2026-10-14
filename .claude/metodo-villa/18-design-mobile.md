# 18 — Design Mobile (manuale di stile per lo stack mobile)

> **Cosa contiene questo capitolo**: il manuale di stile **operativo per il
> mobile** del Metodo Villa. È la traduzione concreta — token, tema, componenti,
> pattern di schermata — dei principi di gusto definiti nel cuore comune. Vale per
> **qualsiasi progetto mobile** di Villa (gestionale da campo, app di consultazione,
> strumento operativo, companion): è neutro rispetto al dominio (non parla di un
> settore specifico) ma **specifico per lo stack mobile**.
>
> **È la specializzazione mobile del 16-design-core**: il capitolo
> `16-design-core.md` dice *cosa* deve rispettare un frontend curato (densità,
> gerarchia, un solo accento, severity coding, stati curati, italiano). Questo
> capitolo dice *come* rispettarlo **con gli strumenti del mobile**. Dove un
> principio è già spiegato nel 16, qui non lo si ripete: lo si **applica**. Per i
> principi di fondo, `vedi 16-design-core.md`.
>
> **È il gemello del 17-design-web**: stessa ossatura, altra piattaforma. Il web
> usa il mouse, le pagine, la barra laterale; il mobile usa il dito, le schermate,
> la barra inferiore. La **sostanza** (densità, gerarchia, severità, un accento,
> stati curati) è identica; cambia la **forma**. Dove il web dice "CSS variables +
> Tailwind + shadcn", il mobile dice "tema centralizzato + Material + widget".
>
> **Da dove è distillato**: dal **comune** di due app Flutter reali e curate
> (un'app outdoor con palette "Alpine Clarity" e un'app gestionale con palette
> teal "Craftsman"), prendendo ciò che **entrambe** fanno bene — tema centralizzato,
> token, sotto-temi per ogni componente, scala tipografica — e **scartando** ciò
> che ciascuna ha di specifico (mappe e gamification da una, chat e comandi vocali
> dall'altra: finiscono nei "moduli opzionali", sez. 14). Le parti dove le due
> divergono sono state risolte prendendo la versione **più pulita** (per esempio:
> la scala di spaziature centralizzata, presente in una sola delle due, diventa
> regola). Sono incluse due **correzioni estetiche calibrate dal vivo** (vedi i
> riquadri "Correzione dal vivo" nelle sezioni Accento e Severity).
>
> **Glossario minimo** (per chi legge senza essere tecnico):
> - **Flutter**: il sistema con cui si costruiscono app per telefono (Android e
>   iPhone) con un solo codice. Non disegna "pagine" come il web: compone
>   **widget** (mattoncini visivi) uno dentro l'altro.
> - **Widget**: ogni elemento visivo in Flutter è un widget — un bottone, un testo,
>   una scheda, l'intera schermata. Si annidano come scatole cinesi.
> - **Material**: la libreria di componenti già pronti di Flutter (bottoni, schede,
>   barre, finestre), nello stile "Material Design" di Google. È lo standard solido
>   e universale: il Metodo lo adotta così com'è, vestito coi colori del progetto.
> - **Tema centralizzato (`ThemeData`)**: un unico posto dove si definiscono colori,
>   caratteri e stili di **tutti** i componenti. È l'equivalente mobile del foglio
>   di stile: si cambia lì e cambia tutta l'app. È il cuore di questo capitolo.
> - **`ColorScheme`**: la tavolozza semantica dentro al tema — "colore primario",
>   "colore di superficie", "colore d'errore" — con i nomi di funzione, non i valori.
> - **`google_fonts`**: il pacchetto che carica un carattere di qualità (Inter)
>   dal prodotto, invece di usare il carattere di sistema del telefono.
> - **`sizer`**: il pacchetto che adatta le misure alle dimensioni dello schermo
>   (un telefono piccolo e un tablet grande), così l'app non "esplode" o non resta
>   minuscola.

---

## 1. Stack mobile cementato

Ogni app mobile di Villa parte da **questo** stack. Non se ne propongono altri
salvo richiesta esplicita di Villa. La coerenza tra progetti vale più della
libertà di scelta sul singolo progetto.

| Livello | Tecnologia | A cosa serve (in parole povere) |
|---------|------------|----------------------------------|
| Framework | **Flutter** (SDK ≥ 3.6) | Il motore che costruisce l'app e la disegna su Android e iPhone con un solo codice |
| Linguaggio | **Dart** | Il linguaggio di Flutter |
| Componenti UI | **Material** (Material 3) | I mattoni dell'interfaccia già pronti, vestiti coi colori del progetto |
| Stile | **Tema centralizzato** (`ThemeData` light + dark) | Un solo posto per colori, caratteri e stili di tutti i componenti |
| Tipografia | **`google_fonts`** — **Inter** (testo e titoli) + carattere monospazio per i dati | Caratteri caricati dal prodotto, mai il font di sistema del telefono |
| Responsività | **`sizer`** | Adatta le misure a schermi piccoli e grandi |
| Icone | **Material Icons** (`Icons.*`) | Una sola famiglia di icone, coerente ovunque |
| Navigazione | **`Navigator`** Flutter (con eventuale router se il progetto cresce) | Gestisce il passaggio tra schermate |
| Stato | a discrezione del progetto (Provider / Riverpod / Bloc) | Tiene allineati dati e schermate; lo stack non lo impone, ma sia **uno solo** per progetto |

> **`useMaterial3: true` sempre.** Il tema dichiara esplicitamente Material 3:
> è lo standard attuale, con i token e i comportamenti moderni.

### 1.1 — forui: opzione futura, non standard

**forui** (una libreria di componenti alternativa per Flutter) **non** è adottata
come standard. Le due app reali da cui questo manuale è distillato usano entrambe
**Material + tema centralizzato**, e sono belle così: cementare forui sarebbe
incoerente con il materiale di partenza e una scommessa non validata. Material è
lo standard solido e universale di Flutter.

forui resta **documentata come opzione futura**: se un progetto la richiederà
esplicitamente, la si valuterà allora. Fino ad allora, **Material**.

**Da NON proporre**: Cupertino-only (lo stile iOS puro, che esclude Android),
React Native, altri toolkit cross-platform, o librerie di componenti di terze
parti al posto di Material. Lo stack è fisso.

> Per i progetti **web** lo stack è un altro (React): `vedi 17-design-web.md`.

---

## 2. Token e colori sul mobile (come si concretizza il principio dei token)

Il principio "token semantici, mai valori grezzi" (`vedi 16-design-core.md`,
principio 1) sul mobile si concretizza così:

- Tutti i colori vivono come **token nel tema centralizzato**: una classe `AppTheme`
  (un solo file) con i colori come costanti nominate e due `ThemeData` (chiaro e
  scuro) costruiti su un `ColorScheme`.
- I widget leggono i colori **dal tema** (`Theme.of(context).colorScheme.primary`),
  **mai** scrivendo un colore a mano dentro la schermata.
- **Vietato** scrivere un colore grezzo dentro un widget (`Color(0xFF2563EB)`,
  `Colors.blue`) fuori dal file del tema. I valori `Color(0x..)` e `Colors.*`
  compaiono **solo** nella definizione del tema, mai nelle schermate.

> **Perché così.** Le due app da cui distilliamo hanno **un solo file di tema**
> ciascuna (~800-900 righe) che definisce tutto. Una delle due lo rispetta in
> pieno (zero colori a mano nei widget); l'altra ogni tanto sgarra dentro le
> schermate. La regola neutra prende la versione **disciplinata**: il colore vive
> nel tema, il widget lo chiede al tema.

### 2.1 — Famiglie di token (i nomi semantici da usare)

In Material i colori semantici vivono nel `ColorScheme`. Questi sono i nomi che
i widget usano — sono **funzioni**, non colori:

| Token (`colorScheme.*`) | Funzione |
|-------------------------|----------|
| `primary` / `onPrimary` | **Accento** unico (azioni) / testo e icone sopra l'accento |
| `primaryContainer` / `onPrimaryContainer` | Variante **tenue** dell'accento (sfondi morbidi, chip attivi) / testo relativo |
| `secondary` / `onSecondary` | Superficie/elemento secondario / testo relativo |
| `tertiary` / `onTertiary` | Terzo colore di supporto (**usare con parsimonia**, vedi 2.2) |
| `surface` / `onSurface` | Superficie di card e fogli / testo principale sopra di essa |
| `onSurfaceVariant` | Testo secondario (attenuato ma **leggibile**) |
| `error` / `onError` | Stato di pericolo/errore / testo relativo |
| `outline` | Bordo sottile di separazione |
| `outlineVariant` | Divisore ancora più tenue |
| `shadow` | Colore dell'ombra (tenue) |

A questi si affianca lo sfondo della schermata (`scaffoldBackgroundColor`), che è
il livello più basso, sotto le superfici delle card.

> **Nota sulla mappatura web ↔ mobile.** Chi conosce il 17 (web) ritrova gli
> stessi concetti con altri nomi: `background` web ≈ `scaffoldBackgroundColor`
> mobile; `card`/`surface` web ≈ `surface` mobile; `foreground` ≈ `onSurface`;
> `muted-foreground` ≈ `onSurfaceVariant`; `primary` = `primary`; `destructive` ≈
> `error`; `border` ≈ `outline`. La sostanza è identica; cambia l'etichetta della
> piattaforma.

### 2.2 — L'accento unico

Un solo colore d'accento in tutto il prodotto (`vedi 16-design-core.md`,
principio 2). È il `primary` del `ColorScheme`. L'accento è **solo** per le azioni
("Salva", "Aggiungi", il bottone principale, la voce di navigazione attiva, il
FAB) — **mai** per gli stati.

La differenziazione tra prodotti diversi si fa con l'**icona del brand** e con la
scelta del colore primario nella fase di styling co-progettata, **non**
introducendo un secondo colore forte che compete.

> ### Correzione dal vivo — un solo accento, non due che competono
>
> Calibrata su una delle due app reali (quella outdoor). Quell'app ha un verde
> brand come primario **e** un arancione come terzo colore, usato per il bottone
> flottante (FAB) e per le azioni della snackbar; in più, dal vivo, i punti
> d'interesse sulla mappa usavano un viola/magenta. Risultato: tre colori forti
> che si contendono l'attenzione, l'occhio non sa dove guardare.
>
> **Versione corretta (regola neutra)**:
> - **Il FAB e le azioni primarie usano il `primary`**, non un secondo colore.
> - Il `tertiary` esiste ma è **di supporto**: si usa con parsimonia, mai come
>   secondo bottone d'azione concorrente. Se non serve, non si usa.
> - I `*Container` (`primaryContainer`, ecc.) sono versioni **tenui** del colore
>   (sfondo morbido al ~10% di opacità), **non** un secondo colore pieno saturo.
>   Una delle due app sbagliava qui (metteva il colore pieno come "container");
>   la regola neutra prende la versione tenue dell'altra.

### 2.3 — Superfici (gerarchia per livelli, non per ombre)

La gerarchia visiva nasce dai **livelli di superficie** e da ombre **discrete**,
non da ombre pesanti (`vedi 16-design-core.md`, principio 5). Tre livelli:

| Livello | Token | Uso |
|---------|-------|-----|
| Sfondo | `scaffoldBackgroundColor` | Sfondo della schermata, il livello più basso. Una sfumatura calda/neutra, **non** bianco accecante in chiaro né nero assoluto in scuro |
| Superficie | `colorScheme.surface` | Card, fogli inferiori, barre. Sta "sopra" lo sfondo |
| Superficie in rilievo | `surface` + **elevazione** discreta (ombra tenue) | Elementi che galleggiano (dialog, menu). L'elevazione è bassa e coerente (sez. 5.3) |

**Tema scuro**: lo sfondo è uno slate scuro (**non** nero quasi assoluto) e le
superfici salgono di un gradino di luminosità. In scuro la gerarchia la fanno **le
superfici**, non le ombre (le ombre in scuro quasi non si vedono).

### 2.4 — Bordi e divisori

Bordi sottili (1px) che separano senza drammatizzare: `colorScheme.outline` per il
bordo standard (input, contorni), `outlineVariant` per i divisori più tenui. Le
due app usano divisori a **bassa opacità** (un grigio trasparente), così
separano senza tracciare linee nere dure.

### 2.5 — Testo (livelli di contrasto)

Tre livelli di "inchiostro" per la gerarchia del testo. **Attenzione**: i livelli
attenuati restano **leggibili**, non sbiaditi (vedi correzione in Accessibilità,
sez. 12).

| Livello | Token | Uso |
|---------|-------|-----|
| Alto | `onSurface` | Testo principale (titoli, corpo, dati importanti) |
| Medio | `onSurfaceVariant` | Testo secondario (descrizioni, sottotitoli) — **leggibile, non sbiadito** |
| Disabilitato | un grigio dedicato a bassa enfasi | Placeholder, elementi non attivi — **solo** per ciò che è davvero inattivo |

Le due fonti definiscono esattamente questi tre livelli (`textHighEmphasis`,
`textMediumEmphasis`, `textDisabled`) per chiaro e scuro: il manuale li adotta.

### 2.6 — Colori semantici (stato)

Questi sono i colori dello **stato**, distinti dall'accento (`vedi
16-design-core.md`, principio 3). Uso operativo nella sezione 3 (Severity).

| Token semantico | Significato |
|-----------------|-------------|
| `success` (verde) | OK, online, completato in tempo |
| `warning` (ambra) | Attenzione non urgente, in attesa |
| `error` (rosso) | Urgenza, errore, scaduto, allarme (è `colorScheme.error`) |
| `info` (cyan/azzurro) | Informazione neutra, distinta dall'accento |

> **Dove vivono.** `error` è già nel `ColorScheme` standard di Material. `success`,
> `warning` e `info` **non** esistono di serie in Material: si aggiungono come
> token nel file del tema (costanti nominate, chiaro e scuro), così sono
> centralizzati come tutti gli altri. Una delle due app già lo fa; il manuale lo
> rende regola.
>
> **Perché `info` cyan e non blu?** Per non confonderlo con l'accento (se l'accento
> è bluastro). `info` vale per badge/note, non per i bottoni.

### 2.7 — Tema chiaro e scuro

- Il tema dichiara **entrambi** i `ThemeData`, `lightTheme` e `darkTheme`, costruiti
  sullo stesso set di token (cambiano i valori, non i nomi).
- L'app aggancia i due temi a `MaterialApp(theme: ..., darkTheme: ..., themeMode:
  ...)`. La scelta chiaro/scuro/sistema è un'impostazione, non un colore deciso a
  mano.
- I widget **non** controllano mai "se siamo in dark" per scegliere un colore a
  mano: chiedono il colore al tema, che è già quello giusto per la modalità
  corrente.

---

## 3. Severity coding sul mobile

Il principio del severity coding (`vedi 16-design-core.md`, principio 3) sul mobile
si applica con questa tabella unica. Quando il prodotto introduce un nuovo concetto
di "stato", lo **mappa** su uno di questi livelli — non ne inventa di nuovi.

| Livello | Colore | Quando | Esempi generici |
|---------|--------|--------|------------------|
| **CRITICO** | `error` (rosso) | Richiede intervento immediato | Operazione fallita · Scadenza superata · Dispositivo in errore |
| **ATTENZIONE** | `warning` (ambra) | Da notare, non immediato | In scadenza · Soglia quasi raggiunta · Batteria bassa |
| **REGOLARE / OK** | `success` (verde) | Tutto a posto | Completato in tempo · Online · Sincronizzato |
| **INFORMATIVO** | `info` (cyan) | Da sapere, neutro | Nuova versione · Nota · Suggerimento |
| **INATTIVO** | grigio (testo a bassa enfasi) | Spento, non rilevante | Offline · Archiviato · Non applicabile |
| **AZIONE PRIMARIA** | `primary` (accento) | "Fai questa cosa" | "Accedi", "Salva", "Aggiungi" |

### Regole di applicazione (mobile)

- **L'accento NON è uno stato.** È la chiamata all'azione. Per l'"info" esiste
  `info`.
- **Mai due livelli sovrapposti** sullo stesso elemento (no chip "rosso con bordo
  ambra"). Se servono due dimensioni, usa due elementi.
- I **badge/chip di stato** usano la variante tenue (vedi sotto), non il colore
  pieno.

> ### Correzione dal vivo — contenitori e banner di stato: niente blocco pieno
>
> Calibrata sull'app outdoor: il banner "modalità demo" era un **blocco viola
> pieno e saturo** che dominava la schermata. Ripetuto a ogni apertura, diventa
> rumore. (È lo stesso difetto visto sul web con i contenitori rossi pieni.)
>
> **Versione corretta** per banner, chip e contenitori di stato: **sfondo tenue +
> bordo colorato + accenti** (icona e testo nel colore della severità), **non** il
> blocco pieno. In pratica: sfondo al ~10% di opacità del colore di stato, bordo
> al ~20%, icona e testo nel colore pieno. Il colore pieno si riserva **solo** al
> bottone di azione primaria o a un singolo avviso urgente esplicito.

---

## 4. Tipografia sul mobile

Applica il principio 7 del cuore (`vedi 16-design-core.md`) allo stack mobile.

### 4.1 — Famiglie

| Ruolo | Font | A cosa serve |
|-------|------|--------------|
| Testo e titoli | **Inter** (via `google_fonts`) | Eccellente leggibilità su schermo; caricato dal prodotto, non dal sistema |
| Dati e codici | un **carattere monospazio** (es. Roboto Mono, via `google_fonts`) | Numeri a larghezza fissa per dati che si confrontano (misure, coordinate, importi, codici) |

**Vietato** il font di sistema del telefono (quello di default di Android/iOS):
sempre Inter caricato via `google_fonts`. Le due app fanno entrambe così. Una usa
Inter per tutto; l'altra affianca un carattere per i titoli e uno monospazio per i
dati. Il manuale adotta **Inter come base** e il **monospazio per i dati** (sez.
4.3).

### 4.2 — Scala tipografica (i ruoli Material, non misure a caso)

Material definisce una scala tipografica a **ruoli**, dentro al `TextTheme` del
tema. I widget usano il ruolo (`Theme.of(context).textTheme.titleLarge`), **mai**
una dimensione scritta a mano. Le due app definiscono entrambe la scala completa;
il manuale la adotta:

| Gruppo | Ruoli | Uso |
|--------|-------|-----|
| **Display** | `displayLarge` / `Medium` / `Small` | Titoli speciali grandi (splash, schermate d'ingresso) |
| **Headline** | `headlineLarge` / `Medium` / `Small` | Titoli di sezione importanti |
| **Title** | `titleLarge` / `Medium` / `Small` | Titoli di card, di lista, della barra superiore |
| **Body** | `bodyLarge` / `Medium` / `Small` | Corpo del testo, descrizioni |
| **Label** | `labelLarge` / `Medium` / `Small` | Etichette di bottoni, didascalie, metadati |

> **Titoli decisi, non timidi.** I titoli usano un peso forte (`FontWeight.w600` o
> `w700`). Un titolo `w400` anonimo fa sembrare timida tutta la schermata.
> `vedi 16-design-core.md`, principio 7.

### 4.3 — Numeri monospazio per i dati

È la versione mobile dei "numeri tabulari" del web. Per **tutti i dati che si
confrontano** (importi, quantità, misure, conteggi, codici, coordinate) si usa il
**carattere monospazio**, così le cifre restano allineate e i codici non si
confondono (`0`/`O`, `1`/`l`). Una delle due app fornisce già un helper dedicato
allo stile-dato; il manuale lo rende regola: definisci uno stile "dato" nel tema e
usalo per ogni numero che vive in colonna o va confrontato.

---

## 5. Spaziature, raggi, elevazioni, durate

Concretizza i principi 5 e 6 (`vedi 16-design-core.md`) sullo stack mobile. Sono
tutti **token centralizzati** (costanti nominate nel tema), mai valori improvvisati.

> **Nota distillazione.** Qui le due fonti **divergono** ed è il punto più
> importante del capitolo. Una delle due ha tutte queste scale **centralizzate**
> come costanti (`spacingMedium = 16`, `radiusLarge = 12`, `elevationLow = 2`,
> `standardAnimation = 200ms`…). L'altra le ha **sparse inline** dentro i widget,
> senza una scala condivisa (il suo buco dichiarato). La regola neutra prende la
> versione **centralizzata**: tutte queste scale vivono come token. L'elenco
> operativo dei token (con i valori Dart concreti) è nel capitolo dello stack e
> della libreria componenti — `vedi blocco 2.2`.

### 5.1 — Spaziature (scala da 4px)

Una scala a multipli di 4, mai valori improvvisati:

| Token | Valore |
|-------|--------|
| `xs` | 4 |
| `sm` | 8 |
| `md` | 16 |
| `lg` | 24 |
| `xl` | 32 |

**Densità di default** (per la densità funzionale, `vedi 16-design-core.md`,
principio 4): padding interno delle card `md` (16); spaziatura tra elementi di una
lista `sm`/`md`. Una schermata-lista mostra **tanti elementi utili** senza far
scorrere a vuoto: se mostra 4 card dove ne starebbero 8, il padding è sbagliato.

### 5.2 — Raggi di smusso

| Token | Valore | Uso |
|-------|--------|-----|
| `radiusSmall` | 4 | Chip, badge piccoli, checkbox |
| `radiusMedium` | 8 | Bottoni, input, card piccole |
| `radiusLarge` | 12 | Card standard |
| `radiusXLarge` | 16 | Fogli inferiori (bottom sheet), card grandi |

Pochi valori standard, applicati ovunque. Nessun raggio improvvisato.

> **Nota sui bottoni a pillola.** Una delle due app arrotonda molto i bottoni (quasi
> a pillola). È una scelta **stilistica di skin**, non una regola: il neutro usa un
> raggio sobrio (`radiusMedium`/`radiusLarge`); la pillola è una variante che uno
> skin può adottare (`vedi blocco 2.3`).

### 5.3 — Elevazioni (ombre discrete)

L'elevazione (l'ombra che fa "galleggiare" un elemento) è **bassa e coerente**,
non scenografica. Le due app concordano su valori contenuti:

| Token | Valore | Uso |
|-------|--------|-----|
| `elevationNone` | 0 | Barra superiore piatta (di default), elementi a filo |
| `elevationLow` | 2 | Card |
| `elevationMedium` | 4 | FAB, elementi attivi |
| `elevationHigh` | 8 | Fogli inferiori, finestre, barra inferiore |

**Mai** ombre colorate per "stato" (niente card con ombra rossa). Lo stato lo
dichiara il colore semantico, non l'ombra. In tema scuro la gerarchia la fanno le
superfici (sez. 2.3), non le ombre.

### 5.4 — Durate e curve delle animazioni

Rapide e sobrie (`vedi 16-design-core.md`, principio 8). Le due app concordano su
durate brevi:

| Token | Durata | Uso |
|-------|--------|-----|
| `shortAnimation` | ~150ms | Micro-feedback (pressione, cambio stato) |
| `standardAnimation` | ~200ms | Transizioni normali (apertura foglio, dissolvenza) |
| `mediumAnimation` | ~300ms | Transizioni grandi (raro) |

Curve: una curva morbida standard (`easeInOut`) per la maggior parte; una curva in
uscita (`easeOut`) per gli ingressi. **Niente** rimbalzo, **niente** elastico,
**niente** parallax. Rispettare la preferenza di sistema "riduci animazioni"
(sez. 12.3).

---

## 6. La struttura dell'app (lo "scheletro" mobile)

È la traduzione mobile dell'AppShell web. Dove il web ha topbar + barra laterale,
il mobile ha **barra superiore (AppBar) + barra inferiore (bottom navigation)**.
Ogni schermata vive dentro uno `Scaffold` — l'impalcatura Material che tiene
insieme barra superiore, corpo, barra inferiore e bottone flottante.

```
┌─────────────────────────────────────────┐
│  AppBar (barra superiore)                │
│  [titolo / brand]            [azioni]    │
├─────────────────────────────────────────┤
│                                          │
│            Corpo della schermata         │
│            (scorre verticalmente)        │
│                                          │
│                              ╭───╮       │
│                              │FAB│       │ ← azione primaria flottante (opz.)
│                              ╰───╯       │
├─────────────────────────────────────────┤
│  Bottom navigation (3-5 voci)            │
│  [home] [lista] [aggiungi] [profilo]     │
└─────────────────────────────────────────┘
```

### 6.1 — Barra superiore (AppBar)

È la testata della schermata: titolo + azioni. Tradotta dal pattern "intestazione
di sezione" del cuore.

- **Piatta di default** (`elevation: 0`); guadagna una sottile ombra **solo quando
  il contenuto scorre sotto di essa** (`scrolledUnderElevation`), per separarla dal
  corpo. Le due app concordano su una barra pulita e minimale.
- **Titolo** con peso deciso (ruolo `titleLarge`/`titleMedium` del tema). Allineato
  a sinistra di default (più spazio per titoli lunghi); centrato solo se il
  progetto lo richiede.
- **Azioni a destra**: icone toccabili (`IconButton`), poche e ordinate. Ogni
  azione-solo-icona ha un'etichetta semantica (sez. 12).
- **Mai** affollarla: titolo + max 2-3 azioni. Il resto in un menu.

### 6.2 — Barra inferiore (bottom navigation)

È la navigazione primaria, l'equivalente mobile della barra laterale web. Tradotta
dal pattern "navigazione primaria" del cuore.

- **3-5 voci** principali, mai di più (il pollice non arriva e l'occhio si perde).
  Ogni voce: icona + etichetta breve.
- **Voce attiva** nel colore `primary` (icona + etichetta); voci inattive nel
  grigio a media enfasi. Le due app concordano.
- **Tipo fisso** (`BottomNavigationBarType.fixed`): le voci non si spostano né
  spariscono al cambio di scheda.
- **Area di tocco a piena larghezza** della voce, non solo l'icona. Rispetta la
  "zona sicura" in basso sui telefoni con la barra gestuale.

### 6.3 — Foglio inferiore (bottom sheet)

Il foglio che sale dal basso per azioni contestuali, dettagli rapidi, form brevi.
È un pattern mobile senza equivalente diretto sul web (lì sarebbe un pannello
laterale). Le due app lo usano entrambe.

- **Maniglia di trascinamento** (drag handle) in alto al centro: una barretta corta
  e tenue che comunica "puoi trascinarmi".
- **Angoli superiori arrotondati** (`radiusXLarge`, 16) per staccarlo dal corpo;
  gli angoli inferiori restano a filo dello schermo.
- **Elevazione alta** (`elevationHigh`) e uno sfondo scuro semitrasparente dietro
  (scrim) che mette a fuoco il foglio.
- Per contenuti lunghi, il foglio è **scorrevole** e può espandersi (foglio
  "ridimensionabile").

### 6.4 — Bottone flottante (FAB)

L'azione primaria della schermata, sempre raggiungibile col pollice (in basso a
destra). È l'equivalente mobile della CTA primaria.

- **Usa il colore `primary`** (l'accento), non un secondo colore. (Vedi la
  correzione dal vivo in sez. 2.2: una delle due app lo coloriva con un secondo
  accento — il neutro lo riporta sul primario.)
- **Una sola** azione primaria per schermata. Se non c'è un'azione primaria chiara,
  **niente FAB**: non si mette per riempire.
- Icona chiara e, dove serve, etichetta (FAB esteso) per dire **cosa fa**.

---

## 7. Componenti compositi (i pattern mobile)

I "pattern compositi" sono **ricette di composizione**: dato un insieme di widget
base (testo, icona, card, badge) più un'intenzione (mostrare un numero chiave,
raggruppare avvisi, presentare un'entità), il pattern dice **come comporli**. Sono
il riferimento visivo, non codice da copiare. Sono i gemelli mobile dei 10 pattern
web (`vedi 17-design-web.md`, sez. 7), nella forma adatta al telefono.

> **Regola generale (dal cuore)**: l'icona importante non va mai "nuda". Quando
> un'icona ha un ruolo chiave (testata di una card statistica, voce attiva, stato
> vuoto), sta dentro un contenitore colorato coerente con la sua semantica
> ("icon box"). E una card mostra il proprio stato semantico **solo se** quello
> stato esiste davvero. `vedi 16-design-core.md`.

| Pattern mobile | A cosa serve | Gemello web |
|----------------|--------------|-------------|
| **StatTile** | Un numero chiave in evidenza, con icona colorata | StatCard |
| **ScreenHeader** | Titolo + sottotitolo + azione della schermata (nell'AppBar o appena sotto) | PageHeader |
| **StatusBanner** | Raggruppare/segnalare avvisi per gravità (sfondo tenue + bordo) | AlarmCenter |
| **EmptyState** | Spiegare una lista vuota e cosa fare | EmptyState |
| **EntityCard** | Una entità di una collezione, come card in lista | EntityCard |
| **StatusChip / Badge** | Etichetta di stato a colpo d'occhio (variante tenue) | Badge |
| **BrandMark** | Far sapere "in che prodotto sono" (splash, AppBar) | BrandMark |
| **IntroHeader** | Porta d'ingresso visiva (login/onboarding) | HeroBanner |
| **ActionGroup** | Azione primaria + secondaria con gerarchia | CTA Group |
| **NavItem** | Voce della barra inferiore con eventuale contatore | NavBadge |

Due regole trasversali, identiche al web:
- Le **StatTile** vanno in **riga da 2-3** in cima alla schermata (non 4-6 come sul
  web: lo schermo è stretto), con numero grande in **monospazio**.
- Lo **StatusBanner** appare **solo se** ci sono avvisi: niente banner vuoto a
  riempire. Usa sfondo tenue + bordo (sez. 3, correzione dal vivo), mai il blocco
  pieno.

> L'inventario operativo di questi componenti — con i nomi dei widget da possedere
> in casa (la "libreria Villa mobile") e le loro responsabilità — è nel capitolo
> dello stack e della libreria, `vedi blocco 2.2`. Qui se ne descrive il **gusto**;
> lì se ne fissa l'**inventario**.

---

## 8. Pattern di schermata (i layout canonici mobile)

Una schermata è una **composizione** di pattern compositi (sez. 7) dentro uno
`Scaffold`. Sono i gemelli mobile dei 5 pattern di pagina web (`vedi
17-design-web.md`, sez. 8).

| Schermata | Ruolo | Composizione tipica |
|-----------|-------|---------------------|
| **Home / Dashboard** | "Stato del mondo" a colpo d'occhio | AppBar + riga di StatTile + StatusBanner (condizionale) + sezione principale |
| **Lista** | "Tutti i [X]" con ricerca/filtri | AppBar con ricerca + lista verticale di EntityCard + EmptyState |
| **Dettaglio** | Singola entità con le sue sezioni | AppBar con titolo entità + intestazione ricca + schede/sezioni scorrevoli |
| **Login / Onboarding** | Porta d'ingresso pubblica | Schermata centrata + BrandMark + form + ActionGroup |
| **Gestione / Form** | Creare o modificare un'entità | AppBar + campi con validazione + ActionGroup (salva/annulla), spesso in un foglio inferiore |

**Cosa le rende riconoscibili** (in breve, la sostanza è quella del 17):
- **Home**: niente azione primaria nell'header (riassume, non chiede di agire); la
  riga di StatTile è il "battito" del prodotto; lo StatusBanner appare solo se
  serve.
- **Lista**: ricerca in cima (nell'AppBar o subito sotto); filtri come chip a
  scelta; **due** stati vuoti distinti (lista globalmente vuota → invito a creare;
  filtro che non trova nulla → "rimuovi filtri").
- **Dettaglio**: intestazione ricca con icona/avatar grande + titolo + chip di
  stato; sezioni navigabili (schede o blocchi); azione primaria sempre
  raggiungibile (AppBar o FAB).
- **Login**: schermata centrata, BrandMark prominente, campi con icona interna,
  azione primaria a piena larghezza, link secondario sotto. Registrazione coerente
  col login, non una versione "minore".
- **Form**: validazione con errore **inline** sotto il campo; bottone "Salva"
  disabilitato finché non è valido; conferma con foglio o finestra per le azioni
  irreversibili.

---

## 9. Catalogo dei widget base (Material)

Tutti i componenti standard usano **Material**, vestito dal tema. La
personalizzazione avviene **solo** via il tema (i sotto-temi della sez. 2-5), mai
ridisegnando un widget da zero. **Vietato** rifare un widget che esiste già: se
serve una variante, si **compone** a partire da quelli standard.

**Vietato il widget "nudo" non a tema** al posto di quello Material:
- testo con stile a mano → `Text` che usa un ruolo del `TextTheme`
- bottone fatto a mano (un `GestureDetector` su un `Container` colorato) →
  `ElevatedButton` / `OutlinedButton` / `TextButton`
- campo di testo custom → `TextField` / `TextFormField` col tema input
- finestra/avviso fatti a mano → `showDialog` / `AlertDialog`, `showModalBottomSheet`,
  `SnackBar`

**Lista minima** dei widget attesi, tutti già a tema nelle due fonti:

| Categoria | Widget Material |
|-----------|-----------------|
| **Azioni** | `ElevatedButton`, `OutlinedButton`, `TextButton`, `IconButton`, `FloatingActionButton` |
| **Input** | `TextField` / `TextFormField`, `Switch`, `Checkbox`, `Radio`, `Slider`, `DropdownButton` |
| **Contenitori** | `Card`, `ListTile`, `ExpansionTile`, `Chip` |
| **Struttura** | `Scaffold`, `AppBar`, `BottomNavigationBar`, `TabBar`, `BottomSheet` |
| **Feedback** | `SnackBar`, `Dialog` / `AlertDialog`, `Tooltip`, `CircularProgressIndicator` / `LinearProgressIndicator` |

**Comportamenti condivisi**: ogni widget supporta tema chiaro e scuro via i token
(mai colori a mano); i bersagli toccabili rispettano i 48px minimi (sez. 12.3); in
caricamento i bottoni mostrano un indicatore e i contenuti uno scheletro o uno
spinner.

**Dimensioni standard delle icone**: una piccola scala coerente (es. 16 / 20 / 24
/ 32), non misure a caso. Per una nuova icona, scegli la `Icons.*` semanticamente
più vicina; non disegnare un'icona custom.

---

## 10. Microinterazioni e feedback aptico sul mobile

Discrete, semantiche, mai gratuite (`vedi 16-design-core.md`, principio 8). Sul
mobile c'è una dimensione in più rispetto al web: il **tatto**.

### 10.1 — Feedback al tocco

- Ogni elemento toccabile dà un **riscontro visivo** alla pressione: l'effetto
  "ink ripple" di Material (l'onda che parte dal punto toccato) sui widget
  standard, o una leggera compressione/cambio di superficie sui custom.
- **Stati**: normale, premuto, disabilitato (a opacità ridotta), in
  caricamento (indicatore al posto dell'etichetta).

### 10.2 — Feedback aptico (vibrazione)

Il **ritorno tattile** — una breve vibrazione — conferma le azioni importanti.
Entrambe le piattaforme da cui distilliamo lo prevedono per i gesti chiave.

- **Usalo con misura**: sulle azioni che contano (conferma, completamento, errore,
  cambio di scheda principale, raggiungimento di una soglia), **non** a ogni tocco.
- **Calibra l'intensità** al peso dell'azione: un tocco leggero (`selectionClick` /
  `lightImpact`) per le selezioni; uno più marcato per conferme o errori.
- Troppo feedback aptico stanca e fa sembrare l'app un giocattolo, esattamente come
  troppe animazioni.

### 10.3 — Transizioni tra schermate

Le transizioni di navigazione usano gli standard Material (scorrimento/dissolvenza
della piattaforma), con le durate brevi della sez. 5.4. **Niente** transizioni
custom scenografiche.

---

## 11. Microcopy e lessico (mobile)

Applica il principio 10 del cuore (`vedi 16-design-core.md`). Identico al web:

- **Italiano** in tutta l'interfaccia (testi, messaggi, snackbar, conferme). Solo i
  nomi di codice (variabili, classi, file) restano in inglese.
- **Niente anglicismi** dietro le etichette: "Invia" non "Submit", "Annulla" non
  "Cancel", "Salva" non "Save".
- **Numeri concreti**: "3 elementi da sincronizzare", non "alcuni elementi".
- **Conferme** = titolo imperativo breve + una riga + bottoni espliciti. Mai "Sei
  sicuro?" → "Confermi la rimozione di [X]?".
- **Errori** = cosa è successo + cosa fare. Mai "Errore" → "Connessione assente.
  Riprova quando torni online."
- **Niente emoji** nell'interfaccia di produzione, niente esclamativi gratuiti,
  niente paternalismo.

> Sul mobile lo spazio è poco: il microcopy è ancora più **breve e diretto** che
> sul web, ma mai a costo della chiarezza. Il vocabolario di dominio lo definisce
> il progetto; questo capitolo è neutro.

---

## 12. Accessibilità sul mobile

L'app sta in mano a utenti diversi, spesso in movimento, all'aperto, con una mano
sola. L'accessibilità non è un di-più. Applica il principio 9 del cuore (`vedi
16-design-core.md`).

### 12.1 — Contrasto

- **WCAG AA come minimo** per tutti i testi. All'aperto serve **più** contrasto, non
  meno (una delle due app è nata proprio per la leggibilità outdoor).

> ### Correzione dal vivo — i testi secondari restano leggibili
>
> Stessa raccomandazione del web: i testi **secondari** (orari, etichette, note)
> non vanno **sbiaditi** per "alleggerire". Si usa il livello a media enfasi
> (`onSurfaceVariant`, un grigio leggibile), **non** un grigio chiarissimo su
> sfondo chiaro. Mai testo grigio chiaro su superficie grigio chiara.

### 12.2 — Etichette semantiche e lettori di schermo

- **Etichette per le icone**: ogni `IconButton` solo-icona ha un'etichetta
  semantica (`tooltip` / `Semantics`), così i lettori di schermo (TalkBack su
  Android, VoiceOver su iOS) dicono cosa fa.
- **Struttura semantica** corretta: titoli, bottoni e campi annunciati per quello
  che sono. Material lo fa di base se si usano i widget standard (un motivo in più
  per non fare widget "nudi", sez. 9).

### 12.3 — Movimento e bersagli toccabili

- **Bersagli toccabili ≥ 48×48dp**: entrambe le app fissano `minimumSize: Size(48,
  48)` sui bottoni. È regola. ("dp" = unità di misura indipendente dalla densità
  dello schermo: 48dp sono grandi uguali su ogni telefono.)
- **Rispetta "riduci animazioni"** del sistema: quando l'utente lo richiede, le
  transizioni decorative si riducono al minimo. Mai animazioni che non si possono
  disattivare.
- **Zona sicura** (safe area): rispetta notch in alto e barra gestuale in basso, non
  mettere comandi sotto di esse.

---

## 13. Convenzioni dei token (mobile)

### 13.1 — Il tema centralizzato è l'unica fonte

Tutti i colori, i caratteri e gli stili dei componenti vivono in **un solo file di
tema** (`AppTheme`, con `lightTheme` e `darkTheme`). È l'unica fonte di verità.
Le due app reali fanno entrambe così: un file, ~800-900 righe, tutto lì.

### 13.2 — I widget non scrivono mai un colore a mano

I widget leggono sempre dal tema (`Theme.of(context).colorScheme.*`,
`...textTheme.*`), mai un `Color(0x..)` o `Colors.*` scritto nella schermata. Così
cambiare un token cambia tutta l'app in un colpo solo, e il tema scuro "funziona
gratis".

### 13.3 — Naming dei token

| Schema | Esempio | Per |
|--------|---------|-----|
| semantico | `colorScheme.primary`, `colorScheme.error` | Colori semantici e accento |
| stato | `success`, `warning`, `info` (token aggiunti al tema) | Severity coding |
| misura a scala | `spacingMedium`, `radiusLarge`, `elevationLow` | Spaziature, raggi, elevazioni |
| tempo a scala | `standardAnimation` | Durate delle animazioni |

**Mai** un valore numerico improvvisato (`padding: 15`, `elevation: 7`): sempre un
token della scala.

---

## 14. Moduli opzionali (specialità tematiche, NON nel cuore)

Le due app da cui distilliamo hanno ciascuna delle **specialità** legate al
proprio dominio. Queste **non** stanno nel cuore neutro (gonfierebbero ogni app
con roba che non le serve): vivono come **moduli/esempi opzionali**, da tirare in
ballo **solo** se il progetto lo richiede. Restano comunque costruiti sugli stessi
token e principi del cuore.

### 14.1 — Modulo "mappa e luoghi" (dall'app outdoor)
Mappa a tutto schermo con marcatori, foglio inferiore che mostra il dettaglio del
punto selezionato, indicatori di posizione. Utile per app con una dimensione
geografica. **Regola dal cuore anche qui**: i marcatori non introducono un secondo
accento che compete col primario (vedi sez. 2.2).

### 14.2 — Modulo "gamification" (dall'app outdoor)
Progressi, punti, traguardi, contatori in evidenza. Utile per app che premiano
l'uso ripetuto. I numeri usano il carattere monospazio (sez. 4.3).

### 14.3 — Modulo "conversazione" (dall'app gestionale)
Chat con bolle e testo formattato, indicatore "sta scrivendo", chip di azioni
rapide. Utile per app con un assistente o una messaggistica.

### 14.4 — Modulo "voce e audio" (dall'app gestionale)
Visualizzazione del livello audio (equalizzatore), trascrizione vocale dal vivo,
controlli di registrazione. Utile per app con comandi vocali.

### 14.5 — Modulo "gerarchia di entità tipizzate" (dall'app gestionale)
Una mappa centralizzata **tipo → colore + icona + etichetta** (es. i livelli di un
inventario): ogni tipo ha un colore e un'icona costanti, usati ovunque (badge,
card, dettaglio, ricerca). È un pattern potente e riutilizzabile **quando** il
dominio ha entità di tipi distinti.
> **Attenzione (regola dal cuore)**: questi colori-per-tipo sono **categorici**
> (distinguono categorie), **non** sono severity coding (sez. 3) e **non** sono
> l'accento (sez. 2.2). Vanno tenuti distinti dai colori di stato, altrimenti si
> svuota di significato sia il tipo sia lo stato. Usali in versione **tenue** sui
> contenitori, mai a blocchi pieni saturi.

---

## 15. Lista di controllo (specifica mobile)

Estende la lista del cuore (`vedi 16-design-core.md`, "In sintesi") con i punti
specifici dello stack mobile. Un'app mobile di Villa rispetta **tutti** questi
punti:

- [ ] Stack: Flutter + Material (Material 3) + tema centralizzato + `google_fonts`
      (Inter) + `sizer`; forui solo opzione futura.
- [ ] Colori, caratteri e stili in **un solo file di tema** (`ThemeData` chiaro +
      scuro su `ColorScheme`); **nessun** `Color(0x..)`/`Colors.*` nei widget.
- [ ] **Un solo accento** (`primary`), usato solo per le azioni (incluso il FAB);
      gli stati hanno i loro colori (`success`/`warning`/`error`/`info`).
- [ ] **Severity coding** costante; banner e chip di stato usano **sfondo tenue +
      bordo + accenti**, mai il blocco di colore pieno.
- [ ] Nessun widget "nudo" non a tema (testo/bottone/campo/finestra fatti a mano):
      sempre i widget Material vestiti dal tema.
- [ ] **Inter** via `google_fonts`; scala tipografica a ruoli (`TextTheme`);
      **monospazio** sui dati numerici; titoli **decisi**.
- [ ] Spaziature/raggi/elevazioni/durate a **scala centralizzata** (token), mai
      valori improvvisati; densità adeguata.
- [ ] **Tema chiaro e scuro** agganciati a `MaterialApp`; responsività con `sizer`.
- [ ] **Microinterazioni** discrete + **feedback aptico** con misura; "riduci
      animazioni" rispettato.
- [ ] **Accessibilità**: contrasto WCAG AA (anche per i testi secondari, **non**
      sbiaditi), etichette semantiche sulle icone, bersagli toccabili ≥ 48dp, zona
      sicura.
- [ ] **Italiano** in UI, errori specifici, niente emoji/paternalismi.
- [ ] Gli **stati** (caricamento, vuoto, errore, successo, primo uso) ci sono tutti;
      ogni lista ha un **EmptyState** ricco.
- [ ] I **pattern compositi** e i **pattern di schermata** sono usati come
      riferimento dove pertinenti.
- [ ] Le **specialità di dominio** (mappe, chat, voce, gerarchie tipizzate) stanno
      nei **moduli opzionali**, non nel cuore.

---

*Capitolo mantenuto in `.claude/metodo-villa/18-design-mobile.md`. È la
specializzazione mobile del cuore comune `16-design-core.md` e il gemello del
`17-design-web.md`. Le regole di tema/stack qui descritte sono coerenti con la
skill `seeding-visivo-mobile` e il suo system-prompt anti-piattezza. Distillato dal
comune di due app Flutter reali e curate, senza copiarne il codice 1:1 né le
specialità di dominio (confinate nei moduli opzionali, sez. 14).*
