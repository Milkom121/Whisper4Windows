---
name: aggiorna-dal-metodo
description: Skill per lo SCARICO intelligente degli aggiornamenti del Metodo Villa dal repository madre (Metodo-Villa-UFFICIALE) DENTRO il progetto in cui si lavora. E' la meta' "leggera" del sistema di sync (cap. 19), ma con una testa intorno al motore meccanico: PRIMA dello scarico rileva situazioni che richiedono giudizio (un file del Metodo modificato in locale che si rischia di perdere, una skill di dominio del progetto da proteggere, un CLAUDE.md anomalo); DOPO lo scarico spiega in linguaggio umano cosa e' cambiato e se serve un'azione. Il copiare resta meccanico e prevedibile (metodo/metodo-sync.sh scarica); questa skill aggiunge comprensione del contesto solo quando serve, restando leggera nel caso normale. Le incongruenze che non si risolvono in modo agevole NON si decidono da soli: si presentano a Villa UNA ALLA VOLTA, stile discovery (regola 1bis del Metodo). Usala quando: "aggiorna il metodo", "scarica gli aggiornamenti del metodo", "allinea il progetto al metodo villa", "porta le novita' del metodo", "sincronizza dal metodo madre". English: pull method updates into the project, sync down from mother method.
---

# Aggiorna dal Metodo (scarico intelligente)

## A cosa serve

Portare nel progetto gli aggiornamenti del **Metodo** dalla madre, **senza toccare** il
codice/roadmap/config del progetto. E' l'operazione **piu' frequente** del sistema di sync,
quindi il suo cuore — il copiare i file — deve restare **meccanico e prevedibile** (come un
bancomat). Questa skill ci mette la **testa solo dove serve**: prima, dopo, e nei casi strani.

## Principi

- **Il motore resta meccanico**: il copiare lo fa `metodo/metodo-sync.sh scarica`. Non ci
  si mette "creativita'" dentro: e' un'operazione di routine, dev'essere sempre uguale.
- **Mai toccare il progetto**: lo scarico agisce solo sui file del Metodo (lista bianca).
- **Reversibile**: non si committa in automatico; Villa rivede il `git diff` e decide.
- **Leggera quando non serve**: se non c'e' nulla di speciale, la skill fa poco — scarica e
  riassume ("fatto, queste le novita', nessuna azione richiesta").
- **Incongruenze non banali -> a Villa, UNA ALLA VOLTA** (vedi sezione dedicata).

## Flusso

### 1. Pre-check con la testa (prima di copiare)
Prima di lanciare il motore, guarda il contesto e cerca le situazioni che richiedono giudizio:
- **File del Metodo modificati in locale**: c'e' una modifica a un file del Metodo dentro il
  progetto? Rischio di sovrascriverla. Capisci se e' (a) una miglioria da **rimandare** prima
  (vedi skill `rimanda-al-metodo`), (b) una **divergenza voluta** da mettere in
  `.metodo-sync-ignore`, (c) roba da buttare. NON sovrascrivere alla cieca.
- **Skill/file di dominio del progetto** sotto `.claude/skills/` non dichiarati: riconoscili
  e proponi di aggiungerli a `.metodo-sync-ignore`, cosi' non vengono toccati ne' rimandati.
- **CLAUDE.md anomalo** (manca/raddoppia la riga di separazione): non forzare; capisci la
  situazione e, se non e' ovvia, chiedi (vedi sezione incongruenze).

### 2. Scarico (motore meccanico)
Lancia `metodo/metodo-sync.sh scarica`. Copia i file del Metodo (saltando le eccezioni),
avvisa sui file modificati, segnala gli orfani, non committa.

### 3. Post-check con la testa (dopo aver copiato)

**Prima cosa: la configurazione del canale Telegram, che il motore non tocca mai.**
Esiste una configurazione condivisa da tutti i progetti (`~/.metodo-villa/condivisa.env`)
con il bot e il gruppo. Il `.env.runner` del progetto **vince** su quella: una riga
vecchia li' dentro continua a mandare le notifiche dove non vuoi piu', in silenzio.
Quindi, se la configurazione condivisa esiste, confronta:

