# Roadmap

> La roadmap è una **proposta di organizzazione del lavoro**: la specifica non prescrive fasi.

## Stato attuale

**Fase 0 — Definizione architetturale e valutazione.** Nessun codice di produzione. Il
repository contiene la specifica, la documentazione derivata, la valutazione preliminare e il
sistema ASDF minimo.

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

### Ordine consigliato

1. **QA-26** (target e obiettivi di latenza) e **QA-19** (piattaforma di riferimento): sono
   domande a cui si risponde senza esperimenti e fissano il metro di tutto il resto.
2. **SPK-02** (GC) e **SPK-01** (primary index): i due rischi che possono mettere in
   discussione le scelte di base.
3. **SPK-03** (WAL e group commit) insieme a **QA-02** e **QA-05**.
4. **SPK-07** (modelli dei protocolli) insieme a **QA-04, QA-06, QA-07, QA-09, QA-24**.
5. **QA-01, QA-03** e filone D (formati).
6. Spike restanti (SPK-04, SPK-05, SPK-06, SPK-08) e filone E (contratti).

### Criteri di uscita

- [ ] Tutte le questioni di priorità A sono chiuse da un ADR.
- [ ] SPK-01, SPK-02, SPK-03 eseguiti, con risultati riproducibili nel repository.
- [ ] I modelli dei protocolli non violano gli invarianti in nessuno degli scenari FI-01…FI-12.
- [ ] I formati persistenti sono documentati.
- [ ] Ogni rischio con esposizione alta ha una mitigazione decisa o è stato accettato
      esplicitamente.
- [ ] I target di [13 Benchmark](13-benchmark.md) sono confermati o rivisti alla luce di stime
      e spike.
- [ ] Decisione esplicita di procedere (o di rivedere l'architettura).

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
