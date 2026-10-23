(in-package #:arcdocdb.fulltext.format.tests)

(deftest REQ-SEC-008-parallel-independent-buffers
  (let ((threads nil) (errors (make-array 4 :initial-element nil))
        (identity (id-serie)))
    (dotimes (worker 4)
      (let ((slot worker))
        (push (sb-thread:make-thread
               (lambda ()
                 (handler-case
                     (multiple-value-bind (buffer start end ignored section-lengths)
                         (fixture :prefix slot :segment-id slot :identity identity)
                       (declare (ignore ignored))
                       (dotimes (i 128)
                         (is (= end (scrivi-cornice-indice-full-text
                                     buffer start end identity slot section-lengths)))
                         (read-ok buffer start end identity slot)))
                   (error (condition) (setf (aref errors slot) condition))))) threads)))
    (dolist (thread threads)
      (is (not (eq :timeout (sb-thread:join-thread thread :timeout 30 :default :timeout)))))
    (dotimes (i 4) (is (null (aref errors i))))
    (is (equalp identity (id-serie)))))
