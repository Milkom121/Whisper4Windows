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

- [x] **F1B1** — Definire con Mario la strategia della lettura vocale. Completato il 2026-10-16.
  - **Mandato aggiornato**: ricerca, piano, implementazione, test e installer;
    domande Discovery solo strategiche, dettagli tecnici delegati all'agente.
  - **Branch**: `codex/discovery-voce-hardware`.
  - **Ingresso**: `docs/fondamenta/obiettivi-e-fattibilita.md`; ricerca gia'
    svolta e aggiornata su richiesta esplicita del 16 ottobre.
  - **Risultato**: uso principale e priorita' qualitative condivisi; comandi,
    origine del testo, testi lunghi e convivenza con dettatura progettati
    dall'agente in coerenza con queste scelte.
  - **Verifica unica**: revisione con Mario di un caso concreto completo,
    con esiti osservabili e decisioni registrate.
  - **Esito**: Mario sceglie lettura personale del testo selezionato con la
    qualita' vocale migliore possibile; comodita' d'uso gradite. La risposta
    chiarisce anche la priorita' qualitativa: seconda domanda eliminata.
    Caso d'uso, confronto fonti aggiornato e proposta di ristrutturazione mirata
    nel rapporto. Motore, tempi accettabili e architettura non certificati.
  - **Verifiche aggiuntive**: Python (6 file) e Rust positivi; difetto di
    avvio microfono riprodotto con acquisizione simulata, ancora da correggere.
    Codice applicativo invariato; nessun test acustico o nuovo installer.
  - **Sequencing**: ricerca e scelta d'uso concluse; procedere alle prove,
    senza trasformare candidati o stime in motori gia' adottati.

### Blocco 1.2 — Primo confronto di voci italiane 🤖 🟡

- [x] **F1B2** — Preparare ed eseguire un confronto riproducibile Qwen3-TTS / Chatterbox Multilingual V3. Completato il 2026-10-16.
  - **Ingresso**: uso selezione/lettura e priorita' alla qualita' confermati;
    rapporto del 16 ottobre e piano operativo aggiornato.
  - **Risultato**: corpus italiano, riferimento utilizzabile, versioni e
    parametri tracciati, campioni confrontabili e misure su RTX 4080 Laptop.
    Distinguere caricamento, primo audio, velocita', memoria ed errori.
  - **Verifica unica**: suite di confronto sugli stessi testi e riferimento,
    rieseguibile con esiti registrati; dichiarare falliti/non coperti.
  - **Vincoli**: ambienti isolati; preservare venv dettatura, Cargo locale e
    driver; nessuna integrazione UI o modifica del motore STT in questo blocco.
  - **Uscita**: dati e campioni pronti all'ascolto; il giudizio soggettivo
    resta a Mario. Runner non avviato da questa analisi.
  - **Esito**: 16 WAV CUDA generati, due voci e quattro testi per motore;
    copie A/B a -24 LUFS e ZIP locale verificati. Misure e istruzioni in
    `docs/fondamenta/confronto-voci-2026-10-16.md` e `experiments/tts-comparison/`.
    Fattore tempo reale 4,91 Qwen / 1,41 Chatterbox, in configurazioni Python
    non ottimizzate e con altre applicazioni attive. Nessun voto acustico presunto.
  - **Verifica**: audio, hash, formato, livello, testi e CUDA positivi; freeze
    backend e hash configurazioni preservati; pacchetti dei due venv coerenti.
    Controllo ASR su tutti i campioni segnala cifre/date da verificare in entrambi.
    App, driver e codice della dettatura invariati; nessun installer costruito.

### Blocco 1.3 — Ascoltare e scegliere la direzione della voce 🤝 🟡

- [ ] **F1B3** — Raccogliere il giudizio di Mario sui campioni A/B.
  - **Ingresso**: raccolta locale completata, rapporto e limiti dichiarati.
  - **Risultato**: preferenza motivata su naturalezza, accento, ritmo e comodita'
    d'ascolto; oppure nessun candidato soddisfacente, senza scelta forzata.
  - **Verifica unica**: ascolto di testi uguali con riferimento uguale e risposta
    di Mario registrata; distinguere preferenza di voce e problemi di pronuncia.
  - **Primo passo**: racconto A/B, voce femminile e maschile; poi numeri/date.
  - **Sequencing**: giudizio umano prima di adottare il motore. Runtime piu'
    rapido e normalizzazione italiana da provare prima della lettura nell'app.

## Percorso successivo da dettagliare

1. Dopo il primo confronto, estendere le prove a VoxCPM2/CosyVoice3, a MOSS
   v1.5 se il percorso adatto alla memoria e' riproducibile e a una baseline
   leggera fra Pocket TTS/MOSS Nano/Kokoro. Decidere in base alla qualita'
   italiana; nessun candidato e' gia' collaudato localmente.
2. Prove di trascrizione e sintesi sul Minisforum MS-S1 MAX, verificando Windows
   e driver reali. Definire il profilo AMD in base ai risultati.
3. Progettare motori, memoria e percorsi dell'interfaccia; scomporre poi
   l'implementazione in blocchi autonomi con verifiche concrete.
4. Integrare lettura e scelta automatica dell'hardware, poi collaudare
   installazione, uso senza rete e recupero dagli errori sulle due macchine.

Il mandato di implementazione e consegna e' dato. Queste direzioni richiedono
la scomposizione in blocchi verificabili dopo le prove sui motori;
oltre il confronto e l'ascolto non sono una sequenza gia' pronta per il runner.
Lo storico precedente e' in `docs/storico/ROADMAP-backend-robusto.md`.
