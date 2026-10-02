# Specifica originale (v1)

> Questo file è la **fonte di verità** del progetto: contiene il testo integrale del prompt di
> progettazione, con la sola formattazione Markdown ripristinata (titoli, elenchi, blocchi di
> codice, alberi). Il contenuto non è stato modificato.
>
> Note di trascrizione:
> - sono state omesse le due frasi di cornice della chat (apertura e chiusura), che non fanno
>   parte della specifica; la loro informazione utile è: *la regola «50 secondi di stabilità +
>   basso carico» si applica solo al MERGE, non al CLEAN*;
> - nella «Priorità concettuale» i separatori `>` erano andati persi nell'incolla e sono stati
>   ripristinati.
>
> Ogni modifica a questo file è un cambio di specifica: va accompagnata da un ADR in
> [`../adr/`](../adr/README.md) e dall'aggiornamento dei documenti derivati.

---

Progetta un database server general-purpose document-oriented scritto principalmente in Common
Lisp, con SBCL come implementazione di riferimento.

L'obiettivo principale è ottenere elevata velocità sulle operazioni fondamentali, forte
parallelismo tra Serie indipendenti, bassa latenza P95/P99, buona scalabilità su CPU multicore e
NVMe, WAL affidabile, transazioni locali e multiserie, MVCC/snapshot, compaction concorrente e
capacità di mantenere buone prestazioni anche durante improvvisi burst di letture.

Il database NON deve essere progettato specificamente per blogging o CMS: deve essere un motore
documentale general-purpose.

## ARCHITETTURA LOGICA

La gerarchia logica è:

```
Server
└── Archivio
    └── Serie
        └── Documento
```

Server:

* processo/server principale;
* gestione connessioni;
* scheduler globale;
* thread pool dinamico;
* gestione degli Archivi.

Archivio:

* contenitore logico/domain;
* contiene più Serie;
* rappresenta il livello al quale possono essere richieste transazioni e snapshot multiserie;
* contiene obbligatoriamente una Serie speciale chiamata Registri.

Serie:

* namespace dei documenti;
* definisce il paradigma/contratto dei documenti;
* definisce struttura/schema, validazione, indici e configurazione storage;
* è l'unità primaria di storage;
* è l'unità primaria di parallelismo;
* possiede il proprio WAL;
* possiede i propri segmenti;
* possiede i propri indici;
* deve poter operare in parallelo e indipendentemente dalle altre Serie.

Documento:

* unità logica di dati;
* possiede un `_id` univoco all'interno della Serie;
* può avere versioni storiche gestite tramite append-only storage e MVCC.

## SERIE SPECIALE Registri

Ogni Archivio deve contenere obbligatoriamente:

```
Registri
```

Registri NON è il WAL dei dati.

Registri contiene:

* catalogo/metadatabase delle Serie;
* metadati della configurazione delle Serie;
* informazioni necessarie al recovery del catalogo;
* un singolo file persistente `multiserie.log`.

`multiserie.log` è il transaction decision log per le transazioni che coinvolgono più Serie.

Non deve esistere un file globale separato per ogni transazione.

## TRANSAZIONI SINGLE-SERIES

Una transazione che coinvolge una sola Serie:

* usa esclusivamente il WAL della Serie;
* non scrive su `multiserie.log`;
* viene serializzata dal logical writer della Serie;
* utilizza optimistic version checking per rilevare conflitti sullo stesso documento.

Esempio:

```
doc42 = version 18
TX101 legge v18
TX102 legge v18
TX101 commit → v19
TX102 verifica expected-version = 18 → conflitto → abort/retry
```

Il controllo della versione deve essere atomico rispetto all'applicazione della modifica da parte
del writer della Serie.

## TRANSAZIONI MULTISERIE

Se una transazione modifica documenti appartenenti a più Serie, deve essere trattata come
transazione multiserie.

Esempio:

```
TX300:
  * modifica A.doc42;
  * modifica B.doc87.
```

La transazione usa:

* WAL della Serie A;
* WAL della Serie B;
* `Registri/multiserie.log`.

Tutte le modifiche della stessa transazione condividono un unico TXID.

