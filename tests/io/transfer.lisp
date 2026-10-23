(in-package #:arcdocdb.io.tests)

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-short-append-and-group-flush
  (let ((calls 0) (flushes 0) (output (zeros 16)) (input (bytes 90 1 2 3 4 5 6 91)))
    (with-file (file (crea-temporaneo
                     "injected.tmp" :backend
                     (backend :writer (lambda (fd source start count)
                                        (is (= fd 7)) (is (eq source input))
                                        (is (= start (1+ (* 2 calls))))
                                        (is (= count (- 6 (* 2 calls))))
                                        (replace output source :start1 (* 2 calls)
                                                 :start2 start :end2 (+ start 2))
                                        (incf calls) 2)
                              :flush (lambda (fd) (is (= fd 7)) (incf flushes) 0))))
      (is (= 6 (append-esatto file input 1 7)))
      (is (= 3 calls)) (is (= 0 (posizione-durevole file)))
      (is (equalp (bytes 1 2 3 4 5 6) (subseq output 0 6)))
      (setf calls 0)
      (is (= 12 (append-esatto file input 1 7)))
      (is (= 12 (durable-flush file))) (is (= 1 flushes))
      (is (= 12 (posizione-durevole file))) (is (eq :open (stato-file file))))))

;;; REQ: REQ-STO-003 REQ-AFF-008
(deftest test-REQ-STO-003-short-pread-positional-no-state-write
  (let ((calls 0) (output (make-array 8 :element-type '(unsigned-byte 8) :initial-element 90)))
    (with-file (file (apri-lettura
                     "injected" :backend
                     (backend :reader (lambda (fd buffer start count offset)
                                        (is (= fd 7)) (is (eq buffer output))
                                        (is (= start (1+ calls))) (is (= count (- 6 calls)))
                                        (is (= offset (+ 41 calls)))
                                        (setf (aref buffer start) (1+ calls)) (incf calls) 1))))
      (is (= 7 (leggi-esatto file output 1 7 41)))
      (is (= 6 calls)) (is (equalp (bytes 90 1 2 3 4 5 6 90) output))
      (is (= 0 (posizione-scritta file))) (is (= 0 (posizione-durevole file)))
      (is (eq :open (stato-file file))))))

;;; REQ: REQ-AFF-001
(deftest test-REQ-AFF-001-write-errors-never-retry
  (dolist (errno (list sb-posix:eio sb-posix:enospc sb-posix:eintr))
    (dolist (partial '(nil t))
      (let ((calls 0) (flushes 0) (input (bytes 1 2 3 4)))
        (with-file (file (crea-temporaneo
                         "injected.tmp" :backend
                         (backend :writer (lambda (fd buffer start count)
                                            (declare (ignore fd buffer))
                                            (incf calls)
                                            (if (and partial (= calls 1)) 2
                                                (progn (is (= start (if partial 2 0)))
                                                       (is (= count (if partial 2 4)))
                                                       (error 'sb-posix:syscall-error :errno errno
                                                                                     :name 'write))))
                                  :flush (lambda (fd) (declare (ignore fd)) (incf flushes) 0))))
          (check-io-error (lambda () (append-esatto file input 0 4)) :write errno (if partial 2 0))
          (is (= calls (if partial 2 1))) (is (= (posizione-scritta file) (if partial 2 0)))
          (is (eq :faulted (stato-file file))) (is (= 0 (posizione-durevole file)))
          (signals io-fault (append-esatto file input 0 4) :io-unavailable)
          (signals io-fault (durable-flush file) :io-unavailable)
          (is (= 0 flushes)) (is (= calls (if partial 2 1))))))))

;;; REQ: REQ-AFF-001
(deftest test-REQ-AFF-001-flush-error-preserves-durable-frontier
  (dolist (errno (list sb-posix:eio sb-posix:enospc sb-posix:eintr))
    (let ((calls 0) (input (bytes 1 2)))
      (with-file (file (crea-temporaneo "injected.tmp" :backend
                       (backend :writer (lambda (fd b start count) (declare (ignore fd b start)) count)
                                :flush (lambda (fd) (declare (ignore fd)) (incf calls)
                                         (if (= calls 1) 0
                                             (error 'sb-posix:syscall-error :errno errno :name 'flush))))))
        (append-esatto file input 0 2) (is (= 2 (durable-flush file)))
        (append-esatto file input 0 2)
        (check-io-error (lambda () (durable-flush file)) :flush errno 0)
        (is (= 4 (posizione-scritta file))) (is (= 2 (posizione-durevole file)))
        (is (eq :faulted (stato-file file)))
        (signals io-fault (durable-flush file)) (is (= 2 calls))))))

;;; REQ: REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-002-read-errors-no-retry-no-shared-mutation
  (dolist (errno (list sb-posix:eio sb-posix:eintr))
    (let ((calls 0))
      (with-file (file (apri-lettura "injected" :backend
                       (backend :reader (lambda (&rest args) (declare (ignore args))
                                          (incf calls)
                                          (if (= calls 1) 2
                                              (error 'sb-posix:syscall-error :errno errno :name 'pread))))))
        (check-io-error (lambda () (leggi-esatto file (zeros 4) 0 4 100)) :read errno 2)
        (is (= calls 2)) (is (eq :open (stato-file file))) (is (= 0 (posizione-scritta file)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-008-invalid-progress-and-eof
  (dolist (result '(0 -1 5 nil 1.0d0 :unexpected))
    (let ((calls 0))
      (with-file (file (crea-temporaneo "injected.tmp" :backend
                       (backend :writer (lambda (&rest args) (declare (ignore args))
                                          (incf calls) result))))
        (signals io-fault (append-esatto file (zeros 4) 0 4))
        (is (= 1 calls)) (is (eq :faulted (stato-file file)))
        (is (= 0 (posizione-scritta file))) (is (= 0 (posizione-durevole file)))))
    (dolist (partial '(nil t))
      (let ((calls 0))
        (with-file (file (apri-lettura "injected" :backend
                         (backend :reader (lambda (&rest args) (declare (ignore args))
                                            (incf calls) (if (and partial (= calls 1)) 2 result)))))
          (signals io-fault (leggi-esatto file (zeros 4) 0 4 0))
          (is (= calls (if partial 2 1))) (is (eq :open (stato-file file))))))))

;;; REQ: REQ-AFF-008
(deftest test-REQ-AFF-008-preflight-budget-and-zero-length
  (let ((calls 0))
    (with-file (file (crea-temporaneo "injected.tmp" :max-transfer 4 :max-file-bytes 6
                     :backend (backend :writer (lambda (fd b s count)
                                                 (declare (ignore fd b s)) (incf calls) count))))
      (signals invalid-argument (append-esatto file (zeros 4) 0 5))
      (signals resource-exhausted (append-esatto file (zeros 5) 0 5))
      (is (= 0 (append-esatto file (zeros 0) 0 0))) (is (= 0 calls))
      (is (= 4 (append-esatto file (zeros 4) 0 4)))
      (signals resource-exhausted (append-esatto file (zeros 4) 0 4))
      (is (= 1 calls)) (is (eq :open (stato-file file)))
      (is (= 6 (append-esatto file (zeros 2) 0 2)))
      (signals invalid-argument (leggi-esatto file (zeros 0) 0 0 0)))
    (with-file (file (apri-lettura "injected" :max-transfer 4 :backend (backend)))
      (signals invalid-argument (leggi-esatto file (zeros 1) 0 1 arcdocdb.io::+max-file-offset+))
      (signals resource-exhausted (leggi-esatto file (zeros 5) 0 5 0))
      (is (= 0 (leggi-esatto file (zeros 0) 0 0 arcdocdb.io::+max-file-offset+)))
      (signals invalid-argument (durable-flush file))
      (signals invalid-argument (append-esatto file (zeros 0) 0 0)))))

;;; REQ: REQ-AFF-001
(deftest test-REQ-AFF-001-close-once-even-eintr
  (dolist (errno (list sb-posix:eintr sb-posix:eio))
    (let* ((calls 0) (file (crea-temporaneo "injected.tmp" :backend
                         (backend :close (lambda (fd) (is (= fd 7)) (incf calls)
                                           (error 'sb-posix:syscall-error :errno errno :name 'close))))))
      (check-io-error (lambda () (chiudi file)) :close errno 0)
      (is (eq :closed (stato-file file))) (chiudi file) (is (= 1 calls))
      (signals io-fault (durable-flush file))
      (signals io-fault (append-esatto file (zeros 0) 0 0)))))

;;; REQ: REQ-AFF-001
(deftest test-REQ-AFF-001-directory-flush-dispatch-and-invalid-return
  (let ((calls 0))
    (with-file (file (apri-directory "injected" :backend
                     (backend :flush (lambda (fd) (declare (ignore fd)) (error "Flush file inatteso."))
                              :directory-flush (lambda (fd) (is (= fd 7)) (incf calls) 0))))
      (is (= 0 (durable-flush file))) (is (= 1 calls))))
  (dolist (result '(1 -1 nil))
    (with-file (file (crea-temporaneo "injected.tmp" :backend
                     (backend :flush (lambda (fd) (declare (ignore fd)) result))))
      (signals io-fault (durable-flush file) :io-flush-result)
      (is (eq :faulted (stato-file file))))))

;;; REQ: REQ-AFF-008 REQ-STO-003
(deftest test-REQ-STO-003-open-preflight-and-errors
  (let* ((calls 0) (b (backend :open (lambda (name mode) (declare (ignore name mode))
                                   (incf calls) 7))))
    (dolist (name '("" "closed.seg" "x.tm"))
      (signals invalid-argument (crea-temporaneo name :backend b)))
    (signals invalid-argument (crea-temporaneo (format nil "bad~C.tmp" #\Null) :backend b))
    (signals invalid-argument (crea-temporaneo "x.tmp" :backend b :max-transfer 0))
    (signals invalid-argument (crea-temporaneo "x.tmp" :backend b :max-transfer 268435457))
    (signals invalid-argument (crea-temporaneo "x.tmp" :backend b :max-file-bytes 0))
    (is (= 0 calls)))
  (check-io-error (lambda () (crea-temporaneo "x.tmp" :backend
                             (backend :open (raises-errno sb-posix:eexist)))) :open sb-posix:eexist 0)
  (signals invariant-violation (crea-temporaneo "x.tmp" :backend
                                (backend :open (lambda (&rest args) (declare (ignore args)) -1)))))

;;; REQ: REQ-AFF-001
(deftest test-REQ-AFF-001-directory-failure-and-empty-file-flush
  (let ((calls 0))
    (with-file (file (apri-directory "injected" :backend
                     (backend :directory-flush (lambda (fd) (declare (ignore fd)) (incf calls)
                                                   (error 'sb-posix:syscall-error :errno sb-posix:eio
                                                                                 :name 'fsync)))))
      (check-io-error (lambda () (durable-flush file)) :flush sb-posix:eio 0)
      (is (eq :faulted (stato-file file)))
      (signals io-fault (durable-flush file)) (is (= 1 calls))))
  (let ((calls 0))
    (with-file (file (crea-temporaneo "injected.tmp" :backend
                     (backend :flush (lambda (fd) (declare (ignore fd)) (incf calls) 0))))
      (is (= 0 (durable-flush file))) (is (= 0 (durable-flush file))) (is (= 2 calls)))))

;;; REQ: REQ-AFF-001 REQ-AFF-002
(deftest test-REQ-AFF-001-invalid-close-result-and-closed-reader
  (dolist (result '(1 -1 nil))
    (let* ((calls 0) (file (apri-lettura "injected" :backend
                          (backend :close (lambda (fd) (declare (ignore fd)) (incf calls) result)))))
      (signals io-fault (chiudi file) :io-close-result)
      (is (eq :closed (stato-file file))) (chiudi file) (is (= 1 calls))
      (signals io-fault (leggi-esatto file (zeros 0) 0 0 0) :io-unavailable))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-invalid-private-descriptor-before-syscall
  (let ((file (arcdocdb.io::%make-file :input nil 4 100)))
    (signals invariant-violation (leggi-esatto file (zeros 1) 0 1 0) :io-descriptor)))
