# 17 — Design Web (manuale di stile per lo stack web)

> **Cosa contiene questo capitolo**: il manuale di stile **operativo per il web**
> del Metodo Villa. È la traduzione concreta — token, componenti, pattern di
> pagina — dei principi di gusto definiti nel cuore comune. Vale per **qualsiasi
> progetto web** di Villa (gestionale, dashboard, portale, strumento interno):
> è neutro rispetto al dominio (non parla di un settore specifico) ma **specifico
> per lo stack web**.
>
> **È la specializzazione web del 16-design-core**: il capitolo `16-design-core.md`
> dice *cosa* deve rispettare un frontend curato (densità, gerarchia, un solo
> accento, severity coding, stati curati, italiano). Questo capitolo dice *come*
> rispettarlo **con gli strumenti del web**. Dove un principio è già spiegato nel
> 16, qui non lo si ripete: lo si **applica**. Per i principi di fondo, `vedi
> 16-design-core.md`.
>
> **Da dove è distillato**: dal design system arricchito di un ecosistema reale
> di prodotti web (distillato e **neutralizzato dal suo dominio**: tutti i
> riferimenti di settore sono stati rimossi e sostituiti con esempi generici),
> più due **correzioni estetiche calibrate dal vivo** su un prodotto reale di
> monitoraggio (vedi i riquadri "Correzione dal vivo" nelle sezioni Severity e
> AlarmCenter, e in Accessibilità).
>
> **Glossario minimo** (per chi legge senza essere tecnico):
> - **Token**: un nome che descrive la *funzione* di un colore o di una misura
>   ("colore primario", "superficie di sfondo") invece del valore numerico. Si
>   cambia in un posto solo e si propaga ovunque.
> - **HSL**: un modo di scrivere i colori per tonalità/saturazione/luminosità,
>   comodo perché si schiarisce o scurisce un colore cambiando un solo numero.
> - **Tailwind**: il sistema con cui si scrivono gli stili come piccole classi
>   (`bg-primary`, `p-4`) invece di fogli di stile separati.
> - **shadcn/ui**: una libreria di componenti pronti (bottoni, input, finestre)
>   che si **copiano dentro il progetto** e si personalizzano.
> - **Lucide**: la collezione di icone usata in tutto il prodotto.

---

## 1. Stack web cementato

Ogni frontend web di Villa parte da **questo** stack. Non se ne propongono altri
salvo richiesta esplicita di Villa. Lo stack non è negoziabile: la coerenza tra
progetti vale più della libertà di scelta sul singolo progetto.

| Livello | Tecnologia | A cosa serve (in parole povere) |
|---------|------------|----------------------------------|
| Framework | **React** 18+ | Il motore che disegna le pagine e le aggiorna quando i dati cambiano |
| Build | **Vite** 5+ | Lo strumento che assembla il progetto e lo serve mentre si sviluppa |
| Linguaggio | **TypeScript** strict 5+ | JavaScript con i controlli: segnala gli errori prima che arrivino all'utente |
| Stile | **Tailwind CSS** 3.4+ | Gli stili scritti come classi brevi, ancorati ai token |
| Componenti UI | **shadcn/ui** | I mattoni dell'interfaccia, copiati in `src/components/ui/` |
| Icone | **Lucide React** | Una sola famiglia di icone, coerente ovunque |
| Tipografia | **Inter** (testo e titoli) + **JetBrains Mono** (dati tabellari, codici) | Caratteri caricati dal prodotto, mai font di sistema |
| Router | **React Router DOM** v6+ | Gestisce le "pagine" e gli indirizzi interni |
| Form | **React Hook Form** + **Zod** | Moduli con validazione (controllo che i campi siano corretti) |
| Stato | **TanStack Query** (dati dal server) + Context API (stato dell'interfaccia) | Tiene allineati i dati e lo stato delle schermate |
| Notifiche brevi | **Sonner** (toast) | I messaggi temporanei in basso/alto ("Salvato") |
| Date | **date-fns** | Formattazione e calcoli sulle date |
| Tabelle | **TanStack Table** + wrapper DataTable | Tabelle ordinabili, paginabili, filtrabili |

**Da NON proporre**: Angular, Vue, Svelte, Next.js (salvo richiesta esplicita),
Material UI, Ant Design, Chakra UI, Bootstrap, jQuery, Redux. Lo stack è fisso.

> Per i progetti **mobile** lo stack è un altro (Flutter): `vedi 18-design-mobile.md`.

---

## 2. Token e colori sul web (come si concretizza il principio dei token)

Il principio "token semantici, mai valori grezzi" (`vedi 16-design-core.md`,
principio 1) sul web si concretizza così:

- Tutti i colori vivono come **CSS variables** (variabili di tema) scritte in
  **HSL**, in `index.css`: il blocco `:root` per il tema chiaro, il blocco
  `.dark` per il tema scuro.
- `tailwind.config.ts` **referenzia** quelle variabili: `colors: { primary:
  'hsl(var(--primary))', ... }`. Le classi Tailwind (`bg-primary`,
  `text-foreground`) puntano sempre al token, mai a un valore.
- **Vietato** scrivere un colore "a mano" dentro un componente
  (`bg-[#2563eb]`), e **vietato** usare le classi-colore generiche di Tailwind
  nei componenti (`bg-blue-500`, `text-red-600`). Quelle compaiono **solo** nella
  definizione delle variabili di base, mai nei `.tsx`.

### 2.1 — Famiglie di token (i nomi semantici da usare)

Questi sono i nomi che compaiono nelle classi Tailwind dei componenti. Sono
**funzioni**, non colori:

| Token | Funzione |
|-------|----------|
| `background` / `foreground` | Sfondo pagina / testo principale sopra di esso |
| `card` / `card-foreground` | Sfondo di una card / testo dentro la card |
| `primary` / `primary-foreground` | **Accento** unico (azioni) / testo sopra l'accento |
| `secondary` / `secondary-foreground` | Superficie/bottone secondario / testo relativo |
| `muted` / `muted-foreground` | Superficie attenuata / testo secondario (attenuato ma **leggibile**) |
| `accent` / `accent-foreground` | Superficie di evidenziazione tenue (hover, voce attiva) |
| `destructive` / `destructive-foreground` | Stato di pericolo/errore / testo relativo |
| `border` | Bordo sottile ("hairline", linea di un capello) di separazione |
| `input` | Bordo dei campi di inserimento |
| `ring` | Anello di focus (vedi accessibilità) |

> **Nota sulla mappatura dei nomi.** Lo stack web standard (shadcn/ui) usa la
> coppia `background`/`foreground`, `primary`/`muted`/`accent`/`destructive`. Il
> design system da cui questo capitolo è distillato usava nomi propri
> (`canvas`, `surface-1..4`, `ink`, `ink-muted`, `accent`, `danger`…). Le sezioni
> seguenti riportano **entrambi** dove serve: i valori dei token sono identici,
> cambia solo l'etichetta. Quando si crea un progetto nuovo, si usano i nomi
> shadcn (`background`/`muted`/`destructive`); quando si legge una specifica di
> pattern qui sotto scritta con i nomi storici, vale la mappatura
> `canvas ≈ background`, `surface-N ≈ livelli di muted`, `ink ≈ foreground`,
> `ink-muted/ink-subtle ≈ muted-foreground`, `danger ≈ destructive`,
> `hairline ≈ border`.

### 2.2 — L'accento unico

Un solo colore d'accento in tutto il prodotto (`vedi 16-design-core.md`,
principio 2). Riferimento operativo: un **blu standard** (≈ `#2563eb`, cioè il
`blue-600` di Tailwind) come valore di default sano e neutro. La differenziazione
tra prodotti diversi si fa con l'**icona del brand**, non cambiando l'accento.
L'accento è **solo** per le azioni ("Salva", "Nuovo X", link, anello di focus,
brand mark) — **mai** per gli stati.

> Se il progetto ha un suo colore brand, lo si usa al posto del blu di default.
> In assenza di indicazione, **non** scegliere indigo/viola/blu generici a caso:
> chiedere a Villa.

