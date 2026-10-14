/**
 * GOLDEN PAGE — Login · Metodo Villa · skill seeding-visivo-web
 * Certificata con stack: React 18 · TypeScript · Tailwind 3.4 · shadcn/ui (CLI 2.x, componenti in src/components/ui/) · Lucide · Inter
 * Skin di riferimento: default (neutro). Incarna i pattern di 17-design-web.md (sez. 7 compositi, sez. 8 pagine).
 * Regole: solo token semantici · solo componenti shadcn · solo icone Lucide · severita con bordo+accenti (non blocco pieno).
 *
 * Pattern di pagina incarnato: 8.4 (Login).
 * Pattern compositi incarnati: BrandMark variante login-splash (7.8), CTA Group variante stack (7.10).
 */

import { useState } from "react";

// Componenti shadcn/ui (alias virtuali qui, reali quando copiati in un progetto)
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Checkbox } from "@/components/ui/checkbox";
import { Card, CardContent } from "@/components/ui/card";

// Icone: solo Lucide, mai grafica vettoriale inline
import { Boxes, Mail, Lock, LogIn, Loader2 } from "lucide-react";

/**
 * Pagina di accesso. Sfondo sobrio con gradiente tenue (ammesso SOLO sulle pagine
 * pubbliche d'ingresso, mai dentro il guscio applicativo). Card centrata + brand
 * splash + form con icone interne + CTA a piena larghezza.
 */
export default function LoginPage() {
  // Stato del form: in un progetto reale qui vivrebbe React Hook Form + Zod.
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [submitting, setSubmitting] = useState(false);

  // Il primario resta disabilitato finche' i campi minimi non sono compilati.
  const canSubmit = email.trim().length > 0 && password.length > 0;

  function handleSubmit(event: React.FormEvent<HTMLFormElement>) {
    event.preventDefault();
    if (!canSubmit || submitting) return;
    setSubmitting(true);
    // Simulazione chiamata di rete: in produzione una mutation TanStack Query.
    window.setTimeout(() => setSubmitting(false), 1200);
  }

  return (
    // Sfondo con gradiente sobrio from-background via-muted to-background (sez. 8.4).
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-b from-background via-muted to-background px-4 py-12">
      <Card className="w-full max-w-md rounded-2xl shadow-lg">
        <CardContent className="p-8">
          {/* BrandMark variante login-splash: cerchio bg-primary/10 + icona accento + nome sotto */}
          <div className="flex flex-col items-center text-center">
            <div className="flex h-16 w-16 items-center justify-center rounded-full bg-primary/10">
              <Boxes className="h-8 w-8 text-primary" aria-hidden="true" />
            </div>
            <h1 className="mt-4 text-2xl font-bold tracking-tight text-foreground">
              Pannello Operativo
            </h1>
            {/* Tagline sobria, operativa, mai markettara (sez. 7.9) */}
            <p className="mt-1 text-sm text-muted-foreground">
              Accedi per gestire clienti, ordini e dispositivi
            </p>
          </div>

          {/* Form di accesso */}
          <form onSubmit={handleSubmit} className="mt-8 space-y-5">
            {/* Campo email con icona interna a sinistra (sez. 8.4 punto 4) */}
            <div className="space-y-2">
              <Label htmlFor="email" className="text-sm font-medium text-foreground">
                Indirizzo email
              </Label>
              <div className="relative">
                <Mail
                  className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground"
                  aria-hidden="true"
                />
                <Input
                  id="email"
                  type="email"
                  autoComplete="email"
                  placeholder="nome@azienda.it"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>

            {/* Campo password con icona interna a sinistra */}
            <div className="space-y-2">
              <div className="flex items-center justify-between">
                <Label htmlFor="password" className="text-sm font-medium text-foreground">
                  Password
                </Label>
                {/* Link secondario, variante ghost: azione minore */}
                <Button variant="link" type="button" className="h-auto p-0 text-sm">
                  Password dimenticata?
                </Button>
              </div>
              <div className="relative">
                <Lock
                  className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground"
                  aria-hidden="true"
                />
                <Input
                  id="password"
                  type="password"
                  autoComplete="current-password"
                  placeholder="••••••••"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="pl-10"
                />
              </div>
            </div>

            {/* "Ricordami" */}
            <div className="flex items-center gap-2">
              <Checkbox id="remember" />
              <Label htmlFor="remember" className="text-sm font-normal text-muted-foreground">
                Ricordami su questo dispositivo
              </Label>
            </div>

            {/* CTA Group variante stack: primario a piena larghezza + link secondario sotto */}
            <div className="flex flex-col gap-3 pt-1">
              <Button type="submit" className="w-full" disabled={!canSubmit || submitting}>
                {submitting ? (
                  <>
                    <Loader2 className="h-4 w-4 animate-spin" aria-hidden="true" />
                    Accesso in corso
                  </>
                ) : (
                  <>
                    <LogIn className="h-4 w-4" aria-hidden="true" />
                    Accedi
                  </>
                )}
              </Button>
            </div>
          </form>

          {/* Riga registrazione, coerente col login (sez. 8.4) */}
          <p className="mt-6 text-center text-sm text-muted-foreground">
            Non hai un account?{" "}
            <Button variant="link" type="button" className="h-auto p-0 text-sm">
              Richiedi l'accesso
            </Button>
          </p>
        </CardContent>
      </Card>
    </div>
  );
}
