STATUS: CHECKPOINT
PHASE: 1
BLOCK: 3
SUMMARY: Confronto Qwen/Chatterbox completato sul portatile: 16 campioni italiani pronti all'ascolto.
PER_VILLA: I campioni A/B sono pronti, con voce femminile e maschile e volume uguale. Chatterbox e' stato piu' rapido; la voce migliore la scegliamo ascoltando. La dettatura e' rimasta invariata.
NEXT: Mario ascolta il racconto A/B nelle due voci, poi cifre/date; registrare la preferenza in F1B3.
DECISIONS_NEEDED: Preferenza acustica sui campioni, oppure nessuno soddisfacente. Nessun motore adottato.
FILES_MODIFIED: experiments/tts-comparison, rapporto confronto-voci, ROADMAP, PROJECT_CONFIG, discovery-notes/state, decisions, obiettivi-e-fattibilita, handoff.
TESTS: PASS — 16 WAV CUDA, testi/hash/formato/segnale, copie -24 LUFS, ZIP CRC, pacchetti coerenti e baseline dettatura preservata. ASR eseguito su 16 file, cifre/date da verificare.
GUARDIANO_STANDARD: PASS — ambienti separati, versioni fissate, pesi verificati, riferimenti attribuiti; nessun driver/servizio o codice app modificato.
GUARDIANO_CONSEGNA: PASS — campioni e dati reali consegnabili; qualita' umana e integrazione non dichiarate come provate.
OLTRE_IL_CHIESTO: Nessuna nuova funzione nell'app; script di ripetizione e controlli necessari al confronto.
OCCHIO_ESTERNO: PASS — revisione indipendente del solo diff finale, nessun difetto concreto segnalato.

---

Mandato corrente: confronto locale e campioni italiani preservando dettatura.
Mandato generale precedente fino all'installer conservato; nessun runner avviato.
Rapporto: docs/fondamenta/confronto-voci-2026-10-16.md.
Codice/corpus/pin/lock/misure: experiments/tts-comparison/ (README per ripetere).
Audio locali: experiments/tts-comparison/outputs/ascolto/.
ZIP: outputs/Campioni_italiani_Qwen_Chatterbox_2026-10-16.zip nell'esperimento.
SHA256 ZIP: 3180fc284ff843c20fcd5757897c66a1c7c0359bd0af94c4fb9572f5580b7e1d.
16 WAV: 4 testi x 2 riferimenti (female/male) x 2 motori, copie a circa -24 LUFS.
Chiave: A=Chatterbox V3, B=Qwen 1.7B Base; mostrarla dopo primo ascolto se utile.
Qwen Torch 2.8 cu128 BF16/SDPA, Chatterbox Torch 2.6 cu124; venv isolati.
Riferimenti Google FLEURS italiani CC-BY-4.0, uguali per entrambi i motori.
RTF complessivo Qwen 4,91 / Chatterbox 1,41; altre app attive, niente streaming.
Picco allocato Torch: Qwen 4466 MiB / Chatterbox 3629 MiB, RTX 4080 Laptop 12 GB.
Trascrizioni di controllo small/CPU in outputs/transcripts.json, 16 file esaminati.
Cifre/date segnalate in entrambi: nessun giudizio acustico automatico o errori nascosti.
Backend freeze e hash requirements/Cargo invariati; diff applicativo assente.
Nessuna nuova dettatura reale, UI lettura, testo lungo, installer, 5080 o AMD provati.
Audio, modelli, riferimenti, baseline e venv ignorati da Git, restano disponibili qui.
Preparazione: risolti installazione Qwen concorrente e fetch Perth interrotto;
versioni fissate e stesso commit Perth da archivio. Nessuna modifica di sistema.
Scelta d'uso gia' chiarita: lettura selezione, qualita' prima della massima velocita'.
Non riproporre intervista strategica; adesso serve ascoltare i campioni.
Branch codex/discovery-voce-hardware; Cargo preesistente e .agents/.codex preservati.

## Prompt per riprendere

Whisper4Windows — F1B3 — Ascolto dei campioni italiani A/B.
LEGGI: istruzioni, ROADMAP, questo handoff e rapporto del confronto.
COSA FARE: acquisire il giudizio di Mario, poi pianificare runtime e normalizzazione.
GATE: preferenza o insoddisfazione registrata; nessuna scelta di motore presunta.
NON fare: rigenerare tutto, cambiare dettatura/driver o adottare il piu' rapido senza ascolto.
