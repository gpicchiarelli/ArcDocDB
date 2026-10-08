# 01 — Visione e obiettivi

> **Fonte:** introduzione e «Obiettivo finale» della [specifica](specifica/specifica-originale.md).

## Che cos'è

ArcDocDB è un database server **documentale general-purpose**, scritto principalmente in Common
Lisp con **SBCL** come implementazione di riferimento. Non è pensato per un dominio applicativo
specifico (non è un motore per blogging o CMS).

## Obiettivi

| Obiettivo | Come la specifica intende ottenerlo | Documento |
|---|---|---|
| Velocità elevata sulle operazioni fondamentali | Hot path corto: primary index in RAM, storage append-only, cache | [03](03-storage.md), [08](08-indici.md), [09](09-cache.md) |
| Forte parallelismo tra Serie indipendenti | La Serie è l'unità di storage e di parallelismo: WAL, segmenti e indici propri | [02](02-modello-logico.md), [10](10-concorrenza-e-scheduling.md) |
| Bassa latenza P95/P99 | Scheduler dinamico, compaction subordinata al traffico utente | [10](10-concorrenza-e-scheduling.md), [07](07-compaction.md) |
| Scalabilità su multicore e NVMe | Un writer logico per Serie, molti reader, compaction parallela | [10](10-concorrenza-e-scheduling.md) |
| WAL affidabile | WAL per Serie con group commit | [04](04-wal-e-durability.md) |
| Transazioni locali e multiserie | OCC sul writer della Serie; protocollo 2PC-like con `multiserie.log` | [05](05-transazioni.md) |
| MVCC/snapshot | Snapshot logici sopra lo storage append-only | [06](06-mvcc-e-snapshot.md) |
| Compaction concorrente | CLEAN e MERGE copy-on-write, parallelizzabili | [07](07-compaction.md) |
| Tenuta sotto burst di letture | Isolamento per Serie, cache partizionabile, MERGE opportunistico | [09](09-cache.md), [07](07-compaction.md) |

L'obiettivo finale, nelle parole della specifica: un hot path molto efficiente per le operazioni
comuni, forte parallelismo tra Serie, storage append-only crash-safe, compaction copy-on-write e
adattiva, transazioni locali e multiserie robuste, e **comportamento prevedibile** sotto carichi
misti e improvvisi burst di lettura.

## Non-obiettivi

Dichiarati dalla specifica:

- **Non** è un motore specializzato per blogging/CMS.
- **Non** si dichiara superiorità su Oracle, MySQL/InnoDB o MongoDB sulla base di benchmark
  eterogenei: il vantaggio del percorso corto è un'**ipotesi architetturale da verificare**
  (vedi [13 Benchmark](13-benchmark.md)).
- I [target preliminari](13-benchmark.md#target-preliminari) **non** sono risultati dimostrati.

> **Deciso (QA-23 → [ADR-0030](adr/0030-scope-v1.md))** — La specifica non menziona replica, backup, autenticazione/autorizzazione
> né cifratura. Finché non viene deciso diversamente si considerano fuori dallo scope della v1.

## Le scelte che definiscono il progetto

Sono le decisioni da cui discende tutto il resto; ciascuna ha un ADR.

> **Deciso ([ADR-0036](adr/0036-leggi-di-progetto.md))** — Il **parallelismo è un principio
> fondante**: non un obiettivo di prestazione ma la forma in cui lo stato è diviso. Le Serie
> non si attendono mai; ciò che condividono è un elenco chiuso, mai pagato per singola
> operazione (INV-P6). È la prima delle dieci [leggi](analisi-progettuale.md#le-leggi) da cui
> discendono i meccanismi del progetto.

1. Common Lisp/SBCL per la logica generale ([ADR-0001](adr/0001-common-lisp-sbcl.md)).
2. La Serie come unità di storage e parallelismo ([ADR-0002](adr/0002-serie-unita-di-storage-e-parallelismo.md)).
3. WAL per Serie, nessun global data WAL ([ADR-0003](adr/0003-wal-per-serie.md)).
4. Storage append-only con un solo segmento ACTIVE ([ADR-0004](adr/0004-storage-append-only-un-solo-active.md)).
5. Un writer logico per Serie con controllo ottimistico delle versioni ([ADR-0005](adr/0005-writer-logico-per-serie.md)).
6. Transazioni multiserie 2PC-like con un unico `multiserie.log` ([ADR-0006](adr/0006-transazioni-multiserie-2pc.md)).
7. CLEAN e MERGE come operazioni distinte, copy-on-write ([ADR-0007](adr/0007-clean-e-merge-distinti.md)).
8. MERGE opportunistico: 50 s di stabilità + basso carico ([ADR-0008](adr/0008-merge-opportunistico.md)).
9. Indici immutabili per i reader, con atomic swap ([ADR-0009](adr/0009-indici-immutabili-atomic-swap.md)).
10. Cache CLOCK, partizionabile per Serie ([ADR-0010](adr/0010-cache-clock.md)).
11. Thread pool dinamico con EWMA/AIMD/isteresi ([ADR-0011](adr/0011-thread-pool-dinamico.md)).
12. SIMD solo dove i benchmark lo giustificano ([ADR-0012](adr/0012-simd-guidato-dai-benchmark.md)).
