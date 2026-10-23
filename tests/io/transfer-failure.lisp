;;;; C4: sonde sui ritorni/uscite dei callback, incluse invalidazioni fuori ownership.
(in-package #:arcdocdb.io.tests)

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-TRANSFER-GUARD-original-write-condition
  (dolist (partial '(nil t))
    (let ((calls 0) (effect nil)
          (original (make-condition 'arcdocdb.conditions:corruption-detected :reason :transfer-probe)))
      (with-file (file (crea-temporaneo "transfer-guard.tmp" :backend
                        (backend :writer (lambda (&rest args) (declare (ignore args))
                                           (incf calls) (setf effect t)
                                           (if (and partial (= calls 1)) 1 (error original))))))
        (handler-case (progn (append-esatto file (bytes 1 2) 0 2) (error "Guasto non rilevato."))
          (arcdocdb.conditions:corruption-detected (c) (is (eq original c))))
        (is effect) (is (eq :faulted (stato-file file)))
        (is (= (if partial 1 0) (posizione-scritta file)))
        (is (zerop (posizione-durevole file)))
        (signals io-fault (append-esatto file (bytes 1 2) 0 2) :io-unavailable)
        (is (= calls (if partial 2 1)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-TRANSFER-GUARD-nonlocal-write
  (dolist (partial '(nil t))
    (let ((calls 0) (effect nil))
      (with-file (file (crea-temporaneo "transfer-guard.tmp" :backend
                        (backend :writer (lambda (&rest args) (declare (ignore args))
                                           (incf calls) (setf effect t)
                                           (if (and partial (= calls 1)) 1
                                               (throw 'transfer-probe :escaped))))))
        (is (eq :escaped (catch 'transfer-probe (append-esatto file (bytes 1 2) 0 2) :unexpected)))
        (is effect) (is (eq :faulted (stato-file file)))
        (is (= (if partial 1 0) (posizione-scritta file)))
        (is (zerop (posizione-durevole file)))
        (signals io-fault (append-esatto file (bytes 1 2) 0 2) :io-unavailable)
        (is (= calls (if partial 2 1)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-TRANSFER-GUARD-closed-write-progress
  (dolist (progress '(1 2))
    (let ((target nil) (calls 0) (closes 0) (armed nil))
      (with-file (file (crea-temporaneo "transfer-guard.tmp" :backend
                        (backend :writer (lambda (&rest args) (declare (ignore args))
                                           (if armed (progn (incf calls) (chiudi target) progress) 2))
                                 :close (lambda (fd) (declare (ignore fd)) (incf closes) 0))))
        (setf target file)
        (is (= 2 (append-esatto file (bytes 7 8) 0 2)))
        (is (= 2 (durable-flush file)))
        (setf armed t)
        (check-io-error (lambda () (append-esatto file (bytes 1 2) 0 2)) :write nil progress)
        (is (= 1 calls closes)) (is (eq :closed (stato-file file)))
        (is (= (+ 2 progress) (posizione-scritta file))) (is (= 2 (posizione-durevole file)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-TRANSFER-GUARD-closed-write-errno
  (let ((target nil) (calls 0))
    (with-file (file (crea-temporaneo "transfer-guard.tmp" :backend
                      (backend :writer (lambda (&rest args) (declare (ignore args))
                                         (incf calls)
                                         (if (= calls 1) 1
                                             (progn (chiudi target)
                                                    (error 'sb-posix:syscall-error
                                                           :errno sb-posix:eintr :name 'write-probe)))))))
      (setf target file)
      (check-io-error (lambda () (append-esatto file (bytes 1 2) 0 2)) :write sb-posix:eintr 1)
      (is (= 2 calls)) (is (eq :closed (stato-file file)))
      (is (= 1 (posizione-scritta file))) (is (zerop (posizione-durevole file))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-TRANSFER-GUARD-closed-write-invalid-result
  (let ((target nil) (calls 0))
    (with-file (file (crea-temporaneo "transfer-guard.tmp" :backend
                      (backend :writer (lambda (&rest args) (declare (ignore args))
                                         (incf calls) (chiudi target) nil))))
      (setf target file)
      (signals io-fault (append-esatto file (bytes 1 2) 0 2) :io-invalid-progress)
      (is (= 1 calls)) (is (eq :closed (stato-file file)))
      (is (zerop (posizione-scritta file))) (is (zerop (posizione-durevole file))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-TRANSFER-GUARD-closed-write-original-condition
  (let ((target nil)
        (original (make-condition 'arcdocdb.conditions:corruption-detected :reason :transfer-probe)))
    (with-file (file (crea-temporaneo "transfer-guard.tmp" :backend
                      (backend :writer (lambda (&rest args) (declare (ignore args))
                                         (chiudi target) (error original)))))
      (setf target file)
      (handler-case (progn (append-esatto file (bytes 1 2) 0 2) (error "Guasto non rilevato."))
        (arcdocdb.conditions:corruption-detected (c) (is (eq original c))))
      (is (eq :closed (stato-file file))) (is (zerop (posizione-scritta file)))
      (is (zerop (posizione-durevole file))))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-008-TRANSFER-GUARD-written-mutated
  (let ((target nil) (calls 0))
    (with-file (file (crea-temporaneo "transfer-guard.tmp" :backend
                      (backend :writer (lambda (&rest args) (declare (ignore args))
                                         (incf calls) (incf (arcdocdb.io::file-written target)) 1))))
      (setf target file)
      (signals invariant-violation (append-esatto file (bytes 1 2) 0 2) :io-append-frontier)
      (is (= 1 calls)) (is (eq :faulted (stato-file file)))
      (is (zerop (posizione-durevole file))))))

;;; REQ: REQ-STO-003 REQ-AFF-004
(deftest test-REQ-AFF-004-TRANSFER-GUARD-closed-read-progress
  (dolist (progress '(1 2))
    (let ((target nil) (calls 0) (buffer (zeros 2)))
      (with-file (file (apri-lettura "transfer-guard" :backend
                        (backend :reader (lambda (fd output start count offset)
                                           (declare (ignore fd count offset))
                                           (incf calls) (setf (aref output start) 7)
                                           (chiudi target) progress))))
        (setf target file)
        (check-io-error (lambda () (leggi-esatto file buffer 0 2 0)) :read nil progress)
        (is (= 1 calls)) (is (eq :closed (stato-file file)))
        (is (zerop (posizione-scritta file))) (is (zerop (posizione-durevole file)))))))

;;; REQ: REQ-STO-003 REQ-AFF-004
(deftest test-REQ-AFF-004-TRANSFER-GUARD-nonlocal-read-remains-readonly
  (let ((buffer (zeros 2)) (calls 0))
    (with-file (file (apri-lettura "transfer-guard" :backend
                      (backend :reader (lambda (&rest args) (declare (ignore args))
                                         (incf calls) (throw 'transfer-probe :escaped)))))
      (is (eq :escaped (catch 'transfer-probe (leggi-esatto file buffer 0 2 0) :unexpected)))
      (is (= 1 calls)) (is (eq :open (stato-file file)))
      (is (zerop (posizione-scritta file))) (is (zerop (posizione-durevole file))))))
