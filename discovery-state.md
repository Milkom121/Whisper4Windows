# Discovery State — Whisper4Windows

## Fase corrente: campioni italiani prodotti, attesa ascolto di Mario

Ricerca e confronto sperimentale svolti il 16 ottobre 2026. Nessun motore scelto.
Skill: `.claude/skills/discovery/SKILL.md`.

## Decisioni prese

- Metodo Villa; app Windows locale, italiano e adattamento NVIDIA/AMD/CPU.
- Mandato esteso a implementazione, test ed eseguibile installabile.
- Domande solo strategiche; scelte tecniche delegate all'agente.
- Mario vuole prevalentemente leggere il testo selezionato con le voci e la
  qualita' migliori possibili. Comodita' d'uso gradite; produzione non prioritaria.
- La risposta 1 chiarisce anche la priorita' qualitativa: seconda domanda eliminata.

## Gap aperti

- Scegliere voce e runtime attraverso campioni italiani comparabili e misure.
- Fissare soglie tecniche prima delle prove; non inventare un'attesa accettata da Mario.
- Qwen 1.7B Base e Chatterbox V3 provati in CUDA sul portatile, 16 file pronti.
  Preferenza acustica da acquisire; cifre/date da controllare all'ascolto.
- Minisforum e 5080 non verificati; testi lunghi e integrazione da collaudare.

## File prodotti

- `discovery-notes.md`: acquisizioni, gap e responsabili.
- `docs/fondamenta/obiettivi-e-fattibilita.md`: analisi codice, motori, fonti,
  differenze 12/16 GB, proposta di integrazione e piano della prova.
- `docs/fondamenta/piano-operativo-voce-hardware.md`: percorso/gate, bozza 0.2.
- Roadmap, consegne, decisioni e mandato nella ricerca esistente aggiornati.
- `docs/fondamenta/confronto-voci-2026-10-16.md`: risultati e limiti.
- `experiments/tts-comparison/`: corpus, script e versioni ripetibili;
  WAV/ZIP, modelli e venv rimangono locali e ignorati da Git.

## Prossimo passo

Mario ascolta A/B, prima racconto nelle due voci, poi cifre/date. Registrare
preferenza o insoddisfazione senza promuovere automaticamente il piu' rapido.
In seguito provare runtime e normalizzazione; altri candidati se necessari.
La lettura nell'app non e' ancora disponibile. Driver e dettatura preservati.
