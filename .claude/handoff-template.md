# Template Handoff — Metodo Villa Runner

**Dove vive l'handoff**: in `docs/diario/handoff.md`.

Due spostamenti alle spalle, entrambi con una ragione precisa:
- **2026-04-09**: da `.claude/handoff.md` a `docs/handoff.md`, perche Claude Code ha
  una protezione hardcoded sui file di `.claude/` che blocca la scrittura anche con
  `--dangerously-skip-permissions`.
- **2026-08-07**: da `docs/handoff.md` a `docs/diario/handoff.md`, col riordino che ha
  diviso i documenti in `fondamenta/` (scritti una volta) e `diario/` (crescono lavorando).

Questo template invece resta in `.claude/handoff-template.md` come riferimento di sola lettura.

Formato obbligatorio per docs/diario/handoff.md:

STATUS: CONTINUE | CHECKPOINT | PHASE_COMPLETE | ERROR | BLOCKED
PHASE: [numero fase]
BLOCK: [numero blocco]
SUMMARY: [cosa hai fatto, in tecnico: lo legge l'agente della corsa dopo]
PER_VILLA: [la stessa cosa detta a VILLA — vedi le regole qui sotto]
NEXT: [prossimo blocco]
DECISIONS_NEEDED: [solo se CHECKPOINT/BLOCKED]
FILES_MODIFIED: [lista file]
TESTS: PASS | FAIL | SKIPPED

## PER_VILLA — la riga che gli arriva sul telefono

**Obbligatoria.** E' l'unica parte dell'handoff che legge un essere umano: il
runner la manda su Telegram. `SUMMARY` resta tecnico, perche' serve all'agente
della corsa successiva, che ha bisogno di nomi di file e codici di blocco.
Villa no.

Non e' `SUMMARY` riscritto piu' corto: sono due cose diverse.

Regole:
- **1-3 righe**, in italiano di tutti i giorni, come lo diresti a voce a
  qualcuno che non ha letto niente.
- Dici il **risultato**, non il lavoro svolto. Non *«implementata la classe
  OrderHistory con soft-delete e 14 test verdi»*, ma *«adesso lo storico degli
  ordini resta salvato e non si perde se qualcuno cancella un cliente»*.
- **Vietati**: nomi di file, percorsi, codici di blocco (F3B12), nomi di
  funzioni o classi, sigle, numeri di test, termini inglesi tecnici. Se una
  parola non la userebbe un direttore di RSA, non entra.
- Se ti sei **fermato**, la cosa piu' importante e' **perche'** e **cosa serve
  da lui**, detto in modo che possa rispondere con una frase.
- Niente elenchi puntati, niente grassetti: e' un paragrafino parlato.

**Prova prima di scrivere**: se Villa leggesse SOLO questa riga, saprebbe cos'e'
successo e se deve fare qualcosa? Se no, riscrivila piu' semplice.

Se manca (handoff vecchi), il runner ripiega sul riassunto tecnico: meglio
qualcosa di tecnico che il silenzio.

Status:
- CONTINUE = blocco ok, continua
- CHECKPOINT = serve decisione umana
- PHASE_COMPLETE = fase finita, review + PR
- ERROR = qualcosa rotto
- BLOCKED = manca info
