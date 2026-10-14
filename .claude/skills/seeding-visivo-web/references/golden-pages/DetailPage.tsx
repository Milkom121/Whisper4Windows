/**
 * GOLDEN PAGE — Dettaglio · Metodo Villa · skill seeding-visivo-web
 * Certificata con stack: React 18 · TypeScript · Tailwind 3.4 · shadcn/ui (CLI 2.x, componenti in src/components/ui/) · Lucide · Inter
 * Skin di riferimento: default (neutro). Incarna i pattern di 17-design-web.md (sez. 7 compositi, sez. 8 pagine).
 * Regole: solo token semantici · solo componenti shadcn · solo icone Lucide · severita con bordo+accenti (non blocco pieno).
 *
 * Pattern di pagina incarnato: 8.3 (Dettaglio).
 * Pattern compositi incarnati: PageHeader ricco con avatar + info pill + CTA Group (7.2/7.10),
 * TabNav (8.3), Card con severity (pattern-design-rich §4), IconBox (§1).
 */

import { useState } from "react";

import {
  Building2,
  Mail,
  Phone,
  MapPin,
  Calendar,
  Pencil,
  MoreVertical,
  Package,
  Euro,
  CheckCircle2,
  AlertTriangle,
  FileText,
  Trash2,
  Download,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

// ---------------------------------------------------------------------------
// Tipi dei dati finti (dominio neutro: scheda di un cliente)
// ---------------------------------------------------------------------------
interface ClientField {
  label: string;
  value: string;
  icon: typeof Mail;
}

interface OrderRow {
  id: string;
  number: string;
  date: string;
  amount: string;
  state: "Completato" | "In corso" | "In ritardo";
}

// ---------------------------------------------------------------------------
// Dati mock
// ---------------------------------------------------------------------------
const client = {
  name: "Bianchi & Co.",
  sector: "Logistica e trasporti",
  initials: "BC",
  status: { label: "Cliente attivo", variant: "tinted-success" },
  contract: { label: "Contratto Premium", variant: "tinted-info" },
};

const contactFields: ClientField[] = [
  { label: "Email", value: "amministrazione@bianchi.it", icon: Mail },
  { label: "Telefono", value: "+39 011 555 0192", icon: Phone },
  { label: "Sede", value: "Via Roma 14, Torino", icon: MapPin },
  { label: "Cliente dal", value: "marzo 2021", icon: Calendar },
];

const recentOrders: OrderRow[] = [
  { id: "o1", number: "#4830", date: "02 giu 2026", amount: "€ 2.450", state: "In corso" },
  { id: "o2", number: "#4815", date: "28 mag 2026", amount: "€ 980", state: "Completato" },
  { id: "o3", number: "#4802", date: "21 mag 2026", amount: "€ 5.120", state: "In ritardo" },
];

const orderBadge: Record<OrderRow["state"], string> = {
  Completato: "tinted-success",
  "In corso": "tinted-info",
  "In ritardo": "tinted-danger",
};

// ---------------------------------------------------------------------------
// Pagina
// ---------------------------------------------------------------------------
export default function DetailPage() {
  const [tab, setTab] = useState("panoramica");

  return (
    <div className="mx-auto max-w-6xl px-4 py-6 md:px-6 lg:px-8">
      {/* Header ricco prominente in una card (sez. 8.3 punto 1) */}
      <Card className="mb-6 shadow-md">
        <CardContent className="p-6">
          <div className="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
            <div className="flex items-start gap-4">
              {/* Avatar grande (~64px) con sfondo accento pieno + iniziali bianche bold */}
              <div className="flex h-16 w-16 flex-shrink-0 items-center justify-center rounded-full bg-primary text-xl font-bold text-primary-foreground">
                {client.initials}
              </div>
              <div className="min-w-0">
                <div className="flex items-center gap-2">
                  <Building2 className="h-4 w-4 text-muted-foreground" aria-hidden="true" />
                  <span className="text-xs font-medium uppercase tracking-wider text-muted-foreground">
                    {client.sector}
                  </span>
                </div>
                <h1 className="mt-1 text-2xl font-bold tracking-tight text-foreground">
                  {client.name}
                </h1>
                {/* Info pill: chip non interattivi, colorati per severita dove ha senso */}
                <div className="mt-3 flex flex-wrap items-center gap-2">
                  <Badge variant={client.status.variant}>{client.status.label}</Badge>
                  <Badge variant={client.contract.variant}>{client.contract.label}</Badge>
                </div>
              </div>
            </div>

            {/* CTA Group (7.10): UN primario + menu "Altre azioni". Resta in alto a destra. */}
            <div className="flex flex-shrink-0 items-center gap-2">
              <Button>
                <Pencil className="h-4 w-4" aria-hidden="true" />
                Modifica
              </Button>
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="outline" size="icon" aria-label="Altre azioni">
                    <MoreVertical className="h-4 w-4" aria-hidden="true" />
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent align="end">
                  <DropdownMenuItem>
                    <Download className="h-4 w-4" aria-hidden="true" />
                    Esporta scheda
                  </DropdownMenuItem>
                  <DropdownMenuSeparator />
                  {/* Azione irreversibile in variante danger dentro il menu */}
                  <DropdownMenuItem className="text-destructive focus:text-destructive">
                    <Trash2 className="h-4 w-4" aria-hidden="true" />
                    Elimina cliente
                  </DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* TabNav sotto l'header: la tab attiva ha sottolineatura accento (shadcn la gestisce) */}
      <Tabs value={tab} onValueChange={setTab}>
        <TabsList>
          <TabsTrigger value="panoramica">Panoramica</TabsTrigger>
          <TabsTrigger value="ordini">Ordini</TabsTrigger>
          <TabsTrigger value="documenti">Documenti</TabsTrigger>
        </TabsList>

        {/* Contenuto della tab "Panoramica": campi in griglia + card con severity */}
        <TabsContent value="panoramica" className="mt-6 space-y-6" role="tabpanel">
          {/* Riepilogo numerico rapido */}
          <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
            <Card className="transition-shadow hover:shadow-md">
              <CardContent className="flex items-center gap-4 p-4">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
                  <Package className="h-5 w-5" aria-hidden="true" />
                </div>
                <div>
                  <p className="text-2xl font-bold tabular-nums text-foreground">24</p>
                  <p className="text-sm text-muted-foreground">Ordini totali</p>
                </div>
              </CardContent>
            </Card>
            <Card className="transition-shadow hover:shadow-md">
              <CardContent className="flex items-center gap-4 p-4">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-success/10 text-success">
                  <Euro className="h-5 w-5" aria-hidden="true" />
                </div>
                <div>
                  <p className="text-2xl font-bold tabular-nums text-foreground">€ 38.200</p>
                  <p className="text-sm text-muted-foreground">Fatturato 2026</p>
                </div>
              </CardContent>
            </Card>
            <Card className="transition-shadow hover:shadow-md">
              <CardContent className="flex items-center gap-4 p-4">
                <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-warning/10 text-warning">
                  <AlertTriangle className="h-5 w-5" aria-hidden="true" />
                </div>
                <div>
                  <p className="text-2xl font-bold tabular-nums text-foreground">1</p>
                  <p className="text-sm text-muted-foreground">Ordine in ritardo</p>
                </div>
              </CardContent>
            </Card>
          </div>

          <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
            {/* Card contatti: campi in griglia chiave/valore */}
            <Card className="transition-shadow hover:shadow-md">
              <CardHeader>
                <CardTitle className="text-base font-semibold">Recapiti</CardTitle>
              </CardHeader>
              <CardContent>
                <dl className="grid grid-cols-1 gap-4 sm:grid-cols-2">
                  {contactFields.map((field) => {
                    const Icon = field.icon;
                    return (
                      <div key={field.label} className="flex items-start gap-3">
                        <div className="flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-lg bg-muted text-muted-foreground">
                          <Icon className="h-4 w-4" aria-hidden="true" />
                        </div>
                        <div className="min-w-0">
                          <dt className="text-xs text-muted-foreground">{field.label}</dt>
                          <dd className="truncate text-sm font-medium text-foreground">{field.value}</dd>
                        </div>
                      </div>
                    );
                  })}
                </dl>
              </CardContent>
            </Card>

            {/* Card con severity (border-l-4): un avviso operativo reale su questo cliente */}
            <Card severity="warning" className="transition-shadow hover:shadow-md">
              <CardHeader>
                <CardTitle className="flex items-center gap-2 text-base font-semibold">
                  <AlertTriangle className="h-4 w-4 text-warning" aria-hidden="true" />
                  Da tenere d&apos;occhio
                </CardTitle>
              </CardHeader>
              <CardContent className="space-y-3">
                {/* Riga avviso: sfondo tenue + bordo (non blocco pieno) */}
                <div className="flex items-start gap-3 rounded-lg border border-warning/30 bg-warning/5 p-3">
                  <AlertTriangle className="mt-0.5 h-4 w-4 flex-shrink-0 text-warning" aria-hidden="true" />
                  <div>
                    <p className="text-sm font-semibold text-foreground">Ordine #4802 in ritardo</p>
                    <p className="mt-0.5 text-sm text-muted-foreground">
                      Consegna prevista il 28 maggio, ancora non evasa.
                    </p>
                  </div>
                </div>
                <div className="flex items-start gap-3 rounded-lg border border-success/30 bg-success/5 p-3">
                  <CheckCircle2 className="mt-0.5 h-4 w-4 flex-shrink-0 text-success" aria-hidden="true" />
                  <div>
                    <p className="text-sm font-semibold text-foreground">Pagamenti regolari</p>
                    <p className="mt-0.5 text-sm text-muted-foreground">
                      Nessuna fattura scaduta negli ultimi 12 mesi.
                    </p>
                  </div>
                </div>
              </CardContent>
            </Card>
          </div>

          {/* Ultimi ordini come lista compatta */}
          <Card className="transition-shadow hover:shadow-md">
            <CardHeader>
              <CardTitle className="text-base font-semibold">Ultimi ordini</CardTitle>
            </CardHeader>
            <CardContent className="p-0">
              <ul className="divide-y divide-border">
                {recentOrders.map((order) => (
                  <li
                    key={order.id}
                    className="flex items-center justify-between gap-4 px-6 py-3 transition-colors hover:bg-muted/50"
                  >
                    <div>
                      <p className="text-sm font-semibold text-foreground">{order.number}</p>
                      <p className="text-sm text-muted-foreground">{order.date}</p>
                    </div>
                    <div className="flex items-center gap-4">
                      <span className="text-sm font-semibold tabular-nums text-foreground">
                        {order.amount}
                      </span>
                      <Badge variant={orderBadge[order.state]}>{order.state}</Badge>
                    </div>
                  </li>
                ))}
              </ul>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Tab "Ordini": placeholder operativo (rimanda alla lista filtrata) */}
        <TabsContent value="ordini" className="mt-6" role="tabpanel">
          <Card className="transition-shadow hover:shadow-md">
            <CardContent className="flex flex-col items-center justify-center px-6 py-12 text-center">
              <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
                <Package className="h-8 w-8 text-primary" aria-hidden="true" />
              </div>
              <h2 className="mb-2 text-lg font-semibold text-foreground">Tutti gli ordini del cliente</h2>
              <p className="mb-6 max-w-md text-sm text-muted-foreground">
                Qui compare lo storico completo degli ordini con filtri per stato e periodo.
              </p>
              <Button variant="outline">Apri lo storico ordini</Button>
            </CardContent>
          </Card>
        </TabsContent>

        {/* Tab "Documenti": placeholder operativo */}
        <TabsContent value="documenti" className="mt-6" role="tabpanel">
          <Card className="transition-shadow hover:shadow-md">
            <CardContent className="flex flex-col items-center justify-center px-6 py-12 text-center">
              <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-muted">
                <FileText className="h-8 w-8 text-muted-foreground" aria-hidden="true" />
              </div>
              <h2 className="mb-2 text-lg font-semibold text-foreground">Nessun documento caricato</h2>
              <p className="mb-6 max-w-md text-sm text-muted-foreground">
                Carica contratti, fatture e allegati per tenerli insieme alla scheda del cliente.
              </p>
              <Button>Carica un documento</Button>
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>
    </div>
  );
}
