# ADR-0004 — Storage append-only con un solo segmento ACTIVE

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («Storage
  append-only», «Segmenti», «Segment metadata»)
- **Riferimenti:** [03 Storage](../03-storage.md), INV-S1…INV-S6

## Contesto

Servono scritture veloci su NVMe, versioni storiche per MVCC e crash-safety semplice da
dimostrare.

## Decisione

- Lo storage è append-only: nessuna modifica in-place.
- Ogni Serie ha esattamente un segmento `ACTIVE`, l'unico scrivibile.
- Un segmento che lascia lo stato `ACTIVE` è immutabile per sempre e non viene riaperto.
- Le nuove scritture vanno sempre in un nuovo `ACTIVE`; mai in un segmento prodotto dalla
  compaction.
- Dimensione target dei segmenti creati dal writer: ~256 MB, configurabile per Serie.
- Stati: `ACTIVE → CLOSED → OBSOLETE → RECLAIMABLE → DELETED`.
- I segment metadata sono dati derivati, ricostruibili.

## Conseguenze

- Scritture sequenziali; le versioni vecchie restano disponibili per gli snapshot senza costi
  aggiuntivi.
- Un file immutabile non può essere corrotto da una scrittura interrotta: la crash-safety
  riguarda solo il segmento `ACTIVE` e i cambi di stato.
- Lo spazio morto si accumula: serve la compaction ([ADR-0007](0007-clean-e-merge-distinti.md)).
- I segmenti immutabili sono facili da mettere in cache, copiare, verificare.
- Ogni lettura passa da un indice che deve conoscere la location corrente.

## Alternative considerate

- *Aggiornamento in-place (B-tree su pagine):* letture senza indice in RAM, ma scritture
  casuali, pagine da proteggere dalle scritture parziali e nessuna versione storica gratuita.
- *LSM-tree con run ordinati:* non richiede l'indice in RAM, ma comporta compaction a livelli
  e letture su più livelli.

## Valutazione

- Rischi: RSK-03 (banda di scrittura), RSK-07 (indice in RAM), RSK-09 (spazio trattenuto).
- Verifica: scenari FI-01, FI-02; stime sulla
  [rotazione](../valutazione/stime-ordine-di-grandezza.md#rotazione-dei-segmenti).
- Aperto: formato dei record (QA-01), rapporto con il WAL (QA-02), manifest (QA-04).
