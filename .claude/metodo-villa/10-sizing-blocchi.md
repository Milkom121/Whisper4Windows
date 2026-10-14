# Sizing dei blocchi

> Questo capitolo e' il **primo riscritto in positivo** (2026-08-19): dice il
> comportamento voluto invece del comportamento vietato. Il criterio, il confronto
> prima/dopo e cosa resta scritto come divieto stanno in
> `docs/fondamenta/come-e-scritto-il-metodo.md`.

## La regola fondamentale

**Un blocco = una modifica coerente con UNA SOLA verifica.**

La dimensione la calibra **chi scrive la ROADMAP**, in fase di pianificazione: e'
una scelta tecnica del pianificatore, e resta sua.

## Test di applicazione

Prima di scrivere un blocco, chiediti:

> "Per chiudere questo blocco, quante suite di verifica diverse devo eseguire?"

- **1 suite** (es. solo pytest backend, oppure solo typecheck frontend, oppure
  solo smoke manuale di un flusso): blocco unico, OK.
- **2+ suite** (es. pytest backend + Playwright frontend + smoke manuale):
  spezzare in N blocchi, uno per suite di verifica.

## Esempio di sizing sbagliato (caso scuola)

Blocco "streaming SSE chat" che combinava in un solo blocco:
- (a) endpoint backend + test L1 backend
- (b) consumer frontend
- (c) verifica E2E completa

Tre verifiche diverse: erano tre blocchi.

**Conseguenze del sizing sbagliato osservate**:
- Tempo di esecuzione lungo (50+ minuti).
- Debugging difficile: quando una sola delle 3 verifiche fallisce, devi
  ricostruire mentalmente quale dei 3 strati ha problemi.
- Atomicita persa: chiudendo a meta resta ignoto cosa e' davvero pronto.
- Recovery dagli errori penoso: rollback parziale impossibile.

## Perche' la regola e' permanente

Blocchi grandi distruggono i vantaggi del Metodo Villa:
- **Atomicita** — un blocco e' o tutto fatto o tutto da rifare.
- **Controllabilita** — sai esattamente cosa cambia nel mondo dopo un blocco.
- **Recovery puntuale** — se qualcosa va storto, riparti dal blocco esatto.
- **Costo runner** — ogni blocco ha overhead fisso (~5-10 min di check
  ambiente); blocchi che richiedono 2+ verifiche diventano 30+ minuti solo
  di overhead.

## Chi calibra i blocchi

Il **pianificatore** (chi scrive la ROADMAP). L'**esecutore** prende il blocco
cosi com'e' scritto e lo completa; se lo trova mal calibrato lo segnala in
`handoff.md`, e la divisione la fa il pianificatore alla prossima passata.

## Che aspetto ha un blocco ben tagliato

Ognuno di questi era un lavoro solo, ed e' diventato piu' blocchi:

| Lavoro grande | I blocchi che ne escono |
|---|---|
| "Refactor del modulo X" | uno per area toccata |
| "Implementa autenticazione" | schema utenti · registrazione · login · reset password · sessioni |
| "Setup ambiente di sviluppo" | deps backend · deps frontend · configurazione DB · seed dati iniziali |
| "Sistema di notifiche end-to-end" | schema · endpoint emit · consumer · UI badge |

La forma si riconosce a occhio: un blocco nomina **una cosa che si puo' verificare
da sola**, non un'area di lavoro.

## Dimensione orientativa

La soglia non e' in righe di codice. Un blocco tipico:
- Tocca da 1 a 5 file principali (+ test).
- Si completa in una sessione di lavoro.
- Ha **un solo** comando di verifica che decide "passato / non passato".
- Produce un risultato concretamente dimostrabile (test verde, schermata
  che funziona, endpoint che risponde).

Quando il taglio non e' ovvio: dividi a meta e guarda se le due meta hanno senso da
sole. Di solito si.
