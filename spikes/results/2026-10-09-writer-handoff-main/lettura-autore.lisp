(:SCHEMA-VERSION 1 :KIND :C1-REVIEW-IMPORT :ROLE :AUTHOR :BASE
 "7f8ca93499090b2a4f515015372046f16ac574cf" :SCOPE :INTEGRATION-ONLY
 :CHECK-STATUS :OK :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :CHECK
 "spikes/out/4000514046-command-42938-0/report.lisp" :REPORT
 (:PATH "docs/implementazione/writer-handoff-revisione.md" :GIT-BLOB
  "04f64ce2d33e27cc5d40482765223aa6dec062ea" :TEXT
  "# Revisione della consegna locale dei writer

Lettura dell'autore sul codice finale e sui dati della copia congelata;
lettura indipendente e verifica integrata conservate nel
[catalogo](../../spikes/results/2026-10-09-writer-handoff/catalogo.lisp).
I due rilievi della prima lettura sono conservati nella
[tabella delle decisioni](writer-handoff-decisioni.md#prima-lettura-indipendente-e-correzioni):
contratto dei retry e complessità del controllo degli stati, entrambi corretti.

| Sorgente | SHA-256 |
|---|---|
| `queue.lisp` | `244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90` |
| `handoff.lisp` | `ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607` |
| `tests/execution/handoff.lisp` | `7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e` |

## Lettura dell'autore

| Punto C1 | Esito e ambito |
|---|---|
| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0045 §§6/8. Nessun cambio di requisito o formato. |
| 2. Invarianti | INV-P1/P2: FIFO, lease e quantum cumulativo; INV-P5/P6: solo guard locale, nessun blocco o stato fra Serie. INV-A8/V4: budget e proprietari espliciti. Oracolo di 7200 passi e prove su thread reali; nessuna qualifica dell'intero motore. |
| 3. Errori | Full/busy precedono l'accettazione; busy al termine conserva la lease e non richiede rielaborazione. Gettoni vecchi/estranei e target invalidi rifiutati. Generation permanente, not-ready non eleggibile/duplicato. FI privata sulle guardie e sette stati incoerenti; invarianti al controller per fail-stop. |
| 4. Limiti | Nessun nuovo ciclo/ricorsione/attesa nel prodotto; un tentativo CAS per guard. Prelievo delegato bounded dal quantum e dallo span. I timeout e le attese con lease nelle fixture forzano interleaving, non costituiscono compiti del prodotto. |
| 5. Allocazioni | Oggetti e ring all'avvio; nessuna allocazione esplicita nel percorso normale. Dieci campioni preallocati osservano zero heap; controllo positivo rileva 16.777.472 byte. Misura seriale locale, esclusi startup, errori e controller; nessuna prova universale. |
| 6. Dati verificati | Payload interno opaco, ownership trasferita al conteggio riuscito; FIFO/span/lease delegati alle primitive. Nessun dato persistente decodificato o restituito da questo componente. |
| 7. Decisioni | Inventario scalari/CASE/cleanup completo; nessun nuovo and/or composto in handoff. Raw 173/190 espressioni e 16/16 esiti; 17 forme non marcate incluse, nessuna esclusione o MC/DC completa. Tutti i 16 mutanti compilano e sono rilevati. |
| 8. Proprietà | Wrapper e ring privati di una Serie. Guard del ring protegge anche stato/count; lease lega owner/generation al thread. Coda interna non esposta, copier assente; nessuna seconda guard. |
| 9. Tracciabilità/check | Annotazioni REQ coerenti; build forzata senza avvisi, suite execution riuscita. `make check` finale passa sulla base `4215fca`, con sorgenti stabili; record e output nel catalogo. Nessun requisito promosso. |
| 10. Standard | Safety 3, ftype completi, slot tipizzati, docstring pre/post/errori, funzioni sotto 60 righe. Helper degli stati con otto e quattro percorsi, entro COD-13; nessuna deviazione approvata o introdotta. |
| 11. Parallelismo | Messaggi modificano solo la propria Serie. Obbligo comune futuro solo su avvio/riaccodamento del tratto. B avanza con A che mantiene guard e lease nella fixture; nessuna misura di throughput, fairness o latenza del database. |
| 12. Atomicità | Nessun cambiamento durevole o eliminazione. Count e decisione ready/idle sono coordinati nella stessa sezione locale; release owner precede stato finale e rilascio guard. |

Nessun rilievo funzionale residuo nel contratto locale. Il chiamante deve
conservare ed eseguire una sola volta il compito restituito da `:schedule`;
il wrapper non implementa lista pronta, risvegli, shutdown o pool adattivo.
Non garantisce progresso se il chiamante abbandona l'obbligo o la lease.

## Lettura indipendente

La [lettura originale](../../spikes/results/2026-10-09-writer-handoff/lettura-indipendente.lisp)
conserva i dodici punti verbatim e l’appendice che chiude il check sulla
base `4215fca`. La [lettura dell’autore](../../spikes/results/2026-10-09-writer-handoff/lettura-autore.lisp)
conserva separatamente il documento e il suo Git blob prima delle aggiunte
editoriali finali. I [probe del revisore](../../spikes/results/2026-10-09-writer-handoff/probe-revisore.lisp)
conservano sia l’errore dell’adattatore ispettivo sia la lettura corretta;
i metadati mancanti sono dichiarati senza ricostruzione.

L’integrazione successiva della validazione UTF-8 su `7f8ca93` aggiunge
il modulo codec ad ASDF e la relativa riga all’indice. Il codice execution,
i suoi test e i due strumenti della campagna restano invariati; ASDF e
l’indice conservano entrambi i contributi. La [verifica completa dell’integrazione](../../spikes/results/2026-10-09-writer-handoff-main/check-integrato.lisp)
passa con exit 0 e sorgenti stabili: 220 test di modulo più smoke,
40 file nel linter senza violazioni e dieci spike. Il nuovo SHA-256 ASDF è
`189c9601616e7b4f013d68954fa0a249b76f9416096b19950b841a4c63621b7e`.
L’[appendice indipendente](../../spikes/results/2026-10-09-writer-handoff-main/lettura-indipendente.lisp)
verifica separatamente questa integrazione, conservando la lettura precedente.

## Strumenti e tentativi conservati

Gli strumenti C4 sono compilati per intero con warning/style-warning fatali.
I self-test verificano marker autentici, target mancanti/ambigui, sink errato,
clock nullo, destinazione esistente e persistenza dei report parziali.
Baseline, log dei sedici mutanti e misure sono conservati integralmente.

I primi due tentativi dell'adattatore di compilazione hanno fallito prima
delle campagne: contrib `sb-md5` non precaricato durante `compile-file`,
poi argv SBCL non impostato per il main del FASL. L'adattatore corretto
precarica i contrib e imposta entrambi gli argv. Il primo esportatore della
copertura cercava `index.html` invece di `cover-index.html`: il path è corretto,
senza modificare o ripetere la campagna di copertura. Output e sorgenti di
questi tentativi sono conservati; non vengono conteggiati come mutanti rilevati.
")
 :SOURCES
 ((:PATH "arcdocdb.asd" :GIT-BLOB "79a517464b4d6eb9324103af02cdf9d9eee357e2"
   :TEXT ";;;; arcdocdb.asd — definizione di sistema ASDF.
;;;;
;;;; Fondazioni dello storage, autorizzate dall'autore il 2026-10-08.

(in-package #:asdf-user)

(defsystem \"arcdocdb\"
  :description \"Database server documentale general-purpose, append-only, in Common Lisp (SBCL).\"
  :author \"Giacomo Picchiarelli\"
  :license \"BSD-2-Clause\"
  :version \"0.0.0\"
  :pathname \"src/\"
  :serial t
  :depends-on (\"sb-posix\")
  :components ((:file \"package\")
               (:module \"foundation\"
                :serial t
                :components ((:file \"package\") (:file \"conditions\")
                             (:file \"binary\") (:file \"crc32c\")
                             (:file \"record\") (:file \"batch\")))
               (:module \"codec\" :serial t
                :components ((:file \"package\") (:file \"utf8\")))
               (:module \"execution\" :serial t
                :components ((:file \"package\") (:file \"queue\") (:file \"writer\")
                             (:file \"handoff\")))
               (:module \"storage\"
                :serial t
                :components ((:file \"package\") (:file \"formats\") (:file \"segment-header\")
                             (:file \"log-header\") (:file \"compaction-scan\")
                             (:file \"control-payload\") (:file \"payload-record\")
                             (:file \"payload-write\")))
               (:module \"io\" :serial t
                :components ((:file \"package\") (:file \"types\") (:file \"native\")
                             (:file \"lifecycle\") (:file \"transfer\") (:file \"flush\")))
               (:module \"wal\" :serial t
                :components ((:file \"package\") (:file \"types\") (:file \"builder\")
                             (:file \"group\") (:file \"executor\")))
               (:module \"recovery\"
                :serial t
                :components ((:file \"package\") (:file \"scan\")
                             (:file \"decisions-package\") (:file \"decisions-types\")
                             (:file \"decisions-sort\") (:file \"decisions-radix\") (:file \"decisions-build\")
                             (:file \"decisions-query\"))))
  :in-order-to ((test-op (test-op \"arcdocdb/tests\"))))

(defsystem \"arcdocdb/tests\"
  :description \"Test di ArcDocDB.\"
  :author \"Giacomo Picchiarelli\"
  :license \"BSD-2-Clause\"
  :depends-on (\"arcdocdb\")
  :pathname \"tests/\"
  :serial t
  :components ((:file \"smoke\")
               (:module \"foundation\"
                :serial t
                :components ((:file \"support\") (:file \"binary\")
                             (:file \"record\") (:file \"batch\")))
               (:module \"codec\" :serial t
                :components ((:file \"support\") (:file \"utf8\") (:file \"threads\")))
               (:module \"execution\" :serial t
                :components ((:file \"support\") (:file \"queue\") (:file \"threads\")
                             (:file \"handoff\")))
               (:module \"storage\"
                :serial t
                :components ((:file \"support\") (:file \"segment-header\") (:file \"log-header\")
                             (:file \"compaction-scan\")
                             (:file \"control-payload\")))
               (:module \"io\" :serial t
                :components ((:file \"support\") (:file \"transfer\") (:file \"native\")))
               (:module \"recovery\"
                :serial t
                :components ((:file \"support\") (:file \"scan\") (:file \"corruption\")
                             (:file \"decisions-support\") (:file \"decisions\")
                             (:file \"decisions-audit\") (:file \"decisions-radix\")))
               (:module \"wal\" :serial t
                :components ((:file \"support\") (:file \"builder\") (:file \"group\") (:file \"fault\")
                             (:file \"native\"))))
  :perform (test-op (o c)
             (uiop:symbol-call '#:arcdocdb.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.utf8.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.execution.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.storage.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.io.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.wal.tests '#:run)))
")
  (:PATH "src/execution/handoff.lisp" :GIT-BLOB
   "a030e7af1afd6db760088f74615fe2396d928b64" :TEXT
   ";;;; Consegna locale del writer: la guard del ring protegge anche lo scheduling.
;;; OWNER: ogni wrapper e la sua coda privata appartengono a una sola Serie.
;;; SHARED: stato/count sotto la stessa guard; owner/generation con protocollo lease.
;;; Nessuno stato fra Serie: :schedule trasferisce un obbligo al chiamante.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (writer-programmabile (:constructor %make-writer-programmabile (queue))
                                (:copier nil))
  \"Pre: coda privata, mai esposta né usata tramite le API basse. Post: writer IDLE.
Le API trasferiscono obblighi :SCHEDULE, non creano thread né inviano notifiche.\"
  (queue (error 'invariant-violation :reason :writer-scheduling)
         :type coda-writer :read-only t)
  (state :idle :type (member :idle :ready :running)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer) null) %check-writer-inattivo))
(defun %check-writer-inattivo (queue)
  \"Pre: guard posseduta, stato IDLE o READY. Post: nessuna lease e quota zero.
INVARIANT-VIOLATION per guard, owner o quota incompatibili con il passaggio.\"
  (unless (eq (coda-writer-guard queue) sb-thread:*current-thread*)
    (error 'invariant-violation :reason :writer-guard))
  (unless (null (coda-writer-owner queue))
    (error 'invariant-violation :reason :writer-scheduling))
  (unless (zerop (coda-writer-extracted queue))
    (error 'invariant-violation :reason :writer-scheduling))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile) null) %check-programmabile))
(defun %check-programmabile (writer)
  \"Pre: guard della coda privata posseduta. Post: ring e stato/owner coerenti.
INVARIANT-VIOLATION per guard errata o stato che non rappresenta il lavoro.\"
  (let* ((queue (writer-programmabile-queue writer))
         (count (coda-writer-count queue)) (owner (coda-writer-owner queue)))
    (unless (eq (coda-writer-guard queue) sb-thread:*current-thread*)
      (error 'invariant-violation :reason :writer-guard))
    (%check-queue queue)
    (case (writer-programmabile-state writer)
      (:idle
       (unless (zerop count) (error 'invariant-violation :reason :writer-scheduling))
       (%check-writer-inattivo queue))
      (:ready
       (unless (plusp count) (error 'invariant-violation :reason :writer-scheduling))
       (%check-writer-inattivo queue))
      (:running
       (unless owner (error 'invariant-violation :reason :writer-scheduling)))
      (otherwise (error 'invariant-violation :reason :writer-scheduling))))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (&key (:capacity t) (:quantum t)) writer-programmabile)
                crea-writer-programmabile))
(defun crea-writer-programmabile (&key (capacity 1024) (quantum 64))
  \"Pre: capacity/quantum nei limiti di CREA-CODA-WRITER. Post: wrapper IDLE
con ring esclusivo preallocato; INVALID-ARGUMENT per configurazione errata.\"
  (let* ((queue (crea-coda-writer :capacity capacity :quantum quantum))
         (writer (%make-writer-programmabile queue)) (thread (%acquisisci-guard queue)))
    (unwind-protect (progn (%check-programmabile writer) writer)
      (%rilascia-guard queue thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile t)
                         (values index (member :schedule :queued) &optional))
                accoda-lavoro-writer))
(defun accoda-lavoro-writer (writer message)
  \"Pre: payload posseduto dal chiamante. Post: accettazione FIFO; :SCHEDULE solo
su IDLE→READY, :QUEUED se già READY/RUNNING. Il chiamante conserva ed esegue una
sola volta l'obbligo :SCHEDULE; un retry della notifica non ripete l'accettazione.
RESOURCE-EXHAUSTED full/busy prima dell'accettazione; invarianti impongono fail-stop.\"
  (let* ((queue (writer-programmabile-queue writer)) (thread (%acquisisci-guard queue)))
    (unwind-protect
         (progn
           (%check-programmabile writer)
           (let* ((schedule (eq (writer-programmabile-state writer) :idle))
                  (count (%accoda-sotto-guard queue message)))
             (when schedule (setf (writer-programmabile-state writer) :ready))
             (%check-programmabile writer)
             (values count (if schedule :schedule :queued))))
      (%rilascia-guard queue thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile) index) inizia-tratto-writer))
(defun inizia-tratto-writer (writer)
  \"Pre: compito pronto assegnato dal chiamante. Post: READY→RUNNING con lease
del thread corrente; nessun messaggio estratto. RESOURCE-EXHAUSTED conserva lo
stato: busy richiede retry del compito; not-ready rifiuta un'assegnazione non
eleggibile/duplicata; generation è esaurimento permanente, senza wrap.\"
  (let* ((queue (writer-programmabile-queue writer)) (thread (%acquisisci-guard queue)))
    (unwind-protect
         (progn
           (%check-programmabile writer)
           (unless (eq (writer-programmabile-state writer) :ready)
             (error 'resource-exhausted :reason :writer-not-ready))
           (let ((lease (acquisisci-writer queue)))
             (setf (writer-programmabile-state writer) :running)
             (%check-programmabile writer)
             lease))
      (%rilascia-guard queue thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile t t t t)
                         (values index (member :messages :empty :yield) &optional))
                preleva-lavori-writer))
(defun preleva-lavori-writer (writer lease target start end)
  \"Pre: lease corrente del tratto e target privato. Post: prelievo FIFO bounded
e quota cumulativa come PRELEVA-MESSAGGI; le medesime condizioni al rifiuto.
La lease impedisce una fine-tratto concorrente; la coda interna resta privata.\"
  (preleva-messaggi (writer-programmabile-queue writer) lease target start end))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile t) (member :schedule :idle))
                termina-tratto-writer))
(defun termina-tratto-writer (writer lease)
  \"Pre: messaggi estratti elaborati, lease corrente. Post: quota/gettone rilasciati
e READY/:SCHEDULE se resta lavoro, IDLE/:IDLE se vuoto, sotto la guard del ring.
Il chiamante conserva l'obbligo :SCHEDULE. Busy conserva lease e stato: ritentare
solo il termine, senza rielaborare payload. INVALID-ARGUMENT lease; invarianti
impongono fail-stop. Nessuna notifica o attesa; nessun cambiamento durevole.\"
  (let ((queue (writer-programmabile-queue writer)))
    (%check-lease queue lease)
    (let ((thread (%acquisisci-guard queue)))
      (unwind-protect
           (progn
             (%check-programmabile writer)
             (let ((pending (plusp (coda-writer-count queue))))
               (rilascia-writer queue lease)
               (setf (writer-programmabile-state writer) (if pending :ready :idle))
               (%check-programmabile writer)
               (if pending :schedule :idle)))
        (%rilascia-guard queue thread)))))
")
  (:PATH "src/execution/queue.lisp" :GIT-BLOB
   "bb4d4d6f222aa360ec64ef2f45ee6ba0524dd2f0" :TEXT
   ";;;; Ring preallocato: serializzazione dei soli indici con un tentativo CAS.
;;; OWNER: payload dal chiamante alla coda soltanto all'accettazione.
;;; SHARED: slots/head/tail/count mutabili soltanto con guard locale posseduta.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(defconstant +max-writer-capacity+ 65536)
(defconstant +max-writer-quantum+ 65536)
(defstruct (coda-writer (:constructor %make-coda-writer (slots capacity quantum))
                       (:copier nil))
  \"Pre: slots privati preallocati e budget finiti. Post: ring vuoto, nessuna lease.
Guard e owner hanno CAS distinti; generation non viene mai riciclata.\"
  (slots #() :type simple-vector :read-only t)
  (capacity 1024 :type index :read-only t)
  (quantum 64 :type index :read-only t)
  (head 0 :type index) (tail 0 :type index) (count 0 :type index)
  (guard nil :type (or null sb-thread:thread))
  (owner nil :type (or null sb-thread:thread))
  (generation 0 :type index) (extracted 0 :type index))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer) null) %check-queue))
(defun %check-queue (queue)
  \"Pre: guard posseduta, oppure coda appena costruita e non pubblicata.
Post: indici bounded e relazione FIFO coerente; INVARIANT-VIOLATION al guasto.\"
  (let ((capacity (coda-writer-capacity queue)) (head (coda-writer-head queue))
        (tail (coda-writer-tail queue)) (count (coda-writer-count queue)))
    (unless (and (<= 1 capacity +max-writer-capacity+)
                 (= (length (coda-writer-slots queue)) capacity)
                 (< head capacity) (< tail capacity) (<= count capacity))
      (error 'invariant-violation :reason :writer-queue-invariant))
    (unless (= tail (mod (+ head count) capacity))
      (error 'invariant-violation :reason :writer-queue-invariant)))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer) sb-thread:thread) %acquisisci-guard))
(defun %acquisisci-guard (queue)
  \"Pre: operazione breve sul ring. Post: guard locale del thread corrente.
Un solo CAS, senza attesa; RESOURCE-EXHAUSTED se busy, INVARIANT-VIOLATION al guasto.\"
  (let ((thread sb-thread:*current-thread*))
    (unless (null (sb-ext:compare-and-swap (coda-writer-guard queue) nil thread))
      (error 'resource-exhausted :reason :writer-queue-busy))
    (unless (eq (coda-writer-guard queue) thread)
      (error 'invariant-violation :reason :writer-guard))
    thread))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer sb-thread:thread) null) %rilascia-guard))
(defun %rilascia-guard (queue thread)
  \"Pre: guard acquisita da THREAD. Post: guard libera tramite un solo CAS.
INVARIANT-VIOLATION per proprietario diverso; nessuna attesa o recupero implicito.\"
  (unless (eq (coda-writer-guard queue) thread)
    (error 'invariant-violation :reason :writer-guard))
  (unless (eq (sb-ext:compare-and-swap (coda-writer-guard queue) thread nil) thread)
    (error 'invariant-violation :reason :writer-guard))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (&key (:capacity t) (:quantum t)) coda-writer) crea-coda-writer))
(defun crea-coda-writer (&key (capacity 1024) (quantum 64))
  \"Pre: capacity e quantum interi tra 1 e 65536, indipendenti.
Post: ring SIMPLE-VECTOR privato allocato una volta; INVALID-ARGUMENT al rifiuto.\"
  (unless (and (typep capacity 'index) (<= 1 capacity +max-writer-capacity+))
    (error 'invalid-argument :reason :writer-configuration))
  (unless (and (typep quantum 'index) (<= 1 quantum +max-writer-quantum+))
    (error 'invalid-argument :reason :writer-configuration))
  (let ((queue (%make-coda-writer (make-array capacity :initial-element nil) capacity quantum)))
    (%check-queue queue)
    queue))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) index) %accoda-sotto-guard))
(defun %accoda-sotto-guard (queue message)
  \"Pre: guard locale posseduta dal thread corrente, payload del produttore.
Post: una sola accettazione FIFO e count aggiornato; RESOURCE-EXHAUSTED se full
senza mutazioni, INVARIANT-VIOLATION per guard o indici incoerenti.\"
  (unless (eq (coda-writer-guard queue) sb-thread:*current-thread*)
    (error 'invariant-violation :reason :writer-guard))
  (%check-queue queue)
  (when (= (coda-writer-count queue) (coda-writer-capacity queue))
    (error 'resource-exhausted :reason :writer-queue-full))
  (let ((tail (coda-writer-tail queue)))
    (setf (svref (coda-writer-slots queue) tail) message
          (coda-writer-tail queue) (mod (1+ tail) (coda-writer-capacity queue))
          (coda-writer-count queue) (1+ (coda-writer-count queue))))
  (%check-queue queue)
  (coda-writer-count queue))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) index) accoda-messaggio))
(defun accoda-messaggio (queue message)
  \"Pre: payload opaco posseduto dal chiamante, compreso NIL. Post: accettato in FIFO,
ownership alla coda, restituisce il count dopo l'accettazione. RESOURCE-EXHAUSTED
per full/busy senza mutare ring o payload; nessun callback, attesa o wakeup.\"
  (let ((thread (%acquisisci-guard queue)))
    (unwind-protect (%accoda-sotto-guard queue message)
      (%rilascia-guard queue thread))))
")
  (:PATH "src/execution/package.lisp" :GIT-BLOB
   "6f3332bb773425341d1ec2ee27b70527e0797dea" :TEXT
   ";;;; Esecuzione locale: coda bounded e lease esplicita del singolo writer.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defpackage #:arcdocdb.execution
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:index)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation)
  (:export #:coda-writer #:crea-coda-writer #:accoda-messaggio
           #:acquisisci-writer #:preleva-messaggi #:rilascia-writer
           #:writer-programmabile #:crea-writer-programmabile #:accoda-lavoro-writer
           #:inizia-tratto-writer #:preleva-lavori-writer #:termina-tratto-writer))
")
  (:PATH "tests/execution/handoff.lisp" :GIT-BLOB
   "ba702352ee63241b9ac993b0aca8f162c3deef1b" :TEXT
   ";;;; Oracolo FIFO e fixture del passaggio locale idle/ready/running.
;;;; Semafori e thread appartengono soltanto alla fixture, non al prodotto.
(in-package #:arcdocdb.execution.tests)

(defun handoff-check-enqueue (writer item expected-count expected-status)
  (multiple-value-bind (count status)
      (arcdocdb.execution:accoda-lavoro-writer writer item)
    (is (= count expected-count))
    (is (eq status expected-status))
    count))

(defun handoff-check-pop (writer lease target start end expected expected-status)
  \"Lista attesa indipendente; verifica anche tutte le celle non scritte.\"
  (let ((before (copy-seq target)))
    (multiple-value-bind (count status)
        (arcdocdb.execution:preleva-lavori-writer writer lease target start end)
      (is (= count (length expected)))
      (is (eq status expected-status))
      (loop for item in expected for i from start do (is (eq item (svref target i))))
      (dotimes (i (length target))
        (unless (<= start i (1- (+ start count)))
          (is (eq (svref before i) (svref target i)))))
      count)))

(defun handoff-drain (writer maximum)
  \"Ready initiale; limite maximum+1, nessuna lettura dei contatori del ring.\"
  (let ((target (make-array (max 1 maximum) :initial-element :untouched)) (items nil))
    (loop repeat (1+ maximum)
          do (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
               (multiple-value-bind (count status)
                   (arcdocdb.execution:preleva-lavori-writer writer lease target 0 (length target))
                 (is (plusp count)) (is (eq status :messages))
                 (dotimes (i count) (push (svref target i) items)))
               (let ((next (arcdocdb.execution:termina-tratto-writer writer lease)))
                 (is (member next '(:idle :schedule)))
                 (when (eq next :idle) (return-from handoff-drain (nreverse items)))))
          finally (error \"Il drain handoff ha superato il limite della fixture.\"))))

(defun handoff-fi-snapshot (writer)
  \"FI: immagine dei campi prima/dopo un rifiuto, mai oracolo dell'ordine FIFO.\"
  (let ((queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (list (arcdocdb.execution::writer-programmabile-state writer)
          (arcdocdb.execution::coda-writer-head queue)
          (arcdocdb.execution::coda-writer-tail queue)
          (arcdocdb.execution::coda-writer-count queue)
          (arcdocdb.execution::coda-writer-owner queue)
          (arcdocdb.execution::coda-writer-generation queue)
          (arcdocdb.execution::coda-writer-extracted queue)
          (copy-seq (arcdocdb.execution::coda-writer-slots queue)))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-handoff-configuration-and-limits
  (dolist (bad '(0 -1 65537 nil 2.0))
    (signals invalid-argument
      (arcdocdb.execution:crea-writer-programmabile :capacity bad :quantum 3)
      :writer-configuration)
    (signals invalid-argument
      (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum bad)
      :writer-configuration))
  (dolist (limits '((1 65536) (65536 1)))
    (let ((writer (arcdocdb.execution:crea-writer-programmabile
                   :capacity (first limits) :quantum (second limits))))
      (handoff-check-enqueue writer nil 1 :schedule)
      (is (equal '(nil) (handoff-drain writer 1)))))
  (let ((writer (arcdocdb.execution:crea-writer-programmabile)))
    (dotimes (i 1024)
      (handoff-check-enqueue writer i (1+ i) (if (zerop i) :schedule :queued)))
    (signals resource-exhausted
      (arcdocdb.execution:accoda-lavoro-writer writer :extra) :writer-queue-full)
    (is (equal (loop for i below 1024 collect i) (handoff-drain writer 1024)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-handoff-single-obligation-and-duplicate-begin
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum 2))
        (target (vector :left :x :y :right)))
    (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
             :writer-not-ready)
    ;; Un invio della notifica che fallisce conserva l'obbligo :schedule.
    ;; Il chiamante ritenta la notifica; il payload accettato non viene riaccodato.
    (multiple-value-bind (count pending) (arcdocdb.execution:accoda-lavoro-writer writer :a)
      (is (= count 1)) (is (eq pending :schedule))
      (let ((attempts 0))
        (flet ((notify () (> (incf attempts) 1)))
          (is (null (notify)))
          (is (eq pending :schedule))
          (handoff-check-enqueue writer :b 2 :queued)
          (is (notify))
          (is (= attempts 2))
          (setf pending nil)))
      (is (null pending))
      (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                 :writer-not-ready)
        (handoff-check-pop writer lease target 1 3 '(:a :b) :messages)
        (handoff-check-pop writer lease target 1 3 nil :yield)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease)))))
    (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
             :writer-not-ready)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-handoff-enqueue-before-and-after-empty-release
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 3))
        (target (vector :untouched)))
    (handoff-check-enqueue writer :initial 1 :schedule)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 0 1 '(:initial) :messages)
      (handoff-check-pop writer lease target 0 1 nil :empty)
      ;; Vuoto, ma running: il prossimo lavoro non crea una seconda notifica.
      (handoff-check-enqueue writer :before-release 1 :queued)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (is (equal '(:before-release) (handoff-drain writer 2)))
    ;; La pubblicazione successiva al rilascio vuoto crea il nuovo obbligo.
    (handoff-check-enqueue writer :after-release 1 :schedule)
    (is (equal '(:after-release) (handoff-drain writer 2)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-handoff-cumulative-quantum-and-successive-slices
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 7 :quantum 3))
        (target (make-array 8 :initial-element :untouched)))
    (dotimes (i 7)
      (handoff-check-enqueue writer i (1+ i) (if (zerop i) :schedule :queued)))
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 1 3 '(0 1) :messages)
      (handoff-check-pop writer lease target 1 7 '(2) :messages)
      (let ((queue (arcdocdb.execution::writer-programmabile-queue writer)))
        (with-execution-guard (queue)
          (handoff-check-pop writer lease target 1 7 nil :yield)))
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 1 7 '(3 4 5) :messages)
      (handoff-check-pop writer lease target 1 7 nil :yield)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (is (equal '(6) (handoff-drain writer 7)))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-handoff-full-ready-and-running-retain-state
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 1))
         (a (vector :a)) (b (vector :b)) (refused (vector :refused)))
    (handoff-check-enqueue writer a 1 :schedule)
    (handoff-check-enqueue writer b 2 :queued)
    (let ((before (handoff-fi-snapshot writer)))
      (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer refused)
               :writer-queue-full)
      (is (equalp before (handoff-fi-snapshot writer))))
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (let ((before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer refused)
                 :writer-queue-full)
        (is (equalp before (handoff-fi-snapshot writer))))
      (handoff-check-pop writer lease (vector :untouched) 0 1 (list a) :messages)
      (handoff-check-enqueue writer refused 2 :queued)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (is (equalp refused #(:refused)))
    (is (equal (list b refused) (handoff-drain writer 2)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-handoff-busy-idle-and-ready-preserve-state
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (with-execution-guard (queue)
      (let ((before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer :refused)
                 :writer-queue-busy)
        (is (equalp before (handoff-fi-snapshot writer)))))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (with-execution-guard (queue)
      (let ((before (handoff-fi-snapshot writer)))
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                 :writer-queue-busy)
        (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer :refused)
                 :writer-queue-busy)
        (is (equalp before (handoff-fi-snapshot writer)))))
    (is (equal '(:kept) (handoff-drain writer 2)))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-handoff-busy-release-retains-lease-for-retry
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (target (vector :left :right)))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (with-execution-guard (queue)
        (let ((before (handoff-fi-snapshot writer)))
          (signals resource-exhausted
            (arcdocdb.execution:preleva-lavori-writer writer lease target 0 2)
            :writer-queue-busy)
          (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer :refused)
                   :writer-queue-busy)
          (signals resource-exhausted (arcdocdb.execution:termina-tratto-writer writer lease)
                   :writer-queue-busy)
          (is (equalp target #(:left :right)))
          (is (equalp before (handoff-fi-snapshot writer)))))
      (handoff-check-pop writer lease target 0 2 '(:kept) :messages)
      (with-execution-guard (queue)
        (let ((before (handoff-fi-snapshot writer)))
          (signals resource-exhausted (arcdocdb.execution:termina-tratto-writer writer lease)
                   :writer-queue-busy)
          (is (equalp before (handoff-fi-snapshot writer)))))
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-005-handoff-early-release-conserves-entire-backlog
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 8)))
    (handoff-check-enqueue writer :a 1 :schedule)
    (handoff-check-enqueue writer :b 2 :queued)
    (let ((old (arcdocdb.execution:inizia-tratto-writer writer)))
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer old)))
      (let ((fresh (arcdocdb.execution:inizia-tratto-writer writer)))
        (is (> fresh old))
        (handoff-check-pop writer fresh (vector :untouched :untouched) 0 2 '(:a :b) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer fresh)))))))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-lease-validation-and-stale-generation
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
        (target (vector :untouched)))
    (handoff-check-enqueue writer :old 1 :schedule)
    (let ((old (arcdocdb.execution:inizia-tratto-writer writer)))
      (dolist (bad (list 0 -1 nil :wrong (1+ most-positive-fixnum)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer bad target 0 1) :writer-lease)
        (signals invalid-argument (arcdocdb.execution:termina-tratto-writer writer bad)
                 :writer-lease))
      (handoff-check-pop writer old target 0 1 '(:old) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer old)))
      (signals invalid-argument (arcdocdb.execution:termina-tratto-writer writer old)
               :writer-lease)
      (handoff-check-enqueue writer :fresh 1 :schedule)
      (let ((fresh (arcdocdb.execution:inizia-tratto-writer writer)))
        (is (> fresh old))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer old target 0 1) :writer-lease)
        (signals invalid-argument (arcdocdb.execution:termina-tratto-writer writer old)
                 :writer-lease)
        (handoff-check-pop writer fresh target 0 1 '(:fresh) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer fresh)))))))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-target-preflight-and-private-alias
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum 3))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (target (vector :left :middle :right)))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (let* ((lease (arcdocdb.execution:inizia-tratto-writer writer))
           (before (handoff-fi-snapshot writer)))
      (dolist (range '((-1 1) (0 0) (2 1) (0 4) (nil 1) (0 nil) (0 1.0)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer lease target
                                                 (first range) (second range)) :writer-target))
      (dolist (bad (list nil '(1 2) (make-array 3 :element-type '(unsigned-byte 8))
                        (make-array 3 :adjustable t :initial-element :caller)
                        (arcdocdb.execution::coda-writer-slots queue)))
        (signals invalid-argument
          (arcdocdb.execution:preleva-lavori-writer writer lease bad 0 1) :writer-target))
      (is (equalp target #(:left :middle :right)))
      (is (equalp before (handoff-fi-snapshot writer)))
      (handoff-check-pop writer lease target 1 3 '(:kept) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))))

;;; REQ: REQ-CON-001 REQ-AFF-008
(deftest test-REQ-AFF-008-handoff-generation-exhaustion-preserves-ready
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 1))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    ;; FI quiescente, nessun thread/lease attivo; si raggiunge l'ultimo token lecito.
    (setf (arcdocdb.execution::coda-writer-generation queue) (1- most-positive-fixnum))
    (handoff-check-enqueue writer :last 1 :schedule)
    (let ((last (arcdocdb.execution:inizia-tratto-writer writer)))
      (is (= last most-positive-fixnum))
      (handoff-check-pop writer last (vector nil) 0 1 '(:last) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer last))))
    (handoff-check-enqueue writer :preserved 1 :schedule)
    (let ((before (handoff-fi-snapshot writer)))
      (dotimes (attempt 2)
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                 :writer-generation)
        (is (equalp before (handoff-fi-snapshot writer)))))
    (handoff-check-enqueue writer :also-accepted 2 :queued)))

(defun handoff-fi-corrupt-state (writer fault)
  \"FI su oggetto privato sacrificato; gli indici del ring rimangono coerenti.\"
  (let ((queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (when (member fault '(:ready-count :ready-owner :ready-extracted :running-owner))
      (handoff-check-enqueue writer :kept 1 :schedule))
    (case fault
      (:idle-count
       (setf (arcdocdb.execution::coda-writer-count queue) 1
             (arcdocdb.execution::coda-writer-tail queue) 1
             (svref (arcdocdb.execution::coda-writer-slots queue) 0) :unexpected))
      ((:idle-owner :ready-owner)
       (setf (arcdocdb.execution::coda-writer-owner queue) sb-thread:*current-thread*))
      ((:idle-extracted :ready-extracted)
       (setf (arcdocdb.execution::coda-writer-extracted queue) 1))
      (:ready-count
       (setf (arcdocdb.execution::coda-writer-count queue) 0
             (arcdocdb.execution::coda-writer-tail queue) 0
             (svref (arcdocdb.execution::coda-writer-slots queue) 0) nil))
      (:running-owner
       (arcdocdb.execution:inizia-tratto-writer writer)
       (setf (arcdocdb.execution::coda-writer-owner queue) nil))
      (otherwise (error \"FI handoff sconosciuta: ~S\" fault)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-rejects-inconsistent-scheduling-states
  (dolist (fault '(:idle-count :idle-owner :idle-extracted :ready-count
                   :ready-owner :ready-extracted :running-owner))
    (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
           (queue (arcdocdb.execution::writer-programmabile-queue writer)))
      (handoff-fi-corrupt-state writer fault)
      (let ((before (handoff-fi-snapshot writer)))
        (with-execution-guard (queue)
          (signals arcdocdb.conditions:invariant-violation
            (arcdocdb.execution::%check-programmabile writer) :writer-scheduling))
        (signals arcdocdb.conditions:invariant-violation
          (arcdocdb.execution:accoda-lavoro-writer writer :refused) :writer-scheduling)
        (is (equalp before (handoff-fi-snapshot writer)))))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-handoff-helpers-require-current-thread-guard
  (let* ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
         (queue (arcdocdb.execution::writer-programmabile-queue writer))
         (before (handoff-fi-snapshot writer)) (threads nil))
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution::%check-programmabile writer) :writer-guard)
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution::%check-writer-inattivo queue) :writer-guard)
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution::%accoda-sotto-guard queue :refused) :writer-guard)
    (is (equalp before (handoff-fi-snapshot writer)))
    ;; FI: guard posseduta dal main; il thread estraneo deve rifiutare i tre helper.
    (unwind-protect
         (with-execution-guard (queue)
           (push (execution-thread
                  \"handoff foreign guard\"
                  (lambda ()
                    (signals arcdocdb.conditions:invariant-violation
                      (arcdocdb.execution::%check-programmabile writer) :writer-guard)
                    (signals arcdocdb.conditions:invariant-violation
                      (arcdocdb.execution::%check-writer-inattivo queue) :writer-guard)
                    (signals arcdocdb.conditions:invariant-violation
                      (arcdocdb.execution::%accoda-sotto-guard queue :refused) :writer-guard)
                    :ok)) threads)
           (execution-join (first threads))
           (is (equalp before (handoff-fi-snapshot writer))))
      (execution-stop-threads threads))
    (handoff-check-enqueue writer :kept 1 :schedule)
    (is (equal '(:kept) (handoff-drain writer 2)))))

(defstruct handoff-model
  (items nil) (state :idle) (remaining 0) (lease 0))

(defun handoff-model-enqueue (writer model item capacity)
  (if (= (length (handoff-model-items model)) capacity)
      (signals resource-exhausted (arcdocdb.execution:accoda-lavoro-writer writer item)
               :writer-queue-full)
      (let ((expected (if (eq (handoff-model-state model) :idle) :schedule :queued)))
        (setf (handoff-model-items model) (append (handoff-model-items model) (list item)))
        (handoff-check-enqueue writer item (length (handoff-model-items model)) expected)
        (when (eq expected :schedule) (setf (handoff-model-state model) :ready)))))

(defun handoff-model-begin (writer model quantum)
  (if (eq (handoff-model-state model) :ready)
      (let ((fresh (arcdocdb.execution:inizia-tratto-writer writer)))
        (is (> fresh (handoff-model-lease model)))
        (setf (handoff-model-lease model) fresh (handoff-model-state model) :running
              (handoff-model-remaining model) quantum))
      (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
               :writer-not-ready)))

(defun handoff-model-pop (writer model start span)
  (when (eq (handoff-model-state model) :running)
    (let* ((remaining (handoff-model-remaining model))
           (items (handoff-model-items model)) (n (min remaining span (length items)))
           (target (make-array (+ start span 2) :initial-element :untouched))
           (status (cond ((zerop remaining) :yield) ((zerop n) :empty) (t :messages))))
      (handoff-check-pop writer (handoff-model-lease model) target start (+ start span)
                         (subseq items 0 n) status)
      (setf (handoff-model-items model) (nthcdr n items))
      (decf (handoff-model-remaining model) n))))

(defun handoff-model-finish (writer model)
  (when (eq (handoff-model-state model) :running)
    (let ((expected (if (handoff-model-items model) :schedule :idle)))
      (is (eq expected (arcdocdb.execution:termina-tratto-writer
                        writer (handoff-model-lease model))))
      (setf (handoff-model-state model) (if (eq expected :schedule) :ready :idle)
            (handoff-model-remaining model) 0))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-001-handoff-seeded-list-and-scheduling-oracle
  (let ((seed #x9d670f42))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dotimes (scenario 9)
        (let* ((capacity (1+ (mod (ash (next) -8) 9)))
               (quantum (1+ (mod (ash (next) -8) 12)))
               (writer (arcdocdb.execution:crea-writer-programmabile
                        :capacity capacity :quantum quantum))
               (model (make-handoff-model)))
          (dotimes (step 800)
            (case (mod (ash (next) -8) 7)
              ((0 1) (handoff-model-enqueue writer model
                                            (if (zerop (mod step 7)) nil (vector scenario step))
                                            capacity))
              (2 (handoff-model-begin writer model quantum))
              ((3 4) (handoff-model-pop writer model (1+ (mod (next) 3))
                                        (1+ (mod (ash (next) -8) 7))))
              (5 (handoff-model-finish writer model))
              (6 (if (eq (handoff-model-state model) :ready)
                     (handoff-model-begin writer model quantum)
                     (handoff-model-finish writer model)))
              (otherwise (error \"Operazione dell'oracolo inattesa.\"))))
          (handoff-model-finish writer model)
          (if (handoff-model-items model)
              (is (equal (handoff-model-items model) (handoff-drain writer capacity)))
              (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                       :writer-not-ready)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-AFF-004
(deftest test-REQ-CON-001-handoff-foreign-thread-cannot-use-lease
  (let ((writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 2))
        (threads nil))
    (handoff-check-enqueue writer :original 1 :schedule)
    (unwind-protect
         (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
           (push (execution-thread
                  \"handoff foreign owner\"
                  (lambda ()
                    (let ((target (vector :untouched)))
                      (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                               :writer-not-ready)
                      (signals invalid-argument
                        (arcdocdb.execution:preleva-lavori-writer writer lease target 0 1)
                        :writer-lease)
                      (signals invalid-argument
                        (arcdocdb.execution:termina-tratto-writer writer lease) :writer-lease)
                      (is (equalp target #(:untouched)))
                      (handoff-check-enqueue writer :producer 2 :queued)
                      :ok))) threads)
           (execution-join (first threads))
           (handoff-check-pop writer lease (vector nil nil) 0 2 '(:original :producer) :messages)
           (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
      (execution-stop-threads threads))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-002-handoff-transfers-successive-slices-between-reused-threads
  (let* ((waves 4)
         (writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 1))
         (messages (make-array waves)) (first-go (sb-thread:make-semaphore))
         (second-go (sb-thread:make-semaphore)) (done (sb-thread:make-semaphore))
         (owners (make-array 2 :initial-element nil)) (threads nil))
    (dotimes (wave waves) (setf (svref messages wave) (list (vector wave 0) (vector wave 1))))
    (unwind-protect
         (progn
           (dotimes (worker 2)
             (let ((index worker))
               (push (execution-thread
                      \"handoff successive owner\"
                      (lambda ()
                        (setf (svref owners index) sb-thread:*current-thread*)
                        (dotimes (wave waves)
                          (execution-wait (if (zerop index) first-go second-go))
                          (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
                            (handoff-check-pop writer lease (vector :untouched) 0 1
                                               (list (nth index (svref messages wave))) :messages)
                            (is (eq (if (zerop index) :schedule :idle)
                                    (arcdocdb.execution:termina-tratto-writer writer lease))))
                          (sb-thread:signal-semaphore (if (zerop index) second-go done)))
                        :ok)) threads)))
           (dotimes (wave waves)
             (handoff-check-enqueue writer (first (svref messages wave)) 1 :schedule)
             (handoff-check-enqueue writer (second (svref messages wave)) 2 :queued)
             (sb-thread:signal-semaphore first-go)
             (execution-wait done))
           (dolist (thread threads) (execution-join thread))
           (is (not (eq (svref owners 0) (svref owners 1))))
           (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer writer)
                    :writer-not-ready))
      (sb-thread:signal-semaphore first-go)
      (sb-thread:signal-semaphore second-go)
      (execution-stop-threads threads))))

(defun handoff-wave-items (series wave)
  \"Identità e CRC atteso costruiti prima dei thread, lista nell'ordine accettato.\"
  (loop for sequence below 3
        for buffer = (execution-buffer 256 (+ (* series 31) (* wave 7) sequence))
        collect (vector series wave sequence buffer (reference-crc buffer 0 (length buffer)))))

(defun handoff-wave-producer (writer messages permission published second-permission second-published)
  (dotimes (wave (length messages))
    (let ((items (svref messages wave)))
      (execution-wait permission)
      (handoff-check-enqueue writer (first items) 1 :schedule)
      (handoff-check-enqueue writer (second items) 2 :queued)
      (sb-thread:signal-semaphore published)
      (execution-wait second-permission)
      (handoff-check-enqueue writer (third items) 2 :queued)
      (sb-thread:signal-semaphore second-published)))
  :ok)

(defun handoff-wave-check-message (writer lease expected)
  (let ((target (vector :left :untouched :right)))
    (handoff-check-pop writer lease target 1 2 (list expected) :messages)
    (is (= (svref expected 4)
           (reference-crc (svref (svref target 1) 3) 0 256)))))

(defun handoff-wave-consumer (writer messages permission taken finish drained results)
  (dotimes (wave (length messages))
    (execution-wait permission)
    (let* ((items (svref messages wave)) (lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-wave-check-message writer lease (first items))
      (handoff-check-pop writer lease (vector :untouched) 0 1 nil :yield)
      (sb-thread:signal-semaphore taken)
      (execution-wait finish)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (loop for item in (rest (svref messages wave)) for last = (eq item (third (svref messages wave)))
          do (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
               (handoff-wave-check-message writer lease item)
               (is (eq (if last :idle :schedule)
                       (arcdocdb.execution:termina-tratto-writer writer lease)))))
    (setf (svref results wave) :verified)
    (sb-thread:signal-semaphore drained))
  :ok)

(defun handoff-semaphore-pair ()
  (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))

(defun handoff-pair-signal (pair)
  (dotimes (i 2) (sb-thread:signal-semaphore (svref pair i))))

(defun handoff-pair-wait (pair)
  (dotimes (i 2) (execution-wait (svref pair i))))

(defun handoff-start-four-workers (writers messages semaphores results)
  (let ((threads nil))
    (dotimes (series 2 threads)
      (let ((s series))
        (push (execution-thread
               \"handoff reused producer\"
               (lambda ()
                 (handoff-wave-producer
                  (svref writers s) (svref messages s)
                  (svref (svref semaphores 0) s) (svref (svref semaphores 1) s)
                  (svref (svref semaphores 4) s) (svref (svref semaphores 5) s)))) threads)
        (push (execution-thread
               \"handoff reused consumer\"
               (lambda ()
                 (handoff-wave-consumer
                  (svref writers s) (svref messages s)
                  (svref (svref semaphores 2) s) (svref (svref semaphores 3) s)
                  (svref (svref semaphores 6) s) (svref (svref semaphores 7) s)
                  (svref results s)))) threads)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-003-handoff-reuses-four-workers-across-independent-series-waves
  (let* ((waves 6)
         (writers (vector (arcdocdb.execution:crea-writer-programmabile :capacity 4 :quantum 1)
                          (arcdocdb.execution:crea-writer-programmabile :capacity 4 :quantum 1)))
         (messages (vector (make-array waves) (make-array waves)))
         (results (vector (make-array waves :initial-element nil)
                          (make-array waves :initial-element nil)))
         (semaphores (make-array 8)) (threads nil))
    (dotimes (i 8) (setf (svref semaphores i) (handoff-semaphore-pair)))
    (dotimes (series 2)
      (dotimes (wave waves)
        (setf (svref (svref messages series) wave) (handoff-wave-items series wave))))
    (unwind-protect
         (progn
           (setf threads (handoff-start-four-workers writers messages semaphores results))
           (is (= 4 (length threads)))
           (dotimes (wave waves)
             (handoff-pair-signal (svref semaphores 0))
             (handoff-pair-wait (svref semaphores 1))
             (handoff-pair-signal (svref semaphores 2))
             (handoff-pair-wait (svref semaphores 3))
             (handoff-pair-signal (svref semaphores 4))
             (handoff-pair-wait (svref semaphores 5))
             ;; FI: A conserva guard e lease; B termina due tratti aggiuntivi.
             (let ((queue-a (arcdocdb.execution::writer-programmabile-queue (svref writers 0))))
               (with-execution-guard (queue-a)
                 (sb-thread:signal-semaphore (svref (svref semaphores 6) 1))
                 (execution-wait (svref (svref semaphores 7) 1))
                 (is (eq :verified (svref (svref results 1) wave)))))
             (sb-thread:signal-semaphore (svref (svref semaphores 6) 0))
             (execution-wait (svref (svref semaphores 7) 0))
             (is (eq :verified (svref (svref results 0) wave))))
           (dolist (thread threads) (execution-join thread))
           (dotimes (series 2)
             (is (every (lambda (result) (eq result :verified)) (svref results series)))
             (signals resource-exhausted
               (arcdocdb.execution:inizia-tratto-writer (svref writers series)) :writer-not-ready))
           (format t \"  Handoff: 4 thread riusati, ~D ondate, ~D messaggi, 2 Serie indipendenti.~%\"
                   waves (* waves 2 3)))
      (dotimes (i 8) (handoff-pair-signal (svref semaphores i)))
      (execution-stop-threads threads))))
")))
