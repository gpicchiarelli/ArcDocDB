;;;; Mutazioni semantiche dell'handoff writer in copie isolate.
;;;; Uso: --self-test oppure --run directory-nuova/; writer-handoff-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-005 REQ-AFF-008
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-handoff.mutation (:use #:cl))
(in-package #:arcdocdb.writer-handoff.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *handoff-mutants*
  '(("handoff-idle-stays-idle" "src/execution/handoff.lisp"
     (("(when schedule (setf (writer-programmabile-state writer) :ready))"
       "(when schedule (setf (writer-programmabile-state writer) :idle))")))
    ("handoff-duplicate-schedule" "src/execution/handoff.lisp"
     (("(values count (if schedule :schedule :queued))"
       "(values count (if schedule :schedule :schedule))")))
    ("handoff-running-enqueue-ready" "src/execution/handoff.lisp"
     (("(when schedule (setf (writer-programmabile-state writer) :ready))"
       "(when (or schedule (eq (writer-programmabile-state writer) :running))
               (setf (writer-programmabile-state writer) :ready))")))
    ("handoff-start-idle" "src/execution/handoff.lisp"
     (("(unless (eq (writer-programmabile-state writer) :ready)"
       "(when (eq (writer-programmabile-state writer) :running)")))
    ("handoff-start-stays-ready" "src/execution/handoff.lisp"
     (("(setf (writer-programmabile-state writer) :running)"
       "(setf (writer-programmabile-state writer) :ready)")))
    ("handoff-backlog-goes-idle" "src/execution/handoff.lisp"
     (("(if pending :ready :idle)" "(if pending :idle :idle)")))
    ("handoff-backlog-loses-schedule" "src/execution/handoff.lisp"
     (("(if pending :schedule :idle)" "(if pending :idle :idle)")))
    ("handoff-empty-goes-ready" "src/execution/handoff.lisp"
     (("(if pending :ready :idle)" "(if pending :ready :ready)")))))

(defun original-queue-mutations ()
  "Legge la lista originale senza LOAD/EVAL; conserva mutanti del ring/lease sul refactor."
  (let ((*read-eval* nil))
    (with-open-file (stream "tools/writer-queue-mutation.lisp" :external-format :utf-8)
      (loop for form = (read stream nil :eof) until (eq form :eof)
            when (and (consp form) (eq (first form) 'defparameter)
                      (eq (second form) '*mutants*))
              do (unless (and (= 3 (length form)) (equal 'quote (first (third form))))
                   (error "COD-60: lista mutanti writer-queue non dichiarativa."))
                 (return-from original-queue-mutations
                   (mapcar (lambda (mutant)
                             (destructuring-bind (path name before after) mutant
                               (list name path (list (list before after)))))
                           (second (third form)))))))
  (error "COD-60: lista mutanti writer-queue assente."))

(defun mutation-list ()
  "Otto mutanti handoff e otto originali writer-queue, fissati prima della campagna."
  (append *handoff-mutants* (original-queue-mutations)))

(defun source-files ()
  "ASD, build, sorgenti e test richiesti dalle copie; nessuna evidenza o Git copiati."
  (append '(#p"arcdocdb.asd" #p"tools/build.lisp")
          (sort (append (directory "src/**/*.lisp") (directory "tests/**/*.lisp"))
                #'string< :key #'namestring)))

(defun fingerprints ()
  "MD5 dei file copiati e del driver: controllo di stabilità, non di autenticità."
  (loop for file in (append (source-files) '(#p"tools/writer-handoff-mutation.lisp"
                                            #p"tools/writer-queue-mutation.lisp"))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun read-text (path)
  "Legge sorgente e log UTF-8 come dati, senza interpretazione."
  (uiop:read-file-string path :external-format :utf-8))

(defun mutate-once (source before after name)
  "COD-60: bersaglio unico e non vuoto, modifica effettiva, nessuna riscrittura originale."
  (let ((position (search before source)))
    (unless (and (plusp (length before)) position (not (string= before after))
                 (not (search before source :start2 (1+ position))))
      (error "COD-60: mutante ~A, bersaglio assente/ambiguo o identico: ~S" name before))
    (concatenate 'string (subseq source 0 position) after
                 (subseq source (+ position (length before))))))

(defun mutated-source (mutant)
  "Valida ogni modifica nell'originale e nel risultato delle modifiche precedenti."
  (destructuring-bind (name path edits) mutant
    (let* ((original (read-text path)) (result original))
      (unless edits (error "COD-60: mutante ~A senza modifiche." name))
      (dolist (edit edits)
        (destructuring-bind (before after) edit
          (mutate-once original before after name)
          (setf result (mutate-once result before after name))))
      result)))

(defun validate-mutations (mutants)
  "Sedici nomi unici; ogni bersaglio appare una sola volta nei sorgenti congelati."
  (unless (= 16 (length mutants)) (error "COD-60: numero mutanti handoff/ring diverso da sedici."))
  (let ((names nil))
    (dolist (mutant mutants)
      (when (member (first mutant) names :test #'string=)
        (error "COD-60: nome mutante ripetuto: ~A" (first mutant)))
      (push (first mutant) names)
      (mutated-source mutant)))
  nil)

(defun event-at-line-start-p (text marker)
  "Solo eventi a inizio riga; citazioni e frammenti di backtrace non contano."
  (loop for line in (uiop:split-string text :separator '(#\Newline))
        thereis (and (<= (length marker) (length line))
                     (string= marker line :end2 (length marker)))))

(defun classify-result (text exit)
  "Compilazione fallita e guasti prima dei test non sono mutanti rilevati."
  (cond ((or (search "compilation aborted" text :test #'char-equal)
             (search "COMPILE-FILE-ERROR" text :test #'char-equal)
             (search "COMPILE-FILE-WARNED" text :test #'char-equal)
             (search "non ammesso (COD-01)" text)) :compilation-failure)
        ((or (not (integerp exit))
             (not (event-at-line-start-p text "execution-test-start "))) :before-tests)
        ((not (zerop exit)) :detected)
        ((event-at-line-start-p text "execution-tests-complete ") :survived)
        (t :before-tests)))

(defun copy-test-system (directory)
  "Copia tutti i sorgenti e test ASDF; gli output delle copie restano privati."
  (dolist (file (source-files))
    (let ((target (merge-pathnames (enough-namestring file) directory)))
      (ensure-directories-exist target)
      (uiop:copy-file file target)))
  nil)

(defun write-runner (directory)
  "Compilazione rigorosa e intera suite execution registrata, inclusi i test handoff."
  (let ((path (merge-pathnames "tools/writer-handoff-isolated-build.lisp" directory)))
    (with-open-file (stream path :direction :output :if-exists :error)
      (dolist (form
                '((require :asdf)
                  (setf asdf:*user-cache* (merge-pathnames "fasl/" (truename "./"))
                        asdf:*compile-file-failure-behaviour* :error
                        asdf:*compile-file-warnings-behaviour* :error)
                  (handler-bind
                      ((warning (lambda (condition)
                                  (unless (typep condition 'sb-kernel:redefinition-warning)
                                    (error "~A non ammesso (COD-01): ~A"
                                           (type-of condition) condition)))))
                    (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
                    (asdf:load-system "arcdocdb" :force t)
                    (asdf:load-system "arcdocdb/tests" :force t))
                  (unless (and (probe-file "tests/execution/handoff.lisp")
                               (asdf:find-component (asdf:find-system "arcdocdb/tests")
                                                    '("execution" "handoff")))
                    (error "Test handoff assente o non registrato in ASDF."))
                  (let* ((package (or (find-package "ARCDOCDB.EXECUTION.TESTS")
                                      (error "Harness execution non caricato.")))
                         (registry (or (find-symbol "*TESTS*" package)
                                       (error "Registro execution assente.")))
                         (tests (reverse (symbol-value registry))))
                    (unless (and tests (every #'fboundp tests))
                      (error "Test execution non caricati dal sistema ASDF."))
                    (dolist (test tests)
                      (format t "~&execution-test-start ~A~%" test) (finish-output)
                      (funcall test) (format t "ok    ~A~%" test))
                    (format t "~&execution-tests-complete ~D~%" (length tests)))))
        (write form :stream stream :pretty t) (terpri stream)))
    path))

(defun execute-tests (directory)
  "Conserva il log per ciascun esito, inclusi errori di compilazione o avvio."
  (write-runner directory)
  (let ((log (merge-pathnames "test.log" directory)))
    (multiple-value-bind (out err exit)
        (uiop:run-program '("sbcl" "--noinform" "--no-userinit" "--no-sysinit"
                            "--disable-debugger" "--script"
                            "tools/writer-handoff-isolated-build.lisp")
                          :directory directory :output log :error-output :output
                          :ignore-error-status t)
      (declare (ignore out err))
      (values (classify-result (read-text log) exit) exit log))))

(defun write-report (directory report)
  "Sostituisce il registro solo dopo avere scritto la nuova copia completa."
  (with-open-file (stream (merge-pathnames "report.next.lisp" directory)
                          :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
  (uiop:rename-file-overwriting-target (merge-pathnames "report.next.lisp" directory)
                                     (merge-pathnames "report.lisp" directory))
  report)

(defun verify-baseline (directory)
  "La baseline invariata deve completare tutta execution, con log conservato prima del gate."
  (let ((baseline (merge-pathnames "baseline/" directory)))
    (copy-test-system baseline)
    (multiple-value-bind (result exit log) (execute-tests baseline)
      (list :result result :exit-code exit :log (namestring log)))))

(defun execute-mutation (mutant ordinal directory)
  "Copia privata per mutante, senza modificare il checkout della campagna."
  (let ((copy (merge-pathnames (format nil "~D/" ordinal) directory)))
    (copy-test-system copy)
    (with-open-file (stream (merge-pathnames (second mutant) copy)
                            :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string (mutated-source mutant) stream))
    (multiple-value-bind (result exit log) (execute-tests copy)
      (list :name (first mutant) :source-file (second mutant)
            :result result :exit-code exit :log (namestring log)))))

(defun acquire-directory (path)
  "MKDIR esclusivo 0700; la directory preesistente è intangibile."
  (let ((directory (uiop:ensure-directory-pathname (merge-pathnames path (uiop:getcwd)))))
    (ensure-directories-exist
     (merge-pathnames "parent-placeholder" (uiop:pathname-parent-directory-pathname directory)))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun initial-report (directory mutants)
  "Plist preinizializzata prima della baseline, con sorgenti e ogni tentativo identificabili."
  (list :schema-version 1 :kind :writer-handoff-mutations :status :running :stage :validation
        :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :targets mutants :planned-mutants (length mutants)
        :baseline :pending :baseline-result nil :baseline-exit-code nil
        :baseline-log (namestring (merge-pathnames "baseline/test.log" directory))
        :mutants nil :current-ordinal nil :current-mutant nil :current-log nil :diagnostic nil
        :detected 0 :survived 0 :compilation-failures 0 :before-tests 0
        :limits '(:targeted-mutants-only :complete-execution-suite :strict-compilation
                  :test-events-at-line-start :partial-campaign-preserved :exclusive-directory
                  :no-pool-ready-list-device-durability-or-performance-qualification)))

(defun append-result (report result)
  "Registra esito e conteggi prima del prossimo mutante."
  (setf (getf report :mutants) (append (getf report :mutants) (list result)))
  (dolist (pair '((:detected :detected) (:survived :survived)
                  (:compilation-failures :compilation-failure) (:before-tests :before-tests)))
    (setf (getf report (first pair))
          (count (second pair) (getf report :mutants) :key (lambda (entry) (getf entry :result)))))
  report)

(defun finish-report (directory report)
  "Fotografa la stabilità anche al fallimento e salva i risultati raccolti."
  (let ((after (fingerprints)))
    (setf (getf report :source-fingerprints-after) after
          (getf report :source-consistency)
          (if (equal (getf report :source-fingerprints-before) after) :stable :changed))
    (when (and (eq :ok (getf report :status)) (eq :changed (getf report :source-consistency)))
      (setf (getf report :status) :source-changed
            (getf report :diagnostic) "COD-61: sorgenti cambiati durante la campagna handoff.")))
  (write-report directory report)
  (format t "~&Writer handoff: ~A, baseline ~A, rilevati ~D/~D; ~A~%"
          (getf report :status) (getf report :baseline) (getf report :detected)
          (getf report :planned-mutants) (merge-pathnames "report.lisp" directory))
  report)

(defun run-campaign (path &key (mutants (mutation-list)) (validator #'validate-mutations)
                             (baseline-runner #'verify-baseline) (mutant-runner #'execute-mutation))
  "Persiste prima e dopo ogni prova; setup, baseline e risultati parziali restano visibili."
  (let* ((directory (acquire-directory path)) (report (initial-report directory mutants)))
    (handler-case
        (progn
          (write-report directory report) (funcall validator mutants)
          (setf (getf report :stage) :baseline) (write-report directory report)
          (let* ((baseline (funcall baseline-runner directory))
                 (passed (and (eq :survived (getf baseline :result))
                              (eql 0 (getf baseline :exit-code)))))
            (setf (getf report :baseline) (if passed :passed :failed)
                  (getf report :baseline-result) (getf baseline :result)
                  (getf report :baseline-exit-code) (getf baseline :exit-code)
                  (getf report :baseline-log) (getf baseline :log))
            (write-report directory report)
            (unless passed (error "COD-61: baseline handoff fallita; ~A" baseline)))
          (loop for mutant in mutants for ordinal from 0
                do (setf (getf report :stage) :mutants (getf report :current-ordinal) ordinal
                         (getf report :current-mutant) (first mutant) (getf report :current-log)
                         (namestring (merge-pathnames (format nil "~D/test.log" ordinal) directory)))
                   (write-report directory report)
                   (append-result report (funcall mutant-runner mutant ordinal directory))
                   (write-report directory report))
          (setf (getf report :stage) :complete (getf report :current-ordinal) nil
                (getf report :current-mutant) nil (getf report :current-log) nil)
          (unless (= (length mutants) (getf report :detected))
            (error "COD-61: mutanti handoff rilevati ~D/~D." (getf report :detected) (length mutants)))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))))
    (finish-report directory report)))

(defun assert-self-test (expression description)
  "Il self-test segnala la regola dello strumento che non è stata rilevata."
  (unless expression (error "COD-60: writer-handoff-mutation.lisp, self-test ~A." description)))

(defun fresh-self-test-directory ()
  "Fixture esclusiva, al più mille collisioni, nessun percorso esterno da rimuovere."
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil "arcdocdb-handoff-mutation-~D-~D-~D/"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error "COD-60: directory fixture handoff non disponibile."))

(defun self-test-log (directory relative)
  "Evento sintetico esplicito; nessun processo figlio durante la fixture del reporter."
  (let ((path (merge-pathnames relative directory)))
    (ensure-directories-exist path)
    (with-open-file (stream path :direction :output :if-exists :error)
      (write-line "evento sintetico del self-test" stream))
    (namestring path)))

(defun self-test-reporter ()
  "Preserva una destinazione esistente e un risultato prima di un guasto tardivo."
  (let ((root (fresh-self-test-directory)))
    (unwind-protect
         (let* ((existing (acquire-directory (merge-pathnames "existing/" root)))
                (marker (self-test-log existing "unchanged.log")) (before (read-text marker))
                (campaign (merge-pathnames "partial/" root))
                (mutants '(("fixture-one" "source" nil) ("fixture-two" "source" nil))))
           (assert-self-test (handler-case (progn (acquire-directory existing) nil) (error () t))
                             :existing-directory-rejected)
           (assert-self-test (string= before (read-text marker)) :existing-directory-preserved)
           (let ((*standard-output* (make-broadcast-stream)))
             (run-campaign campaign :mutants mutants :validator (constantly nil)
               :baseline-runner (lambda (directory)
                                  (list :result :survived :exit-code 0
                                        :log (self-test-log directory "baseline/test.log")))
               :mutant-runner (lambda (mutant ordinal directory)
                                (when (= ordinal 1) (error "fixture: secondo avvio interrotto"))
                                (list :name (first mutant) :result :detected :exit-code 1
                                      :log (self-test-log directory "0/test.log")))))
           (let* ((*read-eval* nil)
                  (saved (with-open-file (stream (merge-pathnames "report.lisp" campaign))
                           (read stream))))
             (assert-self-test (and (= 1 (getf saved :schema-version))
                                    (eq :failed (getf saved :status))
                                    (eq :passed (getf saved :baseline))
                                    (= 1 (getf saved :current-ordinal))
                                    (string= "fixture-two" (getf saved :current-mutant))
                                    (search "secondo avvio" (getf saved :diagnostic))
                                    (= 1 (length (getf saved :mutants)))
                                    (= 1 (getf saved :detected))
                                    (probe-file (getf saved :baseline-log))
                                    (probe-file (getf (first (getf saved :mutants)) :log)))
                               :partial-report-preserved)))
      ;; C4: ROOT appartiene soltanto alla fixture dopo MKDIR esclusivo.
      (uiop:delete-directory-tree root :validate t))))

(defun self-test ()
  "Dimostra marker autentici, classificazioni, bersagli invalidi e report parziali."
  (let ((start "execution-test-start TEST") (complete "execution-tests-complete 1"))
    (assert-self-test (eq :detected (classify-result start 1)) :detected)
    (assert-self-test (eq :survived (classify-result (format nil "~A~%~A~%" start complete) 0))
                      :complete-suite)
    (dolist (text '("" "prefix execution-test-start TEST" "Backtrace: execution-test-start TEST"
                    "(FORMAT T \"execution-test-start ~A\")"))
      (assert-self-test (eq :before-tests (classify-result text 1)) :quoted-marker))
    (assert-self-test (eq :before-tests (classify-result start 0)) :incomplete-suite)
    (assert-self-test (eq :before-tests (classify-result start nil)) :missing-exit)
    (dolist (failure '("compilation aborted" "COMPILE-FILE-ERROR" "COMPILE-FILE-WARNED"
                       "STYLE-WARNING non ammesso (COD-01)"))
      (assert-self-test (eq :compilation-failure
                           (classify-result (format nil "~A~%~A" start failure) 1))
                        :compilation-never-detected)))
  (assert-self-test (string= "xBy" (mutate-once "xAy" "A" "B" "fixture")) :substitution)
  (dolist (case '(("AA" "A" "B") ("x" "A" "B") ("A" "A" "A") ("A" "" "B")))
    (assert-self-test (handler-case (progn (apply #'mutate-once (append case '("fixture"))) nil)
                        (error () t)) :invalid-mutation))
  (validate-mutations (mutation-list)) (self-test-reporter)
  (format t "~&Writer handoff: self-test superato, nessuna campagna eseguita.~%")
  t)

(defun main ()
  "CLI C4, mai campagna implicita, diagnostica e exit nonzero per regola violata."
  (handler-case
      (let ((args (uiop:command-line-arguments)))
        (cond ((equal args '("--self-test")) (self-test))
              ((and (= (length args) 2) (string= (first args) "--run"))
               (let ((report (run-campaign (second args))))
                 (unless (eq :ok (getf report :status))
                   (format *error-output* "~&writer-handoff-mutation.lisp: ~A~%"
                           (getf report :diagnostic))
                   (uiop:quit 1))))
              (t (error "COD-61: uso --self-test oppure --run directory-nuova/."))))
    (error (condition)
      (format *error-output* "~&writer-handoff-mutation.lisp: ~A~%" condition)
      (uiop:quit 1))))

(main)
