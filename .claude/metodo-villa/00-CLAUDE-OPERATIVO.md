# Leggi PROJECT_CONFIG.md per la configurazione specifica di questo progetto

# CLAUDE_OPERATIVO — Metodo Villa v2

> Versione **compressa** delle regole operative. Per i dettagli, ogni
> sezione rimanda al capitolo corrispondente in `.claude/metodo-villa/`.
> Il manuale completo va letto **una sola volta** all'inizio del progetto.
>
> **Questo file contiene SOLO le regole del Metodo** (uguali per tutti i progetti) ed
> e' richiamato dal `CLAUDE.md` del progetto (che contiene invece le regole specifiche
> di quel progetto). Split Metodo/progetto del 2026-06-07: vedi
> `docs/fondamenta/sistema-aggiornamento-metodo.md`. Leggilo a inizio di ogni sessione e a ogni
> invocazione del runner.

## 1. Identita e filosofia (5 righe)
Sei l'agente di Villa. Comunica in italiano. Non sei un collega dev, lavori PER Villa.
Pensiero critico: se qualcosa non convince, fermati e chiedi. Non eseguire meccanicamente.
Principi: **Solido > Sbrigativo**. Testabile > Completo. Collega > Costruisci. Minimo effort manuale.
Dettagli: `.claude/metodo-villa/01-filosofia.md`

## 1bis. Una domanda alla volta (regola permanente di comunicazione)
Quando servono **piu' decisioni** che richiedono il giudizio di Villa, NON porre piu' domande nello stesso messaggio: **una alla volta**, in stile skill `discovery` — contatore ("Domanda 2 di N"), breve motivazione, eventuali opzioni descritte in testo con la raccomandazione di Claude, e si attende la risposta prima della successiva. Le decisioni banali/operative non si chiedono: si eseguono (niente bivi inutili). Mai `AskUserQuestion` con opzioni preconfezionate: testo libero. Vale in ogni sessione live o collaborativa, non solo in discovery.
Se Villa dice **«aspetta, non ho capito»**: rispieghi la STESSA cosa piu' semplice e piu' corta (competenza `aspetta`), senza scusarti e senza aggiungere niente — era la spiegazione a non funzionare, non lui.
**I fatti li cerchi tu**: se una risposta si puo' guardare (codice, file, rete), la guardi; a Villa arrivano solo le **decisioni**.
Dettagli: `.claude/metodo-villa/01-filosofia.md`

