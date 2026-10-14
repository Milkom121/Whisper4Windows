/**
 * GOLDEN PAGE — Dashboard · Metodo Villa · skill seeding-visivo-web
 * Certificata con stack: React 18 · TypeScript · Tailwind 3.4 · shadcn/ui (CLI 2.x, componenti in src/components/ui/) · Lucide · Inter
 * Skin di riferimento: default (neutro). Incarna i pattern di 17-design-web.md (sez. 7 compositi, sez. 8 pagine).
 * Regole: solo token semantici · solo componenti shadcn · solo icone Lucide · severita con bordo+accenti (non blocco pieno).
 *
 * Pattern di pagina incarnato: 8.1 (Dashboard).
 * Pattern compositi incarnati: PageHeader (7.2), StatCard con IconBox (7.1), AlarmCenter/AlertContainer (7.3),
 * EntityCard variante summary (7.5), CTA Group (7.10).
 */

import {
  Package,
  Users,
  HardDrive,
  TrendingUp,
  TrendingDown,
  AlertTriangle,
  Clock,
  ArrowRight,
  CheckCircle2,
  ChevronRight,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";

// ---------------------------------------------------------------------------
// Tipi dei dati finti (dominio neutro: ordini, clienti, dispositivi, attivita)
// ---------------------------------------------------------------------------
type Trend = "up" | "down" | "flat";
type Severity = "danger" | "warning" | "success" | "info";

interface Stat {
  id: string;
  label: string;
  value: number;
  unit?: string;
  icon: typeof Package;
  variant: Severity;
  trend?: { direction: Trend; text: string };
}

interface AlarmItem {
  id: string;
  title: string;
  detail: string;
}

interface RecentActivity {
  id: string;
  title: string;
  subtitle: string;
  amount: string;
  status: "Completato" | "In corso" | "In ritardo";
}

// ---------------------------------------------------------------------------
// Dati mock
// ---------------------------------------------------------------------------
const stats: Stat[] = [
  {
    id: "orders",
    label: "Ordini aperti",
    value: 128,
    unit: "in lavorazione",
    icon: Package,
    variant: "info",
    trend: { direction: "up", text: "+12 vs settimana scorsa" },
  },
  {
    id: "clients",
    label: "Clienti attivi",
    value: 342,
    unit: "con contratto",
    icon: Users,
    variant: "success",
    trend: { direction: "up", text: "+8 nuovi" },
  },
  {
    id: "devices",
    label: "Dispositivi online",
    value: 96,
    unit: "su 104 totali",
    icon: HardDrive,
    variant: "warning",
    trend: { direction: "down", text: "-3 offline" },
  },
  {
    id: "overdue",
    label: "Ordini in ritardo",
    value: 7,
    unit: "oltre la scadenza",
    icon: AlertTriangle,
    variant: "danger",
    trend: { direction: "down", text: "-2 da ieri" },
  },
];

// Avvisi attivi: la sezione AlarmCenter compare SOLO se questo array non e' vuoto.
const activeAlarms: AlarmItem[] = [
  {
    id: "a1",
    title: "Ordine #4821 bloccato",
    detail: "Pagamento non riuscito · cliente Rossi S.r.l.",
  },
  {
    id: "a2",
    title: "Dispositivo HUB-12 in errore",
    detail: "Nessuna risposta da 3 ore · sede di Milano",
  },
];

const recentActivities: RecentActivity[] = [
  { id: "r1", title: "Ordine #4830", subtitle: "Bianchi & Co.", amount: "€ 2.450", status: "In corso" },
  { id: "r2", title: "Ordine #4829", subtitle: "Verdi Logistica", amount: "€ 980", status: "Completato" },
  { id: "r3", title: "Ordine #4825", subtitle: "Rossi S.r.l.", amount: "€ 5.120", status: "In ritardo" },
  { id: "r4", title: "Ordine #4818", subtitle: "Neri Trasporti", amount: "€ 1.300", status: "Completato" },
];

// Mappa lo stato dell'attivita a una variante di badge tinted (mai 'secondary' per stati semantici).
const statusBadge: Record<RecentActivity["status"], { variant: string; label: string }> = {
  Completato: { variant: "tinted-success", label: "Completato" },
  "In corso": { variant: "tinted-info", label: "In corso" },
  "In ritardo": { variant: "tinted-danger", label: "In ritardo" },
};

// ---------------------------------------------------------------------------
// Sotto-componenti locali (in un progetto reale vivrebbero in src/components)
// ---------------------------------------------------------------------------

/** IconBox: icona Lucide dentro un contenitore tinted. Mai icona "nuda" nei KPI. */
function IconBox({ variant, children }: { variant: Severity; children: React.ReactNode }) {
  // Sfondo tenue + testo nel colore della severita (correzione SenilWatch: no blocco pieno).
  const tones: Record<Severity, string> = {
    danger: "bg-destructive/10 text-destructive",
    warning: "bg-warning/10 text-warning",
    success: "bg-success/10 text-success",
    info: "bg-primary/10 text-primary",
  };
  return (
    <div className={`flex h-10 w-10 items-center justify-center rounded-lg ${tones[variant]}`}>
      {children}
    </div>
  );
}

/** StatCard (7.1): etichetta + icona in icon box, numero grande tabular-nums, trend opzionale. */
function StatCard({ stat }: { stat: Stat }) {
  const Icon = stat.icon;
  const trendColor = stat.trend?.direction === "down" ? "text-destructive" : "text-success";
  const TrendIcon = stat.trend?.direction === "down" ? TrendingDown : TrendingUp;
  return (
    <Card className="transition-shadow hover:shadow-md">
      <CardContent className="p-4 md:p-5">
        <div className="mb-3 flex items-center justify-between">
          <span className="text-xs font-medium uppercase tracking-wide text-muted-foreground">
            {stat.label}
          </span>
          <IconBox variant={stat.variant}>
            <Icon className="h-5 w-5" aria-hidden="true" />
          </IconBox>
        </div>
        <p className="text-3xl font-bold leading-none tabular-nums text-foreground">{stat.value}</p>
        {stat.unit && <p className="mt-1 text-xs text-muted-foreground">{stat.unit}</p>}
        {stat.trend && (
          <p className={`mt-3 flex items-center gap-1 text-xs ${trendColor}`}>
            <TrendIcon className="h-3.5 w-3.5" aria-hidden="true" />
            {stat.trend.text}
          </p>
        )}
      </CardContent>
    </Card>
  );
}

// ---------------------------------------------------------------------------
// Pagina
// ---------------------------------------------------------------------------
export default function DashboardPage() {
  const hasAlarms = activeAlarms.length > 0;

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 md:px-6 lg:px-8">
      {/* PageHeader (7.2): la dashboard riassume, niente azione primaria che "chiede di agire" */}
      <header className="mb-6 flex items-start justify-between gap-4 border-b border-border pb-4">
        <div>
          <p className="mb-1 text-xs font-medium uppercase tracking-wider text-muted-foreground">
            Panoramica
          </p>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Buongiorno, Marco</h1>
          {/* Sottotesto quantitativo, non narrativo */}
          <p className="mt-1 text-sm text-muted-foreground">
            128 ordini aperti · 7 in ritardo · 96 dispositivi online
          </p>
        </div>
        <div className="flex flex-shrink-0 items-center gap-2">
          <Button variant="outline">Esporta report</Button>
        </div>
      </header>

      {/* Griglia di 4 StatCard (sez. 8.1): 2 colonne su mobile, 4 su desktop */}
      <section
        aria-label="Indicatori chiave"
        className="grid grid-cols-2 gap-3 md:grid-cols-4 md:gap-6"
      >
        {stats.map((stat) => (
          <StatCard key={stat.id} stat={stat} />
        ))}
      </section>

      {/*
        AlarmCenter / AlertContainer (7.3): rendering CONDIZIONALE.
        Correzione dal vivo (SenilWatch): NON blocco pieno saturo, ma sfondo tenue +
        bordo colorato + accenti. Il colore pieno solo sul bottone d'azione.
      */}
      {hasAlarms && (
        <section className="mt-6">
          <div className="rounded-xl border-2 border-destructive/20 bg-card shadow-md">
            {/* Testata: bg tenue, icona e testo nel colore della severita */}
            <div className="flex items-center justify-between gap-4 rounded-t-xl bg-destructive/10 px-5 py-4">
              <div className="flex items-center gap-3">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-destructive/10 text-destructive">
                  {/* animate-pulse: ammesso, e' uno stato critico persistente non gestito */}
                  <AlertTriangle className="h-5 w-5 animate-pulse" aria-hidden="true" />
                </div>
                <div>
                  <h2 className="text-base font-semibold text-destructive">Centro avvisi</h2>
                  <p className="text-sm text-destructive/80">{activeAlarms.length} attivi da gestire</p>
                </div>
              </div>
              <Button variant="ghost" className="text-destructive hover:bg-destructive/10">
                Vedi tutti
                <ChevronRight className="h-4 w-4" aria-hidden="true" />
              </Button>
            </div>

            {/* Etichetta sotto-sezione in colore severita */}
            <div className="p-5">
              <p className="mb-3 text-xs font-semibold uppercase tracking-wider text-destructive">
                Attivi
              </p>
              <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
                {activeAlarms.map((alarm) => (
                  <div
                    key={alarm.id}
                    className="flex items-start justify-between gap-3 rounded-lg border border-destructive/30 bg-destructive/5 p-3"
                  >
                    <div>
                      <p className="text-sm font-semibold text-foreground">{alarm.title}</p>
                      <p className="mt-0.5 text-sm text-muted-foreground">{alarm.detail}</p>
                    </div>
                    {/* Colore pieno SOLO sul bottone d'azione */}
                    <Button size="sm" className="flex-shrink-0">
                      Risolvi
                    </Button>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </section>
      )}

      {/* Sezione principale: due colonne — attivita recenti + riepilogo rapido */}
      <section className="mt-6 grid grid-cols-1 gap-6 lg:grid-cols-3">
        {/* Lista attivita recenti (occupa 2/3) */}
        <div className="lg:col-span-2">
          <div className="mb-3 flex items-center justify-between">
            <h2 className="text-base font-semibold text-foreground">Attivita recenti</h2>
            <Button variant="link" className="h-auto p-0 text-sm">
              Vai agli ordini
              <ArrowRight className="h-4 w-4" aria-hidden="true" />
            </Button>
          </div>
          <Card className="transition-shadow hover:shadow-md">
            <CardContent className="p-0">
              <ul className="divide-y divide-border">
                {recentActivities.map((activity) => {
                  const badge = statusBadge[activity.status];
                  return (
                    <li
                      key={activity.id}
                      className="flex items-center justify-between gap-4 px-5 py-3 transition-colors hover:bg-muted/50"
                    >
                      <div className="min-w-0">
                        <p className="truncate text-sm font-semibold text-foreground">{activity.title}</p>
                        <p className="truncate text-sm text-muted-foreground">{activity.subtitle}</p>
                      </div>
                      <div className="flex flex-shrink-0 items-center gap-4">
                        <span className="text-sm font-semibold tabular-nums text-foreground">
                          {activity.amount}
                        </span>
                        <Badge variant={badge.variant}>{badge.label}</Badge>
                      </div>
                    </li>
                  );
                })}
              </ul>
            </CardContent>
          </Card>
        </div>

        {/* Colonna laterale: EntityCard variante summary + nota di stato positivo */}
        <div className="space-y-6">
          <div>
            <h2 className="mb-3 text-base font-semibold text-foreground">Cliente del mese</h2>
            {/* EntityCard variante summary (7.5): titolo + coppie chiave/valore + footer */}
            <Card className="transition-shadow hover:shadow-md">
              <CardContent className="p-5">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-base font-semibold text-foreground">Bianchi &amp; Co.</p>
                    <p className="text-sm text-muted-foreground">Logistica · Torino</p>
                  </div>
                  <Badge variant="tinted-success">Top</Badge>
                </div>
                <div className="mt-4 grid grid-cols-2 gap-3">
                  <div className="rounded-lg bg-muted/50 p-3">
                    <p className="text-xs text-muted-foreground">Ordini</p>
                    <p className="text-lg font-bold tabular-nums text-foreground">24</p>
                  </div>
                  <div className="rounded-lg bg-muted/50 p-3">
                    <p className="text-xs text-muted-foreground">Fatturato</p>
                    <p className="text-lg font-bold tabular-nums text-foreground">€ 38k</p>
                  </div>
                </div>
                <div className="mt-4 flex items-center justify-between border-t border-border pt-3 text-xs text-muted-foreground">
                  <span className="flex items-center gap-1">
                    <Clock className="h-3.5 w-3.5" aria-hidden="true" />
                    Aggiornato 5 min fa
                  </span>
                  <Button variant="ghost" size="sm" className="h-auto p-0 text-xs">
                    Dettaglio
                  </Button>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Nota positiva con sfondo tenue success + bordo (stile InfoBox/severity) */}
          <div className="flex items-start gap-3 rounded-xl border border-success/30 bg-success/5 p-4">
            <CheckCircle2 className="mt-0.5 h-5 w-5 flex-shrink-0 text-success" aria-hidden="true" />
            <div>
              <p className="text-sm font-semibold text-foreground">Tutto in regola sulle consegne</p>
              <p className="mt-0.5 text-sm text-muted-foreground">
                Nessuna consegna oltre i termini nelle ultime 24 ore.
              </p>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
