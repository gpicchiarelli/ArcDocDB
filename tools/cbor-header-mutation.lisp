;;;; Mutazioni del verificatore CBOR in copie isolate; il checkout non è modificato.
;;;; Uso: --self-test oppure --run directory-nuova/.
;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.cbor-header.mutation (:use #:cl))
(in-package #:arcdocdb.cbor-header.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *mutants*
  '(("src/codec/cbor-header.lisp" "reserved-28"
     "(<= 28 ai 30)" "(<= 29 ai 30)")
("src/codec/cbor-header.lisp" "physical-span"
     "(> width (- end start))" "(> width (- (length buffer) start))")
("src/codec/cbor-header.lisp" "endianness-low"
     "(ash low 8)" "(ash low 7)")
("src/codec/cbor-header.lisp" "split-u32"
     "(max 0 (- width 4))" "(min 4 (max 0 (- width 3)))")
("src/codec/cbor-header.lisp" "high-low-swapped"
     "(values high low next)" "(values low high next)")
("src/codec/cbor-header.lisp" "simple-31"
     "(< low 32)" "(< low 31)")
("src/codec/cbor-header.lisp" "indefinite-major6"
     "((0 1 6) (error" "((0 1) (error")
("src/codec/cbor-header.lisp" "direct-argument"
     "(values 0 ai (the index (1+ cursor)))" "(values 0 (logxor ai 1) (the index (1+ cursor)))")
("src/codec/cbor-header.lisp" "next-index"
     "(next (+ start width))" "(next (+ start (1- width)))")))

(define-condition target-invalido (error)
  ((motivo :initarg :motivo :reader motivo-target))
  (:report (lambda (condizione flusso)
             (format flusso "Bersaglio della mutazione CBOR invalido: ~S."
                     (motivo-target condizione)))))