### 2.3 — Superfici (scala a 4 livelli, gerarchia senza ombre)

La gerarchia visiva nasce dai **livelli di superficie**, non dalle ombre
(`vedi 16-design-core.md`, principio 5). Quattro livelli, distinti per luminosità.
Tonalità calda (slate), non grigio neutro freddo.

**Tema chiaro**:
| Livello (nome storico) | Valore | Uso |
|------------------------|--------|-----|
| `canvas` (≈ `background`) | `#ffffff` | Sfondo pagina principale |
| `surface-1` | `#f8fafc` | Card primarie, topbar |
| `surface-2` | `#f1f5f9` | Card secondarie, hover, superficie in rilievo |
| `surface-3` | `#e2e8f0` | Sezioni terziarie, stato "attivo" del menu |
| `surface-4` | `#cbd5e1` | Massimo livello (raro) |

**Tema scuro**:
| Livello | Valore | Uso |
|---------|--------|-----|
| `canvas` | `#0f172a` | Sfondo pagina (slate scuro, **non** nero quasi assoluto) |
| `surface-1` | `#1e293b` | Card primarie |
| `surface-2` | `#293548` | Superficie intermedia |
| `surface-3` | `#334155` | Sezioni terziarie |
| `surface-4` | `#475569` | Massimo livello (raro) |

### 2.4 — Bordi ("hairline")

Bordi sottili (1px) che separano senza drammatizzare. Default: il bordo
`hairline` (token `border`). Si sale a un bordo più marcato solo quando serve un
confine netto (es. divisore tra sezioni dello stesso blocco).

| Token | Chiaro | Scuro |
|-------|--------|-------|
| `hairline` (≈ `border`) | `#e2e8f0` | `#334155` |
| `hairline-strong` | `#cbd5e1` | `#475569` |

### 2.5 — Testo (4 livelli di contrasto)

Quattro livelli di "inchiostro" per la gerarchia del testo. **Attenzione**: i
livelli attenuati restano **leggibili** (vedi correzione in Accessibilità), non
sbiaditi.

| Token (nome storico) | Chiaro | Scuro | Uso |
|----------------------|--------|-------|-----|
| `ink` (≈ `foreground`) | `#0f172a` | `#f1f5f9` | Testo principale (titoli, corpo, dati importanti) |
| `ink-muted` (≈ `muted-foreground`) | `#334155` | `#cbd5e1` | Testo secondario (descrizioni, sottotitoli) |
| `ink-subtle` | `#64748b` | `#94a3b8` | Testo terziario (orari, metadati) — **leggibile, non sbiadito** |
| `ink-tertiary` | `#94a3b8` | `#64748b` | Testo quaternario (placeholder, disabilitato) |

### 2.6 — Colori semantici (stato)

Questi sono i colori dello **stato**, distinti dall'accento (`vedi
16-design-core.md`, principio 3). Uso operativo nella sezione 3 (Severity).

| Token | Chiaro | Scuro | Significato |
|-------|--------|-------|-------------|
| `success` | `#16a34a` | `#22c55e` | OK, online, completato in tempo |
| `warning` | `#d97706` | `#f59e0b` | Attenzione non urgente, in attesa |
| `danger` (≈ `destructive`) | `#dc2626` | `#ef4444` | Urgenza, errore, scaduto, allarme |
| `info` | `#0891b2` | `#06b6d4` | Informazione neutra (cyan), distinta dall'accento |

> **Perché `info` cyan e non blu?** Per non confonderlo con l'accento (che è blu
> e significa "azione"). `info` vale per badge/notifiche, non per i bottoni.

### 2.7 — Overlay e tema scuro

- **Overlay** (sfondo scuro dietro finestre e pannelli): `rgba(0,0,0,0.4)` in
  chiaro, `rgba(0,0,0,0.6)` in scuro. Mai gradiente, mai sfocatura di sfondo
  (costa in prestazioni e aggiunge rumore).
- **Tema scuro via classe**: `darkMode: 'class'` in `tailwind.config.ts`. Il
  passaggio chiaro/scuro aggiunge o toglie la classe `.dark` su `<html>`,
  gestita da un hook `useTheme`. **Mai** la media query `prefers-color-scheme`
  diretta — sempre via classe, così l'utente può forzare il tema.

---

## 3. Severity coding sul web

Il principio del severity coding (`vedi 16-design-core.md`, principio 3) sul web
si applica con questa tabella unica. Quando il prodotto introduce un nuovo
concetto di "stato", lo **mappa** su uno di questi livelli — non ne inventa di
nuovi.

| Livello | Colore | Quando | Esempi generici |
|---------|--------|--------|------------------|
| **CRITICO** | `danger` (rosso) | Richiede intervento immediato | Ordine bloccato · Scadenza superata da giorni · Dispositivo in stato di errore |
| **ATTENZIONE** | `warning` (ambra) | Da notare, non immediato | In scadenza oggi · Soglia quasi raggiunta · Batteria 20-50% |
| **REGOLARE / OK** | `success` (verde) | Tutto a posto | Completato in tempo · Online · Conforme |
| **INFORMATIVO** | `info` (cyan) | Da sapere, neutro | Nuova versione disponibile · Nota · Aggiornamento |
| **INATTIVO** | grigio (`ink-subtle`) | Spento, non rilevante | Dispositivo offline · Elemento archiviato · Voce non applicabile |
| **AZIONE PRIMARIA** | `primary` (accento) | "Fai questa cosa" | "Accedi", "Salva", "Nuovo", "Esporta" |

### Regole di applicazione (web)

- **L'accento (blu) NON è uno stato.** È la chiamata all'azione. Per l'"info"
  esiste `info` (cyan).
- **Pulsazione** (`animate-pulse`): solo per stati **critici persistenti** (un
  allarme attivo non gestito, una scadenza superata da molto). Mai su elementi
  non critici: se il "pulse" è ovunque, l'occhio impara a ignorarlo.
