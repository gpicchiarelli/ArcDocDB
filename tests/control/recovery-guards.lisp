;;;; Guardie residue del report CONTROL: prove private, deliberatamente fuori contratto.
;;; OWNER: runner seriale; dati canonici da lettura pubblica, nessuna capacità forgiata usata per I/O.
;;; SHARED: nessuna sostituzione globale, nessun worker o scrittura persistente.
;;; Non si caricano nuovamente i sorgenti per colorare IN-PACKAGE/DECLAIM in SB-COVER.
;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-009
(in-package #:arcdocdb.control.tests)

(deftest test-REQ-AFF-008-CONTROL-recovery-private-read-rejects-zero-chunk
  (crr-with-fixture (crr-log 2)
    (lambda (f)
      (let ((scratch (crr-bytes 228 #xa5)))
        (crr-expect 'invalid-argument :control-recovery-chunk
          (lambda () (c::leggi-control-completo (crr-fixture-input f) 228 scratch 0)))
        (is (every (lambda (byte) (= byte #xa5)) scratch))
        (is (null (crr-events f)))
        (crr-noeffects f)))))

(deftest test-REQ-AFF-008-CONTROL-recovery-private-constructor-rejects-each-invalid-field
  ;; APPLY impedisce che un argomento letterale invalido sia rifiutato dal compilatore del test.
  ;; Un'istanza privata valida viene osservata solo come dati; non alimenta il publisher.
  (dolist (version '(1 2))
    (crr-with-fixture (crr-log version)
      (lambda (f)
        (let* ((actual (crr-success f version))
               (args (list (crr-fixture-view f) (crr-fixture-input f) (c:manifest-control-recuperato actual)
                           228 228 :complete version))
               (constructor (symbol-function 'c::%make-control-recuperato)))
          (crr-clear f)
          (dolist (case '((0 nil) (1 nil) (2 nil) (3 -1) (4 -1) (5 :invalid) (6 0) (6 3)))
            (let ((bad (copy-list args)))
              (setf (nth (first case) bad) (second case))
              (crr-expect 'type-error nil (lambda () (apply constructor bad)))))
          (dolist (status '(:complete :tail))
            (let* ((copy (copy-list args)) (prefix (if (eq status :complete) 228 227)))
              (setf (fifth copy) prefix (sixth copy) status)
              (is (equal (list 228 prefix status version)
                         (multiple-value-list (c:frontiere-control-recuperato (apply constructor copy)))))))
          (is (null (crr-events f))) (crr-noeffects f))))))