(defun source-files ()
  "Tutti i file richiesti dall'ASD, test e build; nessuna evidenza o checkout Git copiato."
  (append '(#p"arcdocdb.asd" #p"tools/build.lisp")
          (sort (append (directory "src/**/*.lisp") (directory "tests/**/*.lisp"))
                #'string< :key #'namestring)))

(defun fingerprints ()
  "MD5 dei file realmente copiati e del driver, per confrontare prima e dopo."
  (loop for file in (append (source-files) '(#p"tools/cbor-header-mutation.lisp"))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun read-text (path)
  "Legge esclusivamente sorgenti e log come dati CBOR."
  (uiop:read-file-string path :external-format :utf-8))

(defun substitute-first (text before after)
  "Sostituisce solo la prima occorrenza, senza riscrivere il testo sorgente originale."
  (let ((pos (search before text)))
    (unless pos (error 'target-invalido :motivo :assente))
    (concatenate 'string (subseq text 0 pos) after (subseq text (+ pos (length before))))))

(defun unique-position (text before)
  "Ogni bersaglio della campagna deve essere presente e non ambiguo."
  (let ((pos (search before text)))
    (unless pos (error 'target-invalido :motivo :assente))
    (when (search before text :start2 (1+ pos)) (error 'target-invalido :motivo :ambiguo))
    pos))

(defun validate-mutants ()
  "Ogni frammento bersaglio deve apparire una sola volta nel proprio file congelato."
  (unless (= 9 (length *mutants*)) (error "Numero mutanti CBOR inatteso."))
  (dolist (mutant *mutants*)
    (destructuring-bind (path name before after) mutant
      (declare (ignore after))
      (handler-case (unique-position (read-text path) before)
        (target-invalido (condizione)
          (error "Mutazione CBOR ~A in ~A: ~A." name path condizione)))))
  nil)

(defun compilation-failure-p (text)
  "Una diagnostica di compilazione non costituisce prova di rilevamento del mutante."
  (or (search "compilation aborted" text :test #'char-equal)
      (search "COMPILE-FILE-ERROR" text :test #'char-equal)
      (search "COMPILE-FILE-WARNED" text :test #'char-equal)))

(defun line-present-p (text expected)
  "Richiede una riga esatta, ammettendo solo il terminatore CR di un flusso CRLF."
  (loop for line in (uiop:split-string text :separator '(#\Newline))
        thereis (string= (string-right-trim '(#\Return) line) expected)))

(defun smoke-started-p (text)
  "Esito smoke su riga esatta; una citazione nel backtrace non costituisce smoke."
  (line-present-p text "ok    ARCDOCDB:*VERSION* è una stringa"))

(defun build-completed-p (text)
  "Richiede la riga esatta di completamento della build rigorosa."
  (line-present-p text "build e test: nessun avviso, tutti i controlli superati"))

(defun classify-result (text exit &optional signal)
  "Segnali e guasti dopo completamento sono WORKER-ERROR, mai rilevamenti runtime."
  (cond (signal (values :worker-error :process-signal))
        ((and (integerp exit) (not (zerop exit)) (build-completed-p text))
         (values :worker-error :after-build-completion))
        ((compilation-failure-p text) (values :invalid :compilation-failure))
        ((or (not (integerp exit)) (not (smoke-started-p text)))
         (values :invalid :before-smoke))
        ((zerop exit) (if (build-completed-p text) (values :survived nil)
                         (values :invalid :missing-build-completion)))
        (t (values :detected nil))))

(defun detected-p (text exit &optional signal)
  "Compilazione, guasti dopo completamento e segnali OS non rilevano il mutante."
  (eq :detected (classify-result text exit signal)))

(defun classify-baseline-result (text exit &optional signal)
  "Solo build completa riuscita è OK; preserva guasti worker e invalida ogni altro esito."
  (multiple-value-bind (result diagnostic) (classify-result text exit signal)
    (case result
      (:survived (values :ok nil))
      (:worker-error (values :worker-error diagnostic))
      (otherwise (values :invalid (or diagnostic :baseline-failed))))))

(defun esigi-target-invalido (funzione motivo)
  "Verifica il self-test dei bersagli, distinguendo assenza e ambiguità."
  (let ((rilevato nil))
    (handler-case (funcall funzione)
      (target-invalido (condizione)
        (unless (eq motivo (motivo-target condizione)) (error condizione))
        (setf rilevato t)))
    (unless rilevato (error "Self-test: bersaglio invalido non rilevato."))))

(defun classifier-self-test ()
  "Distingue runtime, completamento, compilazione e segnale; rifiuta marker citati."
  (let* ((smoke "ok    ARCDOCDB:*VERSION* è una stringa")
         (complete "build e test: nessun avviso, tutti i controlli superati")
         (finished (format nil "~A~%~A~%" smoke complete))
         (crlf (format nil "~A~C~%~A~C~%" smoke #\Return complete #\Return))
         (cases
           (list (list smoke 1 nil '(:detected nil))
                 (list finished 0 nil '(:survived nil))
                 (list crlf 0 nil '(:survived nil))
                 (list smoke 0 nil '(:invalid :missing-build-completion))
                 (list smoke nil nil '(:invalid :before-smoke))
                 (list "runtime prima dello smoke" 1 nil '(:invalid :before-smoke))
                 (list finished 7 nil '(:worker-error :after-build-completion))
                 (list complete 7 nil '(:worker-error :after-build-completion))
                 (list crlf 7 nil '(:worker-error :after-build-completion))
                 (list (format nil "~ACOMPILE-FILE-ERROR" finished) 7 nil
                       '(:worker-error :after-build-completion))
                 (list "compilation aborted" 1 nil '(:invalid :compilation-failure))
                 (list (format nil "~A~%COMPILE-FILE-WARNED" smoke) 1 nil
                       '(:invalid :compilation-failure)))))
    (dolist (text (list (format nil "0: (SEARCH ~S TEST-LOG)" smoke)
                       (concatenate 'string "  " smoke) (concatenate 'string smoke " citato")))
      (push (list text 1 nil '(:invalid :before-smoke)) cases))
    (dolist (quoted (list (format nil "0: (SEARCH ~S LOG)" complete)
                         (concatenate 'string "  " complete) (concatenate 'string complete " citato")))
      (push (list (format nil "~A~%~A" smoke quoted) 1 nil '(:detected nil)) cases))
    (dolist (text (list "" smoke finished "compilation aborted"))
      (dolist (exit '(nil 0 1 137))
        (push (list text exit sb-posix:sigkill '(:worker-error :process-signal)) cases)))
    (dolist (case cases)
      (destructuring-bind (text exit signal expected) case
        (unless (equal expected (multiple-value-list (classify-result text exit signal)))
          (error "tools/cbor-header-mutation.lisp: COD-60, classifier ~S/~S/~S."
                 text exit signal))
        (let ((baseline (list (case (first expected)
                               (:survived :ok) (:worker-error :worker-error) (otherwise :invalid))
                             (if (eq :detected (first expected)) :baseline-failed (second expected)))))
          (unless (equal baseline (multiple-value-list (classify-baseline-result text exit signal)))
            (error "tools/cbor-header-mutation.lisp: COD-60, classifier baseline errato.")))))
    (unless (and (detected-p smoke 1) (not (detected-p finished 7))
                 (not (detected-p smoke 137 sb-posix:sigkill)))
      (error "tools/cbor-header-mutation.lisp: COD-60, detected-p errato."))))

(declaim (ftype (function () (values string &optional)) self-test-process-failures))

(defun self-test ()
  "Verifica sostituzione, classificazione, processi reali e codec congelato."
  (unless (string= "xAxB" (substitute-first "xBxB" "B" "A"))
    (error "tools/cbor-header-mutation.lisp: COD-60, sostituzione errata."))
  (classifier-self-test)
  (esigi-target-invalido (lambda () (substitute-first "abc" "Z" "A")) :assente)
  (esigi-target-invalido (lambda () (unique-position "xBxB" "B")) :ambiguo)
  (esigi-target-invalido (lambda () (unique-position "abc" "Z")) :assente)
  (validate-mutants)
  (list :status :ok :substitution :first-only :classification :after-exact-smoke-line
        :backtrace-marker :invalid
        :invalid-targets '(:missing :ambiguous) :compilation-failure :invalid
        :baseline-completion :exact-build-end-line
        :after-completion-failure :worker-error :os-signal :worker-error
        :process-fixture-report (self-test-process-failures)
        :applicable-mutants 9))

(defun new-directory (name)
  "Crea con mkdir esclusivo, dopo aver creato solo i genitori; non riutilizza directory."
  (let* ((directory (merge-pathnames (uiop:ensure-directory-pathname name) (truename "./")))
         (parent (make-pathname :defaults directory :directory (butlast (pathname-directory directory))
                                :name "segnaposto" :type nil)))
    (ensure-directories-exist parent)
    (sb-posix:mkdir directory #o700)
    directory))

(defun copy-test-system (directory)
  "Copia ASD, sorgenti, test e build; ogni destinazione è nuova e appartiene alla campagna."
  (dolist (file (source-files))
    (let ((target (merge-pathnames (enough-namestring file) directory)))
      (ensure-directories-exist target)
      (uiop:copy-file file target))))

(defun isolated-runner (directory)
  "Salva il runner della copia; output ASDF in fasl locale, distinto dalle altre prove."
  (let ((runner (merge-pathnames "tools/cbor-header-isolated-build.lisp" directory)))
    (with-open-file (stream runner :direction :output :if-exists :error :if-does-not-exist :create)
      (write-line ";;;; Runner della copia isolata; avvia la build rigorosa originale." stream)
      (write '(require :asdf) :stream stream) (terpri stream)
      (write `(asdf:initialize-output-translations
               '(:output-translations (,(namestring directory)
                                      ,(namestring (merge-pathnames "fasl/" directory)))
                                      :ignore-inherited-configuration)) :stream stream)
      (terpri stream)
      (write '(load "tools/build.lisp") :stream stream) (terpri stream))
    runner))

(defun execute-runner (directory)
  "Conserva log, exit e segnale OS del runner preparato, comprese le fixture."
  (let* ((log (merge-pathnames "test.log" directory))
         (process (uiop:launch-program
                    '("sbcl" "--noinform" "--no-userinit" "--no-sysinit"
                      "--disable-debugger" "--script" "tools/cbor-header-isolated-build.lisp")
                    :directory directory :output log :error-output :output)))
    (multiple-value-bind (exit signal) (uiop:wait-process process)
      (values (read-text log) exit log signal))))

(defun execute-copy (directory)
  "Esegue la build rigorosa della copia con cache locale e log conservato."
  (isolated-runner directory)
  (execute-runner directory))

(declaim (ftype (function (pathname condition) (values null &optional)) preserve-setup-error))

(defun run-baseline (directory)
  "La copia invariata deve completare smoke e test con exit zero prima dei mutanti."
  (let ((log (merge-pathnames "test.log" directory)))
    (handler-case
        (progn
          (copy-test-system directory)
          (multiple-value-bind (text exit path-log signal) (execute-copy directory)
            (multiple-value-bind (status diagnostic) (classify-baseline-result text exit signal)
              (list :status status :result (if (eq status :ok) :survived status)
                    :exit-code exit :signal signal :log (namestring path-log) :diagnostic diagnostic))))
      (error (condition)
        (preserve-setup-error log condition)
        (list :status :worker-error :result :worker-error :exit-code nil :signal nil
              :diagnostic :infrastructure-error :detail (princ-to-string condition)
              :log (namestring log))))))

(defun preserve-setup-error (log condition)
  "Conserva anche la diagnostica di setup, senza troncare un log eventualmente già scritto."
  (with-open-file (stream log :direction :output :if-exists :append :if-does-not-exist :create
                              :external-format :utf-8)
    (format stream "~&Errore di infrastruttura della campagna: ~A~%" condition)))

(defun run-mutant (mutant directory)
  "Conserva copia e log anche in caso di sopravvivenza, errore di setup o compilazione."
  (destructuring-bind (path name before after) mutant
    (let ((log (merge-pathnames "test.log" directory)))
      (handler-case
          (progn
            (copy-test-system directory)
            (let* ((source (merge-pathnames path directory)) (text (read-text source)))
              (unique-position text before)
              (with-open-file (stream source :direction :output :if-exists :supersede
                                            :external-format :utf-8)
                (write-string (substitute-first text before after) stream)))
            (multiple-value-bind (text exit path-log signal) (execute-copy directory)
              (multiple-value-bind (result diagnostic) (classify-result text exit signal)
                (list :name name :source-file path :detected (eq result :detected) :exit-code exit
                      :signal signal :result result :diagnostic diagnostic :log (namestring path-log)))))
        (error (condizione)
          (preserve-setup-error log condizione)
          (list :name name :source-file path :detected nil :exit-code nil :signal nil :result :worker-error
                :diagnostic :infrastructure-error :detail (princ-to-string condizione)
                :log (namestring log)))))))

(defun save-report (report directory)
  "Aggiorna solo il report della directory esclusiva; nessun risultato tentato viene perduto."
  (when directory
    (with-open-file (stream (merge-pathnames "report.lisp" directory)
                           :direction :output :if-exists :supersede :if-does-not-exist :create)
      (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))))

(defun append-mutation-result (report result)
  "Registra il risultato e conta i guasti worker separatamente dai mutanti rilevati."
  (setf (getf report :mutants) (append (getf report :mutants) (list result)))
  (when (eq :worker-error (getf result :result))
    (incf (getf report :worker-errors 0)))
  report)

(defun write-process-fixture (directory mode)
  "Runner posseduto dalla fixture: SIGKILL solo sul child oppure complete seguito da exit7."
  (let ((runner (merge-pathnames "tools/cbor-header-isolated-build.lisp" directory)))
    (ensure-directories-exist runner)
    (with-open-file (output runner :direction :output :if-exists :error :external-format :utf-8)
      (dolist (form (append '((require :sb-posix)
                             (format t "ok    ARCDOCDB:*VERSION* è una stringa~%"))
                           (case mode
                             (:signal '((finish-output)
                                        (sb-posix:kill (sb-posix:getpid) sb-posix:sigkill)))
                             (:completion
                              '((format t "build e test: nessun avviso, tutti i controlli superati~%")
                                (finish-output) (sb-ext:exit :code 7)))
                             (otherwise (error "Fixture CBOR sconosciuta: ~S" mode)))))
        (write form :stream output :pretty t) (terpri output)))
    runner))

(defun self-test-process-failures ()
  "Due child sul trasporto reale: SIGKILL ed exit7 dopo complete non rilevano mutanti."
  (let* ((directory (new-directory
                     (format nil "spikes/out/~D-cbor-header-process-self-test-~D/"
                             (get-universal-time) (sb-posix:getpid))))
         (report (list :schema-version 1 :kind :process-failure-self-test :scope :cbor-header
                       :status :running :worker-errors 0 :mutants nil)))
    (save-report report directory)
    (handler-case
        (progn
          (dolist (mode '(:signal :completion))
            (let* ((child (new-directory
                           (merge-pathnames (format nil "~(~A~)/" mode) directory)))
                   (runner (write-process-fixture child mode)))
              (multiple-value-bind (text exit log signal) (execute-runner child)
                (multiple-value-bind (result diagnostic) (classify-result text exit signal)
                  (setf report
                        (append-mutation-result report
                          (list :name (format nil "~(~A~)-fixture" mode) :result result
                                :detected (eq result :detected) :exit-code exit :signal signal
                                :diagnostic diagnostic :log (namestring log) :runner (namestring runner)
                                :baseline-classifier
                                (multiple-value-list (classify-baseline-result text exit signal)))))
                  (save-report report directory)
                  (unless (and (eq result :worker-error) (smoke-started-p text)
                               (equal (list :worker-error diagnostic)
                                      (multiple-value-list (classify-baseline-result text exit signal)))
                               (case mode
                                 (:signal (and (eql signal sb-posix:sigkill) (not (eql exit 0))
                                               (eq diagnostic :process-signal)))
                                 (:completion (and (null signal) (eql exit 7) (build-completed-p text)
                                                   (eq diagnostic :after-build-completion)))
                                 (otherwise nil)))
                    (error "tools/cbor-header-mutation.lisp: COD-60, fixture ~S invalida." mode))))))
          (setf (getf report :status) :passed)
          (save-report report directory)
          (let* ((*read-eval* nil)
                 (saved (with-open-file (input (merge-pathnames "report.lisp" directory)
                                               :external-format :utf-8)
                          (let ((data (read input)))
                            (unless (eq :eof (read input nil :eof))
                              (error "Self-test CBOR: forme aggiuntive nel report."))
                            data))))
            (unless (and (equalp saved report) (= 2 (getf saved :worker-errors))
                         (= 2 (length (getf saved :mutants)))
                         (every (lambda (entry) (and (eq :worker-error (getf entry :result))
                                                    (not (getf entry :detected))))
                                (getf saved :mutants)))
              (error "Self-test CBOR: esiti, segnali o contatori worker non conservati."))))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
        (save-report report directory)
        (error condition)))
    (format t "~&CBOR header: self-test guasti processo superato; ~A~%"
            (merge-pathnames "report.lisp" directory))
    (namestring (merge-pathnames "report.lisp" directory))))

(defun main ()
  "Self-test o nove copie nuove; plist finale e exit nonzero per campagna non valida."
  (let* ((args (rest sb-ext:*posix-argv*)) (before (fingerprints)) (directory nil)
         (report (list :schema-version 1 :kind :cbor-header-mutations :status :running
                       :worker-errors 0 :mutants nil
                       :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
                       :source-fingerprints-before before
                       :targets (loop for (path name old new) in *mutants*
                                      collect (list :source-file path :name name :before old :after new))
                       :limits '(:targeted-mutants-only :bounded-cbor-header-tests
                                 :compile-failure-not-detection :no-payload-or-document-semantics
                                 :no-durability-engine-or-release-qualification))))
    (handler-case
        (progn
          (unless (or (equal args '("--self-test"))
                      (and (= (length args) 2) (string= (first args) "--run")))
            (error "tools/cbor-header-mutation.lisp: COD-61, usare --self-test oppure --run directory-nuova/."))
          (setf (getf report :self-test) (self-test))
          (when (string= (first args) "--run")
            (setf directory (new-directory (second args)))
            (save-report report directory)
            (setf (getf report :baseline)
                  (run-baseline (new-directory (merge-pathnames "baseline/" directory))))
            (when (eq :worker-error (getf (getf report :baseline) :result))
              (incf (getf report :worker-errors)))
            (save-report report directory)
            (unless (eq (getf (getf report :baseline) :status) :ok)
              (error "tools/cbor-header-mutation.lisp: COD-61, baseline invalida o worker-error; ~A."
                     (merge-pathnames "report.lisp" directory)))
            (loop for mutant in *mutants* for i from 0
                  do (let* ((child (new-directory (merge-pathnames (format nil "~D/" i) directory)))
                            (result (run-mutant mutant child)))
                       (setf report (append-mutation-result report result))
                       (save-report report directory)))
            (unless (and (= 9 (length (getf report :mutants)))
                         (every (lambda (result) (getf result :detected)) (getf report :mutants)))
              (error "tools/cbor-header-mutation.lisp: COD-61, sopravvivenza, compilazione o worker-error; ~A."
                     (merge-pathnames "report.lisp" directory))))
          (setf (getf report :status) :ok))
      (error (condizione) (setf (getf report :status) :failed
                               (getf report :diagnostic) (princ-to-string condizione))))
    (let ((after (fingerprints)))
      (setf (getf report :source-fingerprints-after) after
            (getf report :source-consistency) (if (equal before after) :stable :changed))
      (when (and (eq (getf report :status) :ok) (not (equal before after)))
        (setf (getf report :status) :source-changed)))
    (save-report report directory)
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok)
      (format *error-output* "~&tools/cbor-header-mutation.lisp: COD-61, verifica fallita: ~S~@[; ~A~].~%"
              (getf report :status) (getf report :diagnostic))
      (sb-ext:exit :code 1))))

(main)
