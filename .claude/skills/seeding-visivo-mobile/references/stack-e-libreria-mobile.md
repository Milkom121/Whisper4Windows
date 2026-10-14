# Stack mobile + libreria componenti "Villa mobile" + token

> **Cosa contiene**: la specifica **operativa** dello stack mobile e degli
> artefatti da possedere in casa. È il complemento "ingegneristico" del manuale di
> stile `.claude/metodo-villa/18-design-mobile.md`: quello dice *come deve apparire
> e comportarsi* un'app mobile Villa; questo dice *con cosa la si costruisce* — lo
> stack con le versioni, i **token Dart** concreti (la scala di spaziature,
> raggi, elevazioni, durate), e l'**inventario** dei componenti compositi "Villa
> mobile".
>
> **Da dove viene**: distillato dal comune di due app Flutter reali. La scala di
> token centralizzata è ripresa dall'app che già la possedeva (l'altra le aveva
> sparse inline: è il suo buco dichiarato) e riscritta in forma neutra. La libreria
> componenti sistematizza widget oggi "sparsi" (barre, card, tile) in un inventario
> posseduto e coerente.

---

## 1. Stack mobile (versioni pinnate)

Lo stack è **fisso** (decisione D4 del piano). Le versioni sono pinnate per
coerenza tra progetti; si aggiornano solo su richiesta esplicita o per
vulnerabilità.

| Livello | Tecnologia | Versione | Note |
|---------|------------|----------|------|
| Framework | **Flutter** | SDK `^3.6.0` | Allineato alle due fonti |
| Linguaggio | **Dart** | incluso in Flutter | |
| Componenti UI | **Material 3** | `useMaterial3: true` | Standard, vestito dal tema |
| Tipografia | **google_fonts** | `^6.1.0` | Inter (testo) + monospazio (dati) |
| Responsività | **sizer** | `^2.0.15` | Adatta le misure agli schermi |
| Icone | **Material Icons** (`Icons.*`) | incluso | Una sola famiglia |

**`pubspec.yaml` (estratto di riferimento)**:

```yaml
environment:
  sdk: ">=3.6.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  google_fonts: ^6.1.0
  sizer: ^2.0.15
  # gestione stato: UNA sola per progetto (provider | flutter_riverpod | flutter_bloc)
```

**Aggancio del tema** (in `main.dart`): i due temi del file `AppTheme` vanno
agganciati a `MaterialApp`, mai colori a mano nelle schermate.

```dart
MaterialApp(
  theme: AppTheme.lightTheme,
  darkTheme: AppTheme.darkTheme,
  themeMode: ThemeMode.system, // o la scelta dell'utente
  // ...
);
```

> **Vincolo del guardrail (vedi `guardrail-flutter.sh`)**: deve esistere un file
> `theme/app_theme.dart` con `lightTheme` e `darkTheme`, e `MaterialApp` deve
> agganciarli. Questo aggancio è uno degli 8 check.

### 1.1 — forui: opzione futura, non standard

**forui non è adottata.** Lo standard è **Material + tema centralizzato**, perché
è ciò che le due app reali e curate usano (cementare forui sarebbe una scommessa
non validata e incoerente col materiale di partenza). forui resta **documentata
come opzione futura**: la si valuterà solo se un progetto la richiederà
esplicitamente. Fino ad allora, Material. (`vedi 18-design-mobile.md`, sez. 1.1.)

---

## 2. Token Dart centralizzati

Tutte le misure vivono come **costanti nominate**, mai valori improvvisati nei
widget. Sono il gemello mobile delle `spacing`/`radius`/`shadow` del Tailwind web.
Questi token sono il pezzo che una delle due fonti **non aveva** (misure sparse
inline): qui diventano regola.

### 2.1 — Scala di spaziature (multipli di 4)

```dart
/// Spaziature centralizzate. Scala a multipli di 4.
/// Uso: padding, margin, gap tra widget. Mai numeri a mano nei widget.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;   // micro-gap, padding interni stretti
  static const double sm = 8;   // gap tra elementi vicini
  static const double md = 16;  // padding standard delle card, gap di sezione
  static const double lg = 24;  // separazione tra blocchi
  static const double xl = 32;  // margini ampi, spazi d'ingresso
  static const double xxl = 48; // spazi molto ampi (raro)
}
```

### 2.2 — Raggi di smusso