Utilizzare un protocollo equivalente a 2PC:

1. BEGIN
2. PREPARE sui partecipanti
3. flush/fsync dei WAL partecipanti secondo il livello di durability
4. registrazione durevole della decisione nel `multiserie.log`
5. COMMIT oppure ABORT
6. applicazione/visibilità della decisione sui partecipanti.

La decisione COMMIT deve essere durable in `multiserie.log` prima che la transazione sia
considerata definitivamente committed.

Dopo un crash:

* il Recovery Manager legge `multiserie.log`;
* identifica le transazioni preparate/incomplete;
* determina la decisione definitiva;
* completa il COMMIT o l'ABORT sui WAL delle Serie partecipanti.

Non deve esistere un global data WAL.

Esiste solamente il transaction decision log globale `multiserie.log`.

## WAL

Ogni Serie possiede un WAL indipendente.

Il WAL serve per:

* durability;
* recovery;
* ricostruzione dello stato;
* registrazione ordinata delle modifiche.

Il sistema deve privilegiare group commit.

Esempio:

```
TX101 ─┐
TX102 ─┼──> WAL append ──> fsync
TX103 ─┘
```

Evitare fsync per ogni singola operazione salvo esplicita richiesta di durability forte.

Il group commit deve permettere a molte transazioni di condividere una singola operazione di
flush.

Anche `multiserie.log` deve utilizzare group commit dove appropriato.

## STORAGE APPEND-ONLY

Lo storage delle Serie è append-only.

Non modificare in-place i record già scritti nei segmenti.

Esiste esattamente un solo segmento `ACTIVE` scrivibile per ogni Serie.

Regola fondamentale:

```
ACTIVE = unico segmento mutabile.
```

Quando un segmento smette di essere ACTIVE:

* diventa immutabile;
* non può più essere riaperto in scrittura;
* non può più ricevere nuovi record.

Le nuove scritture vanno sempre in un nuovo segmento ACTIVE.

## SEGMENTI

Target/massimo normale per un segmento creato dal writer:

* circa 256 MB;
* configurabile per Serie.

I 256 MB sono un target/limite operativo per la normale creazione dei segmenti da parte del
writer.

NON è un requisito che i segmenti prodotti dalla compaction abbiano 256 MB.

Esempio:

```
S017 = 256 MB
live = 20 MB
dead = 236 MB
```

CLEAN può produrre:

```
S042 = 20 MB
```

S042 è immutabile.

Le nuove scritture NON devono essere aggiunte a S042 per portarlo a 256 MB.

Devono invece andare in:

```
S043 = ACTIVE
```

Quindi:

```
S017
 ↓ CLEAN
S042 = 20 MB immutable

nuove scritture
 ↓
S043 = ACTIVE
```

Stati possibili:

```
ACTIVE
CLOSED
OBSOLETE
RECLAIMABLE
DELETED
```

Solo ACTIVE è scrivibile.

CLOSED, OBSOLETE e RECLAIMABLE sono sempre immutabili.

## SEGMENT METADATA

Ogni segmento deve avere metadata almeno per:

* segment-id;
* record-count;
* live-records;
* dead-records;
* total-bytes;
* live-bytes;
* dead-bytes;
* stato;
* creation time;
* close time;
* eventuale versione/epoch;
* riferimenti necessari al recovery e alla gestione degli snapshot.

Questi metadata sono dati derivati/cache e NON devono essere considerati l'unica fonte di verità.

Devono poter essere:

* ricostruiti;
* verificati;
* corretti tramite WAL/data/index.

## VERSIONI DEI RECORD

Ogni versione può essere classificata come:

LIVE

* versione attualmente raggiungibile dall'indice corrente.

SNAPSHOT-LIVE

* versione non più corrente ma ancora necessaria a uno snapshot attivo.

DEAD

* nessun indice corrente e nessuno snapshot attivo può raggiungerla.

Un record DEAD può essere reclamato solo quando non esistono più riferimenti da:

* indice corrente;
* snapshot attivi;
* transazioni che necessitano quella versione.

## CLEAN

