# Glossario

## Convenzione linguistica

- I **termini di dominio** introdotti dalla specifica restano in italiano, anche nel codice:
  `archivio`, `serie`, `documento`, `registri`, `multiserie`.
- «Serie» è invariabile (una Serie, più Serie). Nel codice: `serie` al singolare e al plurale;
  dove serve distinguere, usare un nome di collezione esplicito (es. `serie-table`).
- I **termini tecnici consolidati** restano in inglese: WAL, segment, snapshot, commit, flush,
  group commit, compaction, reclaim, swap, writer, reader, worker.
- I nomi di stato e di operazione della specifica si scrivono in maiuscolo: `ACTIVE`, `CLOSED`,
  `OBSOLETE`, `RECLAIMABLE`, `DELETED`; `LIVE`, `SNAPSHOT-LIVE`, `DEAD`; CLEAN, MERGE.

## Modello logico

| Termine | Definizione |
|---|---|
| **Server** | Processo principale: connessioni, scheduler globale, thread pool, gestione degli Archivi. |
| **Archivio** | Contenitore logico di più Serie; livello a cui si richiedono transazioni e snapshot multiserie. |
| **Serie** | Namespace di documenti; unità primaria di storage e di parallelismo. Possiede WAL, segmenti e indici propri. |
| **Documento** | Unità logica di dati, identificata da `_id` univoco nella Serie. |
| **`_id`** | Identificatore del documento, univoco all'interno della Serie. |
| **Registri** | Serie speciale obbligatoria di ogni Archivio: catalogo e `multiserie.log`. Non è il WAL dei dati. |
| **Catalogo** | Metadatabase delle Serie, in `Registri/catalog/`. |
| **Contratto** | Ciò che una Serie definisce sui propri documenti: schema, validazione, indici, configurazione storage. |

## Storage

| Termine | Definizione |
|---|---|
| **Append-only** | I record scritti non si modificano; ogni modifica è un nuovo record. |
| **Segmento** | File di record di una Serie. Target ~256 MB se creato dal writer. |
| **ACTIVE** | L'unico segmento scrivibile di una Serie. |
| **CLOSED** | Segmento immutabile, in uso. |
| **OBSOLETE** | Segmento sostituito dalla compaction, ancora leggibile da reader/snapshot già attivi. |
| **RECLAIMABLE** | Segmento che nessuno usa più, eliminabile. |
| **DELETED** | Segmento eliminato. |
| **Segment metadata** | Contatori e tempi di un segmento; dati derivati, ricostruibili. |
| **Tombstone** | Record che marca l'eliminazione di un documento. |
| **Location** | Posizione di una versione: segment-id, offset, length, version. |
| **LIVE** | Versione raggiungibile dall'indice corrente. |
| **SNAPSHOT-LIVE** | Versione non più corrente ma necessaria a uno snapshot attivo. |
| **DEAD** | Versione non raggiungibile né dall'indice corrente né da snapshot attivi. |
| **Manifest** | (Proposta, QA-04) Registrazione autorevole dell'insieme dei segmenti validi di una Serie. |

## Compaction

| Termine | Definizione |
|---|---|
| **Compaction** | Termine generico per CLEAN e MERGE. |
| **CLEAN** | 1 segmento → 1 nuovo segmento con i soli record necessari. Recupera spazio morto. |
| **MERGE** | N segmenti piccoli → 1 nuovo segmento. Riduce la frammentazione. Opportunistico. |
| **Copy-on-write** | Il risultato è un nuovo file; i sorgenti non vengono toccati. |
| **Atomic swap** | Passaggio atomico dei reader dalla vecchia alla nuova versione di indice/segmento. |
| **Reclaim** | Eliminazione di un segmento non più referenziato. |
| **Stabilità** | Tempo trascorso dalla chiusura/stabilizzazione di un segmento; ≥ 50 s per il MERGE. |
| **Basso carico** | Condizione del motore, valutata dal Compaction Scheduler, necessaria per avviare un MERGE. |

## Log e transazioni

| Termine | Definizione |
|---|---|
| **WAL** | Write-ahead log; uno per Serie. |
| **Group commit** | Più transazioni condividono una singola operazione di flush. |
| **Durability** | Garanzia che ciò che è confermato sopravviva a un crash; a più livelli (QA-05). |
| **`multiserie.log`** | Transaction decision log dell'Archivio: decisioni COMMIT/ABORT delle transazioni multiserie. Non contiene dati. |
| **Transazione single-Series** | Modifica documenti di una sola Serie; usa solo il WAL della Serie. |
| **Transazione multiserie** | Modifica documenti di più Serie; protocollo 2PC-like. |
| **TXID** | Identificatore di transazione; unico per tutte le modifiche di una transazione multiserie. |
| **PREPARE** | Prima fase del 2PC: il partecipante registra in modo durevole di poter eseguire il commit. |
| **Punto di commit** | Momento in cui la decisione COMMIT è durevole in `multiserie.log`. |
| **Optimistic version checking (OCC)** | Al commit si verifica che la versione letta sia ancora quella corrente; altrimenti conflitto. |
| **Expected-version** | La versione che la transazione si aspetta di trovare al commit. |

## Concorrenza

