;;;; Oracoli freddi dell'encoder CBOR, congelati prima della lettura del prodotto.
(defpackage #:arcdocdb.cbor.write.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:error-reason #:error-offset)
  (:import-from #:arcdocdb.cbor.tests #:cbor-snapshot #:cbor-unchanged-p
                #:cbor-wait #:cbor-join #:cbor-stop-workers)
  (:export #:run))
(in-package #:arcdocdb.cbor.write.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test della scrittura degli header CBOR minimi superati.~%" (length *tests*))
  t)

(defun cw-reference (major high low)
  "Oracle aritmetico su argomenti validi: bignum ammessi solo in questo modello freddo.
Il valore wire e HIGH*2^32+LOW anche per MT1; nessun encoder o decoder del prodotto."
  (let* ((argument (+ (* high (expt 2 32)) low))
         (width (cond ((< argument 24) 0) ((< argument 256) 1)
                      ((< argument 65536) 2) ((< argument (expt 2 32)) 4) (t 8)))
         (additional (if (zerop width) argument
                         (case width (1 24) (2 25) (4 26) (8 27)))))
    (cons (+ (* major 32) additional)
          (loop for position from (1- width) downto 0
                collect (mod (floor argument (expt 256 position)) 256)))))

(defun cw-fixture (capacity &key (prefix 3) (suffix 11))
  "Destinazione con sentinelle diverse per posizione, anche oltre END."
  (let* ((end (+ prefix capacity))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8))))
    (dotimes (i (length buffer)) (setf (aref buffer i) (mod (+ #xa7 (* i 37)) 256)))
    (values buffer prefix end)))

(defun cw-accept (buffer start end major high low expected)
  "Un solo NEXT fixnum; confronto dell'intera destinazione, non solo del prefisso scritto."
  (let* ((before (copy-seq buffer)) (after (copy-seq buffer))
         (next (+ start (length expected))))
    (replace after expected :start1 start)
    (let ((actual (multiple-value-list
                   (arcdocdb.cbor:scrivi-header-cbor-minimo buffer start end major high low))))
      (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
      (is (= next (first actual))) (is (<= start next end))
      (is (equalp after buffer))
      (is (equalp (subseq before 0 start) (subseq buffer 0 start)))
      (is (equalp (subseq before next) (subseq buffer next)))
      (first actual))))

(defun cw-reject (buffer start end major high low type reason)
  "Tipo e motivo esatti, offset NIL, nessun ritorno normale e nessuna mutazione fisica."
  (let ((before (cbor-snapshot buffer)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (arcdocdb.cbor:scrivi-header-cbor-minimo buffer start end major high low)
                      (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed))) (is (null (error-offset observed))) t)
      (is (cbor-unchanged-p buffer before)))))

(defun cw-compare (buffer start end major high low)
  (cw-accept buffer start end major high low (cw-reference major high low)))

(defun cw-literal-major (major zero-major-header)
  "Vettori letterali MT0 trasformati solo nel campo major, senza calcolare l'argomento."
  (cons (+ (* major 32) (first zero-major-header)) (rest zero-major-header)))

(defun cw-worker-plan (index)
  "Sette header e sink derivati prima dei worker; ogni destinazione ha proprietario esclusivo."
  (let* ((arguments (if (zerop index)
                        '((0 0) (0 24) (0 256) (0 65536) (0 #xffffffff)
                          (1 0) (#x01234567 #x89abcdef))
                        '((#xffffffff #xffffffff) (1 #x10) (0 #x10203040)
                          (0 #x1234) (0 #xa5) (0 23) (0 #x01000000))))
         (specs (loop for major from 0 for (high low) in arguments
                      collect (list major high low (cw-reference major high low))))
         (payload (loop for spec in specs append (copy-list (fourth spec))))
         (prefix 3) (cursor prefix) (sink 0))
    (dolist (spec specs)
      (incf cursor (length (fourth spec)))
      (incf sink (+ cursor (first (fourth spec)))))
    (multiple-value-bind (buffer start end) (cw-fixture (+ (length payload) 4) :prefix prefix)
      (let ((expected (copy-seq buffer)))
        (replace expected payload :start1 start)
        (values buffer start end specs expected sink cursor)))))