```dart
/// Raggi di smusso centralizzati.
class AppRadius {
  AppRadius._();

  static const double sm = 4;   // chip, badge, checkbox
  static const double md = 8;   // bottoni, input, card piccole
  static const double lg = 12;  // card standard
  static const double xl = 16;  // bottom sheet, card grandi
}
```

### 2.3 — Elevazioni (ombre discrete)

```dart
/// Elevazioni centralizzate. Basse e coerenti, mai scenografiche.
class AppElevation {
  AppElevation._();

  static const double none = 0;   // app bar piatta, elementi a filo
  static const double low = 2;    // card
  static const double medium = 4; // FAB, elementi attivi
  static const double high = 8;   // bottom sheet, dialog, bottom nav
}
```

### 2.4 — Durate e curve delle animazioni

```dart
/// Durate e curve centralizzate. Brevi e sobrie.
class AppMotion {
  AppMotion._();

  static const Duration short = Duration(milliseconds: 150);    // micro-feedback
  static const Duration standard = Duration(milliseconds: 200); // transizioni normali
  static const Duration medium = Duration(milliseconds: 300);   // transizioni grandi (raro)

  static const Curve standardCurve = Curves.easeInOut; // default
  static const Curve enterCurve = Curves.easeOut;      // ingressi
}
```

### 2.5 — Bersagli toccabili (touch target)

```dart
/// Dimensioni minime dei bersagli toccabili (accessibilità).
class AppTouchTarget {
  AppTouchTarget._();

  static const double minimum = 48;     // minimo assoluto (regola WCAG/Material)
  static const double comfortable = 56; // azioni frequenti
  static const double large = 64;       // azioni primarie ampie
}
```

Tutti i bottoni del tema fissano `minimumSize: Size(AppTouchTarget.minimum,
AppTouchTarget.minimum)`.

---

## 3. Libreria componenti "Villa mobile"

L'inventario dei **componenti compositi** da possedere in casa: i mattoni
ricorrenti, costruiti **una volta** sopra Material + i token, e riusati ovunque.
Sono i gemelli dei 10 pattern compositi web. Oggi, nelle fonti, sono abbozzati e
sparsi (`CustomAppBar`, `CustomBottomBar`…); qui diventano un set coerente e
nominato.

> **Regola**: ogni componente legge **solo** dal tema (`Theme.of(context)`) e dai
> token (`AppSpacing`, `AppRadius`…). Nessun colore o misura a mano. Tutti
> supportano chiaro/scuro "gratis" perché non hardcodano nulla.

### 3.1 — Guscio e navigazione

| Componente | Responsabilità | Gemello web |
|------------|----------------|-------------|
| `AppScaffold` | Il guscio standard: `Scaffold` + `VillaAppBar` + `VillaBottomNav` + slot FAB, già coerenti | AppShell |
| `VillaAppBar` | Barra superiore a tema: titolo deciso, max 2-3 azioni, ombra solo allo scroll | Topbar |
| `VillaBottomNav` | Barra inferiore 3-5 voci (icona + etichetta), attiva sul `primary`, tipo fisso | Sidebar / BottomBar |
| `BrandMark` | Marchio del prodotto (icon box `primary` + nome), varianti splash/appbar | BrandMark |

```dart
/// Guscio standard di una schermata autenticata.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.bottomNav,
    this.floatingAction,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? bottomNav;
  final Widget? floatingAction;

  // build(): Scaffold con VillaAppBar(title, actions), body, bottomNav, FAB.
  // Implementazione concreta nel progetto: vedi golden-screens/.
}
```

### 3.2 — Dati e stato

| Componente | Responsabilità | Gemello web |
|------------|----------------|-------------|
| `StatTile` | Numero chiave + etichetta + icon box colorato; numero in **monospazio**; in riga da 2-3 | StatCard |
| `StatusBanner` | Avviso per gravità a **sfondo tenue + bordo + accenti** (mai blocco pieno); compare solo se serve | AlarmCenter |
| `StatusChip` | Etichetta di stato a colpo d'occhio, variante **tenue** per severità | Badge |
| `DataText` | Testo in **monospazio** per numeri/codici che si confrontano | tabular-nums |

