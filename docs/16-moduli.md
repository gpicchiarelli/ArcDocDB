# 16 — Moduli software

> **Fonte:** «Moduli software» della [specifica](specifica/prompt-originale.md).

La specifica chiede di organizzare il sistema **almeno** nei 18 moduli seguenti. Gli
identificativi `M01…M18` seguono l'ordine della specifica.

## Elenco e responsabilità

| ID | Modulo | Responsabilità | Documento |
|---|---|---|---|
| M01 | Storage Engine | Facciata per Serie: coordina WAL, segmenti, indice, cache sul percorso di lettura e scrittura | [03](03-storage.md) |
| M02 | WAL Manager | WAL per Serie: append ordinato, group commit, flush, replay | [04](04-wal-e-durability.md) |
| M03 | Segment Manager | Ciclo di vita dei segmenti: ACTIVE unico, rotazione, stati, lettura | [03](03-storage.md) |
| M04 | Segment Metadata Manager | Contatori live/dead e tempi; dati derivati, ricostruibili | [03](03-storage.md#segment-metadata) |
| M05 | Primary Index Manager | `_id → location`, tabella compatta in RAM | [08](08-indici.md) |
| M06 | Secondary Index Manager | ART, B+ tree, posting lists, bitmap, Bloom; base + delta | [08](08-indici.md#indici-secondari) |
| M07 | Cache Manager | CLOCK, partizionamento per Serie, consapevolezza delle versioni | [09](09-cache.md) |
| M08 | Snapshot/MVCC Manager | Snapshot logici, visibilità, protezione delle versioni dal reclaim | [06](06-mvcc-e-snapshot.md) |
| M09 | Transaction Manager | Transazioni single-Series (OCC) e coordinamento multiserie | [05](05-transazioni.md) |
| M10 | Multiseries Transaction Log Manager | `Registri/multiserie.log`: decisioni durevoli, group commit | [05](05-transazioni.md#multiserielog) |
| M11 | Compaction Manager | CLEAN, MERGE, selezione candidati, swap, reclaim | [07](07-compaction.md) |
| M12 | Recovery Manager | Ripartenza dopo crash | [11](11-recovery.md) |
| M13 | Scheduler | Controllo del carico: request scheduler e Compaction Scheduler | [10](10-concorrenza-e-scheduling.md) |
| M14 | Dynamic Thread Pool | Worker riutilizzati, dimensionamento dinamico | [10](10-concorrenza-e-scheduling.md#thread-pool-dinamico) |
| M15 | Query Engine | Esecuzione di query su indici e scansioni | [08](08-indici.md) |
| M16 | Network/Protocol Layer | Connessioni e protocollo | — (QA-20) |
| M17 | Archivio/Serie/Documento Catalog Manager | Catalogo in `Registri/catalog/`, transazionale | [02](02-modello-logico.md#catalogo) |
| M18 | SIMD/Hot Path Optimization Layer | Primitive ottimizzate per gli hot path | [15](15-ottimizzazioni-native.md) |

> **Proposta** — Due moduli di supporto non elencati nella specifica ma necessari:
> **metrics** (richiesto dalla sezione Osservabilità e usato dai controllori) e **io**
> (interfaccia unica verso file e `fsync`, necessaria al fault injection, vedi
> [14](14-fault-injection.md#implicazioni-architetturali)).

## Stratificazione

> **Proposta** — Dipendenze ammesse solo dall'alto verso il basso. Serve a mantenere i moduli
> verificabili in isolamento e a evitare cicli tra package.

```
Strato 5 — accesso        M16 Network/Protocol
                          M15 Query Engine
Strato 4 — coordinamento  M09 Transaction    M11 Compaction    M12 Recovery    M17 Catalog
Strato 3 — Serie          M01 Storage Engine    M08 Snapshot/MVCC    M10 Multiseries Log
Strato 2 — strutture      M02 WAL    M03 Segment    M04 Segment Metadata
                          M05 Primary Index    M06 Secondary Index    M07 Cache
Strato 1 — runtime        M13 Scheduler    M14 Thread Pool
Strato 0 — base           M18 Hot Path    metrics    io
```

Dipendenze che attraversano gli strati e meritano attenzione:

| Relazione | Perché è delicata |
|---|---|
| M11 Compaction ↔ M05 Primary Index ↔ writer della Serie (M01) | lo swap modifica l'indice mentre il writer lo aggiorna (QA-24) |
| M11 Compaction → M08 MVCC | decide quali versioni sono necessarie e quando un segmento è reclamabile |
| M09 Transaction → M10 Multiseries Log → M02 WAL | ordine dei flush nel 2PC (INV-T3) |
| M12 Recovery → quasi tutto | deve conoscere i formati di ogni struttura persistente |
| M13 Scheduler ← metrics ← tutti | i controllori dipendono da misure prodotte ovunque |
| M17 Catalog → M01 Storage Engine | se Registri è una Serie, il catalogo usa lo storage che esso stesso descrive (QA-10) |

## Organizzazione del codice

> **Proposta** — Un package Common Lisp per modulo (`arcdocdb.wal`, `arcdocdb.segment`, …), un
> sistema ASDF `arcdocdb` e un sistema di test `arcdocdb/tests`. Per ora il repository contiene
> solo il sistema minimo (`arcdocdb.asd`, [`src/package.lisp`](../src/package.lisp)): la
> suddivisione in package si introduce con la prima milestone di implementazione, quando le
> interfacce tra moduli saranno fissate dalle decisioni della [Fase 0](roadmap.md).

Il codice è **solo Common Lisp** ([ADR-0001](adr/0001-common-lisp-sbcl.md)).

## Contratti tra moduli

Definire le interfacce è un risultato atteso della fase di definizione architetturale. Per
ogni modulo va prodotto, prima dell'implementazione:

- le operazioni offerte e i loro effetti durevoli;
- gli invarianti che il modulo garantisce e quelli che assume dagli altri;
- il modello di concorrenza (chi può chiamare che cosa, da quale contesto: writer della Serie,
  reader, worker di compaction);
- i formati persistenti di cui è proprietario;
- i punti di crash esposti al fault injection.