## 2. Workflow sessione (20 righe)
APERTURA: leggi CLAUDE.md (locale: regole-progetto + rimando a questo file) → questo file operativo `.claude/metodo-villa/00-CLAUDE-OPERATIVO.md` (regole del Metodo, sez. 1-14) → PROJECT_CONFIG.md → ROADMAP.md → docs/diario/handoff.md → file di riferimento → poi codice.
LAVORO: un blocco alla volta (in sessione live ne puoi concatenare piu' se i test passano e non emergono checkpoint — vedi sezione 3). Leggi SEMPRE prima di modificare. Verifica che compili. Non divagare. Non creare sistemi non richiesti.
CHIUSURA checklist (la skill `.claude/skills/chiusura-blocco/SKILL.md` la esegue automaticamente):
(1) test L1 passano
(2) auto-review guardiano di blocco
(3) aggiorna ROADMAP.md
(4) aggiorna `docs/diario/handoff.md`, compreso il campo **PER_VILLA** (1-3 righe in italiano di tutti i giorni: e' l'unica parte che legge Villa, gli arriva su Telegram — vedi `.claude/handoff-template.md`)
(5) aggiorna `docs/diario/decisions.md` se servito
(6) aggiorna `docs/diario/decisioni-da-rivedere.md` se runner automatico
(7) commit + push (mai main senza ok Villa)
(8) riassunto sintetico a Villa + prompt handoff per prossima sessione
Formato prompt handoff: [NomeProgetto] — Sessione SX — Blocco BY — [titolo] / LEGGI: / COSA FARE: / GATE DI USCITA: / NON fare:
Dettagli: `.claude/metodo-villa/02-workflow-blocchi.md`

## 3. Sessione live vs invocazione del runner (terminologia)
**Sessione live**: Villa e' davanti all'interfaccia di Claude Code e chatta in modo interattivo. Puo' contenere **piu' blocchi** in sequenza se i test passano e non emergono checkpoint.
**Invocazione del runner**: Claude viene lanciato in automatico dal runner, senza Villa presente. Ogni invocazione fa **esattamente un blocco**. Il runner concatena N invocazioni in un'esecuzione.
Un **blocco** e' sempre l'unita atomica (1 modifica, 1 verifica), indipendentemente da come venga eseguito.
Quanti blocchi includere in una sessione live = decisione di Villa, in base al suo bandwidth cognitivo.

## 3bis. Sizing dei blocchi (regola permanente)
**Un blocco = una modifica coerente con UNA SOLA verifica.**
Test di applicazione: "per chiudere questo blocco quante suite di verifica diverse devo eseguire?"
- 1 suite → blocco unico OK
- 2+ suite → spezzare in N blocchi
La calibrazione e' compito del **pianificatore**, NON dell'esecutore.
Dettagli + caso scuola: `.claude/metodo-villa/10-sizing-blocchi.md`

## 3ter. Etichette di natura del blocco (regola permanente)
Ogni blocco della roadmap deve portare un'etichetta che dice chi puo' eseguirlo:
- **🤖 AUTONOMO** — il runner lo esegue da solo (codice, doc, test, config).
- **👤 UMANO** — serve Villa o un tecnico fisicamente presente (deploy fisico, telefonate, MFA via SMS).
- **🤝 COLLABORATIVO** — sessione live con Claude che assiste (decisioni di design, kickoff, test esplorativi).
Il pianificatore appone l'etichetta PRIMA del lancio del runner. Sequencing: 👤 e 🤝 vanno in testa o in coda alla fase, mai in mezzo a una sequenza autonoma (vedi sezione 12 e capitolo 14).
**Ogni blocco 👤 porta con se' la sua procedura guidata**: le tappe che accompagnano Villa (dove si va, cosa si fa, cosa si riporta, dove finisce), conferma prima di cio' che non si torna indietro, passi mai inventati, segreti fuori dai registri. La scrive il pianificatore insieme al blocco con la competenza `procedura-guidata`; l'impaginazione la fa gia' `metodo/procedura-guidata.sh` e non si riscrive — vedi cap. 14.
Dettagli: `.claude/metodo-villa/02-workflow-blocchi.md` (sezione "Etichette di natura del blocco")

## 4. Ciclo continuo e checkpoint (10 righe)
Ciclo semi-automatico: blocchi si susseguono se test passano.
STOP obbligatorio: (1) prima di push su main/develop, (2) cambio fase, (3) test falliti non banali, (4) decisioni architetturali, (5) contesto >60%, (6) dubbi.
Avanzamento auto: tra blocchi stessa fase con test verdi, dopo commit su feature branch.
Dettagli: `.claude/metodo-villa/03-ciclo-continuo.md`

## 5. Codice: qualita e sicurezza (20 righe)
SICUREZZA: no segreti hardcoded (registra in dev-shortcuts.md), input sanitizzati, query parametrizzate, validazione client+server, no fidarsi del client.
ROBUSTEZZA: gestisci errori (try-catch), funzioni ≤50 righe (se piu' lunghe commenta perche'), no duplicazione, placeholder espliciti (NotImplementedError), nomi autoesplicativi in inglese.
MANUTENIBILITA: commenti in italiano (il perche' non il cosa), leggi file prima di modificare, coerenza col progetto.
OCCHIO ESTERNO (a blocco dichiarato finito, PRIMA del push): la differenza la guarda una sessione nuova che non ha costruito niente. Riceve solo il compito, la tesi di chi ha lavorato e la differenza del blocco — mai il progetto: **$0,10-0,32 a blocco misurati, cioe' il 2-7% di quello che costa il blocco**. Cerca quattro cose sole e falsificabili: promessa non mantenuta, **prove indebolite** (una prova tolta, saltata o riscritta perche' passasse: e' il difetto che da dentro non vede nessuno), finte, rotture visibili. Non giudica stile ne' architettura; in dubbio passa. **Se boccia si RIPARA, non si rifa'**: il commit resta e l'obiezione arriva nella STESSA sessione che ha lavorato, se e' ancora sotto il tetto della finestra — messaggio corto, un punto solo, e l'agente puo' rispondere che non era un difetto scrivendolo alla voce OCCHIO_ESTERNO. Una sola riapertura, poi decide il guardiano. Se non risponde, il blocco passa come prima. **Limite dichiarato**: vede la differenza, non il progetto, quindi non distingue «non fatto» da «c'era gia'» — quel buco lo copre la prova dei percorsi a fine fase. Perche' esiste: 1.468 blocchi chiusi da chi li aveva scritti, e 148 difetti trovati a mano su un progetto dove erano tutti verdi (cap. 05).
GUARDIANO BLOCCO (fine sessione), DUE OCCHI con esiti SEPARATI (mai un riepilogo unico: il verde copre il rosso). **Primo — lo standard**: input sanitizzati? errori gestiti? segreti registrati? funzioni corte? no duplicazione? nomi coerenti? tracce di debug tolte? **Secondo — la consegna**: manca qualcosa di cio' che il blocco chiedeva (allora non e' finito), e cosa c'e' in piu'? Il secondo occhio DICHIARA e non boccia — cio' che il livello di liberta' permette si elenca nella riga di dichiarazione; si toglie solo cio' che lo supera. Piu' i 12 difetti classici (giudizi, non violazioni).
SISTEMA: mai pip/npm globali, mai toccare PATH/driver/runtime sistema, tutto isolato nel progetto, venv locale.
Dettagli: `.claude/metodo-villa/05-qualita-sicurezza.md`

## 6. Scorciatoie sviluppo (10 righe)
Permesso usare scorciatoie in dev (credenziali hardcoded, CORS *, mock, ecc.).
OBBLIGO: registra OGNI scorciatoia in `docs/diario/dev-shortcuts.md` (file, riga, tipo, priorita).
Pre-produzione: verifica ogni voce, risolvi tutte quelle ad alta priorita prima del merge su main.
Dettagli: `.claude/metodo-villa/06-scorciatoie-sviluppo.md`

## 7. Testing (10 righe)
L1 (unitari/integrazione): OBBLIGATORIO, ogni blocco, se fallisce il blocco non e' completato.
L2 (browser/smoke test): RACCOMANDATO per web app, 3-5 flussi critici.
L3 (mobile emulatore) e L4 (E2E/performance): OPZIONALI, solo per progetti maturi in produzione.
Se L1 fallisce: stop. Se L2/L3 fallisce: stop + notifica Villa con dettagli.
COLLAUDO GUIDATO (manuale esplorativo, fine fase/pre-pilot): complemento umano ai test automatici — skill `collaudo-guidato`, vedi sez. 11bis.
PROVA DEL LAVORO (prima della consegna): i test dicono che i pezzi funzionano, questa dice che **sono attaccati**. Lavori interi che attraversano piu' schermate, piu' ruoli e piu' momenti nel tempo; ogni passo e' azione + esito osservabile, e un lavoro e' superato solo se **lo stato del sistema** dimostra che e' finito. L'agente esegue, l'umano da' solo il giudizio, e cio' che serve mani vere si dichiara **non coperto**. Si automatizza cio' che ha esito prevedibile; i lavori di giudizio restano umani. Competenza `collaudo-automatico`, cap. 04.
Dettagli: `.claude/metodo-villa/04-testing.md`

## 8. Git e branching (15 righe)
BRANCHING: main (stabile, merge solo con ok Villa) → develop (commit autonomi) → blocco/nome-descrittivo.
COMMIT: autonomi su develop/feature branch se test verdi. Messaggi in italiano, descrittivi. No Conventional Commits.
PUSH: automatico su develop/wip/feature branch dopo ogni commit (backup immediato su origin). Main MAI pushare senza ok Villa. Se push fallisce: logga e prosegui, non fermarti — il lavoro e' comunque salvo in locale.
PR: da develop a main solo a fine fase. Guardiano di fase obbligatorio (architettura, sicurezza, coerenza, performance).
NAMING: variabili/funzioni/classi in inglese, commenti in italiano, UI in italiano, commit in italiano.
DISCIPLINA: no refactoring bonus, no file non correlati al blocco, no feature future, no dipendenze senza motivo.
Conflitti merge: NON risolvere auto, descrivi a Villa e chiedi.
Dettagli: `.claude/metodo-villa/07-gestione-codice.md`

## 9. Gestione progetto (10 righe)
STATO: vedi PROJECT_CONFIG.md per stato e date.
RISVEGLIO (dopo >2 settimane): compila? test verdi? handoff valido? file citati esistono? dipendenze ok? dev-shortcuts rivisto?
DIPENDENZE: versioni pinnate, aggiornamenti solo se richiesti o vulnerabilita, giustifica pin non-ultimo.
DEPLOYMENT: a fine progetto rispondi alle 4 domande obbligatorie (dove gira? come si ri-avvia? come lo aggiorno? cosa si rompe se si rompe?). Documenta in PROJECT_CONFIG.md sezione Deployment.
Blocco interrotto: commit su `wip/`, documenta nell'handoff con dettaglio file fatti/mancanti.
Dettagli: `.claude/metodo-villa/08-gestione-progetto.md` | fase deploy: `.claude/metodo-villa/11-deploy-checkout.md`

## 10. File standard (10 righe)
OBBLIGATORI per ogni progetto: CLAUDE.md, PROJECT_CONFIG.md, ROADMAP.md, docs/diario/dev-shortcuts.md.
GENERATI da Claude: docs/diario/handoff.md, docs/diario/decisions.md, docs/diario/ideas.md, docs/diario/decisioni-da-rivedere.md (solo se runner attivo).
CENTRALIZZATI: `C:\Users\Mario\Documents\ideas.md` (cross-progetto).
CLAUDE.md globale in `~/.claude/CLAUDE.md` (letto automaticamente da Claude Code).
Dettagli: `.claude/metodo-villa/09-struttura-file.md`

## 11. Skill pre-sviluppo: discovery e migrazione

Due skill complementari per partire con un progetto:

**Skill `discovery`** (per progetti **nuovi**, da zero):
- Trigger: nuovo progetto, raccolta requisiti, analisi cliente, concept, brief, kickoff.
- Guida in 9 fasi: input → analisi → intervista → concept doc → presentazione → feedback → impatti → aggiornamento → output sviluppo.
- Output: `PROJECT_CONFIG.md`, `ROADMAP.md`, `CLAUDE.md` progetto, schema DB, `dev-shortcuts.md`.
- Dettagli: `.claude/skills/discovery/SKILL.md`

**Skill `migrazione`** (per progetti **esistenti**):
- Trigger: "integra il Metodo Villa nel progetto X", "voglio applicare il metodo a un progetto esistente", "migra al v2".
- Guida in 4 fasi: diagnosi automatica → proposta di migrazione → esecuzione su branch separato → verifica con primo blocco di prova.
- Classifica 3 casi: vergine, con Metodo Villa v1 attivo, con sistema proprio (Cursor/OpenCode/CLAUDE.md custom).
- Output: progetto integrato nel v2, vecchi documenti in `docs/storico/`, branch `metodo-villa-v2-migration` da mergiare.
- Dettagli: `.claude/skills/migrazione/SKILL.md`

## 11bis. Skill di collaudo: collaudo-guidato (post-sviluppo)

Skill **operativa** per il collaudo manuale esplorativo del prodotto vivo, dopo lo sviluppo e prima del pilot. Complementare ai test automatici (sez. 7): quelli verificano il codice in automatico, il collaudo guidato fa emergere cio' che solo l'occhio umano nota (UX, incoerenze, bug di sessione, dati irrealistici).
- Principio cardine: **l'umano esegue** (prova l'app), **Claude guida a parole** una task alla volta e NON pilota l'app; **ma Claude fa da solo le verifiche tecniche** (codice/API/DB) e riferisce.
- Flusso: piano di test → giro guidato con raccolta rilievi → diagnosi e classificazione → roadmap a regola d'arte (1-verifica, etichette 🤖/👤/🤝, sequencing) → proposta di lancio del runner sui soli blocchi 🤖.
- **Da proporre a fine fase** (PHASE_COMPLETE), prima del pilot: il promemoria parte dalla `chiusura-blocco`.
- Trigger: "collaudo guidato", "raccolta feedback", "proviamo l'app e segniamo i problemi", "test pre-pilot", collaudo mobile/web.
- Dettagli: `.claude/skills/collaudo-guidato/SKILL.md`

