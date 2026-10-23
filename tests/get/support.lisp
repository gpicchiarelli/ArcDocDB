;;;; Prima suite GET: fixture autonome, valori noti e file nativi readonly.
;;; OWNER: runner seriale e un solo worker per fixture; nessuna suite altrui fornisce helper.
;;; SHARED: indice/cache della fixture; buffer e osservatore I/O esclusivi del test.
;;; REQ: REQ-CON-004 REQ-IDX-001 REQ-CCH-002 REQ-FOR-004 REQ-AFF-008
(defpackage #:arcdocdb.get.tests
  (:use #:cl)
  (:local-nicknames (#:g #:arcdocdb.get) (#:p #:arcdocdb.index.primary)
                   (#:c #:arcdocdb.cache) (#:io #:arcdocdb.io)
                   (#:rec #:arcdocdb.record) (#:fmt #:arcdocdb.storage.format)
                   (#:mvcc #:arcdocdb.mvcc) (#:ebr #:arcdocdb.epochs)
                   (#:csn #:arcdocdb.csn) (#:bin #:arcdocdb.binary))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:corruption-detected #:unsupported-format
                #:snapshot-too-old #:io-fault #:error-reason)
  (:import-from #:arcdocdb.get #:crea-ambito-get #:crea-vista-get-serie
                #:crea-segmento-get #:crea-contesto-get #:payload-contesto-get
                #:stato-contesto-get #:avvia-get #:copia-candidato-get
                #:sonda-cache-get #:leggi-record-get #:copia-valore-get
                #:concludi-get #:abbandona-get)
  (:export #:run))
(in-package #:arcdocdb.get.tests)

(defvar *get-tests* nil)

;;; REQ: REQ-AFF-003
(defmacro deftest (name &body body)
  `(progn
     (defun ,name () ,@body)
     (setf *get-tests* (acons ',name #',name
                             (remove ',name *get-tests* :key #'car)))))

;;; REQ: REQ-AFF-003
(defun run ()
  (dolist (test (reverse *get-tests*))
    (funcall (cdr test))
    (format t "ok    ~A~%" (car test)))
  (format t "~D test GET superati.~%" (length *get-tests*))
  t)

;;; REQ: REQ-FOR-004 REQ-LIM-003
(defun get-bytes (&rest contents)
  (make-array (length contents) :element-type '(unsigned-byte 8)
              :initial-contents contents))

;;; REQ: REQ-CON-004
(defun get-zeros (size &optional (fill 0))
  (make-array size :element-type '(unsigned-byte 8) :initial-element fill))

;;; REQ: REQ-FOR-001
(defun get-identity ()
  (make-array 16 :element-type '(unsigned-byte 8)
              :initial-contents '(0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-FOR-004
(defstruct (get-fixture (:constructor %make-get-fixture))
  csns snapshots snapshot epochs epoch scope primary cache view context
  key value record offset end segment path file identity prepared-p version origin
  outcome-offset proof reads (generation 0) (csn 7) (segment-id 17))

;;; REQ: REQ-AFF-001 REQ-AFF-002
(defun get-observed-native-backend (reads)
  "Observer only: public backend delegates unchanged to native adapters.
The private adapter names permit counting actual pread calls, not altering product state."
  (io:make-backend
   #'io::native-open
   (lambda (fd bytes start count offset)
     (push (list offset count) (car reads))
     (io::native-read fd bytes start count offset))
   #'io::native-write #'io::native-flush #'io::native-directory-flush #'io::native-close))

;;; REQ: REQ-CON-004 REQ-AFF-002
(defun get-read-count (fixture)
  (length (car (get-fixture-reads fixture))))

;;; REQ: REQ-AFF-002
(defun get-read-offsets (fixture)
  (mapcar #'first (reverse (car (get-fixture-reads fixture)))))

;;; REQ: REQ-IDX-001 REQ-IDX-003
(defun get-publish (fixture &key (csn (get-fixture-csn fixture))
                               (location (logior (ash (ldb (byte 32 0)
                                                          (get-fixture-segment-id fixture)) 32)
                                                 (get-fixture-offset fixture)))
                               (size (length (get-fixture-record fixture)))
                               (key (get-fixture-key fixture)))
  "Writer public API; CSN/location/size supplied independently of GET output."
  (let* ((index (get-fixture-primary fixture))
         (payload (make-array 5 :element-type '(unsigned-byte 64)
                              :initial-contents
                              (list csn location (logior (ash (length key) 32) (ash 1 48))
                                    size 0))))
    (multiple-value-bind (high low) (p:digest-chiave-indice index key 0 (length key))
      (p:pubblica-chiave-indice index (p:frammento-corrente-indice index high)
                               key 0 (length key) high low payload (p:crea-contesto-indice)))
    nil))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-AFF-001
(defun get-cleanup (fixture)
  "Serial and idempotent: abandon before closing the FD and deleting its owned path."
  (unwind-protect
       (when (get-fixture-context fixture) (abbandona-get (get-fixture-context fixture)))
    (unwind-protect
         (when (plusp (get-fixture-generation fixture))
           (mvcc:termina-snapshot (get-fixture-snapshot fixture) (get-fixture-generation fixture)))
      (unwind-protect
           (when (get-fixture-file fixture) (io:chiudi (get-fixture-file fixture)))
        (when (and (get-fixture-path fixture) (probe-file (get-fixture-path fixture)))
          (delete-file (get-fixture-path fixture))))))
  nil)

;;; REQ: REQ-CON-004 REQ-IDX-001 REQ-FOR-001 REQ-FOR-004 REQ-AFF-001
(defun get-fixture (&key (cache-p t) (prepared-p nil) (csn 7) (snapshot-csn csn)
                        (record-bytes 1024) (version 2) (origin 1) (publish-p t)
                        (key (get-bytes #x47 #x00 #xff)) (value (get-bytes #xa1 #x01 #x02))
                        (segment-id 17) (lifetime 20) (wait 5)
                        (put-stamp (if prepared-p 101 csn)) (proof-txid 101) (proof-csn csn)
                        record-transform proof-transform header-transform)
  "Known bytes, explicit numeric locations/CSNs, public record/header/index writers.
Transforms act only on fixture-owned bytes before append, for labelled corruption witnesses."
  (let* ((f (%make-get-fixture :key key :value value :identity (get-identity)
                             :prepared-p prepared-p :version version :origin origin
                             :offset 64 :csn csn :segment-id segment-id :reads (list nil)))
         (complete nil))
    (unwind-protect
         (progn
           (setf (get-fixture-csns f)
                 (csn:crea-registro-csn :capacity 3 :initial-high (ldb (byte 32 32) snapshot-csn)
                                       :initial-low (ldb (byte 32 0) snapshot-csn))
                 (get-fixture-snapshots f)
                 (mvcc:crea-registro-snapshot (get-fixture-csns f) 2 lifetime wait)
                 (get-fixture-snapshot f) (mvcc:crea-contesto-snapshot (get-fixture-snapshots f))
                 (get-fixture-epochs f) (ebr:crea-registro-epoche 2 2)
                 (get-fixture-epoch f) (ebr:contesto-epoca (get-fixture-epochs f) 0)
                 (get-fixture-scope f) (crea-ambito-get (get-fixture-epochs f) (get-fixture-snapshots f))
                 (get-fixture-primary f)
                 (p:crea-indice-primario :capacity 16 :arena-bytes 2048 :hash-seed-high 23 :hash-seed-low 29)
                 (get-fixture-cache f)
                 (when cache-p
                   (c:crea-cache-serie
                    (make-array 1 :element-type '(unsigned-byte 32) :initial-element 1024)
                    (make-array 1 :element-type '(unsigned-byte 32) :initial-element 1) 16384))
                 (get-fixture-view f)
                 (crea-vista-get-serie (get-fixture-scope f) (get-fixture-primary f)
                                      (get-fixture-cache f) (get-fixture-identity f))
                 (get-fixture-context f) (crea-contesto-get (get-fixture-scope f) 0
                                                         :record-bytes record-bytes
                                                         :budget-payload (+ record-bytes 152))
                 (get-fixture-record f) (get-zeros (+ 24 (length key) (length value))))
           (rec:scrivi-record (get-fixture-record f) 0 1 put-stamp key value
                             :version version :flags (if prepared-p 1 0))
           (when record-transform (funcall record-transform (get-fixture-record f)))
           (when prepared-p
             (let ((body (get-zeros 8)) (proof (get-zeros 32)))
               (bin:scrivi-u64 body 0 proof-csn)
               (rec:scrivi-record proof 0 4 proof-txid (get-bytes) body :version version)
               (when proof-transform (funcall proof-transform proof))
               (setf (get-fixture-proof f) proof
                     (get-fixture-outcome-offset f) (+ 64 (length (get-fixture-record f))))))
           (setf (get-fixture-end f) (+ 64 (length (get-fixture-record f))
                                      (if prepared-p 32 0))
                 (get-fixture-path f)
                 (merge-pathnames (format nil "arcdocdb-get-~A-~A.tmp" (sb-posix:getpid) (gensym))
                                  (uiop:temporary-directory)))
           (let ((header (get-zeros 64)) (writer nil))
             (fmt:scrivi-header-segmento header 0 (get-fixture-identity f) segment-id 3
                                       :version version :origine origin)
             (when header-transform (funcall header-transform header))
             (unwind-protect
                  (progn
                    (setf writer (io:crea-temporaneo (get-fixture-path f)))
                    (io:append-esatto writer header 0 64)
                    (io:append-esatto writer (get-fixture-record f) 0 (length (get-fixture-record f)))
                    (when prepared-p (io:append-esatto writer (get-fixture-proof f) 0 32))
                    (io:durable-flush writer))
               (when writer (io:chiudi writer))))
           (setf (get-fixture-file f)
                 (io:apri-lettura (get-fixture-path f)
                                 :backend (get-observed-native-backend (get-fixture-reads f)))
                 (get-fixture-segment f)
                 (crea-segmento-get (get-fixture-view f) (get-fixture-file f) segment-id (get-zeros 64)))
           (when publish-p (get-publish f))
           (setf complete t)
           f)
      (unless complete (get-cleanup f)))))

;;; REQ: REQ-CON-004 REQ-CMP-007
(defmacro with-get-fixture ((name options) &body body)
  `(let ((,name (get-fixture ,@options)))
     (unwind-protect (progn ,@body) (get-cleanup ,name))))

;;; REQ: REQ-MVC-007 REQ-MVC-004
(defun get-register-snapshot (fixture &optional (now 10))
  (multiple-value-bind (generation csn ready) (mvcc:registra-snapshot (get-fixture-snapshot fixture) now)
    (setf (get-fixture-generation fixture) generation)
    (values generation csn ready)))

;;; REQ: REQ-IDX-001 REQ-MVC-001
(defun get-start (fixture &key snapshot (generation 0) (now 11) (key (get-fixture-key fixture)))
  (avvia-get (get-fixture-context fixture) (get-fixture-view fixture) key snapshot generation now))

;;; REQ: REQ-FOR-004 REQ-CCH-002
(defun get-load (fixture &key (valid-bytes (get-fixture-end fixture))
                            (flags (if (get-fixture-prepared-p fixture) 1 0))
                            (outcome-offset (get-fixture-outcome-offset fixture)))
  (leggi-record-get (get-fixture-context fixture) (get-fixture-segment fixture)
                   valid-bytes flags :outcome-offset outcome-offset))

;;; REQ: REQ-CMP-007 REQ-AFF-004
(defun get-check-idle (fixture)
  (is (eq :idle (stato-contesto-get (get-fixture-context fixture))))
  (is (not (ebr:epoca-attiva-p (get-fixture-epoch fixture)))))

;;; REQ: REQ-CMP-007 REQ-AFF-004
(defun get-check-faulted (fixture)
  (is (eq :faulted (stato-contesto-get (get-fixture-context fixture))))
  (is (not (ebr:epoca-attiva-p (get-fixture-epoch fixture)))))

;;; REQ: REQ-CCH-002 REQ-MVC-004 REQ-AFF-002
(defun get-copy-found (fixture &key (now 12))
  "Independent oracle: expected bytes are the fixture's known input, never product ranges."
  (let ((output (get-zeros (length (get-fixture-value fixture)))))
    (is (= (length output) (copia-valore-get (get-fixture-context fixture) output 0)))
    (is (equalp (get-fixture-value fixture) output))
    (multiple-value-bind (result size) (concludi-get (get-fixture-context fixture) now)
      (is (eq :found result)) (is (= (length output) size)))
    (get-check-idle fixture)
    output))
