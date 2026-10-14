# Autonomia decisionale durante runner automatico

## Quando si applica

Durante l'esecuzione **automatica** del runner (`metodo-villa-runner.sh`),
l'agente attraversa la roadmap senza intervento di Villa per ogni blocco.
Villa **non ha le competenze tecniche** per decidere su scelte come
"quale hashing usare per le password", "quale licenza accettare", "che
schema dare alla tabella X".

Soluzione: l'agente prende quelle scelte **da solo**, applicando le 6
regole permanenti seguenti, e annota ogni decisione presa in
`docs/diario/decisioni-da-rivedere.md` per revisione successiva da parte di
Villa.

Questo capitolo NON si applica alle **sessioni live**, in cui Villa e'
davanti all'interfaccia di Claude Code e si possono chiedere conferme.
Si applica solo alle **invocazioni del runner** (esecuzione automatica
senza Villa).

## Regola 1 — Sicurezza

**Scegli sempre la soluzione piu' sicura e robusta possibile.**

Linee guida concrete:
- Hashing password con argon2 o bcrypt (mai SHA, mai MD5).
- Token con scadenza esplicita.
- Validazione input sempre, su tutti gli endpoint.
- Query parametrizzate sempre (mai concatenazione di stringhe in SQL).
- Secret in variabili ambiente, mai hardcoded.
- CORS restrittivi per default.
- HTTPS preferito ovunque possibile.

Niente checkpoint da chiedere a Villa per la sicurezza: vai col massimo
livello ragionevole. Annota la scelta in `docs/diario/decisioni-da-rivedere.md`.

## Regola 2 — Schema database

**Scelta tecnica migliore secondo best practice del DBMS in uso.**

Linee guida concrete:
- Normalizzazione ragionevole (3NF di base).
- Indici sui campi su cui si filtra/ordina spesso.
- Foreign key con ON DELETE espliciti (mai "default").
- Soft delete preferito a hard delete per dati utente.
- Timestamp con timezone sempre.

**Eccezione**: se la decisione dipende da una norma di legge (retention
dei dati, GDPR, dati sanitari), non decidere qui: applica la **Regola 6**.

## Regola 3 — Librerie e dipendenze

**Vincolo permanente: SOLO librerie open source con licenza libera.**

Licenze **accettate** senza chiedere:
- MIT
- Apache 2.0
- BSD (qualsiasi variante)
- ISC
- MPL 2.0

Licenze **da valutare con cautela** per uso commerciale futuro (annota
sempre):
- GPL, AGPL, LGPL

Licenze **vietate**:
- Proprietarie / closed source
- "Freemium con limiti d'uso"
- "Free per uso personale"
- Creative Commons NC (Non-Commercial)

In caso di dubbio sulla licenza, scegli la libreria con licenza piu'
chiara e annota la scelta in `docs/diario/decisioni-da-rivedere.md`.

## Regola 4 — Scope dei blocchi

**Il blocco e' quello che e'. Non estenderlo MAI durante l'esecuzione
automatica.**

Se durante l'implementazione emerge che servirebbe fare ANCHE altro
(estensione naturale, miglioramento aggiuntivo, refactor opportuno):
- NON farlo nel blocco corrente.
- Annota la "domanda di estensione" in `docs/diario/decisioni-da-rivedere.md`
  con riferimenti precisi (blocco, motivo, cosa avresti aggiunto).
- Completa il blocco originale come definito.

Questa regola e' la difesa principale contro la deriva di scope.

## Regola 5 — Errori logici nei blocchi della roadmap

**Prima di iniziare un blocco, leggilo criticamente.** Se noti errori
logici nel blocco stesso (dipendenze sbagliate, incoerenze con la
discovery, riferimenti a cose inesistenti, contraddizioni con blocchi
precedenti, prerequisiti mancanti), valuta la gravita:

- **Errore minore o risolvibile autonomamente** (ordine di passi
  invertito, dipendenza ovvia da aggiungere, riferimento sbagliato
  facilmente sistemabile): **risolvi e prosegui**. Annota nel file di
  revisione cosa hai trovato e come hai sistemato.
- **Errore grave** (il blocco contraddice una decisione strategica,
  scope incompatibile con altri blocchi, ambiguita che cambia il
  significato del blocco): **fermati con CHECKPOINT** e descrivi a Villa
  il problema. Questo NON e' una decisione tecnica che Villa non sa
  prendere — e' una correzione del piano, e quella la decide Villa.

In sintesi: l'esecuzione automatica deve essere **critica**, non
meccanica. Se il piano e' sbagliato, segnalalo invece di eseguirlo a
testa bassa.

## Regola 6 — Criteri stabiliti da una norma di legge

**Non si chiede a Villa, e non si "sceglie il piu' conservativo": si cerca la
norma applicabile e si applica quella.**

