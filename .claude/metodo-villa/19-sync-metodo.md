# Aggiornamento del Metodo a due sensi (sync madre ↔ progetti)

> **Nuovo in v2** (2026-06-07). Risolve il *drift*: i progetti nascono da
> "Use this template" e fotografano il Metodo a quella data; quando il Metodo
> migliora, le copie restano indietro. Questo capitolo spiega come tenerle
> allineate **nei due sensi**, senza mai toccare il codice del progetto.
> Disegno completo e decisioni: `docs/fondamenta/sistema-aggiornamento-metodo.md`.

## A che serve

- **Scaricare** (madre → progetto): portare nei progetti gli aggiornamenti del
  Metodo (manuale, skill, runner) senza toccare i loro file (codice, roadmap,
  config, regole specifiche).
- **Rimandare** (progetto → madre): riportare alla madre le migliorie al Metodo
  nate lavorando dentro un progetto, così si ridistribuiscono a tutti.

Principio: **scarico leggero, rimando sorvegliato.** Lo scarico è reversibile e si
lancia con disinvoltura. Il rimando ricade su *tutti* i progetti, quindi passa
**sempre** da una proposta che Villa approva. Niente automatismi nascosti.

## Lo strumento

Un unico script `metodo/metodo-sync.sh` (bash; da Windows si raggiunge con
`runner.bat`, voci 3 e 4):

| Comando | Cosa fa |
|---------|---------|
| `scarica [madre]` | Porta gli aggiornamenti del Metodo dalla madre nel progetto. Non committa: lasci rivedere con `git diff`. |
| `rimanda [--tutti\|file…]` | Propone alla madre le migliorie. Senza argomenti = **anteprima** (mostra candidati e diff, non invia). |
| `converti-claude` | Spezza un `CLAUDE.md` misto in file operativo (Metodo) + `CLAUDE.md` magro. Non distruttivo. |
| `stato [madre]` | Mostra che cosa differisce tra progetto e madre (sola lettura). |

La madre si indica con argomento → variabile `METODO_VILLA_HOME` → default noto.

## Le due skill (la testa sopra il motore)

Lo script e' il **motore meccanico**. Sopra ci sono due **skill** che mettono il giudizio:
- **`aggiorna-dal-metodo`** (scarico): motore meccanico + testa solo dove serve (prima:
  rileva divergenze locali e skill di dominio del progetto; dopo: spiega in linguaggio
  umano cosa e' cambiato e se serve un'azione). Leggera nel caso normale.
- **`rimanda-al-metodo`** (rimando): vaglio in due setacci — **neutralita'** (ripulisce
  dal dominio del progetto) e **pertinenza/non-ridondanza** (rispetto al Metodo attuale) —
  poi propone a Villa, che approva.

