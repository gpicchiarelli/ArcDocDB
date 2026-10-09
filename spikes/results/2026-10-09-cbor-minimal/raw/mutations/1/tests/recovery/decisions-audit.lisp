;;;; Seconda lettura C1: ordine fisico dei conflitti dopo il raggruppamento per TXID.
(in-package #:arcdocdb.recovery.tests)

;;; REQ: REQ-TXM-001 REQ-TXM-005 REQ-AFF-009 REQ-AFF-017
(deftest test-REQ-TXM-005-first-physical-decision-conflict-across-txid-groups
  (let* ((maximum (1- (ash 1 64)))
         (file-offset (ash 1 63))
         (a (participant-id 0))
         (b (participant-id maximum #x80))
         (c (participant-id 1 #xff))
         (d (participant-id 2 #xff)))
    (dolist (version '(1 2))
      (dolist (txids (list (list maximum 0) (list 0 maximum)))
        (destructuring-bind (first-txid second-txid) txids
          (let ((specs (list (decision-spec first-txid 0 (list a b c))
                             (decision-spec second-txid 0 (list c a b))
                             (decision-spec first-txid 0 (list b c a))
                             (decision-spec first-txid maximum (list c b a))
                             (decision-spec second-txid 0 (list b a c))
                             (decision-spec second-txid 0 (list a b d)))))
            (dolist (split '(nil t))
              (let ((batches (if split
                                 (list (subseq specs 0 2) (subseq specs 2 4)
                                       (subseq specs 4 6))
                                 (list specs))))
                (multiple-value-bind (buffer start end layouts)
                    (decision-log-fixture batches :version version :file-offset file-offset)
                  (let* ((before (copy-seq buffer))
                         (record-starts (mapcan (lambda (layout)
                                                 (copy-list (getf layout :records)))
                                               layouts))
                         (expected (+ file-offset (fourth record-starts))))
                    ;; La prima discordanza fisica è nel quarto record, anche se
                    ;; il gruppo TXID numericamente minore viene visitato per primo.
                    (loop repeat 2 do
                      (let ((condition
                              (signals corruption-detected
                                (arcdocdb.recovery.decisions:ricostruisci-decisioni
                                  buffer start end :version version :file-offset file-offset
                                  :file-size (+ file-offset end) :max-decisions 6
                                  :max-participants 18 :max-participants-per-decision 3)
                                :decision-conflict)))
                        (is (= expected (error-offset condition)))
                        (is (equalp before buffer))))))))))))))

;;; REQ: REQ-TXM-001 REQ-TXM-005 REQ-AFF-017
(deftest test-REQ-TXM-001-participant-every-byte-and-every-bit
  (let* ((base (make-array 16 :element-type '(unsigned-byte 8) :initial-element #x80))
         (ids (cons base
                    (loop for byte below 16 append
                      (loop for value in '(#x7f #xff) collect
                        (let ((id (copy-seq base))) (setf (aref id byte) value) id)))))
         (spec (decision-spec 31 0 (permute-decisions ids 193))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end) (decision-log-fixture (list (list spec))
                                                                  :version version)
        (multiple-value-bind (table prefix status)
            (decision-fixture-read buffer start end :version version)
          (is (= end prefix)) (is (eq :complete status))
          (assert-decision-table table (list spec))
          ;; Tutti i 128 bit cambiano l'identità, anche nei byte centrali
          ;; non rappresentati dal prefisso/numero di PARTICIPANT-ID.
          (dotimes (byte 16)
            (dotimes (bit 8)
              (let ((query (copy-seq base)))
                (setf (aref query byte) (logxor (aref query byte) (ash 1 bit)))
                (is (not (member query ids :test #'equalp)))
                (is (not (arcdocdb.recovery.decisions:partecipante-decisione-p
                           table 31 query 0 16))))))
          (fill buffer 0)
          (assert-decision-table table (list spec)))))))

;;; REQ: REQ-FOR-003 REQ-TXM-005 REQ-AFF-017
(deftest test-REQ-FOR-003-sealed-trailing-decision-payload
  (dolist (version '(1 2))
    (dolist (size '(43 59 75))
      (let ((body (make-array size :element-type '(unsigned-byte 8) :initial-element 0)))
        ;; 43 = CSN(8) + count(2) + due ID16(32) + un byte residuo.
        (reference-le body 8 2 2)
        (multiple-value-bind (buffer start end)
            (decision-record-log-fixture
             (list (list (reference-record 6 0 (bytes) body :version version)))
             :version version)
          (let* ((before (copy-seq buffer))
                 (condition (signals corruption-detected
                              (decision-fixture-read buffer start end :version version)
                              :decision-trailing-data)))
            (is (not (typep condition 'log-corruption)))
            (is (= (+ start 34) (error-offset condition)))
            (is (equalp before buffer))))))))

;;; REQ: REQ-FOR-003 REQ-TXM-005 REQ-AFF-009 REQ-AFF-017
(deftest test-REQ-FOR-003-short-decision-frame-requires-covering-witness
  (dolist (version '(1 2))
    (dolist (size '(0 1 7 8 9 25))
      (let ((body (make-array size :element-type '(unsigned-byte 8) :initial-element 0)))
        (multiple-value-bind (buffer start end layouts)
            (decision-record-log-fixture
             (list (list (reference-record 6 0 (bytes) body :version version)) nil)
             :version version :durables '(71 72))
          (let ((before (copy-seq buffer)))
            ;; La cornice impone già 26 byte minimi per DECISION: un payload
            ;; più corto non entra nel prefisso, prima del codec semantico.
            (multiple-value-bind (table prefix status)
                (decision-fixture-read buffer start (getf (first layouts) :end)
                   :version version :max-decisions 0 :max-participants 0
                   :max-participants-per-decision 0)
              (is (= start prefix)) (is (eq :tail status))
              (assert-decision-table table nil '(0 1)))
            (let ((condition (signals log-corruption
                               (decision-fixture-read buffer start end :version version
                                  :max-decisions 0 :max-participants 0
                                  :max-participants-per-decision 0)
                               :log-durable-corruption)))
              (is (= start (corruption-prefix-end condition)))
              (is (= (+ 64 start) (error-offset condition)))
              (is (= (+ 64 (getf (second layouts) :seal))
                     (corruption-witness-offset condition)))
              (is (= 72 (corruption-durable-offset condition)))
              (is (eq :decision-length (corruption-first-reason condition))))
            (is (equalp before buffer))))))))

;;; REQ: REQ-TXM-005 REQ-FOR-003 REQ-AFF-009 REQ-AFF-017
(deftest test-REQ-TXM-005-unsealed-semantic-errors-and-covering-witness
  (dolist (version '(1 2))
    (dolist (bad-parts (list (list (participant-id 8))
                            (list (participant-id 8) (participant-id 8))))
      (let* ((good (decision-spec 0 0 (list (participant-id 1) (participant-id 2))))
             (bad (decision-spec 0 1 bad-parts))
             (later (decision-spec 17 1 (list (participant-id 3) (participant-id 4)))))
        (multiple-value-bind (buffer start end layouts)
            (decision-log-fixture (list (list good) (list bad) (list later)) :version version)
          (let* ((failed (second layouts)) (p (getf failed :start))
                 (cut (getf failed :seal)) (before (copy-seq buffer)))
            ;; Una DECISION completa ma non sigillata non sostituisce quella
            ;; del prefisso e non consuma i suoi budget semantici.
            (multiple-value-bind (table prefix status)
                (decision-fixture-read buffer start cut :version version
                   :max-decisions 1 :max-participants 2 :max-participants-per-decision 2)
              (is (= p prefix)) (is (eq :tail status))
              (assert-decision-table table (list good) '(17)))
            (is (equalp before buffer))
            (setf (aref buffer cut) (logxor 1 (aref buffer cut)))
            (set-durable buffer (third layouts) (+ 64 p 1))
            (setf before (copy-seq buffer))
            (let ((condition (signals log-corruption
                               (decision-fixture-read buffer start end :version version
                                                      :max-decisions 0)
                               :log-durable-corruption)))
              (is (= p (corruption-prefix-end condition)))
              (is (= (+ 64 p) (error-offset condition)))
              (is (= (+ 64 (getf (third layouts) :seal))
                     (corruption-witness-offset condition)))
              (is (= (+ 64 p 1) (corruption-durable-offset condition)))
              (is (eq :header-crc (corruption-first-reason condition)))
              (is (equalp before buffer)))))))))

;;; REQ: REQ-AFF-008 REQ-TXM-005 REQ-TXM-001
(deftest test-REQ-AFF-008-decision-budget-offsets-before-coalescence
  (let* ((file-offset (ash 1 63))
         (spec (decision-spec 0 0 (list (participant-id 1) (participant-id 2)))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end layouts)
          (decision-log-fixture (list (list spec) (list spec spec))
                                :version version :file-offset file-offset)
        (let ((before (copy-seq buffer)))
          (let ((condition (signals resource-exhausted
                             (decision-fixture-read buffer start end :version version
                                :file-offset file-offset :max-decisions 2)
                             :decision-count-budget)))
            (is (= (+ file-offset start) (error-offset condition))))
          (let ((condition (signals resource-exhausted
                             (decision-fixture-read buffer start end :version version
                                :file-offset file-offset :max-participants 5)
                             :decision-participant-budget)))
            (is (= (+ file-offset (second (getf (second layouts) :records)))
                   (error-offset condition))))
          (let ((condition (signals resource-exhausted
                             (decision-fixture-read buffer start end :version version
                                :file-offset file-offset :max-participants-per-decision 1)
                             :metadata-budget)))
            ;; Gli errori del codec conservano offset relativi al buffer.
            (is (= (+ start 24) (error-offset condition))))
          (is (equalp before buffer)))))))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-FOR-003 REQ-AFF-008 REQ-AFF-017
(deftest test-REQ-TXM-005-public-default-budgets-and-explicit-version
  (let* ((a (decision-spec 0 0 (list (participant-id 1) (participant-id 2))))
         (b (decision-spec #xffffffffffffffff #xffffffffffffffff
                           (list (participant-id 3 #x80) (participant-id 4 #xff))))
         (duplicate (decision-spec 0 0 (reverse (third a)))))
    (dolist (version '(1 2))
      (dolist (file-offset (list 0 (ash 1 32)))
        (multiple-value-bind (buffer start end)
            (decision-log-fixture (list (list b a) (list duplicate))
                                  :version version :file-offset file-offset)
          (let ((before (copy-seq buffer)))
            ;; La variante zero omette davvero FILE-OFFSET, oltre ai budget.
            (multiple-value-bind (table prefix status)
                (if (zerop file-offset)
                    (arcdocdb.recovery.decisions:ricostruisci-decisioni
                      buffer start end :version version :file-size end)
                    (arcdocdb.recovery.decisions:ricostruisci-decisioni
                      buffer start end :version version :file-offset file-offset
                      :file-size (+ file-offset end)))
              (is (= end prefix)) (is (eq :complete status))
              (assert-decision-table table (list a b) '(1 17)))
            (is (equalp before buffer))
            (signals unsupported-format
                     (arcdocdb.recovery.decisions:ricostruisci-decisioni
                       buffer start end :file-offset file-offset
                       :file-size (+ file-offset end))
                     :record-version)
            (is (equalp before buffer))))))))

;;; REQ: REQ-TXM-001 REQ-TXM-005 REQ-FOR-003 REQ-AFF-008 REQ-AFF-017
(deftest test-REQ-TXM-001-maximum-u16-participant-count
  (let* ((count 65535)
         (spec (decision-spec #xffffffffffffffff 0
                              (loop for i downfrom (1- count) to 0 collect (participant-id i)))))
    (dolist (version '(1 2))
      (multiple-value-bind (buffer start end)
          (decision-log-fixture (list (list spec)) :version version)
        (let ((before (copy-seq buffer)))
          (multiple-value-bind (table prefix status)
              (decision-fixture-read buffer start end :version version :max-decisions 1
                 :max-participants count :max-participants-per-decision count)
            (is (= end prefix)) (is (eq :complete status))
            (is (= 1 (arcdocdb.recovery.decisions:numero-decisioni table)))
            (is (equal (list t 0 count)
                       (multiple-value-list
                         (arcdocdb.recovery.decisions:trova-decisione
                           table #xffffffffffffffff))))
            ;; L'oracolo è l'intervallo dichiarato, senza REMOVE-DUPLICATES
            ;; quadratico sulla lista di 65.535 partecipanti.
            (dolist (number '(0 1 32767 65533 65534))
              (is (arcdocdb.recovery.decisions:partecipante-decisione-p
                     table #xffffffffffffffff (participant-id number) 0 16)))
            (dolist (number '(65535 18446744073709551615))
              (is (not (arcdocdb.recovery.decisions:partecipante-decisione-p
                          table #xffffffffffffffff (participant-id number) 0 16)))))
          (let ((condition (signals resource-exhausted
                             (decision-fixture-read buffer start end :version version
                                                    :max-participants (1- count))
                             :decision-participant-budget)))
            (is (= (+ 64 start) (error-offset condition))))
          (let ((condition (signals resource-exhausted
                             (decision-fixture-read buffer start end :version version
                                       :max-participants-per-decision (1- count))
                             :metadata-budget)))
            (is (= (+ start 24) (error-offset condition))))
          (is (equalp before buffer)))))))
