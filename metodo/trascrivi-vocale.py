"""Trascrittore di messaggi vocali — OPZIONALE.

Riceve il percorso di un file audio e stampa il testo. E' il pezzo che permette
di rispondere al guardiano a voce invece che scrivendo.

NON E' OBBLIGATORIO. Se non lo configuri, i vocali non si perdono: il guardiano
chiede di riscrivere. Per attivarlo, in .env.runner:

    TELEGRAM_TRASCRITTORE=python metodo/trascrivi-vocale.py

Gira in locale con faster-whisper: nessun audio esce dal computer, nessun
fornitore esterno. Se faster-whisper non e' installato, esce con un errore
chiaro e il canale degrada come se il trascrittore non ci fosse.

    pip install faster-whisper

Regolazioni (variabili d'ambiente, tutte con un valore sensato di partenza):
    WHISPER_MODELLO   small (predefinito) | medium | large-v3 ...
    WHISPER_LINGUA    it (predefinito). Vuoto = riconoscimento automatico.
    WHISPER_DISPOSITIVO  cpu (predefinito) | cuda
"""
import os
import sys

MODELLO = os.environ.get('WHISPER_MODELLO', 'small')
LINGUA = os.environ.get('WHISPER_LINGUA', 'it').strip() or None
DISPOSITIVO = os.environ.get('WHISPER_DISPOSITIVO', 'cpu')
# int8 sta in poca memoria ed e' abbastanza per un messaggio vocale di pochi secondi.
CALCOLO = os.environ.get('WHISPER_CALCOLO', 'int8' if DISPOSITIVO == 'cpu' else 'float16')


def main():
    if len(sys.argv) < 2:
        print('Uso: trascrivi-vocale.py <file-audio>', file=sys.stderr)
        return 1
    audio = sys.argv[1]
    if not os.path.isfile(audio):
        print('File audio non trovato: %s' % audio, file=sys.stderr)
        return 1

    try:
        from faster_whisper import WhisperModel
    except ImportError:
        print('faster-whisper non installato: i vocali non si possono trascrivere. '
              'Installa con "pip install faster-whisper", oppure lascia vuoto '
              'TELEGRAM_TRASCRITTORE e rispondi scrivendo.', file=sys.stderr)
        return 2

    try:
        modello = WhisperModel(MODELLO, device=DISPOSITIVO, compute_type=CALCOLO)
        segmenti, _ = modello.transcribe(audio, language=LINGUA, vad_filter=True)
        testo = ' '.join(s.text.strip() for s in segmenti).strip()
    except Exception as e:
        print('Trascrizione fallita (%s): %s' % (type(e).__name__, str(e)[:300]), file=sys.stderr)
        return 3

    if not testo:
        print('Audio vuoto o non comprensibile.', file=sys.stderr)
        return 4

    sys.stdout.write(testo + '\n')
    return 0


if __name__ == '__main__':
    sys.exit(main())
