---
name: seeding-visivo-mobile
description: "Skill per la generazione di frontend MOBILE (app Flutter) belli e coerenti al primo colpo. Usa questa skill ogni volta che si lavora su un'app MOBILE in Flutter e si menziona: seeda questa app mobile, applica il seme visivo mobile, schermata Flutter bella al primo colpo, refactor visivo mobile, riparazione UI mobile piatta, generazione schermate Flutter, prima volta che si crea il frontend di un'app mobile, tema Flutter centralizzato, golden screens mobile, libreria componenti Flutter. Anche quando si avvia un nuovo progetto mobile e si vuole partire con uno stack opinato e curato (Flutter + Material 3 + tema centralizzato + google_fonts + sizer). Sempre quando si parla di 'qualita visiva mobile', 'UI mobile premium', 'stile coerente Flutter', 'design system Flutter applicato', 'app gradevole al primo colpo'. IMPORTANTE: questa skill e' SOLO per mobile/Flutter; per il WEB (React + Vite + TypeScript + Tailwind + shadcn/ui) usa invece la skill seeding-visivo-web. English triggers: seed visual mobile, beautiful Flutter UI generation, mobile frontend scaffolding, Flutter theme bootstrap."
---

# Seeding Visivo Mobile — Frontend Flutter curato al primo colpo

Questa skill risolve, sul **mobile**, lo stesso problema strutturale della sorella
web: il runner produce schermate Flutter **tecnicamente corrette ma esteticamente
piatte**. La causa non è il modello AI, è il fatto che lavora a **blocchi isolati**
senza un seme visivo concreto da imitare.

La skill applica la stessa ricetta — **stack opinato + system prompt anti-piattezza
+ tema pronto + golden screens** — in casa, sui gusti Villa, in Flutter. È il
**gemello mobile** di `seeding-visivo-web`: stessa filosofia, altra piattaforma.

> **Confine netto (a tenuta stagna)**: questa skill vale **solo** per app **mobile
> in Flutter**. Per il **web** (React/Vite/Tailwind/shadcn) usa
> `seeding-visivo-web`. Le due non si sovrappongono.

## Filosofia

**Tre principi guida** (gli stessi del web, declinati su Flutter):

1. **Stack cementato**: ogni app mobile Villa usa lo stesso stack (**Flutter +
   Material 3 + tema centralizzato + google_fonts + sizer**). forui solo opzione
   futura. Niente discussioni stack-per-progetto.
2. **System prompt anti-piattezza mobile**: documento stringente che vieta le scelte
   pigre (colori a mano nei widget, `TextStyle` inline, widget "nudi" non a tema,
   secondo accento sul FAB, banner pieni saturi) e obbliga lo stile cementato.
   Caricato quando l'agente tocca file Flutter.
3. **Seme visivo concreto**: un **tema pronto** (due preset, `default` neutro +
   `outdoor` di esempio), una **libreria di componenti** "Villa mobile" e un set di
   **golden screens** già conformi, da imitare.

**Lingua di default**: italiano. Lo stack tecnico è in inglese, ma la skill comunica
con l'utente in italiano.

**Quando usare questa skill**:
- (a) **Nuova app mobile**: dopo `discovery`, prima dei blocchi tecnici. Genera il
  seme frontend Flutter.
- (b) **Riparazione di app mobile piatta**: progetto Flutter con UI boilerplate, da
  re-seedare.
- (c) **Nuova fase visiva** di un'app matura: moduli con esigenze visive nuove.

**Quando NON usare**:
- Progetti **web** → usa `seeding-visivo-web`.
- App senza UI (servizi, librerie Dart).
- Refactor puramente funzionale (logica senza tocchi UI).

---

## Stato e persistenza

Per non perdere il filo tra messaggi/sessioni, mantieni un file
**`seeding-state.md`** nella cartella di lavoro del progetto target. Struttura:

```markdown
# Seeding Visivo Mobile State — [Nome Progetto]
## Fase corrente: [1-7]
## Stack: Flutter + Material 3
## Preset tema: default | outdoor | [personalizzato]
## Colore primario scelto: [hex]
## Schermate generate finora:
- [elenco con path]
## Guardrail check (6 bloccanti):
- [✓/✗ con dettaglio]
## File modificati:
- [lista]
## Prossimo passo:
- [cosa fare]
```

