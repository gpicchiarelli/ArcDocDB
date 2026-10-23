;;;; Corpus cieco prima della lettura del nuovo scanner; oracoli freddi gia congelati.
(defpackage #:arcdocdb.cbor.minimal.scan.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:corruption-detected #:error-reason #:error-offset)
  (:import-from #:arcdocdb.cbor.structure.tests #:cs-fixture #:cs-snapshot #:cs-unchanged-p
                #:cs-ref-utf8 #:cs-argument #:cs-encode-ast #:cs-wait #:cs-join #:cs-stop-workers)
  (:import-from #:arcdocdb.cbor.minimal.tests #:cm-reference)
  (:export #:run))
(in-package #:arcdocdb.cbor.minimal.scan.tests)
(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test della struttura CBOR minima superati.~%" (length *tests*))
  t)

(defun cms-space-snapshot (space)
  "Stato completo del vecchio scratch, inclusi tutti gli slot e i due array privati."
  (list (copy-seq (arcdocdb.cbor::spazio-cbor-kinds space))
        (copy-seq (arcdocdb.cbor::spazio-cbor-remaining space))
        (arcdocdb.cbor::spazio-cbor-cursor space) (arcdocdb.cbor::spazio-cbor-top space)
        (arcdocdb.cbor::spazio-cbor-nodes space) (arcdocdb.cbor::spazio-cbor-depth space)
        (arcdocdb.cbor::spazio-cbor-peak-depth space) (arcdocdb.cbor::spazio-cbor-pending-tag space)))

(defun cms-accept (buffer start end space expected &rest keys)
  "Tre valori esatti e fixnum; ogni byte del buffer resta invariato."
  (let ((before (cs-snapshot buffer)))
    (unwind-protect
         (let ((actual (multiple-value-list
                        (apply #'arcdocdb.cbor:verifica-struttura-cbor-minima
                               buffer start end space keys))))
           (is (= 3 (length actual))) (is (equal expected actual))
           (is (every (lambda (value) (and (typep value 'fixnum) (<= 0 value))) actual))
           (is (= end (third actual))) actual)
      (is (cs-unchanged-p buffer before)))))

(defun cms-reject (buffer start end space type reason offset &rest keys)
  "Tipo, motivo e offset assoluto; nessun ritorno normale, intero buffer immutabile."
  (let ((before (cs-snapshot buffer)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (apply #'arcdocdb.cbor:verifica-struttura-cbor-minima
                             buffer start end space keys)
                      (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed))) (is (eql offset (error-offset observed))) t)
      (is (cs-unchanged-p buffer before)))))

(defun cms-cold-reject (buffer start end space type reason offset &rest keys)
  "Un rifiuto di preflight non cambia neppure lo scratch gia sporco."
  (let ((before (cms-space-snapshot space)))
    (apply #'cms-reject buffer start end space type reason offset keys)
    (is (equalp before (cms-space-snapshot space)))))

(defun cms-manual-accept (contents nodes depth &rest keys)
  (multiple-value-bind (buffer start end) (cs-fixture contents)
    (apply #'cms-accept buffer start end (arcdocdb.cbor:crea-spazio-cbor)
           (list nodes depth end) keys)))

(defun cms-manual-reject (contents type reason offset &rest keys)
  (multiple-value-bind (buffer start end) (cs-fixture contents)
    (apply #'cms-reject buffer start end (arcdocdb.cbor:crea-spazio-cbor)
           type reason (if (eq offset :end) end (and offset (+ start offset))) keys)))

;;; Solo il modello freddo alloca e usa ricorsione, limitata a 64 byte/64 chiamate.
(defstruct (cms-state (:constructor cms-make-state))
  buffer end cursor (nodes 0) (peak 0) max-nodes max-depth exit)
(defun cms-ref-fail (state reason offset &optional (type 'corruption-detected))
  (throw (cms-state-exit state) (list nil type reason offset)))

(defun cms-ref-string (state major high low)
  (let* ((cursor (cms-state-cursor state)) (end (cms-state-end state)))
    (when (or (plusp high) (> low (- end cursor)))
      (cms-ref-fail state :cbor-truncated end))
    (let ((next (+ cursor low)))
      (when (= major 3)
        (multiple-value-bind (accepted reason offset)
            (cs-ref-utf8 (cms-state-buffer state) cursor next)
          (unless accepted (cms-ref-fail state reason offset))))
      (setf (cms-state-cursor state) next))))

(defun cms-ref-container (state major high low depth recursion lead)
  (when (>= depth (cms-state-max-depth state))
    (cms-ref-fail state :cbor-depth-budget lead 'resource-exhausted))
  (let* ((new-depth (1+ depth)) (arity (if (= major 5) 2 1))
         (room (- (cms-state-end state) (cms-state-cursor state))))
    (setf (cms-state-peak state) (max new-depth (cms-state-peak state)))
    (when (or (plusp high) (> low (floor room arity)))
      (cms-ref-fail state :cbor-truncated (cms-state-end state)))
    (dotimes (child (* arity low))
      (cms-ref-item state new-depth (1+ recursion)))))

(defun cms-ref-item (state depth recursion)
  "Header syntax/minimo freddo prima di nodi, profondita e payload; nessun helper prodotto."
  (let ((lead (cms-state-cursor state)))
    (multiple-value-bind (header type reason offset)
        (cm-reference (cms-state-buffer state) lead (cms-state-end state))
      (unless header (cms-ref-fail state reason offset type))
      (when (> recursion 64) (error "Modello freddo oltre 64 header validi."))
      (when (>= (cms-state-nodes state) (cms-state-max-nodes state))
        (cms-ref-fail state :cbor-node-budget lead 'resource-exhausted))
      (incf (cms-state-nodes state))
      (destructuring-bind (major ai high low next form) header
        (declare (ignore ai form))
        (setf (cms-state-cursor state) next)
        (case major
          ((0 1 7) nil)
          ((2 3) (cms-ref-string state major high low))
          ((4 5) (cms-ref-container state major high low depth recursion lead))
          (6 (cms-ref-item state depth (1+ recursion)))
          (otherwise (error "Major del modello non rappresentabile.")))))))

(defun cms-reference (buffer start end &key (max-bytes 16777216)
                                           (max-nodes 16777216) (max-depth 100))
  "Solo input/configurazioni validi e span <=64; nessuno scratch o parser prodotto."
  (when (> (- end start) 64) (error "Modello freddo oltre 64 byte."))
  (when (> (- end start) max-bytes)
    (return-from cms-reference (values nil 'resource-exhausted :cbor-byte-budget nil)))
  (let* ((exit (gensym "CMS-REF"))
         (state (cms-make-state :buffer buffer :end end :cursor start :max-nodes max-nodes
                               :max-depth max-depth :exit exit))
         (result (catch exit
                   (cms-ref-item state 0 1)
                   (when (< (cms-state-cursor state) end)
                     (cms-ref-fail state :cbor-trailing (cms-state-cursor state)))
                   (list (list (cms-state-nodes state) (cms-state-peak state) end)))))
    (values-list result)))

(defun cms-compare (buffer start end space &rest keys)
  (multiple-value-bind (expected type reason offset)
      (apply #'cms-reference buffer start end keys)
    (if expected (progn (apply #'cms-accept buffer start end space expected keys) (values t nil))
        (progn (apply #'cms-reject buffer start end space type reason offset keys)
               (values nil reason)))))

(defun cms-wide-argument (major ai argument)
  "Fixture nonminima/limite costruita aritmeticamente; nessun encoder prodotto."
  (cons (+ (* major 32) ai)
        (arcdocdb.cbor.tests::cbor-big-endian argument (expt 2 (- ai 24)))))

(defun cms-dirty-space (space)
  "Valori nel dominio degli slot; preflight non puo resetterli in caso di rifiuto."
  (fill (arcdocdb.cbor::spazio-cbor-kinds space) #xa5)
  (fill (arcdocdb.cbor::spazio-cbor-remaining space) #xdeadbeef)
  (setf (arcdocdb.cbor::spazio-cbor-cursor space) 17 (arcdocdb.cbor::spazio-cbor-top space) 7
        (arcdocdb.cbor::spazio-cbor-nodes space) 13 (arcdocdb.cbor::spazio-cbor-depth space) 5
        (arcdocdb.cbor::spazio-cbor-peak-depth space) 8
        (arcdocdb.cbor::spazio-cbor-pending-tag space) t)
  space)
