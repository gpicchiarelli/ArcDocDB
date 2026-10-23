;;;; Microbenchmark seriale riproducibile; non misura il database né la durability.
;;;; Uso: sbcl --noinform --no-userinit --script tools/foundation-bench.lisp --bench
;;;;      sbcl --noinform --no-userinit --script tools/foundation-bench.lisp --self-test
;;;; REQ: REQ-FOR-003 REQ-AFF-002 REQ-LIM-001 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
(asdf:load-system "arcdocdb")

(defpackage #:arcdocdb.foundation.bench
  (:use #:cl)
  (:export #:main))
(in-package #:arcdocdb.foundation.bench)

(defun octets (n)
  (make-array n :element-type '(unsigned-byte 8) :initial-element 0))

(defun sample (function iterations bytes)
  (dotimes (i (min iterations 1024)) (funcall function))
  (sb-ext:gc :full t)
  (let* ((start (get-internal-real-time))
         (before (sb-ext:get-bytes-consed)) (sink 0))
    (declare (type fixnum sink))
    (dotimes (i iterations)
      (setf sink (logxor sink (the fixnum (funcall function)))))
    (let* ((allocated (- (sb-ext:get-bytes-consed) before))
           (ticks (- (get-internal-real-time) start))
           (seconds (/ ticks (float internal-time-units-per-second 1d0))))
      (list :iterations iterations :bytes-per-operation bytes :seconds seconds
            :heap-bytes allocated :sink sink
            :operations-per-second (if (plusp seconds) (/ iterations seconds) nil)
            :mib-per-second (if (plusp seconds)
                                (/ (* iterations bytes) seconds 1048576d0) nil)))))

(defun campaign (name function iterations bytes)
  (list :name name :samples (loop repeat 5 collect (sample function iterations bytes))))

(defun source-fingerprints ()
  "MD5 identifica i sorgenti della misura; non è una prova di autenticità."
  (loop for file in (cons #p"tools/foundation-bench.lisp"
                         (sort (directory "src/foundation/*.lisp") #'string< :key #'namestring))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun self-test ()
  (let ((buffer (make-array 9 :element-type '(unsigned-byte 8)
                            :initial-contents '(49 50 51 52 53 54 55 56 57))))
    (unless (= #xe3069283 (arcdocdb.binary:crc32c buffer 0 9))
      (error "Oracolo CRC del benchmark non soddisfatto."))
    (let ((report (sample (lambda () 42) 4096 0)))
      (unless (and (zerop (getf report :heap-bytes))
                   (= 4096 (getf report :iterations)))
        (error "Contatore delle allocazioni o iterazioni del benchmark errato.")))
    (let* ((probe nil)
           (report (sample (lambda () (setf probe (octets 64)) (length probe)) 4096 64)))
      (unless (and (= 64 (length probe)) (plusp (getf report :heap-bytes)))
        (error "foundation-bench.lisp: COD-60, allocazioni deliberate non rilevate."))))
  (format t "(:self-test :ok)~%"))

(defun benchmark ()
  (let* ((key (octets 16)) (value (octets 2048))
         (record (octets (+ 24 (length key) (length value))))
         (big (octets 16777216)) (high-record (octets (length record)))
         (prepared (octets (length record))) (proof (octets 32)) (csn (octets 8)))
    (arcdocdb.record:scrivi-record record 0 1 19 key value)
    (arcdocdb.record:scrivi-record high-record 0 1 #xffffffffffffffff key value)
    (arcdocdb.record:scrivi-record prepared 0 1 #xfedcba9876543210 key value :flags 1)
    (arcdocdb.binary:scrivi-u64 csn 0 #xffffffffffffffff)
    (arcdocdb.record:scrivi-record proof 0 4 #xfedcba9876543210 (octets 0) csn)
    (let ((*print-pretty* t) (*print-readably* t))
      (write
       (list :scope :foundation-microbench :format 2 :workers 1 :safety 3
             :recorded-at-universal-time (get-universal-time)
             :source-fingerprints (source-fingerprints)
             :sbcl (lisp-implementation-version) :machine (machine-type)
             :cpu (machine-version) :os (software-type) :os-version (software-version)
             :timer-units-per-second internal-time-units-per-second
             :campaigns
             (list
              (campaign :crc-2k (lambda () (arcdocdb.binary:crc32c value 0 2048))
                        32768 2048)
              (campaign :crc-16m (lambda () (arcdocdb.binary:crc32c big 0 16777216))
                        4 16777216)
              (campaign :verify-put-2k
                        (lambda () (arcdocdb.record:verifica-put record 0 (length record)
                                                                key 19 0))
                        32768 (length record))
              (campaign :encode-2k
                        (lambda () (arcdocdb.record:scrivi-record record 0 1 19 key value))
                        32768 (length record))
              (campaign :verify-put-u64-high
                        (lambda () (arcdocdb.record:verifica-put high-record 0 (length high-record)
                                                                key #xffffffffffffffff 0))
                        32768 (length high-record))
              (campaign :encode-u64-high
                        (lambda () (arcdocdb.record:scrivi-record high-record 0 1
                                                                 #xffffffffffffffff key value))
                        32768 (length high-record))
              (campaign :verify-prepared-u64-high
                        (lambda () (arcdocdb.record:verifica-put prepared 0 (length prepared)
                                   key #xffffffffffffffff 1 :proof-buffer proof
                                   :proof-start 0 :proof-end (length proof)))
                        32768 (+ (length prepared) (length proof))))))
      (terpri))))

(defun main ()
  (cond ((equal (rest sb-ext:*posix-argv*) '("--self-test")) (self-test))
        ((equal (rest sb-ext:*posix-argv*) '("--bench")) (benchmark))
        (t (error "Usare --bench o --self-test."))))

(main)
