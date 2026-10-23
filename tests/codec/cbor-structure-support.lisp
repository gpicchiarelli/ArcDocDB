;;;; Supporto e oracolo freddo della struttura CBOR, senza parser di prodotto.
(defpackage #:arcdocdb.cbor.structure.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:corruption-detected #:invariant-violation
                #:error-reason #:error-offset)
  (:export #:run))
(in-package #:arcdocdb.cbor.structure.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test della struttura CBOR superati.~%" (length *tests*))
  t)

(defun cs-fixture (contents &key (prefix 7) (suffix 5))
  "Sentinelle FF su entrambi i lati dello span dichiarato."
  (let* ((end (+ prefix (length contents)))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8)
                             :initial-element #xff)))
    (replace buffer contents :start1 prefix)
    (values buffer prefix end)))

(defun cs-snapshot (buffer)
  "Include tutte le celle, anche oltre il fill pointer di un buffer invalido."
  (cond ((and (vectorp buffer) (array-has-fill-pointer-p buffer))
         (list (fill-pointer buffer)
               (loop for i below (array-total-size buffer)
                     collect (row-major-aref buffer i))))
        ((vectorp buffer) (copy-seq buffer))
        ((arrayp buffer)
         (loop for i below (array-total-size buffer) collect (row-major-aref buffer i)))
        ((listp buffer) (copy-tree buffer))
        (t buffer)))

(defun cs-unchanged-p (buffer before)
  (cond ((and (vectorp buffer) (array-has-fill-pointer-p buffer))
         (and (= (first before) (fill-pointer buffer))
              (equalp (second before)
                      (loop for i below (array-total-size buffer)
                            collect (row-major-aref buffer i)))))
        ((and (arrayp buffer) (not (vectorp buffer)))
         (equalp before (loop for i below (array-total-size buffer)
                             collect (row-major-aref buffer i))))
        (t (equalp before buffer))))

(defun cs-accept (buffer start end workspace expected &rest keys)
  "Esattamente nodi, picco dei contenitori e fine; intero input immutabile."
  (let ((before (cs-snapshot buffer)))
    (unwind-protect
         (let ((actual (multiple-value-list
                        (apply #'arcdocdb.cbor:verifica-struttura-cbor
                               buffer start end workspace keys))))
           (is (= 3 (length actual)))
           (is (equal expected actual))
           (is (every (lambda (value) (and (typep value 'fixnum) (<= 0 value))) actual))
           (is (= end (third actual)))
           actual)
      (is (cs-unchanged-p buffer before)))))

(defun cs-reject (buffer start end workspace type reason offset &rest keys)
  "Rifiuto tipizzato completo, nessun ritorno normale e nessuna modifica all'input."
  (let ((before (cs-snapshot buffer)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn
                 (apply #'arcdocdb.cbor:verifica-struttura-cbor
                        buffer start end workspace keys)
                 (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned))
           (is (typep observed type))
           (is (eq reason (error-reason observed)))
           (is (eql offset (error-offset observed)))
           t)
      (is (cs-unchanged-p buffer before)))))

(defun cs-wait (semaphore)
  (unless (sb-thread:wait-on-semaphore semaphore :timeout 15)
    (error "Semaforo della fixture struttura CBOR oltre 15 secondi.")))

(defun cs-join (thread)
  (let ((result (sb-thread:join-thread thread :timeout 20 :default :timeout)))
    (when (typep result 'error) (error result))
    (is (eq :ok result))))

(defun cs-stop-workers (threads)
  "Cleanup limitato dei soli worker della fixture, con cessazione verificata."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 1 :default :terminated)
    (is (not (sb-thread:thread-alive-p thread))))
  nil)

;;; Stato privato allocato SOLO dal modello freddo; nessuno scratch del prodotto.
(defstruct (cs-ref-state (:constructor cs-make-ref-state))
  buffer end cursor (nodes 0) (peak 0) max-nodes max-depth exit)

(defun cs-ref-fail (state reason offset &optional (type 'corruption-detected))
  (throw (cs-ref-state-exit state) (list nil type reason offset)))

(defun cs-strict-utf8-accepted-p (buffer start end)
  "SBCL e' usato solo per confermare l'accettazione, mai per motivi o offset."
  (handler-case
      (progn (sb-ext:octets-to-string buffer :start start :end end
                                           :external-format :utf-8)
             t)
    (sb-int:character-decoding-error () nil)))

(defun cs-ref-utf8 (buffer start end)
  "Grammatica RFC 3629 manuale: disponibilita, continuazioni, restrizioni scalari."
  (let ((cursor start))
    (loop while (< cursor end)
          do (let* ((lead (aref buffer cursor))
                    (width (cond ((<= lead #x7f) 1)
                                 ((<= #xc2 lead #xdf) 2)
                                 ((<= #xe0 lead #xef) 3)
                                 ((<= #xf0 lead #xf4) 4)
                                 (t (return-from cs-ref-utf8
                                      (values nil :utf8-leading cursor)))))
                    (next (+ cursor width)))
               (when (> next end)
                 (return-from cs-ref-utf8 (values nil :utf8-truncated end)))
               (loop for position from (1+ cursor) below next
                     unless (<= #x80 (aref buffer position) #xbf)
                       do (return-from cs-ref-utf8
                            (values nil :utf8-continuation position)))
               (when (> width 1)
                 (let ((second (aref buffer (1+ cursor))))
                   (when (or (and (= lead #xe0) (< second #xa0))
                             (and (= lead #xed) (> second #x9f))
                             (and (= lead #xf0) (< second #x90))
                             (and (= lead #xf4) (> second #x8f)))
                     (return-from cs-ref-utf8
                       (values nil :utf8-scalar (1+ cursor))))))
               (setf cursor next))))
  (is (cs-strict-utf8-accepted-p buffer start end))
  (values t nil nil))

(defun cs-ref-payload (state major high low)
  "La disponibilita dell'intero payload precede ogni controllo UTF-8."
  (let* ((cursor (cs-ref-state-cursor state))
         (end (cs-ref-state-end state)) (room (- end cursor)))
    (when (or (plusp high) (> low room))
      (cs-ref-fail state :cbor-truncated end))
    (let ((next (+ cursor low)))
      (when (= major 3)
        (multiple-value-bind (accepted reason offset)
            (cs-ref-utf8 (cs-ref-state-buffer state) cursor next)
          (unless accepted (cs-ref-fail state reason offset))))
      (setf (cs-ref-state-cursor state) next)))
  :item)

(defun cs-ref-indefinite-string (state major depth recursion)
  "Ogni chunk e' un nodo distinto, definito e dello stesso major type."
  (loop until (eq :break (cs-ref-item state depth (1+ recursion)
                                    :indef-string major)))
  :item)

(defun cs-ref-container (state major high low form depth recursion lead)
  "Solo mappe/array aumentano la profondita; le chiavi sono figli ordinari."
  (when (>= depth (cs-ref-state-max-depth state))
    (cs-ref-fail state :cbor-depth-budget lead 'resource-exhausted))
  (let ((next-depth (1+ depth)))
    (setf (cs-ref-state-peak state) (max next-depth (cs-ref-state-peak state)))
    (if (eq form :indefinite)
        (if (= major 4)
            (loop until (eq :break (cs-ref-item state next-depth (1+ recursion)
                                              :indef-array)))
            (loop for key = (cs-ref-item state next-depth (1+ recursion) :indef-map-key)
                  until (eq key :break)
                  do (cs-ref-item state next-depth (1+ recursion) :indef-map-value)))
        (let* ((room (- (cs-ref-state-end state) (cs-ref-state-cursor state)))
               (arity (if (= major 5) 2 1)))
          (when (or (plusp high) (> low (floor room arity)))
            (cs-ref-fail state :cbor-truncated (cs-ref-state-end state)))
          (loop repeat (* low arity)
                do (cs-ref-item state next-depth (1+ recursion) :definite)))))
  :item)

(defun cs-ref-item (state depth recursion context &optional chunk-major)
  "Ricorsione indipendente: un tag attende un item prima di consumare arita."
  (let ((lead (cs-ref-state-cursor state)))
    (multiple-value-bind (header reason offset)
        (arcdocdb.cbor.tests::cbor-reference
         (cs-ref-state-buffer state) lead (cs-ref-state-end state))
      (unless header (cs-ref-fail state reason offset))
      (when (> recursion 64)
        (error "Oracolo struttura CBOR oltre le 64 chiamate ricorsive ammesse."))
      (destructuring-bind (major ai high low next form) header
        (declare (ignore ai))
        (when (eq form :break)
          (case context
            (:tag (cs-ref-fail state :cbor-tag-break lead))
            (:indef-map-value (cs-ref-fail state :cbor-map-value lead))
            ((:indef-array :indef-map-key :indef-string) nil)
            (otherwise (cs-ref-fail state :cbor-break lead)))
          (setf (cs-ref-state-cursor state) next)
          (return-from cs-ref-item :break))
        (when (and chunk-major
                   (or (/= major chunk-major) (not (eq form :argument))))
          (cs-ref-fail state :cbor-chunk-type lead))
        (when (>= (cs-ref-state-nodes state) (cs-ref-state-max-nodes state))
          (cs-ref-fail state :cbor-node-budget lead 'resource-exhausted))
        (incf (cs-ref-state-nodes state))
        (setf (cs-ref-state-cursor state) next)
        (case major
          ((0 1 7) :item)
          ((2 3) (if (eq form :indefinite)
                     (cs-ref-indefinite-string state major depth recursion)
                     (cs-ref-payload state major high low)))
          ((4 5) (cs-ref-container state major high low form depth recursion lead))
          (6 (cs-ref-item state depth (1+ recursion) :tag) :item)
          (otherwise (error "Major type non rappresentabile nell'oracolo.")))))))

(defun cs-reference (buffer start end &key (max-bytes 16777216)
                                         (max-nodes 16777216) (max-depth 100))
  "SOLO span e configurazione validi; fixture fredde/fuzz di massimo 64 byte.
Restituisce (nodi picco fine), oppure NIL/tipo/motivo/offset. Non simula lo scratch,
non usa il parser del prodotto e non decide profilo deterministico o validita tag."
  (when (> (- end start) 64)
    (error "L'oracolo struttura CBOR ammette solo fixture fino a 64 byte."))
  (when (> (- end start) max-bytes)
    (return-from cs-reference
      (values nil 'resource-exhausted :cbor-byte-budget nil)))
  (let* ((exit (gensym "CBOR-REFERENCE-EXIT"))
         (state (cs-make-ref-state :buffer buffer :end end :cursor start
                                  :max-nodes max-nodes :max-depth max-depth :exit exit))
         (result (catch exit
                   (cs-ref-item state 0 1 :root)
                   (when (< (cs-ref-state-cursor state) end)
                     (cs-ref-fail state :cbor-trailing (cs-ref-state-cursor state)))
                   (list (list (cs-ref-state-nodes state)
                               (cs-ref-state-peak state) end)))))
    (values-list result)))
