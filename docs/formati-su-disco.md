# Formati su disco

> Formati persistenti definiti dagli ADR 0013, 0014, 0015, 0018, 0021, 0026. Un formato non
> cambia: una modifica è un nuovo numero di versione con migrazione
> ([principi](principi-di-ingegneria.md)).

## Convenzioni comuni

- Interi **little-endian**, allineamento naturale non richiesto.
- Ogni file inizia con un **magic** di 8 byte ASCII e una **versione** `u16`.
- Checksum: **CRC32C** (polinomio Castagnoli), calcolato su tutti i byte che lo precedono nel
  record o nella sezione.
- Un record o una sezione con lunghezza incoerente o CRC errato è **inesistente**: il lettore
  si ferma lì (coda troncata) o rigenera il file (dati derivati). INV-F1.
- Timestamp: nanosecondi, `u64`; quelli «monotoni» non sono confrontabili tra riavvii.
- Identificatori: `segment-id` `u64` crescente per Serie; `txid` `u64` crescente per Archivio;
  `csn` `u64`; id di Serie 16 byte.

## Segmento

File `segments/<segment-id:016x>.seg`. Append-only finché `ACTIVE`, poi immutabile.

### Intestazione (64 byte)

| Offset | Tipo | Campo |
|---|---|---|
| 0 | `char[8]` | magic `ARCDSEG1` |
| 8 | `u16` | versione formato = 1 |
| 10 | `u16` | riservato |
| 12 | `u32` | riservato |
| 16 | `byte[16]` | id della Serie |
| 32 | `u64` | segment-id |
| 40 | `u64` | lineage-min |
| 48 | `u64` | created-at (orologio reale) |
| 56 | `u32` | CRC32C dell'intestazione |
| 60 | `u32` | riservato |

### Record

Dall'offset 64, record contigui.

| Offset | Tipo | Campo |
|---|---|---|
| 0 | `u32` | `len` = lunghezza totale del record, CRC incluso |
| 4 | `u8` | tipo: 1 PUT · 2 TOMBSTONE · 3 PREPARE · 4 COMMIT-GROUP · 5 OUTCOME |
| 5 | `u8` | flag: bit0 prepared · bit1 compresso (riservato) · bit2 contratto-versionato |
| 6 | `u8` | `key-len` (1–255; 0 per i record di controllo) |
| 7 | `u8` | riservato |
| 8 | `u32` | `value-len` |
| 12 | `u64` | `txid` |
| 20 | `u64` | `version` del documento dopo questo record (0 per i record di controllo) |
| 28 | `u64` | `csn` (0 se non ancora noto: record prepared) |
| 36 | `byte[key-len]` | chiave `_id` |
| … | `byte[value-len]` | valore |
| `len-4` | `u32` | CRC32C |

Semantica dei tipi:

| Tipo | Chiave | Valore | Significato |
|---|---|---|---|
| PUT | `_id` | documento CBOR | nuova versione |
| TOMBSTONE | `_id` | vuoto | eliminazione |
| PREPARE | — | `txid` + elenco dei `(key-off-relativi)` dei record prepared precedenti | fine della fase PREPARE di una multiserie |
| COMMIT-GROUP | — | `csn` + elenco di `txid` committed nel lotto | commit del lotto |
| OUTCOME | — | `txid` + esito (1 COMMIT · 2 ABORT) + `csn` | esito di una multiserie |

Regole di lettura (recovery, CLEAN):

- un PUT/TOMBSTONE non prepared è committed se un COMMIT-GROUP successivo nello stesso
  segmento elenca il suo `txid`; il `csn` del record è quello definitivo;
- un record prepared è committed se esiste un OUTCOME COMMIT per il suo `txid` (nello stesso
  segmento o in uno successivo) o una decisione COMMIT in `multiserie.log`; il `csn` è quello
  dell'OUTCOME;
- tutto ciò che resta è morto.

## File hint

File `segments/<segment-id>.hint`: primary index del segmento, scritto alla chiusura o dalla
compaction. Dato derivato: rigenerabile dal segmento.

| Sezione | Contenuto |
|---|---|
| intestazione (64 B) | magic `ARCDHNT1`, versione, id Serie, segment-id, `n` entry, offset delle sezioni, CRC |
| entry (fissa, 32 B × n) | `u32 offset` · `u32 len` · `u64 version` · `u64 csn` · `u32 key-off` · `u8 key-len` · `u8 tipo` · `u8 flag` · `u8 riservato` |
| chiavi | chiavi concatenate, indirizzate da `key-off` |
| piè di pagina | `u32` CRC32C delle sezioni entry + chiavi |

Le entry sono in ordine di `offset` (ordine di scrittura): l'ordinale dell'entry è la «riga»
usata dagli indici secondari.

