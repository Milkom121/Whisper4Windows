# 26 — La memoria di lavoro: riempire la sessione, non tagliarla

> Motore: `si_puo_continuare()` e `build_prompt()` in `metodo/metodo-villa-runner.sh`,
> `metodo/leggi-contesto.py`. Prove: `tests/test_memoria_di_lavoro.sh`.
> Nasce da un'idea di Villa (2026-08-12).

## Il problema, e perche' non si vedeva

Il runner faceva **una sessione per blocco**. Ogni sessione ripaga da zero il preambolo —
regole del Metodo, contesto del progetto, istruzioni, roadmap: **circa 30.000 unita',
misurate**. Su una fase da venti blocchi sono 600.000 unita' per ridire venti volte le stesse
cose, e non c'e' cache che le recuperi (cap. 23: fra invocazioni separate non aggancia).

La strada che sembrava ovvia era tagliare il preambolo. L'abbiamo fatto, ed era il massimo
ottenibile **restando dentro quella forma**. La forma stessa era il problema.

## L'idea

Finito un blocco, la memoria di lavoro e' occupata al 15-20%: c'e' ancora tutto lo spazio
buono. Invece di chiudere la sessione e ricominciare da zero, **il blocco dopo continua li'**.
Il preambolo si paga **una volta ogni tre o quattro blocchi** invece che ogni volta.

Villa lo ha formulato cosi': *«sfruttare ogni sessione dallo 0% al 50%»*. Non tagliare il
lavoro a metà — **riempire la fascia in cui il modello lavora bene**, e fermarsi prima di
quella in cui lavora peggio.

## Perche' la soglia non e' avarizia

La ricerca 2026 sul logoramento del contesto e' netta: i modelli **peggiorano** man mano che
la finestra si riempie, molto prima del limite dichiarato — la precisione di ragionamento cala
in modo misurabile, e l'attenzione si perde su cio' che sta in mezzo. Quindi la soglia fa due
cose in una: **risparmia** (preambolo pagato una volta) e **fa lavorare meglio** (si sta dove
il modello e' affidabile).

## I due numeri, e perche' sono due

| Numero | Valore | A che serve |
|---|---:|---|
| `CONTESTO_SOGLIA_NUOVO` | 35% | si accetta un blocco NUOVO solo se la memoria e' occupata fin qui |
| `CONTESTO_SOGLIA_TETTO` | 50% | il tetto che non si vuole superare: oltre, l'agente chiude al primo punto pulito |

Il margine fra i due **e' lo spazio in cui il blocco nuovo deve entrare**. Con una soglia sola
si finirebbe regolarmente oltre il tetto: si accetta un blocco al 49% e lo si chiude al 70%.

## Quando si continua, e quando no

Si continua **solo** se: la cosa e' accesa (`CONCATENA=si`), il blocco appena chiuso e' andato
**bene** (stato CONTINUE, test verdi), si **sa** quanta memoria e' occupata, e si e' entro il
35%.

Si ricomincia pulito in tutti gli altri casi, e sono i casi che contano:

- dopo un CHECKPOINT, un ERROR, un BLOCKED — **il pasticcio non si eredita**;
- dopo un intervento del guardiano (cap. 24): la situazione e' cambiata, il diario e' stato
  riscritto;
- al cambio di fase;
- se non si riesce a leggere quanta memoria e' occupata: **nel dubbio si ricomincia**.

## Cosa cambia nel messaggio del blocco

Il blocco che continua riceve un messaggio **corto**: qual e' il blocco, di che si tratta, a
che punto e' la memoria, e il promemoria che la verifica di fine blocco resta obbligatoria.
Regole, contesto e roadmap **non si ripetono**: sono gia' nella conversazione, e ripeterli
sarebbe esattamente la spesa che tutto questo serve a evitare.

Ogni blocco resta comunque **atomico**: verifica, diario, commit. Cambia dove lavora, non come
si chiude.

## Come si legge quanta memoria e' occupata

Attenzione a non confondere due numeri:

- i **token consumati** da una sessione crescono a ogni scambio, e dopo un blocco lungo sono
  molti piu' della finestra (ogni scambio ripaga il contesto di prima). Servono per il costo
  (cap. 23), non per lo spazio.
- la **memoria occupata** e' l'ingresso dell'ultima richiesta, e non puo' superare la finestra.
  E' questa che dice se c'e' spazio.

`leggi-contesto.py` la legge dal diario di sessione di Claude Code, prendendo l'ultimo scambio
che riporta un consumo. Se non trova niente, non stampa niente — e il runner ricomincia pulito.

## Cosa si vede a fine corsa

Nel riepilogo compare quante volte il preambolo **non** e' stato ripagato. E' la misura diretta
del risparmio: ogni volta sono ~30.000 unita' che non si sono spese.
