# Implementazione

Fondazioni introdotte dopo la richiesta dell'autore del 2026-10-08 di iniziare la scrittura
del codice. L'autorizzazione non equivale alla chiusura dei criteri della Fase 0 o alla
qualifica del motore completo.

La **ricerca full text** è un requisito approvato della v1
([ADR-0053](../adr/0053-ricerca-full-text-indici-invertiti.md)), con
integrazione e qualifica previste nella fase 8. Il primo
[nucleo di prodotto](full-text.md) comprende analizzatore Unicode 18.0.0,
run invertiti posizionali con predicati all/any/frase e cornice binaria.
Il [codec completo](full-text-codec.md) aggiunge le sezioni `.idx` e query su viste
verificate dei file. Commit, visibilita MVCC e pubblicazione durevole restano da integrare.
Le [riserve locali del writer](full-text-riserve.md) aggiungono ammissione dei budget
e copie possedute sotto lease. Il [ponte PUT/WAL](full-text-put.md) analizza una cornice
privata e ne accoda gli stessi byte, trattenendo il legame al lotto e alla sua incarnazione.
I [riferimenti fisici](full-text-riferimenti.md) conservano posizione e stamp dopo
il riuso del buffer, distinguendo CSN ordinario e TXID prepared.
La [directory privata delle righe](full-text-righe.md) risolve posting e riferimenti
sotto lease, distinguendo assenza, preparazione e cattura completa.
Pubblicazione durevole, MVCC e ritiro restano da collegare.
I criteri sono nel [piano di verifica](../affidabilita/piano-di-verifica.md#ricerca-full-text).
Il [contratto operativo](../full-text.md) e il
[formato `.idx` v2/type 5](../formato-indice-full-text.md) sono definiti da
[ADR-0054](../adr/0054-contratto-e-formato-full-text.md); la prima implementazione
non chiude ancora i requisiti nel loro perimetro complessivo.

| Modulo | Contratto e verifica | Codice |
|---|---|---|
| M1 Single-Series Durable Core | [Startup, recovery, admission e richieste di produzione](production-engine-bootstrap.md), [metodo](production-engine-bootstrap-metodo.md), [evidenze del nucleo](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-22-production-engine-bootstrap/report.md) | [`src/engine/`](../../src/engine/) |
| Sessione Unix M1 | [Contratto, limiti e CLI di produzione](production-unix-m1.md), [qualifica locale](https://github.com/gpicchiarelli/ArcDocDB/blob/13c2eec90a7a80f97f3bd9ded6b62abd75b7cf78/spikes/results/2026-10-23-production-unix-m1/report.md) | [`src/local/`](../../src/local/) |
| Completamento nomi Archivio | [Gate canonico, preflight globale ed effetti per Serie](stabilizzazione-archivio.md), [metodo](stabilizzazione-archivio-metodo.md) | [`src/recovery-bootstrap/`](../../src/recovery-bootstrap/) |
| Nucleo full text | [Profilo Unicode, run posizionale, predicati e cornice](full-text.md), [decisioni](full-text-decisioni.md) | [`src/fulltext/`](../../src/fulltext/) |
| Codec e viste full text | [File completo, legame al descriptor e query sui byte](full-text-codec.md), [revisione](full-text-codec-decisioni.md) | [`src/fulltext/`](../../src/fulltext/) |
| Preparazione documentale full text | [CBOR, percorsi, budget cumulativi e limite del file](full-text-documenti.md), [revisione](full-text-documenti-decisioni.md) | [`src/fulltext/document.lisp`](../../src/fulltext/document.lisp) |
| Riserve full text del writer | [Budget collettivi, copie possedute e ownership](full-text-riserve.md), [metodo e decisioni](full-text-riserve-metodo.md) | [`src/fulltext-admission/`](../../src/fulltext-admission/) |
| Legame PUT/WAL full text | [Cornice posseduta, append e riferimenti al lotto](full-text-put.md), [metodo e decisioni](full-text-put-metodo.md) | [`src/fulltext-put/`](../../src/fulltext-put/) |
| Riferimenti fisici full text | [Cattura dal lotto sigillato e lifetime](full-text-riferimenti.md), [metodo e decisioni](full-text-riferimenti-metodo.md) | [`src/fulltext-put/physical.lisp`](../../src/fulltext-put/physical.lisp) |
| Directory delle righe full text | [Ricerca locale e riferimenti](full-text-righe.md), [metodo e decisioni](full-text-righe-metodo.md) | [`src/fulltext-admission/rows.lisp`](../../src/fulltext-admission/rows.lisp), [`src/fulltext-put/row-reference.lisp`](../../src/fulltext-put/row-reference.lisp) |
| Verifica delle evidenze (C4) | [Processi isolati, limiti e riduzione ordinata](evidenze-parallele.md) | [`tools/check-evidence.lisp`](../../tools/check-evidence.lisp) |
| Prova verticale di una Serie | [Scrittura, SIGKILL, recovery, ripresa e secondo crash](prova-verticale.md) | [`tests/vertical/`](../../tests/vertical/) |
| Creazione relativa dei temporanei | [Nuovo file esclusivo dal parent posseduto](io-creazione-relativa.md), [metodo](io-creazione-relativa-metodo.md) | [`src/io/create-relative.lisp`](../../src/io/create-relative.lisp) |
| Fondazioni binarie | [Record v1/v2, CRC32C e lotti SEAL](fondazioni-binarie.md) | [`src/foundation/`](../../src/foundation/) |
| CRC32C ARM64 | [Backend Lisp/SBCL e risultati GET](crc32c-arm64.md); [metodo](crc32c-arm64-metodo.md) | [`crc32c-native.lisp`](../../src/foundation/crc32c-native.lisp) |
| CRC32C 16/32 B | [Confronto, piccoli record e GET completo](crc32c-unroll32.md); mantenuto il kernel 16 B | [`spike e metodo`](../../spikes/SPK-08-generated-code/metodo-crc32c-unroll32.md) |
| Testo UTF-8 | [Validazione limitata, pura e parallela](utf8.md) | [`src/codec/utf8.lisp`](../../src/codec/utf8.lisp) |
| Testate CBOR | [Lettura pura in sei valori](cbor-header.md) | [`src/codec/cbor-header.lisp`](../../src/codec/cbor-header.lisp) |
| Testate CBOR minime | [Larghezze di argomenti e float, senza decodifica](cbor-minimo.md) | [`src/codec/cbor-minimal.lisp`](../../src/codec/cbor-minimal.lisp) |
| Scrittura delle testate CBOR | [MT0..6 minimi, destinazione privata e preflight](cbor-scrittura.md) | [`src/codec/cbor-write.lisp`](../../src/codec/cbor-write.lisp) |
| Scrittura delle stringhe CBOR | [Item MT2/3, budget completo, UTF-8 e overlap](cbor-stringhe.md) | [`src/codec/cbor-string-write.lisp`](../../src/codec/cbor-string-write.lisp) |
| Scrittura dei valori semplici CBOR | [Codici wire MT7, preflight e destinazione privata](cbor-semplici.md) | [`src/codec/cbor-simple-write.lisp`](../../src/codec/cbor-simple-write.lisp) |
| Scrittura dei float CBOR | [Bit IEEE, riduzione esatta e destinazione privata](cbor-float-scrittura.md) | [`src/codec/cbor-float-write.lisp`](../../src/codec/cbor-float-write.lisp) |
| Composizione degli array CBOR | [Item verificati, budget della radice e scratch privato](cbor-array.md), [verifiche](cbor-array-risultati.md) | [`src/codec/cbor-array-write.lisp`](../../src/codec/cbor-array-write.lisp) |
| Composizione delle mappe CBOR | [Coppie verificate, budget della radice e scratch privato](cbor-map.md), [verifiche](cbor-map-risultati.md) | [`src/codec/cbor-map-write.lisp`](../../src/codec/cbor-map-write.lisp) |
| Composizione dei tag CBOR | [Contenuto verificato, nodi inclusivi e profondità invariata](cbor-tag.md), [verifiche](cbor-tag-risultati.md) | [`src/codec/cbor-tag-write.lisp`](../../src/codec/cbor-tag-write.lisp) |
| Lettura del primo item CBOR | [Frontiera assoluta, coda non letta e scratch privato](cbor-item.md), [verifiche](cbor-item-risultati.md) | [`src/codec/cbor-item-read.lisp`](../../src/codec/cbor-item-read.lisp) |
| Lettura delle stringhe CBOR | [Intervallo readonly del payload MT2/3 e UTF-8](cbor-stringa-lettura.md), [verifiche](cbor-stringa-lettura-risultati.md) | [`src/codec/cbor-string-read.lisp`](../../src/codec/cbor-string-read.lisp) |
| Struttura CBOR | [Item completo, UTF-8 e budget con scratch per worker](cbor-struttura.md) | [`src/codec/cbor-scan.lisp`](../../src/codec/cbor-scan.lisp) |
| Item CBOR con testate minime | [Un attraversamento, limiti e scratch privato](cbor-minimo-struttura.md) | [`src/codec/cbor-scan-minimal.lisp`](../../src/codec/cbor-scan-minimal.lisp) |
| CSN di Archivio | [Registro dei commit in corso e orizzonte](csn.md) | [`src/csn/`](../../src/csn/) |
| Metadati storage | [Header dei segmenti, EDIT e DECISION](metadati-storage.md) | [`src/storage/`](../../src/storage/) |
| Header dei log | [Identità e integrità di control e multiserie](header-log.md) | [`src/storage/log-header.lisp`](../../src/storage/log-header.lisp) |
| Segmenti compattati | [Prefisso CLOSED e record ordinari](segmenti-compattati.md) | [`src/storage/compaction-scan.lisp`](../../src/storage/compaction-scan.lisp) |
| Code dei writer | [MPSC locale, gettone e tratti limitati](code-writer.md) | [`src/execution/`](../../src/execution/) |
| Consegna dei writer | [Idle, pronto, in esecuzione e obbligo di scheduling](writer-handoff.md) | [`src/execution/handoff.lisp`](../../src/execution/handoff.lisp) |
| Lista dei writer pronti | [Ring preallocati, partizioni indipendenti e scansione limitata](writer-ready.md) | [`src/execution/ready.lisp`](../../src/execution/ready.lisp) |
| Ricircolo dei writer pronti | [Scambio FIFO atomico a ring pieno](writer-recycle.md) | [`src/execution/ready-recycle.lisp`](../../src/execution/ready-recycle.lisp) |
| Contesto worker | [Lease, batch confermati, retry e fault locale](writer-worker.md) | [`src/execution/worker-types.lisp`](../../src/execution/worker-types.lisp) |
| Integrazione dei worker | [Base comune, scope e controllo completo](writer-worker-integrazione.md) | [`arcdocdb.asd`](../../arcdocdb.asd) |
| Controllore del pool | [Target limitato, EWMA, AIMD e isteresi](controllore-pool.md) | [`src/scheduler/`](../../src/scheduler/) |
| Attuazione del pool | [Attivazione e ritiro confermati dai worker](pool-worker-lifecycle.md) | [`src/scheduler/lifecycle-worker.lisp`](../../src/scheduler/lifecycle-worker.lisp) |
| Presa governata dal pool | [Gate active, contesto IDLE e presa C1 delegata](pool-worker-claim.md) | [`src/scheduler/pool-claim.lisp`](../../src/scheduler/pool-claim.lisp) |
| Collegamento pool/Serie | [Binding immutabile, nuova presa e obblighi già assunti](pool-dispatch.md) | [`src/dispatch/`](../../src/dispatch/) |
| Ricircolo pool/Serie | [Un solo trasferimento ready e routing del nuovo CLAIMED](pool-recycle.md) | [`src/dispatch/recycle.lisp`](../../src/dispatch/recycle.lisp) |
| Avvio dell'obbligo pool/Serie | [Routing corrente e doppia lease esplicita](pool-begin.md) | [`src/dispatch/begin.lisp`](../../src/dispatch/begin.lisp) |
| Passo del dispatcher pool/Serie | [Scelta unica fra ammissione e obblighi esistenti](pool-step.md) | [`src/dispatch/step.lisp`](../../src/dispatch/step.lisp) |
| Catena pool/dispatcher/Serie | [Worker reali, isolamento e ritiro con handoff](pool-catena-risultati.md); [metodo](pool-catena-metodo.md) | [`tests/scheduler/pool-chain.lisp`](../../tests/scheduler/pool-chain.lisp) |
| Preparazione di un tratto pool/Serie | [Selezione e un solo avvio, con token e rifiuti espliciti](pool-prepara.md); [risultati](pool-prepara-risultati.md) | [`src/dispatch/start.lisp`](../../src/dispatch/start.lisp) |
| Confine I/O | [Append, pread e flush durevole](io.md); [apertura readonly relativa e dimensione](io-apertura-relativa.md) | [`src/io/`](../../src/io/) |
| Completamento I/O | [Cleanup, frontiere e capacità dopo short I/O](io-completamento.md) | [`src/io/flush.lisp`](../../src/io/flush.lisp), [`src/io/transfer.lisp`](../../src/io/transfer.lisp) |
| Rinomina nella directory | [FD parent, cambio atomico e fail-stop locale](io-rinomina.md) | [`src/io/rename.lisp`](../../src/io/rename.lisp) |
| Pubblicazione di temporanei | [Rinomina esclusiva, identità e completamento senza sostituzione](io-pubblicazione.md) | [`src/io/publish.lisp`](../../src/io/publish.lisp) |
| Associazione dei file | [Device/inode e capacità readonly/append del medesimo ACTIVE](associazione-file.md) | [`src/io/identity.lisp`](../../src/io/identity.lisp) |
| Nuovo segmento writer | [Header durevole, rilettura, directory e sorgente certificata](inizializzazione-active.md) | [`src/active/`](../../src/active/) |
| ACTIVE vuoto | [Radice iniziale, CLOSED recuperati e primo lotto](get-active-vuoto.md) | [active-init.lisp](../../src/get-resolver/active-init.lisp) |
| Checkpoint del control log | [EDIT completo, piano privato e preparazione durevole a blocchi](checkpoint-control.md) | [`src/control/`](../../src/control/) |
| Pubblicazione del control log | [Rinomina ancorata, identità dei nomi e gettone unico](pubblicazione-control.md) | [`src/control/publication.lisp`](../../src/control/publication.lisp) |
| Control log recuperato | [Lettura readonly, manifest posseduto e transizione conservativa](control-recuperato.md); [metodo delle misure](control-transizione-metodo.md) | [`src/control/recovery-read.lisp`](../../src/control/recovery-read.lisp) |
| Vecchio ACTIVE recuperato | [Prefisso readonly, prepared risolti e chiusura verificata](active-recuperato.md); [verifiche](active-recuperato-verifica.md) e [metodo delle misure](active-recuperato-metodo.md) | [`src/recovery-active/`](../../src/recovery-active/) |
| Checkpoint dal recovery | [Stato completo da CONTROL e ACTIVE](checkpoint-recovery.md) | [`src/recovery-checkpoint/`](../../src/recovery-checkpoint/) |
| CLOSED recuperati | [Prefisso autorevole, esiti locali e insieme completo prima del publisher](closed-recuperato.md) | [`src/recovery-closed/`](../../src/recovery-closed/) |
| CSN recuperati | [Massimo osservato, fonti autorevoli e aggregazione di una Serie completa](recovery-csn.md) | [`src/recovery-active/csn.lisp`](../../src/recovery-active/csn.lisp), [`src/recovery-closed/csn-serie.lisp`](../../src/recovery-closed/csn-serie.lisp) |
| Piano CSN dell'Archivio | [Insieme Serie, provenienza dei replay e massimo complessivo](csn-archivio-recovery.md) | [`src/recovery-archive-csn/`](../../src/recovery-archive-csn/) |
| Lotti WAL | [Formazione, SEAL e group commit](wal.md) | [`src/wal/`](../../src/wal/) |
| CSN dei lotti WAL | [Chiusura, token e risoluzione](wal-csn.md) | [`src/wal/csn.lisp`](../../src/wal/csn.lisp) |
| Controller della Serie | [Pubblicazione FIFO, token e ritiro I/O](controller-serie.md) | [`src/series/`](../../src/series/) |
| Worker e Serie | [Doppia lease, debito batch e ordine dell'handoff](worker-serie.md) | [`src/series/worker-run.lisp`](../../src/series/worker-run.lisp) |
| Routing dei worker | [Ordinali immutabili, registro copiato e selezione diretta](routing-worker.md) | [`src/series/routing-select.lisp`](../../src/series/routing-select.lisp) |
| Verifica del controller | [Prove strutturate, copertura e misure parallele](controller-serie-risultati.md) | [`tests/series/`](../../tests/series/) |
| Slot dell'indice v2 | [Payload compatto, seqlock e rilocazione](slot-indice-v2.md) | [`src/index/`](../../src/index/) |
| Indice primario v2 | [Chiavi, gruppi Swiss e pubblicazione della directory](indice-primario.md) | [`src/index/primary-read.lisp`](../../src/index/primary-read.lisp) |
| Modo automatico dell'indice | [Primo selettore residente/paginato e modello del lifetime](indice-automatico.md); backend e attuatore aperti | [`src/index/mode-policy.lisp`](../../src/index/mode-policy.lisp) |
| Pagine dell'indice | [Codec e formato per bucket, directory e chiavi lunghe](pagine-indice.md) | [`src/index/page-read.lisp`](../../src/index/page-read.lisp) |
| Hash delle chiavi | [XXH64 tipizzato, seme immutabile e mappe fisiche](hash-chiavi.md) | [`src/hash/`](../../src/hash/) |
| Cache dei record | [Insiemi associativi, CLOCK e copie verificate](cache-record.md) | [`src/cache/`](../../src/cache/) |
| Prestazioni del nucleo GET | [Metodo, oracoli e stress parallelo](get-performance-metodo.md) | [`tests/get-performance/`](../../tests/get-performance/) |
| Costi GET e cardinalità | [Metodo preregistrato](get-costi-metodo.md); [risultati su CRC, copie e 4,19 milioni di chiavi](get-costi-risultati.md) | [`tools/get-cost-bench.lisp`](../../tools/get-cost-bench.lisp) |
| Percorso GET | [Candidato, fonte readonly, cache e conferma snapshot](get-record.md) | [`src/get/`](../../src/get/) |
| Verifica GET | [Prima suite funzionale, metodo e limiti](get-verifica.md) | [`tests/get/`](../../tests/get/) |
| Collegamento CSN/snapshot | [Registro unico e coordinamento senza attese](snapshot-csn.md) | [`src/mvcc/snapshots-csn.lisp`](../../src/mvcc/snapshots-csn.lisp) |
| Verifica snapshot e CSN | [Metodo preregistrato, decisioni e limiti](snapshot-verifica.md) | Registro e adattatore già presenti in `src/mvcc/` |
| Registro snapshot | [Pin, identità, attivazione e scadenza](registro-snapshot.md) | [`src/mvcc/snapshots-register.lisp`](../../src/mvcc/snapshots-register.lisp) |
| Epoche e reclaim | [Slot dei reader e ticket limitati per i segmenti](epoche-e-reclaim.md) | [`src/epochs/`](../../src/epochs/) |
| Compiti di lettura | [Ingresso EBR, controlli snapshot e cleanup](compiti-lettura.md) | [`src/read/`](../../src/read/) |
| Verifica EBR e lettura | [Suite, metodo, mutanti e limiti](lettura-verifica.md) | [`tests/epochs/`](../../tests/epochs/) e [`tests/read/`](../../tests/read/) |
| Resolver GET CLOSED | [Frontiera dal manifest, flag e prova OUTCOME](get-resolver.md); [metodo delle prove funzionali](get-resolver-metodo.md) | [`src/get-resolver/`](../../src/get-resolver/) |
| Directory GET CLOSED | [Selezione limitata del segmento nella Serie](get-directory.md) | [`src/get-directory/`](../../src/get-directory/) |
| Fonti GET della Serie | [Acquisizione ACTIVE/CLOSED dalla singola radice pubblicata](get-fonti-serie.md) | [`src/get-directory/sources-read.lisp`](../../src/get-directory/sources-read.lisp) |
| Resolver GET ACTIVE ordinario | [Lotti verificati, root della Serie e directory persistente](get-active.md); [prove funzionali](get-active-verifica.md), [metodo](get-active-preflight-metodo.md) e [verifica dei rifiuti OPEN](get-active-preflight-verifica.md) | [`src/get-resolver/active-build.lisp`](../../src/get-resolver/active-build.lisp) |
| Scansione recovery | [Prefisso dei log e testimonianze SEAL](scansione-log.md) | [`src/recovery/`](../../src/recovery/) |
| Decisioni multiserie | [Tabella TXID, CSN e partecipanti](decisioni-multiserie.md) | [`src/recovery/decisions-build.lisp`](../../src/recovery/decisions-build.lisp) |
| Decision log dell'Archivio | [Lettura readonly, identità e collegamento al recovery ACTIVE](decisioni-recuperate.md) | [`src/recovery-archive/`](../../src/recovery-archive/) |
| Manifest della Serie | [Ripiegamento degli EDIT del control log](manifest-control-log.md) | [`src/recovery/`](../../src/recovery/) |
| Inventario recovery | [Piano e raccolta readonly dalla directory](inventario.md); [metodo delle prove native](inventario-directory-metodo.md) | [`src/recovery/inventory-build.lisp`](../../src/recovery/inventory-build.lisp), [`inventory-directory.lisp`](../../src/recovery/inventory-directory.lisp) |
| Fonti possedute recovery | [Insieme readonly completo, budget e cleanup](fonti-recovery.md); [metodo](fonti-recovery-metodo.md) | [`src/recovery/inventory-sources.lisp`](../../src/recovery/inventory-sources.lisp) |
| Nomi recuperati | [Completamento idempotente di una fonte viva, identità e fsync parent](stabilizzazione-nomi-recovery.md) | [`src/recovery-series/stabilize.lisp`](../../src/recovery-series/stabilize.lisp), [`src/io/stabilize.lisp`](../../src/io/stabilize.lisp) |
| Versioni recuperate | [Massimo CSN, offset fisici e tombstone provvisorio per chiave](selezione-versioni-recovery.md) | [`src/recovery-selection/`](../../src/recovery-selection/) |
| Indice dal recovery | [Materializzazione privata per chiave e ripristino idempotente](indice-da-recovery.md) | [`src/recovery-selection/index.lisp`](../../src/recovery-selection/index.lisp), [`src/index/primary-restore.lisp`](../../src/index/primary-restore.lisp) |
| Visita CLOSED per il replay | [Prefisso interamente verificato e consegna dei soli dati committed](replay-closed.md) | [`src/recovery-replay/`](../../src/recovery-replay/) |
| Nomi dell'intera Serie | [Preflight globale prima degli effetti, completamento e conteggi](stabilizzazione-serie.md) | [`src/recovery-series/stabilize-set.lisp`](../../src/recovery-series/stabilize-set.lisp) |
| ID dopo recovery | [Proposta oltre high-water e nomi osservati, senza prenotazione](id-segmento-recovery.md) | [`src/recovery/inventory-id.lisp`](../../src/recovery/inventory-id.lisp) |
| ID dall'inventario directory | [Una enumerazione attestata, selezione dal piano e directory prestata](id-directory-recovery.md) | [`src/recovery/inventory-directory-id.lisp`](../../src/recovery/inventory-directory-id.lisp) |
| Ordinamento delle decisioni | [Radix misurato e query concorrenti](decisioni-radix-risultati.md) | [`src/recovery/decisions-radix.lisp`](../../src/recovery/decisions-radix.lisp) |

Le evidenze hanno un ambito esplicito: un test del codec non verifica transazioni,
durability, recovery o prestazioni del database.

Il [bootstrap del runtime Archivio](runtime-archivio.md) collega il piano
CSN alla famiglia unica CSN/snapshot/epoche e al nuovo ambito GET. Il binding
non autorizza ancora il traffico.

Il [recovery semantico della Serie](recovery-serie.md) collega le fonti
readonly possedute ai reader ACTIVE/CLOSED: insieme e budget verificati
prima dei dati, scratch riusato e due risultati solo dopo il gate completo.

La [lettura coordinata dell'Archivio](recovery-archivio.md) applica prima
i preflight di tutte le Serie e i budget globali, poi restituisce letture
complete e piano CSN canonico, senza avviare il runtime o pubblicare effetti.

La [sessione locale M16](sessione-locale.md) propone il contratto necessario
al socket prioritario: framing, handshake, budget e scadenze. SPK-11 esercita
il solo trasporto; avvio/recovery/ammissione del prodotto restano prerequisiti.

L'[adozione dell'ACTIVE nel runtime](adozione-controller-runtime.md) collega
il prepared al CSN comune e rende unico il controller per log canonico,
senza acquisire lease o decidere il catalogo.

L'[adozione dei CLOSED nel runtime](adozione-closed-runtime.md) verifica insieme,
autorità e capacità esatte delle mappe recuperate e costruisce una directory
nel nuovo ambito condividendo le righe immutabili, senza riletture o pubblicazione.

La [raccolta degli archivi di comandi](raccolta-comandi.md) usa un manifest
esplicito, quattro worker e il controllo finale dell'inventario chiuso.

Il [progetto CI e statistiche](ci-statistiche.md) definisce misure per la
versione corrente, runner GitHub e pubblicazione compatta dei risultati
in `main`; resta una proposta da implementare e verificare.

Gli [esiti dei processi nelle mutazioni CBOR](cbor-mutazioni-processi.md)
distinguono i rilevamenti dei mutanti dagli errori dei worker di verifica.
