# Provenienza del Metodo Villa

- Adozione autorizzata da Mario il 2026-10-14 per usare sempre il Metodo nello sviluppo.
- Fonte: https://github.com/Milkom121/Metodo-Villa-UFFICIALE
- Revisione `main` recuperata da GitHub: `59fe604e57a4caa236fe71bfc1cd6a8739a2ce1e`.
- Copia dei file tracciati di quella revisione, senza modifiche locali della madre.
- Importazione tramite `metodo/metodo-sync.sh scarica` e lista bianca ufficiale
  `metodo/metodo-manifest.txt`.

## Eccezioni dichiarate

In `.metodo-sync-ignore`:

- `.claude/precedenti`: esclusa perche' Whisper4Windows e' pubblico, come richiede
  il capitolo 28. Il pattern senza barra finale copre anche la voce radice del
  manifest e protegge gli scarichi futuri.
- `.gitattributes`: mantiene `* text=auto` del progetto e integra le convenzioni
  del Metodo per script e avviatori; personalizzazione dichiarata.

Impostazioni personali, documenti di lavoro, roadmap, registri e credenziali della
madre non fanno parte dell'importazione. I documenti specifici di Whisper4Windows
sono compilati separatamente.

## Conservazione dello stato precedente

- `docs/storico/AGENTS-pre-metodo.md`: istruzioni Codex originali.
- `docs/storico/CLAUDE-pre-metodo.md`: istruzioni Claude originali.
- `docs/storico/ROADMAP-backend-robusto.md`: roadmap con caselle gia' completate;
  lo storico non certifica collaudi nuovi di questa sessione.

Per aggiornare: aggiornare la copia madre dal repository ufficiale e usare la
sincronizzazione, controllando prima modifiche locali e personalizzazioni.