CLEAN opera su un singolo segmento.

Regola:

```
1 segmento sorgente
→ 1 nuovo segmento immutabile contenente solamente i record live/necessari.
```

Esempio:

```
S017:
  256 MB totali
  20 MB live
  236 MB dead

CLEAN:
  S017 → S042
```

S042 contiene solo i 20 MB necessari.

Il segmento originale S017:

* non viene modificato;
* diventa OBSOLETE dopo lo swap;
* resta leggibile finché necessario;
* viene eliminato solo quando nessun reader/snapshot lo utilizza.

CLEAN deve essere copy-on-write.

Non modificare mai il segmento sorgente in-place.

## MERGE

MERGE è distinto da CLEAN.

MERGE serve a ridurre l'eccessivo numero di segmenti piccoli.

Regola:

```
N segmenti piccoli
→ 1 nuovo segmento immutabile.
```

I segmenti sorgenti restano immutabili.

Non eseguire automaticamente un MERGE dopo ogni CLEAN.

Un segmento pulito può rimanere piccolo indefinitamente.

## CONDIZIONI OBBLIGATORIE PER MERGE

Un segmento può essere candidato a MERGE solamente se:

* è CLOSED;
* è immutabile;
* non è ACTIVE;
* è fermo da almeno 50 secondi;
* non è necessario a uno snapshot attivo;
* appartiene a un gruppo che supera le soglie di segmentazione/numero di piccoli segmenti;
* il motore è in una condizione di basso carico.

La soglia minima di stabilità è:

```
segment age >= 50 secondi
```

Il timestamp di riferimento deve essere quello di chiusura/stabilizzazione del segmento.

Lo scopo è evitare di compattare immediatamente segmenti appena chiusi.

Il MERGE è un'operazione di ottimizzazione strutturale e NON deve competere con il traffico
utente.

## LOW-LOAD MERGE POLICY

Prima di avviare un MERGE, il Compaction Scheduler deve verificare il carico del motore.

Considerare almeno:

* CPU utilization;
* P95 request latency;
* P99 request latency;
* profondità delle code;
* throughput delle richieste;
* WAL throughput;
* latenza WAL/fsync;
* utilizzo NVMe;
* I/O queue depth;
* backlog di compaction;
* numero di worker attivi.

Se il carico è alto:

* non avviare nuovi MERGE;
* ridurre la concorrenza dei MERGE;
* dare priorità alle richieste utente e al WAL.

Se durante un MERGE il carico aumenta significativamente:

* non avviare nuovi merge;
* ridurre la concorrenza futura;
* eventualmente mettere in pausa o rallentare il lavoro non critico.

Il MERGE non deve monopolizzare:

* CPU;
* NVMe;
* memoria;
* cache;
* memory bandwidth.

## POLITICA GENERALE DI COMPACTION

La politica è:

```
live = 0
→ DELETE direttamente se nessuno snapshot/reference lo utilizza.

0 < live < total
→ CLEAN → nuovo segmento contenente solo live/needed records.

live ≈ total
→ nessuna compaction necessaria.

troppi segmenti piccoli
→ MERGE, ma solamente se:
  * i segmenti candidati hanno almeno 50 secondi di stabilità;
  * il carico del motore è basso.
```

Quindi CLEAN e MERGE hanno finalità diverse.

CLEAN:

* recupero dello spazio morto;
* rimozione delle versioni inutili.

MERGE:

* riduzione della frammentazione;
* riduzione del numero di segmenti;
* miglioramento della località di lettura.

## COMPACTION PARALLELA

La compaction deve essere parallelizzabile per:

* segmento;
* Serie.

Esempio:

```
Compaction Scheduler
│
├── Worker 1 → S017 → S101
├── Worker 2 → S018 → S102
├── Worker 3 → S019 → S103
└── Worker 4 → S020 → S104
```

Non imporre un singolo compaction worker globale.

Il scheduler deve distribuire dinamicamente il lavoro.

## WORKFLOW CLEAN/MERGE

Workflow generale:

