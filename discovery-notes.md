# Discovery — evoluzione voce e hardware

Versione 0.2, 2026-10-16. Uso principale chiarito; motore e architettura da validare.

## Obiettivo e mandato

Un'unica app Windows locale per dettare e ascoltare testi in italiano, con scelta
automatica NVIDIA, AMD o CPU. Conservare la dettatura esistente. Macchine obiettivo:
RTX 4080 Laptop e Minisforum MS-S1 MAX; la ricerca del 16 ottobre considera
anche la RTX 5080 come profilo NVIDIA, senza presumere che sia disponibile qui.

Mario autorizza raccolta informazioni, piano, implementazione, test ed eseguibile
installabile. Decide solo questioni strategiche tramite Discovery; l'agente
sceglie soluzioni tecniche e dettagli operativi. Una domanda alla volta. Nessuna
autorizzazione implicita a cambiare driver, usare cloud, pubblicare release o
unire su main.

## Acquisizioni

- Tauri 2 / Rust / HTML-JS, FastAPI, sidecar PyInstaller. faster-whisper con
  CUDA o CPU; nessuna sintesi vocale o selezione AMD implementata.
- Il cambio modello puo' azzerare il contesto CUDA: progettare convivenza,
  memoria e cancellazione senza compromettere dettatura o interfaccia.
- La build installer esiste, ma va verificata con il NUOVO sidecar: l'esistenza
  di un vecchio MSI non dimostra il successo della nuova build.
- Ambiente rilevato: Acer Predator PH16-71, Windows 11 Home build 26200,
  RAM 32 GiB, RTX 4080 Laptop con 12282 MiB VRAM, driver NVIDIA 595.97.
- Spazio libero: circa 65 GiB su C e 297 GiB su D. Controllare prima delle
  prove pesanti; non scaricare tutti i candidati insieme.
- Venv: faster-whisper 1.2.1, CTranslate2 4.8.1, ONNX Runtime 1.29.0,
  PyInstaller 6.22.2. Torch, Transformers e qwen-tts non installati.
- Nessun accesso al Minisforum dimostrato qui; memoria, driver e prestazioni
  non misurati. Rilevare i fatti sulla macchina quando sara' accessibile.

## Ricerca riutilizzata e fonti ricontrollate

Base completa: `docs/fondamenta/obiettivi-e-fattibilita.md`.

- [Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS): italiano supportato,
  modelli 0.6B/1.7B, varianti per voce predisposta, disegnata e clonata.
  Candidato di qualita', non vincitore provato sulla macchina di Mario.
