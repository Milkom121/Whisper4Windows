# Pattern Design Rich — Componenti e regole per UI di prodotto

> **Origine**: validati su SenilCure (2026-05-25), ispirati da SenilWatch.
> Questi pattern sono **OBBLIGATORI** per ogni progetto frontend di prodotto Villa.
> Senza di essi, l'output del runner è "tecnicamente corretto ma visivamente piatto".
>
> **Prerequisito**: shadcn/ui installato + `class-variance-authority` (CVA) disponibile.
> Tutti i componenti usano CVA per le varianti + `cn()` utility per merge classi.

---

## 1. IconBox — Icona dentro container tinted colorato

**Scopo**: dare peso visivo alle icone nei punti chiave (KPI card, header sezioni, sidebar attiva, logo, empty state). Senza IconBox, le icone Lucide sono "nude" e grigie — il layout risulta piatto.

**Quando usarlo**: SEMPRE per icone in evidenza (KPI, sidebar attive, header sezione, stati vuoto/errore). MAI per icone inline nel testo o in bottoni piccoli.

**Varianti**: `accent` (bg-primary/10 + text-primary), `success`, `warning`, `danger`, `info`, `muted`.
**Sizes**: `sm` (32px), `md` (40px), `lg` (48px).

```tsx
// Snippet pedagogico — icon-box.tsx
const iconBoxVariants = cva(
  'inline-flex items-center justify-center rounded-lg shrink-0',
  {
    variants: {
      variant: {
        accent:  'bg-primary/10 text-primary',
        success: 'bg-success/10 text-success',
        warning: 'bg-warning/10 text-warning',
        danger:  'bg-destructive/10 text-destructive',
        info:    'bg-primary/10 text-primary',
        muted:   'bg-muted text-muted-foreground',
      },
      size: {
        sm: 'h-8 w-8',
        md: 'h-10 w-10',
        lg: 'h-12 w-12',
      },
    },
    defaultVariants: { variant: 'accent', size: 'md' },
  },
)
```

**Esempio d'uso in una KPI card**:
```tsx
<Card>
  <CardContent className="flex items-center gap-4 p-4">
    <IconBox variant="danger">
      <AlertTriangle className="h-5 w-5" />
    </IconBox>
    <div>
      <p className="text-3xl font-bold tabular-nums">7</p>
      <p className="text-sm text-muted-foreground">Scadenze in ritardo</p>
    </div>
  </CardContent>
</Card>
```

---

## 2. HeroBanner — Card a piena larghezza con sfondo pieno

**Scopo**: richiamare l'attenzione su zone CRITICHE o di forte richiamo (allarmi globali, onboarding, CTA importanti). Sfondo pieno colorato + testo bianco + icona grande.

**Quando usarlo**: 0-1 per pagina, solo per informazioni ad alta priorità (es. "10 scadenze scadute!", "Benvenuto nel sistema"). MAI per informazioni ordinarie.

**Varianti**: `accent`, `success`, `warning`, `danger`.

```tsx
// Snippet pedagogico — hero-banner.tsx
const heroBannerVariants = cva(
  'relative w-full rounded-xl p-6 text-white overflow-hidden',
  {
    variants: {
      variant: {
        accent:  'bg-primary',
        success: 'bg-success',
        warning: 'bg-warning text-warning-foreground',
        danger:  'bg-destructive',
      },
    },
    defaultVariants: { variant: 'accent' },
  },
)
```

**Esempio d'uso**:
```tsx
<HeroBanner variant="danger">
  <div className="flex items-center gap-4">
    <AlertTriangle className="h-8 w-8" />
    <div>
      <h3 className="text-lg font-bold">Centro allarmi</h3>
      <p className="text-sm opacity-90">10 scadenze superate, 3 ospiti senza medico assegnato</p>
    </div>
  </div>
</HeroBanner>
```

---

## 3. InfoBox — Card con sfondo tinted per aree informative

**Scopo**: evidenziare contenuti informativi/tutorial senza l'urgenza di un HeroBanner. Sfondo leggero (5% opacità) + bordo semantico (20% opacità).

**Quando usarlo**: help contestuale ("Come aggiungere X"), note di sezione, suggerimenti. MAI per dati operativi (quelli stanno in Card normali).

**Varianti**: `accent`, `info`, `success`, `warning`, `danger`.

