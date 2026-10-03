# Formati su disco

> Formati persistenti definiti dagli ADR [0039](adr/0039-cornice-unica-dei-record.md) (cornice
> dei record, hint), [0037](adr/0037-lotto-sigillato.md) (lotto e SEAL),
> [0040](adr/0040-manifest-a-record-unico.md) (control log, catalogo),
> [0041](adr/0041-multiserie-segmenti-autosufficienti.md) (`multiserie.log`),
> [0026](adr/0026-indici-secondari-segmentati.md) (indici). Sostituiscono la prima stesura
> (ADR 0013–0021), mai implementata. Dal primo codice in poi un formato non cambia: una
> modifica è un nuovo numero di versione con migrazione ([principi](principi-di-ingegneria.md)).

## Convenzioni comuni

- Interi **little-endian**, allineamento naturale non richiesto.
- Ogni file inizia con un **magic** di 8 byte ASCII e una **versione** `u16`.
- Checksum: **CRC32C** (polinomio Castagnoli).
- Tutti i record di tutti i log hanno la stessa [cornice](#cornice-del-record).
- Ciò che non verifica è **inesistente**: una coda (per un log), un dato da rigenerare (per un
  file derivato), una corruzione dichiarata (per un dato confermato). INV-F1, INV-F3.
- Timestamp: nanosecondi, `u64`, orologio reale; solo informativi.
- Identificatori: `segment-id` `u64` crescente per Serie, **mai riusato**; `txid` `u64`
  crescente per Archivio (solo transazioni multiserie); `csn` `u64`; id di Serie 16 byte.

## Cornice del record

Intestazione fissa di 24 byte, poi chiave e valore.

| Offset | Tipo | Campo |
|---|---|---|
| 0 | `u32` | `header-crc`: CRC32C dei byte 4–23 |
| 4 | `u32` | `body-crc`: CRC32C dei byte di chiave e valore |
| 8 | `u8` | tipo |
| 9 | `u8` | flag: bit0 prepared · bit1 compresso (riservato) · bit2 contratto-versionato · bit3 completo (solo EDIT) |
| 10 | `u8` | `key-len` (1–255 per PUT e TOMBSTONE; 0 per gli altri tipi) |
| 11 | `u8` | riservato, zero |
| 12 | `u32` | `value-len` |
| 16 | `u64` | `stamp` |
| 24 | `byte[key-len]` | chiave |
| … | `byte[value-len]` | valore |

Lunghezza del record = `24 + key-len + value-len`. Un lettore verifica `header-crc` **prima**
di usare le lunghezze, poi `body-crc`.

| Tipo | Log | `stamp` | Valore |
|---|---|---|---|
| 1 PUT | segmento | CSN del lotto; TXID se prepared | documento CBOR |
| 2 TOMBSTONE | segmento | CSN del lotto; TXID se prepared | vuoto |
| 3 SEAL | tutti | CSN del lotto (segmento); numero d'ordine (log di controllo) | vedi [Lotto e SEAL](#lotto-e-seal) |
| 4 OUTCOME | segmento | TXID | `u64 csn` della transazione |
| 5 EDIT | control log | numero d'ordine | vedi [Control log](#control-log) |
| 6 DECISION | `multiserie.log` | TXID | vedi [`multiserie.log`](#multiserielog) |

## Lotto e SEAL

Un log è una sequenza di **lotti**. Un lotto è una sequenza di record seguita da un SEAL.

Valore del SEAL (32 byte):

| Offset | Tipo | Campo |
|---|---|---|
| 0 | `u64` | identificativo del file: `segment-id`; zero per i log di controllo |
| 8 | `u64` | `batch-start`: offset nel file del primo record del lotto |
| 16 | `u64` | `durable-offset`: frontiera durevole del file nota alla chiusura del lotto |
| 24 | `u32` | `count`: numero di record del lotto, SEAL escluso |
| 28 | `u32` | `batch-crc`: CRC32C della sequenza degli `header-crc` dei record del lotto |

Un lotto è **valido** se: ogni suo record ha `header-crc` e `body-crc` validi; il SEAL che lo
segue dichiara l'identificativo di questo file, come `batch-start` la posizione reale del
primo record, il numero e il `batch-crc` reali; ogni record non prepared ha lo stesso `stamp`
del SEAL. Un lotto non valido non esiste (INV-F2).

Regola della coda ([ADR-0037](adr/0037-lotto-sigillato.md) §3): sia `P` l'inizio del primo
lotto non valido. Se un SEAL valido per questo file, in una posizione successiva, dichiara
`durable-offset > P`, il log è **corrotto**; altrimenti la lunghezza valida è `P`.

## Segmento

File `segments/<segment-id:016x>.seg`.

### Intestazione (64 byte)

| Offset | Tipo | Campo |
|---|---|---|
| 0 | `char[8]` | magic `ARCDSEG1` |
| 8 | `u16` | versione formato = 1 |
| 10 | `u8` | origine: 1 writer · 2 compaction |
| 11 | `byte[5]` | riservato |
| 16 | `byte[16]` | id della Serie |
| 32 | `u64` | segment-id |
| 40 | `u64` | created-at |
| 48 | `u64` | riservato |
| 56 | `u32` | CRC32C dei byte 0–55 |
| 60 | `u32` | riservato |

### Contenuto

Dall'offset 64 alla **lunghezza valida** registrata nel manifest:

- **origine writer**: lotti sigillati di record PUT, TOMBSTONE, OUTCOME;
- **origine compaction**: soli record PUT e TOMBSTONE **risolti** (mai prepared, mai OUTCOME,
  nessun SEAL), ciascuno con il proprio CSN.

I byte oltre la lunghezza valida (la coda di un `ACTIVE` chiuso da un recovery) non fanno
parte del segmento.

### Quali record sono committed

In un segmento `CLOSED`, entro la lunghezza valida:

| Record | Committed se |
|---|---|
| PUT, TOMBSTONE non prepared | sempre; il CSN è `stamp` |
| PUT, TOMBSTONE prepared | esiste nello stesso segmento un OUTCOME con lo stesso TXID, oppure il manifest registra l'esito per quel TXID alla chiusura del segmento; il CSN è quello dell'esito |
| tutto il resto | non committed (transazione abortita) |

Nell'`ACTIVE`, durante il recovery, vale lo stesso entro i lotti validi, con la tabella delle
decisioni di `multiserie.log` al posto del manifest (INV-S7).

### Verifica in lettura

Un record raggiunto da una entry dell'indice `(chiave, CSN, location, flag)` è restituito solo
se **tutte** le condizioni valgono (INV-A2): `header-crc` valido; tipo PUT; `24 + key-len +
value-len` uguale alla lunghezza nella entry; `body-crc` valido; chiave uguale; se il record
non è prepared, `stamp` uguale al CSN della entry e entry senza flag prepared; se il record è
prepared, entry con flag prepared. La regola è la stessa per un record letto dal segmento e
per uno ottenuto dalla cache.

## File hint

File `segments/<segment-id>.hint`: indice del segmento. Dato derivato, scritto dopo la
chiusura; rigenerabile dal segmento e dal manifest.

| Sezione | Contenuto |
|---|---|
| intestazione (128 B) | magic `ARCDHNT1`, versione, id Serie, segment-id, `n` entry, `csn-min`, `csn-max`, tabella `(offset, len)` delle sezioni, CRC |
| entry (24 B × n) | `u32 offset` · `u32 len` · `u64 csn` · `u32 key-off` · `u8 key-len` · `u8 tipo` · `u8 flag` · `u8 riservato` |
| chiavi | chiavi concatenate, indirizzate da `key-off` |
| bloom | filtro di esistenza sulle chiavi delle entry: `u32 m` bit, `u32 k` funzioni, poi `u64[ceil(m/64)]`; `k` funzioni dall'hash a 64 bit (double hashing), ~1 % di falsi positivi |
| piè di pagina | `u32` CRC32C di tutte le sezioni |

C'è una entry per ogni record PUT o TOMBSTONE **committed**, in ordine di `offset`; il `csn`
è quello definitivo. L'ordinale dell'entry è la «riga» usata dagli indici secondari. Il flag
riporta se il record su disco è prepared.

## File indice

File `segments/<segment-id>.<nome-indice>.idx`, uno per indice del contratto. Dato derivato.

| Sezione | Contenuto |
|---|---|
| intestazione (64 B) | magic `ARCDIDX1`, versione, tipo di indice, id Serie, segment-id, `n` righe indicizzate, `k` sezioni, tabella `(offset, len)` delle sezioni, CRC |
| sezioni | dipendono dal tipo (sotto) |
| piè di pagina | `u32` CRC32C di tutte le sezioni |

| Tipo | Sezioni |
|---|---|
| **string** | `keys`: chiavi ordinate con front-coding a blocchi di 16 · `key-offsets`: `u32[]` inizio di ogni blocco · `rows`: `u32[]` riga per chiave · `bloom` sui valori |
| **ordered** (numeri, date) | `values`: `u64[]` (int64/doppio/epoca, codificati ordinabili) ordinati · `rows`: `u32[]`; primo e ultimo valore nell'intestazione |
| **category** | `dict`: valori distinti ordinati (front-coding) · `postings`: per valore, `u32 count` + righe delta-encoded varint · `bloom` sui valori |
| **bitmap** | per valore distinto: `u64[ceil(n/64)]` |

La sezione `bloom` di un file indice ha lo stesso formato di quella dell'hint e riguarda i
**valori** indicizzati: dice solo «sicuramente assente / forse presente» (INV-I2) e permette a
una query di uguaglianza di saltare il segmento.

## Control log

File `wal/control.log`: il manifest della Serie. Intestazione di 64 byte (magic `ARCDCTL1`,
versione, id Serie, CRC), poi lotti sigillati di record **EDIT**.

Valore di un EDIT:

| Campo | Tipo | Significato |
|---|---|---|
| `next-id` | `u64` | prossimo segment-id (solo se flag completo; altrimenti zero) |
| `open` | `u64` | segment-id del nuovo `ACTIVE`; zero = invariato |
| `n-closed` | `u32` | numero di segmenti che diventano o sono `CLOSED` |
| per ciascuno | `u64 segment-id` · `u64 valid-bytes` · `u32 n-res` · `n-res × (u64 txid, u64 csn)` | lunghezza valida ed esiti registrati alla chiusura |
| `n-removed` | `u32` | numero di segmenti rimossi |
| per ciascuno | `u64 segment-id` | — |

Il primo record di ogni file ha il flag **completo** e dichiara l'intero stato: `ACTIVE`,
tutti i `CLOSED`, i rimossi il cui file può esistere ancora, il prossimo segment-id. Gli EDIT
successivi si ripiegano su quello. Compattazione e recovery scrivono `control.log.tmp` con un
EDIT completo e lo rinominano sopra l'originale.

## `multiserie.log`

File `Registri/multiserie.log`. Intestazione di 64 byte (magic `ARCDMSL1`, versione, id
Archivio, CRC), poi lotti sigillati di record **DECISION**. Ogni DECISION è un COMMIT.

Valore di una DECISION:

| Offset | Tipo | Campo |
|---|---|---|
| 0 | `u64` | `csn` della transazione |
| 8 | `u16` | `n-part` |
| 10 | `byte[16][n-part]` | id delle Serie partecipanti |

Compattazione: `multiserie.log.tmp` con le sole decisioni non dimenticabili, poi rinomina
sopra l'originale.

## Catalogo (documenti di Registri)

Documento CBOR con chiave = id Serie (16 byte). Campi: `name`, `state`
(`active`/`dropping`), `created-at`, `durability`, `segment-target-bytes`,
`contract` (versione, campi, politica), `indexes` (nome, tipo, campo, `complete-from`
segment-id), `compaction` (soglie di [ADR-0023](adr/0023-politiche-di-compaction.md)),
`cache-share`, `path` (opzionale, per dispositivi diversi).

## Nomi temporanei

Ogni file o directory **preparato** ha suffisso `.tmp` finché la fonte di verità del suo
livello non lo nomina ([ADR-0036](adr/0036-leggi-di-progetto.md)):

| Oggetto | Decisione che lo rende definitivo |
|---|---|
| `<id>.seg.tmp` | EDIT che lo apre o lo chiude |
| `<id>.hint.tmp`, `<id>.<indice>.idx.tmp` | nessuna: derivati, rinominati appena completi |
| `control.log.tmp`, `multiserie.log.tmp` | la rinomina stessa |
| directory `<id-serie>.tmp/` | documento `active` nel catalogo |

Al riavvio: un `.tmp` non nominato si elimina; uno nominato si rinomina; un oggetto con nome
definitivo che nessuna fonte di verità conosce **non si tocca** (INV-A10).
