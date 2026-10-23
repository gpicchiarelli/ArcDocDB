;;;; Fixture ACTIVE: byte/CRC indipendenti, due capacità readonly reali del backend.
;;; OWNER: runner seriale; ogni fixture possiede backend, scratch, tabella e FD fino al cleanup.
;;; SHARED: nessuno stato tra fixture; hook FI privato, mai sostituzioni globali nel supporto.
;;; Limiti: file <=4096 byte, eventi <=16384; nessuna scrittura, attesa o syscall nativa.
;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-008 REQ-AFF-009
(defpackage #:arcdocdb.recovery.active.tests
  (:use #:cl)
  (:local-nicknames (#:ar #:arcdocdb.recovery.active) (#:io #:arcdocdb.io)
                   (#:ct #:arcdocdb.control.tests) (#:rt #:arcdocdb.recovery.tests))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:corruption-detected #:invariant-violation #:unsupported-format
                #:io-fault #:error-reason #:error-offset)
  (:export #:run))
(in-package #:arcdocdb.recovery.active.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))

(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test recovery ACTIVE superati.~%" (length *tests*))
  t)

(defun av-bytes (size &optional (fill 0)) (ct::crr-bytes size fill))
(defun av-cat (&rest arrays) (apply #'ct::crr-cat arrays))
(defun av-identity () (ct::crr-uuid))

(defun av-record (spec version)
  "Spec dichiarativa, packing bytewise e CRC bitwise del solo oracolo test."
  (ecase (first spec)
    (:put (destructuring-bind (kind txid prepared key value) spec
            (is (eq kind :put))
            (rt::reference-record 1 txid key value :version version :flags (if prepared 1 0))))
    (:tombstone (destructuring-bind (kind txid prepared key) spec
                  (is (eq kind :tombstone))
                  (rt::reference-record 2 txid key (av-bytes 0) :version version :flags (if prepared 1 0))))
    (:outcome (let ((value (av-bytes 8)))
                (ct::crr-pack value 0 (third spec) 8)
                (rt::reference-record 4 (second spec) (av-bytes 0) value :version version)))))

(defun av-batch (records start active-id version &optional (durable start))
  "RECORDS sono byte di cornici; SEAL riferisce offset assoluti e CRC dei CRC."
  (let ((body (av-bytes 32))
        (checksums (apply #'av-cat (mapcar (lambda (record) (subseq record 0 4)) records))))
    (ct::crr-pack body 0 active-id 8) (ct::crr-pack body 8 start 8)
    (ct::crr-pack body 16 durable 8) (ct::crr-pack body 24 (length records) 4)
    (ct::crr-pack body 28 (ct::crr-crc checksums 0 (length checksums)) 4)
    (apply #'av-cat (append records (list (rt::reference-record 3 17 (av-bytes 0) body :version version))))))

(defun av-log (batches &key (version 2) (active-id 9) tail (origin 1))
  "Header, lotti e coda dichiarati senza encoder o builder di prodotto."
  (let ((header (ct::control-reference-header (av-identity) version t)) (chunks nil) (pos 64))
    (ct::crr-pack header 32 active-id 8) (setf (aref header 10) origin)
    (ct::crr-pack header 56 (ct::crr-crc header 0 56) 4)
    (push header chunks)
    (dolist (specs batches)
      (let ((batch (av-batch (mapcar (lambda (spec) (av-record spec version)) specs) pos active-id version)))
        (push batch chunks) (incf pos (length batch))))
    (when tail (push tail chunks))
    (apply #'av-cat (nreverse chunks))))

(defstruct (av-fixture (:constructor %av-fixture))
  control input control-input size scratch decisions source reference identity view backend
  control-source (short 4096) (reads 0) hook identity-hook
  (closed (make-array 2 :initial-element nil))
  (events (make-array 16384 :fill-pointer 0)))

(defun av-event (f event)
  (is (< (length (av-fixture-events f)) 16384))
  (vector-push event (av-fixture-events f)))

(defun av-transfer (f fd buffer start count offset)
  (is (member fd '(301 302))) (is (not (aref (av-fixture-closed f) (- fd 301))))
  (let* ((source (if (= fd 301) (av-fixture-control-source f) (av-fixture-source f)))
         (n (min count (av-fixture-short f) (max 0 (- (length source) offset)))))
    (replace buffer source :start1 start :end1 (+ start n) :start2 offset :end2 (+ offset n))
    n))

(defun av-forbidden (f operation &rest arguments)
  (av-event f (cons operation arguments))
  (error 'invariant-violation :reason :active-fixture-forbidden-io))

(defun av-backend (f)
  (io:make-backend
   (lambda (path mode)
     (is (eq mode :input))
     (cond ((equal path "/active-fixture/control.log") 301)
           ((equal path "/active-fixture/9.seg") 302)
           (t (error "Nome fixture inatteso: ~S" path))))
   (lambda (fd buffer start count offset)
     (av-event f (list :read fd start count offset)) (incf (av-fixture-reads f))
     (if (av-fixture-hook f) (funcall (av-fixture-hook f) f fd buffer start count offset)
         (av-transfer f fd buffer start count offset)))
   (lambda (&rest args) (apply #'av-forbidden f :write args))
   (lambda (&rest args) (apply #'av-forbidden f :flush args))
   (lambda (&rest args) (apply #'av-forbidden f :directory-flush args))
   (lambda (fd)
     (is (member fd '(301 302))) (is (not (aref (av-fixture-closed f) (- fd 301))))
     (av-event f (list :close fd)) (setf (aref (av-fixture-closed f) (- fd 301)) t) 0)
   :identity (lambda (fd)
               (av-event f (list :identity fd))
               (if (av-fixture-identity-hook f) (funcall (av-fixture-identity-hook f) f fd)
                   (values 1 fd)))
   :entry-identity (lambda (&rest args) (apply #'av-forbidden f :entry args))
   :rename (lambda (&rest args) (apply #'av-forbidden f :rename args))))

(defun av-clear (f)
  (setf (fill-pointer (av-fixture-events f)) 0 (av-fixture-reads f) 0))
(defun av-events (f) (coerce (av-fixture-events f) 'list))

(defun av-decision-table (specs version)
  (multiple-value-bind (buffer start end) (rt::decision-log-fixture (if specs (list specs) nil) :version version)
    (rt::decision-fixture-read buffer start end :version version)))

(defun av-with-fixture (source thunk &key (version 2) (active-id 9) (short 4096)
                                        (max-transfer 4096) decision-specs)
  "Due file readonly; CONTROL e DECISION decodificati dalle API pubbliche reali."
  (is (<= (length source) 4096)) (is (plusp short))
  (let* ((identity (av-identity))
         (f (%av-fixture :source (copy-seq source) :reference (copy-seq source) :size (length source)
                         :scratch (av-bytes (length source) #xa5) :identity identity
                         :view (ct::crr-view identity) :short short
                         :control-source (ct::crr-log version (ct::crr-edit :active active-id :next (1+ active-id)))
                         :decisions (av-decision-table decision-specs version))))
    (setf (av-fixture-backend f) (av-backend f))
    (unwind-protect
         (progn
           (setf (av-fixture-control-input f)
                 (io:apri-lettura "/active-fixture/control.log" :backend (av-fixture-backend f)))
           (let ((bytes (av-fixture-control-source f)))
             (setf (av-fixture-control f)
                   (arcdocdb.control:leggi-control-recuperato
                    (av-fixture-view f) (av-fixture-control-input f) (length bytes) (av-bytes (length bytes)))))
           (setf (av-fixture-input f)
                 (io:apri-lettura "/active-fixture/9.seg" :backend (av-fixture-backend f) :max-transfer max-transfer))
           (av-clear f) (funcall thunk f))
      (dolist (input (list (av-fixture-input f) (av-fixture-control-input f)))
        (when (and input (not (eq :closed (io:stato-file input)))) (io:chiudi input))))))

(defun av-call (f &rest options)
  (apply #'ar:leggi-active-recuperato (av-fixture-control f) (av-fixture-input f)
         (av-fixture-size f) (av-fixture-decisions f) (av-fixture-scratch f) options))

(defun av-noeffects (f)
  (is (equalp (av-fixture-source f) (av-fixture-reference f)))
  (is (equalp (av-fixture-identity f) (av-identity)))
  (is (equalp (arcdocdb.get::vista-get-serie-identity (av-fixture-view f)) (av-identity)))
  (dolist (input (list (av-fixture-input f) (av-fixture-control-input f)))
    (is (eq :input (io:mode-file input))) (is (eq :open (io:stato-file input)))
    (is (zerop (io:posizione-scritta input))) (is (zerop (io:posizione-durevole input))))
  (is (notany (lambda (event) (member (first event) '(:write :flush :directory-flush :rename :close)))
              (av-events f))))

(defun av-expect (type reason thunk &optional (offset nil offset-p))
  (let ((condition
          (handler-case (progn (funcall thunk) nil)
            (invalid-argument (c) c) (resource-exhausted (c) c) (corruption-detected (c) c)
            (invariant-violation (c) c) (unsupported-format (c) c) (io-fault (c) c) (type-error (c) c))))
    (is (typep condition type))
    (when reason (is (eq reason (error-reason condition))))
    (when offset-p (is (= offset (error-offset condition))))
    condition))
