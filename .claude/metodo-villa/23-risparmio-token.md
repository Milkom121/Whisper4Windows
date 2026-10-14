# 23 — Risparmio di token (quello che il Metodo fa da solo)

> Ricerca completa, misure e leve non ancora adottate: `docs/fondamenta/risparmio-token.md`.
> Qui sta solo quello che il Metodo **fa gia'**, e perche'.

## La regola che viene prima di tutte (Villa, 2026-08-11)

*«Non inficiare il funzionamento del Metodo. Ottimizzare solo il superfluo, senza rompere
la qualita'.»*

In pratica: si toglie **solo cio' che non serve a nessuno** — roba duplicata, testo gia' in
memoria, output che nessuno legge. **Non si tocca** cio' che l'agente usa per lavorare bene:
le regole di qualita', il manuale che applica, il modello che ragiona, la verifica di fine
blocco. Davanti al dubbio «questo serve o no?», la risposta e' **serve**.

Corollario, imparato sul campo: **prima si misura, poi si taglia**. Le stime fatte contando i
caratteri hanno sbagliato di quattro volte su una leva che sembrava grossa (le descrizioni
delle competenze: stimate ~3.000 token, misurate 843). Una leva senza misura non si applica.

## Il problema, in una riga

Il runner riapre l'agente **da capo a ogni blocco**, e fra un'invocazione e l'altra **la cache
non aggancia**: ogni riga di contesto si ripaga tante volte quanti sono i blocchi della corsa.

Misurato il 2026-08-11, tre chiamate di fila nella stessa cartella: la parte riletta dalla
cache resta ferma a 10.797 token, mentre ne vengono **riscritti ~14.200 ogni volta**, anche
quando fra una chiamata e l'altra **non cambia assolutamente nulla**. Quindi la causa non e'
il commit di fine blocco (era la spiegazione scritta qui in un primo momento, ed era
sbagliata): e' che ogni invocazione e' una sessione nuova, e il pezzo grosso del preambolo si
ricompra ogni volta. Conseguenza pratica: **non esiste nessun trucco sull'ordine del messaggio
che recuperi quella spesa.** L'unica cosa che funziona e' che quelle righe non ci siano.

Un file di regole da 6.000 token non costa 6.000 token: su una fase da 20 blocchi ne costa
120.000. E' per questo che nel Metodo il risparmio non e' avarizia: e' manutenzione.

**E c'e' un secondo moltiplicatore, piu' grosso del primo, misurato il 2026-08-16.** Dentro
UN blocco l'agente fa **circa cento domande al modello**, e ogni domanda si riporta dietro
tutto il contesto precedente, messaggio d'apertura compreso. Quindi una riga tolta
dall'apertura non si risparmia una volta per blocco: **si risparmia cento volte per blocco**.
Su Fedorium, mediana di 99 domande e 22,5 milioni di token letti a blocco.

Ed e' qui che si vede quanto pesava la zavorra: nella fase in corso di Fedorium i blocchi
gia' chiusi erano **154.851 caratteri, il 73% della roadmap spedita**. Toglierne il corpo ha
portato il messaggio del blocco da **249.814 a 89.000 caratteri, il 64% in meno** — senza
togliere una riga di cio' che serve a fare il lavoro.

**Dove NON c'era niente da riparare** (misurato, per non riprovarci): la cache di Anthropic
gia' rilegge 15,6 volte per ogni scrittura e risparmia l'81%; quella di Moonshot e' al 99%
di riuso. Il difetto non era mai il tasso di riuso: era la dimensione di cio' che ci sta
dentro. **Una cache che funziona benissimo su un messaggio enorme costa comunque enormemente.**

## Cosa fa il Metodo, oggi

Cinque tagli, tutti nel motore. L'agente non deve fare niente di diverso.

| Taglio | Dove | Cosa cambia |
|---|---|---|
| La roadmap entra ridotta alla **fase in corso** | `estratto_roadmap()` nel runner | delle altre fasi restano i titoli e a che punto sono; il file intero resta sul disco, si apre se serve |
| Dei **blocchi gia' chiusi** resta il titolo, non il corpo | `roadmap_comprimi_fatti()` in `metodo-roadmap.sh` | il dettaglio di un lavoro finito non serve a chi deve fare quello dopo. Restano intestazioni, riga di stato, e per intero i blocchi da fare e in corso. Su una roadmap senza caselle non cambia niente |
| Le regole **non si mandano due volte** | `build_prompt()` nel runner | Claude Code carica da se' il `CLAUDE.md` della cartella di lavoro (e con lui il file operativo): il runner non lo riscrive. Nei monorepo e con gli altri programmi si passa come prima |
| **Non si ordina di rileggere** cio' che e' gia' in contesto | istruzione 1 del prompt | prima diceva «leggi CLAUDE.md e il file operativo», che l'agente aveva gia' davanti |
| Il diario ha un **tetto di 50 righe** | `HANDOFF_MAX_RIGHE` nel runner | dichiarato all'agente nel formato; se lo sfora, la coda viene tagliata dal messaggio (il file resta intero) |

