;;;; Otto mutazioni della coda writer in copie isolate; il checkout non è modificato.
;;;; Uso: --self-test oppure --run directory-nuova/.
;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.writer-queue.mutation (:use #:cl))
(in-package #:arcdocdb.writer-queue.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *mutants*
  '(("src/execution/writer.lisp" "writer-fifo-head"
     "(cursor (coda-writer-head queue))" "(cursor (coda-writer-tail queue))")
    ("src/execution/queue.lisp" "writer-tail-wrap"
     "(coda-writer-tail queue) (mod (1+ tail) (coda-writer-capacity queue))"
     "(coda-writer-tail queue) (mod (+ tail 2) (coda-writer-capacity queue))")
    ("src/execution/queue.lisp" "writer-full-boundary"
     "(= (coda-writer-count queue) (coda-writer-capacity queue))"
     "(> (coda-writer-count queue) (coda-writer-capacity queue))")
    ("src/execution/queue.lisp" "writer-guard-busy"
     "(unless (null (sb-ext:compare-and-swap (coda-writer-guard queue) nil thread))
      (error 'resource-exhausted :reason :writer-queue-busy))"
     "(sb-ext:compare-and-swap (coda-writer-guard queue) nil thread)")
    ("src/execution/writer.lisp" "writer-thread-owner"
     "(eq (coda-writer-owner queue) sb-thread:*current-thread*)"
     "(coda-writer-owner queue)")
    ("src/execution/writer.lisp" "writer-generation-lease"
     "(= lease (coda-writer-generation queue))"
     "(<= lease (coda-writer-generation queue))")
    ("src/execution/writer.lisp" "writer-cumulative-quantum"
     "(let ((remaining (- (coda-writer-quantum queue) (coda-writer-extracted queue))))"
     "(let ((remaining (progn (setf (coda-writer-extracted queue) 0)
                            (- (coda-writer-quantum queue) (coda-writer-extracted queue)))))")
    ("src/execution/writer.lisp" "writer-target-span"
     "(taken (min count (- limit first) remaining))"
     "(taken (min count (max (- limit first) (- (length destination) first)) remaining))")))

(define-condition target-invalido (error)
  ((motivo :initarg :motivo :reader motivo-target))
  (:report (lambda (condizione flusso)
             (format flusso "Bersaglio della mutazione coda writer invalido: ~S."
                     (motivo-target condizione)))))

