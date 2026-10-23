(in-package #:arcdocdb.fulltext.admission.tests)

(deftest req-sec-010-reservation-last-index-refusal
  (let* ((first (d:crea-configurazione-full-text (dt::fields '((1 "subject" ("subject")))) 1 1 1))
         (configs (vector first (config 2))) (sources (sources configs))
         (queue (ex:crea-coda-writer :capacity 16)) (lease (ex:acquisisci-writer queue)))
    (unwind-protect
         (dolist (options (list (list :max-tokens 1)
                               (list :file-bytes (+ 144 (d:limite-fisso-indice-full-text (svref configs 1))))))
           (let ((pool (apply #'pool queue configs options)))
             (rejected (lambda () (f:prenota-full-text pool lease sources)) 'resource-exhausted)
             (is (unborrowed sources)) (is (equal '(0 0 0) (budget pool lease)))
             (is (zerop (f::riserve-full-text-generation pool)))
             (dotimes (i 2) (is (= (d:limite-fisso-indice-full-text (svref configs i))
                                  (f:leggi-bound-riserve-full-text pool lease i))))))
      (ex:rilascia-writer queue lease))))

(deftest req-sec-010-reservation-file-bounds-and-rotation
  (let* ((configs (vector (config 1))) (fixed (d:limite-fisso-indice-full-text (svref configs 0)))
         (queue (ex:crea-coda-writer :capacity 16)) (lease (ex:acquisisci-writer queue)))
    (unwind-protect
         (progn
           (let* ((pool (pool queue configs :file-bytes (+ fixed 144))) (sources (sources configs)))
             (rejected (lambda () (f:prenota-full-text pool lease sources)) 'resource-exhausted :fulltext-reservation-request-too-large)
             (is (unborrowed sources)) (is (equal '(0 0 0) (budget pool lease)))
             (is (= fixed (f:leggi-bound-riserve-full-text pool lease 0))))
           (let ((pool (pool queue configs :file-bytes (+ fixed 145))))
             (multiple-value-bind (slot generation) (f:prenota-full-text pool lease (sources configs))
               (complete pool lease slot generation)
               (is (= (+ fixed 145) (f:leggi-bound-riserve-full-text pool lease 0)))
               (let ((next (sources configs :row 1)))
                 (rejected (lambda () (f:prenota-full-text pool lease next)) 'resource-exhausted :fulltext-reservation-rotation)
                 (is (unborrowed next)) (is (equal '(73 73 1) (budget pool lease))))
               (f:annulla-riserva-full-text pool lease slot generation)
               (is (= fixed (f:leggi-bound-riserve-full-text pool lease 0))))))
      (ex:rilascia-writer queue lease))))

(deftest req-sec-010-reservation-cumulative-memory-budgets
  (let* ((queue (ex:crea-coda-writer :capacity 16)) (configs (configs)) (sources (sources configs))
         (lease (ex:acquisisci-writer queue)))
    (unwind-protect
         (progn
           (dolist (options '((:delta-bytes 145) (:staging-bytes 145)))
             (let ((pool (apply #'pool queue configs options)))
               (rejected (lambda () (f:prenota-full-text pool lease sources)) 'resource-exhausted)
               (is (unborrowed sources)) (is (equal '(0 0 0) (budget pool lease)))))
           (let ((pool (pool queue configs :delta-bytes 146 :staging-bytes 146)))
             (multiple-value-bind (slot generation) (f:prenota-full-text pool lease sources)
               (complete pool lease slot generation) (is (equal '(146 146 1) (budget pool lease)))
               (rejected (lambda () (f:prenota-full-text pool lease (sources configs :row 1))) 'resource-exhausted)
               (f:annulla-riserva-full-text pool lease slot generation)
               (is (equal '(0 0 0) (budget pool lease))))))
      (ex:rilascia-writer queue lease))))

(deftest req-sec-010-reservation-run-and-slot-budgets
  (let* ((queue (ex:crea-coda-writer :capacity 16)) (configs (configs)) (sources (sources configs))
         (lease (ex:acquisisci-writer queue)))
    (unwind-protect
         (progn
           (dolist (options '((:max-tokens 1) (:term-bytes 8)))
             (let ((pool (apply #'f:crea-riserve-full-text queue configs 1 options)))
               (rejected (lambda () (f:prenota-full-text pool lease sources)) 'resource-exhausted :fulltext-reservation-run)
               (is (unborrowed sources)) (is (equal '(0 0 0) (budget pool lease)))))
           (let ((pool (pool queue configs :capacity 1)))
             (multiple-value-bind (slot generation) (f:prenota-full-text pool lease sources)
               (rejected (lambda () (f:prenota-full-text pool lease (sources configs :row 1))) 'resource-exhausted :fulltext-reservation-slots)
               (f:annulla-riserva-full-text pool lease slot generation)))
           (is (unborrowed sources)))
      (ex:rilascia-writer queue lease))))

(deftest req-sec-006-reservation-empty-document-holds-slot
  (with-pool (pool queue configs lease :capacity 1)
    (let ((sources (sources configs :input (dt::document))))
      (multiple-value-bind (slot generation) (f:prenota-full-text pool lease sources)
        (is (equal '(0 0 1) (budget pool lease))) (complete pool lease slot generation 1)
        (dotimes (i 2) (is (zerop (r::indice-posizionale-count (f:leggi-run-riserva-full-text pool lease slot generation i)))))
        (f:annulla-riserva-full-text pool lease slot generation)
        (is (equal '(0 0 0) (budget pool lease)))))))