In piu', per Claude Code: il **filtro dell'output dei test** (`metodo/filtro-test.py`,
agganciato da `metodo/impostazioni-runner.json` e passato con `--settings`). Il Metodo fa
girare tutti i test a ogni blocco; il filtro fa arrivare all'agente le righe di fallimento
e il riepilogo, e mette il resto in un file di cui stampa il percorso.

**Regola di sicurezza del filtro, non negoziabile**: puo' solo mostrare MENO output, mai
cambiare l'esito. Il codice di uscita passa intatto, le righe di fallimento passano sempre,
e davanti a qualunque dubbio (comando non riconosciuto, gia' composto con pipe o `&&`) non
tocca niente. Il caso peggiore e' «nessun risparmio», mai un verde falso. Le prove stanno in
`tests/test_filtro_test.sh` e sono la ragione per cui questo pezzo e' ammesso nel Metodo.

## Il contatore: il Metodo si guarda lavorare

Da 2026-08-12 il runner **registra quanto consuma ogni blocco**. Non risparmia niente da
solo: serve a non tirare piu' a indovinare. Prima di lui ogni leva era pesata a mano una
volta sola, e **due stime su tre si sono rivelate sbagliate** appena misurate.

Il conto arriva dall'agente stesso (`claude -p --output-format json`, letto da
`metodo/leggi-conto.py`) e compare in quattro posti:

| Dove | Cosa si vede |
|---|---|
| All'inizio della corsa | progetto, motore, modello, **quanti blocchi sono previsti** e perche' la corsa finira' |
| A ogni blocco | a che punto siamo del percorso previsto, e quanto si e' speso finora |
| A fine blocco | token e costo di quel blocco, nel registro e in `docs/diario/session-log.md` |
| A fine corsa | totale, media a blocco, modello che ha lavorato |

**Il costo e' quello a listino calcolato dal programma**: con l'abbonamento non e' un
addebito, e' il valore di cio' che si e' consumato. Va detto cosi' anche a Villa.

**A cosa serve davvero** (oltre a vedere la spesa): un blocco che costa **tre volte la
mediana della sua fase** quasi sempre conteneva due lavori invece di uno, o ha mandato
l'agente a girare a vuoto. Il conto diventa un modo per scoprire i blocchi tagliati male —
si guardano i tre piu' cari a fine fase e ci si chiede perche'. Non e' una regola di
risparmio: e' la regola del sizing (cap. 10) che finalmente ha un termometro.

Se l'uscita dell'agente non e' leggibile (un altro programma, una sessione uccisa dal cane
da guardia, un errore) non si inventa niente: il conto resta vuoto e nel registro finisce
tutto com'era. Prove: `tests/test_contatore.sh`.

## Una cosa che sta fuori dal Metodo, ma pesa sul Metodo

Il `~/.claude/CLAUDE.md` di Villa (il suo profilo, valido su tutti i progetti) entra in
memoria a ogni blocco, comprese le corse dove Villa non c'e'. Il 2026-08-11 e' stato diviso
in due: le **regole** restano li' (comprese quelle di sostanza — alleato non sottoposto, mai
stime di tempo, codice pulito), mentre citazioni, storia e motivazioni sono passate in
`~/.claude/parlare-con-villa.md`, che si apre **solo quando Villa c'e'** e un caso e' dubbio.
Nelle corse del runner non va aperto: il messaggio del blocco dice esplicitamente che e' una
sessione automatizzata. Risparmio misurato: 1.835 token per blocco.

## Come ci si accorge che il filtro sta lavorando

Nell'output dei test compare la riga `[output completo dei test: ...]`. Se non c'e', il
gancio non e' scattato: i test girano come sempre, non si e' rotto niente, semplicemente non
si sta risparmiando. Nei monorepo e' il caso normale, perche' il gancio cerca il Metodo nella
cartella di lavoro e li' si lavora dentro un modulo.

## Cosa NON si fa per risparmiare

- **Non si tagliano le regole di qualita'.** Il Metodo esiste perche' Villa non verifica il
  codice: un blocco da rifare costa piu' di dieci blocchi di preambolo.
- **Non si spargono sotto-agenti «per alleggerire»**: partono a cache fredda e col proprio
  preambolo, costano di piu' (fino a 15 volte nei sistemi multi-agente), non di meno. Sono
  una leva di qualita', e si paga.
- **Non si comprime la verifica di fine blocco.** E' l'unica rete che c'e'.
- **Non si ottimizza a occhio.** Prima si misura su una fase vera, poi si cambia, poi si
  rimisura la stessa cosa.
