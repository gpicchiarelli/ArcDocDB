;;;; Lettura funzionale del decision log dell'Archivio; stesura senza esecuzioni.
;;; OWNER: runner seriale; fixture privata, capacità mantenuta fino al cleanup del supporto.
;;; SHARED: nessuna sostituzione di FDEFINITION, worker, attesa o modifica ai sorgenti prodotto.
;;; Oracoli: header/CRC bytewise, spec DECISION e layout indipendenti dal prodotto.
;;; Limiti: file e scratch <=4096 byte, matrici finite, eventi limitati dal supporto.
;;; FI locali: EOF anticipato, progresso impossibile, errore backend e revoca del FD.
;;; Gli accessori privati dell'UUID servono solo alla FI di alias dello scratch.
;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-FOR-001 REQ-FOR-002 REQ-FOR-003
;;; REQ: REQ-AFF-002 REQ-AFF-008 REQ-AFF-009 REQ-AFF-017
(in-package #:arcdocdb.recovery.archive.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun darr-specs ()
  (let ((ids (list (rt::participant-id 1) (rt::participant-id 2 #x80))))
    (list (rt::decision-spec 17 0 ids) (rt::decision-spec 18 #x100000001 (reverse ids)))))

(defun darr-log (version &optional (batches 2))
  (dar-log (loop repeat batches collect (darr-specs)) :version version))

(defun darr-requests (size chunk short &optional (physical-size size))
  "Oracolo pread: header separato, poi chunk e richieste residue degli short read."
  (is (<= 64 size 4096)) (is (plusp chunk)) (is (plusp short))
  (is (<= 0 physical-size size))
  (let ((events nil))
    (dolist (range (cons '(0 64)
                        (loop for base from 64 below size by chunk
                              collect (list base (min size (+ base chunk))))))
      (destructuring-bind (base end) range
        (let ((pos base))
          (loop repeat (- end base) until (= pos end) do
            (push (list :read 401 pos (- end pos) pos) events)
            (let ((n (min (- end pos) short (max 0 (- physical-size pos)))))
              (when (zerop n) (return-from darr-requests (nreverse events)))
              (incf pos n))))))
    (nreverse events)))

(defun darr-events (f expected)
  (is (equal expected (dar-events f)))
  (is (= (count :read expected :key #'first) (dar-fixture-reads f))))

(defun darr-scratch (f copied)
  (let ((scratch (dar-fixture-scratch f)))
    (is (equalp (subseq scratch 0 copied) (subseq (dar-fixture-source f) 0 copied)))
    (is (every (lambda (byte) (= byte #xa5)) (subseq scratch copied)))))

(defun darr-result (result size prefix status version)
  (is (typep result 'da:decisioni-recuperate))
  (is (equal (list size prefix status version)
             (multiple-value-list (da:frontiere-decisioni-recuperate result)))))

(defun darr-table (result specs &optional (missing '(1024 1025)))
  "Confronto dichiarativo tramite sole query pubbliche, senza decodificare il log."
  (let ((expected (rt::decision-oracle specs)))
    (is (= (length expected) (da:numero-decisioni-recuperate result)))
    (dolist (entry expected)
      (destructuring-bind (txid csn ids) entry
        (is (equal (list t csn (length ids))
                   (multiple-value-list (da:trova-decisione-recuperata result txid))))
        (dolist (id ids)
          (is (da:partecipante-decisione-recuperata-p result txid id 0 16)))))
    (dolist (txid missing)
      (is (null (assoc txid expected)))
      (is (equal '(nil 0 0) (multiple-value-list (da:trova-decisione-recuperata result txid)))))))

(defun darr-success (f version specs &rest options)
  (let* ((size (dar-fixture-size f)) (result (apply #'dar-call f options)))
    (darr-result result size size :complete version)
    (darr-table result specs)
    (darr-events f (darr-requests size (getf options :chunk-bytes 65536) (dar-fixture-short f)))
    (darr-scratch f size) (dar-noeffects f)
    result))

(defun darr-preflight (f type reason options &optional offset)
  "Rifiuto prima di ogni lettura/identità; scratch e capacità invariati."
  (let* ((before (copy-seq (dar-fixture-scratch f)))
         (condition (dar-expect type reason (lambda () (apply #'dar-call f options)))))
    (unless (typep condition 'type-error) (is (eql offset (error-offset condition))))
    (is (equalp before (dar-fixture-scratch f)))
    (darr-events f nil) (dar-noeffects f)))

(defun darr-read-rejection (f type reason options &optional offset)
  (let ((condition (dar-expect type reason (lambda () (apply #'dar-call f options)))))
    (is (eql offset (error-offset condition)))
    (darr-events f (darr-requests (dar-fixture-size f) (getf options :chunk-bytes 65536)
                                 (dar-fixture-short f)))
    (darr-scratch f (dar-fixture-size f)) (dar-noeffects f)
    condition))

(defun darr-repair-header (source)
  (ct::crr-pack source 56 (ct::crr-crc source 0 56) 4)
  source)

(defun darr-header-rejection (source type reason)
  (dar-with-input source
    (lambda (f)
      (dar-expect type reason (lambda () (dar-call f :chunk-bytes 7)) 0)
      (darr-events f '((:read 401 0 64 0)))
      (darr-scratch f 64) (dar-noeffects f))))

(defun darr-closed-noeffects (f expected-events)
  "La revoca esplicita è l'unico effetto ammesso; il lettore non chiude di nuovo."
  (darr-events f expected-events)
  (is (dar-fixture-closed f))
  (is (eq :closed (io:stato-file (dar-fixture-input f))))
  (is (eq :input (io:mode-file (dar-fixture-input f))))
  (is (equalp (dar-fixture-source f) (dar-fixture-reference f)))
  (is (equalp (dar-fixture-identity f) (dar-identity)))
  (is (zerop (io:posizione-scritta (dar-fixture-input f))))
  (is (zerop (io:posizione-durevole (dar-fixture-input f))))
  (is (every (lambda (event) (member (first event) '(:read :close))) expected-events)))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-FOR-002 REQ-AFF-008
(deftest test-REQ-REC-001-ARCHIVE-READ-header-only-and-empty-sealed-batches
  (dolist (version '(1 2))
    (dolist (batches '(nil (nil nil)))
      (dar-with-input (dar-log batches :version version)
        (lambda (f)
          (darr-success f version nil :chunk-bytes 1 :max-bytes (dar-fixture-size f)
                        :max-batches 2 :max-batch-records 1 :max-batch-bytes 56
                        :max-decisions 0 :max-participants 0 :max-participants-per-decision 0))
        :max-transfer 64))))

;;; REQ: REQ-REC-001 REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-ARCHIVE-READ-chunks-shorts-same-fd-and-last-short-chunk
  (dolist (version '(1 2))
    (dolist (chunk '(1 64 65 4096))
      (dolist (short '(1 7 4096))
        (dar-with-input (darr-log version)
          (lambda (f)
            (setf (dar-fixture-scratch f) (ct::crr-bytes (+ 7 (dar-fixture-size f)) #xa5))
            (darr-success f version (darr-specs) :chunk-bytes chunk))
          :short short)))))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-AFF-008
(deftest test-REQ-FOR-001-ARCHIVE-READ-truncated-header-before-io
  (dolist (version '(1 2))
    (dolist (size '(0 1 63))
      (dar-with-input (subseq (dar-log nil :version version) 0 size)
        (lambda (f)
          (darr-preflight f 'corruption-detected :archive-recovery-header-truncated nil 0))))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-ARCHIVE-READ-invalid-options-and-whole-file-byte-budget
  (dolist (version '(1 2))
    (dolist (options '((:chunk-bytes 0) (:max-bytes 0) (:max-bytes 63)
                       (:max-batches 0) (:max-batch-records 0) (:max-batch-bytes 55)))
      (dar-with-input (darr-log version)
        (lambda (f)
          (darr-preflight f 'invalid-argument
                          (if (member (first options) '(:chunk-bytes :max-bytes))
                              :archive-recovery-arguments :log-scan-arguments)
                          options))))
    (dar-with-input (darr-log version)
      (lambda (f)
        (darr-preflight f 'resource-exhausted :archive-recovery-byte-budget
                        (list :max-bytes (1- (dar-fixture-size f))))))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-ARCHIVE-READ-scalar-types-before-io
  ;; I valori contrari agli FTYPE passano come dati tramite APPLY.
  (dolist (version '(1 2))
    (dolist (key '(:chunk-bytes :max-bytes :max-batches :max-batch-records :max-batch-bytes
                   :max-decisions :max-participants :max-participants-per-decision))
      (dolist (value (list -1 (case key
                              (:max-batch-records #x100000000)
                              (:max-participants-per-decision 65536)
                              (otherwise (1+ most-positive-fixnum)))))
        (dar-with-input (dar-log nil :version version)
          (lambda (f) (darr-preflight f 'type-error nil (list key value))))))))

;;; REQ: REQ-AFF-008 REQ-AFF-002
(deftest test-REQ-AFF-008-ARCHIVE-READ-scratch-alias-and-short-range-before-io
  (dolist (version '(1 2))
    (dar-with-input (darr-log version)
      (lambda (f)
        ;; FI locale: le API pubbliche non espongono questo vettore posseduto.
        (setf (dar-fixture-scratch f) (da::archivio-recovery-identity (dar-fixture-archive f)))
        (darr-preflight f 'invalid-argument :archive-recovery-alias nil)
        (setf (dar-fixture-scratch f) (copy-seq (dar-fixture-scratch f)))
        (darr-preflight f 'invalid-argument :buffer-range nil)
        (setf (dar-fixture-scratch f) (ct::crr-bytes (1- (dar-fixture-size f)) #xa5))
        (darr-preflight f 'invalid-argument :buffer-range nil)))))

;;; REQ: REQ-AFF-008 REQ-AFF-002
(deftest test-REQ-AFF-008-ARCHIVE-READ-transfer-capacity-exact-thresholds
  (dolist (version '(1 2))
    ;; Un lotto: corpo 188, header 64. La capacità copre MAX(64, MIN(corpo, chunk)).
    (dolist (entry '((63 1 nil) (64 1 t) (64 64 t) (64 65 nil)
                     (65 65 t) (187 4096 nil) (188 4096 t)))
      (destructuring-bind (capacity chunk success) entry
        (dar-with-input (darr-log version 1)
          (lambda (f)
            (is (= 252 (dar-fixture-size f)))
            (if success (darr-success f version (darr-specs) :chunk-bytes chunk)
                (darr-preflight f 'resource-exhausted :io-byte-budget (list :chunk-bytes chunk))))
          :max-transfer capacity)))))

;;; REQ: REQ-AFF-002 REQ-REC-001
(deftest test-REQ-AFF-002-ARCHIVE-READ-closed-capability-before-preflight
  (dolist (version '(1 2))
    (dar-with-input (darr-log version)
      (lambda (f)
        (io:chiudi (dar-fixture-input f)) (dar-clear f)
        (let* ((before (copy-seq (dar-fixture-scratch f)))
               (condition (dar-expect 'io-fault :io-unavailable (lambda () (dar-call f)))))
          (is (null (error-offset condition)))
          (is (eq :input (arcdocdb.conditions:error-operation condition)))
          (is (zerop (arcdocdb.conditions:error-transferred condition)))
          (is (equalp before (dar-fixture-scratch f))))
        (darr-closed-noeffects f nil)))))

;;; REQ: REQ-AFF-002 REQ-STO-003
(deftest test-REQ-AFF-002-ARCHIVE-READ-rejects-append-and-directory-capabilities
  (dolist (mode '(:append :directory))
    (dar-with-input (dar-log nil)
      (lambda (f)
        (let ((calls nil) (input nil))
          (flet ((forbidden (&rest args) (push args calls) (error "I/O inatteso nel rifiuto del modo")))
            (let ((backend (io:make-backend
                            (lambda (path actual-mode)
                              (is (equal path "/archive-fixture/rejected.tmp"))
                              (is (eq actual-mode mode)) 402)
                            #'forbidden #'forbidden #'forbidden #'forbidden
                            (lambda (fd) (is (= fd 402)) (push :close calls) 0))))
              (unwind-protect
                   (progn
                     (setf input (if (eq mode :append)
                                     (io:crea-temporaneo "/archive-fixture/rejected.tmp" :backend backend)
                                     (io:apri-directory "/archive-fixture/rejected.tmp" :backend backend)))
                     (let ((before (copy-seq (dar-fixture-scratch f))))
                       (dar-expect 'invalid-argument :io-mode
                         (lambda () (da:leggi-decisioni-recuperate
                                      (dar-fixture-archive f) input (dar-fixture-size f)
                                      (dar-fixture-scratch f))))
                       (is (equalp before (dar-fixture-scratch f))))
                     (is (eq :open (io:stato-file input))) (is (eq mode (io:mode-file input)))
                     (is (null calls)) (darr-events f nil) (dar-noeffects f))
                (when input (io:chiudi input))))
            (is (equal '(:close) calls))))))))

;;; REQ: REQ-AFF-002 REQ-REC-001
(deftest test-REQ-AFF-002-ARCHIVE-READ-early-eof-is-not-a-log-tail
  (dolist (version '(1 2))
    (let* ((source (darr-log version)) (size (length source)))
      (dolist (cut (list 0 1 63 64 70 (1- size)))
        (dar-with-input source
          (lambda (f)
            (setf (dar-fixture-hook f)
                  (lambda (fixture fd buffer start count offset)
                    (dar-transfer fixture fd buffer start (min count (max 0 (- cut offset))) offset)))
            (let* ((condition (dar-expect 'io-fault :io-eof (lambda () (dar-call f :chunk-bytes 64))))
                   (base (if (< cut 64) 0 (+ 64 (* 64 (floor (- cut 64) 64))))))
              (is (null (error-offset condition)))
              (is (eq :read (arcdocdb.conditions:error-operation condition)))
              (is (null (arcdocdb.conditions:error-errno condition)))
              (is (= (- cut base) (arcdocdb.conditions:error-transferred condition))))
            (darr-events f (darr-requests size 64 7 cut))
            (darr-scratch f cut) (dar-noeffects f))
          :short 7)))))

;;; REQ: REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-ARCHIVE-READ-backend-errors-and-impossible-progress-no-retry
  (dolist (version '(1 2))
    (dolist (target '(0 64))
      (dolist (failure '(:condition :negative :excess :noninteger))
        (dar-with-input (darr-log version)
          (lambda (f)
            (let ((original (make-condition 'io-fault :reason :archive-test-read-failure
                                                    :operation :read :transferred 3)))
              (setf (dar-fixture-hook f)
                    (lambda (fixture fd buffer start count offset)
                      (if (= offset target)
                          (ecase failure (:condition (error original)) (:negative -1)
                            (:excess (1+ count)) (:noninteger nil))
                          (dar-transfer fixture fd buffer start count offset))))
              (let ((condition (dar-expect 'io-fault
                                 (if (eq failure :condition) :archive-test-read-failure :io-invalid-progress)
                                 (lambda () (dar-call f :chunk-bytes 64)))))
                (if (eq failure :condition) (is (eq original condition))
                    (is (zerop (arcdocdb.conditions:error-transferred condition))))))
            (darr-events f (if (zerop target) '((:read 401 0 64 0))
                              '((:read 401 0 64 0) (:read 401 64 64 64))))
            (darr-scratch f target) (dar-noeffects f)))))))

;;; REQ: REQ-AFF-002 REQ-REC-001
(deftest test-REQ-AFF-002-ARCHIVE-READ-revocation-after-progress-never-returns-result
  (dolist (version '(1 2))
    (dolist (target '(0 64))
      (dar-with-input (darr-log version 1)
        (lambda (f)
          (setf (dar-fixture-hook f)
                (lambda (fixture fd buffer start count offset)
                  (let ((n (dar-transfer fixture fd buffer start count offset)))
                    (when (= target offset) (io:chiudi (dar-fixture-input fixture))) n)))
          (let ((condition (dar-expect 'io-fault :io-unavailable (lambda () (dar-call f)))))
            (is (null (error-offset condition)))
            (is (eq :read (arcdocdb.conditions:error-operation condition)))
            (is (= (if (zerop target) 64 188) (arcdocdb.conditions:error-transferred condition))))
          (darr-scratch f (if (zerop target) 64 (dar-fixture-size f)))
          (darr-closed-noeffects f (if (zerop target) '((:read 401 0 64 0) (:close 401))
                                      '((:read 401 0 64 0) (:read 401 64 188 64) (:close 401)))))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-001-ARCHIVE-READ-header-crc-precedes-fields-and-body
  (dolist (version '(1 2))
    (dolist (pos '(0 4 8 10 16 31 32 55 56 59))
      (let ((source (darr-log version)))
        (setf (aref source pos) (logxor 1 (aref source pos)))
        (darr-header-rejection source 'corruption-detected :log-header-crc)))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-002-ARCHIVE-READ-magic-all-reserved-bytes-and-unknown-version
  (dolist (version '(1 2))
    (dolist (pos '(0 4))
      (let ((source (darr-log version)))
        (setf (aref source pos) (logxor 1 (aref source pos)))
        (darr-header-rejection (darr-repair-header source) 'corruption-detected :log-magic)))
    (dolist (range '((10 16) (32 56) (60 64)))
      (loop for pos from (first range) below (second range) do
        (let ((source (darr-log version)))
          (setf (aref source pos) 1)
          (darr-header-rejection (darr-repair-header source) 'corruption-detected :log-reserved))))
    (dolist (unknown '(0 3 256 65535))
      (let ((source (darr-log version)))
        (ct::crr-pack source 8 unknown 2)
        (darr-header-rejection (darr-repair-header source) 'unsupported-format :file-version)))))

;;; REQ: REQ-FOR-001 REQ-REC-001 REQ-TXM-005
(deftest test-REQ-FOR-001-ARCHIVE-READ-entire-archive-uuid-distinct-from-serie
  (is (not (equalp (dar-identity) (av::av-identity))))
  (dolist (version '(1 2))
    (dotimes (i 16)
      (let ((source (darr-log version)))
        (setf (aref source (+ 16 i)) (logxor #x80 (aref source (+ 16 i))))
        (darr-header-rejection (darr-repair-header source) 'corruption-detected :log-identity)))
    (darr-header-rejection (dar-log (list (darr-specs)) :version version :identity (av::av-identity))
                           'corruption-detected :log-identity)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(deftest test-REQ-TXM-005-ARCHIVE-READ-identical-duplicates-canonical-participants
  (dolist (version '(1 2))
    (let* ((a (first (darr-specs))) (b (second (darr-specs)))
           (duplicate (rt::decision-spec (first a) (second a) (reverse (third a)))))
      (dar-with-input (dar-log (list (list b a duplicate) (list duplicate b)) :version version)
        (lambda (f)
          (darr-success f version (list a b) :max-decisions 5 :max-participants 10
                        :max-participants-per-decision 2))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-009
(deftest test-REQ-TXM-005-ARCHIVE-READ-first-physical-conflict-csn-or-participant
  (dolist (version '(1 2))
    (dolist (change '(:csn :participant))
      (let* ((ids (third (first (darr-specs))))
             (high (rt::decision-spec #xffffffffffffffff 0 ids))
             (low (rt::decision-spec 0 0 ids))
             (bad (rt::decision-spec (first high) (if (eq change :csn) 1 0)
                                     (if (eq change :csn) (reverse ids)
                                         (list (first ids) (rt::participant-id 3 #x80)))))
             (bad-low (rt::decision-spec 0 1 ids)))
        (multiple-value-bind (source layouts)
            (dar-log (list (list high low) (list bad bad-low)) :version version)
          (let ((expected (first (getf (second layouts) :records))))
            (dar-with-input source
              (lambda (f)
                (darr-read-rejection f 'corruption-detected :decision-conflict nil expected)))))))))

;;; REQ: REQ-FOR-003 REQ-TXM-005 REQ-AFF-009
(deftest test-REQ-FOR-003-ARCHIVE-READ-sealed-semantic-errors-never-become-tail
  (dolist (version '(1 2))
    (dolist (entry '((0 :decision-participants 88) (1 :decision-participants 88)
                     (3 :metadata-truncated 98)))
      (destructuring-bind (count reason offset) entry
        (multiple-value-bind (source layouts) (dar-log (list (darr-specs)) :version version)
          (ct::crr-pack source 96 count 2)
          (rt::repair-decision-batch source (first layouts))
          (dar-with-input source
            (lambda (f) (darr-read-rejection f 'corruption-detected reason nil offset))))))
    (let* ((id (rt::participant-id 1)) (spec (rt::decision-spec 17 0 (list id (copy-seq id)))))
      (dar-with-input (dar-log (list (list spec)) :version version)
        (lambda (f)
          (darr-read-rejection f 'corruption-detected :decision-duplicate-participant nil 64))))))

;;; REQ: REQ-AFF-008 REQ-TXM-005 REQ-AFF-009
(deftest test-REQ-AFF-008-ARCHIVE-READ-physical-budgets-before-coalescence
  (dolist (version '(1 2))
    (let ((source (darr-log version)))
      (dar-with-input source
        (lambda (f)
          (darr-success f version (darr-specs) :max-bytes (dar-fixture-size f)
                        :max-batches 2 :max-batch-records 2 :max-batch-bytes 188
                        :max-decisions 4 :max-participants 8 :max-participants-per-decision 2)))
      (dolist (entry '((:max-batches 1 :log-batch-budget 252)
                       (:max-batch-records 1 :batch-record-budget 130)
                       (:max-batch-bytes 187 :batch-byte-budget 196)
                       (:max-decisions 3 :decision-count-budget 64)
                       (:max-decisions 0 :decision-count-budget 64)
                       (:max-participants 7 :decision-participant-budget 318)
                       (:max-participants 0 :decision-participant-budget 64)
                       (:max-participants-per-decision 1 :metadata-budget 88)
                       (:max-participants-per-decision 0 :metadata-budget 88)))
        (destructuring-bind (key budget reason offset) entry
          (dar-with-input source
            (lambda (f) (darr-read-rejection f 'resource-exhausted reason (list key budget) offset))))))))

;;; REQ: REQ-AFF-009 REQ-REC-001 REQ-TXM-005
(deftest test-REQ-AFF-009-ARCHIVE-READ-unsealed-tail-and-conflict-presumed-abort
  (dolist (version '(1 2))
    (multiple-value-bind (source layouts) (dar-log (list (darr-specs) (darr-specs)) :version version)
      (let* ((failed (second layouts)) (prefix (getf failed :start)) (seal (getf failed :seal)))
        (dolist (cut (list (1+ prefix) (+ prefix 23) (+ prefix 24) (+ prefix 65) seal (1- (length source))))
          (dar-with-input (subseq source 0 cut)
            (lambda (f)
              (let ((result (dar-call f :chunk-bytes 64 :max-decisions 2 :max-participants 4)))
                (darr-result result cut prefix :tail version) (darr-table result (darr-specs)))
              (darr-events f (darr-requests cut 64 4096))
              (darr-scratch f cut) (dar-noeffects f))))))
    (let* ((good (first (darr-specs)))
           (bad (rt::decision-spec (first good) 99 (third good)))
           (tail (rt::reference-decision-record bad version))
           (prefix (length (dar-log (list (list good)) :version version))))
      (dar-with-input (dar-log (list (list good)) :version version :tail tail)
        (lambda (f)
          (let ((result (dar-call f :max-decisions 1 :max-participants 2)))
            (darr-result result (dar-fixture-size f) prefix :tail version) (darr-table result (list good)))
          (darr-events f (darr-requests (dar-fixture-size f) 65536 4096))
          (darr-scratch f (dar-fixture-size f)) (dar-noeffects f))))))

;;; REQ: REQ-AFF-009 REQ-REC-001 REQ-TXM-005
(deftest test-REQ-AFF-009-ARCHIVE-READ-witness-search-ignores-corrupt-length-and-exact-boundary
  (dolist (version '(1 2))
    (dolist (delta '(-1 0 1))
      (multiple-value-bind (source layouts)
          (dar-log (list (darr-specs) (darr-specs) (darr-specs)) :version version)
        (let* ((failed (second layouts)) (later (third layouts)) (prefix (getf failed :start))
               (witness (getf later :seal)))
          (ct::crr-pack source (+ prefix 12) #xffffffff 4)
          (ct::crr-pack source prefix (ct::crr-crc source (+ prefix 4) (+ prefix 24)) 4)
          (ct::crr-pack source (+ witness 40) (+ prefix delta) 8)
          (rt::repair-reference-record source witness (getf later :end))
          (dar-with-input source
            (lambda (f)
              (if (plusp delta)
                  (let ((condition (darr-read-rejection f 'arcdocdb.recovery.scan:log-corruption
                                      :log-durable-corruption nil prefix)))
                    (is (= prefix (arcdocdb.recovery.scan:corruption-prefix-end condition)))
                    (is (= witness (arcdocdb.recovery.scan:corruption-witness-offset condition)))
                    (is (= (+ prefix delta) (arcdocdb.recovery.scan:corruption-durable-offset condition)))
                    (is (eq :record-length (arcdocdb.recovery.scan:corruption-first-reason condition))))
                  (let ((result (dar-call f)))
                    (darr-result result (length source) prefix :tail version) (darr-table result (darr-specs))
                    (darr-events f (darr-requests (length source) 65536 4096))
                    (darr-scratch f (length source)) (dar-noeffects f))))))))))

;;; REQ: REQ-AFF-009 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-AFF-009-ARCHIVE-READ-durable-witness-before-semantic-conflict-or-budget
  (dolist (version '(1 2))
    (dolist (body-p '(nil t))
      (let* ((good (first (darr-specs))) (bad (rt::decision-spec (first good) 99 (third good))))
        (multiple-value-bind (source layouts)
            (dar-log (list (list good bad) (darr-specs) (darr-specs)) :version version)
          (let* ((failed (second layouts)) (later (third layouts)) (prefix (getf failed :start))
                 (pos (+ prefix (if body-p 24 0))))
            (setf (aref source pos) (logxor 1 (aref source pos)))
            (dar-with-input source
              (lambda (f)
                (let ((condition (darr-read-rejection f 'arcdocdb.recovery.scan:log-corruption
                                    :log-durable-corruption '(:max-decisions 0) prefix)))
                  (is (= prefix (arcdocdb.recovery.scan:corruption-prefix-end condition)))
                  (is (= (getf later :seal) (arcdocdb.recovery.scan:corruption-witness-offset condition)))
                  (is (= (getf later :start) (arcdocdb.recovery.scan:corruption-durable-offset condition)))
                  (is (eq (if body-p :body-crc :header-crc)
                          (arcdocdb.recovery.scan:corruption-first-reason condition))))))))))))
