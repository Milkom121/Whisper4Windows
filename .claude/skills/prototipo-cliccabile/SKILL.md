---
name: prototipo-cliccabile
description: "Skill operativa per far DECIDERE VILLA PRIMA che il codice esista: si costruisce una paginetta che lui apre col doppio clic, coi bottoni scritti nella lingua del mestiere, lo stato sempre a vista e gli scenari scomodi gia' pronti da provare. Serve quando una REGOLA del dominio e' in dubbio (quando una pratica si puo' chiudere, cosa succede se due documenti si contraddicono, come si calcola una tariffa, chi puo' fare cosa): invece di descriverla a parole o costruirla e poi rifarla, Villa la prova cliccando e dice se e' giusta. Il prototipo e' usa e getta dal primo minuto; la logica sta in un file separato, cosi' quando la risposta arriva quel pezzo si solleva e va nel codice vero e la pagina si butta. Usa questa skill quando si menziona: prototipo, provare una regola prima di costruirla, «fammi vedere come funzionerebbe», dubbio su una regola di dominio, simulare un comportamento, spike su una decisione, «non sono sicuro che questa regola sia giusta». Distinta da: `progettazione-ux` (progetta le SCHERMATE e i percorsi; questa prova le REGOLE), `seeding-visivo-web` (fa il frontend vero e bello; questa fa un foglio grezzo che si butta). English triggers: clickable prototype, decision spike, try the rule before building it."
user-invocable: true
---

# Il prototipo che Villa clicca

Un prototipo qui risponde a **una domanda sola**, e la domanda e' quasi sempre di
questa forma: *«questa regola, quando la usi davvero, e' giusta?»*.

Villa non legge il codice. Descritta a parole, una regola sembra sempre sensata;
cliccata, si scopre in trenta secondi che nel caso scomodo fa una cosa che nessuno
voleva. **Il momento utile e' quando lui dice «aspetta, questo non dovrebbe essere
possibile».**

## Quando serve (e quando no)

| Situazione | Cosa fare |
|---|---|
| Una regola del mestiere e' in dubbio, e sbagliarla costa | **prototipo** |
| Il dubbio e' su **come appare** o su quali schermate servono | `progettazione-ux` |
| Il dubbio e' tecnico (regge il carico? questa libreria funziona?) | uno spike normale, non questa skill |
| La regola e' chiara e nessuno ha dubbi | si costruisce, senza prototipo |

## Come si costruisce, in concreto

Si copia il modello e si toccano **due soli file**:

```bash
cp -r metodo/modelli/prototipo docs/diario/prototipo-<nome>
```

1. **`regole.js`** — la logica, che non sa niente della pagina (niente `document`,
   niente bottoni, niente colori). Ogni regola prende lo stato e restituisce
   `{ stato, permesso, dice }`.
2. **`CONFIGURAZIONE`**, in fondo a `pagina.html` — l'elenco dei **gesti** e degli
   **scenari**.

Tutto il resto (impaginazione, diario, stato a vista, tema chiaro e scuro) c'e'
gia' e **non si riscrive**: se ogni prototipo viene diverso, Villa deve reimparare
ogni volta dove guardare.

Poi: doppio clic su `pagina.html`. Nessun programma da installare, nessun servizio
da avviare.

## Le quattro regole che lo rendono utile

**1. I bottoni parlano la lingua del mestiere.** «Consegna la relazione», non
«submit». «Segnala una prova che non regge», non «setFlag». Chi decide deve
riconoscere i gesti, altrimenti clicca a caso.

**2. Lo stato e' sempre a vista.** Un prototipo in cui non si vede cosa e'
cambiato non fa decidere niente: fa solo vedere che i bottoni funzionano.

**3. Gli scenari mostrano i casi SCOMODI, non quello felice.** Il caso felice non
insegna niente a nessuno. Si preparano da due a quattro percorsi che mettono la
regola in difficolta': il dato che manca, i due documenti che si contraddicono, la
persona che non dovrebbe poter fare quella cosa, il limite superato di uno.
**Ogni passo di uno scenario porta il suo nome**, cosi' il diario si legge senza
tornare al codice.

**4. La logica sta fuori dalla pagina.** Quando la risposta arriva, `regole.js` si
solleva e va nel codice vero; la pagina si butta. Se la logica finisse dentro la
pagina, il lavoro si rifarebbe da capo — e allora tanto valeva costruire subito.

## Cosa fare dopo

- **La regola era giusta**: `regole.js` diventa il punto di partenza del codice
  vero (la forma cambia, la sostanza no), e la decisione si scrive in
  `docs/diario/decisions.md`.
- **La regola era sbagliata**: si e' scoperto prima di costruire, che era lo scopo.
  Si annota **cosa** non andava — quello vale piu' del prototipo.
- **In tutti e due i casi**: il prototipo si butta. E' usa e getta dal primo
  minuto, e conservarlo crea una seconda verita' che diverge dal codice vero.

## Anti-pattern

- **Farlo bello.** Non e' il prodotto: e' un foglio su cui provare una regola. Il
  bello lo fanno le skill di seeding, dopo, sul codice vero.
- **Metterci dentro tutta l'applicazione.** Una domanda, un prototipo.
- **Tenerlo.** Vedi sopra: due verita' che divergono.
- **Mostrare solo il caso felice.** E' il modo piu' rapido di far approvare una
  regola sbagliata.
- **Chiedere a Villa di installare qualcosa** per aprirlo. Doppio clic, o non
  serve a niente.
