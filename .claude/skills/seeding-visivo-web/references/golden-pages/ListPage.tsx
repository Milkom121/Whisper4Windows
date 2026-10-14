/**
 * GOLDEN PAGE — Lista · Metodo Villa · skill seeding-visivo-web
 * Certificata con stack: React 18 · TypeScript · Tailwind 3.4 · shadcn/ui (CLI 2.x, componenti in src/components/ui/) · Lucide · Inter
 * Skin di riferimento: default (neutro). Incarna i pattern di 17-design-web.md (sez. 7 compositi, sez. 8 pagine).
 * Regole: solo token semantici · solo componenti shadcn · solo icone Lucide · severita con bordo+accenti (non blocco pieno).
 *
 * Pattern di pagina incarnato: 8.2 (Lista).
 * Pattern compositi incarnati: PageHeader (7.2), FilterBar in card con ricerca (8.2), Tabs come segmented control (8.2),
 * EntityCard variante monitoring/summary (7.5), EmptyState ricco (7.4), CTA Group (7.10).
 */

import { useMemo, useState } from "react";

import {
  Search,
  Plus,
  HardDrive,
  Wifi,
  WifiOff,
  Battery,
  MoreVertical,
  Clock,
  PackageSearch,
  Pencil,
  RotateCw,
  Trash2,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardContent } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";

// ---------------------------------------------------------------------------
// Tipi dei dati finti (dominio neutro: dispositivi connessi di una flotta)
// ---------------------------------------------------------------------------
type DeviceState = "online" | "warning" | "offline";

interface Device {
  id: string;
  name: string;
  code: string;
  location: string;
  state: DeviceState;
  battery: number; // percentuale 0-100
  lastSeen: string;
}

// Filtri come segmented control. "all" mostra tutto.
type Filter = "all" | DeviceState;

// ---------------------------------------------------------------------------
// Dati mock
// ---------------------------------------------------------------------------
const devices: Device[] = [
  { id: "d1", name: "Hub centrale", code: "HUB-01", location: "Milano · Sede", state: "online", battery: 92, lastSeen: "ora" },
  { id: "d2", name: "Sensore varco A", code: "SNS-12", location: "Milano · Magazzino", state: "warning", battery: 34, lastSeen: "8 min fa" },
  { id: "d3", name: "Gateway nord", code: "GW-07", location: "Torino · Filiale", state: "online", battery: 78, lastSeen: "2 min fa" },
  { id: "d4", name: "Sensore varco B", code: "SNS-13", location: "Milano · Magazzino", state: "offline", battery: 0, lastSeen: "3 ore fa" },
  { id: "d5", name: "Lettore badge", code: "RDR-21", location: "Roma · Sede", state: "online", battery: 64, lastSeen: "1 min fa" },
  { id: "d6", name: "Hub secondario", code: "HUB-02", location: "Napoli · Filiale", state: "warning", battery: 41, lastSeen: "15 min fa" },
];

// Mappa lo stato del dispositivo a etichetta, badge tinted e icona.
const stateMeta: Record<DeviceState, { label: string; badge: string; icon: typeof Wifi; tone: string }> = {
  online: { label: "Online", badge: "tinted-success", icon: Wifi, tone: "text-success" },
  warning: { label: "Da verificare", badge: "tinted-warning", icon: Wifi, tone: "text-warning" },
  offline: { label: "Offline", badge: "tinted-neutral", icon: WifiOff, tone: "text-muted-foreground" },
};

