# Architettura di ArcDocDB

> Documento consolidato del progetto, risultato della Fase 0. Riunisce le decisioni della
> [specifica](specifica/prompt-originale.md) e degli [ADR](adr/README.md) in un'unica
> descrizione coerente. In caso di dubbio prevalgono specifica e ADR; questo documento li
> cita. I formati persistenti sono in [formati-su-disco.md](formati-su-disco.md).

## In una pagina

ArcDocDB è un database documentale **log-structured**: ogni Serie scrive i record una sola
volta, in sequenza, nel suo segmento `ACTIVE`; un **indice primario compatto in memoria**
mappa `_id` alla posizione della versione corrente; i segmenti chiusi sono **immutabili** e
portano con sé i propri file indice; la **compaction** copia ciò che serve in segmenti nuovi e
non tocca mai i vecchi. La concorrenza è **un writer per Serie, reader senza lock**; la
visibilità è governata da un **numero di sequenza di commit (CSN)** per Archivio; le
transazioni multiserie usano un **2PC** con decision log unico. Tutto è Common Lisp su SBCL,
senza allocazioni sui percorsi caldi.

```
                 Server (processo SBCL)
 ┌─────────────────────────────────────────────────────────────────────┐
 │ Protocollo (TCP, frame CBOR)    Scheduler + pool CPU + pool I/O      │
 │                                                                      │
 │  Archivio ─ CSN ─ coordinatore multiserie ─ Registri/multiserie.log  │
 │   │                                                                  │
 │   ├── Serie A ── coda ─▶ writer A ─▶ ACTIVE A ──▶ CLOSED… (immutabili)│
 │   │                │        │                       │                │
 │   │                │   indice A (RAM)        hint/idx/bloom per seg. │
 │   │              reader ◀── cache A ◀─────── pread ◀┘                │
 │   ├── Serie B …                                                      │
 │   └── Registri (catalogo = Serie)                                    │
 │                                                                      │
 │  Compaction Scheduler ─ worker CLEAN/MERGE ─ EBR ─ reclaim           │
 └─────────────────────────────────────────────────────────────────────┘
```

## Modello logico

`Server → Archivio → Serie → Documento` ([02](02-modello-logico.md)). La Serie è l'unità di
storage, parallelismo e isolamento. L'Archivio è l'ambito di CSN, snapshot, transazioni
multiserie e catalogo.

### Archivio e Registri

- **Registri è una Serie** con configurazione incorporata; ogni Serie dell'Archivio è un
  documento del catalogo, identificato da un id stabile a 16 byte che dà il nome alla sua
  directory ([ADR-0022](adr/0022-registri-come-serie-catalogo.md)).
- L'Archivio possiede: il contatore **CSN**, il registro degli **snapshot attivi**, l'insieme
  delle multiserie **in applicazione**, il **coordinatore** e `multiserie.log`, l'**epoca**
  per il reclaim.

### Layout fisico

```
Archivio/
├── Registri/
│   ├── catalog/                 ← storage della Serie Registri
│   │   ├── wal/control.log
│   │   ├── segments/<id>.seg|.hint|.bloom|.<idx>.idx
│   │   └── index/               ← riservato (indici riassuntivi futuri)
│   └── multiserie.log
├── 0f3a…c2/                     ← Serie (id interno; il nome è nel catalogo)
│   ├── wal/control.log
│   ├── segments/
│   └── index/
└── …
```

## Memoria

Tutte le strutture grandi sono array specializzati a vita lunga, senza puntatori, allocati
una volta; i percorsi caldi non allocano ([ADR-0024](adr/0024-memoria-e-gc.md)).

| Struttura | Per | Contenuto | Crescita |
|---|---|---|---|
| Primary index | Serie | tabella Swiss: byte di controllo + 5 parole/slot | sostituzione + scambio atomico |
| Key arena | Serie | chiavi `_id` contigue | chunk da 64 MB |
| Versioni trattenute | Serie | `chiave → (csn-da, csn-a, location, versione)` | solo con snapshot attivi |
| Intenti | Serie | `chiave → txid` prepared | piccola |
| Delta indici secondari | Serie | entry dell'`ACTIVE` per ogni indice | svuotato alla chiusura |
| Cache | Serie (partizione) | arena di slot per classi + tabella `(seg, off) → slot` | budget dallo scheduler |
| Buffer `ACTIVE` | Serie | lotto in formazione + lotti in flush | fisso |
| Metriche | worker/Serie | contatori padded + istogrammi log-lineari | fisso |
| Epoche | worker | una parola per worker, padded | fisso |

## Concorrenza

### Thread pool

Due pool dinamici ([ADR-0011](adr/0011-thread-pool-dinamico.md),
[ADR-0017](adr/0017-piattaforma-e-io.md)):

