# 14 — Sequencing dei blocchi nella roadmap

## Perche' esiste questo capitolo

Il runner del Metodo Villa esegue i blocchi della roadmap in sequenza,
**senza Villa davanti**. Se in mezzo alla sequenza compare un blocco
che richiede una persona fisica (deploy su un server da raggiungere a
mano, una telefonata al cliente, un login con MFA via SMS), il runner
si ferma e tutti i blocchi successivi devono aspettare.

Il problema non e' il blocco umano in se', e' la sua **posizione**
nella sequenza. Se quel blocco poteva essere fatto prima del lancio
del runner o dopo la fine, allora la sequenza intera ha perso tempo
inutilmente.

Questo capitolo definisce le tre nature di blocco e detta la regola di
ordinamento che il pianificatore della roadmap (chi scrive i blocchi)
deve rispettare.

## Le tre nature di blocco

### 🤖 AUTONOMO

Il runner puo' eseguirlo da solo, senza nessuna presenza umana.
Esempi tipici:

- Modifiche al codice (refactor, nuove feature, bugfix).
- Scrittura o aggiornamento di file di documentazione.
- Esecuzione di test automatici.
- Configurazione di file (env, settings, build).
- Migrazioni di schema database in ambiente di sviluppo.
- Generazione di asset (immagini, dati di test).

Il blocco autonomo non chiede mai conferme a un umano per andare
avanti. Tutte le decisioni tecniche le prende l'agente seguendo le 6
regole di autonomia (vedi `12-autonomia-runner.md`).

### 👤 UMANO

Richiede Villa, un tecnico, o un altro essere umano fisicamente
presente. Il runner **non puo'** eseguirlo. Esempi tipici:

- Deploy su un server fisico in casa o in ufficio (accendere la
  macchina, collegare un cavo, fare login locale).
- Telefonate al cliente, riunioni, demo.
- Operazioni su sistemi protetti da MFA via SMS o token fisico.
- Sostituzione di hardware (disco, scheda di rete).
- Approvazioni che richiedono firma o autenticazione fuori banda.
- Verifiche manuali di percezione (es. "guarda se il colore va bene").

Se un blocco e' umano, il runner deve **per forza** fermarsi prima.

Fermarsi non basta: un blocco 👤 porta con se' la **procedura guidata** che
accompagna Villa tappa per tappa — la regola sta in fondo a questo capitolo.

### 🤝 COLLABORATIVO

Villa apre una sessione live con Claude e i due lavorano insieme in
tempo reale. Il runner non lo esegue, perche' serve il dialogo. Esempi
tipici:

- Decisioni di design importanti (architettura, scelta tecnologica
  strutturale).
- Kickoff di un nuovo progetto o di una nuova fase.
- Test esplorativi di una UI ancora instabile, dove Villa guarda e
  Claude propone aggiustamenti.
- Discovery di requisiti col cliente.
- Revisione del piano di una fase prima del lancio del runner.

Il blocco collaborativo e' diverso da quello umano: l'umano non e'
necessario per ragioni fisiche, ma per ragioni di **giudizio
condiviso**.

## La regola di ordinamento

**I blocchi umani e collaborativi NON devono stare in mezzo alla
sequenza autonoma.**

Vanno o **in testa** alla fase (sessione live prima del lancio del
runner) o **in coda** (sessione live dopo la fine del runner).

Il runner non deve mai fermarsi a meta' sequenza per un blocco umano
se quel blocco poteva essere fatto prima o dopo.

## Anti-pattern: il caso Fase E del progetto Melo

Roadmap della Fase E di Melo_Rebirth_2026, prima di questa lezione:

```
E.1  🤖 Setup endpoint API
E.2  🤖 Migrazione schema
E.3  🤖 Aggiornamento client
E.4  🤖 Test integrazione
E.5  🤖 Documentazione API
E.6  🤖 Refactor consumer
E.7  🤖 Cleanup vecchio codice
E.8  🤖 Aggiornamento .env example
E.9  👤 Deploy sul server di casa            <-- BLOCCO UMANO IN MEZZO
E.10 🤖 Smoke test ambiente produzione
E.11 🤖 Aggiornamento changelog
E.12 🤖 Notifica clienti
E.13 🤖 Tag release
E.14 🤖 Pulizia branch
```

Cosa e' successo realmente:

- Runner lanciato sulla Fase E.
- I primi 8 blocchi (E.1 -> E.8) vanno bene, tutti autonomi.
- Al blocco E.9 il runner si ferma: serve Villa fisicamente in casa a
  fare il deploy sul server. Villa non c'e'.
