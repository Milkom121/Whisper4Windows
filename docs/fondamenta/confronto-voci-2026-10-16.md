# Campioni italiani Qwen3-TTS e Chatterbox

Prova eseguita il **16 ottobre 2026** sulla RTX 4080 Laptop di Mario.
Sono pronti **16 audio locali**: quattro testi, due riferimenti vocali e due
motori. L'applicazione e le dipendenze della dettatura sono rimaste invariate.

## Ascolto

Pacchetto locale: `experiments/tts-comparison/outputs/Campioni_italiani_Qwen_Chatterbox_2026-10-16.zip`
(10,4 MiB circa). Le copie d'ascolto sono anche nella sottocartella `outputs/ascolto/`.

- `01_racconto`: prosa e naturalezza.
- `02_dialogo`: domande, pause e intonazione.
- `03_numeri`: cifre, date, valuta e abbreviazioni, senza normalizzazione aggiunta.
- `04_tecnico`: software, NVIDIA e parole inglesi.

Ogni testo ha una versione `female` e una `male`, rispettivamente riferimento
femminile e maschile. **Iniziare dal racconto**, confrontando A e B della stessa
voce. L'ascolto di Mario non e' ancora avvenuto e non viene presunto.

Le copie sono portate a circa **-24 LUFS** tramite guadagno costante, senza
cambiare velocita', pause o parole. Livelli finali verificati: da -24,025 a
-24,000 LUFS. Non sono stati ritagliati errori o scelte le generazioni migliori
fra molti tentativi: ogni segmento e' stato generato una volta con seed fissato.

Il pacchetto include testi, chiave A/B, misure complete, riferimenti, licenze
di provenienza, versioni dei pacchetti e trascrizioni di controllo. SHA-256:
`3180fc284ff843c20fcd5757897c66a1c7c0359bd0af94c4fb9572f5580b7e1d`.

<details>
<summary>Chiave A/B — aprire dopo il primo ascolto</summary>

A = Chatterbox Multilingual V3. B = Qwen3-TTS 1.7B Base.

</details>

## Configurazioni effettivamente provate

| Parte | Qwen | Chatterbox |
|---|---|---|
| Modello | Qwen3-TTS-12Hz-1.7B-Base | Multilingual V3, checkpoint `t3_mtl23ls_v3.safetensors` |
| Runtime | qwen-tts 0.1.1, PyTorch 2.8.0 CUDA 12.8 | sorgente Chatterbox 0.1.7 fissato, PyTorch 2.6.0 CUDA 12.4 |
| Impostazioni | BF16, SDPA, clonazione con audio e trascrizione, generazione non streaming | parametri ufficiali di base, `exaggeration=0.5`, `cfg_weight=0.5` |
| Lingua | Italian esplicito | `it` esplicito |
| Esecuzione | GPU, processo dedicato | GPU, processo dedicato, dopo Qwen |

Python 3.12.10. Driver NVIDIA 595.97; GPU 12.282 MiB totali. Alimentazione
collegata rilevata durante la prova. Le altre applicazioni non sono state
terminate: questi dati descrivono la sessione reale, non la massima prestazione
di una macchina completamente libera.

I due venv sono separati sia fra loro sia da `backend/venv`. Le loro dipendenze
richiedono anche versioni diverse di NumPy e Transformers: l'isolamento e'
stato effettivamente necessario. Nessun driver, PATH o runtime di sistema modificato.

## Tempi e memoria misurati

| Misura | Qwen | Chatterbox |
|---|---:|---:|
| Caricamento motore da file locali | 78,01 s | 46,70 s |
| Prima preparazione del riferimento femminile | 4,26 s | 18,97 s |
| Preparazione successiva del riferimento maschile | 0,17 s | 0,18 s |
| Generazione dei 16 segmenti | 786,85 s | 199,95 s |
| Audio prodotto, esclusi silenzi aggiunti fra segmenti | 160,16 s | 141,40 s |
| Fattore tempo reale complessivo | **4,91** | **1,41** |
| Mediana del fattore tempo reale per segmento | 4,64 | 1,22 |
| Picco memoria GPU allocata da PyTorch | 4.466 MiB | 3.629 MiB |
| Picco memoria GPU riservata da PyTorch | 5.184 MiB | 3.954 MiB |
| Picco RAM del processo | 4.432 MiB | 4.968 MiB |
| Picco occupazione GPU totale, comprese altre app | 11.548 MiB | 10.314 MiB |

Fattore tempo reale = tempo di generazione / durata audio. Sotto 1 la voce
viene prodotta piu' rapidamente dell'ascolto; sopra 1 serve piu' tempo. In
questa configurazione Chatterbox e' stato complessivamente piu' rapido.

