# Confronto italiano Qwen3-TTS / Chatterbox

Esperimento separato dall'applicazione. Nessun import dal backend e nessuna
modifica al suo ambiente. Ogni motore gira nel proprio processo e venv, uno
alla volta sulla GPU. Non avviare un secondo servizio sulla porta dell'app.

## Materiale e ripetibilita'

- `versions.json`: revisioni dei modelli, sorgenti consultati e seed.
- `corpus.json`: quattro testi originali, due segmenti per testo.
- `prepare_references.py`: due riferimenti italiani dal validation set di
  [Google FLEURS](https://huggingface.co/datasets/google/fleurs), CC-BY-4.0.
  Autori: team Google FLEURS; attribuzione e revisione anche nel manifest.
  Clip identiche per entrambi i motori, senza identita' attribuite ai parlanti.
- `download_models.py`: file a revisione fissata, verifica SHA-256 dei pesi LFS.
- `run_comparison.py`: genera campioni e misure, senza riprodurre audio o usare
  il microfono. Richiede CUDA ed evita un ripiego CPU silenzioso.
- `outputs/`: audio grezzi e risultati locali, esclusi da Git.
- `references/`: audio di riferimento e trascrizioni, esclusi da Git.

Prima di ripetere, conservare `baseline.local.json` per confrontare dipendenze
e hash della dettatura. Gli ambienti creati sono `.venv-qwen` e
`.venv-chatterbox`, Python 3.12.10. I pacchetti risolti effettivamente e gli
hash dei checkpoint accompagnano i risultati. Nessun driver viene installato.

Qwen: pacchetto `qwen-tts==0.1.1`, PyTorch/Torchaudio 2.8.0 CUDA 12.8.
Chatterbox: sorgente alla revisione registrata, PyTorch/Torchaudio 2.6.0 CUDA
12.4; dipendenza Perth fissata tramite `chatterbox-overrides.txt`.

## Esecuzione (PowerShell, dalla radice del repository)

Preparazione dei riferimenti e dei pesi con Python standard:

```powershell
backend/venv/Scripts/python.exe experiments/tts-comparison/capture_baseline.py
backend/venv/Scripts/python.exe experiments/tts-comparison/prepare_references.py
backend/venv/Scripts/python.exe experiments/tts-comparison/download_models.py
```

`capture_baseline.py` va eseguito una sola volta prima delle installazioni e
rifiuta di sovrascrivere una baseline esistente.

Dopo aver preparato i due ambienti, eseguire i motori **in sequenza**:

```powershell
experiments/tts-comparison/.venv-qwen/Scripts/python.exe experiments/tts-comparison/run_comparison.py qwen
experiments/tts-comparison/.venv-chatterbox/Scripts/python.exe experiments/tts-comparison/run_comparison.py chatterbox
```

Per ricreare gli ambienti dalle versioni effettivamente risolte (operazione
voluminosa, da non eseguire dentro `backend/venv`):

```powershell
uv venv --python backend/venv/Scripts/python.exe experiments/tts-comparison/.venv-qwen
uv venv --python backend/venv/Scripts/python.exe experiments/tts-comparison/.venv-chatterbox
uv pip sync --python experiments/tts-comparison/.venv-qwen/Scripts/python.exe experiments/tts-comparison/requirements-qwen.lock.txt --extra-index-url https://download.pytorch.org/whl/cu128 --index-strategy unsafe-best-match
uv pip sync --python experiments/tts-comparison/.venv-chatterbox/Scripts/python.exe experiments/tts-comparison/requirements-chatterbox.lock.txt --extra-index-url https://download.pytorch.org/whl/cu124 --index-strategy unsafe-best-match
```

Prima di sovrascrivere un ambiente dell'esperimento, conservarne il freeze se
si stanno confrontando configurazioni diverse. Il file locale di baseline va
creato sulla macchina di prova prima delle installazioni; contiene hash dei
file applicativi da preservare e il freeze del venv dettatura.

Controllo degli audio e pacchetto d'ascolto, dopo entrambi i motori:

```powershell
backend/venv/Scripts/python.exe experiments/tts-comparison/validate_results.py
experiments/tts-comparison/.venv-chatterbox/Scripts/python.exe experiments/tts-comparison/package_samples.py
```

La verifica assistita del contenuto usa `check_transcripts.py` con un modello
Whisper gia' in cache, su CPU e dopo la misura dei due motori. Non sostituisce
l'ascolto e non assegna un voto di qualita' alla voce.

## Che cosa misurano i risultati

Tempi di caricamento motore da file locali (inclusi import specifici del motore,
escluso l'import iniziale di PyTorch) e preparazione riferimento separati dalla
generazione. Ogni segmento ha durata audio, tempo di elaborazione, fattore
tempo reale (tempo elaborazione / durata audio) e picco memoria PyTorch.
La RAM e l'occupazione totale della GPU sono campionate ogni mezzo secondo:
il dato GPU totale comprende anche le altre applicazioni.
Le altre applicazioni non vengono terminate: sono misure di questo portatile
nelle condizioni della sessione, non un benchmark a macchina completamente libera.

Queste API producono il segmento completo: **non e' una misura di latenza
al primo suono di un'app con streaming**. Il primo segmento include il costo
del primo uso; i successivi sono a motore caldo. Il confronto non comprende
FlashAttention, quantizzazione, runtime C++ o altri interventi di accelerazione.

I riferimenti durano 8,46 secondi (voce femminile) e 7,50 secondi (maschile).
Chatterbox usa internamente finestre di condizionamento diverse da Qwen: stessa
clip non significa identico trattamento interno. I numeri e le abbreviazioni
sono inviati come scritti, senza normalizzatore aggiunto all'applicazione.

L'ascolto di Mario decide la preferenza. La generazione di un WAV valido non
certifica naturalezza, pronuncia corretta, testi di dieci minuti o convivenza
funzionale con la dettatura. I relativi limiti vanno dichiarati nella consegna.
