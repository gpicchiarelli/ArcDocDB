;;;; Lettura pubblica ACTIVE: matrici finite v1/v2, nessuna esecuzione durante la stesura.
;;; OWNER: runner seriale, fixture privata; capacità mantenute fino al cleanup del supporto.
;;; SHARED: FI su FDEFINITION solo seriali, NO CONCURRENT, ripristinate con UNWIND-PROTECT.
;;; Oracoli: byte/CRC del supporto indipendenti; ogni richiesta pread e identità è confrontata.
;;; Limiti: file <=4096 byte, eventi <=16384, cicli su matrici finite o byte della fixture.
;;; ARV-D01/D02: soglie, singoli rifiuti e assenza di I/O prima dell'header.
;;; ARV-D03/D06/D11: esiti pubblici reali; guardie difensive con FI esplicite outside-contract.
;;; Nessun wrapper, buffer di prodotto o FD viene costruito/modificato privatamente.
;;; Semantica TXID e serializer sono qualificati dalle suite dedicate.
;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-002 REQ-FOR-003 REQ-AFF-002 REQ-AFF-008 REQ-AFF-009
(in-package #:arcdocdb.recovery.active.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun avr-specs ()
  "Due record ordinari con stamp del SEAL: nessuna risoluzione TXID in questi casi."
  (list (list :put 17 nil (av-bytes 1 7) (av-bytes 2 8))
        (list :tombstone 17 nil (av-bytes 1 9))))

(defun avr-log (version &optional (batches 2))
  (av-log (loop repeat batches collect (avr-specs)) :version version))

(defun avr-requests (size chunk short &optional (physical-size size))
  "Due identità, header separato, poi chunk: richieste residue esatte, incluso EOF prematuro."
  (is (<= 64 size 4096)) (is (plusp chunk)) (is (plusp short))
  (is (<= 0 physical-size size))
  (let ((events (list (list :identity 301) (list :identity 302))))
    (dolist (range (cons '(0 64)
                        (loop for base from 64 below size by chunk
                              collect (list base (min size (+ base chunk))))))
      (destructuring-bind (base end) range
        (let ((pos base))
          (loop repeat (- end base) until (= pos end) do
            (push (list :read 302 pos (- end pos) pos) events)
            (let ((n (min (- end pos) short (max 0 (- physical-size pos)))))
              (when (zerop n) (return-from avr-requests (nreverse events)))
              (incf pos n))))))
    (nreverse events)))