- **Mai due livelli sovrapposti** sullo stesso elemento (no badge "rosso
  pulsante con bordo ambra"). Se servono due dimensioni, usa due elementi.

> ### Correzione dal vivo — contenitori di stato critico: niente blocco pieno
>
> Calibrata su un prodotto reale di monitoraggio: un contenitore di stato critico
> **non** deve essere un blocco di colore pieno, saturo e dominante (es. un
> riquadro tutto rosso pieno). Un blocco così "si mangia" la pagina e, ripetuto
> molte volte al giorno, diventa rumore.
>
> **Versione corretta** per badge, pill e riquadri di stato: **sfondo tenue +
> bordo colorato + accenti** (icona e testo nel colore della severità). In
> pratica, per un badge: `bg-danger/10 border border-danger/20 text-danger` —
> **non** `bg-danger` pieno. Il colore pieno si riserva **solo** al bottone di
> azione primaria o a un singolo avviso urgente esplicito. Questa regola si
> applica anche al pattern **AlarmCenter** (sezione 7.3).

---

## 4. Tipografia sul web

Applica il principio 7 del cuore (`vedi 16-design-core.md`) allo stack web.

### 4.1 — Famiglie

| Ruolo | Font | A cosa serve |
|-------|------|--------------|
| Testo e titoli | **Inter** | Eccellente leggibilità, kerning già ottimizzato; caricato dal prodotto via `@font-face` o Google Fonts |
| Dati tabellari e codici | **JetBrains Mono** | Numeri a larghezza fissa garantiti; codici (`C312-A`) non si confondono (`0`/`O`, `1`/`l`) |

**Vietato** il font di sistema (`font-sans` puro, Segoe UI, Roboto, Arial):
sempre Inter caricato dal prodotto.

### 4.2 — Scala tipografica (token di ruolo, non misure a caso)

Pochi nomi di ruolo, applicati ovunque. **Vietato** `text-[15px]` o
`text-[11.5px]` improvvisati.

| Token | Dimensione | Interlinea | Peso | Uso |
|-------|-----------|-----------|------|-----|
| `text-display-lg` | 56px | 1.10 | 600 | Titolo di pagine speciali (login splash) |
| `text-display-md` | 40px | 1.15 | 600 | H1 di sezioni principali |
| `text-display-sm` | 32px | 1.20 | 600 | H1 di pagina standard |
| `text-headline` | 28px | 1.20 | 600 | H2 di sezione |
| `text-card-title` | 22px | 1.25 | 500 | Titoli di card |
| `text-subhead` | 20px | 1.40 | 400 | Sottotitoli |
| `text-body-lg` | 18px | 1.50 | 400 | Corpo in evidenza |
| `text-body` | 16px | 1.50 | 400 | Corpo standard |
| `text-body-sm` | 14px | 1.50 | 400 | Corpo in card dense, celle di tabella, label |
| `text-caption` | 12px | 1.40 | 400 | Metadati, orari, note a margine |
| `text-button` | 14px | 1.20 | 500 | Etichetta dei bottoni |
| `text-eyebrow` | 13px | 1.30 | 500 (+`tracking`) | "Sopra-titolo" maiuscoletto (es. "REPORTISTICA") |

> **Titoli decisi, non timidi.** I titoli di pagina usano un peso forte
> (`font-bold` / `font-semibold`) e `tracking-tight`. Un titolo `font-medium`
> anonimo fa sembrare timida tutta la pagina.

### 4.3 — Numeri a larghezza fissa (tabular-nums)

Per **tutti i dati che si confrontano in colonna** (importi, quantità, misure,
conteggi, codici) si usa `font-variant-numeric: tabular-nums` (classe
`tabular-nums`). Senza, in una tabella le cifre "saltano" perché `1` è stretto e
`8` è largo; con i numeri tabulari le colonne restano perfettamente allineate.
Obbligatorio su: ogni tabella, ogni StatCard, ogni dato numerico verticale.

---

## 5. Spacing, raggi, ombre, transizioni

Concretizza i principi 5 e 6 (`vedi 16-design-core.md`) sullo stack web.

### 5.1 — Spaziature (scala da 4px)

Una scala, mai valori improvvisati (`p-[15px]`, `gap-[7px]` sono vietati).

| Token | Valore | Tailwind |
|-------|--------|----------|
| `xxs` | 4px | `p-1`, `gap-1` |
| `xs` | 8px | `p-2`, `gap-2` |
| `sm` | 12px | `p-3`, `gap-3` |
| `md` | 16px | `p-4`, `gap-4` |
| `lg` | 24px | `p-6`, `gap-6` |
| `xl` | 32px | `p-8`, `gap-8` |
| `xxl` | 48px | `p-12`, `gap-12` |

**Densità di default** (per la densità funzionale, `vedi 16-design-core.md`,
principio 4): card di contenuto `p-4`, righe di tabella `py-3`. Card singole
prominenti (hero, dashboard ad alta densità) possono salire a `p-6`/`p-8`. Mai
oltre. Una pagina-lista deve mostrare **25-30 righe utili** in un viewport 1080p:
se ne mostra 12, il padding è sbagliato.

### 5.2 — Raggi di smusso

| Token | Valore | Uso |
|-------|--------|-----|
| `rounded-sm` | 6px | Input, badge piccoli |
| `rounded-md` | 8px | Bottoni, card piccole, voci di menu |
| `rounded-lg` | 12px | Card standard, finestre piccole |
| `rounded-xl` | 16px | Card grandi, finestre standard |
| `rounded-2xl` | 24px | Card hero, finestre grandi (raro) |
| `rounded-pill` / `rounded-full` | 9999px | Avatar, badge di stato, chip |

Nessun raggio custom oltre questi (`rounded-[7px]` vietato).

### 5.3 — Ombre

Poche, controllate. In tema scuro la gerarchia la fanno le superfici, non le
ombre.

| Token | Chiaro | Scuro | Uso |
|-------|--------|-------|-----|
| `shadow-sm` | `0 1px 2px rgba(0,0,0,.05)` | `none` | Card con elevazione minima |
| `shadow-md` | `0 2px 8px rgba(0,0,0,.08)` | `0 2px 8px rgba(0,0,0,.3)` | Card prominenti, menu a tendina |
| `shadow-lg` | `0 4px 16px rgba(0,0,0,.12)` | `0 4px 16px rgba(0,0,0,.4)` | Finestre, pannelli laterali |
| `shadow-focus-ring` | `0 0 0 2px rgba(37,99,235,.5)` | idem | Anello di focus sistematico |

**Mai** ombre colorate per "stato" (niente card di emergenza con ombra rossa). Lo
stato lo dichiara il colore semantico (bordo/sfondo), non l'ombra. **Card senza
ombra = piatte**: la card standard ha `shadow-md` di default + `hover:shadow-lg`.

### 5.4 — Transizioni

Rapide e sobrie. Niente rimbalzo, niente elastico.

| Token | Durata | Uso |
|-------|--------|-----|
| `duration-fast` | 100ms | Hover semplici |
| `duration-normal` | 200ms | Ingresso finestre, slide, dissolvenza |
| `duration-slow` | 300ms | Transizioni grandi (raro) |

**Mai** transizioni globali tipo `* { transition: all .2s }` (costose e
imprevedibili): sempre specifiche (`transition-colors`, `transition-transform`,
`transition-opacity`). E sempre rispettare `prefers-reduced-motion`: quando
l'utente lo richiede, le animazioni si riducono a ~0.

---

## 6. AppShell (il guscio dell'applicazione)

Ogni pagina autenticata vive dentro lo stesso "guscio": topbar in alto, sidebar a
sinistra (su schermi medi e grandi), barra di navigazione in basso (su mobile).
È la traduzione web del pattern "navigazione primaria" (`vedi 16-design-core.md`).

```
┌─────────────────────────────────────────────────┐
│  Topbar (h-12, fissa)                            │
│  [BrandMark] [Ricerca globale] [Tema] [User]     │
├──────┬──────────────────────────────────────────┤
│      │                                           │
│ Side │              Contenuto principale         │
│ bar  │              (scroll interno)             │
│ w-52 │                                           │
└──────┴──────────────────────────────────────────┘
              [Barra inferiore (mobile, <md)]
```

### 6.1 — Topbar (altezza canonica `h-12` = 48px, fissa)

**Mai più alta di 48px.** Sopra i 64px si entra in territorio "dashboard
consumer", incompatibile con un tono professionale.

Layout (sinistra → centro → destra):

| Slot | Contenuto | Note |
|------|-----------|------|
| **Brand mark** (sinistra) | Pattern `BrandMark` (sez. 7.8), variante topbar | Cliccabile, porta alla home del prodotto |
| **Ricerca globale** (centro) | `Input` con icona di ricerca a sinistra inline, `max-w-md` | Nascosta su mobile. Se il backend non è pronto: lascia il campo visibile, cursore "non disponibile" — comunica "funzione in arrivo", non rimuoverla |
| **Azioni** (destra) | IconButton in fila: tema, eventuale assistente, menu utente | Ordine fisso da destra: utente, (assistente), tema |

**Menu utente** (trigger in topbar): avatar piccolo (32×32) con iniziali su
`bg-primary/10 text-primary`; nome + ruolo visibili da `md` in su. Un **chip
ruolo** colorato distingue a colpo d'occhio il tipo di utente.

> **Chip ruolo, generico e neutro.** Mappa ogni **ruolo applicativo** del
> progetto (es. amministratore, operatore, responsabile, sola lettura) a una
> variante di colore coerente con la palette (sez. 2). Regole: (a) il chip ruolo
> non si confonde mai con il chip *stato* (online/offline); (b) si usano le
> varianti **tenui** (`bg-{semantic}/10 text-{semantic} border border-{semantic}/20`),
> mai il colore pieno; (c) i nomi dei ruoli li definisce il progetto, qui non se
> ne prescrivono di specifici.

### 6.2 — Sidebar (da `md` in su: `w-52` espansa / `w-14` ridotta)

Larghezza espansa `w-52` (208px), ridotta `w-14` (56px, basta per icona +
padding). Struttura dall'alto in basso: gruppi di voci (pattern `NavGroup`, sez.
7.6), un'area flessibile che spinge in basso, un footer con il pulsante di
riduzione e la versione.

