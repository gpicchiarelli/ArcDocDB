;;;; Corpus REQ-CBR-004 dal metodo preregistrato, prima del nuovo prodotto.
;;;; Oracolo aritmetico derivato dai vecchi test IEEE, senza helper del writer.
(defpackage #:arcdocdb.cbor.float.write.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:error-reason #:error-offset)
  (:import-from #:arcdocdb.cbor.tests #:cbor-snapshot #:cbor-unchanged-p
                #:cbor-wait #:cbor-join #:cbor-stop-workers)
  (:export #:run))
(in-package #:arcdocdb.cbor.float.write.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test della scrittura dei float CBOR superati.~%" (length *tests*)) t)

(defparameter *cfw-offsets* '(0 1 2 3 7 15 31 63))

(defun cfw-format (size)
  "Parametri IEEE generali: esponente, frazione e bias; soltanto oracolo freddo."
  (or (cdr (assoc size '((16 5 10 15) (32 8 23 127) (64 11 52 1023))))
      (error "Formato IEEE del corpus sconosciuto: ~S" size)))

(defun cfw-description (bits size)
  "Classe, segno, valore razionale o payload NaN e precisione originale.
Interi boxed e razionali sono ammessi solo nell'oracolo dei test."
  (destructuring-bind (e p bias) (cfw-format size)
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

(defun cfw-binary-exponent (value)
  "floor(log2(value)) mediante interi, senza LOG e senza float Common Lisp."
  (assert (plusp value))
  (let ((candidate (- (integer-length (numerator value))
                      (integer-length (denominator value)))))
    (if (< value (expt 2 candidate)) (1- candidate) candidate)))

(defun cfw-encode-finite (value e p bias)
  "Codifica esatta di un razionale positivo; NIL quando richiede arrotondamento."
  (assert (plusp value))
  (let ((minimum-normal (expt 2 (- 1 bias)))
        (maximum-exponent (- (expt 2 e) 2 bias)))
    (if (< value minimum-normal)
        (let ((units (/ value (expt 2 (- 1 bias p)))))
          (when (and (integerp units) (<= 1 units (1- (expt 2 p)))) units))
        (let* ((power (cfw-binary-exponent value))
               (significand (/ value (expt 2 (- power p)))))
          (when (and (<= (- 1 bias) power maximum-exponent)
                     (integerp significand)
                     (<= (expt 2 p) significand (1- (expt 2 (1+ p)))))
            (+ (* (+ power bias) (expt 2 p)) (- significand (expt 2 p))))))))

(defun cfw-encode (description size)
  "Codifica razionale indipendente; NaN preserva significando, quiet/signaling e segno."
  (destructuring-bind (class sign datum original-p) description
    (destructuring-bind (e p bias) (cfw-format size)
      (let ((body
              (case class
                (:zero 0)
                (:infinity (* (1- (expt 2 e)) (expt 2 p)))
                (:finite (cfw-encode-finite datum e p bias))
                (:nan
                 (let ((payload (* datum (expt 2 (- p original-p)))))
                   (when (and (integerp payload) (<= 1 payload (1- (expt 2 p))))
                     (+ (* (1- (expt 2 e)) (expt 2 p)) payload))))
                (otherwise (error "Classe del corpus sconosciuta: ~S" class)))))
        (when body (+ (* sign (expt 2 (1- size))) body))))))

(defun cfw-same-description-p (left right)
  (and (eq (first left) (first right)) (= (second left) (second right))
       (if (eq (first left) :nan)
           (= (/ (third left) (expt 2 (fourth left)))
              (/ (third right) (expt 2 (fourth right))))
           (= (third left) (third right)))))

(defun cfw-octets (bits width)
  "Big-endian aritmetico freddo, senza pack/unpack di prodotto."
  (loop for power from (1- width) downto 0
        collect (mod (floor bits (expt 256 power)) 256)))

(defun cfw-input (size bits)
  (list (ecase size (16 25) (32 26) (64 27))
        (floor bits 4294967296) (mod bits 4294967296)))

(defun cfw-reference (ai high low)
  "Sceglie la prima codifica IEEE esatta per classe/valore razionale, non per shift."
  (let* ((size (ecase ai (25 16) (26 32) (27 64)))
         (bits (+ (* high 4294967296) low))
         (description (cfw-description bits size)))
    (dolist (candidate '(16 32 64))
      (when (<= candidate size)
        (let ((encoded (cfw-encode description candidate)))
          (when encoded
            (return-from cfw-reference
              (cons (ecase candidate (16 #xf9) (32 #xfa) (64 #xfb))
                    (cfw-octets encoded (/ candidate 8))))))))
    (error "Nessuna codifica esatta per input IEEE valido.")))

(defun cfw-destination (capacity &key (prefix 3) (suffix 11))
  (let* ((end (+ prefix capacity))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8))))
    (dotimes (i (length buffer)) (setf (aref buffer i) (mod (+ #xa7 (* i 37)) 256)))
    (values buffer prefix end)))

(defun cfw-accept (buffer start end ai high low &optional cold-wire)
  "Un solo NEXT fixnum e confronto dell'intero array con byte freddi e sentinelle."
  (let* ((wire (or cold-wire (cfw-reference ai high low)))
         (next (+ start (length wire))) (expected (copy-seq buffer)))
    (replace expected wire :start1 start)
    (let ((actual (multiple-value-list
                   (arcdocdb.cbor:scrivi-float-cbor-minimo buffer start end ai high low))))
      (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
      (is (= next (first actual))) (is (<= start next end))
      (is (equalp expected buffer)) (first actual))))

(defun cfw-reject (buffer start end ai high low type reason)
  "Tipo/reason/offset NIL e intero array fisico intatto anche con errore pubblico."
  (let ((before (cbor-snapshot buffer)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (arcdocdb.cbor:scrivi-float-cbor-minimo buffer start end ai high low)
                      (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed)))
           (is (null (error-offset observed))) t)
      (is (cbor-unchanged-p buffer before)))))

(defun cfw-probe (size bits &optional literal)
  "Tutti gli offset, span esatto/residuo e tutte le capacita insufficienti della forma scelta."
  (destructuring-bind (ai high low) (cfw-input size bits)
    (let ((wire (cfw-reference ai high low)))
      (when literal (is (equal literal wire)))
      (dolist (prefix *cfw-offsets*)
        (dolist (configuration '((0 0) (0 11) (7 11)))
          (destructuring-bind (slack suffix) configuration
            (multiple-value-bind (buffer start end)
                (cfw-destination (+ (length wire) slack) :prefix prefix :suffix suffix)
              (cfw-accept buffer start end ai high low wire))))
        (dotimes (capacity (length wire))
          (multiple-value-bind (buffer start end)
              (cfw-destination capacity :prefix prefix :suffix 19)
            (cfw-reject buffer start end ai high low 'resource-exhausted :cbor-float-capacity)))))))

(defun cfw-neighbors (bits size)
  (remove-if-not (lambda (value) (<= 0 value (1- (expt 2 (1- size)))))
                 (list (1- bits) bits (1+ bits))))

(defun cfw-plan (start end before inputs)
  "Piano immutabile: AI/HIGH/LOW/NEXT/token/intero array, preparato freddo."
  (mapcar (lambda (input)
            (destructuring-bind (ai high low) input
              (let* ((wire (cfw-reference ai high low)) (next (+ start (length wire)))
                     (expected (copy-seq before)))
                (replace expected wire :start1 start)
                (list ai high low start end next
                      (+ next (first wire) (car (last wire))) expected)))) inputs))

(defun cfw-copy-plan (plan)
  (mapcar (lambda (item) (append (subseq item 0 7) (list (copy-seq (eighth item))))) plan))

(defun cfw-worker (index buffer before plan rounds ready go done starts firsts ends sinks)
  "Due ondate: rendezvous dopo il primo item verificato, destinazione e piani privati.
Il WALL della fixture include rendezvous e controlli; non misura il tempo puro dell'encoder."
  (handler-case
      (progn
        (dotimes (wave 2)
          (setf (aref starts index wave) (get-internal-real-time))
          (let ((sink 0) (cursor plan))
            (dotimes (iteration rounds)
              (destructuring-bind (ai high low start end next token expected) (first cursor)
                (declare (ignore token)) (replace buffer before)
                (let ((actual (multiple-value-list
                               (arcdocdb.cbor:scrivi-float-cbor-minimo
                                buffer start end ai high low))))
                  (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
                  (is (= next (first actual))) (is (equalp expected buffer))
                  (incf sink (+ (first actual) (aref buffer start) (aref buffer (1- next))))))
              (setf cursor (or (rest cursor) plan))
              ;; Nessun worker termina l'onda prima del primo item verificato dell'altro.
              (when (zerop iteration)
                (setf (aref firsts index wave) (get-internal-real-time))
                (sb-thread:signal-semaphore (svref ready wave))
                (cbor-wait (svref go wave))))
            (is (= sink (* (floor rounds (length plan)) (reduce #'+ plan :key #'seventh))))
            (setf (aref sinks index wave) sink))
          (setf (aref ends index wave) (get-internal-real-time))
          (sb-thread:signal-semaphore (svref done wave)))
        :ok)
    (error (condition) condition)))