```tsx
// Snippet pedagogico — info-box.tsx
const infoBoxVariants = cva(
  'rounded-xl border p-4',
  {
    variants: {
      variant: {
        info:    'bg-primary/5 border-primary/20 text-foreground',
        success: 'bg-success/5 border-success/20 text-foreground',
        warning: 'bg-warning/5 border-warning/20 text-foreground',
        danger:  'bg-destructive/5 border-destructive/20 text-foreground',
      },
    },
    defaultVariants: { variant: 'info' },
  },
)
```

---

## 4. Card con prop `severity` — Bordo laterale colorato

**Scopo**: dare stato semantico evidente a una Card senza cambiarne il layout. Il `border-l-4` colorato comunica immediatamente "questa card ha un'urgenza" o "questa card è positiva".

**Quando usarlo**: card paziente con allarme attivo (danger), card completata (success), card in attesa (warning). MAI su card senza stato semantico (sarebbe rumore visivo).

```tsx
// Estensione di card.tsx shadcn — aggiungere prop severity
const cardVariants = cva(
  'rounded-2xl border bg-card text-card-foreground shadow-md transition-all duration-200 hover:shadow-lg',
  {
    variants: {
      severity: {
        none:    '',
        info:    'border-l-4 border-l-primary',
        success: 'border-l-4 border-l-success',
        warning: 'border-l-4 border-l-warning',
        danger:  'border-l-4 border-l-destructive',
      },
    },
    defaultVariants: { severity: 'none' },
  },
)
```

**Prima / Dopo**:
```tsx
// PRIMA (piatto): Card senza alcuna indicazione di stato
<Card><CardContent>Paziente con 5 scadenze scadute</CardContent></Card>

// DOPO (con severity): bordo rosso evidente a sinistra
<Card severity="danger"><CardContent>Paziente con 5 scadenze scadute</CardContent></Card>
```

---

## 5. Badge varianti tinted — Sfondo leggero + testo scuro

**Scopo**: i Badge shadcn di default hanno varianti troppo piatte (`default`, `secondary`, `outline`, `destructive`). Le varianti tinted aggiungono sfondo leggero al 15% + testo colorato + bordo al 30% — molto più leggibili senza essere aggressivi.

**Quando usarlo**: per TUTTI gli stati semantici (online/offline, pendente/scaduto, verde/giallo/rosso). MAI le varianti default per stati semantici.

**Varianti da aggiungere**: `tinted-success`, `tinted-warning`, `tinted-danger`, `tinted-info`, `tinted-neutral`.

```tsx
// Estensione di badge.tsx shadcn — aggiungere alle variants CVA
'tinted-success': 'bg-success/15 text-success border-success/30 font-semibold',
'tinted-warning': 'bg-warning/15 text-warning border-warning/30 font-semibold',
'tinted-danger':  'bg-destructive/15 text-destructive border-destructive/30 font-semibold',
'tinted-info':    'bg-primary/15 text-primary border-primary/30 font-semibold',
'tinted-neutral': 'bg-muted text-muted-foreground border-border font-semibold',
```

**Prima / Dopo**:
```tsx
// PRIMA: badge grigio anonimo per tutti gli stati
<Badge variant="secondary">Scaduta</Badge>

// DOPO: badge rosso tinted, immediatamente leggibile
<Badge variant="tinted-danger">Scaduta</Badge>
```

---

## 6. Ombre semantiche — shadow-md default + hover shadow-lg

**Scopo**: le Card shadcn di default NON hanno ombre. Risultano piatte, "stampate sulla pagina". Aggiungere `shadow-md` di default + `shadow-lg` su hover + varianti dark mode.

**Regola**: Card = `shadow-md` default + `hover:shadow-lg` + `transition-all duration-200`. Dialog/Sheet aperti = `shadow-lg`. MAI `shadow-2xl` (troppo aggressivo) salvo modal grandi.

```tsx
// Classe base della Card (sovrascrive il default shadcn)
'rounded-2xl border bg-card text-card-foreground shadow-md transition-all duration-200 hover:shadow-lg dark:shadow-black/30 dark:hover:shadow-black/50'
```

**Nota dark mode**: le ombre standard Tailwind sono quasi invisibili su sfondo scuro. Aggiungere `dark:shadow-black/30` per renderle percepibili.

---

## 7. Avatar colorato semantico per ruolo

**Scopo**: l'avatar con sfondo grigio e iniziali grigie è anonimo. Un avatar con sfondo pieno colorato per ruolo + iniziali bianche bold è immediatamente riconoscibile e dà personalità all'UI.