| Nel `.env.runner` del progetto | Cosa fare |
|---|---|
| `TELEGRAM_CHAT_ID` = una chat privata (numero positivo) mentre la condivisa punta a un gruppo (negativo) | **Segnalalo**: le notifiche di questo progetto finiscono nella chat privata invece che nella sua sezione del gruppo. Proponi di togliere la riga: il progetto eredita il gruppo e si crea da solo la sua sezione al primo messaggio. |
| `TELEGRAM_BOT_TOKEN` uguale a quello condiviso | Riga inutile e duplicata: proponi di toglierla (il gettone si rigenera in un posto solo). |
| `TELEGRAM_CHAT_ID`/`TELEGRAM_BOT_TOKEN` **diversi** dai condivisi | E' un'eccezione voluta: **non toccare**, e dillo a Villa in una riga. |
| `TELEGRAM_TOPIC_ID` valorizzato | E' la sezione di questo progetto: **non si tocca mai**. |

Non farlo di nascosto e non farlo a metà: o si toglie la riga e si verifica con
`./metodo/metodo-telegram.sh stato`, o si lascia com'e'.

Poi, non lasciare Villa davanti a un elenco tecnico. **Spiega in linguaggio umano**:
- cosa e' arrivato di nuovo (le novita' del Metodo, a parole);
- se qualcuna **richiede un'azione** nel progetto (es. una nuova regola che cambia come si fa
  qualcosa) oppure no;
- poi Villa rivede e committa (o gli prepari tu il commit dei soli file Metodo, se te lo chiede).

## Gestione delle incongruenze (UNA ALLA VOLTA, stile discovery)

Se emergono problemi o incongruenze che **non si risolvono in modo agevole e ovvio** (es: una
modifica locale preziosa che cozza con la versione della madre; un'anomalia che il motore non
sa gestire; una scelta tra alternative che cambia il risultato), allora:

- **NON decidere da solo** (non e' una decisione banale/operativa) e **NON ammucchiare** i
  problemi in un unico messaggio.
- Raccogli l'elenco, poi presentane **uno alla volta** a Villa, nello stile della skill
  `discovery` e della regola 1bis del Metodo:
  1. **contatore** — "Incongruenza 2 di N";
  2. **cosa e' successo e perche' conta** — breve, in linguaggio umano;
  3. **2-3 opzioni descritte a parole**, con la **raccomandazione di Claude**;
  4. **attendi la risposta** prima di passare alla successiva.
- Le incongruenze **banali/operative** si risolvono da sole, senza interpellare Villa (niente
  bivi inutili).

**Caso runner (Villa NON presente)**: in esecuzione automatica non si possono porre domande.
Quindi distingui in base alla **bloccanza**:
- **Incongruenza NON bloccante** (puoi procedere comunque, scegliendo un default ragionevole
  secondo le 6 regole di autonomia, cap. 12): **vai avanti** e **annota** in
  `docs/diario/decisioni-da-rivedere.md` per la revisione di Villa. NON fermarti per questo.
- **Incongruenza BLOCCANTE** (non puoi procedere senza il giudizio di Villa): **fermati**
  (`STATUS: BLOCKED` / `CHECKPOINT`), annota, e la si analizza con Villa quando torna.

Ci si ferma SOLO se l'incongruenza impedisce davvero di procedere; altrimenti si procede annotando.

## Cosa NON fare

- NON mettere "intelligenza" dentro il copiare: il motore resta meccanico.
- NON toccare codice/roadmap/config del progetto.
- NON sovrascrivere alla cieca una modifica locale al Metodo: prima capisci cos'e'.
- NON decidere da solo le incongruenze non banali: portale a Villa, una alla volta.
- NON committare in automatico (salvo richiesta esplicita).

## Distribuzione

Skill **operativa**: vive in `.claude/skills/` e viaggia col Metodo (lista bianca). Il
**comando puro** `metodo/metodo-sync.sh scarica` resta disponibile per il **runner** (headless),
dove serve il comportamento meccanico e prevedibile. Dettagli: cap. 19 e
`docs/fondamenta/sistema-aggiornamento-metodo.md`.
