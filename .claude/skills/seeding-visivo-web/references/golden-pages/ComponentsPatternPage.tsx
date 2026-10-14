/**
 * GOLDEN PAGE — Showcase /dev/components-pattern · Metodo Villa · skill seeding-visivo-web
 * Certificata con stack: React 18 · TypeScript · Tailwind 3.4 · shadcn/ui (CLI 2.x, componenti in src/components/ui/) · Lucide · Inter
 * Skin di riferimento: default (neutro). Mostra TUTTI i 10 pattern compositi di 17-design-web.md (sez. 7).
 * Regole: solo token semantici · solo componenti shadcn · solo icone Lucide · severita con bordo+accenti (non blocco pieno).
 *
 * Scopo: pagina vivente di riferimento. Il runner la consulta prima di scrivere
 * qualunque nuovo componente, per imitare lo stile gia' fissato. Va montata su
 * una rotta interna tipo /dev/components-pattern (solo in sviluppo).
 *
 * Pattern compositi mostrati: StatCard (7.1), PageHeader (7.2), AlarmCenter (7.3),
 * EmptyState (7.4), EntityCard (7.5), NavGroup (7.6), NavBadge (7.7),
 * BrandMark (7.8), HeroBanner (7.9), CTA Group (7.10).
 */

import {
  Boxes, Plus, Package, Users, Activity, TrendingUp,
  AlertTriangle, Inbox, ChevronRight, Cpu, Settings,
} from "lucide-react";

// Componenti shadcn/ui (alias virtuali qui, reali quando copiati in un progetto)
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import { Avatar, AvatarFallback } from "@/components/ui/avatar";

/* ------------------------------------------------------------------ */
/* Helper locali (in un progetto reale diventano componenti condivisi)  */
/* ------------------------------------------------------------------ */