Asimmetria: lo scarico ragiona **solo quando serve**, il rimando ragiona **sempre** (il
vaglio e' il suo cuore). Il **comando puro** dello script resta per il **runner** (headless).

**Incongruenze non risolvibili in autonomia**: non si decidono da soli e non si ammucchiano
— si presentano a Villa **una alla volta**, stile `discovery` (regola 1bis). In modalita'
runner (Villa assente), se l'incongruenza **non e' bloccante** procede e **annota** (`docs/diario/decisioni-da-rivedere.md`); si **ferma** solo se e' **bloccante**, cioe' non puo' procedere senza Villa (cap. 12).

## Che cosa è "Metodo" (la lista bianca)

Lo strumento tocca **solo** ciò che è elencato in `metodo/metodo-manifest.txt`: il
manuale `.claude/metodo-villa/`, le skill `.claude/skills/`, la macchina in `metodo/`,
l'avviatore `runner.bat`, `.gitattributes`, il template di handoff.
**Tutto il resto è invisibile per costruzione**: codice, `ROADMAP.md`,
`PROJECT_CONFIG.md`, `CLAUDE.md` (regole-progetto), `README.md`, `docs/` del progetto
(comprese `fondamenta/` e `diario/`). Così il rimando non può portarsi dietro il codice.

Regola: **mai mettere file specifici di un progetto sotto `.claude/skills/` o
`.claude/metodo-villa/`.** Le skill contengono *esempi* del Metodo; la
personalizzazione di un progetto vive nel suo codice (es. `src/`), fuori lista bianca.

## Lo split del CLAUDE.md

Le regole del Metodo (sez. 1-14) vivono in `.claude/metodo-villa/00-CLAUDE-OPERATIVO.md`
(è Metodo: si sincronizza). Il `CLAUDE.md` del progetto resta **magro**: un rimando
`@.claude/metodo-villa/00-CLAUDE-OPERATIVO.md` + solo le regole del progetto, sotto la
riga `--- REGOLE SPECIFICHE PROGETTO ---`. Così aggiornare il Metodo non tocca mai le
regole del progetto. Il runner e la sequenza di apertura leggono **esplicitamente** il
file operativo (non si fidano solo dell'`@import`, fragile in headless).

## Gli spostamenti: come i progetti vecchi si riordinano da soli

**Il problema.** Lo scarico *copia* e non cancella mai nulla di sua iniziativa (e'
una garanzia, non un limite). Quindi quando il Metodo **sposta** un file, un progetto
nato prima si ritrova la copia nuova nel posto nuovo **e** quella vecchia nel posto
vecchio: doppioni per sempre, e nessuno sa quale vale.

**La soluzione.** `metodo/metodo-spostamenti.txt` dichiara, una volta, "questo stava
li' e ora sta qua". Lo scarico lo applica **dopo** la copia e il progetto si trova
riordinato senza interventi a mano. Applicarlo piu' volte non fa danni.

Due tipi, con garanzie diverse:

| Tipo | Che cos'e' | Che cosa fa lo scarico |
|------|-----------|------------------------|
| `metodo` | File di **proprieta' della madre** (runner, strumenti, avviatore) | **Rimuove** il vecchio — ma solo dopo aver verificato che la copia nuova sia davvero arrivata. Nessuna perdita: il contenuto e' della madre |
| `impalcatura` | File il cui **contenuto e' del progetto** ma il cui **percorso lo decide il Metodo** (handoff, progress, log: il runner li cerca a percorso fisso) | **Sposta**, e non cancella MAI. Se esistono sia il vecchio sia il nuovo non indovina: lo segnala a Villa |

**Perche' l'impalcatura si puo' spostare senza tradire il vincolo numero uno.** Il
vincolo e' "non toccare i file del progetto": protegge cio' che il progetto ha
*scelto* — codice, roadmap, configurazione, i suoi documenti. Ma il percorso di
`handoff.md` non l'ha mai scelto il progetto: e' sempre stato imposto dal Metodo, che
lo ha scritto dentro il runner. Cambiarlo e' una modifica del Metodo, non del progetto.
Il **contenuto** non viene toccato: si sposta il file, non si riscrive.

**Cio' che invece non si sposta da solo.** I documenti del progetto rimasti sciolti in
`docs/` non si smistano a macchina: solo Villa sa se un documento e' `fondamenta/`
(scritto una volta) o `diario/` (cresce lavorando). Lo scarico li **elenca** e si ferma la'.

## Eccezioni per progetto (divergenze volute)

Un progetto che personalizza apposta un file del Metodo (es. il runner del monorepo
SenilCare) lo dichiara in `.metodo-sync-ignore` nella sua radice (stile `.gitignore`:
una path/glob per riga, `#` per commenti). Default assente/vuoto = nessuna eccezione.
Scarico e rimando saltano quelle path e le stampano in chiaro.

## Conflitti e governance

La madre è la **fonte di verità**. Il rimando crea un **ramo** nella madre
(`rientro/da-<progetto>-<data>`) e una proposta di fusione (PR): non tocca mai il
Metodo ufficiale finché Villa non fonde. Se due progetti hanno cambiato lo stesso
pezzo, git segnala il **conflitto** e lo scioglie Villa — mai in automatico (cap. 07).
Disciplina che riduce i conflitti: **scarica prima di rimandare**.

## Quando proporlo (agganci ai flussi)

- **Apertura sessione**: se la madre ha novità, proponi lo scarico.
- **Chiusura-blocco**: se nel blocco hai toccato file del Metodo, proponi il rimando.

Sempre come **proposta declinabile**, mai passo forzato.

## Sicurezza (cosa NON fa)

- Non tocca mai codice/roadmap/config/regole del progetto.
- Non parte su area di lavoro "sporca" senza backup (niente perdita di file non salvati).
- La conversione del CLAUDE.md salva `.pre-split.bak` e si ferma se il marcatore è
  anomalo: non cancella mai regole di progetto.
- Non risolve conflitti da solo. Non cancella file (segnala gli orfani).

## Relazione con altri capitoli

- Estende il modello "skill come repository-template" (decisione D8) con la
  manutenzione nel tempo.
- Si appoggia alle regole git e conflitti (cap. 07) e alla validazione
  multi-agente (cap. 15), usata per validare il disegno prima di costruirlo.
