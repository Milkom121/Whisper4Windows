# Obiettivi e fattibilita' — voce italiana e hardware automatico

## Mandato e stato

Mario vuole una sola app Windows che trascriva e legga in italiano, scegliendo
automaticamente NVIDIA, AMD o CPU. Macchine: RTX 4080 Laptop da 12 GB e Minisforum
MS-S1 MAX con Ryzen AI Max+ 395 / Radeon 8060S. Memoria, Windows e driver del
Minisforum sono da rilevare sulla macchina reale.

Il mandato corrente autorizza l'adozione del Metodo. La ricerca in conversazione
e' materiale di pianificazione; non e' la scelta definitiva di un motore ne'
l'autorizzazione ad avviare il runner.

## Stato verificato nel codice

- Registrazione locale, trascrizione all'arresto e inserimento tramite appunti.
- faster-whisper / CTranslate2; automatico cerca CUDA, poi CPU.
- Gestione librerie e controlli di memoria specifici NVIDIA.
- Nessun motore TTS e nessun profilo AMD implementato.
- `unload_model()` puo' azzerare il contesto CUDA: la convivenza con un secondo
  motore deve essere progettata e provata.
- Il watchdog rileva la terminazione. Il timeout su un lavoro in un thread non
  garantisce di interrompere un blocco del codice nativo.

## Candidati della ricerca del 2026-10-14 (da provare)

- Qwen3-TTS 1.7B: primo candidato per la voce italiana; distinguere Base,
  VoiceDesign e CustomVoice. Memoria e latenza locali non misurate.
  Fonte: https://github.com/QwenLM/Qwen3-TTS
- Chatterbox Multilingual V3: confronto per italiano e dimensioni;
  Turbo/Nano sono inglesi. Fonte: https://github.com/resemble-ai/chatterbox
- OmniVoice e VoxCPM2: alternative, senza integrarli tutti a priori.
  Fonti: https://github.com/k2-fsa/OmniVoice e https://github.com/OpenBMB/VoxCPM
- Kokoro: possibile voce leggera, da ascoltare in italiano.
  Fonte: https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md

La ricerca indica fattibilita', non un vincitore assoluto. Gli errori nelle parole
non misurano da soli naturalezza, accento o piacevolezza.

Per AMD, CTranslate2 4.8.3 del 2026-10-13 introduce correzioni Windows/ROCm:
https://github.com/OpenNMT/CTranslate2/releases/tag/v4.8.3
La correzione e' provata dagli autori su RX 9060 XT, non certifica Whisper sul
Minisforum: https://github.com/OpenNMT/CTranslate2/pull/2106
Alternativa: https://github.com/ggml-org/whisper.cpp#vulkan-gpu-support

Compatibilita' AMD/PyTorch da ricontrollare prima delle prove:
https://rocm.docs.amd.com/en/latest/compatibility/compatibility-matrix.html
https://rocm.docs.amd.com/projects/ai-ecosystem/en/latest/frameworks/pytorch/install.html
Il supporto del runtime non certifica l'intero percorso del modello vocale.

## Decisioni di prodotto ancora aperte

- Origine del testo: selezione, appunti o campo dell'app.
- Voce desiderata e necessita' effettiva di clonazione o controllo espressivo.
- Controlli di lettura e comportamento all'inizio di una dettatura.
- Priorita' tra qualita', prontezza e testi lunghi.

Una domanda alla volta. Motori e librerie sono dettagli delegati all'agente;
le preferenze d'uso richiedono Mario.

## Prove richieste prima di adottare un motore

Stessi testi italiani: date, cifre, abbreviazioni, nomi propri, punteggiatura e un
brano lungo. Rilevare avvio a freddo e a caldo, primo audio, velocita' sostenuta,
picco di memoria, errori di lettura e ascolto di Mario. Sul Minisforum provare
anche cambio modello, chiusura, riavvio e ripiego CPU. I tempi della ricerca
precedente non sono misurazioni sul Minisforum di Mario.
