# ADR-0013 — Storage log-structured: il segmento ACTIVE è il log dei dati; `wal/` è il control log della Serie

- **Stato:** Accettata (emenda la specifica); **sostituita in parte da [ADR-0037](0037-lotto-sigillato.md)**: un record è committed se sta in un lotto sigillato valido (punto 4); i tipi di record sono in [ADR-0039](0039-cornice-unica-dei-record.md).
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-02; **emenda** la sezione «WAL» e il ruolo di
  `wal/` nel «Layout fisico». Mantiene: WAL per Serie, nessun global data WAL, group commit,
  `multiserie.log` unico.
- **Riferimenti:** [architettura](../architettura.md#percorso-di-scrittura),
  [formati su disco](../formati-su-disco.md), INV-W1, INV-D1, INV-F1

## Contesto

La specifica prevede per ogni Serie un WAL e segmenti append-only. Se il record completo va in
entrambi, ogni byte è scritto due volte e la fascia alta dei target di INSERT supera la banda
di un dispositivo NVMe ([stime](../valutazione/stime-ordine-di-grandezza.md#banda-di-scrittura)).
Un WAL separato serve a proteggere strutture aggiornate in-place; con segmenti append-only è
ridondante.

## Decisione

1. **Il segmento `ACTIVE` è il log dei dati della Serie.** Ogni record (PUT, tombstone,
   PREPARE, COMMIT di gruppo, OUTCOME) è scritto **una sola volta**, nel segmento `ACTIVE`,
   con lunghezza e CRC32C. Il group commit esegue `write` + flush sul segmento `ACTIVE`.
2. **`wal/control.log` è il WAL della Serie**: un log append-only, write-ahead, dei soli
   cambiamenti *strutturali* — apertura e chiusura di segmenti, swap di compaction, cambi di
   stato, checkpoint. È piccolo e scritto raramente; usa group commit.
3. Il recovery dei dati di una Serie è la scansione del segmento `ACTIVE` dall'ultimo
   checkpoint; il recovery della struttura è il replay di `control.log`
   ([ADR-0018](0018-control-log-manifest-swap.md)).
4. Un record è committed se seguito, nello stesso segmento, da un record COMMIT di gruppo che
   lo elenca; un record PREPARE è committed se esiste un OUTCOME COMMIT per il suo TXID
   ([ADR-0021](0021-2pc-intenti-outcome.md)).

Pattern: log-structured storage con indice in memoria (Bitcask, Riak), dove il file dati è il
log; manifest separato per la struttura (LevelDB/RocksDB).

## Conseguenze

- Amplificazione di scrittura 1× sul percorso dei dati; un solo flush per gruppo.
- La parte della specifica che attribuisce al WAL «durability, recovery, ricostruzione dello
  stato, registrazione ordinata» resta vera per l'insieme «segmento ACTIVE + control log».
- Le transazioni abortite lasciano record morti nel segmento: li recupera il CLEAN.
- Il formato del record deve bastare al recovery senza indice (INV-F1).
- `multiserie.log` resta separato e invariato.

## Alternative considerate

- *Record completo nel WAL e poi nel segmento:* 2× scritture; scartata per banda.
- *WAL con soli riferimenti ai record nel segmento:* una scrittura, ma due file da sincronizzare
  in ordine a ogni gruppo (due flush): più complesso e più lento del log unico, senza vantaggi.

## Valutazione

- Rischi chiusi: RSK-03 (ridotto a 1×). Residuo: molti segmenti `ACTIVE` (uno per Serie)
  eseguono flush concorrenti — misura SPK-03.
- Verifica: FI-01, FI-02 (coda troncata → scartata dal CRC); SPK-07.
