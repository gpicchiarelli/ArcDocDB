;;;; requisiti.lisp — requisiti tracciati di ArcDocDB (dati, non codice).
;;;;
;;;; Ogni requisito è una lista di proprietà:
;;;;   :id    REQ-<AREA>-<nnn>, stabile (non si rinumera; si ritira)
;;;;   :src   sezione della specifica, o ADR/processo da cui deriva
;;;;   :txt   enunciato verificabile (niente virgolette doppie nel testo)
;;;;   :cls   classe di integrità (ADR-0031): "C1" "C2" "C3" "C4"
;;;;   :inv   invarianti (INV-...) che il requisito realizza
;;;;   :adr   decisioni (ADR-nnnn) che lo realizzano
;;;;   :ver   metodi di verifica: :test :prop :diff :model :fi :fuzz :corr :mut
;;;;          :soak :bench :rev :analisi   (almeno uno)
;;;;   :fi    scenari di fault injection (FI-nn) che lo verificano
;;;;   :stato :specificato | :progettato | :implementato | :verificato
;;;;
;;;; La matrice docs/tracciabilita/matrice.md è GENERATA da questo file con
;;;; `make trace-write` e controllata da `make trace`.

(
 ;; ---- Architettura logica e Registri --------------------------------------
 (:id "REQ-ARC-001" :src "Architettura logica" :cls "C2" :stato :progettato
  :txt "La gerarchia logica è Server, Archivio, Serie, Documento."
  :inv () :adr ("ADR-0002") :ver (:rev :test) :fi ())
 (:id "REQ-ARC-002" :src "Architettura logica" :cls "C1" :stato :progettato
  :txt "La Serie è l'unità primaria di storage e di parallelismo; possiede log, segmenti e indici propri e opera in modo indipendente dalle altre Serie."
  :inv ("INV-W1" "INV-P3") :adr ("ADR-0002") :ver (:test :bench) :fi ())
 (:id "REQ-ARC-003" :src "Architettura logica" :cls "C1" :stato :progettato
  :txt "Un Documento ha un _id univoco nella Serie e può avere versioni storiche gestite da storage append-only e MVCC."
  :inv () :adr ("ADR-0014") :ver (:test :diff) :fi ())
 (:id "REQ-ARC-004" :src "Architettura logica" :cls "C1" :stato :progettato
  :txt "L'Archivio è il livello delle transazioni e degli snapshot multiserie e contiene obbligatoriamente la Serie Registri."
  :inv () :adr ("ADR-0022") :ver (:test) :fi ())
 (:id "REQ-REG-001" :src "Serie speciale Registri" :cls "C1" :stato :progettato
  :txt "Registri non è il WAL dei dati: contiene il catalogo e un unico file multiserie.log; non esiste un file per transazione."
  :inv ("INV-W2") :adr ("ADR-0006" "ADR-0022") :ver (:rev :test) :fi ())
 (:id "REQ-REG-002" :src "Catalogo" :cls "C1" :stato :progettato
  :txt "Il catalogo memorizza per ogni Serie nome, configurazione, schema, indici, configurazione dei segmenti, stato e metadata di recovery, ed è modificabile in modo transazionale e crash-safe: il documento della Serie è il punto di atomicità di creazione ed eliminazione, la directory segue."
  :inv ("INV-A7" "INV-A11") :adr ("ADR-0022" "ADR-0040") :ver (:test :fi) :fi ("FI-13"))
 (:id "REQ-REG-003" :src "Layout fisico" :cls "C1" :stato :progettato
  :txt "Ogni Serie è fisicamente indipendente nel proprio direttorio; non esiste un global data WAL."
  :inv ("INV-W1") :adr ("ADR-0003") :ver (:rev :analisi) :fi ())

 ;; ---- Storage, segmenti, versioni -----------------------------------------
 (:id "REQ-STO-001" :src "Storage append-only" :cls "C1" :stato :progettato
  :txt "I record già scritti nei segmenti non sono mai modificati in-place."
  :inv ("INV-S1") :adr ("ADR-0004") :ver (:test :rev) :fi ())
 (:id "REQ-STO-002" :src "Storage append-only" :cls "C1" :stato :progettato
  :txt "Esiste esattamente un segmento ACTIVE per Serie ed è l'unico scrivibile."
  :inv ("INV-S2" "INV-S3") :adr ("ADR-0004") :ver (:test :model) :fi ())
 (:id "REQ-STO-003" :src "Storage append-only" :cls "C1" :stato :progettato
  :txt "Un segmento che smette di essere ACTIVE è immutabile e non è più riaperto in scrittura."
  :inv ("INV-S4") :adr ("ADR-0004") :ver (:test) :fi ())
 (:id "REQ-STO-004" :src "Segmenti" :cls "C1" :stato :progettato
  :txt "Le nuove scritture vanno sempre in un nuovo segmento ACTIVE, mai in un segmento prodotto dalla compaction."
  :inv ("INV-S5") :adr ("ADR-0004") :ver (:test) :fi ())
 (:id "REQ-STO-005" :src "Segmenti" :cls "C1" :stato :progettato
  :txt "I segmenti creati dal writer hanno dimensione target circa 256 MB configurabile per Serie; i segmenti prodotti dalla compaction non hanno requisito di dimensione."
  :inv ("INV-C4") :adr ("ADR-0004" "ADR-0023") :ver (:test) :fi ())
 (:id "REQ-STO-006" :src "Segmenti" :cls "C1" :stato :progettato
  :txt "Gli stati del segmento sono ACTIVE, CLOSED, OBSOLETE, RECLAIMABLE, DELETED con transizioni a senso unico; solo ACTIVE è scrivibile; di durevole c'è solo l'appartenenza all'insieme registrato nel manifest."
  :inv ("INV-S3" "INV-S4") :adr ("ADR-0018" "ADR-0040") :ver (:test :model) :fi ())
 (:id "REQ-MET-001" :src "Segment metadata" :cls "C1" :stato :progettato
  :txt "I segment metadata (identificativo, conteggi, byte, stato, tempi, epoch) sono dati derivati e possono essere ricostruiti, verificati e corretti da log, dati e indice."
  :inv ("INV-S6") :adr ("ADR-0018" "ADR-0040") :ver (:test :fi) :fi ("FI-10"))
 (:id "REQ-VER-001" :src "Versioni dei record" :cls "C1" :stato :progettato
  :txt "Ogni versione è LIVE, SNAPSHOT-LIVE o DEAD; una versione DEAD è reclamabile solo senza riferimenti da indice, snapshot e transazioni."
  :inv ("INV-R1" "INV-M2") :adr ("ADR-0015" "ADR-0020" "ADR-0038") :ver (:test :model) :fi ())

 ;; ---- CLEAN, MERGE, compaction --------------------------------------------
 (:id "REQ-CLN-001" :src "Clean" :cls "C1" :stato :progettato
  :txt "CLEAN trasforma un segmento sorgente in un nuovo segmento immutabile contenente solo i record live o necessari."
  :inv ("INV-C1") :adr ("ADR-0007") :ver (:test :diff) :fi ())
 (:id "REQ-CLN-002" :src "Clean" :cls "C1" :stato :progettato
  :txt "CLEAN è copy-on-write: il segmento sorgente non è mai modificato, diventa OBSOLETE dopo lo swap e resta leggibile finché necessario."
  :inv ("INV-C3") :adr ("ADR-0007" "ADR-0018" "ADR-0040") :ver (:test :fi) :fi ("FI-07"))
 (:id "REQ-CLN-003" :src "Segmenti" :cls "C1" :stato :progettato
  :txt "Il segmento prodotto da CLEAN può essere molto più piccolo del target e può restare piccolo indefinitamente."
  :inv ("INV-C4") :adr ("ADR-0007") :ver (:test) :fi ())
 (:id "REQ-MRG-001" :src "Merge" :cls "C1" :stato :progettato
  :txt "MERGE trasforma N segmenti piccoli in un nuovo segmento immutabile e lascia immutabili i sorgenti."
  :inv ("INV-C2" "INV-C3") :adr ("ADR-0007") :ver (:test :fi) :fi ("FI-08"))
 (:id "REQ-MRG-002" :src "Merge" :cls "C3" :stato :progettato
  :txt "Non si esegue automaticamente un MERGE dopo ogni CLEAN."
  :inv ("INV-C4") :adr ("ADR-0008") :ver (:test) :fi ())
 (:id "REQ-MRG-003" :src "Condizioni obbligatorie per Merge" :cls "C3" :stato :progettato
  :txt "Un segmento è candidato a MERGE solo se CLOSED, immutabile, non ACTIVE, fermo da almeno 50 secondi dal timestamp di chiusura o stabilizzazione, non necessario a uno snapshot attivo, in un gruppo che supera le soglie, e con il motore a basso carico."
  :inv ("INV-C5" "INV-C6") :adr ("ADR-0008" "ADR-0023") :ver (:test :bench) :fi ())
 (:id "REQ-MRG-004" :src "Low-load merge policy" :cls "C3" :stato :progettato
  :txt "Prima di un MERGE si valuta il carico; con carico alto non si avviano MERGE, se ne riduce la concorrenza e si dà priorità a richieste e log; se il carico aumenta durante un MERGE si sospende o rallenta il lavoro non critico."
  :inv ("INV-C6" "INV-P4") :adr ("ADR-0008" "ADR-0023") :ver (:test :bench) :fi ())
 (:id "REQ-CMP-001" :src "Politica generale di compaction" :cls "C3" :stato :progettato
  :txt "Con live uguale a zero e nessun riferimento il segmento è eliminato; con live parziale si esegue CLEAN; con live circa uguale al totale non si compatta."
  :inv () :adr ("ADR-0023") :ver (:test) :fi ())
 (:id "REQ-CMP-002" :src "Workflow Clean/Merge" :cls "C1" :stato :progettato
  :txt "Il workflow di compaction segue i tredici passi della specifica; il nuovo segmento non è visibile come definitivo prima che i suoi dati siano durevoli."
  :inv ("INV-C7") :adr ("ADR-0018" "ADR-0040") :ver (:test :model :fi) :fi ("FI-06"))
 (:id "REQ-CMP-003" :src "Fault injection" :cls "C1" :stato :progettato
  :txt "Un segmento sorgente resta recuperabile fino al completamento dello swap."
  :inv ("INV-C8") :adr ("ADR-0018" "ADR-0040") :ver (:model :fi) :fi ("FI-06" "FI-07" "FI-08"))
 (:id "REQ-CMP-004" :src "Fault injection" :cls "C1" :stato :progettato
  :txt "Una compaction interrotta è ripetibile o completabile durante il recovery."
  :inv ("INV-C9" "INV-A7") :adr ("ADR-0018" "ADR-0040") :ver (:model :fi) :fi ("FI-07" "FI-08"))
 (:id "REQ-CMP-005" :src "Readers durante compaction" :cls "C1" :stato :progettato
  :txt "I reader continuano a leggere i segmenti vecchi durante la compaction; la compaction non blocca globalmente le letture; dopo lo swap i nuovi reader usano il nuovo segmento."
  :inv ("INV-C10") :adr ("ADR-0016") :ver (:test :model :bench) :fi ())
 (:id "REQ-CMP-006" :src "Compaction parallela" :cls "C3" :stato :progettato
  :txt "La compaction è parallelizzabile per segmento e per Serie, con limiti indipendenti dal request scheduler e priorità utente, log, CLEAN necessario, MERGE."
  :inv ("INV-P4") :adr ("ADR-0011" "ADR-0023") :ver (:test :bench) :fi ())
 (:id "REQ-CMP-007" :src "Index/Snapshot/Reclaim" :cls "C1" :stato :progettato
  :txt "Un segmento è eliminato solo quando nessun indice, snapshot, transazione attiva o reader lo referenzia o lo utilizza."
  :inv ("INV-R1") :adr ("ADR-0016") :ver (:model :fi) :fi ("FI-09" "FI-11"))
 (:id "REQ-CMP-008" :src "ADR-0042" :cls "C1" :stato :progettato
  :txt "Un tombstone è scartato dalla compaction solo se è superato da una versione durevole più recente, oppure se nessuna versione della chiave è trattenuta e nessun altro segmento può contenere un record più vecchio della stessa chiave (filtro di esistenza e CSN minimo del segmento)."
  :inv ("INV-D1" "INV-C11") :adr ("ADR-0042") :ver (:test :prop :model) :fi ())
 (:id "REQ-CMP-009" :src "ADR-0042" :cls "C1" :stato :progettato
  :txt "La compaction copia solo i record necessari (puntati dall'indice, puntati dalle versioni trattenute, tombstone non scartabili), riscrive i record prepared committed come record ordinari con il loro CSN e non copia mai SEAL né OUTCOME."
  :inv ("INV-C1" "INV-S7") :adr ("ADR-0041" "ADR-0042") :ver (:test :diff :model) :fi ())

 ;; ---- Log, durability -------------------------------------------------------
 (:id "REQ-WAL-001" :src "WAL" :cls "C1" :stato :progettato
  :txt "Ogni Serie ha un log dei dati indipendente (segmento ACTIVE) e un control log strutturale; non esiste un global data WAL."
  :inv ("INV-W1" "INV-F1") :adr ("ADR-0003" "ADR-0013") :ver (:test :rev) :fi ())
 (:id "REQ-WAL-002" :src "WAL" :cls "C1" :stato :progettato
  :txt "Il sistema usa il group commit; non esegue un flush per ogni operazione salvo richiesta di durability forte; per ogni log c'è un solo compito di I/O alla volta, che scrive i lotti chiusi ed esegue il flush."
  :inv () :adr ("ADR-0019" "ADR-0037") :ver (:test :bench) :fi ())
 (:id "REQ-WAL-003" :src "WAL" :cls "C1" :stato :progettato
  :txt "I livelli di durability sono async, group e strong e cambiano solo il momento di pubblicazione e conferma; per group e strong un dato confermato non è perso e non è visibile prima di essere durevole."
  :inv ("INV-D1" "INV-V1") :adr ("ADR-0019" "ADR-0037") :ver (:test :fi) :fi ("FI-01" "FI-02" "FI-05"))
 (:id "REQ-WAL-004" :src "WAL" :cls "C1" :stato :progettato
  :txt "multiserie.log usa il group commit."
  :inv ("INV-W2") :adr ("ADR-0021" "ADR-0041") :ver (:test :bench) :fi ())
 (:id "REQ-WAL-005" :src "ADR-0037" :cls "C1" :stato :progettato
  :txt "Ogni log è una sequenza di lotti sigillati: un lotto è valido per intero (SEAL che ne fissa file, posizione, numero di record, contenuto) o non esiste; un record non prepared è committed se e solo se sta in un lotto valido; il CSN del lotto è preso alla chiusura."
  :inv ("INV-F2" "INV-M5") :adr ("ADR-0037" "ADR-0039") :ver (:test :fuzz :corr :fi :model) :fi ("FI-01" "FI-02"))
 (:id "REQ-WAL-006" :src "ADR-0037" :cls "C1" :stato :progettato
  :txt "Una scrittura è confermata al client solo dopo la pubblicazione nell'indice e, per group e strong, solo dopo il flush che copre il suo lotto; la pubblicazione avviene in ordine di lotto."
  :inv ("INV-V5" "INV-V1") :adr ("ADR-0037") :ver (:test :diff :fi) :fi ("FI-01" "FI-02"))

 ;; ---- Transazioni -----------------------------------------------------------
 (:id "REQ-TXS-001" :src "Transazioni single-series" :cls "C1" :stato :progettato
  :txt "Una transazione su una sola Serie usa solo il log della Serie e non scrive su multiserie.log."
  :inv ("INV-T1") :adr ("ADR-0005") :ver (:test) :fi ())
 (:id "REQ-TXS-002" :src "Transazioni single-series" :cls "C1" :stato :progettato
  :txt "Una transazione single-Series è serializzata dal writer logico e rileva i conflitti con optimistic version checking; il controllo della versione è atomico rispetto all'applicazione."
  :inv ("INV-T2" "INV-P1") :adr ("ADR-0005") :ver (:test :diff :model) :fi ())
 (:id "REQ-TXS-003" :src "Transazioni single-series" :cls "C1" :stato :progettato
  :txt "Con due transazioni che leggono la stessa versione, la seconda a committare fallisce con conflitto e può ritentare."
  :inv ("INV-T2") :adr ("ADR-0005") :ver (:test :diff) :fi ())
 (:id "REQ-TXM-001" :src "Transazioni multiserie" :cls "C1" :stato :progettato
  :txt "Tutte le modifiche di una transazione multiserie condividono un unico TXID."
  :inv ("INV-T5") :adr ("ADR-0006" "ADR-0041") :ver (:test :fi) :fi ("FI-12"))
 (:id "REQ-TXM-002" :src "Transazioni multiserie" :cls "C1" :stato :progettato
  :txt "La transazione multiserie segue un protocollo 2PC: BEGIN, PREPARE sui partecipanti, flush, decisione durevole, COMMIT o ABORT, applicazione."
  :inv () :adr ("ADR-0006" "ADR-0021" "ADR-0041") :ver (:test :model :fi) :fi ("FI-03"))
 (:id "REQ-TXM-003" :src "Transazioni multiserie" :cls "C1" :stato :progettato
  :txt "La decisione COMMIT è durevole in multiserie.log prima che la transazione sia considerata committed."
  :inv ("INV-T3") :adr ("ADR-0021" "ADR-0041") :ver (:model :fi) :fi ("FI-04" "FI-05"))
 (:id "REQ-TXM-004" :src "Fault injection" :cls "C1" :stato :progettato
  :txt "Nessuna transazione multiserie risulta parzialmente committed, nemmeno dopo un crash, e uno snapshot la vede per intero o per niente."
  :inv ("INV-T4" "INV-V2") :adr ("ADR-0020" "ADR-0021" "ADR-0038" "ADR-0041") :ver (:model :fi) :fi ("FI-03" "FI-04" "FI-05" "FI-12"))
 (:id "REQ-TXM-005" :src "Transazioni multiserie" :cls "C1" :stato :progettato
  :txt "Dopo un crash il Recovery Manager legge multiserie.log, identifica le transazioni preparate o incomplete, determina la decisione (presumed abort: senza DECISION la transazione è abortita) e rende durevole l'esito COMMIT di ogni partecipante nel record che ne chiude il segmento."
  :inv ("INV-T4" "INV-A7") :adr ("ADR-0021" "ADR-0041") :ver (:model :fi) :fi ("FI-03" "FI-04" "FI-05"))
 (:id "REQ-TXM-006" :src "ADR-0021" :cls "C1" :stato :progettato
  :txt "Il writer di una Serie non si ferma ad attendere la decisione di una multiserie; i documenti con intento pendente rispondono conflict senza attesa."
  :inv ("INV-P3") :adr ("ADR-0021") :ver (:test :model :bench) :fi ())
 (:id "REQ-TXM-007" :src "ADR-0041" :cls "C1" :stato :progettato
  :txt "Un segmento CLOSED è autosufficiente: la rotazione attende che la Serie non abbia intenti pendenti; un record prepared è committed se e solo se il suo OUTCOME è nello stesso segmento o il suo esito è nel record del manifest che ha chiuso il segmento."
  :inv ("INV-S7") :adr ("ADR-0041" "ADR-0040") :ver (:test :model :fi) :fi ("FI-03" "FI-05" "FI-12"))
 (:id "REQ-TXM-008" :src "ADR-0041" :cls "C1" :stato :progettato
  :txt "Una transazione multiserie è confermata al client dopo che la decisione è durevole e l'esito è stato applicato in memoria su tutti i partecipanti sani; un abort non scrive alcun record."
  :inv ("INV-V5" "INV-T3") :adr ("ADR-0041") :ver (:test :model :fi) :fi ("FI-05" "FI-12"))

 ;; ---- Indici ----------------------------------------------------------------
 (:id "REQ-IDX-001" :src "Index" :cls "C1" :stato :progettato
  :txt "Il primary index mappa _id a location (segment-id, offset, length, version; la versione è il CSN) con lookup O(1) medio, in strutture compatte senza un oggetto Lisp per entry."
  :inv () :adr ("ADR-0015" "ADR-0024" "ADR-0043") :ver (:test :bench) :fi ())
 (:id "REQ-IDX-002" :src "Index snapshot" :cls "C1" :stato :progettato
  :txt "Gli indici sono immutabili per i reader; le nuove versioni diventano visibili con atomic swap e i reader precedenti completano sulla versione vecchia."
  :inv ("INV-I1") :adr ("ADR-0009") :ver (:test :model :fi) :fi ("FI-06"))
 (:id "REQ-IDX-003" :src "ADR-0032" :cls "C1" :stato :progettato
  :txt "La lettura di una entry del primary index non osserva mai uno stato intermedio, con tentativi limitati e ripiego sul writer."
  :inv ("INV-I1" "INV-A8") :adr ("ADR-0015" "ADR-0032" "ADR-0043") :ver (:test :model :soak) :fi ())
 (:id "REQ-IDX-004" :src "ADR-0015" :cls "C1" :stato :progettato
  :txt "La rilocazione da compaction aggiorna una entry solo se punta ancora alla location sorgente e non sovrascrive mai una versione più nuova."
  :inv ("INV-V3") :adr ("ADR-0015") :ver (:test :model :fi) :fi ("FI-06"))
 (:id "REQ-IDX-005" :src "ADR-0043" :cls "C1" :stato :progettato
  :txt "Il primary index è una directory di frammenti a capacità fissa: nessuna manutenzione copia più di un frammento, lo spazio di slot e chiavi eliminati è recuperato alla divisione, e la stessa tabella realizza indice, versioni trattenute e versioni in sospeso."
  :inv ("INV-I3" "INV-A8") :adr ("ADR-0043") :ver (:test :model :bench) :fi ())
 (:id "REQ-IDX-006" :src "ADR-0042" :cls "C1" :stato :progettato
  :txt "Il primary index contiene solo documenti vivi; la sua ricostruzione sceglie per ogni chiave il record committed con il CSN massimo e dà lo stesso risultato per qualsiasi ordine di lettura dei segmenti."
  :inv ("INV-C11" "INV-S6") :adr ("ADR-0042" "ADR-0039") :ver (:test :prop :fi) :fi ("FI-10"))
 (:id "REQ-SEC-001" :src "Secondary index" :cls "C2" :stato :progettato
  :txt "Gli indici secondari usano strutture per tipo di query (stringhe e prefix, intervalli, categorie, bitmap); il Bloom filter sui valori, sezione del file indice, dice solo assente o forse presente."
  :inv ("INV-I2") :adr ("ADR-0026" "ADR-0039") :ver (:test :diff) :fi ())
 (:id "REQ-SEC-002" :src "Secondary index delta" :cls "C2" :stato :progettato
  :txt "Gli indici secondari seguono il modello base più delta immutabili e la nuova base è costruita senza bloccare i reader."
  :inv () :adr ("ADR-0026") :ver (:test :diff) :fi ())

 ;; ---- Cache -------------------------------------------------------------------
 (:id "REQ-CCH-001" :src "Cache" :cls "C3" :stato :progettato
  :txt "La cache usa CLOCK, può essere partizionata per Serie e misura la scan pollution per decidere un'eventuale evoluzione a 2Q."
  :inv () :adr ("ADR-0010" "ADR-0025") :ver (:test :bench) :fi ())
 (:id "REQ-CCH-002" :src "Cache e snapshot" :cls "C1" :stato :progettato
  :txt "La cache è consapevole della versione: un reader non ottiene mai una versione incompatibile con il proprio snapshot."
  :inv ("INV-M3") :adr ("ADR-0025" "ADR-0044") :ver (:test :prop) :fi ())
 (:id "REQ-CCH-003" :src "Cache" :cls "C2" :stato :progettato
  :txt "Il percorso di lettura è richiesta, Serie, snapshot e indice, cache, segmento."
  :inv () :adr ("ADR-0025") :ver (:test) :fi ())
 (:id "REQ-CCH-004" :src "ADR-0044" :cls "C1" :stato :progettato
  :txt "La cache è un acceleratore puro: nessuna invalidazione, ri-etichettatura o svuotamento; il sistema dà le stesse risposte con la cache disattivata; una verifica fallita su un dato in cache lo scarta e rilegge dal segmento senza quarantena."
  :inv ("INV-A12" "INV-M3") :adr ("ADR-0044") :ver (:test :diff :corr) :fi ())

 ;; ---- Concorrenza -----------------------------------------------------------
 (:id "REQ-CON-001" :src "Concorrenza" :cls "C1" :stato :progettato
  :txt "Esiste un solo writer logico per Serie e molti reader concorrenti."
  :inv ("INV-P1") :adr ("ADR-0005") :ver (:test :model) :fi ())
 (:id "REQ-CON-002" :src "Concorrenza" :cls "C1" :stato :progettato
  :txt "Non esistono un global writer lock, un thread permanente per Serie o un thread per richiesta; ogni modifica allo stato di una Serie passa dal suo writer."
  :inv ("INV-P2" "INV-V4") :adr ("ADR-0005") :ver (:rev :analisi :test) :fi ())
 (:id "REQ-CON-003" :src "Parallelismo" :cls "C3" :stato :progettato
  :txt "Serie indipendenti scrivono in parallelo; un burst su una Serie non impedisce scritture, query o compaction sulle altre."
  :inv ("INV-P3") :adr ("ADR-0002") :ver (:bench :test) :fi ())
 (:id "REQ-THR-001" :src "Thread pool dinamico" :cls "C3" :stato :progettato
  :txt "Un pool dinamico di worker riutilizzati adatta il numero di worker con EWMA, AIMD e isteresi, senza creare e distruggere thread continuamente."
  :inv () :adr ("ADR-0011" "ADR-0017") :ver (:test :bench) :fi ())
 (:id "REQ-CON-005" :src "Parallelismo" :cls "C1" :stato :progettato
  :txt "Il parallelismo è un principio fondante: tra Serie non esiste alcun lock né alcuna scrittura condivisa per singola operazione; ciò che le Serie condividono è un elenco chiuso con costo limitato, pagato al più per lotto, per transazione multiserie o per snapshot; ogni meccanismo dichiara che cosa rende seriale; letture, compaction, recovery, ricostruzione dell'indice e query procedono in parallelo sulle rispettive unità."
  :inv ("INV-P6" "INV-P3") :adr ("ADR-0036" "ADR-0002" "ADR-0045") :ver (:rev :analisi :bench :test) :fi ())
 (:id "REQ-CON-004" :src "ADR-0045" :cls "C1" :stato :progettato
  :txt "Ogni unità di lavoro è un compito che gira fino al completamento; un worker di calcolo non esegue chiamate bloccanti; ogni attesa è un parcheggio in una lista con lunghezza e tempo massimi; una lettura che manca la cache migra al pool di I/O ripartendo dall'inizio."
  :inv ("INV-P5" "INV-A8") :adr ("ADR-0045") :ver (:test :rev :bench) :fi ())

 ;; ---- MVCC e snapshot -------------------------------------------------------
 (:id "REQ-MVC-001" :src "Snapshot / MVCC" :cls "C1" :stato :progettato
  :txt "Uno snapshot è una vista logica consistente; un GET semplice legge la versione corrente committed."
  :inv ("INV-M1") :adr ("ADR-0020") :ver (:test :prop :diff) :fi ("FI-11"))
 (:id "REQ-MVC-002" :src "Snapshot / MVCC" :cls "C1" :stato :progettato
  :txt "Una transazione locale può usare uno snapshot della Serie; una multiserie uno snapshot coerente a livello di Archivio."
  :inv ("INV-V2") :adr ("ADR-0020" "ADR-0038") :ver (:test :model) :fi ("FI-12"))
 (:id "REQ-MVC-003" :src "Snapshot / MVCC" :cls "C1" :stato :progettato
  :txt "Uno snapshot impedisce alla compaction di eliminare le versioni che gli servono."
  :inv ("INV-M2") :adr ("ADR-0020") :ver (:test :fi) :fi ("FI-11"))
 (:id "REQ-MVC-004" :src "ADR-0020" :cls "C1" :stato :progettato
  :txt "Uno snapshot oltre la durata massima è terminato e le operazioni che lo usano ricevono snapshot-too-old."
  :inv ("INV-A8") :adr ("ADR-0020") :ver (:test) :fi ())
 (:id "REQ-MVC-005" :src "ADR-0038" :cls "C1" :stato :progettato
  :txt "Uno snapshot con CSN s esegue la prima lettura solo quando l'orizzonte di visibilità è almeno s; due letture dello stesso documento nello stesso snapshot danno lo stesso risultato; uno snapshot creato dopo la conferma di un commit lo vede."
  :inv ("INV-M4" "INV-M1") :adr ("ADR-0038") :ver (:test :prop :model :fi) :fi ("FI-11" "FI-12"))
 (:id "REQ-MVC-006" :src "ADR-0038" :cls "C1" :stato :progettato
  :txt "La versione di un documento è il CSN del commit che l'ha prodotta: expected-version è un CSN, non si ripete e non riparte dopo un'eliminazione; per ogni documento l'ordine dei CSN è l'ordine delle versioni."
  :inv ("INV-M5" "INV-T2") :adr ("ADR-0038") :ver (:test :diff :model) :fi ())
 (:id "REQ-MVC-007" :src "ADR-0038" :cls "C1" :stato :progettato
  :txt "Il writer trattiene la versione sostituita quando la soglia del registro degli snapshot è inferiore al CSN nuovo; la registrazione di uno snapshot pubblica la soglia prima di leggere il proprio CSN, con barriera di memoria completa."
  :inv ("INV-M2") :adr ("ADR-0038") :ver (:test :model :soak) :fi ())
 (:id "REQ-MVC-008" :src "ADR-0046" :cls "C1" :stato :progettato
  :txt "Il registro dei CSN in volo ha capacità fissa; assegnazione del CSN e registrazione sono indivisibili rispetto all'avanzamento dell'orizzonte; uno slot non viene riusato finché il suo CSN non è pubblicato o annullato; quando non ci sono pendenti H raggiunge l'ultimo CSN, anche se un commit lento è stato superato da molti commit conclusi."
  :inv ("INV-M4" "INV-M6" "INV-A8") :adr ("ADR-0046") :ver (:test :model :bench) :fi ())

 ;; ---- Recovery --------------------------------------------------------------
 (:id "REQ-REC-001" :src "Recovery" :cls "C1" :stato :progettato
  :txt "Il Recovery Manager verifica log, segment metadata, index metadata, atomic swap, stato dei segmenti, stato delle transazioni e multiserie.log."
  :inv ("INV-F1") :adr ("ADR-0018" "ADR-0033" "ADR-0037") :ver (:test :fi) :fi ("FI-01" "FI-06"))
 (:id "REQ-REC-002" :src "Recovery" :cls "C1" :stato :progettato
  :txt "Dopo un crash il sistema recupera i log delle Serie, ricostruisce o verifica gli indici, identifica i segmenti, completa o annulla le compaction incomplete, processa multiserie.log e completa le multiserie preparate."
  :inv ("INV-A7") :adr ("ADR-0018" "ADR-0021" "ADR-0040" "ADR-0041") :ver (:test :fi :soak) :fi ("FI-07" "FI-08" "FI-10"))
 (:id "REQ-REC-003" :src "Fault injection" :cls "C1" :stato :progettato
  :txt "Nessun dato committed è perso."
  :inv ("INV-D1") :adr ("ADR-0013" "ADR-0019" "ADR-0037") :ver (:fi :diff :soak) :fi ("FI-01" "FI-02" "FI-05" "FI-06" "FI-09" "FI-10"))
 (:id "REQ-REC-004" :src "Recovery" :cls "C1" :stato :progettato
  :txt "Un atomic swap incompleto è riconoscibile durante il recovery."
  :inv ("INV-C7") :adr ("ADR-0018" "ADR-0040") :ver (:model :fi) :fi ("FI-06"))

 ;; ---- Osservabilità, benchmark, fault injection, nativo, moduli --------------
 (:id "REQ-OBS-001" :src "Osservabilità" :cls "C3" :stato :progettato
  :txt "Sono esposte le metriche di richiesta: throughput, P50, P95, P99, P99.9."
  :inv () :adr ("ADR-0011") :ver (:test) :fi ())
 (:id "REQ-OBS-002" :src "Osservabilità" :cls "C3" :stato :progettato
  :txt "Sono esposte le metriche di storage, log, indici, cache, scheduler e GC elencate dalla specifica."
  :inv () :adr ("ADR-0011") :ver (:test) :fi ())
 (:id "REQ-BEN-001" :src "Benchmark" :cls "C4" :stato :progettato
  :txt "I benchmark sono riproducibili e, nei confronti con altri sistemi, eseguiti su hardware, dataset, indici, durability, concorrenza e semantica equivalenti."
  :inv ("INV-X2") :adr ("ADR-0028") :ver (:bench :rev) :fi ())
 (:id "REQ-BEN-002" :src "Target preliminari" :cls "C4" :stato :progettato
  :txt "I target di prestazione sono ipotesi finché non verificati; non si dichiara superiorità da benchmark eterogenei."
  :inv ("INV-X2") :adr ("ADR-0028") :ver (:rev) :fi ())
 (:id "REQ-FLT-001" :src "Fault injection" :cls "C1" :stato :progettato
  :txt "Sono implementati i test di fault injection per i dodici scenari della specifica e per la creazione di Serie."
  :inv () :adr ("ADR-0035") :ver (:fi) :fi ("FI-01" "FI-02" "FI-03" "FI-04" "FI-05" "FI-06" "FI-07" "FI-08" "FI-09" "FI-10" "FI-11" "FI-12" "FI-13"))
 (:id "REQ-SIM-001" :src "SIMD e ottimizzazioni native" :cls "C3" :stato :progettato
  :txt "Il sistema usa strutture compatte e array tipizzati; il SIMD si introduce solo sugli hot path dimostrati dai benchmark."
  :inv ("INV-X1") :adr ("ADR-0012" "ADR-0024") :ver (:rev :bench) :fi ())
 (:id "REQ-SIM-002" :src "ADR-0001" :cls "C4" :stato :progettato
  :txt "Il codice del progetto è solo Common Lisp."
  :inv ("INV-X3") :adr ("ADR-0001" "ADR-0027") :ver (:analisi :rev) :fi ())
 (:id "REQ-MOD-001" :src "Moduli software" :cls "C2" :stato :progettato
  :txt "Il sistema è organizzato almeno nei diciotto moduli della specifica."
  :inv () :adr ("ADR-0031") :ver (:rev) :fi ())

 ;; ---- Formati ---------------------------------------------------------------
 (:id "REQ-VAL-001" :src "Piano degli spike" :cls "C4" :stato :implementato
  :txt "La suite della Fase 0 compila gli esperimenti senza avvisi in processi isolati, esegue controlli deterministici e benchmark separati e conserva comandi, ambiente e output grezzo; nessun esito degli spike promuove automaticamente un requisito del motore a verificato."
  :inv ("INV-X2" "INV-X3") :adr ("ADR-0035") :ver (:test :analisi) :fi ())
 (:id "REQ-FOR-001" :src "ADR-0013" :cls "C1" :stato :progettato
  :txt "Ogni record e ogni file persistente porta lunghezza e CRC32C; ciò che non si verifica è trattato come inesistente (coda), rigenerato (dato derivato) o dichiarato corrotto (dato confermato)."
  :inv ("INV-F1") :adr ("ADR-0013" "ADR-0014" "ADR-0039") :ver (:test :fuzz :corr :fi) :fi ("FI-01" "FI-10"))
 (:id "REQ-FOR-002" :src "ADR-0014" :cls "C1" :stato :progettato
  :txt "Ogni file persistente ha magic e versione di formato; un formato non cambia, si crea una nuova versione con migrazione."
  :inv ("INV-F1") :adr ("ADR-0014") :ver (:test :rev) :fi ())
 (:id "REQ-FOR-003" :src "ADR-0039" :cls "C1" :stato :progettato
  :txt "Tutti i record di tutti i log hanno la stessa cornice di 24 byte con CRC dell'intestazione e CRC del corpo; l'intestazione è verificata prima di usare le lunghezze; il CRC del corpo è calcolato fuori dal writer."
  :inv ("INV-F1" "INV-F2") :adr ("ADR-0039") :ver (:test :fuzz :corr :bench) :fi ())
 (:id "REQ-FOR-004" :src "ADR-0047" :cls "C1" :stato :progettato
  :txt "La lettura di un record prepared verifica una prova autorevole del segmento (OUTCOME o esito nel manifest): il TXID della prova coincide con lo stamp del record e il suo CSN coincide con quello della entry; una prova mancante, corrotta o riferita a un'altra versione produce errore di integrità."
  :inv ("INV-A2" "INV-S7") :adr ("ADR-0039" "ADR-0047") :ver (:test :corr :fuzz :diff) :fi ())

 ;; ---- Affidabilità (software critico) --------------------------------------
 (:id "REQ-AFF-001" :src "ADR-0033" :cls "C1" :stato :progettato
  :txt "Un errore di scrittura, flush, rinomina o sincronizzazione di directory porta la Serie o l'Archivio in FAULTED senza retry e senza conferma del lotto."
  :inv ("INV-A1") :adr ("ADR-0033") :ver (:test :fi) :fi ("FI-02"))
 (:id "REQ-AFF-002" :src "ADR-0033" :cls "C1" :stato :progettato
  :txt "Ogni record letto da disco o da cache è verificato con i CRC32C di intestazione e corpo e con il confronto di chiave e CSN (la versione) prima di essere restituito; un dato non verificato non è mai restituito."
  :inv ("INV-A2") :adr ("ADR-0033" "ADR-0039") :ver (:test :corr :fuzz) :fi ())
 (:id "REQ-AFF-003" :src "ADR-0034" :cls "C4" :stato :implementato
  :txt "Nessun codice di prodotto è compilato con safety inferiore a 2; la compilazione è priva di avvisi; i costrutti vietati sono rilevati dal linter."
  :inv ("INV-A3") :adr ("ADR-0034") :ver (:analisi) :fi ())
 (:id "REQ-AFF-004" :src "ADR-0033" :cls "C1" :stato :progettato
  :txt "Ogni errore è una condizione tipizzata della gerarchia arcdocdb-error, mai ignorata; le asserzioni sugli invarianti restano attive e in C1 portano la Serie in FAULTED."
  :inv ("INV-A4") :adr ("ADR-0033" "ADR-0034") :ver (:analisi :rev :mut) :fi ())
 (:id "REQ-AFF-005" :src "ADR-0035" :cls "C4" :stato :verificato
  :txt "Ogni requisito ha fonte, classe e verifica; ogni invariante e ogni scenario FI è coperto da almeno un requisito; la matrice è generata e controllata."
  :inv ("INV-A5") :adr ("ADR-0035") :ver (:analisi) :fi ())
 (:id "REQ-AFF-006" :src "ADR-0033" :cls "C1" :stato :progettato
  :txt "Un processo di scrubbing verifica i segmenti chiusi con ciclo completo entro 7 giorni e mette in quarantena i segmenti con errori."
  :inv ("INV-A6") :adr ("ADR-0033") :ver (:test :corr) :fi ())
 (:id "REQ-AFF-007" :src "ADR-0033" :cls "C1" :stato :progettato
  :txt "Il recovery è idempotente: interromperlo in qualsiasi punto e rieseguirlo produce lo stesso stato finale."
  :inv ("INV-A7") :adr ("ADR-0033" "ADR-0036") :ver (:model :fi :soak) :fi ("FI-01" "FI-06" "FI-07" "FI-08" "FI-10"))
 (:id "REQ-AFF-008" :src "ADR-0033" :cls "C1" :stato :progettato
  :txt "Ogni risorsa ha un limite configurato e controllato; il superamento produce un rifiuto esplicito; nessun ciclo è illimitato."
  :inv ("INV-A8") :adr ("ADR-0033" "ADR-0034") :ver (:test :rev) :fi ())
 (:id "REQ-AFF-009" :src "ADR-0037" :cls "C1" :stato :progettato
  :txt "Il recovery distingue una coda da una corruzione con la frontiera durevole dichiarata dai SEAL: un'anomalia sotto la frontiera di un SEAL successivo valido porta il log in FAULTED senza alcuna scrittura; altrimenti la lunghezza valida è l'inizio del primo lotto non valido. La regola vale per segmento ACTIVE, control log e multiserie.log e non dipende dall'ordine di persistenza delle scritture non sincronizzate."
  :inv ("INV-F1" "INV-F3" "INV-A1") :adr ("ADR-0033" "ADR-0037") :ver (:test :fi :corr :model) :fi ("FI-01" "FI-02"))
 (:id "REQ-AFF-010" :src "ADR-0033" :cls "C1" :stato :progettato
  :txt "Esiste un verificatore offline che apre un Archivio in sola lettura, verifica formati, CRC e coerenza tra log, segmenti, hint, indici, multiserie.log e catalogo, e riporta ogni anomalia."
  :inv ("INV-F1") :adr ("ADR-0033") :ver (:test :corr) :fi ())
 (:id "REQ-AFF-011" :src "ADR-0033" :cls "C1" :stato :progettato
  :txt "L'apertura di un Archivio acquisisce un lock esclusivo; una seconda apertura fallisce immediatamente."
  :inv () :adr ("ADR-0033") :ver (:test) :fi ())
 (:id "REQ-AFF-012" :src "ADR-0028" :cls "C3" :stato :progettato
  :txt "Il sistema raggiunge i minimi vincolanti di prestazione con tutti i controlli di affidabilità attivi."
  :inv () :adr ("ADR-0028" "ADR-0031") :ver (:bench) :fi ())
 (:id "REQ-AFF-013" :src "ADR-0035" :cls "C1" :stato :progettato
  :txt "Tempo, casualità, schedulazione e I/O passano da interfacce iniettabili; il sistema intero gira in un simulatore deterministico riproducibile da seme."
  :inv () :adr ("ADR-0035") :ver (:test :rev) :fi ())
 (:id "REQ-AFF-014" :src "ADR-0030" :cls "C1" :stato :progettato
  :txt "Esiste un backup consistente (segmenti chiusi, control log e hint a un CSN) verificabile dal verificatore offline; un restore rifiuta un backup che non verifica."
  :inv ("INV-F1") :adr ("ADR-0030") :ver (:test :corr) :fi ())
 (:id "REQ-AFF-015" :src "ADR-0033" :cls "C1" :stato :progettato
  :txt "Serie e Archivio hanno stati di salute definiti (HEALTHY, DEGRADED, FAULTED, MULTI-DISABLED); ogni transizione è un evento registrato e una metrica."
  :inv ("INV-A1") :adr ("ADR-0033") :ver (:test :model) :fi ())
 (:id "REQ-AFF-016" :src "ADR-0027" :cls "C4" :stato :progettato
  :txt "Il sistema non ha dipendenze esterne oltre SBCL e i suoi contrib."
  :inv ("INV-X3") :adr ("ADR-0027") :ver (:analisi) :fi ())
 (:id "REQ-AFF-017" :src "ADR-0036" :cls "C1" :stato :progettato
  :txt "Il recovery non modifica e non tronca alcun segmento esistente: chiude l'ACTIVE trovato alla sua lunghezza valida con un record del manifest e ne apre uno nuovo; il suo punto di atomicità per Serie è la rinomina del control log compattato."
  :inv ("INV-A9" "INV-A7") :adr ("ADR-0036" "ADR-0037" "ADR-0040") :ver (:test :model :fi :soak) :fi ("FI-01" "FI-02" "FI-10"))
 (:id "REQ-AFF-018" :src "ADR-0036" :cls "C1" :stato :progettato
  :txt "Un file o una directory è eliminato solo se ha suffisso tmp e nessuna fonte di verità lo nomina, oppure se una fonte di verità ne registra la rimozione; un oggetto con nome definitivo sconosciuto non è toccato ed è segnalato; un segment-id nominato dal manifest non è mai riusato."
  :inv ("INV-A10") :adr ("ADR-0036" "ADR-0040") :ver (:test :fi :corr) :fi ("FI-09" "FI-13"))
 (:id "REQ-AFF-019" :src "ADR-0036" :cls "C1" :stato :progettato
  :txt "Ogni operazione che cambia lo stato durevole ha un solo punto di atomicità (SEAL, EDIT, DECISION, documento di catalogo); ciò che lo precede è scartabile e ciò che lo segue è un completamento idempotente che il recovery ripete."
  :inv ("INV-A11" "INV-A7") :adr ("ADR-0036" "ADR-0040") :ver (:model :fi :rev) :fi ("FI-06" "FI-07" "FI-08" "FI-13"))
)
