;;;; Mutazione mirata DECISION/radix: copie isolate e compilazione rigorosa.
;;;; Uso: sbcl --script tools/decisions-radix-mutation.lisp --self-test
;;;;      sbcl --script tools/decisions-radix-mutation.lisp --run directory-nuova/
;;;; REQ: REQ-AFF-003 REQ-AFF-005
(require :asdf)
(require :sb-posix)

(defparameter *radix-mutations*
  '(("radix-id-msd-first" "decisions-radix.lisp"
      (("(- +participant-id-bytes+ 1 pass)" "pass")))
    ("radix-txid-missing-high-byte" "decisions-radix.lisp"
      (("(dotimes (digit 8)" "(dotimes (digit 7)")))
    ("radix-entry-unstable-scatter" "decisions-radix.lisp"
      (("  (dotimes (i (length source))
    (let* ((entry (the decision-entry (aref source i)))"
        "  (loop for i downfrom (1- (length source)) to 0 do
    (let* ((entry (the decision-entry (aref source i)))")))
    ("radix-skip-two-buckets" "decisions-radix.lisp"
      (("(when (> occupied 1)" "(when (> occupied 2)")))
    ("radix-rotate-uniform-id-pass" "decisions-radix.lisp"
      (("        (when (radix-id-starts source count digit histogram)
          (radix-scatter-ids source target count digit histogram)
          (rotatef source target))))"
        "        (when (radix-id-starts source count digit histogram)
          (radix-scatter-ids source target count digit histogram))
        (rotatef source target)))")))
    ("radix-histogram-u16" "decisions-radix.lisp"
      (("(deftype radix-histogram () '(simple-array (unsigned-byte 64) (256)))"
        "(deftype radix-histogram () '(simple-array (unsigned-byte 16) (256)))")
       ("(target (make-array (length participants) :element-type '(unsigned-byte 8)))
        (histogram (make-array +decision-radix-buckets+
                               :element-type '(unsigned-byte 64) :initial-element 0))"
        "(target (make-array (length participants) :element-type '(unsigned-byte 8)))
        (histogram (make-array +decision-radix-buckets+
                               :element-type '(unsigned-byte 16) :initial-element 0))")
       ("(let ((source entries) (target (make-array (length entries) :element-type t))
        (histogram (make-array +decision-radix-buckets+
                               :element-type '(unsigned-byte 64) :initial-element 0))"
        "(let ((source entries) (target (make-array (length entries) :element-type t))
        (histogram (make-array +decision-radix-buckets+
                               :element-type '(unsigned-byte 16) :initial-element 0))")))
    ("radix-id-missing-first-byte" "decisions-radix.lisp"
      (("(dotimes (pass +participant-id-bytes+)"
        "(dotimes (pass (1- +participant-id-bytes+))")))))

(defun original-decision-mutations ()
  "Legge soltanto la lista dati originale, senza LOAD/EVAL né esecuzione del MAIN."
  (let ((*read-eval* nil))
    (with-open-file (stream "tools/foundation-mutation.lisp" :external-format :utf-8)
      (loop for form = (read stream nil :eof)
            until (or (eq form :eof) (equal form '(main)))
            when (and (consp form) (eq (first form) 'defparameter)
                      (eq (second form) '*decision-mutants*))
              do (unless (and (= (length form) 3) (equal (first (third form)) 'quote))
                   (error "COD-60: lista DECISION originale non dichiarativa."))
                 (return-from original-decision-mutations
                   (mapcar (lambda (mutant)
                             (destructuring-bind (name file before after) mutant
                               (list name file (list (list before after)))))
                           (second (third form)))))))
  (error "COD-60: lista DECISION originale assente prima del MAIN."))

(defun mutation-list ()
  "Sette mutanti originali e sette candidati radix, con modifiche esplicite."
  (append (original-decision-mutations) *radix-mutations*))

(defun read-text (path)
  "Legge il sorgente o log UTF-8 senza interpretarlo come istruzioni."
  (uiop:read-file-string path :external-format :utf-8))

(defun mutation-source (file)
  "Percorso dei soli sorgenti DECISION assegnati alla campagna."
  (merge-pathnames file "src/recovery/"))

(defun mutate-once (source before after name)
  "COD-60: un bersaglio unico, non vuoto e una sostituzione che cambia il testo."
  (let ((position (search before source)))
    (unless (and (plusp (length before)) position (not (string= before after))
                 (not (search before source :start2 (1+ position))))
      (error "COD-60: mutante ~A, bersaglio assente/ambiguo o identico: ~S" name before))
    (concatenate 'string (subseq source 0 position) after
                 (subseq source (+ position (length before))))))

(defun mutated-source (mutant)
  "Valida ogni modifica anche nel testo originale, poi applica in ordine."
  (destructuring-bind (name file edits) mutant
    (let* ((original (read-text (mutation-source file))) (result original))
      (unless edits (error "COD-60: mutante ~A senza modifiche." name))
      (dolist (edit edits)
        (destructuring-bind (before after) edit
          (mutate-once original before after name)
          (setf result (mutate-once result before after name))))
      result)))

(defun validate-mutations (mutants)
  "Ogni nome è unico e ogni bersaglio esiste una volta prima delle copie."
  (let ((names nil))
    (dolist (mutant mutants)
      (when (member (first mutant) names :test #'string=)
        (error "COD-60: nome mutante ripetuto: ~A" (first mutant)))
      (push (first mutant) names)
      (mutated-source mutant)))
  nil)

(defun event-at-line-start-p (text marker)
  "Accetta eventi reali a inizio riga, mai citazioni o frammenti del backtrace."
  (loop for line in (uiop:split-string text :separator '(#\Newline))
        thereis (and (<= (length marker) (length line))
                     (string= marker line :end2 (length marker)))))

(defun classify-result (text exit)
  "Compilazione e guasti prima dei test non rilevano il mutante."
  (cond ((or (search "compilation aborted" text :test #'char-equal)
             (search "COMPILE-FILE-ERROR" text :test #'char-equal)
             (search "COMPILE-FILE-WARNED" text :test #'char-equal)
             (search "non ammesso (COD-01)" text)) :compilation-failure)
        ((or (not (integerp exit))
             (not (event-at-line-start-p text "decision-test-start "))) :before-tests)
        ((not (zerop exit)) :detected)
        ((event-at-line-start-p text "decision-tests-complete ") :survived)
        (t :before-tests)))

(defun copy-test-system (directory)
  "Copia ASD e tutti i file Lisp ricorsivi, inclusi moduli aggiunti da altre chat."
  (let ((files (append '("arcdocdb.asd" "tools/build.lisp")
                       (mapcar #'enough-namestring (directory "src/**/*.lisp"))
                       (mapcar #'enough-namestring (directory "tests/**/*.lisp")))))
    (dolist (file (remove-duplicates files :test #'string=))
      (let ((target (merge-pathnames file directory)))
        (ensure-directories-exist target)
        (uiop:copy-file file target))))
  nil)

(defun write-runner (directory)
  "Cache privata, compilazione rigorosa e test selezionati da definizioni registrate."
  (let ((path (merge-pathnames "tools/decisions-radix-isolated-build.lisp" directory)))
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
                  (let* ((*package* (or (find-package "ARCDOCDB.RECOVERY.TESTS")
                                       (error "Harness recovery non caricato.")))
                         (*read-eval* nil) (deftest (find-symbol "DEFTEST" *package*))
                         (files '("tests/recovery/decisions.lisp"
                                  "tests/recovery/decisions-audit.lisp")) (tests nil))
                    (when (probe-file "tests/recovery/decisions-radix.lisp")
                      (unless (asdf:find-component (asdf:find-system "arcdocdb/tests")
                                                   '("recovery" "decisions-radix"))
                        (error "Test radix presente ma non registrato in ASDF."))
                      (setf files (append files '("tests/recovery/decisions-radix.lisp"))))
                    (dolist (file files)
                      (let ((selected 0))
                        (with-open-file (input file :external-format :utf-8)
                          (loop for form = (read input nil :eof) until (eq form :eof)
                                when (and (consp form) (eq (first form) deftest))
                                  do (push (second form) tests) (incf selected)))
                        (unless (plusp selected) (error "File senza test DECISION: ~A" file))))
                    (unless (and tests (every #'fboundp tests))
                      (error "Test DECISION non caricati dal sistema ASDF."))
                    (setf tests (nreverse tests))
                    (dolist (test tests)
                      (format t "~&decision-test-start ~A~%" test) (finish-output)
                      (funcall test) (format t "ok    ~A~%" test))
                    (format t "~&decision-tests-complete ~D~%" (length tests)))))
        (write form :stream stream :pretty t) (terpri stream)))
    path))

(defun execute-tests (directory)
  "Ogni esito conserva test.log, incluso errore di compilazione o di avvio."
  (write-runner directory)
  (let ((log (merge-pathnames "test.log" directory)))
    (multiple-value-bind (out err exit)
        (uiop:run-program '("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
                            "tools/decisions-radix-isolated-build.lisp")
                          :directory directory :output log :error-output :output
                          :ignore-error-status t)
      (declare (ignore out err))
      (values (classify-result (read-text log) exit) exit log))))

(defun write-report (directory report)
  "Aggiorna il registro senza stampare ogni risultato; conserva l'ultima copia completa."
  (with-open-file (stream (merge-pathnames "report.next.lisp" directory)
                          :direction :output :if-exists :supersede)
    (write report :stream stream :pretty t) (terpri stream))
  (uiop:rename-file-overwriting-target (merge-pathnames "report.next.lisp" directory)
                                     (merge-pathnames "report.lisp" directory))
  report)

(defun verify-baseline (directory)
  "Restituisce anche il log della baseline riuscita; il chiamante persiste prima del gate."
  (let ((baseline (merge-pathnames "baseline/" directory)))
    (copy-test-system baseline)
    (multiple-value-bind (result exit log) (execute-tests baseline)
      (list :result result :exit-code exit :log (namestring log)))))

(defun execute-mutation (mutant ordinal directory)
  "Una copia per mutante, mai modifiche al checkout chiamante."
  (let ((copy (merge-pathnames (format nil "~D/" ordinal) directory)))
    (copy-test-system copy)
    (with-open-file (stream (merge-pathnames (mutation-source (second mutant)) copy)
                            :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string (mutated-source mutant) stream))
    (multiple-value-bind (result exit log) (execute-tests copy)
      (list :name (first mutant) :result result :exit-code exit :log (namestring log)))))

(defun acquire-campaign-directory (path)
  "Acquisisce con MKDIR esclusivo 0700; una directory esistente non è mai sovrascritta."
  (let ((directory (uiop:ensure-directory-pathname (merge-pathnames path (uiop:getcwd)))))
    (ensure-directories-exist
     (merge-pathnames "parent-placeholder" (uiop:pathname-parent-directory-pathname directory)))
    (handler-case (sb-posix:mkdir (namestring directory) #o700)
      (sb-posix:syscall-error (condition)
        (error "COD-61: directory nuova non acquisita: ~A; ~A" directory condition)))
    directory))

(defun initial-report (directory mutant-count)
  "Schema dichiarativo anche prima della baseline e durante una campagna interrotta."
  (list :schema-version 1 :kind :targeted-mutation :scope :decisions-radix
        :status :running :stage :validation :baseline :pending
        :baseline-result nil :baseline-exit-code nil
        :baseline-log (namestring (merge-pathnames "baseline/test.log" directory))
        :planned-mutants mutant-count :mutants nil :current-ordinal nil :current-mutant nil
        :current-log nil :diagnostic nil :detected 0 :survived 0
        :compilation-failures 0 :before-tests 0
        :limits '(:selected-mutants-only :strict-compilation :test-events-at-line-start
                  :partial-campaign-preserved :exclusive-directory :no-performance-claim)))

(defun append-mutation-result (report result)
  "Aggiunge un esito in ordine fisico e aggiorna i conteggi prima della prossima copia."
  (setf (getf report :mutants) (append (getf report :mutants) (list result)))
  (dolist (pair '((:detected :detected) (:survived :survived)
                  (:compilation-failures :compilation-failure) (:before-tests :before-tests)))
    (setf (getf report (first pair))
          (count (second pair) (getf report :mutants) :key (lambda (entry) (getf entry :result)))))
  report)

(defun print-summary (directory report)
  "Un solo riepilogo finale; dettagli e diagnostica restano nel registro della campagna."
  (format t "~&DECISION/radix: ~A, baseline ~A, mutanti rilevati ~D/~D; ~A~%"
          (getf report :status) (getf report :baseline) (getf report :detected)
          (getf report :planned-mutants) (merge-pathnames "report.lisp" directory)))

(defun record-campaign-failure (directory report condition)
  "Preserva ordinalità, log atteso ed esiti precedenti anche per un guasto di copia/avvio."
  (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
  (handler-case (write-report directory report)
    (error (write-condition)
      (format *error-output* "~&COD-61: aggiornamento registro ~A fallito: ~A~%"
              directory write-condition)))
  (print-summary directory report))

(defun run-campaign (path)
  "Registra ogni passaggio; baseline completa e solo mutanti eseguiti possono superare il gate."
  (let* ((mutants (mutation-list)) (directory (acquire-campaign-directory path))
         (report (initial-report directory (length mutants))))
    (handler-case
        (progn
          (write-report directory report)
          (validate-mutations mutants)
          (setf (getf report :stage) :baseline)
          (write-report directory report)
          (let* ((baseline (verify-baseline directory))
                 (passed (and (eq (getf baseline :result) :survived)
                              (eql (getf baseline :exit-code) 0))))
            (setf (getf report :baseline) (if passed :passed :failed)
                  (getf report :baseline-result) (getf baseline :result)
                  (getf report :baseline-exit-code) (getf baseline :exit-code)
                  (getf report :baseline-log) (getf baseline :log))
            (write-report directory report)
            (unless passed (error "COD-61: baseline DECISION/radix fallita; ~A" baseline)))
          (loop for mutant in mutants for ordinal from 0
                do (setf (getf report :stage) :mutants (getf report :current-ordinal) ordinal
                         (getf report :current-mutant) (first mutant)
                         (getf report :current-log)
                         (namestring (merge-pathnames (format nil "~D/test.log" ordinal) directory)))
                   (write-report directory report)
                   (append-mutation-result report (execute-mutation mutant ordinal directory))
                   (write-report directory report))
          (setf (getf report :stage) :complete (getf report :current-ordinal) nil
                (getf report :current-mutant) nil (getf report :current-log) nil)
          (unless (= (length mutants) (getf report :detected))
            (error "COD-61: mutanti DECISION/radix rilevati ~D/~D; ~A"
                   (getf report :detected) (length mutants) directory))
          (setf (getf report :status) :passed)
          (write-report directory report)
          (print-summary directory report))
      (error (condition)
        (record-campaign-failure directory report condition)
        (error condition)))))

(defun assert-self-test (expression description)
  "Un errore del self-test identifica la regola dello strumento."
  (unless expression (error "COD-60: self-test fallito: ~A" description)))

(defun fresh-self-test-directory ()
  "Directory esclusiva della sola fixture; collisioni limitate a mille tentativi."
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil "arcdocdb-radix-tool-~D-~D-~D/"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition))
                 (error condition)))))
  (error "COD-60: directory esclusiva del self-test non disponibile."))

(defun self-test-log (directory relative-path)
  "Piccolo log dichiarato dalla fixture, senza compilazione o processi figli."
  (let ((path (merge-pathnames relative-path directory)))
    (ensure-directories-exist path)
    (with-open-file (stream path :direction :output :if-exists :error)
      (write-line "evento sintetico del self-test" stream))
    (namestring path)))

(defun self-test-campaign-registration ()
  "Rifiuta directory esistenti e conserva un primo esito prima di un guasto tardivo."
  (let ((root (fresh-self-test-directory))
        (old-baseline (symbol-function 'verify-baseline))
        (old-mutation (symbol-function 'execute-mutation)))
    (unwind-protect
         (let* ((existing (acquire-campaign-directory (merge-pathnames "existing/" root)))
                (marker (self-test-log existing "unchanged.log"))
                (before (read-text marker)) (campaign (merge-pathnames "partial/" root)))
           (assert-self-test
            (handler-case (progn (acquire-campaign-directory existing) nil) (error () t))
            :existing-directory-rejected)
           (assert-self-test (string= before (read-text marker)) :existing-directory-preserved)
           (setf (symbol-function 'verify-baseline)
                 (lambda (directory)
                   (list :result :survived :exit-code 0
                         :log (self-test-log directory "baseline/test.log")))
                 (symbol-function 'execute-mutation)
                 (lambda (mutant ordinal directory)
                   (when (= ordinal 1) (error "fixture: secondo avvio interrotto"))
                   (list :name (first mutant) :result :detected :exit-code 1
                         :log (self-test-log directory (format nil "~D/test.log" ordinal)))))
           (let ((*standard-output* (make-broadcast-stream)))
             (assert-self-test (handler-case (progn (run-campaign campaign) nil) (error () t))
                               :late-failure-reported))
           (let* ((*read-eval* nil)
                  (report (with-open-file (stream (merge-pathnames "report.lisp" campaign))
                            (read stream))))
             (assert-self-test (= 1 (getf report :schema-version)) :report-schema)
             (assert-self-test (eq :failed (getf report :status)) :partial-status)
             (assert-self-test (eq :passed (getf report :baseline)) :successful-baseline)
             (assert-self-test (probe-file (getf report :baseline-log)) :baseline-log-preserved)
             (assert-self-test (= 1 (getf report :current-ordinal)) :interrupted-ordinal)
             (assert-self-test (string= (first (second (mutation-list)))
                                       (getf report :current-mutant)) :interrupted-mutant)
             (assert-self-test (search "secondo avvio" (getf report :diagnostic)) :diagnostic)
             (assert-self-test (= 1 (length (getf report :mutants))) :previous-result-preserved)
             (assert-self-test (= 1 (getf report :detected)) :partial-count)
             (assert-self-test (probe-file (getf (first (getf report :mutants)) :log))
                               :previous-log-preserved)))
      (setf (symbol-function 'verify-baseline) old-baseline
            (symbol-function 'execute-mutation) old-mutation)
      ;; C4: ROOT è posseduta dalla fixture dopo MKDIR esclusivo, nessun percorso esterno.
      (uiop:delete-directory-tree root :validate t))))

(defun self-test ()
  "Il classificatore distingue rilevamento, compilazione, citazioni e suite incompleta."
  (let ((start "decision-test-start TEST") (complete "decision-tests-complete 1"))
    (assert-self-test (eq :detected (classify-result start 1)) :detected)
    (assert-self-test (eq :survived (classify-result (format nil "~A~%~A~%" start complete) 0))
                      :complete-suite)
    (dolist (text (list "" "prefix decision-test-start TEST"
                        "(FORMAT T \"decision-test-start ~A\")"
                        "Backtrace: decision-test-start TEST"))
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
    (assert-self-test
     (handler-case (progn (apply #'mutate-once (append case '("fixture"))) nil)
       (error () t)) :invalid-mutation))
  (validate-mutations (mutation-list))
  (self-test-campaign-registration)
  (format t "~&DECISION/radix: self-test superato, nessuna campagna eseguita.~%")
  t)

(defun main ()
  "CLI C4: errore visibile e codice non nullo; nessuna esecuzione implicita della campagna."
  (handler-case
      (let ((args (uiop:command-line-arguments)))
        (cond ((equal args '("--self-test")) (self-test))
              ((and (= (length args) 2) (string= (first args) "--run"))
               (run-campaign (second args)))
              (t (error "COD-61: uso --self-test oppure --run directory-nuova/."))))
    (error (condition)
      (format *error-output* "~&decisions-radix-mutation.lisp: ~A~%" condition)
      (uiop:quit 1))))

(main)
