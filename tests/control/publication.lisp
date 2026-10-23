;;;; Percorso funzionale ACTIVE -> checkpoint -> pubblicazione, backend esclusivamente in memoria.
;;; OWNER: ogni test possiede mappe FD/nomi/byte, capacità, hook e registro eventi della sua fixture.
;;; SHARED: fixture autonome; soltanto la FI CAS usa un wrapper globale temporaneo di preflight.
;;; La FI CAS richiede runner seriale, resta sul prepared della fixture e ripristina dopo i join.
;;; LIMITI: file <= 4096 byte, <= 32 FD, <= 4096 eventi; cicli su input finiti.
;;; Non prova power-loss, assenza di heap, motore completo o esclusività verso altri processi.
(in-package #:arcdocdb.control.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defstruct control-memory-node (bytes (zeros 0)) (device 9) (inode 0) directory-p)
(defstruct control-memory-fd node mode closed-p)
(defstruct (control-fixture (:constructor %make-control-fixture) (:conc-name cf-))
  (names (make-hash-table :test 'equal)) (fds (make-hash-table :test 'eql))
  (counts (make-hash-table :test 'eq)) (events (make-array 64 :adjustable t :fill-pointer 0))
  (next-fd 100) (next-inode 1000) (files nil) (workers nil) backend hook short-transfer
  identity view directory active-input active-append active header
  control-input control-append previous old-node old-bytes payload expected plan prepared
  (version 2) (chunk 31))

;;; OWNER: timeout della fixture concorrente, distinto da assertion/product error.
(define-condition control-fixture-timeout (error)
  ((phase :initarg :phase :reader control-timeout-phase))
  (:report (lambda (condition stream) (format stream "Timeout fixture CONTROL: ~A" (control-timeout-phase condition)))))

(defun control-pack (buffer start value width)
  "Oracolo little-endian, limitato alla larghezza del campo della fixture."
  (dotimes (i width) (setf (aref buffer (+ start i)) (ldb (byte 8 (* 8 i)) value)))
  buffer)

(defun control-crc (buffer start end)
  "Oracolo CRC32C bit per bit, senza codec o tabelle del prodotto."
  (let ((crc #xffffffff))
    (loop for i from start below end do
      (setf crc (logxor crc (aref buffer i)))
      (dotimes (bit 8)
        (setf crc (logxor (ash crc -1) (if (oddp crc) #x82f63b78 0)))))
    (logxor crc #xffffffff)))

(defun control-reference-header (identity version &optional segment-p)
  (let ((bytes (zeros 64)))
    (control-pack bytes 0 #x44435241 4)
    (control-pack bytes 4 (if segment-p #x31474553 #x314c5443) 4)
    (control-pack bytes 8 version 2)
    (replace bytes identity :start1 16)
    (when segment-p
      (setf (aref bytes 10) 1)
      (control-pack bytes 32 17 8)
      (control-pack bytes 40 #x123456789abcdef0 8))
    (control-pack bytes 56 (control-crc bytes 0 56) 4)
    bytes))

(defun control-reference-record (kind flags stamp payload)
  (let* ((size (+ 24 (length payload))) (bytes (zeros size)))
    (setf (aref bytes 8) kind (aref bytes 9) flags)
    (control-pack bytes 12 (length payload) 4)
    (control-pack bytes 16 stamp 8)
    (replace bytes payload :start1 24)
    (control-pack bytes 4 (control-crc bytes 24 size) 4)
    (control-pack bytes 0 (control-crc bytes 4 24) 4)
    bytes))

(defun control-reference-checkpoint (identity version payload &optional (stamp #x1020304050607080))
  (let* ((edit (control-reference-record 5 8 stamp payload)) (seal-value (zeros 32))
         (bytes (zeros (+ 144 (length payload)))))
    (control-pack seal-value 8 64 8)
    (control-pack seal-value 24 1 4)
    (control-pack seal-value 28 (control-crc edit 0 4) 4)
    (replace bytes (control-reference-header identity version))
    (replace bytes edit :start1 64)
    (replace bytes (control-reference-record 3 0 stamp seal-value) :start1 (+ 64 (length edit)))
    bytes))

(defun control-payload (&key (active 17) (next 18) (rich t))
  "Fonte autorevole della fixture: CLOSED 11/120, esito TXID101/CSN alto, REMOVED7.
L'inventario fisico CLOSED resta fuori ambito; nessun risultato CONTROL viene forgiato."
  (let ((closed (zeros (if rich 36 0))) (removed (zeros (if rich 8 0))))
    (when rich
      (control-pack closed 0 11 8) (control-pack closed 8 120 8)
      (control-pack closed 16 1 4) (control-pack closed 20 101 8)
      (control-pack closed 28 #x100000002 8) (control-pack removed 0 7 8))
    (let ((bytes (zeros (+ 24 (length closed) (length removed)))))
      (is (= (length bytes)
             (arcdocdb.storage.format:scrivi-valore-edit
              bytes 0 next active closed (if rich 1 0) removed :completo t)))
      bytes)))

(defun control-node (fixture name)
  (or (gethash name (cf-names fixture))
      (error 'sb-posix:syscall-error :errno sb-posix:enoent :name 'control-memory-entry)))

(defun control-handle (fixture fd)
  (let ((handle (gethash fd (cf-fds fixture))))
    (unless (and handle (not (control-memory-fd-closed-p handle)))
      (error 'sb-posix:syscall-error :errno sb-posix:ebadf :name 'control-memory-fd))
    handle))

(defun control-observe (fixture operation arguments thunk)
  "Registra prima del callback: anche un errore/nonlocal conserva l'evento tentato."
  (when (>= (length (cf-events fixture)) 4096) (error "Budget eventi CONTROL esaurito."))
  (let ((ordinal (incf (gethash operation (cf-counts fixture) 0))))
    (vector-push-extend (cons operation arguments) (cf-events fixture))
    (multiple-value-bind (override first second)
        (when (cf-hook fixture) (funcall (cf-hook fixture) fixture operation ordinal arguments))
      (if override (values first second) (funcall thunk)))))

(defun control-memory-open (fixture name mode)
  (control-observe
   fixture :open (list name mode)
   (lambda ()
     (when (>= (hash-table-count (cf-fds fixture)) 32) (error "Budget FD CONTROL esaurito."))
     (let ((node (if (eq mode :append)
                     (progn
                       (when (gethash name (cf-names fixture))
                         (error 'sb-posix:syscall-error :errno sb-posix:eexist :name 'control-memory-open))
                       (setf (gethash name (cf-names fixture))
                             (make-control-memory-node :inode (incf (cf-next-inode fixture)))))
                     (control-node fixture name))))
       (unless (eq (not (null (control-memory-node-directory-p node))) (eq mode :directory))
         (error 'sb-posix:syscall-error :errno sb-posix:einval :name 'control-memory-open))
       (let ((fd (incf (cf-next-fd fixture))))
         (setf (gethash fd (cf-fds fixture)) (make-control-memory-fd :node node :mode mode))
         fd)))))

(defun control-memory-read (fixture fd buffer start count offset)
  (control-observe
   fixture :read (list fd start count offset)
   (lambda ()
     (let* ((handle (control-handle fixture fd))
            (bytes (control-memory-node-bytes (control-memory-fd-node handle)))
            (size (min count (or (cf-short-transfer fixture) count) (max 0 (- (length bytes) offset)))))
       (is (eq :input (control-memory-fd-mode handle)))
       (when (plusp size)
         (replace buffer bytes :start1 start :end1 (+ start size) :start2 offset :end2 (+ offset size)))
       size))))

(defun control-memory-write (fixture fd buffer start count)
  (control-observe
   fixture :write (list fd start count)
   (lambda ()
     (let* ((handle (control-handle fixture fd)) (node (control-memory-fd-node handle))
            (old (control-memory-node-bytes node)) (size (min count (or (cf-short-transfer fixture) count)))
            (end (+ (length old) size)))
       (is (eq :append (control-memory-fd-mode handle)))
       (when (> end 4096) (error "Budget byte CONTROL esaurito."))
       (let ((bytes (zeros end)))
         (replace bytes old)
         (replace bytes buffer :start1 (length old) :start2 start :end2 (+ start size))
         (setf (control-memory-node-bytes node) bytes))
       size))))

(defun control-memory-zero (fixture operation fd)
  (control-observe fixture operation (list fd)
                   (lambda () (control-handle fixture fd) 0)))

(defun control-memory-identity (fixture fd)
  (control-observe
   fixture :identity (list fd)
   (lambda ()
     (let ((node (control-memory-fd-node (control-handle fixture fd))))
       (is (not (control-memory-node-directory-p node)))
       (values (control-memory-node-device node) (control-memory-node-inode node))))))

(defun control-memory-entry (fixture fd leaf)
  (control-observe
   fixture :entry (list fd (copy-seq leaf))
   (lambda ()
     (is (eq :directory (control-memory-fd-mode (control-handle fixture fd))))
     (let ((node (control-node fixture (concatenate 'string "/control-fixture/" leaf))))
       (is (not (control-memory-node-directory-p node)))
       (values (control-memory-node-device node) (control-memory-node-inode node))))))

(defun control-memory-rename (fixture fd source target)
  (control-observe
   fixture :rename (list fd (copy-seq source) (copy-seq target))
   (lambda ()
     (is (eq :directory (control-memory-fd-mode (control-handle fixture fd))))
     (let* ((from (concatenate 'string "/control-fixture/" source))
            (to (concatenate 'string "/control-fixture/" target)) (node (control-node fixture from)))
       (setf (gethash to (cf-names fixture)) node)
       (is (remhash from (cf-names fixture)))
       0))))

(defun control-memory-backend (fixture &optional missing)
  (io:make-backend
   (lambda (name mode) (control-memory-open fixture name mode))
   (lambda (fd bytes start count offset) (control-memory-read fixture fd bytes start count offset))
   (lambda (fd bytes start count) (control-memory-write fixture fd bytes start count))
   (lambda (fd) (control-memory-zero fixture :flush fd))
   (lambda (fd) (control-memory-zero fixture :directory-flush fd))
   (lambda (fd)
     (control-observe fixture :close (list fd)
                      (lambda () (setf (control-memory-fd-closed-p (control-handle fixture fd)) t) 0)))
   :identity (unless (eq missing :identity) (lambda (fd) (control-memory-identity fixture fd)))
   :entry-identity (unless (eq missing :entry) (lambda (fd leaf) (control-memory-entry fixture fd leaf)))
   :rename (unless (eq missing :rename) (lambda (fd source target) (control-memory-rename fixture fd source target)))))

(defun control-own (fixture file)
  (push file (cf-files fixture))
  file)

(defun control-clear (fixture)
  (setf (fill-pointer (cf-events fixture)) 0)
  (clrhash (cf-counts fixture))
  nil)

(defun control-events (fixture)
  (coerce (cf-events fixture) 'list))

(defun control-operations (fixture)
  (mapcar #'car (control-events fixture)))

(defun control-count (fixture operation)
  (gethash operation (cf-counts fixture) 0))

(defun control-cleanup (fixture)
  "Solo il caller chiude: disabilita FI prima del cleanup di capacità possedute."
  (when (some #'sb-thread:thread-alive-p (cf-workers fixture))
    (error 'control-fixture-timeout :phase :cleanup-capabilities))
  (setf (cf-hook fixture) nil)
  (dolist (file (cf-files fixture)) (io:chiudi file))
  nil)

(defun control-view (identity)
  "Factory canoniche; nessun %make di ACTIVE, vista o risultati CONTROL."
  (let* ((csns (arcdocdb.csn:crea-registro-csn :capacity 3))
         (snapshots (arcdocdb.mvcc:crea-registro-snapshot csns 2 20 5))
         (epochs (arcdocdb.epochs:crea-registro-epoche 2 2))
         (primary (arcdocdb.index.primary:crea-indice-primario
                   :capacity 16 :max-depth 1 :arena-bytes 256
                   :directory-budget-bytes 16 :fragment-budget-bytes 912
                   :hash-seed-high 23 :hash-seed-low 29)))
    (g:crea-vista-get-serie (g:crea-ambito-get epochs snapshots) primary nil identity)))

(defun control-open-files (fixture read-transfer write-transfer file-limit)
  (let ((backend (cf-backend fixture)))
    (setf (cf-control-append fixture)
          (control-own fixture (io:crea-temporaneo "/control-fixture/control.log.tmp" :backend backend
                                                 :max-transfer write-transfer :max-file-bytes file-limit))
          (cf-control-input fixture)
          (control-own fixture (io:apri-lettura "/control-fixture/control.log.tmp" :backend backend
                                              :max-transfer read-transfer)))))

(defun control-prepare (fixture &optional (scratch (zeros (cf-chunk fixture))) (chunk (cf-chunk fixture)))
  (c:prepara-checkpoint-control (cf-plan fixture) (cf-control-input fixture) (cf-control-append fixture)
                               (cf-directory fixture) scratch :chunk-bytes chunk))

(defun control-validate-previous (fixture)
  (let* ((bytes (zeros (length (cf-old-bytes fixture)))) (size (length bytes)))
    (is (= size (io:leggi-esatto (cf-previous fixture) bytes 0 size 0)))
    (is (equalp bytes (cf-old-bytes fixture)))
    (is (= 64 (arcdocdb.storage.format:verifica-header-log bytes 0 size :control (cf-identity fixture))))
    (multiple-value-bind (manifest prefix status)
        (arcdocdb.recovery.manifest:ricostruisci-manifest bytes 64 size :version (cf-version fixture)
                                                        :file-size size :max-batches 1 :max-batch-records 1)
      (is (= prefix size)) (is (eq status :complete))
      (is (= 11 (arcdocdb.recovery.manifest:segmento-attivo manifest))))))

(defun make-control-fixture (&key (version 2) (stage :prepared) (chunk 31) missing
                                 (read-transfer 4096) (write-transfer 4096) (file-limit 4096))
  (let* ((identity (zeros 16)) (f (%make-control-fixture :version version :chunk chunk :identity identity))
         (complete nil))
    (dotimes (i 16) (setf (aref identity i) (+ 32 i)))
    (unwind-protect
         (progn
           (setf (cf-backend f) (control-memory-backend f missing) (cf-view f) (control-view identity)
                 (gethash "/control-fixture" (cf-names f))
                 (make-control-memory-node :inode 1 :directory-p t)
                 (cf-old-bytes f) (control-reference-checkpoint identity version (control-payload :active 11 :rich nil))
                 (cf-old-node f) (make-control-memory-node :inode 2 :bytes (copy-seq (cf-old-bytes f)))
                 (gethash "/control-fixture/control.log" (cf-names f)) (cf-old-node f))
           (let ((backend (cf-backend f)))
             (setf (cf-directory f) (control-own f (io:apri-directory "/control-fixture/" :backend backend))
                   (cf-active-append f) (control-own f (io:crea-temporaneo "/control-fixture/segment-17.tmp" :backend backend))
                   (cf-active-input f) (control-own f (io:apri-lettura "/control-fixture/segment-17.tmp" :backend backend))
                   (cf-previous f) (control-own f (io:apri-lettura "/control-fixture/control.log" :backend backend))))
           (control-validate-previous f)
           (setf (cf-header f) (zeros 64)
                 (cf-active f) (a:prepara-segmento-attivo (cf-view f) (cf-active-input f) (cf-active-append f)
                                                        (cf-directory f) 17 #x123456789abcdef0
                                                        (cf-header f) (zeros 64) :version version)
                 (cf-payload f) (control-payload)
                 (cf-expected f) (control-reference-checkpoint identity version (cf-payload f)))
           (unless (eq stage :active)
             (setf (cf-plan f) (c:crea-checkpoint-control (cf-active f) (cf-payload f) #x1020304050607080)))
           (control-open-files f read-transfer write-transfer file-limit)
           (control-clear f)
           (when (eq stage :prepared) (setf (cf-prepared f) (control-prepare f)) (control-clear f))
           (setf complete t)
           f)
      (unless complete (control-cleanup f)))))

(defmacro with-control-fixture ((fixture &rest options) &body body)
  `(let ((,fixture (make-control-fixture ,@options)))
     (unwind-protect (progn ,@body) (control-cleanup ,fixture))))

(defun control-publish (fixture)
  (c:pubblica-control-recuperato (cf-prepared fixture) (cf-previous fixture)))

(defun control-check-state (fixture state observed)
  (is (equal (list state observed)
             (multiple-value-list (c:stato-pubblicazione-control (cf-prepared fixture))))))

(defun control-check-old (fixture &optional (installed nil))
  (is (equalp (cf-old-bytes fixture) (control-memory-node-bytes (cf-old-node fixture))))
  (is (eq (cf-old-node fixture)
          (control-memory-fd-node (control-handle fixture (io::file-fd (cf-previous fixture))))))
  (unless installed
    (is (eq (cf-old-node fixture) (control-node fixture "/control-fixture/control.log")))))

(defun control-check-no-hidden-effects (fixture)
  (dolist (operation '(:open :read :write :flush :close)) (is (zerop (control-count fixture operation)))))

(defun control-check-retry-refused (fixture state observed)
  (let ((events (control-events fixture)))
    (signals invalid-argument (control-publish fixture) :control-publication-state)
    (is (equal events (control-events fixture)))
    (control-check-state fixture state observed)))

(defun control-check-success (fixture result)
  (is (typep result 'c:control-pubblicato))
  (control-check-state fixture :published t)
  (is (eq (c:log-control-preparato (cf-prepared fixture)) (c:log-control-pubblicato result)))
  (is (eq (c:manifest-checkpoint-control (cf-plan fixture)) (c:manifest-control-pubblicato result)))
  (is (eq (cf-active fixture) (c:active-control-pubblicato result)))
  (is (equal '(:identity :entry :identity :entry :rename :identity :entry :directory-flush)
             (control-operations fixture)))
  (is (equalp (cf-expected fixture) (control-memory-node-bytes (control-node fixture "/control-fixture/control.log"))))
  (is (null (gethash "/control-fixture/control.log.tmp" (cf-names fixture))))
  (control-check-old fixture t)
  (dolist (file (cf-files fixture)) (is (eq :open (io:stato-file file))))
  (control-check-no-hidden-effects fixture)
  (control-check-retry-refused fixture :published t))

;;; REQ: REQ-FOR-001 REQ-FOR-003 REQ-REC-001
(deftest test-REQ-FOR-001-CONTROL-canonical-active-and-checkpoint-v1-v2
  (dolist (version '(1 2))
    (with-control-fixture (f :version version :stage :plan)
      (is (equalp (control-reference-header (cf-identity f) version t) (cf-header f)))
      (is (= 64 (io:posizione-scritta (cf-active-append f)) (io:posizione-durevole (cf-active-append f))))
      (is (equalp (cf-expected f) (c::checkpoint-control-bytes (cf-plan f))))
      (is (= 212 (c:lunghezza-checkpoint-control (cf-plan f))))
      (is (null (control-events f))))))

;;; REQ: REQ-REC-001 REQ-FOR-003
(deftest test-REQ-REC-001-CONTROL-manifest-complete-state
  (with-control-fixture (f :stage :plan)
    (let ((manifest (c:manifest-checkpoint-control (cf-plan f))))
      (is (= 17 (arcdocdb.recovery.manifest:segmento-attivo manifest)))
      (is (equal '(t 18) (multiple-value-list (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))
      (is (= 1 (arcdocdb.recovery.manifest:numero-segmenti-chiusi manifest)))
      (is (= 1 (arcdocdb.recovery.manifest:numero-segmenti-rimossi manifest)))
      (is (equal '(:closed 120 1) (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest 11))))
      (is (equal '(:removed 0 0) (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest 7))))
      (is (equal '(t 4294967298) (multiple-value-list (arcdocdb.recovery.manifest:trova-esito-chiusura manifest 11 101)))))))

;;; REQ: REQ-AFF-008 REQ-FOR-003
(deftest test-REQ-AFF-008-CONTROL-builder-copies-caller-payload
  (with-control-fixture (f :stage :plan)
    (fill (cf-payload f) #xee)
    (is (equalp (cf-expected f) (c::checkpoint-control-bytes (cf-plan f))))
    (setf (cf-prepared f) (control-prepare f))
    (is (equalp (cf-expected f) (control-memory-node-bytes (control-node f "/control-fixture/control.log.tmp"))))))

;;; REQ: REQ-AFF-001 REQ-AFF-002 REQ-REC-001
(deftest test-REQ-REC-001-CONTROL-prepare-chunks-order-and-short-last-block
  (with-control-fixture (f :stage :plan :chunk 31)
    (setf (cf-prepared f) (control-prepare f))
    (is (equal (append '(:identity :identity :identity :identity) (make-list 7 :initial-element :write)
                      '(:flush) (make-list 7 :initial-element :read) '(:directory-flush))
               (control-operations f)))
    (let ((reads (remove-if-not (lambda (event) (eq :read (car event))) (control-events f)))
          (writes (remove-if-not (lambda (event) (eq :write (car event))) (control-events f))))
      (is (equal '(0 31 62 93 124 155 186) (mapcar #'fifth reads)))
      (is (equal '(31 31 31 31 31 31 26) (mapcar #'fourth reads)))
      (is (equal '(0 31 62 93 124 155 186) (mapcar #'third writes)))
      (is (equal '(31 31 31 31 31 31 26) (mapcar #'fourth writes))))
    (is (eq (c:manifest-checkpoint-control (cf-plan f)) (c:manifest-control-preparato (cf-prepared f))))
    (is (= 212 (io:posizione-scritta (cf-control-append f)) (io:posizione-durevole (cf-control-append f))))
    (control-check-state f :prepared nil)
    (control-check-old f)
    (is (zerop (control-count f :rename))) (is (zerop (control-count f :close)))))

;;; REQ: REQ-AFF-008 REQ-AFF-002
(deftest test-REQ-AFF-008-CONTROL-prepare-one-byte-and-oversized-chunks
  (dolist (chunk '(1 212 1024))
    (with-control-fixture (f :stage :plan :chunk chunk)
      (setf (cf-prepared f) (control-prepare f))
      (is (= (ceiling 212 chunk) (control-count f :write) (control-count f :read)))
      (is (equalp (cf-expected f) (control-memory-node-bytes (control-node f "/control-fixture/control.log.tmp")))))))

;;; REQ: REQ-AFF-001 REQ-AFF-002
(deftest test-REQ-AFF-001-CONTROL-prepare-positive-short-io
  (with-control-fixture (f :stage :plan)
    (setf (cf-short-transfer f) 3 (cf-prepared f) (control-prepare f))
    (is (> (control-count f :read) 7)) (is (> (control-count f :write) 7))
    (is (= 212 (io:posizione-scritta (cf-control-append f)) (io:posizione-durevole (cf-control-append f))))
    (is (equalp (cf-expected f) (control-memory-node-bytes (control-node f "/control-fixture/control.log.tmp"))))))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest test-REQ-REC-001-CONTROL-publication-success-accessors-and-retry
  (dolist (version '(1 2))
    (with-control-fixture (f :version version)
      (control-check-success f (control-publish f)))))

(defun control-caught (thunk)
  "Confine del test: conserva l'oggetto originale, inclusi errori esterni al prodotto."
  (handler-case (progn (funcall thunk) nil) (error (condition) condition)))

(defun control-rejection (fixture thunk type reason)
  (let ((before (control-events fixture)) (caught (control-caught thunk)))
    (is (typep caught type)) (is (eq reason (error-reason caught)))
    (is (equal before (control-events fixture)))
    (when (cf-prepared fixture) (control-check-state fixture :prepared nil))
    (control-check-old fixture)))

(defun control-inject-condition (fixture operation ordinal original)
  (setf (cf-hook fixture)
        (lambda (f op n arguments)
          (declare (ignore f arguments))
          (when (and (eq operation op) (= ordinal n)) (error original))
          nil)))

(defun control-check-publisher-fault (fixture observed directory-state &optional (installed observed))
  (control-check-state fixture :faulted observed)
  (is (eq directory-state (io:stato-file (cf-directory fixture))))
  (control-check-old fixture installed)
  (control-check-no-hidden-effects fixture)
  (control-check-retry-refused fixture :faulted observed))

;;; REQ: REQ-AFF-008 REQ-FOR-003
(deftest test-REQ-AFF-008-CONTROL-builder-payload-and-budget-preflight
  (with-control-fixture (f :stage :active)
    (dolist (budget '(0 23 16777217))
      (control-rejection f (lambda () (c:crea-checkpoint-control (cf-active f) (cf-payload f) 9 :max-payload budget))
                         'invalid-argument :control-checkpoint-budget))
    (dolist (payload (list (zeros 0) (zeros 23) (cf-payload f)))
      (control-rejection f (lambda () (c:crea-checkpoint-control (cf-active f) payload 9 :max-payload 24))
                         'resource-exhausted :control-checkpoint-payload))))

;;; REQ: REQ-REC-001 REQ-FOR-003
(deftest test-REQ-REC-001-CONTROL-builder-rejects-other-active
  (with-control-fixture (f :stage :active)
    (control-rejection f (lambda () (c:crea-checkpoint-control (cf-active f) (control-payload :active 16) 9))
                       'invalid-argument :control-checkpoint-active)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-builder-manifest-cumulative-budgets
  (with-control-fixture (f :stage :active)
    (control-rejection f (lambda () (c:crea-checkpoint-control (cf-active f) (cf-payload f) 9 :max-segmenti 2))
                       'resource-exhausted :manifest-segment-budget)
    (control-rejection f (lambda () (c:crea-checkpoint-control (cf-active f) (cf-payload f) 9 :max-esiti 0))
                       'resource-exhausted :manifest-outcome-budget)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-prepare-zero-chunk
  (with-control-fixture (f :stage :plan)
    (control-rejection f (lambda () (control-prepare f (zeros 31) 0))
                       'invalid-argument :control-checkpoint-chunk)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-prepare-short-scratch
  (with-control-fixture (f :stage :plan)
    (control-rejection f (lambda () (control-prepare f (zeros 30))) 'invalid-argument :buffer-range)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-prepare-three-scratch-aliases
  (with-control-fixture (f :stage :plan)
    (dolist (scratch (list (c::checkpoint-control-bytes (cf-plan f))
                          (c::checkpoint-control-identity (cf-plan f))
                          (g::vista-get-serie-identity (cf-view f))))
      (control-rejection f (lambda () (control-prepare f scratch))
                         'invalid-argument :control-checkpoint-alias))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-prepare-read-transfer-budget
  (with-control-fixture (f :stage :plan :read-transfer 30)
    (control-rejection f (lambda () (control-prepare f)) 'resource-exhausted :io-byte-budget)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-prepare-write-transfer-and-total-budgets
  (dolist (limits '((30 4096) (4096 211)))
    (with-control-fixture (f :stage :plan :write-transfer (first limits) :file-limit (second limits))
      (control-rejection f (lambda () (control-prepare f)) 'resource-exhausted :io-group-budget))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-prepare-started-append
  (with-control-fixture (f :stage :plan)
    (io:append-esatto (cf-control-append f) (zeros 1) 0 1)
    (control-clear f)
    (control-rejection f (lambda () (control-prepare f)) 'invalid-argument :control-checkpoint-started)))

;;; REQ: REQ-AFF-001 REQ-REC-001
(deftest test-REQ-REC-001-CONTROL-prepare-rejects-physical-active-alias
  (with-control-fixture (f :stage :plan)
    ;; FI: identità fisiche del solo backend simulano due nomi dello stesso inode.
    (let ((active (control-node f "/control-fixture/segment-17.tmp"))
          (control (control-node f "/control-fixture/control.log.tmp")))
      (setf (control-memory-node-inode control) (control-memory-node-inode active)))
    (signals invalid-argument (control-prepare f) :io-file-alias)
    (is (equal '(:identity :identity :identity :identity) (control-operations f)))
    (is (zerop (io:posizione-scritta (cf-control-append f))))
    (control-check-old f)))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-CONTROL-prepare-backend-mismatch
  (with-control-fixture (f :stage :plan)
    (let ((other (control-memory-backend f)))
      (let ((input (control-own f (io:apri-lettura "/control-fixture/control.log.tmp" :backend other))))
        (control-clear f)
        (control-rejection f
                           (lambda () (c:prepara-checkpoint-control (cf-plan f) input (cf-control-append f)
                                                                   (cf-directory f) (zeros 31) :chunk-bytes 31))
                           'invalid-argument :control-checkpoint-backend)))))

;;; REQ: REQ-AFF-002 REQ-FOR-002
(deftest test-REQ-AFF-002-CONTROL-prepare-readback-first-middle-last-and-boundary
  (dolist (offset '(0 30 31 106 211))
    (with-control-fixture (f :stage :plan)
      ;; FI: altera un byte fisico dopo il flush, senza mutare piano o risultati.
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (declare (ignore arguments))
              (when (and (eq operation :read) (= ordinal 1))
                (let ((bytes (control-memory-node-bytes (control-node fixture "/control-fixture/control.log.tmp"))))
                  (setf (aref bytes offset) (logxor 1 (aref bytes offset)))))
              nil))
      (let ((caught (control-caught (lambda () (control-prepare f)))))
        (is (typep caught 'corruption-detected))
        (is (eq :control-checkpoint-readback (error-reason caught)))
        (is (= offset (error-offset caught))))
      (is (zerop (control-count f :directory-flush))) (is (zerop (control-count f :rename)))
      (is (= 212 (io:posizione-durevole (cf-control-append f))))
      (let ((events (control-events f)))
        (signals invalid-argument (control-prepare f) :control-checkpoint-started)
        (is (equal events (control-events f))))
      (control-check-old f))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-prepare-file-flush-failure
  (with-control-fixture (f :stage :plan)
    (setf (cf-hook f) (lambda (fixture operation ordinal arguments)
                       (declare (ignore fixture ordinal arguments))
                       (when (eq operation :flush) (values t 1))))
    (signals io-fault (control-prepare f) :io-flush-result)
    (is (eq :faulted (io:stato-file (cf-control-append f))))
    (is (= 212 (io:posizione-scritta (cf-control-append f))))
    (is (zerop (io:posizione-durevole (cf-control-append f))))
    (is (zerop (control-count f :read))) (is (zerop (control-count f :directory-flush)))
    (let ((events (control-events f)))
      (signals io-fault (control-prepare f) :io-unavailable)
      (is (equal events (control-events f))))))

(defun control-fi-touch-writer-byte (fixture arguments)
  "FI esplicita: effetto fisico prima dell'uscita incompleta, progresso non ancora reso dal callback."
  (let* ((fd (first arguments)) (node (control-memory-fd-node (control-handle fixture fd)))
         (old (control-memory-node-bytes node)) (bytes (zeros (1+ (length old)))))
    (replace bytes old)
    (setf (aref bytes (length old)) #x41 (control-memory-node-bytes node) bytes)))

(defun control-check-incomplete-writer (fixture)
  (is (eq :faulted (io:stato-file (cf-control-append fixture))))
  (is (zerop (io:posizione-scritta (cf-control-append fixture))))
  (is (zerop (io:posizione-durevole (cf-control-append fixture))))
  (is (= 1 (length (control-memory-node-bytes (control-node fixture "/control-fixture/control.log.tmp")))))
  (is (= 1 (control-count fixture :write)))
  (is (zerop (control-count fixture :flush))) (is (zerop (control-count fixture :close)))
  (let ((events (control-events fixture)))
    (signals io-fault (control-prepare fixture) :io-unavailable)
    (is (equal events (control-events fixture))))
  (control-check-old fixture))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-prepare-writer-typed-error-after-byte
  (with-control-fixture (f :stage :plan)
    (let ((original (make-condition 'resource-exhausted :reason :control-fi-writer-after-byte)))
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (when (and (eq operation :write) (= ordinal 1))
                (control-fi-touch-writer-byte fixture arguments) (error original))
              nil))
      (is (eq original (control-caught (lambda () (control-prepare f)))))
      (control-check-incomplete-writer f))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-prepare-writer-nonlocal-after-byte
  (with-control-fixture (f :stage :plan)
    (let ((marker (list :control-fi-writer-nonlocal)))
      (is (eq marker
              (block escaped
                (setf (cf-hook f)
                      (lambda (fixture operation ordinal arguments)
                        (when (and (eq operation :write) (= ordinal 1))
                          (control-fi-touch-writer-byte fixture arguments) (return-from escaped marker))
                        nil))
                (control-prepare f) :fell-through)))
      (control-check-incomplete-writer f))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-CONTROL-publication-missing-entry-and-rename-callbacks
  (dolist (missing '(:entry :rename))
    (with-control-fixture (f :missing missing)
      (control-rejection f (lambda () (control-publish f)) 'unsupported-format :io-replacement-unavailable))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-CONTROL-replacement-preflight-missing-identity
  (with-control-fixture (f)
    ;; Factory reali di capacità del backend incompleto; nessun prepared sintetico.
    (let* ((backend (control-memory-backend f :identity))
           (directory (control-own f (io:apri-directory "/control-fixture/" :backend backend)))
           (input (control-own f (io:apri-lettura "/control-fixture/control.log.tmp" :backend backend)))
           (previous (control-own f (io:apri-lettura "/control-fixture/control.log" :backend backend))))
      (control-clear f)
      (control-rejection f (lambda () (io:verifica-capacita-sostituzione directory input previous
                                                                      "control.log.tmp" "control.log"))
                         'unsupported-format :io-replacement-unavailable))))

;;; REQ: REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-CONTROL-publication-previous-mode-and-backend
  (with-control-fixture (f)
    (control-rejection f (lambda () (c:pubblica-control-recuperato (cf-prepared f) (cf-control-append f)))
                       'invalid-argument :io-mode)
    (let ((other (control-own f (io:apri-lettura "/control-fixture/control.log"
                                               :backend (control-memory-backend f)))))
      (control-clear f)
      (control-rejection f (lambda () (c:pubblica-control-recuperato (cf-prepared f) other))
                         'invalid-argument :io-identity-backend))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-closed-capabilities
  (dolist (selector (list #'cf-directory #'cf-control-input #'cf-control-append #'cf-active-input #'cf-active-append))
    (with-control-fixture (f)
      (io:chiudi (funcall selector f)) (control-clear f)
      (control-rejection f (lambda () (control-publish f)) 'io-fault :io-unavailable)))
  (with-control-fixture (f)
    (io:chiudi (cf-previous f)) (control-clear f)
    ;; Il witness del vecchio FD chiuso è il nodo posseduto; nessuna lettura su FD chiuso.
    (let ((caught (control-caught (lambda () (control-publish f)))))
      (is (typep caught 'io-fault)) (is (eq :io-unavailable (error-reason caught))))
    (control-check-state f :prepared nil)
    (is (null (control-events f)))
    (is (equalp (cf-old-bytes f) (control-memory-node-bytes (cf-old-node f))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-log-health-preflight
  (dolist (active-p '(nil t))
    (with-control-fixture (f)
      ;; FI esplicita: log guasto precedente, per isolare il rifiuto senza guastare un FD.
      (setf (arcdocdb.wal::log-io-state
             (if active-p (a:log-segmento-attivo-preparato (cf-active f))
                 (c:log-control-preparato (cf-prepared f)))) :faulted)
      (control-rejection f (lambda () (control-publish f)) 'invalid-argument
                         (if active-p :control-active-log :control-publication-log)))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-CONTROL-publication-checkpoint-written-and-durable-frontiers
  (dolist (which '(:written :durable))
    (with-control-fixture (f)
      ;; FI esplicita: ciascuna frontiera discordante separatamente; nessun successo forgiato.
      (ecase which
        (:written (setf (io::file-written (cf-control-append f)) 213))
        (:durable (setf (io::file-durable (cf-control-append f)) 211)))
      (control-rejection f (lambda () (control-publish f)) 'invalid-argument :control-publication-advanced))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-CONTROL-publication-active-written-and-durable-frontiers
  (dolist (which '(:written :durable))
    (with-control-fixture (f)
      ;; FI esplicita: isola ogni condizione della dipendenza ACTIVE header-only.
      (ecase which
        (:written (setf (io::file-written (cf-active-append f)) 65))
        (:durable (setf (io::file-durable (cf-active-append f)) 63)))
      (control-rejection f (lambda () (control-publish f)) 'invalid-argument :control-active-advanced))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-CONTROL-publication-real-active-advance-before-claim
  (with-control-fixture (f)
    (io:append-esatto (cf-active-append f) (zeros 1) 0 1)
    (io:durable-flush (cf-active-append f)) (control-clear f)
    (control-rejection f (lambda () (control-publish f)) 'invalid-argument :control-active-advanced)))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-publication-original-error-at-each-fd-identity
  (dotimes (index 3)
    (with-control-fixture (f)
      (let ((original (make-condition 'resource-exhausted :reason :control-fi-identity)))
        (control-inject-condition f :identity (1+ index) original)
        (is (eq original (control-caught (lambda () (control-publish f)))))
        (is (= (1+ index) (control-count f :identity)))
        (is (= (if (= index 2) 1 0) (control-count f :rename)))
        (is (zerop (control-count f :directory-flush)))
        (control-check-publisher-fault f nil (if (= index 2) :faulted :open) (= index 2))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-publication-original-error-at-each-entry-identity
  (dotimes (index 3)
    (with-control-fixture (f)
      (let ((original (make-condition 'invariant-violation :reason :control-fi-entry)))
        (control-inject-condition f :entry (1+ index) original)
        (is (eq original (control-caught (lambda () (control-publish f)))))
        (is (= (1+ index) (control-count f :entry)))
        (is (= (if (= index 2) 1 0) (control-count f :rename)))
        (is (zerop (control-count f :directory-flush)))
        (control-check-publisher-fault f nil (if (= index 2) :faulted :open) (= index 2))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-publication-errno-operation-and-no-retry
  (dolist (phase '((:identity :identity) (:entry :entry-identity) (:rename :rename) (:directory-flush :flush)))
    (dolist (errno (list sb-posix:eio sb-posix:eintr))
      (with-control-fixture (f)
        (control-inject-condition f (first phase) 1
                                  (make-condition 'sb-posix:syscall-error :errno errno :name 'control-fi-syscall))
        (let ((caught (control-caught (lambda () (control-publish f)))))
          (is (typep caught 'io-fault)) (is (eq :io-syscall (error-reason caught)))
          (is (= errno (error-errno caught))) (is (eq (second phase) (error-operation caught))))
        (is (= 1 (control-count f (first phase))))
        (let ((flushed-p (eq (first phase) :directory-flush)))
          (control-check-publisher-fault f flushed-p
                                        (if (member (first phase) '(:rename :directory-flush)) :faulted :open)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-publication-invalid-fd-identity-components
  (dolist (components (list (list :not-device 2) (list 9 (ash 1 64))))
    (with-control-fixture (f)
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (declare (ignore fixture arguments))
              (when (and (eq operation :identity) (= ordinal 1))
                (values t (first components) (second components)))))
      (signals invariant-violation (control-publish f) :io-identity-result)
      (is (equal '(:identity) (control-operations f)))
      (control-check-publisher-fault f nil :open))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-publication-invalid-entry-identity-components
  (dolist (components (list (list (ash 1 64) 2) (list 9 :not-inode)))
    (with-control-fixture (f)
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (declare (ignore fixture arguments))
              (when (and (eq operation :entry) (= ordinal 1))
                (values t (first components) (second components)))))
      (signals invariant-violation (control-publish f) :io-entry-identity-result)
      (is (equal '(:identity :entry) (control-operations f)))
      (control-check-publisher-fault f nil :open))))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest test-REQ-REC-001-CONTROL-publication-entry-device-or-inode-mismatch-at-each-step
  (dolist (ordinal '(1 2 3))
    (dolist (component '(:device :inode))
      (with-control-fixture (f)
        ;; FI: risposta del namespace diversa dal FD, una componente alla volta.
        (setf (cf-hook f)
              (lambda (fixture operation n arguments)
                (when (and (eq operation :entry) (= n ordinal))
                  (let ((node (control-node fixture (concatenate 'string "/control-fixture/" (second arguments)))))
                    (values t (+ (control-memory-node-device node) (if (eq component :device) 1 0))
                            (+ (control-memory-node-inode node) (if (eq component :inode) 1 0)))))))
        (signals invalid-argument (control-publish f) :io-replacement-identity)
        (is (= ordinal (control-count f :entry)))
        (is (= (if (= ordinal 3) 1 0) (control-count f :rename)))
        (is (zerop (control-count f :directory-flush)))
        (control-check-publisher-fault f nil (if (= ordinal 3) :faulted :open) (= ordinal 3))))))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest test-REQ-REC-001-CONTROL-publication-source-target-physical-alias
  (with-control-fixture (f)
    ;; FI: il backend simula un hardlink, senza modificare i risultati preparati.
    (setf (control-memory-node-inode (cf-old-node f))
          (control-memory-node-inode (control-node f "/control-fixture/control.log.tmp")))
    (signals invalid-argument (control-publish f) :io-replacement-alias)
    (is (equal '(:identity :entry :identity :entry) (control-operations f)))
    (control-check-publisher-fault f nil :open)))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest test-REQ-REC-001-CONTROL-publication-identities-distinct-in-either-component
  (dolist (same '(:device :inode))
    (with-control-fixture (f)
      ;; Configurazione del backend: identità valide, realmente distinte.
      (let ((source (control-node f "/control-fixture/control.log.tmp")) (target (cf-old-node f)))
        (when (eq same :inode)
          (setf (control-memory-node-inode target) (control-memory-node-inode source)
                (control-memory-node-device target) 10)))
      (control-check-success f (control-publish f)))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-rename-nonzero-or-invalid-result
  (dolist (value '(nil 1 -1 0.0d0))
    (with-control-fixture (f)
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (declare (ignore fixture ordinal arguments))
              (when (eq operation :rename) (values t value))))
      (signals io-fault (control-publish f) :io-rename-result)
      (is (= 1 (control-count f :rename))) (is (zerop (control-count f :directory-flush)))
      (control-check-publisher-fault f nil :faulted))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-publication-rename-original-typed-and-foreign-errors
  (dolist (original (list (make-condition 'resource-exhausted :reason :control-fi-rename)
                         (make-condition 'simple-error :format-control "FI esterna nella rinomina CONTROL.")))
    (with-control-fixture (f)
      (control-inject-condition f :rename 1 original)
      (is (eq original (control-caught (lambda () (control-publish f)))))
      (is (= 1 (control-count f :rename))) (is (zerop (control-count f :directory-flush)))
      (control-check-publisher-fault f nil :faulted))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-publication-nonlocal-identity-entry-and-rename
  (dolist (phase '((:identity 1) (:identity 2) (:identity 3) (:entry 1) (:entry 2) (:entry 3) (:rename 1)))
    (with-control-fixture (f)
      (let ((marker (list :control-fi-nonlocal)))
        (is (eq marker
                (block escaped
                  (setf (cf-hook f)
                        (lambda (fixture operation ordinal arguments)
                          (declare (ignore fixture arguments))
                          (when (and (eq operation (first phase)) (= ordinal (second phase)))
                            (return-from escaped marker))
                          nil))
                  (control-publish f) :fell-through)))
        (let ((post-p (= 3 (second phase))))
          (control-check-publisher-fault f nil
                                        (if (or post-p (eq :rename (first phase))) :faulted :open) post-p))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-directory-flush-nonzero
  (with-control-fixture (f)
    (setf (cf-hook f)
          (lambda (fixture operation ordinal arguments)
            (declare (ignore fixture ordinal arguments))
            (when (eq operation :directory-flush) (values t 1))))
    (signals io-fault (control-publish f) :io-flush-result)
    (is (= 1 (control-count f :rename) (control-count f :directory-flush)))
    (control-check-publisher-fault f t :faulted)))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-publication-directory-flush-original-typed-error
  (with-control-fixture (f)
    (let ((original (make-condition 'resource-exhausted :reason :control-fi-directory-flush))
          (state-at-caller nil))
      (control-inject-condition f :directory-flush 1 original)
      (is (eq original
              (control-caught
               (lambda ()
                 (unwind-protect (control-publish f)
                   (setf state-at-caller (list (io:stato-file (cf-directory f))
                                               (c:stato-pubblicazione-control (cf-prepared f)))))))))
      (is (equal '(:faulted :faulted) state-at-caller))
      (is (= 1 (control-count f :rename) (control-count f :directory-flush)))
      (control-check-publisher-fault f t :faulted))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-directory-flush-nonlocal
  (with-control-fixture (f)
    (let ((marker (list :control-fi-directory-exit)) (state-at-caller nil))
      (is (eq marker
              (block escaped
                (setf (cf-hook f)
                      (lambda (fixture operation ordinal arguments)
                        (declare (ignore fixture ordinal arguments))
                        (when (eq operation :directory-flush) (return-from escaped marker)) nil))
                (unwind-protect (control-publish f)
                  (setf state-at-caller (list (io:stato-file (cf-directory f))
                                              (c:stato-pubblicazione-control (cf-prepared f)))))
                :fell-through)))
      (is (equal '(:faulted :faulted) state-at-caller))
      (is (= 1 (control-count f :rename) (control-count f :directory-flush)))
      (control-check-publisher-fault f t :faulted))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-directory-callback-closes-and-returns-zero
  (with-control-fixture (f)
    ;; FI fuori contratto: close pubblica dal callback; il cleanup non deve riaprire CLOSED.
    ;; Lo zero del backend arriva dopo la close: il modello deve permettere il ritorno POSIX.
    (setf (cf-hook f)
          (lambda (fixture operation ordinal arguments)
            (declare (ignore ordinal arguments))
            (when (eq operation :directory-flush)
              (io:chiudi (cf-directory fixture)) (values t 0))))
    (signals io-fault (control-publish f) :io-unavailable)
    (control-check-state f :faulted t)
    (is (eq :closed (io:stato-file (cf-directory f))))
    (is (= 1 (control-count f :close)))
    (is (= 1 (control-count f :rename) (control-count f :directory-flush)))
    (control-check-old f t)
    (control-check-retry-refused f :faulted t)))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-rename-callback-closes-and-returns-zero
  (with-control-fixture (f)
    ;; FI fuori contratto: effetto reale del backend, close pubblica, poi ritorno zero.
    (setf (cf-hook f)
          (lambda (fixture operation ordinal arguments)
            (declare (ignore ordinal arguments))
            (when (eq operation :rename)
              (let ((node (control-node fixture "/control-fixture/control.log.tmp")))
                (setf (gethash "/control-fixture/control.log" (cf-names fixture)) node)
                (remhash "/control-fixture/control.log.tmp" (cf-names fixture)))
              (io:chiudi (cf-directory fixture)) (values t 0))))
    ;; La verifica entry può rilevare EBADF prima del successivo controllo OPEN.
    (signals io-fault (control-publish f))
    (control-check-state f :faulted nil)
    (is (eq :closed (io:stato-file (cf-directory f))))
    (is (= 1 (control-count f :close) (control-count f :rename)))
    (is (zerop (control-count f :directory-flush)))
    (control-check-old f t)
    (control-check-retry-refused f :faulted nil)))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-directory-close-then-original-error
  (with-control-fixture (f)
    (let ((original (make-condition 'resource-exhausted :reason :control-fi-close-then-error)))
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (declare (ignore ordinal arguments))
              (when (eq operation :directory-flush)
                (io:chiudi (cf-directory fixture)) (error original)) nil))
      (is (eq original (control-caught (lambda () (control-publish f)))))
      (control-check-state f :faulted t)
      (is (eq :closed (io:stato-file (cf-directory f))))
      (is (= 1 (control-count f :close)))
      (control-check-old f t)
      (control-check-retry-refused f :faulted t))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-CONTROL-publication-callback-advances-active-postcondition
  (dolist (flush-active-p '(nil t))
    (with-control-fixture (f)
      ;; FI fuori contratto con API pubbliche: ACTIVE avanza nel callback del parent.
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (declare (ignore ordinal arguments))
              (when (eq operation :directory-flush)
                (io:append-esatto (cf-active-append fixture) (zeros 1) 0 1)
                (when flush-active-p (io:durable-flush (cf-active-append fixture)))) nil))
      (signals invalid-argument (control-publish f) :control-active-advanced)
      (control-check-state f :faulted t)
      (is (eq :open (io:stato-file (cf-directory f))))
      (is (= 65 (io:posizione-scritta (cf-active-append f))))
      (is (= (if flush-active-p 65 64) (io:posizione-durevole (cf-active-append f))))
      (is (= 1 (control-count f :rename) (control-count f :directory-flush) (control-count f :write)))
      (is (zerop (control-count f :close)))
      (control-check-old f t)
      (control-check-retry-refused f :faulted t))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-CONTROL-publication-callback-advances-checkpoint-postcondition
  (dolist (flush-control-p '(nil t))
    (with-control-fixture (f)
      ;; FI fuori contratto: append pubblica al checkpoint già rinominato.
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (declare (ignore ordinal arguments))
              (when (eq operation :directory-flush)
                (io:append-esatto (cf-control-append fixture) (zeros 1) 0 1)
                (when flush-control-p (io:durable-flush (cf-control-append fixture)))) nil))
      (signals invalid-argument (control-publish f) :control-publication-advanced)
      (control-check-state f :faulted t)
      (is (eq :open (io:stato-file (cf-directory f))))
      (is (= 213 (io:posizione-scritta (cf-control-append f))))
      (is (= (if flush-control-p 213 212) (io:posizione-durevole (cf-control-append f))))
      (is (= 1 (control-count f :rename) (control-count f :directory-flush) (control-count f :write)))
      (is (zerop (control-count f :close)))
      (control-check-old f t)
      (control-check-retry-refused f :faulted t))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-callback-closes-previous-postcondition
  (with-control-fixture (f)
    (setf (cf-hook f)
          (lambda (fixture operation ordinal arguments)
            (declare (ignore ordinal arguments))
            (when (eq operation :directory-flush) (io:chiudi (cf-previous fixture))) nil))
    (signals io-fault (control-publish f) :io-unavailable)
    (control-check-state f :faulted t)
    (is (eq :closed (io:stato-file (cf-previous f))))
    (is (eq :open (io:stato-file (cf-directory f))))
    (is (equalp (cf-old-bytes f) (control-memory-node-bytes (cf-old-node f))))
    (is (= 1 (control-count f :close)))
    (control-check-retry-refused f :faulted t)))

;;; REQ: REQ-AFF-004 REQ-REC-001
(deftest test-REQ-AFF-004-CONTROL-publication-uncaught-reentrancy-preserves-original
  (with-control-fixture (f)
    (let ((inner nil))
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (declare (ignore ordinal arguments))
              (when (eq operation :identity)
                (handler-bind ((invalid-argument (lambda (condition) (setf inner condition))))
                  (control-publish fixture))) nil))
      (let ((outer (control-caught (lambda () (control-publish f)))))
        (is (typep outer 'invalid-argument)) (is (eq :control-publication-state (error-reason outer)))
        (is (eq inner outer)))
      (is (equal '(:identity) (control-operations f)))
      (control-check-publisher-fault f nil :open))))

;;; REQ: REQ-AFF-004 REQ-REC-001
(deftest test-REQ-REC-001-CONTROL-publication-handled-reentrancy-winner-preserved
  (with-control-fixture (f)
    (let ((rejections 0))
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (declare (ignore arguments))
              (when (and (eq operation :identity) (= ordinal 1))
                (let ((events (control-events fixture)))
                  (signals invalid-argument (control-publish fixture) :control-publication-state)
                  (incf rejections)
                  (is (equal events (control-events fixture)))
                  (control-check-state fixture :publishing nil))) nil))
      (control-check-success f (control-publish f))
      (is (= 1 rejections)))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-directory-frontier-mutated-in-callback
  (with-control-fixture (f)
    ;; FI esplicita: una directory non ha append; isola il controllo scritto stabile del flush.
    (setf (cf-hook f)
          (lambda (fixture operation ordinal arguments)
            (declare (ignore ordinal arguments))
            (when (eq operation :directory-flush) (setf (io::file-written (cf-directory fixture)) 1)) nil))
    (signals invariant-violation (control-publish f) :io-flush-frontier)
    (is (zerop (io:posizione-durevole (cf-directory f))))
    (control-check-publisher-fault f t :faulted)))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-publication-closed-checkpoint-after-flush
  (dolist (selector (list #'cf-control-input #'cf-control-append #'cf-active-input #'cf-active-append))
    (with-control-fixture (f)
      ;; FI fuori contratto: capacità dipendente chiusa mentre il parent viene sincronizzato.
      (setf (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (declare (ignore ordinal arguments))
              (when (eq operation :directory-flush) (io:chiudi (funcall selector fixture))) nil))
      (signals io-fault (control-publish f) :io-unavailable)
      (control-check-state f :faulted t)
      (is (eq :open (io:stato-file (cf-directory f))))
      (is (eq :closed (io:stato-file (funcall selector f))))
      (is (= 1 (control-count f :close)))
      (control-check-old f t)
      (control-check-retry-refused f :faulted t))))

;;; REQ: REQ-REC-001 REQ-AFF-001
(deftest test-REQ-REC-001-CONTROL-publication-missing-source-or-target-entry
  (dolist (leaf '("control.log.tmp" "control.log"))
    (with-control-fixture (f)
      ;; FI namespace: rimozione esclusivamente della voce posseduta dal backend di questa fixture.
      (remhash (concatenate 'string "/control-fixture/" leaf) (cf-names f))
      (let ((caught (control-caught (lambda () (control-publish f)))))
        (is (typep caught 'io-fault)) (is (eq :entry-identity (error-operation caught)))
        (is (= sb-posix:enoent (error-errno caught))))
      (control-check-state f :faulted nil)
      (is (eq :open (io:stato-file (cf-directory f))))
      (is (zerop (control-count f :rename)))
      (is (equalp (cf-old-bytes f) (control-memory-node-bytes (cf-old-node f))))
      (control-check-no-hidden-effects f)
      (control-check-retry-refused f :faulted nil))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-prepare-directory-flush-original-error
  (with-control-fixture (f :stage :plan)
    (let ((original (make-condition 'resource-exhausted :reason :control-fi-preparation-parent)))
      (control-inject-condition f :directory-flush 1 original)
      (is (eq original (control-caught (lambda () (control-prepare f)))))
      (is (eq :faulted (io:stato-file (cf-directory f))))
      (is (= 212 (io:posizione-durevole (cf-control-append f))))
      (is (zerop (control-count f :rename))) (is (zerop (control-count f :close)))
      (let ((events (control-events f)))
        (signals io-fault (control-prepare f) :io-unavailable)
        (is (equal events (control-events f))))
      (control-check-old f))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-prepare-directory-flush-nonlocal
  (with-control-fixture (f :stage :plan)
    (let ((marker (list :control-fi-prepare-parent-exit)))
      (is (eq marker
              (block escaped
                (setf (cf-hook f)
                      (lambda (fixture operation ordinal arguments)
                        (declare (ignore fixture ordinal arguments))
                        (when (eq operation :directory-flush) (return-from escaped marker)) nil))
                (control-prepare f) :fell-through)))
      (is (eq :faulted (io:stato-file (cf-directory f))))
      (let ((events (control-events f)))
        (signals io-fault (control-prepare f) :io-unavailable)
        (is (equal events (control-events f))))
      (control-check-old f))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-prepare-writer-close-stops-short-io
  (with-control-fixture (f :stage :plan)
    ;; FI fuori contratto: primo byte confermato, close pubblica, nessun secondo writer ammesso.
    (setf (cf-hook f)
          (lambda (fixture operation ordinal arguments)
            (when (and (eq operation :write) (= ordinal 1))
              (control-fi-touch-writer-byte fixture arguments)
              (io:chiudi (cf-control-append fixture)) (values t 1))))
    (signals io-fault (control-prepare f) :io-unavailable)
    (is (eq :closed (io:stato-file (cf-control-append f))))
    (is (= 1 (io:posizione-scritta (cf-control-append f)) (control-count f :write) (control-count f :close)))
    (is (zerop (io:posizione-durevole (cf-control-append f))))
    (let ((events (control-events f)))
      (signals io-fault (control-prepare f) :io-unavailable)
      (is (equal events (control-events f))))
    (control-check-old f)))

(defun control-wait-gate (gate phase)
  (unless (sb-thread:wait-on-semaphore gate :timeout 5)
    (error 'control-fixture-timeout :phase phase))
  nil)

(defun control-worker (thunk)
  "Confine worker: il join trasferisce la stessa condizione, senza trasformarla in assert."
  (sb-thread:make-thread
   (lambda () (handler-case (list :value (funcall thunk)) (error (condition) (list :condition condition))))
   :name "CONTROL-CAS-fixture"))

(defun control-join (thread)
  (let* ((marker (list :control-join-timeout))
         (result (sb-thread:join-thread thread :timeout 5 :default marker)))
    (when (eq marker result) (error 'control-fixture-timeout :phase :join))
    (when (and (eq :condition (first result)) (typep (second result) 'control-fixture-timeout))
      (error (second result)))
    result))

(defun control-stop-worker (thread)
  "Cleanup bounded prima di ripristinare la preflight globale o chiudere capacità."
  (when thread
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (let ((joined (sb-thread:join-thread thread :timeout 2 :default :control-worker-stopped)))
      (when (sb-thread:thread-alive-p thread) (error 'control-fixture-timeout :phase :cleanup))
      joined)))

(defun control-cas-contenders (fixture)
  "FI di schedulazione: due preflight REALI completate prima di qualsiasi presa.
Il wrapper coordina soltanto questa fixture; nessuno stato, gettone o risultato viene forgiato."
  (let* ((name 'c::verifica-pubblicazione-control) (original (fdefinition name))
         (start (sb-thread:make-semaphore)) (ready (sb-thread:make-semaphore))
         (winner-release (sb-thread:make-semaphore)) (loser-release (sb-thread:make-semaphore))
         (claimed (sb-thread:make-semaphore)) (finish (sb-thread:make-semaphore))
         (winner nil) (loser nil))
    (unwind-protect
         (progn
           ;; FI esplicita e seriale: ritorno originale conservato, gate dopo i controlli reali.
           (setf (fdefinition name)
                 (lambda (prepared previous)
                   (prog1 (funcall original prepared previous)
                     (when (eq prepared (cf-prepared fixture))
                       (sb-thread:signal-semaphore ready)
                       (control-wait-gate (if (eq winner sb-thread:*current-thread*) winner-release loser-release)
                                          :after-preflight)))))
           (setf (cf-hook fixture)
                 (lambda (f operation ordinal arguments)
                   (declare (ignore arguments))
                   (when (and (eq operation :identity) (= ordinal 1))
                     (sb-thread:signal-semaphore claimed)
                     (control-wait-gate finish :winner-finish)
                     ;; Osservazione dal proprietario: cleanup del CAS perdente già concluso.
                     (control-check-state f :publishing nil)) nil))
           (setf winner (control-worker (lambda () (control-wait-gate start :winner-start) (control-publish fixture))))
           (push winner (cf-workers fixture))
           (setf loser (control-worker (lambda () (control-wait-gate start :loser-start) (control-publish fixture))))
           (push loser (cf-workers fixture))
           (sb-thread:signal-semaphore start 2)
           (dotimes (i 2) (control-wait-gate ready :both-preflight))
           (sb-thread:signal-semaphore winner-release)
           (control-wait-gate claimed :winner-claimed)
           (sb-thread:signal-semaphore loser-release)
           (let ((result (control-join loser)))
             (is (eq :condition (first result)))
             (is (typep (second result) 'invalid-argument))
             (is (eq :control-publication-state (error-reason (second result)))))
           (sb-thread:signal-semaphore finish)
           (let ((result (control-join winner)))
             (when (eq :condition (first result)) (error (second result)))
             (is (eq :value (first result)))
             (control-check-success fixture (second result))))
      (sb-thread:signal-semaphore start 2)
      (sb-thread:signal-semaphore winner-release)
      (sb-thread:signal-semaphore loser-release)
      (sb-thread:signal-semaphore finish)
      (unwind-protect
           (unwind-protect (control-stop-worker loser) (control-stop-worker winner))
        ;; Nessun ripristino globale o cambio hook mentre un consumer può usarli.
        (when (every (lambda (thread) (or (null thread) (not (sb-thread:thread-alive-p thread))))
                     (list loser winner))
          (setf (fdefinition name) original (cf-hook fixture) nil))))))

;;; REQ: REQ-REC-001 REQ-AFF-004
(deftest test-REQ-REC-001-CONTROL-publication-cas-loser-does-not-fault-winner
  (with-control-fixture (f)
    (control-cas-contenders f)))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-CONTROL-prepare-writer-error-preserves-known-short-progress
  (with-control-fixture (f :stage :plan)
    (let ((original (make-condition 'resource-exhausted :reason :control-fi-second-writer)))
      (setf (cf-short-transfer f) 3
            (cf-hook f)
            (lambda (fixture operation ordinal arguments)
              (when (and (eq operation :write) (= ordinal 2))
                (control-fi-touch-writer-byte fixture arguments) (error original)) nil))
      (is (eq original (control-caught (lambda () (control-prepare f)))))
      (is (eq :faulted (io:stato-file (cf-control-append f))))
      (is (= 3 (io:posizione-scritta (cf-control-append f))))
      (is (= 4 (length (control-memory-node-bytes (control-node f "/control-fixture/control.log.tmp")))))
      (is (zerop (io:posizione-durevole (cf-control-append f))))
      (is (= 2 (control-count f :write)))
      (is (zerop (control-count f :flush))) (is (zerop (control-count f :close)))
      (let ((events (control-events f)))
        (signals io-fault (control-prepare f) :io-unavailable)
        (is (equal events (control-events f))))
      (control-check-old f))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-prepare-original-error-at-each-identity
  (dotimes (index 4)
    (with-control-fixture (f :stage :plan)
      (let ((original (make-condition 'resource-exhausted :reason :control-fi-preparation-identity)))
        (control-inject-condition f :identity (1+ index) original)
        (is (eq original (control-caught (lambda () (control-prepare f)))))
        (is (= (1+ index) (control-count f :identity)))
        (is (eq :open (io:stato-file (cf-control-append f))))
        (is (zerop (io:posizione-scritta (cf-control-append f))))
        (is (zerop (control-count f :write))) (is (zerop (control-count f :close)))
        (control-check-old f)))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-active-preparation-original-error-at-each-identity
  (dotimes (index 2)
    (with-control-fixture (f :stage :active)
      (let* ((backend (cf-backend f))
             (append (control-own f (io:crea-temporaneo "/control-fixture/fresh-active.tmp" :backend backend)))
             (input (control-own f (io:apri-lettura "/control-fixture/fresh-active.tmp" :backend backend)))
             (original (make-condition 'resource-exhausted :reason :control-fi-active-identity)))
        (control-clear f)
        (control-inject-condition f :identity (1+ index) original)
        (is (eq original
                (control-caught
                 (lambda () (a:prepara-segmento-attivo (cf-view f) input append (cf-directory f)
                                                      18 100 (zeros 64) (zeros 64) :version (cf-version f))))))
        (is (= (1+ index) (control-count f :identity)))
        (is (eq :open (io:stato-file append))) (is (zerop (io:posizione-scritta append)))
        (is (zerop (control-count f :write))) (is (zerop (control-count f :close)))
        (control-check-old f)))))