- I 5 blocchi successivi (E.10 -> E.14), che erano tutti autonomi,
  restano fermi in attesa.

E.9 poteva benissimo essere spostato. Non c'era nessuna ragione tecnica
per cui dovesse stare a meta'.

## Pattern corretto

La Fase E riordinata correttamente:

```
=== PRE-BLOCCHI (sessione live prima del runner) ===
E.0  🤝 Kickoff fase (Villa + Claude rivedono la roadmap)

=== CORE AUTONOMO (eseguito dal runner) ===
E.1  🤖 Setup endpoint API
E.2  🤖 Migrazione schema
E.3  🤖 Aggiornamento client
E.4  🤖 Test integrazione
E.5  🤖 Documentazione API
E.6  🤖 Refactor consumer
E.7  🤖 Cleanup vecchio codice
E.8  🤖 Aggiornamento .env example
E.9  🤖 Smoke test ambiente produzione (girato su staging cloud)
E.10 🤖 Aggiornamento changelog
E.11 🤖 Tag release
E.12 🤖 Pulizia branch

=== POST-BLOCCHI (sessione live dopo il runner) ===
E.13 👤 Deploy sul server di casa
E.14 🤖 Notifica clienti (eseguita da Villa con un comando, dopo il deploy)
```

Risultato: il runner ora esegue 12 blocchi autonomi di fila senza mai
fermarsi a sorpresa. Villa apre una sessione live solo per il blocco
finale, sapendo gia' che deve farlo. Niente attese, niente blocchi a
catena.

## Eccezione: punti di stop pianificati

A volte un blocco umano e' una **dipendenza forte** per i blocchi
autonomi successivi. Esempio: serve il deploy in produzione prima di
poter raccogliere il feedback reale degli utenti, e i blocchi
successivi lavorano su quel feedback.

In quel caso il blocco umano **deve** stare a meta', perche' i blocchi
dopo non possono partire senza. Soluzione: dichiararlo esplicitamente
come **punto di stop pianificato** nella roadmap.

Convenzione di marcatura:

```
E.8  🤖 Endpoint feedback
E.9  👤 [PUNTO DI STOP PIANIFICATO] Deploy in produzione
        --- Il runner si ferma qui di proposito ---
E.10 🤖 Analisi feedback raccolto
```

Il runner si ferma con uno `STATUS: CHECKPOINT` quando incontra il
blocco. Villa lo vede chiaramente perche' e' marcato come previsto, non
come sorpresa.

La differenza pratica e' questa:

- **Sorpresa**: il runner si ferma e Villa pensa "ah, dovevo fare
  questa cosa, non ci avevo pensato". Tempo perso.
- **Pianificato**: il runner si ferma e Villa pensa "ok, era previsto,
  ora faccio la cosa". Nessuna sorpresa.

## Chi applica questa regola

Il **pianificatore** della roadmap (chi scrive la sequenza dei
blocchi). Concretamente:

- L'agente in **skill discovery** (per progetti nuovi).
- L'agente in **sessione live di pianificazione fase**.
- L'agente in **skill chiusura-blocco**, quando aggiorna la roadmap
  con i blocchi successivi gia' previsti.

Prima di lanciare il runner sulla fase, l'agente deve scorrere la
sequenza e verificare:

1. Ogni blocco ha un'etichetta (🤖 / 👤 / 🤝).
2. I blocchi 👤 e 🤝 stanno in testa o in coda, non in mezzo.
3. Se un blocco 👤 sta in mezzo per dipendenza forte, e' marcato come
   "punto di stop pianificato".

Se la regola non e' rispettata, l'agente avvisa Villa **prima del
lancio** e propone il riordino. Non lascia che la scoperta avvenga a
runner gia' partito.

## Quando un blocco passa da una natura all'altra

Le nature non sono fisse per sempre. Un blocco oggi marcato 👤 puo'
diventare 🤖 in futuro:

- Un deploy oggi 👤 (server fisico) puo' diventare 🤖 quando lo
  spostiamo su un PaaS (Railway, Fly, Vercel) che si aggiorna da git
  push automatico.
- Un MFA SMS oggi 👤 puo' diventare 🤖 con un token di lunga durata in
  secret manager (se le policy lo permettono).

Vale la pena, in fase di chiusura progetto o di review periodica,
chiedersi quali blocchi umani della roadmap potrebbero essere
automatizzati e annotarlo in `docs/diario/ideas.md`. Meno blocchi umani in
mezzo = piu' fasi che il runner puo' chiudere da solo.


