;;;; Fixture C4 dei confini delle condizioni serie; nessun autorun o load del prodotto.
;;; REQ: REQ-VAL-001 REQ-AFF-012
;;; OWNER: il controller possiede package, registri e destinazioni esclusive della fixture.
;;; SHARED: nessuno; CI-CHILD viene sostituita soltanto durante una chiamata sincrona.
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 3)))

(defun ci-condition-require (predicate description)
  (unless predicate (error "Fixture condizioni CI: ~A." description))
  t)

(defun ci-condition-fixture (function &key case-condition runner-condition)
  "Due casi reali del catalogo, provenienza esplicita e package transitorio.
Le condizioni sono oggetti precreati: nessuna attesa o scadenza dello scheduler."
  (let* ((name (symbol-name (gensym "ARCDOCDB.CI.CONDITIONS.FIXTURE.")))
         (package (make-package name :use nil))
         (one (intern "ONE" package)) (two (intern "TWO" package))
         (registry (intern "*TESTS*" package)) (runner (intern "RUN" package))
         (calls (vector 0 0)))
    (unwind-protect
         (progn
           (setf (symbol-value registry) (list two one))
           (loop for symbol in (list one two) for index from 0 do
             (let ((position index)
                   (id (arcdocdb.ci.tests::qualified-id name (symbol-name symbol))))
               (setf (symbol-function symbol)
                     (lambda ()
                       (arcdocdb.ci.tests::call-registered-case
                        id (lambda ()
                             (incf (aref calls position))
                             (when (and (zerop position) case-condition)
                               (error case-condition))
                             t))))))
           (setf (symbol-function runner)
                 (lambda ()
                   (when runner-condition (error runner-condition))
                   (dolist (case (reverse (symbol-value registry))) (funcall case))
                   t))
           (let ((arcdocdb.ci.tests::*suite-table* (list (list name :symbol-list "*TESTS*")))
                 (arcdocdb.ci.tests::*definitions* (make-hash-table :test #'equal))
                 (arcdocdb.ci.tests::*case-observer* nil)
                 (arcdocdb.ci.tests::*inside-case* nil))
             (dolist (symbol (list one two))
               (arcdocdb.ci.tests::register-definition
                name (symbol-name symbol) "tests/ci-conditions-fixture.lisp"))
             (funcall function name calls)))
      (delete-package package))))

(defun ci-condition-events (path)
  "Legge soltanto gli eventi appena scritti dalla fixture trusted, senza READ-EVAL."
  (with-standard-io-syntax
    (let ((*read-eval* nil) (eof (gensym "EOF")))
      (with-open-file (stream path :external-format :utf-8)
        (loop for event = (read stream nil eof) until (eq event eof) collect event)))))

(defun ci-condition-check-counts (report started passed failed not-run)
  (loop for key in '(:planned :known-planned :started :passed :failed :not-run :skipped)
        for expected in (list 2 2 started passed failed not-run 0)
        do (ci-condition-require (eql expected (getf report key))
                                 (format nil "contatore ~S atteso ~D" key expected)))
  t)

(defun ci-condition-check-source (report package)
  (dolist (row (getf report :tests))
    (ci-condition-require
     (and (equal package (getf row :suite))
          (equal "tests/ci-conditions-fixture.lisp" (getf row :source)))
     "attribuzione suite e sorgente del caso"))
  t)

(defun ci-condition-recorded-failure (directory condition runner-p)
  "Verifica rapporto finale, contatori, eventi e mancata esecuzione dei casi successivi."
  (ci-condition-fixture
   (lambda (package calls)
     (let* ((path (merge-pathnames "tests.lisp" directory))
            (report (arcdocdb.ci.tests:run :report-path path))
            (rows (getf report :tests)) (suite (first (getf report :suites)))
            (text (arcdocdb.ci.tests::condition-text condition))
            (events (ci-condition-events (merge-pathnames "tests.events.lisp" directory))))
       (ci-condition-require (and (eq :ci-tests (getf report :kind))
                                  (eq :failed (getf report :status))
                                  (equal text (getf report :condition)))
                             "rapporto finale fallito con condizione originale")
       (ci-condition-check-counts report (if runner-p 0 1) 0 (if runner-p 0 1)
                                  (if runner-p 2 1))
       (ci-condition-check-source report package)
       (ci-condition-require
        (and (= 1 (length (getf report :suites)))
             (eq :failed (getf suite :status)) (eq :runner-stopped (getf suite :reason)))
        "suite fallita, mai verde dopo una condizione seria")
       (ci-condition-require (equalp calls (if runner-p #(0 0) #(1 0)))
                             "nessun corpo successivo eseguito")
       (ci-condition-require (= 2 (length rows)) "due casi inventariati")
       (unless runner-p
         (let ((first (first rows)))
           (ci-condition-require
            (and (eq :failed (getf first :status)) (eq :test-error (getf first :reason))
                 (equal text (getf first :condition))
                 (integerp (getf first :duration-ticks))
                 (not (minusp (getf first :duration-ticks))))
            "caso fallito con condizione e durata")))
       (dolist (row (if runner-p rows (rest rows)))
         (ci-condition-require (and (eq :not-run (getf row :status))
                                    (eq :runner-stopped (getf row :reason))
                                    (null (getf row :duration-ticks)))
                               "caso successivo non eseguito e motivo esplicito"))
       (ci-condition-require
        (equal (mapcar (lambda (event) (getf event :event)) events)
               (if runner-p '(:inventory :suite-started :suite-failed)
                   '(:inventory :suite-started :started :failed :suite-failed)))
        "sequenza esatta degli eventi del fallimento")
       (loop for event in (rest events) for sequence from 1 do
         (ci-condition-require (and (eql sequence (getf event :sequence))
                                    (equal package (getf event :suite)))
                               "eventi attribuiti e sequenze contigue"))
       (unless runner-p
         (let ((id (arcdocdb.ci.tests::qualified-id package "ONE")))
           (ci-condition-require
            (and (equal id (getf (third events) :test))
                 (equal id (getf (fourth events) :test))
                 (equal text (getf (fourth events) :detail)))
            "eventi STARTED/FAILED attribuiti allo stesso caso")))
       (ci-condition-require (equal text (getf (car (last events)) :detail))
                             "evento finale conserva la condizione della suite")
       (ci-condition-require (equal report (ci-read path))
                             "rapporto persistito identico al risultato in memoria")
       t))
   :case-condition (unless runner-p condition) :runner-condition (when runner-p condition)))

(defun ci-condition-recorded-success (directory)
  "Controllo positivo: nessuna intercettazione produce un fallimento inventato."
  (ci-condition-fixture
   (lambda (package calls)
     (let* ((path (merge-pathnames "tests.lisp" directory))
            (report (arcdocdb.ci.tests:run :report-path path))
            (events (ci-condition-events (merge-pathnames "tests.events.lisp" directory))))
       (ci-condition-require (and (eq :passed (getf report :status))
                                  (null (getf report :condition))
                                  (eq :passed (getf (first (getf report :suites)) :status)))
                             "controllo positivo del catalogo")
       (ci-condition-check-counts report 2 2 0 0)
       (ci-condition-check-source report package)
       (ci-condition-require (equalp calls #(1 1)) "entrambi i corpi positivi eseguiti")
       (ci-condition-require (every (lambda (row) (eq :passed (getf row :status)))
                                    (getf report :tests)) "due casi positivi passati")
       (ci-condition-require
        (equal (mapcar (lambda (event) (getf event :event)) events)
               '(:inventory :suite-started :started :passed :started :passed :suite-passed))
        "eventi del controllo positivo")
       (ci-condition-require (equal report (ci-read path)) "persistenza del controllo positivo")
       t))))

(defun ci-condition-asdf-failure (runner-p)
  "Senza report il percorso ASDF deve rilanciare ERROR, mai lasciare sfuggire TIMEOUT."
  (let ((condition (make-condition 'sb-ext:timeout)))
    (ci-condition-fixture
     (lambda (package calls)
       (declare (ignore package))
       (let ((observed (handler-case (progn (arcdocdb.ci.tests:run) nil)
                         (error (failure) failure))))
         (ci-condition-require
          (and (typep observed 'error) (not (eq condition observed))
               (search "Catalogo test:" (princ-to-string observed)))
          "ASDF segnala ERROR dopo il riepilogo del fallimento")
         (ci-condition-require (equalp calls (if runner-p #(0 0) #(1 0)))
                               "ASDF interrompe i corpi successivi")
         t))
     :case-condition (unless runner-p condition) :runner-condition (when runner-p condition))))

(defun ci-condition-child-result (directory failure-p)
  "FI sincrona del solo ingresso child; ripristino della funzione anche sul codice difettoso."
  (let ((original (symbol-function 'ci-child)) (calls 0)
        (condition (make-condition 'sb-ext:timeout))
        (path (merge-pathnames "child-result.lisp" directory)))
    (unwind-protect
         (progn
           (setf (symbol-function 'ci-child)
                 (lambda (job out)
                   (incf calls)
                   (ci-condition-require (and (equal "verify-linux" job)
                                              (equal directory (ci-directory out)))
                                         "argomenti originali del child")
                   (if failure-p (error condition) 0)))
           (ci-condition-require (eql (if failure-p 1 0)
                                      (ci-child-bounded "verify-linux" directory))
                                 "codice di uscita coerente del confine child")
           (ci-condition-require (= 1 calls) "un solo tentativo child")
           (if failure-p
               (let ((report (ci-read path)))
                 (ci-condition-require
                  (and (eql 1 (getf report :schema-version))
                       (eq :ci-child-failure (getf report :kind))
                       (eq :failed (getf report :status))
                       (equal "verify-linux" (getf report :job))
                       (equal (princ-to-string condition) (getf report :reason)))
                  "fallback child persistito con la condizione originale"))
               (ci-condition-require (null (ci-lstat path))
                                     "nessun fallback di errore nel controllo positivo")))
      (setf (symbol-function 'ci-child) original))
    (ci-condition-require (eq original (symbol-function 'ci-child))
                          "funzione CI-CHILD ripristinata")
    t))

(defun ci-conditions-self-test (out)
  "Nove prove C4 deterministiche: sei controlli negativi, nessun processo o prodotto.
Le condizioni serie che sfuggono al codice precedente diventano righe FAILED della regressione."
  (let ((root (ci-mkdir out)) (cases nil) (negative 0))
    (labels ((check (id thunk &optional negative-p)
               (when negative-p (incf negative))
               (handler-case
                   (push (list :id id :status (if (funcall thunk) :passed :failed)) cases)
                 (serious-condition (condition)
                   (push (list :id id :status :failed
                               :condition (arcdocdb.ci.tests::condition-text condition)) cases))))
             (fixture-directory (name) (ci-mkdir (merge-pathnames name root))))
      (check "timeout-is-serious-not-error"
             (lambda () (let ((condition (make-condition 'sb-ext:timeout)))
                          (and (typep condition 'serious-condition)
                               (not (typep condition 'error))))))
      (check "catalog-positive-control"
             (lambda () (ci-condition-recorded-success (fixture-directory "catalog-positive/"))))
      (check "ordinary-error-attribution"
             (lambda () (ci-condition-recorded-failure
                         (fixture-directory "ordinary-error/")
                         (make-condition 'simple-error :format-control "EXPECTED-CI-ERROR"
                                                       :format-arguments nil) nil)) t)
      (check "registered-timeout-attribution"
             (lambda () (ci-condition-recorded-failure
                         (fixture-directory "registered-timeout/") (make-condition 'sb-ext:timeout) nil)) t)
      (check "runner-timeout-before-case-attribution"
             (lambda () (ci-condition-recorded-failure
                         (fixture-directory "runner-timeout/") (make-condition 'sb-ext:timeout) t)) t)
      (check "asdf-registered-timeout-signals-error"
             (lambda () (ci-condition-asdf-failure nil)) t)
      (check "asdf-runner-timeout-signals-error"
             (lambda () (ci-condition-asdf-failure t)) t)
      (check "child-timeout-durable-failure"
             (lambda () (ci-condition-child-result (fixture-directory "child-timeout/") t)) t)
      (check "child-positive-control"
             (lambda () (ci-condition-child-result (fixture-directory "child-positive/") nil))))
    (let* ((ordered (nreverse cases))
           (failed (count :failed ordered :key (lambda (row) (getf row :status))))
           (report (list :schema-version 1 :kind :ci-test-self-test
                         :status (if (zerop failed) :passed :failed)
                         :counts (list :planned (length ordered) :started (length ordered)
                                       :passed (- (length ordered) failed) :failed failed :not-run 0
                                       :negative-cases negative)
                         :fixture-data-only t :cases ordered)))
      (ci-save (merge-pathnames "conditions-self-test.lisp" root) report)
      report)))
