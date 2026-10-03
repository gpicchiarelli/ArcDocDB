# ADR-0018 — Control log della Serie: manifest dei segmenti e swap atomico

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-04 e QA-13; realizza INV-C7, INV-C8, INV-C9
- **Riferimenti:** [formati su disco](../formati-su-disco.md#control-log),
  [architettura](../architettura.md#compaction), [ADR-0013](0013-log-structured-segmento-active-come-log.md)

## Contesto

Serve una registrazione autorevole e atomica dell'insieme dei segmenti validi di una Serie,
così che un crash in qualsiasi punto del workflow di compaction sia riconoscibile e risolvibile.

## Decisione

1. **`wal/control.log`** è un log append-only di record `{seq, tipo, payload, CRC32C}`:
   `SEG-OPEN`, `SEG-CLOSE`, `SWAP`, `SEG-OBSOLETE`, `SEG-RECLAIMABLE`, `SEG-DELETED`,
   `CHECKPOINT`. Lo scrive solo il writer logico della Serie, con group commit.
2. **Lo stato di un segmento è l'ultimo record che lo riguarda.** Lo stato fisico di `ACTIVE`
   è l'ultimo `SEG-OPEN` senza `SEG-CLOSE`.
3. **Swap = un record.** `SWAP {op-id, output: [id…], sources: [id…], lineage-min}` è
   l'unico punto di atomicità della compaction: prima del record gli output sono invisibili,
   dopo sono definitivi e i sorgenti sono `OBSOLETE`. Il record è scritto solo dopo che gli
   output (segmento + hint + indici) sono stati flushati e rinominati da `.tmp` al nome finale,
   con `fsync` della directory.
4. **Rilocazione dopo lo swap.** Le rilocazioni condizionali dell'indice
   ([ADR-0015](0015-primary-index-swiss-table-swmr.md)) seguono il record `SWAP`; se il
   processo cade tra i due, al riavvio l'indice si ricostruisce dagli hint degli output.
5. **Compattazione del log.** Quando supera una soglia, il writer scrive `control.log.new`
   con un solo `CHECKPOINT` che elenca l'insieme corrente dei segmenti con stato, timestamp e
   lineage, lo flusha, lo rinomina sopra l'originale e sincronizza la directory.
6. **Timestamp di stabilizzazione** (per la regola dei 50 s): l'istante del record
   `SEG-CLOSE` o `SWAP` che ha reso il segmento immutabile, da orologio monotono, memorizzato
   nel record. Dopo un riavvio i segmenti usano l'istante di fine recovery.
7. Al riavvio, i file `.tmp` e i segmenti non menzionati dal log sono orfani e vengono
   eliminati.

Pattern: MANIFEST + CURRENT (LevelDB/RocksDB); rinomina atomica + fsync della directory.

## Conseguenze

- Ogni riga della [tabella dei crash](../11-recovery.md#casi-di-compaction-interrotta) ha
  una risposta deterministica.
- Un solo meccanismo di durability strutturale per Serie, nello stesso ordine totale delle
  scritture (il writer).
- Il log è piccolo: un record per evento strutturale, non per scrittura.

## Alternative considerate

- *Manifest riscritto per intero a ogni evento:* semplice ma O(segmenti) per evento.
- *Record di swap nel log dei dati:* mescola struttura e dati; il log dei dati ruota.

## Valutazione

- Verifica: FI-06, FI-07, FI-08, FI-09; modello in SPK-07.
