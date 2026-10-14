# Scorciatoie e limiti gia' presenti

Rilievo iniziale del 2026-10-14: queste impostazioni non sono state cambiate
nell'adozione del Metodo. Valutarle nei blocchi pertinenti.

## API locale con CORS permissivo

- File: `backend/main.py`, configurazione `CORSMiddleware`.
- Tipo: cors-permissivo; priorita' alta prima della nuova distribuzione.
- Stato: da valutare insieme al perimetro di accesso del servizio locale.

## WebView con protezioni di sviluppo

- File: `frontend/src-tauri/tauri.conf.json`, `security.csp` e `devtools`.
- Tipo: configurazione di sviluppo; priorita' da definire prima del rilascio.
- Stato: CSP disattivata e strumenti di sviluppo abilitati, da verificare nel bundle.

## Dipendenze non bloccate in modo riproducibile

- File: `backend/requirements.txt`, `.gitignore` (`**/Cargo.lock`).
- Tipo: riproducibilita'; priorita' media prima di confronti e rilascio.
- Stato: versioni minime Python e lock Rust non versionato; le prove sui motori
  devono registrare versioni effettive e ambienti isolati.

## Avvio e documentazione non allineati

- File: `START_APP.bat`, `BUILD.md`, `backend/build_backend.py`.
- Tipo: operativita'; priorita' media.
- Stato: evitare il doppio backend; le guide sul bundle CUDA non sono tutte
  allineate al download su richiesta previsto nel codice.
