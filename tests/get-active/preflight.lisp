;;;; Decisioni OPEN: rifiuti prima di CSN, adozione o I/O del nuovo lotto.
;;; OWNER: ogni test possiede fixture, lotti non adottati e FI dichiarate.
;;; SHARED: nessun dato mutato fuori dalla fixture; ripristino FI dopo il witness.
(in-package #:arcdocdb.get.active.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defun active-preflight-same-fields-p (before after)
  "Scalari per valore, capacità/radici per identità; niente EQUALP fra grafi."
  (and (= (length before) (length after)) (every #'eql before after)))

(defun active-preflight-batch-fields (batch)
  (list batch (w::lotto-kind batch) (w::lotto-file-id batch) (w::lotto-version batch)
        (w::lotto-buffer batch) (w::lotto-offsets batch) (w::lotto-seal-value batch)
        (w::lotto-empty-key batch) (w::lotto-used batch) (w::lotto-count batch)
        (w::lotto-start batch) (w::lotto-owner batch) (w::lotto-state batch)
        (w::lotto-csn-registry batch) (w::lotto-csn-log batch) (w::lotto-csn-slot batch)
        (w::lotto-csn-high batch) (w::lotto-csn-low batch) (w::lotto-csn-pending batch)))

(defun active-preflight-controller-fields (fixture)
  (let ((controller (af-controller fixture)))
    ;; La salute è verificata separatamente: i due guasti OPEN devono cambiarla.
    (list controller (af-lease fixture) (s::controllore-serie-registry controller)
          (s::controllore-serie-log controller) (s::controllore-serie-slots controller)
          (s::controllore-serie-root controller) (s::controllore-serie-planned-root controller)
          (s::controllore-serie-next-offset controller) (s::controllore-serie-owner controller)
          (s::controllore-serie-lease-generation controller)
          (s::controllore-serie-event-generation controller)
          (s::controllore-serie-last-high controller) (s::controllore-serie-last-low controller)
          (s::controllore-serie-head controller) (s::controllore-serie-tail controller)
          (s::controllore-serie-publish-head controller) (s::controllore-serie-count controller)
          (s::controllore-serie-unresolved controller) (s::controllore-serie-active-io controller)
          (s::controllore-serie-effect-active controller)
          (io:stato-file (af-input fixture)) (io:stato-file (af-append fixture))
          (io:posizione-scritta (af-append fixture)) (io:posizione-durevole (af-append fixture))
          (w::log-io-active (af-controller-log fixture))
          (w:stato-log (af-controller-log fixture)))))

(defun active-preflight-event-fields (event)
  (list event (s::commit-serie-controller event) (s::commit-serie-position event)
        (s::commit-serie-generation event) (s::commit-serie-lotto event)
        (s::commit-serie-slot event) (s::commit-serie-high event) (s::commit-serie-low event)
        (s::commit-serie-expected-root event) (s::commit-serie-root event)
        (s::commit-serie-level event) (s::commit-serie-phase event) (s::commit-serie-io-state event)))

(defun active-preflight-csn-image (registry)
  "Fixture seriale: anche la lettura privata degli slot rispetta il mutex del registro."
  (sb-thread:with-mutex ((arcdocdb.csn::registro-csn-mutex registry))
    (list
     (list registry (arcdocdb.csn::registro-csn-capacity registry)
           (arcdocdb.csn::registro-csn-highs registry) (arcdocdb.csn::registro-csn-lows registry)
           (arcdocdb.csn::registro-csn-used registry) (arcdocdb.csn::registro-csn-cursor registry)
           (arcdocdb.csn::registro-csn-last-high registry) (arcdocdb.csn::registro-csn-last-low registry)
           (arcdocdb.csn::registro-csn-horizon-high registry)
           (arcdocdb.csn::registro-csn-horizon-low registry))
     (copy-seq (arcdocdb.csn::registro-csn-highs registry))
     (copy-seq (arcdocdb.csn::registro-csn-lows registry)))))

(defun active-preflight-decision-image (fixture batch previous)
  "Attese di stato precedenti all'ingresso: byte/token, intero ring, credito e grafi."
  (let* ((controller (af-controller fixture))
         (roots (remove-duplicates
                 (append (list previous (s::controllore-serie-root controller)
                               (s::controllore-serie-planned-root controller))
                         (coerce (af-roots fixture) 'list)) :test #'eq)))
    (list :batch (active-preflight-batch-fields batch)
          :arrays (mapcar (lambda (array) (cons array (copy-seq array)))
                          (list (w::lotto-buffer batch) (w::lotto-offsets batch)
                                (w::lotto-seal-value batch) (w::lotto-empty-key batch)))
          :controller (active-preflight-controller-fields fixture)
          :ring (map 'list #'active-preflight-event-fields (s::controllore-serie-slots controller))
          :csn (active-preflight-csn-image (af-registry fixture))
          :graphs (loop for root in roots when (typep root 'r:radice-get-attiva)
                        collect (active-construction-graph-witness (r::radice-get-attiva-directory root))))))

(defun active-preflight-decision-unchanged-p (fixture batch before &key archive-fault-p)
  (let ((csn (active-preflight-csn-image (af-registry fixture)))
        (ring (map 'list #'active-preflight-event-fields
                   (s::controllore-serie-slots (af-controller fixture)))))
    (and (active-preflight-same-fields-p (getf before :batch) (active-preflight-batch-fields batch))
         (every (lambda (pair) (equalp (cdr pair) (car pair))) (getf before :arrays))
         (active-preflight-same-fields-p (getf before :controller)
                                         (active-preflight-controller-fields fixture))
         (= (length ring) (length (getf before :ring)))
         (every #'active-preflight-same-fields-p (getf before :ring) ring)
         (active-preflight-same-fields-p (first (getf before :csn)) (first csn))
         (equalp (second (getf before :csn)) (second csn))
         (equalp (third (getf before :csn)) (third csn))
         (every #'active-construction-graph-unchanged-p (getf before :graphs))
         (eq (if archive-fault-p :faulted :healthy) (s:stato-controllore-serie (af-controller fixture)))
         (eq (if archive-fault-p :archive :none) (s:ambito-fault-serie (af-controller fixture)))
         (active-no-effects-p fixture) (active-clean-p fixture))))

(defun active-preflight-check-positive (fixture batch previous puts)
  (let ((ordinary (active-preflight-witness fixture batch))
        (before (active-preflight-decision-image fixture batch previous)))
    ;; Nessun handler trasforma un errore inatteso in un'asserzione del test.
    (is (equal (list puts)
               (multiple-value-list
                (r:verifica-capienza-get-attiva (af-source fixture) (af-lease fixture) batch previous))))
    (is (active-open-unchanged-p fixture batch ordinary))
    (is (active-preflight-decision-unchanged-p fixture batch before)))
  t)

(defun active-preflight-check-refusal (fixture batch previous type reason &key archive-fault-p thunk)
  "Osserva causa e stato prima del cleanup esterno; il thunk serve al contratto locale di spazio."
  (let ((before (active-preflight-decision-image fixture batch previous))
        (first-condition nil) (caught nil))
    (handler-case
        (handler-bind ((arcdocdb.conditions:arcdocdb-error
                        (lambda (condition)
                          (when (and (null first-condition) (typep condition type))
                            (setf first-condition condition)))))
          (if thunk (funcall thunk)
              (r:verifica-capienza-get-attiva (af-source fixture) (af-lease fixture) batch previous)))
      (arcdocdb.conditions:arcdocdb-error (condition)
        ;; IO-FAULT e ogni classe inattesa rimangono condizioni del prodotto/runtime,
        ;; senza convertirle in un falso kill tramite IS.
        (if (typep condition type) (setf caught condition) (error condition))))
    (is (typep caught type)) (is (eq first-condition caught))
    (is (eq reason (error-reason caught)))
    (is (active-preflight-decision-unchanged-p fixture batch before :archive-fault-p archive-fault-p)))
  t)

(defun active-preflight-identity-batch (fixture file-id version)
  "Identità alternativa via API WAL pubblica; nessuna mutazione degli slot read-only."
  (declare (ignore fixture))
  (let ((batch (w:crea-lotto :segment file-id :version version :capacity 112 :max-records 1)))
    (w:aggiungi-record batch 1 (active-key 0) (active-value 0))
    batch))

(defun active-preflight-dispose-sealed (fixture batch)
  "Solo dopo witness: lotto mai adottato, nessun consumatore; annullamento esplicito del caller."
  (when (eq :pendente (w:stato-csn-lotto batch))
    (s:fault-controllore-serie (af-controller fixture) (af-lease fixture))
    (w:marca-log-faulted (af-controller-log fixture))
    (multiple-value-bind (slot high low) (w:leggi-csn-lotto batch)
      (w:annulla-csn-lotto batch (af-registry fixture) slot high low)))
  nil)

;;; REQ: REQ-WAL-005 REQ-FOR-001 REQ-MVC-008
(deftest test-REQ-WAL-005-active-preflight-batch-file-id
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      ;; TT e FT: versione e byte validi in entrambi, cambia soltanto file-id.
      (active-preflight-check-positive f (active-preflight-identity-batch f 17 version) nil 1)
      (active-preflight-check-refusal f (active-preflight-identity-batch f 18 version) nil
                                      'invalid-argument :active-batch-identity))))

;;; REQ: REQ-WAL-005 REQ-FOR-001 REQ-MVC-008
(deftest test-REQ-WAL-005-active-preflight-batch-version
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      ;; TT e TF: file-id canonico; entrambi i lotti sono validi nel proprio formato.
      (active-preflight-check-positive f (active-preflight-identity-batch f 17 version) nil 1)
      (active-preflight-check-refusal f (active-preflight-identity-batch f 17 (if (= version 1) 2 1)) nil
                                      'invalid-argument :active-batch-identity))))

;;; REQ: REQ-WAL-005 REQ-MVC-008
(deftest test-REQ-WAL-005-active-preflight-empty-open
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      (active-preflight-check-refusal f (active-make-batch f nil) nil
                                      'invalid-argument :active-open-empty))))

;;; REQ: REQ-WAL-005 REQ-MVC-008 REQ-AFF-004
(deftest test-REQ-WAL-005-active-preflight-open-token-bound
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      (let ((batch (active-make-batch f '((:kind :put)))))
        (active-seal-batch f batch 64)
        (unwind-protect
             (progn
               ;; FI tipizzata: token reale ancora pendente, solo stato locale riportato OPEN.
               (setf (w::lotto-state batch) :open)
               (is (eq :pendente (w:stato-csn-lotto batch)))
               (active-preflight-check-refusal f batch nil 'invalid-argument :active-open-bound))
          (setf (w::lotto-state batch) :sealed)
          (active-preflight-dispose-sealed f batch))))))

;;; REQ: REQ-WAL-005 REQ-MVC-008
(deftest test-REQ-WAL-005-active-preflight-sealed-refused-with-token-preserved
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      (let ((batch (active-make-batch f '((:kind :put)))))
        (active-seal-batch f batch 64)
        (unwind-protect
             (progn
               (active-preflight-check-refusal f batch nil 'invalid-argument :lotto-state)
               (is (eq :sealed (w:stato-lotto batch)))
               (is (eq :pendente (w:stato-csn-lotto batch))))
          (active-preflight-dispose-sealed f batch))))))

;;; REQ: REQ-WAL-005 REQ-CON-004
(deftest test-REQ-WAL-005-active-preflight-previous-order
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil
                            :batches '(((:kind :put)) ((:kind :put))))
      (with-active-fixture (foreign :version version :cache-p nil)
        (let ((batch (active-make-batch f '((:kind :put))))
              (current (aref (af-roots f) 1)))
          (active-preflight-check-positive f batch current 1)
          (dolist (previous (list (aref (af-roots f) 0) (aref (af-roots foreign) 0)))
            (active-preflight-check-refusal f batch previous 'invalid-argument :active-root-order)))))))

;;; REQ: REQ-WAL-005 REQ-AFF-008 REQ-MVC-008
(deftest test-REQ-AFF-008-active-preflight-ring-full
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :publish-count 0
                            :batches (make-list 8 :initial-element '((:kind :put))))
      (let ((batch (active-make-batch f '((:kind :put)))) (previous (aref (af-roots f) 7)))
        ;; Otto eventi reali in otto slot; nessuna FI della geometria del ring.
        (is (= 8 (s::controllore-serie-count (af-controller f))))
        (active-preflight-check-refusal f batch previous 'resource-exhausted :serie-full)
        (active-publish-through f 1) (active-reuse-through f 1)
        (active-clear-effects f)
        (is (= 7 (s::controllore-serie-count (af-controller f))))
        (active-preflight-check-positive f batch previous 1)))))

;;; REQ: REQ-WAL-005 REQ-AFF-008 REQ-MVC-008
(deftest test-REQ-AFF-008-active-preflight-event-generation-bound
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      (let* ((controller (af-controller f)) (generation (s::controllore-serie-event-generation controller))
             (batch (active-make-batch f '((:kind :put)))))
        (unwind-protect
             (progn
               ;; FI del solo contatore tipizzato; ring vuoto e lease restano validi.
               (setf (s::controllore-serie-event-generation controller) (1- most-positive-fixnum))
               (active-preflight-check-positive f batch nil 1)
               (setf (s::controllore-serie-event-generation controller) most-positive-fixnum)
               (active-preflight-check-refusal f batch nil 'resource-exhausted :serie-event-generation))
          (setf (s::controllore-serie-event-generation controller) generation))))))

;;; REQ: REQ-WAL-005 REQ-IDX-001 REQ-MVC-008
(deftest test-REQ-WAL-005-active-preflight-contiguous-offset
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil)
      (let* ((controller (af-controller f)) (start (s::controllore-serie-next-offset controller))
             (previous (aref (af-roots f) 0)) (batch (active-make-batch f '((:kind :put)))))
        (active-preflight-check-positive f batch previous 1)
        (unwind-protect
             (progn
               ;; FI locale: contiguità falsa pur restando nello spazio segmento.
               (setf (s::controllore-serie-next-offset controller) (1+ start))
               (active-preflight-check-refusal f batch previous 'invalid-argument :active-root-frontier))
          (setf (s::controllore-serie-next-offset controller) start))))))

;;; REQ: REQ-WAL-005 REQ-AFF-008
(deftest test-REQ-AFF-008-active-preflight-segment-space
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      (let ((batch (active-make-batch f '((:kind :put)))))
        (is (= 56 (w:lunghezza-lotto batch)))
        ;; Contratto LOCALE di misura: start è esplicito, non una radice pubblicata
        ;; fittizia e non un file nativo da 4 GiB. Header64, PUT56, SEAL56, max u32.
        (dolist (start (list 64 (- #xffffffff 112)))
          (let ((before (active-preflight-decision-image f batch nil)))
            (is (null (r::verifica-misure-aperte-attive (af-source f) batch start)))
            (is (active-preflight-decision-unchanged-p f batch before))))
        (dolist (start (list 63 (1+ (- #xffffffff 112))))
          (active-preflight-check-refusal
           f batch nil 'resource-exhausted :active-segment-budget
           :thunk (lambda () (r::verifica-misure-aperte-attive (af-source f) batch start))))))))

;;; REQ: REQ-WAL-005 REQ-AFF-008 REQ-MVC-008
(deftest test-REQ-AFF-008-active-preflight-record-boundary
  (dolist (version '(1 2))
    (dolist (limit '(2 1))
      (with-active-fixture (f :version version :cache-p nil :batches nil :max-batch-records limit)
        (let ((batch (active-make-batch f '((:kind :put) (:kind :tombstone)))))
          (is (= 2 (w::lotto-count batch))) (is (= 96 (w:lunghezza-lotto batch)))
          (if (= limit 2)
              (active-preflight-check-positive f batch nil 1)
              (active-preflight-check-refusal f batch nil 'resource-exhausted :active-batch-record-budget)))))))

;;; REQ: REQ-WAL-005 REQ-AFF-008 REQ-MVC-008
(deftest test-REQ-AFF-008-active-preflight-seal-byte-boundary
  (dolist (version '(1 2))
    (dolist (limit '(112 111))
      (with-active-fixture (f :version version :cache-p nil :batches nil :max-batch-bytes limit)
        (let ((batch (active-make-batch f '((:kind :put)))))
          ;; Oracolo wire letterale: 24+16+16 body e 56 SEAL, non size del resolver.
          (is (= 56 (w:lunghezza-lotto batch)))
          (if (= limit 112)
              (active-preflight-check-positive f batch nil 1)
              (active-preflight-check-refusal f batch nil 'resource-exhausted :active-batch-byte-budget)))))))

;;; REQ: REQ-WAL-005 REQ-FOR-003 REQ-AFF-001 REQ-MVC-008
(deftest test-REQ-AFF-001-active-preflight-header-corruption-faults-archive
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      (let ((batch (active-make-batch f '((:kind :put)))))
        ;; OPEN esclusivo, FI del solo CRC header: la prima causa resta :header-crc.
        (setf (aref (w::lotto-buffer batch) 0) (logxor 1 (aref (w::lotto-buffer batch) 0)))
        (active-preflight-check-refusal f batch nil 'corruption-detected :header-crc :archive-fault-p t)
        (is (eq :libero (w:stato-csn-lotto batch)))))))

;;; REQ: REQ-WAL-005 REQ-AFF-001 REQ-AFF-004 REQ-MVC-008
(deftest test-REQ-AFF-001-active-preflight-open-count-faults-archive
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      (let ((batch (active-make-batch f '((:kind :put) (:kind :put)))))
        ;; FI tipizzata: due record validi ma count uno; il primo avanza 56 byte,
        ;; poi la frontiera112 smentisce il count. Nessuna falsa prova di progress=0:
        ;; checked-header conforme avanza almeno24 e quella difesa resta distinta.
        (setf (w::lotto-count batch) 1)
        (active-preflight-check-refusal f batch nil 'invariant-violation :active-open-count
                                        :archive-fault-p t)
        (is (eq :libero (w:stato-csn-lotto batch)))))))
