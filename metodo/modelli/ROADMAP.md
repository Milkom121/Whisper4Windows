# Roadmap — [NomeProgetto]

> Piano di sviluppo in fasi e blocchi (vedi `.claude/metodo-villa/10-sizing-blocchi.md`).
> Segna `[x]` completato, `[>]` in corso, `[ ]` da fare.
> Natura del blocco: 🤖 autonomo (runner) · 👤 umano · 🤝 collaborativo (con Villa).
>
> **Questa roadmap la scrive la discovery**, dopo che Villa ha raccontato cos'e' il
> progetto. Finche' resta cosi', il runner non ha niente da eseguire — ed e' giusto.

---

## Fase 0 — Fondamenta

### Blocco 0.1 — [titolo del primo blocco] 🤝
- [ ] [che cosa produce questo blocco, in una riga]
  - **Gate di uscita**: [come si capisce che e' finito: quale verifica passa]

---

## Come si scrive un blocco

**Un blocco = una modifica coerente con UNA SOLA verifica.** Se per chiuderlo
servono due suite di prove diverse, sono due blocchi (capitolo 10).

Ogni blocco porta un'etichetta che dice **chi puo' eseguirlo**:

| | Chi | Esempi |
|---|---|---|
| 🤖 | Il runner, da solo | codice, documentazione, test, configurazione |
| 👤 | Serve Villa di persona | deploy fisico, telefonate, codici via SMS |
| 🤝 | Sessione con Claude | decisioni di design, kickoff, prove esplorative |

I blocchi 👤 e 🤝 vanno **in testa o in coda a una fase, mai in mezzo** a una
sequenza autonoma: altrimenti il runner si ferma a meta' corsa (capitolo 14).
