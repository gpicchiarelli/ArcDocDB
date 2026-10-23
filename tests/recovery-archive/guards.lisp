;;;; Guardie difensive: FI seriale dei soli risultati delle dipendenze, sempre ripristinate.
;;; OWNER: runner dopo il join dei test precedenti; nessun worker attivo o nuovo nel perimetro.
;;; SHARED: FDEFINITION globale sostituita solo nell'estensione dinamica seriale della FI.
;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-009
(in-package #:arcdocdb.recovery.archive.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun darg-with-function (name replacement thunk)
  "Nessuna mutazione della capacità; il cleanup ripristina la dipendenza anche dopo un errore."
  (let ((original (fdefinition name)))
    (unwind-protect
         (progn (setf (fdefinition name) replacement) (funcall thunk))
      (setf (fdefinition name) original))))

(deftest test-REQ-AFF-008-ARCHIVE-GUARDS-body-compound-conditions-and-empty-body
  (dar-with-input (dar-log nil)
    (lambda (f)
      (dolist (pair '((0 64) (1 63)))
        (dar-expect 'invalid-argument :archive-recovery-read-range
          (lambda () (da::leggi-corpo-decisioni (dar-fixture-input f) (second pair)
                       (dar-fixture-scratch f) (first pair)))))
      (is (null (da::leggi-corpo-decisioni (dar-fixture-input f) 64 (dar-fixture-scratch f) 1)))
      (darr-events f nil) (dar-noeffects f))))

(deftest test-REQ-AFF-009-ARCHIVE-GUARDS-preflight-inconsistent-end-before-io
  (let ((original (fdefinition 'arcdocdb.recovery.scan::check-scan-arguments)))
    (dar-with-input (dar-log nil)
      (lambda (f)
        (darg-with-function 'arcdocdb.recovery.scan::check-scan-arguments
          (lambda (&rest args) (apply original args) 0)
          (lambda () (dar-expect 'invariant-violation :archive-recovery-preflight (lambda () (dar-call f)))))
        (darr-events f nil) (dar-noeffects f)
        (darr-success f 2 nil)))))

(deftest test-REQ-AFF-009-ARCHIVE-GUARDS-io-return-header-and-body-before-result
  (dolist (version '(1 2))
    (dolist (target '(0 64))
      (let ((original (fdefinition 'io:leggi-esatto)))
        (dar-with-input (darr-log version 1)
          (lambda (f)
            (darg-with-function 'io:leggi-esatto
              (lambda (input scratch start end offset)
                (if (= target offset) start (funcall original input scratch start end offset)))
              (lambda ()
                (if (zerop target)
                    (dar-expect 'invariant-violation :archive-recovery-header-read (lambda () (dar-call f)))
                    (dar-expect 'invariant-violation :archive-recovery-read (lambda () (dar-call f)) 64))))
            (darr-events f (if (zerop target) nil '((:read 401 0 64 0))))
            (dar-noeffects f)
            (dar-clear f) (darr-success f version (darr-specs))))))))

(deftest test-REQ-AFF-009-ARCHIVE-GUARDS-header-decoder-inconsistent-end
  (let ((original (fdefinition 'arcdocdb.storage.format:verifica-header-log)))
    (dar-with-input (darr-log 2 1)
      (lambda (f)
        (darg-with-function 'arcdocdb.storage.format:verifica-header-log
          (lambda (&rest args)
            (multiple-value-bind (next version) (apply original args)
              (is (= next 64)) (values 65 version)))
          (lambda () (dar-expect 'invariant-violation :archive-recovery-header (lambda () (dar-call f)))))
        (darr-events f '((:read 401 0 64 0))) (dar-noeffects f)
        (dar-clear f) (darr-success f 2 (darr-specs))))))

(deftest test-REQ-AFF-009-ARCHIVE-GUARDS-prefix-range-and-complete-tail-coherence
  (dolist (version '(1 2))
    (dolist (variant '(:below-header :beyond-eof :complete-short :tail-at-eof))
      (let ((original (fdefinition 'arcdocdb.recovery.decisions:ricostruisci-decisioni)))
        (dar-with-input (darr-log version 1)
          (lambda (f)
            (darg-with-function 'arcdocdb.recovery.decisions:ricostruisci-decisioni
              (lambda (&rest args)
                (multiple-value-bind (table prefix status) (apply original args)
                  (is (eq status :complete))
                  (ecase variant
                    (:below-header (values table 63 status))
                    (:beyond-eof (values table (1+ prefix) status))
                    (:complete-short (values table (1- prefix) status))
                    (:tail-at-eof (values table prefix :tail)))))
              (lambda () (dar-expect 'invariant-violation :archive-recovery-prefix (lambda () (dar-call f)))))
            (darr-events f (darr-requests (dar-fixture-size f) 65536 4096)) (dar-noeffects f)
            (dar-clear f) (darr-success f version (darr-specs))))))))

(deftest test-REQ-AFF-008-ARCHIVE-GUARDS-private-constructors-still-enforce-types
  (dar-with-input (dar-log nil)
    (lambda (f)
      (let* ((result (dar-call f))
             (args (list (dar-fixture-archive f) (dar-fixture-input f)
                         (da::decisioni-recuperate-table result) 64 64 :complete 2)))
        (dar-clear f)
        (dolist (entry '((0 nil) (1 nil) (2 nil) (3 -1) (4 -1) (5 :bad) (6 3)))
          (let ((invalid (copy-list args)))
            (setf (nth (first entry) invalid) (second entry))
            (dar-expect 'type-error nil
              (lambda () (apply #'dar-invoke 'da::%make-decisioni-recuperate invalid)))))
        (dolist (size '(15 17))
          (dar-expect 'type-error nil
            (lambda () (dar-invoke 'da::%make-archivio-recovery
                         (da::archivio-recovery-scope (dar-fixture-archive f)) (ct::crr-bytes size)))))
        (dar-expect 'type-error nil
          (lambda () (dar-invoke 'da::%make-archivio-recovery nil (dar-identity))))
        (darr-events f nil) (dar-noeffects f)))))