- **Voce attiva**: sfondo tenue `bg-primary/10` **+** striscia a sinistra
  `border-l-2 border-primary` + testo `text-primary font-medium`. La striscia
  aiuta lo scorrimento rapido quando le voci sono molte. Mai contemporaneamente
  bordo *e* sfondo pieno: o sfondo tenue + striscia, o solo sfondo tenue.
- **Voce inattiva**: testo `text-muted-foreground`, hover `hover:bg-muted/50`.
  Sentito ma non invadente.
- **Tooltip su ridotta**: quando la sidebar è ridotta, ogni voce mostra il
  proprio nome come tooltip (attributo `title`).
- **Contatori**: pattern `NavBadge` (sez. 7.7).
- **Pulsante riduci/espandi**: nel **footer** della sidebar (non nell'header, che
  resta pulito). Icone `PanelLeftClose` / `PanelLeftOpen`.
- **Su mobile** la sidebar diventa un overlay con apertura a "hamburger" (`lg:`),
  non resta fissa.

### 6.3 — Barra inferiore (mobile, `<md`)

Le voci principali del prodotto (max 4-5), icona + etichetta. Voce attiva: icona
e etichetta `text-primary`. Rispetta la "safe area" in basso sui dispositivi con
notch. Tap target a piena larghezza, non solo l'icona.

### 6.4 — Slot assistente contestuale (opzionale)

Se il prodotto integra un **assistente contestuale** (un pannello di aiuto
opzionale), lo si aggancia come bottone flottante in basso a destra (`fixed
bottom-6 right-6`, cerchio `bg-primary`, icona `Sparkles`) che apre un pannello
laterale da destra. Pulsazione lenta solo da fermo. È **opzionale**: la maggior
parte dei progetti non lo ha.

---

## 7. Componenti compositi (i 10 pattern del web)

I "pattern compositi" sono **ricette di composizione**: dato un insieme di
componenti base (Button, Input, Card, Badge…) più un'intenzione (mostrare un
numero chiave, raggruppare avvisi per gravità, navigare per gruppi), il pattern
dice **come comporli** con dimensioni e gerarchie precise. Non sono codice da
copiare: sono il riferimento visivo. Sono più "opinionati" dei componenti base,
perché modificarli rompe la coerenza tra progetti.

> **Regola generale (dal cuore)**: l'icona importante non va mai "nuda". Quando
> un'icona ha un ruolo chiave (testata di una card statistica, voce attiva, stato
> vuoto), sta dentro un contenitore colorato coerente con la sua semantica
> ("icon box"). E una card mostra il proprio stato semantico (es. bordo colorato
> a sinistra) **solo se** quello stato esiste davvero. `vedi 16-design-core.md`.

### Tabella riassuntiva dei 10 pattern compositi

| # | Pattern | A cosa serve (in una riga) | Quando usarlo |
|---|---------|----------------------------|----------------|
| 7.1 | **StatCard** | Un numero chiave in evidenza, con icona colorata | Dashboard (4-6 tile), riepiloghi |
| 7.2 | **PageHeader** | Titolo + sottotitolo + azioni di una pagina | Ogni pagina applicativa |
| 7.3 | **AlarmCenter / AlertContainer** | Raggruppare avvisi per gravità | Quando esistono avvisi attivi da gestire |
| 7.4 | **EmptyState ricco** | Spiegare una lista vuota e cosa fare | Ogni lista/tab/ricerca che può essere vuota |
| 7.5 | **EntityCard** | Una entità di una collezione, come card | Liste di 5-30 elementi multi-attributo |
| 7.6 | **NavGroup** | Un gruppo di voci di sidebar con titoletto | Sidebar con più di 4 voci |
| 7.7 | **NavBadge** | Contatore su una voce di navigazione | Voci con un conteggio significativo |
| 7.8 | **BrandMark** | Far sapere "in che prodotto sono" | Topbar, sidebar, login, email |
| 7.9 | **HeroBanner** | Porta d'ingresso visiva (login/onboarding) | Solo pagine pubbliche d'ingresso |
| 7.10 | **CTA Group** | Azione primaria + secondarie con gerarchia | Form, footer di finestre, header |

---

### 7.1 — StatCard (tile statistico)

Tile con un numero/dato grande + etichetta + icona colorata laterale. Il pattern
più presente nelle dashboard.

**Anatomia**:
```
┌──────────────────────────────┐
│  ETICHETTA MAIUSCOLA   [icn] │ ← etichetta piccola + icona in icon box
│  42                          │ ← valore grande, tabular-nums
│  unità / sottotesto          │ ← contesto del numero
│  ▲ +3 vs ieri (opzionale)    │ ← trend opzionale
└──────────────────────────────┘
```

**Specifiche**:
| Slot | Specifica |
|------|-----------|
| Contenitore | `Card`, `p-4 md:p-5`, con `shadow-md` |
| Riga testata | `flex items-center justify-between mb-3` |
| Etichetta | `text-caption font-medium text-muted-foreground uppercase tracking-wide` |
| Icon box | `w-10 h-10 rounded-lg flex items-center justify-center bg-{semantic}/10` |
| Icona | `w-5 h-5 text-{semantic}` |
| Valore | `text-display-sm font-bold tabular-nums text-foreground leading-none` |
| Sottotesto | `text-caption text-muted-foreground mt-1` |
| Trend (opz.) | `text-caption text-{success\|danger} flex items-center gap-1 mt-3` con icona `TrendingUp`/`TrendingDown` |

**Varianti**: `default` (conteggio puro), `severity` (il colore dell'icona
riflette la gravità: rosso/ambra/verde), `withTrend` (confronto temporale),
`withSparkline` (mini-grafico di andamento, raro).

**Quando usarlo**: dashboard (`grid grid-cols-2 md:grid-cols-3 lg:grid-cols-4`),
header di lista quando il conteggio è un dato di lavoro ("8 in ritardo · 30 in
scadenza"). **Quando NON usarlo**: per un solo dato isolato (usa un badge o testo
grande); per dati subordinati a un'entità (usa l'`EntityCard`).

---

### 7.2 — PageHeader (testata di pagina)

Titolo + (sottotitolo | eyebrow | badge) + azioni a destra. La prima impressione
che l'utente riceve aprendo una pagina.

**Anatomia**:
```
┌───────────────────────────────────────────────────────┐
│ [icn]  EYEBROW                       [Azione 2] [CTA] │
│        Titolo della pagina                            │
│        120 elementi · 8 in ritardo                    │ ← sottotesto quantitativo
└───────────────────────────────────────────────────────┘
```

**Specifiche**:
| Slot | Specifica |
|------|-----------|
| Contenitore | `flex items-start justify-between gap-4 pb-4 border-b border-border mb-6` |
| Icona (opz.) | `w-7 h-7 text-primary` o variante semantica |
| Eyebrow (opz.) | `text-eyebrow text-muted-foreground uppercase tracking-wider mb-1` |
| Titolo | `text-display-sm font-semibold text-foreground leading-tight` (deciso) |
| Sottotitolo | `text-body-sm text-muted-foreground mt-1` |
| Azioni (dx) | `flex items-center gap-2 flex-shrink-0` |

**Regole anti-pattern**:
- **Max 2 azioni primarie**. Se ne servono di più, raggruppale in un menu "Altre
  azioni" (Dropdown). (Anti-pattern osservato dal vivo: troppe azioni primarie
  con colori disordinati che competono.)
- **Niente emoji** nel titolo.
- **Sottotesto quantitativo, non narrativo**: "120 attivi · 3 critici" sì, "Qui
  trovi tutti i tuoi elementi…" no.

**Quando usarlo**: ogni pagina applicativa. **Quando NON usarlo**: sotto-sezioni
della stessa pagina (usa un H2 + descrizione, senza il bordo inferiore).

