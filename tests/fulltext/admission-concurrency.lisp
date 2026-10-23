(in-package #:arcdocdb.fulltext.admission.tests)

(deftest req-sec-010-reservation-hot-allocation
  (dolist (id '(1 #xffffffffffffffff))
    (let* ((configs (vector (config id #xffffffffffffffff))) (queue (ex:crea-coda-writer :capacity 16))
           (pool (pool queue configs :capacity 1)) (sources (sources configs))
           (query (at::small-space)) (lease (ex:acquisisci-writer queue)))
      (unwind-protect
           (progn
             (at::analyzed "alpha" :space query)
             (dotimes (i 100)
               (multiple-value-bind (slot generation) (f:prenota-full-text pool lease sources)
                 (complete pool lease slot generation) (f:annulla-riserva-full-text pool lease slot generation)))
             (sb-ext:gc :full t)
             (let ((before (sb-ext:get-bytes-consed)))
               (dotimes (i 1000)
                 (multiple-value-bind (slot generation) (f:prenota-full-text pool lease sources)
                   (check-pending-row pool lease 0 :pending)
                   (complete pool lease slot generation)
                   (check-pending-row pool lease 0 :pending)
                   (is (r:corrisponde-riga-full-text (f:leggi-run-riserva-full-text pool lease slot generation 0) 0 1 query :all))
                   (f:annulla-riserva-full-text pool lease slot generation)
                   (check-pending-row pool lease 0 :absent)))
               (let ((allocated (- (sb-ext:get-bytes-consed) before)))
                 (format t "Riserve/copia/query, ID ~D: ~D byte consed per 1000 operazioni.~%" id allocated)
                 (is (zerop allocated)))))
        (ex:rilascia-writer queue lease)))))

(deftest req-sec-006-reservation-four-independent-writers
  (let* ((configs (configs)) (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
         (contexts (loop repeat 4 collect
                     (let ((queue (ex:crea-coda-writer :capacity 16)))
                       (list queue (pool queue configs :capacity 1) (sources configs)))))
         (threads (loop for context in contexts collect
                    (let ((private context))
                      (sb-thread:make-thread
                       (lambda ()
                         (destructuring-bind (queue pool sources) private
                           (sb-thread:signal-semaphore ready)
                           (is (sb-thread:wait-on-semaphore start :timeout 15))
                           (let ((lease (ex:acquisisci-writer queue)))
                             (unwind-protect
                                  (dotimes (i 100)
                                    (multiple-value-bind (slot generation) (f:prenota-full-text pool lease sources)
                                      (check-pending-row pool lease 0 :pending)
                                      (complete pool lease slot generation 1)
                                      (is (dt::matches (f:leggi-run-riserva-full-text pool lease slot generation 1) 0 2 "beta" :all))
                                      (f:annulla-riserva-full-text pool lease slot generation)
                                      (check-pending-row pool lease 0 :absent)))
                               (ex:rilascia-writer queue lease)))) t)
                       :name "fulltext-reservation-writer")))))
    (is (sb-thread:wait-on-semaphore ready :n 4 :timeout 15))
    (dotimes (i 4) (sb-thread:signal-semaphore start))
    (dolist (thread threads) (is (eq t (sb-thread:join-thread thread :timeout 30 :default :timeout))))))
