;;;; Costruzione CLOSED: prove, budget e copie, con file e manifest reali.
;;; OWNER: ogni test possiede fixture e buffer; nessuna pubblicazione concorrente.
;;; SHARED: nessuno stato tra test; immagini e CSN attesi sono espliciti.
(in-package #:arcdocdb.get.resolver.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; REQ: REQ-FOR-001 REQ-FOR-003 REQ-FOR-004 REQ-IDX-001
(deftest test-REQ-FOR-004-resolver-native-v1-v2-multiple-batches-and-puts
  (dolist (version '(1 2))
    (with-resolver-fixture
        (fixture :version version :cache-p nil
                 :batches '(((:kind :prepared :txid #x100000000 :csn 7)
                             (:kind :prepared :txid #xffffffff :csn 7))
                            ((:kind :ordinary :csn 7)
                             (:kind :outcome :txid #xffffffff :csn 7)
                             (:kind :outcome :txid #x100000000 :csn 7))))
      ;; PUT56, PUT56, SEAL56, PUT56, OUTCOME32, OUTCOME32, SEAL56.
      (is (= 408 (rf-end fixture)))
      (is (equalp #(64 120 232) (rf-offsets fixture)))
      (is (equalp #(56 56 56) (rf-sizes fixture)))
      (is (equalp #(288 320) (rf-proof-offsets fixture)))
      (is (= 72 (r:payload-mappa-segmento-get (rf-map fixture))))
      (is (eq :input (io:mode-file (rf-file fixture))))
      (is (eq :open (io:stato-file (rf-file fixture))))
      ;; Questi byte non provengono dalla mappa o dalla risposta GET.
      (is (equalp #(0 0 0 0 51 68 85 102 119 136 153 170 187 204 221 238)
                  (aref (rf-keys fixture) 0)))
      (is (equalp #(29 102 175 248 65 138 211 28 101 174 247 64 137 210 27 100)
                  (aref (rf-values fixture) 0)))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-AFF-008 REQ-FOR-004
(deftest test-REQ-AFF-008-resolver-payload-zero-outcomes-exact-one-short
  (dolist (version '(1 2))
    (with-resolver-fixture (fixture :version version :cache-p nil :build-p nil
                                   :records '((:kind :ordinary :csn 7)) :proofs nil)
      (is (typep (resolver-build-map fixture :budget-payload 24) 'r:mappa-segmento-get))
      (is (= 24 (r:payload-mappa-segmento-get (rf-map fixture))))
      (let ((old (rf-map fixture)))
        (signals resource-exhausted (resolver-build-map fixture :budget-payload 23)
                 :resolver-payload-budget)
        (is (eq old (rf-map fixture))))
      (is (zerop (length (rf-proof-offsets fixture))))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-AFF-008 REQ-FOR-004
(deftest test-REQ-AFF-008-resolver-payload-one-outcome-exact-one-short
  (dolist (version '(1 2))
    (with-resolver-fixture (fixture :version version :cache-p nil :build-p nil)
      (is (typep (resolver-build-map fixture :budget-payload 44) 'r:mappa-segmento-get))
      (is (= 24 (r:payload-mappa-segmento-get (rf-map fixture))))
      (let ((old (rf-map fixture)))
        (signals resource-exhausted (resolver-build-map fixture :budget-payload 43)
                 :resolver-payload-budget)
        (is (eq old (rf-map fixture))))
      (is (equalp #(120) (rf-proof-offsets fixture)))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-AFF-008 REQ-FOR-004
(deftest test-REQ-AFF-008-resolver-payload-two-outcomes-radix-exact-one-short
  (dolist (version '(1 2))
    (with-resolver-fixture
        (fixture :version version :cache-p nil :build-p nil
                 :proofs (list (list :txid +resolver-default-txid+ :csn 7)
                               (list :txid +resolver-default-txid+ :csn 7)))
      ;; Un PUT, due OUTCOME: 24 + 40*2 + 1024 = 1128 byte di picco.
      (is (typep (resolver-build-map fixture :budget-payload 1128) 'r:mappa-segmento-get))
      (is (= 24 (r:payload-mappa-segmento-get (rf-map fixture))))
      (let ((old (rf-map fixture)))
        (signals resource-exhausted (resolver-build-map fixture :budget-payload 1127)
                 :resolver-payload-budget)
        (is (eq old (rf-map fixture))))
      (is (equalp #(120 152) (rf-proof-offsets fixture)))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-AFF-008 REQ-FOR-003
(deftest test-REQ-AFF-008-resolver-empty-prefix-zero-payload
  (dolist (version '(1 2))
    (with-resolver-fixture (fixture :version version :cache-p nil :batches nil :budget-payload 0)
      (is (= 64 (rf-end fixture)))
      (is (= 0 (r:payload-mappa-segmento-get (rf-map fixture))))
      (is (zerop (length (rf-keys fixture))))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-FOR-004 REQ-AFF-002
(deftest test-REQ-FOR-004-resolver-unresolved-prepared-not-invented-commit
  (dolist (version '(1 2))
    (with-resolver-fixture (fixture :version version :cache-p nil :proofs nil)
      (is (= 24 (r:payload-mappa-segmento-get (rf-map fixture))))
      (is (eq :candidate (resolver-begin fixture 0)))
      ;; La riga senza prova conserva CSN zero; il candidato legale 7 non concorda.
      ;; Non si pubblica un CSN zero nell'indice, né si interpreta il caso come abort.
      (signals invariant-violation (r:risolvi-candidato-get (rf-context fixture) (rf-map fixture))
               :resolver-candidate-csn)
      (is (resolver-clean-p fixture :faulted))
      (is (null (resolver-reads fixture)))
      (is (every (lambda (byte) (= byte +resolver-sentinel+)) (rf-output fixture))))))

;;; REQ: REQ-FOR-004 REQ-AFF-002
(deftest test-REQ-FOR-004-resolver-outcome-before-put-is-corruption
  (dolist (version '(1 2))
    (with-resolver-fixture
        (fixture :version version :cache-p nil :build-p nil
                 :batches '(((:kind :outcome :txid #x100000000 :csn 7)
                             (:kind :prepared :txid #x100000000 :csn 7))))
      (is (equalp #(96) (rf-offsets fixture)))
      (is (equalp #(64) (rf-proof-offsets fixture)))
      (signals corruption-detected (resolver-build-map fixture) :resolver-outcome-before-put)
      (is (null (rf-map fixture)))
      (is (eq :open (io:stato-file (rf-file fixture))))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-FOR-004 REQ-AFF-002
(deftest test-REQ-FOR-004-resolver-conflicting-outcome-low-word
  (dolist (version '(1 2))
    (with-resolver-fixture
        (fixture :version version :cache-p nil :build-p nil
                 :records '((:kind :prepared :txid #x100000000 :csn #x100000007))
                 :proofs '((:txid #x100000000 :csn #x100000007)
                           (:txid #x100000000 :csn #x100000008)))
      (signals corruption-detected (resolver-build-map fixture) :resolver-conflicting-outcome)
      (is (null (rf-map fixture)))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-FOR-004 REQ-AFF-002
(deftest test-REQ-FOR-004-resolver-conflicting-outcome-high-word
  (dolist (version '(1 2))
    (with-resolver-fixture
        (fixture :version version :cache-p nil :build-p nil
                 :records '((:kind :prepared :txid #x100000000 :csn #x100000007))
                 :proofs '((:txid #x100000000 :csn #x100000007)
                           (:txid #x100000000 :csn #x200000007)))
      (signals corruption-detected (resolver-build-map fixture) :resolver-conflicting-outcome)
      (is (null (rf-map fixture)))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-FOR-004 REQ-IDX-001 REQ-CON-004
(deftest test-REQ-CON-004-resolver-source-buffer-reuse-does-not-alter-map
  (dolist (version '(1 2))
    (with-resolver-fixture (fixture :version version :cache-p nil)
      ;; Il caller riusa il buffer dopo costruzione; FD, indice e immagine rimangono intatti.
      (fill (rf-buffer fixture) #xa5)
      (unwind-protect
           (progn
             (is (eq :candidate (resolver-begin fixture 0)))
             (multiple-value-bind (segment end flags proof)
                 (r:risolvi-candidato-get (rf-context fixture) (rf-map fixture))
               (is (typep segment 'g:segmento-get)) (is (= end 208))
               (is (= flags 1)) (is (= proof 120)))
             (is (equal '(:segment :disabled :not-attempted nil nil)
                        (multiple-value-list
                         (r:leggi-record-risolto-get (rf-context fixture) (rf-map fixture)))))
             (is (resolver-copy-and-finish fixture 0)))
        (g:abbandona-get (rf-context fixture)))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-AFF-008 REQ-STO-006
(deftest test-REQ-AFF-008-resolver-source-budget-before-io
  (dolist (version '(1 2))
    (with-resolver-fixture (fixture :version version :cache-p nil :build-p nil)
      (is (= 208 (rf-end fixture)))
      (signals resource-exhausted (resolver-build-map fixture :max-bytes 207 :max-batch-bytes 207)
               :resolver-source-budget)
      (is (null (resolver-reads fixture)))
      (setf (rf-buffer fixture) (resolver-octets 207))
      (signals resource-exhausted (resolver-build-map fixture) :resolver-source-budget)
      (is (null (resolver-reads fixture)))
      (is (null (rf-map fixture)))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-AFF-008 REQ-FOR-003
(deftest test-REQ-AFF-008-resolver-record-and-batch-budgets
  (dolist (version '(1 2))
    (with-resolver-fixture
        (fixture :version version :cache-p nil :build-p nil
                 :batches '(((:kind :prepared :txid 11 :csn 7))
                            ((:kind :outcome :txid 11 :csn 7))))
      (is (typep (resolver-build-map fixture :max-records 2 :max-batches 2 :max-batch-records 1)
                 'r:mappa-segmento-get))
      (let ((old (rf-map fixture)))
        (signals resource-exhausted (resolver-build-map fixture :max-records 1)
                 :resolver-record-budget)
        (is (eq old (rf-map fixture)))
        (signals resource-exhausted (resolver-build-map fixture :max-batches 1)
                 :resolver-batch-budget)
        (is (eq old (rf-map fixture))))
      (is (resolver-clean-p fixture)))))

;;; REQ: REQ-STO-006 REQ-FOR-003 REQ-AFF-002
(deftest test-REQ-STO-006-resolver-one-fd-authoritative-prefix-preserves-tail
  (dolist (version '(1 2))
    (with-resolver-fixture (fixture :version version :cache-p nil :build-p nil)
      (resolver-build-map fixture)
      (let ((reads (resolver-reads fixture)))
        (is (= 2 (length reads)))
        (is (= (first (first reads)) (first (second reads))))
        (is (equal '((0 64) (64 144)) (mapcar #'cdr reads))))
      (is (= 208 (rf-end fixture)))
      (is (= 219 (length (rf-image fixture))))
      ;; Lettura distinta del controller: byte fisici dopo END non toccati dal costruttore.
      (with-open-file (stream (rf-path fixture) :direction :input :element-type '(unsigned-byte 8))
        (let ((copy (resolver-octets 219)))
          (is (= 219 (read-sequence copy stream)))
          (is (equalp copy (rf-image fixture)))
          (is (loop for i from 208 below 219 always (= #xee (aref copy i))))))
      (is (resolver-clean-p fixture)))))