1. selezionare segmento candidato;
2. verificare stato;
3. verificare snapshot/reference;
4. leggere sequenzialmente il segmento;
5. copiare solamente record necessari;
6. creare nuovo segmento;
7. fsync del nuovo segmento;
8. preparare metadata;
9. eseguire atomic index swap;
10. segnare il segmento sorgente OBSOLETE;
11. attendere che nessun reader/snapshot lo utilizzi;
12. segnare RECLAIMABLE;
13. eliminare.

Per MERGE:

* leggere più segmenti;
* produrre un nuovo segmento;
* eseguire lo stesso meccanismo copy-on-write;
* mantenere i sorgenti immutabili fino al reclaim.

## READERS DURANTE COMPACTION

I reader devono poter continuare a leggere i segmenti vecchi mentre la compaction produce i nuovi
segmenti.

La compaction non deve bloccare globalmente le letture.

Dopo l'atomic swap:

* i nuovi reader usano il nuovo indice/segmento;
* i reader già attivi possono terminare usando il vecchio segmento.

## INDEX

Primary index:

```
_id → location
```

La location deve contenere almeno:

* segment-id;
* offset;
* length;
* version.

L'indice `_id` deve essere altamente ottimizzato per lookup O(1) medio.

Valutare una struttura tipo Swiss Table.

Evitare milioni di oggetti Lisp separati per ogni entry.

Preferire:

* packed arrays;
* vectors;
* strutture compatte;
* metadata binari;
* memoria contigua.

## SECONDARY INDEX

Utilizzare strutture differenti in base al tipo di query:

Stringhe/prefix:

* ART.

Numeri/date/range:

* B+ tree o struttura equivalente ordinata.

Categorie:

* posting lists.

Boolean/low cardinality:

* bitmap.

Bloom filter per segmento:

* utilizzarlo solamente per stabilire che un valore è sicuramente assente oppure potenzialmente
  presente;
* non usarlo come struttura di localizzazione definitiva.

## SECONDARY INDEX DELTA

Per indici secondari soggetti a frequenti modifiche usare un modello LSM-like:

```
base index
+
immutable delta(s)
→ merge asincrono
→ nuova base index
```

Esempio:

```
category="tech"
→ REMOVE 42

category="sport"
→ ADD 42
```

La nuova base index viene costruita senza bloccare globalmente i reader.

## INDEX SNAPSHOT

Gli indici devono essere immutabili per i reader.

Esempio:

```
Reader → Index v17

Writer:
  costruisce Index v18
  atomic swap

nuovi reader → Index v18
reader precedenti → completano su v17.
```

## CACHE

La cache iniziale utilizza CLOCK.

Se i benchmark mostrano scan pollution significativa, valutare 2Q.

La cache può essere partizionata per Serie per impedire che un burst su una singola Serie
monopolizzi tutta la cache.

Read path:

```
request
→ Serie
→ snapshot/index
→ cache
→ segment
```

## CONCORRENZA

Preferire:

```
1 logical writer per Serie
+
molti reader concorrenti.
```

Non utilizzare:

* un thread permanente per ogni Serie;
* un thread per ogni richiesta;
* un global writer lock.

Serie indipendenti devono poter scrivere in parallelo.

Esempio:

```
client
→ queue Serie A
→ Writer A
→ WAL A

client
→ queue Serie B
→ Writer B
→ WAL B
```

Il writer serializza solamente ciò che deve essere serializzato all'interno della singola Serie.

## THREAD POOL DINAMICO

Usare un pool dinamico di worker thread.

Non creare/distruggere continuamente thread.

Riutilizzare i worker.

Lo scheduler deve adattare dinamicamente il numero di worker in base a:

* queue depth;
* CPU utilization;
* throughput;
* P50;
* P95;
* P99;
* numero di Serie attive;
* distribuzione del carico tra Serie;
* I/O utilization;
* WAL throughput;
* compaction backlog.

Usare una strategia tipo:

* EWMA;
* AIMD;
* hysteresis.

Regole indicative:

```
queue cresce + CPU libera
→ aumentare worker.

queue cresce + CPU satura
→ non aumentare ciecamente.

P99 peggiora significativamente
→ fermare l'espansione o ridurre worker.

queue vuota + CPU bassa
→ ridurre worker.
```

