# Il Metodo Villa — Manuale Operativo v2.0

Evoluzione del Metodo Villa v1 (distillato da 9 CLAUDE.md di progetti
reali, 2026-03-20), aggiornata con le lezioni apprese durante lo
sviluppo di Creation Machine (157 blocchi completati al 2026-05-22).

Un sistema unificato di regole operative per lo sviluppo software
condotto da Claude, con focus su: workflow a blocchi atomici, pensiero
critico, qualita, sicurezza, e gestione efficiente del contesto.

## Indice

| File | Descrizione |
|------|-------------|
| **00-CLAUDE-OPERATIVO.md** ⭐ | **Nuovo in v2 (2026-06-07)** — Le regole operative del Metodo in forma compressa (sez. 1-15), estratte dal vecchio CLAUDE.md misto. È il file richiamato dal CLAUDE.md magro di ogni progetto (split Metodo/progetto, vedi cap. 19) |
| **01-filosofia.md** | Filosofia di lavoro, pensiero critico come regola d'oro, i quattro principi (Solido > Sbrigativo, ecc.), raccolta idee |
| **02-workflow-blocchi.md** | Workflow a blocchi dettagliato: apertura sessione, durante, chiusura, prompt handoff, test manuali |
| **03-ciclo-continuo.md** | Automazione del ciclo continuo e checkpoint obbligatori (stop vs avanzamento automatico) |
| **04-testing.md** | 4 livelli di testing (L1 obbligatorio, L2/L3/L4 progressivi), integrazione nel ciclo continuo |
| **05-qualita-sicurezza.md** | Standard di qualita (sicurezza, robustezza, manutenibilita), guardiani di blocco e fase, sicurezza di sistema |
| **06-scorciatoie-sviluppo.md** | Gestione scorciatoie di sviluppo, registrazione obbligatoria in `docs/diario/dev-shortcuts.md`, checkpoint pre-produzione |
| **07-gestione-codice.md** | Commit policy, branching, naming (lingua per componente), disciplina di sviluppo |
| **08-gestione-progetto.md** | Stato progetto, protocollo risveglio dopo pausa, gestione dipendenze, deployment, log decisioni |
| **09-struttura-file.md** | Struttura file standard (CLAUDE.md, ROADMAP.md, dev-shortcuts.md, .claude/), come attivare il sistema |
| **10-sizing-blocchi.md** ⭐ | **Nuovo in v2** — Regola fondamentale "1 blocco = 1 verifica", test di applicazione, esempi di sizing sbagliato |
| **11-deploy-checkout.md** | Fase di deploy: handoff finale, 4 domande obbligatorie, checkout pre-produzione |
| **12-autonomia-runner.md** ⭐ | **Nuovo in v2** — 6 regole di autonomia decisionale durante runner automatico (sicurezza, DB, librerie, scope, errori blocchi, **norme di legge**) |
| **13-plugin-esterni.md** ⭐ | **Nuovo in v2** — SuperPowers e AwesomeDesign: cosa sono, quando servono, automatismo di proposta di installazione |
| **14-sequencing-blocchi.md** ⭐ | **Nuovo in v2** — Sequencing dei blocchi: i blocchi umani/collaborativi in testa o coda, mai in mezzo a una sequenza autonoma (anti-pattern del runner che si ferma a metà) · **la procedura guidata** che ogni blocco 👤 porta con sé |
| **15-validazione-multi-agente.md** ⭐ | **Nuovo in v2** — Validare artefatti importanti (roadmap corpose, design) con più agenti freschi a contesto pulito e prospettive diverse, prima di sigillarli |
| **16-design-core.md** ⭐ | **Nuovo in v2** — Cuore comune del design web+mobile: principi universali (token, un accento, severity coding, densità, gerarchia, tipografia, accessibilità, italiano), pattern universali, stati UX, anti-pattern. Neutro rispetto allo stack. Specializzato da 17 (web) e 18 (mobile) |
| **17-design-web.md** ⭐ | **Nuovo in v2** — Manuale di stile web (specializzazione del 16): stack cementato, token HSL, 10 pattern compositi + 5 pattern di pagina, AppShell, microinterazioni, accessibilità. Distillato e neutralizzato dal dominio. Fonte operativa della skill `seeding-visivo-web` |
| **18-design-mobile.md** ⭐ | **Nuovo in v2** — Manuale di stile mobile (specializzazione del 16): stack Flutter cementato, tema centralizzato + ColorScheme, token Dart, pattern compositi + pattern di schermata, struttura app (AppBar / bottom nav / bottom sheet / FAB), microinterazioni + feedback aptico, accessibilità, moduli opzionali. Distillato dal comune di due app Flutter reali. Fonte operativa della skill `seeding-visivo-mobile` |
| **19-sync-metodo.md** ⭐ | **Nuovo in v2 (2026-06-07)** — Aggiornamento del Metodo a due sensi (madre ↔ progetti): scarico/rimando, lista bianca, split CLAUDE.md, eccezioni per progetto, governance. Strumento `metodo/metodo-sync.sh` |
| **20-progettazione-ux.md** ⭐ | **Nuovo (2026-06-25)** — Progettazione dell'esperienza (UX) prima di costruire il frontend: produce `mappa-esperienza.md` (elenco schermate, navigazione, 2-4 flussi, tabella per-schermata con colonna Stati obbligatoria). Due modalità (manuale 🤝 / automatica 🤖 con revisione anche via Telegram/voce). Sta tra `discovery` e il seeding. Paletti anti-burocrazia (niente personas / hi-fi a mano / Figma) |
| **21-corsie-parallele.md** ⭐ | **Nuovo (2026-08-09)** — Lavorare su piu' corsie in parallelo dentro lo stesso progetto: forma tronco/rami/riunione, distinzione fondamenta/confini, regola del congelamento (in corsia il comune e' in sola lettura, chi deve toccarlo si ferma), tre condizioni per dividere, quando non conviene, etichetta `[[CORSIA]]` in roadmap, diario separato per corsia, riunione una-per-volta, 4 anti-pattern. Il parallelo NON e' il default |
| **22-agenti-esecutori.md** ⭐ | **Nuovo (2026-08-09)** — Il Metodo non dipende da un solo programma: il **contratto minimo** che un agente esecutore deve rispettare (lavora senza nessuno davanti, legge/scrive/esegue, salta i permessi, termina da solo, accetta messaggi lunghi, scrive l'handoff nel formato giusto), la trappola della riga di comando (~32.000 caratteri su Windows), agenti supportati (`claude` default, `opencode`), cosa si perde fuori da Claude Code (le competenze vanno elencate nel messaggio), perche' il gateway e' scartato come fondamenta, come si aggiunge un agente nuovo |
| **23-risparmio-token.md** ⭐ | **Nuovo (2026-08-11)** — Perche' nel Metodo ogni riga di contesto si ripaga a ogni blocco (il runner riparte da capo e fra un'invocazione e l'altra la cache non aggancia — misurato), i quattro tagli gia' fatti nel motore (roadmap ridotta alla fase in corso, regole non spedite due volte, nessun ordine di rileggere cio' che c'e' gia', tetto al diario), il filtro dell'output dei test con la sua regola di sicurezza (puo' solo mostrare meno, mai cambiare l'esito), e cosa NON si taglia mai. Misure e leve ancora aperte: `docs/fondamenta/risparmio-token.md` |
| **24-guardiano-degli-stop.md** ⭐ | **Nuovo (2026-08-12)** — Cosa succede quando il runner si ferma: scrive a Villa nella sezione Telegram del progetto e aspetta 10 minuti (risposta anche vocale, e se lui risponde si continua a parlare); se non lo sente decide da solo secondo direttive precise (solido non sbrigativo, mai sopra un test rosso, sicurezza al massimo, decisioni di prodotto solo in forma reversibile o stop). Ogni decisione finisce nel diario, su Telegram e nel riepilogo. Freni: 3 interventi per corsa, si puo' spegnere. Non tocca i blocchi 👤/🤝, che sono stop pianificati |
| **25-ganci-del-metodo.md** ⭐ | **Nuovo (2026-08-12)** — Perche' una regola scritta otto volte nel manuale non basta, e come si tiene in piedi davvero: con un **innesco osservabile**, non con un'esortazione. I due ganci esistenti (competenze quando nasce un file di interfaccia, filtro dell'output dei test), le due regole che li rendono innocui (non bloccano mai, parlano una volta sola per sessione), e cosa NON risolvono — la progettazione dell'esperienza, che deve stare in roadmap |
| **26-memoria-di-lavoro.md** ⭐ | **Nuovo (2026-08-12)** — Riempire la sessione invece di tagliarla: finito un blocco andato bene, se la memoria di lavoro e' occupata entro il 35% il blocco dopo continua nella STESSA sessione, e il preambolo (~30.000 unita') si paga una volta ogni tre-quattro blocchi invece che ogni volta. Il tetto al 50% perche' oltre meta' finestra il modello ragiona misurabilmente peggio. Non si concatena mai dopo un problema: il pasticcio non si eredita. Idea di Villa |
| **27-sorvegliante.md** ⭐ | **Nuovo (2026-08-12)** — Il runner non taglia piu' la sessione allo scadere di un tempo fisso: guarda se l'agente sta ancora lavorando (il suo diario di sessione cresce) e lo lascia finire; interviene se e' PIANTATO (fermo 10 minuti) o oltre un tetto assoluto. Il perche' dell'interruzione viaggia col guardiano, perche' «piantato» e «troppo lungo» portano a decisioni diverse. E ora TUTTI gli stop non programmati (sessione crollata, diario mancante, stato ignoto, giro a vuoto) passano dal guardiano, non solo quelli dichiarati dall'agente |
| **28-indirizzario-precedenti.md** ⭐ | **Nuovo (2026-08-14)** — Le stesse cose risolte piu' volte in venti progetti. Non un archivio di componenti (costa tre volte, diverge dal giorno dopo, e quasi tutto l'agente lo capisce da solo leggendo il codice): un **indirizzario** che tiene solo cio' che dal codice non si ricava — che la cosa esiste, dove sta, se e' prendibile, **com'e' andata sul campo**. Un file per progetto in `.claude/precedenti/`, cercabile con `metodo/cerca-precedenti.py`, agganciato all'apertura del blocco e alla nascita di un file nuovo. Idea di Villa |
| **29-caccia-ai-problemi.md** ⭐ | **Nuovo (2026-08-19)** — La disciplina davanti a un difetto difficile: **niente ipotesi finche' non esiste un comando che va rosso**, i dieci modi per costruirlo, il ciclo **stretto** (veloce, deterministico, segnale netto), il problema intermittente (alzare il tasso, non cercare la riproduzione pulita), la minimizzazione, 3-5 ipotesi falsificabili **prima** di provarne una, le tracce etichettate e la lista di chiusura (l'ipotesi giusta finisce nel commit). Col **tetto**: solo sui problemi difficili, e dopo tre giri senza restringere si consegna cio' che si e' capito |
| **30-vocabolario-del-progetto.md** ⭐ | **Nuovo (2026-08-19)** — Venti parole del dominio, due righe l'una, **e le parole vietate**: quando per la stessa cosa ce ne sono tre, se ne sceglie una e si bandiscono le altre. Si aggiorna nell'istante in cui la parola si decide. Vale **solo dove il dominio ha un lessico proprio** — su un progetto tecnico e' zavorra che si paga a ogni blocco. Villa non legge il codice: le parole **sono** il contratto |