(defun avr-events (f expected)
  (is (equal expected (av-events f)))
  (is (= (count :read expected :key #'first) (av-fixture-reads f)))
  (is (notany #'identity (av-fixture-closed f))))

(defun avr-scratch (f copied)
  "Separa byte trasferiti e sentinelle, inclusi eventuali byte oltre EOF nello scratch."
  (let ((scratch (av-fixture-scratch f)))
    (is (equalp (subseq scratch 0 copied) (subseq (av-fixture-source f) 0 copied)))
    (is (every (lambda (byte) (= byte #xa5)) (subseq scratch copied)))))

(defun avr-query (result size prefix status version batches records)
  (is (typep result 'ar:active-recuperato))
  (is (equal (list size prefix status version)
             (multiple-value-list (ar:frontiere-active-recuperato result))))
  (is (equal (list batches records 0 0 0 0)
             (multiple-value-list (ar:statistiche-active-recuperato result))))
  (is (typep (ar:segmento-active-recuperato result) 'arcdocdb.get:segmento-get))
  (is (eq (ar:segmento-active-recuperato result) (ar:segmento-active-recuperato result))))

(defun avr-success (f version batches records &rest options)
  (let* ((size (av-fixture-size f)) (result (apply #'av-call f options)))
    (avr-query result size size :complete version batches records)
    (avr-events f (avr-requests size (getf options :chunk-bytes 65536) (av-fixture-short f)))
    (avr-scratch f size) (av-noeffects f)
    result))

(defun avr-preflight (f type reason options &optional offset)
  "Rifiuto senza osservazioni d'identità, letture, mutazioni o perdita di capacità."
  (let* ((before (copy-seq (av-fixture-scratch f)))
         (condition (av-expect type reason (lambda () (apply #'av-call f options)))))
    (unless (typep condition 'type-error) (is (eql offset (error-offset condition))))
    (is (equalp before (av-fixture-scratch f)))
    (avr-events f nil) (av-noeffects f)))

(defun avr-read-rejection (f type reason options &optional offset)
  (let ((condition (av-expect type reason (lambda () (apply #'av-call f options)))))
    (is (eql offset (error-offset condition)))
    (avr-events f (avr-requests (av-fixture-size f) (getf options :chunk-bytes 65536)
                                (av-fixture-short f)))
    (avr-scratch f (av-fixture-size f)) (av-noeffects f)
    condition))

(defun avr-header-rejection (source version type reason &optional offset)
  (av-with-fixture source
    (lambda (f)
      (let ((condition (av-expect type reason (lambda () (av-call f :chunk-bytes 7)))))
        (is (eql offset (error-offset condition))))
      (avr-events f '((:identity 302) (:identity 301) (:read 302 0 64 0)))
      (avr-scratch f 64) (av-noeffects f))
    :version version))

(defun avr-repair-header (source)
  (ct::crr-pack source 56 (ct::crr-crc source 0 56) 4)
  source)

(defun avr-closed-effects (f closed-fd)
  "FI di revoca: ammessi soltanto stato CLOSED ed evento CLOSE esplicito."
  (is (equalp (av-fixture-source f) (av-fixture-reference f)))
  (is (equalp (av-fixture-identity f) (av-identity)))
  (is (equalp (arcdocdb.get::vista-get-serie-identity (av-fixture-view f)) (av-identity)))
  (loop for input in (list (av-fixture-control-input f) (av-fixture-input f))
        for fd from 301 do
    (is (eq :input (io:mode-file input)))
    (is (eq (if (= fd closed-fd) :closed :open) (io:stato-file input)))
    (is (eql (= fd closed-fd) (aref (av-fixture-closed f) (- fd 301))))
    (is (zerop (io:posizione-scritta input))) (is (zerop (io:posizione-durevole input))))
  (is (notany (lambda (event) (member (first event) '(:write :flush :directory-flush :rename)))
              (av-events f))))

;;; REQ: REQ-REC-001 REQ-FOR-002 REQ-AFF-008
(deftest test-REQ-REC-001-ACTIVE-READ-ARV-D01-D06-D11-header-only
  (dolist (version '(1 2))
    (dolist (id '(9 #x100000009 #xffffffffffffffff))
      ;; NEXT deve restare rappresentabile nella fixture CONTROL.
      (unless (= id #xffffffffffffffff)
        (av-with-fixture (av-log nil :version version :active-id id)
          (lambda (f)
            (avr-success f version 0 0 :chunk-bytes 1 :max-bytes 64 :max-batches 1
                         :max-batch-records 1 :max-batch-bytes 56 :max-records 0
                         :max-prepared 0 :max-outcomes 0))
          :version version :active-id id :max-transfer 64)))))

;;; REQ: REQ-REC-001 REQ-FOR-002 REQ-AFF-002
(deftest test-REQ-REC-001-ACTIVE-READ-exact-chunks-shorts-no-header-reread
  (dolist (version '(1 2))
    (dolist (chunk '(1 31 64 65 4096))
      (dolist (short '(1 7 4096))
        (av-with-fixture (avr-log version)
          (lambda (f)
            (setf (av-fixture-scratch f) (av-bytes (+ 7 (av-fixture-size f)) #xa5))
            (avr-success f version 2 4 :chunk-bytes chunk :max-prepared 0 :max-outcomes 0))
          :version version :short short)))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-READ-ARV-D01-truncated-header-preflight
  (dolist (version '(1 2))
    (dolist (size '(0 1 63))
      (av-with-fixture (subseq (av-log nil :version version) 0 size)
        (lambda (f)
          (avr-preflight f 'corruption-detected :active-recovery-header-truncated nil 0))
        :version version))))

;;; REQ: REQ-REC-001 REQ-AFF-002
(deftest test-REQ-AFF-002-ACTIVE-READ-early-physical-eof-header-and-body
  (dolist (version '(1 2))
    (let* ((source (avr-log version)) (size (length source)))
      (dolist (cut (list 0 1 63 64 70 (1- size)))
        (av-with-fixture source
          (lambda (f)
            (setf (av-fixture-hook f)
                  (lambda (fixture fd buffer start count offset)
                    (av-transfer fixture fd buffer start (min count (max 0 (- cut offset))) offset)))
            (let* ((condition (av-expect 'io-fault :io-eof (lambda () (av-call f :chunk-bytes 31))))
                   (base (if (< cut 64) 0 (+ 64 (* 31 (floor (- cut 64) 31))))))
              (is (null (error-offset condition)))
              (is (eq :read (arcdocdb.conditions:error-operation condition)))
              (is (null (arcdocdb.conditions:error-errno condition)))
              (is (= (- cut base) (arcdocdb.conditions:error-transferred condition))))
            (avr-events f (avr-requests size 31 7 cut))
            (avr-scratch f cut) (av-noeffects f))
          :version version :short 7)))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-READ-ARV-D01-invalid-chunk-and-header-budget
  (dolist (version '(1 2))
    (dolist (options '((:chunk-bytes 0) (:max-bytes 63) (:chunk-bytes 0 :max-bytes 63)))
      (av-with-fixture (avr-log version)
        (lambda (f) (avr-preflight f 'invalid-argument :active-recovery-arguments options))
        :version version))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-READ-ARV-D02-caller-and-format-byte-limits
  (dolist (version '(1 2))
    (av-with-fixture (avr-log version)
      (lambda (f)
        (avr-preflight f 'resource-exhausted :active-recovery-byte-budget
                       (list :max-bytes (1- (av-fixture-size f))))
        (avr-success f version 2 4 :max-bytes (av-fixture-size f)))
      :version version)
    (av-with-fixture (av-log nil :version version)
      (lambda (f)
        ;; EOF attestato sintetico: rifiuto prima del range, senza buffer da 4 GiB.
        (setf (av-fixture-size f) #x100000000)
        (avr-preflight f 'resource-exhausted :active-recovery-byte-budget
                       '(:max-bytes #x100000000)))
      :version version)))

;;; REQ: REQ-AFF-008 REQ-AFF-002
(deftest test-REQ-AFF-008-ACTIVE-READ-scratch-alias-before-range-and-one-byte-short
  (dolist (version '(1 2))
    (av-with-fixture (avr-log version)
      (lambda (f)
        (setf (av-fixture-scratch f) (arcdocdb.get::vista-get-serie-identity (av-fixture-view f)))
        (avr-preflight f 'invalid-argument :active-recovery-alias nil)
        (setf (av-fixture-scratch f) (copy-seq (av-fixture-scratch f)))
        (avr-preflight f 'invalid-argument :buffer-range nil)
        (setf (av-fixture-scratch f) (av-bytes (1- (av-fixture-size f)) #xa5))
        (avr-preflight f 'invalid-argument :buffer-range nil))
      :version version)))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-READ-header-and-body-transfer-capacity
  (dolist (version '(1 2))
    (dolist (entry '((1 63 nil) (65 64 nil) (65 65 t) (4096 209 t) (4096 208 nil)))
      (destructuring-bind (chunk capacity success) entry
        ;; 24+1+128 PUT, 56 SEAL = 209 byte di corpo.
        (let ((source (av-log (list (list (list :put 17 nil (av-bytes 1) (av-bytes 128))))
                              :version version)))
          (is (= 273 (length source)))
          (av-with-fixture source
            (lambda (f)
              (if success (avr-success f version 1 1 :chunk-bytes chunk)
                  (avr-preflight f 'resource-exhausted :io-byte-budget (list :chunk-bytes chunk))))
            :version version :max-transfer capacity))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-READ-invalid-scanner-budgets-before-identity
  (dolist (version '(1 2))
    (dolist (options '((:max-batches 0) (:max-batch-records 0) (:max-batch-bytes 55)))
      (av-with-fixture (avr-log version)
        (lambda (f) (avr-preflight f 'invalid-argument :log-scan-arguments options))
        :version version))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-READ-out-of-type-budgets-before-identity
  ;; APPLY passa i valori come dati, senza chiamate costanti contrarie al FTYPE.
  (dolist (version '(1 2))
    (dolist (key '(:chunk-bytes :max-bytes :max-batches :max-batch-records :max-batch-bytes
                   :max-records :max-prepared :max-outcomes))
      (dolist (value (list -1 (if (member key '(:max-batch-records :max-prepared :max-outcomes))
                                #x100000000 (1+ most-positive-fixnum))))
        (av-with-fixture (avr-log version)
          (lambda (f) (avr-preflight f 'type-error nil (list key value)))
          :version version)))))

;;; REQ: REQ-AFF-008 REQ-REC-001
(deftest test-REQ-AFF-008-ACTIVE-READ-exact-scanner-budgets-never-become-tail
  (dolist (version '(1 2))
    ;; Due record da 27/25 byte, lotto da 108 byte, secondo lotto a 172.
    (let ((source (avr-log version)))
      (is (= 280 (length source)))
      (av-with-fixture source
        (lambda (f)
          (avr-success f version 2 4 :max-batches 2 :max-batch-records 2
                       :max-batch-bytes 108 :max-records 4))
        :version version)
      (dolist (entry '((:max-batches 1 :log-batch-budget 172)
                       (:max-batch-records 1 :batch-record-budget 91)
                       (:max-batch-bytes 107 :batch-byte-budget 116)
                       (:max-records 3 :active-recovery-record-budget nil)
                       (:max-records 0 :active-recovery-record-budget nil)))
        (destructuring-bind (key budget reason offset) entry
          (av-with-fixture source
            (lambda (f) (avr-read-rejection f 'resource-exhausted reason (list key budget) offset))
            :version version))))))

;;; REQ: REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-ACTIVE-READ-backend-mismatch-before-identity
  (dolist (version '(1 2))
    (av-with-fixture (avr-log version)
      (lambda (f)
        (av-with-fixture (avr-log version)
          (lambda (other)
            (let ((before (copy-seq (av-fixture-scratch f))))
              (av-expect 'invalid-argument :active-recovery-backend
                (lambda ()
                  (ar:leggi-active-recuperato (av-fixture-control f) (av-fixture-input other)
                    (av-fixture-size f) (av-fixture-decisions f) (av-fixture-scratch f))))
              (is (equalp before (av-fixture-scratch f))))
            (avr-events f nil) (avr-events other nil)
            (av-noeffects f) (av-noeffects other))
          :version version))
      :version version)))

;;; REQ: REQ-AFF-002 REQ-FOR-001
(deftest test-REQ-AFF-002-ACTIVE-READ-ARV-D02-physical-alias-and-full-identities
  (dolist (version '(1 2))
    (dolist (pair '((1 99) (#x100000001 302) (1 #x10000012e) (1 302)))
      (destructuring-bind (device inode) pair
        (av-with-fixture (avr-log version)
          (lambda (f)
            ;; ACTIVE=(1,302); CONTROL varia un componente per volta, inclusi bit alti.
            (setf (av-fixture-identity-hook f)
                  (lambda (fixture fd)
                    (is (eq fixture f))
                    (if (= fd 302) (values 1 302) (values device inode))))
            (if (and (= device 1) (= inode 302))
                (let ((before (copy-seq (av-fixture-scratch f))))
                  (av-expect 'invalid-argument :io-file-alias (lambda () (av-call f)))
                  (avr-events f '((:identity 302) (:identity 301)))
                  (is (equalp before (av-fixture-scratch f))) (av-noeffects f))
                (avr-success f version 2 4)))
          :version version)))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-001-ACTIVE-READ-header-crc-before-other-fields-and-body
  (dolist (version '(1 2))
    (dolist (pos '(0 8 10 16 32 48 56))
      (let ((source (avr-log version)))
        (setf (aref source pos) (logxor 1 (aref source pos)))
        (avr-header-rejection source version 'corruption-detected :segment-header-crc 0)))))

;;; REQ: REQ-FOR-001 REQ-FOR-002
(deftest test-REQ-FOR-001-ACTIVE-READ-entire-uuid-and-u64-id-before-body
  (dolist (version '(1 2))
    (dolist (range '((16 32) (32 40)))
      (loop for pos from (first range) below (second range) do
        (let ((source (avr-log version)))
          (setf (aref source pos) (logxor 1 (aref source pos)))
          (avr-header-rejection (avr-repair-header source) version 'corruption-detected :segment-identity 0))))))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-REC-001
(deftest test-REQ-FOR-002-ACTIVE-READ-magic-reserved-version-origin-before-body
  (dolist (version '(1 2))
    (dolist (entry '((0 0 :segment-magic) (4 0 :segment-magic)
                     (11 1 :segment-reserved) (15 1 :segment-reserved)
                     (48 1 :segment-reserved) (55 1 :segment-reserved)
                     (60 1 :segment-reserved) (63 1 :segment-reserved)
                     (10 0 :segment-origin) (10 3 :segment-origin)
                     (10 2 :active-recovery-origin)))
      (destructuring-bind (pos value reason) entry
        (let ((source (avr-log version)))
          (setf (aref source pos) value)
          (avr-header-rejection (avr-repair-header source) version 'corruption-detected reason
                                (unless (eq reason :active-recovery-origin) 0)))))
    (dolist (unknown '(0 3 256 65535))
      (let ((source (avr-log version)))
        (ct::crr-pack source 8 unknown 2)
        (avr-header-rejection (avr-repair-header source) version 'unsupported-format :file-version 0)))))

;;; REQ: REQ-REC-001 REQ-AFF-009
(deftest test-REQ-AFF-009-ACTIVE-READ-ARV-D06-D11-unsealed-tail-boundaries
  (dolist (version '(1 2))
    (let* ((source (avr-log version)) (prefix 172))
      (dolist (cut '(173 195 196 199 224 225 279))
        (av-with-fixture (subseq source 0 cut)
          (lambda (f)
            (let ((result (av-call f :chunk-bytes 31)))
              (avr-query result cut prefix :tail version 1 2))
            (avr-events f (avr-requests cut 31 4096))
            (avr-scratch f cut) (av-noeffects f))
          :version version))
      ;; Record completi ma senza SEAL: conflitto semantico nella coda non visitabile.
      (let ((tail (av-cat (av-record '(:outcome 99 1) version) (av-record '(:outcome 99 2) version))))
        (av-with-fixture (av-cat (subseq source 0 prefix) tail)
          (lambda (f)
            (let ((result (av-call f :max-records 2 :max-outcomes 0)))
              (avr-query result (av-fixture-size f) prefix :tail version 1 2))
            (avr-events f (avr-requests (av-fixture-size f) 65536 4096))
            (avr-scratch f (av-fixture-size f)) (av-noeffects f))
          :version version)))))

;;; REQ: REQ-REC-001 REQ-AFF-009 REQ-AFF-002
(deftest test-REQ-AFF-009-ACTIVE-READ-durable-witness-precedes-semantic-conflict
  (dolist (version '(1 2))
    (dolist (body-p '(nil t))
      (let* ((source (av-log (list (list '(:outcome 99 1) '(:outcome 99 2))
                                  (avr-specs) (avr-specs)) :version version))
             (prefix 184) (witness (- (length source) 56)))
        ;; Prefisso strutturalmente valido ma semanticamente contraddittorio.
        ;; Il lotto successivo fallisce CRC; il terzo SEAL attesta D=292>P=184.
        (let ((pos (+ prefix (if body-p 24 0))))
          (setf (aref source pos) (logxor 1 (aref source pos))))
        (av-with-fixture source
          (lambda (f)
            (let ((condition (avr-read-rejection f 'arcdocdb.recovery.scan:log-corruption
                                :log-durable-corruption '(:max-records 0) prefix)))
              (is (= prefix (arcdocdb.recovery.scan:corruption-prefix-end condition)))
              (is (= witness (arcdocdb.recovery.scan:corruption-witness-offset condition)))
              (is (= 292 (arcdocdb.recovery.scan:corruption-durable-offset condition)))
              (is (eq (if body-p :body-crc :header-crc)
                      (arcdocdb.recovery.scan:corruption-first-reason condition)))))
          :version version)))))

;;; REQ: REQ-AFF-009 REQ-REC-001
(deftest test-REQ-AFF-009-ACTIVE-READ-witness-search-and-exact-durable-boundary
  (dolist (version '(1 2))
    (dolist (delta '(-1 0 1))
      (let* ((first (avr-log version 1)) (prefix (length first))
             (second (av-batch (mapcar (lambda (spec) (av-record spec version)) (avr-specs))
                               prefix 9 version))
             (third-start (+ prefix (length second)))
             (third (av-batch (mapcar (lambda (spec) (av-record spec version)) (avr-specs))
                              third-start 9 version (+ prefix delta)))
             (source (av-cat first second third)))
        ;; Lunghezza corrotta con CRC header riparato: la ricerca non deve saltare il testimone.
        (ct::crr-pack source (+ prefix 12) #xffffffff 4)
        (ct::crr-pack source prefix (ct::crr-crc source (+ prefix 4) (+ prefix 24)) 4)
        (av-with-fixture source
          (lambda (f)
            (if (plusp delta)
                (let ((condition (avr-read-rejection f 'arcdocdb.recovery.scan:log-corruption
                                    :log-durable-corruption nil prefix)))
                  (is (= (+ third-start 52) (arcdocdb.recovery.scan:corruption-witness-offset condition)))
                  (is (= (1+ prefix) (arcdocdb.recovery.scan:corruption-durable-offset condition)))
                  (is (eq :record-length (arcdocdb.recovery.scan:corruption-first-reason condition))))
                (let ((result (av-call f)))
                  (avr-query result (length source) prefix :tail version 1 2)
                  (avr-events f (avr-requests (length source) 65536 4096))
                  (avr-scratch f (length source)) (av-noeffects f))))
          :version version)))))

;;; REQ: REQ-AFF-002 REQ-REC-001
(deftest test-REQ-AFF-002-ACTIVE-READ-either-capability-closed-before-preflight
  (dolist (version '(1 2))
    (dolist (fd '(301 302))
      (av-with-fixture (avr-log version)
        (lambda (f)
          (io:chiudi (if (= fd 301) (av-fixture-control-input f) (av-fixture-input f)))
          (av-clear f)
          (let ((before (copy-seq (av-fixture-scratch f)))
                (condition (av-expect 'io-fault :io-unavailable (lambda () (av-call f)))))
            (is (null (error-offset condition)))
            (is (eq :input (arcdocdb.conditions:error-operation condition)))
            (is (zerop (arcdocdb.conditions:error-transferred condition)))
            (is (equalp before (av-fixture-scratch f))))
          (is (null (av-events f))) (avr-closed-effects f fd))
        :version version))))
