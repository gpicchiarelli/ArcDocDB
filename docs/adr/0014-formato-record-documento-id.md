# ADR-0014 — Formato di record, documento e `_id`

- **Stato:** Accettata; **sostituita in parte da [ADR-0039](0039-cornice-unica-dei-record.md)**: intestazione a 24 byte con due CRC, tipi PUT, TOMBSTONE, SEAL, OUTCOME (punto 3). Documento, `_id` e hash restano.
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-01
- **Riferimenti:** [formati su disco](../formati-su-disco.md#cornice-del-record), INV-F1

## Contesto

Il record è l'unità scritta nei segmenti; deve essere leggibile in sequenza senza indice
(recovery, CLEAN, scansioni), verificabile, e compatto per l'indice in memoria.

## Decisione

1. **Documento.** Lo storage tratta il documento come **bytes opachi**. La codifica canonica
   del Query Engine e del protocollo è **CBOR (RFC 8949)** in codifica deterministica: binaria,
   standard, autodescrittiva, implementabile in poche centinaia di righe di Common Lisp, con
   interi, stringhe, bytes, array, mappe, date e tag per i tipi estesi.
2. **`_id`.** Sequenza di byte di lunghezza 1–255 scelta dal client o generata dal server. Il
   confronto è bytewise. Un `_id` generato è un identificatore a 16 byte ordinabile per tempo
   (timestamp + casuale, nello stile ULID), che favorisce la località nelle scansioni.
3. **Record.** Intestazione binaria a lunghezza fissa (little-endian), chiave, valore, CRC32C
   (Castagnoli) su tutto il record. Tipi: PUT, TOMBSTONE, PREPARE, COMMIT-GROUP, OUTCOME.
   Dettaglio in [formati su disco](../formati-su-disco.md#cornice-del-record). Dimensione massima di un
   record: **16 MiB − 1** (limite della location nell'indice,
   [ADR-0015](0015-primary-index-swiss-table-swmr.md)); dimensione massima del documento
   configurabile per Serie, default 4 MiB ([limiti](../limiti.md)).
4. **Indice.** L'indice conserva un hash a 64 bit della chiave e un riferimento alla chiave in
   una **key arena** in memoria; la verifica della chiave avviene in RAM, mai leggendo il
   record ([ADR-0015](0015-primary-index-swiss-table-swmr.md)).
5. **Hash.** Funzione a 64 bit non crittografica con seme per Serie (stile xxHash/wyhash),
   implementata in Common Lisp tipizzato.

Pattern: record length-prefixed con CRC32C (RocksDB, Kafka); CBOR come codifica documentale
(standard IETF); ULID per identificatori ordinabili.

## Conseguenze

- Ogni file persistente è scansionabile e verificabile da solo.
- Nessuna dipendenza da librerie: CBOR, CRC32C e hash sono codice del progetto (tabellare,
  tipizzato, senza allocazione).
- Il limite di 255 byte su `_id` rende l'intestazione compatta; chiavi lunghe non sono un caso
  d'uso.

## Alternative considerate

- *JSON testuale:* parsing costoso, numeri ambigui, nessun tipo binario.
- *Formato binario proprietario:* nessun vantaggio su CBOR e nessuno standard.
- *`_id` solo a 16 byte fissi:* più compatto, ma impedisce chiavi naturali.

## Valutazione

- Verifica: test di round-trip CBOR contro vettori RFC; FI-01 (record troncato).
- Costo: ~44 byte di intestazione+CRC per record, trascurabile su documenti da 1–4 KB.