---

### 7.3 — AlarmCenter / AlertContainer (centro avvisi)

Contenitore che raggruppa avvisi per gravità: testata colorata + lista interna +
footer "vedi tutti". È la traduzione web del "contenitore di stato"
(`vedi 16-design-core.md`).

**Anatomia**:
```
┌────────────────────────────────────────────────────┐
│  [icn]  Centro avvisi              [Vedi tutti]     │ ← testata severità
│         3 attivi · 2 in gestione                   │
│  ATTIVI                                             │ ← sotto-sezione
│  ┌──────────────┐  ┌──────────────┐                │
│  │  Avviso 1    │  │  Avviso 2    │  (griglia 2)    │
│  └──────────────┘  └──────────────┘                │
│  IN GESTIONE                                        │
│  ┌────────────────────────────────────────────┐    │
│  │  Riga avviso gestito (+ azione "Risolvi")  │    │
│  └────────────────────────────────────────────┘    │
└────────────────────────────────────────────────────┘
```

> ### Correzione dal vivo — la testata NON è un blocco di colore pieno
>
> Calibrata sullo stesso prodotto di monitoraggio. La versione "alta" usava una
> testata a **colore pieno** (o gradiente) saturo. Su molte apparizioni
> quotidiane diventa rumore e domina la pagina.
>
> **Versione corretta**: il contenitore usa **sfondo tenue + bordo colorato +
> accenti**, non il blocco pieno.
> - Contenitore esterno: `bg-card rounded-xl shadow-md border-2 border-{severity}/20`.
> - Testata: `bg-{severity}/10` con **icona e testo** nel colore della severità
>   (`text-{severity}`), **non** `bg-{severity}` pieno e **mai** gradiente.
> - Etichette delle sotto-sezioni: `text-eyebrow text-{severity} uppercase
>   tracking-wider` (es. "ATTIVI" in rosso, "IN GESTIONE" in ambra).
> - Griglia avvisi attivi: `grid grid-cols-1 lg:grid-cols-2 gap-3`.
>
> Il colore pieno si riserva **solo** al bottone di azione o a un singolo avviso
> urgente esplicito. Questa è la stessa regola della sezione 3 (Severity).

**Varianti per severità**: `danger` (avvisi critici), `warning` (attenzione),
`info` (informazioni di sistema).

**Quando usarlo**: in cima a una dashboard **quando esistono** avvisi attivi —
rendering condizionale: se non ce ne sono, la sezione **non compare** (niente
placeholder vuoto, fa rumore per niente). **Quando NON usarlo**: per un solo
avviso isolato (usa una `Card` con stato o un toast); per liste lunghe e
omogenee (>20) usa una DataTable con severity coding.

---

### 7.4 — EmptyState ricco (stato vuoto)

Contenitore + icona grande in icon box + titolo + descrizione + azione. Spiega
*perché* è vuoto e *cosa fare* (`vedi 16-design-core.md`, "UX di base"). È la
versione ricca rispetto al povero "icona grigia + testo grigio" dei boilerplate.

**Anatomia**:
```
┌──────────────────────────────────────────────┐
│              ╭─────╮                          │
│              │ icn │   ← icona grande in cerchio
│              ╰─────╯                          │
│        Titolo (cosa manca)                    │
│        Descrizione (perché / cosa fare)       │
│        [Azione]   ← opzionale                 │
└──────────────────────────────────────────────┘
```

**Specifiche**:
| Slot | Specifica |
|------|-----------|
| Contenitore | `flex flex-col items-center justify-center text-center py-12 px-6 bg-{semantic}/5 border border-{semantic}/20 rounded-xl` |
| Icon box | `w-16 h-16 rounded-full bg-{semantic}/10 flex items-center justify-center mb-4` |
| Icona | `w-8 h-8 text-{semantic}` |
| Titolo | `text-card-title font-semibold text-foreground mb-2` |
| Descrizione | `text-body text-muted-foreground max-w-md mx-auto mb-6` |
| Azione (opz.) | `Button` primario o ghost a seconda del contesto |

**Varianti per sentiment**:
| Variante | Quando | Esempio generico |
|----------|--------|------------------|
| `success` (verde) | Vuoto = buona notizia | "Niente in ritardo. Tutto in regola." |
| `info` (accento) | Vuoto = invito ad agire | "Nessun elemento ancora. Aggiungi il primo." |
| `neutral` (grigio) | Filtro che non trova nulla | "Nessun risultato per la ricerca." |
| `warning` (ambra) | Vuoto inatteso | "Il dispositivo non risponde. Verifica la connessione." |

**Regola d'oro**: ogni lista del prodotto **deve** avere un EmptyState ricco, mai
un'area grigia silenziosa. **Quando NON usarlo**: durante il caricamento (usa lo
skeleton); in caso di errore di rete (usa ErrorState con "Riprova").

---

### 7.5 — EntityCard (card di un'entità)

Card che mostra **una entità di dominio** (un cliente, un ordine, un dispositivo,
un utente, un progetto…) in una griglia o lista: avatar/icona + informazioni
gerarchiche + badge di stato + azioni inline.

**Anatomia**:
```
┌─────────────────────────────────────────────────┐
│  Titolo entità              [icn] [icn] [icn]   │ ← titolo + azioni inline
│  sotto-info (2-3 attributi)                     │
│  ┌─────┐ ┌─────┐ ┌─────┐                         │ ← corpo: metriche o badge
│  │ M1  │ │ M2  │ │ M3  │                         │
│  └─────┘ └─────┘ └─────┘                         │
│  ⏱ aggiornato 3 min fa        [⚠ stato]          │ ← footer: timestamp + badge
└─────────────────────────────────────────────────┘
```

**Specifiche**:
| Slot | Specifica |
|------|-----------|
| Contenitore | `relative bg-card rounded-xl shadow-sm border-2 border-border p-4 cursor-pointer transition-all duration-normal hover:shadow-md hover:border-hairline-strong` |
| Contenitore con stato critico | aggiungi `border-danger` (+ `animate-pulse` solo se davvero critico persistente) |
| Contenitore con dato stantio | aggiungi `border-warning` |
| Titolo | `text-card-title font-semibold text-foreground leading-tight truncate` |
| Sotto-info | `text-body-sm text-muted-foreground` |
| Azioni inline | `flex items-center gap-2` con IconButton ghost |
| Footer | `flex items-center justify-between text-caption text-muted-foreground mt-4 pt-3 border-t border-border` |

**Varianti**: `monitoring` (corpo = griglia di metriche con severity coding),
`summary` (corpo = 2-3 coppie chiave/valore), `actionable` (corpo con azione
primaria in mezzo), `compact` (solo testata + footer, per liste dense su mobile).

**Quando usarlo**: liste di **5-30** entità dove ogni elemento ha più attributi
visibili insieme. **Quando NON usarlo**: liste di 100+ entità omogenee → usa la
**DataTable**; singola entità → usa il pattern Dettaglio (sez. 8.3).

> **Regola anti-pattern (microinterazioni)**: niente `hover:scale-105` su card in
> liste con più di ~10 elementi: è disorientante. Usa `hover:shadow-md
> hover:border-hairline-strong` senza scale. Lo zoom leggero (`hover:scale-[1.02]`)
> è ammesso solo su griglie brevi o card singole prominenti.

---

### 7.6 — NavGroup (gruppo di sidebar)

Gruppo di voci di sidebar coerenti, separate da un titoletto ("eyebrow") +
separatore. Dà struttura semantica alla sidebar (raggruppa voci sparse in
macro-categorie).

**Anatomia**:
```
─── separatore ──────────
TITOLETTO GRUPPO          ← eyebrow maiuscoletto
  [icn] Voce 1      [8]   ← con NavBadge opzionale
  [icn] Voce 2
  [icn] Voce 3      [3]
```

**Specifiche**: separatore `<hr className="my-4 border-t border-border" />` (si
salta se è il primo gruppo); titoletto `px-4 text-xs font-semibold uppercase
tracking-wider mb-2 text-muted-foreground`; voci in `space-y-1`.

