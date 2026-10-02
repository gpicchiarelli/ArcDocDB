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

## Decisioni attese

ADR da produrre nella [Fase 0](../roadmap.md) per chiudere le questioni di priorità A.

| Tema | Questioni |
|---|---|
| Target per Serie/aggregati e obiettivi numerici di latenza | QA-26 |
| Piattaforma di riferimento e primitive di I/O | QA-19 |
| Modello di memoria: heap gestito e memoria esterna | QA-18 |
| Formato di record, documento e `_id` | QA-01 |
| Rapporto WAL ↔ segmenti | QA-02 |
| Livelli di durability | QA-05 |
| Primary index: struttura, concorrenza, MVCC, persistenza | QA-24, QA-03 |
| Manifest dei segmenti e meccanismo dello swap | QA-04 |
| Ordine di commit di Archivio e snapshot multiserie | QA-06 |
| Stato PREPARED e livelli di isolamento | QA-07, QA-09 |
