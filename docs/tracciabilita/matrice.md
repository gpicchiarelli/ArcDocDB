# Matrice di tracciabilità

> **Generata** da [requisiti.lisp](requisiti.lisp) con `make trace-write`. Non modificare a mano: `make trace` fallisce se non coincide.

**Sommario.** 114 requisiti. Per classe: C1 89, C2 6, C3 12, C4 7. Per stato: specificato 0, progettato 111, implementato 2, verificato 1. Invarianti coperti: 65/65. Scenari FI coperti: 13/13.

## Requisiti

| ID | Enunciato | Fonte | Classe | Stato | Invarianti | ADR | Verifica | FI |
|---|---|---|---|---|---|---|---|---|
| REQ-ARC-001 | La gerarchia logica è Server, Archivio, Serie, Documento. | Architettura logica | C2 | progettato |  | [0002](../adr/0002-serie-unita-di-storage-e-parallelismo.md) | rev, test |  |
| REQ-ARC-002 | La Serie è l'unità primaria di storage e di parallelismo; possiede log, segmenti e indici propri e opera in modo indipendente dalle altre Serie. | Architettura logica | C1 | progettato | INV-W1, INV-P3 | [0002](../adr/0002-serie-unita-di-storage-e-parallelismo.md) | test, bench |  |
| REQ-ARC-003 | Un Documento ha un _id univoco nella Serie e può avere versioni storiche gestite da storage append-only e MVCC. | Architettura logica | C1 | progettato |  | [0014](../adr/0014-formato-record-documento-id.md) | test, diff |  |
| REQ-ARC-004 | L'Archivio è il livello delle transazioni e degli snapshot multiserie e contiene obbligatoriamente la Serie Registri. | Architettura logica | C1 | progettato |  | [0022](../adr/0022-registri-come-serie-catalogo.md) | test |  |
| REQ-REG-001 | Registri non è il WAL dei dati: contiene il catalogo e un unico file multiserie.log; non esiste un file per transazione. | Serie speciale Registri | C1 | progettato | INV-W2 | [0006](../adr/0006-transazioni-multiserie-2pc.md), [0022](../adr/0022-registri-come-serie-catalogo.md) | rev, test |  |
| REQ-REG-002 | Il catalogo memorizza per ogni Serie nome, configurazione, schema, indici, configurazione dei segmenti, stato e metadata di recovery, ed è modificabile in modo transazionale e crash-safe: il documento della Serie è il punto di atomicità di creazione ed eliminazione, la directory segue. | Catalogo | C1 | progettato | INV-A7, INV-A11 | [0022](../adr/0022-registri-come-serie-catalogo.md), [0040](../adr/0040-manifest-a-record-unico.md) | test, fi | FI-13 |
| REQ-REG-003 | Ogni Serie è fisicamente indipendente nel proprio direttorio; non esiste un global data WAL. | Layout fisico | C1 | progettato | INV-W1 | [0003](../adr/0003-wal-per-serie.md) | rev, analisi |  |
| REQ-STO-001 | I record già scritti nei segmenti non sono mai modificati in-place. | Storage append-only | C1 | progettato | INV-S1 | [0004](../adr/0004-storage-append-only-un-solo-active.md) | test, rev |  |
| REQ-STO-002 | Esiste esattamente un segmento ACTIVE per Serie ed è l'unico scrivibile. | Storage append-only | C1 | progettato | INV-S2, INV-S3 | [0004](../adr/0004-storage-append-only-un-solo-active.md) | test, model |  |
| REQ-STO-003 | Un segmento che smette di essere ACTIVE è immutabile e non è più riaperto in scrittura. | Storage append-only | C1 | progettato | INV-S4 | [0004](../adr/0004-storage-append-only-un-solo-active.md) | test |  |
| REQ-STO-004 | Le nuove scritture vanno sempre in un nuovo segmento ACTIVE, mai in un segmento prodotto dalla compaction. | Segmenti | C1 | progettato | INV-S5 | [0004](../adr/0004-storage-append-only-un-solo-active.md) | test |  |
| REQ-STO-005 | I segmenti creati dal writer hanno dimensione target circa 256 MB configurabile per Serie; i segmenti prodotti dalla compaction non hanno requisito di dimensione. | Segmenti | C1 | progettato | INV-C4 | [0004](../adr/0004-storage-append-only-un-solo-active.md), [0023](../adr/0023-politiche-di-compaction.md) | test |  |
| REQ-STO-006 | Gli stati del segmento sono ACTIVE, CLOSED, OBSOLETE, RECLAIMABLE, DELETED con transizioni a senso unico; solo ACTIVE è scrivibile; di durevole c'è solo l'appartenenza all'insieme registrato nel manifest. | Segmenti | C1 | progettato | INV-S3, INV-S4 | [0018](../adr/0018-control-log-manifest-swap.md), [0040](../adr/0040-manifest-a-record-unico.md) | test, model |  |
| REQ-MET-001 | I segment metadata (identificativo, conteggi, byte, stato, tempi, epoch) sono dati derivati e possono essere ricostruiti, verificati e corretti da log, dati e indice. | Segment metadata | C1 | progettato | INV-S6 | [0018](../adr/0018-control-log-manifest-swap.md), [0040](../adr/0040-manifest-a-record-unico.md) | test, fi | FI-10 |
| REQ-VER-001 | Ogni versione è LIVE, SNAPSHOT-LIVE o DEAD; una versione DEAD è reclamabile solo senza riferimenti da indice, snapshot e transazioni. | Versioni dei record | C1 | progettato | INV-R1, INV-M2 | [0015](../adr/0015-primary-index-swiss-table-swmr.md), [0020](../adr/0020-csn-snapshot-isolamento.md), [0038](../adr/0038-orizzonte-di-visibilita.md) | test, model |  |
| REQ-CLN-001 | CLEAN trasforma un segmento sorgente in un nuovo segmento immutabile contenente solo i record live o necessari. | Clean | C1 | progettato | INV-C1 | [0007](../adr/0007-clean-e-merge-distinti.md) | test, diff |  |
| REQ-CLN-002 | CLEAN è copy-on-write: il segmento sorgente non è mai modificato, diventa OBSOLETE dopo lo swap e resta leggibile finché necessario. | Clean | C1 | progettato | INV-C3 | [0007](../adr/0007-clean-e-merge-distinti.md), [0018](../adr/0018-control-log-manifest-swap.md), [0040](../adr/0040-manifest-a-record-unico.md) | test, fi | FI-07 |
| REQ-CLN-003 | Il segmento prodotto da CLEAN può essere molto più piccolo del target e può restare piccolo indefinitamente. | Segmenti | C1 | progettato | INV-C4 | [0007](../adr/0007-clean-e-merge-distinti.md) | test |  |
| REQ-MRG-001 | MERGE trasforma N segmenti piccoli in un nuovo segmento immutabile e lascia immutabili i sorgenti. | Merge | C1 | progettato | INV-C2, INV-C3 | [0007](../adr/0007-clean-e-merge-distinti.md) | test, fi | FI-08 |
| REQ-MRG-002 | Non si esegue automaticamente un MERGE dopo ogni CLEAN. | Merge | C3 | progettato | INV-C4 | [0008](../adr/0008-merge-opportunistico.md) | test |  |
| REQ-MRG-003 | Un segmento è candidato a MERGE solo se CLOSED, immutabile, non ACTIVE, fermo da almeno 50 secondi dal timestamp di chiusura o stabilizzazione, non necessario a uno snapshot attivo, in un gruppo che supera le soglie, e con il motore a basso carico. | Condizioni obbligatorie per Merge | C3 | progettato | INV-C5, INV-C6 | [0008](../adr/0008-merge-opportunistico.md), [0023](../adr/0023-politiche-di-compaction.md) | test, bench |  |
| REQ-MRG-004 | Prima di un MERGE si valuta il carico; con carico alto non si avviano MERGE, se ne riduce la concorrenza e si dà priorità a richieste e log; se il carico aumenta durante un MERGE si sospende o rallenta il lavoro non critico. | Low-load merge policy | C3 | progettato | INV-C6, INV-P4 | [0008](../adr/0008-merge-opportunistico.md), [0023](../adr/0023-politiche-di-compaction.md) | test, bench |  |
| REQ-CMP-001 | Con live uguale a zero e nessun riferimento il segmento è eliminato; con live parziale si esegue CLEAN; con live circa uguale al totale non si compatta. | Politica generale di compaction | C3 | progettato |  | [0023](../adr/0023-politiche-di-compaction.md) | test |  |
| REQ-CMP-002 | Il workflow di compaction segue i tredici passi della specifica; il nuovo segmento non è visibile come definitivo prima che i suoi dati siano durevoli. | Workflow Clean/Merge | C1 | progettato | INV-C7 | [0018](../adr/0018-control-log-manifest-swap.md), [0040](../adr/0040-manifest-a-record-unico.md) | test, model, fi | FI-06 |
| REQ-CMP-003 | Un segmento sorgente resta recuperabile fino al completamento dello swap. | Fault injection | C1 | progettato | INV-C8 | [0018](../adr/0018-control-log-manifest-swap.md), [0040](../adr/0040-manifest-a-record-unico.md) | model, fi | FI-06, FI-07, FI-08 |
| REQ-CMP-004 | Una compaction interrotta è ripetibile o completabile durante il recovery. | Fault injection | C1 | progettato | INV-C9, INV-A7 | [0018](../adr/0018-control-log-manifest-swap.md), [0040](../adr/0040-manifest-a-record-unico.md) | model, fi | FI-07, FI-08 |
| REQ-CMP-005 | I reader continuano a leggere i segmenti vecchi durante la compaction; la compaction non blocca globalmente le letture; dopo lo swap i nuovi reader usano il nuovo segmento. | Readers durante compaction | C1 | progettato | INV-C10 | [0016](../adr/0016-epoch-based-reclamation.md) | test, model, bench |  |
| REQ-CMP-006 | La compaction è parallelizzabile per segmento e per Serie, con limiti indipendenti dal request scheduler e priorità utente, log, CLEAN necessario, MERGE. | Compaction parallela | C3 | progettato | INV-P4 | [0011](../adr/0011-thread-pool-dinamico.md), [0023](../adr/0023-politiche-di-compaction.md) | test, bench |  |
| REQ-CMP-007 | Un segmento è eliminato solo quando nessun indice, snapshot, transazione attiva o reader lo referenzia o lo utilizza. | Index/Snapshot/Reclaim | C1 | progettato | INV-R1 | [0016](../adr/0016-epoch-based-reclamation.md) | model, fi | FI-09, FI-11 |
| REQ-CMP-008 | Un tombstone è scartato dalla compaction solo se è superato da una versione durevole più recente, oppure se nessuna versione della chiave è trattenuta e nessun altro segmento può contenere un record più vecchio della stessa chiave (filtro di esistenza e CSN minimo del segmento). | ADR-0042 | C1 | progettato | INV-D1, INV-C11 | [0042](../adr/0042-tombstone-e-indice-dei-vivi.md) | test, prop, model |  |
| REQ-CMP-009 | La compaction copia solo i record necessari (puntati dall'indice, puntati dalle versioni trattenute, tombstone non scartabili), riscrive i record prepared committed come record ordinari con il loro CSN e non copia mai SEAL né OUTCOME. | ADR-0042 | C1 | progettato | INV-C1, INV-S7 | [0041](../adr/0041-multiserie-segmenti-autosufficienti.md), [0042](../adr/0042-tombstone-e-indice-dei-vivi.md) | test, diff, model |  |
| REQ-WAL-001 | Ogni Serie ha un log dei dati indipendente (segmento ACTIVE) e un control log strutturale; non esiste un global data WAL. | WAL | C1 | progettato | INV-W1, INV-F1 | [0003](../adr/0003-wal-per-serie.md), [0013](../adr/0013-log-structured-segmento-active-come-log.md) | test, rev |  |
| REQ-WAL-002 | Il sistema usa il group commit; non esegue un flush per ogni operazione salvo richiesta di durability forte; per ogni log c'è un solo compito di I/O alla volta, che scrive i lotti chiusi ed esegue il flush. | WAL | C1 | progettato |  | [0019](../adr/0019-durability-e-group-commit-pipelined.md), [0037](../adr/0037-lotto-sigillato.md) | test, bench |  |
| REQ-WAL-003 | I livelli di durability sono async, group e strong e cambiano solo il momento di pubblicazione e conferma; per group e strong un dato confermato non è perso e non è visibile prima di essere durevole. | WAL | C1 | progettato | INV-D1, INV-V1 | [0019](../adr/0019-durability-e-group-commit-pipelined.md), [0037](../adr/0037-lotto-sigillato.md) | test, fi | FI-01, FI-02, FI-05 |
| REQ-WAL-004 | multiserie.log usa il group commit. | WAL | C1 | progettato | INV-W2 | [0021](../adr/0021-2pc-intenti-outcome.md), [0041](../adr/0041-multiserie-segmenti-autosufficienti.md) | test, bench |  |
| REQ-WAL-005 | Ogni log è una sequenza di lotti sigillati: un lotto è valido per intero (SEAL che ne fissa file, posizione, numero di record, contenuto) o non esiste; un record non prepared è committed se e solo se sta in un lotto valido; il CSN del lotto è preso alla chiusura. | ADR-0037 | C1 | progettato | INV-F2, INV-M5 | [0037](../adr/0037-lotto-sigillato.md), [0039](../adr/0039-cornice-unica-dei-record.md) | test, fuzz, corr, fi, model | FI-01, FI-02 |
| REQ-WAL-006 | Una scrittura è confermata al client solo dopo la pubblicazione nell'indice e, per group e strong, solo dopo il flush che copre il suo lotto; la pubblicazione avviene in ordine di lotto. | ADR-0037 | C1 | progettato | INV-V5, INV-V1 | [0037](../adr/0037-lotto-sigillato.md) | test, diff, fi | FI-01, FI-02 |
| REQ-TXS-001 | Una transazione su una sola Serie usa solo il log della Serie e non scrive su multiserie.log. | Transazioni single-series | C1 | progettato | INV-T1 | [0005](../adr/0005-writer-logico-per-serie.md) | test |  |
| REQ-TXS-002 | Una transazione single-Series è serializzata dal writer logico e rileva i conflitti con optimistic version checking; il controllo della versione è atomico rispetto all'applicazione. | Transazioni single-series | C1 | progettato | INV-T2, INV-P1 | [0005](../adr/0005-writer-logico-per-serie.md) | test, diff, model |  |
| REQ-TXS-003 | Con due transazioni che leggono la stessa versione, la seconda a committare fallisce con conflitto e può ritentare. | Transazioni single-series | C1 | progettato | INV-T2 | [0005](../adr/0005-writer-logico-per-serie.md) | test, diff |  |
| REQ-TXM-001 | Tutte le modifiche di una transazione multiserie condividono un unico TXID. | Transazioni multiserie | C1 | progettato | INV-T5 | [0006](../adr/0006-transazioni-multiserie-2pc.md), [0041](../adr/0041-multiserie-segmenti-autosufficienti.md) | test, fi | FI-12 |
| REQ-TXM-002 | La transazione multiserie segue un protocollo 2PC: BEGIN, PREPARE sui partecipanti, flush, decisione durevole, COMMIT o ABORT, applicazione. | Transazioni multiserie | C1 | progettato |  | [0006](../adr/0006-transazioni-multiserie-2pc.md), [0021](../adr/0021-2pc-intenti-outcome.md), [0041](../adr/0041-multiserie-segmenti-autosufficienti.md) | test, model, fi | FI-03 |
| REQ-TXM-003 | La decisione COMMIT è durevole in multiserie.log prima che la transazione sia considerata committed. | Transazioni multiserie | C1 | progettato | INV-T3 | [0021](../adr/0021-2pc-intenti-outcome.md), [0041](../adr/0041-multiserie-segmenti-autosufficienti.md) | model, fi | FI-04, FI-05 |
| REQ-TXM-004 | Nessuna transazione multiserie risulta parzialmente committed, nemmeno dopo un crash, e uno snapshot la vede per intero o per niente. | Fault injection | C1 | progettato | INV-T4, INV-V2 | [0020](../adr/0020-csn-snapshot-isolamento.md), [0021](../adr/0021-2pc-intenti-outcome.md), [0038](../adr/0038-orizzonte-di-visibilita.md), [0041](../adr/0041-multiserie-segmenti-autosufficienti.md) | model, fi | FI-03, FI-04, FI-05, FI-12 |
| REQ-TXM-005 | Dopo un crash il Recovery Manager legge multiserie.log, identifica le transazioni preparate o incomplete, determina la decisione (presumed abort: senza DECISION la transazione è abortita) e rende durevole l'esito COMMIT di ogni partecipante nel record che ne chiude il segmento. | Transazioni multiserie | C1 | progettato | INV-T4, INV-A7 | [0021](../adr/0021-2pc-intenti-outcome.md), [0041](../adr/0041-multiserie-segmenti-autosufficienti.md) | model, fi | FI-03, FI-04, FI-05 |
| REQ-TXM-006 | Il writer di una Serie non si ferma ad attendere la decisione di una multiserie; i documenti con intento pendente rispondono conflict senza attesa. | ADR-0021 | C1 | progettato | INV-P3 | [0021](../adr/0021-2pc-intenti-outcome.md) | test, model, bench |  |
| REQ-TXM-007 | Un segmento CLOSED è autosufficiente: la rotazione attende che la Serie non abbia intenti pendenti; un record prepared è committed se e solo se il suo OUTCOME è nello stesso segmento o il suo esito è nel record del manifest che ha chiuso il segmento. | ADR-0041 | C1 | progettato | INV-S7 | [0041](../adr/0041-multiserie-segmenti-autosufficienti.md), [0040](../adr/0040-manifest-a-record-unico.md) | test, model, fi | FI-03, FI-05, FI-12 |
| REQ-TXM-008 | Una transazione multiserie è confermata al client dopo che la decisione è durevole e l'esito è stato applicato in memoria su tutti i partecipanti sani; un abort non scrive alcun record. | ADR-0041 | C1 | progettato | INV-V5, INV-T3 | [0041](../adr/0041-multiserie-segmenti-autosufficienti.md) | test, model, fi | FI-05, FI-12 |
| REQ-IDX-001 | Il primary index mappa _id a location (segment-id, offset, length, version; la versione è il CSN) con lookup O(1) medio, in strutture compatte senza un oggetto Lisp per entry. | Index | C1 | progettato |  | [0015](../adr/0015-primary-index-swiss-table-swmr.md), [0024](../adr/0024-memoria-e-gc.md), [0043](../adr/0043-primary-index-a-frammenti.md) | test, bench |  |
| REQ-IDX-002 | Gli indici sono immutabili per i reader; le nuove versioni diventano visibili con atomic swap e i reader precedenti completano sulla versione vecchia. | Index snapshot | C1 | progettato | INV-I1 | [0009](../adr/0009-indici-immutabili-atomic-swap.md) | test, model, fi | FI-06 |
| REQ-IDX-003 | La lettura di una entry del primary index non osserva mai uno stato intermedio, con tentativi limitati e ripiego sul writer. | ADR-0032 | C1 | progettato | INV-I1, INV-A8 | [0015](../adr/0015-primary-index-swiss-table-swmr.md), [0032](../adr/0032-seqlock-a-64-bit.md), [0043](../adr/0043-primary-index-a-frammenti.md) | test, model, soak |  |
| REQ-IDX-004 | La rilocazione da compaction aggiorna una entry solo se punta ancora alla location sorgente e non sovrascrive mai una versione più nuova. | ADR-0015 | C1 | progettato | INV-V3 | [0015](../adr/0015-primary-index-swiss-table-swmr.md) | test, model, fi | FI-06 |
| REQ-IDX-005 | Il primary index è una directory di frammenti a capacità fissa: nessuna manutenzione copia più di un frammento, lo spazio di slot e chiavi eliminati è recuperato alla divisione, e la stessa tabella realizza indice, versioni trattenute e versioni in sospeso. | ADR-0043 | C1 | progettato | INV-I3, INV-A8 | [0043](../adr/0043-primary-index-a-frammenti.md) | test, model, bench |  |
| REQ-IDX-006 | Il primary index contiene solo documenti vivi; la sua ricostruzione sceglie per ogni chiave il record committed con il CSN massimo e dà lo stesso risultato per qualsiasi ordine di lettura dei segmenti. | ADR-0042 | C1 | progettato | INV-C11, INV-S6 | [0042](../adr/0042-tombstone-e-indice-dei-vivi.md), [0039](../adr/0039-cornice-unica-dei-record.md) | test, prop, fi | FI-10 |
| REQ-SEC-001 | Gli indici secondari usano strutture per tipo di query (stringhe e prefix, intervalli, categorie, bitmap); il Bloom filter sui valori, sezione del file indice, dice solo assente o forse presente. | Secondary index | C2 | progettato | INV-I2 | [0026](../adr/0026-indici-secondari-segmentati.md), [0039](../adr/0039-cornice-unica-dei-record.md) | test, diff |  |
| REQ-SEC-002 | Gli indici secondari seguono il modello base più delta immutabili e la nuova base è costruita senza bloccare i reader. | Secondary index delta | C2 | progettato |  | [0026](../adr/0026-indici-secondari-segmentati.md) | test, diff |  |
| REQ-IDX-007 | Il reader ricontrolla root e generazione dopo il sondaggio anche su miss, con tentativi limitati; la manutenzione dichiara e controlla separatamente slot, byte delle chiavi, riferimenti della directory e memoria transitoria. | ADR-0050 | C1 | progettato | INV-I3, INV-A8 | [0043](../adr/0043-primary-index-a-frammenti.md), [0050](../adr/0050-pubblicazione-e-costi-della-directory.md) | test, model, bench, rev |  |
| REQ-CCH-001 | La cache usa CLOCK, può essere partizionata per Serie e misura la scan pollution per decidere un'eventuale evoluzione a 2Q. | Cache | C3 | progettato |  | [0010](../adr/0010-cache-clock.md), [0025](../adr/0025-cache-per-location.md) | test, bench |  |
| REQ-CCH-002 | La cache è consapevole della versione: un reader non ottiene mai una versione incompatibile con il proprio snapshot. | Cache e snapshot | C1 | progettato | INV-M3 | [0025](../adr/0025-cache-per-location.md), [0044](../adr/0044-cache-acceleratore-puro.md) | test, prop |  |
| REQ-CCH-003 | Il percorso di lettura è richiesta, Serie, snapshot e indice, cache, segmento. | Cache | C2 | progettato |  | [0025](../adr/0025-cache-per-location.md) | test |  |
| REQ-CCH-004 | La cache è un acceleratore puro: nessuna invalidazione, ri-etichettatura o svuotamento; il sistema dà le stesse risposte con la cache disattivata; una verifica fallita su un dato in cache lo scarta e rilegge dal segmento senza quarantena. | ADR-0044 | C1 | progettato | INV-A12, INV-M3 | [0044](../adr/0044-cache-acceleratore-puro.md) | test, diff, corr |  |
| REQ-CON-001 | Esiste un solo writer logico per Serie e molti reader concorrenti. | Concorrenza | C1 | progettato | INV-P1 | [0005](../adr/0005-writer-logico-per-serie.md) | test, model |  |
| REQ-CON-002 | Non esistono un global writer lock, un thread permanente per Serie o un thread per richiesta; ogni modifica allo stato di una Serie passa dal suo writer. | Concorrenza | C1 | progettato | INV-P2, INV-V4 | [0005](../adr/0005-writer-logico-per-serie.md) | rev, analisi, test |  |
| REQ-CON-003 | Serie indipendenti scrivono in parallelo; un burst su una Serie non impedisce scritture, query o compaction sulle altre. | Parallelismo | C3 | progettato | INV-P3 | [0002](../adr/0002-serie-unita-di-storage-e-parallelismo.md) | bench, test |  |
| REQ-THR-001 | Un pool dinamico di worker riutilizzati adatta il numero di worker con EWMA, AIMD e isteresi, senza creare e distruggere thread continuamente. | Thread pool dinamico | C3 | progettato |  | [0011](../adr/0011-thread-pool-dinamico.md), [0017](../adr/0017-piattaforma-e-io.md) | test, bench |  |
| REQ-CON-005 | Il parallelismo è un principio fondante: tra Serie non esiste alcun lock né alcuna scrittura condivisa per singola operazione; ciò che le Serie condividono è un elenco chiuso con costo limitato, pagato al più per lotto, per transazione multiserie o per snapshot; ogni meccanismo dichiara che cosa rende seriale; letture, compaction, recovery, ricostruzione dell'indice e query procedono in parallelo sulle rispettive unità. | Parallelismo | C1 | progettato | INV-P6, INV-P3 | [0036](../adr/0036-leggi-di-progetto.md), [0002](../adr/0002-serie-unita-di-storage-e-parallelismo.md), [0045](../adr/0045-modello-di-esecuzione.md) | rev, analisi, bench, test |  |
| REQ-CON-004 | Ogni unità di lavoro è un compito che gira fino al completamento; un worker di calcolo non esegue chiamate bloccanti; ogni attesa è un parcheggio in una lista con lunghezza e tempo massimi; una lettura che manca la cache migra al pool di I/O ripartendo dall'inizio. | ADR-0045 | C1 | progettato | INV-P5, INV-A8 | [0045](../adr/0045-modello-di-esecuzione.md) | test, rev, bench |  |
| REQ-MVC-001 | Uno snapshot è una vista logica consistente; un GET semplice legge la versione corrente committed. | Snapshot / MVCC | C1 | progettato | INV-M1 | [0020](../adr/0020-csn-snapshot-isolamento.md) | test, prop, diff | FI-11 |
| REQ-MVC-002 | Una transazione locale può usare uno snapshot della Serie; una multiserie uno snapshot coerente a livello di Archivio. | Snapshot / MVCC | C1 | progettato | INV-V2 | [0020](../adr/0020-csn-snapshot-isolamento.md), [0038](../adr/0038-orizzonte-di-visibilita.md) | test, model | FI-12 |
| REQ-MVC-003 | Uno snapshot impedisce alla compaction di eliminare le versioni che gli servono. | Snapshot / MVCC | C1 | progettato | INV-M2 | [0020](../adr/0020-csn-snapshot-isolamento.md) | test, fi | FI-11 |
| REQ-MVC-004 | Uno snapshot oltre la durata massima è terminato e le operazioni che lo usano ricevono snapshot-too-old. | ADR-0020 | C1 | progettato | INV-A8 | [0020](../adr/0020-csn-snapshot-isolamento.md) | test |  |
| REQ-MVC-005 | Uno snapshot con CSN s esegue la prima lettura solo quando l'orizzonte di visibilità è almeno s; due letture dello stesso documento nello stesso snapshot danno lo stesso risultato; uno snapshot creato dopo la conferma di un commit lo vede. | ADR-0038 | C1 | progettato | INV-M4, INV-M1 | [0038](../adr/0038-orizzonte-di-visibilita.md) | test, prop, model, fi | FI-11, FI-12 |
| REQ-MVC-006 | La versione di un documento è il CSN del commit che l'ha prodotta: expected-version è un CSN, non si ripete e non riparte dopo un'eliminazione; per ogni documento l'ordine dei CSN è l'ordine delle versioni. | ADR-0038 | C1 | progettato | INV-M5, INV-T2 | [0038](../adr/0038-orizzonte-di-visibilita.md) | test, diff, model |  |
| REQ-MVC-007 | Il writer trattiene la versione sostituita quando la soglia del registro degli snapshot è inferiore al CSN nuovo; la registrazione di uno snapshot pubblica la soglia prima di leggere il proprio CSN, con barriera di memoria completa. | ADR-0038 | C1 | progettato | INV-M2 | [0038](../adr/0038-orizzonte-di-visibilita.md) | test, model, soak |  |
| REQ-MVC-008 | Il registro dei CSN in volo ha capacità fissa; assegnazione del CSN e registrazione sono indivisibili rispetto all'avanzamento dell'orizzonte; uno slot non viene riusato finché il suo CSN non è pubblicato o annullato; quando non ci sono pendenti H raggiunge l'ultimo CSN, anche se un commit lento è stato superato da molti commit conclusi. | ADR-0046 | C1 | progettato | INV-M4, INV-M6, INV-A8 | [0046](../adr/0046-orizzonte-con-registro-limitato.md) | test, model, bench |  |
| REQ-REC-001 | Il Recovery Manager verifica log, segment metadata, index metadata, atomic swap, stato dei segmenti, stato delle transazioni e multiserie.log. | Recovery | C1 | progettato | INV-F1 | [0018](../adr/0018-control-log-manifest-swap.md), [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md), [0037](../adr/0037-lotto-sigillato.md) | test, fi | FI-01, FI-06 |
| REQ-REC-002 | Dopo un crash il sistema recupera i log delle Serie, ricostruisce o verifica gli indici, identifica i segmenti, completa o annulla le compaction incomplete, processa multiserie.log e completa le multiserie preparate. | Recovery | C1 | progettato | INV-A7 | [0018](../adr/0018-control-log-manifest-swap.md), [0021](../adr/0021-2pc-intenti-outcome.md), [0040](../adr/0040-manifest-a-record-unico.md), [0041](../adr/0041-multiserie-segmenti-autosufficienti.md) | test, fi, soak | FI-07, FI-08, FI-10 |
| REQ-REC-003 | Nessun dato committed è perso. | Fault injection | C1 | progettato | INV-D1 | [0013](../adr/0013-log-structured-segmento-active-come-log.md), [0019](../adr/0019-durability-e-group-commit-pipelined.md), [0037](../adr/0037-lotto-sigillato.md) | fi, diff, soak | FI-01, FI-02, FI-05, FI-06, FI-09, FI-10 |
| REQ-REC-004 | Un atomic swap incompleto è riconoscibile durante il recovery. | Recovery | C1 | progettato | INV-C7 | [0018](../adr/0018-control-log-manifest-swap.md), [0040](../adr/0040-manifest-a-record-unico.md) | model, fi | FI-06 |
| REQ-OBS-001 | Sono esposte le metriche di richiesta: throughput, P50, P95, P99, P99.9. | Osservabilità | C3 | progettato |  | [0011](../adr/0011-thread-pool-dinamico.md) | test |  |
| REQ-OBS-002 | Sono esposte le metriche di storage, log, indici, cache, scheduler e GC elencate dalla specifica. | Osservabilità | C3 | progettato |  | [0011](../adr/0011-thread-pool-dinamico.md) | test |  |
| REQ-BEN-001 | I benchmark sono riproducibili e, nei confronti con altri sistemi, eseguiti su hardware, dataset, indici, durability, concorrenza e semantica equivalenti. | Benchmark | C4 | progettato | INV-X2 | [0028](../adr/0028-target-e-obiettivi-di-latenza.md) | bench, rev |  |
| REQ-BEN-002 | I target di prestazione sono ipotesi finché non verificati; non si dichiara superiorità da benchmark eterogenei. | Target preliminari | C4 | progettato | INV-X2 | [0028](../adr/0028-target-e-obiettivi-di-latenza.md) | rev |  |
| REQ-FLT-001 | Sono implementati i test di fault injection per i dodici scenari della specifica e per la creazione di Serie. | Fault injection | C1 | progettato |  | [0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md) | fi | FI-01, FI-02, FI-03, FI-04, FI-05, FI-06, FI-07, FI-08, FI-09, FI-10, FI-11, FI-12, FI-13 |
| REQ-SIM-001 | Il sistema usa strutture compatte e array tipizzati; il SIMD si introduce solo sugli hot path dimostrati dai benchmark. | SIMD e ottimizzazioni native | C3 | progettato | INV-X1 | [0012](../adr/0012-simd-guidato-dai-benchmark.md), [0024](../adr/0024-memoria-e-gc.md) | rev, bench |  |
| REQ-SIM-002 | Il codice del progetto è solo Common Lisp. | ADR-0001 | C4 | progettato | INV-X3 | [0001](../adr/0001-common-lisp-sbcl.md), [0027](../adr/0027-dipendenze-e-test.md) | analisi, rev |  |
| REQ-MOD-001 | Il sistema è organizzato almeno nei diciotto moduli della specifica. | Moduli software | C2 | progettato |  | [0031](../adr/0031-software-critico-criteri-e-priorita.md) | rev |  |
| REQ-VAL-001 | La suite della Fase 0 compila gli esperimenti senza avvisi in processi isolati, esegue controlli deterministici e benchmark separati e registra in forma strutturata ogni prova e benchmark: parametri, comandi, ambiente, revisione, hash dei sorgenti, risultati, limiti, output grezzo e fallimenti. Nessun esito degli spike promuove automaticamente un requisito del motore a verificato. | Piano degli spike | C4 | implementato | INV-X2, INV-X3 | [0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md) | test, analisi |  |
| REQ-FOR-001 | Ogni record e ogni file persistente porta lunghezza e CRC32C; ciò che non si verifica è trattato come inesistente (coda), rigenerato (dato derivato) o dichiarato corrotto (dato confermato). | ADR-0013 | C1 | progettato | INV-F1 | [0013](../adr/0013-log-structured-segmento-active-come-log.md), [0014](../adr/0014-formato-record-documento-id.md), [0039](../adr/0039-cornice-unica-dei-record.md) | test, fuzz, corr, fi | FI-01, FI-10 |
| REQ-FOR-002 | Ogni file persistente ha magic e versione di formato; un formato non cambia, si crea una nuova versione con migrazione. | ADR-0014 | C1 | progettato | INV-F1 | [0014](../adr/0014-formato-record-documento-id.md) | test, rev |  |
| REQ-FOR-003 | Tutti i record di tutti i log hanno la stessa cornice di 24 byte con CRC dell'intestazione e CRC del corpo; l'intestazione è verificata prima di usare le lunghezze; il CRC del corpo è calcolato fuori dal writer. | ADR-0039 | C1 | progettato | INV-F1, INV-F2 | [0039](../adr/0039-cornice-unica-dei-record.md) | test, fuzz, corr, bench |  |
| REQ-FOR-004 | La lettura di un record prepared verifica una prova autorevole del segmento (OUTCOME o esito nel manifest): il TXID della prova coincide con lo stamp del record e il suo CSN coincide con quello della entry; una prova mancante, corrotta o riferita a un'altra versione produce errore di integrità. | ADR-0047 | C1 | progettato | INV-A2, INV-S7 | [0039](../adr/0039-cornice-unica-dei-record.md), [0047](../adr/0047-verifica-csn-dei-record-prepared.md) | test, corr, fuzz, diff |  |
| REQ-AFF-001 | Un errore di scrittura, flush, rinomina o sincronizzazione di directory porta la Serie o l'Archivio in FAULTED senza retry e senza conferma del lotto. | ADR-0033 | C1 | progettato | INV-A1 | [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md) | test, fi | FI-02 |
| REQ-AFF-002 | Ogni record letto da disco o da cache è verificato con i CRC32C di intestazione e corpo e con il confronto di chiave e CSN (la versione) prima di essere restituito; un dato non verificato non è mai restituito. | ADR-0033 | C1 | progettato | INV-A2 | [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md), [0039](../adr/0039-cornice-unica-dei-record.md) | test, corr, fuzz |  |
| REQ-AFF-003 | Nessun codice di prodotto è compilato con safety inferiore a 2; la compilazione è priva di avvisi; i costrutti vietati sono rilevati dal linter. | ADR-0034 | C4 | implementato | INV-A3 | [0034](../adr/0034-policy-di-compilazione-e-standard-di-codifica.md) | analisi |  |
| REQ-AFF-004 | Ogni errore è una condizione tipizzata della gerarchia arcdocdb-error, mai ignorata; le asserzioni sugli invarianti restano attive e in C1 portano la Serie in FAULTED. | ADR-0033 | C1 | progettato | INV-A4 | [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md), [0034](../adr/0034-policy-di-compilazione-e-standard-di-codifica.md) | analisi, rev, mut |  |
| REQ-AFF-005 | Ogni requisito ha fonte, classe e verifica; ogni invariante e ogni scenario FI è coperto da almeno un requisito; la matrice è generata e controllata. | ADR-0035 | C4 | verificato | INV-A5 | [0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md) | analisi |  |
| REQ-AFF-006 | Un processo di scrubbing verifica i segmenti chiusi con ciclo completo entro 7 giorni e mette in quarantena i segmenti con errori. | ADR-0033 | C1 | progettato | INV-A6 | [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md) | test, corr |  |
| REQ-AFF-007 | Il recovery è idempotente: interromperlo in qualsiasi punto e rieseguirlo produce lo stesso stato finale. | ADR-0033 | C1 | progettato | INV-A7 | [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md), [0036](../adr/0036-leggi-di-progetto.md) | model, fi, soak | FI-01, FI-06, FI-07, FI-08, FI-10 |
| REQ-AFF-008 | Ogni risorsa ha un limite configurato e controllato; il superamento produce un rifiuto esplicito; nessun ciclo è illimitato. | ADR-0033 | C1 | progettato | INV-A8 | [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md), [0034](../adr/0034-policy-di-compilazione-e-standard-di-codifica.md) | test, rev |  |
| REQ-AFF-009 | Il recovery distingue una coda da una corruzione con la frontiera durevole dichiarata dai SEAL: un'anomalia sotto la frontiera di un SEAL successivo valido porta il log in FAULTED senza alcuna scrittura; altrimenti la lunghezza valida è l'inizio del primo lotto non valido. La regola vale per segmento ACTIVE, control log e multiserie.log e non dipende dall'ordine di persistenza delle scritture non sincronizzate. | ADR-0037 | C1 | progettato | INV-F1, INV-F3, INV-A1 | [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md), [0037](../adr/0037-lotto-sigillato.md) | test, fi, corr, model | FI-01, FI-02 |
| REQ-AFF-010 | Esiste un verificatore offline che apre un Archivio in sola lettura, verifica formati, CRC e coerenza tra log, segmenti, hint, indici, multiserie.log e catalogo, e riporta ogni anomalia. | ADR-0033 | C1 | progettato | INV-F1 | [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md) | test, corr |  |
| REQ-AFF-011 | L'apertura di un Archivio acquisisce un lock esclusivo; una seconda apertura fallisce immediatamente. | ADR-0033 | C1 | progettato |  | [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md) | test |  |
| REQ-AFF-012 | Il sistema raggiunge i minimi vincolanti di prestazione con tutti i controlli di affidabilità attivi. | ADR-0028 | C3 | progettato |  | [0028](../adr/0028-target-e-obiettivi-di-latenza.md), [0031](../adr/0031-software-critico-criteri-e-priorita.md) | bench |  |
| REQ-AFF-013 | Tempo, casualità, schedulazione e I/O passano da interfacce iniettabili; il sistema intero gira in un simulatore deterministico riproducibile da seme. | ADR-0035 | C1 | progettato |  | [0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md) | test, rev |  |
| REQ-AFF-014 | Esiste un backup consistente (segmenti chiusi, control log e hint a un CSN) verificabile dal verificatore offline; un restore rifiuta un backup che non verifica. | ADR-0030 | C1 | progettato | INV-F1 | [0030](../adr/0030-scope-v1.md) | test, corr |  |
| REQ-AFF-015 | Serie e Archivio hanno stati di salute definiti (HEALTHY, DEGRADED, FAULTED, MULTI-DISABLED); ogni transizione è un evento registrato e una metrica. | ADR-0033 | C1 | progettato | INV-A1 | [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md) | test, model |  |
| REQ-AFF-016 | Il sistema non ha dipendenze esterne oltre SBCL e i suoi contrib. | ADR-0027 | C4 | progettato | INV-X3 | [0027](../adr/0027-dipendenze-e-test.md) | analisi |  |
| REQ-AFF-017 | Il recovery non modifica e non tronca alcun segmento esistente: chiude l'ACTIVE trovato alla sua lunghezza valida con un record del manifest e ne apre uno nuovo; il suo punto di atomicità per Serie è la rinomina del control log compattato. | ADR-0036 | C1 | progettato | INV-A9, INV-A7 | [0036](../adr/0036-leggi-di-progetto.md), [0037](../adr/0037-lotto-sigillato.md), [0040](../adr/0040-manifest-a-record-unico.md) | test, model, fi, soak | FI-01, FI-02, FI-10 |
| REQ-AFF-018 | Un file o una directory è eliminato solo se ha suffisso tmp e nessuna fonte di verità lo nomina, oppure se una fonte di verità ne registra la rimozione; un oggetto con nome definitivo sconosciuto non è toccato ed è segnalato; un segment-id nominato dal manifest non è mai riusato. | ADR-0036 | C1 | progettato | INV-A10 | [0036](../adr/0036-leggi-di-progetto.md), [0040](../adr/0040-manifest-a-record-unico.md) | test, fi, corr | FI-09, FI-13 |
| REQ-AFF-019 | Ogni operazione che cambia lo stato durevole ha un solo punto di atomicità (SEAL, EDIT, DECISION, documento di catalogo); ciò che lo precede è scartabile e ciò che lo segue è un completamento idempotente che il recovery ripete. | ADR-0036 | C1 | progettato | INV-A11, INV-A7 | [0036](../adr/0036-leggi-di-progetto.md), [0040](../adr/0040-manifest-a-record-unico.md) | model, fi, rev | FI-06, FI-07, FI-08, FI-13 |
| REQ-LIM-001 | Il documento CBOR non compresso ammette 16 MiB effettivi esclusi header e chiave; v2 usa key-len u16, lunghezza record u32 e slot a 5 parole, senza interpretare v1 come v2. | ADR-0048 | C1 | progettato | INV-F1, INV-A8 | [0048](../adr/0048-limiti-documentali-e-formato-v2.md) | test, fuzz, corr, fi | FI-01 |
| REQ-LIM-002 | Il decoder limita a 100 livelli i contenitori CBOR con radice a livello 1 e applica budget espliciti prima del writer. | ADR-0048 | C2 | progettato | INV-A8 | [0048](../adr/0048-limiti-documentali-e-formato-v2.md) | test, fuzz, rev |  |
| REQ-LIM-003 | Le chiavi binarie ammettono 1..65535 byte; arene, copie e migrazioni hanno budget e non confermano operazioni incomplete; la migrazione preserva sorgenti e atomicità. | ADR-0048 | C1 | progettato | INV-A8, INV-A11 | [0048](../adr/0048-limiti-documentali-e-formato-v2.md) | test, fi, bench, rev | FI-06 |

## Copertura degli invarianti

| Invariante | Requisiti |
|---|---|
| INV-S1 | REQ-STO-001 |
| INV-S2 | REQ-STO-002 |
| INV-S3 | REQ-STO-002, REQ-STO-006 |
| INV-S4 | REQ-STO-003, REQ-STO-006 |
| INV-S5 | REQ-STO-004 |
| INV-S6 | REQ-MET-001, REQ-IDX-006 |
| INV-C1 | REQ-CLN-001, REQ-CMP-009 |
| INV-C2 | REQ-MRG-001 |
| INV-C3 | REQ-CLN-002, REQ-MRG-001 |
| INV-C4 | REQ-STO-005, REQ-CLN-003, REQ-MRG-002 |
| INV-C5 | REQ-MRG-003 |
| INV-C6 | REQ-MRG-003, REQ-MRG-004 |
| INV-C7 | REQ-CMP-002, REQ-REC-004 |
| INV-C8 | REQ-CMP-003 |
| INV-C9 | REQ-CMP-004 |
| INV-C10 | REQ-CMP-005 |
| INV-R1 | REQ-VER-001, REQ-CMP-007 |
| INV-W1 | REQ-ARC-002, REQ-REG-003, REQ-WAL-001 |
| INV-W2 | REQ-REG-001, REQ-WAL-004 |
| INV-D1 | REQ-CMP-008, REQ-WAL-003, REQ-REC-003 |
| INV-T1 | REQ-TXS-001 |
| INV-T2 | REQ-TXS-002, REQ-TXS-003, REQ-MVC-006 |
| INV-T3 | REQ-TXM-003, REQ-TXM-008 |
| INV-T4 | REQ-TXM-004, REQ-TXM-005 |
| INV-T5 | REQ-TXM-001 |
| INV-M1 | REQ-MVC-001, REQ-MVC-005 |
| INV-M2 | REQ-VER-001, REQ-MVC-003, REQ-MVC-007 |
| INV-M3 | REQ-CCH-002, REQ-CCH-004 |
| INV-I1 | REQ-IDX-002, REQ-IDX-003 |
| INV-I2 | REQ-SEC-001 |
| INV-P1 | REQ-TXS-002, REQ-CON-001 |
| INV-P2 | REQ-CON-002 |
| INV-P3 | REQ-ARC-002, REQ-TXM-006, REQ-CON-003, REQ-CON-005 |
| INV-P4 | REQ-MRG-004, REQ-CMP-006 |
| INV-X1 | REQ-SIM-001 |
| INV-X2 | REQ-BEN-001, REQ-BEN-002, REQ-VAL-001 |
| INV-X3 | REQ-SIM-002, REQ-VAL-001, REQ-AFF-016 |
| INV-F1 | REQ-WAL-001, REQ-REC-001, REQ-FOR-001, REQ-FOR-002, REQ-FOR-003, REQ-AFF-009, REQ-AFF-010, REQ-AFF-014, REQ-LIM-001 |
| INV-V1 | REQ-WAL-003, REQ-WAL-006 |
| INV-V2 | REQ-TXM-004, REQ-MVC-002 |
| INV-V3 | REQ-IDX-004 |
| INV-V4 | REQ-CON-002 |
| INV-A1 | REQ-AFF-001, REQ-AFF-009, REQ-AFF-015 |
| INV-A2 | REQ-FOR-004, REQ-AFF-002 |
| INV-A3 | REQ-AFF-003 |
| INV-A4 | REQ-AFF-004 |
| INV-A5 | REQ-AFF-005 |
| INV-A6 | REQ-AFF-006 |
| INV-A7 | REQ-REG-002, REQ-CMP-004, REQ-TXM-005, REQ-REC-002, REQ-AFF-007, REQ-AFF-017, REQ-AFF-019 |
| INV-A8 | REQ-IDX-003, REQ-IDX-005, REQ-IDX-007, REQ-CON-004, REQ-MVC-004, REQ-MVC-008, REQ-AFF-008, REQ-LIM-001, REQ-LIM-002, REQ-LIM-003 |
| INV-F2 | REQ-WAL-005, REQ-FOR-003 |
| INV-F3 | REQ-AFF-009 |
| INV-V5 | REQ-WAL-006, REQ-TXM-008 |
| INV-M4 | REQ-MVC-005, REQ-MVC-008 |
| INV-M5 | REQ-WAL-005, REQ-MVC-006 |
| INV-M6 | REQ-MVC-008 |
| INV-S7 | REQ-CMP-009, REQ-TXM-007, REQ-FOR-004 |
| INV-C11 | REQ-CMP-008, REQ-IDX-006 |
| INV-I3 | REQ-IDX-005, REQ-IDX-007 |
| INV-P6 | REQ-CON-005 |
| INV-P5 | REQ-CON-004 |
| INV-A9 | REQ-AFF-017 |
| INV-A10 | REQ-AFF-018 |
| INV-A11 | REQ-REG-002, REQ-AFF-019, REQ-LIM-003 |
| INV-A12 | REQ-CCH-004 |

## Copertura degli scenari di fault injection

| Scenario | Requisiti |
|---|---|
| FI-01 | REQ-WAL-003, REQ-WAL-005, REQ-WAL-006, REQ-REC-001, REQ-REC-003, REQ-FLT-001, REQ-FOR-001, REQ-AFF-007, REQ-AFF-009, REQ-AFF-017, REQ-LIM-001 |
| FI-02 | REQ-WAL-003, REQ-WAL-005, REQ-WAL-006, REQ-REC-003, REQ-FLT-001, REQ-AFF-001, REQ-AFF-009, REQ-AFF-017 |
| FI-03 | REQ-TXM-002, REQ-TXM-004, REQ-TXM-005, REQ-TXM-007, REQ-FLT-001 |
| FI-04 | REQ-TXM-003, REQ-TXM-004, REQ-TXM-005, REQ-FLT-001 |
| FI-05 | REQ-WAL-003, REQ-TXM-003, REQ-TXM-004, REQ-TXM-005, REQ-TXM-007, REQ-TXM-008, REQ-REC-003, REQ-FLT-001 |
| FI-06 | REQ-CMP-002, REQ-CMP-003, REQ-IDX-002, REQ-IDX-004, REQ-REC-001, REQ-REC-003, REQ-REC-004, REQ-FLT-001, REQ-AFF-007, REQ-AFF-019, REQ-LIM-003 |
| FI-07 | REQ-CLN-002, REQ-CMP-003, REQ-CMP-004, REQ-REC-002, REQ-FLT-001, REQ-AFF-007, REQ-AFF-019 |
| FI-08 | REQ-MRG-001, REQ-CMP-003, REQ-CMP-004, REQ-REC-002, REQ-FLT-001, REQ-AFF-007, REQ-AFF-019 |
| FI-09 | REQ-CMP-007, REQ-REC-003, REQ-FLT-001, REQ-AFF-018 |
| FI-10 | REQ-MET-001, REQ-IDX-006, REQ-REC-002, REQ-REC-003, REQ-FLT-001, REQ-FOR-001, REQ-AFF-007, REQ-AFF-017 |
| FI-11 | REQ-CMP-007, REQ-MVC-001, REQ-MVC-003, REQ-MVC-005, REQ-FLT-001 |
| FI-12 | REQ-TXM-001, REQ-TXM-004, REQ-TXM-007, REQ-TXM-008, REQ-MVC-002, REQ-MVC-005, REQ-FLT-001 |
| FI-13 | REQ-REG-002, REQ-FLT-001, REQ-AFF-018, REQ-AFF-019 |

## Decisioni (ADR) e requisiti che le realizzano

| ADR | Requisiti |
|---|---|
| [0001](../adr/0001-common-lisp-sbcl.md) | REQ-SIM-002 |
| [0002](../adr/0002-serie-unita-di-storage-e-parallelismo.md) | REQ-ARC-001, REQ-ARC-002, REQ-CON-003, REQ-CON-005 |
| [0003](../adr/0003-wal-per-serie.md) | REQ-REG-003, REQ-WAL-001 |
| [0004](../adr/0004-storage-append-only-un-solo-active.md) | REQ-STO-001, REQ-STO-002, REQ-STO-003, REQ-STO-004, REQ-STO-005 |
| [0005](../adr/0005-writer-logico-per-serie.md) | REQ-TXS-001, REQ-TXS-002, REQ-TXS-003, REQ-CON-001, REQ-CON-002 |
| [0006](../adr/0006-transazioni-multiserie-2pc.md) | REQ-REG-001, REQ-TXM-001, REQ-TXM-002 |
| [0007](../adr/0007-clean-e-merge-distinti.md) | REQ-CLN-001, REQ-CLN-002, REQ-CLN-003, REQ-MRG-001 |
| [0008](../adr/0008-merge-opportunistico.md) | REQ-MRG-002, REQ-MRG-003, REQ-MRG-004 |
| [0009](../adr/0009-indici-immutabili-atomic-swap.md) | REQ-IDX-002 |
| [0010](../adr/0010-cache-clock.md) | REQ-CCH-001 |
| [0011](../adr/0011-thread-pool-dinamico.md) | REQ-CMP-006, REQ-THR-001, REQ-OBS-001, REQ-OBS-002 |
| [0012](../adr/0012-simd-guidato-dai-benchmark.md) | REQ-SIM-001 |
| [0013](../adr/0013-log-structured-segmento-active-come-log.md) | REQ-WAL-001, REQ-REC-003, REQ-FOR-001 |
| [0014](../adr/0014-formato-record-documento-id.md) | REQ-ARC-003, REQ-FOR-001, REQ-FOR-002 |
| [0015](../adr/0015-primary-index-swiss-table-swmr.md) | REQ-VER-001, REQ-IDX-001, REQ-IDX-003, REQ-IDX-004 |
| [0016](../adr/0016-epoch-based-reclamation.md) | REQ-CMP-005, REQ-CMP-007 |
| [0017](../adr/0017-piattaforma-e-io.md) | REQ-THR-001 |
| [0018](../adr/0018-control-log-manifest-swap.md) | REQ-STO-006, REQ-MET-001, REQ-CLN-002, REQ-CMP-002, REQ-CMP-003, REQ-CMP-004, REQ-REC-001, REQ-REC-002, REQ-REC-004 |
| [0019](../adr/0019-durability-e-group-commit-pipelined.md) | REQ-WAL-002, REQ-WAL-003, REQ-REC-003 |
| [0020](../adr/0020-csn-snapshot-isolamento.md) | REQ-VER-001, REQ-TXM-004, REQ-MVC-001, REQ-MVC-002, REQ-MVC-003, REQ-MVC-004 |
| [0021](../adr/0021-2pc-intenti-outcome.md) | REQ-WAL-004, REQ-TXM-002, REQ-TXM-003, REQ-TXM-004, REQ-TXM-005, REQ-TXM-006, REQ-REC-002 |
| [0022](../adr/0022-registri-come-serie-catalogo.md) | REQ-ARC-004, REQ-REG-001, REQ-REG-002 |
| [0023](../adr/0023-politiche-di-compaction.md) | REQ-STO-005, REQ-MRG-003, REQ-MRG-004, REQ-CMP-001, REQ-CMP-006 |
| [0024](../adr/0024-memoria-e-gc.md) | REQ-IDX-001, REQ-SIM-001 |
| [0025](../adr/0025-cache-per-location.md) | REQ-CCH-001, REQ-CCH-002, REQ-CCH-003 |
| [0026](../adr/0026-indici-secondari-segmentati.md) | REQ-SEC-001, REQ-SEC-002 |
| [0027](../adr/0027-dipendenze-e-test.md) | REQ-SIM-002, REQ-AFF-016 |
| [0028](../adr/0028-target-e-obiettivi-di-latenza.md) | REQ-BEN-001, REQ-BEN-002, REQ-AFF-012 |
| [0029](../adr/0029-interfacce-protocollo-query-contratto.md) | —  (decisione senza requisito diretto) |
| [0030](../adr/0030-scope-v1.md) | REQ-AFF-014 |
| [0031](../adr/0031-software-critico-criteri-e-priorita.md) | REQ-MOD-001, REQ-AFF-012 |
| [0032](../adr/0032-seqlock-a-64-bit.md) | REQ-IDX-003 |
| [0033](../adr/0033-fail-stop-e-integrita-end-to-end.md) | REQ-REC-001, REQ-AFF-001, REQ-AFF-002, REQ-AFF-004, REQ-AFF-006, REQ-AFF-007, REQ-AFF-008, REQ-AFF-009, REQ-AFF-010, REQ-AFF-011, REQ-AFF-015 |
| [0034](../adr/0034-policy-di-compilazione-e-standard-di-codifica.md) | REQ-AFF-003, REQ-AFF-004, REQ-AFF-008 |
| [0035](../adr/0035-strategia-di-verifica-e-tracciabilita.md) | REQ-FLT-001, REQ-VAL-001, REQ-AFF-005, REQ-AFF-013 |
| [0036](../adr/0036-leggi-di-progetto.md) | REQ-CON-005, REQ-AFF-007, REQ-AFF-017, REQ-AFF-018, REQ-AFF-019 |
| [0037](../adr/0037-lotto-sigillato.md) | REQ-WAL-002, REQ-WAL-003, REQ-WAL-005, REQ-WAL-006, REQ-REC-001, REQ-REC-003, REQ-AFF-009, REQ-AFF-017 |
| [0038](../adr/0038-orizzonte-di-visibilita.md) | REQ-VER-001, REQ-TXM-004, REQ-MVC-002, REQ-MVC-005, REQ-MVC-006, REQ-MVC-007 |
| [0039](../adr/0039-cornice-unica-dei-record.md) | REQ-WAL-005, REQ-IDX-006, REQ-SEC-001, REQ-FOR-001, REQ-FOR-003, REQ-FOR-004, REQ-AFF-002 |
| [0040](../adr/0040-manifest-a-record-unico.md) | REQ-REG-002, REQ-STO-006, REQ-MET-001, REQ-CLN-002, REQ-CMP-002, REQ-CMP-003, REQ-CMP-004, REQ-TXM-007, REQ-REC-002, REQ-REC-004, REQ-AFF-017, REQ-AFF-018, REQ-AFF-019 |
| [0041](../adr/0041-multiserie-segmenti-autosufficienti.md) | REQ-CMP-009, REQ-WAL-004, REQ-TXM-001, REQ-TXM-002, REQ-TXM-003, REQ-TXM-004, REQ-TXM-005, REQ-TXM-007, REQ-TXM-008, REQ-REC-002 |
| [0042](../adr/0042-tombstone-e-indice-dei-vivi.md) | REQ-CMP-008, REQ-CMP-009, REQ-IDX-006 |
| [0043](../adr/0043-primary-index-a-frammenti.md) | REQ-IDX-001, REQ-IDX-003, REQ-IDX-005, REQ-IDX-007 |
| [0044](../adr/0044-cache-acceleratore-puro.md) | REQ-CCH-002, REQ-CCH-004 |
| [0045](../adr/0045-modello-di-esecuzione.md) | REQ-CON-005, REQ-CON-004 |
| [0046](../adr/0046-orizzonte-con-registro-limitato.md) | REQ-MVC-008 |
| [0047](../adr/0047-verifica-csn-dei-record-prepared.md) | REQ-FOR-004 |
| [0048](../adr/0048-limiti-documentali-e-formato-v2.md) | REQ-LIM-001, REQ-LIM-002, REQ-LIM-003 |
| [0049](../adr/0049-capacita-oltre-la-ram.md) | —  (decisione senza requisito diretto) |
| [0050](../adr/0050-pubblicazione-e-costi-della-directory.md) | REQ-IDX-007 |
| [0051](../adr/0051-presentazione-della-documentazione.md) | —  (decisione senza requisito diretto) |
