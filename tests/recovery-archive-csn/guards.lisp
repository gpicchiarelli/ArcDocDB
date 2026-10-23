;;;; FI seriali, distinte dai replay positivi; nessun writer o worker durante le sostituzioni.
;;; OWNER: runner seriale dopo i join nativi; cleanup FDEFINITION anche dopo l'errore.
;;; SHARED: nessuna primitiva CL sostituita, nessuna istanza valida del prodotto mutata.
;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-TXM-005 REQ-AFF-008 REQ-AFF-009
(in-package #:arcdocdb.recovery.archive.csn.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun acrg-with-function (name replacement thunk)
  (let ((original (fdefinition name)))
    (unwind-protect
         (progn (setf (fdefinition name) replacement) (funcall thunk))
      (setf (fdefinition name) original))))

(defun acrg-positive (f)
  (let ((plan (acr-plan f)))
    (is (equal '(nil 0) (multiple-value-list (ac:massimo-csn-archivio plan))))
    (acr-noeffects f) plan))

(deftest test-REQ-AFF-009-ARCHIVE-CSN-GUARDS-result-consumption
  (acr-with-fixture
   (lambda (f)
     (let ((original (fdefinition 'ac::verifica-piano-csn-preflight)))
       (acrg-with-function 'ac::verifica-piano-csn-preflight
         (lambda (&rest args) (1+ (apply original args)))
         (lambda () (acr-expect 'invariant-violation :archive-csn-result (lambda () (acr-plan f))))))
     (acr-noeffects f) (acrg-positive f))))

(deftest test-REQ-AFF-009-ARCHIVE-CSN-GUARDS-result-absence-requires-zero
  (acr-with-fixture
   (lambda (f)
     (let ((original (fdefinition 'da:massimo-csn-decisioni-recuperate)))
       (acrg-with-function 'da:massimo-csn-decisioni-recuperate
         (lambda (source)
           (multiple-value-bind (present maximum) (funcall original source)
             (is (null present)) (is (zerop maximum)) (values nil 1)))
         (lambda () (acr-expect 'invariant-violation :archive-csn-result (lambda () (acr-plan f))))))
     (acr-noeffects f) (acrg-positive f))))

(deftest test-REQ-AFF-009-ARCHIVE-CSN-GUARDS-decision-lifetime-rechecked-after-series
  (acr-with-fixture
   (lambda (f)
     (let ((original (fdefinition 'cr:massimo-csn-serie-recuperata)) (returned nil) (calls 0))
       (acrg-with-function 'cr:massimo-csn-serie-recuperata
         (lambda (&rest args)
           (multiple-value-prog1 (apply original args)
             (incf calls) (io:chiudi (acr-fixture-decision-input f))))
         (lambda () (acr-expect 'io-fault :io-unavailable
                      (lambda () (setf returned (acr-plan f))))))
       (is (= calls 1)) (is (null returned))
       (is (eq :closed (io:stato-file (acr-fixture-decision-input f))))
       (is (= 1 (length (acr-events f)))) (is (eq :close (caar (acr-events f)))))
     (acr-clear f) (acr-noeffects f))))

(deftest test-REQ-AFF-009-ARCHIVE-CSN-GUARDS-decision-shape-before-maximum
  ;; Costruttori privati solo per guasti di forma irraggiungibili dal replay canonico.
  (dolist (fact '((0 0 :decision-entry-count) (1 16 :decision-entry-count)
                  (2 31 :decision-entry-size) (2 33 :decision-entry-size)))
    (destructuring-bind (count bytes reason) fact
      (let* ((entry (arcdocdb.recovery.decisions::%make-decision-entry 1 7 count (ct::crr-bytes bytes) 64))
             (table (arcdocdb.recovery.decisions::%make-decision-table (vector entry))))
        (acr-expect 'invariant-violation reason
          (lambda () (arcdocdb.recovery.decisions:massimo-csn-decisioni table))))))
  (let ((table (arcdocdb.recovery.decisions::%make-decision-table (vector nil))))
    (acr-expect 'type-error nil (lambda () (arcdocdb.recovery.decisions:massimo-csn-decisioni table)))))

(deftest test-REQ-AFF-008-ARCHIVE-CSN-GUARDS-private-constructors-and-query-types
  (acr-with-fixture
   (lambda (f)
     (let ((args (list (acr-fixture-archive f) 1 1 nil 0)))
       (dolist (fact '((0 nil) (1 -1) (2 -1) (3 1) (4 -1) (4 #x10000000000000000)))
         (let ((invalid (copy-list args)))
           (setf (nth (first fact) invalid) (second fact))
           (acr-expect 'type-error nil (lambda () (apply #'acr-invoke 'ac::%make-piano-csn-archivio invalid))))))
     (dolist (args (list (list nil #()) (list (acr-fixture-archive f) nil)))
       (acr-expect 'type-error nil
         (lambda () (apply #'acr-invoke 'ac::%make-insieme-serie-recovery args))))
     (dolist (name '(ac:numero-serie-recovery ac:massimo-csn-archivio ac:statistiche-piano-csn-archivio
                    ac:parole-base-csn-archivio))
       (dolist (bad (list nil #() (acr-fixture-decisions f)))
         (acr-expect 'type-error nil (lambda () (acr-invoke name bad)))))
     (acr-noeffects f) (acrg-positive f))))

(deftest test-REQ-AFF-009-ARCHIVE-CSN-GUARDS-closed-state-and-prefix-delegated
  ;; Wrapper incoerente forgiato solo per FI: i risultati positivi provengono dai reader.
  (dolist (version '(1 2))
    (acr-with-fixture
     (lambda (f)
       (dolist (fact '((9 64) (2 63) (2 65)))
         (destructuring-bind (id prefix) fact
           (let ((bad (cr::%make-closed-recuperato
                       (aref (acr-fixture-controls f) 0)
                       (aref (aref (acr-fixture-closed-inputs f) 0) 0)
                       id prefix version 1 0 0 0 0 0 0 nil 0)))
             (acr-expect 'invalid-argument :closed-recovery-set-prefix
               (lambda () (ac:crea-piano-csn-archivio (acr-fixture-set f) (acr-fixture-decisions f)
                            (acr-fixture-active f) (vector (vector bad))))))))
       (is (equal '(nil 0) (multiple-value-list (ac:massimo-csn-archivio (acr-plan f)))))
       (acr-noeffects f))
     :version version :series (list (acr-serie 1 :closed (list (acr-closed 2)))))))