Se la sessione si interrompe, leggi questo file per riprendere.

---

## Workflow completo

Il processo è in 7 fasi. Per progetti riparazione (caso b), salta alla Fase 3.

### Fase 1 — Identifica contesto e stack
Verifica e raccogli:
1. **Tipo di app**: gestionale da campo, app di consultazione, strumento operativo,
   companion, ecc.
2. **Conferma stack mobile**: Flutter + Material 3 (default, salvo richiesta).
3. **Stile di partenza**: NON scegliere qui i colori. Si decidono nella **Fase 4 —
   Styling co-progettato** (un momento 🤝 con Villa). Qui annota solo se esiste già
   un brand/preset di riferimento o un'ispirazione.

Salva le scelte in `seeding-state.md`.

### Fase 2 — Carica il system prompt anti-piattezza mobile
Leggi e applica `references/system-prompt-anti-piattezza-mobile.md`. Da qui in poi,
ogni file Flutter che produci rispetta le regole VIETATO/OBBLIGATORIO/PRINCIPI.

Conferma a Villa: "System prompt anti-piattezza mobile caricato. Da ora opero in
modalità Lovable-like su Flutter: stack cementato, tema centralizzato, no scelte
mediocri."

### Fase 3 — Scaffolda (o adatta) lo stack Flutter
**Stato attuale**: non c'è ancora un repo template pubblicato. **Workaround**: copia
nel progetto i file di riferimento di questa skill.

Passi base:
```bash
# Nuovo progetto Flutter (se non esiste)
flutter create nome_app
cd nome_app
# Dipendenze nel pubspec.yaml: google_fonts ^6.1.0, sizer ^2.0.15
flutter pub add google_fonts sizer
```
Poi copia da `references/golden-screens/theme/` nel progetto:
- `theme/app_theme.dart` (la fabbrica AppPalette → ThemeData), `theme/tokens.dart`
  (AppSpacing/Radius/Elevation/Motion/TouchTarget), `theme/palette_default.dart` (+
  `palette_outdoor.dart` come esempio).
- `widgets/villa_widgets.dart` (la libreria componenti "Villa mobile").

Aggancia il tema in `main.dart`:
```dart
MaterialApp(
  theme: AppTheme.light(kDefaultPalette),
  darkTheme: AppTheme.dark(kDefaultPalette),
  themeMode: ThemeMode.system,
);
```

Per **progetti riparazione (caso b)**: NON sovrascrivere le schermate esistenti.
Introduci il tema e i componenti, poi migra una schermata alla volta, validando.

Salva i file creati in `seeding-state.md`.

### Fase 4 — Styling co-progettato (🤝 COLLABORATIVO)
Qui si decide l'aspetto dell'app. È **intrinsecamente 🤝 collaborativa**: le scelte
estetiche (palette, tono, brand) le fa **Villa**, non l'agente. Va eseguita in
**sessione live, PRIMA** dei blocchi autonomi che generano le schermate.

> **Fallback neutro per il runner (regola di autonomia)**: se questa fase NON è stata
> fatta — il runner gira in autonomia, Villa assente — **NON inventare una palette**.
> Applica il **preset `default`** (`palette_default.dart`) e annota in
> `seeding-state.md`: «preset: default (fallback, styling non co-progettato)». **Mai
> far scegliere i colori al runner da solo.**

**Il dialogo di co-progettazione** (con Villa presente). Si parte da un preset e lo
si adatta. Preset disponibili:
- `default` — palette neutra slate + accento blu (`palette_default.dart`). La base da
  vestire. Allineata cromaticamente allo skin-default web.
- `outdoor` — esempio "Alpine Clarity" (verde foresta), mostra come si compila un
  preset (`palette_outdoor.dart`).

Domande da porre a Villa (testo libero, **non** a scelta multipla):
1. **Colore del brand** (il primario / accento): c'è già un colore aziendale? Un'app
   che piace come ispirazione?
2. **Tono**: più sobrio/istituzionale o più caldo?
3. **Modalità di default**: la dark mode c'è **sempre** (regola permanente di Villa, non opzionale; il guardrail la verifica) — qui si decide solo la predefinita: chiara, scura o di sistema (`ThemeMode.system`)?
4. **Brand mark**: nome dell'app + un'icona Material (`Icons.*`) che lo rappresenti.
5. **Densità**: gestionale denso o più arioso?

