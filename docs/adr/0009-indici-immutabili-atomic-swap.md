# ADR-0009 — Indici immutabili per i reader, atomic swap

- **Stato:** Accettata
- **Data:** 2026-10-01
- **Rapporto con la specifica:** registra una decisione della specifica («Index», «Secondary
  index», «Secondary index delta», «Index snapshot»)
- **Riferimenti:** [08 Indici](../08-indici.md), INV-I1, INV-I2

## Contesto

Letture e scritture devono procedere senza bloccarsi a vicenda, e la compaction deve poter
sostituire segmenti senza fermare i reader.

## Decisione

- Primary index `_id → location` (segment-id, offset, length, version), in RAM, ottimizzato
  per lookup O(1) medio; struttura compatta (valutare una Swiss Table), senza un oggetto Lisp
  per entry.
- Indici secondari specializzati per tipo di query: ART per stringhe/prefix, B+ tree o
  equivalente per intervalli, posting lists per categorie, bitmap per bassa cardinalità.
- Bloom filter per segmento solo come test di assenza, mai come localizzazione definitiva.
- Indici secondari con modifiche frequenti: base + delta immutabili, fusione asincrona.
- Gli indici sono immutabili per i reader: una nuova versione diventa visibile con un atomic
  swap; i reader già attivi completano sulla versione precedente.

## Conseguenze

- I reader non prendono lock sugli indici.
- Le versioni vecchie di un indice vanno trattenute finché hanno reader: stesso problema di
  reclaim dei segmenti.
- Il primary index deve stare in RAM: limite di capacità e tempo di riavvio.
- Per il primary index, aggiornato a ogni scrittura, il modello «nuova versione + swap» non è
  applicabile alla lettera: va definito il meccanismo equivalente.

## Alternative considerate

- *Indici mutabili protetti da lock in lettura/scrittura:* semplici, ma i reader contendono
  con il writer e con la compaction.
- *Primary index su disco:* nessun limite di RAM, ma almeno una lettura in più per GET.

## Valutazione

- Rischi: RSK-02, RSK-07, RSK-13.
- Verifica: SPK-01 (prototipo del primary index), SPK-07 (modello dello swap); FI-06, FI-10.
- Aperto: QA-24 (meccanismo per il primary index), QA-03 (persistenza), QA-25 (indici
  secondari), QA-16 (tracciamento dei reader).