```dart
/// Avviso di stato: sfondo tenue + bordo colorato + icona/testo nel colore.
/// MAI blocco di colore pieno (correzione dal vivo, vedi 18-design-mobile sez. 3).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.severity, // Severity.error | warning | success | info
    required this.message,
    this.onAction,
    this.actionLabel,
  });

  final Severity severity;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;

  // build(): Container con color: base.withValues(alpha: 0.10),
  //          border: base.withValues(alpha: 0.20), icona+testo in `base`.
}
```

### 3.3 — Collezioni e dettaglio

| Componente | Responsabilità | Gemello web |
|------------|----------------|-------------|
| `EntityCard` | Una entità in lista: titolo + sotto-info + chip di stato + azioni; bordo colorato **solo** se ha uno stato reale | EntityCard |
| `SectionHeader` | Titolo di sezione + eventuale azione (dentro il corpo, non l'AppBar) | PageHeader (interno) |
| `EmptyStateView` | Stato vuoto ricco: icon box + titolo + descrizione + azione; varianti per sentiment | EmptyState |
| `LoadingView` / `ErrorView` | Caricamento (scheletro/indicatore) ed errore (messaggio + "Riprova") | Skeleton / ErrorState |

### 3.4 — Azioni e overlay

| Componente | Responsabilità | Gemello web |
|------------|----------------|-------------|
| `ActionGroup` | Gerarchia di azioni: **un** primario (pieno) + secondario (testo/outline) | CTA Group |
| `AppBottomSheet` | Foglio inferiore con maniglia, angoli alti arrotondati, scrim | (Drawer/Sheet) |
| `ConfirmSheet` / `ConfirmDialog` | Conferma per azioni irreversibili (titolo + riga + bottoni espliciti) | ConfirmDialog |

```dart
/// Gruppo di azioni con gerarchia: un solo primario.
/// Il primario usa il `primary` del tema (mai un secondo accento).
class ActionGroup extends StatelessWidget {
  const ActionGroup({
    super.key,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.axis = Axis.vertical, // stack su mobile di default
  });

  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Axis axis;

  // build(): ElevatedButton(primary) + TextButton/OutlinedButton(secondary).
}
```

> **Severità come tipo, non come stringa.** Si definisce un `enum Severity { error,
> warning, success, info, neutral }` con una funzione che mappa la severità sul
> colore del tema (`error` → `colorScheme.error`, ecc.). Così `StatusBanner`,
> `StatusChip` e i bordi di `EntityCard` parlano la stessa lingua e non si
> introducono colori a mano.

---

## 4. Catalogo dei widget base (Material)

Sotto i componenti compositi ci sono i widget **Material standard**, vestiti dal
tema. Non si reinventano: si compongono. L'elenco completo e le regole ("vietato
il widget nudo non a tema") sono nel manuale: `vedi 18-design-mobile.md`, sez. 9.

In sintesi: azioni (`ElevatedButton`/`OutlinedButton`/`TextButton`/`IconButton`/
`FloatingActionButton`), input (`TextFormField`/`Switch`/`Checkbox`/`Radio`/
`Slider`/`DropdownButton`), contenitori (`Card`/`ListTile`/`ExpansionTile`/`Chip`),
struttura (`Scaffold`/`AppBar`/`BottomNavigationBar`/`TabBar`/`BottomSheet`),
feedback (`SnackBar`/`AlertDialog`/`Tooltip`/`*ProgressIndicator`).

---

## 5. Lista di controllo (Blocco 2.2)

- [ ] Stack pinnato: Flutter `^3.6.0`, `google_fonts ^6.1.0`, `sizer ^2.0.15`,
      Material 3.
- [ ] **forui = opzione futura** documentata, non adottata.
- [ ] **Token Dart** centralizzati: `AppSpacing`, `AppRadius`, `AppElevation`,
      `AppMotion`, `AppTouchTarget` — scala definita, niente valori a mano.
- [ ] **Libreria "Villa mobile"** inventariata: guscio/navigazione, dati/stato,
      collezioni/dettaglio, azioni/overlay — ogni componente legge solo dal tema e
      dai token.
- [ ] Catalogo widget base rimandato al manuale (`18-design-mobile.md` sez. 9).

---

*Artefatto operativo della skill `seeding-visivo-mobile`. Complementa il manuale di
stile `.claude/metodo-villa/18-design-mobile.md`. Distillato dal comune di due app
Flutter reali; token e libreria riscritti in forma neutra, senza copiare il codice
delle fonti 1:1.*