**Quando usarlo**: Topbar (utente loggato), card paziente (operatore assegnato), timeline diari (autore). SEMPRE con iniziali bianche bold.

**Mapping colori suggerito** (da adattare al dominio del progetto):
- **primary**: ruoli dirigenziali (caposala, manager, medico)
- **success**: ruoli operativi (infermiere, assistente, OSS)
- **warning**: ruoli specialistici (fisioterapista, educatore)

```tsx
// Esempio concettuale — nel componente che renderizza l'avatar utente
const roleColorMap: Record<string, string> = {
  caposala:  'bg-primary',
  medico:    'bg-primary',
  ip:        'bg-success',
  asa:       'bg-success',
  oss:       'bg-success',
  fkt:       'bg-warning',
  educatore: 'bg-warning',
}

<div className={cn('flex h-8 w-8 items-center justify-center rounded-full text-white font-bold text-xs', roleColorMap[role] ?? 'bg-muted')}>
  {initials}
</div>
```

---

## 8. Tipografia gerarchica bold

**Scopo**: i titoli `font-medium` (il default shadcn) sono anonimi. La tipografia gerarchica forte usa `font-bold` + `tracking-tight` per titoli pagina, `font-semibold` per sezioni, e numeri KPI giganti.

**Regole fisse**:
- Titolo pagina: `text-2xl font-bold tracking-tight`
- Titolo sezione/card: `text-base font-semibold`
- Numero KPI: `text-3xl font-bold tabular-nums`
- Sottotitolo/label: `text-sm text-muted-foreground`

**Prima / Dopo**:
```tsx
// PRIMA (piatto)
<h1 className="text-lg font-medium">Ospiti</h1>

// DOPO (gerarchico)
<h1 className="text-2xl font-bold tracking-tight">Ospiti</h1>
<p className="text-sm text-muted-foreground">120 totali</p>
```

---

## 9. Microinterazioni standard + KPI card pattern

### Microinterazioni

**Scopo**: ogni elemento interattivo deve dare feedback visivo. Senza microinterazioni, l'UI sembra "morta".

**Regole fisse**:
- Righe tabella: `hover:bg-muted/50 transition-colors`
- Card: `transition-all duration-200 hover:shadow-lg` (già nel pattern 6)
- Voci sidebar/nav: `hover:bg-muted/50 transition-colors`
- Button: ha già `transition-colors` da shadcn

**NON fare**: `hover:scale-105` su liste lunghe (disorientante), `animate-bounce`, transizioni > 300ms.

### KPI card pattern

**Scopo**: in cima alle pagine ricche (Dashboard, Inbox), 3-4 Card piccole affiancate che danno il "colpo d'occhio" numerico.

**Struttura fissa**:
```tsx
<div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
  {/* Ripetere per ogni KPI */}
  <Card>
    <CardContent className="flex items-center gap-4 p-4">
      <IconBox variant="danger">
        <AlertTriangle className="h-5 w-5" />
      </IconBox>
      <div>
        <p className="text-3xl font-bold tabular-nums">{count}</p>
        <p className="text-sm text-muted-foreground">Scadenze scadute</p>
      </div>
    </CardContent>
  </Card>
</div>
```

**Regole KPI card**:
- 3-4 card, MAI più di 5 (diventa rumore).
- Ogni card ha un IconBox con variante semantica coerente con il dato.
- Il numero è GRANDE (`text-3xl font-bold tabular-nums`).
- La label sotto è piccola (`text-sm text-muted-foreground`).
- MAI KPI card senza IconBox (risulta piatta).

---

## Riepilogo: checklist rapida per ogni pagina

Prima di chiudere un blocco frontend, verifica:

- [ ] Titolo pagina usa `text-2xl font-bold tracking-tight`?
- [ ] Card hanno `shadow-md` e `hover:shadow-lg`?
- [ ] Badge di stato usano varianti tinted (non `secondary`)?
- [ ] Icone in evidenza sono dentro `IconBox` (non nude)?
- [ ] KPI card (se presenti) seguono il pattern con `IconBox` + numero grande?
- [ ] Righe tabella hanno `hover:bg-muted/50 transition-colors`?
- [ ] Avatar utente ha sfondo colorato per ruolo (non grigio)?

Se anche solo una risposta è "no", il blocco non raggiunge il livello visivo richiesto.

---

*Documento creato il 2026-05-25. Origine: 9 pattern introdotti nel design system di SenilCure durante la sezione RV (Restyling Visivo), validati da Villa contro il riferimento estetico SenilWatch.*
