(:SCHEMA-VERSION 1 :KIND :C1-REVIEW :ROLE :AUTHOR :SCOPE :WRITER-READY
 :BASE-COMMIT "33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691"
 :RECORDED-AT-UNIVERSAL-TIME 4000523537 :STATUS :REVIEWED-LOCAL :REVIEW-POINTS
 12 :OPEN-FINDINGS NIL :SOURCES
 ((:PATH "arcdocdb.asd" :BYTES 5198 :SHA256
   "6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc" :GIT-BLOB
   "b309d3b475a52063d3eb8d948027fbcbbb6ba933" :TEXT
   ";;;; arcdocdb.asd — definizione di sistema ASDF.
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
                :components ((:file \"package\") (:file \"utf8\")
                             (:file \"cbor-package\") (:file \"cbor-header\")))
               (:module \"csn\" :serial t
                :components ((:file \"package\") (:file \"registry\")))
               (:module \"execution\" :serial t
                :components ((:file \"package\") (:file \"queue\") (:file \"writer\")
                             (:file \"handoff\") (:file \"ready-types\") (:file \"ready\")))
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
                             (:file \"decisions-query\")
                             (:file \"manifest-package\") (:file \"manifest-types\")
                             (:file \"manifest-decode\") (:file \"manifest-fold\")
                             (:file \"manifest-build\") (:file \"manifest-query\"))))
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
                :components ((:file \"support\") (:file \"utf8\") (:file \"threads\")
                             (:file \"cbor-support\") (:file \"cbor-header\") (:file \"cbor-threads\")))
               (:module \"csn\" :serial t
                :components ((:file \"support\") (:file \"registry\") (:file \"threads\")))
               (:module \"execution\" :serial t
                :components ((:file \"support\") (:file \"queue\") (:file \"threads\")
                             (:file \"handoff\") (:file \"ready\")))
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
                             (:file \"decisions-audit\") (:file \"decisions-radix\") (:file \"manifest-support\")
                             (:file \"manifest\") (:file \"manifest-audit\")))
               (:module \"wal\" :serial t
                :components ((:file \"support\") (:file \"builder\") (:file \"group\") (:file \"fault\")
                             (:file \"native\"))))
  :perform (test-op (o c)
             (uiop:symbol-call '#:arcdocdb.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.foundation.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.utf8.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.cbor.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.csn.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.execution.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.storage.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.io.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.recovery.tests '#:run)
             (uiop:symbol-call '#:arcdocdb.wal.tests '#:run)))
")
  (:PATH "src/execution/package.lisp" :BYTES 771 :SHA256
   "97704f44544084b6823924a48724f4fc54fdbda60df1b0891c5066afaf183af8" :GIT-BLOB
   "c5144c7752d1b21e9d09f86d0f1fe4d8acc979be" :TEXT
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
           #:inizia-tratto-writer #:preleva-lavori-writer #:termina-tratto-writer
           #:lista-writer-pronti #:crea-lista-writer-pronti
           #:pubblica-writer-pronto #:preleva-writer-pronto))
")
  (:PATH "src/execution/queue.lisp" :BYTES 5374 :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90" :GIT-BLOB
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
  (:PATH "src/execution/writer.lisp" :BYTES 6484 :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105" :GIT-BLOB
   "8e5102497f628796fa8faffa2085a165496af230" :TEXT
   ";;;; Lease locale del writer; la quota limita ogni acquisizione, non la capacità.
;;; OWNER: generation/extracted solo dal writer con lease corrente; CAS owner separato.
;;; SHARED: payload dalla coda al consumatore solo dopo prelievo, nessun callback.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) null) %check-lease))
(defun %check-lease (queue lease)
  \"Pre: token opaco fornito dal chiamante. Post: thread/generation correnti e quota valida.
INVALID-ARGUMENT per token stale, errato o altro thread; INVARIANT-VIOLATION per quota.\"
  (unless (and (typep lease 'index) (plusp lease)
               (eq (coda-writer-owner queue) sb-thread:*current-thread*)
               (= lease (coda-writer-generation queue)))
    (error 'invalid-argument :reason :writer-lease))
  (unless (and (<= 1 (coda-writer-quantum queue) +max-writer-quantum+)
               (<= (coda-writer-extracted queue) (coda-writer-quantum queue)))
    (error 'invariant-violation :reason :writer-owner))
  nil)

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer sb-thread:thread) null) %libera-owner))
(defun %libera-owner (queue thread)
  \"Pre: THREAD possiede owner, campi della lease già finalizzati. Post: owner libero.
Un solo CAS; INVARIANT-VIOLATION al guasto, fail-stop del chiamante senza retry.\"
  (unless (eq (coda-writer-owner queue) thread)
    (error 'invariant-violation :reason :writer-owner))
  (unless (eq (sb-ext:compare-and-swap (coda-writer-owner queue) thread nil) thread)
    (error 'invariant-violation :reason :writer-owner))
  nil)

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer) index) acquisisci-writer))
(defun acquisisci-writer (queue)
  \"Pre: chiamante richiede una nuova lease. Post: generation positiva, quota nuova;
RESOURCE-EXHAUSTED per writer busy o generation esaurita. Overflow non incrementa
né cambia extracted e libera il CAS acquisito; nessun wrap, callback o scheduling.\"
  (let ((thread sb-thread:*current-thread*) (committed nil))
    (unless (null (sb-ext:compare-and-swap (coda-writer-owner queue) nil thread))
      (error 'resource-exhausted :reason :writer-busy))
    (unwind-protect
         (progn
           (unless (and (eq (coda-writer-owner queue) thread)
                        (zerop (coda-writer-extracted queue)))
             (error 'invariant-violation :reason :writer-owner))
           (when (= (coda-writer-generation queue) most-positive-fixnum)
             (error 'resource-exhausted :reason :writer-generation))
           (incf (coda-writer-generation queue))
           (setf committed t)
           (coda-writer-generation queue))
      (unless committed (%libera-owner queue thread)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (coda-writer t t t)
                         (values simple-vector index index &optional)) %check-target))
(defun %check-target (queue target start end)
  \"Pre: destinazione del consumatore e range dichiarato. Post: SIMPLE-VECTOR e indici
non vuoti validati prima del ring; INVALID-ARGUMENT per alias, tipo o range errati.\"
  (unless (and (typep target 'simple-vector) (not (eq target (coda-writer-slots queue))))
    (error 'invalid-argument :reason :writer-target))
  (unless (and (typep start 'index) (typep end 'index) (< start end) (<= end (length target)))
    (error 'invalid-argument :reason :writer-target))
  (values target (the index start) (the index end)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t t t t)
                         (values index (member :messages :empty :yield) &optional)) preleva-messaggi))
(defun preleva-messaggi (queue lease target start end)
  \"Pre: lease del thread corrente e destinazione privata non alias degli slots.
Post: FIFO fino a MIN(count, range, quota), slots liberati, ownership al consumatore;
fuori dai messaggi copiati target invariato. :YIELD senza lavoro sul ring a quota zero,
:EMPTY se vuoto, :MESSAGES dopo copia. INVALID-ARGUMENT per lease/target, RESOURCE-
EXHAUSTED per guard busy; errori interni impongono fail-stop al chiamante.\"
  (%check-lease queue lease)
  (multiple-value-bind (destination first limit) (%check-target queue target start end)
    (let ((remaining (- (coda-writer-quantum queue) (coda-writer-extracted queue))))
      (declare (type index remaining))
      (when (zerop remaining) (return-from preleva-messaggi (values 0 :yield)))
      (let ((thread (%acquisisci-guard queue)))
        (unwind-protect
             (progn
               (%check-queue queue)
               (let* ((count (coda-writer-count queue))
                      (taken (min count (- limit first) remaining))
                      (cursor (coda-writer-head queue))
                      (extracted (coda-writer-extracted queue))
                      (slots (coda-writer-slots queue)) (capacity (coda-writer-capacity queue)))
                 (declare (type index count taken cursor extracted capacity))
                 (dotimes (i taken)
                   (setf (svref destination (+ first i)) (svref slots cursor)
                         (svref slots cursor) nil
                         cursor (mod (1+ cursor) capacity)))
                 (setf (coda-writer-head queue) cursor (coda-writer-count queue) (- count taken)
                       (coda-writer-extracted queue) (+ extracted taken))
                 (%check-queue queue)
                 (unless (and (<= taken remaining)
                              (<= (coda-writer-extracted queue) (coda-writer-quantum queue)))
                   (error 'invariant-violation :reason :writer-owner))
                 (values taken (if (zerop taken) :empty :messages))))
          (%rilascia-guard queue thread))))))

;;; REQ: REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer t) null) rilascia-writer))
(defun rilascia-writer (queue lease)
  \"Pre: lease corrente del thread proprietario. Post: quota azzerata prima del CAS owner
verso NIL, generation conservata. INVALID-ARGUMENT per token errato/stale/altro thread;
INVARIANT-VIOLATION al guasto. Nessun ready, wakeup, callback o controller implicito.\"
  (%check-lease queue lease)
  (setf (coda-writer-extracted queue) 0)
  (%libera-owner queue sb-thread:*current-thread*))
")
  (:PATH "src/execution/handoff.lisp" :BYTES 7394 :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607" :GIT-BLOB
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
  (:PATH "src/execution/ready-types.lisp" :BYTES 5248 :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f" :GIT-BLOB
   "5b3c26f78d5c4aa53ca200abdd3e0f753f926b54" :TEXT
   ";;;; Lista pronta partizionata: nessun contatore comune fra i ring.
;;; OWNER: scheduler dell'Archivio; ogni partizione possiede indici e slots.
;;; SHARED: lista Serie pronte (ADR-0045 §8), solo pubblicazione/prelievo per tratto.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defconstant +max-partizioni-pronte+ 64)
;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defconstant +max-capacita-pronta+ 65536)

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (partizione-pronta (:constructor %make-partizione-pronta (slots capacity))
                             (:copier nil))
  \"Pre: ring privato preallocato e capacity bounded. Post: vuoto, guard libera.
Slots/indici sono mutati soltanto dal proprietario della guard locale.\"
  (slots #() :type simple-vector :read-only t)
  (capacity 1024 :type index :read-only t)
  (head 0 :type index) (tail 0 :type index) (count 0 :type index)
  (guard nil :type (or null sb-thread:thread)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (lista-writer-pronti (:constructor %make-lista-writer-pronti (partitions))
                              (:copier nil))
  \"Pre: partizioni private, indipendenti e bounded. Post: lista pronta vuota.
Non deduplica obblighi :SCHEDULE né governa stato o risvegli dei worker.\"
  (partitions #() :type simple-vector :read-only t))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta) null) %check-forma-pronta))
(defun %check-forma-pronta (partition)
  \"Pre: ring appena creato oppure guard posseduta. Post: forma e FIFO coerenti.
INVARIANT-VIOLATION per limiti, indici o relazione head/count/tail errati.\"
  (let ((capacity (partizione-pronta-capacity partition)))
    (unless (<= 1 capacity +max-capacita-pronta+)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (= (length (partizione-pronta-slots partition)) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (< (partizione-pronta-head partition) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (< (partizione-pronta-tail partition) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (<= (partizione-pronta-count partition) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (= (partizione-pronta-tail partition)
               (mod (+ (partizione-pronta-head partition)
                       (partizione-pronta-count partition)) capacity))
      (error 'invariant-violation :reason :ready-queue-invariant)))
  nil)

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta) null) %check-pronta))
(defun %check-pronta (partition)
  \"Pre: guard locale acquisita. Post: proprietario corrente e forma valida.
INVARIANT-VIOLATION per guard estranea o incoerenza interna.\"
  (unless (eq (partizione-pronta-guard partition) sb-thread:*current-thread*)
    (error 'invariant-violation :reason :ready-queue-guard))
  (%check-forma-pronta partition))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t) partizione-pronta) %partizione-verificata))
(defun %partizione-verificata (ready shard)
  \"Pre: lista costruita con la factory. Post: partizione dell'indice verificato.
INVALID-ARGUMENT per indice errato; INVARIANT-VIOLATION per lista privata invalida.\"
  (let ((partitions (lista-writer-pronti-partitions ready)))
    (unless (<= 1 (length partitions) +max-partizioni-pronte+)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (typep shard 'index) (error 'invalid-argument :reason :ready-target))
    (unless (< shard (length partitions)) (error 'invalid-argument :reason :ready-target))
    (let ((partition (svref partitions shard)))
      (unless (typep partition 'partizione-pronta)
        (error 'invariant-violation :reason :ready-queue-invariant))
      partition)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (&key (:shards t) (:capacity t)) lista-writer-pronti)
                crea-lista-writer-pronti))
(defun crea-lista-writer-pronti (&key (shards 4) (capacity 1024))
  \"Pre: shards 1..64, capacity per ring 1..65536. Post: ring privati preallocati.
INVALID-ARGUMENT per budget errati; nessuna allocazione sul percorso normale per compito.\"
  (unless (typep shards 'index) (error 'invalid-argument :reason :ready-configuration))
  (unless (<= 1 shards +max-partizioni-pronte+)
    (error 'invalid-argument :reason :ready-configuration))
  (unless (typep capacity 'index) (error 'invalid-argument :reason :ready-configuration))
  (unless (<= 1 capacity +max-capacita-pronta+)
    (error 'invalid-argument :reason :ready-configuration))
  (let ((partitions (make-array shards :initial-element nil)))
    (dotimes (i shards)
      (let ((partition (%make-partizione-pronta
                        (make-array capacity :initial-element nil) capacity)))
        (%check-forma-pronta partition)
        (setf (svref partitions i) partition)))
    (let ((ready (%make-lista-writer-pronti partitions)))
      (%partizione-verificata ready 0)
      ready)))
")
  (:PATH "src/execution/ready.lisp" :BYTES 6635 :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327" :GIT-BLOB
   "4119f86231b7d8698fc3558868ff8a5bcbdf3090" :TEXT
   ";;;; Passaggi degli obblighi :schedule; nessuno stato membership o cleanup writer.
;;; OWNER: obbligo al chiamante prima di publish, al ring, poi al worker dopo pop.
;;; SHARED: lista Serie pronte (ADR-0045 §8), una pubblicazione/prelievo per tratto.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta) (or null sb-thread:thread)) %prendi-guard-pronta))
(defun %prendi-guard-pronta (partition)
  \"Pre: accesso breve al ring. Post: guard del thread corrente oppure NIL se busy.
Un solo CAS, nessuna attesa; INVARIANT-VIOLATION al guasto della proprietà.\"
  (let ((thread sb-thread:*current-thread*))
    (unless (null (sb-ext:compare-and-swap (partizione-pronta-guard partition) nil thread))
      (return-from %prendi-guard-pronta nil))
    (unless (eq (partizione-pronta-guard partition) thread)
      (error 'invariant-violation :reason :ready-queue-guard))
    thread))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta sb-thread:thread) null) %rilascia-guard-pronta))
(defun %rilascia-guard-pronta (partition thread)
  \"Pre: guard posseduta da THREAD. Post: guard libera con un CAS verificato.
INVARIANT-VIOLATION per proprietà errata; nessun retry o recupero implicito.\"
  (unless (eq (partizione-pronta-guard partition) thread)
    (error 'invariant-violation :reason :ready-queue-guard))
  (unless (eq (sb-ext:compare-and-swap (partizione-pronta-guard partition) thread nil) thread)
    (error 'invariant-violation :reason :ready-queue-guard))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta writer-programmabile) index) %pubblica-pronto))
(defun %pubblica-pronto (partition writer)
  \"Pre: guard corrente e obbligo unico del chiamante. Post: una accettazione FIFO.
RESOURCE-EXHAUSTED se full prima della mutazione; INVARIANT-VIOLATION al guasto.\"
  (%check-pronta partition)
  (when (= (partizione-pronta-count partition) (partizione-pronta-capacity partition))
    (error 'resource-exhausted :reason :ready-queue-full))
  (let ((tail (partizione-pronta-tail partition)))
    (unless (null (svref (partizione-pronta-slots partition) tail))
      (error 'invariant-violation :reason :ready-queue-invariant))
    (setf (svref (partizione-pronta-slots partition) tail) writer
          (partizione-pronta-tail partition) (mod (1+ tail) (partizione-pronta-capacity partition))
          (partizione-pronta-count partition) (1+ (partizione-pronta-count partition))))
  (%check-pronta partition)
  (partizione-pronta-count partition))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta)
                         (values (or null writer-programmabile) (member :writer :empty) &optional))
                %preleva-pronto))
(defun %preleva-pronto (partition)
  \"Pre: guard corrente. Post: riferimento FIFO al worker, slot liberato; NIL/:EMPTY
se vuoto. INVARIANT-VIOLATION per forma o payload incoerente, fail-stop del chiamante.\"
  (%check-pronta partition)
  (when (zerop (partizione-pronta-count partition))
    (return-from %preleva-pronto (values nil :empty)))
  (let* ((head (partizione-pronta-head partition))
         (writer (svref (partizione-pronta-slots partition) head)))
    (unless (typep writer 'writer-programmabile)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (setf (svref (partizione-pronta-slots partition) head) nil
          (partizione-pronta-head partition) (mod (1+ head) (partizione-pronta-capacity partition))
          (partizione-pronta-count partition) (1- (partizione-pronta-count partition)))
    (%check-pronta partition)
    (values writer :writer)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t t) index) pubblica-writer-pronto))
(defun pubblica-writer-pronto (ready shard writer)
  \"Pre: un unico obbligo :SCHEDULE da pubblicare una sola volta. Post: count locale,
obbligo al ring. INVALID-ARGUMENT per shard/writer; RESOURCE-EXHAUSTED full/busy
conserva obbligo al chiamante. Il retry non accetta nuovamente i payload nel writer.\"
  (let ((partition (%partizione-verificata ready shard)))
    (unless (typep writer 'writer-programmabile)
      (error 'invalid-argument :reason :ready-writer))
    (let ((thread (%prendi-guard-pronta partition)))
      (unless thread (error 'resource-exhausted :reason :ready-queue-busy))
      (unwind-protect (%pubblica-pronto partition writer)
        (%rilascia-guard-pronta partition thread)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta)
                         (values (or null writer-programmabile) (member :writer :empty :busy) &optional))
                %prova-pronta))
(defun %prova-pronta (partition)
  \"Pre: una partizione candidata. Post: writer/empty dal ring oppure NIL/:BUSY.
Un CAS senza spin; cleanup dopo acquisizione verificata, invarianti fail-stop.\"
  (let ((thread (%prendi-guard-pronta partition)))
    (unless thread (return-from %prova-pronta (values nil :busy)))
    (unwind-protect (%preleva-pronto partition)
      (%rilascia-guard-pronta partition thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t)
                         (values (or null writer-programmabile) (member :writer :empty :busy) index &optional))
                preleva-writer-pronto))
(defun preleva-writer-pronto (ready start)
  \"Pre: start indice valido. Post: al più K tentativi circolari; writer/:WRITER e
cursore seguente alla partizione servita, oppure NIL e :BUSY/:EMPTY con start+1.
EMPTY sono osservazioni locali, non quiescenza globale; un worker conserva il
riferimento fino all'avvio riuscito. INVALID-ARGUMENT indice; invarianti fail-stop.\"
  (%partizione-verificata ready start)
  (let* ((size (length (lista-writer-pronti-partitions ready)))
         (cursor (the index start)) (busy nil))
    (dotimes (i size)
      (multiple-value-bind (writer status) (%prova-pronta (%partizione-verificata ready cursor))
        (case status
          (:writer (return-from preleva-writer-pronto
                     (values writer :writer (mod (1+ cursor) size))))
          (:busy (setf busy t))
          (:empty nil)
          (otherwise (error 'invariant-violation :reason :ready-queue-invariant))))
      (setf cursor (mod (1+ cursor) size)))
    (values nil (if busy :busy :empty) (mod (1+ (the index start)) size))))
")
  (:PATH "tests/execution/ready.lisp" :BYTES 33555 :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e" :GIT-BLOB
   "9f81552333f86fe0b20f2d5e8ba48b20634f5a09" :TEXT
   ";;;; Liste FIFO indipendenti; i writer sono riferimenti opachi per la lista pronta.
;;;; Ogni riferimento delle prove pubbliche viene da :schedule ed è completato.
;;;; I semafori appartengono solo alla fixture e hanno timeout tramite execution-wait.
(in-package #:arcdocdb.execution.tests)

(defun ready-test-writer ()
  (arcdocdb.execution:crea-writer-programmabile :capacity 3 :quantum 1))

(defun ready-prepare-fixture-writer (&optional (writer (ready-test-writer)))
  \"Un unico payload corrisponde a un obbligo :schedule del writer idle.\"
  (handoff-check-enqueue writer :ready-fixture 1 :schedule)
  writer)

(defun ready-complete-fixture-writer (writer)
  \"Consuma un obbligo dell'oracolo pubblico; il writer torna idle prima del riuso.\"
  (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
    (handoff-check-pop writer lease (vector nil) 0 1 '(:ready-fixture) :messages)
    (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease)))))

(defun ready-check-publish (ready shard writer expected-count)
  (is (= expected-count (arcdocdb.execution:pubblica-writer-pronto ready shard writer))))

(defun ready-check-take (ready start expected expected-status expected-next)
  (multiple-value-bind (writer status next)
      (arcdocdb.execution:preleva-writer-pronto ready start)
    (is (eq writer expected))
    (is (eq status expected-status))
    (is (= next expected-next))
    next))

(defun ready-check-complete-take (ready start expected expected-status expected-next)
  (let ((next (ready-check-take ready start expected expected-status expected-next)))
    (when expected (ready-complete-fixture-writer expected))
    next))

(defun ready-model-publish (ready model shard writer capacity)
  (let ((items (svref model shard)))
    (if (= (length items) capacity)
        (signals resource-exhausted
          (arcdocdb.execution:pubblica-writer-pronto ready shard writer) :ready-queue-full)
        (progn
          (ready-check-publish ready shard writer (1+ (length items)))
          (setf (svref model shard) (append items (list writer)))
          t))))

(defun ready-model-take (ready model start &optional busy-shards)
  \"Primo riferimento nelle liste FIFO, senza leggere indici/count del prodotto.\"
  (let ((shards (length model)))
    (dotimes (distance shards)
      (let* ((shard (mod (+ start distance) shards)) (items (svref model shard)))
        (when (and items (not (member shard busy-shards)))
          (setf (svref model shard) (rest items))
          (return-from ready-model-take
            (values (ready-check-complete-take ready start (first items) :writer
                                              (mod (1+ shard) shards))
                    (first items))))))
    (values (ready-check-take ready start nil (if busy-shards :busy :empty)
                             (mod (1+ start) shards)) nil)))

(defun ready-test-partition (ready shard)
  \"Accessor privato usato solo per FI, mai per l'oracolo FIFO.\"
  (svref (arcdocdb.execution::lista-writer-pronti-partitions ready) shard))

(defun ready-call-with-guards (partitions thunk)
  \"FI: un CAS per guard, rilascio anche se un'asserzione della fixture fallisce.\"
  (let ((thread sb-thread:*current-thread*) (owned nil))
    (unwind-protect
         (progn
           (dolist (partition partitions)
             (is (null (sb-ext:compare-and-swap
                        (arcdocdb.execution::partizione-pronta-guard partition) nil thread)))
             (push partition owned))
           (funcall thunk))
      (dolist (partition owned)
        (is (eq thread (sb-ext:compare-and-swap
                        (arcdocdb.execution::partizione-pronta-guard partition) thread nil)))))))

(defun ready-fi-snapshot (partition)
  \"Immagine per rifiuti/FI, senza usarla come ordine FIFO atteso.\"
  (list (arcdocdb.execution::partizione-pronta-head partition)
        (arcdocdb.execution::partizione-pronta-tail partition)
        (arcdocdb.execution::partizione-pronta-count partition)
        (arcdocdb.execution::partizione-pronta-guard partition)
        (copy-seq (arcdocdb.execution::partizione-pronta-slots partition))))

(defun ready-pool-publish (ready model writers phases homes index shard capacity)
  \"Pool dell'oracolo: full conserva pending; published non viene ripubblicato.\"
  (case (svref phases index)
    (:idle
     (ready-prepare-fixture-writer (svref writers index))
     (setf (svref phases index) :pending (svref homes index) shard))
    (:pending nil)
    (:published (return-from ready-pool-publish nil))
    (otherwise (error \"Fase dell'oracolo pronta inattesa.\")))
  (when (ready-model-publish ready model (svref homes index) (svref writers index) capacity)
    (setf (svref phases index) :published)))

(defun ready-pool-take (ready model writers phases start)
  (multiple-value-bind (next writer) (ready-model-take ready model start)
    (when writer
      (let ((index (position writer writers :test #'eq)))
        (is index)
        (is (eq (svref phases index) :published))
        (setf (svref phases index) :idle)))
    next))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-AFF-008-ready-configuration-and-limits
  (dolist (bad '(0 -1 65 nil 2.0))
    (signals invalid-argument
      (arcdocdb.execution:crea-lista-writer-pronti :shards bad :capacity 3)
      :ready-configuration))
  (dolist (bad '(0 -1 65537 nil 2.0))
    (signals invalid-argument
      (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity bad)
      :ready-configuration))
  (dolist (limits '((1 65536) (64 1)))
    (let ((ready (arcdocdb.execution:crea-lista-writer-pronti
                  :shards (first limits) :capacity (second limits)))
          (writer (ready-test-writer)))
      (dotimes (shard (first limits))
        (ready-prepare-fixture-writer writer)
        (ready-check-publish ready shard writer 1)
        (ready-check-complete-take ready shard writer :writer
                                   (mod (1+ shard) (first limits))))))
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti)) (writers (make-array 1025)))
    (dotimes (i 1025) (setf (svref writers i) (ready-prepare-fixture-writer)))
    (dotimes (i 1024) (ready-check-publish ready 3 (svref writers i) (1+ i)))
    (signals resource-exhausted
      (arcdocdb.execution:pubblica-writer-pronto ready 3 (svref writers 1024)) :ready-queue-full)
    (ready-check-complete-take ready 0 (svref writers 0) :writer 0)
    (ready-check-publish ready 3 (svref writers 1024) 1024)
    (loop for i from 1 below 1025
          do (ready-check-complete-take ready 0 (svref writers i) :writer 0))
    (ready-check-take ready 3 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-shard-and-writer-preflight
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 2))
        (writer (ready-prepare-fixture-writer)))
    (ready-check-publish ready 1 writer 1)
    (dolist (bad (list -1 3 nil 1.0 (1+ most-positive-fixnum)))
      (signals invalid-argument (arcdocdb.execution:pubblica-writer-pronto ready bad writer)
               :ready-target)
      (signals invalid-argument (arcdocdb.execution:preleva-writer-pronto ready bad)
               :ready-target))
    (dolist (bad (list nil :writer (vector :writer) (arcdocdb.execution:crea-coda-writer)))
      (signals invalid-argument (arcdocdb.execution:pubblica-writer-pronto ready 1 bad)
               :ready-writer))
    (ready-check-complete-take ready 0 writer :writer 2)
    (ready-check-take ready 2 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-004
(deftest test-REQ-CON-001-ready-per-shard-fifo-wrap-and-private-opaque-ring
  (dolist (shards '(1 2 3 7))
    (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards shards :capacity 3))
          (model (make-array shards :initial-element nil)) (cursor 0))
      (dotimes (round 31)
        (dotimes (shard shards)
          (loop repeat (- 3 (length (svref model shard)))
                do (ready-model-publish ready model shard (ready-prepare-fixture-writer) 3)))
        (dotimes (i shards) (setf cursor (ready-model-take ready model cursor))))
      (loop repeat (* 3 shards) do (setf cursor (ready-model-take ready model cursor)))
      (is (every #'null model))))
  ;; FI di ring isolato, fuori dal protocollo handoff: nessuna membership/dedup.
  (let ((partition (arcdocdb.execution::%make-partizione-pronta (vector nil nil) 2))
        (writer (ready-test-writer)))
    (ready-call-with-guards
     (list partition)
     (lambda ()
       (is (= 1 (arcdocdb.execution::%pubblica-pronto partition writer)))
       (is (= 2 (arcdocdb.execution::%pubblica-pronto partition writer)))
       (dotimes (i 2)
         (multiple-value-bind (actual status) (arcdocdb.execution::%preleva-pronto partition)
           (is (eq actual writer)) (is (eq status :writer))))
       (multiple-value-bind (actual status) (arcdocdb.execution::%preleva-pronto partition)
         (is (null actual)) (is (eq status :empty)))))))

;;; REQ: REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-004-ready-cursor-rotates-first-choice-and-empty-scan
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 2))
         (writers (make-array 6))
         (cursor 0))
    (dotimes (i 6) (setf (svref writers i) (ready-prepare-fixture-writer)))
    (dotimes (shard 3)
      (dotimes (i 2) (ready-check-publish ready shard (svref writers (+ (* shard 2) i)) (1+ i))))
    (dotimes (turn 6)
      (let ((shard (mod turn 3)))
        (setf cursor (ready-check-complete-take ready cursor
                                               (svref writers (+ (* shard 2) (floor turn 3)))
                                               :writer (mod (1+ shard) 3)))))
    (dotimes (turn 6)
      (let ((next (mod (1+ cursor) 3)))
        (setf cursor (ready-check-take ready cursor nil :empty next))))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-001-ready-seeded-independent-lists-and-cursors
  (let ((seed #x7213bc08))
    (flet ((next () (setf seed (logand #xffffffff (+ (* seed 1664525) 1013904223)))))
      (dotimes (scenario 9)
        (let* ((shards (1+ (mod (ash (next) -8) 7)))
               (capacity (1+ (mod (ash (next) -8) 9)))
               (ready (arcdocdb.execution:crea-lista-writer-pronti
                       :shards shards :capacity capacity))
               (model (make-array shards :initial-element nil))
               (writers (make-array 11)) (phases (make-array 11 :initial-element :idle))
               (homes (make-array 11 :initial-element 0)) (cursor 0))
          (dotimes (i 11) (setf (svref writers i) (ready-test-writer)))
          (dotimes (step 1000)
            (if (< (mod (ash (next) -8) 5) 3)
                (ready-pool-publish ready model writers phases homes
                                    (mod (ash (next) -8) 11) (mod (ash (next) -8) shards) capacity)
                (setf cursor (ready-pool-take ready model writers phases
                                              (if (evenp step) cursor
                                                  (mod (ash (next) -8) shards))))))
          (loop repeat (* shards capacity)
                do (setf cursor (ready-pool-take ready model writers phases cursor)))
          (is (every #'null model))
          (dotimes (i 11)
            (when (eq (svref phases i) :pending)
              (ready-pool-publish ready model writers phases homes i (svref homes i) capacity)
              (is (eq (svref phases i) :published))
              (setf cursor (ready-pool-take ready model writers phases (svref homes i)))))
          (is (every (lambda (phase) (eq phase :idle)) phases)))))))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-ready-full-preserves-scheduling-obligation
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
        (blocker (ready-prepare-fixture-writer)) (writer (ready-test-writer)) (target (vector nil nil)))
    (ready-check-publish ready 0 blocker 1)
    (multiple-value-bind (count pending) (arcdocdb.execution:accoda-lavoro-writer writer :a)
      (is (= count 1)) (is (eq pending :schedule))
      (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)
               :ready-queue-full)
      (is (eq pending :schedule))
      (handoff-check-enqueue writer :b 2 :queued)
      (ready-check-complete-take ready 0 blocker :writer 0)
      (ready-check-publish ready 0 writer 1)
      (setf pending nil)
      (is (null pending)))
    (ready-check-take ready 0 writer :writer 0)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 0 2 '(:a) :messages)
      (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
    (ready-check-publish ready 0 writer 1)
    (ready-check-take ready 0 writer :writer 0)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease target 0 2 '(:b) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
    (ready-check-take ready 0 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-ready-dequeued-reference-survives-begin-busy
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (ready-test-writer))
         (queue (arcdocdb.execution::writer-programmabile-queue writer)))
    (handoff-check-enqueue writer :once 1 :schedule)
    (ready-check-publish ready 0 writer 1)
    (multiple-value-bind (dequeued status cursor)
        (arcdocdb.execution:preleva-writer-pronto ready 0)
      (is (eq dequeued writer)) (is (eq status :writer)) (is (zerop cursor))
      (with-execution-guard (queue)
        (signals resource-exhausted (arcdocdb.execution:inizia-tratto-writer dequeued)
                 :writer-queue-busy))
      ;; Nessuna ripubblicazione: il caller conserva il riferimento estratto.
      (ready-check-take ready 0 nil :empty 0)
      (let ((lease (arcdocdb.execution:inizia-tratto-writer dequeued)))
        (handoff-check-pop dequeued lease (vector nil) 0 1 '(:once) :messages)
        (is (eq :idle (arcdocdb.execution:termina-tratto-writer dequeued lease)))))
    (ready-check-take ready 0 nil :empty 0)))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-004-ready-skips-busy-home-and-preserves-local-ring
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 2))
         (a (ready-prepare-fixture-writer)) (b (ready-prepare-fixture-writer))
         (refused (ready-prepare-fixture-writer))
         (home (ready-test-partition ready 0)))
    (ready-check-publish ready 0 a 1)
    (ready-check-publish ready 2 b 1)
    (ready-call-with-guards
     (list home)
     (lambda ()
       (let ((before (ready-fi-snapshot home)))
         (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 refused)
                  :ready-queue-busy)
         (ready-check-complete-take ready 0 b :writer 0)
         (ready-check-take ready 0 nil :busy 1)
         (is (equalp before (ready-fi-snapshot home))))))
    (ready-check-complete-take ready 0 a :writer 1)
    (ready-check-publish ready 0 refused 1)
    (ready-check-complete-take ready 0 refused :writer 1)
    (ready-check-take ready 0 nil :empty 1)))

;;; REQ: REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-004-ready-busy-observations-and-scan-order-oracle
  (dotimes (pattern 8)
    (dotimes (start 3)
      (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 3 :capacity 1))
             (model (make-array 3 :initial-element nil))
             (busy (loop for i below 3 when (logbitp i pattern) collect i))
             (partitions (mapcar (lambda (i) (ready-test-partition ready i)) busy)))
        (dotimes (shard 3)
          (when (evenp shard)
            (ready-model-publish ready model shard (ready-prepare-fixture-writer) 1)))
        (ready-call-with-guards
         partitions
         (lambda ()
           (dotimes (attempt 4) (ready-model-take ready model start busy))))
        (dotimes (attempt 3) (ready-model-take ready model start))
        (is (every #'null model))))))

;;; REQ: REQ-CON-001 REQ-CON-005 REQ-AFF-008
(deftest test-REQ-CON-005-ready-busy-publication-retains-obligation-and-payload
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (ready-test-writer)) (partition (ready-test-partition ready 0)))
    (multiple-value-bind (count pending) (arcdocdb.execution:accoda-lavoro-writer writer :once)
      (is (= count 1)) (is (eq pending :schedule))
      (ready-call-with-guards
       (list partition)
       (lambda ()
         (let ((before (ready-fi-snapshot partition)))
           (signals resource-exhausted (arcdocdb.execution:pubblica-writer-pronto ready 0 writer)
                    :ready-queue-busy)
           (is (equalp before (ready-fi-snapshot partition))))))
      (is (eq pending :schedule))
      (ready-check-publish ready 0 writer 1)
      (setf pending nil) (is (null pending)))
    (ready-check-take ready 0 writer :writer 0)
    (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
      (handoff-check-pop writer lease (vector nil) 0 1 '(:once) :messages)
      (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
    (ready-check-take ready 0 nil :empty 0)))

(defun ready-fi-bad-partition (fault)
  \"FI quiescente: constructor privato senza factory, tipi degli slot rispettati.\"
  (let* ((capacity (case fault (:capacity-zero 0) (:capacity-big 65537) (otherwise 2)))
         (size (if (member fault '(:capacity-zero :capacity-big)) 0
                   (if (eq fault :slots-length) 1 2)))
         (partition (arcdocdb.execution::%make-partizione-pronta
                     (make-array size :initial-element nil) capacity)))
    (case fault
      ((:capacity-zero :capacity-big :slots-length) nil)
      (:head (setf (arcdocdb.execution::partizione-pronta-head partition) 2))
      (:tail (setf (arcdocdb.execution::partizione-pronta-tail partition) 2))
      (:count (setf (arcdocdb.execution::partizione-pronta-count partition) 3))
      (:relation (setf (arcdocdb.execution::partizione-pronta-tail partition) 1))
      (otherwise (error \"FI pronta sconosciuta: ~S\" fault)))
    partition))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-rejects-invalid-private-ring-shapes
  (dolist (fault '(:capacity-zero :capacity-big :slots-length :head :tail :count :relation))
    (let* ((partition (ready-fi-bad-partition fault))
           (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition)))
           (before (ready-fi-snapshot partition)))
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution::%check-forma-pronta partition) :ready-queue-invariant)
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:pubblica-writer-pronto ready 0 (ready-test-writer))
        :ready-queue-invariant)
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:preleva-writer-pronto ready 0) :ready-queue-invariant)
      (is (equalp before (ready-fi-snapshot partition))))))

;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-rejects-invalid-private-partition-arrays
  (dolist (partitions (list #() (make-array 65 :initial-element nil) (vector nil)))
    (let ((ready (arcdocdb.execution::%make-lista-writer-pronti partitions)))
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:pubblica-writer-pronto ready 0 (ready-test-writer))
        :ready-queue-invariant)
      (signals arcdocdb.conditions:invariant-violation
        (arcdocdb.execution:preleva-writer-pronto ready 0) :ready-queue-invariant))))

;;; REQ: REQ-CON-001 REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-rejects-inconsistent-occupied-and-free-slots
  (dolist (bad (list nil :foreign (vector :foreign)))
    (let* ((partition (arcdocdb.execution::%make-partizione-pronta (vector bad nil) 2))
           (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition))))
      (setf (arcdocdb.execution::partizione-pronta-count partition) 1
            (arcdocdb.execution::partizione-pronta-tail partition) 1)
      (let ((before (ready-fi-snapshot partition)))
        (signals arcdocdb.conditions:invariant-violation
          (arcdocdb.execution:preleva-writer-pronto ready 0) :ready-queue-invariant)
        (is (equalp before (ready-fi-snapshot partition))))))
  (let* ((partition (arcdocdb.execution::%make-partizione-pronta
                     (vector (ready-test-writer) nil) 2))
         (ready (arcdocdb.execution::%make-lista-writer-pronti (vector partition)))
         (before (ready-fi-snapshot partition)))
    (signals arcdocdb.conditions:invariant-violation
      (arcdocdb.execution:pubblica-writer-pronto ready 0 (ready-test-writer))
      :ready-queue-invariant)
    (is (equalp before (ready-fi-snapshot partition)))))

(defun ready-check-unowned-helpers (partition writer)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%check-pronta partition) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%pubblica-pronto partition writer) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%preleva-pronto partition) :ready-queue-guard)
  (signals arcdocdb.conditions:invariant-violation
    (arcdocdb.execution::%rilascia-guard-pronta partition sb-thread:*current-thread*)
    :ready-queue-guard))

;;; REQ: REQ-CON-004 REQ-AFF-004
(deftest test-REQ-AFF-004-ready-helpers-reject-missing-and-foreign-guard
  (let* ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (partition (ready-test-partition ready 0)) (writer (ready-test-writer))
         (before (ready-fi-snapshot partition)) (threads nil))
    (ready-check-unowned-helpers partition writer)
    (unwind-protect
         (ready-call-with-guards
          (list partition)
          (lambda ()
            (push (execution-thread
                   \"ready foreign guard\"
                   (lambda ()
                     (ready-check-unowned-helpers partition writer)
                     (is (null (arcdocdb.execution::%prendi-guard-pronta partition)))
                     (multiple-value-bind (actual status) (arcdocdb.execution::%prova-pronta partition)
                       (is (null actual)) (is (eq status :busy)))
                     :ok)) threads)
            (execution-join (first threads))))
      (execution-stop-threads threads))
    (is (equalp before (ready-fi-snapshot partition)))
    (ready-prepare-fixture-writer writer)
    (ready-check-publish ready 0 writer 1)
    (ready-check-complete-take ready 0 writer :writer 0)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-005
(deftest test-REQ-CON-005-ready-handoff-before-after-release-and-next-wave
  (let ((ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
        (writer (arcdocdb.execution:crea-writer-programmabile :capacity 2 :quantum 3))
        (target (vector :untouched)))
    (dotimes (wave 4)
      (let ((first (vector wave :initial)) (before (vector wave :before))
            (after (vector wave :after)))
        (handoff-check-enqueue writer first 1 :schedule)
        (ready-check-publish ready 1 writer 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease target 0 1 (list first) :messages)
          (handoff-check-pop writer lease target 0 1 nil :empty)
          (handoff-check-enqueue writer before 1 :queued)
          (ready-check-take ready 0 nil :empty 1)
          (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease))))
        (ready-check-publish ready 1 writer 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease target 0 1 (list before) :messages)
          (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
        (handoff-check-enqueue writer after 1 :schedule)
        (ready-check-publish ready 1 writer 1)
        (ready-check-take ready 0 writer :writer 0)
        (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
          (handoff-check-pop writer lease target 0 1 (list after) :messages)
          (is (eq :idle (arcdocdb.execution:termina-tratto-writer writer lease))))
        (ready-check-take ready 1 nil :empty 0)))))

(defun ready-wave-items (series wave)
  (loop for sequence below 3
        for buffer = (execution-buffer 256 (+ (* series 37) (* wave 11) sequence))
        collect (vector series wave sequence buffer (reference-crc buffer 0 (length buffer)))))

(defun ready-read-message (writer lease expected)
  (let ((target (vector :left :untouched :right)))
    (handoff-check-pop writer lease target 1 2 (list expected) :messages)
    (is (= (svref expected 4) (reference-crc (svref (svref target 1) 3) 0 256)))))

(defun ready-wave-producer (ready home writer messages go published third-go third-published)
  (dotimes (wave (length messages))
    (let ((items (svref messages wave)))
      (execution-wait go)
      (handoff-check-enqueue writer (first items) 1 :schedule)
      (ready-check-publish ready home writer 1)
      (handoff-check-enqueue writer (second items) 2 :queued)
      (sb-thread:signal-semaphore published)
      (execution-wait third-go)
      (handoff-check-enqueue writer (third items) 2 :queued)
      (sb-thread:signal-semaphore third-published)))
  :ok)

(defun ready-wave-consumer (ready home writer messages go taken finish drained results)
  (let ((cursor (mod (1+ home) 2)))
    (dotimes (wave (length messages))
      (execution-wait go)
      (setf cursor (ready-check-take ready cursor writer :writer (mod (1+ home) 2)))
      (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
        (ready-read-message writer lease (first (svref messages wave)))
        (handoff-check-pop writer lease (vector :untouched) 0 1 nil :yield)
        (sb-thread:signal-semaphore taken)
        (execution-wait finish)
        (is (eq :schedule (arcdocdb.execution:termina-tratto-writer writer lease)))
        (ready-check-publish ready home writer 1))
      (loop for item in (rest (svref messages wave)) for sequence from 1
            do (setf cursor (ready-check-take ready cursor writer :writer (mod (1+ home) 2)))
               (let ((lease (arcdocdb.execution:inizia-tratto-writer writer)))
                 (ready-read-message writer lease item)
                 (is (eq (if (= sequence 2) :idle :schedule)
                         (arcdocdb.execution:termina-tratto-writer writer lease)))
                 (unless (= sequence 2) (ready-check-publish ready home writer 1))))
      (setf (svref results wave) :verified)
      (sb-thread:signal-semaphore drained)))
  :ok)

(defun ready-semaphore-pair ()
  (vector (sb-thread:make-semaphore) (sb-thread:make-semaphore)))

(defun ready-pair-signal (pair)
  (dotimes (i 2) (sb-thread:signal-semaphore (svref pair i))))

(defun ready-pair-wait (pair)
  (dotimes (i 2) (execution-wait (svref pair i))))

(defun ready-start-wave-workers (ready writers messages semaphores results producers)
  (let ((threads nil) (complete nil))
    (unwind-protect
         (progn
           (dotimes (series 2)
             (let ((s series))
               (let ((producer
                       (execution-thread
                        \"ready reused producer\"
                        (lambda ()
                          (ready-wave-producer
                           ready s (svref writers s) (svref messages s)
                           (svref (svref semaphores 0) s) (svref (svref semaphores 1) s)
                           (svref (svref semaphores 4) s) (svref (svref semaphores 5) s))))))
                 (push producer threads) (setf (svref producers s) producer))
               (push (execution-thread
                      \"ready reused consumer\"
                      (lambda ()
                        (ready-wave-consumer
                         ready s (svref writers s) (svref messages s)
                         (svref (svref semaphores 2) s) (svref (svref semaphores 3) s)
                         (svref (svref semaphores 6) s) (svref (svref semaphores 7) s)
                         (svref results s)))) threads)))
           (setf complete t)
           threads)
      (unless complete (execution-stop-threads threads)))))

(defun ready-drive-wave (ready semaphores results producers wave)
  \"Ordini causali controllati: B progredisce mentre la guard dello shard A è ferma.\"
  (ready-pair-signal (svref semaphores 0))
  (ready-pair-wait (svref semaphores 1))
  (ready-call-with-guards
   (list (ready-test-partition ready 0))
   (lambda ()
     (sb-thread:signal-semaphore (svref (svref semaphores 2) 1))
     (execution-wait (svref (svref semaphores 3) 1))
     (is (every #'sb-thread:thread-alive-p producers))
     (sb-thread:signal-semaphore (svref (svref semaphores 4) 1))
     (execution-wait (svref (svref semaphores 5) 1))
     (sb-thread:signal-semaphore (svref (svref semaphores 6) 1))
     (execution-wait (svref (svref semaphores 7) 1))
     (is (eq :verified (svref (svref results 1) wave)))
     (ready-check-take ready 0 nil :busy 1)))
  (sb-thread:signal-semaphore (svref (svref semaphores 2) 0))
  (execution-wait (svref (svref semaphores 3) 0))
  (is (sb-thread:thread-alive-p (svref producers 0)))
  (sb-thread:signal-semaphore (svref (svref semaphores 4) 0))
  (execution-wait (svref (svref semaphores 5) 0))
  (sb-thread:signal-semaphore (svref (svref semaphores 6) 0))
  (execution-wait (svref (svref semaphores 7) 0))
  (is (eq :verified (svref (svref results 0) wave)))
  (ready-check-take ready (mod wave 2) nil :empty (mod (1+ wave) 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-003 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-003-ready-reused-workers-live-producers-and-independent-shards
  (let* ((waves 6)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 2 :capacity 1))
         (writers (vector (ready-test-writer) (ready-test-writer)))
         (messages (vector (make-array waves) (make-array waves)))
         (results (vector (make-array waves :initial-element nil)
                          (make-array waves :initial-element nil)))
         (producers (vector nil nil)) (semaphores (make-array 8)) (threads nil))
    (dotimes (i 8) (setf (svref semaphores i) (ready-semaphore-pair)))
    (dotimes (series 2)
      (dotimes (wave waves)
        (setf (svref (svref messages series) wave) (ready-wave-items series wave))))
    (unwind-protect
         (progn
           (setf threads (ready-start-wave-workers ready writers messages semaphores results producers))
           (is (= 4 (length threads)))
           (dotimes (wave waves) (ready-drive-wave ready semaphores results producers wave))
           (dolist (thread threads) (execution-join thread))
           (dotimes (series 2)
             (is (every (lambda (result) (eq result :verified)) (svref results series))))
           (format t \"  Ready: 4 thread riusati, ~D ondate, ~D payload, shard fermata e stealing.~%\"
                   waves (* 2 waves 3)))
      (dotimes (i 8) (ready-pair-signal (svref semaphores i)))
      (execution-stop-threads threads))))

(defun ready-competing-consumer (ready expected go done results index waves)
  (dotimes (wave waves)
    (execution-wait go)
    (multiple-value-bind (writer status cursor) (arcdocdb.execution:preleva-writer-pronto ready 0)
      (is (zerop cursor))
      (if (eq status :writer)
          (progn (is (eq writer expected)) (ready-complete-fixture-writer writer))
          (progn (is (null writer)) (is (member status '(:empty :busy)))))
      (setf (svref results index) status))
    (sb-thread:signal-semaphore done))
  :ok)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005
(deftest test-REQ-CON-002-ready-competing-consumers-take-one-reference-per-wave
  (let* ((waves 8)
         (ready (arcdocdb.execution:crea-lista-writer-pronti :shards 1 :capacity 1))
         (writer (ready-test-writer)) (go (ready-semaphore-pair)) (done (ready-semaphore-pair))
         (results (vector nil nil)) (threads nil))
    (unwind-protect
         (progn
           (dotimes (consumer 2)
             (let ((index consumer))
               (push (execution-thread
                      \"ready competing reused consumer\"
                      (lambda () (ready-competing-consumer ready writer (svref go index)
                                                           (svref done index) results index waves))) threads)))
           (dotimes (wave waves)
             (ready-prepare-fixture-writer writer)
             (ready-check-publish ready 0 writer 1)
             (ready-pair-signal go)
             (ready-pair-wait done)
             (is (= 1 (count :writer results)))
             (is (= 1 (+ (count :empty results) (count :busy results))))
             (ready-check-take ready 0 nil :empty 0))
           (dolist (thread threads) (execution-join thread))
           (format t \"  Ready: 2 consumer riusati, ~D ondate, un riferimento estratto per ondata.~%\" waves))
      (ready-pair-signal go)
      (execution-stop-threads threads))))
")
  (:PATH "tools/writer-ready-bench.lisp" :BYTES 20889 :SHA256
   "9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4" :GIT-BLOB
   "f666bc8d68738c65c442404ffffc6d342a020c9b" :TEXT
   ";;;; Allocazioni seriali della lista pronta composta con handoff; nessun I/O nel ciclo.
;;;; Uso: --self-test oppure --bench directory-nuova/; writer-ready-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-ready.bench (:use #:cl))
(in-package #:arcdocdb.writer-ready.bench)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +iterations+ 4096)
(defconstant +warmup+ 128)
(defconstant +replicas+ 5)

(defun fingerprints ()
  \"Registra ASD, prodotto e driver: controllo di stabilità, non di autenticità.\"
  (loop for path in (append '(#p\"arcdocdb.asd\" #p\"tools/writer-ready-bench.lisp\")
                            (sort (directory \"src/**/*.lisp\") #'string< :key #'namestring))
        collect (list :file (enough-namestring path)
                      :md5 (format nil \"~(~{~2,'0X~}~)\"
                                   (coerce (sb-md5:md5sum-file path) 'list)))))

(defun load-product ()
  \"Forza compilazione rigorosa prima delle fixture e della misura.\"
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition)
                             (unless (typep condition 'sb-kernel:redefinition-warning)
                               (error \"~A non ammesso (COD-01): ~A\" (type-of condition) condition)))))
      (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
      (asdf:load-system \"arcdocdb\" :force t))))

(defun execution-function (name)
  \"Risolve una API esportata prima del clock; nessuna ricerca di simboli nel ciclo.\"
  (multiple-value-bind (symbol visibility) (find-symbol name \"ARCDOCDB.EXECUTION\")
    (unless (and symbol (eq visibility :external) (fboundp symbol))
      (error \"COD-60: API execution non disponibile: ~A.\" name))
    (symbol-function symbol)))

(defun expected-sink (iterations token)
  \"Oracolo indipendente: somma dei token fissi e degli indici delle chiamate.\"
  (logand most-positive-fixnum (+ (* iterations token) (/ (* iterations (1- iterations)) 2))))

(defun sample-record (replica iterations warmup token)
  \"Tutte le chiavi della misura sono allocate prima di warmup, heap e clock.\"
  (list :replica replica :status :running :stage :warmup :iterations iterations
        :warmup-iterations (min warmup iterations) :completed-iterations 0
        :heap-bytes nil :raw-ticks nil :seconds nil :time-quality :pending
        :sink nil :expected-sink (expected-sink iterations token)
        :expected-return-token token :diagnostic nil))

(defun sample (function iterations token progress &key (warmup +warmup+) (clock #'get-internal-real-time))
  \"Warmup e GC prima della misura; raw e numero di cicli conservati anche al fallimento.\"
  (unless (and (<= 1 iterations +iterations+) (<= 0 warmup +warmup+)
               (typep token '(integer 0 #.most-positive-fixnum)))
    (error \"COD-60: parametri benchmark ready fuori budget.\"))
  (dotimes (i (min warmup iterations)) (funcall function))
  (sb-ext:gc :full t)
  (setf (getf progress :stage) :measured)
  (let ((ticks-before (funcall clock)) (heap-before (sb-ext:get-bytes-consed)) (sink 0) (failure nil))
    (declare (type fixnum sink))
    (handler-case
        (dotimes (i iterations)
          (setf sink (logand most-positive-fixnum (+ sink i (the fixnum (funcall function))))
                (getf progress :completed-iterations) (1+ i)))
      (error (condition) (setf failure condition)))
    (let ((heap (- (sb-ext:get-bytes-consed) heap-before)) (ticks (- (funcall clock) ticks-before)))
      (setf (getf progress :heap-bytes) heap (getf progress :raw-ticks) ticks
            (getf progress :sink) sink (getf progress :time-quality)
            (if (zerop ticks) :below-resolution :measured)
            (getf progress :seconds) (when (plusp ticks) (/ ticks (float internal-time-units-per-second 1d0))))
      (when failure (error failure))
      (unless (and (>= heap 0) (>= ticks 0) (= (getf progress :expected-sink) sink))
        (error \"COD-60: clock/heap invalido o sink ready ~D diverso da ~D.\"
               sink (getf progress :expected-sink)))
      (setf (getf progress :status) :ok (getf progress :stage) :complete)))
  progress)

(defun publish-batch (enqueue publish ready writers shards)
  \"Due obblighi per shard, ciascuno pubblicato una volta; count 1/2 indipendente dal ring.\"
  (let ((token 0))
    (declare (type fixnum token))
    (dotimes (shard shards token)
      (dotimes (ordinal 2)
        (let* ((index (+ (* 2 shard) ordinal)) (writer (svref writers index)))
          (multiple-value-bind (count action) (funcall enqueue writer (1+ index))
            (unless (and (= 1 count) (eq :schedule action))
              (error \"COD-60: manca il nuovo obbligo di pubblicazione ready.\"))
            (incf token (+ count 11)))
          (let ((count (funcall publish ready shard writer)))
            (unless (= (1+ ordinal) count) (error \"COD-60: count ready diverso da 1/2.\"))
            (incf token count)))))))

(defun consume-writer (start pop finish writer target nonces index)
  \"Una lease nuova, un payload preallocato, termine idle; nessun obbligo ripetuto.\"
  (let ((lease (funcall start writer)) (token 19))
    (declare (type fixnum token))
    (unless (= lease (incf (the fixnum (svref nonces index))))
      (error \"COD-60: nonce del writer pronto incoerente.\"))
    (multiple-value-bind (count status) (funcall pop writer lease target 1 2)
      (unless (and (= 1 count) (eq :messages status) (eql (1+ index) (svref target 1))
                   (eq :outside (svref target 0)) (eq :outside (svref target 2)))
        (error \"COD-60: payload/ownership/span del writer pronto incoerenti.\"))
      (incf token (+ (* 3 count) (* 5 (the fixnum (svref target 1))))))
    (unless (eq :idle (funcall finish writer lease))
      (error \"COD-60: writer pronto non torna idle dopo il consumo.\"))
    (+ token 23)))

(defun cycle-function (shards capacity)
  \"Fixture preallocata; due giri e passo 2 sul ring di3 verificano FIFO, wrap e cursor.\"
  (let* ((create-ready (execution-function \"CREA-LISTA-WRITER-PRONTI\"))
         (publish (execution-function \"PUBBLICA-WRITER-PRONTO\"))
         (take (execution-function \"PRELEVA-WRITER-PRONTO\"))
         (create-writer (execution-function \"CREA-WRITER-PROGRAMMABILE\"))
         (enqueue (execution-function \"ACCODA-LAVORO-WRITER\"))
         (start (execution-function \"INIZIA-TRATTO-WRITER\"))
         (pop (execution-function \"PRELEVA-LAVORI-WRITER\"))
         (finish (execution-function \"TERMINA-TRATTO-WRITER\"))
         (ready (funcall create-ready :shards shards :capacity capacity))
         (writers (make-array (* 2 shards))) (nonces (make-array (* 2 shards) :initial-element 0))
         (target (make-array 3 :initial-element :outside)) (cursor 0))
    (declare (type fixnum cursor shards capacity))
    (dotimes (i (length writers)) (setf (svref writers i) (funcall create-writer :capacity 1 :quantum 1)))
    (lambda ()
      (let ((token (publish-batch enqueue publish ready writers shards)))
        (declare (type fixnum token))
        (dotimes (ordinal 2)
          (dotimes (visit shards)
            (let ((index (+ (* 2 cursor) ordinal)) (expected-next (mod (1+ cursor) shards)))
              (multiple-value-bind (writer status next) (funcall take ready cursor)
                (unless (and (eq (svref writers index) writer) (eq :writer status) (= expected-next next))
                  (error \"COD-60: identità/FIFO/status/cursor della lista pronta incoerenti.\"))
                (incf token (+ 17 (* 5 (1+ index)) (* 7 next)))
                (incf token (consume-writer start pop finish writer target nonces index))
                (setf cursor next)))))
        (multiple-value-bind (writer status next) (funcall take ready cursor)
          (unless (and (null writer) (eq :empty status) (= (mod (1+ cursor) shards) next))
            (error \"COD-60: scansione vuota/cursor ready incoerenti.\"))
          (setf cursor next)
          (incf token 29))
        token))))

(defun campaign-record (scenario shards capacity)
  \"Oracolo: M=2K wrapper, sum=count+identità+cursor+azioni, pari a 27K²+154K+29.\"
  (unless (= 3 capacity) (error \"COD-60: capacità ready preregistrata diversa da tre.\"))
  (let ((token (+ (* 27 shards shards) (* 154 shards) 29)))
    (list :scenario scenario :shards shards :capacity-per-shard capacity :writers-per-shard 2
          :ready-published-per-cycle (* 2 shards) :calls-per-cycle (1+ (* 12 shards))
          :expected-token token :token-rule
          '(:enqueue-count-plus-schedule-11 :publish-count :ready-writer-17
            :writer-id-times-5 :next-cursor-times-7 :lease-19 :taken-times-3
            :payload-id-times-5 :finish-idle-23 :ready-empty-29)
          :status :running :stage :fixture :current-replica nil :samples nil :diagnostic nil)))

(defun campaign (progress checkpoint)
  \"Cinque campioni; ogni prova corrente è collegata al report prima dell'esecuzione.\"
  (let ((function (cycle-function (getf progress :shards) (getf progress :capacity-per-shard))))
    (dotimes (replica +replicas+)
      (let ((measurement (sample-record replica +iterations+ +warmup+ (getf progress :expected-token))))
        (setf (getf progress :current-replica) replica (getf progress :stage) :replica
              (getf progress :samples) (append (getf progress :samples) (list measurement)))
        (when checkpoint (funcall checkpoint))
        (sample function +iterations+ (getf progress :expected-token) measurement)
        (when checkpoint (funcall checkpoint))
        (unless (zerop (getf measurement :heap-bytes))
          (error \"COD-30: heap osservato non nullo nella replica ~D di ~A.\"
                 replica (getf progress :scenario)))))
    (setf (getf progress :status) :ok (getf progress :stage) :complete
          (getf progress :current-replica) nil))
  progress)

(defun run-campaigns (report &key checkpoint (runner #'campaign))
  \"I due scenari vengono registrati in ordine e conservati anche al fallimento.\"
  (dolist (spec '((:one-shard 1 3) (:four-shards 4 3)))
    (let ((progress (apply #'campaign-record spec)))
      (setf (getf report :current-campaign) progress
            (getf report :campaigns) (append (getf report :campaigns) (list progress)))
      (when checkpoint (funcall checkpoint))
      (funcall runner progress checkpoint)))
  report)

(defun make-report ()
  \"Metadati di misura e limiti; tutte le chiavi condivise esistono prima degli aggiornamenti.\"
  (list :schema-version 1 :kind :writer-ready-benchmark :status :running :stage :pending
        :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :diagnostic nil :self-test nil :campaigns nil :current-campaign nil
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :recorded-at (get-universal-time)
        :sbcl (lisp-implementation-version) :machine (machine-type) :os (software-type)
        :os-version (software-version) :workers 1 :safety 3 :iterations +iterations+
        :warmup +warmup+ :replicas +replicas+ :timer-units-per-second internal-time-units-per-second
        :limits '(:success-path-only :serial-composed-handoff-and-ready-cycles :preallocated-inputs
                  :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
                  :clock-zero-is-below-resolution :no-throughput-p99-scaling-or-time-threshold
                  :no-pool-device-durability-or-release-qualification)))

(defun acquire-directory (path)
  \"MKDIR esclusivo 0700; una destinazione precedente non viene mai scritta.\"
  (let ((directory (uiop:ensure-directory-pathname (merge-pathnames path (uiop:getcwd)))))
    (ensure-directories-exist
     (merge-pathnames \"parent-placeholder\" (uiop:pathname-parent-directory-pathname directory)))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun write-report (report directory)
  \"Scrive esclusivamente nella directory reclamata; conserva l'ultima plist completa.\"
  (with-open-file (stream (merge-pathnames \"report.next.lisp\" directory)
                          :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
  (uiop:rename-file-overwriting-target (merge-pathnames \"report.next.lisp\" directory)
                                     (merge-pathnames \"report.lisp\" directory))
  report)

(defun mark-failed (report condition)
  \"L'errore conserva sample e scenario correnti, inclusi raw raccolti prima del controllo.\"
  (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
  (let ((current (getf report :current-campaign)))
    (when current
      (setf (getf current :status) :failed (getf current :diagnostic) (princ-to-string condition))
      (let ((last (car (last (getf current :samples)))))
        (when (and last (eq :running (getf last :status)))
          (setf (getf last :status) :failed (getf last :diagnostic) (princ-to-string condition))))))
  report)

(defun run-driver (args &key (self-tester #'self-test) (campaign-runner #'run-campaigns)
                            (product-loader #'load-product))
  \"Directory, load e ogni prova registrati; fallimenti visibili senza sovrascrivere altro.\"
  (let ((report (make-report)) (owned-directory nil))
    (handler-case
        (progn
          (unless (or (equal args '(\"--self-test\"))
                      (and (= 2 (length args)) (string= \"--bench\" (first args))))
            (error \"COD-61: uso --self-test oppure --bench directory-nuova/.\"))
          (when (= 2 (length args)) (setf owned-directory (acquire-directory (second args))))
          (setf (getf report :stage) :load-product)
          (when owned-directory (write-report report owned-directory))
          (funcall product-loader)
          (setf (getf report :stage) :self-test (getf report :self-test) (funcall self-tester))
          (when owned-directory
            (write-report report owned-directory)
            (setf (getf report :stage) :campaigns)
            (funcall campaign-runner report :checkpoint (lambda () (write-report report owned-directory))))
          (setf (getf report :status) :ok (getf report :stage) :complete))
      (error (condition) (mark-failed report condition)))
    (let ((after (fingerprints)))
      (setf (getf report :source-fingerprints-after) after (getf report :source-consistency)
            (if (equal (getf report :source-fingerprints-before) after) :stable :changed))
      (when (and (eq :ok (getf report :status)) (eq :changed (getf report :source-consistency)))
        (setf (getf report :status) :source-changed
              (getf report :diagnostic) \"COD-61: sorgenti cambiati durante il benchmark ready.\")))
    (when owned-directory (write-report report owned-directory))
    report))

(defun fresh-self-test-directory ()
  \"Fixture temporanea esclusiva, con limite di mille collisioni.\"
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil \"arcdocdb-ready-bench-~D-~D-~D/\"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error \"COD-60: directory fixture benchmark ready non disponibile.\"))

(defun self-test-partial-run (report &key checkpoint)
  \"Primo scenario completo; secondo interrompe la replica dopo un raw sintetico.\"
  (run-campaigns report :checkpoint checkpoint
    :runner (lambda (progress persist)
              (setf (getf progress :stage) :replica (getf progress :current-replica) 0
                    (getf progress :samples)
                    (list (list :status :running :raw-ticks 7 :heap-bytes 0 :diagnostic nil)))
              (when persist (funcall persist))
              (if (eq :one-shard (getf progress :scenario))
                  (setf (getf progress :stage) :complete (getf progress :status) :ok)
                  (error \"fixture: seconda campagna interrotta\")))))

(defun self-test-reporter ()
  \"Rifiuta una destinazione esistente e conserva scenario precedente e replica fallita.\"
  (let ((root (fresh-self-test-directory)))
    (unwind-protect
         (let* ((existing (acquire-directory (merge-pathnames \"existing/\" root)))
                (failed-directory (merge-pathnames \"failed/\" root)))
           (write-report '(:sentinel :unchanged) existing)
           (unless (eq :failed (getf (run-driver (list \"--bench\" (namestring existing))
                                               :self-tester (constantly :passed)
                                               :product-loader (constantly nil)) :status))
             (error \"COD-60: destinazione precedente accettata.\"))
           (let ((*read-eval* nil))
             (with-open-file (input (merge-pathnames \"report.lisp\" existing))
               (unless (equal (read input) '(:sentinel :unchanged))
                 (error \"COD-60: report precedente modificato.\"))))
           (run-driver (list \"--bench\" (namestring failed-directory))
                       :self-tester (constantly :passed) :product-loader (constantly nil)
                       :campaign-runner #'self-test-partial-run)
           (let* ((*read-eval* nil)
                  (saved (with-open-file (input (merge-pathnames \"report.lisp\" failed-directory))
                           (read input))) (cases (getf saved :campaigns))
                  (partial (first (getf (second cases) :samples))))
             (unless (and (eq :failed (getf saved :status)) (= 2 (length cases))
                          (eq :ok (getf (first cases) :status))
                          (eq :failed (getf (second cases) :status))
                          (eq :replica (getf (second cases) :stage))
                          (= 0 (getf (second cases) :current-replica))
                          (eq :failed (getf partial :status)) (= 7 (getf partial :raw-ticks))
                          (= 0 (getf partial :heap-bytes)))
               (error \"COD-60: campagna precedente o prova parziale perse.\"))))
      ;; C4: ROOT è soltanto la directory acquisita dalla fixture.
      (uiop:delete-directory-tree root :validate t))))

(defun self-test ()
  \"Heap positivo, sink errato, clock nullo, cicli legali e reporter dei fallimenti.\"
  (let* ((baseline (sample-record 0 +iterations+ +warmup+ 0)) (probe nil)
         (positive (sample-record 0 16 0 1048576)) (api-probes nil))
    (sample (lambda () 0) +iterations+ 0 baseline)
    (unless (zerop (getf baseline :heap-bytes)) (error \"COD-60: baseline contatore non nulla.\"))
    (sample (lambda ()
              (setf probe (make-array 1048576 :element-type '(unsigned-byte 8) :initial-element 0))
              (length probe)) 16 1048576 positive :warmup 0)
    (unless (and (= 1048576 (length probe)) (>= (getf positive :heap-bytes) (* 16 1048576)))
      (error \"COD-60: allocazione deliberata non rilevata.\"))
    (let ((wrong (sample-record 0 2 0 0)) (zero (sample-record 0 2 0 0)))
      (unless (handler-case (progn (sample (lambda () 1) 2 0 wrong :warmup 0) nil)
                (error () t)) (error \"COD-60: sink errato non respinto.\"))
      (sample (lambda () 0) 2 0 zero :warmup 0 :clock (constantly 0))
      (unless (and (eq :below-resolution (getf zero :time-quality))
                   (null (getf zero :seconds))) (error \"COD-60: clock nullo utilizzato come durata.\")))
    (dolist (shards '(1 4))
      (let* ((token (+ (* 27 shards shards) (* 154 shards) 29))
             (progress (sample-record 0 4 0 token)))
        (sample (cycle-function shards 3) 4 token progress :warmup 0)
        (push (list :shards shards :capacity-per-shard 3 :probe progress) api-probes)))
    (self-test-reporter)
    (list :status :ok :baseline baseline :positive-control positive
          :wrong-sink :rejected :zero-clock :below-resolution :partial-report :preserved
          :existing-destination :preserved :composed-api-probes (nreverse api-probes))))

(defun main ()
  \"CLI C4; risultato strutturato anche senza destinazione e diagnostica con exit nonzero.\"
  (let ((report (run-driver (uiop:command-line-arguments))))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status))
      (format *error-output* \"~&writer-ready-bench.lisp: ~A~%\" (getf report :diagnostic))
      (uiop:quit 1))))

(main)
")
  (:PATH "tools/writer-ready-mutation.lisp" :BYTES 25632 :SHA256
   "06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb" :GIT-BLOB
   "1401a183d345aedb1eb7eb07e3331180325fb07a" :TEXT
   ";;;; Mutazioni semantiche della lista writer pronti in copie isolate.
;;;; Uso: --self-test oppure --run directory-nuova/; writer-ready-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-005 REQ-AFF-008
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-ready.mutation (:use #:cl))
(in-package #:arcdocdb.writer-ready.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *ready-mutants*
  '((\"ready-fifo-head-from-tail\" \"src/execution/ready.lisp\"
     ((\"(head (partizione-pronta-head partition))\"
       \"(head (partizione-pronta-tail partition))\")))
    (\"ready-tail-wrap-two\" \"src/execution/ready.lisp\"
     ((\"(mod (1+ tail) (partizione-pronta-capacity partition))\"
       \"(mod (+ tail 2) (partizione-pronta-capacity partition))\")))
    (\"ready-head-wrap-two\" \"src/execution/ready.lisp\"
     ((\"(mod (1+ head) (partizione-pronta-capacity partition))\"
       \"(mod (+ head 2) (partizione-pronta-capacity partition))\")))
    (\"ready-full-boundary\" \"src/execution/ready.lisp\"
     ((\"(= (partizione-pronta-count partition) (partizione-pronta-capacity partition))\"
       \"(> (partizione-pronta-count partition) (partizione-pronta-capacity partition))\")))
    (\"ready-pop-count-unchanged\" \"src/execution/ready.lisp\"
     ((\"(1- (partizione-pronta-count partition))\" \"(partizione-pronta-count partition)\")))
    (\"ready-pop-keeps-reference\" \"src/execution/ready.lisp\"
     ((\"(setf (svref (partizione-pronta-slots partition) head) nil\"
       \"(setf (svref (partizione-pronta-slots partition) head) writer\")))
    (\"ready-release-keeps-guard\" \"src/execution/ready.lisp\"
     ((\"(sb-ext:compare-and-swap (partizione-pronta-guard partition) thread nil)\"
       \"(sb-ext:compare-and-swap (partizione-pronta-guard partition) thread thread)\")))
    (\"ready-scan-forgets-busy\" \"src/execution/ready.lisp\"
     ((\"(:busy (setf busy t))\" \"(:busy (setf busy nil))\")))
    (\"ready-scan-stops-on-busy\" \"src/execution/ready.lisp\"
     ((\"(:busy (setf busy t))\"
       \"(:busy (return-from preleva-writer-pronto
                   (values nil :busy (mod (1+ (the index start)) size))))\")))
    (\"ready-scan-misses-last-shard\" \"src/execution/ready.lisp\"
     ((\"(dotimes (i size)\" \"(dotimes (i (1- size))\")))
    (\"ready-success-cursor-stays\" \"src/execution/ready.lisp\"
     ((\"(values writer :writer (mod (1+ cursor) size))\" \"(values writer :writer cursor)\")))
    (\"ready-unsuccessful-cursor-stays\" \"src/execution/ready.lisp\"
     ((\"(values nil (if busy :busy :empty) (mod (1+ (the index start)) size))\"
       \"(values nil (if busy :busy :empty) (the index start))\")))))

(defun mutation-list ()
  \"Dodici mutanti semantici ready fissati prima della campagna.\"
  *ready-mutants*)

(defun source-files ()
  \"ASD, build, sorgenti e test richiesti dalle copie; nessuna evidenza o Git copiati.\"
  (append '(#p\"arcdocdb.asd\" #p\"tools/build.lisp\")
          (sort (append (directory \"src/**/*.lisp\") (directory \"tests/**/*.lisp\"))
                #'string< :key #'namestring)))

(defun fingerprints ()
  \"MD5 dei file copiati e del driver: controllo di stabilità, non di autenticità.\"
  (loop for file in (append (source-files) '(#p\"tools/writer-ready-mutation.lisp\"))
        collect (list :file (enough-namestring file)
                      :md5 (format nil \"~(~{~2,'0X~}~)\"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun read-text (path)
  \"Legge sorgente e log UTF-8 come dati, senza interpretazione.\"
  (uiop:read-file-string path :external-format :utf-8))

(defun mutate-once (source before after name)
  \"COD-60: bersaglio unico e non vuoto, modifica effettiva, nessuna riscrittura originale.\"
  (let ((position (search before source)))
    (unless (and (plusp (length before)) position (not (string= before after))
                 (not (search before source :start2 (1+ position))))
      (error \"COD-60: mutante ~A, bersaglio assente/ambiguo o identico: ~S\" name before))
    (concatenate 'string (subseq source 0 position) after
                 (subseq source (+ position (length before))))))

(defun mutated-source (mutant)
  \"Valida ogni modifica nell'originale e nel risultato delle modifiche precedenti.\"
  (destructuring-bind (name path edits) mutant
    (let* ((original (read-text path)) (result original))
      (unless edits (error \"COD-60: mutante ~A senza modifiche.\" name))
      (dolist (edit edits)
        (destructuring-bind (before after) edit
          (mutate-once original before after name)
          (setf result (mutate-once result before after name))))
      result)))

(defun validate-mutations (mutants)
  \"Dodici nomi unici; ogni bersaglio appare una sola volta nei sorgenti congelati.\"
  (unless (= 12 (length mutants)) (error \"COD-60: numero mutanti ready diverso da dodici.\"))
  (let ((names nil))
    (dolist (mutant mutants)
      (when (member (first mutant) names :test #'string=)
        (error \"COD-60: nome mutante ripetuto: ~A\" (first mutant)))
      (push (first mutant) names)
      (mutated-source mutant)))
  nil)

(defun event-at-line-start-p (text marker)
  \"Solo eventi a inizio riga; citazioni e frammenti di backtrace non contano.\"
  (loop for line in (uiop:split-string text :separator '(#\\Newline))
        thereis (and (<= (length marker) (length line))
                     (string= marker line :end2 (length marker)))))

(defun classify-result (text exit &optional signal)
  \"Segnali OS, compilazione e guasti fuori dai test non sono mutanti rilevati.\"
  (cond (signal :worker-error)
        ((or (search \"compilation aborted\" text :test #'char-equal)
             (search \"COMPILE-FILE-ERROR\" text :test #'char-equal)
             (search \"COMPILE-FILE-WARNED\" text :test #'char-equal)
             (search \"non ammesso (COD-01)\" text)) :compilation-failure)
        ((and (integerp exit) (not (zerop exit))
              (event-at-line-start-p text \"execution-tests-complete \")) :worker-error)
        ((or (not (integerp exit))
             (not (event-at-line-start-p text \"execution-test-start \"))) :before-tests)
        ((not (zerop exit)) :detected)
        ((event-at-line-start-p text \"execution-tests-complete \") :survived)
        (t :before-tests)))

(defun copy-test-system (directory)
  \"Copia tutti i sorgenti e test ASDF; gli output delle copie restano privati.\"
  (dolist (file (source-files))
    (let ((target (merge-pathnames (enough-namestring file) directory)))
      (ensure-directories-exist target)
      (uiop:copy-file file target)))
  nil)

(defun write-runner (directory)
  \"Compilazione rigorosa e intera suite execution registrata, inclusi i test ready.\"
  (let ((path (merge-pathnames \"tools/writer-ready-isolated-build.lisp\" directory)))
    (with-open-file (stream path :direction :output :if-exists :error)
      (dolist (form
                '((require :asdf)
                  (setf asdf:*user-cache* (merge-pathnames \"fasl/\" (truename \"./\"))
                        asdf:*compile-file-failure-behaviour* :error
                        asdf:*compile-file-warnings-behaviour* :error)
                  (handler-bind
                      ((warning (lambda (condition)
                                  (unless (typep condition 'sb-kernel:redefinition-warning)
                                    (error \"~A non ammesso (COD-01): ~A\"
                                           (type-of condition) condition)))))
                    (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
                    (asdf:load-system \"arcdocdb\" :force t)
                    (asdf:load-system \"arcdocdb/tests\" :force t))
                  (unless (and (probe-file \"tests/execution/ready.lisp\")
                               (asdf:find-component (asdf:find-system \"arcdocdb/tests\")
                                                    '(\"execution\" \"ready\")))
                    (error \"Test ready assente o non registrato in ASDF.\"))
                  (let* ((package (or (find-package \"ARCDOCDB.EXECUTION.TESTS\")
                                      (error \"Harness execution non caricato.\")))
                         (registry (or (find-symbol \"*TESTS*\" package)
                                       (error \"Registro execution assente.\")))
                         (tests (reverse (symbol-value registry))))
                    (unless (and tests (every #'fboundp tests))
                      (error \"Test execution non caricati dal sistema ASDF.\"))
                    (dolist (test tests)
                      (format t \"~&execution-test-start ~A~%\" test) (finish-output)
                      (funcall test) (format t \"ok    ~A~%\" test))
                    (format t \"~&execution-tests-complete ~D~%\" (length tests)))))
        (write form :stream stream :pretty t) (terpri stream)))
    path))

(defun execute-runner (directory)
  \"Conserva log, exit code e segnale OS del processo isolato già preparato.\"
  (let* ((log (merge-pathnames \"test.log\" directory))
         (process (uiop:launch-program
                   '(\"sbcl\" \"--noinform\" \"--no-userinit\" \"--no-sysinit\"
                     \"--disable-debugger\" \"--script\" \"tools/writer-ready-isolated-build.lisp\")
                   :directory directory :output log :error-output :output)))
    (multiple-value-bind (exit signal) (uiop:wait-process process)
      (values (classify-result (read-text log) exit signal) exit log signal))))

(defun execute-tests (directory)
  \"Conserva il log per ciascun esito, inclusi errori di compilazione o avvio.\"
  (write-runner directory)
  (execute-runner directory))

(defun write-report (directory report)
  \"Sostituisce il registro solo dopo avere scritto la nuova copia completa.\"
  (with-open-file (stream (merge-pathnames \"report.next.lisp\" directory)
                          :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
  (uiop:rename-file-overwriting-target (merge-pathnames \"report.next.lisp\" directory)
                                     (merge-pathnames \"report.lisp\" directory))
  report)

(defun verify-baseline (directory)
  \"La baseline invariata deve completare tutta execution, con log conservato prima del gate.\"
  (let ((baseline (merge-pathnames \"baseline/\" directory)))
    (copy-test-system baseline)
    (multiple-value-bind (result exit log signal) (execute-tests baseline)
      (list :result result :exit-code exit :signal signal :log (namestring log)))))

(defun execute-mutation (mutant ordinal directory)
  \"Copia privata per mutante, senza modificare il checkout della campagna.\"
  (let ((copy (merge-pathnames (format nil \"~D/\" ordinal) directory)))
    (copy-test-system copy)
    (with-open-file (stream (merge-pathnames (second mutant) copy)
                            :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string (mutated-source mutant) stream))
    (multiple-value-bind (result exit log signal) (execute-tests copy)
      (list :name (first mutant) :source-file (second mutant)
            :result result :exit-code exit :signal signal :log (namestring log)))))

(defun acquire-directory (path)
  \"MKDIR esclusivo 0700; la directory preesistente è intangibile.\"
  (let ((directory (uiop:ensure-directory-pathname (merge-pathnames path (uiop:getcwd)))))
    (ensure-directories-exist
     (merge-pathnames \"parent-placeholder\" (uiop:pathname-parent-directory-pathname directory)))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun initial-report (directory mutants)
  \"Plist preinizializzata prima della baseline, con sorgenti e ogni tentativo identificabili.\"
  (list :schema-version 1 :kind :writer-ready-mutations :status :running :stage :validation
        :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :targets mutants :planned-mutants (length mutants)
        :baseline :pending :baseline-result nil :baseline-exit-code nil :baseline-signal nil
        :baseline-log (namestring (merge-pathnames \"baseline/test.log\" directory))
        :mutants nil :current-ordinal nil :current-mutant nil :current-log nil :diagnostic nil
        :detected 0 :survived 0 :compilation-failures 0 :before-tests 0 :worker-errors 0
        :limits '(:targeted-mutants-only :complete-execution-suite :strict-compilation
                  :test-events-at-line-start :partial-campaign-preserved :exclusive-directory
                  :no-pool-device-durability-or-performance-qualification)))

(defun append-result (report result)
  \"Registra esito e conteggi prima del prossimo mutante.\"
  (setf (getf report :mutants) (append (getf report :mutants) (list result)))
  (dolist (pair '((:detected :detected) (:survived :survived)
                  (:compilation-failures :compilation-failure) (:before-tests :before-tests)
                  (:worker-errors :worker-error)))
    (setf (getf report (first pair))
          (count (second pair) (getf report :mutants) :key (lambda (entry) (getf entry :result)))))
  report)

(defun finish-report (directory report)
  \"Fotografa la stabilità anche al fallimento e salva i risultati raccolti.\"
  (let ((after (fingerprints)))
    (setf (getf report :source-fingerprints-after) after
          (getf report :source-consistency)
          (if (equal (getf report :source-fingerprints-before) after) :stable :changed))
    (when (and (eq :ok (getf report :status)) (eq :changed (getf report :source-consistency)))
      (setf (getf report :status) :source-changed
            (getf report :diagnostic) \"COD-61: sorgenti cambiati durante la campagna ready.\")))
  (write-report directory report)
  (format t \"~&Writer ready: ~A, baseline ~A, rilevati ~D/~D; ~A~%\"
          (getf report :status) (getf report :baseline) (getf report :detected)
          (getf report :planned-mutants) (merge-pathnames \"report.lisp\" directory))
  report)

(defun run-campaign (path &key (mutants (mutation-list)) (validator #'validate-mutations)
                             (baseline-runner #'verify-baseline) (mutant-runner #'execute-mutation))
  \"Persiste prima e dopo ogni prova; setup, baseline e risultati parziali restano visibili.\"
  (let* ((directory (acquire-directory path)) (report (initial-report directory mutants)))
    (handler-case
        (progn
          (write-report directory report) (funcall validator mutants)
          (setf (getf report :stage) :baseline) (write-report directory report)
          (let* ((baseline (funcall baseline-runner directory))
                 (passed (and (eq :survived (getf baseline :result))
                              (eql 0 (getf baseline :exit-code)))))
            (setf (getf report :baseline) (if passed :passed :failed)
                  (getf report :baseline-result) (getf baseline :result)
                  (getf report :baseline-exit-code) (getf baseline :exit-code)
                  (getf report :baseline-signal) (getf baseline :signal)
                  (getf report :baseline-log) (getf baseline :log))
            (write-report directory report)
            (unless passed (error \"COD-61: baseline ready fallita; ~A\" baseline)))
          (loop for mutant in mutants for ordinal from 0
                do (setf (getf report :stage) :mutants (getf report :current-ordinal) ordinal
                         (getf report :current-mutant) (first mutant) (getf report :current-log)
                         (namestring (merge-pathnames (format nil \"~D/test.log\" ordinal) directory)))
                   (write-report directory report)
                   (append-result report (funcall mutant-runner mutant ordinal directory))
                   (write-report directory report))
          (setf (getf report :stage) :complete (getf report :current-ordinal) nil
                (getf report :current-mutant) nil (getf report :current-log) nil)
          (unless (= (length mutants) (getf report :detected))
            (error \"COD-61: mutanti ready rilevati ~D/~D.\" (getf report :detected) (length mutants)))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))))
    (finish-report directory report)))

(defun assert-self-test (expression description)
  \"Il self-test segnala la regola dello strumento che non è stata rilevata.\"
  (unless expression (error \"COD-60: writer-ready-mutation.lisp, self-test ~A.\" description)))

(defun fresh-self-test-directory ()
  \"Fixture esclusiva, al più mille collisioni, nessun percorso esterno da rimuovere.\"
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil \"arcdocdb-ready-mutation-~D-~D-~D/\"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error \"COD-60: directory fixture ready non disponibile.\"))

(defun self-test-log (directory relative)
  \"Evento sintetico esplicito; nessun processo figlio durante la fixture del reporter.\"
  (let ((path (merge-pathnames relative directory)))
    (ensure-directories-exist path)
    (with-open-file (stream path :direction :output :if-exists :error)
      (write-line \"evento sintetico del self-test\" stream))
    (namestring path)))

(defun self-test-process-signal ()
  \"Un child fixture si termina con SIGKILL; trasporto e report conservano la prova.\"
  (let* ((directory (acquire-directory
                    (format nil \"spikes/out/~D-ready-signal-self-test-~D/\"
                            (get-universal-time) (sb-posix:getpid))))
         (runner (merge-pathnames \"tools/writer-ready-isolated-build.lisp\" directory))
         (report (initial-report directory '((\"signal-fixture\" \"fixture\" nil)))))
    (setf (getf report :kind) :process-signal-self-test (getf report :stage) :runner)
    (write-report directory report)
    (ensure-directories-exist runner)
    (with-open-file (stream runner :direction :output :if-exists :error)
      (dolist (form '((require :sb-posix)
                      (format t \"~&execution-test-start SIGNAL-FIXTURE~%\")
                      (finish-output)
                      (sb-posix:kill (sb-posix:getpid) sb-posix:sigkill)))
        (write form :stream stream :pretty t) (terpri stream)))
    (multiple-value-bind (result exit log signal) (execute-runner directory)
      (append-result report
        (list :name \"signal-fixture\" :result result :exit-code exit
              :signal signal :log (namestring log)))
      (write-report directory report)
      (assert-self-test (and (eq result :worker-error)
                             (eql signal sb-posix:sigkill)
                             (not (eql exit 0))
                             (event-at-line-start-p (read-text log) \"execution-test-start \"))
                        :signaled-process-never-detected)
      (let* ((*read-eval* nil)
             (saved (with-open-file (stream (merge-pathnames \"report.lisp\" directory))
                      (read stream)))
             (entry (first (getf saved :mutants))))
        (assert-self-test (and (= 1 (getf saved :worker-errors))
                               (zerop (getf saved :detected))
                               (eql exit (getf entry :exit-code))
                               (eql signal (getf entry :signal)))
                          :signal-report-preserved)))
    (setf (getf report :status) :passed (getf report :stage) :complete)
    (finish-report directory report)
    (format t \"~&Writer ready: self-test segnale OS superato; ~A~%\"
            (merge-pathnames \"report.lisp\" directory))))

(defun self-test-reporter ()
  \"Preserva una destinazione esistente e un risultato prima di un guasto tardivo.\"
  (let ((root (fresh-self-test-directory)))
    (unwind-protect
         (let* ((existing (acquire-directory (merge-pathnames \"existing/\" root)))
                (marker (self-test-log existing \"unchanged.log\")) (before (read-text marker))
                (campaign (merge-pathnames \"partial/\" root))
                (mutants '((\"fixture-one\" \"source\" nil) (\"fixture-two\" \"source\" nil))))
           (assert-self-test (handler-case (progn (acquire-directory existing) nil) (error () t))
                             :existing-directory-rejected)
           (assert-self-test (string= before (read-text marker)) :existing-directory-preserved)
           (let ((*standard-output* (make-broadcast-stream)))
             (run-campaign campaign :mutants mutants :validator (constantly nil)
               :baseline-runner (lambda (directory)
                                  (list :result :survived :exit-code 0
                                        :log (self-test-log directory \"baseline/test.log\")))
               :mutant-runner (lambda (mutant ordinal directory)
                                (when (= ordinal 1) (error \"fixture: secondo avvio interrotto\"))
                                (list :name (first mutant) :result :detected :exit-code 1
                                      :log (self-test-log directory \"0/test.log\")))))
           (let* ((*read-eval* nil)
                  (saved (with-open-file (stream (merge-pathnames \"report.lisp\" campaign))
                           (read stream))))
             (assert-self-test (and (= 1 (getf saved :schema-version))
                                    (eq :failed (getf saved :status))
                                    (eq :passed (getf saved :baseline))
                                    (= 1 (getf saved :current-ordinal))
                                    (string= \"fixture-two\" (getf saved :current-mutant))
                                    (search \"secondo avvio\" (getf saved :diagnostic))
                                    (= 1 (length (getf saved :mutants)))
                                    (= 1 (getf saved :detected))
                                    (probe-file (getf saved :baseline-log))
                                    (probe-file (getf (first (getf saved :mutants)) :log)))
                               :partial-report-preserved)))
      ;; C4: ROOT appartiene soltanto alla fixture dopo MKDIR esclusivo.
      (uiop:delete-directory-tree root :validate t))))

(defun self-test ()
  \"Dimostra marker autentici, classificazioni, bersagli invalidi e report parziali.\"
  (let ((start \"execution-test-start TEST\") (complete \"execution-tests-complete 1\"))
    (assert-self-test (eq :detected (classify-result start 1)) :detected)
    (assert-self-test (eq :survived (classify-result (format nil \"~A~%~A~%\" start complete) 0))
                      :complete-suite)
    (assert-self-test (eq :worker-error
                         (classify-result (format nil \"~A~%~A~%\" start complete) 1))
                      :completed-suite-failure)
    (assert-self-test (eq :worker-error (classify-result complete 1))
                      :completed-marker-failure)
    (assert-self-test (eq :detected
                         (classify-result (format nil \"~A~%Backtrace: ~A\" start complete) 1))
                      :quoted-completion-never-accepted)
    (dolist (text '(\"\" \"prefix execution-test-start TEST\" \"Backtrace: execution-test-start TEST\"
                    \"(FORMAT T \\\"execution-test-start ~A\\\")\"))
      (assert-self-test (eq :before-tests (classify-result text 1)) :quoted-marker))
    (assert-self-test (eq :before-tests (classify-result start 0)) :incomplete-suite)
    (assert-self-test (eq :before-tests (classify-result start nil)) :missing-exit)
    (dolist (failure '(\"compilation aborted\" \"COMPILE-FILE-ERROR\" \"COMPILE-FILE-WARNED\"
                       \"STYLE-WARNING non ammesso (COD-01)\"))
      (assert-self-test (eq :compilation-failure
                           (classify-result (format nil \"~A~%~A\" start failure) 1))
                        :compilation-never-detected)))
  (assert-self-test (string= \"xBy\" (mutate-once \"xAy\" \"A\" \"B\" \"fixture\")) :substitution)
  (dolist (case '((\"AA\" \"A\" \"B\") (\"x\" \"A\" \"B\") (\"A\" \"A\" \"A\") (\"A\" \"\" \"B\")))
    (assert-self-test (handler-case (progn (apply #'mutate-once (append case '(\"fixture\"))) nil)
                        (error () t)) :invalid-mutation))
  (validate-mutations (mutation-list))
  (self-test-process-signal)
  (self-test-reporter)
  (format t \"~&Writer ready: self-test superato, nessuna campagna eseguita.~%\")
  t)

(defun main ()
  \"CLI C4, mai campagna implicita, diagnostica e exit nonzero per regola violata.\"
  (handler-case
      (let ((args (uiop:command-line-arguments)))
        (cond ((equal args '(\"--self-test\")) (self-test))
              ((and (= (length args) 2) (string= (first args) \"--run\"))
               (let ((report (run-campaign (second args))))
                 (unless (eq :ok (getf report :status))
                   (format *error-output* \"~&writer-ready-mutation.lisp: ~A~%\"
                           (getf report :diagnostic))
                   (uiop:quit 1))))
              (t (error \"COD-61: uso --self-test oppure --run directory-nuova/.\"))))
    (error (condition)
      (format *error-output* \"~&writer-ready-mutation.lisp: ~A~%\" condition)
      (uiop:quit 1))))

(main)
"))
 :REVIEW-DOCUMENT
 (:PATH "docs/implementazione/writer-ready-revisione.md" :BYTES 4269 :SHA256
  "1cf7c83838ab382a27e0cdf3081fd39c2fe78f3478611c4aaef3526ba1a2feee" :GIT-BLOB
  "caafe0a8685e4faf2215bebe5f37fd1a80683f93" :TEXT
  "# Revisione della lista dei writer pronti

Ambito C1: i due sorgenti della lista pronta, API/ASDF e composizione con
handoff. Nessun cambiamento persistente o qualifica dell'intero scheduler.

## Lettura dell'autore

| Punto C1 | Esito e ambito |
|---|---|
| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0045 §§6/8, ADR-0005. La lista pronta condivisa è toccata per tratto, senza coda comune per richiesta. |
| 2. Invarianti | FIFO locale, esclusività della guard, capacità finita e proprietà dell'obbligo. La macchina del writer resta nel precedente handoff; nessuna seconda membership da sincronizzare. Oracoli e prove concorrenti sono verificati nella campagna separata. |
| 3. Errori | Input invalidi/full/busy precedono la mutazione. Busy della scansione è un risultato senza condizioni; il worker conserva il riferimento preso durante busy di avvio. Invarianti segnalati al proprietario per fail-stop, senza rollback o controller implicito. |
| 4. Limiti | Factory <=64 partizioni; scansione <=64 acquisizioni, <=128 CAS inclusi i rilasci. Nessun retry, spin, ricorsione o attesa nel prodotto; ring <=65536 slot. |
| 5. Allocazioni | Strutture/ring all'avvio; nessuna allocazione esplicita nel percorso normale. La campagna misura la composizione handoff/lista, non startup o condizioni d'errore; si riporta il heap osservato senza promessa universale. |
| 6. Dati | La lista trasporta riferimenti al tipo writer verificato; non interpreta payload o dati persistenti e non legge lo stato del writer. Nessun callback, I/O o risposta del motore. |
| 7. Decisioni | Controlli scalari separati, CASE/default e cleanup inventariati. Nessun nuovo and/or composto; raw ed esiti restano nel denominatore completo senza esclusioni approvate o MC/DC implicita. |
| 8. Proprietà | Partizioni/slots/capacity privati e read-only dove applicabile, copier assenti. Indici e contenuti sotto guard, cursore locale del worker. Obbligo caller→ring→worker; esattamente una pubblicazione è una precondizione del chiamante. |
| 9. Check | `make check` su 33aa224: 294 test più smoke, lint su 52 file senza violazioni, trace/link/evidence e dieci spike superati; record 4000522904-command-41347-0 OK/STABLE/exit0. I gate del motore restano aperti. |
| 10. Standard | Safety3, ftype/slot tipizzati, docstring, funzioni <=60 righe e complessità <=7. Strumenti C4 con self-test e preservazione dei rapporti parziali; nessuna deviazione introdotta. |
| 11. Parallelismo | Guard indipendenti per partizione, nessuna guard/contatore globale, nessuna scrittura comune per messaggio. Il lavoro dei writer avviene fuori dalle guard della ready list. Non si promettono lock-freedom, bilanciamento o starvation temporale. |
| 12. Atomicità | Nessun cambiamento durevole o eliminazione. La pubblicazione e il prelievo FIFO avvengono sotto la guard locale; non esiste cleanup scheduler che possa cancellare un'ondata successiva del writer. |

La prima lettura indipendente ha chiesto due precisazioni delle docstring,
chiuse nei sorgenti: cleanup dopo acquisizione verificata; allocazioni del
solo percorso normale. L'[inventario](writer-ready-decisioni.md) conserva
hash iniziali e finali e i confini della lettura.

Risvegli, parcheggio dopo empty, arresto dei worker, controller e pool
adattivo richiedono integrazione. La lista non garantisce progresso se il
chiamante duplica o abbandona l'obbligo. Questo limite non viene nascosto
dal risultato positivo di una fixture FIFO isolata.

## Chiusura della verifica integrata

La lettura indipendente iniziale conserva i dodici punti e i due rilievi
chiusi. Le appendici verificano l'integrazione con `fd96fb3`, `201562d` e infine `33aa224`, il runner
C4 corretto e il check completo, con gli stessi sorgenti ready e test.
Il runner separa segnali OS e fallimenti dopo completion reale dai mutanti
rilevati: SIGKILL effettivo è `:worker-error`; la campagna ripetuta rileva
12/12 mutanti con signal NIL e nessun worker error. Le due campagne e le
versioni degli strumenti rimangono nel
[catalogo](../../spikes/results/2026-10-09-writer-ready/catalogo.lisp), insieme
alle letture originali, probe e rapporti di processo. Nessuna esclusione
approvata, MC/DC completa o qualifica del pool viene dedotta dai risultati.
")
 :REPORT-ORIGINAL "# Revisione della lista dei writer pronti

Ambito C1: i due sorgenti della lista pronta, API/ASDF e composizione con
handoff. Nessun cambiamento persistente o qualifica dell'intero scheduler.

## Lettura dell'autore

| Punto C1 | Esito e ambito |
|---|---|
| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0045 §§6/8, ADR-0005. La lista pronta condivisa è toccata per tratto, senza coda comune per richiesta. |
| 2. Invarianti | FIFO locale, esclusività della guard, capacità finita e proprietà dell'obbligo. La macchina del writer resta nel precedente handoff; nessuna seconda membership da sincronizzare. Oracoli e prove concorrenti sono verificati nella campagna separata. |
| 3. Errori | Input invalidi/full/busy precedono la mutazione. Busy della scansione è un risultato senza condizioni; il worker conserva il riferimento preso durante busy di avvio. Invarianti segnalati al proprietario per fail-stop, senza rollback o controller implicito. |
| 4. Limiti | Factory <=64 partizioni; scansione <=64 acquisizioni, <=128 CAS inclusi i rilasci. Nessun retry, spin, ricorsione o attesa nel prodotto; ring <=65536 slot. |
| 5. Allocazioni | Strutture/ring all'avvio; nessuna allocazione esplicita nel percorso normale. La campagna misura la composizione handoff/lista, non startup o condizioni d'errore; si riporta il heap osservato senza promessa universale. |
| 6. Dati | La lista trasporta riferimenti al tipo writer verificato; non interpreta payload o dati persistenti e non legge lo stato del writer. Nessun callback, I/O o risposta del motore. |
| 7. Decisioni | Controlli scalari separati, CASE/default e cleanup inventariati. Nessun nuovo and/or composto; raw ed esiti restano nel denominatore completo senza esclusioni approvate o MC/DC implicita. |
| 8. Proprietà | Partizioni/slots/capacity privati e read-only dove applicabile, copier assenti. Indici e contenuti sotto guard, cursore locale del worker. Obbligo caller→ring→worker; esattamente una pubblicazione è una precondizione del chiamante. |
| 9. Check | `make check` su 33aa224: 294 test più smoke, lint su 52 file senza violazioni, trace/link/evidence e dieci spike superati; record 4000522904-command-41347-0 OK/STABLE/exit0. I gate del motore restano aperti. |
| 10. Standard | Safety3, ftype/slot tipizzati, docstring, funzioni <=60 righe e complessità <=7. Strumenti C4 con self-test e preservazione dei rapporti parziali; nessuna deviazione introdotta. |
| 11. Parallelismo | Guard indipendenti per partizione, nessuna guard/contatore globale, nessuna scrittura comune per messaggio. Il lavoro dei writer avviene fuori dalle guard della ready list. Non si promettono lock-freedom, bilanciamento o starvation temporale. |
| 12. Atomicità | Nessun cambiamento durevole o eliminazione. La pubblicazione e il prelievo FIFO avvengono sotto la guard locale; non esiste cleanup scheduler che possa cancellare un'ondata successiva del writer. |

La prima lettura indipendente ha chiesto due precisazioni delle docstring,
chiuse nei sorgenti: cleanup dopo acquisizione verificata; allocazioni del
solo percorso normale. L'[inventario](writer-ready-decisioni.md) conserva
hash iniziali e finali e i confini della lettura.

Risvegli, parcheggio dopo empty, arresto dei worker, controller e pool
adattivo richiedono integrazione. La lista non garantisce progresso se il
chiamante duplica o abbandona l'obbligo. Questo limite non viene nascosto
dal risultato positivo di una fixture FIFO isolata.

## Chiusura della verifica integrata

La lettura indipendente iniziale conserva i dodici punti e i due rilievi
chiusi. Le appendici verificano l'integrazione con `fd96fb3`, `201562d` e infine `33aa224`, il runner
C4 corretto e il check completo, con gli stessi sorgenti ready e test.
Il runner separa segnali OS e fallimenti dopo completion reale dai mutanti
rilevati: SIGKILL effettivo è `:worker-error`; la campagna ripetuta rileva
12/12 mutanti con signal NIL e nessun worker error. Le due campagne e le
versioni degli strumenti rimangono nel
[catalogo](../../spikes/results/2026-10-09-writer-ready/catalogo.lisp), insieme
alle letture originali, probe e rapporti di processo. Nessuna esclusione
approvata, MC/DC completa o qualifica del pool viene dedotta dai risultati.
"
 :INTEGRATED-CHECK "spikes/out/4000522904-command-41347-0/report.lisp" :LIMITS
 (:LOCAL-PRIMITIVE-ONLY :RAW-COVERAGE-GAPS-RETAINED :NO-APPROVED-EXCLUSIONS
  :NO-COMPLETE-MCDC :NO-ENGINE-POOL-OR-PERFORMANCE-QUALIFICATION))
