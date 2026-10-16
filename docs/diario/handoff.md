STATUS: CONTINUE
PHASE: 1
BLOCK: 2
SUMMARY: Analisi codice e ricerca TTS aggiornate al 16 ottobre; risposta strategica registrata, F1B1 concluso.
PER_VILLA: La priorita' e' leggere il testo selezionato con la voce italiana migliore possibile. Consiglio di conservare l'app e rinforzare i motori; prima della scelta servono campioni comparabili.
NEXT: F1B2, primo confronto isolato Qwen3-TTS / Chatterbox V3 su RTX 4080 Laptop, poi ascolto di Mario.
DECISIONS_NEEDED: Nessuna nuova domanda strategica adesso; scelta della voce dopo i campioni.
FILES_MODIFIED: rapporto obiettivi-e-fattibilita, piano operativo, discovery-notes/state, ROADMAP, PROJECT_CONFIG, decisions, handoff.
TESTS: PASS — Python 6 file, cargo check offline, 8 documenti e integrita' app; /start falsamente avviato riprodotto con acquisizione simulata. Handoff 46/50 righe, diff valido.
GUARDIANO_STANDARD: PASS — solo documentazione, fonti collegate, limiti dichiarati; nessun runtime o voce installati.
GUARDIANO_CONSEGNA: PASS per analisi e scelta d'uso; sintesi vocale, ascolto comparativo e installer restano lavori successivi dichiarati.
OLTRE_IL_CHIESTO: Nessuna nuova funzione; conservato il contesto AMD precedente.
OCCHIO_ESTERNO: PASS — revisione indipendente del solo diff, nessun difetto concreto segnalato.

---

Mandato precedente fino all'installer conservato; questa sessione analizza il
progetto e aggiorna la ricerca richiesta. Nessun runner o benchmark avviato.
Mario: soprattutto lettura personale della selezione, qualita'/voci migliori,
accessori UX utili graditi. Risposta chiarisce entrambe le domande: niente seconda.
Caso d'uso e fonti: docs/fondamenta/obiettivi-e-fattibilita.md (16 ottobre).
Piano 0.2: docs/fondamenta/piano-operativo-voce-hardware.md.
Non rifare la ricerca acquisita: confrontare campioni, non altri cataloghi.
Qwen/Chatterbox prima; VoxCPM2/CosyVoice3 e MOSS v1.5 con percorso riproducibile;
baseline Pocket TTS/MOSS Nano/Kokoro. Nessun vincitore presunto.
Qualita' prima della massima velocita'; tempi numerici non concordati.
Proposta: Tauri conservato, TTS in processo separato, memoria coordinata.
Difetto riprodotto con AST/microfono simulato: /start ignora il False restituito
da AudioCapture.start_recording e dichiara started. Da correggere, non fixato.
Altri rischi statici: reset CUDA, timeout thread, concorrenza cambio modello,
API locale/CSP, download variabili, vecchi artefatti scambiati per build nuova.
GPU: RTX 4080 Laptop, 12282 MiB; driver 595.97, circa 5923 MiB liberi al rilievo.
Rust passa con warning noto delete_result:1017. Sintassi Python 6/6.
Test vocali, app intera, installer, 5080 e Minisforum non collaudati.
YouTube: titoli/descrizioni trovati, apertura fallita; video/audio non esaminati.
Branch: codex/discovery-voce-hardware; Cargo.toml preesistente da preservare.
Cartelle locali .agents/ e .codex/ non aggiunte alla consegna pubblica.
Nessun acquisto, cloud, cambio driver, release o merge main impliciti.

## Prompt per riprendere

Whisper4Windows — F1B2 — Confronto italiano Qwen3-TTS / Chatterbox V3.
LEGGI: istruzioni progetto, ROADMAP, questo handoff e rapporto del 16 ottobre.
COSA FARE: corpus, ambienti isolati, versioni tracciate, campioni e misure GPU.
GATE: confronto rieseguibile, risultati reali e campioni pronti all'ascolto.
NON fare: sostituire dettatura/UI, cambiare driver o dichiarare voci gia' provate.