(defun source-files ()
  "Tutti i file richiesti dall'ASD, test e build; nessuna evidenza o checkout Git copiato."
  (append '(#p"arcdocdb.asd" #p"tools/build.lisp")
          (sort (append (directory "src/**/*.lisp") (directory "tests/**/*.lisp"))
                #'string< :key #'namestring)))

(defun fingerprints ()
  "MD5 dei file realmente copiati e del driver, per confrontare prima e dopo."
  (loop for file in (append (source-files) '(#p"tools/writer-queue-mutation.lisp"))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun read-text (path)
  "Legge esclusivamente sorgenti e log come dati UTF-8."
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
  (unless (= 8 (length *mutants*)) (error "Numero mutanti coda writer inatteso."))
  (dolist (mutant *mutants*)
    (destructuring-bind (path name before after) mutant
      (declare (ignore after))
      (handler-case (unique-position (read-text path) before)
        (target-invalido (condizione)
          (error "Mutazione coda writer ~A in ~A: ~A." name path condizione)))))
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

(defun classify-result (text exit)
  "Solo errore runtime dopo smoke rileva il mutante; gli altri guasti sono INVALID."
  (cond ((compilation-failure-p text) (values :invalid :compilation-failure))
        ((or (not (integerp exit)) (not (smoke-started-p text)))
         (values :invalid :before-smoke))
        ((zerop exit) (values :survived nil))
        (t (values :detected nil))))

(defun detected-p (text exit)
  "Rilevato solo con exit nonzero dopo smoke; compilazione fallita non conta."
  (eq :detected (classify-result text exit)))

(defun esigi-target-invalido (funzione motivo)
  "Verifica il self-test dei bersagli, distinguendo assenza e ambiguità."
  (let ((rilevato nil))
    (handler-case (funcall funzione)
      (target-invalido (condizione)
        (unless (eq motivo (motivo-target condizione)) (error condizione))
        (setf rilevato t)))
    (unless rilevato (error "Self-test: bersaglio invalido non rilevato."))))

(defun self-test ()
  "Verifica prima sostituzione, classificazioni e applicabilità ai due sorgenti correnti."
  (let* ((smoke "ok    ARCDOCDB:*VERSION* è una stringa")
         (backtrace (format nil "0: (SEARCH ~S TEST-LOG)" smoke)))
    (unless (and (string= "xAxB" (substitute-first "xBxB" "B" "A"))
                 (detected-p smoke 1) (not (detected-p smoke 0))
                 (not (detected-p "compilation aborted" 1))
                 (not (detected-p (format nil "~A~%compilation aborted" smoke) 1))
                 (not (detected-p backtrace 1))
                 (not (detected-p (concatenate 'string "  " smoke) 1))
                 (not (detected-p (concatenate 'string smoke " citato") 1))
                 (line-present-p "build e test: nessun avviso, tutti i controlli superati"
                                 "build e test: nessun avviso, tutti i controlli superati")
                 (eq :invalid (classify-result backtrace 1))
                 (eq :invalid (classify-result "compilation aborted" 1))
                 (eq :invalid (classify-result "runtime prima dello smoke" 1)))
      (error "Mutazioni coda writer: self-test di sostituzione/classificazione fallito.")))
  (esigi-target-invalido (lambda () (substitute-first "abc" "Z" "A")) :assente)
  (esigi-target-invalido (lambda () (unique-position "xBxB" "B")) :ambiguo)
  (esigi-target-invalido (lambda () (unique-position "abc" "Z")) :assente)
  (validate-mutants)
  (list :status :ok :substitution :first-only :classification :after-exact-smoke-line
        :backtrace-marker :invalid
        :invalid-targets '(:missing :ambiguous) :compilation-failure :invalid
        :baseline-completion :exact-build-end-line
        :applicable-mutants 8))

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
  (let ((runner (merge-pathnames "tools/writer-queue-isolated-build.lisp" directory)))
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

(defun execute-copy (directory)
  "Esegue la build rigorosa della copia con cache locale e log conservato."
  (let ((log (merge-pathnames "test.log" directory)))
    (isolated-runner directory)
    (multiple-value-bind (out err exit)
        (uiop:run-program '("sbcl" "--noinform" "--no-userinit" "--no-sysinit"
                            "--disable-debugger" "--script" "tools/writer-queue-isolated-build.lisp")
                          :directory directory :output log :error-output :output
                          :ignore-error-status t)
      (declare (ignore out err))
      (values (read-text log) exit log))))

(defun run-baseline (directory)
  "La copia invariata deve completare smoke e test con exit zero prima dei mutanti."
  (copy-test-system directory)
  (multiple-value-bind (text exit log) (execute-copy directory)
    (let ((passed (and (integerp exit) (zerop exit) (not (compilation-failure-p text))
                       (smoke-started-p text)
                       (line-present-p text "build e test: nessun avviso, tutti i controlli superati"))))
      (list :status (if passed :ok :invalid) :exit-code exit :log (namestring log)
            :diagnostic (unless passed :baseline-failed)))))

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
              (with-open-file (stream source :direction :output :if-exists :supersede)
                (write-string (substitute-first text before after) stream)))
            (multiple-value-bind (text exit path-log) (execute-copy directory)
              (multiple-value-bind (result diagnostic) (classify-result text exit)
                (list :name name :source-file path :detected (eq result :detected) :exit-code exit
                      :result result :diagnostic diagnostic :log (namestring path-log)))))
        (error (condizione)
          (preserve-setup-error log condizione)
          (list :name name :source-file path :detected nil :exit-code nil :result :invalid
                :diagnostic :infrastructure-error :detail (princ-to-string condizione)
                :log (namestring log)))))))

(defun save-report (report directory)
  "Aggiorna solo il report della directory esclusiva; nessun risultato tentato viene perduto."
  (when directory
    (with-open-file (stream (merge-pathnames "report.lisp" directory)
                           :direction :output :if-exists :supersede :if-does-not-exist :create)
      (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))))

(defun main ()
  "Self-test o otto copie nuove; plist finale e exit nonzero per campagna non valida."
  (let* ((args (rest sb-ext:*posix-argv*)) (before (fingerprints)) (directory nil)
         (report (list :schema-version 1 :kind :writer-queue-mutations :status :running
                       :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
                       :source-fingerprints-before before
                       :targets (loop for (path name old new) in *mutants*
                                      collect (list :source-file path :name name :before old :after new))
                       :limits '(:targeted-mutants-only :bounded-writer-queue-tests
                                 :compile-failure-not-detection :no-ready-list-wakeup-or-pool-qualification
                                 :no-durability-engine-or-release-qualification))))
    (handler-case
        (progn
          (unless (or (equal args '("--self-test"))
                      (and (= (length args) 2) (string= (first args) "--run")))
            (error "Usare --self-test oppure --run directory-nuova/."))
          (setf (getf report :self-test) (self-test))
          (when (string= (first args) "--run")
            (setf directory (new-directory (second args)))
            (save-report report directory)
            (setf (getf report :baseline)
                  (run-baseline (new-directory (merge-pathnames "baseline/" directory))))
            (save-report report directory)
            (unless (eq (getf (getf report :baseline) :status) :ok)
              (error "Mutazioni coda writer: baseline invariata non riuscita."))
            (loop for mutant in *mutants* for i from 0
                  do (let* ((child (new-directory (merge-pathnames (format nil "~D/" i) directory)))
                            (result (run-mutant mutant child)))
                       (setf (getf report :mutants) (append (getf report :mutants) (list result)))
                       (save-report report directory)))
            (unless (and (= 8 (length (getf report :mutants)))
                         (every (lambda (result) (getf result :detected)) (getf report :mutants)))
              (error "Mutazioni coda writer: sopravvivenza o errore prima dello smoke.")))
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
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(main)
