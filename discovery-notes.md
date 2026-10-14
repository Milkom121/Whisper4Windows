# Discovery — evoluzione voce e hardware

Versione 0.1, 2026-10-14. Raccolta iniziale, non specifica approvata.

## Obiettivo e mandato

Un'unica app Windows locale per dettare e ascoltare testi in italiano, con scelta
automatica NVIDIA, AMD o CPU. Conservare la dettatura esistente. Macchine obiettivo:
RTX 4080 Laptop e Minisforum MS-S1 MAX.

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

## Gap strategici — risponde Mario

1. Prima versione: lettore quotidiano oppure anche produzione di contenuti con
   identita' vocali personalizzate/clonate? Raccomandazione: lettore quotidiano
   come obiettivo iniziale, senza introdurre uno studio vocale per supposizione.
2. Priorita' fra avvio pronto e massima naturalezza. Formulare dopo la risposta 1;
   eliminare la domanda se la risposta precedente chiarisce gia' il compromesso.

Nessuna risposta nuova ricevuta. Raccomandazioni non equivalgono a decisioni.

## Gap tecnici — risolve l'agente

- Motori, versioni, licenze, runtime e confronto della qualita' italiana.
- Comandi e origine del testo coerenti con il percorso scelto: selezione,
  appunti e campo dell'app, senza scaricare microdecisioni su Mario.
- Testi lunghi, controlli di lettura, concorrenza con dettatura e memoria.
- Download verificati, uso offline dopo preparazione e recupero dagli errori.
- Protezione API/WebView, dipendenze riproducibili, migrazione impostazioni.
- Build con errori propagati, artefatti tracciabili e test di installazione.

## Non ancora specificato: responsabile e momento

- Uso e compromesso voce: Mario, intervista corrente.
- Motore: agente, dopo confronto misurato coerente con le risposte.
- Giudizio soggettivo: Mario su pochi campioni, se discriminante.
- Certificazione AMD: test sul Minisforum reale prima di dichiararlo collaudato.
- Firma digitale: rilevare il certificato disponibile prima del rilascio;
  nessun acquisto o servizio esterno implicito.