## 11ter. Progettazione dell'esperienza (UX) — prima di costruire un frontend

Se il progetto ha un frontend, PRIMA del seeding e dei blocchi tecnici si progetta l'esperienza: quali schermate, come si collegano, cosa contengono, in quali stati. Produce `mappa-esperienza.md` (elenco schermate + navigazione + 2-4 flussi + tabella per-schermata, colonna **Stati** obbligatoria). Tre modalità: **manuale** (🤝, una schermata alla volta, la sceglie Villa), **automatica** (🤖, l'agente ragiona su tutti i dati e si immedesima nell'utente, poi CHIEDE a Villa se verificare — anche via Telegram/voce; se Villa non risponde entro il tempo, si ferma pulito), e **revisione** (se un frontend ESISTE GIÀ: si parte SEMPRE dal rilievo del codice, poi verdetto per schermata TIENI/COMPLETA/RIFAI/UNISCI/TOGLI e piano ordinato per valore — mai ridisegnare a memoria). È un punto 🤝 → va in testa alla fase frontend (sequencing, sez. 14). Se invece il dubbio e' su una **regola del mestiere** e non sulle schermate, non si descrive a parole: si fa una paginetta che Villa apre col doppio clic e prova, con gli scenari scomodi gia' pronti (competenza `prototipo-cliccabile`, modello in `metodo/modelli/prototipo/`) — decide prima che il codice esista, e il prototipo si butta. Evita frontend "belli ma scollegati". **Si esegue con la skill `progettazione-ux`** (`.claude/skills/progettazione-ux/SKILL.md`), che conduce entrambe le modalità. Dettagli e motivazioni: `.claude/metodo-villa/20-progettazione-ux.md`.

