# Whisper4Windows — Configurazione progetto

## Identita' e stato

- App desktop Windows per dettatura locale e inserimento del testo nell'app attiva.
- Repository: https://github.com/Milkom121/Whisper4Windows
- Upstream: https://github.com/BaderJabri/Whisper4Windows
- Stato: applicazione esistente; nuova evoluzione in definizione.
- Ultima sessione e aggiornamento: 2026-10-16 (analisi e ricerca, app invariata).
- Metodo: copia del repository ufficiale; provenienza ed eccezioni in
  `docs/fondamenta/metodo-villa-origine.md`.

## Stack esistente

| Parte | Tecnologia e percorso |
|---|---|
| Desktop e integrazione Windows | Tauri 2 / Rust, `frontend/src-tauri/` |
| Interfaccia | HTML/JavaScript in `frontend/dist/` |
| Servizio locale | Python / FastAPI / Uvicorn, `backend/main.py` |
| Trascrizione | faster-whisper / CTranslate2; CUDA NVIDIA o CPU |
| Audio | sounddevice / NumPy, `backend/audio_capture.py` |
| Distribuzione | backend PyInstaller come sidecar; bundle Tauri NSIS/MSI |
| Stato utente | impostazioni persistenti Rust; modelli e librerie in AppData |

Sintesi vocale e accelerazione AMD non sono ancora implementate. Il supporto CPU
esiste gia'. Non introdurre database o cambiare frontend per adattarsi agli esempi
del Metodo. Il venv locale verificato usa Python 3.12 e CTranslate2 4.8.1;
il file requirements contiene versioni minime, non un ambiente riproducibile.

## Comandi essenziali (PowerShell, dalla radice)

Sintassi Python, con il venv esistente:

```powershell
backend/venv/Scripts/python.exe -c "import pathlib, py_compile; files = sorted(pathlib.Path('backend').glob('*.py')); [py_compile.compile(str(p), doraise=True) for p in files]; print('Python OK:', len(files), 'file')"
```

Controllo Rust:

```powershell
cargo check --manifest-path frontend/src-tauri/Cargo.toml --offline
```

`--offline` richiede dipendenze in cache. Il controllo Tauri richiede il sidecar
previsto nella configurazione e gli strumenti Rust/MSVC gia' installati. Dichiarare
i prerequisiti mancanti senza installazioni globali automatiche.

Backend separato, solo nel debug senza frontend/sidecar gia' attivo:

```powershell
backend/venv/Scripts/python.exe -m uvicorn main:app --app-dir backend --host 127.0.0.1 --port 8000
```

Build esistenti: `BUILD_BACKEND.bat`, `BUILD_INSTALLER.bat`; contengono installazioni
di dipendenze e richiedono un mandato di build. Non esiste una suite automatica
completa dei percorsi applicativi. `backend/test_gpu_capabilities.py` e' diagnostica,
non un collaudo completo del prodotto.

## Deployment e operativita'

- Dove gira: Windows x64, app desktop e backend su `127.0.0.1:8000`.
- Avvio/riavvio: il frontend lancia il sidecar e lo riavvia dopo una terminazione
  inattesa; esiste riavvio manuale. Un processo vivo ma bloccato non equivale a
  un processo terminato e richiede un controllo diverso.
- Aggiornamento: costruire e collaudare un nuovo installer; la procedura della
  nuova versione sara' definita dopo le prove sui motori.
- Guasti: backend e librerie GPU possono compromettere la trascrizione; esiste
  ripiego CPU da collaudare nei percorsi reali. La porta 8000 deve essere libera
  e i modelli scaricati prima dell'uso senza rete.

Alcune guide precedenti descrivono CUDA inclusa nel bundle, mentre
`backend/build_backend.py` prevede librerie scaricate a richiesta. Per le prove
usare codice e configurazione effettivi; il riordino delle guide e' lavoro futuro.

## Metodo e confini

- Apertura: istruzioni agenti, regole operative, questo file, roadmap e consegne.
- Aggiornamento: `runner.bat`, voce **9**, oppure da Git Bash
  `bash metodo/metodo-sync.sh scarica` con la madre ufficiale aggiornata.
- Repository pubblico: non pubblicare `.claude/precedenti/`, credenziali,
  impostazioni locali del runner o log completi.
- Il runner e' importato; il suo avvio segue un mandato distinto. Il prossimo
  confronto riguarda ora campioni italiani: Mario ha chiarito l'uso personale
  della lettura della selezione e la priorita' alla qualita'.
- `--help`, controlli sintattici e lettura dello stato verificano l'integrazione,
  non equivalgono a una corsa reale dell'agente automatico.

## Verifiche dell'adozione (2026-10-14)

- Sintassi Python: sei file del backend, esito positivo.
- `cargo check --offline`: positivo; warning preesistente per `delete_result`
  non usato in `frontend/src-tauri/src/lib.rs:1017`, lasciato fuori scope.
- Integrita' del Metodo: 125 file ufficiali identici, eccezioni dichiarate,
  storico e modifica locale Cargo preservati; codice applicativo invariato.
- Sintassi shell e aiuto runner: positivi. Lo strumento di stato legge F1B1
  come confronto collaborativo e prevede zero blocchi autonomi prima di Mario.
- Applicazione e nuovo installer non collaudati in questa adozione.

## Verifiche dell'analisi (2026-10-16)

- Sintassi Python (6 file) e `cargo check --offline` positivi, stesso warning Rust.
- Analisi e fonti aggiornate in `docs/fondamenta/obiettivi-e-fattibilita.md`;
  avvio audio falsamente riuscito riprodotto con acquisizione simulata.
- Codice applicativo invariato. Nessun motore TTS, ascolto comparativo o installer provato.

## Confronto vocale isolato (2026-10-16, successivo all'analisi)

- Qwen3-TTS 1.7B Base e Chatterbox Multilingual V3 eseguiti in CUDA sulla RTX
  4080 Laptop: 16 WAV e pacchetto locale d'ascolto, nessuna integrazione nell'app.
- Ambienti in `experiments/tts-comparison/.venv-qwen` e `.venv-chatterbox`;
  corpus, script, revisioni e lock file separati dal backend della dettatura.
- Rapporto: `docs/fondamenta/confronto-voci-2026-10-16.md`; audio, pesi,
  log e venv locali sono esclusi da Git. Ripetizione descritta nel README dell'esperimento.
- Verificati formato/hash/volume dei 16 file e preservazione di freeze e
  configurazioni della dettatura. Giudizio di ascolto ancora da Mario;
  controllo ASR segnala cifre/date da rivedere in entrambi i motori.
- Nessuna nuova prova di dettatura reale, UI, installer, 5080 o AMD.
