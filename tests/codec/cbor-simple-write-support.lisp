;;;; Corpus dal contratto REQ-CBR-003, preparato prima del nuovo prodotto.
(defpackage #:arcdocdb.cbor.simple.write.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:error-reason #:error-offset)
  (:import-from #:arcdocdb.cbor.tests #:cbor-snapshot #:cbor-unchanged-p
                #:cbor-wait #:cbor-join #:cbor-stop-workers)
  (:export #:run))
(in-package #:arcdocdb.cbor.simple.write.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test della scrittura dei valori semplici CBOR superati.~%" (length *tests*))
  t)

(defparameter *csw-offsets* '(0 1 2 3 7 15 31 63))

(defun csw-value-at (position)
  "Enumerazione dei 248 codici wire ammessi, senza decoder."
  (if (< position 24) position (+ position 8)))

(defun csw-reference (value)
  "Oracolo aritmetico freddo per un codice ammesso, senza codec di prodotto."
  (if (< value 24) (list (+ 224 value)) (list 248 value)))

(defun csw-destination (capacity &key (prefix 3) (suffix 9))
  (let* ((end (+ prefix capacity))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8))))
    (dotimes (i (length buffer)) (setf (aref buffer i) (mod (+ #xa7 (* i 37)) 256)))
    (values buffer prefix end)))

(defun csw-accept (buffer start end value &optional literal)
  "Arity uno, NEXT fixnum, byte freddi e intero array fisico, anche oltre END."
  (let* ((wire (csw-reference value)) (next (+ start (length wire)))
         (expected (copy-seq buffer)))
    (when literal (is (equal literal wire)))
    (replace expected wire :start1 start)
    (let ((actual (multiple-value-list
                   (arcdocdb.cbor:scrivi-semplice-cbor-minimo buffer start end value))))
      (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
      (is (= next (first actual))) (is (<= start next end))
      (is (equalp expected buffer))
      (first actual))))

(defun csw-reject (buffer start end value type reason)
  "Tipo, motivo, offset NIL e nessuna mutazione dell'intero array fisico."
  (let ((before (cbor-snapshot buffer)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (arcdocdb.cbor:scrivi-semplice-cbor-minimo buffer start end value)
                      (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed)))
           (is (null (error-offset observed))) t)
      (is (cbor-unchanged-p buffer before)))))

(defun csw-plan (start end before codes)
  "Piano freddo: codice, NEXT, token e tutti i byte attesi per ogni item."
  (mapcar (lambda (value)
            (let* ((wire (csw-reference value)) (next (+ start (length wire)))
                   (expected (copy-seq before)))
              (replace expected wire :start1 start)
              (list value start end next (+ next (first wire) (car (last wire))) expected)))
          codes))

(defun csw-copy-plan (plan)
  "Snapshot indipendente anche degli array attesi annidati nel piano."
  (mapcar (lambda (item) (append (subseq item 0 5) (list (copy-seq (sixth item))))) plan))

(defun csw-worker (index buffer before plan rounds ready go done starts firsts ends sinks)
  "Due ondate: rendezvous dopo il primo item verificato, risorse private e input immutabili.
Il WALL della fixture include rendezvous e controlli; non misura il tempo puro dell'encoder."
  (handler-case
      (progn
        (dotimes (wave 2)
          (setf (aref starts index wave) (get-internal-real-time))
          (let ((sink 0) (cursor plan))
            (dotimes (iteration rounds)
              (destructuring-bind (value start end next token expected) (first cursor)
                (declare (ignore token))
                (replace buffer before)
                (let ((actual (multiple-value-list
                               (arcdocdb.cbor:scrivi-semplice-cbor-minimo
                                buffer start end value))))
                  (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
                  (is (= next (first actual))) (is (equalp expected buffer))
                  (incf sink (+ (first actual) (aref buffer start) (aref buffer (1- next))))))
              (setf cursor (or (rest cursor) plan))
              ;; Rendezvous dopo il primo item e i suoi controlli, senza chiamate prodotto aggiuntive.
              (when (zerop iteration)
                (setf (aref firsts index wave) (get-internal-real-time))
                (sb-thread:signal-semaphore (svref ready wave))
                (cbor-wait (svref go wave))))
            (is (= sink (* (floor rounds (length plan))
                           (reduce #'+ plan :key #'fifth))))
            (setf (aref sinks index wave) sink))
          (setf (aref ends index wave) (get-internal-real-time))
          (sb-thread:signal-semaphore (svref done wave)))
        :ok)
    (error (condition) condition)))
