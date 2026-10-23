;;;; Guardie relazionali interne; chiamate fredde opache al compilatore.
(in-package #:arcdocdb.hash64.tests)

(defun hash-helper-refusal (name arguments reason)
  (let* ((buffer (first arguments)) (before (copy-seq buffer))
         (function (symbol-function (find-symbol name "ARCDOCDB.HASH64"))))
    (is (handler-case (progn (apply function arguments) nil)
          (arcdocdb.conditions:invariant-violation (condition)
            (is (eq reason (error-reason condition))) t)))
    (is (equalp buffer before))))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-block-relational-guards
  (let ((buffer (hash-corpus-bytes 64)))
    (hash-helper-refusal "HASH-BLOCKS" (list buffer 0 31 0) :hash-block-span)
    (hash-helper-refusal "HASH-BLOCKS" (list buffer 33 32 0) :hash-block-span)))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(deftest test-REQ-IDX-001-hash-tail-relational-guards
  (let ((buffer (hash-corpus-bytes 64)))
    (hash-helper-refusal "HASH-TAIL" (list buffer 2 1 0) :hash-tail-span)
    (hash-helper-refusal "HASH-TAIL" (list buffer 0 65 0) :hash-tail-span)
    (hash-helper-refusal "HASH-TAIL" (list buffer 0 32 0) :hash-tail-span)))
