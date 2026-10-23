;;;; Lettore CLOSED: matrici finite v1/v2, writer/compaction, nessuna esecuzione in stesura.
;;; OWNER: runner seriale; fixture e scratch privati, capacità mantenute dal supporto.
;;; SHARED: nessuna sostituzione globale; guasti solo tramite hook del backend della fixture.
;;; Oracoli indipendenti: richieste residue calcolate da P/chunk/short, byte e CRC CT/RT.
;;; Limiti: file <=4096 byte, eventi <=32768, cicli limitati alle matrici o ai byte dichiarati.
;;; REQ: REQ-REC-001 REQ-STO-006 REQ-FOR-001 REQ-FOR-002 REQ-AFF-002 REQ-AFF-008
(in-package #:arcdocdb.recovery.closed.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun cdrr-bytes (size &optional (fill #xa5))
  (ct::crr-bytes size fill))

(defun cdrr-log (version origin &optional (id 2))
  "Due record ordinari; writer in due lotti, compaction senza SEAL."
  (let ((put (cdr-record :put 17 :key #(7) :value #(8 9)))
        (tombstone (cdr-record :tombstone 19 :key #(10))))
    (if (= origin 1)
        (cdr-log (list (cdr-batch 17 put) (cdr-batch 19 tombstone))
                 :version version :origin origin :id id)
        (cdr-log nil :records (list put tombstone) :version version :origin origin :id id))))

(defun cdrr-requests (prefix chunk short &optional (physical-size prefix) (fd 502))
  "Header poi corpo, senza identità/EOF: ogni short riduce esattamente il residuo."
  (is (<= 64 prefix 4096)) (is (plusp chunk)) (is (plusp short))
  (is (<= 0 physical-size prefix))
  (let ((events nil))
    (dolist (range (cons '(0 64)
                        (loop for base from 64 below prefix by chunk
                              collect (list base (min prefix (+ base chunk))))))
      (destructuring-bind (base end) range
        (let ((pos base))
          (loop repeat (- end base) until (= pos end) do
            (push (list :read fd pos (- end pos) pos) events)
            (let ((n (min (- end pos) short (max 0 (- physical-size pos)))))
              (when (zerop n) (return-from cdrr-requests (nreverse events)))
              (incf pos n))))))
    (nreverse events)))

(defun cdrr-events (f expected)
  (is (equal expected (cdr-events f)))
  (is (= (count :read expected :key #'first) (cdr-fixture-reads f))))

(defun cdrr-scratch (f copied)
  "Byte copiati identici alla sorgente; canary intatti da COPIED fino alla fine dello scratch."
  (let ((scratch (cdr-fixture-scratch f)))
    (is (equalp (subseq scratch 0 copied) (subseq (cdr-fixture-source f) 0 copied)))
    (is (every (lambda (byte) (= byte #xa5)) (subseq scratch copied)))))

(defun cdrr-query (result id prefix version origin batches records)
  (is (typep result 'cr:closed-recuperato))
  (is (equal (list id prefix version origin)
             (multiple-value-list (cr:frontiere-closed-recuperato result))))
  (is (equal (list batches records 0 0 0 0)
             (multiple-value-list (cr:statistiche-closed-recuperato result)))))

(defun cdrr-success (f version origin batches records &rest options)
  (let ((result (apply #'cdr-call f options)))
    (cdrr-query result (cdr-fixture-id f) (cdr-fixture-prefix f) version origin batches records)
    (cdrr-events f (cdrr-requests (cdr-fixture-prefix f)
                                (getf options :chunk-bytes 65536) (cdr-fixture-short f)))
    (cdrr-scratch f (cdr-fixture-prefix f)) (cdr-noeffects f)
    result))

(defun cdrr-preflight (f type reason options)
  "Rifiuto senza alcuna chiamata backend e senza mutare lo scratch."
  (let ((before (copy-seq (cdr-fixture-scratch f)))
        (condition (cdr-expect type reason (lambda () (apply #'cdr-call f options)))))
    (unless (typep condition 'type-error) (is (null (error-offset condition))))
    (is (equalp before (cdr-fixture-scratch f)))
    (cdrr-events f nil) (cdr-noeffects f)
    condition))

(defun cdrr-repair-header (source)
  (ct::crr-pack source 56 (ct::crr-crc source 0 56) 4)
  source)

(defun cdrr-header-rejection (source version type reason)
  (cdr-with-fixture source
    (lambda (f)
      (setf (cdr-fixture-scratch f) (cdrr-bytes (+ 7 (length source))))
      (let ((condition (cdr-expect type reason (lambda () (cdr-call f :chunk-bytes 1)))))
        (is (eql 0 (error-offset condition))))
      (cdrr-events f '((:read 502 0 64 0)))
      (cdrr-scratch f 64) (cdr-noeffects f))
    :version version))

(defun cdrr-revoked-effects (f fd)
  "Solo la close esplicita è ammessa; byte, UUID e frontiere restano intatti."
  (is (equalp (cdr-fixture-source f) (cdr-fixture-reference f)))
  (is (equalp (gethash 501 (cdr-fixture-images f)) (cdr-fixture-control-source f)))
  (is (equalp (arcdocdb.get::vista-get-serie-identity (cdr-fixture-view f)) (ct::crr-uuid)))
  (dolist (entry (list (list 501 (cdr-fixture-control-input f)) (list 502 (cdr-fixture-input f))))
    (destructuring-bind (number input) entry
      (is (eq :input (io:mode-file input)))
      (is (eq (if (= fd number) :closed :open) (io:stato-file input)))
      (is (eql (= fd number) (not (null (gethash number (cdr-fixture-closed f))))))
      (is (zerop (io:posizione-scritta input))) (is (zerop (io:posizione-durevole input)))))
  (is (every (lambda (event) (member (first event) '(:read :close))) (cdr-events f))))

(defun cdrr-transfer-error (condition reason transferred &optional errno)
  (is (typep condition 'io-fault)) (is (eq reason (error-reason condition)))
  (is (eq :read (arcdocdb.conditions:error-operation condition)))
  (is (eql errno (arcdocdb.conditions:error-errno condition)))
  (is (= transferred (arcdocdb.conditions:error-transferred condition)))
  (is (null (error-offset condition))))

;;; REQ: REQ-REC-001 REQ-FOR-002 REQ-AFF-008
(deftest test-REQ-REC-001-CLOSED-READ-CDR-D01-header-only-all-true
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (dolist (id '(0 2 #x100000002 #xffffffffffffffff))
        (cdr-with-fixture (cdr-log nil :version version :origin origin :id id)
          (lambda (f)
            (dolist (bytes '(64 #xffffffff))
              (cdr-clear f)
              (setf (cdr-fixture-scratch f) (cdrr-bytes 71))
              (cdrr-success f version origin 0 0 :chunk-bytes 1 :max-bytes bytes :max-batches 1
                            :max-batch-records 1 :max-batch-bytes 56 :max-records 0
                            :max-prepared 0 :max-outcomes 0 :max-esiti-chiusura 0)))
          :version version :id id :max-transfer 64)))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-CLOSED-READ-CDR-D01-each-false-and-byte-bounds
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (dolist (options '((:chunk-bytes 0) (:max-bytes 63) (:max-bytes #x100000000)
                         (:max-batches 0) (:max-batch-records 0) (:max-batch-bytes 55)
                         (:chunk-bytes 0 :max-bytes 63 :max-batches 0
                          :max-batch-records 0 :max-batch-bytes 55)))
        (cdr-with-fixture (cdr-log nil :version version :origin origin)
          (lambda (f)
            (cdrr-preflight f 'invalid-argument :closed-recovery-arguments options))
          :version version)))))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-AFF-002
(deftest test-REQ-FOR-001-CLOSED-READ-header-crc-precedes-fields-and-body
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (dolist (pos '(0 4 8 10 16 32 48 56))
        (let ((source (cdrr-log version origin)))
          (setf (aref source pos) (logxor 1 (aref source pos)))
          (cdrr-header-rejection source version 'corruption-detected :segment-header-crc))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-CLOSED-READ-typed-arguments-before-io
  (dolist (version '(1 2))
    (cdr-with-fixture (cdrr-log version 1)
      (lambda (f)
        (let ((before (copy-seq (cdr-fixture-scratch f))))
          (dolist (key '(:chunk-bytes :max-bytes :max-batches :max-records :max-batch-records
                         :max-batch-bytes :max-prepared :max-outcomes :max-esiti-chiusura))
            (dolist (value (list -1 nil 1/2
                                (if (member key '(:max-batch-records :max-prepared :max-outcomes
                                                 :max-esiti-chiusura))
                                    #x100000000 (1+ most-positive-fixnum))))
              (cdr-expect 'type-error nil
                (lambda ()
                  (cdr-invoke 'cr:leggi-closed-recuperato (cdr-fixture-control f)
                    (cdr-fixture-input f) (cdr-fixture-id f) (cdr-fixture-scratch f) key value)))))
          (dolist (id '(-1 #x10000000000000000 nil))
            (cdr-expect 'type-error nil
              (lambda ()
                (cdr-invoke 'cr:leggi-closed-recuperato (cdr-fixture-control f)
                  (cdr-fixture-input f) id (cdr-fixture-scratch f)))))
          (dolist (args (list (list nil (cdr-fixture-input f) 2 (cdr-fixture-scratch f))
                             (list (cdr-fixture-control f) nil 2 (cdr-fixture-scratch f))
                             (list (cdr-fixture-control f) (cdr-fixture-input f) 2 #(1 2 3))))
            (cdr-expect 'type-error nil (lambda () (apply #'cdr-invoke 'cr:leggi-closed-recuperato args))))
          (is (equalp before (cdr-fixture-scratch f))))
        (cdrr-events f nil) (cdr-noeffects f))
      :version version)))

;;; REQ: REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-CLOSED-READ-backend-mismatch-before-io
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (cdr-with-fixture (cdrr-log version origin)
        (lambda (f)
          (cdr-with-fixture (cdrr-log version origin)
            (lambda (other)
              (let ((before (copy-seq (cdr-fixture-scratch f))))
                (cdr-expect 'invalid-argument :closed-recovery-backend
                  (lambda ()
                    (cr:leggi-closed-recuperato (cdr-fixture-control f) (cdr-fixture-input other)
                      (cdr-fixture-id f) (cdr-fixture-scratch f))))
                (is (equalp before (cdr-fixture-scratch f))))
              (cdrr-events f nil) (cdrr-events other nil)
              (cdr-noeffects f) (cdr-noeffects other))
            :version version))
        :version version))))

;;; REQ: REQ-AFF-002 REQ-STO-006
(deftest test-REQ-AFF-002-CLOSED-READ-mode-before-backend-and-io
  ;; Capacità autentica, creata pubblicamente: nessuna mutazione degli slot del prodotto.
  (dolist (version '(1 2))
    (dolist (mode '(:append :directory))
      (let* ((calls nil)
             (forbidden (lambda (&rest args) (push args calls) (error "I/O inatteso nel rifiuto modo")))
             (backend (io:make-backend
                       (lambda (path actual-mode)
                         (is (string= path "/closed-fixture/mode.tmp")) (is (eq mode actual-mode)) 503)
                       forbidden forbidden forbidden forbidden
                       (lambda (fd) (is (= fd 503)) 0)))
             (input (if (eq mode :append)
                        (io:crea-temporaneo "/closed-fixture/mode.tmp" :backend backend)
                        (io:apri-directory "/closed-fixture/mode.tmp" :backend backend))))
        (unwind-protect
             (cdr-with-fixture (cdr-log nil :version version)
               (lambda (f)
                 (let ((before (copy-seq (cdr-fixture-scratch f))))
                   (cdr-expect 'invalid-argument :io-mode
                     (lambda ()
                       (cr:leggi-closed-recuperato (cdr-fixture-control f) input 2 (cdr-fixture-scratch f))))
                   (is (equalp before (cdr-fixture-scratch f))))
                 (is (null calls)) (is (eq :open (io:stato-file input)))
                 (is (zerop (io:posizione-scritta input))) (is (zerop (io:posizione-durevole input)))
                 (cdrr-events f nil) (cdr-noeffects f))
               :version version)
          (io:chiudi input))))))

;;; REQ: REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-CLOSED-READ-either-capability-closed-before-io
  (dolist (version '(1 2))
    (dolist (fd '(501 502))
      (cdr-with-fixture (cdrr-log version 1)
        (lambda (f)
          (io:chiudi (if (= fd 501) (cdr-fixture-control-input f) (cdr-fixture-input f)))
          (cdr-clear f)
          (let ((before (copy-seq (cdr-fixture-scratch f)))
                (condition (cdr-expect 'io-fault :io-unavailable (lambda () (cdr-call f)))))
            (is (eq :input (arcdocdb.conditions:error-operation condition)))
            (is (zerop (arcdocdb.conditions:error-transferred condition)))
            (is (null (error-offset condition)))
            (is (equalp before (cdr-fixture-scratch f))))
          (cdrr-events f nil) (cdrr-revoked-effects f fd))
        :version version))))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-008
(deftest test-REQ-REC-001-CLOSED-READ-membership-before-header
  (dolist (version '(1 2))
    (cdr-with-fixture (cdrr-log version 1)
      (lambda (f)
        (dolist (id '(9 3 #x100000002))
          ;; ACTIVE, sconosciuto, ID che differisce solo nei bit alti.
          (let ((before (copy-seq (cdr-fixture-scratch f))))
            (cdr-expect 'invalid-argument :closed-recovery-state
              (lambda ()
                (cr:leggi-closed-recuperato (cdr-fixture-control f) (cdr-fixture-input f)
                  id (cdr-fixture-scratch f))))
            (is (equalp before (cdr-fixture-scratch f)))))
        (cdrr-events f nil) (cdr-noeffects f))
      :version version)
    (cdr-with-fixture (cdr-log nil :version version)
      (lambda (f) (cdrr-preflight f 'invalid-argument :closed-recovery-state nil))
      :version version :closed nil)))

;;; REQ: REQ-AFF-008 REQ-FOR-001
(deftest test-REQ-AFF-008-CLOSED-READ-scratch-alias-range-and-canaries
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (cdr-with-fixture (cdrr-log version origin)
        (lambda (f)
          (setf (cdr-fixture-scratch f) (arcdocdb.get::vista-get-serie-identity (cdr-fixture-view f)))
          (cdrr-preflight f 'invalid-argument :closed-recovery-alias nil)
          (setf (cdr-fixture-scratch f) (copy-seq (cdr-fixture-scratch f)))
          (cdrr-preflight f 'invalid-argument :buffer-range nil)
          (setf (cdr-fixture-scratch f) (cdrr-bytes (1- (cdr-fixture-prefix f))))
          (cdrr-preflight f 'invalid-argument :buffer-range nil)
          (setf (cdr-fixture-scratch f) (cdrr-bytes (+ 7 (cdr-fixture-prefix f))))
          (cdrr-success f version origin (if (= origin 1) 2 0) 2))
        :version version))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-CLOSED-READ-prefix-and-closure-budgets-before-io
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (cdr-with-fixture (cdrr-log version origin)
        (lambda (f)
          (cdrr-preflight f 'resource-exhausted :closed-recovery-byte-budget
                          (list :max-bytes (1- (cdr-fixture-prefix f))))
          (cdrr-preflight f 'resource-exhausted :closed-recovery-closure-budget '(:max-esiti-chiusura 1))
          (cdrr-success f version origin (if (= origin 1) 2 0) 2
                        :max-bytes (cdr-fixture-prefix f) :max-esiti-chiusura 2))
        ;; Esiti EDIT orfani: contati dal preflight, senza prepared da classificare.
        :version version :outcomes '((77 0) (#x10000004d #xffffffffffffffff))))))

;;; REQ: REQ-AFF-008 REQ-AFF-002
(deftest test-REQ-AFF-008-CLOSED-READ-transfer-budget-exact-and-minus-one
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (let* ((record (cdr-record :put 17 :key #(7) :value (cdrr-bytes 128 8)))
             (source (if (= origin 1)
                         (cdr-log (list (cdr-batch 17 record)) :version version)
                         (cdr-log nil :records (list record) :origin 2 :version version)))
             (body (- (length source) 64)))
        (dolist (chunk (list 1 64 65 body (1+ body) 4096))
          (let ((required (max 64 (min body chunk))))
            (dolist (capacity (list (1- required) required))
              (cdr-with-fixture source
                (lambda (f)
                  (if (= capacity required)
                      (cdrr-success f version origin (if (= origin 1) 1 0) 1 :chunk-bytes chunk)
                      (cdrr-preflight f 'resource-exhausted :io-byte-budget (list :chunk-bytes chunk))))
                :version version :max-transfer capacity))))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-STO-006
(deftest test-REQ-FOR-001-CLOSED-READ-entire-uuid-and-full-u64-id
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (loop for pos from 16 below 40 do
        (let ((source (cdrr-log version origin)))
          (setf (aref source pos) (logxor 1 (aref source pos)))
          (cdrr-header-rejection (cdrr-repair-header source) version 'corruption-detected :segment-identity)))
      (dolist (id '(0 2 #x100000002 #x8000000000000002 #xffffffffffffffff))
        (cdr-with-fixture (cdrr-log version origin id)
          (lambda (f) (cdrr-success f version origin (if (= origin 1) 2 0) 2 :chunk-bytes 64))
          :version version :id id)))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-CLOSED-READ-magic-and-all-reserved-bytes-before-body
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (dolist (range '((0 8 :segment-magic) (11 16 :segment-reserved)
                       (48 56 :segment-reserved) (60 64 :segment-reserved)))
        (destructuring-bind (start end reason) range
          (loop for pos from start below end do
            (let ((source (cdrr-log version origin)))
              (setf (aref source pos) (logxor 1 (aref source pos)))
              (cdrr-header-rejection (cdrr-repair-header source) version 'corruption-detected reason))))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-CLOSED-READ-unknown-version-and-origin-before-body
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (dolist (unknown '(0 3 256 65535))
        (let ((source (cdrr-log version origin)))
          (ct::crr-pack source 8 unknown 2)
          (cdrr-header-rejection (cdrr-repair-header source) version 'unsupported-format :file-version)))
      (dolist (unknown '(0 3 255))
        (let ((source (cdrr-log version origin)))
          (setf (aref source 10) unknown)
          (cdrr-header-rejection (cdrr-repair-header source) version 'corruption-detected :segment-origin))))))

;;; REQ: REQ-REC-001 REQ-FOR-002
(deftest test-REQ-FOR-002-CLOSED-READ-version-comes-from-segment-header
  (dolist (control-version '(1 2))
    (dolist (segment-version '(1 2))
      (dolist (origin '(1 2))
        (cdr-with-fixture (cdrr-log segment-version origin)
          (lambda (f) (cdrr-success f segment-version origin (if (= origin 1) 2 0) 2))
          :version control-version)))))

;;; REQ: REQ-AFF-002 REQ-REC-001
(deftest test-REQ-AFF-002-CLOSED-READ-chunks-shorts-and-last-short
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (dolist (chunk '(1 31 64 65 4096))
        (dolist (short '(1 7 64 4096))
          (cdr-with-fixture (cdrr-log version origin)
            (lambda (f)
              (setf (cdr-fixture-scratch f) (cdrr-bytes (+ 7 (length (cdr-fixture-source f)))))
              (cdrr-success f version origin (if (= origin 1) 2 0) 2 :chunk-bytes chunk))
            :version version :short short))))))

;;; REQ: REQ-STO-006 REQ-REC-001 REQ-AFF-002
(deftest test-REQ-STO-006-CLOSED-READ-header-only-prefix-ignores-physical-tail
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (let ((source (ct::crr-cat (cdr-log nil :version version :origin origin) (cdrr-bytes 97 #xff))))
        (cdr-with-fixture source
          (lambda (f)
            (cdrr-success f version origin 0 0 :chunk-bytes 4096 :max-bytes 64 :max-records 0
                          :max-prepared 0 :max-outcomes 0 :max-esiti-chiusura 0))
          :version version :prefix 64 :max-transfer 64)))))

;;; REQ: REQ-STO-006 REQ-REC-001 REQ-AFF-002
(deftest test-REQ-STO-006-CLOSED-READ-prefix-is-authoritative-over-complete-or-broken-tail
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (multiple-value-bind (whole layouts) (cdrr-log version origin)
        (let ((prefix (getf (first layouts) :end)))
          (dolist (broken '(nil t))
            (let ((source (copy-seq whole)))
              (when broken (setf (aref source prefix) (logxor 1 (aref source prefix))))
              (cdr-with-fixture source
                (lambda (f)
                  (cdrr-success f version origin (if (= origin 1) 1 0) 1 :chunk-bytes 31
                                :max-bytes prefix :max-records 1 :max-batches 1))
                :version version :prefix prefix))))))))

;;; REQ: REQ-AFF-002 REQ-STO-006 REQ-REC-001
(deftest test-REQ-AFF-002-CLOSED-READ-physical-eof-before-authoritative-prefix
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (let* ((whole (cdrr-log version origin)) (prefix (length whole)))
        (dolist (cut (list 0 1 63 64 65 (1- prefix)))
          ;; EOF fisico reale del backend, P invariato nel CONTROL pubblico.
          (cdr-with-fixture (subseq whole 0 cut)
            (lambda (f)
              (setf (cdr-fixture-scratch f) (cdrr-bytes (+ 7 prefix)))
              (let ((condition (cdr-expect 'io-fault :io-eof (lambda () (cdr-call f :chunk-bytes 31)))))
                (cdrr-transfer-error condition :io-eof (if (< cut 64) cut (mod (- cut 64) 31))))
              (cdrr-events f (cdrr-requests prefix 31 7 cut))
              (cdrr-scratch f cut) (cdr-noeffects f))
            :version version :prefix prefix :short 7))))))

;;; REQ: REQ-AFF-002 REQ-REC-001
(deftest test-REQ-AFF-002-CLOSED-READ-original-conditions-preserved-even-after-revocation
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (dolist (foreign '(nil t))
        (dolist (close-p '(nil t))
          (dolist (index '(2 11))
            (cdr-with-fixture (cdrr-log version origin)
              (lambda (f)
                (let* ((marker (list :original))
                       (original (if foreign
                                     (make-condition 'simple-error :format-control "Guasto ~S" :format-arguments marker)
                                     (make-condition 'io-fault :reason :io-syscall :operation :read
                                                     :errno sb-posix:eintr :offset 777 :transferred 5)))
                       (requests (cdrr-requests (cdr-fixture-prefix f) 31 7))
                       (copied (fifth (nth index requests))))
                  (setf (cdr-fixture-hook f)
                        (lambda (fixture fd buffer start count offset)
                          (if (= (1+ index) (cdr-fixture-reads fixture))
                              (progn
                                (when close-p (io:chiudi (cdr-fixture-input fixture)))
                                (error original))
                              (cdr-transfer fixture fd buffer start count offset))))
                  (let ((caught (if foreign
                                    (handler-case (cdr-call f :chunk-bytes 31) (simple-error (condition) condition))
                                    (cdr-expect 'io-fault :io-syscall (lambda () (cdr-call f :chunk-bytes 31))))))
                    (is (eq original caught))
                    (if foreign
                        (is (eq marker (simple-condition-format-arguments caught)))
                        (progn
                          (is (eql 777 (error-offset caught)))
                          (is (= 5 (arcdocdb.conditions:error-transferred caught)))
                          (is (= sb-posix:eintr (arcdocdb.conditions:error-errno caught)))
                          (is (eq :read (arcdocdb.conditions:error-operation caught))))))
                  (cdrr-events f (append (subseq requests 0 (1+ index)) (when close-p '((:close 502)))))
                  (cdrr-scratch f copied)
                  (if close-p (cdrr-revoked-effects f 502) (cdr-noeffects f))))
              :version version :short 7)))))))

;;; REQ: REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-CLOSED-READ-syscall-and-invalid-progress-stop-at-first-error
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (let* ((source (cdrr-log version origin)) (requests (cdrr-requests (length source) 31 7)))
        (dolist (index (list 0 1 10 (1- (length requests))))
          (dolist (failure '(:eintr :eio :zero :negative :fraction :too-large :nil))
            (cdr-with-fixture source
              (lambda (f)
                (setf (cdr-fixture-hook f)
                      (lambda (fixture fd buffer start count offset)
                        (if (= (1+ index) (cdr-fixture-reads fixture))
                            (ecase failure
                              ((:eintr :eio)
                               (error 'sb-posix:syscall-error :name 'pread
                                      :errno (if (eq failure :eintr) sb-posix:eintr sb-posix:eio)))
                              (:zero 0) (:negative -1) (:fraction 1/2) (:too-large (1+ count)) (:nil nil))
                            (cdr-transfer fixture fd buffer start count offset))))
                (let* ((copied (fifth (nth index requests)))
                       (reason (case failure
                                 ((:eintr :eio) :io-syscall) (:zero :io-eof) (otherwise :io-invalid-progress)))
                       (errno (case failure (:eintr sb-posix:eintr) (:eio sb-posix:eio) (otherwise nil)))
                       (condition (cdr-expect 'io-fault reason (lambda () (cdr-call f :chunk-bytes 31)))))
                  (cdrr-transfer-error condition reason (if (< copied 64) copied (mod (- copied 64) 31)) errno)
                  (cdrr-events f (subseq requests 0 (1+ index)))
                  (cdrr-scratch f copied) (cdr-noeffects f)))
              :version version :short 7)))))))

;;; REQ: REQ-AFF-002 REQ-STO-006 REQ-REC-001
(deftest test-REQ-AFF-002-CLOSED-READ-revocation-during-header-body-and-final-transfer
  ;; Revoca deliberatamente fuori dal contratto di lifetime, tramite il solo backend locale.
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (let* ((source (cdrr-log version origin)) (prefix (length source))
             (requests (cdrr-requests prefix 31 7)))
        (dolist (index (list 0 9 10 (1- (length requests))))
          (dolist (fd-to-close '(501 502))
            (cdr-with-fixture source
              (lambda (f)
                (setf (cdr-fixture-hook f)
                      (lambda (fixture fd buffer start count offset)
                        (let ((n (cdr-transfer fixture fd buffer start count offset)))
                          (when (= (1+ index) (cdr-fixture-reads fixture))
                            (io:chiudi (if (= fd-to-close 501)
                                          (cdr-fixture-control-input fixture) (cdr-fixture-input fixture))))
                          n)))
                (let* ((event (nth index requests))
                       (copied (+ (fifth event) (min 7 (fourth event))))
                       (segment-p (= fd-to-close 502))
                       (condition (cdr-expect 'io-fault :io-unavailable (lambda () (cdr-call f :chunk-bytes 31)))))
                  (if segment-p
                      (cdrr-transfer-error condition :io-unavailable
                                           (if (<= copied 64) copied
                                               (- copied (+ 64 (* 31 (floor (- (fifth event) 64) 31))))))
                      (progn
                        (is (eq :input (arcdocdb.conditions:error-operation condition)))
                        (is (zerop (arcdocdb.conditions:error-transferred condition)))
                        (is (null (error-offset condition)))))
                  (cdrr-events f (append (subseq requests 0 (1+ index)) (list (list :close fd-to-close))
                                        (unless segment-p (subseq requests (1+ index)))))
                  (cdrr-scratch f (if segment-p copied prefix))
                  (cdrr-revoked-effects f fd-to-close)))
              :version version :short 7)))))))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-STO-006 REQ-AFF-002
(deftest test-REQ-FOR-003-CLOSED-READ-corruption-before-prefix-is-never-tail
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (multiple-value-bind (whole layouts) (cdrr-log version origin)
        (dolist (layout layouts)
          (let ((record (first (getf layout :records))))
            (dolist (delta '(0 24))
              (let ((source (copy-seq whole)))
                (setf (aref source (+ record delta)) (logxor 1 (aref source (+ record delta))))
                (cdr-with-fixture source
                  (lambda (f)
                    (let ((condition (cdr-expect 'corruption-detected (if (zerop delta) :header-crc :body-crc)
                                                (lambda () (cdr-call f :chunk-bytes 31)))))
                      (is (eql record (error-offset condition))))
                    (cdrr-events f (cdrr-requests (cdr-fixture-prefix f) 31 4096))
                    (cdrr-scratch f (cdr-fixture-prefix f)) (cdr-noeffects f))
                  :version version)))))))))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-STO-006
(deftest test-REQ-STO-006-CLOSED-READ-incomplete-prefix-is-rejected-without-reading-tail
  (dolist (version '(1 2))
    (dolist (origin '(1 2))
      (multiple-value-bind (source layouts) (cdrr-log version origin)
        (let* ((first (first layouts)) (record (first (getf first :records)))
               (record-end (if (= origin 1) (getf first :seal) (getf first :end)))
               (cuts (list (list (1+ record) record :truncated-header)
                           (list (+ record 24) record :record-length)
                           (list (1- record-end) record :record-length))))
          (when (= origin 1)
            (setf cuts (append cuts (list (list record-end record-end :truncated-header)
                                          (list (1+ record-end) record-end :truncated-header)
                                          (list (1- (getf first :end)) record-end :record-length)))))
          (dolist (entry cuts)
            (destructuring-bind (prefix offset reason) entry
              (cdr-with-fixture source
                (lambda (f)
                  (let ((condition (cdr-expect 'corruption-detected reason (lambda () (cdr-call f :chunk-bytes 31)))))
                    (is (eql offset (error-offset condition))))
                  (cdrr-events f (cdrr-requests prefix 31 4096))
                  (cdrr-scratch f prefix) (cdr-noeffects f))
                :version version :prefix prefix))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-002
(deftest test-REQ-AFF-008-CLOSED-READ-CDR-D03-body-range-each-false-and-exact
  ;; Ingresso interno diretto: nessuna FI globale, nessun risultato del codec contraffatto.
  (dolist (version '(1 2))
    (cdr-with-fixture (cdrr-log version 1)
      (lambda (f)
        (dolist (pair '((64 0) (63 1) (63 0)))
          (let ((before (copy-seq (cdr-fixture-scratch f))))
            (cdr-expect 'invalid-argument :closed-recovery-read-range
              (lambda ()
                (cdr-invoke 'cr::leggi-corpo-closed (cdr-fixture-input f) (first pair)
                  (cdr-fixture-scratch f) (second pair))))
            (is (equalp before (cdr-fixture-scratch f)))))
        (cdrr-events f nil)
        (cr::leggi-corpo-closed (cdr-fixture-input f) 64 (cdr-fixture-scratch f) 1)
        (cdrr-events f nil) (cdrr-scratch f 0) (cdr-noeffects f)
        (dolist (chunk '(1 64 4096))
          (cdr-clear f)
          (setf (cdr-fixture-scratch f) (cdrr-bytes (+ 7 (cdr-fixture-prefix f))))
          (cr::leggi-corpo-closed (cdr-fixture-input f) (cdr-fixture-prefix f) (cdr-fixture-scratch f) chunk)
          (cdrr-events f (remove-if (lambda (event) (< (fifth event) 64))
                                   (cdrr-requests (cdr-fixture-prefix f) chunk 4096)))
          (is (every (lambda (byte) (= byte #xa5)) (subseq (cdr-fixture-scratch f) 0 64)))
          (is (equalp (subseq (cdr-fixture-scratch f) 64 (cdr-fixture-prefix f))
                      (subseq (cdr-fixture-source f) 64 (cdr-fixture-prefix f))))
          (is (every (lambda (byte) (= byte #xa5)) (subseq (cdr-fixture-scratch f) (cdr-fixture-prefix f))))
          (cdr-noeffects f)))
      :version version)))
