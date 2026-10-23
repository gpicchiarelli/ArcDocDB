;;;; Gare fra API pubbliche, senza dichiarare le finestre interne o la memoria debole coperte.
(in-package #:arcdocdb.epochs.tests)

;;; REQ: REQ-CMP-007 REQ-AFF-004
(deftest test-REQ-CMP-007-ebr-claim-is-exclusive
  (let* ((registry (crea-registro-epoche 1 1))
         (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
         (results (make-array 2 :initial-element nil))
         (deadline (epochs-deadline)) (threads nil))
    (multiple-value-bind (ticket generation) (prenota-ritiro registry (list :segment))
      (pubblica-ritiro ticket generation) (aggiorna-soglia-reclaim registry)
      (unwind-protect
           (progn
             (dotimes (i 2)
               (let ((worker i))
                 (push (epochs-worker
                        (format nil "EBR reclaimer ~D" worker)
                        (lambda ()
                          (sb-thread:signal-semaphore ready)
                          (epochs-wait start deadline)
                          (setf (svref results worker)
                                (handler-case
                                    (if (acquisisci-reclaim ticket generation) :claimed :unexpected-nil)
                                  (invalid-argument (condition) (error-reason condition))))
                          :ok)) threads)))
             (is (not (eq (first threads) (second threads))))
             (dotimes (i 2) (epochs-wait ready deadline))
             (sb-thread:signal-semaphore start 2)
             (dolist (thread threads) (epochs-join thread deadline))
             (is (= 1 (count :claimed results)))
             (is (= 1 (count :retirement-not-available results)))
             (epochs-check-ticket ticket generation :claimed 1)
             (epochs-check-state registry 2 2 1 0)
             ;; Completa solo dopo join di entrambi: nessun I/O duplicato è simulato.
             (completa-reclaim ticket generation))
        (sb-thread:signal-semaphore start 2)
        (epochs-stop-workers threads)))))

;;; REQ: REQ-CMP-005 REQ-CMP-007 REQ-CON-004
(deftest test-REQ-CMP-005-ebr-reader-finishes-with-maintenance-mutex-held
  (let* ((registry (crea-registro-epoche 2 1))
         (reader (contesto-epoca registry 0)) (other (contesto-epoca registry 1))
         (held (sb-thread:make-semaphore)) (release (sb-thread:make-semaphore))
         (deadline (epochs-deadline)) (threads nil))
    (unwind-protect
         (progn
           (push (epochs-worker
                  "EBR maintenance mutex holder"
                  (lambda ()
                    (sb-thread:with-mutex ((arcdocdb.epochs::registro-epoche-mutex registry))
                      (sb-thread:signal-semaphore held)
                      (epochs-wait release deadline))
                    :ok)) threads)
           (epochs-wait held deadline)
           (push (epochs-worker
                  "EBR reader while maintenance is held"
                  (lambda ()
                    (unwind-protect
                         (progn (is (entra-epoca reader)) (is (epoca-attiva-p reader))
                                (is (null (esci-epoca reader))) (is (not (epoca-attiva-p reader))))
                      (when (epoca-attiva-p reader) (esci-epoca reader)))
                    :ok)) threads)
           ;; Il holder viene rilasciato solo dopo il join del reader.
           (epochs-join (first threads) deadline)
           (is (not (epoca-attiva-p other)))
           (sb-thread:signal-semaphore release)
           (epochs-join (second threads) deadline)
           (epochs-check-state registry 1 1 0 0))
      (sb-thread:signal-semaphore release)
      (epochs-stop-workers threads))))
