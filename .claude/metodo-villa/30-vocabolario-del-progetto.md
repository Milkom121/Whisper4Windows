# 30 — Il vocabolario del progetto

## Perche' esiste

Ogni blocco riparte da capo. Cosi' la stessa cosa finisce per chiamarsi **ospite**
in un blocco, **paziente** in quello dopo e **utente** nel terzo — nel codice, nelle
schermate e nei messaggi. Nessuno sbaglia niente di grave, e intanto il prodotto
parla tre lingue.

Su di noi vale doppio: **Villa non legge il codice**. Le parole che gli arrivano
**sono** il contratto. Se la parola cambia, cambia la cosa che lui crede di aver
deciso.

## Quando NON si adotta

**Solo dove il dominio ha un lessico proprio** — sanita', finanza, edilizia,
legale, logistica. Su un progetto tecnico (uno strumento, una libreria, un motore)
il vocabolario e' zavorra: un file in piu' che si carica a ogni blocco della corsa
e che non risolve niente, perche' li' le parole sono gia' quelle del mestiere di
chi scrive il codice.

Nel dubbio: se Villa e un esperto del settore userebbero parole che un programmatore
non conosce, serve. Altrimenti no.

## Cosa contiene

`docs/fondamenta/vocabolario.md`, **venti termini circa, due righe l'uno**. Sta in
una schermata, o non lo legge nessuno.

```markdown
| Parola | Cosa vuol dire | Da non usare |
|---|---|---|
| **Ospite** | La persona che vive nella struttura. Non e' un paziente: il rapporto e' di residenza, non di cura. | paziente, utente, cliente |
| **Presa in carico** | Il momento in cui un ospite entra e gli viene assegnato un referente. | ammissione, ingresso, apertura pratica |
```

**Solo termini del dominio.** Fuori i concetti di programmazione: qui non stanno
«coda», «cache», «repository». Il vocabolario **non e' una specifica** e non
contiene decisioni tecniche — quelle vivono in `decisions.md`.

**La colonna delle parole vietate e' la meta' che fa il lavoro.** Quando per la
stessa cosa esistono tre parole, se ne sceglie una e **si bandiscono le altre**:
senza il divieto scritto, la parola scartata rientra al terzo blocco.

## Si aggiorna nell'istante in cui la parola si decide

Non a fine sessione, non a fine fase: **nel momento in cui si sceglie**. Una parola
decisa e non scritta e' persa — chi apre il blocco dopo non c'era.

## Quando si ferma Villa, e quando no

Se Villa usa un termine che contraddice il vocabolario, l'agente lo ferma **solo
quando l'ambiguita' cambia cosa viene costruito**:

> «Hai detto *ospite*, ma il vocabolario dice *paziente*: sono due cose diverse nel
> modello dei dati. Quale dei due intendi?»

Se il senso e' chiaro dal contesto, **non si interrompe**: si va avanti e nel
proprio testo si usa la parola del vocabolario. Un agente che corregge il lessico a
ogni frase e' fastidioso e rallenta le decisioni, che sono la cosa per cui Villa e'
li'.

## Chi lo scrive e chi lo usa

- **Nasce** nella `discovery`, dove le parole del cliente si sentono per la prima
  volta.
- **Cresce** a ogni blocco che decide una parola nuova (lo chiede la
  `chiusura-blocco`).
- **Si usa** quando si scrivono nomi nel codice, testi a schermo, messaggi d'errore
  e le righe che legge Villa.