// ---------------------------------------------------------------------------
// Pagina
// ---------------------------------------------------------------------------
export default function ListPage() {
  const [query, setQuery] = useState("");
  const [filter, setFilter] = useState<Filter>("all");

  // Filtro combinato: testo (nome/codice/sede) + stato selezionato.
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return devices.filter((d) => {
      const matchesQuery =
        q.length === 0 ||
        d.name.toLowerCase().includes(q) ||
        d.code.toLowerCase().includes(q) ||
        d.location.toLowerCase().includes(q);
      const matchesFilter = filter === "all" || d.state === filter;
      return matchesQuery && matchesFilter;
    });
  }, [query, filter]);

  // Due stati vuoti diversi (sez. 8.2 punto 5): lista vuota per filtri vs nessun dato.
  const isFilteringActively = filter !== "all" || query.trim().length > 0;
  const isEmpty = filtered.length === 0;

  return (
    <div className="mx-auto max-w-7xl px-4 py-6 md:px-6 lg:px-8">
      {/* PageHeader (7.2) con azione primaria a destra */}
      <header className="mb-6 flex items-start justify-between gap-4 border-b border-border pb-4">
        <div>
          <p className="mb-1 text-xs font-medium uppercase tracking-wider text-muted-foreground">
            Flotta
          </p>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Dispositivi</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {devices.length} totali · {devices.filter((d) => d.state === "offline").length} offline
          </p>
        </div>
        <div className="flex flex-shrink-0 items-center gap-2">
          <Button>
            <Plus className="h-4 w-4" aria-hidden="true" />
            Nuovo dispositivo
          </Button>
        </div>
      </header>

      {/* FilterBar dentro una card (sez. 8.2 punto 1): "isola" dei controlli */}
      <Card className="mb-4 shadow-sm">
        <CardContent className="flex flex-col gap-4 p-4 lg:flex-row lg:items-center lg:justify-between">
          {/* Campo di ricerca con icona inline a sinistra */}
          <div className="relative w-full lg:max-w-sm">
            <Search
              className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground"
              aria-hidden="true"
            />
            <Input
              type="search"
              placeholder="Cerca per nome, codice o sede"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="pl-10"
            />
          </div>

          {/* Filtri come segmented control (Tabs): Tutti / Online / Da verificare / Offline */}
          <Tabs value={filter} onValueChange={(v) => setFilter(v as Filter)}>
            <TabsList>
              <TabsTrigger value="all">Tutti</TabsTrigger>
              <TabsTrigger value="online">Online</TabsTrigger>
              <TabsTrigger value="warning">Da verificare</TabsTrigger>
              <TabsTrigger value="offline">Offline</TabsTrigger>
            </TabsList>
          </Tabs>
        </CardContent>
      </Card>

      {/* Conteggio risultati sopra la lista */}
      {!isEmpty && (
        <p className="mb-3 text-sm text-muted-foreground" aria-live="polite">
          {filtered.length} {filtered.length === 1 ? "risultato" : "risultati"}
        </p>
      )}

      {/* Corpo: griglia di EntityCard (5-30 elementi) OPPURE EmptyState ricco */}
      {isEmpty ? (
        // EmptyState ricco (7.4): ramo condizionale renderizzato. Sentiment diverso
        // a seconda che si stia filtrando (neutral) o che la lista sia vuota (info).
        isFilteringActively ? (
          <div className="flex flex-col items-center justify-center rounded-xl border border-border bg-muted/30 px-6 py-12 text-center">
            <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-muted">
              <PackageSearch className="h-8 w-8 text-muted-foreground" aria-hidden="true" />
            </div>
            <h2 className="mb-2 text-lg font-semibold text-foreground">Nessun risultato</h2>
            <p className="mb-6 max-w-md text-sm text-muted-foreground">
              Nessun dispositivo corrisponde ai filtri attivi. Prova a rimuovere la ricerca o a
              cambiare lo stato selezionato.
            </p>
            <Button
              variant="outline"
              onClick={() => {
                setQuery("");
                setFilter("all");
              }}
            >
              Rimuovi filtri
            </Button>
          </div>
        ) : (
          <div className="flex flex-col items-center justify-center rounded-xl border border-primary/20 bg-primary/5 px-6 py-12 text-center">
            <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
              <HardDrive className="h-8 w-8 text-primary" aria-hidden="true" />
            </div>
            <h2 className="mb-2 text-lg font-semibold text-foreground">Nessun dispositivo ancora</h2>
            <p className="mb-6 max-w-md text-sm text-muted-foreground">
              Collega il primo dispositivo della flotta per iniziare a monitorarne stato e batteria.
            </p>
            <Button>
              <Plus className="h-4 w-4" aria-hidden="true" />
              Collega il primo dispositivo
            </Button>
          </div>
        )
      ) : (
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {filtered.map((device) => {
            const meta = stateMeta[device.state];
            const StateIcon = meta.icon;
            // Severity sulla card: bordo sinistro solo se lo stato lo giustifica.
            const severityBorder =
              device.state === "offline"
                ? "border-l-4 border-l-destructive"
                : device.state === "warning"
                ? "border-l-4 border-l-warning"
                : "";
            // Colore della batteria per severita (testo, non blocco pieno).
            const batteryTone =
              device.battery === 0
                ? "text-destructive"
                : device.battery < 40
                ? "text-warning"
                : "text-success";

            return (
              // EntityCard (7.5): titolo + azioni inline, corpo metriche, footer timestamp + badge
              <Card
                key={device.id}
                className={`cursor-pointer transition-shadow hover:shadow-md ${severityBorder}`}
              >
                <CardContent className="p-4">
                  {/* Testata: titolo + menu azioni inline */}
                  <div className="flex items-start justify-between gap-2">
                    <div className="min-w-0">
                      <p className="truncate text-base font-semibold text-foreground">{device.name}</p>
                      <p className="truncate text-sm text-muted-foreground">
                        {device.code} · {device.location}
                      </p>
                    </div>
                    {/* Una sola azione inline: menu "Altre azioni" (mai molti bottoni) */}
                    <DropdownMenu>
                      <DropdownMenuTrigger asChild>
                        <Button variant="ghost" size="icon" aria-label="Altre azioni">
                          <MoreVertical className="h-4 w-4" aria-hidden="true" />
                        </Button>
                      </DropdownMenuTrigger>
                      <DropdownMenuContent align="end">
                        <DropdownMenuItem>
                          <Pencil className="h-4 w-4" aria-hidden="true" />
                          Modifica
                        </DropdownMenuItem>
                        <DropdownMenuItem>
                          <RotateCw className="h-4 w-4" aria-hidden="true" />
                          Riavvia
                        </DropdownMenuItem>
                        <DropdownMenuSeparator />
                        <DropdownMenuItem className="text-destructive focus:text-destructive">
                          <Trash2 className="h-4 w-4" aria-hidden="true" />
                          Rimuovi
                        </DropdownMenuItem>
                      </DropdownMenuContent>
                    </DropdownMenu>
                  </div>

                  {/* Corpo: due metriche (stato connessione + batteria) */}
                  <div className="mt-4 grid grid-cols-2 gap-3">
                    <div className="rounded-lg bg-muted/50 p-3">
                      <div className="flex items-center gap-1.5">
                        <StateIcon className={`h-4 w-4 ${meta.tone}`} aria-hidden="true" />
                        <span className="text-xs text-muted-foreground">Connessione</span>
                      </div>
                      <p className="mt-1 text-sm font-semibold text-foreground">{meta.label}</p>
                    </div>
                    <div className="rounded-lg bg-muted/50 p-3">
                      <div className="flex items-center gap-1.5">
                        <Battery className={`h-4 w-4 ${batteryTone}`} aria-hidden="true" />
                        <span className="text-xs text-muted-foreground">Batteria</span>
                      </div>
                      <p className={`mt-1 text-sm font-semibold tabular-nums ${batteryTone}`}>
                        {device.battery}%
                      </p>
                    </div>
                  </div>

                  {/* Footer: timestamp + badge di stato */}
                  <div className="mt-4 flex items-center justify-between border-t border-border pt-3">
                    <span className="flex items-center gap-1 text-xs text-muted-foreground">
                      <Clock className="h-3.5 w-3.5" aria-hidden="true" />
                      Visto {device.lastSeen}
                    </span>
                    <Badge variant={meta.badge}>{meta.label}</Badge>
                  </div>
                </CardContent>
              </Card>
            );
          })}
        </div>
      )}
    </div>
  );
}