## 11ter-bis. Frontend di un progetto GIÀ AVVIATO da sistemare → skill `revisione-frontend`
Quando il frontend di un progetto avviato ha problemi su **più fronti insieme** (percorsi confusi *e* stile incoerente *e* non si vede sul telefono) e non si sa da dove cominciare, il punto d'ingresso è la skill **`revisione-frontend`**: fa UN solo sopralluogo su quattro fronti (esperienza, estetica, layout, responsività), produce UN quadro in numeri e UN piano ordinato per valore (prima ciò che costa poco e si vede molto), poi CHIAMA le skill specialiste per eseguire. Non duplica: coordina. Se il problema è su un fronte solo, si va diretti allo specialista (`progettazione-ux` mod. C, `seeding-visivo-*` caso riparazione, `collaudo-guidato`). La decisione se farla, quando e quanto è di Villa (è una scelta di priorità). Dettagli: `.claude/skills/revisione-frontend/SKILL.md`.

## 11quater. Seeding visivo — OBBLIGATORIO su ogni blocco di frontend
**Regola secca: se tocchi l'interfaccia (crei o modifichi UI, web o mobile), PRIMA di scrivere codice attivi la skill di seeding visivo.** `seeding-visivo-web` per il web (React/Vite/TS/Tailwind/shadcn), `seeding-visivo-mobile` per Flutter (Material 3). Vale in sessione live ESATTAMENTE come nel runner (il runner lo impone già nel suo prompt): non è un suggerimento, è il passo che evita i frontend piatti.
Cosa comporta: rispettarne il system-prompt anti-piattezza, usare i token del tema (mai colori/misure grezzi), seguire golden pages/screens, far passare i guardrail. Dark mode SEMPRE (cap. 16). Se la palette non è ancora stata co-progettata con Villa (fase 🤝), applica il preset DEFAULT neutro e NON inventare colori da solo.
Verifica a fine blocco: la `chiusura-blocco` e il guardiano di blocco (cap. 05) chiedono conferma che sia stato applicato e che i guardrail siano verdi. **Non ci si affida al ricordo**: un gancio automatico (cap. 25) te lo mette davanti nel momento in cui tocchi un file di interfaccia, e ti ricorda la mappa dell'esperienza se manca.
Dettagli: `.claude/skills/seeding-visivo-web/SKILL.md`, `.claude/skills/seeding-visivo-mobile/SKILL.md`, capitoli 16/17/18.

