;;;; C4: guasti deterministici del flush, callback private e nessuna syscall reale.
;;; OWNER: runner seriale e capacità locali; nessuna sostituzione globale di funzioni.
(in-package #:arcdocdb.io.tests)

(defun flush-guard-fixture (mode callback)
  (let ((file nil) (armed nil) (calls 0) (closes 0) (complete nil))
    (let* ((flush (lambda (fd)
                    (is (= fd 7))
                    (if armed (progn (incf calls) (funcall callback file)) 0)))
           (injected (backend :writer (lambda (fd buffer start count)
                                        (declare (ignore buffer start)) (is (= fd 7)) count)
                              :flush flush :directory-flush flush
                              :close (lambda (fd) (declare (ignore fd)) (incf closes) 0))))
      (unwind-protect
           (progn
             (setf file (ecase mode
                          (:append (crea-temporaneo "flush-guard.tmp" :backend injected))
                          (:directory (apri-directory "flush-guard" :backend injected))))
             (when (eq mode :append)
               (is (= 2 (append-esatto file (bytes 1 2) 0 2)))
               (is (= 2 (durable-flush file)))
               (is (= 4 (append-esatto file (bytes 3 4) 0 2))))
             (setf armed t complete t)
             (values file (lambda () calls) (lambda () closes)))
        (when (and file (not complete)) (chiudi file))))))

(defmacro with-flush-guard ((file calls closes mode callback) &body body)
  `(multiple-value-bind (,file ,calls ,closes) (flush-guard-fixture ,mode ,callback)
     (unwind-protect (progn ,@body) (chiudi ,file))))

;;; REQ: REQ-AFF-001 REQ-STO-003
(deftest test-REQ-AFF-001-FLUSH-GUARD-success
  (dolist (mode '(:append :directory))
    (with-flush-guard (file calls closes mode (lambda (f) (declare (ignore f)) 0))
      (let ((written (posizione-scritta file)))
        (is (= written (durable-flush file) (posizione-durevole file)))
        (is (eq :open (stato-file file))) (is (= 1 (funcall calls)))
        (is (zerop (funcall closes)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-FLUSH-GUARD-original-condition
  (let ((original (make-condition 'arcdocdb.conditions:corruption-detected :reason :flush-probe)))
    (dolist (mode '(:append :directory))
      (with-flush-guard (file calls closes mode (lambda (f) (declare (ignore f)) (error original)))
        (let ((durable (posizione-durevole file)))
          (handler-case (progn (durable-flush file) (error "Guasto non rilevato."))
            (arcdocdb.conditions:corruption-detected (c) (is (eq original c))))
          (is (= durable (posizione-durevole file))) (is (eq :faulted (stato-file file)))
          (is (= 1 (funcall calls))) (is (zerop (funcall closes)))
          (signals io-fault (durable-flush file) :io-unavailable)
          (is (= 1 (funcall calls))))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-FLUSH-GUARD-nonlocal-exit
  (dolist (mode '(:append :directory))
    (with-flush-guard (file calls closes mode
                           (lambda (f) (declare (ignore f)) (throw 'flush-probe :escaped)))
      (let ((durable (posizione-durevole file)))
        (is (eq :escaped (catch 'flush-probe (durable-flush file) :unexpected)))
        (is (= durable (posizione-durevole file))) (is (eq :faulted (stato-file file)))
        (is (= 1 (funcall calls))) (is (zerop (funcall closes)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-008-FLUSH-GUARD-invalid-results
  (dolist (mode '(:append :directory))
    (dolist (result '(nil -1 1 0.0d0 :unexpected))
      (with-flush-guard (file calls closes mode (lambda (f) (declare (ignore f)) result))
        (let ((durable (posizione-durevole file)))
          (signals io-fault (durable-flush file) :io-flush-result)
          (is (= durable (posizione-durevole file))) (is (eq :faulted (stato-file file)))
          (is (= 1 (funcall calls))) (is (zerop (funcall closes))))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-001-FLUSH-GUARD-errno-no-retry
  (dolist (mode '(:append :directory))
    (dolist (errno (list sb-posix:eio sb-posix:eintr sb-posix:enospc))
      (with-flush-guard (file calls closes mode
                             (lambda (f) (declare (ignore f))
                               (error 'sb-posix:syscall-error :errno errno :name 'flush-probe)))
        (let ((durable (posizione-durevole file)))
          (check-io-error (lambda () (durable-flush file)) :flush errno 0)
          (is (= durable (posizione-durevole file))) (is (eq :faulted (stato-file file)))
          (is (= 1 (funcall calls))) (is (zerop (funcall closes))))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-FLUSH-GUARD-close-success-rejected
  (dolist (mode '(:append :directory))
    (with-flush-guard (file calls closes mode (lambda (f) (chiudi f) 0))
      (let ((durable (posizione-durevole file)))
        (signals io-fault (durable-flush file) :io-unavailable)
        (is (eq :closed (stato-file file))) (is (= durable (posizione-durevole file)))
        (is (= 1 (funcall calls))) (is (= 1 (funcall closes)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-FLUSH-GUARD-close-errno-preserved
  (dolist (mode '(:append :directory))
    (with-flush-guard (file calls closes mode
                           (lambda (f) (chiudi f)
                             (error 'sb-posix:syscall-error :errno sb-posix:eintr :name 'flush-probe)))
      (let ((durable (posizione-durevole file)))
        (check-io-error (lambda () (durable-flush file)) :flush sb-posix:eintr 0)
        (is (eq :closed (stato-file file))) (is (= durable (posizione-durevole file)))
        (is (= 1 (funcall calls))) (is (= 1 (funcall closes)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-FLUSH-GUARD-close-invalid-result-preserved
  (dolist (mode '(:append :directory))
    (with-flush-guard (file calls closes mode (lambda (f) (chiudi f) -1))
      (let ((durable (posizione-durevole file)))
        (signals io-fault (durable-flush file) :io-flush-result)
        (is (eq :closed (stato-file file))) (is (= durable (posizione-durevole file)))
        (is (= 1 (funcall calls))) (is (= 1 (funcall closes)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-FLUSH-GUARD-close-original-condition
  (let ((original (make-condition 'arcdocdb.conditions:corruption-detected :reason :flush-probe)))
    (dolist (mode '(:append :directory))
      (with-flush-guard (file calls closes mode (lambda (f) (chiudi f) (error original)))
        (let ((durable (posizione-durevole file)))
          (handler-case (progn (durable-flush file) (error "Guasto non rilevato."))
            (arcdocdb.conditions:corruption-detected (c) (is (eq original c))))
          (is (eq :closed (stato-file file))) (is (= durable (posizione-durevole file)))
          (is (= 1 (funcall calls))) (is (= 1 (funcall closes))))))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-008-FLUSH-GUARD-written-mutated
  (dolist (mode '(:append :directory))
    (with-flush-guard (file calls closes mode
                           (lambda (f) (incf (arcdocdb.io::file-written f)) 0))
      (let ((durable (posizione-durevole file)))
        (signals invariant-violation (durable-flush file) :io-flush-frontier)
        (is (= durable (posizione-durevole file))) (is (eq :faulted (stato-file file)))
        (is (= 1 (funcall calls))) (is (zerop (funcall closes)))))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-008-FLUSH-GUARD-preflight-closed
  (dolist (mode '(:append :directory))
    (with-flush-guard (file calls closes mode (lambda (f) (declare (ignore f)) 0))
      (chiudi file)
      (signals io-fault (durable-flush file) :io-unavailable)
      (is (eq :closed (stato-file file))) (is (zerop (funcall calls)))
      (is (= 1 (funcall closes))))))

;;; REQ: REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-008-FLUSH-GUARD-preflight-input
  (let ((calls 0))
    (with-file (file (apri-lettura "flush-input"
                                 :backend (backend :flush (lambda (fd) (declare (ignore fd)) (incf calls) 0))))
      (signals invalid-argument (durable-flush file) :io-flush-mode)
      (is (eq :open (stato-file file))) (is (zerop calls)))))
