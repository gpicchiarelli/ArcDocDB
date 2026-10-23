;;;; Microbenchmark seriale dei metadati: nessun I/O, manifest o commit durevole.
;;;; Uso: --self-test oppure --bench. Le fixture sono costruite prima della misura.
;;; REQ: REQ-FOR-003 REQ-AFF-008 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
(asdf:load-system "arcdocdb")
(defpackage #:arcdocdb.storage.bench (:use #:cl))
(in-package #:arcdocdb.storage.bench)
(declaim (optimize (safety 3) (debug 2)))

(defun octets (n)
  (make-array n :element-type '(unsigned-byte 8) :initial-element 0))

(defun sample (function iterations bytes)
  (dotimes (i (min iterations 1024)) (funcall function))
  (sb-ext:gc :full t)
  (let* ((start (get-internal-real-time)) (before (sb-ext:get-bytes-consed)) (sink 0))
    (declare (type fixnum sink))
    (dotimes (i iterations)
      (setf sink (logxor sink (the fixnum (funcall function)))))
    (let* ((allocated (- (sb-ext:get-bytes-consed) before))
           (seconds (/ (- (get-internal-real-time) start)
                       (float internal-time-units-per-second 1d0))))
      (list :iterations iterations :bytes-per-operation bytes :seconds seconds
            :heap-bytes allocated :sink sink
            :operations-per-second (if (plusp seconds) (/ iterations seconds) nil)))))

(defun campaign (name function iterations bytes)
  (list :name name :samples (loop repeat 5 collect (sample function iterations bytes))))

(defun fingerprints ()
  (loop for file in (append (list #p"arcdocdb.asd" #p"tools/storage-bench.lisp")
                           (sort (append (directory "src/foundation/*.lisp")
                                         (directory "src/storage/*.lisp"))
                                 #'string< :key #'namestring))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun fixture-edit (count)
  (let* ((closed (octets (* count 36))) (removed (octets 0))
         (payload (octets (+ 24 (length closed)))))
    (dotimes (i count)
      (let ((pos (* i 36)))
        (arcdocdb.binary:scrivi-u64 closed pos (1+ i))
        (arcdocdb.binary:scrivi-u64 closed (+ pos 8) #xffffffff)
        (arcdocdb.binary:scrivi-u32 closed (+ pos 16) 1)
        (arcdocdb.binary:scrivi-u64 closed (+ pos 20) #xffffffffffffffff)
        (arcdocdb.binary:scrivi-u64 closed (+ pos 28) #xffffffffffffffff)))
    (arcdocdb.storage.format:scrivi-valore-edit
     payload 0 #xffffffffffffffff #xffffffffffffffff closed count removed :completo t)
    (values payload closed removed)))

(defun frame (payload kind)
  (let ((record (octets (+ 24 (length payload)))))
    (arcdocdb.record:scrivi-record record 0 kind #xffffffffffffffff (octets 0) payload
                                 :flags (if (= kind 5) 8 0))
    record))

(defun self-test ()
  (let ((plain (sample (lambda () 42) 4096 0)) (probe nil))
    (unless (zerop (getf plain :heap-bytes)) (error "Baseline del contatore non zero."))
    (let ((report (sample (lambda () (setf probe (octets 64)) (length probe)) 4096 64)))
      (unless (and (= 64 (length probe)) (plusp (getf report :heap-bytes)))
        (error "COD-60: allocazioni deliberate non rilevate."))))
  (format t "(:self-test :ok)~%"))

(defun edit-campaigns (count iterations)
  (multiple-value-bind (payload closed removed) (fixture-edit count)
    (let ((record (frame payload 5)))
      (list
       (campaign (list :verify-edit :closed count :outcomes count)
                 (lambda () (arcdocdb.storage.format:verifica-record-edit
                             record 0 (length record) :version 2)) iterations (length record))
       (campaign (list :encode-edit :closed count :outcomes count)
                 (lambda () (arcdocdb.storage.format:scrivi-valore-edit
                             payload 0 #xffffffffffffffff #xffffffffffffffff closed count removed
                             :completo t)) iterations (length payload))))))

(defun decision-campaigns (count iterations)
  (let* ((parts (octets (* count 16))) (payload (octets (+ 10 (length parts)))))
    (arcdocdb.storage.format:scrivi-valore-decision payload 0 #xffffffffffffffff parts)
    (let ((record (frame payload 6)))
      (list
       (campaign (list :verify-decision :participants count)
                 (lambda () (arcdocdb.storage.format:verifica-record-decision
                             record 0 (length record) :version 2)) iterations (length record))
       (campaign (list :encode-decision :participants count)
                 (lambda () (arcdocdb.storage.format:scrivi-valore-decision
                             payload 0 #xffffffffffffffff parts)) iterations (length payload))))))

(defun benchmark ()
  (let ((header (octets 64)) (serie (octets 16)))
    (arcdocdb.storage.format:scrivi-header-segmento header 0 serie #xffffffffffffffff
                                                 #xffffffffffffffff)
    (let ((*print-pretty* t) (*print-readably* t))
      (write
       (list :scope :storage-metadata-microbench :workers 1 :safety 3 :format 2
             :source-fingerprints (fingerprints) :recorded-at (get-universal-time)
             :sbcl (lisp-implementation-version) :machine (machine-type)
             :cpu (machine-version) :os (software-type) :os-version (software-version)
             :timer-units-per-second internal-time-units-per-second
             :limits '(:no-io :no-durability :no-duplicate-validation
                       :no-index-update :no-concurrency :external-load-uncontrolled)
             :campaigns
             (append
              (list (campaign :verify-header-u64-high
                              (lambda () (arcdocdb.storage.format:verifica-header-segmento
                                          header 0 64 serie #xffffffffffffffff)) 262144 64)
                    (campaign :encode-header-u64-high
                              (lambda () (arcdocdb.storage.format:scrivi-header-segmento
                                          header 0 serie #xffffffffffffffff #xffffffffffffffff))
                              262144 64))
              (edit-campaigns 2 131072) (edit-campaigns 1024 1024)
              (decision-campaigns 2 131072) (decision-campaigns 65535 32))))
      (terpri))))

(let ((args (rest sb-ext:*posix-argv*)))
  (cond ((equal args '("--bench")) (benchmark))
        ((equal args '("--self-test")) (self-test))
        (t (error "Usare --bench o --self-test."))))
