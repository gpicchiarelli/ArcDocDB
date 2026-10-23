;;;; Oracoli UTF-8 indipendenti: grammatica RFC 3629 e decoder SBCL senza replacement.
(defpackage #:arcdocdb.utf8.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:corruption-detected #:error-reason #:error-offset)
  (:export #:run))
(in-package #:arcdocdb.utf8.tests)

(defvar *tests* nil)
(defconstant +utf8-test-limit+ 16777216)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test UTF-8 superati.~%" (length *tests*))
  t)

(defun utf8-fixture (contents &key (prefix 7) (suffix 5))
  "Byte invalidi fuori dallo span rendono osservabile ogni sconfinamento."
  (let* ((end (+ prefix (length contents)))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8)
                             :initial-element #xff)))
    (replace buffer contents :start1 prefix)
    (values buffer prefix end)))

(defun utf8-snapshot (buffer)
  (cond ((and (vectorp buffer) (array-has-fill-pointer-p buffer))
         (list (fill-pointer buffer)
               (loop for i below (array-total-size buffer) collect (row-major-aref buffer i))))
        ((vectorp buffer) (copy-seq buffer))
        ((arrayp buffer) (loop for i below (array-total-size buffer) collect (row-major-aref buffer i)))
        ((listp buffer) (copy-tree buffer))
        (t buffer)))

(defun utf8-unchanged-p (buffer before)
  (cond ((and (vectorp buffer) (array-has-fill-pointer-p buffer))
         (and (= (first before) (fill-pointer buffer))
              (equalp (second before)
                      (loop for i below (array-total-size buffer) collect (row-major-aref buffer i)))))
        ((and (arrayp buffer) (not (vectorp buffer)))
         (equalp before (loop for i below (array-total-size buffer) collect (row-major-aref buffer i))))
        (t (equalp before buffer))))

(defun utf8-accept (buffer start end expected &rest options)
  "Controlla un solo risultato, conteggio fixnum e immutabilita dell'intero input."
  (let ((before (utf8-snapshot buffer)))
    (unwind-protect
         (let ((values (multiple-value-list
                        (apply #'arcdocdb.utf8:verifica-utf8 buffer start end options))))
           (is (= 1 (length values)))
           (is (and (typep (first values) 'fixnum) (<= 0 (first values))
                    (= expected (first values))))
           (first values))
      (is (utf8-unchanged-p buffer before)))))

(defun utf8-reject (buffer start end type reason &key (offset nil offset-p)
                                                       (max-bytes +utf8-test-limit+))
  "Gli errori semantici hanno offset manuali; nessun valore normale prima del rifiuto."
  (let ((before (utf8-snapshot buffer)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (arcdocdb.utf8:verifica-utf8 buffer start end :max-bytes max-bytes)
                      (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed)))
           (when offset-p (is (eql offset (error-offset observed))))
           t)
      (is (utf8-unchanged-p buffer before)))))

(defun utf8-strict-reference (buffer start end)
  "SOLO validita/count. SBCL controlla certe continuation prima delle troncature.
Non usare i suoi motivi/offset come oracolo del contratto del prodotto."
  (handler-case
      (values t (length (sb-ext:octets-to-string buffer :start start :end end
                                                    :external-format :utf-8)))
    (sb-int:character-decoding-error () (values nil nil))))

(defun utf8-encode-scalars (scalars)
  "Encoding bit per bit di scalar gia scelti; non riusa il classificatore del prodotto."
  (let ((octets nil) (ends nil) (length 0))
    (flet ((emit (byte) (push byte octets) (incf length)))
      (dolist (scalar scalars)
        (is (and (<= 0 scalar #x10ffff) (not (<= #xd800 scalar #xdfff))))
        (cond ((< scalar #x80) (emit scalar))
              ((< scalar #x800)
               (emit (logior #xc0 (ash scalar -6)))
               (emit (logior #x80 (logand scalar #x3f))))
              ((< scalar #x10000)
               (emit (logior #xe0 (ash scalar -12)))
               (emit (logior #x80 (logand (ash scalar -6) #x3f)))
               (emit (logior #x80 (logand scalar #x3f))))
              (t
               (emit (logior #xf0 (ash scalar -18)))
               (emit (logior #x80 (logand (ash scalar -12) #x3f)))
               (emit (logior #x80 (logand (ash scalar -6) #x3f)))
               (emit (logior #x80 (logand scalar #x3f)))))
        (push length ends)))
    (values (make-array length :element-type '(unsigned-byte 8) :initial-contents (nreverse octets))
            (nreverse ends))))

(defun utf8-wait (semaphore)
  (unless (sb-thread:wait-on-semaphore semaphore :timeout 15)
    (error "Semaforo della fixture UTF-8 oltre 15 secondi.")))

(defun utf8-join (thread)
  (let ((result (sb-thread:join-thread thread :timeout 20 :default :timeout)))
    (when (typep result 'error) (error result))
    (is (eq :ok result))))

(defun utf8-stop-workers (threads)
  "Cleanup di soli worker noti: semafori e kernel puro su buffer privati.
Verifica la cessazione dopo il join limitato anche nel percorso di errore."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 1 :default :terminated)
    (is (not (sb-thread:thread-alive-p thread))))
  nil)