// IconBox: icona chiave dentro un contenitore colorato semantico. Mai icona "nuda".
type Sem = "accent" | "success" | "warning" | "danger" | "info" | "muted";
const iconBoxTone: Record<Sem, string> = {
  accent: "bg-primary/10 text-primary",
  success: "bg-success/10 text-success",
  warning: "bg-warning/10 text-warning",
  danger: "bg-destructive/10 text-destructive",
  info: "bg-info/10 text-info",
  muted: "bg-muted text-muted-foreground",
};
function IconBox({ tone, children }: { tone: Sem; children: React.ReactNode }) {
  return (
    <div className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg ${iconBoxTone[tone]}`}>
      {children}
    </div>
  );
}

// Cornice di sezione della showcase, con il nome del pattern visibile.
function PatternSection({ name, hint, children }: { name: string; hint: string; children: React.ReactNode }) {
  return (
    <section className="space-y-3">
      <div>
        <h2 className="text-base font-semibold text-foreground">{name}</h2>
        <p className="text-sm text-muted-foreground">{hint}</p>
      </div>
      <div className="rounded-xl border border-border bg-card p-5 shadow-sm">{children}</div>
    </section>
  );
}

/* ------------------------------------------------------------------ */
/* Dati finti NEUTRI (nessun dominio specifico)                         */
/* ------------------------------------------------------------------ */
const stats = [
  { label: "Ordini oggi", value: "128", icon: Package, tone: "accent" as Sem, trend: "+12%" },
  { label: "Clienti attivi", value: "1.504", icon: Users, tone: "info" as Sem, trend: "+3%" },
  { label: "Dispositivi online", value: "342", icon: Activity, tone: "success" as Sem, trend: "98%" },
  { label: "Da verificare", value: "7", icon: AlertTriangle, tone: "warning" as Sem, trend: "-2" },
];

const entities = [
  { name: "Cliente Rossi S.r.l.", meta: "Ordine #4821 · 3 articoli", status: "success", statusLabel: "In tempo", initials: "RS" },
  { name: "Cliente Bianchi", meta: "Ordine #4822 · 1 articolo", status: "warning", statusLabel: "In attesa", initials: "CB" },
  { name: "Cliente Verdi & Co.", meta: "Ordine #4823 · 8 articoli", status: "danger", statusLabel: "In ritardo", initials: "VC" },
];

const tinted: Record<string, string> = {
  success: "bg-success/15 text-success border border-success/30",
  warning: "bg-warning/15 text-warning border border-warning/30",
  danger: "bg-destructive/15 text-destructive border border-destructive/30",
};

export default function ComponentsPatternPage() {
  return (
    <div className="mx-auto max-w-5xl space-y-10 p-8">
      {/* Intestazione della showcase */}
      <header className="space-y-1">
        <h1 className="text-2xl font-bold tracking-tight text-foreground">
          Showcase pattern — /dev/components-pattern
        </h1>
        <p className="text-sm text-muted-foreground">
          Riferimento vivente dei pattern compositi del Metodo Villa (skin default, dati neutri).
        </p>
      </header>

      {/* 7.1 — StatCard */}
      <PatternSection name="StatCard" hint="Tile statistico: IconBox + numero grande tabular + trend. 4-6 per dashboard.">
        <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
          {stats.map((s) => (
            <Card key={s.label} className="shadow-sm transition-shadow hover:shadow-md">
              <CardContent className="flex items-start justify-between p-5">
                <div className="space-y-1">
                  <p className="text-sm text-muted-foreground">{s.label}</p>
                  <p className="text-3xl font-bold tabular-nums text-foreground">{s.value}</p>
                  <p className="text-xs font-medium text-muted-foreground">{s.trend}</p>
                </div>
                <IconBox tone={s.tone}><s.icon className="h-5 w-5" aria-hidden="true" /></IconBox>
              </CardContent>
            </Card>
          ))}
        </div>
      </PatternSection>

      {/* 7.2 — PageHeader */}
      <PatternSection name="PageHeader" hint="Testata di pagina: titolo deciso + sottotesto quantitativo + azione primaria a destra.">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div>
            <h3 className="text-2xl font-bold tracking-tight text-foreground">Ordini</h3>
            <p className="text-sm text-muted-foreground">128 ordini totali · 7 da verificare</p>
          </div>
          <Button><Plus className="h-4 w-4" aria-hidden="true" />Nuovo ordine</Button>
        </div>
      </PatternSection>

      {/* 7.3 — AlarmCenter (CORREZIONE SenilWatch: bordo+accenti, non blocco pieno) */}
      <PatternSection name="AlarmCenter / AlertContainer" hint="Contenitore di avvisi per gravita. Sfondo tenue + bordo, MAI blocco pieno saturo.">
        <div className="rounded-lg border-2 border-destructive/20 bg-destructive/5">
          <div className="flex items-center gap-2 border-b border-destructive/20 bg-destructive/10 px-4 py-2.5">
            <AlertTriangle className="h-4 w-4 text-destructive" aria-hidden="true" />
            <span className="text-sm font-semibold text-destructive">Centro avvisi · 2 critici</span>
          </div>
          <ul className="divide-y divide-border">
            <li className="flex items-center justify-between px-4 py-3">
              <span className="text-sm text-foreground">Ordine #4823 in ritardo da 3 giorni</span>
              <Button size="sm" variant="destructive">Risolvi</Button>
            </li>
            <li className="flex items-center justify-between px-4 py-3">
              <span className="text-sm text-foreground">Dispositivo D-12 offline</span>
              <Button size="sm" variant="outline">Dettagli</Button>
            </li>
          </ul>
        </div>
      </PatternSection>

      {/* 7.4 — EmptyState ricco */}
      <PatternSection name="EmptyState ricco" hint="Stato vuoto: icona in IconBox + cosa manca + azione per riempirlo. Mai 'Nessun dato'.">
        <div className="flex flex-col items-center justify-center gap-3 py-10 text-center">
          <IconBox tone="muted"><Inbox className="h-5 w-5" aria-hidden="true" /></IconBox>
          <div>
            <p className="font-semibold text-foreground">Nessun ordine ancora</p>
            <p className="text-sm text-muted-foreground">Crea il primo ordine per vederlo qui.</p>
          </div>
          <Button variant="outline"><Plus className="h-4 w-4" aria-hidden="true" />Nuovo ordine</Button>
        </div>
      </PatternSection>

      {/* 7.5 — EntityCard */}
      <PatternSection name="EntityCard" hint="Card di un'entita in griglia: avatar/iniziali + nome + meta + badge stato tinted.">
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {entities.map((e) => (
            <Card key={e.name} className="shadow-sm transition-shadow hover:shadow-md">
              <CardContent className="flex items-center gap-3 p-4">
                <Avatar className="h-10 w-10"><AvatarFallback className="bg-primary text-primary-foreground font-bold">{e.initials}</AvatarFallback></Avatar>
                <div className="min-w-0 flex-1">
                  <p className="truncate font-semibold text-foreground">{e.name}</p>
                  <p className="truncate text-sm text-muted-foreground">{e.meta}</p>
                </div>
                <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${tinted[e.status]}`}>{e.statusLabel}</span>
              </CardContent>
            </Card>
          ))}
        </div>
      </PatternSection>

      {/* 7.6 e 7.7 — NavGroup + NavBadge */}
      <PatternSection name="NavGroup + NavBadge" hint="Gruppo di sidebar con eyebrow + voci; badge contatore sulla voce.">
        <nav className="max-w-xs space-y-1">
          <p className="px-3 pb-1 text-xs font-semibold uppercase tracking-wider text-muted-foreground">Operativita</p>
          <a className="flex items-center gap-3 rounded-md bg-accent px-3 py-2 text-sm font-medium text-accent-foreground" aria-current="page">
            <Package className="h-4 w-4" aria-hidden="true" />Ordini
            <span className="ml-auto rounded-full bg-primary px-1.5 py-0.5 text-xs font-semibold text-primary-foreground tabular-nums">7</span>
          </a>
          <a className="flex items-center gap-3 rounded-md px-3 py-2 text-sm text-foreground transition-colors hover:bg-muted/50">
            <Users className="h-4 w-4" aria-hidden="true" />Clienti
          </a>
          <a className="flex items-center gap-3 rounded-md px-3 py-2 text-sm text-foreground transition-colors hover:bg-muted/50">
            <Cpu className="h-4 w-4" aria-hidden="true" />Dispositivi
            <span className={`ml-auto rounded-full px-1.5 py-0.5 text-xs font-semibold tabular-nums ${tinted.danger}`}>2</span>
          </a>
        </nav>
      </PatternSection>

      {/* 7.8 — BrandMark (3 varianti) */}
      <PatternSection name="BrandMark" hint="Marchio del prodotto: container bg-primary + icona Lucide + nome. Varianti topbar/sidebar/splash.">
        <div className="flex flex-wrap items-center gap-8">
          {/* topbar */}
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary"><Boxes className="h-5 w-5 text-primary-foreground" aria-hidden="true" /></div>
            <span className="font-semibold text-foreground">Pannello</span>
          </div>
          {/* sidebar-collapsed */}
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary"><Boxes className="h-5 w-5 text-primary-foreground" aria-hidden="true" /></div>
          {/* splash */}
          <div className="flex flex-col items-center gap-2">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10"><Boxes className="h-8 w-8 text-primary" aria-hidden="true" /></div>
            <span className="text-sm font-medium text-foreground">Pannello Operativo</span>
          </div>
        </div>
      </PatternSection>

      {/* 7.9 — HeroBanner */}
      <PatternSection name="HeroBanner / IntroSection" hint="Porta d'ingresso o zona di forte richiamo (max 0-1 per pagina). Toni tenui, non saturi.">
        <div className="flex flex-col items-start gap-3 rounded-xl border border-primary/20 bg-primary/5 p-6">
          <IconBox tone="accent"><TrendingUp className="h-5 w-5" aria-hidden="true" /></IconBox>
          <div>
            <h3 className="text-lg font-bold text-foreground">Benvenuto nel Pannello</h3>
            <p className="text-sm text-muted-foreground">Tieni sotto controllo ordini, clienti e dispositivi in un colpo d'occhio.</p>
          </div>
          <Button>Inizia<ChevronRight className="h-4 w-4" aria-hidden="true" /></Button>
        </div>
      </PatternSection>

      {/* 7.10 — CTA Group (3 layout) */}
      <PatternSection name="CTA Group" hint="Gruppo azioni: primario + secondario. Layout affiancato, stack, o split.">
        <div className="space-y-4">
          {/* affiancato */}
          <div className="flex gap-3">
            <Button>Salva</Button>
            <Button variant="outline">Annulla</Button>
          </div>
          {/* stack */}
          <div className="flex max-w-xs flex-col gap-2">
            <Button className="w-full">Conferma</Button>
            <Button variant="ghost" className="w-full">Torna indietro</Button>
          </div>
          {/* split (primario a dx) */}
          <div className="flex items-center justify-between border-t border-border pt-4">
            <Button variant="ghost"><Settings className="h-4 w-4" aria-hidden="true" />Opzioni</Button>
            <div className="flex gap-2">
              <Button variant="outline">Bozza</Button>
              <Button>Pubblica</Button>
            </div>
          </div>
        </div>
      </PatternSection>

      {/* Estensioni "rich": badge tinted + IconBox per severita (riferimento rapido) */}
      <PatternSection name="Badge tinted + severita" hint="Stati a colpo d'occhio con sfondo tenue + bordo, mai pieno saturo.">
        <div className="flex flex-wrap gap-2">
          <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${tinted.success}`}>In tempo</span>
          <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${tinted.warning}`}>In attesa</span>
          <span className={`rounded-full px-2 py-0.5 text-xs font-semibold ${tinted.danger}`}>In ritardo</span>
          <Badge variant="secondary">Neutro</Badge>
        </div>
      </PatternSection>
    </div>
  );
}
