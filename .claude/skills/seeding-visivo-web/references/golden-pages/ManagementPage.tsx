/**
 * GOLDEN PAGE — Gestione · Metodo Villa · skill seeding-visivo-web
 * Certificata con stack: React 18 · TypeScript · Tailwind 3.4 · shadcn/ui (CLI 2.x, componenti in src/components/ui/) · Lucide · Inter
 * Skin di riferimento: default (neutro). Incarna i pattern di 17-design-web.md (sez. 7 compositi, sez. 8 pagine).
 * Regole: solo token semantici · solo componenti shadcn · solo icone Lucide · severita con bordo+accenti (non blocco pieno).
 *
 * Pattern di pagina incarnato: 8.5 (Gestione / CRUD amministrativo).
 * Pattern compositi incarnati: PageHeader (7.2), DataTable/Table shadcn (8.5), Dialog per crea/modifica,
 * AlertDialog (ConfirmDialog) per la cancellazione, chip ruolo/stato tinted (6.1), CTA Group (7.10).
 */

import { useState } from "react";

import {
  UserPlus,
  Search,
  MoreVertical,
  Pencil,
  KeyRound,
  Ban,
  Trash2,
  ShieldCheck,
} from "lucide-react";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent } from "@/components/ui/card";
import {
  Table,
  TableBody,
  TableCell,
  TableHead,
  TableHeader,
  TableRow,
} from "@/components/ui/table";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from "@/components/ui/dropdown-menu";
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from "@/components/ui/alert-dialog";

// ---------------------------------------------------------------------------
// Tipi dei dati finti (dominio neutro: utenti e ruoli del gestionale)
// ---------------------------------------------------------------------------
type Role = "Amministratore" | "Operatore" | "Sola lettura";
type UserStatus = "Attivo" | "Sospeso" | "Invito inviato";

interface User {
  id: string;
  name: string;
  email: string;
  role: Role;
  status: UserStatus;
  initials: string;
}

// ---------------------------------------------------------------------------
// Dati mock
// ---------------------------------------------------------------------------
const initialUsers: User[] = [
  { id: "u1", name: "Marco Bianchi", email: "marco.bianchi@azienda.it", role: "Amministratore", status: "Attivo", initials: "MB" },
  { id: "u2", name: "Laura Verdi", email: "laura.verdi@azienda.it", role: "Operatore", status: "Attivo", initials: "LV" },
  { id: "u3", name: "Paolo Rossi", email: "paolo.rossi@azienda.it", role: "Operatore", status: "Sospeso", initials: "PR" },
  { id: "u4", name: "Anna Neri", email: "anna.neri@azienda.it", role: "Sola lettura", status: "Invito inviato", initials: "AN" },
  { id: "u5", name: "Giulia Conti", email: "giulia.conti@azienda.it", role: "Amministratore", status: "Attivo", initials: "GC" },
];

// Chip ruolo: varianti tinted, mai colore pieno (sez. 6.1).
const roleBadge: Record<Role, string> = {
  Amministratore: "tinted-info",
  Operatore: "tinted-neutral",
  "Sola lettura": "tinted-neutral",
};

// Chip stato: severity coding in varianti tinted.
const statusBadge: Record<UserStatus, string> = {
  Attivo: "tinted-success",
  Sospeso: "tinted-danger",
  "Invito inviato": "tinted-warning",
};

// Avatar colorato per ruolo: sfondo pieno + iniziali bianche bold (pattern-design-rich §7).
const roleAvatarTone: Record<Role, string> = {
  Amministratore: "bg-primary",
  Operatore: "bg-success",
  "Sola lettura": "bg-muted text-muted-foreground",
};

