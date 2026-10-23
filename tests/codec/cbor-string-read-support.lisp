;;;; Corpus freddo REQ-CBR-009, prima del nuovo lettore di prodotto.
(defpackage #:arcdocdb.cbor.string.read.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:corruption-detected #:error-reason #:error-offset)
  (:import-from #:arcdocdb.cbor.structure.tests #:cs-snapshot #:cs-unchanged-p
                #:cs-wait #:cs-join #:cs-stop-workers)
  (:export #:run))
(in-package #:arcdocdb.cbor.string.read.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test della lettura delle stringhe CBOR minime superati.~%" (length *tests*)) t)

(defun csr-fixture (contents tail &key (prefix 7) (suffix 5))
  "Sentinelle posizionali su tutto il buffer, anche oltre la finestra autorizzata."
  (let* ((end (+ prefix (length contents) (length tail)))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8))))
    (dotimes (i (length buffer)) (setf (aref buffer i) (mod (+ #xa7 (* i 37)) 256)))
    (replace buffer contents :start1 prefix)
    (replace buffer tail :start1 (+ prefix (length contents)))
    (values buffer prefix end)))

(defun csr-argument (major argument)
  "Testata minima aritmetica fredda; nessun writer o reader di prodotto come oracolo."
  (let* ((width (cond ((< argument 24) 0) ((< argument 256) 1)
                      ((< argument 65536) 2) ((< argument #x100000000) 4) (t 8)))
         (ai (if (zerop width) argument (case width (1 24) (2 25) (4 26) (8 27)))))
    (cons (+ (* major 32) ai)
          (loop for power from (1- width) downto 0
                collect (mod (floor argument (expt 256 power)) 256)))))

(defun csr-accept (buffer start end major payload next &rest keys)
  "Tre fixnum esatti, nessuna copia restituita e intero array fisico immutato."
  (let ((before (cs-snapshot buffer)))
    (unwind-protect
         (let ((actual (multiple-value-list
                        (apply #'arcdocdb.cbor:leggi-stringa-cbor-minima buffer start end keys))))
           (is (= 3 (length actual))) (is (equal (list major payload next) actual))
           (is (every (lambda (value) (and (typep value 'fixnum) (<= 0 value))) actual))
           (is (<= 2 major 3)) (is (< start payload)) (is (<= payload next end)) actual)
      (is (cs-unchanged-p buffer before)))))

(defun csr-reject (buffer start end type reason offset &rest keys)
  "Rifiuto tipizzato e assoluto, nessun ritorno normale; preserva tutto il backing array."
  (let ((before (cs-snapshot buffer)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (multiple-value-list
                       (apply #'arcdocdb.cbor:leggi-stringa-cbor-minima buffer start end keys))
                      (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed))) (is (eql offset (error-offset observed))) t)
      (is (cs-unchanged-p buffer before)))))

(defun csr-probe (contents major header-size)
  "Due allineamenti e quattro code: vuota, scalare valido e due code malformate."
  (dolist (prefix '(0 7))
    (dolist (tail '(nil (0) (#xff) (#x1c #x18 0)))
      (multiple-value-bind (buffer start end) (csr-fixture contents tail :prefix prefix)
        (csr-accept buffer start end major (+ start header-size) (+ start (length contents)))))))

(defun csr-token (buffer major payload next)
  (+ (* 17 major) (* 31 payload) next
     (loop for i below (length buffer) sum (* (1+ i) (aref buffer i)))))

(defun csr-worker (index buffer start end expected token before rounds
                   ready go done starts firsts finishes sinks)
  "WALL comprende primo item verificato, rendezvous e controlli; niente tempo puro decoder."
  (handler-case
      (progn
        (dotimes (wave 2)
          (setf (aref starts index wave) (get-internal-real-time))
          (let ((sink 0))
            (dotimes (iteration rounds)
              (let ((actual (multiple-value-list
                             (arcdocdb.cbor:leggi-stringa-cbor-minima buffer start end))))
                (is (= 3 (length actual))) (is (equal expected actual))
                (is (every (lambda (value) (typep value 'fixnum)) actual))
                (is (equalp before buffer)) (is (< start (second actual)))
                (is (<= (second actual) (third actual) end))
                (incf sink (apply #'csr-token buffer actual)))
              (when (zerop iteration)
                (setf (aref firsts index wave) (get-internal-real-time))
                (sb-thread:signal-semaphore (svref ready wave)) (cs-wait (svref go wave))))
            (is (= sink (* rounds token))) (setf (aref sinks index wave) sink))
          (setf (aref finishes index wave) (get-internal-real-time))
          (sb-thread:signal-semaphore (svref done wave)))
        :ok)
    (error (condition) condition)))
