# Piano operativo — voce italiana e hardware automatico

Bozza 0.2 del 2026-10-16, aggiornata dopo la risposta strategica di Mario.
La roadmap e' l'unica fonte dello stato dei blocchi. Qui si descrivono percorso e
gate: non sono certificazioni di funzioni o test gia' eseguiti.

## 1. Decisioni strategiche

Uso principale chiarito: leggere il testo selezionato con la qualita' vocale
migliore possibile; comodita' d'uso gradite. La risposta chiarisce anche il
compromesso qualitativo, quindi non serve la seconda domanda prevista.
Caso concreto e criteri di confronto nel rapporto `obiettivi-e-fattibilita.md`.
Tempi accettabili numerici non ancora concordati; non inventarli come decisioni.

## 2. Prove isolate dei motori

- Ambiente TTS separato, senza alterare il venv della dettatura.
- Corpus italiano: cifre, date, abbreviazioni, nomi, frasi e brano lungo.
- Primo confronto: Qwen3-TTS 1.7B e Chatterbox Multilingual V3. Poi VoxCPM2
  e CosyVoice3 per cercare un vantaggio italiano; MOSS v1.5 solo con pesi/runtime
  riproducibili compatibili con la memoria. Una baseline leggera fra Pocket TTS,
  MOSS Nano ONNX e Kokoro. La priorita' e' la voce, non il numero di motori.
- Misurare primo audio, velocita', RAM/VRAM, correttezza e stabilita'; distinguere
  avvio a freddo, a caldo e alternanza con la dettatura.
- AMD: provare runtime e macchina, poi conservare CTranslate2 o introdurre
  adattatore alternativo secondo i risultati. Niente promessa universale.
- Verificare licenze di codice, pesi e voci prima di distribuirli.

Uscita: motori/versioni e profili motivati da dati, limiti registrati.
Nessuna modifica automatica di driver o PATH di sistema.

## 3. Progettazione e integrazione

- Contratto per capacita', caricamento, lavoro, cancellazione ed errori.
- Rilevare runtime utilizzabili: il nome GPU non basta. Ripiego CPU motivato e
  visibile. Evitare reset CUDA condivisi e lavori nativi impossibili da fermare;
  valutare processi separati, senza trattarli come architettura gia' implementata.
- Coordinare ascolto/registrazione: non perdere dettatura o impostazioni e non
  catturare involontariamente la voce sintetica nel microfono.
- Acquisire la selezione prima di spostare il focus; provare controlli Windows
  compatibili e fallback appunti senza leggere testo vecchio o perdere formati.
- Correggere il difetto riprodotto di /start che dichiara registrazione avviata
  anche quando AudioCapture.start_recording() fallisce.
- Rilevare l'interfaccia attuale prima di estenderla; conservare stack e stile.
- Download con progresso, spazio richiesto, annullamento e integrita'; offline
  dopo preparazione. Proteggere API locale e WebView prima del rilascio.

Prima di sviluppare: blocchi piccoli in ROADMAP, ognuno con una suite di verifica,
natura e peso. Uscita: percorsi interi funzionanti e regressioni della dettatura.

## 4. Collaudo del prodotto

| Percorso | Prova richiesta |
|---|---|
| Dettatura | registra, interrompi, trascrivi e inserisci; annulla senza residui |
| Lettura | primo audio e completamento italiano; stop, errori e testo lungo |
| Convivenza | alterna lettura/dettatura e cambia modello senza reset o blocchi |
| Hardware | NVIDIA reale, CPU forzata e AMD reale prima della certificazione |
| Recupero | modello mancante, download interrotto, poca memoria, worker terminato |
| Offline | riavvio senza rete dopo preparazione e completamento dei due compiti |
| Installazione | nuovo pacchetto in ambiente pulito, avvio, aggiornamento, rimozione |

Test simulati verificano logica, non certificano GPU o qualita' acustica reali.
Separare passati, falliti e non coperti. Giudizio sulla voce e accesso al Minisforum
possono richiedere Mario: non presentare prove remote come gia' disponibili.

## 5. Build e consegna

Fissare versioni e provenienza; niente successi basati su vecchi artefatti.
Costruire sidecar, eseguibile e installer coordinati, poi provare il pacchetto
e non solo i sorgenti. Consegnare file, versione, hash e istruzioni essenziali,
con download iniziali, stato firma e copertura reale dichiarati.

Nessuna pubblicazione di release o fusione su main implicita. Se manca la prova
Minisforum, una build preliminare non e' un rilascio AMD pienamente collaudato.