| Termine | Definizione |
|---|---|
| **Writer logico** | L'unico flusso di esecuzione che muta una Serie in un dato momento; non è un thread dedicato. |
| **Reader** | Operazione di lettura in corso; può essere concorrente a writer e compaction. |
| **Worker** | Thread del pool dinamico. |
| **Snapshot** | Vista logica consistente a un punto/versione; non è una copia fisica. |
| **MVCC** | Multi-version concurrency control: i reader vedono versioni, non lock. |
| **EWMA / AIMD / isteresi** | Media mobile esponenziale / crescita additiva e riduzione moltiplicativa / soglie distinte in salita e discesa: gli strumenti del controllo dinamico. |
| **Scan pollution** | Degrado della cache causato da scansioni che espellono dati frequentemente usati. |

## Termini introdotti dalle decisioni di progetto

| Termine | Definizione |
|---|---|
| **Control log** | `wal/control.log`: log strutturale della Serie (segmenti, swap, stati, checkpoint). ADR-0013, ADR-0018. |
| **CSN** | Commit Sequence Number: contatore di Archivio che ordina i commit e definisce la visibilità. ADR-0020. |
| **File hint** | Indice primario di un segmento chiuso, da cui si ricostruisce l'indice in memoria. ADR-0015. |
| **Key arena** | Area di memoria contigua che contiene le chiavi `_id` di una Serie. ADR-0015. |
| **Versioni trattenute** | Tabella delle versioni non più correnti ancora visibili a uno snapshot. ADR-0015. |
| **Seqlock** | Contatore per slot che permette letture senza lock e rileva le scritture concorrenti. ADR-0032. |
| **EBR** | Epoch-based reclamation: un oggetto ritirato si elimina quando ogni reader ha superato l'epoca del ritiro. ADR-0016. |
| **Intento** | Modifica di una transazione multiserie preparata e non ancora decisa su un documento. ADR-0021. |
| **OUTCOME** | Record che registra nel segmento l'esito (COMMIT/ABORT) di una multiserie. ADR-0021. |
| **Presumed abort** | Regola di recovery: senza decisione COMMIT durevole, la transazione è abortita. ADR-0021. |
| **Lineage** | Il più piccolo segment-id tra gli antenati di un segmento; governa lo scarto dei tombstone. ADR-0023. |
| **Stato di carico** | `basso` / `normale` / `alto`: governa CLEAN e MERGE. ADR-0023. |
| **Rilocazione condizionale** | Aggiornamento di una entry dell'indice dopo la compaction, applicato solo se punta ancora alla location sorgente. ADR-0015. |

## Affidabilità

| Termine | Definizione |
|---|---|
| **Classe di integrità** | C1 percorso dei dati, C2 correttezza funzionale, C3 governo delle risorse, C4 strumenti. ADR-0031. |
| **Fail-stop** | A fronte di un guasto non recuperabile il componente si ferma invece di proseguire con uno stato incerto. ADR-0033. |
| **HEALTHY / DEGRADED / FAULTED** | Stati di salute di una Serie; `MULTI-DISABLED` per l'Archivio. ADR-0033. |
| **Quarantena** | Stato di un segmento con dati non verificabili: non viene letto né compattato. ADR-0033. |
| **Verifica in lettura** | Controllo di CRC32C, chiave, versione e CSN prima di restituire un record. ADR-0033. |
| **Scrubbing** | Rilettura periodica dei segmenti chiusi per rilevare alterazioni latenti. ADR-0033. |
| **Scansione di risincronizzazione** | Ricerca di record validi dopo un'anomalia nel log, per distinguere coda troncata da corruzione. ADR-0033. |
| **Verificatore offline** | `arcdocdb-verify`: controlla in sola lettura formati, CRC e coerenza di un Archivio. ADR-0033. |
| **Simulatore deterministico** | Esecuzione del sistema con tempo, casualità, schedulazione e I/O simulati, riproducibile da seme. ADR-0035. |
| **Test differenziale** | Stessa sequenza di operazioni sul motore e su un modello di riferimento; i risultati devono coincidere. ADR-0035. |
| **Deviazione** | Scostamento registrato e approvato da una regola di codifica. |

## Identificativi della documentazione

| Prefisso | Significato | Dove |
|---|---|---|
| `INV-` | Invariante | [invarianti.md](invarianti.md) |
| `QA-` | Questione aperta | [questioni-aperte.md](questioni-aperte.md) |
| `FI-` | Scenario di fault injection | [14-fault-injection.md](14-fault-injection.md) |
| `M01…M18` | Modulo software | [16-moduli.md](16-moduli.md) |
| `ADR-` | Decisione architetturale | [adr/](adr/README.md) |
| `RSK-` | Rischio | [valutazione/registro-rischi.md](valutazione/registro-rischi.md) |
| `SPK-` | Spike di valutazione | [valutazione/piano-spike.md](valutazione/piano-spike.md) |
| `REQ-` | Requisito tracciato | [tracciabilita/requisiti.lisp](tracciabilita/requisiti.lisp) |
| `FM-` | Modo di guasto | [affidabilita/analisi-dei-guasti.md](affidabilita/analisi-dei-guasti.md) |
| `COD-` | Regola di codifica | [affidabilita/standard-di-codifica.md](affidabilita/standard-di-codifica.md) |
| `DEV-` / `COV-` | Deviazione / eccezione di copertura | [affidabilita/deviazioni.md](affidabilita/deviazioni.md) |
