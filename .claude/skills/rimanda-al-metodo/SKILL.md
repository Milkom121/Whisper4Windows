---
name: rimanda-al-metodo
description: Skill per il RIMANDO (upload) di migliorie al Metodo Villa dal progetto in cui si lavora SU al repository madre (Metodo-Villa-UFFICIALE), cosi' la miglioria si ridistribuisce a tutti gli altri progetti. Usala quando, lavorando dentro un progetto, hai migliorato il METODO stesso (manuale .claude/metodo-villa/, skill .claude/skills/, runner, strumenti in metodo/) e vuoi portarlo alla fonte. PRIMA di proporre qualsiasi cosa fa un VAGLIO INTELLIGENTE in due setacci: (A) NEUTRALITA' — la modifica e' ripulita da tutto cio' che e' specifico del progetto da cui nasce (nomi, entita' di dominio, esempi, percorsi); (B) PERTINENZA e NON-RIDONDANZA — e' una vera novita' utile a TUTTI i progetti e non e' gia' presente nel Metodo madre nello stato attuale. Il motore meccanico (confronta/crea ramo/apre proposta) e' metodo/metodo-sync.sh rimanda; QUESTA skill ci mette il giudizio. Rimando SEMPRE SORVEGLIATO: Villa approva prima dell'invio; mai automatico; mai codice del progetto. Trigger: "rimanda al metodo", "carica la miglioria sulla madre", "porta questa modifica al Metodo Villa", "upload al repository del metodo", "manda al metodo madre", "rifluisci al metodo". English: send improvement upstream to the Method, upload method change to mother repo.
---

# Rimanda al Metodo (upload sorvegliato con vaglio intelligente)

## A cosa serve

Quando lavorando in un progetto migliori il **Metodo** (non il progetto), questa skill
porta la miglioria al **repository madre** `Metodo-Villa-UFFICIALE`, cosi' arriva a tutti gli
altri progetti al loro prossimo scarico. Ma non carica "tutto cio' che e' diverso": fa
prima un **vaglio** perche' nella madre entri solo roba **neutra** e **pertinente**.

Il rimando e' la meta' "sorvegliata" del sistema di sync (cap. 19): **passa SEMPRE
dall'approvazione di Villa**. Lo scarico (madre -> progetto) e' un'altra cosa, leggera e
meccanica: non usa questa skill.

## Quando attivarla / quando NO

- **SI**: hai cambiato un file del Metodo dentro un progetto (un capitolo del manuale, una
  skill, una regola, lo strumento) e quella miglioria ha senso per **tutti** i progetti.
- **NO**: hai cambiato solo codice/roadmap/config del progetto (non e' Metodo). NO: la
  modifica e' una **divergenza voluta** del progetto (es. il runner del monorepo
  SenilCare) — quella resta nel progetto, dichiarata in `.metodo-sync-ignore`.

## Principi (non negoziabili)

- **Mai codice del progetto**: il rimando tocca solo i file della lista bianca
  (`metodo/metodo-manifest.txt`). Il codice del progetto e' invisibile per costruzione.
- **Mai roba di dominio non ripulita**: ció che entra nella madre deve essere agnostico
  dal progetto.
- **Mai automatico**: si propone, Villa approva, poi si invia.
- **Conflitti mai risolti in autonomia**: se la madre e' cambiata sulle stesse righe, si
  descrive a Villa (cap. 07).

## Flusso

### 1. Allineati prima (riduce conflitti e falsi candidati)
Se la madre potrebbe essere piu' avanti, fai prima uno **scarico**
(`metodo/metodo-sync.sh scarica`) o almeno avvisa Villa. Cosi' confronti la tua modifica
con il Metodo **com'e' adesso**, non con una versione vecchia: questo serve direttamente
al setaccio B (non-ridondanza).

### 2. Trova i candidati (motore meccanico)
Lancia l'anteprima: `metodo/metodo-sync.sh rimanda` (senza argomenti). Restituisce
l'elenco dei file del Metodo che differiscono dalla madre, col **diff** di ciascuno.
Questo e' solo il punto di partenza: NON proporre questo elenco cosi' com'e'.

### 3. VAGLIO — per ogni candidato, passa i due setacci

