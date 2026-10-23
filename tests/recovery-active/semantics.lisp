;;;; Semantica del vecchio ACTIVE: ARV-D04,D05,D07,D08,D09,D10,D12.
;;; OWNER: runner seriale; fixture, capacità readonly e risultati restano vivi fino al cleanup.
;;; SHARED: solo le FI dichiarate sostituiscono funzioni di prodotto; NO CONCURRENT.
;;; METODO: esiti ordinari soltanto da AV-CALL/API pubbliche; oracoli bytewise indipendenti.
;;; Le FI chiamano le dipendenze reali e ripristinano rilegature/dati con UNWIND-PROTECT.
;;; Limiti: file <=4096 byte; nessuna esecuzione/compilazione o attestazione C1/MC/DC.
;;; Non forziamo conteggi >u32, milioni di esiti o mutazioni concorrenti durante il packing.
;;; L'ownership osservata dopo poison non costituisce una prova di reachability del GC.
;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007 REQ-FOR-003 REQ-AFF-008 REQ-AFF-009
(in-package #:arcdocdb.recovery.active.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun avs-put (txid &optional (prepared t))
  "Documento volutamente opaco: questo recovery non interpreta CBOR/schema."
  (list :put txid prepared (av-bytes 1 #x41) (av-bytes 2 #xfe)))

(defun avs-tombstone (txid &optional (prepared t))
  (list :tombstone txid prepared (av-bytes 1 #x42)))

(defun avs-participants ()
  (list (rt::participant-id 1) (av-identity) (rt::participant-id 2 #xff)))

(defun avs-decision (txid csn)
  (list txid csn (avs-participants)))

(defun avs-record-position (batches batch-index record-index version)
  "Offset assoluto da sole lunghezze note delle fixture, senza decoder del prodotto."
  (+ (length (av-log (subseq batches 0 batch-index) :version version))
     (loop for spec in (subseq (nth batch-index batches) 0 record-index)
           sum (length (av-record spec version)))))

(defun avs-assert-stats (recovered expected)
  (let ((actual (multiple-value-list (ar:statistiche-active-recuperato recovered))))
    (is (equal expected actual))
    (destructuring-bind (batches records prepared local derived aborted) actual
      (is (<= batches (+ 1 records)))
      (is (= prepared (+ local derived aborted))))))

(defun avs-assert-query (recovered txid expected)
  "EXPECTED è (TXID CSN), oppure NIL; CSN zero presente resta distinto dall'assenza."
  (is (equal (if expected (list t (second expected)) '(nil 0))
             (multiple-value-list (ar:esito-chiusura-active recovered txid)))))

(defun avs-closure-bytes (active-id prefix outcomes)
  "Entry CLOSED little-endian indipendente dal serializer e dalle costanti di prodotto."
  (let ((bytes (av-bytes (+ 20 (* 16 (length outcomes))))))
    (ct::crr-pack bytes 0 active-id 8)
    (ct::crr-pack bytes 8 prefix 8)
    (ct::crr-pack bytes 16 (length outcomes) 4)
    (loop for (txid csn) in outcomes for pos from 20 by 16 do
      (ct::crr-pack bytes pos txid 8)
      (ct::crr-pack bytes (+ pos 8) csn 8))
    bytes))

(defun avs-assert-closure (recovered active-id prefix outcomes)
  "Range esatto e buffer sentinella; due scritture devono produrre gli stessi byte."
  (let* ((expected (avs-closure-bytes active-id prefix outcomes)) (size (length expected)))
    (is (= size (ar:lunghezza-chiusura-active recovered)))
    (dolist (start '(0 3 7))
      (dolist (trailing '(0 5))
        (let* ((buffer (av-bytes (+ start size trailing) #xa7)) (before (copy-seq buffer)))
          (replace before expected :start1 start)
          (dotimes (repeat 2)
            (is (= (+ start size) (ar:scrivi-chiusura-active recovered buffer start)))
            (is (equalp before buffer))))))))

(defun avs-read-success (f stats &rest options)
  (let ((recovered (apply #'av-call f options)))
    (is (typep recovered 'ar:active-recuperato))
    (avs-assert-stats recovered stats)
    (is (equalp (av-fixture-scratch f) (av-fixture-reference f)))
    (av-noeffects f)
    recovered))

(defun avs-reject (f type reason offset &rest options)
  "Errore semantico dopo lettura completa; nessun risultato parziale o effetto durevole."
  (let* ((thunk (lambda () (apply #'av-call f options)))
         (condition (if offset (av-expect type reason thunk offset)
                        (av-expect type reason thunk))))
    (unless offset (is (null (error-offset condition))))
    (is (equalp (av-fixture-scratch f) (av-fixture-reference f)))
    (av-noeffects f)
    condition))

;;; ARV-D04: prima occorrenza e ripetizioni PUT/TOMBSTONE nello stesso lotto.
;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-ACTIVE-ARV-D04-prepared-same-batch-zero-max-u64
  (dolist (version '(1 2))
    (let ((source (av-log (list (list (avs-put 0) (avs-tombstone 0)
                                     (avs-tombstone #xffffffffffffffff)
                                     (avs-put #xffffffffffffffff))) :version version)))
      (av-with-fixture source
        (lambda (f)
          (let ((r (avs-read-success f '(1 4 2 0 0 2) :max-prepared 2 :max-outcomes 0)))
            (avs-assert-query r 0 nil)
            (avs-assert-query r #xffffffffffffffff nil)
            (avs-assert-closure r 9 (length source) nil)))
        :version version))))

;;; REQ: REQ-TXM-007
(deftest test-REQ-TXM-007-ACTIVE-ARV-D04-prepared-different-batches-offset
  (dolist (version '(1 2))
    (dolist (txid '(0 #xffffffffffffffff))
      (dolist (makers (list (list #'avs-put #'avs-put) (list #'avs-put #'avs-tombstone)
                            (list #'avs-tombstone #'avs-put)))
        (let ((batches (list (list (funcall (first makers) txid)) nil
                             (list (funcall (second makers) txid)))))
          (av-with-fixture (av-log batches :version version)
            (lambda (f)
              (avs-reject f 'corruption-detected :active-recovery-prepared-batches
                          (avs-record-position batches 2 0 version)))
            :version version))))))

;;; REQ: REQ-TXM-007
(deftest test-REQ-TXM-007-ACTIVE-ARV-D04-outcome-before-prepared-same-other-batch
  (dolist (version '(1 2))
    (dolist (txid '(0 #xffffffffffffffff))
      (dolist (make-prepared (list #'avs-put #'avs-tombstone))
        (let ((p (funcall make-prepared txid)) (o (list :outcome txid 0)))
          (dolist (batches (list (list (list o p)) (list (list p o p))
                                 (list (list o) (list p)) (list (list p o) (list p))))
            (let* ((batch-index (1- (length batches)))
                   (record-index (1- (length (nth batch-index batches)))))
              (av-with-fixture (av-log batches :version version)
                (lambda (f)
                  (avs-reject f 'corruption-detected :active-recovery-outcome-before-prepare
                              (avs-record-position batches batch-index record-index version)))
                :version version))))))))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-ARV-D04-prepared-budget-distinct-not-physical
  (dolist (version '(1 2))
    (let ((batches (list (list (avs-put 7) (avs-tombstone 7) (avs-put 8)))))
      (av-with-fixture (av-log batches :version version)
        (lambda (f)
          (avs-read-success f '(1 3 2 0 0 2) :max-prepared 2)
          (dolist (budget '(0 1))
            (av-clear f)
            (avs-reject f 'resource-exhausted :active-recovery-prepared-budget
                        (avs-record-position batches 0 (if (zerop budget) 0 2) version)
                        :max-prepared budget)))
        :version version))))

;;; ARV-D05: duplicati identici consumano due record ma un solo commit locale.
;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-ACTIVE-ARV-D05-identical-outcomes-coalesce
  (dolist (version '(1 2))
    (dolist (pair '((0 0) (#xffffffffffffffff #xffffffffffffffff) (0 #xffffffffffffffff)
                    (#xffffffffffffffff 0)))
      (destructuring-bind (txid csn) pair
        (let ((p (avs-put txid)) (o (list :outcome txid csn)))
          (dolist (batches (list (list (list p o o)) (list (list p) (list o) (list o))))
            (let ((source (av-log batches :version version)))
              (av-with-fixture source
                (lambda (f)
                  (let ((r (avs-read-success f (list (length batches) 3 1 1 0 0) :max-outcomes 2)))
                    (avs-assert-query r txid nil)
                    (avs-assert-closure r 9 (length source) nil)))
                :version version))))))))

;;; REQ: REQ-TXM-007
(deftest test-REQ-TXM-007-ACTIVE-ARV-D05-conflicting-outcomes-zero-high-bits
  (dolist (version '(1 2))
    (dolist (txid '(0 #xffffffffffffffff))
      (dolist (csns '((0 1) (1 0) (0 #xffffffffffffffff) (#xffffffffffffffff 0)
                      (1 #x100000001) (#x7fffffffffffffff #xffffffffffffffff)))
        (dolist (orphan '(nil t))
          (let ((batches (list (append (unless orphan (list (avs-put txid)))
                                      (list (list :outcome txid (first csns))))
                               (list (list :outcome txid (second csns))))))
            (av-with-fixture (av-log batches :version version)
              (lambda (f)
                (avs-reject f 'corruption-detected :active-recovery-outcome-conflict
                            (avs-record-position batches 1 0 version)))
              :version version)))))))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-ARV-D05-outcome-budget-physical-including-orphans
  (dolist (version '(1 2))
    (dolist (orphan '(nil t))
      (let* ((o '(:outcome 0 0))
             (first (append (unless orphan (list (avs-put 0))) (list o)))
             (batches (list first (list o))) (source (av-log batches :version version)))
        (av-with-fixture source
          (lambda (f)
            (avs-read-success f (if orphan '(2 2 0 0 0 0) '(2 3 1 1 0 0)) :max-outcomes 2)
            (dolist (budget '(0 1))
              (av-clear f)
              (avs-reject f 'resource-exhausted :active-recovery-outcome-budget
                          (if (zerop budget)
                              (avs-record-position batches 0 (if orphan 0 1) version)
                              (avs-record-position batches 1 0 version))
                          :max-outcomes budget)))
          :version version)))))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-ARV-D04-D05-zero-budgets-ordinary-and-empty
  (dolist (version '(1 2))
    (dolist (specs (list nil (list (avs-put 17 nil) (avs-tombstone 17 nil))))
      (let ((source (av-log (if specs (list specs) nil) :version version)))
        (av-with-fixture source
          (lambda (f)
            (let ((r (avs-read-success f (if specs '(1 2 0 0 0 0) '(0 0 0 0 0 0))
                                       :max-prepared 0 :max-outcomes 0)))
              (avs-assert-query r 17 nil)
              (avs-assert-closure r 9 (length source) nil)))
          :version version)))))

;;; ARV-D07/D08: le quattro risoluzioni normali, inclusi CSN presenti zero/u64 massimo.
;;; REQ: REQ-TXM-005 REQ-TXM-007
(deftest test-REQ-TXM-007-ACTIVE-ARV-D07-D08-resolution-table-all-four-cases
  (dolist (version '(1 2))
    (dolist (txid '(0 #xffffffffffffffff))
      (dolist (csn '(0 #xffffffffffffffff))
        (dolist (local '(nil t))
          (dolist (decision '(nil t))
            (let* ((batches (list (list (avs-put txid) (avs-tombstone txid))))
                   (batches (if local (append batches (list (list (list :outcome txid csn)))) batches))
                   (source (av-log batches :version version))
                   (derived (and decision (not local)))
                   (outcomes (when derived (list (list txid csn)))))
              (av-with-fixture source
                (lambda (f)
                  (let ((r (avs-read-success f (list (length batches) (if local 3 2) 1
                                                    (if local 1 0) (if derived 1 0)
                                                    (if (or local decision) 0 1)))))
                    (avs-assert-query r txid (first outcomes))
                    (avs-assert-closure r 9 (length source) outcomes)))
                :version version :decision-specs (when decision (list (avs-decision txid csn)))))))))))

;;; REQ: REQ-TXM-005 REQ-TXM-007
(deftest test-REQ-TXM-005-ACTIVE-ARV-D07-decision-nonparticipant-with-without-outcome
  (dolist (version '(1 2))
    (dolist (local '(nil t))
      (let ((specs (append (list (avs-put 0)) (when local (list '(:outcome 0 0))))))
        (av-with-fixture (av-log (list specs) :version version)
          (lambda (f) (avs-reject f 'corruption-detected :active-recovery-participant nil))
          :version version
          :decision-specs (list (list 0 0 (list (rt::participant-id 1) (rt::participant-id 2)))))))))

;;; REQ: REQ-TXM-005 REQ-TXM-007
(deftest test-REQ-TXM-005-ACTIVE-ARV-D08-decision-csn-conflicts-low-high-zero
  (dolist (version '(1 2))
    (dolist (txid '(0 #xffffffffffffffff))
      (dolist (csns '((0 1) (1 0) (0 #xffffffffffffffff) (#xffffffffffffffff 0)
                      (1 #x100000001) (#x7fffffffffffffff #xffffffffffffffff)))
        (av-with-fixture (av-log (list (list (avs-tombstone txid)
                                            (list :outcome txid (first csns)))) :version version)
          (lambda (f) (avs-reject f 'corruption-detected :active-recovery-decision-conflict nil))
          :version version :decision-specs (list (avs-decision txid (second csns))))))))

;;; Un OUTCOME orfano non consulta DECISION e non genera coppie nella chiusura.
;;; REQ: REQ-TXM-005 REQ-TXM-007
(deftest test-REQ-TXM-007-ACTIVE-ARV-D08-orphan-outcomes-ignore-unrelated-decisions
  (dolist (version '(1 2))
    (let ((source (av-log (list '((:outcome 0 0) (:outcome #xffffffffffffffff #xffffffffffffffff)))
                          :version version)))
      (av-with-fixture source
        (lambda (f)
          (let ((r (avs-read-success f '(1 2 0 0 0 0) :max-prepared 0 :max-outcomes 2)))
            (avs-assert-query r 0 nil)
            (avs-assert-query r #xffffffffffffffff nil)
            (avs-assert-closure r 9 (length source) nil)))
        :version version
        :decision-specs (list (list 0 #xffffffffffffffff
                                    (list (rt::participant-id 1) (rt::participant-id 2)))
                             (avs-decision #xffffffffffffffff 0))))))

;;; ARV-D09: TXID distinti, record fisici e tutte le classi hanno conteggi differenti.
;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-ACTIVE-ARV-D09-mixed-statistics-exact-partition
  (dolist (version '(1 2))
    (let* ((batches (list (list (avs-put 17 nil) (avs-tombstone 17 nil)
                                (avs-put 0) (avs-tombstone 0) (avs-put 1)
                                (avs-put 2) (avs-tombstone 2) (avs-tombstone 3)
                                (avs-put 4) (avs-tombstone 5) (avs-put 6))
                          '((:outcome 0 0) (:outcome 0 0)
                            (:outcome 1 #xffffffffffffffff) (:outcome 999 18))))
           (source (av-log batches :version version))
           (outcomes '((2 0) (3 #xffffffffffffffff))))
      (av-with-fixture source
        (lambda (f)
          (let ((r (avs-read-success f '(2 15 7 2 2 3) :max-prepared 7 :max-outcomes 4)))
            (loop for txid from 0 to 7 do (avs-assert-query r txid (assoc txid outcomes)))
            (avs-assert-query r 17 nil)
            (avs-assert-query r 999 nil)
            (avs-assert-closure r 9 (length source) outcomes)))
        :version version
        :decision-specs (list (avs-decision 0 0) (avs-decision 2 0)
                             (avs-decision 3 #xffffffffffffffff)
                             (list 999 19 (list (rt::participant-id 1) (rt::participant-id 2))))))))

;;; REQ: REQ-TXM-007 REQ-AFF-009
(deftest test-REQ-TXM-007-ACTIVE-ARV-D09-unsealed-outcome-and-prepared-not-counted
  (dolist (version '(1 2))
    (dolist (decision '(nil t))
      (let* ((prefix (av-log (list (list (avs-put 1))) :version version))
             (tail (av-cat (av-record '(:outcome 1 99) version) (av-record (avs-put 2) version)))
             (source (av-cat prefix tail)) (outcomes (when decision '((1 0)))))
        (av-with-fixture source
          (lambda (f)
            (let ((r (avs-read-success f (if decision '(1 1 1 0 1 0) '(1 1 1 0 0 1))
                                       :max-prepared 1 :max-outcomes 0)))
              (is (equal (list (length source) (length prefix) :tail version)
                         (multiple-value-list (ar:frontiere-active-recuperato r))))
              (avs-assert-query r 1 (first outcomes))
              (avs-assert-query r 2 nil)
              (avs-assert-closure r 9 (length prefix) outcomes)))
          :version version :decision-specs (when decision (list (avs-decision 1 0))))))))

;;; ARV-D10: ricerca vuota/singola e taglie non potenze di due, ogni hit e ogni lacuna.
;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-ACTIVE-ARV-D10-ordered-outcomes-binary-search-all-gaps
  (dolist (version '(1 2))
    (dolist (count '(0 1 3 5 6 7 9 17))
      (let* ((outcomes (loop for i below count collect
                        (list (+ 2 (* 3 i)) (if (evenp i) 0 #xffffffffffffffff))))
             (specs (mapcar (lambda (pair) (avs-put (first pair))) (reverse outcomes)))
             (source (av-log (if specs (list specs) nil) :version version)))
        (av-with-fixture source
          (lambda (f)
            (let ((r (avs-read-success f (list (if specs 1 0) count count 0 count 0))))
              (av-clear f)
              (loop for txid from 0 to (+ 3 (* 3 count)) do
                (avs-assert-query r txid (assoc txid outcomes)))
              (avs-assert-query r #xffffffffffffffff nil)
              (avs-assert-closure r 9 (length source) outcomes)
              (is (null (av-events f)))
              (av-noeffects f)))
          :version version
          :decision-specs (mapcar (lambda (pair) (apply #'avs-decision pair)) (reverse outcomes)))))))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-ACTIVE-ARV-D10-u64-order-all-bits-no-csn-order-assumption
  (dolist (version '(1 2))
    (let* ((outcomes '((0 #xffffffffffffffff) (1 0) (#xffffffff #x100000000)
                       (#x100000000 1) (#x8000000000000000 #x8000000000000000)
                       (#xffffffff00000000 0) (#xffffffffffffffff #x123456789abcdef0)))
           (source (av-log (list (mapcar (lambda (pair) (avs-tombstone (first pair)))
                                         (reverse outcomes))) :version version)))
      (av-with-fixture source
        (lambda (f)
          (let ((r (avs-read-success f '(1 7 7 0 7 0))))
            (dolist (pair outcomes) (avs-assert-query r (first pair) pair))
            (dolist (txid '(2 #xfffffffe #x100000001 #x7fffffffffffffff
                            #x8000000000000001 #xfffffffeffffffff #xfffffffffffffffe))
              (avs-assert-query r txid nil))
            (avs-assert-closure r 9 (length source) outcomes)))
        :version version :decision-specs (mapcar (lambda (pair) (apply #'avs-decision pair)) outcomes)))))

;;; ARV-D12: vettore letterale del formato, indipendente anche dall'helper di packing test.
;;; REQ: REQ-FOR-003 REQ-TXM-007
(deftest test-REQ-FOR-003-ACTIVE-ARV-D12-closure-literal-bytes-high-id-and-csn
  (dolist (version '(1 2))
    (let* ((id #x1020304050607080) (txid #x0102030405060708) (csn #x8899aabbccddeeff)
           (source (av-log (list (list (avs-put txid))) :version version :active-id id)))
      (is (= 147 (length source)))
      (av-with-fixture source
        (lambda (f)
          (let* ((r (avs-read-success f '(1 1 1 0 1 0)))
                 (output (av-bytes 36 #xa7))
                 (expected #(#x80 #x70 #x60 #x50 #x40 #x30 #x20 #x10
                              #x93 0 0 0 0 0 0 0 1 0 0 0
                              8 7 6 5 4 3 2 1 #xff #xee #xdd #xcc #xbb #xaa #x99 #x88)))
            (is (= 36 (ar:lunghezza-chiusura-active r)))
            (is (= 36 (ar:scrivi-chiusura-active r output 0)))
            (is (equalp expected output))
            (avs-assert-closure r id 147 (list (list txid csn)))))
        :version version :active-id id :decision-specs (list (avs-decision txid csn))))))

;;; REQ: REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-ARV-D12-short-range-before-any-write
  (dolist (version '(1 2))
    (dolist (derived '(nil t))
      (let* ((source (av-log (list (list (avs-put 1))) :version version))
             (outcomes (when derived '((1 0)))))
        (av-with-fixture source
          (lambda (f)
            (let* ((r (avs-read-success f (if derived '(1 1 1 0 1 0) '(1 1 1 0 0 1))))
                   (size (ar:lunghezza-chiusura-active r)))
              (av-clear f)
              (dolist (layout (list (list (1- size) 0) (list (+ size 4) 5)
                                    (list size (1+ size)) (list 0 0)))
                (destructuring-bind (capacity start) layout
                  (let* ((buffer (av-bytes capacity #xd3)) (before (copy-seq buffer)))
                    (av-expect 'invalid-argument :buffer-range
                               (lambda () (ar:scrivi-chiusura-active r buffer start)))
                    (is (equalp before buffer)))))
              (avs-assert-closure r 9 (length source) outcomes)
              (is (null (av-events f)))
              (av-noeffects f)))
          :version version :decision-specs (when derived (list (avs-decision 1 0))))))))

;;; REQ: REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-ARV-D12-series-identity-alias-precedes-range
  (dolist (version '(1 2))
    (av-with-fixture (av-log (list (list (avs-put 1))) :version version)
      (lambda (f)
        (let* ((r (avs-read-success f '(1 1 1 0 1 0)))
               (identity (arcdocdb.get::vista-get-serie-identity (av-fixture-view f)))
               (before (copy-seq identity)))
          (av-clear f)
          (dolist (start '(0 16 99))
            (av-expect 'invalid-argument :active-recovery-closure-alias
                       (lambda () (ar:scrivi-chiusura-active r identity start)))
            (is (equalp before identity)))
          (avs-assert-query r 1 '(1 0))
          (is (null (av-events f)))
          (av-noeffects f)))
      :version version :decision-specs (list (avs-decision 1 0)))))

;;; FI ownership dopo consegna: poison interni della tabella, poi ripristino integrale.
;;; La tabella è reale e resta congelata per tutta AV-CALL; nessuna entry viene forgiata.
(defun avs-with-poisoned-decisions (table thunk)
  (let* ((entries (arcdocdb.recovery.decisions::%table-entries table))
         (saved (copy-seq entries))
         (participants (loop for entry across saved collect
                         (arcdocdb.recovery.decisions::%entry-participants entry)))
         (copies (mapcar #'copy-seq participants)))
    (unwind-protect
         (progn
           (dolist (bytes participants) (fill bytes #xe7))
           (fill entries nil)
           (funcall thunk))
      (loop for bytes in participants for copy in copies do (replace bytes copy))
      (replace entries saved))
    (is (equalp saved entries))))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-ACTIVE-ARV-D10-D12-result-independent-of-scratch-and-decision-internals
  (dolist (version '(1 2))
    (let* ((outcomes '((0 #xffffffffffffffff) (3 0) (#xffffffffffffffff 1)))
           (source (av-log (list (mapcar (lambda (pair) (avs-put (first pair)))
                                         (reverse outcomes))) :version version)))
      (av-with-fixture source
        (lambda (f)
          (let ((r (avs-read-success f '(1 3 3 0 3 0))))
            (av-clear f)
            (fill (av-fixture-scratch f) #x5a)
            (avs-with-poisoned-decisions (av-fixture-decisions f)
              (lambda ()
                (dotimes (repeat 2)
                  (avs-assert-stats r '(1 3 3 0 3 0))
                  (dolist (pair outcomes) (avs-assert-query r (first pair) pair))
                  (avs-assert-query r 1 nil)
                  (avs-assert-closure r 9 (length source) outcomes))
                (let ((expected (copy-seq (av-fixture-scratch f))))
                  (replace expected (avs-closure-bytes 9 (length source) outcomes) :start1 3)
                  (is (= 71 (ar:scrivi-chiusura-active r (av-fixture-scratch f) 3)))
                  (is (equalp expected (av-fixture-scratch f))))))
            (is (null (av-events f)))
            (av-noeffects f)
            (avs-read-success f '(1 3 3 0 3 0))))
        :version version :decision-specs (mapcar (lambda (pair) (apply #'avs-decision pair)) outcomes)))))

;;;; FI outside-contract: guardie non raggiungibili da file/tabella canonici.
;;;; Nessuna modifica permanente di funzioni, capacità o risultati del percorso ordinario.
(defun avs-with-function-fi (name replacement thunk)
  "Uso esclusivamente seriale; cleanup della rilegatura anche per condizioni/nonlocal exit."
  (let ((original (fdefinition name)))
    (unwind-protect
         (progn (setf (fdefinition name) (funcall replacement original)) (funcall thunk))
      (setf (fdefinition name) original))
    (is (eq original (fdefinition name)))))

;;; ARV-D07: >=2 falso; il decoder pubblico rifiuterebbe una simile DECISION a monte.
;;; REQ: REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-ARV-D07-FI-decision-participant-count-outside-contract
  (av-with-fixture (av-log (list (list (avs-put 1))))
    (lambda (f)
      (let ((hit nil))
        (avs-with-function-fi 'ar::trova-decisione
          (lambda (original)
            (lambda (table txid)
              (multiple-value-bind (present csn count) (funcall original table txid)
                (is present) (is (= count 3)) (setf hit t)
                (values present csn 1))))
          (lambda () (avs-reject f 'corruption-detected :active-recovery-participant nil)))
        (is hit))
      (av-clear f)
      (avs-read-success f '(1 1 1 0 1 0)))
    :decision-specs (list (avs-decision 1 0))))

(defun avs-with-dirty-resolution (workspace field thunk)
  "FI ARV-D09: un solo contatore iniziale nonzero; ripristina lo stesso workspace reale."
  (let ((local (ar::workspace-active-local workspace))
        (aborted (ar::workspace-active-aborted workspace))
        (derived (ar::workspace-active-derived workspace)))
    (is (zerop (hash-table-count derived)))
    (unwind-protect
         (progn
           (case field
             (:local (setf (ar::workspace-active-local workspace) 1))
             (:aborted (setf (ar::workspace-active-aborted workspace) 1))
             (:derived (setf (gethash 999 derived) 0))
             (otherwise (error 'invariant-violation :reason :active-test-fi-field)))
           (funcall thunk))
      (setf (ar::workspace-active-local workspace) local
            (ar::workspace-active-aborted workspace) aborted)
      (remhash 999 derived))))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-ARV-D09-FI-each-initial-resolution-counter
  (dolist (field '(:local :aborted :derived))
    (av-with-fixture (av-log (list (list (avs-put 1))))
      (lambda (f)
        (let ((hit nil))
          (avs-with-function-fi 'ar::risolvi-prepared-active
            (lambda (original)
              (lambda (workspace decisions identity)
                (setf hit t)
                (avs-with-dirty-resolution workspace field
                  (lambda () (funcall original workspace decisions identity)))))
            (lambda () (avs-reject f 'invariant-violation :active-recovery-already-resolved nil)))
          (is hit))
        (av-clear f)
        (avs-read-success f '(1 1 1 0 1 0)))
      :decision-specs (list (avs-decision 1 0)))))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-ARV-D09-FI-final-resolution-partition-mismatch
  (av-with-fixture (av-log (list (list (avs-put 1))))
    (lambda (f)
      (let ((injected nil))
        (unwind-protect
             (avs-with-function-fi 'ar::risolvi-txid-active
               (lambda (original)
                 (lambda (workspace decisions identity txid)
                   (funcall original workspace decisions identity txid)
                   (setf injected workspace)
                   (incf (ar::workspace-active-aborted workspace))
                   nil))
               (lambda () (avs-reject f 'invariant-violation :active-recovery-resolution-count nil)))
          (when injected (decf (ar::workspace-active-aborted injected))))
        (is injected))
      (av-clear f)
      (avs-read-success f '(1 1 1 0 0 1)))))

;;; ARV-D10: TXID reale presente, CSN outside-contract; ogni mutazione viene ripristinata.
;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-ARV-D10-FI-pack-csn-type-invalid
  (dolist (bad-csn (list -1 (ash 1 64) :not-a-csn))
    (av-with-fixture (av-log (list (list (avs-put 1))))
      (lambda (f)
        (let ((hit nil))
          (avs-with-function-fi 'ar::impacchetta-esiti-active
            (lambda (original)
              (lambda (workspace)
                (let ((table (ar::workspace-active-derived workspace)))
                  (multiple-value-bind (csn present) (gethash 1 table)
                    (is present) (is (zerop csn)) (setf hit t)
                    (unwind-protect
                         (progn (setf (gethash 1 table) bad-csn) (funcall original workspace))
                      (setf (gethash 1 table) csn))))))
            (lambda () (avs-reject f 'invariant-violation :active-recovery-pack-value nil)))
          (is hit))
        (av-clear f)
        (avs-read-success f '(1 1 1 0 1 0)))
      :decision-specs (list (avs-decision 1 0)))))

;;; ARV-D12: il packing reale precede l'iniezione di due array di lunghezze diverse.
;;; Il risultato incoerente esiste solo in questa FI; nessuna capacità viene costruita a mano.
;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-AFF-008-ACTIVE-ARV-D12-FI-closure-and-query-shape-before-write
  (av-with-fixture (av-log (list (list (avs-put 1))))
    (lambda (f)
      (let ((broken nil) (hit nil))
        (avs-with-function-fi 'ar::impacchetta-esiti-active
          (lambda (original)
            (lambda (workspace)
              (multiple-value-bind (ids csns) (funcall original workspace)
                (is (= 1 (length ids) (length csns))) (setf hit t)
                (values ids (subseq csns 0 0)))))
          (lambda () (setf broken (av-call f))))
        (is hit)
        (av-clear f)
        (dolist (txid '(0 1 #xffffffffffffffff))
          (av-expect 'invariant-violation :active-recovery-query-shape
                     (lambda () (ar:esito-chiusura-active broken txid))))
        (dolist (capacity '(0 36 43))
          (let* ((output (av-bytes capacity #xb6)) (before (copy-seq output)))
            (av-expect 'invariant-violation :active-recovery-closure-shape
                       (lambda () (ar:scrivi-chiusura-active broken output 3)))
            (is (equalp before output))))
        (is (null (av-events f)))
        (av-noeffects f))
      (avs-read-success f '(1 1 1 0 1 0)))
    :decision-specs (list (avs-decision 1 0))))
