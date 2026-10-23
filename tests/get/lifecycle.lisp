;;;; GET-D01/D02/D03/D09: capacità, ammissione, visibilità e consegna privata.
;;; OWNER: un solo worker per fixture; cleanup esterno prima di ogni richiesta.
;;; REQ: REQ-CON-004 REQ-MVC-001 REQ-MVC-004 REQ-MVC-005 REQ-AFF-008
(in-package #:arcdocdb.get.tests)

(define-condition get-lifecycle-abort (error) ())

;;; REQ: REQ-MVC-004 REQ-CMP-007
(defun get-lifecycle-copy (fixture)
  "Copia effettiva prima della conferma; atteso dai byte di input noti."
  (is (eq :candidate (get-start fixture)))
  (is (eq :segment (get-load fixture)))
  (let ((output (get-zeros (length (get-fixture-value fixture)) #xee)))
    (is (= (length output) (copia-valore-get (get-fixture-context fixture) output 0)))
    (is (equalp (get-fixture-value fixture) output))
    (is (eq :copied (stato-contesto-get (get-fixture-context fixture))))
    (is (ebr:epoca-attiva-p (get-fixture-epoch fixture)))
    output))

;;; REQ: REQ-MVC-001 REQ-MVC-004 REQ-MVC-005
(defun get-lifecycle-snapshot-csn (candidate limit expected)
  "CSN record/indice coerenti, snapshot indipendente, nessun oracolo privato."
  (with-get-fixture (f (:cache-p nil :csn candidate :snapshot-csn limit))
    (is (equal (list 1 limit t) (multiple-value-list (get-register-snapshot f))))
    (let ((before (get-read-count f)))
      (is (eq expected (get-start f :snapshot (get-fixture-snapshot f) :generation 1)))
      (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
      (if (eq expected :candidate)
          (progn
            (is (eq :segment (get-load f)))
            (is (equalp (get-fixture-value f) (get-copy-found f))))
          (progn
            (is (= before (get-read-count f)))
            (is (equal '(:history-required 0)
                       (multiple-value-list (concludi-get (get-fixture-context f) 12))))
            (get-check-idle f)))
      (is (= limit (mvcc:verifica-snapshot (get-fixture-snapshot f) 1 13))))))

;;; GET-D01 — REQ: REQ-AFF-008 REQ-CON-004
(deftest test-REQ-AFF-008-get-exact-payload-budget
  (with-get-fixture (f (:cache-p nil))
    ;; Limiti dichiarati dal formato e dal budget, non accessori privati GET.
    (dolist (size '(1 24 128 65536 16842775))
      (let ((context (crea-contesto-get (get-fixture-scope f) 1
                                       :record-bytes size :budget-payload (+ size 152))))
        (is (= (+ size 152) (payload-contesto-get context)))
        (is (eq :idle (stato-contesto-get context)))
        (is (not (ebr:epoca-attiva-p (ebr:contesto-epoca (get-fixture-epochs f) 1))))))))

;;; GET-D01 — REQ: REQ-AFF-008 REQ-CON-004
(deftest test-REQ-AFF-008-get-default-payload-budget
  (with-get-fixture (f (:cache-p nil))
    (let ((context (crea-contesto-get (get-fixture-scope f) 1)))
      (is (= 65688 (payload-contesto-get context)))
      (is (eq :idle (stato-contesto-get context))))))

;;; GET-D01 — REQ: REQ-AFF-008 REQ-CON-004
(deftest test-REQ-AFF-008-get-budget-refused-before-worker-lookup
  (with-get-fixture (f (:cache-p nil))
    (dolist (size '(1 128 16842775))
      ;; Worker invalido intenzionale: il budget deve rifiutare prima del lookup.
      ;; Questo osserva l'ordine dei rifiuti, non misura allocazioni o RSS.
      (signals resource-exhausted
        (crea-contesto-get (get-fixture-scope f) -1
                          :record-bytes size :budget-payload (+ size 151))
        :get-worker-budget)
      (get-check-idle f))))

;;; GET-D01 — REQ: REQ-AFF-008 REQ-CON-004
(deftest test-REQ-AFF-008-get-invalid-worker-configuration
  (with-get-fixture (f (:cache-p nil))
    (dolist (size '(-1 0 16842776))
      (signals invalid-argument
        (crea-contesto-get (get-fixture-scope f) 1
                          :record-bytes size :budget-payload most-positive-fixnum)
        :get-worker-configuration))
    (dolist (budget (list -1 (1+ most-positive-fixnum)))
      (signals invalid-argument
        (crea-contesto-get (get-fixture-scope f) 1 :record-bytes 1 :budget-payload budget)
        :get-worker-configuration))
    (get-check-idle f)))

;;; GET-D01 — REQ: REQ-FOR-001 REQ-IDX-001
(deftest test-REQ-FOR-001-get-view-identity-length
  (with-get-fixture (f (:cache-p nil))
    (dolist (size '(0 15 17))
      (signals invalid-argument
        (crea-vista-get-serie (get-fixture-scope f) (get-fixture-primary f) nil (get-zeros size))
        :get-serie-identity))
    (get-check-idle f)))

;;; GET-D01 — REQ: REQ-FOR-001 REQ-IDX-001
(deftest test-REQ-FOR-001-get-view-copies-identity
  (with-get-fixture (f (:cache-p nil))
    (let* ((identity (get-identity))
           (view (crea-vista-get-serie (get-fixture-scope f) (get-fixture-primary f) nil identity)))
      (setf (aref identity 0) #xff (aref identity 15) #xee)
      ;; Il medesimo header reale mantiene l'identità iniziale 0..15.
      (is (typep (crea-segmento-get view (get-fixture-file f) 17 (get-zeros 64))
                 'g:segmento-get))
      (get-check-idle f))))

;;; GET-D02 — REQ: REQ-CON-004 REQ-MVC-005
(deftest test-REQ-CON-004-get-second-view-same-canonical-archive
  (with-get-fixture (f (:cache-p nil :publish-p nil))
    (let ((view (crea-vista-get-serie (get-fixture-scope f) (get-fixture-primary f) nil (get-identity))))
      (is (eq :absent (avvia-get (get-fixture-context f) view (get-fixture-key f) nil 0 11)))
      (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
      (is (equal '(:absent 0) (multiple-value-list (concludi-get (get-fixture-context f) 12))))
      (get-check-idle f))))

;;; GET-D02 — REQ: REQ-CON-004 REQ-MVC-005
(deftest test-REQ-CON-004-get-equal-registers-distinct-archive-refused
  (with-get-fixture (f (:cache-p nil))
    (let* ((other-scope (crea-ambito-get (get-fixture-epochs f) (get-fixture-snapshots f)))
           (view (crea-vista-get-serie other-scope (get-fixture-primary f) nil (get-identity))))
      (signals invalid-argument
        (avvia-get (get-fixture-context f) view (get-fixture-key f) nil 0 11) :get-archive-owner)
      (get-check-idle f))))

;;; GET-D02 — REQ: REQ-CON-004 REQ-MVC-005
(deftest test-REQ-CON-004-get-foreign-archive-refused
  (with-get-fixture (f (:cache-p nil))
    (with-get-fixture (foreign (:cache-p nil))
      (signals invalid-argument
        (avvia-get (get-fixture-context f) (get-fixture-view foreign) (get-fixture-key f) nil 0 11)
        :get-archive-owner)
      (get-check-idle f)
      (get-check-idle foreign))))

;;; GET-D02 — REQ: REQ-LIM-003 REQ-CON-004
(deftest test-REQ-LIM-003-get-key-length-boundaries
  (with-get-fixture (f (:cache-p nil))
    (dolist (size '(0 65536))
      (signals invalid-argument (get-start f :key (get-zeros size #xfe)) :get-key-range)
      (get-check-idle f))
    (dolist (size '(1 65535))
      (is (eq :absent (get-start f :key (get-zeros size #xfe))))
      (is (equal '(:absent 0) (multiple-value-list (concludi-get (get-fixture-context f) 12))))
      (get-check-idle f))))

;;; GET-D02 — REQ: REQ-CON-004 REQ-AFF-008
(deftest test-REQ-CON-004-get-private-key-alias-refused
  (with-get-fixture (f (:cache-p nil :record-bytes 128))
    ;; Privati usati solo come input alias vietati, mai come oracolo dei dati.
    (dolist (key (list (g::contesto-get-bytes (get-fixture-context f))
                      (g::contesto-get-proof (get-fixture-context f))))
      (signals invalid-argument (get-start f :key key) :get-key-alias)
      (get-check-idle f))))

;;; GET-D02 — REQ: REQ-IDX-001 REQ-CMP-007
(deftest test-REQ-IDX-001-get-unconfigured-hash-releases-epoch
  (with-get-fixture (f (:cache-p nil))
    (let* ((primary (p:crea-indice-primario :capacity 16 :arena-bytes 64))
           (view (crea-vista-get-serie (get-fixture-scope f) primary nil (get-identity))))
      (signals invalid-argument
        (avvia-get (get-fixture-context f) view (get-fixture-key f) nil 0 11)
        :primary-hash-unconfigured)
      (get-check-idle f)
      ;; Un rifiuto durante l'hash non lascia residui per il tentativo successivo.
      (is (eq :candidate (get-start f)))
      (abbandona-get (get-fixture-context f))
      (get-check-idle f))))

;;; GET-D02 — REQ: REQ-CON-004 REQ-CMP-007
(deftest test-REQ-CON-004-get-nested-start-preserves-existing-pin
  (with-get-fixture (f (:cache-p nil))
    (is (eq :candidate (get-start f)))
    (signals invalid-argument (get-start f :now 12) :get-worker-state)
    (is (eq :candidate (stato-contesto-get (get-fixture-context f))))
    (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
    (abbandona-get (get-fixture-context f))
    (get-check-idle f)))

;;; GET-D02/D09 — REQ: REQ-CON-004 REQ-CMP-007
(deftest test-REQ-CON-004-get-premature-finish-preserves-existing-pin
  (with-get-fixture (f (:cache-p nil))
    (is (eq :candidate (get-start f)))
    (signals invalid-argument (concludi-get (get-fixture-context f) 12) :get-result-not-ready)
    (is (eq :candidate (stato-contesto-get (get-fixture-context f))))
    (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
    (abbandona-get (get-fixture-context f))
    (get-check-idle f)))

;;; GET-D02 — REQ: REQ-CMP-007 REQ-CON-004
(deftest test-REQ-CMP-007-get-abandon-is-idempotent-and-reusable
  (with-get-fixture (f (:cache-p nil))
    (is (eq :candidate (get-start f)))
    (is (null (abbandona-get (get-fixture-context f))))
    (get-check-idle f)
    (is (null (abbandona-get (get-fixture-context f))))
    (get-check-idle f)
    (is (eq :candidate (get-start f :now 13)))
    (abbandona-get (get-fixture-context f))
    (get-check-idle f)))

;;; GET-D02 — REQ: REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-AFF-004-get-fi-faulted-context-is-terminal
  (with-get-fixture (f (:cache-p nil))
    ;; FI esplicita del solo stato locale; nessun reader attivo viene azzerato.
    (setf (g::contesto-get-state (get-fixture-context f)) :faulted)
    (signals invalid-argument (get-start f) :get-worker-state)
    (get-check-faulted f)
    (abbandona-get (get-fixture-context f))
    (abbandona-get (get-fixture-context f))
    (get-check-faulted f)))

;;; GET-D02 — REQ: REQ-AFF-004 REQ-CON-004
(deftest test-REQ-AFF-004-get-fi-idle-residue-faults
  (dolist (field '(:view :key :value-start :value-end))
    (with-get-fixture (f (:cache-p nil))
      ;; Una causa per fixture: dati residui incoerenti nello stato IDLE.
      (ecase field
        (:view (setf (g::contesto-get-view (get-fixture-context f)) (get-fixture-view f)))
        (:key (setf (g::contesto-get-key (get-fixture-context f)) (get-fixture-key f)))
        (:value-start (setf (g::contesto-get-value-start (get-fixture-context f)) 1))
        (:value-end (setf (g::contesto-get-value-end (get-fixture-context f)) 1)))
      (signals invariant-violation (get-start f) :get-worker-residue)
      (get-check-faulted f)
      (abbandona-get (get-fixture-context f))
      (get-check-faulted f))))

;;; GET-D03 — REQ: REQ-MVC-005 REQ-IDX-001
(deftest test-REQ-MVC-005-get-current-miss-authorizes-absence
  (with-get-fixture (f (:cache-p nil :publish-p nil))
    (let ((reads (get-read-count f)))
      (is (eq :absent (get-start f)))
      (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
      (is (= reads (get-read-count f)))
      (is (equal '(:absent 0) (multiple-value-list (concludi-get (get-fixture-context f) 12))))
      (get-check-idle f))))

;;; GET-D03 — REQ: REQ-MVC-001 REQ-MVC-004
(deftest test-REQ-MVC-001-get-snapshot-miss-requires-history
  (with-get-fixture (f (:cache-p nil :publish-p nil :snapshot-csn 7))
    (is (equal '(1 7 t) (multiple-value-list (get-register-snapshot f))))
    (let ((reads (get-read-count f)))
      (is (eq :history-required (get-start f :snapshot (get-fixture-snapshot f) :generation 1)))
      (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
      (is (= reads (get-read-count f)))
      (is (equal '(:history-required 0)
                 (multiple-value-list (concludi-get (get-fixture-context f) 12))))
      (get-check-idle f)
      (is (= 7 (mvcc:verifica-snapshot (get-fixture-snapshot f) 1 13))))))

;;; GET-D03 — REQ: REQ-MVC-001 REQ-MVC-004
(deftest test-REQ-MVC-001-get-snapshot-candidate-older-than-limit
  (dolist (pair '((6 7) (4294967294 4294967295) (4294967295 4294967296)
                  (9223372036854775807 9223372036854775808)))
    (get-lifecycle-snapshot-csn (first pair) (second pair) :candidate)))

;;; GET-D03 — REQ: REQ-MVC-001 REQ-MVC-004
(deftest test-REQ-MVC-001-get-snapshot-candidate-equal-to-limit
  (dolist (csn '(7 4294967295 4294967296 9223372036854775808))
    (get-lifecycle-snapshot-csn csn csn :candidate)))

;;; GET-D03 — REQ: REQ-MVC-001 REQ-MVC-004
(deftest test-REQ-MVC-001-get-snapshot-newer-candidate-requires-history
  (dolist (pair '((8 7) (4294967296 4294967295) (4294967297 4294967296)
                  (9223372036854775809 9223372036854775808)))
    (get-lifecycle-snapshot-csn (first pair) (second pair) :history-required)))

;;; GET-D03 — REQ: REQ-MVC-005 REQ-IDX-001
(deftest test-REQ-MVC-005-get-current-high-csn-remains-candidate
  (dolist (csn '(4294967295 4294967296 9223372036854775808))
    (with-get-fixture (f (:cache-p nil :csn csn))
      (is (eq :candidate (get-start f)))
      (is (eq :segment (get-load f)))
      (is (equalp (get-fixture-value f) (get-copy-found f))))))

;;; GET-D09 — REQ: REQ-MVC-004 REQ-AFF-002 REQ-CMP-007
(deftest test-REQ-MVC-004-get-copy-is-private-until-final-confirmation
  (with-get-fixture (f (:cache-p nil))
    (let ((output (get-zeros 9 #xee)))
      (is (eq :candidate (get-start f)))
      (is (eq :segment (get-load f)))
      (is (= 5 (copia-valore-get (get-fixture-context f) output 2)))
      (is (equalp (get-bytes #xee #xee #xa1 #x01 #x02 #xee #xee #xee #xee) output))
      (is (eq :copied (stato-contesto-get (get-fixture-context f))))
      (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
      (is (equal '(:found 3) (multiple-value-list (concludi-get (get-fixture-context f) 12))))
      (get-check-idle f))))

;;; GET-D02/D09 — REQ: REQ-IDX-001 REQ-CMP-007
(deftest test-REQ-IDX-001-get-candidate-copy-has-independent-storage
  (with-get-fixture (f (:cache-p nil))
    (let ((output (make-array 5 :element-type '(unsigned-byte 64) :initial-element 99))
          (second-output (make-array 5 :element-type '(unsigned-byte 64) :initial-element 77)))
      (is (eq :candidate (get-start f)))
      (is (null (copia-candidato-get (get-fixture-context f) output)))
      (is (= 7 (aref output 0)))
      (is (= #x1100000040 (aref output 1)))
      (is (= 30 (aref output 3)))
      (let ((known-copy (copy-seq output)))
        (fill output 0)
        (is (null (copia-candidato-get (get-fixture-context f) second-output)))
        (is (equalp known-copy second-output)))
      (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
      (abbandona-get (get-fixture-context f))
      (get-check-idle f))))

;;; GET-D02/D09 — REQ: REQ-CON-004 REQ-IDX-001
(deftest test-REQ-CON-004-get-candidate-alias-preserves-existing-pin
  (with-get-fixture (f (:cache-p nil))
    (let ((before (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0))
          (after (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0)))
      (is (eq :candidate (get-start f)))
      (copia-candidato-get (get-fixture-context f) before)
      (signals invalid-argument
        (copia-candidato-get (get-fixture-context f) (g::contesto-get-content (get-fixture-context f)))
        :get-candidate-alias)
      (is (eq :candidate (stato-contesto-get (get-fixture-context f))))
      (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
      (copia-candidato-get (get-fixture-context f) after)
      (is (equalp before after))
      (abbandona-get (get-fixture-context f))
      (get-check-idle f))))

;;; GET-D09 — REQ: REQ-AFF-008 REQ-CMP-007
(deftest test-REQ-AFF-008-get-output-range-error-releases-epoch
  (dolist (case '(:insufficient :past-end))
    (with-get-fixture (f (:cache-p nil))
      (let* ((output (get-zeros 2 #xee)) (before (copy-seq output)) (authorized nil))
        (is (eq :candidate (get-start f)))
        (is (eq :segment (get-load f)))
        (if (eq case :insufficient)
            (signals invalid-argument
              (progn (copia-valore-get (get-fixture-context f) output 0) (setf authorized t))
              :get-output-range)
            (signals invalid-argument
              (progn (copia-valore-get (get-fixture-context f) output 3) (setf authorized t))
              :buffer-range))
        (is (null authorized))
        (is (equalp before output))
        (get-check-idle f)))))

;;; GET-D09 — REQ: REQ-CON-004 REQ-CMP-007
(deftest test-REQ-CON-004-get-output-alias-error-releases-epoch
  (dolist (alias '(:key :bytes :proof))
    (with-get-fixture (f (:cache-p nil))
      (is (eq :candidate (get-start f)))
      (is (eq :segment (get-load f)))
      ;; Privati usati solo come output alias vietati; byte attesi dall'input.
      (let* ((output (ecase alias
                       (:key (get-fixture-key f))
                       (:bytes (g::contesto-get-bytes (get-fixture-context f)))
                       (:proof (g::contesto-get-proof (get-fixture-context f)))))
             (before (copy-seq output)) (authorized nil))
        (signals invalid-argument
          (progn (copia-valore-get (get-fixture-context f) output 0) (setf authorized t))
          :get-output-alias)
        (is (null authorized))
        (is (equalp before output))
        (get-check-idle f)))))

;;; GET-D09 — REQ: REQ-MVC-004 REQ-CMP-007
(deftest test-REQ-MVC-004-get-final-expiry-after-value-copy
  (with-get-fixture (f (:cache-p nil))
    (is (equal '(1 7 t) (multiple-value-list (get-register-snapshot f))))
    (let ((output (get-zeros 3 #xee)) (authorized nil))
      (is (eq :candidate (get-start f :snapshot (get-fixture-snapshot f) :generation 1)))
      (is (eq :segment (get-load f)))
      (is (= 3 (copia-valore-get (get-fixture-context f) output 0)))
      (is (equalp (get-fixture-value f) output))
      (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
      (signals snapshot-too-old
        (progn (concludi-get (get-fixture-context f) 30) (setf authorized t)) :snapshot-age-expired)
      (is (null authorized))
      (get-check-idle f))))

;;; GET-D09 — REQ: REQ-MVC-004 REQ-CMP-007
(deftest test-REQ-MVC-004-get-final-termination-after-value-copy
  (with-get-fixture (f (:cache-p nil))
    (is (equal '(1 7 t) (multiple-value-list (get-register-snapshot f))))
    (let ((output (get-zeros 3 #xee)) (authorized nil))
      (is (eq :candidate (get-start f :snapshot (get-fixture-snapshot f) :generation 1)))
      (is (eq :segment (get-load f)))
      (is (= 3 (copia-valore-get (get-fixture-context f) output 0)))
      (is (equalp (get-fixture-value f) output))
      (is (ebr:epoca-attiva-p (get-fixture-epoch f)))
      (mvcc:termina-snapshot (get-fixture-snapshot f) 1)
      (signals snapshot-too-old
        (progn (concludi-get (get-fixture-context f) 12) (setf authorized t)) :snapshot-ended)
      (is (null authorized))
      (get-check-idle f))))

;;; GET-D09 — REQ: REQ-CON-004 REQ-MVC-004 REQ-CMP-007
(deftest test-REQ-CON-004-get-clock-regression-after-value-copy
  (dolist (snapshot-p '(nil t))
    (with-get-fixture (f (:cache-p nil))
      (when snapshot-p (get-register-snapshot f))
      (let ((output (get-zeros 3 #xee)) (authorized nil))
        (is (eq :candidate (get-start f :snapshot (when snapshot-p (get-fixture-snapshot f))
                                    :generation (if snapshot-p 1 0))))
        (is (eq :segment (get-load f)))
        (is (= 3 (copia-valore-get (get-fixture-context f) output 0)))
        (is (equalp (get-fixture-value f) output))
        (signals invalid-argument
          (progn (concludi-get (get-fixture-context f) 10) (setf authorized t)) :read-clock-regression)
        (is (null authorized))
        (get-check-idle f)))))

;;; GET-D09 — REQ: REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-AFF-004-get-fi-empty-value-range-faults
  (with-get-fixture (f (:cache-p nil))
    (is (eq :candidate (get-start f)))
    (is (eq :segment (get-load f)))
    ;; FI: la chiave nota misura tre byte, il valore inizia al byte 27.
    (setf (g::contesto-get-value-start (get-fixture-context f)) 27
          (g::contesto-get-value-end (get-fixture-context f)) 27)
    (let ((output (get-zeros 3 #xee)) (authorized nil))
      (signals invariant-violation
        (progn (copia-valore-get (get-fixture-context f) output 0) (setf authorized t)) :get-value-range)
      (is (null authorized))
      (is (equalp (get-bytes #xee #xee #xee) output))
      (get-check-faulted f)
      (abbandona-get (get-fixture-context f))
      (get-check-faulted f))))

;;; GET-D09 — REQ: REQ-AFF-004 REQ-CMP-007
(deftest test-REQ-AFF-004-get-fi-value-overflow-faults
  (with-get-fixture (f (:cache-p nil :record-bytes 128))
    (is (eq :candidate (get-start f)))
    (is (eq :segment (get-load f)))
    ;; FI del solo range locale, oltre la capacità pubblicamente configurata.
    (setf (g::contesto-get-value-end (get-fixture-context f)) 129)
    (let ((output (get-zeros 3 #xee)) (authorized nil))
      (signals invariant-violation
        (progn (copia-valore-get (get-fixture-context f) output 0) (setf authorized t)) :get-value-overflow)
      (is (null authorized))
      (is (equalp (get-bytes #xee #xee #xee) output))
      (get-check-faulted f)
      (abbandona-get (get-fixture-context f))
      (get-check-faulted f))))

;;; GET-D09 — REQ: REQ-AFF-003 REQ-CMP-007
(deftest test-REQ-AFF-003-get-external-error-after-copy-cleans-owner
  (with-get-fixture (f (:cache-p nil))
    (let ((output nil))
      (signals get-lifecycle-abort
        (unwind-protect
             (progn
               (setf output (get-lifecycle-copy f))
               (error 'get-lifecycle-abort))
          (abbandona-get (get-fixture-context f))))
      (is (equalp (get-fixture-value f) output))
      (get-check-idle f)
      (is (eq :candidate (get-start f :now 13)))
      (abbandona-get (get-fixture-context f))
      (get-check-idle f))))

;;; GET-D09 — REQ: REQ-AFF-003 REQ-CMP-007
(deftest test-REQ-AFF-003-get-external-throw-after-copy-cleans-owner
  (with-get-fixture (f (:cache-p nil))
    (let ((output nil) (authorized nil))
      (setf authorized
            (eq :found
                (catch 'get-lifecycle-stop
                  (unwind-protect
                       (progn
                         (setf output (get-lifecycle-copy f))
                         (throw 'get-lifecycle-stop :abandoned))
                    (abbandona-get (get-fixture-context f))))))
      (is (null authorized))
      (is (equalp (get-fixture-value f) output))
      (get-check-idle f))))
