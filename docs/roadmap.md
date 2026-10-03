# Roadmap

> La roadmap è una **proposta di organizzazione del lavoro**: la specifica non prescrive fasi.

## Stato attuale

**Fase 0 — Definizione architetturale e valutazione.** Nessun codice di produzione.

Al 2026-10-03 la parte di **definizione è completa**: le 26 questioni aperte sono chiuse dagli
ADR 0013–0030, il progetto è consolidato in [architettura.md](architettura.md) e i formati in
[formati-su-disco.md](formati-su-disco.md). Restano: la conferma dell'autore su ADR-0028 e
ADR-0030, e la parte di **valutazione sperimentale** (spike SPK-01, SPK-02, SPK-03 e modello
SPK-07).

## Fase 0 — Definizione architetturale e valutazione

Scopo: arrivare all'implementazione con le decisioni strutturali prese, i rischi principali
misurati e i protocolli critici verificati su modello.

### Filoni di lavoro

| Filone | Attività | Risultato |
|---|---|---|
| **A. Decisioni** | Chiudere le [questioni aperte](questioni-aperte.md) di priorità A | Un ADR per ciascuna |
| **B. Spike** | Eseguire gli [spike](valutazione/piano-spike.md) in ordine di rischio | Misure e raccomandazioni in `spikes/` |
| **C. Modelli** | Descrivere come macchine a stati 2PC + recovery e compaction + swap + reclaim; esplorarne i crash | Protocolli verificati rispetto agli [invarianti](invarianti.md) |
| **D. Formati** | Definire i formati persistenti: record, WAL, segmento, manifest, `multiserie.log`, catalogo | Documento dei formati su disco |
| **E. Contratti** | Definire le interfacce tra i [moduli](16-moduli.md#contratti-tra-moduli) | Contratto per modulo |
| **F. Valutazione** | Aggiornare [registro rischi](valutazione/registro-rischi.md) e [stime](valutazione/stime-ordine-di-grandezza.md) con i risultati | Verdetto di fattibilità |

### Ordine consigliato (parte restante)

1. Conferma di **ADR-0028** (target, latenze, pausa GC ≤ 5 ms) e **ADR-0030** (scope).
2. **SPK-02** (GC) e **SPK-01** (primary index): i due rischi che possono mettere in
   discussione le scelte di base.
3. **SPK-07** (modello di 2PC + compaction/swap/reclaim con crash in ogni punto).
4. **SPK-03** (flush concorrenti di molte Serie).
5. Spike restanti (SPK-04, SPK-05, SPK-06, SPK-08), eseguibili anche durante la Fase 1.

### Criteri di uscita

- [x] Tutte le questioni di priorità A sono chiuse da un ADR (2026-10-03).
- [x] I formati persistenti sono documentati ([formati-su-disco.md](formati-su-disco.md)).
- [x] Ogni rischio con esposizione alta ha una mitigazione decisa o è stato accettato
      esplicitamente ([registro](valutazione/registro-rischi.md#stato-dopo-gli-adr-2026-10-03)).
- [x] I contratti tra moduli sono definiti ([architettura](architettura.md#contratti)).
- [ ] ADR-0028 e ADR-0030 confermati dall'autore.
- [ ] SPK-01, SPK-02, SPK-03 eseguiti, con risultati riproducibili nel repository.
- [ ] Il modello SPK-07 non viola gli invarianti in nessuno degli scenari FI-01…FI-13.
- [ ] I target di [13 Benchmark](13-benchmark.md) sono confermati o rivisti alla luce di stime
      e spike.
- [ ] Decisione esplicita di procedere alla Fase 1.

## Fasi successive (schema)

L'ordine segue due principi: una **fetta verticale** funzionante il prima possibile e
l'infrastruttura di **fault injection** prima dei protocolli che deve verificare. Il dettaglio
si definisce alla chiusura della Fase 0.

| Fase | Contenuto | Moduli | Verifica |
|---|---|---|---|
| 1 | Una Serie: WAL, segmento ACTIVE, rotazione, primary index, GET/PUT/DELETE, recovery dal WAL; strato di I/O con fault injection | M01–M05, M12, io | FI-01, FI-02, FI-10 |
| 2 | Group commit, livelli di durability, cache, metriche | M02, M07, metrics | benchmark di base |
| 3 | Snapshot/MVCC e transazioni single-Series | M08, M09 | FI-11 |
| 4 | CLEAN, swap, reclaim | M11, M04 | FI-06, FI-07, FI-09 |
| 5 | Archivio, Registri, catalogo, più Serie; writer logici su thread pool dinamico; scheduler | M13, M14, M17 | benchmark di isolamento tra Serie |
| 6 | Transazioni multiserie e `multiserie.log` | M09, M10 | FI-03, FI-04, FI-05, FI-12 |
| 7 | MERGE, low-load policy, Compaction Scheduler | M11, M13 | FI-08, benchmark di interferenza |
| 8 | Indici secondari e Query Engine | M06, M15 | — |
| 9 | Protocollo di rete e server | M16 | — |
| 10 | Campagna di benchmark; ottimizzazioni sugli hot path misurati | M18 | [13 Benchmark](13-benchmark.md) |
