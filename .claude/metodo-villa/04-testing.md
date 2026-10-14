# Strategia di Testing Completa

## Livelli di testing progressivi

### Livello 1 — Test unitari e di integrazione (sempre, automatici)

Questo è il livello minimo, obbligatorio per ogni progetto:
- Eseguiti automaticamente alla fine di ogni blocco di sviluppo
- Se falliscono, il ciclo si ferma — il blocco successivo NON parte
- Sono la condizione minima per dichiarare un blocco completato
- Comandi tipici: `pytest`, `go test`, `flutter test`, `npm test`, `cargo test`

Ogni progetto deve definire nel suo CLAUDE.md locale il comando esatto per eseguire i test L1 (vedi gate di uscita nella roadmap).

### Livello 2 — Test visuale/funzionale via browser (per web app)

Per i progetti con interfaccia web (BottegaLLM, Melo, SenilWatch dashboard, Dydat admin):
- Usa Claude in Chrome o strumenti simili per:
  - Navigare l'app deployata localmente
  - Verificare i flussi utente principali (login, navigazione, CRUD base)
  - Controllare regressioni visive (screenshot comparison tra sessioni)
  - Monitorare errori nella console browser
  - Verificare che le richieste di rete rispondano correttamente
- Può essere integrato nel ciclo continuo come "guardiano" tra i blocchi: dopo che L1 passa, il browser verifica che l'app funzioni ancora end-to-end

**Raccomandazione**: Definire una suite di "smoke test" visivi per ogni progetto web: i 3-5 flussi utente critici che devono sempre funzionare. Esempio per Melo: login admin → dashboard → lista ospiti → dettaglio ospite → logout. Se uno di questi flussi si rompe, il blocco non è completato.

### Livello 3 — Test mobile via emulatore (livello avanzato — opzionale)

Per i progetti con app mobile (SenilWatch mobile, Dydat frontend Flutter, BottegaLLM AppMobile), quando il progetto raggiunge maturità:
- Strumenti disponibili:
  - **Android Emulator Skill** — navigazione semantica dell'UI, test di accessibilità, visual regression su emulatore
  - **Appium Claude Android** — test in linguaggio naturale su dispositivi reali o emulati, senza scrivere codice di test
  - **Mobile App Tester Skill** — supporta framework multipli: Appium, Detox, XCUITest, Espresso
- Più complesso da configurare rispetto ai test browser — richiede emulatore attivo e setup dedicato

**Raccomandazione**: Implementare L3 solo dopo che L1 e L2 sono stabili e rodati. Il test mobile è costoso in termini di tempo e configurazione — meglio avere una base solida prima. L3 è per progetti maturi che vanno verso produzione, non per standard development.

**Decisione**: Flutter integration test nativi come standard per i progetti mobile (già usati in Dydat e SenilWatch). Framework aggiuntivi (Appium, Espresso) solo se emerge una necessità specifica non coperta dai test nativi Flutter.

### Livello 4 — Test E2E e performance (livello avanzato — opzionale)

Per progetti in fase di pre-produzione o produzione:
- Load testing e stress testing (quanti utenti concorrenti regge il sistema?)
- Test di sicurezza (penetration testing, OWASP top 10)
- Test di accessibilità (WCAG compliance)
- Monitoring continuo (uptime, tempi di risposta, errori in produzione)

**Raccomandazione**: Non automatizzare L4 nel ciclo continuo — eseguire come task schedulati separati (settimanali o pre-release). Includerli nel ciclo rallenterebbe troppo lo sviluppo senza beneficio proporzionale. L4 è per progetti maturi che vanno a produzione, non per standard development.

## Collaudo guidato — la verifica manuale con l'occhio umano

I quattro livelli sopra sono **automatici**: verificano che il codice faccia ciò che dicono i test. Ma l'uso reale rivela cose che nessun test automatico vede — incoerenze di UX, bug di sessione, dati irrealistici, comportamenti strani che solo una persona nota mentre prova davvero. Per questo, **a fine fase e prima del pilot**, il Metodo prevede un **collaudo guidato**: un giro manuale esplorativo del prodotto vivo, condotto con Villa.

- **Chi fa cosa**: l'**umano esegue** le azioni (prova l'app); **Claude guida a parole** una task alla volta e **non** pilota l'app al posto suo; **ma Claude esegue da solo le verifiche tecniche** (legge il codice, interroga API/DB) per dare cause radice fondate.
- **Output**: un documento di rilievi classificati (`docs/collaudo-<contesto>.md`) che diventa una roadmap eseguibile.
- **Quando**: su richiesta, e **proposto automaticamente a fine fase** (vedi la skill `chiusura-blocco`).
- **Dove**: skill `.claude/skills/collaudo-guidato/SKILL.md`.

Distinzione netta: **L1-L4 = automatici sul codice; collaudo guidato = manuale esplorativo con l'occhio umano.** Sono complementari, non alternativi.

## La prova del lavoro — il collaudo per lavori interi

I quattro livelli sopra provano il codice; il collaudo guidato porta l'occhio umano
sul prodotto vivo. Resta fuori una terza domanda, che nessuno dei due fa:

> **Si riesce a lavorare?**

