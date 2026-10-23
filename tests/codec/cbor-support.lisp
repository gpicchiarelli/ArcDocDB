;;;; Oracoli dell'header CBOR: RFC 8949, senza lettura del codec di prodotto.
(defpackage #:arcdocdb.cbor.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:corruption-detected #:error-reason #:error-offset)
  (:export #:run))
(in-package #:arcdocdb.cbor.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test degli header CBOR superati.~%" (length *tests*))
  t)

(defun cbor-fixture (contents &key (prefix 7) (suffix 5))
  (let* ((end (+ prefix (length contents)))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8)
                             :initial-element #xff)))
    (replace buffer contents :start1 prefix)
    (values buffer prefix end)))

(defun cbor-snapshot (buffer)
  (cond ((and (vectorp buffer) (array-has-fill-pointer-p buffer))
         (list (fill-pointer buffer)
               (loop for i below (array-total-size buffer) collect (row-major-aref buffer i))))
        ((vectorp buffer) (copy-seq buffer))
        ((arrayp buffer) (loop for i below (array-total-size buffer) collect (row-major-aref buffer i)))
        ((listp buffer) (copy-tree buffer))
        (t buffer)))

(defun cbor-unchanged-p (buffer before)
  (cond ((and (vectorp buffer) (array-has-fill-pointer-p buffer))
         (and (= (first before) (fill-pointer buffer))
              (equalp (second before)
                      (loop for i below (array-total-size buffer) collect (row-major-aref buffer i)))))
        ((and (arrayp buffer) (not (vectorp buffer)))
         (equalp before (loop for i below (array-total-size buffer) collect (row-major-aref buffer i))))
        (t (equalp before buffer))))

(defun cbor-accept (buffer start end expected)
  "Sei valori esatti; interi immediati e buffer interamente immutabile."
  (let ((before (cbor-snapshot buffer)))
    (unwind-protect
         (let ((actual (multiple-value-list (arcdocdb.cbor:leggi-header-cbor buffer start end))))
           (is (= 6 (length actual)))
           (is (equal expected actual))
           (is (every (lambda (value) (and (typep value 'fixnum) (<= 0 value)))
                      (subseq actual 0 5)))
           (is (<= (first actual) 7)) (is (<= (second actual) 31))
           (is (typep (third actual) '(unsigned-byte 32)))
           (is (typep (fourth actual) '(unsigned-byte 32)))
           (is (<= start (fifth actual) end))
           (is (member (sixth actual) '(:argument :indefinite :break)))
           actual)
      (is (cbor-unchanged-p buffer before)))))

(defun cbor-reject (buffer start end type reason offset)
  "Tipo, motivo e offset sono parte del contratto; nessun ritorno normale."
  (let ((before (cbor-snapshot buffer)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (arcdocdb.cbor:leggi-header-cbor buffer start end) (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed)))
           (is (eql offset (error-offset observed)))
           t)
      (is (cbor-unchanged-p buffer before)))))

(defun cbor-reference (buffer start end)
  "Modello aritmetico indipendente su span valido. Bignum ammessi SOLO nell'oracolo.
Restituisce lista dei sei valori, oppure NIL/motivo/offset; nessun parser del corpo."
  (when (= start end) (return-from cbor-reference (values nil :cbor-truncated end)))
  (let* ((lead (aref buffer start)) (major (floor lead 32)) (ai (mod lead 32)))
    (cond ((<= 28 ai 30) (values nil :cbor-reserved start))
          ((= ai 31)
           (case major
             ((0 1 6) (values nil :cbor-indefinite start))
             ((2 3 4 5) (values (list major ai 0 0 (1+ start) :indefinite) nil nil))
             (7 (values (list major ai 0 0 (1+ start) :break) nil nil))))
          ((< ai 24) (values (list major ai 0 ai (1+ start) :argument) nil nil))
          (t
           (let* ((width (nth (- ai 24) '(1 2 4 8))) (next (+ start 1 width)) (argument 0))
             (when (> next end)
               (return-from cbor-reference (values nil :cbor-truncated end)))
             (loop for position from (1+ start) below next
                   do (setf argument (+ (* argument 256) (aref buffer position))))
             (when (and (= major 7) (= ai 24) (< argument 32))
               (return-from cbor-reference (values nil :cbor-simple (1+ start))))
             (values (list major ai (floor argument 4294967296) (mod argument 4294967296)
                           next :argument) nil nil))))))

(defun cbor-compare-reference (buffer start end)
  (multiple-value-bind (expected reason offset) (cbor-reference buffer start end)
    (if expected
        (progn (cbor-accept buffer start end expected) t)
        (progn (cbor-reject buffer start end 'corruption-detected reason offset) nil))))

(defun cbor-big-endian (argument width)
  "Pack aritmetico freddo, indipendente dai lettori di parole del prodotto."
  (loop for shift from (1- width) downto 0
        collect (mod (floor argument (expt 256 shift)) 256)))

(defun cbor-wait (semaphore)
  (unless (sb-thread:wait-on-semaphore semaphore :timeout 15)
    (error "Semaforo della fixture header CBOR oltre 15 secondi.")))
(defun cbor-join (thread)
  (let ((result (sb-thread:join-thread thread :timeout 20 :default :timeout)))
    (when (typep result 'error) (error result))
    (is (eq :ok result))))
(defun cbor-stop-workers (threads)
  "Worker noti, solo semafori e kernel puro su input privato; cessazione verificata."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 1 :default :terminated)
    (is (not (sb-thread:thread-alive-p thread))))
  nil)
