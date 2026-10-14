@.claude/metodo-villa/00-CLAUDE-OPERATIVO.md

--- REGOLE SPECIFICHE PROGETTO ---

# Whisper4Windows

App desktop Windows per trascrizione locale. Obiettivo della prossima evoluzione:
aggiungere lettura vocale italiana e adattamento automatico a NVIDIA, AMD e CPU.
Queste nuove funzioni sono in definizione, non implementate.

- Frontend esistente: Tauri 2, Rust e HTML/JavaScript in `frontend/dist/`.
- Backend: Python, FastAPI e Uvicorn su `127.0.0.1:8000`, distribuito come
  sidecar PyInstaller `whisper-backend.exe`.
- Trascrizione attuale: faster-whisper / CTranslate2, CUDA NVIDIA o CPU.
- File chiave: `frontend/src-tauri/src/lib.rs`, `backend/main.py`,
  `backend/whisper_engine.py`, `backend/gpu_manager.py`, `backend/audio_capture.py`.

## Vincoli

- Conservare dettatura, scorciatoie, appunti, impostazioni e recupero del backend.
- Elaborazione vocale locale; servizi cloud richiedono una scelta esplicita.
- Linguaggi, nomi di funzioni e commenti del codice restano in inglese, come nel
  progetto originario; comunicazione e documentazione di lavoro in italiano.
- Non sostituire lo stack con React, Flutter o altri framework solo per
  applicare gli esempi visivi del Metodo.
- Dipendenze e prove isolate nel progetto. Non modificare driver, PATH o runtime
  di sistema durante adozione o prove senza mandato pertinente.
- Per eseguire l'app avviare il frontend con il suo sidecar. Non avviare anche un
  secondo backend sulla porta 8000; il backend separato serve al debug dedicato.
- L'importazione del Metodo non avvia runner, notifiche, confronti di modelli
  o nuove funzioni. Il loro avvio segue il relativo mandato.

## Lavoro e verifiche

Seguire il blocco della roadmap su un ramo dedicato (`codex/` come prefisso
predefinito, salvo indicazione del blocco). Niente merge o push su `main` senza
autorizzazione. Preservare le modifiche locali estranee al blocco.

Comandi e precondizioni sono in `PROJECT_CONFIG.md`. Per modifiche Python
controllare la sintassi; per modifiche Rust usare `cargo check`; aggiungere la
verifica funzionale pertinente. Nell'adozione del Metodo verificare anche che
il codice applicativo sia invariato. Non presentare come superate prove non eseguite.

La roadmap precedente, gia' segnata completata, e' conservata in
`docs/storico/ROADMAP-backend-robusto.md`: non certifica nuovi collaudi odierni.