## Cosa e' cambiato rispetto al v1

I file `01-09` e `11` sono identici al v1 (filosofia e regole base
restano valide).

I capitoli **10, 12, 13** sono nuovi e raccolgono lezioni apprese
sviluppando un progetto reale (Creation Machine):
- **Sizing dei blocchi**: errore tipico individuato dopo un blocco di
  50+ minuti che andava spezzato in 3.
- **Autonomia runner**: 6 regole per dare all'agente la responsabilita
  di decisioni tecniche senza chiedere a Villa, quando il runner gira
  automaticamente.
- **Plugin esterni**: SuperPowers (disciplina di sviluppo) e
  AwesomeDesign (stili UI di riferimento), con automatismo di proposta.

La **skill `chiusura-blocco`** in `.claude/skills/chiusura-blocco/SKILL.md`
e' stata anch'essa rivista (sequenza piu' esplicita, gestione test
falliti, riferimento opzionale a `docs/diario/decisioni-da-rivedere.md`).

Tra le skill operative c'e' ora anche **`collaudo-guidato`**
(`.claude/skills/collaudo-guidato/SKILL.md`): conduce il collaudo manuale
esplorativo del prodotto a fine fase / pre-pilot, raccoglie i rilievi e li
trasforma in roadmap. Distillata da un collaudo reale (Big Mama Crew
Planning, 2026-06-06).

## Note operative

Questo manuale e' strutturato per essere letto **una sola volta**
all'inizio del progetto, poi consultato per sezioni specifiche. Ogni
file e' auto-contenuto.

Per l'uso quotidiano, consultare il **CLAUDE.md** nella root del
progetto: e' una sintesi compressa con riferimenti puntuali ai capitoli
del manuale.

---

*v2 distillato il 2026-05-22 dal progetto Creation Machine.*
*v1 generato il 2026-03-20.*
