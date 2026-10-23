;;;; Oracoli freddi indipendenti: RFC 8949 4.1/4.2.1 e aritmetica IEEE.
;;; Nessun nuovo sorgente cbor-minimal/cbor-float letto prima del freeze.
(defpackage #:arcdocdb.cbor.minimal.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:corruption-detected #:error-reason #:error-offset)
  (:import-from #:arcdocdb.cbor.tests #:cbor-fixture #:cbor-snapshot
                #:cbor-unchanged-p #:cbor-big-endian #:cbor-wait
                #:cbor-join #:cbor-stop-workers)
  (:export #:run))
(in-package #:arcdocdb.cbor.minimal.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test delle testate CBOR minime superati.~%" (length *tests*)) t)

(defun cm-format (size)
  "Parametri generali IEEE: bit esponente, bit frazione, bias."
  (or (cdr (assoc size '((16 5 10 15) (32 8 23 127) (64 11 52 1023))))
      (error "Formato IEEE dell'oracolo sconosciuto: ~S" size)))

(defun cm-description (bits size)
  "Classe, segno, grandezza razionale o significando NaN, larghezza originale.
Interi boxed e rapporti sono ammessi SOLO in questo oracolo freddo."
  (destructuring-bind (e p bias) (cm-format size)
    (let* ((sign (floor bits (expt 2 (1- size))))
           (body (mod bits (expt 2 (1- size))))
           (exponent (floor body (expt 2 p))) (fraction (mod body (expt 2 p))))
      (assert (<= 0 sign 1))
      (cond ((= exponent (1- (expt 2 e)))
             (list (if (zerop fraction) :infinity :nan) sign fraction p))
            ((and (zerop exponent) (zerop fraction)) (list :zero sign 0 p))
            (t (list :finite sign
                     (* (if (zerop exponent) fraction (+ (expt 2 p) fraction))
                        (expt 2 (- (if (zerop exponent) 1 exponent) bias p))) p))))))

(defun cm-binary-exponent (positive-rational)
  "floor(log2(value)) ricavato da interi, senza LOG o float nativi."
  (assert (plusp positive-rational))
  (let ((candidate (- (integer-length (numerator positive-rational))
                      (integer-length (denominator positive-rational)))))
    (if (< positive-rational (expt 2 candidate)) (1- candidate) candidate)))

(defun cm-encode-finite (value e p bias)
  "Codifica esatta generale di un razionale positivo; NIL se non rappresentabile."
  (assert (plusp value))
  (let* ((minimum-normal (expt 2 (- 1 bias)))
         (maximum-exponent (- (expt 2 e) 2 bias)))
    (if (< value minimum-normal)
        (let ((units (/ value (expt 2 (- 1 bias p)))))
          (when (and (integerp units) (<= 1 units (1- (expt 2 p)))) units))
        (let* ((power (cm-binary-exponent value))
               (significand (/ value (expt 2 (- power p)))))
          (when (and (<= (- 1 bias) power maximum-exponent)
                     (integerp significand)
                     (<= (expt 2 p) significand (1- (expt 2 (1+ p)))))
            (+ (* (+ power bias) (expt 2 p)) (- significand (expt 2 p))))))))

(defun cm-encode-description (description size)
  "Codifica esatta indipendente; NaN conserva segno e significando zero-padded.
Non converte NaN in float nativo, non quieta signaling, non canonizza payload."
  (destructuring-bind (class sign datum original-p) description
    (destructuring-bind (e p bias) (cm-format size)
      (let ((body
              (case class
                (:zero 0)
                (:infinity (* (1- (expt 2 e)) (expt 2 p)))
                (:finite (cm-encode-finite datum e p bias))
                (:nan
                 (let ((shortened (* datum (expt 2 (- p original-p)))))
                   (when (and (integerp shortened)
                              (<= 1 shortened (1- (expt 2 p))))
                     (+ (* (1- (expt 2 e)) (expt 2 p)) shortened))))
                (otherwise (error "Classe dell'oracolo sconosciuta: ~S" class)))))
        (when body (+ (* sign (expt 2 (1- size))) body))))))

(defun cm-float-minimal-p (bits size)
  (if (= size 16) t
      (null (cm-encode-description (cm-description bits size)
                                  (if (= size 32) 16 32)))))

(defun cm-same-description-p (a b)
  "Equivalenza esatta di classe, segno e valore, incluso il significando NaN."
  (and (eq (first a) (first b)) (= (second a) (second b))
       (if (eq (first a) :nan)
           (= (/ (third a) (expt 2 (fourth a)))
              (/ (third b) (expt 2 (fourth b))))
           (= (third a) (third b)))))

(defun cm-reference (buffer start end)
  "Modello sintattico aritmetico, poi filtro locale. Nessun helper prodotto.
Lista dei sei valori o NIL/tipo/reason/offset, con sintassi prima del minimo."
  (unless (and (typep buffer '(simple-array (unsigned-byte 8) (*)))
               (typep start 'fixnum) (typep end 'fixnum) (<= 0 start end (length buffer)))
    (return-from cm-reference (values nil 'invalid-argument :cbor-range nil)))
  (when (= start end)
    (return-from cm-reference (values nil 'corruption-detected :cbor-truncated end)))
  (let* ((lead (aref buffer start)) (major (floor lead 32)) (ai (mod lead 32)))
    (when (<= 28 ai 30)
      (return-from cm-reference (values nil 'corruption-detected :cbor-reserved start)))
    (when (= ai 31)
      (return-from cm-reference
        (values nil 'corruption-detected
                (if (member major '(0 1 6)) :cbor-indefinite :cbor-nonminimal) start)))
    (when (< ai 24)
      (return-from cm-reference (values (list major ai 0 ai (1+ start) :argument))))
    (let* ((width (expt 2 (- ai 24))) (next (+ start 1 width)) (argument 0))
      (when (> next end)
        (return-from cm-reference (values nil 'corruption-detected :cbor-truncated end)))
      (loop for position from (1+ start) below next
            do (setf argument (+ (* argument 256) (aref buffer position))))
      (when (and (= major 7) (= ai 24) (< argument 32))
        (return-from cm-reference (values nil 'corruption-detected :cbor-simple (1+ start))))
      (when (if (< major 7)
                (< argument (nth (- ai 24) '(24 256 65536 4294967296)))
                (and (> ai 24) (not (cm-float-minimal-p argument (* width 8)))))
        (return-from cm-reference (values nil 'corruption-detected :cbor-nonminimal start)))
      (values (list major ai (floor argument 4294967296) (mod argument 4294967296)
                    next :argument)))))

(defun cm-accept (buffer start end expected)
  (let ((before (cbor-snapshot buffer)))
    (unwind-protect
         (let ((actual (multiple-value-list (arcdocdb.cbor:leggi-header-cbor-minimo buffer start end))))
           (is (= (length actual) 6)) (is (equal actual expected))
           (is (every (lambda (v) (and (typep v 'fixnum) (<= 0 v))) (subseq actual 0 5)))
           (is (typep (third actual) '(unsigned-byte 32)))
           (is (typep (fourth actual) '(unsigned-byte 32)))
           (is (eq (sixth actual) :argument)) actual)
      (is (cbor-unchanged-p buffer before)))))

(defun cm-reject (buffer start end type reason offset)
  (let ((before (cbor-snapshot buffer)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (arcdocdb.cbor:leggi-header-cbor-minimo buffer start end) (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq (error-reason observed) reason))
           (is (eql (error-offset observed) offset)) t)
      (is (cbor-unchanged-p buffer before)))))

(defun cm-compare (buffer start end)
  (multiple-value-bind (expected type reason offset) (cm-reference buffer start end)
    (if expected (progn (cm-accept buffer start end expected) (values t nil))
        (progn (cm-reject buffer start end type reason offset) (values nil reason)))))

(defun cm-set-argument (buffer start argument width)
  (replace buffer (cbor-big-endian argument width) :start1 (1+ start)) buffer)
(defun cm-header-fixture (major ai argument &key (prefix 5))
  (cbor-fixture (cons (+ (* major 32) ai)
                      (if (< ai 24) nil (cbor-big-endian argument (expt 2 (- ai 24)))))
                :prefix prefix))
(defun cm-float-fixture (size bits)
  (cm-header-fixture 7 (ecase size (16 25) (32 26) (64 27)) bits))

(defun cm-neighbors (bits size)
  "Adiacenze di codifiche positive: test freddo di confini e significandi."
  (remove-if-not (lambda (n) (<= 0 n (1- (expt 2 (1- size)))))
                 (list (1- bits) bits (1+ bits))))
