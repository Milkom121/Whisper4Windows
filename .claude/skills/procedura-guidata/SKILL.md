---
name: procedura-guidata
description: "Skill operativa per SCRIVERE LE TAPPE di una procedura guidata: il percorso passo-passo che accompagna Villa (o un tecnico) dentro un blocco 👤 UMANO — quelle cose che il runner non puo' fare da solo perche' richiedono una persona davanti (prendere una chiave da un fornitore, configurare un dominio, accendere un servizio, un accesso protetto da messaggio sul telefono). L'agente scrive SOLO le tappe; l'impaginazione, il conteggio «tappa 3 di 7», le conferme prima di cio' che non si torna indietro, la raccolta dei valori e il registro li fa gia' `metodo/procedura-guidata.sh`. Usa questa skill quando: si pianifica un blocco 👤 UMANO e va scritto come si esegue, «scrivi la procedura per…», «guidami passo passo a configurare X», «cosa devo fare io a mano», il runner si e' fermato su un blocco umano e Villa chiede da dove si comincia. Complementare a: `chiusura-blocco` (chiude un blocco), `collaudo-guidato` (fa provare il prodotto all'umano e raccoglie i difetti — li' l'umano esplora, qui l'umano esegue un percorso deciso). English triggers: guided procedure, step-by-step runbook for a human block, walk me through the manual setup."
user-invocable: true
---

# Procedura guidata — le tappe che accompagnano una persona

Questa competenza esegue la regola del capitolo
`.claude/metodo-villa/14-sequencing-blocchi.md`, sezione «La procedura guidata».
Il capitolo dice **cosa** e **perche'**; qui c'e' il **come si scrive**.

## Il principio: tu scrivi le tappe, l'impaginazione c'e' gia'

Il modello `metodo/procedura-guidata.sh` fa gia' tutto cio' che si ripete: schermo
pulito a ogni tappa, «tappa 3 di 7», la conferma prima di cio' che non si torna
indietro, la raccolta del valore, la scrittura nel file giusto, il registro.

**Non riscrivere niente di tutto questo.** Se scrivi la tua impaginazione, la
prossima procedura verra' diversa e Villa dovra' reimparare dove guardare.
Tu produci un file di tappe, e basta.

## Il file di tappe

Una tappa per blocco, blocchi separati da una riga con `---`:

```
TAPPA: Prendere la chiave del fornitore
DOVE: https://esempio.it/chiavi
FAI: Premi «Crea nuova chiave» e copia quella che compare
RIPORTA: la chiave (segreto)
SCRIVI: .env.runner CHIAVE_FORNITORE
---
TAPPA: Spegnere il servizio vecchio
DOVE: pannello del fornitore, sezione Servizi
FAI: Premi «Termina» sul servizio vecchio
CONFERMA: il servizio vecchio verra' spento e non si riaccende
```

| Campo | Obbligatorio | A cosa serve |
|---|---|---|
| `TAPPA` | si' | il titolo, cosi' Villa sa cosa sta facendo |
| `DOVE` | quasi sempre | l'indirizzo esatto o il comando esatto. **Mai** «vai nelle impostazioni» |
| `FAI` | si' | il gesto concreto, col nome del bottone come si legge a schermo |
| `RIPORTA` | se c'e' un valore | cosa si copia. Aggiungi `(segreto)` per chiavi e parole d'ordine |
| `SCRIVI` | se c'e' un valore | `<file> <NOME>`: dove finisce, senza che Villa apra niente |
| `CONFERMA` | per cio' che non si torna indietro | la frase che spiega cosa sta per succedere |

Si lancia cosi', e il resto lo fa il modello:

```bash
bash metodo/procedura-guidata.sh docs/diario/tappe-<nome>.txt
```

## Le quattro regole per scriverle bene

**1. Non inventare i passi.** Se non sai davvero com'e' fatta oggi quella
schermata, **dillo e chiedi**: «non so se il bottone si chiama ancora *Crea
chiave* — me lo confermi?». Un clic inventato non fa perdere tempo: manda a fare
la cosa sbagliata chi si fida di te. Vale doppio per i pannelli dei fornitori,
che cambiano senza avvisare.

**2. `CONFERMA` su tutto cio' che non si torna indietro.** Cancellare, spegnere,
pubblicare, pagare, mandare un messaggio a qualcuno. Nel dubbio, mettila: una
conferma di troppo costa un invio, una di meno costa un guaio.

**3. `(segreto)` su ogni chiave, gettone o parola d'ordine.** Il modello smette
di mostrarla a schermo e nel registro scrive solo il nome. Senza quella parola il
valore resta scritto in un file che nessuno sorveglia piu'.

**4. Una tappa = un gesto.** Se una tappa contiene «e poi», sono due tappe. Il
conteggio serve a Villa per sapere quanto manca: con tappe doppie mente.

## Quando si butta e quando si tiene

**Effimera per default**: scritta per una corsa sola, poi si butta con il file di
tappe. Le procedure conservate invecchiano insieme alle schermate dei fornitori,
e una procedura vecchia e' peggio di nessuna procedura.

**Si tiene** solo un percorso che si ripete davvero — l'installazione di un
cliente nuovo, il rinnovo annuale di un certificato. Allora il file di tappe entra
in `metodo/` col suo nome e viene rivisto quando lo si usa.

## Dove finisce il lavoro

- File di tappe in `docs/diario/tappe-<nome>.txt` (effimero) o in `metodo/` (se si tiene).
- Nel blocco 👤 della roadmap, una riga che dice come si lancia.
- Se durante la scrittura scopri che un passo non lo sai: **la domanda a Villa**, non
  un passo inventato.