Il caricamento include gli import specifici del motore, ma esclude l'import
iniziale di PyTorch. Pesi gia' scaricati: i download non sono inclusi nei tempi
della tabella. I primi usi includono inizializzazioni; non sono state ripetute
serie complete per stimare intervalli di confidenza. RAM e GPU totale sono
campionate ogni mezzo secondo; allocazione e riserva sono misure PyTorch.

Queste API restituiscono frasi complete. **Non e' una misura del tempo al primo
suono udibile di un'app con streaming**. Non sono stati provati FlashAttention,
CUDA graphs, faster-qwen3-tts, quantizzazione o C++. La lentezza della baseline
Qwen non dimostra che ogni sua implementazione sia altrettanto lenta.

## Contenuto e qualita': cosa sappiamo

Un Whisper small gia' in cache ha riletto i 16 file su CPU, dopo le misure GPU.
Le trascrizioni riportano sostanzialmente i brani di prosa e dialogo, con
differenze ortografiche e alcune parole da verificare. Per **date, valuta e
abbreviazioni** emergono trascrizioni molto problematiche in entrambi i motori.

Questo e' un segnale da controllare ascoltando, non un verdetto acustico
automatico: Whisper puo' sbagliare a sua volta. Non e' stato calcolato un voto
di naturalezza, ne' un WER sui numeri senza una normalizzazione affidabile.
Gli audio problematici non sono stati nascosti o corretti nella consegna.

Prima dell'integrazione sara' necessario provare la conversione italiana di
date, importi e abbreviazioni in forme parlate, mantenendo il significato del
testo selezionato. La preferenza sul timbro, l'accento, la prosodia e la fatica
d'ascolto resta a Mario. Nessun vincitore di qualita' scelto automaticamente.

## Riferimenti vocali e attribuzione

Entrambi i motori ricevono **le stesse due clip italiane** di
[Google FLEURS](https://huggingface.co/datasets/google/fleurs), split validation
`it_it`, revisione `70bb2e84b976b7e960aa89f1c648e09c59f894dd`, licenza
[CC-BY-4.0](https://creativecommons.org/licenses/by/4.0/).

- Femminile: `10055650398672901952.wav`, 8,46 secondi.
- Maschile: `10020283897811844164.wav`, 7,50 secondi.

Nessuna voce o registrazione di Mario e' stata acquisita. Le etichette dei
parlanti provengono dal dataset, senza attribuire identita' personali. La stessa
clip non comporta identico trattamento interno: Chatterbox usa finestre di
condizionamento diverse da Qwen. Sono riferimenti di prova, non le voci
definitive selezionate per il prodotto.

Codice/pesi dei candidati: [Qwen](https://github.com/QwenLM/Qwen3-TTS) e
[Chatterbox](https://github.com/resemble-ai/chatterbox). Revisioni esatte in
`experiments/tts-comparison/versions.json`; hash dei 18 file modello verificati
nel pacchetto. Il tokenizer Qwen incorporato coincide con quello della
revisione separata registrata. Pacchetti risolti fissati nei due lock file.

## Verifiche e limiti della consegna

- **PASS**: 16 WAV grezzi integri, non vuoti/non silenziosi, testi corrispondenti,
  inferenza CUDA e hash validi. Nessuna saturazione oltre la soglia di controllo.
- **PASS**: 16 copie d'ascolto a volume confrontabile e ZIP con CRC verificati.
- **PASS**: compatibilita' dichiarata dei pacchetti nei due ambienti (`uv pip check`).
- **PASS**: freeze del backend e hash di requirements/Cargo identici alla baseline;
  nessuna modifica al codice applicativo nel diff. Cargo preesistente preservato.
- **Eseguito**: controllo assistito del contenuto su tutti i 16 file. Le
  criticita' di pronuncia restano aperte, non promosse come corrette.
- **Non eseguito**: ascolto umano, nuova dettatura reale, lettura della selezione
  dall'app, streaming, testo continuo di dieci minuti, stop/pausa, alternanza
  funzionale con la dettatura, installer, macchina 5080 o AMD.

Durante l'allestimento una seconda installazione Qwen avviata troppo presto
e' stata fermata, poi ripetuta con Torch CUDA fissato. Il trasferimento Git
di Perth si e' interrotto; e' stato usato l'archivio della stessa revisione.
Questi problemi di preparazione sono risolti e non sono prestazioni TTS.
Il warning SoX di Qwen non ha impedito questa generazione; non e' stato
installato alcun eseguibile di sistema per silenziarlo.

## Ripetere e proseguire

Istruzioni in `experiments/tts-comparison/README.md`. Dati aggregati e hash
degli audio in `experiments/tts-comparison/measurements-2026-10-16.json`.
Audio, modelli, log, baseline e ambienti restano locali, esclusi da Git.

Prossimo passo: ascolto A/B di Mario. Dopo la preferenza, verificare il runtime
adatto alla lettura quotidiana e la normalizzazione italiana; non adottare un
motore soltanto per il tempo della tabella o per una trascrizione automatica.