- [CTranslate2 4.8.3](https://github.com/OpenNMT/CTranslate2/releases/tag/v4.8.3):
  correzioni Windows/ROCm, non un collaudo Whisper sul Minisforum.
- [Matrice AMD Windows Ryzen](https://rocm.docs.amd.com/projects/radeon-ryzen/en/latest/docs/compatibility/compatibilityryz/windows/windows_compatibility.html):
  include Ryzen AI Max+ 395 con runtime/Python specifici; avverte che l'intero
  stack ROCm non e' supportato su Windows. Segnala anche il passaggio a documentazione
  unificata: fissare la combinazione adottata, non aggiornare alla cieca.
- [whisper.cpp](https://github.com/ggml-org/whisper.cpp#vulkan-gpu-support):
  alternativa STT Vulkan, da confrontare se necessaria.

## Risposta strategica di Mario — 2026-10-16

- Uso prevalente personale: ascoltare il testo selezionato con la qualita' e
  le voci migliori possibili. Funzioni accessorie utili all'esperienza gradite.
- Il caso prioritario e' quindi selezione → lettura, con naturalezza prima
  della massima velocita'. Nessun tempo d'attesa numerico ancora concordato.
- La risposta chiarisce entrambe le domande previste: non riproporre la seconda.
- Produzione di contenuti, esportazione, cronologia e clonazione come funzione
  utente non sono requisiti acquisiti. Una voce preparata tramite riferimento
  e' una possibile scelta tecnica, non richiede per forza la voce di Mario.

## Analisi aggiornata del 16 ottobre

Rapporto completo con fonti: `docs/fondamenta/obiettivi-e-fattibilita.md`.
Conservare Tauri/faster-whisper e ristrutturare motori, errori e distribuzione
e' la raccomandazione, non una riscrittura gia' autorizzata nei dettagli.

- Confronto qualita': Qwen3-TTS, Chatterbox Multilingual V3, VoxCPM2,
  CosyVoice3; MOSS v1.5 con runtime/pesi adatti alla memoria se riproducibili.
- Confronto leggero: Pocket TTS ora italiano, MOSS Nano ONNX e Kokoro.
- Verificate distinzioni fra codice/pesi: OmniVoice non commerciale nei pesi,
  Pocket CC-BY-4.0 nei pesi; Fish S2/Drama non sono la baseline 12/16 GB.
- Qwen anche via llama.cpp e runtime comunitario faster-qwen3-tts; non
  presumere parita' di voce, streaming o prestazioni fra implementazioni.
- Sintassi Python (6 file) e cargo check offline positivi; warning Rust noto.
- Riprodotto in memoria: avvio audio fallito ma /start risponde started.
  Prova simulata, nessun microfono reale avviato, difetto non corretto qui.
- RTX4080Laptop confermata: 12282 MiB totali; circa 5923 MiB liberi al rilievo.
- Video YouTube trovati tramite titoli/descrizioni; non visionati/ascoltati.
- Nessun nuovo motore, benchmark vocale, build o modifica applicativa.

## Gap tecnici — risolve l'agente

- Motori, versioni, licenze, runtime e confronto della qualita' italiana.
- Comandi e origine del testo coerenti con il percorso scelto: selezione,
  appunti e campo dell'app, senza scaricare microdecisioni su Mario.
- Testi lunghi, controlli di lettura, concorrenza con dettatura e memoria.
- Download verificati, uso offline dopo preparazione e recupero dagli errori.
- Protezione API/WebView, dipendenze riproducibili, migrazione impostazioni.
- Build con errori propagati, artefatti tracciabili e test di installazione.

## Non ancora specificato: responsabile e momento

- Uso e priorita' qualitativa: chiariti da Mario il 16 ottobre.
- Soglie pratiche di attesa/stabilita': agente prima della prova, poi valutare
  con Mario se il compromesso cambia sensibilmente l'esperienza.
- Motore: agente, dopo confronto misurato coerente con le risposte.
- Giudizio soggettivo: Mario su pochi campioni, se discriminante.
- Certificazione AMD: test sul Minisforum reale prima di dichiararlo collaudato.
- Firma digitale: rilevare il certificato disponibile prima del rilascio;
  nessun acquisto o servizio esterno implicito.

## Confronto sperimentale del 16 ottobre — completato

- Mandato diretto di Mario: confrontare Qwen e Chatterbox sul portatile,
  preparare campioni italiani preservando la dettatura.
- 16 WAV generati in CUDA: quattro testi originali, due riferimenti italiani
  Google FLEURS CC-BY-4.0, due motori con stessi testi/riferimenti.
- Qwen 1.7B Base BF16/SDPA, Torch 2.8.0 CUDA 12.8; Chatterbox Multilingual V3,
  Torch 2.6.0 CUDA 12.4. Venv distinti; pacchetti fissati, checkpoint verificati.
- Fattore tempo reale complessivo: Qwen 4,91, Chatterbox 1,41. Altre app attive,
  nessuna ottimizzazione di serving e nessun tempo di riproduzione streaming.
- Copie A/B a circa -24 LUFS e ZIP 10,4 MiB pronti; ASR su 16 campioni segnala
  possibili problemi di cifre/date in entrambi. Nessun voto di naturalezza automatico.
- Freeze del venv della dettatura e hash requirements/Cargo invariati;
  nessuna modifica applicativa, driver o installer. Audio e ambienti solo locali.
- Rapporto: `docs/fondamenta/confronto-voci-2026-10-16.md`.
- Prossimo giudizio richiesto: preferenza di Mario dopo ascolto; seconda
  domanda strategica precedente non va riproposta.