// ---------------------------------------------------------------------------
// Pagina
// ---------------------------------------------------------------------------
export default function ManagementPage() {
  const [users] = useState<User[]>(initialUsers);
  const [query, setQuery] = useState("");

  // Stato della finestra crea/modifica e della conferma di eliminazione.
  const [editDialogOpen, setEditDialogOpen] = useState(false);
  const [editingUser, setEditingUser] = useState<User | null>(null);
  const [deletingUser, setDeletingUser] = useState<User | null>(null);

  const filtered = users.filter((u) => {
    const q = query.trim().toLowerCase();
    return q.length === 0 || u.name.toLowerCase().includes(q) || u.email.toLowerCase().includes(q);
  });

  function openCreate() {
    setEditingUser(null);
    setEditDialogOpen(true);
  }

  function openEdit(user: User) {
    setEditingUser(user);
    setEditDialogOpen(true);
  }

  return (
    <div className="mx-auto max-w-6xl px-4 py-6 md:px-6 lg:px-8">
      {/* PageHeader (7.2) con azione primaria a destra */}
      <header className="mb-6 flex items-start justify-between gap-4 border-b border-border pb-4">
        <div>
          <p className="mb-1 text-xs font-medium uppercase tracking-wider text-muted-foreground">
            Amministrazione
          </p>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">Utenti e ruoli</h1>
          <p className="mt-1 text-sm text-muted-foreground">
            {users.length} utenti · {users.filter((u) => u.status === "Attivo").length} attivi
          </p>
        </div>
        <div className="flex flex-shrink-0 items-center gap-2">
          <Button onClick={openCreate}>
            <UserPlus className="h-4 w-4" aria-hidden="true" />
            Nuovo utente
          </Button>
        </div>
      </header>

      {/* FilterBar dentro una card con ricerca */}
      <Card className="mb-4 shadow-sm">
        <CardContent className="p-4">
          <div className="relative w-full lg:max-w-sm">
            <Search
              className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground"
              aria-hidden="true"
            />
            <Input
              type="search"
              placeholder="Cerca per nome o email"
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              className="pl-10"
            />
          </div>
        </CardContent>
      </Card>

      {/* DataTable obbligatoria per le pagine admin (sez. 8.5). Wrapper Table shadcn. */}
      <Card className="overflow-hidden shadow-sm">
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Utente</TableHead>
              <TableHead className="hidden md:table-cell">Email</TableHead>
              <TableHead>Ruolo</TableHead>
              <TableHead>Stato</TableHead>
              {/* Colonna azioni in fondo, allineata a destra */}
              <TableHead className="w-12 text-right">
                <span className="sr-only">Azioni</span>
              </TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {filtered.map((user) => (
              <TableRow key={user.id} className="transition-colors hover:bg-muted/50">
                <TableCell>
                  <div className="flex items-center gap-3">
                    {/* Avatar colorato per ruolo + iniziali bianche bold */}
                    <div
                      className={`flex h-9 w-9 flex-shrink-0 items-center justify-center rounded-full text-xs font-bold text-primary-foreground ${roleAvatarTone[user.role]}`}
                    >
                      {user.initials}
                    </div>
                    <div className="min-w-0">
                      <p className="truncate text-sm font-semibold text-foreground">{user.name}</p>
                      {/* Email visibile inline su mobile (la colonna dedicata e' nascosta) */}
                      <p className="truncate text-xs text-muted-foreground md:hidden">{user.email}</p>
                    </div>
                  </div>
                </TableCell>
                <TableCell className="hidden text-sm text-muted-foreground md:table-cell">
                  {user.email}
                </TableCell>
                <TableCell>
                  <Badge variant={roleBadge[user.role]}>{user.role}</Badge>
                </TableCell>
                <TableCell>
                  <Badge variant={statusBadge[user.status]}>{user.status}</Badge>
                </TableCell>
                <TableCell className="text-right">
                  {/* Un solo IconButton "Altre azioni" che apre un Dropdown (mai molti bottoni inline) */}
                  <DropdownMenu>
                    <DropdownMenuTrigger asChild>
                      <Button variant="ghost" size="icon" aria-label={`Azioni per ${user.name}`}>
                        <MoreVertical className="h-4 w-4" aria-hidden="true" />
                      </Button>
                    </DropdownMenuTrigger>
                    <DropdownMenuContent align="end">
                      <DropdownMenuItem onClick={() => openEdit(user)}>
                        <Pencil className="h-4 w-4" aria-hidden="true" />
                        Modifica
                      </DropdownMenuItem>
                      <DropdownMenuItem>
                        <KeyRound className="h-4 w-4" aria-hidden="true" />
                        Reimposta password
                      </DropdownMenuItem>
                      <DropdownMenuItem>
                        <Ban className="h-4 w-4" aria-hidden="true" />
                        Sospendi
                      </DropdownMenuItem>
                      <DropdownMenuSeparator />
                      {/* Eliminazione: voce danger che apre il ConfirmDialog, mai cancellazione diretta */}
                      <DropdownMenuItem
                        className="text-destructive focus:text-destructive"
                        onClick={() => setDeletingUser(user)}
                      >
                        <Trash2 className="h-4 w-4" aria-hidden="true" />
                        Elimina
                      </DropdownMenuItem>
                    </DropdownMenuContent>
                  </DropdownMenu>
                </TableCell>
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </Card>

      {/*
        Dialog crea/modifica (sez. 8.5 punto 4): Modal per form brevi (<=5 campi).
        Per form lunghi si userebbe uno Sheet (Drawer). Validazione Zod renderebbe
        il "Salva" disabilitato finche' il form non e' valido.
      */}
      <Dialog open={editDialogOpen} onOpenChange={setEditDialogOpen}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle>{editingUser ? "Modifica utente" : "Nuovo utente"}</DialogTitle>
            <DialogDescription>
              {editingUser
                ? "Aggiorna i dati e il ruolo dell'utente."
                : "Inserisci i dati del nuovo utente. Ricevera' un invito via email."}
            </DialogDescription>
          </DialogHeader>

          {/* FormField: label + Input shadcn (mai il campo HTML nativo) */}
          <div className="space-y-4 py-2">
            <div className="space-y-2">
              <Label htmlFor="user-name">Nome e cognome</Label>
              <Input id="user-name" defaultValue={editingUser?.name ?? ""} placeholder="Mario Rossi" />
            </div>
            <div className="space-y-2">
              <Label htmlFor="user-email">Email</Label>
              <Input
                id="user-email"
                type="email"
                defaultValue={editingUser?.email ?? ""}
                placeholder="nome@azienda.it"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="user-role">Ruolo</Label>
              {/* Select shadcn, mai il menu a tendina HTML nativo */}
              <Select defaultValue={editingUser?.role ?? "Operatore"}>
                <SelectTrigger id="user-role">
                  <SelectValue placeholder="Scegli un ruolo" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="Amministratore">Amministratore</SelectItem>
                  <SelectItem value="Operatore">Operatore</SelectItem>
                  <SelectItem value="Sola lettura">Sola lettura</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Nota informativa sul ruolo: sfondo tenue + bordo (InfoBox), non blocco pieno */}
            <div className="flex items-start gap-3 rounded-lg border border-primary/20 bg-primary/5 p-3">
              <ShieldCheck className="mt-0.5 h-4 w-4 flex-shrink-0 text-primary" aria-hidden="true" />
              <p className="text-sm text-muted-foreground">
                Gli amministratori possono gestire utenti e impostazioni. Assegna questo ruolo solo a
                chi serve davvero.
              </p>
            </div>
          </div>

          {/* CTA Group variante horizontal-end: Annulla (ghost) + Salva (primario a destra) */}
          <DialogFooter>
            <Button variant="ghost" onClick={() => setEditDialogOpen(false)}>
              Annulla
            </Button>
            <Button onClick={() => setEditDialogOpen(false)}>
              {editingUser ? "Salva modifiche" : "Crea utente"}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/*
        ConfirmDialog SEMPRE per l'eliminazione (sez. 8.5 punto 5): variante danger,
        testo esplicito, mai paternalistico. Il pieno destructive solo sul bottone d'azione.
      */}
      <AlertDialog open={deletingUser !== null} onOpenChange={(open) => !open && setDeletingUser(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Eliminare l&apos;utente {deletingUser?.name}?</AlertDialogTitle>
            <AlertDialogDescription>
              L&apos;utente perdera' immediatamente l&apos;accesso. L&apos;azione e&apos;
              irreversibile.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Annulla</AlertDialogCancel>
            {/* Bottone d'azione con il colore pieno destructive */}
            <AlertDialogAction
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
              onClick={() => setDeletingUser(null)}
            >
              Elimina utente
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
