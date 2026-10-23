;;;; Costruzione ACTIVE: attese wire/payload indipendenti, rifiuti prima del CSN.
(in-package #:arcdocdb.get.active.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defun active-preflight-witness (fixture batch)
  "Stato precedente al solo ingresso OPEN: byte, token, frontiere e ring."
  (let ((controller (af-controller fixture)))
    (list (copy-seq (w::lotto-buffer batch)) (w:lunghezza-lotto batch)
          (w::lotto-count batch) (w:stato-lotto batch) (w:stato-csn-lotto batch)
          (multiple-value-list (arcdocdb.csn:leggi-frontiere-csn (af-registry fixture)))
          (s::controllore-serie-planned-root controller) (s:leggi-radice-serie controller)
          (multiple-value-list (s:conta-commit-serie controller (af-lease fixture)))
          (s::controllore-serie-next-offset controller) (s::controllore-serie-event-generation controller)
          (io:posizione-scritta (af-append fixture)) (io:posizione-durevole (af-append fixture)))))
(defun active-open-unchanged-p (fixture batch before)
  (let ((after (active-preflight-witness fixture batch)))
    (and (equalp before after) (eq (seventh before) (seventh after))
         (eq (eighth before) (eighth after)) (active-no-effects-p fixture)
         (eq :healthy (s:stato-controllore-serie (af-controller fixture)))
         (active-clean-p fixture))))

(defun active-construction-graph-witness (directory)
  "Quattro livelli: riferimenti dei nodi e righe PUT, esclusivamente witness di persistenza."
  (let ((result nil))
    (labels ((walk (node depth)
               (when node
                 (push (cons node (copy-seq node)) result)
                 (dotimes (i 16)
                   (let ((child (svref node i)))
                     (when child
                       (if (< depth 3) (walk child (1+ depth))
                           (let ((rows (r::mappa-segmento-get-rows child)))
                             (push (cons rows (copy-seq rows)) result)))))))))
      (walk directory 0))
    result))
(defun active-construction-graph-unchanged-p (witness)
  (every (lambda (pair)
           (and (= (length (car pair)) (length (cdr pair)))
                (loop for actual across (car pair) for expected across (cdr pair)
                      always (eql actual expected))))
         witness))

