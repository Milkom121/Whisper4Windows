# Validazione multi-agente di artefatti importanti

> **Nuovo in v2** (aggiunto 2026-05-29, lezione dal progetto SenilCure).
>
> Prima di "sigillare" un artefatto importante e costoso da sbagliare — **una roadmap corposa**, un design architetturale, un piano di migrazione — non fidarsi della propria stesura. Farla validare da **più agenti freschi, a contesto pulito, con prospettive diverse**, e correggere prima di procedere.

## Perché

Chi ha scritto l'artefatto è **cieco ai propri errori e alle proprie assunzioni**: percorsi di file dati per scontati, decisioni assunte come prese, dettagli impliciti che "si capiscono". Un revisore **senza il contesto pregresso** vede esattamente ciò che manca o non torna, perché non può colmare i buchi con la memoria della conversazione.

La **diversità di prospettive** pesca più classi di problemi della semplice ripetizione: tre revisori con tre lenti diverse trovano più cose di tre revisori identici.

## Quando applicarla (e quando no)

- **SÌ**: roadmap che il runner eseguirà per molte ore; design di un modulo nuovo; piano di refactor ampio; qualsiasi artefatto dove un errore non visto si paga caro a valle (il runner che lavora ore su basi sbagliate).
- **NO**: una modifica piccola, un documento di lavoro interno. Sarebbe spreco.
- **Sul singolo blocco non serve un collegio, ma un occhio da fuori sì**: il guardiano di blocco è auto-review, cioè la stessa cecità descritta qui sopra applicata al posto da cui passa tutto il lavoro. Ci pensa **l'occhio esterno** (cap. 05), che guarda solo il compito e la differenza e costa una frazione del blocco. Fino al 2026-08-22 questa riga diceva che «per il blocco basta il guardiano di blocco»: era l'eccezione che svuotava il capitolo.

Regola pratica: **più è lungo e autonomo il lavoro che dipende dall'artefatto, più vale la validazione multi-agente prima di lanciarlo.**

## Come si fa

1. **Scrivi l'artefatto** per intero (es. la sotto-roadmap dell'ondata).
2. **Lancia 2-4 agenti freschi in parallelo**, ognuno con una **prospettiva diversa** e a contesto pulito (non devono ereditare le tue assunzioni). Per una roadmap, le tre lenti collaudate sono:
   - **Fattibilità tecnica / coerenza col codice reale**: i file, le funzioni, i percorsi citati esistono e sono come descritti? Le estensioni proposte combaciano col modello dati attuale? Le dipendenze tra blocchi reggono?
   - **Idoneità all'esecuzione autonoma (runner)**: ogni blocco rispetta "1 blocco = 1 verifica" (cap. 10)? I blocchi umani/collaborativi sono in coda e non in mezzo (cap. 14)? I gate sono concreti e verificabili da una macchina? Ci sono blocchi troppo grandi da spezzare?
   - **Coerenza con le decisioni prese, le regole di progetto e i confini dell'ecosistema**: rispetta le decisioni di Villa? Non mette nel modulo cose che spettano ad altri moduli? Rispetta multi-tenant/audit/eventi e le regole permanenti? Manca qualche feedback/requisito già deciso?
   - (varia le lenti secondo l'artefatto: per un design, aggiungi sicurezza, performance, manutenibilità.)
3. **Ogni agente riferisce una lista di problemi** con gravità (alta/media/bassa) + correzione suggerita. NON riscrive l'artefatto: solo segnala.
4. **L'autore sintetizza e corregge con giudizio**: non tutti i rilievi sono validi — alcuni nascono dal fatto che il revisore non ha contesto. Applica quelli reali, scarta quelli infondati (motivando), e **annota in fondo all'artefatto le correzioni applicate**.

## Cosa dare agli agenti

- Il percorso dell'artefatto da validare.
- I percorsi delle **fonti** che devono incrociare (codice reale, documenti di decisione, regole di progetto, perimetro dell'ecosistema).
- Il vincolo privacy (niente PII reale).
- Il formato di risposta: lista concisa di problemi `[gravità] descrizione + file/blocco + correzione`, niente riscrittura.

## Esempio reale (SenilCure, 2026-05-29)

Roadmap "Ondata 3" (19 blocchi per il runner) validata da 3 revisori freschi prima del lancio. Hanno trovato: **percorsi di file errati** (nomi ereditati da una vecchia roadmap, mai verificati), **due blocchi troppo grandi** da spezzare (violavano "1 blocco = 1 verifica"), **gate troppo vaghi** per una macchina, **dipendenze tra blocchi non dichiarate**. Tutto corretto prima di lanciare il runner — errori che, non visti, avrebbero fatto sbagliare il runner per ore. Nessuna di queste cose era visibile all'autore della roadmap.

## Relazione con altri capitoli

- Estende il **pensiero critico** (cap. 01) e i **guardiani** (cap. 05) al livello della *pianificazione*, non solo del codice.
- Si appoggia a **sizing** (cap. 10) e **sequencing** (cap. 14) come criteri che i revisori verificano.
- È il passo che chiude la scrittura di una sotto-roadmap prima del lancio del runner (cap. 03).