**Setaccio A — Neutralita' (agnostico dal progetto).**
Leggi il diff e cerca tracce del progetto da cui nasce:
- nome del progetto, sue entita'/concetti di dominio, esempi specifici, percorsi, dati.
- *Esempio*: una miglioria a una skill che nell'esempio dice "scheda clinica del
  paziente" (dominio sanitario di SenilCure). Va **neutralizzata**: "scheda clinica del
  paziente" -> "un documento/una scheda". Se la miglioria e' utile ma sporca, la
  **riscrivi in forma generica** prima di proporla. Se e' inscindibile dal dominio (ha
  senso solo per quel progetto), la **scarti**.

**Setaccio B — Pertinenza e non-ridondanza (rispetto al Metodo di ADESSO).**
Apri lo stato attuale del Metodo madre (il file corrispondente + i capitoli correlati) e
chiediti:
- e' **gia' presente** nel Metodo, magari in altra forma? -> ridondante, **scarta**.
- e' una regola che ha senso per **tutti** i progetti, o serve solo a questo? -> se serve
  solo a questo, **scarta** (eventualmente diventa una divergenza in `.metodo-sync-ignore`).
- e' **coerente** con le decisioni e le regole gia' nel Metodo? -> se contraddice, fermati
  e discutine con Villa.

### 4. Prepara le versioni da inviare
Per i pezzi che passano: se serviva neutralizzare, **applica la versione neutra al file
del Metodo nel progetto** (il file del Metodo nel progetto deve comunque essere neutro:
gli esempi di dominio vivono nel codice del progetto, non nei file del Metodo). Quella
versione neutra e' sia cio' che resta nel progetto sia cio' che si rimanda.

### 5. Proponi a Villa un vaglio ragionato
Presenta una tabella chiara, una riga per candidato:

| Pezzo | Giudizio | Perche' |
|-------|----------|---------|
| (file/modifica) | RIMANDO / NEUTRALIZZO cosi'… / SCARTO | (motivo: gia' presente / sporco di dominio / solo-progetto / nuovo e utile) |

Spiega in linguaggio umano. Attendi l'approvazione (o le correzioni) di Villa.

### 6. Invia (solo sui pezzi approvati)
Sui soli file approvati: `metodo/metodo-sync.sh rimanda <file...>` (oppure `--tutti` se
Villa approva l'intero set). Il motore crea un ramo dedicato nella madre, committa, apre
la proposta di fusione (PR). Per i file ad alto rischio di divergenza (runner) serve
`--conferma-divergenti` — normalmente NON si rimandano.

### 7. Conflitti e chiusura
Se la fusione nella madre incontra un conflitto (un altro progetto ha toccato le stesse
righe), **non risolverlo da solo**: descrivi a Villa le due versioni e fagli scegliere.
La fusione finale nel Metodo ufficiale la decide Villa.

## Gestione delle incongruenze (UNA ALLA VOLTA, stile discovery)

Se durante il vaglio o l'invio emergono problemi/incongruenze che **non si risolvono in
modo agevole e ovvio** (es: una miglioria utile ma inscindibile dal dominio; il dubbio se
una modifica sia gia' presente nel Metodo; un conflitto sulle stesse righe), allora:

- **NON decidere da solo** (non e' banale) e **NON ammucchiare** i problemi in un unico
  messaggio.
- Presentali a Villa **uno alla volta**, stile `discovery` / regola 1bis del Metodo:
  1. **contatore** — "Incongruenza 2 di N";
  2. **cosa e' successo e perche' conta** — breve, in linguaggio umano;
  3. **2-3 opzioni a parole** con la **raccomandazione di Claude**;
  4. **attendi la risposta** prima della successiva.
- Le incongruenze **banali/operative** si risolvono da sole (niente bivi inutili).

Il rimando e' comunque **sempre sorvegliato** (Villa presente che approva), quindi non parte
mai in automatico dal runner: se non c'e' Villa, il rimando non si fa.

## Cosa NON fare

- NON proporre l'elenco grezzo del motore senza il vaglio.
- NON caricare nulla che contenga tracce del progetto (neutralizza o scarta).
- NON caricare doppioni o regole utili solo a quel progetto.
- NON inviare senza l'ok di Villa. NON risolvere conflitti in autonomia.
- NON toccare codice/roadmap/config del progetto.

## Distribuzione

Skill **operativa**: vive in `.claude/skills/` e viaggia col Metodo (e' nella lista
bianca). Ogni progetto la riceve con lo scarico. Dettagli del sistema: cap. 19 e
`docs/fondamenta/sistema-aggiornamento-metodo.md`.