;;; REQ: REQ-WAL-006 REQ-FOR-001 REQ-AFF-008
(deftest test-REQ-FOR-001-active-source-configuration-identity-and-fd
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :batches nil :cache-p nil)
      (is (typep (active-create-source f :budget-payload 0) 'r:sorgente-get-attiva))
      (is (eq :input (io:mode-file (af-input f))))
      (is (eq :append (io:mode-file (af-append f))))
      (is (not (eq (af-input f) (af-append f))))
      (dolist (options '((:max-pages 0) (:max-pages 65537) (:max-puts 0)
                         (:batch-records 0) (:batch-bytes 55) (:budget-payload -1)))
        (signals invalid-argument (apply #'active-create-source f options) :active-configuration))
      ;; FI tipizzata della sola capacità header: FD/associazione/controller
      ;; restano quelli reali. Nessun secondo proprietario dell'append viene creato.
      (dolist (identity (list (list 0 18 version 1) (list 0 17 (if (= version 1) 2 1) 1)
                             (list 1 17 version 1) (list 0 17 version 2)))
        (let ((segment (g::%make-segmento-get (af-view f) (af-input f)
                                            (first identity) (second identity)
                                            (third identity) (fourth identity))))
          (signals invalid-argument
            (r:crea-sorgente-get-attiva (af-controller f) (af-lease f) segment
                                      :associazione-file (af-association f)) :active-source-identity)))
      (is (active-no-effects-p f))
      (io:chiudi (af-input f))
      (signals invalid-argument
        (r:crea-sorgente-get-attiva (af-controller f) (af-lease f) (af-segment f)) :active-source-file)
      (signals io-fault (active-create-source f) :io-unavailable)
      (is (active-no-effects-p f))
      (is (active-clean-p f)))))

;;; REQ: REQ-FOR-001 REQ-FOR-003 REQ-IDX-001 REQ-WAL-006
(deftest test-REQ-FOR-003-active-native-v1-v2-put-and-tombstone
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil
                            :batches '(((:kind :put) (:kind :tombstone))))
      ;; Header64 + PUT56 + TOMBSTONE40 + SEAL56, da piano letterale.
      (is (= 216 (af-end f)))
      (is (equalp #(64) (af-offsets f))) (is (equalp #(56) (af-sizes f)))
      (is (= 152 (length (aref (af-images f) 0))))
      (is (= 536 (r:payload-radice-get-attiva (aref (af-roots f) 0))))
      (is (equal '(:fixture-page 0) (r:contenuto-radice-get-attiva (aref (af-roots f) 0))))
      ;; Lettura raw distinta: confronta tutti i byte persistiti con l'oracolo,
      ;; senza ottenere un'attesa dal resolver o dalla directory costruita.
      (with-open-file (stream (af-path f) :direction :input :element-type '(unsigned-byte 8))
        (let ((header (active-octets 64)) (body (active-octets 152)))
          (is (= 64 (read-sequence header stream)))
          (is (= 152 (read-sequence body stream)))
          (is (equalp header (af-header f))) (is (equalp body (aref (af-images f) 0)))
          (is (eq :eof (read-byte stream nil :eof)))))
      (is (active-no-effects-p f))
      (is (active-clean-p f)))))

;;; REQ: REQ-IDX-001 REQ-AFF-008 REQ-WAL-005
(deftest test-REQ-IDX-001-active-tombstone-page-zero-puts
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :budget-payload 512
                            :batches '(((:kind :tombstone))))
      (is (= 160 (af-end f))) (is (zerop (length (af-keys f))))
      (let ((root (aref (af-roots f) 0)))
        (is (= 1 (r::radice-get-attiva-count root)))
        (is (zerop (r::radice-get-attiva-puts root)))
        (is (= 512 (r:payload-radice-get-attiva root)))
        (is (eq root (s:leggi-radice-serie (af-controller f)))))
      (is (active-no-effects-p f)) (is (active-clean-p f)))))

;;; REQ: REQ-WAL-005 REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-WAL-005-active-preflight-immutable-no-csn-or-io
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      (let* ((batch (active-make-batch f '((:kind :put) (:kind :tombstone))))
             (before (active-preflight-witness f batch)))
        (dotimes (repeat 2)
          (is (= 1 (r:verifica-capienza-get-attiva (af-source f) (af-lease f) batch nil))))
        (is (active-open-unchanged-p f batch before))
        (is (equal '(0 6 0 6) (sixth before)))
        (is (eq :libero (w:stato-csn-lotto batch)))))))

;;; REQ: REQ-AFF-008 REQ-IDX-001
(deftest test-REQ-AFF-008-active-first-payload-exact-one-short
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :budget-payload 536)
      (is (= 536 (r:payload-radice-get-attiva (aref (af-roots f) 0))))
      (is (active-clean-p f)))
    (with-active-fixture (f :version version :cache-p nil :batches nil :budget-payload 535)
      (let* ((batch (active-make-batch f '((:kind :put))))
             (before (active-preflight-witness f batch)))
        (signals resource-exhausted
          (r:verifica-capienza-get-attiva (af-source f) (af-lease f) batch nil) :active-payload-budget)
        (is (active-open-unchanged-p f batch before))))))

;;; REQ: REQ-AFF-008 REQ-IDX-001
(deftest test-REQ-AFF-008-active-second-payload-peak-exact-one-short
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :budget-payload 1072
                            :batches '(((:kind :put)) ((:kind :put))))
      (is (= 536 (r:payload-radice-get-attiva (aref (af-roots f) 0))))
      (is (= 560 (r:payload-radice-get-attiva (aref (af-roots f) 1))))
      (is (equalp #(64 176) (af-offsets f))) (is (= 288 (af-end f)))
      (is (active-clean-p f)))
    (with-active-fixture (f :version version :cache-p nil :budget-payload 1071)
      (let* ((batch (active-make-batch f '((:kind :put))))
             (previous (aref (af-roots f) 0)) (before (active-preflight-witness f batch)))
        (signals resource-exhausted
          (r:verifica-capienza-get-attiva (af-source f) (af-lease f) batch previous) :active-payload-budget)
        (is (active-open-unchanged-p f batch before))))))

;;; REQ: REQ-AFF-008 REQ-IDX-001
(deftest test-REQ-AFF-008-active-page-budget-exact-refuses-next
  (with-active-fixture (f :cache-p nil :max-pages 1)
    (let* ((batch (active-make-batch f '((:kind :tombstone))))
           (before (active-preflight-witness f batch)))
      (is (= 1 (r::radice-get-attiva-count (aref (af-roots f) 0))))
      (signals resource-exhausted
        (r:verifica-capienza-get-attiva (af-source f) (af-lease f) batch (aref (af-roots f) 0))
        :active-page-budget)
      (is (active-open-unchanged-p f batch before)))))

;;; REQ: REQ-AFF-008 REQ-IDX-001
(deftest test-REQ-AFF-008-active-put-budget-exact-refuses-next
  (with-active-fixture (f :cache-p nil :max-puts 1)
    (let* ((batch (active-make-batch f '((:kind :put))))
           (before (active-preflight-witness f batch)))
      (is (= 1 (r::radice-get-attiva-puts (aref (af-roots f) 0))))
      (signals resource-exhausted
        (r:verifica-capienza-get-attiva (af-source f) (af-lease f) batch (aref (af-roots f) 0))
        :active-put-budget)
      (is (active-open-unchanged-p f batch before)))))

;;; REQ: REQ-AFF-008 REQ-WAL-005
(deftest test-REQ-AFF-008-active-record-byte-budgets-exact-one-short
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :max-batch-records 2 :max-batch-bytes 152
                            :batches '(((:kind :put) (:kind :tombstone))))
      (is (= 216 (af-end f))) (is (active-clean-p f)))
    (dolist (mode '(:records :bytes))
      (with-active-fixture (f :version version :cache-p nil :batches nil
                              :max-batch-records (if (eq mode :records) 1 2)
                              :max-batch-bytes (if (eq mode :bytes) 151 152))
        (let* ((batch (active-make-batch f '((:kind :put) (:kind :tombstone))))
               (before (active-preflight-witness f batch)))
          (signals resource-exhausted
            (r:verifica-capienza-get-attiva (af-source f) (af-lease f) batch nil)
            (if (eq mode :records) :active-batch-record-budget :active-batch-byte-budget))
          (is (active-open-unchanged-p f batch before)))))))

;;; REQ: REQ-FOR-004 REQ-WAL-005 REQ-MVC-008
(deftest test-REQ-FOR-004-active-prepared-outcome-refused-before-csn
  (dolist (version '(1 2))
    (dolist (kind '(:prepared :outcome))
      (with-active-fixture (f :version version :cache-p nil :batches nil)
        (let* ((batch (active-make-batch f (list (list :kind kind))))
               (before (active-preflight-witness f batch)))
          (signals invalid-argument
            (r:verifica-capienza-get-attiva (af-source f) (af-lease f) batch nil)
            (if (eq kind :prepared) :active-prepared-unsupported :active-outcome-unsupported))
          (is (active-open-unchanged-p f batch before)))))))

;;; REQ: REQ-IDX-001 REQ-CON-004 REQ-WAL-006
(deftest test-REQ-CON-004-active-roots-persist-after-public-batch-reuse
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil
                            :batches '(((:kind :put)) ((:kind :put))))
      (let* ((first (aref (af-roots f) 0)) (second (aref (af-roots f) 1))
             (directory (r::radice-get-attiva-directory first))
             (before (active-construction-graph-witness directory)))
        (active-reuse-through f 2)
        (dotimes (rank 2)
          (is (eq :open (w:stato-lotto (aref (af-batches f) rank))))
          (is (eq :libero (w:stato-csn-lotto (aref (af-batches f) rank))))
          (fill (w::lotto-buffer (aref (af-batches f) rank)) #xa5))
        (is (active-construction-graph-unchanged-p before))
        (is (eq second (s:leggi-radice-serie (af-controller f))))
        (is (= 176 (r::radice-get-attiva-end first))) (is (= 288 (r::radice-get-attiva-end second)))
        (is (eq :candidate (active-begin f 0)))
        (multiple-value-bind (segment end flags proof)
            (r:risolvi-candidato-attivo-get (af-context f) (af-source f))
          (is (eq segment (af-segment f))) (is (= 176 end))
          (is (zerop flags)) (is (null proof)))
        (is (equal '(:segment :disabled :not-attempted nil nil)
                   (multiple-value-list (r:leggi-record-attivo-get (af-context f) (af-source f)))))
        (is (active-copy-and-finish f 0))))))

;;; REQ: REQ-FOR-003 REQ-AFF-001 REQ-WAL-006
(deftest test-REQ-AFF-001-active-sealed-crc-faults-archive-preserves-cause
  (dolist (version '(1 2))
    (with-active-fixture (f :version version :cache-p nil :batches nil)
      (let ((batch (active-make-batch f '((:kind :put))))
            (condition-seen nil))
        (is (= 1 (r:verifica-capienza-get-attiva (af-source f) (af-lease f) batch nil)))
        (active-seal-batch f batch 64)
        ;; FI sul valore SEALED esclusivo del writer, prima di ogni dispatch.
        (setf (aref (w::lotto-buffer batch) 40) (logxor 1 (aref (w::lotto-buffer batch) 40)))
        (unwind-protect
             (handler-case
                 (r:registra-lotto-get-attivo (af-source f) (af-lease f) batch nil :crc-fi :group)
               (corruption-detected (condition)
                 (setf condition-seen condition)
                 (is (eq :body-crc (error-reason condition)))))
          ;; Nessun compito è mai stato consegnato: il caller conserva il token
          ;; pre-adozione e ne annulla esplicitamente il credito sul log terminale.
          (w:marca-log-faulted (af-controller-log f))
          (when (eq :pendente (w:stato-csn-lotto batch))
            (multiple-value-bind (slot high low) (w:leggi-csn-lotto batch)
              (w:annulla-csn-lotto batch (af-registry f) slot high low))))
        (is condition-seen)
        (is (eq :faulted (s:stato-controllore-serie (af-controller f))))
        (is (eq :archive (s:ambito-fault-serie (af-controller f))))
        (is (null (s::controllore-serie-root (af-controller f))))
        (is (null (s::controllore-serie-planned-root (af-controller f))))
        (is (equal '(0 0 0) (multiple-value-list (s:conta-commit-serie (af-controller f) (af-lease f)))))
        (is (eq :sealed (w:stato-lotto batch)))
        (is (active-no-effects-p f)) (is (active-clean-p f))))))
