(:SCHEMA-VERSION 1 :KIND :VERIFICATION-ADAPTER-SOURCES :VERSION :INTEGRATED
 :SOURCES
 ((:PATH "spikes/out/writer-ready-mutation-before-signal-fix.lisp" :BYTES 22302
   :SHA256 "e22f1e32f1c4dd98ebe84af818145c22fb8b4c386f3bf04bc235edc7a7257829"
   :GIT-BLOB "5477f5a83b87e22d8cd7fd040f5d6aa8ab978986" :TEXT
   ";;;; Mutazioni semantiche della lista writer pronti in copie isolate.
;;;; Uso: --self-test oppure --run directory-nuova/; writer-ready-metodo.md.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-005 REQ-AFF-008
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-ready.mutation (:use #:cl))
(in-package #:arcdocdb.writer-ready.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *ready-mutants*
  '((\"ready-fifo-head-from-tail\" \"src/execution/ready.lisp\"
     ((\"(head (partizione-pronta-head partition))\"
       \"(head (partizione-pronta-tail partition))\")))
    (\"ready-tail-wrap-two\" \"src/execution/ready.lisp\"
     ((\"(mod (1+ tail) (partizione-pronta-capacity partition))\"
       \"(mod (+ tail 2) (partizione-pronta-capacity partition))\")))
    (\"ready-head-wrap-two\" \"src/execution/ready.lisp\"
     ((\"(mod (1+ head) (partizione-pronta-capacity partition))\"
       \"(mod (+ head 2) (partizione-pronta-capacity partition))\")))
    (\"ready-full-boundary\" \"src/execution/ready.lisp\"
     ((\"(= (partizione-pronta-count partition) (partizione-pronta-capacity partition))\"
       \"(> (partizione-pronta-count partition) (partizione-pronta-capacity partition))\")))
    (\"ready-pop-count-unchanged\" \"src/execution/ready.lisp\"
     ((\"(1- (partizione-pronta-count partition))\" \"(partizione-pronta-count partition)\")))
    (\"ready-pop-keeps-reference\" \"src/execution/ready.lisp\"
     ((\"(setf (svref (partizione-pronta-slots partition) head) nil\"
       \"(setf (svref (partizione-pronta-slots partition) head) writer\")))
    (\"ready-release-keeps-guard\" \"src/execution/ready.lisp\"
     ((\"(sb-ext:compare-and-swap (partizione-pronta-guard partition) thread nil)\"
       \"(sb-ext:compare-and-swap (partizione-pronta-guard partition) thread thread)\")))
    (\"ready-scan-forgets-busy\" \"src/execution/ready.lisp\"
     ((\"(:busy (setf busy t))\" \"(:busy (setf busy nil))\")))
    (\"ready-scan-stops-on-busy\" \"src/execution/ready.lisp\"
     ((\"(:busy (setf busy t))\"
       \"(:busy (return-from preleva-writer-pronto
                   (values nil :busy (mod (1+ (the index start)) size))))\")))
    (\"ready-scan-misses-last-shard\" \"src/execution/ready.lisp\"
     ((\"(dotimes (i size)\" \"(dotimes (i (1- size))\")))
    (\"ready-success-cursor-stays\" \"src/execution/ready.lisp\"
     ((\"(values writer :writer (mod (1+ cursor) size))\" \"(values writer :writer cursor)\")))
    (\"ready-unsuccessful-cursor-stays\" \"src/execution/ready.lisp\"
     ((\"(values nil (if busy :busy :empty) (mod (1+ (the index start)) size))\"
       \"(values nil (if busy :busy :empty) (the index start))\")))))

(defun mutation-list ()
  \"Dodici mutanti semantici ready fissati prima della campagna.\"
  *ready-mutants*)

(defun source-files ()
  \"ASD, build, sorgenti e test richiesti dalle copie; nessuna evidenza o Git copiati.\"
  (append '(#p\"arcdocdb.asd\" #p\"tools/build.lisp\")
          (sort (append (directory \"src/**/*.lisp\") (directory \"tests/**/*.lisp\"))
                #'string< :key #'namestring)))

(defun fingerprints ()
  \"MD5 dei file copiati e del driver: controllo di stabilità, non di autenticità.\"
  (loop for file in (append (source-files) '(#p\"tools/writer-ready-mutation.lisp\"))
        collect (list :file (enough-namestring file)
                      :md5 (format nil \"~(~{~2,'0X~}~)\"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun read-text (path)
  \"Legge sorgente e log UTF-8 come dati, senza interpretazione.\"
  (uiop:read-file-string path :external-format :utf-8))

(defun mutate-once (source before after name)
  \"COD-60: bersaglio unico e non vuoto, modifica effettiva, nessuna riscrittura originale.\"
  (let ((position (search before source)))
    (unless (and (plusp (length before)) position (not (string= before after))
                 (not (search before source :start2 (1+ position))))
      (error \"COD-60: mutante ~A, bersaglio assente/ambiguo o identico: ~S\" name before))
    (concatenate 'string (subseq source 0 position) after
                 (subseq source (+ position (length before))))))

(defun mutated-source (mutant)
  \"Valida ogni modifica nell'originale e nel risultato delle modifiche precedenti.\"
  (destructuring-bind (name path edits) mutant
    (let* ((original (read-text path)) (result original))
      (unless edits (error \"COD-60: mutante ~A senza modifiche.\" name))
      (dolist (edit edits)
        (destructuring-bind (before after) edit
          (mutate-once original before after name)
          (setf result (mutate-once result before after name))))
      result)))

(defun validate-mutations (mutants)
  \"Dodici nomi unici; ogni bersaglio appare una sola volta nei sorgenti congelati.\"
  (unless (= 12 (length mutants)) (error \"COD-60: numero mutanti ready diverso da dodici.\"))
  (let ((names nil))
    (dolist (mutant mutants)
      (when (member (first mutant) names :test #'string=)
        (error \"COD-60: nome mutante ripetuto: ~A\" (first mutant)))
      (push (first mutant) names)
      (mutated-source mutant)))
  nil)

(defun event-at-line-start-p (text marker)
  \"Solo eventi a inizio riga; citazioni e frammenti di backtrace non contano.\"
  (loop for line in (uiop:split-string text :separator '(#\\Newline))
        thereis (and (<= (length marker) (length line))
                     (string= marker line :end2 (length marker)))))

(defun classify-result (text exit)
  \"Compilazione fallita e guasti prima dei test non sono mutanti rilevati.\"
  (cond ((or (search \"compilation aborted\" text :test #'char-equal)
             (search \"COMPILE-FILE-ERROR\" text :test #'char-equal)
             (search \"COMPILE-FILE-WARNED\" text :test #'char-equal)
             (search \"non ammesso (COD-01)\" text)) :compilation-failure)
        ((or (not (integerp exit))
             (not (event-at-line-start-p text \"execution-test-start \"))) :before-tests)
        ((not (zerop exit)) :detected)
        ((event-at-line-start-p text \"execution-tests-complete \") :survived)
        (t :before-tests)))

(defun copy-test-system (directory)
  \"Copia tutti i sorgenti e test ASDF; gli output delle copie restano privati.\"
  (dolist (file (source-files))
    (let ((target (merge-pathnames (enough-namestring file) directory)))
      (ensure-directories-exist target)
      (uiop:copy-file file target)))
  nil)

(defun write-runner (directory)
  \"Compilazione rigorosa e intera suite execution registrata, inclusi i test ready.\"
  (let ((path (merge-pathnames \"tools/writer-ready-isolated-build.lisp\" directory)))
    (with-open-file (stream path :direction :output :if-exists :error)
      (dolist (form
                '((require :asdf)
                  (setf asdf:*user-cache* (merge-pathnames \"fasl/\" (truename \"./\"))
                        asdf:*compile-file-failure-behaviour* :error
                        asdf:*compile-file-warnings-behaviour* :error)
                  (handler-bind
                      ((warning (lambda (condition)
                                  (unless (typep condition 'sb-kernel:redefinition-warning)
                                    (error \"~A non ammesso (COD-01): ~A\"
                                           (type-of condition) condition)))))
                    (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" (truename \"./\")))
                    (asdf:load-system \"arcdocdb\" :force t)
                    (asdf:load-system \"arcdocdb/tests\" :force t))
                  (unless (and (probe-file \"tests/execution/ready.lisp\")
                               (asdf:find-component (asdf:find-system \"arcdocdb/tests\")
                                                    '(\"execution\" \"ready\")))
                    (error \"Test ready assente o non registrato in ASDF.\"))
                  (let* ((package (or (find-package \"ARCDOCDB.EXECUTION.TESTS\")
                                      (error \"Harness execution non caricato.\")))
                         (registry (or (find-symbol \"*TESTS*\" package)
                                       (error \"Registro execution assente.\")))
                         (tests (reverse (symbol-value registry))))
                    (unless (and tests (every #'fboundp tests))
                      (error \"Test execution non caricati dal sistema ASDF.\"))
                    (dolist (test tests)
                      (format t \"~&execution-test-start ~A~%\" test) (finish-output)
                      (funcall test) (format t \"ok    ~A~%\" test))
                    (format t \"~&execution-tests-complete ~D~%\" (length tests)))))
        (write form :stream stream :pretty t) (terpri stream)))
    path))

(defun execute-tests (directory)
  \"Conserva il log per ciascun esito, inclusi errori di compilazione o avvio.\"
  (write-runner directory)
  (let ((log (merge-pathnames \"test.log\" directory)))
    (multiple-value-bind (out err exit)
        (uiop:run-program '(\"sbcl\" \"--noinform\" \"--no-userinit\" \"--no-sysinit\"
                            \"--disable-debugger\" \"--script\"
                            \"tools/writer-ready-isolated-build.lisp\")
                          :directory directory :output log :error-output :output
                          :ignore-error-status t)
      (declare (ignore out err))
      (values (classify-result (read-text log) exit) exit log))))

(defun write-report (directory report)
  \"Sostituisce il registro solo dopo avere scritto la nuova copia completa.\"
  (with-open-file (stream (merge-pathnames \"report.next.lisp\" directory)
                          :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))
  (uiop:rename-file-overwriting-target (merge-pathnames \"report.next.lisp\" directory)
                                     (merge-pathnames \"report.lisp\" directory))
  report)

(defun verify-baseline (directory)
  \"La baseline invariata deve completare tutta execution, con log conservato prima del gate.\"
  (let ((baseline (merge-pathnames \"baseline/\" directory)))
    (copy-test-system baseline)
    (multiple-value-bind (result exit log) (execute-tests baseline)
      (list :result result :exit-code exit :log (namestring log)))))

(defun execute-mutation (mutant ordinal directory)
  \"Copia privata per mutante, senza modificare il checkout della campagna.\"
  (let ((copy (merge-pathnames (format nil \"~D/\" ordinal) directory)))
    (copy-test-system copy)
    (with-open-file (stream (merge-pathnames (second mutant) copy)
                            :direction :output :if-exists :supersede :external-format :utf-8)
      (write-string (mutated-source mutant) stream))
    (multiple-value-bind (result exit log) (execute-tests copy)
      (list :name (first mutant) :source-file (second mutant)
            :result result :exit-code exit :log (namestring log)))))

(defun acquire-directory (path)
  \"MKDIR esclusivo 0700; la directory preesistente è intangibile.\"
  (let ((directory (uiop:ensure-directory-pathname (merge-pathnames path (uiop:getcwd)))))
    (ensure-directories-exist
     (merge-pathnames \"parent-placeholder\" (uiop:pathname-parent-directory-pathname directory)))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun initial-report (directory mutants)
  \"Plist preinizializzata prima della baseline, con sorgenti e ogni tentativo identificabili.\"
  (list :schema-version 1 :kind :writer-ready-mutations :status :running :stage :validation
        :process-argv sb-ext:*posix-argv* :tool-arguments (uiop:command-line-arguments)
        :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
        :source-fingerprints-before (fingerprints) :source-fingerprints-after nil
        :source-consistency :pending :targets mutants :planned-mutants (length mutants)
        :baseline :pending :baseline-result nil :baseline-exit-code nil
        :baseline-log (namestring (merge-pathnames \"baseline/test.log\" directory))
        :mutants nil :current-ordinal nil :current-mutant nil :current-log nil :diagnostic nil
        :detected 0 :survived 0 :compilation-failures 0 :before-tests 0
        :limits '(:targeted-mutants-only :complete-execution-suite :strict-compilation
                  :test-events-at-line-start :partial-campaign-preserved :exclusive-directory
                  :no-pool-device-durability-or-performance-qualification)))

(defun append-result (report result)
  \"Registra esito e conteggi prima del prossimo mutante.\"
  (setf (getf report :mutants) (append (getf report :mutants) (list result)))
  (dolist (pair '((:detected :detected) (:survived :survived)
                  (:compilation-failures :compilation-failure) (:before-tests :before-tests)))
    (setf (getf report (first pair))
          (count (second pair) (getf report :mutants) :key (lambda (entry) (getf entry :result)))))
  report)

(defun finish-report (directory report)
  \"Fotografa la stabilità anche al fallimento e salva i risultati raccolti.\"
  (let ((after (fingerprints)))
    (setf (getf report :source-fingerprints-after) after
          (getf report :source-consistency)
          (if (equal (getf report :source-fingerprints-before) after) :stable :changed))
    (when (and (eq :ok (getf report :status)) (eq :changed (getf report :source-consistency)))
      (setf (getf report :status) :source-changed
            (getf report :diagnostic) \"COD-61: sorgenti cambiati durante la campagna ready.\")))
  (write-report directory report)
  (format t \"~&Writer ready: ~A, baseline ~A, rilevati ~D/~D; ~A~%\"
          (getf report :status) (getf report :baseline) (getf report :detected)
          (getf report :planned-mutants) (merge-pathnames \"report.lisp\" directory))
  report)

(defun run-campaign (path &key (mutants (mutation-list)) (validator #'validate-mutations)
                             (baseline-runner #'verify-baseline) (mutant-runner #'execute-mutation))
  \"Persiste prima e dopo ogni prova; setup, baseline e risultati parziali restano visibili.\"
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
            (unless passed (error \"COD-61: baseline ready fallita; ~A\" baseline)))
          (loop for mutant in mutants for ordinal from 0
                do (setf (getf report :stage) :mutants (getf report :current-ordinal) ordinal
                         (getf report :current-mutant) (first mutant) (getf report :current-log)
                         (namestring (merge-pathnames (format nil \"~D/test.log\" ordinal) directory)))
                   (write-report directory report)
                   (append-result report (funcall mutant-runner mutant ordinal directory))
                   (write-report directory report))
          (setf (getf report :stage) :complete (getf report :current-ordinal) nil
                (getf report :current-mutant) nil (getf report :current-log) nil)
          (unless (= (length mutants) (getf report :detected))
            (error \"COD-61: mutanti ready rilevati ~D/~D.\" (getf report :detected) (length mutants)))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))))
    (finish-report directory report)))

(defun assert-self-test (expression description)
  \"Il self-test segnala la regola dello strumento che non è stata rilevata.\"
  (unless expression (error \"COD-60: writer-ready-mutation.lisp, self-test ~A.\" description)))

(defun fresh-self-test-directory ()
  \"Fixture esclusiva, al più mille collisioni, nessun percorso esterno da rimuovere.\"
  (loop for attempt below 1000
        for directory = (merge-pathnames
                         (format nil \"arcdocdb-ready-mutation-~D-~D-~D/\"
                                 (get-universal-time) (sb-posix:getpid) attempt)
                         (uiop:temporary-directory))
        do (handler-case (progn (sb-posix:mkdir (namestring directory) #o700)
                                (return-from fresh-self-test-directory directory))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error \"COD-60: directory fixture ready non disponibile.\"))

(defun self-test-log (directory relative)
  \"Evento sintetico esplicito; nessun processo figlio durante la fixture del reporter.\"
  (let ((path (merge-pathnames relative directory)))
    (ensure-directories-exist path)
    (with-open-file (stream path :direction :output :if-exists :error)
      (write-line \"evento sintetico del self-test\" stream))
    (namestring path)))

(defun self-test-reporter ()
  \"Preserva una destinazione esistente e un risultato prima di un guasto tardivo.\"
  (let ((root (fresh-self-test-directory)))
    (unwind-protect
         (let* ((existing (acquire-directory (merge-pathnames \"existing/\" root)))
                (marker (self-test-log existing \"unchanged.log\")) (before (read-text marker))
                (campaign (merge-pathnames \"partial/\" root))
                (mutants '((\"fixture-one\" \"source\" nil) (\"fixture-two\" \"source\" nil))))
           (assert-self-test (handler-case (progn (acquire-directory existing) nil) (error () t))
                             :existing-directory-rejected)
           (assert-self-test (string= before (read-text marker)) :existing-directory-preserved)
           (let ((*standard-output* (make-broadcast-stream)))
             (run-campaign campaign :mutants mutants :validator (constantly nil)
               :baseline-runner (lambda (directory)
                                  (list :result :survived :exit-code 0
                                        :log (self-test-log directory \"baseline/test.log\")))
               :mutant-runner (lambda (mutant ordinal directory)
                                (when (= ordinal 1) (error \"fixture: secondo avvio interrotto\"))
                                (list :name (first mutant) :result :detected :exit-code 1
                                      :log (self-test-log directory \"0/test.log\")))))
           (let* ((*read-eval* nil)
                  (saved (with-open-file (stream (merge-pathnames \"report.lisp\" campaign))
                           (read stream))))
             (assert-self-test (and (= 1 (getf saved :schema-version))
                                    (eq :failed (getf saved :status))
                                    (eq :passed (getf saved :baseline))
                                    (= 1 (getf saved :current-ordinal))
                                    (string= \"fixture-two\" (getf saved :current-mutant))
                                    (search \"secondo avvio\" (getf saved :diagnostic))
                                    (= 1 (length (getf saved :mutants)))
                                    (= 1 (getf saved :detected))
                                    (probe-file (getf saved :baseline-log))
                                    (probe-file (getf (first (getf saved :mutants)) :log)))
                               :partial-report-preserved)))
      ;; C4: ROOT appartiene soltanto alla fixture dopo MKDIR esclusivo.
      (uiop:delete-directory-tree root :validate t))))

(defun self-test ()
  \"Dimostra marker autentici, classificazioni, bersagli invalidi e report parziali.\"
  (let ((start \"execution-test-start TEST\") (complete \"execution-tests-complete 1\"))
    (assert-self-test (eq :detected (classify-result start 1)) :detected)
    (assert-self-test (eq :survived (classify-result (format nil \"~A~%~A~%\" start complete) 0))
                      :complete-suite)
    (dolist (text '(\"\" \"prefix execution-test-start TEST\" \"Backtrace: execution-test-start TEST\"
                    \"(FORMAT T \\\"execution-test-start ~A\\\")\"))
      (assert-self-test (eq :before-tests (classify-result text 1)) :quoted-marker))
    (assert-self-test (eq :before-tests (classify-result start 0)) :incomplete-suite)
    (assert-self-test (eq :before-tests (classify-result start nil)) :missing-exit)
    (dolist (failure '(\"compilation aborted\" \"COMPILE-FILE-ERROR\" \"COMPILE-FILE-WARNED\"
                       \"STYLE-WARNING non ammesso (COD-01)\"))
      (assert-self-test (eq :compilation-failure
                           (classify-result (format nil \"~A~%~A\" start failure) 1))
                        :compilation-never-detected)))
  (assert-self-test (string= \"xBy\" (mutate-once \"xAy\" \"A\" \"B\" \"fixture\")) :substitution)
  (dolist (case '((\"AA\" \"A\" \"B\") (\"x\" \"A\" \"B\") (\"A\" \"A\" \"A\") (\"A\" \"\" \"B\")))
    (assert-self-test (handler-case (progn (apply #'mutate-once (append case '(\"fixture\"))) nil)
                        (error () t)) :invalid-mutation))
  (validate-mutations (mutation-list)) (self-test-reporter)
  (format t \"~&Writer ready: self-test superato, nessuna campagna eseguita.~%\")
  t)

(defun main ()
  \"CLI C4, mai campagna implicita, diagnostica e exit nonzero per regola violata.\"
  (handler-case
      (let ((args (uiop:command-line-arguments)))
        (cond ((equal args '(\"--self-test\")) (self-test))
              ((and (= (length args) 2) (string= (first args) \"--run\"))
               (let ((report (run-campaign (second args))))
                 (unless (eq :ok (getf report :status))
                   (format *error-output* \"~&writer-ready-mutation.lisp: ~A~%\"
                           (getf report :diagnostic))
                   (uiop:quit 1))))
              (t (error \"COD-61: uso --self-test oppure --run directory-nuova/.\"))))
    (error (condition)
      (format *error-output* \"~&writer-ready-mutation.lisp: ~A~%\" condition)
      (uiop:quit 1))))

(main)
")
  (:PATH "spikes/out/writer-ready-mutation-final-self-test.lisp" :BYTES 1946
   :SHA256 "1e56ffe30651accc4cf9980c9516c680c37a2f21f01a5b902c37fde89f1aea41"
   :GIT-BLOB "2dfd3ef2a7df94fa4be074ff2ea455d4bde82d29" :TEXT
   ";;;; Adapter C4: compila interamente un tool e carica il FASL con --self-test.
;;;; Contrib pre-caricati prima della compilazione rigorosa; argv espliciti per MAIN.
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(let* ((arguments (uiop:command-line-arguments))
       (tool (first arguments))
       (fasl (and tool (merge-pathnames (concatenate 'string (pathname-name tool) \".fasl\")
                                        \"spikes/out/ready-tool-final-fasl/\"))))
  (unless (and (= 1 (length arguments))
               (member tool '(\"tools/writer-ready-mutation.lisp\")
                       :test #'string=))
    (error \"COD-61: adapter richiede il path di uno dei due nuovi tool ready.\"))
  (ensure-directories-exist fasl)
  (setf asdf:*compile-file-failure-behaviour* :error
        asdf:*compile-file-warnings-behaviour* :error
        asdf:*user-cache* (merge-pathnames \"spikes/out/ready-tool-final-product-fasl/\" (truename \"./\")))
  (asdf:initialize-output-translations
   `(:output-translations
     (,(namestring (truename \"./\"))
      ,(namestring (merge-pathnames
                    (concatenate 'string \"spikes/out/ready-tool-final-product-fasl/\" (pathname-name tool) \"/\")
                    (truename \"./\"))))
     :ignore-inherited-configuration))
  (handler-bind
      ((warning (lambda (condition)
                  (unless (typep condition 'sb-kernel:redefinition-warning)
                    (error \"~A non ammesso (COD-01): ~A\" (type-of condition) condition)))))
    (multiple-value-bind (output warnings failure) (compile-file tool :output-file fasl)
      (unless (and output (not warnings) (not failure))
        (error \"COD-01: compile-file completo non riuscito per ~A.\" tool))
      (setf uiop/image:*command-line-arguments* '(\"--self-test\")
            sb-ext:*posix-argv* '(\"sbcl\" \"--self-test\"))
      (load output)))
  (format t \"~&Tool ready ~A: COMPILE-FILE completo e --self-test FASL superati.~%\" tool))
")
  (:PATH "spikes/out/ready-mutation-final-summary.lisp" :BYTES 1317 :SHA256
   "0e43a3ddfb0da387b994d0abd63db64d77fa9454809f91467204989fcb2b064d" :GIT-BLOB
   "1f1882278571a4206c1a62e3506fd4a10212be7c" :TEXT
   ";;;; Lettura dei dati finali: dodici esiti e tredici log, nessun processo test avviato.
(require :asdf)
(let ((*read-eval* nil))
  (with-open-file (stream \"spikes/out/ready-mutations-final/report.lisp\")
    (let* ((report (read stream)) (entries (getf report :mutants))
           (logs (cons (getf report :baseline-log) (mapcar (lambda (entry) (getf entry :log)) entries))))
      (assert (eq :ok (getf report :status)))
      (assert (eq :stable (getf report :source-consistency)))
      (assert (eq :passed (getf report :baseline)))
      (assert (eql 0 (getf report :baseline-exit-code)))
      (assert (null (getf report :baseline-signal :missing)))
      (assert (= 12 (length entries)))
      (assert (= 13 (length logs)))
      (dolist (entry entries)
        (assert (eq :detected (getf entry :result)))
        (assert (eql 1 (getf entry :exit-code)))
        (assert (null (getf entry :signal :missing))))
      (dolist (log logs)
        (assert (probe-file log))
        (assert (plusp (length (uiop:read-file-string log :external-format :utf-8)))))
      (dolist (key '(:survived :compilation-failures :before-tests :worker-errors))
        (assert (eql 0 (getf report key))))
      (format t \"~&Finale: baseline exit0/signal NIL,12 detected exit1/signal NIL,13 log integri; nessun worker-error.~%\"))))
")
  (:PATH "spikes/out/ready-publication-functions-first-version.lisp" :BYTES
   1645 :SHA256
   "2fe9eb6d7b3d5958cefec9cd3d7a83e7b2f2deccc18bba636e4686f79b39f5e7" :GIT-BLOB
   "0f61d908a08217eff6de167bbd3af6f68ed18136" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")
(defun ready-save-data (data path)
  (with-open-file (stream path :direction :output :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write data :stream stream :pretty t) (terpri stream))))
(defun ready-source-record (path)
  (list :path path :bytes (arcdocdb.evidence:file-bytes path)
        :sha256 (arcdocdb.evidence:file-sha256 path)
        :git-blob (string-trim '(#\\Newline #\\Space)
                    (uiop:run-program (list \"git\" \"hash-object\" \"--\" (namestring (pathname path))) :output :string))
        :text (uiop:read-file-string path :external-format :utf-8)))
(defun ready-copy-evidence (source target)
  (let ((data (arcdocdb.evidence:read-evidence source)))
    (when (probe-file target) (error \"Destinazione esistente: ~A\" target))
    (uiop:copy-file source target)
    (when (eq :compressed-evidence (getf data :kind))
      (let ((payload (getf data :payload)))
        (when (probe-file (merge-pathnames payload (uiop:pathname-directory-pathname target)))
          (error \"Payload esistente: ~A\" payload))
        (uiop:copy-file (merge-pathnames payload (uiop:pathname-directory-pathname source))
                        (merge-pathnames payload (uiop:pathname-directory-pathname target)))))
    (arcdocdb.evidence:read-evidence target)))
(defun ready-copy-process (record stem)
  (dolist (part '(\"report\" \"conservazione\"))
    (ready-copy-evidence (format nil \"spikes/out/~A/~A.lisp\" record part)
      (format nil \"spikes/results/2026-10-09-writer-ready/~A~A.lisp\" stem
              (if (string= part \"report\") \"\" \"-conservazione\")))))
")
  (:PATH "spikes/out/ready-publication-functions.lisp" :BYTES 1736 :SHA256
   "dbd1433cc3cf04e371653b08223f6e3023db71444899bc0868eb956a67355680" :GIT-BLOB
   "026a9c86e9f7f730c2912e77d532c3dcdedfd272" :TEXT "(require :asdf)
(load \"tools/evidence-storage.lisp\")
(defun ready-save-data (data path)
  (with-open-file (stream path :direction :output :if-exists :error :external-format :utf-8)
    (let ((*print-readably* t)) (write data :stream stream :pretty t) (terpri stream))))
(defun ready-source-record (path)
  (list :path path :bytes (arcdocdb.evidence:file-bytes path)
        :sha256 (arcdocdb.evidence:file-sha256 path)
        :git-blob (string-trim '(#\\Newline #\\Space)
                    (uiop:run-program (list \"git\" \"hash-object\" \"--\" (namestring (pathname path))) :output :string))
        :text (uiop:read-file-string path :external-format :utf-8)))
(defun ready-copy-evidence (source target)
  (arcdocdb.evidence:read-evidence source)
  (let ((data (let ((*read-eval* nil))
                (with-open-file (stream source) (read stream)))))
    (when (probe-file target) (error \"Destinazione esistente: ~A\" target))
    (uiop:copy-file source target)
    (when (eq :compressed-evidence (getf data :kind))
      (let ((payload (getf data :payload)))
        (when (probe-file (merge-pathnames payload (uiop:pathname-directory-pathname target)))
          (error \"Payload esistente: ~A\" payload))
        (uiop:copy-file (merge-pathnames payload (uiop:pathname-directory-pathname source))
                        (merge-pathnames payload (uiop:pathname-directory-pathname target)))))
    (arcdocdb.evidence:read-evidence target)))
(defun ready-copy-process (record stem)
  (dolist (part '(\"report\" \"conservazione\"))
    (ready-copy-evidence (format nil \"spikes/out/~A/~A.lisp\" record part)
      (format nil \"spikes/results/2026-10-09-writer-ready/~A~A.lisp\" stem
              (if (string= part \"report\") \"\" \"-conservazione\")))))
")
  (:PATH "spikes/out/ready-publish-first-review.lisp" :BYTES 568 :SHA256
   "9a70093863919270e2491cae21db6198e34d8c69d6278529d7968af2772da003" :GIT-BLOB
   "97cdfe893511e674584591aec8d4f76434eb009f" :TEXT
   "(load \"spikes/out/ready-publication-functions.lisp\")
(ready-copy-process \"4000521104-command-8510-0\" \"pubblicazione-mirata-processo\")
(ready-copy-evidence \"spikes/out/ready-independent-review.lisp\"
                     \"spikes/results/2026-10-09-writer-ready/revisione-indipendente-iniziale.lisp\")
(ready-copy-evidence \"spikes/out/ready-review-probes.lisp\"
                     \"spikes/results/2026-10-09-writer-ready/probe-revisione-iniziale.lisp\")
(load \"spikes/out/ready-refresh-catalog.lisp\")
(format t \"Prima revisione e processo di pubblicazione conservati.~%\")
")
  (:PATH "spikes/out/ready-publish-final.lisp" :BYTES 3543 :SHA256
   "c427f67bf43e39ed96f3b219cb5c3783e58ed7529d6992cfb0531550e8690e62" :GIT-BLOB
   "8f8c4d23c79ec3b54e6ce8a114599c6b73ae8268" :TEXT
   "(load \"spikes/out/ready-publication-functions.lisp\")
(load \"spikes/out/ready-author-review.lisp\")
(dolist (entry '((\"4000521888-command-44171-0\" \"prima-revisione-processo\")
                 (\"4000521809-command-41045-0\" \"mutazioni-finali-self-test\")
                 (\"4000521918-command-45102-0\" \"mutazioni-finali-processo\")
                 (\"4000522063-command-47453-0\" \"mutazioni-finali-probe-processo\")
                 (\"4000522494-command-56187-0\" \"pubblicazione-fd96-processo\")
                 (\"4000522834-command-13958-0\" \"pubblicazione-cbor-processo\")
                 (\"4000522904-command-41347-0\" \"check-finale-processo\")))
  (ready-copy-process (first entry) (second entry)))
(dolist (entry '((\"spikes/out/ready-mutations-final/report.lisp\" \"mutazioni-finali-dati.lisp\")
                 (\"spikes/out/4000521810-ready-signal-self-test-41080/report.lisp\" \"segnale-os-dati.lisp\")
                 (\"spikes/out/ready-author-review-data.lisp\" \"revisione-autore.lisp\")
                 (\"spikes/out/ready-main-independent-review.lisp\" \"revisione-indipendente-finale.lisp\")
                 (\"spikes/out/ready-main-review-probes.lisp\" \"probe-revisione-finale.lisp\")))
  (ready-copy-evidence (first entry)
                       (concatenate 'string \"spikes/results/2026-10-09-writer-ready/\" (second entry))))
(let ((report (arcdocdb.evidence:read-evidence \"spikes/out/ready-mutations-final/report.lisp\")))
  (ready-save-data
    (list :schema-version 1 :kind :raw-mutation-logs :version :signal-aware
          :logs (mapcar #'ready-source-record
                         (cons (getf report :baseline-log)
                               (mapcar (lambda (entry) (getf entry :log)) (getf report :mutants)))))
    \"spikes/results/2026-10-09-writer-ready/mutazioni-finali-log.lisp\"))
(ready-save-data
  (list :schema-version 1 :kind :process-signal-raw-sources
        :sources (mapcar #'ready-source-record
           '(\"spikes/out/4000521810-ready-signal-self-test-41080/test.log\"
             \"spikes/out/4000521810-ready-signal-self-test-41080/tools/writer-ready-isolated-build.lisp\")))
  \"spikes/results/2026-10-09-writer-ready/segnale-os-originali.lisp\")
(ready-save-data
  (list :schema-version 1 :kind :verification-adapter-sources :version :integrated
        :sources (mapcar #'ready-source-record
          '(\"spikes/out/writer-ready-mutation-before-signal-fix.lisp\"
            \"spikes/out/writer-ready-mutation-final-self-test.lisp\"
            \"spikes/out/ready-mutation-final-summary.lisp\"
            \"spikes/out/ready-publication-functions-first-version.lisp\"
            \"spikes/out/ready-publication-functions.lisp\"
            \"spikes/out/ready-publish-first-review.lisp\"
            \"spikes/out/ready-publish-final.lisp\"
            \"spikes/out/ready-author-review.lisp\"
            \"spikes/out/ready-publish-fd96-check.lisp\"
            \"spikes/out/ready-publish-cbor-check.lisp\"
            \"spikes/out/ready-refresh-catalog.lisp\"
            \"docs/implementazione/writer-ready-metodo.md\")))
  \"spikes/results/2026-10-09-writer-ready/sorgenti-adattatori-finali.lisp\")
(ready-copy-evidence \"spikes/out/4000522979-check-41982-0/report.lisp\"
                     \"spikes/results/2026-10-09-writer-ready/spikes-finali.lisp\")
(ready-copy-evidence \"spikes/out/4000522979-check-41982-0/conservazione.lisp\"
                     \"spikes/results/2026-10-09-writer-ready/spikes-finali-conservazione.lisp\")
(load \"spikes/out/ready-refresh-catalog.lisp\")
(format t \"Dati finali, due letture C1 e check integrato preservati.~%\")
")
  (:PATH "spikes/out/ready-author-review.lisp" :BYTES 1666 :SHA256
   "66e3664481dd7921a6f4a5386345bda6615b9f9eef4df105bb00a0ae4947b7ce" :GIT-BLOB
   "d7e857c07962b8cdce116a6916974786106ca2fb" :TEXT
   "(load \"spikes/out/ready-publication-functions.lisp\")
(let* ((check (arcdocdb.evidence:read-evidence \"spikes/out/4000522904-command-41347-0/report.lisp\"))
       (review \"docs/implementazione/writer-ready-revisione.md\")
       (files '(\"arcdocdb.asd\" \"src/execution/package.lisp\" \"src/execution/queue.lisp\"
                \"src/execution/writer.lisp\" \"src/execution/handoff.lisp\"
                \"src/execution/ready-types.lisp\" \"src/execution/ready.lisp\"
                \"tests/execution/ready.lisp\" \"tools/writer-ready-bench.lisp\"
                \"tools/writer-ready-mutation.lisp\")))
  (unless (and (eq :ok (getf check :status)) (eq :stable (getf check :source-consistency))
               (eql 0 (getf check :exit-code)))
    (error \"Verifica integrata non riuscita o sorgenti cambiati.\"))
  (ready-save-data
    (list :schema-version 1 :kind :c1-review :role :author :scope :writer-ready
          :base-commit \"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\"
          :recorded-at-universal-time (get-universal-time) :status :reviewed-local
          :review-points 12 :open-findings nil
          :sources (mapcar #'ready-source-record files)
          :review-document (ready-source-record review)
          :report-original (uiop:read-file-string review :external-format :utf-8)
          :integrated-check \"spikes/out/4000522904-command-41347-0/report.lisp\"
          :limits '(:local-primitive-only :raw-coverage-gaps-retained :no-approved-exclusions
                    :no-complete-mcdc :no-engine-pool-or-performance-qualification))
    \"spikes/out/ready-author-review-data.lisp\"))
(format t \"Lettura C1 autore conservata con dodici punti e hash finali.~%\")
")
  (:PATH "spikes/out/ready-publish-fd96-check.lisp" :BYTES 871 :SHA256
   "b247cbee2a1971dddb489dc3b09333cac4264dcbd4ea253cf8fb91f6ee0b507e" :GIT-BLOB
   "28dcf8a2dc1c956413864a9d6689ca2c636d1bc0" :TEXT
   "(load \"spikes/out/ready-publication-functions.lisp\")
(ready-copy-process \"4000521907-command-44843-0\" \"check-integrato-processo\")
(let ((out #p\"spikes/results/2026-10-09-writer-ready-fd96-spikes/\"))
  (ensure-directories-exist out)
  (ready-copy-evidence \"spikes/out/4000521968-check-46180-0/report.lisp\" (merge-pathnames \"spikes.lisp\" out))
  (ready-copy-evidence \"spikes/out/4000521968-check-46180-0/conservazione.lisp\" (merge-pathnames \"conservazione.lisp\" out))
  (ready-save-data
    (list :schema-version 1 :kind :evidence-catalog :component :writer-ready-integrated-spikes
          :base \"fd96fb3145f593f31552de26a8fd93478b69fc8f\"
          :entries '((:artifact \"spikes.lisp\") (:artifact \"conservazione.lisp\")))
    (merge-pathnames \"catalogo.lisp\" out)))
(load \"spikes/out/ready-refresh-catalog.lisp\")
(format t \"Check fd96 e master degli spike conservati.~%\")
")
  (:PATH "spikes/out/ready-publish-cbor-check.lisp" :BYTES 866 :SHA256
   "db29a21ff307383b22bf2b88401fbe8fa9a4eb17e7360954c011a7e726d2d0a3" :GIT-BLOB
   "45b10ad52134831d8a74dd9e5640598195f07b02" :TEXT
   "(load \"spikes/out/ready-publication-functions.lisp\")
(ready-copy-process \"4000522514-command-56618-0\" \"check-cbor-processo\")
(let ((out #p\"spikes/results/2026-10-09-writer-ready-cbor-spikes/\"))
  (ensure-directories-exist out)
  (ready-copy-evidence \"spikes/out/4000522582-check-59441-0/report.lisp\" (merge-pathnames \"spikes.lisp\" out))
  (ready-copy-evidence \"spikes/out/4000522582-check-59441-0/conservazione.lisp\" (merge-pathnames \"conservazione.lisp\" out))
  (ready-save-data
    (list :schema-version 1 :kind :evidence-catalog :component :writer-ready-integrated-spikes
          :base \"201562dffd8c48e5d2047f73ef905f64b447e663\"
          :entries '((:artifact \"spikes.lisp\") (:artifact \"conservazione.lisp\")))
    (merge-pathnames \"catalogo.lisp\" out)))
(load \"spikes/out/ready-refresh-catalog.lisp\")
(format t \"Check CBOR e master degli spike conservati.~%\")
")
  (:PATH "spikes/out/ready-refresh-catalog.lisp" :BYTES 891 :SHA256
   "fdd8e8555ff737c4688a50dc1b8704be5a647e5eadec138060349f811572687f" :GIT-BLOB
   "9369743b3064eabd6760a0139356b7d3663415de" :TEXT "(require :asdf)
(let* ((out #p\"spikes/results/2026-10-09-writer-ready/\")
       (data (list :schema-version 1 :kind :evidence-catalog :component :writer-ready
                   :base \"33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691\"
                   :historical-bases '(\"92d8b0ebf498800e4847bc4828560c6dac879c0e\" \"fd96fb3145f593f31552de26a8fd93478b69fc8f\" \"201562dffd8c48e5d2047f73ef905f64b447e663\")
                   :entries (loop for path in (sort (directory (merge-pathnames \"*.lisp\" out)) #'string< :key #'namestring)
                                  unless (string= (file-namestring path) \"catalogo.lisp\")
                                  collect (list :artifact (file-namestring path))))))
  (with-open-file (stream (merge-pathnames \"catalogo.lisp\" out) :direction :output :if-exists :supersede)
    (let ((*print-readably* t)) (write data :stream stream :pretty t) (terpri stream))))
")
  (:PATH "docs/implementazione/writer-ready-metodo.md" :BYTES 5986 :SHA256
   "6f778d4eccdc5d8fccc0b63d8677956a13837991e9a915ab4ad79d1592b4952f" :GIT-BLOB
   "c04cfa11a0b9edaf4b73a251845690cdbb3ee98c" :TEXT
   "# Metodo della lista dei writer pronti

Registrato il 2026-10-09 prima delle campagne, base `92d8b0e`.
Componente C1: lista pronta preallocata a partizioni indipendenti, da
[ADR-0045 §§6/8](../adr/0045-modello-di-esecuzione.md), REQ-CON-001/002/004/005
e REQ-AFF-008; INV-P1/P2/P5/P6, INV-A8 e INV-V4.

## Contratto preregistrato

Ogni partizione è un ring FIFO con una guard locale acquisita con un solo
CAS. Nessuno spin, callback, I/O, contatore globale o allocazione per compito.
Il ring trasporta riferimenti ai writer, senza membership, generazioni o
cleanup dello stato del writer. Il protocollo di
[handoff](writer-handoff.md) resta invariato. La lista comune è toccata solo
per pubblicare o prendere un tratto, non per ciascun messaggio.

La costruzione accetta 1..64 partizioni, default 4, e 1..65536 slot per
partizione, default 1024; massimo 4194304 riferimenti preallocati. La scelta
della partizione di una Serie è un dato del chiamante, fissato prima del
percorso caldo. Non viene introdotto un algoritmo di hashing del catalogo.

`pubblica-writer-pronto(lista shard writer)` trasferisce un obbligo già
prodotto da `:schedule` e restituisce il count locale. Full/busy rifiutano
prima della mutazione: l'obbligo rimane al chiamante. Il retry riguarda
questa pubblicazione, senza accettare nuovamente il payload nel writer.
Un successo non si ritenta: l'API non deduplica pubblicazioni errate.

`preleva-writer-pronto(lista start)` prova al più K partizioni in ordine
circolare. Una guard contesa non impedisce di provarne un'altra. Restituisce
writer, `:writer` e cursore successivo alla partizione servita; senza successo
restituisce NIL, `:busy` se almeno una guard era contesa, altrimenti `:empty`,
e cursore successivo a start. Empty significa solo che ciascuna osservazione
locale era vuota: un producer concorrente può pubblicare subito dopo; non è
una prova di quiescenza globale né autorizza un parcheggio senza protocollo.
Ogni candidata ha un tentativo CAS di acquisizione; un'acquisizione riuscita
richiede anche il CAS di rilascio. Sono al più K acquisizioni e 2K CAS totali.

Il worker conserva il riferimento preso fino all'avvio riuscito del writer;
busy non lo duplica né lo perde. Non c'è cleanup tardivo di un flag scheduler
dopo `termina-tratto-writer`: una nuova ondata può già essere pubblicata.
Pool, risvegli, shutdown, controller FAULTED e adattività richiedono ancora
integrazione. Non si garantisce progresso se il chiamante abbandona un obbligo.

## Scelta e prove

Il ring con guard a tentativo singolo estende il protocollo già verificato
delle code locali. La partizione riduce il dominio di contesa; la scansione
circolare ha un limite statico e non introduce una ready queue globale per
richiesta. Non è una struttura lock-free e non viene dichiarata la soluzione
universalmente più veloce. I CAS seguono il
[contratto SBCL](https://www.sbcl.org/manual/#Atomic-Operations) e servono
anche da [barriere di memoria](https://www.sbcl.org/manual/#Barriers).
L'alternativa MPMC con sequenza per slot richiederebbe un nuovo protocollo
di pubblicazione, overflow e riuso; non viene selezionata senza prove proprie.

- Oracolo indipendente con liste FIFO e cursore, sequenze finite con seme,
  capacity 1 e altre cardinalità, wrap, pieno, vuoto e rotazione tra partizioni.
- Limiti/default, input invalidi, rifiuti senza mutazione, cleanup dopo full,
  guard posseduta da altro thread e FI privata sugli invarianti del ring.
- Handoff integrato: obbligo conservato su pubblicazione full/busy e avvio
  busy; entrambi gli ordini enqueue/fine vuota, nuova ondata e riaccodamento.
- Worker reali riusati su ondate con producer vivi e più consumer; una
  partizione occupata mentre l'altra avanza. Retry e join del solo harness
  hanno limiti e gli errori dei worker sono rilanciati.
- Due letture C1, inventario delle decisioni, copertura raw completa di tutti
  i file execution. Nessuna forma sottratta, esclusione approvata o MC/DC
  implicita. Build senza warning/style-warning, lint e `make check`.
- Dodici mutanti semantici preregistrati nel runner prima della campagna:
  ring, proprietà, capienza, scansione, busy, cursore e pubblicazione. Baseline
  riuscita obbligatoria; compilation failure e before-tests non sono rilevamenti.
- Allocazioni: due scenari preallocati con una e quattro partizioni, cinque
  campioni di 4096 cicli ciascuno, warmup 128 e GC fuori dal contatore. Capacità 3 e due writer per partizione forzano wrap; ogni ciclo include
  accettazione del payload preallocato, pubblicazione, prelievo e fine del
  tratto. Si misura la composizione handoff/lista pronta. Identità,
  count, status e cursore contribuiscono a un sink esatto; controllo positivo
  heap, sink errato rifiutato e clock nullo distinto. Percorsi d'errore esclusi;
  zero osservato non è una garanzia universale, né throughput o P99.

Tutti i tentativi sono registrati con `tools/record-command.lisp`, argv,
ambiente, sorgenti stabili e output integrali. I C4 hanno self-test e rapporti
parziali; le prove congelate vivono in una clone separata. Dati grandi vengono
compressi senza perdita e verificati dal lettore delle evidenze. I gate del
motore e i target integrati restano aperti.

## Correzione del runner prima della campagna finale

Dopo l'integrazione di `fd96fb3`, il runner ready adotta la correzione della
classificazione di processo: un segnale OS o un exit nonzero dopo il marcatore
reale di completamento sono `:worker-error`, mai rilevamento. Exit e segnale
restano distinti nei dati e nella baseline; il self-test termina un proprio
child con SIGKILL e conserva runner, log e report. Il set dei dodici mutanti
resta invariato. La campagna viene ripetuta integralmente in
`ready-mutations-final`, conservando precedente driver e campagna; prodotto,
test e benchmark restano invariati; le prove mirate di copertura e allocazione
non richiedono ripetizione. La suite completa sarà rieseguita dal check integrato.
")))
