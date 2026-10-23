;;;; Oracoli indipendenti e capacità readonly del decision log dell'Archivio.
;;; OWNER: runner seriale, un backend/FD/scratch per fixture, eventi <=32768.
;;; SHARED: risultato completo solo in lettura; nessuna FI globale nel supporto.
;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-AFF-008 REQ-AFF-009
(defpackage #:arcdocdb.recovery.archive.tests
  (:use #:cl)
  (:local-nicknames (#:da #:arcdocdb.recovery.archive) (#:io #:arcdocdb.io)
                   (#:ct #:arcdocdb.control.tests) (#:rt #:arcdocdb.recovery.tests)
                   (#:av #:arcdocdb.recovery.active.tests))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:corruption-detected #:invariant-violation #:unsupported-format
                #:io-fault #:error-reason #:error-offset)
  (:export #:run))
(in-package #:arcdocdb.recovery.archive.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test recovery Archivio superati.~%" (length *tests*)) t)

(defun dar-identity ()
  "UUID dell'Archivio distinto dall'UUID della Serie delle fixture ACTIVE."
  (rt::participant-id #xfedcba9876543210 #xe1))

(defun dar-log (batches &key (version 2) (identity (dar-identity)) tail)
  "Header ADR-0052, packing bytewise e CRC bitwise; SEAL da oracoli test indipendenti."
  (multiple-value-bind (buffer start end layouts)
      (rt::decision-log-fixture batches :version version :prefix 64 :file-offset 0)
    (is (= start 64)) (is (= end (length buffer)))
    (let ((header (ct::control-reference-header identity version)))
      (ct::crr-pack header 4 #x314c534d 4)
      (ct::crr-pack header 56 (ct::crr-crc header 0 56) 4)
      (replace buffer header))
    (values (if tail (ct::crr-cat buffer tail) buffer) layouts)))

(defstruct (dar-fixture (:constructor %dar-fixture))
  archive input size scratch source reference backend identity
  (reads 0) (short 4096) hook (closed nil)
  (events (make-array 32768 :fill-pointer 0)))

(defun dar-event (f event)
  (is (< (length (dar-fixture-events f)) 32768))
  (vector-push event (dar-fixture-events f)))
(defun dar-events (f) (coerce (dar-fixture-events f) 'list))
(defun dar-clear (f)
  (setf (fill-pointer (dar-fixture-events f)) 0 (dar-fixture-reads f) 0))
(defun dar-transfer (f fd buffer start count offset)
  (is (= fd 401)) (is (not (dar-fixture-closed f)))
  (let* ((source (dar-fixture-source f))
         (n (min count (dar-fixture-short f) (max 0 (- (length source) offset)))))
    (replace buffer source :start1 start :end1 (+ start n) :start2 offset :end2 (+ offset n)) n))
(defun dar-forbidden (f operation &rest args)
  (dar-event f (cons operation args))
  (error 'invariant-violation :reason :archive-fixture-forbidden-io))

(defun dar-backend (f)
  (io:make-backend
   (lambda (path mode)
     (is (equal path "/archive-fixture/multiserie.log")) (is (eq mode :input)) 401)
   (lambda (fd buffer start count offset)
     (dar-event f (list :read fd start count offset)) (incf (dar-fixture-reads f))
     (if (dar-fixture-hook f) (funcall (dar-fixture-hook f) f fd buffer start count offset)
         (dar-transfer f fd buffer start count offset)))
   (lambda (&rest args) (apply #'dar-forbidden f :write args))
   (lambda (&rest args) (apply #'dar-forbidden f :flush args))
   (lambda (&rest args) (apply #'dar-forbidden f :directory-flush args))
   (lambda (fd)
     (is (= fd 401)) (is (not (dar-fixture-closed f)))
     (dar-event f (list :close fd)) (setf (dar-fixture-closed f) t) 0)
   :identity (lambda (fd) (dar-event f (list :identity fd)) (values 1 fd))
   :entry-identity (lambda (&rest args) (apply #'dar-forbidden f :entry args))
   :rename (lambda (&rest args) (apply #'dar-forbidden f :rename args))))

(defun dar-with-input (source thunk &key scope (identity (dar-identity))
                                        (max-transfer 4096) (short 4096))
  "Un FD readonly; dimensioni <=4096 e short positivo, cleanup solo dopo il callback."
  (is (<= (length source) 4096)) (is (plusp short))
  (let* ((canonical-scope (or scope (arcdocdb.get::vista-get-serie-scope (ct::crr-view identity))))
         (f (%dar-fixture :archive (da:crea-archivio-recovery canonical-scope identity)
                         :source (copy-seq source) :reference (copy-seq source)
                         :size (length source) :scratch (ct::crr-bytes (length source) #xa5)
                         :identity (copy-seq identity) :short short)))
    (setf (dar-fixture-backend f) (dar-backend f))
    (unwind-protect
         (progn (setf (dar-fixture-input f)
                      (io:apri-lettura "/archive-fixture/multiserie.log"
                                       :backend (dar-fixture-backend f) :max-transfer max-transfer))
                (dar-clear f) (funcall thunk f))
      (when (and (dar-fixture-input f) (not (eq :closed (io:stato-file (dar-fixture-input f)))))
        (io:chiudi (dar-fixture-input f))))))

(defun dar-call (f &rest options)
  (apply #'da:leggi-decisioni-recuperate (dar-fixture-archive f) (dar-fixture-input f)
         (dar-fixture-size f) (dar-fixture-scratch f) options))
(defun dar-noeffects (f)
  (is (equalp (dar-fixture-source f) (dar-fixture-reference f)))
  (is (equalp (da::archivio-recovery-identity (dar-fixture-archive f)) (dar-fixture-identity f)))
  (is (eq :open (io:stato-file (dar-fixture-input f))))
  (is (eq :input (io:mode-file (dar-fixture-input f))))
  (is (zerop (io:posizione-scritta (dar-fixture-input f))))
  (is (zerop (io:posizione-durevole (dar-fixture-input f))))
  (is (every (lambda (e) (member (first e) '(:read :identity))) (dar-events f))))
(defun dar-expect (type reason thunk &optional (offset nil offset-p))
  (if offset-p (av::av-expect type reason thunk offset) (av::av-expect type reason thunk)))

(declaim (notinline dar-invoke))
(defun dar-invoke (name &rest arguments)
  "Entrata dinamica per tipi intenzionalmente errati: conserva i controlli runtime del prodotto."
  (apply (symbol-function name) arguments))
