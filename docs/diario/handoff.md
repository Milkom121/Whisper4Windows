STATUS: CHECKPOINT
PHASE: 1
BLOCK: 1
SUMMARY: Metodo Villa ufficiale importato e collegato a Claude/Codex; F0B1 verificato. Prossimo blocco F1B1 collaborativo.
PER_VILLA: Il Metodo ufficiale e' dentro il progetto e i controlli sono passati. Adesso definiamo come vuoi usare la lettura vocale, poi passiamo alle prove sulle tue due macchine.
NEXT: Definire con Mario il primo percorso di lettura, una domanda alla volta.
DECISIONS_NEEDED: Origine del testo nel primo percorso di lettura: selezione, appunti o testo inserito nell'app.
FILES_MODIFIED: AGENTS.md, CLAUDE.md, ROADMAP.md, PROJECT_CONFIG.md, configurazione Git, risorse Metodo, docs.
TESTS: PASS
GUARDIANO_STANDARD: PASS — nessun codice applicativo modificato, nessun segreto rilevato, dati privati esclusi, copie ufficiali integre.
GUARDIANO_CONSEGNA: PASS — importazione, collegamento, storico, configurazione, consegne e piano iniziale presenti.
OLTRE_IL_CHIESTO: Nessuno; il rilievo dei limiti esistenti documenta la configurazione iniziale senza correggerla.
OCCHIO_ESTERNO: PASS — revisione indipendente senza difetti concreti verificati. Prova isolata dello stop collaborativo del revisore inconclusiva; nessuna corsa reale dichiarata.

---

Mandato: importare/aggiornare il Metodo, poi spiegare il percorso di sviluppo.
Il codice dell'app non va modificato. Modifica locale preesistente a
`frontend/src-tauri/Cargo.toml` da conservare fuori dai commit dell'adozione.
Ricerca gia' svolta: `docs/fondamenta/obiettivi-e-fattibilita.md`.
Runner non avviato; nessun nuovo modello vocale installato o provato.
Fonte ufficiale: `59fe604e57a4caa236fe71bfc1cd6a8739a2ce1e`.
Verifiche: 125 file identici, JSON e shell validi, lettura della roadmap e
confronto collaborativo corretti; sei file Python compilati; cargo check offline
positivo con warning preesistente `delete_result` non usato.
Nessun collaudo manuale dell'app o corsa reale del runner in questa adozione.

## Prompt per riprendere

Whisper4Windows — Sessione S1 — Blocco F1B1 — Definire la lettura vocale.
LEGGI: AGENTS.md, CLAUDE.md, .claude/metodo-villa/00-CLAUDE-OPERATIVO.md,
PROJECT_CONFIG.md, ROADMAP.md e questo handoff; poi obiettivi-e-fattibilita.md
in docs/fondamenta/. Non rileggere istruzioni gia' presenti nel contesto.
COSA FARE: concordare il primo percorso d'uso, una domanda alla volta,
partendo dall'origine del testo. Riutilizzare la ricerca gia' salvata.
GATE: caso concreto di lettura accettato da Mario e decisioni registrate.
NON fare: avviare runner, installare modelli, modificare app o driver,
considerare Qwen o il profilo AMD scelte gia' collaudate.