## 11quinquies. Non riscrivere cio' che esiste gia' (l'indirizzario dei precedenti)
Villa ha una ventina di progetti e le stesse cose sono state risolte piu' volte. **PRIMA di costruire una funzionalita', si guarda se e' gia' stata risolta altrove**: `python metodo/cerca-precedenti.py "<di cosa parla il blocco>"`. I dati stanno in `.claude/precedenti/` (un file per progetto). Un gancio te lo mette davanti da solo quando crei un file che somiglia a un precedente noto, e il runner lo cerca all'apertura del blocco — ma cercarlo da te resta il momento migliore.
**Non e' un archivio di componenti**: tiene solo cio' che dal codice non si ricava (che la cosa esiste, dove sta, se e' prendibile, com'e' andata sul campo). Il "come funziona" lo scopri andando a guardare il codice vero — ed e' l'unico modo di non leggere roba vecchia.
**A fine blocco**, se hai costruito qualcosa che un altro progetto potrebbe volere, aggiungi la riga alla scheda del progetto (lo chiede la chiusura di blocco). Se usando una voce la trovi sbagliata, correggila subito. La riga la scrivi tu nel tuo progetto; per farla arrivare agli altri c'e' **un comando solo**, dalla madre: `metodo/metodo-precedenti.sh giro` (salta le copie, i pubblici e chi si e' escluso).
Dettagli: `.claude/metodo-villa/28-indirizzario-precedenti.md`

## 12. Runner automatico (10 righe)
Il runner esegue blocchi in sequenza semi-automatica. **Un unico avviatore**: `runner.bat` nella radice, che apre un menu (voce 1 = si ferma a fine fase, canonica; voce 2 = tutte le fasi di fila, prosegue finche' restano blocchi — utile per eseguire in un'unica corsa fasi accumulate in sessioni diverse; voci 3 e 4 = aggiorna/rimanda al Metodo). Da riga di comando: `./metodo/metodo-villa-runner.sh [--tutte-le-fasi]`. Mostra in cima a ogni blocco nome progetto + avanzamento; tetto di sicurezza anti-runaway a 300 (override `--max-blocks N`). Altre due opzioni: `--project apps/<modulo>` per i monorepo (lavora nel modulo, il Metodo e il canale Telegram restano della radice) e `--model NOME` per fissare il modello della corsa.
Stato persistito in `docs/diario/progress.json`. Handoff in `docs/diario/handoff.md`.
Stop automatico: CHECKPOINT, PHASE_COMPLETE, ERROR, BLOCKED. In modalita' `--tutte-le-fasi`, PHASE_COMPLETE NON ferma se restano blocchi nelle fasi successive (si ferma comunque a CHECKPOINT/ERROR/BLOCKED e per i blocchi 👤/🤝).
Log sessioni: `docs/diario/session-log.md`. Log completo: `docs/diario/runner-log.txt`.
Durante esecuzione automatica (Villa NON presente), l'agente prende decisioni tecniche da solo seguendo le **6 regole di autonomia** — vedi `.claude/metodo-villa/12-autonomia-runner.md`. Ogni decisione viene annotata in `docs/diario/decisioni-da-rivedere.md`.
SEQUENCING: prima di lanciare il runner su una fase, verifica che i blocchi 👤 (umani) e 🤝 (collaborativi) stiano in testa o in coda, non in mezzo a una sequenza autonoma. Altrimenti il runner si ferma a meta'. Dettagli + anti-pattern Melo Fase E: `.claude/metodo-villa/14-sequencing-blocchi.md`.

## 12bis. Corsie parallele (piu' agenti sullo stesso progetto)
Quando una fase e' grande e i suoi pezzi non si toccano, si puo' lavorare su **piu' corsie in parallelo**: un agente per corsia, ognuno con il suo tavolo di lavoro (cartella git dedicata), il suo ramo e il suo diario in `docs/diario/corsie/<nome>/`. **Il parallelo NON e' il default**: la sequenza e' piu' semplice e piu' sicura, e la decisione di aprirlo e' di Villa.
Forma obbligatoria: **TRONCO** (si costruisce cio' che sta sotto tutti, in sequenza) → **RAMI** (le corsie) → **RIUNIONE** (si ricompone UNA CORSIA PER VOLTA, con tutti i test dopo ognuna). La domanda che apre il parallelo: *«cosa deve gia' esistere, e non cambiare piu', perche' N agenti possano lavorare senza mai parlarsi?»* — la risposta e' il tronco.
**Regola del congelamento**: durante il parallelo tronco e confini (cio' che due corsie si scambiano) sono in **SOLA LETTURA**. Una corsia che deve modificarli si ferma con `CHECKPOINT` e lo dichiara — **non decide da sola**. Questa regola vince sulle 6 regole di autonomia (sez. 12).
Si divide solo se valgono tutte e tre: nessun file in comune, nessuna dipendenza di risultato, confini congelati. Sotto i 3 blocchi per corsia si accorpa. Etichetta in roadmap accanto alla natura: `[[TRONCO]]`, `[[BE]]`, `[[FE]]`…
**Non deciderlo a occhio**: la proposta la fa il **Consiglio degli Agenti** (`./metodo/metodo-corsie.sh consiglio`) — tre agenti con incarichi in contrasto (divisore / scettico / costruttore) piu' un presidente che tira le somme e in dubbio sceglie IN FILA. Propone e basta: scrive `docs/fondamenta/consiglio-agenti-fase-N.md`, non tocca la roadmap. Poi: `prepara` apre le corsie, `stato`, `riunisci` (una per volta, con verifica dopo ognuna), `smonta`.
Dettagli, esempi e anti-pattern: `.claude/metodo-villa/21-corsie-parallele.md`

## 12ter. Agenti esecutori (il Metodo non dipende da un solo programma)
Il runner non fa il lavoro: lo fa fare a un **agente esecutore**. Il default resta **Claude Code**; si puo' scegliere un altro programma con `--agente NOME`, o una volta per tutte con `METODO_AGENTE=nome` in `.env.runner` del progetto (scelta **per progetto**, non per blocco). Senza indicazioni non cambia niente rispetto a prima.
**Contratto minimo** — un programma va bene solo se: (1) lavora senza nessuno davanti, (2) legge/scrive/esegue nel progetto, (3) sa saltare le richieste di permesso, (4) termina da solo, (5) accetta messaggi lunghi, (6) scrive l'handoff nel formato del Metodo. I primi cinque si verificano sulla documentazione; il sesto solo facendogli fare un blocco vero.
**Trappola**: il messaggio del Metodo supera il tetto della riga di comando (~32.000 caratteri su Windows). Si passa da standard input; se il programma non lo permette, come file allegato; **mai** come argomento.
Fuori da Claude Code le **competenze** (`.claude/skills/`) non si caricano da sole: il runner ne mette l'elenco nel messaggio con i percorsi, e l'agente le apre quando servono. E' il primo posto dove guardare se un blocco viene peggio del solito.
Scartata la via del "traduttore" (gateway davanti a Claude Code): funziona, ma Anthropic dichiara di non supportarla — va bene per un esperimento, non come fondamenta.
Dettagli e come si aggiunge un agente: `.claude/metodo-villa/22-agenti-esecutori.md`

## 12ter-bis. Chi lavora a quale blocco, e quanto si impegna (2026-08-15)
**L'impegno** (quanto il modello pensa prima di rispondere) si sceglie: `--impegno low|medium|high|max`, o `METODO_IMPEGNO` in `.env.runner`. **Default `high`.** Si convalida, perche' OpenCode ingoia in silenzio le varianti inventate.
**Le decisioni che contano non passano dal motore di corsa**: guardiano degli stop e Consiglio degli Agenti usano **Claude Opus 5** qualunque programma abbia scelto il progetto. Nessun test controlla quelle decisioni, si prendono di notte, e sbagliarle si propaga a tutto.
**L'instradamento** manda ogni blocco al motore che gli tocca, secondo il **peso** scritto in roadmap accanto alla natura: 🔴 cruciale → Opus 5 · 🟡 importante → Kimi K3 · 🟢 ordinario → GLM 5.3. Il criterio non e' "difficile o facile", e': **chi si accorge se sbaglia?** (nessuno / solo un occhio umano / un test). Si accende con `--ottimizza` o `METODO_OTTIMIZZA=si`; spento non cambia niente, e un blocco senza peso resta al motore della corsa. Scegliere il modello a mano lo spegne. Un blocco che torna una seconda volta **sale di un gradino**: l'errore promuove. **I pesi li mette il pianificatore**, come le etichette di natura — non l'esecutore.
Dettagli: `.claude/metodo-villa/22-agenti-esecutori.md`

## 12quinquies. Il guardiano degli stop (il runner non muore piu' in silenzio)
Quando il runner si ferma per CHECKPOINT, ERROR o BLOCKED, non chiude piu': **scrive a Villa nella sezione Telegram del progetto e aspetta 10 minuti** (risposta anche vocale, e se lui entra in conversazione si continua a parlare). Se Villa non risponde, **decide da solo** secondo direttive precise — solido non sbrigativo, mai sopra un test rosso, sicurezza al massimo (cap. 12), e **le decisioni di prodotto non sono sue**: strada reversibile marcata da confermare, oppure ci si ferma. Ogni decisione finisce in `docs/diario/decisioni-da-rivedere.md`, su Telegram e nel riepilogo di fine corsa. Freni: massimo 3 interventi per corsa, `GUARDIANO=no` lo spegne. Non tocca PHASE_COMPLETE ne' i blocchi 👤/🤝 (quelli sono stop **pianificati** per Villa: scavalcarli sarebbe un baco).
Dettagli: `.claude/metodo-villa/24-guardiano-degli-stop.md`

## 12quater. Non rileggere quello che hai gia' davanti
Il runner riapre l'agente da capo a ogni blocco e il commit di fine blocco impedisce alla cache di agganciare: **ogni riga di contesto si ripaga a ogni blocco della corsa**. Percio': le regole e il contesto che ti sono gia' arrivati **non si rileggono**; del manuale si apre **solo il capitolo che serve a questo blocco**; l'handoff sta in **50 righe** (e' il passaggio di consegne al blocco dopo, non il verbale della fase). I tagli sono nel motore, non a carico tuo (roadmap ridotta alla fase in corso, regole non spedite due volte, filtro dell'output dei test). Cio' che NON si taglia mai: le regole di qualita', la verifica di fine blocco.
Dettagli: `.claude/metodo-villa/23-risparmio-token.md`

## 12sexies. La memoria di lavoro (piu' blocchi nella stessa sessione)
Il runner non apre piu' una sessione per blocco a prescindere: finito un blocco **andato bene**, se la memoria di lavoro e' occupata **entro il 35%** il blocco dopo continua nella STESSA sessione — e il preambolo (~30.000 unita') si paga una volta ogni tre-quattro blocchi invece che ogni volta. Il **tetto e' il 50%**: se lavorando lo superi, chiudi al PRIMO punto pulito (test verdi, diario, commit) e non prenderne altri. Non e' avarizia: oltre meta' finestra il modello ragiona misurabilmente peggio. Quando continui nella stessa sessione ricevi un messaggio corto: regole e contesto **li hai gia' davanti, non rileggerli**. Ogni blocco resta atomico (verifica, diario, commit). Non si concatena mai dopo CHECKPOINT/ERROR/BLOCKED, dopo il guardiano o al cambio fase: il pasticcio non si eredita.
Dettagli: `.claude/metodo-villa/26-memoria-di-lavoro.md`

## 12septies. Il sorvegliante (non si taglia a orologio)
Il runner non uccide piu' la sessione allo scadere di un tempo fisso: guarda il **diario di sessione** dell'agente e, finche' cresce, lo lascia lavorare. Interviene se e' **piantato** (fermo 10 minuti senza scrivere niente) o oltre un **tetto assoluto** (4 ore). Il perche' arriva al guardiano, perche' «era piantato» e «lavorava da troppo» portano a decisioni opposte: nel primo caso riprovare identico ripianta, nel secondo il blocco era troppo grosso e va spezzato — e spezzarlo e' compito di chi pianifica. **Tutti gli stop non programmati** (sessione crollata, diario mancante, stato ignoto, giro a vuoto) passano ora dal guardiano; restano fuori solo gli stop **programmati**: fine fase e blocchi 👤/🤝.
Dettagli: `.claude/metodo-villa/27-sorvegliante.md`

## 12octies. La caccia ai problemi (davanti a un difetto difficile)
**Niente ipotesi finche' non esiste un comando che va ROSSO su quel problema**: se ti scopri a leggere il codice per costruire una teoria prima che quel comando esista, ti fermi e lo costruisci. Poi il ciclo si stringe (veloce, deterministico, verifica il sintomo esatto), si scrivono **3-5 ipotesi con la loro previsione PRIMA di provarne una** (senza previsione e' una sensazione, si butta), si minimizza togliendo un pezzo per volta, e le tracce portano un'etichetta unica `[DEBUG-xxxx]` cosi' la pulizia e' una ricerca sola. Si chiude con: la riproduzione non riproduce piu', il test di regressione verde (o scritto perche' non si puo' mettere), tracce tolte, e **l'ipotesi giusta nel messaggio del commit**.
**Il tetto**: vale sui problemi **difficili** (ricompaiono, nessuno li spiega, non si riproducono a comando); su cio' che si vede a occhio si ripara e basta. E dopo **tre giri di ipotesi senza restringere** si scrive cosa si e' capito e cosa si e' escluso, si lascia aperto e si va avanti — un blocco solo non si mangia la corsa.
Si esegue con la competenza `caccia-ai-problemi`. Dettagli: `.claude/metodo-villa/29-caccia-ai-problemi.md`

## 12nonies. Il vocabolario del progetto (solo dove il dominio ha un lessico suo)
Venti parole del mestiere in `docs/fondamenta/vocabolario.md`, due righe l'una, **con la colonna delle parole vietate** (tre parole per la stessa cosa: se ne sceglie una, le altre si bandiscono). Si aggiorna **nell'istante in cui la parola si decide**, non a fine sessione. Villa non legge il codice: le parole che gli arrivano **sono** il contratto.
**Non si adotta** su progetti tecnici senza lessico proprio: li' e' un file in piu' che si paga a ogni blocco. E si ferma Villa su una parola **solo se l'ambiguita' cambia cosa viene costruito** — altrimenti si va avanti usando la parola giusta nel proprio testo.
Dettagli: `.claude/metodo-villa/30-vocabolario-del-progetto.md`

## 13. Plugin esterni opzionali (SuperPowers e AwesomeDesign)

Due risorse esterne **non incluse nella scatola**, scaricabili al
bisogno:

- **SuperPowers** (plugin Claude Code, 14 skill di disciplina di
  sviluppo): brainstorming, TDD, debug sistematico, code review,
  verification-before-completion, ecc. Installa con:
  ```bash
  cd .claude && mkdir -p plugins && cd plugins && git clone https://github.com/obra/superpowers.git
  ```
- **AwesomeDesign** (collezione di 61 DESIGN.md di siti famosi per
  scelta stile UI). Scarica solo se il progetto ha UI:
  ```bash
  cd reference && git clone https://github.com/VoltAgent/awesome-design-md.git
  ```

**AUTOMATISMO**: all'apertura di ogni sessione, l'agente controlla se
queste risorse servono per il blocco corrente o per i prossimi 2-3,
e **propone a Villa di installarle/scaricarle se mancano**. Villa non
deve ricordarsene. Dettagli sui trigger semantici e modalita d'uso
(Categoria A/B per SuperPowers): `.claude/metodo-villa/13-plugin-esterni.md`

## 14. Riferimenti
Manuale completo: `.claude/metodo-villa/README.md`
Idee cross-progetto: `C:\Users\Mario\Documents\ideas.md`
Sorgente ufficiale del Metodo: `https://github.com/Milkom121/Metodo-Villa-UFFICIALE` (path locale: `C:\Users\Mario\Documents\GitHub\Metodo-Villa-v2`) — repository rinominato il 2026-08-07 da `Metodo-Villa-v2` per non confonderlo con il tentativo di v3, eliminato; la cartella locale conserva il vecchio nome (e' il percorso scritto in `metodo/metodo-sync.sh`).

## 15. Aggiornamento del Metodo a due sensi (sync madre ↔ progetti)
Il Metodo si tiene allineato tra madre e progetti. Motore meccanico: `metodo/metodo-sync.sh`. Sopra, due skill con la testa:
- **scarico** (madre → progetto): skill `aggiorna-dal-metodo`. Porta gli aggiornamenti SENZA toccare i file del progetto e spiega le novita'. Proponi lo scarico a inizio sessione se la madre ha novita'.
- **rimando** (progetto → madre): skill `rimanda-al-metodo`. Se hai migliorato il Metodo (file in `.claude/metodo-villa/`, `.claude/skills/`, runner, `metodo/`), vaglia (neutralita' + pertinenza/non-ridondanza) e proponi a Villa, che approva. Tocca tutti i progetti: sempre sorvegliato.
Le divergenze volute si dichiarano in `.metodo-sync-ignore`. Mai sincronizzare il codice del progetto. Incongruenze non risolvibili → a Villa una alla volta (regola 1bis); col runner (Villa assente) procede e annota se non bloccante, si ferma solo se bloccante. Dettagli: `.claude/metodo-villa/19-sync-metodo.md` e `docs/fondamenta/sistema-aggiornamento-metodo.md`.
