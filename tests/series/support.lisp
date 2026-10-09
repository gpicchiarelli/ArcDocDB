;;;; ADR-0037/0046/0033: harness bounded, senza scheduler o indice di prodotto.
;;;; OWNER: ogni fixture e posseduta dal suo test o dal singolo worker dichiarato.
;;;; SHARED: nei test concorrenti solo registro CSN e semafori del protocollo.
(defpackage #:arcdocdb.series.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:invariant-violation #:io-fault #:error-reason)
  (:import-from #:arcdocdb.series #:crea-controllore-serie
                #:acquisisci-controllore-serie #:rilascia-controllore-serie
                #:registra-commit-serie #:inizia-io-commit-serie #:completa-io-commit-serie
                #:ritira-io-commit-serie
                #:pubblica-commit-serie #:riusa-commit-serie #:fault-controllore-serie
                #:annulla-commit-serie #:leggi-radice-serie #:stato-controllore-serie
                #:ambito-fault-serie #:stato-commit-serie #:leggi-csn-commit-serie
                #:conta-commit-serie)
  (:export #:run))
(in-package #:arcdocdb.series.tests)
(declaim (optimize (safety 3) (debug 3)))

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))

(defun run ()
  (dolist (test (reverse *tests*))
    (funcall test)
    (format t "ok    ~A~%" test))
  (format t "~D test del controller Serie superati.~%" (length *tests*))
  t)

(defconstant +series-word-base+ 4294967296)
(defun series-number (high low)
  "Oracolo C4: aritmetica matematica, anche oltre il fixnum; mai helper di prodotto."
  (+ (* high +series-word-base+) low))

(defstruct (series-root (:constructor series-root (id parent)))
  "Descrittore opaco e immutabile fornito dal writer: identita distinta per commit."
  (id 0 :read-only t) (parent nil :read-only t))

(defstruct (series-fixture (:constructor %series-fixture))
  registry file log controller lease calls (planned nil) (next 0) (last 0))

(defun series-file (calls writer flush)
  (arcdocdb.io:crea-temporaneo
   "series-controller-fake.tmp" :max-transfer 1048576 :max-file-bytes #xffffffff
   :backend
   (arcdocdb.io.tests::backend
    :open (lambda (name mode) (declare (ignore name mode)) (incf (svref calls 0)) 7)
    :writer (lambda (fd buffer start count)
              (incf (svref calls 1))
              (if writer (funcall writer fd buffer start count) count))
    :flush (lambda (fd) (incf (svref calls 2)) (if flush (funcall flush fd) 0))
    :close (lambda (fd) (declare (ignore fd)) (incf (svref calls 3)) 0))))

(defun call-with-series-fixture (thunk &key (capacity 4) (csn-capacity 16) (base 0)
                                       registry (file-id 31) (root (series-root 0 nil))
                                       (next-offset 0) writer flush)
  (multiple-value-bind (high low) (floor base +series-word-base+)
    (let* ((calls (make-array 4 :initial-element 0))
           (file (series-file calls writer flush))
           (f (%series-fixture
               :registry (or registry (arcdocdb.csn:crea-registro-csn
                                       :capacity csn-capacity :initial-high high :initial-low low))
               :file file :calls calls :planned root :next next-offset :last base)))
      (unwind-protect
           (progn
             (setf (series-fixture-log f) (arcdocdb.wal:crea-log-io file :segment file-id)
                   (series-fixture-controller f)
                   (crea-controllore-serie (series-fixture-registry f) (series-fixture-log f)
                                          :capacity capacity :root root :next-offset next-offset)
                   (series-fixture-lease f)
                   (acquisisci-controllore-serie (series-fixture-controller f)))
             (funcall thunk f))
        (when (series-fixture-lease f)
          (rilascia-controllore-serie (series-fixture-controller f) (series-fixture-lease f)))
        (arcdocdb.io:chiudi file)))))

(defmacro with-series ((f &rest options) &body body)
  `(call-with-series-fixture (lambda (,f) ,@body) ,@options))

(defun series-open-lot (f &key (id 1))
  (let ((lot (arcdocdb.wal:crea-lotto :segment
                                    (arcdocdb.wal::log-io-file-id (series-fixture-log f))
                                    :capacity 128 :max-records 1)))
    (arcdocdb.wal:aggiungi-record lot 1 (bytes id) (bytes #xa0))
    lot))

(defun series-seal (f &key (offset (series-fixture-next f)) (id 1) lot)
  (let ((batch (or lot (series-open-lot f :id id))))
    (arcdocdb.wal:sigilla-lotto-con-csn
     batch (series-fixture-registry f) (series-fixture-log f) offset
     (arcdocdb.io:posizione-durevole (series-fixture-file f)))
    batch))

(defun series-adopt (f lot &key (level :group) (root (series-root
                                                      (1+ (series-fixture-last f))
                                                      (series-fixture-planned f))))
  (multiple-value-bind (event generation)
      (registra-commit-serie (series-fixture-controller f) (series-fixture-lease f) lot
                            (series-fixture-planned f) root level)
    (is (and (typep generation 'fixnum) (plusp generation)))
    (is (eq :preparato (stato-commit-serie (series-fixture-controller f) event generation)))
    (let ((token (multiple-value-list (arcdocdb.wal:leggi-csn-lotto lot))))
      (is (equal token (multiple-value-list
                       (leggi-csn-commit-serie (series-fixture-controller f) event generation))))
      (setf (series-fixture-last f) (series-number (second token) (third token))))
    (setf (series-fixture-planned f) root
          (series-fixture-next f) (+ (arcdocdb.wal:inizio-lotto lot)
                                    (arcdocdb.wal:lunghezza-lotto lot)))
    (values event generation root)))

(defun series-group (f &rest lots)
  (let ((group (arcdocdb.wal:crea-gruppo (series-fixture-log f) :max-lots 8)))
    (dolist (lot lots) (arcdocdb.wal:aggiungi-lotto group lot))
    (arcdocdb.wal:chiudi-gruppo group)
    group))

(defun series-begin (f event generation)
  (is (null (inizia-io-commit-serie (series-fixture-controller f) (series-fixture-lease f)
                                 event generation))))
(defun series-complete (f event generation)
  (is (null (completa-io-commit-serie (series-fixture-controller f) (series-fixture-lease f)
                                   event generation))))
(defun series-withdraw-io (f event generation)
  "Solo dopo rifiuto del dispatch o ritiro definitivo confermato dal chiamante."
  (is (null (ritira-io-commit-serie (series-fixture-controller f) (series-fixture-lease f)
                                 event generation))))
(defun series-retire (f event generation)
  (is (null (riusa-commit-serie (series-fixture-controller f) (series-fixture-lease f)
                              event generation))))

(defun series-counts (f count unresolved active)
  (is (equal (list count unresolved active)
             (multiple-value-list (conta-commit-serie (series-fixture-controller f)
                                                    (series-fixture-lease f))))))

(defun series-frontiers (registry last live)
  "Atteso H = minimo dei CSN ancora obbligati - 1, oppure ultimo assegnato."
  (let* ((actual (multiple-value-list (arcdocdb.csn:leggi-frontiere-csn registry)))
         (expected (if live (1- (reduce #'min live)) last)))
    (is (= 4 (length actual)))
    (is (every (lambda (word) (typep word '(unsigned-byte 32))) actual))
    (is (= last (series-number (first actual) (second actual))))
    (is (= expected (series-number (third actual) (fourth actual))))
    expected))

(defun series-publish (f event generation expected-h)
  (let ((result (multiple-value-list
                 (pubblica-commit-serie (series-fixture-controller f) (series-fixture-lease f)
                                       event generation))))
    (is (= 3 (length result)))
    (is (eq :risolto (first result)))
    (is (every (lambda (word) (typep word '(unsigned-byte 32))) (rest result)))
    (is (= expected-h (series-number (second result) (third result))))
    (is (eq :risolto (stato-commit-serie (series-fixture-controller f) event generation)))
    result))

(defun series-annul (f event generation expected-h)
  (let ((result (multiple-value-list
                 (annulla-commit-serie (series-fixture-controller f) (series-fixture-lease f)
                                      event generation))))
    (is (= 3 (length result)))
    (is (eq :annullato (first result)))
    (is (every (lambda (word) (typep word '(unsigned-byte 32))) (rest result)))
    (is (= expected-h (series-number (second result) (third result))))
    (is (eq :annullato (stato-commit-serie (series-fixture-controller f) event generation)))
    result))

(defun series-pending (thunk)
  (is (equal '(:pendente 0 0) (multiple-value-list (funcall thunk)))))

(defun series-healthy (f)
  (is (eq :healthy (stato-controllore-serie (series-fixture-controller f))))
  (is (eq :none (ambito-fault-serie (series-fixture-controller f)))))
(defun series-faulted (f scope)
  (is (eq :faulted (stato-controllore-serie (series-fixture-controller f))))
  (is (eq scope (ambito-fault-serie (series-fixture-controller f)))))

(defun series-image (objects &key opaque health-opaque)
  "Solo harness/FI: snapshot dell'intero grafo mutabile, inclusi byte e identita.
Non determina radici, ordine o H attesi. Le visite hanno il limite del grafo preallocato.
HEALTH-OPAQUE maschera solo STATE dei controller elencati nelle FI che richiedono fault."
  (let ((seen (make-hash-table :test #'eq)) (next 0))
    (labels ((identity-image (object) (list :identity object))
             (visit (object)
               (cond
                 ((or (numberp object) (symbolp object) (characterp object)) object)
                 ((member object opaque :test #'eq) (identity-image object))
                 ((typep object 'sb-thread:mutex)
                  (list :mutex (identity-image object) (identity-image (sb-thread:mutex-owner object))))
                 ((gethash object seen) (list :ref (gethash object seen)))
                 ((or (arrayp object) (consp object) (typep object 'structure-object))
                  (setf (gethash object seen) (incf next))
                  (cond
                    ((arrayp object)
                     (list :array (identity-image object) (array-element-type object)
                           (array-dimensions object)
                           (loop for i below (array-total-size object)
                                 collect (visit (row-major-aref object i)))))
                    ((consp object) (list :cons (identity-image object) (visit (car object))
                                          (visit (cdr object))))
                    (t (let* ((class (class-of object)) (name (class-name class))
                              (package (and (symbolp name) (symbol-package name))))
                         (if (and package (search "ARCDOCDB." (package-name package)))
                             (list :structure (identity-image object) name
                                   (loop for slot in (sb-mop:class-slots class)
                                         for key = (sb-mop:slot-definition-name slot)
                                         collect
                                         (list key
                                               (if (and (member object health-opaque :test #'eq)
                                                        (string= "STATE" (symbol-name key)))
                                                   :health-transition
                                                   (visit (slot-value object key))))))
                             (identity-image object))))))
                 (t (identity-image object)))))
      (mapcar #'visit objects))))

(defun series-image-equal (a b)
  "EQUALP per i valori congelati, EQ per ogni riferimento: rileva anche copie uguali."
  (cond
    ((and (consp a) (consp b) (eq (car a) :identity) (eq (car b) :identity))
     (eq (second a) (second b)))
    ((and (consp a) (consp b))
     (and (series-image-equal (car a) (car b)) (series-image-equal (cdr a) (cdr b))))
    (t (eql a b))))

(defun series-fixture-image (fixtures lots groups)
  (series-image (append fixtures lots groups)))

(defun series-error (thunk type &optional reason)
  (is (handler-case (progn (funcall thunk) nil)
        (arcdocdb-error (condition)
          (is (typep condition type))
          (when reason (is (eq reason (error-reason condition))))
          t))))

(defun series-refusal (fixtures thunk type &key reason lots groups)
  "Rifiuto normalizzato: controller, tutti gli eventi, WAL/file/CSN e byte invariati."
  (let* ((all (if (listp fixtures) fixtures (list fixtures)))
         (before (series-fixture-image all lots groups)))
    (series-error thunk type reason)
    (is (series-image-equal before (series-fixture-image all lots groups))))
  t)

(defun series-archive-refusal (f thunk reason &key lots groups)
  "FI preflight: cambia solo la salute in Archivio faulted; tutti gli altri campi invariati."
  (let* ((objects (append (list f) lots groups))
         (controller (series-fixture-controller f))
         (before (series-image objects :health-opaque (list controller))))
    (series-error thunk 'invariant-violation reason)
    (series-faulted f :archive)
    (is (series-image-equal before (series-image objects :health-opaque (list controller)))))
  t)

(defun series-private-slot (object name)
  "FI esplicita: risolve il nome di uno slot del prodotto, senza creare simboli."
  (or (find name (sb-mop:class-slots (class-of object))
            :key (lambda (slot) (symbol-name (sb-mop:slot-definition-name slot)))
            :test #'string-equal)
      (error "Slot FI ~A assente in ~S." name (class-name (class-of object)))))

(defun series-fi-set (object name value)
  (setf (slot-value object (sb-mop:slot-definition-name (series-private-slot object name))) value))

(defun series-call-with-function-fi (symbol replacement thunk)
  "FI seriale soltanto: sostituzione temporanea al confine WAL/CSN, sempre ripristinata."
  (let ((original (symbol-function symbol)))
    (unwind-protect
         (progn (setf (symbol-function symbol) replacement) (funcall thunk))
      (setf (symbol-function symbol) original))))

(defun series-deadline (&optional (seconds 20))
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))
(defun series-seconds-left (deadline)
  (let ((remaining (- deadline (get-internal-real-time))))
    (unless (plusp remaining) (error "Budget temporale della fixture Serie esaurito."))
    (/ remaining (float internal-time-units-per-second 1d0))))
(defun series-wait (semaphore deadline)
  (is (sb-thread:wait-on-semaphore semaphore :timeout (series-seconds-left deadline))))
(defun series-worker (name thunk)
  (sb-thread:make-thread
   (lambda () (handler-case (funcall thunk) (error (condition) condition))) :name name))
(defun series-join (thread deadline)
  (let ((result (sb-thread:join-thread thread :timeout (series-seconds-left deadline)
                                           :default :series-timeout)))
    (when (typep result 'error) (error result))
    (is (eq :ok result))))
(defun series-stop-workers (threads)
  (dolist (thread threads)
    (when (sb-thread:thread-alive-p thread) (sb-thread:terminate-thread thread))
    (sb-thread:join-thread thread :timeout 1 :default :series-terminated)
    (is (not (sb-thread:thread-alive-p thread)))))

(defun series-retry (thunk deadline reasons &optional refused)
  "Retry C4 con tetto di tempo e tentativi; nessun retry aggiunto al prodotto."
  (loop repeat 1000000
        do (series-seconds-left deadline)
           (handler-case (return-from series-retry (funcall thunk))
             (resource-exhausted (condition)
               (is (member (error-reason condition) reasons))
               (when refused (funcall refused (error-reason condition)))))
           (sb-thread:thread-yield))
  (error "Budget dei retry della fixture Serie esaurito."))

(defun series-publish-retry (f event generation deadline)
  (loop repeat 1000000
        do (series-seconds-left deadline)
           (let ((result (multiple-value-list
                          (pubblica-commit-serie (series-fixture-controller f)
                                                (series-fixture-lease f) event generation))))
             (case (first result)
               (:risolto (is (= 3 (length result))) (return-from series-publish-retry result))
               (:pendente (is (equal '(:pendente 0 0) result)))
               (otherwise (error "Esito inatteso di pubblicazione: ~S." result))))
           (sb-thread:thread-yield))
  (error "Budget di pubblicazione della fixture Serie esaurito."))