## La procedura guidata: come si consegna un blocco 👤 a Villa

Un blocco 👤 UMANO oggi si comporta cosi': il runner arriva, vede l'etichetta,
si ferma e avvisa. Poi Villa apre la roadmap e trova una riga — «configurare il
dominio sul fornitore», «prendere la chiave dell'API» — e deve ricostruire da
solo da dove si comincia, dove si va, cosa si copia e dove va incollato. Il
lavoro c'e' tutto: manca il modo di consegnarglielo.

**Ogni blocco 👤 porta con se' la sua procedura guidata**: un percorso a tappe
che accompagna chi lo esegue dall'inizio alla fine. La scrive chi pianifica,
insieme al blocco, non chi si trova davanti allo stop.

### Cosa contiene una tappa

Sempre le stesse quattro cose, nello stesso ordine:

1. **Dove si va** — l'indirizzo esatto della pagina, o il comando esatto da
   lanciare. Non «vai nelle impostazioni del fornitore»: l'indirizzo.
2. **Cosa si fa li'** — il gesto concreto, con il nome del bottone o del campo
   come si legge a schermo.
3. **Cosa si riporta indietro** — il valore da copiare, se ce n'e' uno.
4. **Dove finisce** — il file e la riga in cui quel valore va scritto. Lo scrive
   la procedura, non Villa a mano.

E accanto, sempre: **a che punto siamo** («tappa 3 di 7»). Una tappa per
schermata pulita: cio' che e' passato non deve restare a ingombrare.

### Le tre regole che la rendono sicura

**Conferma prima di cio' che non si torna indietro.** Cancellare, pubblicare,
pagare, mandare un messaggio: la procedura si ferma, dice cosa sta per
succedere e aspetta un si' esplicito. Tutto il resto scorre.

**I passi non si inventano.** Dove chi scrive la procedura non sa davvero
com'e' fatta oggi quella schermata, lo **dichiara** e chiede — non tira a
indovinare un bottone che potrebbe non esistere. Un clic inventato non fa
perdere tempo: fa fare la cosa sbagliata a chi si fida.

**I segreti non lasciano tracce.** Chiavi, parole d'ordine e gettoni si
raccolgono e si scrivono **solo** nel file delle configurazioni che il deposito
ignora (`.env` e simili). Mai nel registro della corsa, mai ripetuti a schermo
dopo essere stati incollati, mai dentro un messaggio di errore.

### La procedura e' effimera

Si scrive per **una corsa sola** e si butta, come il codice usa e getta. Si
conserva solo quando quel percorso si ripete davvero (l'installazione di un
cliente nuovo, il rinnovo annuale di un certificato): allora diventa uno
strumento del progetto e vive in `metodo/`.

Il motivo e' pratico: una procedura conservata invecchia insieme alle schermate
del fornitore, e una procedura vecchia e' peggio di nessuna procedura — manda
chi la segue a cercare un bottone che e' stato spostato sei mesi fa.

### Dove si scrive

Dentro il blocco stesso della roadmap, sotto la descrizione, come elenco
numerato di tappe. Quando le tappe sono piu' di cinque o raccolgono valori che
vanno scritti da qualche parte, si scrivono in un file di tappe e le esegue
`metodo/procedura-guidata.sh` — cosi' Villa risponde e basta, invece di leggere
e ricopiare. **L'impaginazione non si riscrive mai**: il modello fa gia' schermo
pulito, conteggio, conferme, raccolta e registro; l'agente scrive solo le tappe.
Come si scrivono: competenza `procedura-guidata`.
## Il secondo asse: la corsia

L'etichetta di natura (🤖 / 👤 / 🤝) dice **chi** puo' eseguire un blocco.
Quando una fase viene divisa in corsie parallele, ogni blocco porta anche
un'etichetta che dice **dove** sta: `[[TRONCO]]`, `[[BE]]`, `[[FE]]`…

I due assi sono indipendenti e si sommano sulla stessa riga:

```
- [ ] **F4B6** Schermata elenco    🤖 [[FE]]
```

Le regole di ordinamento di questo capitolo continuano a valere **dentro
ogni corsia**: un blocco 👤 o 🤝 in mezzo a una corsia la ferma tutta (le
altre proseguono). Quando e' lecito aprire le corsie, come si congela cio'
che hanno in comune e come si rimette insieme il lavoro: capitolo
`21-corsie-parallele.md`.