Lo stesso scheduler deve coordinare il carico di:

* query;
* writer;
* WAL;
* compaction.

## COMPACTION SCHEDULER DINAMICO

Il Compaction Scheduler deve avere limiti indipendenti dal normale request scheduler.

Deve poter:

* aumentare worker CLEAN quando il sistema è scarico;
* ridurli quando aumenta il traffico;
* impedire MERGE durante carico elevato;
* preferire CLEAN urgente rispetto a MERGE;
* evitare starvation delle richieste utente.

Priorità concettuale:

```
user traffic
>
WAL/durability
>
CLEAN necessario
>
MERGE opportunistico
```

Il MERGE è quindi deliberatamente opportunistico.

## SNAPSHOT / MVCC

Uno snapshot è una vista logica consistente a un determinato punto/versione.

Non è una copia fisica dell'intero database.

Un normale GET non necessita di uno snapshot globale:

* legge la versione corrente committed.

Una transazione locale può utilizzare uno snapshot della Serie.

Una transazione multiserie può utilizzare uno snapshot coerente a livello di Archivio.

La natura append-only dello storage conserva naturalmente versioni storiche fino al reclaim.

Uno snapshot deve impedire alla compaction di eliminare le versioni che esso necessita.

Esempio:

```
Snapshot S vede:
  A = 100
  B = 200

Un'altra transazione aggiorna entrambi.

Lo snapshot continua a vedere:
  A = 100
  B = 200

fino alla sua conclusione.
```

## INDEX/SNAPSHOT/RECLAIM

Il reclaim di un segmento deve avvenire solamente quando:

* nessun indice corrente lo referenzia;
* nessuno snapshot lo referenzia;
* nessuna transazione attiva lo necessita;
* nessun reader sta ancora utilizzando il segmento.

## CACHE E SNAPSHOT

La cache deve essere consapevole della versione/epoch del dato.

Evitare che un reader ottenga una versione incompatibile con il proprio snapshot.

## SIMD E OTTIMIZZAZIONI NATIVE

Il database deve essere progettato per essere SIMD-friendly.

In Common Lisp/SBCL:

1. utilizzare strutture dati compatte;
2. typed arrays;
3. type declarations;
4. minimizzare boxing e allocazioni;
5. favorire accessi sequenziali;
6. profilare;
7. introdurre SIMD solamente sui veri hot path.

SBCL può generare SIMD automaticamente in alcuni casi numerici opportunamente tipizzati.

Per hot path estremi è possibile utilizzare:

* SBCL-specific operations;
* foreign functions;
* C/C++;
* Rust.

Preferire comunque Common Lisp per la logica generale del database.

Candidati SIMD:

* bitmap AND/OR/XOR;
* Bloom filters;
* scans;
* confronti;
* filtri;
* parsing;
* hashing;
* compressione/decompressione.

La struttura append-only con segmenti immutabili e scansioni sequenziali deve favorire tali
ottimizzazioni.

## RECOVERY

Il Recovery Manager deve essere in grado di ricostruire il sistema dopo crash.

Deve verificare:

* WAL;
* segment metadata;
* index metadata;
* atomic swap;
* segment state;
* transaction state;
* `multiserie.log`.

Dopo crash:

* recuperare i WAL delle singole Serie;
* ricostruire o verificare gli indici;
* identificare segmenti ACTIVE/CLOSED/OBSOLETE;
* completare o annullare operazioni di compaction incomplete;
* processare `multiserie.log`;
* completare transazioni multiserie preparate.

Le operazioni di compaction devono essere crash-safe.

Un segmento nuovo non deve diventare visibile come definitivo prima che i suoi dati siano
durable.

Un atomic swap incompleto deve poter essere determinato durante recovery.

## CATALOGO

`Registri/catalog/` contiene il catalogo delle Serie.

Per ogni Serie memorizzare almeno:

* nome;
* configurazione;
* schema/contratto;
* configurazione degli indici;
* segment configuration;
* stato;
* metadata necessari al recovery.

Il catalogo deve essere modificabile in modo transazionale e crash-safe.