Quando una decisione dipende da una regola scritta nella legge — quanto a lungo
si conservano certi dati, che cosa impone il GDPR, come vanno trattati i dati
sanitari, che obblighi ci sono su fatturazione o consenso — non e' una scelta
tecnica ne' una preferenza di Villa: la risposta esiste gia' e sta in una norma.

Procedura, in quest'ordine:

1. **Individua la norma applicabile** per la giurisdizione e il dominio del
   progetto (li trovi in `PROJECT_CONFIG.md`; se mancano, il dominio si desume
   dalla discovery).
2. **Applica quella norma**, non un'approssimazione prudente. Una scelta piu'
   restrittiva del dovuto e' comunque una scelta sbagliata: costa funzionalita'
   senza aggiungere conformita'.
3. **Annota in `docs/diario/decisioni-da-rivedere.md` QUALE norma hai applicato
   e DOVE l'hai letta** (fonte e articolo). Senza questo la voce e' inutile.
4. **Solo se la norma non e' determinabile** — giurisdizione ambigua, fonti in
   contrasto, caso che dipende da come l'azienda opera e non dalla legge —
   **fermati e avvisa Villa**.

**Perche' la citazione della fonte non e' un formalismo.** La lettura che un
agente fa di una norma non e' un parere legale: e' una ricostruzione, e puo'
essere sbagliata. Scrivere quale norma e dove si e' letta e' cio' che rende la
scelta **controllabile da un umano** invece che da prendere sulla fiducia. Una
voce senza fonte non e' verificabile, e quindi non vale.

**Categoria** da usare nel file di revisione: `norma-di-legge`.

> Questa regola sostituisce il vecchio «prendi la scelta piu' conservativa»
> (Villa, 2026-08-08): *«nel caso di criteri di business la procedura non e'
> fermarsi e chiedere a me, ma valutare qual e' la norma di legge e applicare
> quei criteri; se proprio non e' possibile, allora notificare a me.»*

## Vincolo trasversale — Mai attribuire a Villa decisioni che non ha preso

Durante l'esecuzione automatica l'agente prende molte scelte tecniche da
solo (regole 1-3 e 6). Ma quando le **documenta** (in ROADMAP, handoff,
`docs/diario/decisions.md`, commenti, commit), deve distinguere nettamente:

- **Decisione di Villa** — scrivila come tale SOLO se Villa l'ha detta
  esplicitamente in una sessione live (o e' gia' in `docs/diario/decisions.md`).
- **Scelta/inferenza dell'agente** — marcala come "scelta autonoma (da
  rivedere)" o "proposta", **mai** come "decisione di Villa: X".

Non mettere mai parole in bocca a Villa. Inventare una sua decisione e'
peggio che non documentarla: sporca la memoria del progetto con vincoli
fasulli che nessuno ha scelto e che poi vengono presi per veri, orientando
il lavoro futuro nella direzione sbagliata.

> Difetto che ha originato questa regola (SenilCure, 2026-05-29): in
> `ROADMAP.md` era finita la frase *"decisione di Villa 2026-05-29: niente
> runner lungo, sessioni brevi"* — una decisione che Villa non ha **mai**
> preso, scritta dall'agente come se fosse sua. Rimossa appena rilevata.

## Cosa NON va annotato (dettagli reversibili)

Scelte tecniche di routine che NON vanno nel file di revisione perche'
sono banali e facilmente reversibili:
- Nomi di campi/funzioni/variabili (in inglese, come da metodo).
- Testi UI (in italiano).
- Stile codice (formattazione, spaziatura).
- Dettagli di implementazione interna non visibili dall'esterno.

Decidi e prosegui senza annotare.

## Il file `docs/diario/decisioni-da-rivedere.md`

Formato per ogni voce:

```
## YYYY-MM-DD — Blocco X.Y

- **Categoria**: sicurezza / schema-DB / libreria / norma-di-legge / scope-esteso / errore-blocco / altro
- **Cosa ho deciso**: [descrizione concreta]
- **Perche'**: [motivazione]
- **Facilita di cambiarla in futuro**: facile / medio / difficile
- **Riferimento**: [file modificato, riga, o blocco interessato]
```

## A fine esecuzione del runner

L'handoff prodotto al termine dell'esecuzione del runner (o di
ciascuna invocazione, se il runner si ferma a checkpoint) deve
includere:
- Numero di **nuove voci** aggiunte a `docs/diario/decisioni-da-rivedere.md`
  durante le invocazioni.
- Lista delle **2-3 piu' importanti** da rivedere subito (sicurezza,
  scelte di scope, errori segnalati).

Cosi Villa, all'inizio della prossima sessione live, sa subito cosa
vale la pena guardare prima di lanciare un nuovo round del runner.
