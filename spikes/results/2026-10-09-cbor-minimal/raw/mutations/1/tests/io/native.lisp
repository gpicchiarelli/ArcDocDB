(in-package #:arcdocdb.io.tests)

;;; REQ: REQ-STO-003 REQ-AFF-001 REQ-AFF-002
(deftest test-REQ-STO-003-native-append-flush-and-checked-record
  (with-directory (directory)
    (let* ((path (merge-pathnames "segment.tmp" directory))
           (serie (zeros 16)) (header (zeros 64)) (key (bytes 42)) (value (bytes 1 2 3 4))
           (record (zeros 29)) (output (zeros 93)))
      (arcdocdb.storage.format:scrivi-header-segmento header 0 serie 17 0)
      (arcdocdb.record:scrivi-record record 0 1 19 key value)
      (with-file (file (crea-temporaneo path))
        (is (= 64 (append-esatto file header 0 64)))
        (is (= 93 (append-esatto file record 0 29)))
        (is (= 93 (durable-flush file)))
        (signals io-fault (crea-temporaneo path)))
      (with-file (dir (apri-directory directory)) (durable-flush dir))
      (with-file (file (apri-lettura path))
        (is (= 93 (leggi-esatto file output 0 93 0)))
        (is (equalp header (subseq output 0 64)))
        (is (= 64 (arcdocdb.storage.format:verifica-header-segmento output 0 93 serie 17)))
        (is (= 89 (arcdocdb.record:verifica-put output 64 93 key 19 0)))
        (let ((small (zeros 4)))
          (leggi-esatto file small 0 4 89) (is (equalp value small))
          (leggi-esatto file small 0 4 89) (is (equalp value small)))
        (check-io-error (lambda () (leggi-esatto file (zeros 94) 0 94 0)) :read nil 93)))))

;;; REQ: REQ-STO-003 REQ-AFF-001
(deftest test-REQ-STO-003-native-no-follow-file-kinds-and-cloexec
  (with-directory (directory)
    (let* ((path (merge-pathnames "file.tmp" directory))
           (link (merge-pathnames "symlink.tmp" directory))
           (fifo (merge-pathnames "fifo" directory)))
      (with-file (file (crea-temporaneo path))
        (let ((fd (arcdocdb.io::file-fd file)))
          (is (logbitp 0 (sb-posix:fcntl fd sb-posix:f-getfd)))))
      (sb-posix:symlink (namestring path) (namestring link))
      (signals io-fault (apri-lettura link))
      (signals io-fault (crea-temporaneo link))
      (signals io-fault (apri-lettura directory) :io-file-kind)
      (signals io-fault (apri-directory path))
      (let ((link-directory (merge-pathnames "directory-link" directory)))
        (sb-posix:symlink (namestring directory) (namestring link-directory))
        (unwind-protect
             (signals io-fault (apri-directory (uiop:ensure-directory-pathname link-directory)))
          (sb-posix:unlink (namestring link-directory))))
      (sb-posix:mkfifo fifo #o600)
      (signals io-fault (apri-lettura fifo) :io-file-kind))))

;;; REQ: REQ-STO-003 REQ-AFF-002
(deftest test-REQ-STO-003-concurrent-pread-distinct-buffers
  (with-directory (directory)
    (let ((path (merge-pathnames "readers.tmp" directory)) (data (zeros 4096)))
      (dotimes (i 4096) (setf (aref data i) (mod i 251)))
      (with-file (file (crea-temporaneo path)) (append-esatto file data 0 4096) (durable-flush file))
      (with-file (file (apri-lettura path))
        (let ((threads (loop for offset in '(0 1000 2000 3000)
                             collect (let ((position offset))
                                       (sb-thread:make-thread
                                        (lambda ()
                                          (let ((out (zeros 256)))
                                            (dotimes (i 1000)
                                              (leggi-esatto file out 0 256 position)
                                              (is (equalp out (subseq data position (+ position 256)))))
                                            t)))))))
          (dolist (thread threads) (is (eq t (sb-thread:join-thread thread :timeout 10))))
          (is (eq :open (stato-file file))) (is (= 0 (posizione-scritta file))))))))

;;; REQ: REQ-FOR-003 REQ-AFF-001
(deftest test-REQ-FOR-003-native-two-sealed-batches-one-flush
  (dolist (version '(1 2))
    (with-directory (directory)
      (let* ((path (merge-pathnames "batches.tmp" directory)) (serie (zeros 16)) (header (zeros 64)))
        (arcdocdb.storage.format:scrivi-header-segmento header 0 serie 31 0 :version version)
        (multiple-value-bind (first start end)
            (arcdocdb.foundation.tests::batch-fixture :version version :prefix 0 :file-offset 64)
          (declare (ignore start))
          (let ((second-offset (+ 64 end)))
            (multiple-value-bind (second start2 end2)
                (arcdocdb.foundation.tests::batch-fixture :version version :prefix 0
                                                        :file-offset second-offset :stamp 20)
              (declare (ignore start2))
              (with-file (file (crea-temporaneo path))
                (append-esatto file header 0 64) (append-esatto file first 0 end)
                (append-esatto file second 0 end2)
                (is (zerop (posizione-durevole file)))
                (is (= (+ second-offset end2) (durable-flush file))))
              (with-file (file (apri-lettura path))
                (let ((out (zeros (+ second-offset end2))))
                  (leggi-esatto file out 0 (length out) 0)
                  (is (= second-offset (arcdocdb.record:verifica-lotto
                                        out 64 second-offset 31 :version version :file-offset 0)))
                  (is (= (length out) (arcdocdb.record:verifica-lotto
                                      out second-offset (length out) 31
                                      :version version :file-offset 0))))))))))))

;;; REQ: REQ-AFF-004
(deftest test-REQ-AFF-004-native-errno-and-cleanup-provenance
  ;; FD int massimo non disponibile nell'ambiente di questa campagna.
  (dolist (thunk (list (lambda () (arcdocdb.io::native-read 2147483647 (zeros 1) 0 1 0))
                      (lambda () (arcdocdb.io::native-write 2147483647 (zeros 1) 0 1))))
    (handler-case (progn (funcall thunk) (error "EBADF native non rilevato."))
      (sb-posix:syscall-error (c) (is (= sb-posix:ebadf (sb-posix:syscall-errno c))))))
  (handler-case (arcdocdb.io::cleanup-open 2147483647 :io-syscall sb-posix:eio)
    (io-fault (c) (is (= sb-posix:eio (error-errno c)))
                  (is (= sb-posix:ebadf (arcdocdb.conditions:error-cleanup-errno c))))))