**Varianti per scopo**: `primary` (voci di lavoro quotidiano), `secondary`
(reportistica/configurazione), `admin` (voci visibili solo a ruoli con privilegi),
`dev` (voci visibili solo in modalità sviluppo: titoletto in **ambra**
`text-warning`, per segnalare visivamente che "non sono funzioni di prodotto").

**Quando usarlo**: sidebar con più di 4 voci. **Quando NON usarlo**: nella barra
inferiore mobile (gerarchia inutile in 4-5 slot).

---

### 7.7 — NavBadge (contatore su voce)

Badge contatore su una voce di navigazione: comunica "ci sono N cose da fare qui"
senza che l'utente entri.

**Specifiche**: `inline-flex items-center justify-center min-w-[20px] h-5 px-1.5
rounded-pill text-caption font-semibold tabular-nums`. Colore per severità (in
**tenue** o pieno a seconda del caso, vedi sotto): `bg-danger text-{...}`
(critico), `bg-warning` (attenzione), `bg-primary` (info), grigio (neutro).
`animate-pulse` **solo** se conteggio > 5 **e** severità critica. Tronca a "9+"
oltre il 9.

**Doppia posizione** (regola web):
- **Sidebar espansa**: badge **inline**, a destra dell'etichetta. Più leggibile,
  mostra il numero esatto.
- **Sidebar ridotta**: badge **sovrapposto** all'icona (`absolute -top-1 -right-1`),
  così resta visibile senza etichetta.

**Quando usarlo**: voci con un conteggio dinamico utile a dare priorità ("In
arrivo 12", "In ritardo 3"), e tab di pagine multi-tab. **Quando NON usarlo**: su
voci statiche ("Impostazioni"), o per numeri grandi (>99): usa "99+" o sposta il
dato in una StatCard. **Regola**: mai icone dentro il badge, solo numeri — è un
quantificatore.

---

### 7.8 — BrandMark (marchio del prodotto)

Identità visiva del prodotto: contenitore icona + nome. Compare in più contesti
(login, topbar, sidebar) e **deve** essere coerente.

**Specifiche per variante**:
| Variante | Contenitore | Icona | Nome | Quando |
|----------|-------------|-------|------|--------|
| `topbar` | `w-8 h-8 rounded-lg bg-primary` | `w-5 h-5 text-primary-foreground` | `text-body-sm font-semibold tracking-tight` da `sm`+ | Topbar |
| `sidebar-expanded` | come topbar | come topbar | `text-body-lg font-semibold` | Header sidebar espansa |
| `sidebar-collapsed` | solo il contenitore icona | come topbar | nessuno | Header sidebar ridotta |
| `login-splash` | `w-16 h-16 rounded-full bg-primary/10` | `w-8 h-8 text-primary` | sotto: `text-display-md font-semibold mt-4` | Login, registrazione |

L'icona la sceglie il progetto (un'icona Lucide semanticamente coerente con il
prodotto). **Regola d'oro**: il contenitore è **sempre** `bg-primary` (l'accento)
in tutti i contesti — è il "sigillo" del prodotto; cambia l'icona tra prodotti
diversi, non il colore.

**Quando usarlo**: ogni pagina applicativa, ogni splash, ogni email transazionale
— l'utente deve sempre sapere "in che prodotto sono". **Quando NON usarlo**:
dentro finestre/dialoghi (il contesto è già chiaro).

---

### 7.9 — HeroBanner / IntroSection (porta d'ingresso)

Banner introduttivo per pagine **pubbliche** (login, registrazione, onboarding):
brand prominente + titolo evocativo + descrizione + gruppo di azioni. È la "porta
d'ingresso visiva" al prodotto.

**Specifiche**: contenitore `bg-primary/5 border border-primary/10 rounded-2xl
p-8 md:p-12`; brand mark variante `login-splash`; claim `text-display-lg
font-semibold tracking-tight mt-6`; descrizione `text-body-lg text-muted-foreground
mt-2 max-w-xl`; gruppo azioni (pattern 7.10) `flex flex-wrap gap-3 mt-8`.

**Quando usarlo**: solo per pagine "porta d'ingresso". **Quando NON usarlo**:
dentro l'app autenticata (l'utente conosce già il prodotto). **Regola
anti-pattern**: il claim è **operativo** e sobrio, mai markettaro o paternalistico
(no "Rivoluziona il tuo lavoro!").

---

### 7.10 — CTA Group (gruppo di azioni)

Raggruppamento di bottoni con gerarchia: **1** azione primaria + 1-2 secondarie +
eventuale link. Ricorre in form, footer di finestre, header, hero banner.

**Specifiche per variante**:
| Variante | Contenitore | Uso |
|----------|-------------|-----|
| `horizontal` | `flex items-center gap-3` | Header, barre di azione |
| `horizontal-end` | `flex items-center justify-end gap-3` | Footer di finestra (standard) |
| `stack` | `flex flex-col gap-3` con bottoni `w-full` | Submit di form + secondario |
| `responsive` | `flex flex-col sm:flex-row gap-3` | Stack su mobile, riga su desktop |

**Gerarchia (regola permanente)**: (1) **un solo** primario nel gruppo, mai due
che competono; (2) il primario va a **destra** (in orizzontale) o **in alto** (in
stack); (3) i secondari accompagnano, non dominano; (4) link/ghost per le azioni
minori ("Annulla").

