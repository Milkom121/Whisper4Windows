# 22 — Agenti esecutori

## Perche' esiste questo capitolo

Il runner non fa il lavoro: lo fa fare. Lancia un programma — un **agente
esecutore** — che legge il messaggio, lavora sul progetto e se ne va.

Fino al 2026-08 quel programma era uno solo: Claude Code. Funziona bene,
ma lega il Metodo a un fornitore per tre cose che non dipendono da noi:
disponibilita', prezzo, e regole d'uso.

Questo capitolo definisce **cosa deve saper fare** un programma per poter
eseguire un blocco del Metodo, **come se ne aggiunge uno**, e **cosa
cambia** quando non si usa Claude Code.

Il Metodo non cambia in base all'agente. Cambia solo chi tiene la penna.

## Il contratto minimo

Un programma puo' fare l'agente esecutore **se e solo se** rispetta tutti
questi punti. Non sono preferenze: se ne manca uno, il runner si pianta
di notte e nessuno se ne accorge fino al mattino.

| # | Requisito | Perche' e' obbligatorio |
|---|---|---|
| 1 | **Lavora senza nessuno davanti**: riceve un messaggio, lavora, finisce | Il runner gira quando Villa dorme |
| 2 | **Legge, scrive ed esegue** dentro la cartella del progetto | Senza, non costruisce niente |
| 3 | **Sa saltare le richieste di permesso** | Alla prima domanda resterebbe fermo fino al timeout |
| 4 | **Termina da solo** quando ha finito | Il runner aspetta la sua fine per leggere l'handoff |
| 5 | **Accetta un messaggio lungo** (decine di migliaia di caratteri) | Il messaggio del Metodo contiene regole, configurazione e roadmap |
| 6 | **Scrive l'handoff nel formato del Metodo** | E' il punto che decide tutto: senza, il runner non sa piu' a che punto e' |

I primi cinque sono proprieta' del **programma**: si verificano leggendo
la sua documentazione. Il sesto e' capacita' del **modello**: si verifica
solo facendogli fare un blocco vero.

## La trappola della riga di comando

Il messaggio del Metodo e' grande: contiene le regole, la configurazione
del progetto, la roadmap intera e le istruzioni del blocco. Decine di
migliaia di caratteri, spesso oltre centomila.

Alcuni programmi vogliono il messaggio come **argomento della riga di
comando**. Li' c'e' un tetto che non si puo' alzare:

- Windows: circa **32.000 caratteri**
- Linux: circa 2 MB

Oltre quel tetto il comando non parte nemmeno: si rompe prima, con un
errore che non parla di prompt e manda fuori strada.

**C'e' una seconda trappola, e si e' presa in pieno.** Il file allegato
sembrava la via d'uscita: si passa un percorso, il programma apre il file,
niente tetti. Non e' cosi'. **OpenCode tratta l'allegato come l'uscita di
uno strumento e la tronca a 50 KB**, scrivendo in coda «Output capped at
50 KB». Non e' un errore: e' una riga di testo dentro il messaggio, che
nessuno legge.

Misurato il 2026-08-16 su Fedorium (messaggio di 250.000 caratteri):
**arrivava il 20%**. Restavano fuori il grosso della roadmap, la riga che
dice **quale blocco fare** e il **diario del blocco precedente**. Troncate
**110 consegne su 119**. L'agente non lavorava alla cieca — si accorgeva
del taglio e si rileggeva il file a pagine, arrivando al 100% — ma pagava
**5-12 giri a vuoto per blocco**, circa un decimo del tempo, ogni volta. E
gli esiti non lo dicevano: zero errori, blocchi chiusi in ordine. **Un
difetto che non si vede negli esiti si vede solo misurando.**

**Regola, senza gradini:**

1. il messaggio si passa **da standard input** (il programma lo legge come
   se glielo si versasse dentro);
2. **mai** come file allegato: chi lo tronca non lo dichiara;
3. **mai** come argomento della riga di comando.

Un programma che non accetta lo standard input **non soddisfa il contratto
minimo** e non si aggiunge. Prima di aggiungerne uno si prova cosi': gli si
manda un testo lungo (200.000 caratteri) con una parola inventata **in
fondo**, e gli si chiede di ripeterla. Se non la ripete, sta troncando.

## Gli agenti supportati

| | `claude` (default) | `opencode` |
|---|---|---|
| Cos'e' | Claude Code | agente libero, non legato a un fornitore |
| Come riceve il messaggio | standard input | standard input |
| Salta i permessi | `--dangerously-skip-permissions` | `--auto` |
| Scelta del modello | `--model NOME` | `--model fornitore/modello` |
| Fornitori | solo Anthropic | molti |
| Competenze del Metodo | le carica da solo | vanno elencate nel messaggio |

