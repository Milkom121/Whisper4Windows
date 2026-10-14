# 11 — Fase Deploy (checkout di fine progetto)

> Il Metodo Villa copre il ciclo di sviluppo blocco-per-blocco fino al "codice verde e committato". Questo documento aggiunge **la fase deploy**: cosa va deciso e documentato PRIMA di considerare un progetto "live in produzione".

## Obiettivo

Evitare che un progetto finito arrivi in produzione senza risposte chiare su:

- Dove gira (che macchina, che sistema operativo, che runtime)
- Come si ri-avvia se cade
- Come si aggiorna quando fai commit nuovi
- Cosa si rompe se si rompe, e chi se ne accorge

Senza queste risposte il progetto funziona "finche' non lo tocca nessuno", poi alla prima emergenza scopri che non hai runbook e perdi mezza giornata a riscoprire la configurazione.

## Le 4 domande obbligatorie

Rispondile **scritte** nel `PROJECT_CONFIG.md` sezione Deployment del progetto, oppure nel README se il progetto non usa Metodo Villa.

### 1. Dove gira?

- Macchina fisica / VPS / PaaS / Kubernetes cluster?
- Sistema operativo e versione
- Runtime primario (Docker, node nativo, Python venv, systemd unit, ecc.)
- IP / dominio / porta di uscita pubblica

### 2. Come si ri-avvia da solo?

Il servizio deve tornare in piedi da solo almeno in questi scenari:

- Crash del processo
- Reboot della macchina
- Blackout (macchina si spegne bruscamente, poi torna su)

Tecnologie comuni di auto-restart:

- Docker: `restart: unless-stopped` o `restart: always` nel `docker-compose.yml`
- Windows: servizio gestito da NSSM (supervised) o servizio nativo
- Linux: unit `systemd` con `Restart=always`
- Kubernetes: Deployment con replicas >= 1
- PaaS (Railway, Fly, Render): gestito dalla piattaforma

Se la risposta e' "lo riavvio io a mano", **non e' una risposta accettabile per produzione**.

### 3. Come lo aggiorno?

Quando il codice cambia, come arriva in produzione?

- Manuale: documenta il comando esatto (es. `ssh server && cd /app && git pull && docker compose up -d --build`)
- Semi-automatico: CI che produce artifact + tu fai "deploy" con un click
- Auto-deploy: worker che fa polling git / webhook CI / GitOps

Se auto-deploy: specifica il trigger, il healthcheck, la procedura di rollback.

### 4. Cosa si rompe se si rompe?

Se il servizio cade, cosa perde l'utente? Cosa perdono dati/integrita'?

- Si perdono dati in corso? (DB senza backup = rischio maggiore)
- Si perdono utenti? (sessioni non persistenti, carrelli, ecc.)
- Altri progetti sulla stessa macchina sono isolati, o cadono anche loro?
- Chi si accorge che e' caduto? (monitoring automatico, ping umano, notifica Telegram, nessuno)

## Il pattern "ricetta infrastrutturale"

Le scelte concrete per rispondere alle 4 domande dipendono dalla **combinazione macchina + tipo di app**. Non ha senso scrivere regole universali: ogni combinazione e' una **ricetta**.

Convenzione: mantieni le ricette in repo separati dal progetto e dal boilerplate, con nome `infra-<contesto>`. Esempi:

- `infra-windows-docker-cloudflare` — Windows + Docker Desktop + Cloudflare Tunnel + NSSM (tipico setup casa/ufficio)
- `infra-linux-vps-caddy` — VPS Linux + Docker + Caddy reverse proxy
- `infra-synology-nas` — NAS Synology con Container Manager
- `infra-railway` — PaaS Railway (ricetta piu' semplice, la piattaforma fa quasi tutto)

Ogni repo `infra-*` contiene:

- `README.md` — cosa copre, vincoli espliciti, quando usarla
- `CHECKLIST-NUOVA-MACCHINA.md` — setup da zero
- `docs/mappa-porte.md` (o mappa risorse) — cosa e' allocato
- `docs/runbook-reboot.md` (o equivalent) — sequenza attesa + troubleshooting
- `docs/aggiungere-progetto.md` — checklist per ospitare un progetto nuovo
- `scripts/` — automazioni di setup

**Quando finisci un progetto col Metodo Villa e arrivi alla fase deploy**:

1. Rispondi alle 4 domande → le scrivi in `PROJECT_CONFIG.md`
2. Identifica la ricetta giusta per il tuo caso → trovi (o crei) il repo `infra-*` corrispondente
3. Segui la checklist `docs/aggiungere-progetto.md` di quella ricetta
4. Aggiorna la mappa risorse della ricetta

## Perche' non una skill automatica (ancora)

Questa fase **non** e' coperta da una skill Claude oggi. Motivazione:
- Scrivere una skill "deploy universale" con un solo caso reale alle spalle produce astrazioni teoriche
- Per ora: gestiamo la fase a mano seguendo questa checklist + una ricetta `infra-*`
- Quando avremo 3+ deploy in contesti diversi (vedi `docs/diario/ideas.md` — voce "Skill deployment"), si estrarra' il pattern comune e si scrivera' la skill vera

Fino a quel momento: questa pagina e' la guida.