> **Regola anti-pattern**: niente colori arbitrari per differenziare due azioni
> (es. verde per una, viola per un'altra). La palette è quella della sezione 2 e
> la semantica quella della 3. Per distinguere due azioni speculari (es. "Chiama"
> vs "Scrivi") usa **icone diverse + variante secondaria**, non colori semantici
> diversi.

---

## 8. Pattern di pagina (i 5 layout canonici)

Una pagina è una **composizione** di pattern compositi (sez. 7) + scelte di
layout. Non è "un insieme di componenti a caso": ha un ruolo definito nel flusso
di lavoro.

### Tabella riassuntiva dei 5 pattern di pagina

| # | Pattern | Ruolo | Composizione tipica |
|---|---------|-------|---------------------|
| 8.1 | **Dashboard** | Entry point: "stato del mondo" a colpo d'occhio | PageHeader + griglia StatCard + AlarmCenter (condizionale) + sezione principale |
| 8.2 | **Lista** | "Tutti i [X]" con filtri e ricerca | PageHeader + FilterBar in card + DataTable o griglia di EntityCard + EmptyState |
| 8.3 | **Dettaglio** | Singola entità con sezioni navigabili | Header ricco + TabNav + contenuto della tab |
| 8.4 | **Login** | Porta d'ingresso pubblica | Pagina centrata + BrandMark splash + form + CTA Group + (opz. HeroBanner) |
| 8.5 | **Gestione** | CRUD amministrativo tabellare | PageHeader + FilterBar + DataTable + Modal/Drawer + ConfirmDialog |

---

### 8.1 — Pagina Dashboard

Entry point dopo il login: comunica lo "stato del mondo" in un colpo d'occhio.

**Cosa la rende riconoscibile**:
1. **PageHeader senza azione primaria** (la dashboard riassume, non chiede di
   agire).
2. **Griglia di StatCard** a 4 colonne (3 su tablet, 2 su mobile): il "battito"
   del prodotto.
3. **AlarmCenter a rendering condizionale**: appare **solo** se ci sono avvisi
   attivi; se non ce ne sono, la sezione non si vede (niente placeholder vuoto).
4. **Sezione principale** dipendente dal prodotto, ma sempre presente (es. una
   tabella compatta "Da fare oggi", una griglia di card di monitoraggio).
5. **Azione di navigazione in fondo**, opzionale: "Vai a [area]" — invito a
   uscire dalla dashboard dopo aver "letto lo stato".

Griglia statistiche di riferimento: `grid grid-cols-2 md:grid-cols-4 gap-3
md:gap-6`, mobile-first. Numero di StatCard: 4 di norma, fino a 6 se la "scena"
del prodotto è ricca di metriche.

---

### 8.2 — Pagina Lista

Vista "tutti i [X]" del prodotto: filtri + ricerca + (griglia di card | DataTable)
+ stato vuoto.

**Cosa la rende riconoscibile**:
1. **FilterBar dentro una card** (`bg-card border border-border rounded-xl p-4
   mb-4`), non spalmata in alto: crea un'isola "qui regoli cosa vedi".
2. **Campo di ricerca con icona inline a sinistra** (`pl-10 pr-4 py-2`, icona
   `absolute left-3`).
3. **Filtri secondari come "segmented control"** (gruppo di chip su sfondo
   `bg-muted`, attivo `bg-card shadow-sm`) o chip filtro singoli.
4. **Conteggio + chip dei filtri attivi** sopra la lista, ciascuno con "× rimuovi".
5. **Due stati vuoti diversi**: lista globalmente vuota (variante `info`, azione
   "Crea il primo") vs filtri che restringono (variante `neutral`, "rimuovi
   filtri").

**Scelta griglia vs tabella**: griglia di EntityCard per **5-30** elementi;
**DataTable** per liste >30, con testata "appiccicata" sotto la topbar (`sticky
top-12`), `py-3` sulle righe, `text-body-sm` sulle celle, e una colonna finale di
azioni con un menu "Altre azioni" (Dropdown) — mai molti bottoni inline (rumore).
Densità target: 25-30 righe utili in 1080p.

---

### 8.3 — Pagina Dettaglio

Singola entità con tutti i suoi dati organizzati in sezioni navigabili.

**Cosa la rende riconoscibile**:
1. **Header ricco prominente** (una card) con avatar/icona grande (≈64px), titolo
   H1, "info pill" inline (chip non interattivi con info densa) e, in alto a
   destra, l'azione primaria.
2. **Info pill** come chip non cliccabili: `inline-flex items-center gap-1.5 px-2
   py-0.5 rounded-pill text-caption`, colorate per severità quando ha senso.
3. **TabNav sotto l'header**: la tab attiva ha la sottolineatura nell'accento
   (`border-b-2 border-primary text-primary`); badge contatore opzionale su
   alcune tab.
4. **Contenuto della tab** in `role="tabpanel"`, con padding aerato (`p-6`); mai
   contenuto sotto la piega senza un titolo di sezione.
5. **Azione "appiccicata" in alto a destra**: azione primaria + menu "Altre
   azioni"; resta visibile durante lo scroll. Le azioni **irreversibili** (es.
   eliminazione) hanno variante `danger` dentro il menu.

---

### 8.4 — Pagina Login

Porta d'ingresso pubblica: pagina centrata, brand prominente, form pulito, azione
primaria a piena larghezza, link secondario.

**Cosa la rende riconoscibile**:
1. **Sfondo con gradiente sobrio** `from-background via-muted to-background` —
   **non** un gradiente consumer acceso. Crea profondità senza chiasso. (I
   gradienti sono ammessi **solo** qui, mai dentro il guscio applicativo.)
2. **Card centrata** `max-w-md rounded-2xl shadow-lg`.
3. **BrandMark variante `login-splash`** in alto, con eventuale tagline sobria.
4. **Input con icona interna** (icona `absolute left-3 top-1/2 -translate-y-1/2
   text-muted-foreground`, input `pl-10 pr-4 py-3`).
5. **Azione primaria a piena larghezza** + link secondario sotto (pattern CTA
   Group `stack`).

**Coerenza login/registrazione**: la pagina di registrazione deve essere
allineata visivamente al login (stesso sfondo, stessa card, stesso BrandMark),
non una versione "minore". (Anti-pattern osservato dal vivo: registrazione
trascurata rispetto al login.)

---

### 8.5 — Pagina Gestione

CRUD amministrativo tabellare con azioni inline.

**Cosa la rende riconoscibile**:
1. **DataTable obbligatoria** (mai griglia di card per le pagine admin): colonne
   fisse, ordinabili, colonne secondarie nascoste su mobile.
2. **Chip ruolo/stato inline** nella riga (badge con severity coding, in varianti
   tenui).
3. **Colonna azioni in fondo** con un IconButton ghost `MoreVertical` che apre un
   Dropdown ("Modifica", "Reimposta", "Sospendi", "Elimina"). Mai più bottoni
   inline.
4. **Modal/Drawer per crea/modifica** (Modal per form brevi, Drawer per form
   lunghi, >5 campi).
5. **ConfirmDialog SEMPRE per l'eliminazione**, mai eliminazione inline diretta:
   variante `danger`, testo esplicito ("Eliminare l'elemento X? L'azione è
   irreversibile.").

Form di creazione con `FormField` + validazione Zod: errori inline, bottone
"Salva" disabilitato finché il form non è valido.

---

## 9. Catalogo dei componenti base (shadcn/ui)

Tutti i componenti standard usano **shadcn/ui**, copiati in `src/components/ui/`
(mai importati da `node_modules`). La personalizzazione avviene **solo** via i
token (le CSS variables), mai modificando il sorgente del componente. **Vietato**
rifare un componente che esiste già: se serve una variante, si **estende**.

**Vietato l'HTML grezzo** al posto del componente:
- `<button>` nativo → `<Button>`
- `<input>` nativo → `<Input>`
- `<select>` nativo → `<Select>`
- `<table>` grezza → `<DataTable>` (wrapper) o `<Table>`
- `<svg>` custom per icone → **Lucide React** (`import { Heart } from 'lucide-react'`)
- `alert()` / `confirm()` / `prompt()` del browser → `<Modal>` / `<ConfirmDialog>`
  / toast (Sonner)

**Lista minima** dei componenti base attesi in ogni progetto:

| Categoria | Componenti |
|-----------|------------|
| **Atomici** | Button, IconButton (wrapper), Input, Textarea, Select, Checkbox, Radio, Switch, Badge, Avatar, Spinner, Skeleton, ProgressBar |
| **Layout** | Container, Stack, Grid, Card, Tabs |
| **Overlay** | Dialog (= Modal), Sheet (= Drawer), DropdownMenu, Tooltip, AlertDialog (= ConfirmDialog) |
| **Compositi base** | DataTable (wrapper su TanStack Table), EmptyState, ErrorState, FormField (wrapper con label + required + errore inline + helper) |

**Comportamenti condivisi**: ogni componente supporta tema chiaro e scuro via
token (mai colori scritti a mano); l'anello di focus è `shadow-focus-ring` su
`:focus-visible` (mai su `:focus` da mouse); lo stato disabilitato è
`opacity-50 cursor-not-allowed`; in caricamento i bottoni mostrano uno spinner
inline e i contenuti uno skeleton.

**Dimensioni standard delle icone Lucide**: `w-4 h-4` (xs), `w-5 h-5` (default),
`w-6 h-6` (lg), `w-8 h-8` (xl). Per una nuova icona, scegli quella semanticamente
più vicina; non improvvisare un SVG.

---

## 10. Microinterazioni sul web

Discrete, semantiche, mai gratuite (`vedi 16-design-core.md`, principio 8).

### 10.1 — Stati interattivi

| Stato | Pattern | Quando |
|-------|---------|--------|
| **Hover** | `hover:bg-muted/50` (o `hover:bg-surface-2`) sugli elementi cliccabili; `hover:opacity-80` per icone semplici | Default su ogni elemento cliccabile |
| **Active** | `active:scale-[0.98]` (compressione minima, non 0.95) | Bottoni e tap |
| **Focus-visible** | `focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2` | Tastiera (mai mouse) |
| **Disabled** | `opacity-50 cursor-not-allowed` | Elementi non azionabili |
| **Loading** | spinner inline nel bottone | Submit in corso |

### 10.2 — Animazioni di ingresso/uscita

`fade-in` (200ms) per gli overlay; `scale-in` (200ms, da 0.95 a 1.0) per le
finestre centrate; `slide-left` per i pannelli da destra; `slide-up` per i
pannelli mobile dal basso; `shimmer` (1.5s) per gli skeleton.

### 10.3 — Pulsazione (`animate-pulse`)

**Solo** stati critici persistenti (un avviso critico non gestito, un contatore
critico in sidebar quando supera una soglia). **Mai**: sugli skeleton (usa
`shimmer`), sui bottoni in attesa (usa lo spinner), sull'hover delle card (usa
`transition-colors`), sulle notifiche generiche.

---

## 11. Microcopy e lessico (web)

Applica il principio 10 del cuore (`vedi 16-design-core.md`). In sintesi, valido
su tutti i progetti:

- **Italiano** in tutta l'interfaccia (testi, messaggi, toast, conferme). Solo i
  nomi di codice (variabili, classi, funzioni, file) restano in inglese.
- **Niente anglicismi** dietro le etichette: "Invia" non "Submit", "Annulla" non
  "Cancel", "Salva" non "Save", "Impostazioni" non "Settings".
- **Numeri concreti**: "3 elementi in ritardo", non "alcuni elementi".
- **Conferme** = titolo imperativo breve + una riga di descrizione + bottoni
  espliciti. Mai "Sei sicuro?" → "Confermi la rimozione di [X]?".
- **Errori** = cosa è successo + cosa fare. Mai "Errore generico" → "Connessione
  interrotta. Riprova tra qualche secondo."
- **Niente emoji** nell'interfaccia di produzione, niente esclamativi gratuiti,
  niente paternalismo.

> Il vocabolario **specifico di dominio** (i termini del singolo settore) lo
> definisce il progetto, nei suoi documenti di microcopy. Questo capitolo è
> neutro: non prescrive termini di settore.

---

## 12. Accessibilità sul web

L'interfaccia sta in mano a utenti diversi, su dispositivi diversi (tablet,
smartphone, PC). L'accessibilità non è un di-più. Applica il principio 9 del cuore
(`vedi 16-design-core.md`).