Da queste risposte si fissano i **token** del preset (`vedi 18-design-mobile.md`,
sez. 2): soprattutto il `primary` (chiaro/scuro). Gli altri token (superfici,
severità) restano quelli del preset salvo richiesta. Mostra a Villa la palette
applicata e fatti confermare prima di procedere.

**Applicazione tecnica**: duplica `palette_default.dart`, cambia i valori `primary`
(e l'eventuale `tertiary`) concordati, lascia il resto. Conferma Inter via
google_fonts. Salva in `seeding-state.md`: preset di partenza, colore primario,
modalità, brand mark.

### Fase 5 — Genera le schermate "scheletro" core
Basandoti sui requisiti (da `discovery` o `PROJECT_CONFIG.md`), genera lo scheletro
di queste schermate canoniche, imitando le golden in `references/golden-screens/screens/`:
1. **Login / Onboarding** (vedi `login_screen.dart`)
2. **Home / Dashboard** (vedi `home_screen.dart`)
3. **Lista** dell'entità principale (vedi `list_screen.dart`)
4. **Dettaglio** entità (vedi `detail_screen.dart`)
5. **Form / Gestione** (creazione/modifica, spesso in un foglio inferiore)

Per ogni schermata applica i pattern di schermata canonici (`vedi 18-design-mobile.md`,
sez. 8). NIENTE composizioni libere: usa i componenti della libreria "Villa mobile".

### Fase 6 — Genera la gallery dei componenti
Una schermata showcase (vedi `components_gallery.dart`) con TUTTI i compositi resi
con dati neutri: StatTile, StatusBanner (3 severità), StatusChip, EntityCard,
EmptyStateView, ActionGroup. Diventa la **fonte vivente di riferimento** per i
blocchi successivi: il runner la consulta prima di scrivere nuovi widget.

### Fase 7 — Esegui i guardrail e chiudi il seeding
Esegui `references/guardrail-flutter.sh` sul progetto (o sulle schermate). 6 check
bloccanti + 2 warning:
1. Anti-colore hardcoded · 2. Anti-`TextStyle` inline · 3. Tema centralizzato
(light+dark) · 4. `MaterialApp` aggancia theme+darkTheme · 5. `google_fonts` ·
6. Un accento coerente (FAB sul primary). Warning: 7. spaziatura magica ·
8. `useMaterial3`.

Score minimo per chiudere: **6/6** bloccanti. I 2 warning indicano "UI tecnicamente
corretta ma piatta": correggerli prima di chiudere.

Aggiorna `seeding-state.md` con stato finale: ✓ Completato. Comunica a Villa:
schermate generate (con path), punteggio guardrail 6/6, prossimo passo.

---

## Riferimenti

- **Manuale Metodo Villa**: `.claude/metodo-villa/18-design-mobile.md` (stile mobile),
  `16-design-core.md` (cuore comune web+mobile).
- **Stack e libreria**: `references/stack-e-libreria-mobile.md` (stack pinnato, token
  Dart, inventario componenti "Villa mobile").
- **System prompt anti-piattezza mobile**: `references/system-prompt-anti-piattezza-mobile.md`.
- **Tema pronto**: `references/golden-screens/theme/` (`app_theme.dart`, `tokens.dart`,
  `palette_default.dart`, `palette_outdoor.dart`).
- **Golden screens**: `references/golden-screens/` (mini-progetto conforme: login,
  home, list, detail, gallery + libreria `widgets/villa_widgets.dart`).
- **Guardrail**: `references/guardrail-flutter.sh` (8 check; fixture di prova in
  `references/guardrail-fixtures/`).
- **Skill sorella (web)**: `seeding-visivo-web` — stessa filosofia per React/web.
- **Skill complementari**: `discovery` (nuovi progetti), `migrazione` (progetti
  esistenti).

---

*Skill creata il 2026-06-03 come gemello mobile di `seeding-visivo-web`, nella Fase 2
dell'iniziativa "Potenziamento Skill Frontend". Distillata dal comune di due app
Flutter reali e curate (palette outdoor "Alpine Clarity" e gestionale "Craftsman").
Fonte operativa: `.claude/metodo-villa/18-design-mobile.md`.*
