(in-package #:arcdocdb.fulltext.admission.tests)

(deftest req-sec-006-reservation-cancellation-at-every-copy-stage
  (with-pool (pool queue configs lease :capacity 1)
    (let ((sources (sources configs)))
      (dotimes (steps 64)
        (multiple-value-bind (slot generation) (f:prenota-full-text pool lease sources)
          (when (plusp steps) (f:passo-riserva-full-text pool lease slot generation steps))
          (f:annulla-riserva-full-text pool lease slot generation)
          (is (unborrowed sources)) (is (equal '(0 0 0) (budget pool lease)))
          (dotimes (i 2) (is (= (d:limite-fisso-indice-full-text (svref configs i))
                               (f:leggi-bound-riserve-full-text pool lease i)))))))))

(deftest req-sec-010-reservation-transfer-retains-historical-cost
  (with-pool (pool queue configs lease :capacity 1)
    (multiple-value-bind (slot generation) (f:prenota-full-text pool lease (sources configs))
      (complete pool lease slot generation)
      (is (eq :transferred (f:trasferisci-riserva-full-text pool lease slot generation)))
      (is (equal '(146 0 1) (budget pool lease)))
      (dotimes (i 2)
        (is (= (+ 145 (d:limite-fisso-indice-full-text (svref configs i)))
               (f:leggi-bound-riserve-full-text pool lease i)))
        (is (dt::matches (f:leggi-run-riserva-full-text pool lease slot generation i) 0 1 "alpha" :phrase)))
      (rejected (lambda () (f:annulla-riserva-full-text pool lease slot generation)) 'invalid-argument :fulltext-reservation-cancel-state)
      (rejected (lambda () (f:trasferisci-riserva-full-text pool lease slot generation)) 'invalid-argument)
      (rejected (lambda () (f:prenota-full-text pool lease (sources configs :row 1))) 'resource-exhausted :fulltext-reservation-slots)
      (is (equal '(146 0 1) (budget pool lease))))))

(deftest req-sec-006-reservation-stale-lease-and-foreign-token
  (let* ((configs (configs)) (queue (ex:crea-coda-writer :capacity 16)) (pool (pool queue configs))
         (other (pool queue configs)) (first (ex:acquisisci-writer queue)))
    (multiple-value-bind (slot generation) (f:prenota-full-text pool first (sources configs))
      (ex:rilascia-writer queue first)
      (let ((lease (ex:acquisisci-writer queue)))
        (unwind-protect
             (progn
               (rejected (lambda () (f:passo-riserva-full-text pool first slot generation 1)) 'invalid-argument :writer-lease)
               (rejected (lambda () (f:passo-riserva-full-text other lease slot generation 1)) 'invalid-argument :fulltext-reservation-token)
               (let ((thread (sb-thread:make-thread
                              (lambda () (rejected (lambda () (budget pool lease)) 'invalid-argument :writer-lease) t))))
                 (is (eq t (sb-thread:join-thread thread :timeout 30 :default :timeout))))
               (complete pool lease slot generation) (f:annulla-riserva-full-text pool lease slot generation))
          (ex:rilascia-writer queue lease))))))

(deftest req-sec-006-reservation-lost-source-fail-stop
  (with-pool (pool queue configs lease)
    (let ((sources (sources configs)))
      (multiple-value-bind (slot generation) (f:prenota-full-text pool lease sources)
        (setf (d::preparazione-full-text-phase (svref sources 0)) :idle)
        (rejected (lambda () (f:passo-riserva-full-text pool lease slot generation 1)) 'invariant-violation :fulltext-reservation-borrow)
        (is (eq :faulted (f::riserve-full-text-state pool)))
        (is (= 146 (f::riserve-full-text-delta-used pool)))
        (is (eq slot (d::preparazione-full-text-borrower (svref sources 1))))
        (rejected (lambda () (f:annulla-riserva-full-text pool lease slot generation)) 'invariant-violation)))))

(deftest req-sec-006-reservation-interrupted-adoption-fail-stop
  (with-pool (pool queue configs lease)
    (let* ((sources (sources configs)) (symbol 'f::cattura-sorgenti-riserva) (original (symbol-function symbol)))
      (unwind-protect
           (progn
             (setf (symbol-function symbol)
                   (lambda (pool slot sources) (funcall original pool slot sources) (throw 'interrupted :stopped)))
             (is (eq :stopped (catch 'interrupted (f:prenota-full-text pool lease sources))))
             (is (eq :faulted (f::riserve-full-text-state pool)))
             (is (not (f::riserve-full-text-effect pool)))
             (is (every #'d::preparazione-full-text-borrower sources))
             (is (= 145 (aref (f::riserve-full-text-used pool) 1))))
        (setf (symbol-function symbol) original)))))