## File indice

File `segments/<segment-id>.<nome-indice>.idx`, uno per indice del contratto. Formato comune
(«impronta»):

| Sezione | Contenuto |
|---|---|
| intestazione (64 B) | magic `ARCDIDX1`, versione, tipo di indice, id Serie, segment-id, `n` righe indicizzate, `k` sezioni, tabella `(offset, len)` delle sezioni, CRC |
| sezioni | dipendono dal tipo (sotto) |
| piè di pagina | `u32` CRC32C di tutte le sezioni |

| Tipo | Sezioni |
|---|---|
| **string** | `keys`: chiavi ordinate con front-coding a blocchi di 16 · `key-offsets`: `u32[]` inizio di ogni blocco · `rows`: `u32[]` riga per chiave, nello stesso ordine |
| **ordered** (numeri, date) | `values`: `u64[]` (int64/doppio/epoca, codificati ordinabili) ordinati · `rows`: `u32[]` |
| **category** | `dict`: valori distinti ordinati (front-coding) · `postings`: per valore, `u32 count` + righe delta-encoded varint |
| **bitmap** | per valore distinto: `u64[ceil(n/64)]` |

Metadati min/max per sezione sono nell'intestazione (per `ordered`, primo e ultimo valore).

## Bloom filter

File `segments/<segment-id>.bloom`: intestazione (magic `ARCDBLM1`, versione, `m` bit, `k`
funzioni, `n` chiavi, CRC), poi `u64[ceil(m/64)]`, poi CRC. `k` funzioni derivate dall'hash
a 64 bit della chiave (double hashing). Dimensionato per ~1 % di falsi positivi.

## Control log

File `wal/control.log`. Record contigui:

| Offset | Tipo | Campo |
|---|---|---|
| 0 | `u32` | `len` |
| 4 | `u8` | tipo |
| 5 | `u8` | riservato |
| 6 | `u16` | riservato |
| 8 | `u64` | `seq` (crescente) |
| 16 | `u64` | timestamp monotono |
| 24 | … | payload |
| `len-4` | `u32` | CRC32C |

| Tipo | Payload |
|---|---|
| 1 SEG-OPEN | `segment-id` |
| 2 SEG-CLOSE | `segment-id` · `record-count` · `total-bytes` |
| 3 SWAP | `op-id` · `n-out` · `segment-id[n-out]` · `n-src` · `segment-id[n-src]` · `lineage-min` |
| 4 SEG-OBSOLETE | `segment-id` |
| 5 SEG-RECLAIMABLE | `segment-id` |
| 6 SEG-DELETED | `segment-id` |
| 7 CHECKPOINT | `active-id` · `next-segment-id` · `n` · per segmento: `id`, stato, `lineage-min`, `record-count`, `total-bytes`, `live-bytes`, `dead-bytes`, `closed-at` |

Il primo record del file (dopo l'intestazione `ARCDCTL1`, versione, id Serie) è sempre un
CHECKPOINT (vuoto per una Serie nuova). Compattazione: nuovo file con un solo CHECKPOINT,
flush, rinomina sopra l'originale, `fsync` della directory.

## `multiserie.log`

File `Registri/multiserie.log`, intestazione `ARCDMSL1` + versione + id Archivio. Record:

| Offset | Tipo | Campo |
|---|---|---|
| 0 | `u32` | `len` |
| 4 | `u8` | tipo: 1 COMMIT · 2 ABORT · 3 CHECKPOINT |
| 5 | `u8` | riservato |
| 6 | `u16` | `n-part` |
| 8 | `u64` | `seq` |
| 16 | `u64` | `txid` |
| 24 | `u64` | `csn` (0 per ABORT) |
| 32 | `byte[16][n-part]` | id delle Serie partecipanti |
| `len-4` | `u32` | CRC32C |

CHECKPOINT: `n` decisioni non dimenticabili che seguono, `csn-high`. Compattazione come il
control log.

## Catalogo (documenti di Registri)

Documento CBOR con chiave = id Serie (16 byte). Campi: `name`, `state`
(`creating`/`active`/`dropping`), `created-at`, `durability`, `segment-target-bytes`,
`contract` (versione, campi, politica), `indexes` (nome, tipo, campo, `complete-from`
segment-id), `compaction` (soglie di [ADR-0023](adr/0023-politiche-di-compaction.md)),
`cache-share`, `path` (opzionale, per dispositivi diversi).

## Nomi dei file temporanei

Ogni file prodotto da chiusura o compaction è scritto come `<nome>.tmp`, flushato, rinominato
al nome finale; poi `fsync` della directory. Un `.tmp` trovato al riavvio è eliminato.
