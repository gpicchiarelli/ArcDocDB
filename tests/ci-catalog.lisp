;;;; C4: catalogo unico, caricabile senza ASDF e senza package del prodotto.
;;; REQ: REQ-VAL-001 REQ-AFF-012
(defpackage #:arcdocdb.ci.tests
  (:use #:cl)
  (:export #:run #:suite-specifications #:discover))
(in-package #:arcdocdb.ci.tests)
(declaim (optimize (safety 3) (debug 3)))

(defparameter *suite-table*
  '(("ARCDOCDB.TESTS" :smoke)
    ("ARCDOCDB.HASH64.TESTS")
    ("ARCDOCDB.FOUNDATION.TESTS")
    ("ARCDOCDB.FULLTEXT.FORMAT.TESTS")
    ("ARCDOCDB.FULLTEXT.ANALYSIS.TESTS")
    ("ARCDOCDB.FULLTEXT.CODEC.TESTS")
    ("ARCDOCDB.FULLTEXT.DOCUMENT.TESTS")
    ("ARCDOCDB.FULLTEXT.ADMISSION.TESTS")
    ("ARCDOCDB.FULLTEXT.PUT.TESTS")
    ("ARCDOCDB.UTF8.TESTS")
    ("ARCDOCDB.CBOR.TESTS")
    ("ARCDOCDB.CBOR.MINIMAL.TESTS")
    ("ARCDOCDB.CBOR.STRUCTURE.TESTS")
    ("ARCDOCDB.CBOR.MINIMAL.SCAN.TESTS")
    ("ARCDOCDB.CBOR.WRITE.TESTS")
    ("ARCDOCDB.CBOR.STRING.WRITE.TESTS")
    ("ARCDOCDB.CBOR.SIMPLE.WRITE.TESTS")
    ("ARCDOCDB.CBOR.FLOAT.WRITE.TESTS")
    ("ARCDOCDB.CBOR.ARRAY.WRITE.TESTS")
    ("ARCDOCDB.CBOR.MAP.WRITE.TESTS")
    ("ARCDOCDB.CBOR.TAG.WRITE.TESTS")
    ("ARCDOCDB.CBOR.ITEM.READ.TESTS")
    ("ARCDOCDB.CBOR.STRING.READ.TESTS")
    ("ARCDOCDB.CSN.TESTS")
    ("ARCDOCDB.MVCC.TESTS" :alist "*MVCC-TESTS*")
    ("ARCDOCDB.EPOCHS.TESTS" :alist "*EPOCHS-TESTS*")
    ("ARCDOCDB.READ.TESTS" :alist "*READ-TESTS*")
    ("ARCDOCDB.GET.TESTS" :alist "*GET-TESTS*")
    ("ARCDOCDB.GET.PERFORMANCE.TESTS" :symbol-list "*GET-PERFORMANCE-TESTS*")
    ("ARCDOCDB.CACHE.TESTS")
    ("ARCDOCDB.GET.DIRECTORY.TESTS" :symbol-list "*GET-DIRECTORY-TESTS*")
    ("ARCDOCDB.GET.RESOLVER.TESTS" :alist "*GET-RESOLVER-TESTS*")
    ("ARCDOCDB.GET.ACTIVE.TESTS" :alist "*GET-ACTIVE-TESTS*")
    ("ARCDOCDB.EXECUTION.TESTS")
    ("ARCDOCDB.SCHEDULER.TESTS")
    ("ARCDOCDB.STORAGE.TESTS")
    ("ARCDOCDB.IO.TESTS")
    ("ARCDOCDB.CONTROL.TESTS")
    ("ARCDOCDB.RECOVERY.TESTS")
    ("ARCDOCDB.RECOVERY.ACTIVE.TESTS")
    ("ARCDOCDB.RECOVERY.ARCHIVE.TESTS")
    ("ARCDOCDB.RECOVERY.ACTIVE.CHECKPOINT.TESTS")
    ("ARCDOCDB.RECOVERY.CLOSED.TESTS")
    ("ARCDOCDB.RECOVERY.ARCHIVE.CSN.TESTS")
    ("ARCDOCDB.RUNTIME.TESTS")
    ("ARCDOCDB.WAL.TESTS")
    ("ARCDOCDB.SERIES.TESTS")
    ("ARCDOCDB.INDEX.SLOTS.TESTS")
    ("ARCDOCDB.INDEX.PRIMARY.TESTS")
    ("ARCDOCDB.INDEX.MODE.TESTS")
    ("ARCDOCDB.INDEX.PAGE.TESTS")
    ("ARCDOCDB.VERTICAL.TESTS" :explicit)
    ("ARCDOCDB.ENGINE.TESTS")
    ("ARCDOCDB.LOCAL.WIRE.TESTS")
    ("ARCDOCDB.LOCAL.NATIVE.TESTS")
    ("ARCDOCDB.LOCAL.SERVER.TESTS")
    ("ARCDOCDB.LOCAL.PROCESS.TESTS")))

(defparameter *vertical-cases*
  '("TEST-REQ-REC-001-VERTICAL-NATIVE-SIGKILL-REOPEN-V1-V2"
    "TEST-REQ-VAL-001-VERTICAL-ORACLE-REJECTS-WRONG-VALUE"
    "TEST-REQ-REC-001-VERTICAL-RESUME-WRITES-SECOND-SIGKILL-V1-V2"
    "TEST-REQ-VAL-001-VERTICAL-ORACLE-REJECTS-REUSED-CSN"))

(defparameter *vertical-display-names*
  '("test-REQ-REC-001-vertical-native-SIGKILL-reopen-v1-v2"
    "test-REQ-VAL-001-vertical-oracle-rejects-wrong-value"
    "test-REQ-REC-001-vertical-resume-writes-second-SIGKILL-v1-v2"
    "test-REQ-VAL-001-vertical-oracle-rejects-reused-CSN"))

(defparameter *coverage-exclusions*
  '("ARCDOCDB.FULLTEXT.ANALYSIS.TESTS::REQ-SEC-008-FRAMING-ALLOCATION"
    "ARCDOCDB.FULLTEXT.ANALYSIS.TESTS::REQ-SEC-010-HOT-PATH-ALLOCATION"
    "ARCDOCDB.FULLTEXT.CODEC.TESTS::REQ-SEC-010-CODEC-HOT-ALLOCATION"
    "ARCDOCDB.FULLTEXT.DOCUMENT.TESTS::REQ-SEC-010-DOCUMENT-HOT-ALLOCATION"
    "ARCDOCDB.FULLTEXT.ADMISSION.TESTS::REQ-SEC-010-RESERVATION-HOT-ALLOCATION"
    "ARCDOCDB.FULLTEXT.PUT.TESTS::REQ-SEC-010-PUT-HOT-ALLOCATION"
    "ARCDOCDB.INDEX.MODE.TESTS::REQ-IDX-008-FINESTRA-SENZA-ALLOCAZIONE"))

