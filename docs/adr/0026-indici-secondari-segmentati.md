# ADR-0026 — Indici secondari segmentati: un file immutabile a formato fisso per segmento, delta in memoria per l'ACTIVE

- **Stato:** Accettata
- **Data:** 2026-10-03
- **Rapporto con la specifica:** chiude QA-25; realizza «Secondary index», «Secondary index
  delta», «Index snapshot». Decisione dell'autore (2026-10-03): gli indici hanno formato
  predefinito e sono divisi per segmento.
- **Riferimenti:** [architettura](../architettura.md#indici-secondari),
  [formati su disco](../formati-su-disco.md#file-indice), INV-I1, INV-I2

## Contesto

Gli indici secondari devono restare coerenti con commit, snapshot e recovery, costare poco al
writer, e permettere algoritmi ottimi (sequenziali, SIMD-friendly). La specifica chiede
strutture specializzate per tipo e un modello base + delta.

## Decisione

### Segmentazione

**Ogni segmento chiuso possiede i propri file di indice, immutabili**, prodotti insieme al
segmento (alla chiusura dall'`ACTIVE`, o dalla compaction per i suoi output):

- `<id>.hint` — primary index del segmento ([ADR-0015](0015-primary-index-swiss-table-swmr.md));
- `<id>.<indice>.idx` — un file per ogni indice secondario definito nel contratto;
- `<id>.bloom` — Bloom filter sulle chiavi del segmento.

Il «base index» della specifica è l'**unione degli indici dei segmenti chiusi**; il «delta» è
l'**indice in memoria del segmento `ACTIVE`**, aggiornato dal writer nel lotto (append in
array specializzati, costo O(1) per entry). Il «merge asincrono» è la chiusura del segmento
(che materializza il delta in file) e il MERGE dei segmenti (che fonde gli indici dei
sorgenti). Non esistono altre strutture da fondere né da mantenere.

### Formato fisso

Tutti i file di indice condividono la stessa **impronta**: intestazione fissa (magic, versione
del formato, tipo di indice, segment-id, numero di entry, offset delle sezioni), sezioni ad
array a larghezza fissa o a offset, piè di pagina con CRC32C. Sono letti con `pread` in buffer
riutilizzati o caricati per intero in array specializzati: nessun parsing, nessuna
allocazione per entry, accesso sequenziale.

| Tipo (dal contratto) | Struttura nel file del segmento | Algoritmi |
|---|---|---|
| stringa / prefix | chiavi ordinate con front-coding + array di offset (ART in memoria solo nel delta) | ricerca binaria, scansione di prefisso sequenziale |
| numero / data / range | array ordinato di `(valore, riga)` a larghezza fissa | ricerca binaria, scansione di intervallo, vettorizzabile |
| categoria | dizionario dei valori + posting list di righe (delta-encoded) | intersezione/unione sequenziale |
| boolean / bassa cardinalità | bitmap per valore (una parola per 64 righe) | AND/OR/XOR su parole, SIMD-friendly |
| Bloom | array di bit con k funzioni derivate dall'hash a 64 bit | test di assenza |

La «riga» è l'ordinale del record nel segmento; dall'ordinale si risale a offset, chiave,
versione e CSN tramite l'hint.

### Query

Una query su un indice visita i segmenti **in parallelo** (sono indipendenti), ottiene righe
per segmento, le converte in `(chiave, versione, CSN)` con l'hint, e **filtra per
visibilità** con il primary index: una riga è un risultato solo se la versione è quella che
lo snapshot (o il read committed) vede. Nessuna cancellazione negli indici dei segmenti: le
versioni superate sono scartate dal filtro, e sparite dal file quando il CLEAN produce il
nuovo segmento.

### Coerenza e recovery

- Aggiornamento **sincrono** con il commit (nel lotto del writer), quindi coerente con il
  CSN per costruzione.
- Gli indici dei segmenti sono dati derivati: al riavvio il delta dell'`ACTIVE` si ricostruisce
  dalla scansione del segmento; un file indice mancante o corrotto si rigenera dal segmento.
- Le modifiche al contratto (nuovo indice) generano i file mancanti in background, segmento
  per segmento; il contratto registra da quale segment-id l'indice è completo.

Pattern: indici immutabili per segmento fusi dalla compaction (Apache Lucene; SSTable di
LevelDB/RocksDB con filtri per file); posting list e bitmap (Lucene, Roaring).

## Conseguenze

- Il writer paga solo append in memoria; la costruzione dei file avviene alla chiusura, fuori
  dal percorso di commit.
- Immutabilità e formato fisso rendono naturali SIMD, prefetch e `pread` senza parsing.
- Il costo di una query cresce con il numero di segmenti: è il motivo per cui il MERGE esiste;
  il Bloom filter e i metadati min/max per segmento riducono i segmenti visitati.
- Un solo meccanismo di persistenza per tutti gli indici (il segmento e i suoi file).

## Alternative considerate

- *Indice secondario globale per Serie (B+ tree/ART in memoria) con delta LSM:* strutture a
  puntatori, fusioni separate dalla compaction, persistenza propria; più meccanismi.
- *Indici solo in memoria ricostruiti al riavvio:* richiede di rileggere tutti i documenti.

## Valutazione

- Verifica: benchmark «indexed query» con numero crescente di segmenti; test di coerenza con
  snapshot; FI-10 (rigenerazione).
- Rivedere se: la latenza delle query con molti segmenti (es. 1000) supera l'obiettivo anche
  con Bloom e min/max → ADR su un indice riassuntivo per Serie.
