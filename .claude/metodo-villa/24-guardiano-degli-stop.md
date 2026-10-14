# 24 — Il guardiano degli stop

> Cosa succede quando il runner si ferma. Motore: `metodo/metodo-guardiano.sh`.
> Prove: `tests/test_guardiano.sh`.

## Il problema

Il runner si ferma per quattro motivi: serve una decisione (CHECKPOINT), qualcosa non
funziona (ERROR), manca qualcosa che ha solo Villa (BLOCKED), la fase e' finita
(PHASE_COMPLETE). Nei primi tre casi, fino al 2026-08-12, mandava un avviso **a senso unico**
e chiudeva. Se Villa dormiva, la corsa restava ferma fino al mattino — spesso per una
decisione che si prendeva in trenta secondi.

Il canale a due sensi (`metodo/metodo-telegram.sh chiedi`) esisteva gia' ed era collaudato,
ma **il runner non lo chiamava mai**: lo usavano solo due skill, e solo se l'agente si
trovava a leggerle. Mancava il filo.

## Come funziona adesso

Quando il runner sta per fermarsi per CHECKPOINT, ERROR o BLOCKED, passa dal guardiano:

1. **Mette insieme la situazione** — diario del blocco, ultime righe del registro, il blocco
   in ballo. Senza chiamare nessun modello: sono file.
2. **Scrive a Villa** nella sezione Telegram del progetto e **aspetta 10 minuti**. La risposta
   puo' essere anche un vocale (trascritto in locale, l'audio non esce dal computer).
3. **Se Villa risponde**: si decide insieme. Il guardiano puo' chiedere un chiarimento e
   ricominciare ad aspettare — fino a tre scambi. **La parola di Villa vince** su qualunque
   preferenza del guardiano.
4. **Se Villa non risponde**: decide da solo, secondo le direttive qui sotto.
5. **In tutti i casi scrive cosa ha deciso**: in `docs/diario/decisioni-da-rivedere.md` (con
   il perche', il rischio e se va confermata), su Telegram, e nel riepilogo di fine corsa.
6. Se la decisione permette di andare avanti, **riscrive il diario del blocco** con le
   istruzioni per chi eseguira' il prossimo, e la corsa riparte.

## Le direttive — la parte che conta

Senza queste, «decide da solo» vuol dire «tira a indovinare». In ordine, la prima che si
applica vince:

1. **Solido, non sbrigativo.** Fra due strade, sempre la piu' professionale e duratura.
2. **Mai sopra un test rosso.** Si decide *come* riparare, mai di tirare dritto.
3. **Sicurezza e dati**: valgono le sei regole di autonomia (cap. 12), al massimo livello
   ragionevole. Se c'entra una legge, si cerca la norma e si cita.
4. **Le decisioni di prodotto e di direzione non sono sue.** Se la scelta e' di quel tipo:
   strada **reversibile** e marcata `DA_CONFERMARE`, oppure — se ogni strada e' difficile da
   annullare — **ci si ferma**.
5. **Non inventare requisiti.** Se manca un accesso, un dato, una preferenza che solo Villa
   ha: ci si ferma. Nessun ragionamento la fa comparire.
6. **Minimo indispensabile.** Si decide solo cio' che sblocca il blocco fermo.

## Dove il guardiano NON entra

- **PHASE_COMPLETE**: la fase e' finita, non c'e' niente da decidere.
- **Blocchi 👤 e 🤝 della roadmap**: sono stop **pianificati** per Villa. Scavalcarli non
  sarebbe autonomia, sarebbe un baco.
- **Loop rilevato e handoff mancante**: sono guasti del meccanismo, non decisioni.

## I freni

| Freno | Perche' |
|---|---|
| `GUARDIANO_MAX_INTERVENTI` (3) | oltre, il runner si ferma davvero: un guardiano senza tetto puo' insistere tutta la notte su una strada sbagliata |
| `GUARDIANO_GIRI_CHAT` (3) | quanti scambi al massimo quando Villa risponde |
| `GUARDIANO_ATTESA` (600 s) | quanto aspetta prima di decidere da solo |
| `GUARDIANO=no` | lo si spegne e il runner torna a fermarsi come prima |
| Se l'agente non risponde | non si inventa niente: ci si ferma |
| Se `metodo-guardiano.sh` manca | il runner lavora come prima. Meglio senza guardiano che senza runner |

## Cosa resta da fare (dichiarato, non nascosto)

Il canale conversa **allo stop**, non sempre. Una chat libera con l'agente mentre lavora —
scrivere sul telefono nel mezzo di un blocco e farsi rispondere — e' un'altra cosa: servirebbe
qualcuno in ascolto per tutta la corsa. Non c'e' e non e' previsto qui.