Un lavoro vero attraversa **piu' schermate, piu' ruoli e piu' momenti nel tempo**, ed e'
nelle **giunture** che il software si rompe — non dentro una schermata. Su Fedorius, il
2026-08-19, un difetto di montaggio era passato **sotto 4.525 prove verdi**: ogni pezzo
funzionava da solo, erano attaccati male. Le prove dicono che i pezzi funzionano; i
percorsi dicono che sono attaccati.

**Non e' un livello L5.** La scala L1-L4 e' citata in tutti i progetti, e un numero in
piu' suggerirebbe «piu' avanzato di L4»: questo collaudo e' ortogonale, non superiore. E'
una sezione sorella del collaudo guidato.

### I tre ingredienti, presi dal prodotto e mai inventati

1. **I ruoli reali**, ognuno col suo **vincolo**: mani occupate, cinque minuti fra un
   impegno e l'altro, passa due volte a settimana, guarda solo dal telefono. **E' il
   vincolo che fa emergere il difetto, non il nome della persona** — le personas restano
   fuori (cap. 20). Il modo piu' rapido di trovare il vincolo giusto: chiedersi **perche'
   quella persona smetterebbe di usare il prodotto**.
2. **L'oggetto** attorno a cui ruota il lavoro nel dominio: un cliente, una pratica, una
   commessa, un paziente.
3. **I lavori interi**, dall'**evento che li fa nascere** fino al momento in cui sono
   **finiti**.

### La regola che la rende utile

Ogni passo si scrive come **azione + esito osservabile**. «Apri la lista» non e' un passo;
«apri la lista → compaiono solo le pratiche della tua sede» lo e'.

E un lavoro e' **superato solo se alla fine lo stato del sistema dimostra che e'
finito**: il record esiste, ha lo stato giusto, l'avviso e' partito. Le schermate che si
aprono non sono una prova.

### Chi fa cosa

- **L'agente esegue** tutto cio' che passa da uno schermo o da una porta del sistema, e
  riporta.
- **L'umano decide solo il giudizio**: e' utile, e' nel posto giusto, lo accettiamo.
- Cio' che si vede solo con le mani vere — il telefono mentre si cammina, la luce del
  corridoio, il guanto — resta **dichiarato come non coperto**. Mai verde per omissione.

### Cosa si automatizza, e cosa no

Si automatizzano i lavori a **esito prevedibile**: permessi, isolamento fra clienti,
cestino e ripristino, preferenze che restano, consegna, conti che tornano.

**Non** si automatizzano i lavori che dipendono dal **giudizio**: la qualita' di un
testo, il tono, la risposta a un caso ambiguo. Su Fedorius erano 24 lavori su 73 — un
terzo del piano, ed e' il cuore del prodotto. Un collaudo che non lo dichiara fa credere
di aver provato il prodotto quando ha provato l'impalcatura.

### Le due trappole

- **Il catalogo di sessanta flussi che nessuno esegue.** Si evita scrivendo l'elenco
  **largo e sottile** ed eseguendone **cinque profondi** prima di allargare.
- **I flussi importati da un altro dominio.** Si evita prendendo ruoli e oggetti dal
  prodotto vero: si scrivono **contro** la mappa dell'esperienza e la discovery, mai a
  memoria.

### Dove sta, e con cosa si esegue

Dopo i test automatici, dopo il collaudo guidato, **prima della consegna**. Un flusso per
blocco: il piano dei lavori **e' una fase di roadmap**, e la esegue il runner con lo
stato, il guardiano e il diario che ha gia' — non serve un secondo motore.

Si esegue con la competenza `collaudo-automatico`. Il disegno, e cosa e' stato verificato
sul campo, in `docs/fondamenta/prova-del-lavoro-disegno.md`.

**Distinzione netta**: il **collaudo guidato** e' l'umano che esplora e nota; la **prova
del lavoro** e' l'agente che percorre lavori interi decisi in anticipo e misura lo stato
finale.


## Integrazione testing nel ciclo continuo

Il flusso completo, quando il ciclo continuo è attivo:

```
Blocco sviluppo
    → Test L1 (unitari/integrazione) — SEMPRE
    → [se web app] Test L2 (browser smoke test) — SE CONFIGURATO
    → [se mobile] Test L3 (emulatore) — SE CONFIGURATO
    → Checkpoint/Report
    → Blocco successivo (o stop se fallito)
```

### Regole di arresto:

- **L1 fallisce**: il ciclo si ferma. Il blocco successivo non parte. Il fallimento viene documentato nel handoff.
- **L2/L3 fallisce**: il ciclo si ferma e notifica Villa con screenshot e log dell'errore. Il test unitario potrebbe non catturare regressioni visive — serve l'occhio umano (o quello di Claude via browser).
- **Tutto passa**: il ciclo procede automaticamente al blocco successivo, oppure si ferma al checkpoint configurato (dipende dal livello di automazione scelto).

**Raccomandazione**: Per ogni progetto, definire esplicitamente nella roadmap quali livelli di test si applicano a ciascun blocco. Non tutti i blocchi richiedono L2/L3 — un blocco che tocca solo il backend non ha bisogno di test browser.