(defvar *definitions* (make-hash-table :test #'equal))
(defvar *case-observer* nil)
(defvar *inside-case* nil)

(defun qualified-id (package name)
  (concatenate 'string package "::" name))

(defun suite-specifications ()
  "Inventario statico: nessun lookup del prodotto, nessun conteggio inferito."
  (loop for (package adapter registry) in *suite-table*
        collect (list :id package :package package :runner "RUN"
                      :adapter (or adapter :symbol-list)
                      :registry (unless (member adapter '(:smoke :explicit))
                                  (or registry "*TESTS*"))
                      :cases (case adapter
                               (:smoke '("PACKAGE-PRESENT" "VERSION-STRING"))
                               (:explicit (copy-list *vertical-cases*))))))

(defun lookup (package name &optional function-p)
  (let* ((pkg (find-package package)) (sym (and pkg (find-symbol name pkg))))
    (unless (and sym (or (not function-p) (fboundp sym)))
      (error "Catalogo: simbolo mancante ~A::~A." package name))
    sym))

(defun proper-size (object &optional (limit 100000))
  (let ((n (and (listp object)
                (handler-case (list-length object) (type-error () nil)))))
    (unless (and n (<= n limit)) (error "Catalogo: lista impropria/ciclica o oltre budget."))
    n))

(defun normalize-registry (package adapter registry)
  "Adattatori distinti; l'alist ha cdr funzione, non una lista (nome funzione)."
  (proper-size registry)
  (let ((seen (make-hash-table :test #'equal)))
    (loop for entry in (reverse registry)
          for name = (ecase adapter (:symbol-list entry) (:alist (and (consp entry) (car entry))))
          for id = (and (symbolp name) (qualified-id package (symbol-name name)))
          do (unless (and name (symbolp name) (symbol-package name)
                          (string= package (package-name (symbol-package name)))
                          (fboundp name)
                          (or (eq adapter :symbol-list) (functionp (cdr entry))))
               (error "Catalogo: registro ~A ~S non valido." package adapter))
          do (when (gethash id seen) (error "Catalogo: ID duplicato ~A." id))
             (setf (gethash id seen) t)
          collect (list :id id :suite package :name (symbol-name name) :source nil))))

(defun begin-source (source)
  "Un load dello stesso FASL sostituisce solo la sua provenienza precedente."
  (let ((old nil))
    (maphash (lambda (id row) (when (equal source (getf row :source)) (push id old))) *definitions*)
    (dolist (id old) (remhash id *definitions*))))

(defun register-definition (package name source)
  "Eseguito dal FASL prima di PUSHNEW/ACONS: duplicati non occultabili dal registro."
  (let ((id (qualified-id package name)))
    (when (gethash id *definitions*)
      (error "Catalogo: definizione duplicata ~A (~A, ~A)." id
             (getf (gethash id *definitions*) :source) source))
    (setf (gethash id *definitions*) (list :id id :source source))))

(defun call-registered-case (id thunk)
  (if (and *case-observer* (not *inside-case*))
      (let ((*inside-case* t)) (funcall *case-observer* id thunk))
      (funcall thunk)))

(defun condition-text (condition)
  (let* ((*print-readably* nil) (*print-length* 20) (*print-level* 6) (*print-circle* t)
         (text (princ-to-string condition)))
    (subseq text 0 (min 8192 (length text)))))

(defun call-with-registration-audit (thunk)
  "Hook ASDF; i FASL conservano provenienza e osservazione anche in un nuovo Lisp.
Fonte API: https://asdf.common-lisp.dev/asdf.html#Controlling-file-compilation"
  (let ((previous *macroexpand-hook*) (first t))
    (let ((*macroexpand-hook*
            (lambda (expander form environment)
              (let* ((head (and (consp form) (first form)))
                     (name (and (consp form) (second form)))
                     (pkg (and (symbolp name) (symbol-package name)))
                     (package (and pkg (package-name pkg)))
                     (registered (and (symbolp head) (string= (symbol-name head) "DEFTEST")
                                      package (assoc package *suite-table* :test #'equal)))
                     (explicit (and (eq head 'defun) (equal package "ARCDOCDB.VERTICAL.TESTS")
                                    (member (symbol-name name) *vertical-cases* :test #'equal))))
                (if (or registered explicit)
                    (let* ((name (second form))
                           (root (funcall (lookup "ASDF" "SYSTEM-SOURCE-DIRECTORY" t) "arcdocdb"))
                           (source (enough-namestring *compile-file-truename* root))
                           (id (qualified-id package (symbol-name name)))
                           (begin first))
                      (setf first nil)
                      `(progn
                         ,@(when begin `((begin-source ,source)))
                         (register-definition ,package ,(symbol-name name) ,source)
                         ,(funcall previous expander
                                   (if registered
                                       `(,head ,name
                                          (call-registered-case ,id (lambda () ,@(cddr form))))
                                       form)
                                   environment)))
                    (funcall previous expander form environment))))))
      (funcall thunk))))

(defun discover ()
  "Tutti i casi prima di RUN. Suite assente => PLANNED NIL, mai zero inventato."
  (let ((tests nil) (suites nil) (complete t) (known 0)
        (specs (suite-specifications)) (seen (make-hash-table :test #'equal)))
    (dolist (spec specs)
      (let* ((package (getf spec :package))
             (adapter (getf spec :adapter)) (rows nil) (reason nil))
        (when (gethash package seen) (error "Suite duplicata ~A." package))
        (setf (gethash package seen) t)
        (handler-case
            (progn
              (lookup package "RUN" t)
              (setf rows
                    (if (member adapter '(:smoke :explicit))
                        (loop for name in (getf spec :cases)
                              do (when (eq adapter :explicit) (lookup package name t))
                              collect (list :id (qualified-id package name) :suite package :name name
                                            :source (if (eq adapter :smoke) "tests/smoke.lisp"
                                                        "tests/vertical/processes.lisp")))
                        (let ((registry (lookup package (getf spec :registry))))
                          (unless (boundp registry) (error "Registro non caricato ~A." registry))
                          (normalize-registry package adapter (symbol-value registry)))))
              (unless (eq adapter :smoke)
                (dolist (row rows)
                  (let ((definition (gethash (getf row :id) *definitions*)))
                    (unless definition (error "Provenienza non registrata: ~A." (getf row :id)))
                    (setf (getf row :source) (getf definition :source)))))
              ;; Rifiuta casi presenti nelle definizioni ma rimossi dal registro finale.
              (maphash (lambda (id definition)
                         (declare (ignore definition))
                         (when (and (<= (+ 2 (length package)) (length id))
                                    (string= (concatenate 'string package "::") id
                                             :end2 (+ 2 (length package)))
                                    (not (find id rows :key (lambda (r) (getf r :id)) :test #'equal)))
                           (error "Definizione non inventariata ~A." id))) *definitions*))
          (error (condition) (setf reason (condition-text condition) rows nil complete nil)))
        (incf known (length rows))
        (push (append (copy-list spec)
                      (list :status (if reason :missing :ready) :reason reason
                            :planned (unless reason (length rows)))) suites)
        (dolist (row rows)
          (push (append row (list :status :not-run :reason :not-started
                                  :condition nil :duration-ticks nil)) tests))))
    (dolist (pkg (list-all-packages))
      (let* ((name (package-name pkg)) (n (length name)) (run (find-symbol "RUN" pkg)))
        (when (and (> n 15) (string= name "ARCDOCDB." :end1 9)
                   (string= name ".TESTS" :start1 (- n 6))
                   (not (equal name "ARCDOCDB.CI.TESTS")) run (fboundp run)
                   (not (gethash name seen)))
          (error "Suite sconosciuta al catalogo: ~A." name))))
    (list :kind :ci-test-inventory :status (if complete :ready :missing)
          :planned (when complete known) :known-planned known
          :tests (nreverse tests) :suites (nreverse suites))))

(defun wire-value-p (value &optional (depth 0))
  (and (< depth 64)
       (typecase value
         (null t) (integer t) (string t)
         (symbol (or (eq value t) (keywordp value)))
         (cons (proper-size value)
               (every (lambda (x) (wire-value-p x (1+ depth))) value)))))

(defun write-data (stream data)
  "Writer plain: mai dispatch, oggetti opachi, float o dipendenza dal pretty printer."
  (unless (wire-value-p data) (error "Catalogo: valore estraneo al wire."))
  (with-standard-io-syntax
    (let ((*print-readably* nil) (*print-pretty* nil) (*print-circle* nil)
          (*print-level* nil) (*print-length* nil)
          (bytes 0) (elements 0))
      (labels ((emit (character)
                 (incf bytes (let ((n (char-code character)))
                               (cond ((< n 128) 1) ((< n 2048) 2)
                                     ((<= #xd800 n #xdfff) (error "Surrogato Unicode nel wire."))
                                     ((< n 65536) 3) ((<= n #x10ffff) 4)
                                     (t (error "Carattere fuori Unicode.")))))
                 (when (> bytes 1048576) (error "Catalogo: wire oltre 1 MiB."))
                 (write-char character stream))
               (text (value) (loop for character across value do (emit character)))
               (value (item depth)
                 (when (or (> depth 32) (> (incf elements) 100000))
                   (error "Catalogo: wire oltre budget profondità/elementi."))
                 (cond ((null item) (text "NIL"))
                       ((eq t item) (text "T"))
                       ((keywordp item)
                        (let ((name (symbol-name item)))
                          (unless (and (<= 1 (length name) 127)
                                       (every (lambda (c) (or (char<= #\A c #\Z)
                                                              (char<= #\0 c #\9)
                                                              (find c "-_"))) name))
                            (error "Catalogo: keyword non rappresentabile."))
                          (emit #\:) (text name)))
                       ((integerp item)
                        (unless (<= (- (expt 2 127)) item (1- (expt 2 127)))
                          (error "Catalogo: intero fuori signed-128."))
                        (text (format nil "~D" item)))
                       ((stringp item)
                        (let ((start bytes))
                          (emit #\")
                          (loop for c across item do
                            (when (find c "\\\"") (emit #\\)) (emit c))
                          (emit #\")
                          (when (> (- bytes start 2) 65536) (error "Catalogo: stringa oltre 64 KiB."))))
                       (t (emit #\()
                          (loop for tail on item do
                            (unless (eq tail item) (emit #\Space))
                            (value (car tail) (1+ depth)))
                          (emit #\))))))
        (value data 0) (terpri stream) (finish-output stream)))))

(defun save-data (path data &key replace)
  (ensure-directories-exist path)
  (with-open-file (stream path :direction :output :external-format :utf-8
                              :if-exists (if replace :supersede :error)
                              :if-does-not-exist :create)
    (write-data stream data)) data)

(defun smoke-case (name)
  (let* ((package (find-package "ARCDOCDB"))
         (ok (if (equal name "PACKAGE-PRESENT") package
                 (let ((symbol (and package (find-symbol "*VERSION*" package))))
                   (and symbol (boundp symbol) (stringp (symbol-value symbol)))))))
    (format t "~:[FAIL~;ok  ~]  ~A~%" ok
            (if (equal name "PACKAGE-PRESENT") "package ARCDOCDB presente"
                "ARCDOCDB:*VERSION* è una stringa"))
    (unless ok (error "Smoke test fallito.")) t))

(defun invoke-suite (spec excluded)
  (let* ((package (getf spec :package)) (adapter (getf spec :adapter)))
    (case adapter
      (:smoke
       (dolist (name (getf spec :cases))
         (call-registered-case (qualified-id package name) (lambda () (smoke-case name)))))
      (:explicit
       (loop for name in (getf spec :cases) for display in *vertical-display-names* do
         (call-registered-case (qualified-id package name)
                               (lambda () (funcall (lookup package name t))))
         (format t "ok    ~A~%" display))
       (format t "4 test verticali superati; 16 scenari positivi e 2 controlli negativi.~%"))
      (otherwise
       (let* ((symbol (lookup package (getf spec :registry)))
              (registry (symbol-value symbol))
              (selected (remove-if
                         (lambda (entry)
                           (member (qualified-id package
                                                 (symbol-name (if (eq adapter :alist) (car entry) entry)))
                                   excluded :test #'equal)) registry)))
         ;; PROGV mantiene gli stessi runner e stdout di make check; nessuna ridefinizione.
         (progv (list symbol) (list selected) (funcall (lookup package "RUN" t))))))))

(defun run (&key report-path excluded-tests)
  "Scrive prima inventario e poi eventi flushati; al primo errore termina la sessione.
REPORT-PATH contiene un solo riepilogo wire. Il sibling *.events.lisp è append-only.
Senza REPORT-PATH propaga il fallimento ad ASDF. Nessun test viene eseguito al load."
  (let* ((inventory (discover)) (rows (getf inventory :tests)) (suites (getf inventory :suites))
         (event-path (and report-path
                          (make-pathname :name (concatenate 'string (pathname-name report-path) ".events")
                                         :defaults report-path)))
         (events nil) (sequence 0) (failure nil) (report nil)
         (run-start (get-internal-real-time)))
    (proper-size excluded-tests)
    (dolist (id excluded-tests)
      (unless (and (member id *coverage-exclusions* :test #'equal)
                   (find id rows :key (lambda (r) (getf r :id)) :test #'equal))
        (error "Esclusione non autorizzata o assente: ~A." id)))
    (labels ((snapshot (status)
               (setf report
                     (list :schema-version 1 :kind :ci-tests :status status
                           :planned (getf inventory :planned) :known-planned (getf inventory :known-planned)
                           :started (count-if (lambda (r) (member (getf r :status) '(:started :passed :failed))) rows)
                           :passed (count :passed rows :key (lambda (r) (getf r :status)))
                           :failed (count :failed rows :key (lambda (r) (getf r :status)))
                           :not-run (count :not-run rows :key (lambda (r) (getf r :status)))
                           :skipped (length excluded-tests)
                           :ticks (- (get-internal-real-time) run-start)
                           :time-unit internal-time-units-per-second
                           :duration-unit :internal-time-ticks :ticks-per-second internal-time-units-per-second
                           :tests rows :suites suites :events (when event-path (file-namestring event-path))
                           :condition failure))
               (when report-path (save-data report-path report :replace t)) report)
             (event (state row &optional detail)
               (when events
                 (write-data events (list :sequence (incf sequence) :event state
                                          :suite (getf row :suite) :test (getf row :id)
                                          :tick (get-internal-real-time) :detail detail))))
             (observe (id thunk)
               (let ((row (find id rows :key (lambda (r) (getf r :id)) :test #'equal))
                     (start (get-internal-real-time)))
                 (unless (and row (eq :not-run (getf row :status))
                              (not (member id excluded-tests :test #'equal)))
                   (error "Chiamata inattesa o duplicata al test ~A." id))
                 (setf (getf row :status) :started (getf row :reason) nil)
                 (event :started row)
                 (handler-case
                     (multiple-value-prog1 (funcall thunk)
                       (setf (getf row :status) :passed
                             (getf row :duration-ticks) (- (get-internal-real-time) start))
                       (event :passed row))
                   (serious-condition (condition)
                     (setf (getf row :status) :failed (getf row :reason) :test-error
                           (getf row :condition) (condition-text condition)
                           (getf row :duration-ticks) (- (get-internal-real-time) start))
                     (event :failed row (getf row :condition))
                     (error condition))))))
      ;; Exclusive reservation precedes replace snapshots; never clobber an older campaign.
      (when report-path (save-data report-path inventory))
      (unwind-protect
           (progn
             (when event-path
               (setf events (open event-path :direction :output :external-format :utf-8
                                            :if-exists :error :if-does-not-exist :create))
               (write-data events (list :event :inventory :data inventory)))
             (dolist (row rows)
               (when (member (getf row :id) excluded-tests :test #'equal)
                 (setf (getf row :reason) :coverage-allocation-exclusion)))
             (snapshot :running)
             (if (not (eq :ready (getf inventory :status)))
                 (setf failure "Inventario incompleto: cardinalità totale sconosciuta.")
                 (let ((*case-observer* #'observe))
                   (dolist (suite suites)
                     (if failure
                         (setf (getf suite :status) :not-run (getf suite :reason) :runner-stopped)
                         (handler-case
                             (progn
                               (setf (getf suite :status) :started)
                               (event :suite-started (list :suite (getf suite :id)))
                               (invoke-suite suite excluded-tests)
                               (when (find-if (lambda (r)
                                                (and (equal (getf r :suite) (getf suite :id))
                                                     (eq :not-run (getf r :status))
                                                     (not (member (getf r :id) excluded-tests :test #'equal)))) rows)
                                 (error "Il runner non ha eseguito tutti i casi inventariati."))
                               (setf (getf suite :status) :passed)
                               (event :suite-passed (list :suite (getf suite :id))))
                           (serious-condition (condition)
                             (setf failure (condition-text condition)
                                   (getf suite :status) :failed (getf suite :reason) :runner-stopped)
                             (event :suite-failed (list :suite (getf suite :id)) failure))))
                     (snapshot :running))))
             (dolist (row rows)
               (when (and failure (eq :not-run (getf row :status))
                          (eq :not-started (getf row :reason)))
                 (setf (getf row :reason) :runner-stopped)))
             (snapshot (if failure :failed :passed)))
        (when events (close events)))
      (when (and failure (not report-path)) (error "Catalogo test: ~A" failure))
      report)))