## Come si sceglie, in pratica

Due righe in `.env.runner` del progetto, scritte una volta sola:

```
METODO_AGENTE=opencode
METODO_MODELLO=fornitore/modello
```

Da quel momento il runner di quel progetto lavora cosi', anche quando lo
si lancia dal menu senza scrivere nulla. Per una prova estemporanea ci
sono `--agente NOME` e `--model NOME`, che vincono sulla configurazione.

Senza indicazioni resta `claude` col suo modello di default: **chi non fa
niente non si accorge di nulla.**

Il nome del modello e' quello che vuole **l'agente scelto**, non un nome
del Metodo: Claude Code vuole `claude-opus-5`, OpenCode vuole
`fornitore/modello`. Il Metodo non traduce e non convalida: passa la
stringa e lascia che sia il programma a lamentarsi se e' sbagliata.

**Le chiavi dei fornitori non passano dal Metodo.** Ogni agente ha il suo
modo di custodirle (OpenCode: `opencode auth login`, oppure le variabili
d'ambiente del fornitore). Il Metodo non le legge, non le scrive e non le
mette nei suoi file — cosi' non possono finire per sbaglio in un commit.

La scelta e' **per progetto**, non per blocco: cambiare programma a meta'
fase vuol dire cambiare il modo di lavorare a meta' del lavoro.

## Cosa si perde fuori da Claude Code

Le **competenze del Metodo** (`.claude/skills/`) sono file di istruzioni
che Claude Code apre da solo quando servono. Gli altri programmi non
sanno che esistono.

Il ripiego del runner: quando l'agente non le carica da solo, il messaggio
porta l'**elenco** delle competenze — nome, a cosa servono, dove stanno —
con l'istruzione di aprirle e seguirle quando pertinenti. L'agente ha gli
strumenti per leggere i file: gli basta sapere che ci sono.

Funziona, ma non e' identico: dipende dall'agente che si ricordi di
aprirle. E' il primo posto dove guardare se un blocco eseguito da un
agente diverso viene peggio del solito.

## Quanto ha consumato, qualunque motore sia (2026-08-16)

Il contatore del runner chiedeva il conto solo a Claude Code. Con OpenCode
non lo chiedeva nemmeno: per Kimi e GLM il consumo risultava **zero**, e
meta' del quadro della corsa era cieca proprio sui motori che
l'instradamento usa di piu'.

I due programmi dicono le stesse cose in due forme diverse:

| | Claude Code | OpenCode |
|---|---|---|
| come si chiede | `--output-format json` | `--format json` |
| cosa torna | un oggetto solo, con dentro tutto | un evento per riga |
| dove sta il conto | `usage` + `total_cost_usd` | negli eventi di **fine passo** |
| il modello | lo dice lui (quello che ha davvero lavorato) | non lo dice: lo sa chi lo ha lanciato |

Tre cose da sapere, tutte imparate sbattendoci contro:

- **I passi si sommano.** Un blocco vero fa decine di giri di attrezzi, e
  ogni giro chiude un passo con il suo conto. Prendere l'ultimo vuol dire
  contare l'ultimo respiro di una corsa lunga.
- **Un blocco andato liscio in un colpo lascia una riga sola**, che come
  oggetto si legge benissimo — e verrebbe scambiata per un'uscita di Claude
  Code senza conto, cioe' per zero. Il segno che distingue e' la `part`: gli
  eventi ce l'hanno tutti, l'uscita di Claude Code non ce l'ha mai.
- **I prezzi non si scrivono nel Metodo.** Quando OpenCode non mette il
  costo negli eventi, si legge il suo stesso listino
  (`~/.cache/opencode/models.json`, dollari per milione di token). Un
  listino scritto a mano invecchierebbe in silenzio. Se il modello li' non
  c'e', il costo resta zero e i token si contano lo stesso: meglio nessun
  numero che uno inventato.

Con un **abbonamento a quota fissa** (i piani "coding plan") il listino e'
zero davvero: non c'e' nessun addebito per blocco, e il numero che conta e'
quello dei token. Quanta quota resti e' un'altra domanda, e ha un suo
strumento a parte.

## Perche' il "traduttore" e' scartato

Esiste un'altra strada: mettere davanti a Claude Code un **traduttore**
(gateway) che gira le richieste a un altro modello. Tecnicamente funziona,
e prodotti come LiteLLM o Bifrost lo fanno.

E' stata **scartata come fondamenta**, per una ragione sola ma decisiva:
la documentazione di Anthropic dichiara che non e' supportato instradare
Claude Code verso modelli non-Claude attraverso nessun gateway. Vuol dire
che ogni aggiornamento di Claude Code puo' romperlo, e non c'e' nessuno a
cui chiedere.

Va benissimo per **un esperimento**. Non per il sistema su cui poggiano
tutti i progetti.

## Un posto solo sa quali programmi esistono

La scelta del programma vive in `metodo/metodo-agente.sh`, caricato da chi deve far
lavorare un agente: il runner (per i blocchi) e lo strumento delle corsie (per il
**Consiglio degli Agenti**).

Non e' un vezzo di ordine. Prima la scelta viveva solo nel runner, e il Consiglio
chiamava Claude Code a prescindere: un progetto che aveva scelto un altro programma se
lo ritrovava scavalcato **senza accorgersene, e senza sapere che stava spendendo
altrove**. Difetto trovato sul campo il 2026-08-10, mentre girava un Consiglio vero.

Regola che ne deriva: **se un pezzo del Metodo fa lavorare un agente, deve passare da
li'.** Nessun altro file nomina `claude` o `opencode`.

## Come si aggiunge un agente nuovo

1. **Verifica il contratto** sulla sua documentazione, punto per punto.
   Se cade il punto 1 o il 3, si scarta subito: non c'e' rimedio.
2. **Aggiungi il suo caso** ad `avvia_agente()` in `metodo/metodo-agente.sh`. E' l'unico
   punto del Metodo che sa quali agenti esistono.
3. **Aggiungi le prove**: come si costruisce il comando, cosa succede se
   il programma non e' installato.
4. **Fagli fare un blocco vero** e guarda l'handoff. Il punto 6 del
   contratto si verifica solo cosi'.

## Chi decide

| Decisione | Chi |
|---|---|
| Quale agente usa un progetto | **Villa** (`METODO_AGENTE` in `.env.runner`) |
| Se un agente nuovo rispetta il contratto | Chi lo aggiunge, sulla documentazione |
| Se un agente e' abbastanza bravo | Solo una prova con un blocco vero |

Il Metodo resta identico qualunque sia l'agente. Se per far funzionare un
agente bisogna cambiare le regole del Metodo, quell'agente non va bene.

## Scegliere il modello quando si lancia (2026-08-12)

Dal menu (`runner.bat`, voce **11**) si sceglie chi esegue i blocchi di **questa** corsa —
Claude Code, OpenCode, o quello che il progetto ha gia' scelto — senza toccare la
configurazione. Con OpenCode si sceglie anche il modello, e si vedono **soltanto i modelli
dei fornitori per cui OpenCode ha una credenziale registrata**: il catalogo ne elenca
centinaia, e sceglierne uno senza chiave vuol dire lanciare una corsa che muore al primo
blocco.

Nemmeno i modelli `opencode/...` fanno eccezione, benche' il catalogo li dia per gratuiti:
senza `opencode providers login` non partono. Il giorno in cui quell'accesso viene fatto,
compaiono da soli — non c'e' niente da aggiornare a mano.

Motore: `metodo/metodo-modelli.sh` (`fornitori` / `modelli <fornitore>`).
Prove: `tests/test_modelli.sh`.

## Quanto il modello si impegna (2026-08-15)

I modelli moderni hanno una manopola: quanto pensare prima di rispondere.
Pensare di piu' costa di piu' e serve solo dove il problema lo merita.

Si imposta con `--impegno`, o una volta per tutte con `METODO_IMPEGNO` in
`.env.runner`. I livelli sono **low, medium, high, max**; il **default e'
`high`**, che e' la scelta di Villa: sopra si spende molto per guadagnare
poco.

I due programmi la chiamano in modo diverso — Claude Code `--effort`,
OpenCode `--variant` — e il livello piu' basso ha due nomi (`low` di qua,
`minimal` di la'). E' **l'unico punto in cui il Metodo traduce**, e
traduce un livello, non un identificativo di modello.

**L'impegno si convalida.** Non e' pignoleria: OpenCode accetta in
silenzio anche una variante inventata (provato: `--variant pippo` non da'
nessun errore). Senza il controllo, un impegno scritto male girerebbe per
giorni al livello di default e nessuno lo saprebbe.

Misura del 2026-08-15 su GLM-5.3, stesso problema: a impegno minimo
ragiona 305 unita', ad alto 800. Il livello `max` su quel modello non e'
mappato e non cambia niente.

## Le decisioni che contano non passano dal motore di corsa

Il guardiano degli stop e il Consiglio degli Agenti **non** usano il
programma scelto dal progetto: usano **Claude Opus 5**, sempre.

Il motivo e' lo stesso che regge tutto il capitolo: quelle decisioni
nessun test le controlla, si prendono di notte senza nessuno davanti, e
sbagliarle si propaga a tutto il lavoro che viene dopo.

Prima del 2026-08-15 non era cosi': un progetto con `METODO_AGENTE=opencode`
faceva decidere quelle cose al suo modello di corsa. Nessuno l'aveva
deciso e nessuno se n'era accorto.

Meccanica: `con_la_testa()` in `metodo/metodo-agente.sh`. Se il programma
della testa non e' installato si prosegue col motore del progetto — meglio
una decisione presa da un modello meno bravo che una corsa che non parte.

## Un motore per ogni peso di blocco (l'instradamento)

Il criterio non e' "difficile o facile". E': **chi si accorge se il
modello sbaglia?**

| Peso | Cosa ci sta dentro | Chi se ne accorge | Chi lavora |
|---|---|---|---|
| 🔴 **cruciale** | architettura, schema dei dati, sicurezza, blocchi da cui dipende il resto | nessuno subito: si scopre fra due settimane, e intanto tutto il lavoro dopo e' storto | **Claude Opus 5** |
| 🟡 **importante** | schermate nuove, ridisegni, testi che legge un utente | solo un occhio umano: i test passano lo stesso e il risultato e' brutto | **Kimi K3** |
| 🟢 **ordinario** | codice di routine, backend, test, documentazione, configurazione | un test automatico, subito | **GLM 5.3** |

**Come si scrive**: l'emoji accanto a quella della natura, nella riga del
blocco o nella sua intestazione — `### Blocco 4.2 — Schema ordini 🤖 🔴`.
Vale anche la parola scritta (`cruciale`, `importante`, `ordinario`): le
roadmap le scrivono anche i modelli, e farsi capire costa meno che farsi
ubbidire.

**Chi mette i pesi**: il **pianificatore**, insieme all'etichetta di
natura, prima che il runner parta. Non l'esecutore — vale la stessa regola
del sizing (sez. 3bis del file operativo).

**Come si accende**: `--ottimizza` per una corsa, `METODO_OTTIMIZZA=si`
per fissarlo su un progetto. **Spento non cambia niente.** E anche acceso,
un blocco senza peso scritto resta al motore della corsa: nessuna roadmap
scritta prima di oggi cambia comportamento.

**Scegliere il modello a mano spegne l'instradamento**, e il runner lo
dice. Sono due modi alternativi di decidere chi lavora, mai sovrapposti:
cosi' leggendo il registro si capisce sempre perche' un blocco e' finito
su un motore invece che su un altro.

**L'errore promuove.** Un blocco che torna una seconda volta sale di un
gradino: ordinario → importante → cruciale. Rifarlo con lo stesso motore
che l'ha appena sbagliato e' il modo piu' rapido di sbagliarlo di nuovo.
Sopra "cruciale" non c'e' niente: si resta li'.

**La mappa peso → motore vive in un posto solo** (`MOTORE_*` in
`metodo/metodo-agente.sh`) e **non e' configurabile per progetto**. Se ogni
progetto avesse la sua, fra sei mesi nessuno saprebbe piu' dire perche' un
blocco e' finito dove e' finito.

### Il punto debole, dichiarato

Il valore di tutto questo dipende dalla **qualita' delle etichette**, non
dal codice che le legge — che e' banale. Un blocco etichettato 🟢 che in
realta' era 🔴 finisce al motore economico, fallisce, e sveglia il
guardiano. La promozione lo recupera, ma al prezzo di due corse buttate.

Percio': **nella roadmap entra una sola etichetta nuova, il peso, con tre
valori.** Se un giorno servissero anche il modello esatto e l'impegno per
blocco, chi pianifica passerebbe piu' tempo a compilare che a pensare, e
le etichette diventerebbero rumore che nessuno legge.

## Quanto manca a QUESTA corsa (2026-08-15)

Il quadro di partenza dice tre cose, e l'ultima e' quella che risponde
alla domanda vera:

```
Roadmap  : 150 in tutto · 96 fatti · 54 da fare  (tutto il progetto, non questa corsa)
Fase 13  : 30 in tutto · 18 fatti · 12 da fare
QUESTA CORSA: 5 blocchi, poi si tocca il tetto di sicurezza (5)
```

Il difetto riparato: la previsione contava i blocchi rimasti in roadmap
**ignorando il tetto** (`--max-blocks`). Numero vero, domanda sbagliata —
e un annuncio che risponde a un'altra domanda e' peggio di nessun
annuncio, perche' si smette di leggerlo.
