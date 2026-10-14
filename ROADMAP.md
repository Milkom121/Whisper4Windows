# Whisper4Windows — Roadmap

Obiettivo: un'app locale che trascrive e legge in italiano, adattandosi alle
risorse NVIDIA, AMD o CPU. Metodo di sviluppo: Metodo Villa ufficiale.

`[x]` completato, `[>]` in corso, `[ ]` da fare.
Natura: 🤖 autonomo, 👤 umano, 🤝 collaborativo. Peso: 🟢 ordinario,
🟡 importante, 🔴 cruciale. Un blocco ha una modifica coerente e una verifica.

## Fase 0 — Adozione del Metodo Villa

### Blocco 0.1 — Importazione e collegamento al progetto 🤖 🟡

- [x] **F0B1** — Importare il Metodo ufficiale e preservare il progetto esistente. Completato il 2026-10-14.
  - **Mandato**: richiesta esplicita di Mario del 2026-10-14.
  - **Branch**: `codex/adozione-metodo-villa`.
  - **Risultato**: manuale, skill, runner e aggiornamento presenti; istruzioni
    per Claude e Codex collegate; configurazione e consegne specifiche compilate;
    vecchi documenti preservati nello storico.
  - **Verifica unica**: controllo d'integrazione dell'adozione — file importati
    identici alla fonte salvo eccezioni dichiarate, esclusione dell'indirizzario
    privato, lettura di roadmap e stato dagli strumenti, collegamenti operativi
    validi e codice applicativo invariato. I controlli Python/Rust sono riscontri
    aggiuntivi sullo stato iniziale del progetto.
  - **Fuori scope**: nuovi motori vocali, interfaccia, dipendenze, driver,
    avvio del runner e fusione su main.
  - **Esito**: 125 file ufficiali identici, storico e codice preservati;
    lettura della prossima fase corretta, nessun blocco autonomo oltre il
    confronto con Mario. Sintassi Python, shell e controllo Rust positivi.

## Fase 1 — Definizione della nuova versione

### Blocco 1.1 — Decidere l'uso della lettura vocale 🤝 🟡

- [ ] **F1B1** — Definire con Mario il primo percorso di lettura del testo.
  - **Ingresso**: `docs/fondamenta/obiettivi-e-fattibilita.md`; ricerca gia'
    svolta, da non ripetere senza nuove esigenze.
  - **Risultato**: requisiti condivisi su origine del testo, voce italiana,
    controlli di ascolto, testi lunghi e comportamento durante la dettatura.
  - **Verifica unica**: revisione con Mario di un caso concreto completo,
    con esiti osservabili e decisioni registrate.
  - **Primo passo**: una domanda sull'uso principale della lettura; non chiedere
    a Mario scelte di librerie, runtime o dettagli tecnici delegati all'agente.
  - **Sequencing**: confronto prima dei blocchi autonomi. Il runner non deve
    oltrepassarlo o interpretare ipotesi tecniche come scelte approvate.

## Percorso successivo da dettagliare

1. Prove isolate delle voci italiane sulla RTX 4080 Laptop, misurando ascolto,
   attesa iniziale, velocita' e memoria. Qwen3-TTS e' un candidato, non una
   scelta definitiva gia' collaudata.
2. Prove di trascrizione e sintesi sul Minisforum MS-S1 MAX, verificando Windows
   e driver reali. Definire il profilo AMD in base ai risultati.
3. Progettare motori, memoria e percorsi dell'interfaccia; scomporre poi
   l'implementazione in blocchi autonomi con verifiche concrete.
4. Integrare lettura e scelta automatica dell'hardware, poi collaudare
   installazione, uso senza rete e recupero dagli errori sulle due macchine.

Queste sono direzioni di pianificazione, non blocchi eseguibili approvati.
Lo storico precedente e' in `docs/storico/ROADMAP-backend-robusto.md`.
