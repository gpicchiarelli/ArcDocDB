;;;; Qualifica statica predisposta per leggi-control-recuperato e query pubbliche.
;;;; Caricare dopo control/native; nessuna dipendenza da tests/recovery.
;;; OWNER: runner seriale; ogni chiamata possiede backend, FD fittizio, vista e scratch.
;;; SHARED: solo le FI CRV-D02 sostituiscono temporaneamente una funzione; NO CONCURRENT.
;;; METODO: v1/v2, byte little-endian e CRC bitwise indipendenti dai codec di prodotto.
;;; L'oracolo delle richieste ricostruisce ogni pread fino all'EOF, inclusi gli short read.
;;; Limiti: file <= 4096 byte, eventi <= 8192, un FD per fixture, nessun worker/attesa.
;;; CRV-D01: ogni congiunto falso separatamente e frontiera header esatta.
;;; CRV-D02: COMPLETE/TAIL pubblici coerenti; quattro risultati outside-contract in FI.
;;; Le FI ripristinano la dipendenza con unwind-protect; nessun wrapper di risultato forgiato.
;;; Fuori dalle FI: guardie difensive :control-recovery-preflight/:read/:header non forzate.
;;; Nessuna esecuzione, compilazione, misura o attestazione di copertura in questa consegna.
;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-002 REQ-FOR-003 REQ-AFF-002
;;; REQ: REQ-AFF-008 REQ-AFF-009 REQ-AFF-017 REQ-AFF-018
(in-package #:arcdocdb.control.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun crr-bytes (size &optional (value 0))
  (is (<= 0 size 4096))
  (make-array size :element-type '(unsigned-byte 8) :initial-element value))

(defun crr-pack (bytes start value width)
  (dotimes (i width bytes)
    (setf (aref bytes (+ start i)) (ldb (byte 8 (* i 8)) value))))

(defun crr-crc (bytes start end)
  "CRC32C bitwise della fixture, senza chiamate al prodotto."
  (let ((crc #xffffffff))
    (loop for pos from start below end do
      (setf crc (logxor crc (aref bytes pos)))
      (dotimes (bit 8)
        (setf crc (logxor (ash crc -1) (if (oddp crc) #x82f63b78 0)))))
    (logxor crc #xffffffff)))

(defun crr-cat (&rest sequences)
  (let ((result (crr-bytes (reduce #'+ sequences :key #'length :initial-value 0))) (pos 0))
    (dolist (bytes sequences result)
      (replace result bytes :start1 pos)
      (incf pos (length bytes)))))

(defun crr-uuid ()
  (let ((bytes (crr-bytes 16)))
    (dotimes (i 16 bytes) (setf (aref bytes i) (+ 32 i)))))

(defun crr-header (version)
  (let ((bytes (crr-bytes 64)))
    (crr-pack bytes 0 #x44435241 4)
    (crr-pack bytes 4 #x314c5443 4)
    (crr-pack bytes 8 version 2)
    (replace bytes (crr-uuid) :start1 16)
    (crr-pack bytes 56 (crr-crc bytes 0 56) 4)
    bytes))

(defun crr-record (kind flags stamp payload)
  (let ((bytes (crr-bytes (+ 24 (length payload)))))
    (setf (aref bytes 8) kind (aref bytes 9) flags)
    (crr-pack bytes 12 (length payload) 4)
    (crr-pack bytes 16 stamp 8)
    (replace bytes payload :start1 24)
    (crr-pack bytes 4 (crr-crc bytes 24 (length bytes)) 4)
    (crr-pack bytes 0 (crr-crc bytes 4 24) 4)
    bytes))

(defun crr-edit (&key (next 18) (active 17) closed removed)
  "Payload locale: CLOSED=(id valid-bytes ((txid csn)...)), REMOVED=(id...)."
  (let* ((size (+ 24 (* 8 (length removed))
                  (reduce #'+ closed :initial-value 0
                          :key (lambda (entry) (+ 20 (* 16 (length (third entry))))))))
         (bytes (crr-bytes size)) (pos 20))
    (crr-pack bytes 0 next 8) (crr-pack bytes 8 active 8)
    (crr-pack bytes 16 (length closed) 4)
    (dolist (entry closed)
      (crr-pack bytes pos (first entry) 8)
      (crr-pack bytes (+ pos 8) (second entry) 8)
      (crr-pack bytes (+ pos 16) (length (third entry)) 4)
      (incf pos 20)
      (dolist (outcome (third entry))
        (crr-pack bytes pos (first outcome) 8)
        (crr-pack bytes (+ pos 8) (second outcome) 8)
        (incf pos 16)))
    (crr-pack bytes pos (length removed) 4) (incf pos 4)
    (dolist (id removed) (crr-pack bytes pos id 8) (incf pos 8))
    (is (= pos size))
    bytes))

(defun crr-rich-edit (&optional delta-p)
  (crr-edit :next (if delta-p 0 18) :active 17
            :closed '((11 120 ((101 0) (#x100000065 #xfedcba9876543210)))) :removed '(7)))

(defun crr-seal (start durable count checksum stamp)
  (let ((payload (crr-bytes 32)))
    (crr-pack payload 8 start 8) (crr-pack payload 16 durable 8)
    (crr-pack payload 24 count 4) (crr-pack payload 28 checksum 4)
    (crr-record 3 0 stamp payload)))

(defun crr-batch (start durable edits &optional (stamp #x1020304050607080))
  "EDITS contiene (flags payload); CRC SEAL sui quattro byte CRC di ciascun record."
  (let* ((records (mapcar (lambda (entry) (crr-record 5 (first entry) stamp (second entry))) edits))
         (checksums (apply #'crr-cat (mapcar (lambda (record) (subseq record 0 4)) records)))
         (seal (crr-seal start durable (length records) (crr-crc checksums 0 (length checksums)) stamp)))
    (apply #'crr-cat (append records (list seal)))))

(defun crr-log (version &optional (payload (crr-rich-edit)))
  (crr-cat (crr-header version) (crr-batch 64 0 (list (list 8 payload)))))

(defun crr-history (version)
  "Due EDIT fisici identici: le occorrenze consumano budget prima della coalescenza."
  (let ((first (crr-log version)))
    (crr-cat first (crr-batch (length first) (length first) (list (list 0 (crr-rich-edit t))) 19))))

(defun crr-view (identity)
  (let* ((csns (arcdocdb.csn:crea-registro-csn :capacity 3))
         (snapshots (arcdocdb.mvcc:crea-registro-snapshot csns 2 20 5))
         (epochs (arcdocdb.epochs:crea-registro-epoche 2 2))
         (primary (arcdocdb.index.primary:crea-indice-primario
                   :capacity 16 :max-depth 1 :arena-bytes 256
                   :directory-budget-bytes 16 :fragment-budget-bytes 912
                   :hash-seed-high 23 :hash-seed-low 29)))
    (g:crea-vista-get-serie (g:crea-ambito-get epochs snapshots) primary nil identity)))

(defstruct (crr-fixture (:constructor %crr-fixture))
  source reference identity view input backend (short 4096) (reads 0) hook closed-p
  (events (make-array 8192 :fill-pointer 0)))

(define-condition crr-foreign-failure (error)
  ((marker :initarg :marker :reader crr-foreign-marker)))

(defun crr-event (fixture event)
  (is (< (length (crr-fixture-events fixture)) 8192))
  (vector-push event (crr-fixture-events fixture)))

(defun crr-forbidden (fixture operation &rest arguments)
  (crr-event fixture (cons operation arguments))
  (error 'invariant-violation :reason :control-recovery-fixture-unexpected-io))

(defun crr-reader (f fd buffer start count offset)
  (crr-event f (list :read fd start count offset))
  (is (= fd 211)) (is (not (crr-fixture-closed-p f)))
  (incf (crr-fixture-reads f))
  (if (crr-fixture-hook f)
      (funcall (crr-fixture-hook f) f buffer start count offset)
      (crr-transfer f buffer start count offset)))

(defun crr-transfer (f buffer start count offset)
  (let ((n (min count (crr-fixture-short f) (max 0 (- (length (crr-fixture-source f)) offset)))))
    (replace buffer (crr-fixture-source f) :start1 start :end1 (+ start n)
             :start2 offset :end2 (+ offset n))
    n))

(defun crr-backend (f)
  (io:make-backend
   (lambda (path mode) (crr-event f (list :open path mode)) 211)
   (lambda (fd buffer start count offset) (crr-reader f fd buffer start count offset))
   (lambda (&rest args) (apply #'crr-forbidden f :write args))
   (lambda (&rest args) (apply #'crr-forbidden f :flush args))
   (lambda (&rest args) (apply #'crr-forbidden f :directory-flush args))
   (lambda (fd)
     (crr-event f (list :close fd))
     (is (= fd 211)) (is (not (crr-fixture-closed-p f)))
     (setf (crr-fixture-closed-p f) t) 0)
   :identity (lambda (&rest args) (apply #'crr-forbidden f :identity args))
   :entry-identity (lambda (&rest args) (apply #'crr-forbidden f :entry args))
   :rename (lambda (&rest args) (apply #'crr-forbidden f :rename args))))

(defun crr-clear (f)
  (setf (fill-pointer (crr-fixture-events f)) 0 (crr-fixture-reads f) 0))

(defun crr-with-fixture (source thunk &key (short 4096) (max-transfer 4096) (mode :input))
  (is (<= (length source) 4096)) (is (plusp short))
  (let* ((identity (crr-uuid))
         (f (%crr-fixture :source (copy-seq source) :reference (copy-seq source)
                         :identity identity :view (crr-view identity) :short short)))
    (setf (crr-fixture-backend f) (crr-backend f)
          (crr-fixture-input f)
          (ecase mode
            (:input (io:apri-lettura "/control-recovery/control.log"
                                    :backend (crr-fixture-backend f) :max-transfer max-transfer))
            (:directory (io:apri-directory "/control-recovery/"
                                          :backend (crr-fixture-backend f) :max-transfer max-transfer))
            (:append (io:crea-temporaneo "/control-recovery/control.log.tmp"
                                        :backend (crr-fixture-backend f) :max-transfer max-transfer))))
    (crr-clear f)
    (unwind-protect (funcall thunk f) (io:chiudi (crr-fixture-input f)))))

(defun crr-call (f size scratch options)
  (apply #'c:leggi-control-recuperato (crr-fixture-view f) (crr-fixture-input f) size scratch options))

(defun crr-events (f)
  (coerce (crr-fixture-events f) 'list))

(defun crr-requests (size chunk short &optional (physical-size size))
  "Oracolo di ogni richiesta, ultimo tentativo zero incluso se EOF fisico anticipato."
  (is (<= 0 size 4096)) (is (plusp chunk)) (is (plusp short))
  (is (<= 0 physical-size size))
  (let ((events nil))
    (loop for base from 0 below size by chunk do
      (let ((pos base) (end (min size (+ base chunk))))
        (loop repeat (- end base) until (= pos end) do
          (push (list :read 211 pos (- end pos) pos) events)
          (let ((n (min (- end pos) short (max 0 (- physical-size pos)))))
            (when (zerop n) (return-from crr-requests (nreverse events)))
            (incf pos n)))))
    (nreverse events)))

(defun crr-noeffects (f &optional (state :open))
  (is (equalp (crr-fixture-source f) (crr-fixture-reference f)))
  (is (equalp (crr-fixture-identity f) (crr-uuid)))
  (is (equalp (arcdocdb.get::vista-get-serie-identity (crr-fixture-view f)) (crr-uuid)))
  (is (eq state (io:stato-file (crr-fixture-input f))))
  (is (= 0 (io:posizione-scritta (crr-fixture-input f))))
  (is (= 0 (io:posizione-durevole (crr-fixture-input f))))
  (is (eq (eq state :closed) (crr-fixture-closed-p f))))

(defun crr-expect (type reason thunk &optional (offset nil offset-p))
  "Soltanto condizioni specifiche: nessun catch di ERROR, SERIOUS-CONDITION o T."
  (let ((condition
          (handler-case (progn (funcall thunk) nil)
            (invalid-argument (c) c) (resource-exhausted (c) c)
            (corruption-detected (c) c) (unsupported-format (c) c)
            (io-fault (c) c) (invariant-violation (c) c) (type-error (c) c))))
    (is (typep condition type))
    (when reason (is (eq reason (error-reason condition))))
    (when offset-p (is (eql offset (error-offset condition))))
    condition))

(defun crr-preflight (f size scratch type reason options)
  (let ((before (copy-seq scratch)) (state (io:stato-file (crr-fixture-input f))))
    (crr-expect type reason (lambda () (crr-call f size scratch options)))
    (is (equalp before scratch)) (is (null (crr-events f)))
    (crr-noeffects f state)))

(defun crr-rich-query (recovered size prefix status version)
  (is (typep recovered 'c:control-recuperato))
  (is (equal (list size prefix status version)
             (multiple-value-list (c:frontiere-control-recuperato recovered))))
  (let ((manifest (c:manifest-control-recuperato recovered)))
    (is (eq manifest (c:manifest-control-recuperato recovered)))
    (is (= 17 (arcdocdb.recovery.manifest:segmento-attivo manifest)))
    (is (equal '(t 18) (multiple-value-list (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))
    (is (= 1 (arcdocdb.recovery.manifest:numero-segmenti-chiusi manifest)))
    (is (= 1 (arcdocdb.recovery.manifest:numero-segmenti-rimossi manifest)))
    (dolist (entry '((17 :active 0 0) (11 :closed 120 2) (7 :removed 0 0) (0 :unknown 0 0)))
      (is (equal (rest entry)
                 (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest (first entry))))))
    (dolist (entry '((11 101 t 0) (11 #x100000065 t #xfedcba9876543210)
                     (11 #x200000065 nil 0) (11 100 nil 0) (7 101 nil 0) (17 101 nil 0)))
      (is (equal (cddr entry)
                 (multiple-value-list (arcdocdb.recovery.manifest:trova-esito-chiusura
                                       manifest (first entry) (second entry))))))))

(defun crr-success (f version &rest options)
  (let* ((size (length (crr-fixture-source f))) (scratch (crr-bytes (+ size 7) #xcc))
         (result (crr-call f size scratch options)))
    (crr-rich-query result size size :complete version)
    (is (equalp (subseq scratch 0 size) (crr-fixture-source f)))
    (is (every (lambda (b) (= b #xcc)) (subseq scratch size)))
    (is (equal (crr-requests size (getf options :chunk-bytes 65536) (crr-fixture-short f)) (crr-events f)))
    (crr-noeffects f)
    result))

(defun crr-read-rejection (source options type reason &optional (offset nil offset-p))
  (crr-with-fixture
   source
   (lambda (f)
     (let* ((size (length source)) (scratch (crr-bytes (+ size 7) #xcc))
            (thunk (lambda () (crr-call f size scratch (list* :chunk-bytes 31 options))))
            (condition (if offset-p (crr-expect type reason thunk offset) (crr-expect type reason thunk))))
       (is (equal (crr-requests size 31 4096) (crr-events f)))
       (is (equalp source (subseq scratch 0 size)))
       (is (every (lambda (b) (= b #xcc)) (subseq scratch size)))
       (crr-noeffects f)
       condition))))

;;; REQ: REQ-FOR-001 REQ-FOR-003
(deftest test-REQ-FOR-001-CONTROL-RECOVERY-bitwise-fixture-oracle
  (let ((check (crr-bytes 9)))
    (dotimes (i 9) (setf (aref check i) (+ 49 i)))
    (is (= #xe3069283 (crr-crc check 0 9))))
  (is (= 228 (length (crr-log 1))))
  (is (= 228 (length (crr-log 2)))))

;;; REQ: REQ-REC-001 REQ-FOR-002
(deftest test-REQ-REC-001-CONTROL-RECOVERY-v1-public-defaults
  (crr-with-fixture (crr-log 1) (lambda (f) (crr-success f 1))))

;;; REQ: REQ-REC-001 REQ-FOR-002
(deftest test-REQ-REC-001-CONTROL-RECOVERY-v2-public-defaults
  (crr-with-fixture (crr-log 2) (lambda (f) (crr-success f 2))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-017
(deftest test-REQ-REC-001-CONTROL-RECOVERY-chunks-shortreads-all-offsets
  (dolist (version '(1 2))
    (let ((source (crr-log version)))
      (loop for chunk from 1 to (1+ (length source)) do
        (dolist (short '(1 7 4096))
          (crr-with-fixture source (lambda (f) (crr-success f version :chunk-bytes chunk))
                            :short short :max-transfer (min chunk (length source))))))))

;;; REQ: REQ-REC-001 REQ-AFF-002
(deftest test-REQ-REC-001-CONTROL-RECOVERY-owned-manifest-scratch-reused
  (dolist (version '(1 2))
    (let* ((first (crr-log version)) (other (crr-log version (crr-edit :active 23 :next 24)))
           (scratch (crr-bytes (+ (length first) 7) #xcc)))
      (crr-with-fixture
       first
       (lambda (f)
         (let ((recovered (crr-call f (length first) scratch '(:chunk-bytes 31))))
           (fill scratch #xff)
           (crr-rich-query recovered (length first) (length first) :complete version)
           (crr-with-fixture
            other
            (lambda (second)
              (let ((result (crr-call second (length other) scratch '(:chunk-bytes 7))))
                (is (= 23 (arcdocdb.recovery.manifest:segmento-attivo (c:manifest-control-recuperato result))))
                (is (equal (crr-requests (length other) 7 4096) (crr-events second)))
                (crr-noeffects second))))
           (crr-rich-query recovered (length first) (length first) :complete version)
           (is (equal (crr-requests (length first) 31 4096) (crr-events f)))
           (crr-noeffects f)))))))

;;; CRV-D01: singoli operandi falsi, nessun byte scritto nello scratch o callback.
;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-CRV-D01-zero-chunk
  (crr-with-fixture (crr-log 2)
    (lambda (f) (crr-preflight f 228 (crr-bytes 228 #xcc) 'invalid-argument
                             :control-recovery-arguments '(:chunk-bytes 0)))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-CRV-D01-size-below-header
  (dotimes (size 64)
    (crr-with-fixture (crr-header 2)
      (lambda (f) (crr-preflight f size (crr-bytes 64 #xcc) 'invalid-argument
                               :control-recovery-arguments '(:chunk-bytes 1 :max-bytes 64))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-CRV-D01-budget-below-header
  (crr-with-fixture (crr-header 2)
    (lambda (f) (crr-preflight f 64 (crr-bytes 64 #xcc) 'invalid-argument
                             :control-recovery-arguments '(:chunk-bytes 1 :max-bytes 63)))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-REC-001-CONTROL-RECOVERY-CRV-D01-exact-header-no-snapshot
  (dolist (version '(1 2))
    (crr-read-rejection (crr-header version) '(:max-bytes 64) 'corruption-detected
                        :manifest-missing-snapshot 64)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-alias-before-buffer-range
  (crr-with-fixture (crr-log 2)
    (lambda (f)
      (crr-preflight f 228 (arcdocdb.get::vista-get-serie-identity (crr-fixture-view f))
                     'invalid-argument :control-recovery-alias nil))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-short-scratch-no-effects
  (crr-with-fixture (crr-log 2)
    (lambda (f) (crr-preflight f 228 (crr-bytes 227 #xcc) 'invalid-argument :buffer-range nil))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-transfer-budget-min-size-chunk
  (crr-with-fixture (crr-log 2)
    (lambda (f) (crr-preflight f 228 (crr-bytes 228 #xcc) 'resource-exhausted
                             :io-byte-budget '(:chunk-bytes 31))) :max-transfer 30)
  (crr-with-fixture (crr-log 2)
    (lambda (f) (crr-success f 2 :chunk-bytes 65536)) :max-transfer 228))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-wrong-capability-mode
  (dolist (mode '(:append :directory))
    (crr-with-fixture (crr-log 2)
      (lambda (f) (crr-preflight f 228 (crr-bytes 228 #xcc) 'invalid-argument :io-mode nil)) :mode mode)))

;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-closed-input-preflight
  (crr-with-fixture (crr-log 2)
    (lambda (f)
      (io:chiudi (crr-fixture-input f)) (crr-clear f)
      (crr-preflight f 228 (crr-bytes 228 #xcc) 'io-fault :io-unavailable nil))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-invalid-scanner-budgets-before-read
  (dolist (options '((:max-batches 0) (:max-batch-records 0)))
    (crr-with-fixture (crr-log 2)
      (lambda (f) (crr-preflight f 228 (crr-bytes 228 #xcc) 'invalid-argument :log-scan-arguments options)))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-out-of-type-budgets-before-read
  ;; APPLY conserva valori errati come dati, senza chiamate costanti contrarie al FTYPE.
  (dolist (key '(:chunk-bytes :max-bytes :max-batches :max-batch-records :max-edits :max-segmenti :max-esiti))
    (dolist (value (list -1 (if (member key '(:max-batch-records :max-segmenti :max-esiti))
                              #x100000000 (1+ most-positive-fixnum))))
      (crr-with-fixture (crr-log 2)
        (lambda (f) (crr-preflight f 228 (crr-bytes 228 #xcc) 'type-error nil (list key value)))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-exact-byte-budget-and-exhaustion
  (dolist (version '(1 2))
    (crr-with-fixture (crr-log version)
      (lambda (f)
        (crr-preflight f 228 (crr-bytes 228 #xcc) 'resource-exhausted :control-recovery-byte-budget '(:max-bytes 227))
        (crr-success f version :max-bytes 228 :max-batches 1 :max-batch-records 1
                     :max-edits 1 :max-segmenti 3 :max-esiti 2)))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-batch-budget-not-converted-to-tail
  (dolist (version '(1 2))
    (crr-with-fixture (crr-history version) (lambda (f) (crr-success f version :max-batches 2)))
    (crr-read-rejection (crr-history version) '(:max-batches 1) 'resource-exhausted :log-batch-budget 228)
    (crr-read-rejection (crr-cat (crr-log version) (crr-bytes 1)) '(:max-batches 1)
                        'resource-exhausted :log-batch-budget 228)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-record-budget-exact-and-exhausted
  (dolist (version '(1 2))
    (let ((source (crr-cat (crr-header version)
                           (crr-batch 64 0 (list (list 8 (crr-rich-edit)) (list 0 (crr-edit :next 0 :active 0)))))))
      (crr-with-fixture source (lambda (f) (crr-success f version :max-batch-records 2)))
      (crr-read-rejection source '(:max-batch-records 1) 'resource-exhausted :batch-record-budget 172))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-edit-budget-exact-and-exhausted
  (dolist (version '(1 2))
    (crr-with-fixture (crr-history version) (lambda (f) (crr-success f version :max-edits 2)))
    (crr-read-rejection (crr-history version) '(:max-edits 1) 'resource-exhausted :manifest-edit-budget 228)
    (crr-read-rejection (crr-log version) '(:max-edits 0) 'resource-exhausted :manifest-edit-budget 64)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-segment-occurrences-before-coalescence
  (dolist (version '(1 2))
    (crr-with-fixture (crr-history version) (lambda (f) (crr-success f version :max-segmenti 6)))
    (crr-read-rejection (crr-history version) '(:max-segmenti 5) 'resource-exhausted :manifest-segment-budget 228)
    (crr-read-rejection (crr-log version) '(:max-segmenti 2) 'resource-exhausted :manifest-segment-budget 64)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-outcome-occurrences-before-coalescence
  (dolist (version '(1 2))
    (crr-with-fixture (crr-history version) (lambda (f) (crr-success f version :max-esiti 4)))
    (crr-read-rejection (crr-history version) '(:max-esiti 3) 'resource-exhausted :manifest-outcome-budget 228)
    (crr-read-rejection (crr-log version) '(:max-esiti 1) 'resource-exhausted :metadata-budget 108)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-per-edit-closed-removed-budgets
  (dolist (version '(1 2))
    (dolist (payload (list (crr-edit :closed '((11 64 nil) (12 64 nil))) (crr-edit :removed '(7 8))))
      (crr-read-rejection (crr-log version payload) '(:max-segmenti 1) 'resource-exhausted :metadata-budget 108))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-RECOVERY-zero-outcomes-valid-zero-segments-exhausted
  (dolist (version '(1 2))
    (let ((source (crr-log version (crr-edit))))
      (crr-with-fixture source
        (lambda (f)
          (let ((result (crr-call f (length source) (crr-bytes (length source))
                                  '(:max-esiti 0 :max-segmenti 1 :max-edits 1))))
            (is (= 0 (arcdocdb.recovery.manifest:numero-segmenti-chiusi (c:manifest-control-recuperato result))))
            (is (equal (list (length source) (length source) :complete version)
                       (multiple-value-list (c:frontiere-control-recuperato result))))
            (is (equal (crr-requests (length source) 65536 4096) (crr-events f)))
            (crr-noeffects f))))
      (crr-read-rejection source '(:max-segmenti 0) 'resource-exhausted :manifest-segment-budget 64))))

(defun crr-witness-log (version body-p)
  (let* ((first (crr-log version)) (prefix (length first))
         (empty (crr-edit :next 0 :active 0))
         (second (crr-batch prefix prefix (list (list 0 empty) (list 0 empty)) 31))
         (third-start (+ prefix (length second)))
         (third (crr-batch third-start third-start (list (list 0 empty)) 29))
         (bad (+ prefix 48)) (witness (+ third-start 48)))
    ;; Il secondo SEAL non copre il guasto; soltanto il SEAL successivo prova corruzione.
    (setf (aref second (+ 48 (if body-p 24 0))) (logxor 1 (aref second (+ 48 (if body-p 24 0)))))
    (values (crr-cat first second third) prefix bad witness third-start)))

;;; REQ: REQ-AFF-009 REQ-AFF-017
(deftest test-REQ-AFF-009-CONTROL-RECOVERY-durable-witness-beyond-first-bad-record
  (dolist (version '(1 2))
    (dolist (body-p '(nil t))
      (multiple-value-bind (source prefix bad witness durable) (crr-witness-log version body-p)
        (let ((condition (crr-read-rejection source nil 'arcdocdb.recovery.scan:log-corruption
                                            :log-durable-corruption prefix)))
          (is (> bad prefix))
          (is (= prefix (arcdocdb.recovery.scan:corruption-prefix-end condition)))
          (is (= witness (arcdocdb.recovery.scan:corruption-witness-offset condition)))
          (is (= durable (arcdocdb.recovery.scan:corruption-durable-offset condition)))
          (is (eq (if body-p :body-crc :header-crc)
                  (arcdocdb.recovery.scan:corruption-first-reason condition))))))))

;;; REQ: REQ-REC-001 REQ-AFF-009 REQ-AFF-017
(deftest test-REQ-REC-001-CONTROL-RECOVERY-genuine-tail-every-cut-after-valid-prefix
  (dolist (version '(1 2))
    (let* ((first (crr-log version)) (prefix (length first))
           (delta (crr-edit :next 0 :active 19 :closed '((17 64 nil))))
           (second (crr-batch prefix prefix (list (list 0 delta)) 19)))
      (dotimes (cut (length second))
        (let ((source (crr-cat first (subseq second 0 cut))))
          (crr-with-fixture source
            (lambda (f)
              (let* ((scratch (crr-bytes (+ (length source) 7) #xcc))
                     (result (crr-call f (length source) scratch '(:chunk-bytes 31))))
                (crr-rich-query result (length source) prefix (if (zerop cut) :complete :tail) version)
                (is (equalp source (subseq scratch 0 (length source))))
                (is (every (lambda (b) (= b #xcc)) (subseq scratch (length source))))
                (is (equal (crr-requests (length source) 31 7) (crr-events f)))
                (crr-noeffects f))) :short 7)))
      (let ((source (crr-cat first second)))
        (crr-with-fixture source
          (lambda (f)
            (let* ((result (crr-call f (length source) (crr-bytes (length source)) nil))
                   (manifest (c:manifest-control-recuperato result)))
              (is (equal (list (length source) (length source) :complete version)
                         (multiple-value-list (c:frontiere-control-recuperato result))))
              (is (= 19 (arcdocdb.recovery.manifest:segmento-attivo manifest)))
              (is (equal '(t 20) (multiple-value-list (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))
              (is (equal '(:closed 64 0) (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest 17))))
              (is (equal (crr-requests (length source) 65536 4096) (crr-events f)))
              (crr-noeffects f))))))))

;;; REQ: REQ-REC-001 REQ-AFF-002
(deftest test-REQ-REC-001-CONTROL-RECOVERY-sealed-semantic-errors-never-tail
  (dolist (version '(1 2))
    (let ((payload (crr-edit :next 0 :active 17)))
      (crr-read-rejection (crr-cat (crr-header version) (crr-batch 64 0 (list (list 0 payload))))
                          nil 'corruption-detected :manifest-missing-snapshot 64))
    (crr-read-rejection (crr-log version (crr-edit :next 17)) nil 'corruption-detected :manifest-next-id 64)
    (let ((first (crr-log version)))
      (crr-read-rejection (crr-cat first (crr-batch (length first) (length first) (list (list 8 (crr-rich-edit)))))
                          nil 'corruption-detected :manifest-repeated-snapshot (length first)))))

;;; REQ: REQ-FOR-001
(deftest test-REQ-FOR-001-CONTROL-RECOVERY-header-crc-and-validation-order
  (dolist (version '(1 2))
    (loop for pos from 56 below 60 do
      (dotimes (bit 8)
        (let ((source (crr-log version)))
          (setf (aref source pos) (logxor (ash 1 bit) (aref source pos)))
          (crr-read-rejection source nil 'corruption-detected :log-header-crc 0))))
    (let ((source (crr-log version)))
      (crr-pack source 8 3 2) ; versione ignota senza riparare il CRC: resta un errore CRC.
      (crr-read-rejection source nil 'corruption-detected :log-header-crc 0))))

(defun crr-header-mutation (version pos value reason &optional (type 'corruption-detected))
  (let ((source (crr-log version)))
    (setf (aref source pos) value)
    (crr-pack source 56 (crr-crc source 0 56) 4)
    (crr-read-rejection source nil type reason 0)))

;;; REQ: REQ-FOR-002
(deftest test-REQ-FOR-002-CONTROL-RECOVERY-invalid-magic-valid-crc
  (dolist (version '(1 2))
    (dotimes (pos 8)
      (crr-header-mutation version pos (logxor 1 (aref (crr-header version) pos)) :log-magic))))

;;; REQ: REQ-REC-001 REQ-FOR-002
(deftest test-REQ-REC-001-CONTROL-RECOVERY-every-uuid-byte-valid-crc
  (dolist (version '(1 2))
    (dotimes (i 16) (crr-header-mutation version (+ 16 i) (logxor 1 (+ 32 i)) :log-identity))))

;;; REQ: REQ-FOR-002
(deftest test-REQ-FOR-002-CONTROL-RECOVERY-every-reserved-byte-valid-crc
  (dolist (version '(1 2))
    (dolist (range '((10 16) (32 56) (60 64)))
      (loop for pos from (first range) below (second range) do
        (crr-header-mutation version pos 1 :log-reserved)))))

;;; REQ: REQ-FOR-002
(deftest test-REQ-FOR-002-CONTROL-RECOVERY-unsupported-header-format
  (dolist (version '(0 3 65535))
    (let ((source (crr-log 2)))
      (crr-pack source 8 version 2) (crr-pack source 56 (crr-crc source 0 56) 4)
      (crr-read-rejection source nil 'unsupported-format :file-version 0))))

;;; REQ: REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-physical-eof-every-shortread-cut
  (dolist (version '(1 2))
    (let* ((full (crr-log version)) (size (length full)))
      (dotimes (cut size)
        ;; FI: EOF fisico inferiore all'attestazione del caller; mai una TAIL utilizzabile.
        (crr-with-fixture (subseq full 0 cut)
          (lambda (f)
            (let* ((scratch (crr-bytes (+ size 7) #xcc))
                   (condition (crr-expect 'io-fault :io-eof
                                         (lambda () (crr-call f size scratch '(:chunk-bytes 31))))))
              (is (eq :read (error-operation condition)))
              (is (= (mod cut 31) (arcdocdb.conditions:error-transferred condition)))
              (is (null (error-errno condition)))
              (is (equal (crr-requests size 31 7 cut) (crr-events f)))
              (is (equalp (subseq full 0 cut) (subseq scratch 0 cut)))
              (is (every (lambda (b) (= b #xcc)) (subseq scratch cut)))
              (crr-noeffects f))) :short 7)))))

(defun crr-callback-case (thunk)
  (crr-with-fixture (crr-log 2) thunk :short 7))

(defun crr-attempts-three (f scratch &optional close-p)
  (let ((expected (subseq (crr-requests 228 31 7) 0 3)))
    (is (equal (if close-p (append expected '((:close 211))) expected) (crr-events f)))
    (is (equalp (subseq (crr-log 2) 0 14) (subseq scratch 0 14)))
    (is (every (lambda (b) (= b #xcc)) (subseq scratch 14)))
    (crr-noeffects f (if close-p :closed :open))))

(defun crr-install-callback (f action close-p)
  "FI locale al terzo pread; chiudere qui viola esplicitamente la precondizione di lifetime."
  (setf (crr-fixture-hook f)
        (lambda (fixture buffer start count offset)
          (if (= 3 (crr-fixture-reads fixture))
              (progn (when close-p (io:chiudi (crr-fixture-input fixture))) (funcall action))
              (crr-transfer fixture buffer start count offset)))))

;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-original-io-condition-open-and-closed
  (dolist (close-p '(nil t))
    (crr-callback-case
     (lambda (f)
       (let ((scratch (crr-bytes 235 #xcc))
             (original (make-condition 'io-fault :reason :control-recovery-original
                                       :operation :read :errno sb-posix:eio :offset 777 :transferred 5)))
         (crr-install-callback f (lambda () (error original)) close-p)
         (is (eq original (crr-expect 'io-fault :control-recovery-original
                                     (lambda () (crr-call f 228 scratch '(:chunk-bytes 31))) 777)))
         (is (= 5 (arcdocdb.conditions:error-transferred original)))
         (is (= sb-posix:eio (error-errno original)))
         (is (eq :read (error-operation original)))
         (crr-attempts-three f scratch close-p))))))

;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-original-foreign-condition-open-and-closed
  (dolist (close-p '(nil t))
    (crr-callback-case
     (lambda (f)
       (let* ((scratch (crr-bytes 235 #xcc)) (marker (list :foreign))
              (original (make-condition 'crr-foreign-failure :marker marker)))
         (crr-install-callback f (lambda () (error original)) close-p)
         (is (eq original (handler-case (crr-call f 228 scratch '(:chunk-bytes 31))
                            (crr-foreign-failure (c) c))))
         (is (eq marker (crr-foreign-marker original)))
         (crr-attempts-three f scratch close-p))))))

;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-nonlocal-values-open-and-closed
  (dolist (close-p '(nil t))
    (crr-callback-case
     (lambda (f)
       (let ((scratch (crr-bytes 235 #xcc)) (marker (list :nonlocal)))
         (is (equal (list marker 0 #xfedcba9876543210)
                    (multiple-value-list
                     (block escape
                       (crr-install-callback f (lambda () (return-from escape (values marker 0 #xfedcba9876543210))) close-p)
                       (crr-call f 228 scratch '(:chunk-bytes 31))))))
         (crr-attempts-three f scratch close-p))))))

;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-syscall-error-progress-no-retry
  (crr-callback-case
   (lambda (f)
     (let ((scratch (crr-bytes 235 #xcc)))
       (crr-install-callback f (lambda () (error 'sb-posix:syscall-error :errno sb-posix:eio :name 'crr-read)) nil)
       (let ((condition (crr-expect 'io-fault :io-syscall
                                   (lambda () (crr-call f 228 scratch '(:chunk-bytes 31))))))
         (is (eq :read (error-operation condition)))
         (is (= sb-posix:eio (error-errno condition)))
         (is (= 14 (arcdocdb.conditions:error-transferred condition))))
       (crr-attempts-three f scratch)))))

;;; REQ: REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-invalid-reader-progress
  ;; FI backend outside-contract: nessun risultato o retry, scratch invariato.
  (dolist (result '(0 -1 32 :foreign))
    (crr-with-fixture (crr-log 2)
      (lambda (f)
        (let ((scratch (crr-bytes 235 #xcc)))
          (setf (crr-fixture-hook f) (lambda (&rest args) (declare (ignore args)) result))
          (let ((condition (crr-expect 'io-fault (if (eql result 0) :io-eof :io-invalid-progress)
                                      (lambda () (crr-call f 228 scratch '(:chunk-bytes 31))))))
            (is (eq :read (error-operation condition)))
            (is (= 0 (arcdocdb.conditions:error-transferred condition))))
          (is (equal '((:read 211 0 31 0)) (crr-events f)))
          (is (every (lambda (b) (= b #xcc)) scratch))
          (crr-noeffects f))))))

;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-close-during-read-no-result
  ;; FI outside-contract al primo/ultimo callback, dopo il trasferimento effettivo dei byte.
  (dolist (ordinal '(1 33))
    (crr-with-fixture (crr-log 2)
      (lambda (f)
        (let ((scratch (crr-bytes 235 #xcc)))
          (setf (crr-fixture-hook f)
                (lambda (fixture buffer start count offset)
                  (let ((n (crr-transfer fixture buffer start count offset)))
                    (when (= ordinal (crr-fixture-reads fixture)) (io:chiudi (crr-fixture-input fixture)))
                    n)))
          (let ((condition (crr-expect 'io-fault :io-unavailable
                                      (lambda () (crr-call f 228 scratch '(:chunk-bytes 7))))))
            (is (eq :read (error-operation condition)))
            (is (= (if (= ordinal 1) 7 4) (arcdocdb.conditions:error-transferred condition))))
          (is (equal (append (subseq (crr-requests 228 7 4096) 0 ordinal) '((:close 211))) (crr-events f)))
          (crr-noeffects f :closed))))))

(defun crr-prefix-fi (f prefix status thunk)
  "FI CRV-D02 outside-contract, helper privato; runner esclusivamente seriale.
Il vero decoder viene eseguito, poi si falsificano solo le frontiere.
La dipendenza importata dal bridge condivide il simbolo del decoder pubblico: UNWIND lo ripristina."
  (let* ((name 'c::ricostruisci-manifest) (original (fdefinition name)))
    (unwind-protect
         (progn
           (setf (fdefinition name)
                 (lambda (&rest args)
                   (multiple-value-bind (manifest real-prefix real-status) (apply original args)
                     (is (= real-prefix 228)) (is (eq real-status :complete))
                     (values manifest prefix status))))
           (funcall thunk))
      (setf (fdefinition name) original))
    (is (eq original (fdefinition name)))
    (crr-clear f)
    (crr-success f 2 :chunk-bytes 31)))

(defun crr-prefix-rejection (prefix status)
  (crr-with-fixture (crr-log 2)
    (lambda (f)
      (crr-prefix-fi f prefix status
        (lambda ()
          (let ((scratch (crr-bytes 235 #xcc)))
            (crr-expect 'invariant-violation :control-recovery-prefix
                        (lambda () (crr-call f 228 scratch '(:chunk-bytes 31))))
            (is (equal (crr-requests 228 31 4096) (crr-events f)))
            (is (equalp (crr-log 2) (subseq scratch 0 228)))
            (is (every (lambda (b) (= b #xcc)) (subseq scratch 228)))
            (crr-noeffects f)))))))

;;; CRV-D02: range falso, equivalenza COMPLETE/EOF vera in ciascuna FI.
;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-CRV-D02-prefix-before-header-outside-contract
  (crr-prefix-rejection 63 :tail))

;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-CRV-D02-prefix-beyond-eof-outside-contract
  (crr-prefix-rejection 229 :tail))

;;; CRV-D02: range vero, equivalenza falsa separatamente nei due sensi.
;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-CRV-D02-complete-before-eof-outside-contract
  (crr-prefix-rejection 227 :complete))

;;; REQ: REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-CRV-D02-tail-at-eof-outside-contract
  (crr-prefix-rejection 228 :tail))


(defun crr-call-with-dependency-fi (name replacement thunk)
  "FI privata outside-contract: sostituzione seriale, ripristino prima del cleanup fixture."
  (let ((original (fdefinition name)))
    (unwind-protect
         (progn (setf (fdefinition name) (funcall replacement original)) (funcall thunk))
      (setf (fdefinition name) original))))

;;; REQ: REQ-REC-001 REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-preflight-return-outside-contract
  (crr-with-fixture (crr-log 2)
    (lambda (f)
      (crr-call-with-dependency-fi 'arcdocdb.recovery.scan::check-scan-arguments
        (lambda (original)
          (lambda (&rest args) (1- (apply original args))))
        (lambda ()
          (crr-preflight f 228 (crr-bytes 228 #xcc) 'invariant-violation
                        :control-recovery-preflight nil))))))

;;; REQ: REQ-REC-001 REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-read-return-outside-contract
  (crr-with-fixture (crr-log 2)
    (lambda (f)
      (let ((scratch (crr-bytes 228 #xcc)))
        (crr-call-with-dependency-fi 'c::leggi-esatto
          (lambda (original) (lambda (&rest args) (1- (apply original args))))
          (lambda ()
            (crr-expect 'invariant-violation :control-recovery-read
                        (lambda () (crr-call f 228 scratch '(:chunk-bytes 31))) 0)
            (is (equal '((:read 211 0 31 0)) (crr-events f)))
            (is (equalp (subseq scratch 0 31) (subseq (crr-log 2) 0 31)))
            (is (every (lambda (byte) (= byte #xcc)) (subseq scratch 31)))
            (crr-noeffects f)))))))

;;; REQ: REQ-REC-001 REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-header-return-outside-contract
  (crr-with-fixture (crr-log 2)
    (lambda (f)
      (let ((scratch (crr-bytes 228 #xcc)))
        (crr-call-with-dependency-fi 'c::verifica-header-log
          (lambda (original)
            (lambda (&rest args)
              (multiple-value-bind (start version) (apply original args)
                (values (1- start) version))))
          (lambda ()
            (crr-expect 'invariant-violation :control-recovery-header
                        (lambda () (crr-call f 228 scratch '(:chunk-bytes 31))))
            (is (equal (crr-requests 228 31 4096) (crr-events f)))
            (is (equalp scratch (crr-log 2))) (crr-noeffects f)))))))

;;; REQ: REQ-REC-001 REQ-AFF-002
(deftest test-REQ-AFF-002-CONTROL-RECOVERY-close-after-replay-outside-contract
  (crr-with-fixture (crr-log 2)
    (lambda (f)
      (let ((scratch (crr-bytes 228)))
        (crr-call-with-dependency-fi 'c::ricostruisci-manifest
          (lambda (original)
            (lambda (&rest args)
              (multiple-value-prog1 (apply original args) (io:chiudi (crr-fixture-input f)))))
          (lambda ()
            (crr-expect 'io-fault :io-unavailable
                        (lambda () (crr-call f 228 scratch '(:chunk-bytes 31))))
            (is (equal (append (crr-requests 228 31 4096) '((:close 211))) (crr-events f)))
            (is (equalp scratch (crr-log 2))) (crr-noeffects f :closed)))))))
