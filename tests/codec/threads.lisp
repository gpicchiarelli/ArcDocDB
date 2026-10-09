(in-package #:arcdocdb.utf8.tests)

;;; REQ: REQ-CON-005 REQ-AFF-004 REQ-AFF-008
(deftest test-REQ-CON-005-utf8-two-private-buffers-and-real-cpu-overlap
  (let* ((units 65536) (repetitions 64) (count (* 4 units))
         (patterns (vector (bytes 0 #xc2 #x80 #xe0 #xa0 #x80 #xf4 #x8f #xbf #xbf)
                           (bytes #x7f #xdf #xbf #xed #x9f #xbf #xf0 #x90 #x80 #x80)))
         (buffers (make-array 2)) (copies (make-array 2))
         (ready (sb-thread:make-semaphore)) (go (sb-thread:make-semaphore))
         (starts (vector 0 0)) (ends (vector 0 0)) (sinks (vector 0 0)) (threads nil))
    (dotimes (index 2)
      (let* ((pattern (svref patterns index))
             (buffer (make-array (* units (length pattern)) :element-type '(unsigned-byte 8))))
        (dotimes (unit units) (replace buffer pattern :start1 (* unit (length pattern))))
        (setf (svref buffers index) buffer (svref copies index) (copy-seq buffer))))
    (is (not (eq (svref buffers 0) (svref buffers 1))))
    (unwind-protect
         (progn
           (dotimes (i 2)
             (let ((index i))
               (push (sb-thread:make-thread
                      (lambda ()
                        (handler-case
                            (progn
                              (sb-thread:signal-semaphore ready)
                              (utf8-wait go)
                              ;; I semafori precedono entrambi gli intervalli osservati.
                              (setf (svref starts index) (get-internal-real-time))
                              (let ((buffer (svref buffers index)) (sink 0))
                                (dotimes (iteration repetitions)
                                  (let ((result (arcdocdb.utf8:verifica-utf8
                                                 buffer 0 (length buffer) :max-bytes (length buffer))))
                                    (is (= result count)) (incf sink result)))
                                (setf (svref sinks index) sink))
                              (setf (svref ends index) (get-internal-real-time))
                              :ok)
                          (error (condition) condition)))
                      :name "UTF-8 private buffer worker") threads)))
           (dotimes (i 2) (utf8-wait ready))
           (sb-thread:signal-semaphore go 2)
           (dolist (thread threads) (utf8-join thread))
           (dotimes (index 2)
             (is (> (svref ends index) (svref starts index)))
             (is (= (svref sinks index) (* count repetitions)))
             (is (equalp (svref buffers index) (svref copies index))))
           (let ((overlap (- (min (svref ends 0) (svref ends 1))
                             (max (svref starts 0) (svref starts 1)))))
             (is (plusp overlap))
             (format t "  UTF-8 CPU: 2 worker, ~D byte, sink ~D ciascuno, overlap ~D tick, ~D tick/s.~%"
                     (* 2 repetitions (length (svref buffers 0))) (* count repetitions)
                     overlap internal-time-units-per-second)))
      (sb-thread:signal-semaphore go 2)
      (utf8-stop-workers threads))))
