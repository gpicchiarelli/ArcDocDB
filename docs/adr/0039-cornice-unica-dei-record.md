# ADR-0039 — Cornice unica dei record: due CRC, quattro tipi nei segmenti, hint risolto

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** nessuna emenda. **Sostituisce in parte**
  [ADR-0014](0014-formato-record-documento-id.md) punto 3 (intestazione e tipi del record) e
  la parte sui file hint di [ADR-0015](0015-primary-index-swiss-table-swmr.md). Documento
  (CBOR), `_id` e hash di ADR-0014 restano.
- **Riferimenti:** [analisi progettuale](../analisi-progettuale.md) AP-08, AP-11, AP-13;
  [formati su disco](../formati-su-disco.md); INV-F1, INV-F2, INV-A2

## Contesto

Il formato v1 non è ancora implementato: si può correggere senza migrazione. Tre problemi:
il CRC unico copre campi che solo il writer conosce, quindi il writer deve calcolare il CRC di
tutto il documento (AP-13); segmento, control log e `multiserie.log` hanno tre intestazioni
diverse; alcuni campi e un tipo di record non hanno funzione.

## Decisione

### 1. Una sola cornice per ogni record di ogni log

Intestazione fissa di **24 byte**, poi chiave e valore:

| Offset | Tipo | Campo |
|---|---|---|
| 0 | `u32` | `header-crc`: CRC32C dei byte 4–23 |
| 4 | `u32` | `body-crc`: CRC32C di chiave e valore |
| 8 | `u8` | tipo |
| 9 | `u8` | flag |
| 10 | `u8` | `key-len` |
| 11 | `u8` | riservato |
| 12 | `u32` | `value-len` |
| 16 | `u64` | `stamp` |

- La lunghezza del record è `24 + key-len + value-len`: non esiste un campo di lunghezza
  separato che possa mentire. L'intestazione si verifica **da sola** prima di fidarsi delle
  lunghezze.
- `header-crc` copre `body-crc`: intestazione e corpo sono legati.
- **Chi calcola che cosa.** Il worker che riceve la richiesta calcola `body-crc` (lavoro
  proporzionale ai byte, fuori dal writer). Il writer, alla chiusura del lotto, scrive `stamp`
  e calcola `header-crc` su 20 byte: nessun lavoro per byte nella parte seriale oltre alla
  copia nel buffer.

### 2. Tipi

| Tipo | Dove | `stamp` | Valore |
|---|---|---|---|
| 1 PUT | segmento | CSN; TXID se prepared | documento |
| 2 TOMBSTONE | segmento | CSN; TXID se prepared | vuoto |
| 3 SEAL | ogni log | CSN del lotto (segmento); numero d'ordine (log di controllo) | identificativo del file, inizio del lotto, frontiera durevole, numero di record, CRC del lotto |
| 4 OUTCOME | segmento | TXID | CSN della transazione |
| 5 EDIT | control log | numero d'ordine | apre, chiude, rimuove ([ADR-0040](0040-manifest-a-record-unico.md)) |
| 6 DECISION | `multiserie.log` | TXID | CSN, partecipanti |

Rispetto al formato precedente scompaiono: il record `PREPARE` (i record prepared sono
riconosciuti dal flag e resi atomici dal SEAL del loro lotto), il campo `version`
([ADR-0038](0038-orizzonte-di-visibilita.md)), il TXID per le operazioni ordinarie (un lotto è
atomico per posizione, [ADR-0037](0037-lotto-sigillato.md)), gli esiti `ABORT`
([ADR-0041](0041-multiserie-segmenti-autosufficienti.md)), l'intestazione propria del control
log e di `multiserie.log`.

### 3. Hint: sempre risolto, con il filtro di esistenza

Il file hint di un segmento chiuso ha una entry di **24 byte** per ogni record PUT o
TOMBSTONE **committed**, in ordine di offset, con il CSN **definitivo** (per i record
prepared, quello dell'esito: alla chiusura ogni esito è noto, INV-S7). Contiene inoltre:

- nell'intestazione, `csn-min` e `csn-max` del segmento;
- una sezione **Bloom** sulle chiavi delle entry: è il filtro di esistenza che governa lo
  scarto dei tombstone ([ADR-0042](0042-tombstone-e-indice-dei-vivi.md)).

Il file `.bloom` separato non esiste più. I filtri sui **valori** degli indici secondari sono
una sezione dei rispettivi file `.idx` ([ADR-0026](0026-indici-secondari-segmentati.md)), come
chiede la specifica («Bloom filter per segmento … un valore è sicuramente assente»).

L'hint resta un dato derivato: si rigenera dal segmento e dal manifest; se manca o non
verifica, lo scarto dei tombstone lo tratta come «forse presente» e la ricostruzione
dell'indice scansiona il segmento.

### 4. Verifica in lettura (precisa INV-A2)

Un record raggiunto da una entry dell'indice è restituito solo se: `header-crc` è valido; il
tipo è PUT; la lunghezza calcolata coincide con quella della entry; `body-crc` è valido; la
chiave coincide; e — se il record non è prepared — `stamp` coincide con il CSN della entry.
Se il record è prepared, la entry deve portare il flag corrispondente (il CSN viene
dall'esito). La regola è la stessa da disco e da cache.

Pattern: CRC di intestazione e di corpo distinti, con il primo che copre il secondo
(TigerBeetle); record auto-delimitato verificabile prima di leggerne il corpo (Kafka record
batch); filtro di esistenza per file (SSTable di LevelDB/RocksDB, Cassandra).

## Conseguenze

- Un solo codec e un solo fuzzer per segmenti, control log e `multiserie.log`.
- 24 byte per record invece di 40; 24 byte per entry di hint invece di 32.
- Il budget del writer per operazione non dipende più dalla dimensione del documento, salvo
  la copia.
- Un difetto del worker nel calcolo di `body-crc` produce un record che non verifica: viene
  rilevato alla prima lettura e dallo scrubbing, non corrompe in silenzio.

## Alternative considerate

- *CRC unico calcolato dal writer:* lavoro per byte nella parte seriale.
- *CRC unico calcolato prima, con CSN fuori dal record:* i segmenti prodotti dalla compaction
  contengono record di lotti diversi e hanno comunque bisogno del CSN per record.
- *Combinare due CRC con l'algebra del CRC:* evita il secondo campo, ma è un algoritmo in più
  da verificare per risparmiare 4 byte.

## Valutazione

- Verifica: fuzzing della cornice; corruzione deliberata di ogni campo (ogni danno rilevato);
  SPK-09 misura il CRC separato per intestazione e corpo.
