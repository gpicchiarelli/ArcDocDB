;;;; ADR-0032/0048: harness degli slot v2; nessuna prova eseguita al caricamento.
;;;; OWNER: *TESTS* e del loader seriale; ogni banco/input/output e della fixture.
;;;; SHARED: solo il banco e i semafori espliciti nelle fixture concorrenti.
;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-004 REQ-AFF-004 REQ-AFF-008
(defpackage #:arcdocdb.index.slots.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:invariant-violation #:error-reason)
  (:import-from #:arcdocdb.record #:+header-bytes+ #:+max-document-bytes+
                #:+max-record-bytes+)
  (:import-from #:arcdocdb.index.slots #:banco-slot #:crea-banco-slot
                #:leggi-slot-v2 #:pubblica-slot-v2 #:rimuovi-slot-v2
                #:riloca-slot-v2 #:credito-scrittura-slot
                #:congela-banco-slot #:invalida-banco-slot)
  (:export #:run))
(in-package #:arcdocdb.index.slots.tests)
(declaim (optimize (safety 3) (debug 3)))

(deftype slot-test-buffer () '(simple-array (unsigned-byte 64) (5)))
(deftype slot-test-word () '(unsigned-byte 64))
;;; OWNER: registrazione solo durante il caricamento seriale dei tre file di test.
(defvar *tests* nil)
(declaim (type list *tests*))

;;; REQ: REQ-AFF-003
(defmacro deftest (name &body body)
  "Pre: nome con REQ e corpo fidato. Post: definizione tipizzata registrata una volta."
  `(progn
     (declaim (ftype (function () t) ,name))
     (defun ,name () "Fixture bounded; segnala il fallimento delle asserzioni." ,@body)
     (pushnew ',name *tests*)))

;;; REQ: REQ-AFF-003 REQ-IDX-003
(declaim (ftype (function () (values (eql t) (integer 0 *) &optional)) run))
(defun run ()
  "Pre: support, slots e slot-threads caricati dal parent. Post: T e test count.
Ogni fallimento e propagato; nessun benchmark o comando di registrazione implicito."
  (let ((tests (reverse *tests*)))
    (is (>= (length tests) 25))
    (dolist (test tests)
      (funcall test)
      (format t "ok    ~A~%" test))
    (format t "~D test degli slot indice v2 superati.~%" (length tests))
    (values t (length tests))))

;;; REQ: REQ-IDX-001
(declaim (ftype (function (&rest slot-test-word) slot-test-buffer) slot-buffer))
(defun slot-buffer (&rest words)
  "Pre: cinque u64 privati. Post: buffer specializzato senza alias; errore di fixture altrimenti."
  (is (= 5 (length words)))
  (make-array 5 :element-type '(unsigned-byte 64) :initial-contents words))

;;; REQ: REQ-IDX-001 REQ-LIM-001
(declaim (ftype (function (&key (:csn slot-test-word) (:segment (unsigned-byte 32))
                               (:offset (unsigned-byte 32)) (:key-offset (unsigned-byte 32))
                               (:key-length (unsigned-byte 16)) (:document-length (unsigned-byte 32))
                               (:end slot-test-word)) slot-test-buffer) slot-payload))
(defun slot-payload (&key (csn #x8000000000000029) (segment 31) (offset 64)
                         (key-offset 32) (key-length 2) (document-length 3) (end 0))
  "Pre: campi privati rappresentabili. Post: encoding aritmetico ADR-0048, senza helper di prodotto.
Le fixture negative modificano poi una sola parola; nessun predicato valida questo oracolo."
  (slot-buffer csn (+ (* segment #x100000000) offset)
               (+ (* 1 #x1000000000000) (* key-length #x100000000) key-offset)
               (+ +header-bytes+ key-length document-length) end))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(declaim (ftype (function (banco-slot) list) slot-image))
(defun slot-image (bank)
  "Pre: nessun worker modifica BANK. Post: snapshot C4 di dati, sequenze e stato terminale."
  (list (arcdocdb.index.slots::banco-slot-state bank)
        (arcdocdb.index.slots::banco-slot-health bank)
        (copy-seq (arcdocdb.index.slots::banco-slot-words bank))))

;;; REQ: REQ-AFF-004
(declaim (ftype (function (function symbol keyword) null) slot-error))
(defun slot-error (thunk type reason)
  "Pre: operazione che deve fallire. Post: controllati classe e reason; altri errori propagati."
  (is (handler-case (progn (funcall thunk) nil)
        (arcdocdb-error (condition)
          (is (typep condition type))
          (is (eq reason (error-reason condition)))
          t)))
  nil)

;;; REQ: REQ-IDX-003 REQ-AFF-004
(declaim (ftype (function (banco-slot function symbol keyword &rest slot-test-buffer) null)
                slot-refusal))
(defun slot-refusal (bank thunk type reason &rest buffers)
  "Pre: fixture seriale. Post: rifiuto tipizzato e banco/input/output tutti invariati."
  (let ((before (slot-image bank)) (copies (mapcar #'copy-seq buffers)))
    (slot-error thunk type reason)
    (is (equalp before (slot-image bank)))
    (loop for buffer in buffers for copy in copies do (is (equalp buffer copy))))
  nil)

;;; REQ: REQ-IDX-003 REQ-AFF-004
(declaim (ftype (function (banco-slot function keyword &rest slot-test-buffer) null) slot-fault))
(defun slot-fault (bank thunk reason &rest buffers)
  "Pre: FI stabile prima della copia reader. Post: solo salute FAULTED, dati e buffer invariati."
  (let ((before (slot-image bank)) (copies (mapcar #'copy-seq buffers)))
    (slot-error thunk 'invariant-violation reason)
    (is (eq :faulted (arcdocdb.index.slots::banco-slot-health bank)))
    (is (eq (first before) (arcdocdb.index.slots::banco-slot-state bank)))
    (is (equalp (third before) (arcdocdb.index.slots::banco-slot-words bank)))
    (loop for buffer in buffers for copy in copies do (is (equalp buffer copy))))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-003
(declaim (ftype (function (banco-slot integer slot-test-buffer) null) slot-read-equals))
(defun slot-read-equals (bank index expected)
  "Pre: slot vivo stabile. Post: un solo valore LIVE e tutte le cinque parole esatte."
  (let ((output (slot-buffer 101 102 103 104 105)) (before (copy-seq expected)))
    (is (equal '(:live) (multiple-value-list (leggi-slot-v2 bank index output))))
    (is (equalp expected output))
    (is (equalp before expected)))
  nil)

;;; REQ: REQ-IDX-003 REQ-IDX-006
(declaim (ftype (function (banco-slot integer) null) slot-read-empty))
(defun slot-read-empty (bank index)
  "Pre: slot vuoto stabile. Post: EMPTY con output sentinel intatto, inclusa fine trattenuta."
  (let* ((output (slot-buffer 201 202 203 204 205)) (before (copy-seq output)))
    (is (equal '(:empty) (multiple-value-list (leggi-slot-v2 bank index output))))
    (is (equalp before output)))
  nil)

;;; REQ: REQ-IDX-003 REQ-AFF-004
(declaim (ftype (function (banco-slot integer) slot-test-word) slot-sequence))
(defun slot-sequence (bank index)
  "Pre: fixture seriale e indice valido. Post: sola lettura FI del contatore, senza oracoli prodotto."
  (let ((base (* index (if (arcdocdb.index.slots::banco-slot-retained bank) 6 5))))
    (aref (arcdocdb.index.slots::banco-slot-words bank)
          (+ base arcdocdb.index.slots::+slot-sequence+))))

;;; REQ: REQ-IDX-003 REQ-AFF-004
(declaim (ftype (function (banco-slot integer fixnum slot-test-word) null) slot-fi-word))
(defun slot-fi-word (bank index field value)
  "Pre: writer di fixture esclusivo. Post: FI dichiarata su una parola fisica; nessuna riparazione."
  (let* ((stride (if (arcdocdb.index.slots::banco-slot-retained bank) 6 5))
         (words (arcdocdb.index.slots::banco-slot-words bank)))
    (is (<= 0 index (1- (arcdocdb.index.slots::banco-slot-capacity bank))))
    (is (<= 0 field (1- stride)))
    (setf (aref words (+ (* index stride) field)) value))
  nil)

;;; REQ: REQ-IDX-003 REQ-LIM-001 REQ-AFF-004
(declaim (ftype (function (slot-test-buffer &key (:retained-p boolean)) null) slot-reject-source))
(defun slot-reject-source (source &key (retained-p nil))
  "Pre: payload malformato ma cinque u64. Post: pubblicazione rifiutata senza mutare un banco vivo."
  (let* ((bank (crea-banco-slot :capacity 2 :retained-p retained-p))
         (live (slot-payload :end (if retained-p #x8000000000000030 0))))
    (is (null (pubblica-slot-v2 bank 0 live)))
    (slot-refusal bank (lambda () (pubblica-slot-v2 bank 0 source))
                  'invalid-argument :index-slot-payload source)
    (slot-read-equals bank 0 live)
    (slot-read-empty bank 1))
  nil)

;;; REQ: REQ-IDX-004
(declaim (ftype (function (fixnum slot-test-word &key (:retained-p boolean)) null)
                slot-stale-relocation))
(defun slot-stale-relocation (field value &key (retained-p nil))
  "Pre: un solo campo EXPECTED diverso e ancora valido. Post: NIL, nessuna scrittura o credito perso."
  (let* ((bank (crea-banco-slot :capacity 1 :retained-p retained-p))
         (live (slot-payload :end (if retained-p #x8000000000000030 0)))
         (expected (copy-seq live)))
    (setf (aref expected field) value)
    (let ((replacement (copy-seq expected)))
      (incf (aref replacement 1) 16)
      (is (null (pubblica-slot-v2 bank 0 live)))
      (let ((before (slot-image bank)) (e (copy-seq expected)) (r (copy-seq replacement)))
        (is (null (riloca-slot-v2 bank 0 expected replacement)))
        (is (equalp before (slot-image bank)))
        (is (equalp expected e)) (is (equalp replacement r)))
      (slot-read-equals bank 0 live)))
  nil)

;;; REQ: REQ-IDX-004 REQ-AFF-004
(declaim (ftype (function (fixnum slot-test-word &key (:retained-p boolean)) null)
                slot-reject-relocation-change))
(defun slot-reject-relocation-change (field value &key (retained-p nil))
  "Pre: sostituzione valida che cambia un campo immutabile. Post: rifiuto prima della mutazione."
  (let* ((bank (crea-banco-slot :capacity 1 :retained-p retained-p))
         (expected (slot-payload :end (if retained-p #x8000000000000030 0)))
         (replacement (copy-seq expected)))
    (incf (aref replacement 1) 16)
    (setf (aref replacement field) value)
    (is (null (pubblica-slot-v2 bank 0 expected)))
    (slot-refusal bank (lambda () (riloca-slot-v2 bank 0 expected replacement))
                  'invalid-argument :index-slot-relocation-content expected replacement)
    (slot-read-equals bank 0 expected))
  nil)

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (&optional (integer 1 60)) integer) slot-deadline))
(defun slot-deadline (&optional (seconds 20))
  "Pre: budget della fixture positivo e bounded. Post: deadline monotona C4, nessuna misura prodotto."
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (integer) double-float) slot-seconds-left))
(defun slot-seconds-left (deadline)
  "Pre: deadline della fixture. Post: timeout positivo; errore tipizzato se budget scaduto."
  (let ((remaining (- deadline (get-internal-real-time))))
    (unless (plusp remaining)
      (error 'invariant-violation :reason :slot-test-deadline))
    (/ remaining (float internal-time-units-per-second 1d0))))

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (sb-thread:semaphore integer) null) slot-wait))
(defun slot-wait (semaphore deadline)
  "Pre: semaforo del protocollo di fixture. Post: handoff acquisito; timeout causa fallimento."
  (unless (sb-thread:wait-on-semaphore semaphore :timeout (slot-seconds-left deadline))
    (error 'invariant-violation :reason :slot-test-wait-timeout))
  nil)

;;; REQ: REQ-CON-004 REQ-AFF-004
(declaim (ftype (function (string function) sb-thread:thread) slot-worker))
(defun slot-worker (name thunk)
  "Pre: corpo bounded. Post: errori registrati come risultato del worker e propagati dal join."
  (sb-thread:make-thread
   (lambda () (handler-case (funcall thunk) (error (condition) condition))) :name name))

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (sb-thread:thread integer) null) slot-join))
(defun slot-join (thread deadline)
  "Pre: worker della fixture. Post: risultato OK e thread concluso; timeout/errori sono fallimenti."
  (let ((result (sb-thread:join-thread thread :timeout (slot-seconds-left deadline)
                                            :default :slot-join-timeout)))
    (when (eq result :slot-join-timeout)
      (error 'invariant-violation :reason :slot-test-join-timeout))
    (when (typep result 'error) (error result))
    (is (eq :ok result))
    (is (not (sb-thread:thread-alive-p thread))))
  nil)

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (list) null) slot-stop-workers))
(defun slot-stop-workers (threads)
  "Pre: lista finita di worker della fixture. Post: risorse rilasciate con join bounded verificato."
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (let ((result (sb-thread:join-thread thread :timeout 1 :default :slot-cleanup)))
      (when (typep result 'error) (error result))
      (is (member result '(:ok :slot-cleanup)))
      (is (not (sb-thread:thread-alive-p thread)))))
  nil)
