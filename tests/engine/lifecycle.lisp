(in-package #:arcdocdb.engine.tests)

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-LIM-003 REQ-REC-001
(deftest test-REQ-AFF-001-production-preflight-index-fault-closes-admission
  (with-root (root)
    (with-engine (engine (open-engine root :create t))
      (initial-workload engine)
      (let ((originals (images root)) (seen nil))
        (arcdocdb.index.primary:invalida-indice-primario (arcdocdb.engine::motore-index engine))
        (handler-case (e:scrivi-documento engine (key 4) (value 5))
          (arcdocdb.conditions:invariant-violation (condition)
            (is (eq :primary-index-faulted (arcdocdb.conditions:error-reason condition))) (setf seen t)))
        (is seen) (is (eq :faulted (e:stato-motore engine))) (check-images root originals)
        (is (equal '(0 5 0 5) (multiple-value-list
                               (arcdocdb.csn:leggi-frontiere-csn (arcdocdb.engine::motore-registry engine)))))
        (signals arcdocdb.conditions:invalid-argument (e:leggi-documento engine (key 1) (bytes 64)))))
    (with-engine (engine (open-engine root)) (check-initial engine))))

;;; REQ: REQ-LIM-003 REQ-IDX-005 REQ-REC-001 REQ-WAL-006
(deftest test-REQ-LIM-003-production-index-load-rejects-before-commit
  (dolist (version '(1 2))
    (with-root (root)
      (with-engine (engine (open-engine root :create t :version version))
        (loop for id from 1 to 28 do (is (= id (e:scrivi-documento engine (key id) (value id)))))
        (reject-index-limit root engine 29 :primary-fragment-load)
        (check-frontier engine 28)
        (loop for id from 1 to 28 do (check-get engine id (value id))))
      (with-engine (engine (open-engine root :version version))
        (check-frontier engine 28)
        (loop for id from 1 to 28 do (check-get engine id (value id)))
        (is (= 29 (e:scrivi-documento engine (key 1) (value 5))))
        (is (= 30 (e:cancella-documento engine (key 2))))
        (is (= 31 (e:scrivi-documento engine (key 29) (value 29)))))
      (with-engine (engine (open-engine root :version version))
        (check-frontier engine 31) (check-get engine 1 (value 5)) (check-get engine 2 nil)
        (loop for id from 3 to 29 do (check-get engine id (value id)))))))

;;; REQ: REQ-LIM-003 REQ-IDX-005 REQ-REC-001 REQ-WAL-006
(deftest test-REQ-LIM-003-production-key-arena-rejects-before-commit
  (dolist (version '(1 2))
    (with-root (root)
      (with-engine (engine (open-engine root :create t :version version :arena-bytes 64))
        (loop for id from 1 to 4 do (is (= id (e:scrivi-documento engine (key id) (value id)))))
        (reject-index-limit root engine 5 :primary-key-arena-full)
        (check-frontier engine 4))
      (with-engine (engine (open-engine root :version version :arena-bytes 64))
        (check-frontier engine 4)
        (is (= 5 (e:cancella-documento engine (key 2))))
        ;; DELETE libera la capienza live, non recupera byte dell'arena append-only.
        (reject-index-limit root engine 5 :primary-key-arena-full)
        (is (= 6 (e:scrivi-documento engine (key 1) (value 5)))))
      (with-engine (engine (open-engine root :version version :arena-bytes 64))
        (check-frontier engine 6) (check-get engine 1 (value 5)) (check-get engine 2 nil)
        (check-get engine 3 (value 3)) (check-get engine 4 (value 4)) (check-get engine 5 nil)))))

;;; REQ: REQ-VAL-001 REQ-REC-001 REQ-AFF-012
(deftest test-REQ-VAL-001-production-image-oracle-permits-only-exact-final-rename
  (with-root (root)
    (let* ((temporary (merge-pathnames "0000000000000003.seg.tmp" root))
           (final (merge-pathnames "0000000000000003.seg" root))
           (originals nil))
      (with-open-file (stream temporary :direction :output :if-exists :error
                             :element-type '(unsigned-byte 8))
        (write-sequence (bytes 64 73) stream))
      (setf originals (images root t))
      (check-segment-images root originals)
      (rename-file temporary final)
      (signals error (check-images root originals))
      (check-segment-images root originals)
      (with-open-file (stream final :direction :io :if-exists :overwrite
                             :element-type '(unsigned-byte 8))
        (write-byte 74 stream))
      (signals error (check-segment-images root originals))
      (with-open-file (stream temporary :direction :output :if-exists :error
                             :element-type '(unsigned-byte 8))
        (write-sequence (bytes 64 73) stream))
      (signals error (check-segment-images root originals))
      (delete-file temporary)
      (with-open-file (stream final :direction :io :if-exists :overwrite
                             :element-type '(unsigned-byte 8))
        (write-byte 73 stream))
      (setf originals (images root t))
      (check-segment-images root originals)
      (with-open-file (stream temporary :direction :output :if-exists :error
                             :element-type '(unsigned-byte 8))
        (write-sequence (bytes 64 73) stream))
      (signals error (check-segment-images root originals))
      (delete-file final)
      (signals error (check-segment-images root originals)))))

;;; REQ: REQ-REC-001 REQ-CON-002 REQ-WAL-006 REQ-MVC-006 REQ-IDX-001
(deftest test-REQ-REC-001-production-startup-recovery-admission-v1-v2
  (dolist (version '(1 2))
    (with-root (root)
      (let ((phases nil))
        (with-engine (engine (open-engine root :create t :version version
                              :observer (lambda (engine phase)
                                          (push phase phases)
                                          (when (member phase '(:starting :storage-created :before-recovery :recovered
                                                               :checkpoint-prepared :checkpoint-published :before-admission))
                                            (is (not (eq :ready (e:stato-motore engine))))
                                            (signals arcdocdb.conditions:invalid-argument
                                              (e:scrivi-documento engine (key 1) (value 1))))
                                          nil)))
          (is (eq :ready (e:stato-motore engine)))
          (is (find :before-admission phases))
          (initial-workload engine) (check-initial engine))
        (let ((originals (images root t)))
          (with-engine (engine (open-engine root :version version))
            (check-initial engine) (resumed-workload engine) (check-resumed engine))
          (check-images root originals))
        (with-engine (engine (open-engine root :version version)) (check-resumed engine))))))

;;; REQ: REQ-AFF-001 REQ-REC-001 REQ-CON-002
(deftest test-REQ-AFF-001-production-exclusive-owner-and-close
  (with-root (root)
    (let ((engine (open-engine root :create t)))
      (unwind-protect
           (progn
             (initial-workload engine)
             (let ((originals (images root)))
               (signals arcdocdb.conditions:io-fault (open-engine root))
               (check-images root originals))
             (let ((rejected nil))
               (sb-thread:join-thread
                (sb-thread:make-thread
                 (lambda ()
                   (handler-case (e:leggi-documento engine (key 1) (bytes 64))
                     (arcdocdb.conditions:invalid-argument () (setf rejected t))))))
               (is rejected))
             (check-initial engine))
        (e:chiudi-motore engine))
      (e:chiudi-motore engine)
      (signals arcdocdb.conditions:invalid-argument (e:scrivi-documento engine (key 1) (value 1)))
      (with-engine (reopened (open-engine root)) (check-initial reopened)))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-REC-001-production-init-explicit-and-existing-data-preserved
  (with-root (root)
    (signals arcdocdb.conditions:io-fault (open-engine root))
    (is (null (uiop:directory-files root)))
    (with-engine (engine (open-engine root :create t)) (initial-workload engine))
    (let ((originals (images root)))
      (signals arcdocdb.conditions:invalid-argument (open-engine root :create t))
      (check-images root originals))
    (with-engine (engine (open-engine root)) (check-initial engine))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004 REQ-AFF-018
(deftest test-REQ-REC-001-production-startup-fault-releases-lock-and-preserves-cause
  (dolist (phase '(:before-recovery :recovered :checkpoint-prepared :checkpoint-published :before-admission))
    (with-root (root)
      (with-engine (engine (open-engine root :create t)) (initial-workload engine))
      (let ((cause (make-condition 'arcdocdb.conditions:io-fault :reason :injected-startup :operation :engine))
            (seen nil) (originals (images root t)))
        (handler-case
            (open-engine root :observer (lambda (engine step)
                                         (is (not (eq :ready (e:stato-motore engine))))
                                         (when (eq phase step) (error cause)) nil))
          (arcdocdb.conditions:io-fault (condition) (is (eq condition cause)) (setf seen t)))
        (is seen)
        (check-images root originals)
        (with-engine (engine (open-engine root)) (check-initial engine))))))

;;; REQ: REQ-WAL-006 REQ-AFF-001 REQ-AFF-004 REQ-CON-002
(deftest test-REQ-WAL-006-production-write-fault-terminal-no-confirmation
  (dolist (phase '(:before-append :after-append :after-flush :after-commit))
    (with-root (root)
      (let ((armed nil) (cause (make-condition 'arcdocdb.conditions:io-fault :reason :injected-write :operation :engine)))
        (with-engine (engine (open-engine root :create t
                              :observer (lambda (engine step)
                                          (declare (ignore engine))
                                          (when (and armed (eq step phase)) (error cause)) nil)))
          (initial-workload engine)
          (setf armed t)
          (let ((seen nil))
            (handler-case (e:scrivi-documento engine (key 4) (value 5))
              (arcdocdb.conditions:io-fault (condition) (is (eq cause condition)) (setf seen t)))
            (is seen))
          (is (eq :faulted (e:stato-motore engine)))
          (signals arcdocdb.conditions:invalid-argument (e:leggi-documento engine (key 1) (bytes 64))))
        (with-engine (engine (open-engine root))
          (check-get engine 1 (value 3)) (check-get engine 2 nil) (check-get engine 3 (value 4))
          (check-frontier engine (if (eq phase :before-append) 5 6)))))))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-REC-001
(deftest test-REQ-FOR-004-production-corruption-no-admission-no-rewrite
  (with-root (root)
    (with-engine (engine (open-engine root :create t)) (initial-workload engine))
    (let* ((paths (remove-if-not (lambda (p) (search ".seg" (file-namestring p))) (uiop:directory-files root)))
           (path (find-if (lambda (p) (> (length (image p)) 64)) paths)))
      (is path)
      (with-open-file (stream path :direction :io :element-type '(unsigned-byte 8) :if-exists :overwrite)
        (file-position stream 108)
        (let ((byte (read-byte stream))) (file-position stream 108) (write-byte (logxor 1 byte) stream)))
      (let ((originals (images root)))
        (signals arcdocdb.conditions:corruption-detected (open-engine root))
        (check-images root originals)))))

;;; REQ: REQ-MVC-005 REQ-REC-001 REQ-AFF-002
(deftest test-REQ-MVC-005-production-decreasing-csn-rejected-before-effects
  (with-root (root)
    (with-engine (engine (open-engine root :create t)) (check-frontier engine 0))
    (let* ((path (find-if (lambda (p) (search "0000000000000002.seg" (file-namestring p)))
                          (uiop:directory-files root))) (position 64))
      (is path)
      (with-open-file (stream path :direction :output :element-type '(unsigned-byte 8) :if-exists :append)
        (dolist (csn '(5 4))
          (let ((batch (arcdocdb.wal:crea-lotto :segment 2 :capacity 512 :max-records 1)))
            (arcdocdb.wal:aggiungi-record batch 1 (key 1) (value 1))
            (let ((size (arcdocdb.wal:sigilla-lotto batch csn position position)))
              (write-sequence (arcdocdb.wal::lotto-buffer batch) stream :end size)
              (incf position size)))))
      (let ((originals (images root)) (names (length (uiop:directory-files root))))
        (signals arcdocdb.conditions:corruption-detected (open-engine root))
        (is (= names (length (uiop:directory-files root)))) (check-images root originals)))))

;;; REQ: REQ-REC-001 REQ-AFF-018
(deftest test-REQ-REC-001-production-orphan-conflict-before-effects
  (with-root (root)
    (with-engine (engine (open-engine root :create t)) (initial-workload engine))
    (dolist (leaf '("00000000000000ff.seg" "00000000000000ff.seg.tmp"))
      (with-open-file (stream (merge-pathnames leaf root) :direction :output
                              :element-type '(unsigned-byte 8) :if-exists :error)
        (write-byte 9 stream)))
    (let ((originals (images root)) (names (length (uiop:directory-files root))))
      (signals arcdocdb.conditions:corruption-detected (open-engine root))
      (is (= names (length (uiop:directory-files root)))) (check-images root originals))))

;;; REQ: REQ-AFF-004 REQ-REC-001 REQ-CON-002
(deftest test-REQ-AFF-004-production-cleanup-preserves-primary-and-attempts-all
  (with-root (root)
    (with-engine (engine (open-engine root :create t)) (initial-workload engine))
    (let ((cause (make-condition 'arcdocdb.conditions:io-fault :reason :primary-fi :operation :engine))
          (seen nil))
      (handler-case
          (open-engine root
            :observer (lambda (engine phase)
                        (when (eq phase :before-admission)
                          ;; FI: guasto del fault-handler e una close EBADF, entrambi secondari.
                          (incf (arcdocdb.engine::motore-lease engine))
                          (sb-posix:close (arcdocdb.io::file-fd (first (arcdocdb.engine::motore-fds engine))))
                          (error cause)) nil))
        (e:errore-cleanup-motore (condition)
          (is (eq cause (e:causa-cleanup-motore condition)))
          (is (>= (length (e:errori-cleanup-motore condition)) 3))
          (setf seen t)))
      (is seen)
      (with-engine (engine (open-engine root)) (check-initial engine)))))
