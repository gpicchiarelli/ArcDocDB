;;;; Harness C4 dell'indice primario v2; esecuzione affidata al runner registrato.
;;; OWNER: il runner possiede il registro dei test; ogni fixture ha un solo writer.
;;; SHARED: solo indice e chiavi immutabili nei worker; scratch/output privati.
;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005 REQ-IDX-007 REQ-AFF-008
(defpackage #:arcdocdb.index.primary.tests
  (:use #:cl)
  (:local-nicknames (#:p #:arcdocdb.index.primary) (#:s #:arcdocdb.index.slots))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.binary #:octets #:u32 #:u64)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:invariant-violation #:error-reason)
  (:export #:run))
(in-package #:arcdocdb.index.primary.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

;;; OWNER: registro modificato soltanto dal loader seriale, letto dal runner.
(defvar *tests* nil)

;;; REQ: REQ-AFF-003
(defmacro deftest (name &body body)
  "Pre: nome con requisito e corpo statico. Post: funzione registrata una sola volta."
  `(progn
     (declaim (ftype (function () t) ,name))
     (defun ,name () ,@body)
     (pushnew ',name *tests*)))

;;; REQ: REQ-AFF-003
(declaim (ftype (function () boolean) run))
(defun run ()
  "Pre: suite caricata; chiamata seriale dal runner. Post: T solo se ogni test termina."
  (dolist (test (reverse *tests*))
    (funcall test)
    (format t "ok    ~A~%" test))
  (format t "~D test dell'indice primario superati.~%" (length *tests*))
  t)

(defconstant +primary-test-budget+ 1048576)
(defconstant +primary-sentinel+ #xdeadbeefcafef00d)

;;; REQ: REQ-IDX-003 REQ-CON-004
(defstruct (primary-fixture (:constructor %make-primary-fixture (index writer reader output)))
  "Pre: risorse private appena allocate. Post: contesti distinti, nessun worker avviato."
  (index nil :type p:indice-primario :read-only t)
  (writer nil :type p:contesto-indice :read-only t)
  (reader nil :type p:contesto-indice :read-only t)
  (output #() :type s::contenuto-slot :read-only t))

;;; REQ: REQ-IDX-001 REQ-IDX-005
(declaim (ftype (function (&key (:capacity integer) (:arena-bytes integer)
                               (:max-depth integer) (:directory-budget integer)
                               (:fragment-budget integer)) primary-fixture) primary-fixture))
(defun primary-fixture (&key (capacity 32) (arena-bytes 256) (max-depth 4)
                           (directory-budget +primary-test-budget+)
                           (fragment-budget +primary-test-budget+))
  "Pre: configurazione valida. Post: indice vuoto e buffer privati specializzati."
  (%make-primary-fixture
   (p:crea-indice-primario :capacity capacity :arena-bytes arena-bytes :max-depth max-depth
                         :directory-budget-bytes directory-budget
                         :fragment-budget-bytes fragment-budget)
   (p:crea-contesto-indice) (p:crea-contesto-indice)
   (make-array 5 :element-type '(unsigned-byte 64) :initial-element +primary-sentinel+)))

;;; REQ: REQ-LIM-003
(declaim (ftype (function (&rest (unsigned-byte 8)) octets) primary-key))
(defun primary-key (&rest bytes)
  "Pre: byte della fixture. Post: chiave binaria privata, senza conversioni testuali."
  (make-array (length bytes) :element-type '(unsigned-byte 8) :initial-contents bytes))

;;; REQ: REQ-IDX-001 REQ-LIM-003
(declaim (ftype (function (octets u64 &key (:location u64) (:extra integer) (:offset u32))
                         s::contenuto-slot) primary-payload))
(defun primary-payload (key csn &key (location #x1700000100) (extra 1) (offset 0))
  "Pre: chiave non vuota e CSN valido. Post: payload atteso, costruito senza helper del prodotto."
  (make-array 5 :element-type '(unsigned-byte 64)
              :initial-contents
              (list csn location (logior offset (ash (length key) 32) (ash 1 48))
                    (+ arcdocdb.record:+header-bytes+ (length key) extra) 0)))

;;; REQ: REQ-IDX-007
(declaim (ftype (function (primary-fixture &optional u32) p:frammento-indice) primary-current))
(defun primary-current (fixture &optional (high 0))
  "Pre: writer seriale. Post: frammento ottenuto dalla root corrente, mai da uno slot salvato."
  (p:frammento-corrente-indice (primary-fixture-index fixture) high))

;;; REQ: REQ-IDX-001 REQ-IDX-003
(declaim (ftype (function (primary-fixture octets u64 u32 u32
                         &key (:fragment p:frammento-indice) (:source s::contenuto-slot)
                              (:location u64) (:extra integer)) s::contenuto-slot) primary-put))
(defun primary-put (fixture key csn high low &key fragment source (location #x1700000100) (extra 1))
  "Pre: writer esclusivo e digest scelto coerentemente dalla fixture. Post: fonte privata immutata."
  (let* ((index (primary-fixture-index fixture))
         (payload (or source (primary-payload key csn :location location :extra extra)))
         (before (copy-seq payload)))
    (is (null (p:pubblica-chiave-indice index (or fragment (primary-current fixture high))
                                      key 0 (length key) high low payload
                                      (primary-fixture-writer fixture))))
    (is (equalp before payload))
    payload))

;;; REQ: REQ-IDX-001 REQ-IDX-003
(declaim (ftype (function (primary-fixture octets u32 u32) (member :live :absent :retry-limit))
                primary-read))
(defun primary-read (fixture key high low)
  "Pre: fixture possiede reader e output. Post: stato pubblico; nessun retry dell'harness."
  (p:leggi-indice-primario (primary-fixture-index fixture) key 0 (length key) high low
                          (primary-fixture-reader fixture) (primary-fixture-output fixture)))

;;; REQ: REQ-IDX-001 REQ-IDX-004
(declaim (ftype (function (s::contenuto-slot s::contenuto-slot &optional (or null u32)) boolean)
                primary-check-payload))
(defun primary-check-payload (actual expected &optional offset)
  "Pre: campione LIVE. Post: verifica tutti i campi non offset e, se fornito, l'offset atteso."
  (dolist (word '(0 1 3 4)) (is (= (aref actual word) (aref expected word))))
  (is (= (ash (aref actual 2) -32) (ash (aref expected 2) -32)))
  (when offset (is (= offset (ldb (byte 32 0) (aref actual 2)))))
  t)

;;; REQ: REQ-IDX-001
(declaim (ftype (function (primary-fixture octets u32 u32 s::contenuto-slot
                                         &optional (or null u32)) s::contenuto-slot) primary-live))
(defun primary-live (fixture key high low expected &optional offset)
  "Pre: chiave attesa viva. Post: payload indipendente verificato; copia privata per messaggi."
  (is (eq :live (primary-read fixture key high low)))
  (primary-check-payload (primary-fixture-output fixture) expected offset)
  (copy-seq (primary-fixture-output fixture)))

;;; REQ: REQ-IDX-003 REQ-IDX-007
(declaim (ftype (function (primary-fixture octets u32 u32 (member :absent :retry-limit)) boolean)
                primary-no-output))
(defun primary-no-output (fixture key high low status)
  "Pre: chiave valida. Post: miss/retry preserva tutte le cinque parole, contesto liberato."
  (fill (primary-fixture-output fixture) +primary-sentinel+)
  (let ((before (copy-seq (primary-fixture-output fixture))))
    (is (eq status (primary-read fixture key high low)))
    (is (equalp before (primary-fixture-output fixture)))
    (is (not (p::contesto-indice-busy (primary-fixture-reader fixture)))))
  t)

;;; REQ: REQ-IDX-006
(declaim (ftype (function (primary-fixture octets u32 u32) boolean) primary-delete))
(defun primary-delete (fixture key high low)
  "Pre: writer esclusivo. Post: ritorno pubblico T/NIL controllato dal test chiamante."
  (p:rimuovi-chiave-indice (primary-fixture-index fixture) (primary-current fixture high)
                         key 0 (length key) high low (primary-fixture-writer fixture)))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture p:frammento-indice) list) primary-image))
(defun primary-image (fixture fragment)
  "Solo fixture: identita root/arena e copie dei dati per provare rifiuti senza mutazioni."
  (let ((index (primary-fixture-index fixture)) (bank (p::frammento-indice-bank fragment)))
    (list (p::indice-primario-root index) (p::frammento-indice-arena fragment)
          (p::indice-primario-revision index) (p::indice-primario-health index)
          (p::frammento-indice-exposure fragment) (p::frammento-indice-used fragment)
          (p::frammento-indice-live fragment) (s::banco-slot-state bank) (s::banco-slot-health bank)
          (copy-seq (p::frammento-indice-arena fragment))
          (copy-seq (p::frammento-indice-controls fragment)) (copy-seq (s::banco-slot-words bank)))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (list list) boolean) primary-image-equal))
(defun primary-image-equal (before after)
  "Pre: immagini della stessa fixture. Post: identita confrontate con EQ, valori con EQUALP."
  (and (eq (first before) (first after)) (eq (second before) (second after))
       (equalp (cddr before) (cddr after))))

;;; REQ: REQ-IDX-003 REQ-IDX-005 REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (primary-fixture p:frammento-indice function symbol keyword) boolean)
                primary-refusal))
(defun primary-refusal (fixture fragment thunk type reason)
  "Pre: rifiuto previsto. Post: tipo/reason esatti, root/revisione/payload/controlli/arena immutati."
  (let ((before (primary-image fixture fragment)))
    (is (handler-case (progn (funcall thunk) nil)
          (arcdocdb-error (condition)
            (is (typep condition type))
            (is (eq reason (error-reason condition)))
            t)))
    (is (primary-image-equal before (primary-image fixture fragment))))
  t)

;;; REQ: REQ-IDX-005
(declaim (ftype (function (primary-fixture integer integer &optional integer) p:frammento-indice)
                primary-candidate))
(defun primary-candidate (fixture depth prefix &optional (arena-bytes 256))
  "Pre: geometria valida. Post: candidato vuoto privato; non usa il nuovo costruttore di rebuild."
  (p:crea-frammento-indice (primary-fixture-index fixture) :depth depth :prefix prefix
                         :arena-bytes arena-bytes))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture p:frammento-indice octets u32 u32) s::contenuto-slot)
                primary-copy-live))
(defun primary-copy-live (fixture candidate key high low)
  "Pre: chiave nota nella root corrente. Post: copia manuale esatta del payload vivo nel candidato."
  (is (eq :live (primary-read fixture key high low)))
  (let ((source (copy-seq (primary-fixture-output fixture))))
    (primary-put fixture key (aref source 0) high low :fragment candidate :source source)))

;;; REQ: REQ-IDX-007
(declaim (ftype (function (p:frammento-indice) integer) primary-fragment-bytes))
(defun primary-fragment-bytes (fragment)
  "Pre: frammento sano. Post: contabilita indipendente dalle funzioni payload del prodotto."
  (+ (* 8 (length (s::banco-slot-words (p::frammento-indice-bank fragment))))
     (length (p::frammento-indice-controls fragment)) (length (p::frammento-indice-arena fragment))))

;;; REQ: REQ-IDX-007
(declaim (ftype (function (primary-fixture) integer) primary-root-bytes))
(defun primary-root-bytes (fixture)
  "Pre: directory canonica. Post: ogni frammento corrente contato una volta per identita."
  (let* ((root (p::indice-primario-root (primary-fixture-index fixture)))
         (directory (p::root-indice-directory root))
         (fragments (remove-duplicates (coerce directory 'list) :test #'eq)))
    (+ (* 8 (length directory))
       (loop for fragment in fragments sum (primary-fragment-bytes fragment)))))

;;; REQ: REQ-IDX-007
(declaim (ftype (function (primary-fixture p:frammento-indice &optional (or null p:frammento-indice))
                         integer) primary-plan-budget))
(defun primary-plan-budget (fixture first &optional second)
  "Pre: candidati costruiti. Post: limite transitorio esatto per root+candidati+directory nuova."
  (let* ((root (p::indice-primario-root (primary-fixture-index fixture)))
         (depth (max (p::root-indice-depth root) (p::frammento-indice-depth first))))
    (+ (primary-root-bytes fixture) (primary-fragment-bytes first)
       (if second (primary-fragment-bytes second) 0) (* 8 (ash 1 depth)))))

;;; REQ: REQ-IDX-005 REQ-IDX-007
(declaim (ftype (function (primary-fixture p:frammento-indice p:frammento-indice
                         &optional (or null p:frammento-indice)) p:pubblicazione-indice) primary-plan))
(defun primary-plan (fixture source first &optional second)
  "Pre: copie manuali vive complete. Post: piano preparato con il budget esatto della fixture."
  (p:prepara-directory-indice (primary-fixture-index fixture) source first
                             (primary-plan-budget fixture first second) second))

;;; REQ: REQ-IDX-003
(declaim (ftype (function (p:frammento-indice integer u64) null) primary-fi-sequence))
(defun primary-fi-sequence (fragment slot sequence)
  "Solo FI seriale: forza il seqlock, senza worker o mutazioni del prodotto concorrenti."
  (let ((bank (p::frammento-indice-bank fragment)))
    (setf (aref (s::banco-slot-words bank)
                (+ (s::base-slot bank slot) s::+slot-sequence+)) sequence))
  nil)

;;; REQ: REQ-IDX-007
(declaim (ftype (function (function function) t) primary-with-probe-fi))
(defun primary-with-probe-fi (after-probe thunk)
  "Solo FI seriale: callback dopo sonda-reader, prima della conferma root; sempre ripristinata."
  (let* ((symbol 'p::sonda-reader) (original (symbol-function symbol)))
    (unwind-protect
         (progn
           (setf (symbol-function symbol)
                 (lambda (&rest arguments)
                   (let ((result (apply original arguments)))
                     (funcall after-probe result)
                     result)))
           (funcall thunk))
      (setf (symbol-function symbol) original))))
