# 27 — Il sorvegliante: guardare se lavora, non l'orologio

> Motore: `sorveglia_agente()` in `metodo/metodo-villa-runner.sh`.
> Prove: `tests/test_sorvegliante.sh`. Chiesto da Villa (2026-08-12).

## Cosa c'era prima, e perche' non andava

Il runner lanciava l'agente con un cane da guardia: allo scadere di un tempo fisso — mezz'ora,
un'ora, quello che si era impostato — **uccideva tutto**, qualunque cosa stesse succedendo.

Il difetto e' nel criterio, non nel numero. **Il tempo non dice se sta succedendo qualcosa**:
dice solo quanto e' passato. Un blocco grosso che stava lavorando bene veniva troncato a meta',
e quel lavoro era gia' stato pagato. Alzare il tempo non risolveva: spostava soltanto il punto
in cui si taglia a caso, e nel frattempo lasciava appesa per ore una sessione piantata.

## Cosa fa adesso

Claude Code, mentre lavora, scrive il proprio **diario di sessione**: ogni scambio aggiunge
righe. Quel file e' il segno vitale. Il sorvegliante lo guarda ogni mezzo minuto:

- **cresce** → sta lavorando: lo si lascia andare, anche a lungo;
- **non cresce da `INATTIVITA_MAX_MINUTI`** (10 di default) → e' piantato: si interrompe;
- **si supera `TETTO_ASSOLUTO_MINUTI`** (240) → si chiude comunque, per non restare in ostaggio
  in eterno di una sessione che macina senza arrivare in fondo.

Perche' il runner possa guardare quel file **fin dall'inizio**, l'identificativo della sessione
lo decide lui prima di partire (`--session-id`) invece di scoprirlo alla fine.

## Il perche' viaggia con l'interruzione

Le due interruzioni non sono lo stesso problema, e la differenza cambia la decisione:

| Motivo | Cosa vuol dire | Cosa se ne fa il guardiano |
|---|---|---|
| `appeso` | fermo da dieci minuti senza scrivere niente | non stava lavorando: era piantato. Riprovare identico lo ripianta |
| `tetto` | ha lavorato per quattro ore senza finire | il blocco e' quasi certamente troppo grosso: va spezzato, e spezzarlo non e' compito del guardiano |

Il motivo finisce nella situazione che il guardiano legge (cap. 24), insieme alla direttiva 7:
guardare cosa e' rimasto a meta', e scegliere fra riprendere da li', ricominciare pulito, o
fermarsi perche' il blocco andava tagliato meglio.

## Il modo piu' comune di piantarsi: accendere qualcosa che resta acceso

Il 2026-08-16 il blocco 5.6 ha fermato la corsa. Il sorvegliante ha fatto il suo mestiere: il
silenzio era vero, l'ultima mossa dell'agente era delle 03:33:53 e alle 03:44 non era ancora
successo niente. Ma il **perche'** non era quello che sembrava.

L'ultima mossa era questa:

```
Start-Process python -ArgumentList 'metodo/servitore-gui.py','--porta','8799' ...
```

Il comando non e' mai tornato indietro. E il servitore e' rimasto acceso anche dopo
l'interruzione: **venti minuti dopo teneva ancora la porta 8799**, perche' `Start-Process`
lo aveva messo FUORI dall'albero del blocco, e uccidere l'albero non lo raggiungeva.

**Le due trappole sono opposte e si scambiano l'una con l'altra.** Chi accende un programma
che non finisce puo' sbagliare in due modi, tutti e due invisibili:

| Errore | Cosa succede | Come lo si vede |
|---|---|---|
| lo lascia attaccato alla propria uscita | chi lo ha lanciato aspetta la fine di qualcosa che per definizione non finisce | il blocco si pianta e il sorvegliante lo interrompe |
| lo stacca fino a metterlo fuori dall'albero | sopravvive al blocco e tiene la porta | il blocco DOPO fallisce senza capire perche' |

Chi scappa dalla prima cade nella seconda. Per questo il Metodo non chiede di ricordarsi la
forma giusta: da' lo strumento che le evita tutte e due, **`metodo/con-servitore.sh`**, e
l'istruzione 2ter del messaggio del blocco dice di usarlo.

```
metodo/con-servitore.sh <porta> <secondi> -- <comando che accende> -- <comando di prova>
```

Accende con l'uscita in un file e l'ingresso chiuso (niente attesa infinita), lascia il
processo **figlio** (quindi l'albero lo comprende), aspetta che la porta risponda davvero
invece di contare i secondi, esegue la prova e **spegne sempre** — anche se la prova
fallisce, anche se lo si interrompe. Lo spegnimento sta in un `trap`, non in fondo allo
script, proprio perche' deve valere nei casi in cui si esce male.

**Una lezione che vale oltre i servitori.** Il guardiano, quella notte, ha letto «si e'
fermato» e ha concluso «il blocco era troppo grosso, va spezzato in tre». Sul taglio non
aveva torto — quel blocco impastava tre verifiche — ma sulla **causa** si era inventato una
storia credibile senza guardare cosa stesse facendo l'agente nell'ultimo minuto. Spezzare il
blocco non avrebbe tolto la trappola: il pezzo che verifica la pagina avrebbe riacceso il
servitore e si sarebbe piantato uguale. **Quando un blocco si ferma, la prima cosa da
guardare sono le sue ultime mosse, non la sua dimensione.**

## Tutti gli stop non programmati passano dal guardiano

Prima il guardiano vedeva solo gli stop **dichiarati dall'agente** (checkpoint, errore,
bloccato). Tutto il resto faceva morire la corsa in silenzio. Adesso ci passano anche:

- la **sessione crollata o interrotta** (`FAILED`);
- il **diario di bordo mancante** (`MISSING`);
- lo **stato incomprensibile** nell'handoff;
- il **giro a vuoto** (stesso blocco ripetuto): e' un baco del meccanismo, ed e' esattamente
  cio' che un occhio nuovo sistema rimettendo a posto il diario.

Restano fuori, per scelta, gli stop **programmati**: fine fase, e i blocchi 👤/🤝 della roadmap.
Quelli sono appuntamenti con Villa, non imprevisti.

E in tutti questi casi **la sessione non si riprende mai**: si riparte puliti (cap. 26). Dopo
un problema, portarsi dietro la conversazione vorrebbe dire portarsi dietro il pasticcio.