## LAYOUT FISICO

Struttura indicativa:

```
Archivio/
├── Registri/
│   ├── catalog/
│   └── multiserie.log
│
├── Serie-A/
│   ├── wal/
│   ├── segments/
│   └── index/
│
├── Serie-B/
│   ├── wal/
│   ├── segments/
│   └── index/
│
└── ...
```

Non creare un global data WAL.

Ogni Serie rimane fisicamente indipendente.

## PARALLELISMO

Il parallelismo deve essere gerarchico:

```
Server
→ Archivio
→ Serie
→ writer/readers
→ WAL
→ compaction
→ query/index operations
```

La Serie è l'unità principale di isolamento del carico.

L'obiettivo è evitare che una Serie molto trafficata blocchi le altre.

Un burst di letture su Serie A non deve impedire:

* scritture su Serie B;
* query su Serie C;
* compaction controllata su Serie D.

## OSSERVABILITÀ

Implementare metriche dettagliate almeno per:

Request:

* throughput;
* P50;
* P95;
* P99;
* P99.9.

Storage:

* segment count;
* segment size;
* live/dead ratio;
* bytes reclaimed;
* CLEAN throughput;
* MERGE throughput.

WAL:

* append throughput;
* fsync latency;
* group size;
* WAL queue depth.

Index:

* hit rate;
* lookup latency;
* rebuild time.

Cache:

* hit/miss;
* eviction;
* per-Serie occupancy;
* scan pollution.

Scheduler:

* worker count;
* queue depth;
* CPU utilization;
* I/O utilization;
* compaction concurrency.

GC/SBCL:

* allocation rate;
* GC frequency;
* GC pause;
* heap usage.

## BENCHMARK

I benchmark devono essere eseguiti su hardware identico quando si confronta il database con altri
sistemi.

Hardware di riferimento:

* 16–32 core;
* 64–128 GB RAM;
* NVMe PCIe 4/5;
* dataset sufficientemente grande da evitare benchmark puramente cache-only quando si misura
  storage;
* documenti indicativamente 1–4 KB.

Workload da misurare:

* GET `_id`;
* GET `_id` con cache hit;
* GET `_id` con accesso NVMe;
* INSERT;
* UPDATE;
* DELETE/tombstone;
* indexed query;
* sequential scan;
* CLEAN;
* MERGE;
* mixed read/write;
* burst di sole letture;
* burst di scritture;
* transazioni single-Series;
* transazioni multiserie.

Misurare sempre:

* throughput;
* P50;
* P95;
* P99;
* CPU;
* RAM;
* cache hit rate;
* WAL bandwidth;
* fsync latency;
* NVMe bandwidth;
* queue depth;
* compaction throughput;
* numero worker;
* contention;
* SBCL GC.

## TARGET PRELIMINARI

Questi valori sono target architetturali indicativi, NON benchmark già dimostrati.

Su hardware adeguato:

GET `_id`, cache/index:
~1–4 M ops/s aggregate.

GET `_id`, NVMe:
~150k–600k ops/s.

INSERT async durability:
~700k–2 M ops/s.

INSERT group commit:
~300k–1 M ops/s.

UPDATE append-only:
~400k–1.2 M ops/s.

DELETE/tombstone:
~500k–1.5 M ops/s.

Simple indexed query:
~500k–2 M ops/s.

Sequential scan:
~1–5+ GB/s.

CLEAN:
~0.5–3+ GB/s.

MERGE:
dipendente da numero di segmenti, dimensioni, layout, I/O e carico disponibile.

Multiseries transactions:
ordine di grandezza da decine a centinaia di migliaia di transazioni/s, fortemente dipendente dal
numero di Serie coinvolte e dal costo del commit durevole.

Questi numeri devono essere verificati tramite benchmark reali.

## CONFRONTO CON ORACLE, MYSQL E MONGODB

Non utilizzare benchmark eterogenei per dichiarare superiorità diretta.

Oracle, MySQL/InnoDB e MongoDB hanno:

* architetture differenti;
* semantiche differenti;
* livelli di durability differenti;
* workload differenti;
* configurazioni differenti.