### 12.1 — Contrasto

- **WCAG AA come minimo** per tutti i testi. ("WCAG AA" è lo standard
  internazionale di leggibilità: fissa un rapporto minimo di contrasto tra testo
  e sfondo.)
- Il testo `body` non scende sotto i 14px (`text-body-sm`); il `caption` (12px)
  solo per metadati non critici.

> ### Correzione dal vivo — i testi secondari restano leggibili
>
> Calibrata su un prodotto reale: i testi **secondari** (orari, etichette, righe
> d'aiuto, note) non vanno **sbiaditi** per "alleggerire" la pagina. Devono
> rispettare il contrasto **WCAG AA** come il testo principale. In pratica: si
> usa `muted-foreground` (un grigio leggibile), **non** un grigio chiarissimo su
> sfondo chiaro. Mai testo grigio chiaro su superficie grigio chiara. Questa è la
> stessa raccomandazione dei livelli di testo (sez. 2.5) e del cuore (principio 9).

### 12.2 — Focus, tastiera, lettori di schermo

- **Anello di focus** sistematico via `:focus-visible` (mai su `:focus` da mouse).
- **Focus trap** dentro finestre e pannelli (il Tab cicla solo lì dentro); **Esc**
  chiude; **auto-focus** sul primo campo all'apertura; blocco dello scroll della
  pagina quando una finestra è aperta.
- **Etichette per le icone**: `aria-label` su ogni bottone che ha solo l'icona.
- `aria-current="page"` sulla voce di sidebar attiva; `role="alert"` su toast di
  errore e su error state; `aria-live="polite"` sui contenuti che cambiano da
  soli (es. i contatori); `aria-describedby` per collegare un campo al suo
  messaggio di errore/aiuto.

### 12.3 — Movimento e tap target

- **`prefers-reduced-motion`** rispettato sistematicamente: quando l'utente lo
  richiede, le transizioni si riducono a ~0. Mai animazioni decorative (parallax,
  autoplay).
- **Tap target ≥ 44×44px** per bottoni e icone toccabili; nella barra inferiore,
  area di tocco a piena larghezza, non solo l'icona.

---

## 13. Convenzioni dei token (web)

### 13.1 — CSS variables come unica fonte

Tutti i colori vivono come CSS variables in `:root` (chiaro) e `.dark` (scuro);
Tailwind referenzia le variabili, non i valori. **Mai** un valore scritto a mano
in una classe (`bg-[#2563eb]`): sempre il token (`bg-primary`).

### 13.2 — I componenti non leggono le variables direttamente

I componenti React non leggono mai le CSS variables a mano: sempre tramite le
classi Tailwind (`bg-primary`, `text-foreground`). Così cambiare un token cambia
tutto in un colpo solo.

### 13.3 — Naming dei token

| Schema | Esempio | Per |
|--------|---------|-----|
| semantico | `--primary`, `--destructive` | Colori semantici e accento |
| superficie a livelli | `--surface-1`, `--surface-2` | Scala delle superfici |
| testo a livelli | `--foreground`, `--muted-foreground` | Scala del testo |
| stato visivo | `--ring`, `--border` | Stati e bordi |

### 13.4 — Stacking (z-index): una scala, definita una volta

| Token | Valore | Uso |
|-------|--------|-----|
| `z-base` | 0 | Default |
| `z-dropdown` | 100 | Menu a tendina |
| `z-topbar` | 150 | Topbar fissa |
| `z-sticky` | 200 | Testate e barre filtri "appiccicate" |
| `z-overlay` | 300 | Sfondo dietro finestre |
| `z-modal` | 400 | Finestre |
| `z-toast` | 500 | Notifiche temporanee |
| `z-tooltip` | 600 | Tooltip |

**Mai** uno `z-9999` improvvisato.

---

## 14. Lista di controllo (specifica web)

Estende la lista del cuore (`vedi 16-design-core.md`, "In sintesi") con i punti
specifici dello stack web. Un frontend web di Villa rispetta **tutti** questi
punti:

- [ ] Stack: React + Vite + TypeScript + Tailwind + shadcn/ui + Lucide + Inter.
- [ ] Colori come **CSS variables HSL** (token); nessun valore scritto a mano nei
      `.tsx`, nessuna classe-colore generica di Tailwind nei componenti.
- [ ] **Un solo accento** (`primary`), usato solo per le azioni; gli stati hanno
      i loro colori (`success`/`warning`/`danger`/`info`).
- [ ] **Severity coding** costante; i contenitori di stato critico usano **sfondo
      tenue + bordo + accenti**, mai il blocco di colore pieno.
- [ ] Nessun **HTML grezzo** (button/input/select/table/svg/alert): sempre i
      componenti shadcn + Lucide.
- [ ] **Inter** caricato dal prodotto; scala tipografica a token; **tabular-nums**
      sui dati numerici; titoli **decisi**.
- [ ] Spaziature/raggi/ombre a **scala**; card con ombra (mai piatte); densità
      25-30 righe utili in 1080p.
- [ ] **Tema chiaro e scuro** via classe `.dark`; responsive mobile-first.
- [ ] **Microinterazioni** discrete; `animate-pulse` solo per i critici;
      `prefers-reduced-motion` rispettato.
- [ ] **Accessibilità**: contrasto WCAG AA (anche per i testi secondari, **non**
      sbiaditi), focus-visible, `aria-label` sulle icone, tap target ≥ 44px.
- [ ] **Italiano** in UI, errori specifici, niente emoji/paternalismi.
- [ ] Gli **stati** (caricamento, vuoto, errore, successo, primo uso) ci sono
      tutti; ogni lista ha un **EmptyState ricco**.
- [ ] I **10 pattern compositi** e i **5 pattern di pagina** sono usati come
      riferimento dove pertinenti.

---

*Capitolo mantenuto in `.claude/metodo-villa/17-design-web.md`. È la
specializzazione web del cuore comune `16-design-core.md`. Per il mobile vedi
`18-design-mobile.md`. Le regole di token/stack qui descritte sono coerenti con
la skill `seeding-visivo-web` e il suo system-prompt anti-piattezza.*
