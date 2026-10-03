# Registro delle decisioni architetturali (ADR)

Un ADR registra **una** decisione: contesto, scelta, conseguenze, e come se ne valuta la
tenuta. Gli ADR sono la memoria del progetto: spiegano perché l'architettura è fatta così.

## Regole

- Numerazione progressiva a quattro cifre; un ADR non si rinumera e non si cancella.
- Stati: **Proposta** → **Accettata** → eventualmente **Sostituita da ADR-nnnn** o
  **Ritirata**.
- Un ADR accettato non si riscrive: per cambiare decisione se ne scrive uno nuovo che
  sostituisce il precedente.
- Un ADR che emenda la [specifica](../specifica/prompt-originale.md) lo dichiara nel campo
  «Rapporto con la specifica».
- Ogni [questione aperta](../questioni-aperte.md) si chiude con un ADR.
- Modello: [0000-modello.md](0000-modello.md).

## Decisioni registrate

Gli ADR 0001–0012 registrano le decisioni **già contenute nella specifica v1**. Le sezioni
«Alternative» e «Valutazione» sono contributi della fase di valutazione, non parte della
specifica.

| ADR | Decisione | Stato |
|---|---|---|
| [0001](0001-common-lisp-sbcl.md) | Common Lisp/SBCL; solo Common Lisp per ora | Accettata (emenda la specifica) |
| [0002](0002-serie-unita-di-storage-e-parallelismo.md) | La Serie come unità di storage e parallelismo | Accettata |
| [0003](0003-wal-per-serie.md) | WAL per Serie, nessun global data WAL | Accettata |
| [0004](0004-storage-append-only-un-solo-active.md) | Storage append-only con un solo segmento ACTIVE | Accettata |
| [0005](0005-writer-logico-per-serie.md) | Un writer logico per Serie con controllo ottimistico | Accettata |
| [0006](0006-transazioni-multiserie-2pc.md) | Transazioni multiserie 2PC-like con un unico `multiserie.log` | Accettata |
| [0007](0007-clean-e-merge-distinti.md) | CLEAN e MERGE distinti, copy-on-write | Accettata |
| [0008](0008-merge-opportunistico.md) | MERGE opportunistico: 50 s di stabilità + basso carico | Accettata |
| [0009](0009-indici-immutabili-atomic-swap.md) | Indici immutabili per i reader, atomic swap | Accettata |
| [0010](0010-cache-clock.md) | Cache CLOCK, partizionabile per Serie | Accettata |
| [0011](0011-thread-pool-dinamico.md) | Thread pool dinamico con EWMA/AIMD/isteresi | Accettata |
| [0012](0012-simd-guidato-dai-benchmark.md) | SIMD solo dove i benchmark lo giustificano | Accettata |

## Decisioni di progetto (Fase 0, 2026-10-03)

Chiudono le [questioni aperte](../questioni-aperte.md). Ogni ADR cita il pattern adottato e
dove è usato in produzione ([principi di ingegneria](../principi-di-ingegneria.md)). Il
risultato consolidato è in [architettura.md](../architettura.md) e
[formati-su-disco.md](../formati-su-disco.md).

| ADR | Decisione | Chiude | Stato |
|---|---|---|---|
| [0013](0013-log-structured-segmento-active-come-log.md) | Il segmento ACTIVE è il log dei dati; `wal/` è il control log | QA-02 | Accettata (emenda la specifica) |
| [0014](0014-formato-record-documento-id.md) | Record binario con CRC32C, documenti CBOR, `_id` 1–255 byte | QA-01 | Accettata |
| [0015](0015-primary-index-swiss-table-swmr.md) | Primary index Swiss SWMR, seqlock per slot, versioni trattenute, hint per segmento | QA-24, QA-03 | Accettata |
| [0016](0016-epoch-based-reclamation.md) | Epoch-based reclamation | QA-16 | Accettata |
| [0017](0017-piattaforma-e-io.md) | Linux x86-64 di riferimento; I/O bloccante su pool dedicato; `durable-flush` | QA-19 | Accettata |
| [0018](0018-control-log-manifest-swap.md) | Control log come manifest; `SWAP` come record unico; stabilizzazione | QA-04, QA-13 | Accettata |
| [0019](0019-durability-e-group-commit-pipelined.md) | Livelli `:async`/`:group`/`:strong`; group commit pipelined | QA-05 | Accettata |
| [0020](0020-csn-snapshot-isolamento.md) | CSN di Archivio; snapshot = numero; SI + `:serializable`; `snapshot-too-old` | QA-06, QA-09, QA-14 | Accettata |
| [0021](0021-2pc-intenti-outcome.md) | 2PC con intenti no-wait, record OUTCOME, presumed abort, troncamento | QA-07, QA-08 | Accettata |
| [0022](0022-registri-come-serie-catalogo.md) | Registri è una Serie; catalogo di documenti; bootstrap | QA-10 | Accettata |
| [0023](0023-politiche-di-compaction.md) | Soglie, stati di carico, limitatore di banda, tombstone per lineage | QA-11, QA-12, QA-15 | Accettata |
| [0024](0024-memoria-e-gc.md) | Array specializzati a vita lunga; zero allocazione sul hot path | QA-18 | Accettata |
| [0025](0025-cache-per-location.md) | Cache per location, arena a slot, CLOCK per partizione | QA-17 | Accettata |
| [0026](0026-indici-secondari-segmentati.md) | Indici secondari per segmento, formato fisso, delta in memoria | QA-25 | Accettata |
| [0027](0027-dipendenze-e-test.md) | Nessuna dipendenza esterna; harness proprio | QA-22 | Accettata |
| [0028](0028-target-e-obiettivi-di-latenza.md) | Target aggregati; obiettivi numerici di latenza e di pausa GC | QA-26 | **Proposta** |
| [0029](0029-interfacce-protocollo-query-contratto.md) | Protocollo a frame CBOR; query come dati; contratto additivo | QA-20, QA-21 | Accettata |
| [0030](0030-scope-v1.md) | Scope della v1 | QA-23 | **Proposta** |