Il database proposto può avere un percorso particolarmente corto per operazioni document/KV
semplici grazie a:

* Serie indipendenti;
* un writer logico per Serie;
* primary index in RAM;
* append-only storage;
* WAL per Serie;
* group commit;
* segmenti immutabili;
* cache;
* parallelismo orizzontale tra Serie.

Questo deve essere trattato come ipotesi architetturale da verificare sperimentalmente, non come
risultato già dimostrato.

Per un confronto corretto usare:

* stesso hardware;
* stesso dataset;
* stessa dimensione documento;
* stessi indici;
* stesso livello di durability;
* stessa concorrenza;
* workload equivalente;
* stessa semantica della transazione.

## FAULT INJECTION

Implementare test di fault injection almeno per:

* crash durante WAL append;
* crash durante fsync;
* crash dopo prepare;
* crash prima del commit decision;
* crash dopo commit decision;
* crash durante atomic index swap;
* crash durante CLEAN;
* crash durante MERGE;
* crash durante reclaim;
* crash durante rebuild index;
* crash con snapshot attivi;
* crash durante transazione multiserie.

Verificare invarianti:

1. nessun dato committed deve andare perso;
2. nessuna transazione multiserie deve risultare parzialmente committed;
3. nessun segmento ancora referenziato deve essere eliminato;
4. nessuno snapshot deve osservare una versione non coerente;
5. un segmento sorgente deve rimanere recuperabile fino al completamento dello swap;
6. compaction interrotta deve essere ripetibile o completabile durante recovery.

## MODULI SOFTWARE

Organizzare il sistema almeno nei seguenti moduli:

1. Storage Engine
2. WAL Manager
3. Segment Manager
4. Segment Metadata Manager
5. Primary Index Manager
6. Secondary Index Manager
7. Cache Manager
8. Snapshot/MVCC Manager
9. Transaction Manager
10. Multiseries Transaction Log Manager
11. Compaction Manager
12. Recovery Manager
13. Scheduler
14. Dynamic Thread Pool
15. Query Engine
16. Network/Protocol Layer
17. Archivio/Serie/Documento Catalog Manager
18. SIMD/Hot Path Optimization Layer

## PRINCIPI ARCHITETTURALI FONDAMENTALI

Il progetto deve rispettare questi principi:

* append-only;
* un solo ACTIVE segment per Serie;
* solo ACTIVE è scrivibile;
* segmenti CLOSED/OBSOLETE/RECLAIMABLE sempre immutabili;
* nuove scritture sempre su un nuovo ACTIVE;
* CLEAN produce un nuovo segmento immutabile;
* MERGE produce un nuovo segmento immutabile;
* CLEAN e MERGE non modificano mai i sorgenti;
* CLEAN può produrre segmenti molto più piccoli di 256 MB;
* MERGE non è obbligatorio dopo CLEAN;
* MERGE solamente su segmenti stabili da almeno 50 secondi;
* MERGE solamente quando il carico del motore è basso;
* MERGE è opportunistico e non deve penalizzare il traffico utente;
* compaction parallelizzabile;
* scheduler dinamico;
* WAL per Serie;
* group commit;
* nessun global data WAL;
* un unico `Registri/multiserie.log`;
* 2PC-like per transazioni multiserie;
* MVCC/snapshot logici;
* reclaim solo quando non esistono più riferimenti;
* primary index altamente ottimizzato;
* secondary indexes specializzati;
* cache anti-scan-pollution;
* parallelismo tra Serie;
* un logical writer per Serie;
* molti reader concorrenti;
* thread pool dinamico;
* SIMD solamente dove dimostrato utile dai benchmark;
* recovery crash-safe;
* fault injection;
* benchmark riproducibili.

Obiettivo finale: costruire un database documentale general-purpose in Common Lisp/SBCL con un
hot path molto efficiente per le operazioni comuni, forte parallelismo tra Serie, storage
append-only crash-safe, compaction copy-on-write e adattiva, transazioni locali e multiserie
robuste, e comportamento prevedibile sotto carichi misti e improvvisi burst di lettura.