- **Pool CPU**: richieste, writer logici, compaction (parte di calcolo), query. Dimensionato
  dallo scheduler (EWMA/AIMD/isteresi) tra `min` e `2 × core`.
- **Pool I/O**: `pread`, `write`, flush. Può superare di molto il numero di core.

Il **writer logico** di una Serie è un esecutore seriale: una coda MPSC; il primo worker che
trova la coda non vuota e acquisisce il token della Serie la svuota a lotti; nessun thread
dedicato, nessun lock globale ([ADR-0005](adr/0005-writer-logico-per-serie.md)).

### Reclaim

Epoch-based reclamation per segmenti `OBSOLETE`, tabelle sostituite e file indice ritirati
([ADR-0016](adr/0016-epoch-based-reclamation.md)). Le sezioni di lettura non contengono I/O
di rete né attese.

## Percorso di scrittura

```
worker richiesta                       writer logico (lotto)                 pool I/O
───────────────                        ─────────────────────                 ────────
parse CBOR, valida contratto,     ─▶   per op: lookup indice,
hash chiave, codifica record           check expected-version + intenti,
                                       assegna versione+1, csn = csn lotto,
                                       append record nel buffer ACTIVE,
                                       append entry nei delta indici sec.,
                                       stage aggiornamento indice
                                       ── fine lotto ──
                                       COMMIT-GROUP record, write()   ─▶   flush (fdatasync)
                                       (passa al lotto successivo)         │
                                       ◀── callback in coda ───────────────┘
                                       pubblica indice (seqlock),
                                       versioni trattenute, dead-bytes,
                                       conferma i client del lotto
```

- Il record è scritto **una volta**, nel segmento `ACTIVE` ([ADR-0013](adr/0013-log-structured-segmento-active-come-log.md)).
- Livelli `:async` / `:group` / `:strong`; con `:group` la pubblicazione segue il flush
  ([ADR-0019](adr/0019-durability-e-group-commit-pipelined.md)).
- **Rotazione**: a `target` byte il writer chiude il lotto, flusha, scrive `hint`, `bloom`
  e `idx` del segmento, appende `SEG-CLOSE` + `SEG-OPEN` al control log, apre il nuovo file.

## Percorso di lettura

```
GET(serie, _id [, snapshot s])
  entra epoca
  hash → probe tabella (seqlock) → verifica chiave in arena
  se s dato e csn(entry) > s → cerca in versioni trattenute
  location (seg, off, len)
  cache[(seg, off)] → hit: copia nel buffer di risposta
                    → miss: pread (pool I/O) nello slot, inserisci, copia
  esci epoca
```

Nessuna allocazione; nessun lock; la cache è per location e non si invalida mai
([ADR-0025](adr/0025-cache-per-location.md)).

## Primary index

Tabella Swiss SWMR con seqlock per slot, key arena, versioni trattenute, rilocazione
condizionale; persistenza tramite file hint per segmento
([ADR-0015](adr/0015-primary-index-swiss-table-swmr.md)).

Slot (5 parole + 1 byte di controllo):

| Parola | Contenuto |
|---|---|
| 0 | hash64 della chiave |
| 1 | key-off (40 bit) · key-len (8) · tipo (8) · flag (8) |
| 2 | segment-id (32) · offset (32) |
| 3 | length (24) · versione (40) |
| 4 | csn (56) · seqlock (8) |

I limiti che discendono da questo layout sono in [limiti.md](limiti.md).

## Indici secondari

Un file immutabile a formato fisso per segmento e per indice, più Bloom filter; delta in
memoria per l'`ACTIVE`; query per segmento in parallelo con filtro di visibilità sul primary
index ([ADR-0026](adr/0026-indici-secondari-segmentati.md)).

## Snapshot e MVCC

CSN per Archivio; snapshot = numero; versioni trattenute per i documenti sovrascritti durante
uno snapshot; `snapshot-too-old` oltre la durata massima; livelli: read committed per GET,
snapshot isolation per le transazioni, `:serializable` opzionale con validazione del
read-set ([ADR-0020](adr/0020-csn-snapshot-isolamento.md)).

## Transazioni

### Single-Series

Operazioni con expected-version eseguite dal writer nel lotto; conflitto → `conflict`;
un CSN per lotto ([ADR-0005](adr/0005-writer-logico-per-serie.md)).

### Transazioni multiserie

```
coordinatore            writer A                 writer B              multiserie.log
    │ PREPARE ─────────▶ check, record prepared,
    │                    PREPARE A, intenti, flush
    │ PREPARE ─────────────────────────────────▶ (idem)
    │ ◀ prepared ─────── │                        │
    │ ◀ prepared ─────────────────────────────────┘
    │ decisione COMMIT ─────────────────────────────────────────────▶ append + flush
    │ csn ← incf; T in «in applicazione»; conferma client
    │ OUTCOME(T, csn) ─▶ indice, intenti, record OUTCOME
    │ OUTCOME(T, csn) ─────────────────────────▶ (idem)
    │ tutti applicati → T dimenticabile
```

Writer mai bloccato; intenti no-wait; presumed abort in recovery; troncamento del log per
checkpoint ([ADR-0021](adr/0021-2pc-intenti-outcome.md)).

## Compaction

- Selezione per spazio morto (CLEAN) o numero di segmenti piccoli stabili da ≥ 50 s (MERGE),
  con stato di carico `{basso, normale, alto}` e limitatore di banda per worker
  ([ADR-0023](adr/0023-politiche-di-compaction.md)).
- Workflow copy-on-write: lettura sequenziale → copia dei record necessari (LIVE,
  SNAPSHOT-LIVE, PREPARE non decisi, tombstone non scartabili) in `<id>.seg.tmp` + hint +
  idx + bloom → flush → rinomina → **record `SWAP`** nel control log → rilocazioni
  condizionali tramite il writer → sorgenti `OBSOLETE` → epoca superata → `RECLAIMABLE` →
  eliminazione ([ADR-0018](adr/0018-control-log-manifest-swap.md)).
- Parallela per segmento e per Serie; i reader non si fermano mai.

## Archivio: coordinamento minimo

Ciò che le Serie condividono, e il suo costo:

| Elemento condiviso | Costo per operazione |
|---|---|
| CSN | un incremento atomico per lotto (single-Series) o per decisione (multiserie) |
| Epoca | una lettura e una scrittura locale per sezione di lettura |
| Registro snapshot | solo alla creazione/chiusura di uno snapshot |
| `multiserie.log` | solo per le multiserie, con group commit |
| Scheduler | fuori dal percorso delle richieste |

## Recovery

Ordine ([11](11-recovery.md), [ADR-0022](adr/0022-registri-come-serie-catalogo.md)):

1. Registri: replay di `control.log`, ricostruzione dell'indice da hint + `ACTIVE`.
2. `multiserie.log` → tabella delle decisioni.
3. Per ogni Serie, in parallelo: replay del control log (insieme dei segmenti, orfani e
   `.tmp` eliminati); indice da hint; scansione dell'`ACTIVE` (record committed = seguiti da
   COMMIT-GROUP; PREPARE risolti con la tabella delle decisioni, `OUTCOME` mancanti appesi);
   delta degli indici secondari dall'`ACTIVE`; ricalcolo dei contatori dead-bytes.
4. CSN = massimo osservato + 1; stabilizzazione dei segmenti = fine recovery.
5. Apertura al traffico.

## Scheduler e osservabilità

Metriche per worker e per Serie, istogrammi log-lineari, senza allocazione; lo scheduler
legge valori EWMA per: numero di worker CPU e I/O, budget della cache per Serie, stato di
carico, banda e concorrenza della compaction ([12](12-osservabilita.md)).

## Interfacce

Protocollo a frame CBOR su TCP con multiplexing; query come dati; contratto della Serie nel
catalogo con evoluzione additiva ([ADR-0029](adr/0029-interfacce-protocollo-query-contratto.md)).

## Contratti

Regole di interfaccia tra moduli ([16](16-moduli.md)), derivate dagli ADR:

1. **Nessuna allocazione** nelle API dei percorsi caldi: ingressi come `(array start end)`,
   uscite in buffer del chiamante; i codici di esito sono valori immediati.
2. **Chi muta una Serie è il suo writer**: ogni modifica a indice, intenti, versioni
   trattenute, delta, contatori e control log passa dalla coda del writer. Compaction e
   coordinatore *propongono* (rilocazioni, OUTCOME); il writer *applica*.
3. **Chi legge entra in un'epoca** e non fa I/O di rete né attese al suo interno.
4. **Tutto l'I/O passa dal modulo `io`**, sostituibile in test.
5. **Ogni file persistente** ha magic, versione, lunghezza e CRC32C per record o per file
   (INV-F1).
6. **Ogni dato derivato dichiara la propria fonte** e ha una procedura di ricostruzione.

## Moduli

Corrispondenza con i 18 moduli della specifica in [16-moduli.md](16-moduli.md); gli ADR
indicano per ciascuno il meccanismo. Package: `arcdocdb.<modulo>`; moduli di supporto `io` e
`metrics`.

## Che cosa resta da misurare

Le decisioni sono prese; tre ipotesi quantitative restano da verificare con gli spike prima
della Fase 1 ([valutazione](valutazione/README.md#rivalutazione-2026-10-03)):

1. pause del GC con heap grande e allocazione nulla (SPK-02, criterio ≤ 5 ms);
2. throughput e correttezza del primary index SWMR (SPK-01);
3. scalabilità dei flush concorrenti di molte Serie (SPK-03).
