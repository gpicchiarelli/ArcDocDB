;;;; Mutazioni mirate in copie isolate; nessun sorgente del repository viene riscritto.
;;;; Uso: --run directory-nuova/ [foundation|storage|recovery|decisions|manifest|io|wal] [--jobs 1..4]
;;;; oppure --self-test; baseline seriale, copie e processi dei mutanti indipendenti.
;;;; REQ: REQ-FOR-003 REQ-FOR-004 REQ-AFF-002 REQ-LIM-001 REQ-LIM-003 REQ-VAL-001
(require :asdf)
(require :sb-posix)
(defpackage #:arcdocdb.foundation.mutation (:use #:cl))
(in-package #:arcdocdb.foundation.mutation)

(defparameter *mutants*
  '(("crc-polynomial" "crc32c.lisp" "#x82f63b78" "#x82f63b79")
    ("header-crc" "record.lisp" "(unless (= (leggi-u32 buffer start)"
                                  "(unless (/= (leggi-u32 buffer start)")
    ("body-crc" "record.lisp" "(unless (= (leggi-u32 buffer (+ start +body-crc-offset+))"
                                "(unless (/= (leggi-u32 buffer (+ start +body-crc-offset+))")
    ("key-limit" "record.lisp" "(<= key-length key-limit)" "(< key-length key-limit)")
    ("index-and-or" "record.lisp" "(and (= next end) (= kind +put+)" "(or (= next end) (= kind +put+)")
    ("prepared-flag" "record.lisp" "(if (logbitp 0 actual-flags)" "(if (logbitp 1 actual-flags)")
    ("seal-checksum" "batch.lisp" "(= (leggi-u32 buffer (+ value-start +seal-checksum-offset+)) checksum)"
                                   "(/= (leggi-u32 buffer (+ value-start +seal-checksum-offset+)) checksum)")
    ("batch-stamp" "batch.lisp" "(/= stamp actual-stamp)" "(= stamp actual-stamp)")
    ("byte-budget" "batch.lisp" "(> (- next pos) remaining)" "(>= (- next pos) remaining)")))

(defparameter *storage-mutants*
  '(("segment-crc" "segment-header.lisp" "(unless (= (leggi-u32 buffer (+ start +segment-crc-offset+))"
                                          "(unless (/= (leggi-u32 buffer (+ start +segment-crc-offset+))")
    ("segment-magic-and-or" "segment-header.lisp" "(and (= (leggi-u32 buffer start)"
                                                   "(or (= (leggi-u32 buffer start)")
    ("segment-identity-and-or" "segment-header.lisp" "(and (loop for i below +serie-id-bytes+"
                                                      "(or (loop for i below +serie-id-bytes+")
    ("reserved-and-or" "segment-header.lisp" "(and (zero-range-p buffer" "(or (zero-range-p buffer")
    ("metadata-budget" "formats.lisp" "(> actual budget)" "(>= actual budget)")
    ("closed-minimum" "control-payload.lisp" "(<= +segment-header-bytes+" "(< +segment-header-bytes+")
    ("cumulative-outcomes" "control-payload.lisp" "(esigi-budget outcomes (- max-esiti total)"
                                                  "(esigi-budget outcomes max-esiti")
    ("edit-exact-consumption" "control-payload.lisp" "(unless (= end (spazio-ripetuto removed-start"
                                                   "(unless (>= end (spazio-ripetuto removed-start")
    ("decision-minimum" "control-payload.lisp" "(< count +min-participants+)" "(<= count +min-participants+)")
    ("decision-exact-consumption" "control-payload.lisp" "(unless (= end (spazio-ripetuto parts-start"
                                                       "(unless (>= end (spazio-ripetuto parts-start")))

(defparameter *recovery-mutants*
  '(("durable-strict-boundary" "scan.lisp" "(> durable absolute-prefix)"
                                         "(>= durable absolute-prefix)")
    ("witness-file-identity" "scan.lisp"
      "(u64-equal-p buffer (+ vs +seal-file-id-offset+) file-id)" "(= file-id file-id)")
    ("skip-search-position" "scan.lisp" "loop for delta below limit"
                                      "loop for delta below limit by 2")
    ("tail-batch-start" "scan.lisp" "(values pos :tail batches records)"
                                   "(values (min end (+ pos +header-bytes+)) :tail batches records)")
    ("physical-eof" "scan.lisp" "(= file-size (+ file-offset end))"
                               "(<= file-size (+ file-offset end))")
    ("search-budget-boundary" "scan.lisp" "(when (< limit positions)"
                                         "(when (<= limit positions)")
    ("witness-future-position" "scan.lisp"
      "(<= records-start batch-start (+ file-offset pos))"
      "(and (typep (+ file-offset pos) 'u64) (<= records-start batch-start))")
    ("witness-durable-position" "scan.lisp" "(<= durable batch-start)"
                                           "(<= 0 durable)")
    ("log-byte-budget-boundary" "scan.lisp" "(> (- end start) max-bytes)"
                                           "(>= (- end start) max-bytes)")))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-FOR-003 REQ-VAL-001
(defparameter *decision-mutants*
  '(("decision-count-boundary" "decisions-build.lisp" "(when (> count max-decisions)"
                                                      "(when (>= count max-decisions)")
    ("decision-cumulative-participants" "decisions-build.lisp"
      "(when (> participants (- max-participants total))" "(when (> participants max-participants)")
    ("decision-duplicate-participant" "decisions-sort.lisp"
      "(0 (error 'corruption-detected :reason :decision-duplicate-participant
                       :offset source-offset))"
      "(0 (when (zerop source-offset)
                  (error 'corruption-detected :reason :decision-duplicate-participant
                         :offset source-offset)))")
    ("decision-csn-conflict" "decisions-build.lisp"
      "(= (%entry-csn left) (%entry-csn right))" "(= (%entry-csn left) (%entry-csn left))")
    ("decision-last-id-byte" "decisions-sort.lisp"
      "(dotimes (i +participant-id-bytes+ 0)" "(dotimes (i (1- +participant-id-bytes+) 0)")
    ("decision-missing-found" "decisions-query.lisp" "(values nil 0 0)" "(values t 0 0)")
    ("decision-set-conflict" "decisions-build.lisp"
      "(loop for i below (length a) always" "(loop for i below (min 1 (length a)) always")))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-AFF-008 REQ-AFF-018 REQ-VAL-001
(defparameter *manifest-mutants*
  '(("manifest-first-complete" "manifest-fold.lisp"
      "(unless (= (%edit-flags edit) +edit-complete+)"
      "(when (= (%edit-flags edit) +edit-complete+)")
    ("manifest-count-boundary" "manifest-build.lisp"
      "(when (> (1+ count) (%limits-edits limits))"
      "(when (>= (1+ count) (%limits-edits limits))")
    ("manifest-cumulative-outcomes" "manifest-build.lisp"
      "(when (> (%edit-outcomes edit) (- (%limits-outcomes limits) outcomes))"
      "(when (> (%edit-outcomes edit) (%limits-outcomes limits))")
    ("manifest-active-transition" "manifest-fold.lisp"
      "(unless (eq changed closing)" "(unless (or changed closing)")
    ("manifest-last-removal" "manifest-decode.lisp"
      "(dotimes (i (%edit-removed-count edit))"
      "(dotimes (i (max 0 (1- (%edit-removed-count edit))))")
    ("manifest-next-increment" "manifest-fold.lisp"
      "(max previous-next (1+ maximum))" "(max previous-next maximum)")
    ("manifest-csn-zero-presence" "manifest-query.lisp"
      "(if present (values t csn) (values nil 0))"
      "(if (and present (not (zerop csn))) (values t csn) (values nil 0))")
    ("manifest-csn-high-word" "manifest-decode.lisp"
      "(csn (leggi-u64 buffer" "(csn (leggi-u32 buffer")))

(defparameter *io-mutants*
  '(("input-mutates-health" "types.lisp" "(unless (eq operation :read)" "(when (eq operation :read)")
    ("write-does-not-fault" "types.lisp" "(setf (file-state file) :faulted)"
                                       "(setf (file-state file) :open)")
    ("transfer-byte-budget" "transfer.lisp" "(> count (file-max-transfer file))"
                                          "(>= count (file-max-transfer file))")
    ("progress-and-or" "transfer.lisp" "(and (integerp result) (<= 1 result remaining))"
                                      "(or (integerp result) (<= 1 result remaining))")
    ("read-offset-advance" "transfer.lisp" "remaining (+ offset done))"
                                         "remaining offset)")
    ("write-position-advance" "transfer.lisp" "(incf (file-written file) progress)"
                                            "(incf (file-written file) 1)")
    ("file-byte-budget" "transfer.lisp" "(> count (- (file-max-file-bytes file) (file-written file)))"
                                       "(>= count (- (file-max-file-bytes file) (file-written file)))")
    ("close-state-after-error" "lifecycle.lisp" "(setf (file-state file) :closed)"
                                              "(setf (file-state file) :open)")
    ("flush-success-zero" "flush.lisp" "(unless (eql result 0)" "(when (eql result 0)")
    ("durable-frontier" "flush.lisp" "(setf (file-durable file) (file-written file))"
                                    "(setf (file-durable file) 0)")))

(defparameter *wal-mutants*
  '(("reserve-seal-space" "builder.lisp"
      "(+ +header-bytes+ (length key) (length value) +seal-total+)"
      "(+ +header-bytes+ (length key) (length value))")
    ("preserve-prepared-txid" "builder.lisp" "(not (logbitp 0 flags))" "(not (logbitp 1 flags))")
    ("cumulative-seal-crc" "builder.lisp"
      "(crc32c buffer pos (+ pos +header-crc-bytes+) checksum)"
      "(crc32c buffer pos (+ pos +header-crc-bytes+) 0)")
    ("historical-durable-frontier" "builder.lisp"
      "(scrivi-u64 seal +seal-durable-offset+ durable)"
      "(scrivi-u64 seal +seal-durable-offset+ file-start)")
    ("seal-record-count" "builder.lisp"
      "(scrivi-u32 seal +seal-count-offset+ (lotto-count lotto))"
      "(scrivi-u32 seal +seal-count-offset+ (1+ (lotto-count lotto)))")
    ("group-exact-byte-budget" "group.lisp"
      "(> (lotto-used lotto) (- (gruppo-max-bytes group) (gruppo-bytes group)))"
      "(>= (lotto-used lotto) (- (gruppo-max-bytes group) (gruppo-bytes group)))")
    ("group-format-identity" "group.lisp"
      "(= (lotto-version lotto) (log-io-version log))"
      "(<= (lotto-version lotto) (log-io-version log))")
    ("group-awaits-durability" "group.lisp"
      "(eq (lotto-state lotto) :durable)" "(member (lotto-state lotto) '(:written :durable))")
    ("log-acquire-once" "executor.lisp"
      "(sb-ext:compare-and-swap (log-io-active log) nil group)"
      "(sb-ext:compare-and-swap (log-io-active log) nil nil)")
    ("flush-claim-once" "executor.lisp"
      "(sb-ext:compare-and-swap (gruppo-state group) :written :flushing)"
      "(sb-ext:compare-and-swap (gruppo-state group) :written :written)")
    ("write-byte-frontier" "executor.lisp"
      "(= end (+ (lotto-start lotto) (lotto-used lotto)))"
      "(= end (+ (lotto-start lotto) (1+ (lotto-used lotto))))")
    ("log-faulted-after-error" "executor.lisp"
      "(log-io-state (gruppo-log group)) :faulted"
      "(log-io-state (gruppo-log group)) :open")))

(defun read-text (path)
  (uiop:read-file-string path :external-format :utf-8))

(defun substitute-first (text before after)
  (let ((pos (search before text)))
    (unless pos (error "foundation-mutation.lisp: mutazione non applicabile: ~S" before))
    (concatenate 'string (subseq text 0 pos) after (subseq text (+ pos (length before))))))

(defun copy-test-system (directory)
  (dolist (file (append '("arcdocdb.asd" "src/package.lisp" "tests/smoke.lisp" "tools/build.lisp")
                       (mapcar #'enough-namestring (directory "src/foundation/*.lisp"))
                       (mapcar #'enough-namestring (directory "tests/foundation/*.lisp"))
                       (mapcar #'enough-namestring (directory "src/storage/*.lisp"))
                       (mapcar #'enough-namestring (directory "tests/storage/*.lisp"))
                       (mapcar #'enough-namestring (directory "src/recovery/*.lisp"))
                       (mapcar #'enough-namestring (directory "tests/recovery/*.lisp"))
                       (mapcar #'enough-namestring (directory "src/io/*.lisp"))
                       (mapcar #'enough-namestring (directory "tests/io/*.lisp"))
                       (mapcar #'enough-namestring (directory "src/wal/*.lisp"))
                       (mapcar #'enough-namestring (directory "tests/wal/*.lisp"))))
    (let ((target (merge-pathnames file directory)))
      (ensure-directories-exist target)
      (uiop:copy-file file target))))

(defun detected-p (text exit)
  "Un errore prima dell'avvio dei test non conta come rilevamento."
  (and (not (zerop exit)) (search "ok    ARCDOCDB:*VERSION*" text)))

(defun decision-event-p (text marker)
  "Riconosce solo un evento a inizio riga, senza accettare citazioni nel backtrace."
  (loop for line in (uiop:split-string text :separator '(#\Newline))
        thereis (and (<= (length marker) (length line))
                     (string= marker line :end2 (length marker)))))

(defun dedicated-scope-p (scope)
  "DECISION e manifest richiedono i propri marker, oltre alla compilazione rigorosa."
  (member scope '("decisions" "manifest") :test #'string=))

(defun scope-token (scope)
  "Token stabile dei marker dei test dedicati."
  (if (string= scope "decisions") "decision" scope))

(defun scope-markers (scope)
  "Marker a inizio riga; lo smoke è conservato solo negli ambiti preesistenti."
  (if (dedicated-scope-p scope)
      (values (format nil "~A-test-start " (scope-token scope))
              (format nil "~A-tests-complete " (scope-token scope)))
      (values "ok    ARCDOCDB:*VERSION* è una stringa"
              "build e test: nessun avviso, tutti i controlli superati")))

(defun decision-result (text exit &optional (scope "decisions"))
  "Compilazione e guasti prima dei test dell'ambito non rilevano il mutante."
  (multiple-value-bind (started completed) (scope-markers scope)
    (cond ((or (search "compilation aborted" text :test #'char-equal)
               (search "COMPILE-FILE-ERROR" text :test #'char-equal)
               (search "COMPILE-FILE-WARNED" text :test #'char-equal)
               (search "non ammesso (COD-01)" text))
           :compilation-failure)
          ((and (integerp exit) (not (zerop exit)) (decision-event-p text completed))
           :worker-error)
          ((or (not (integerp exit))
               (not (decision-event-p text started))) :before-tests)
          ((not (zerop exit)) :detected)
          ((decision-event-p text completed) :survived)
          (t :before-tests))))

(defun decision-source-directory () "src/recovery/")

(defun validate-decision-mutants (&optional (mutants *decision-mutants*))
  "Ogni bersaglio dedicato esiste una volta e la sostituzione ne cambia il testo."
  (unless mutants (error "foundation-mutation.lisp: COD-60, nessun mutante selezionato."))
  (dolist (mutant mutants)
    (destructuring-bind (name file before after) mutant
      (let* ((source (read-text (merge-pathnames file (decision-source-directory))))
             (position (search before source)))
        (unless (and position (not (search before source :start2 (1+ position)))
                     (not (string= before after)))
          (error "foundation-mutation.lisp: COD-60, bersaglio assente/ambiguo: ~A" name)))))
  nil)

(defun dedicated-test-form (scope)
  "Seleziona solo DEFTEST caricati dei due file dedicati, con lettura priva di eval."
  `(let* ((*package* (or (find-package "ARCDOCDB.RECOVERY.TESTS")
                        (error "Harness recovery non caricato.")))
          (*read-eval* nil) (deftest (find-symbol "DEFTEST" *package*)) (tests nil))
     (dolist (file ',(if (string= scope "decisions")
                        '("tests/recovery/decisions.lisp" "tests/recovery/decisions-audit.lisp")
                        '("tests/recovery/manifest.lisp" "tests/recovery/manifest-audit.lisp")))
       (let ((selected 0))
         (with-open-file (input file :external-format :utf-8)
           (loop for form = (read input nil :eof) until (eq form :eof)
                 when (and (consp form) (eq (first form) deftest))
                   do (push (second form) tests) (incf selected)))
         (unless (plusp selected) (error "File senza test dedicati: ~A" file))))
     (unless (and tests (every #'fboundp tests))
       (error "Test dedicati non caricati dal sistema ASDF."))
     (setf tests (nreverse tests))
     (dolist (test tests)
       (format t ,(format nil "~~&~A-test-start ~~A~~%" (scope-token scope)) test)
       (finish-output) (funcall test) (format t "ok    ~A~%" test))
     (format t ,(format nil "~~&~A-tests-complete ~~D~~%" (scope-token scope)) (length tests))))

(defun write-decision-runner (directory &optional (scope "decisions"))
  "Cache privata e build rigorosa; test dedicati per manifest e DECISION."
  (let ((runner (merge-pathnames "tools/mutation-isolated-build.lisp" directory)))
    (with-open-file (stream runner :direction :output :if-exists :error)
      (dolist (form
               `((require :asdf)
                 (asdf:initialize-output-translations
                  '(:output-translations (,(namestring directory)
                                         ,(namestring (merge-pathnames "fasl/" directory)))
                                         :ignore-inherited-configuration))
                 ,@(if (not (dedicated-scope-p scope)) '((load "tools/build.lisp"))
                       `((setf asdf:*compile-file-failure-behaviour* :error
                       asdf:*compile-file-warnings-behaviour* :error)
                 (handler-bind
                     ((warning (lambda (condition)
                                 (unless (typep condition 'sb-kernel:redefinition-warning)
                                   (error "~A non ammesso (COD-01): ~A"
                                          (type-of condition) condition)))))
                   (asdf:load-asd (merge-pathnames "arcdocdb.asd" (truename "./")))
                   (asdf:load-system "arcdocdb" :force t)
                   (asdf:load-system "arcdocdb/tests" :force t))
                         ,(dedicated-test-form scope)))))
        (write form :stream stream :pretty t) (terpri stream)))
    runner))

(defun launch-copy (directory scope)
  "Avvia SBCL senza init con directory/log/cache privati; nessuna shell."
  (write-decision-runner directory scope)
  (uiop:launch-program '("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
                         "tools/mutation-isolated-build.lisp")
                       :directory directory :output (merge-pathnames "test.log" directory)
                       :error-output :output))

(defun execute-decisions (directory &optional (scope "decisions"))
  "Compila tutti i componenti e invoca solo i test dedicati; conserva il log."
  (let ((log (merge-pathnames "test.log" directory)))
    (let ((exit (uiop:wait-process (launch-copy directory scope))))
      (values (decision-result (read-text log) exit scope) exit log))))

(defun new-directory (name)
  "Directory esclusiva: prepara solo i genitori e rifiuta ogni destinazione esistente."
  (let* ((directory (merge-pathnames (uiop:ensure-directory-pathname name) (truename "./")))
         (parent (make-pathname :defaults directory
                               :directory (butlast (pathname-directory directory))
                               :name "segnaposto" :type nil)))
    (ensure-directories-exist parent)
    (sb-posix:mkdir directory #o700)
    directory))

(defun check-jobs (text)
  "Accetta solo la rappresentazione decimale di un numero di worker tra 1 e 4."
  (unless (and (stringp text) (plusp (length text))
               (every (lambda (char) (find char "0123456789")) text))
    (error "foundation-mutation.lisp: COD-61, --jobs richiede un intero 1..4."))
  (let ((jobs (parse-integer text)))
    (unless (<= 1 jobs 4)
      (error "foundation-mutation.lisp: COD-61, --jobs fuori intervallo 1..4: ~A" text))
    jobs))

(defun parse-options (args)
  "CLI storica più --jobs N; nessuna opzione duplicata, incompleta o sconosciuta."
  (let ((positional nil) (jobs 1) (seen-jobs nil))
    (loop while args do
      (let ((arg (pop args)))
        (if (string= arg "--jobs")
            (progn
              (when seen-jobs (error "foundation-mutation.lisp: COD-61, --jobs duplicato."))
              (setf seen-jobs t jobs (check-jobs (pop args))))
            (push arg positional))))
    (setf positional (nreverse positional))
    (cond ((equal positional '("--self-test")) (values :self-test nil "foundation" jobs))
          ((and (<= 2 (length positional) 3) (string= (first positional) "--run")
                (or (= (length positional) 2)
                    (member (third positional)
                            '("foundation" "storage" "recovery" "decisions" "manifest" "io" "wal")
                            :test #'string=)))
           (values :run (second positional) (or (third positional) "foundation") jobs))
          (t (error "foundation-mutation.lisp: COD-61, usare --self-test oppure --run directory-nuova/ [foundation|storage|recovery|decisions|manifest|io|wal] [--jobs 1..4].")))))

(defun worker-failure (task condition &optional exit)
  "I guasti di preparazione, avvio e raccolta non interrompono gli altri worker."
  (list :name (getf task :name) :result :worker-error :exit-code exit
        :diagnostic (princ-to-string condition)
        :log (namestring (merge-pathnames "test.log" (getf task :directory)))))

(defun parallel-results (tasks jobs launch collect)
  "Avvia al più JOBS processi per gruppo; attende tutti, risultati nell'ordine dei task."
  (unless (and (integerp jobs) (<= 1 jobs 4))
    (error "foundation-mutation.lisp: COD-61, numero di worker invalido: ~S" jobs))
  (let ((results (make-array (length tasks))))
    (loop for start from 0 below (length tasks) by jobs do
      (let ((active nil))
        (loop for index from start below (min (length tasks) (+ start jobs))
              for task = (nth index tasks) do
                (handler-case (push (list index task (funcall launch task)) active)
                  (error (condition) (setf (aref results index) (worker-failure task condition)))))
        (dolist (worker (nreverse active))
          (destructuring-bind (index task process) worker
            (let ((exit nil))
              (handler-case
                  (multiple-value-bind (code signal) (uiop:wait-process process)
                    (setf exit code)
                    (when signal (error "Worker terminato dal segnale ~D." signal))
                    (setf (aref results index) (funcall collect task exit)))
                (error (condition)
                  (setf (aref results index) (worker-failure task condition exit)))))))))
    (coerce results 'list)))

(defun launch-mutant (task)
  "Copia la baseline verificata, applica una sola mutazione e avvia un processo privato."
  (let* ((directory (getf task :directory)) (scope (getf task :scope))
         (source-scope (if (dedicated-scope-p scope) "recovery" scope)))
    (destructuring-bind (name file before after) (getf task :mutant)
      (declare (ignore name))
      (new-directory directory)
      (uiop:with-current-directory ((getf task :baseline-directory))
        (copy-test-system directory))
      (let* ((source (merge-pathnames file
                      (merge-pathnames (format nil "src/~A/" source-scope) directory)))
             (modified (substitute-first (read-text source) before after)))
        (with-open-file (stream source :direction :output :if-exists :supersede
                                      :external-format :utf-8)
          (write-string modified stream))))
    (launch-copy directory scope)))

(defun collect-mutant (task exit)
  "Classificazione runtime distinta da compilazione, pre-test ed errori worker."
  (let ((log (merge-pathnames "test.log" (getf task :directory))))
    (list :name (getf task :name) :result (decision-result (read-text log) exit (getf task :scope))
          :exit-code exit :log (namestring log))))

(defun save-campaign (report directory)
  "Conserva stato e risultati, compresi tutti i fallimenti, nella directory esclusiva."
  (with-open-file (stream (merge-pathnames "report.lisp" directory)
                          :direction :output :if-exists :supersede :external-format :utf-8)
    (write report :stream stream :pretty t) (terpri stream)))

(defun run-campaign (mutants directory scope jobs)
  "Baseline seriale prima di ogni worker; mutanti isolati e risultato finale deterministico."
  (let* ((directory (new-directory directory))
         (report (list :scope (intern (string-upcase scope) :keyword) :jobs jobs :status :running))
         (baseline-directory (merge-pathnames "baseline/" directory)))
    (when (dedicated-scope-p scope) (validate-decision-mutants mutants))
    (save-campaign report directory)
    (new-directory baseline-directory)
    (copy-test-system baseline-directory)
    (multiple-value-bind (result exit log) (execute-decisions baseline-directory scope)
      (setf (getf report :baseline) (if (eq result :survived) :passed result)
            (getf report :baseline-exit-code) exit (getf report :baseline-log) (namestring log))
      (unless (eq result :survived)
        (setf (getf report :status) :failed)
        (save-campaign report directory)
        (error "foundation-mutation.lisp: COD-61, baseline ~A: ~A; ~A" scope result log)))
    (save-campaign report directory)
    (let* ((tasks (loop for mutant in mutants for index from 0
                        collect (list :name (first mutant) :mutant mutant :scope scope
                                      :baseline-directory baseline-directory
                                      :directory (merge-pathnames (format nil "~D/" index) directory))))
           (results (parallel-results tasks jobs #'launch-mutant #'collect-mutant)))
      (setf (getf report :mutants) results)
      (loop for (key value) on '(:detected :detected :survived :survived
                                 :compilation-failures :compilation-failure
                                 :before-tests :before-tests :worker-errors :worker-error) by #'cddr
            do (setf (getf report key)
                     (count value results :key (lambda (result) (getf result :result)))))
      (setf (getf report :status) (if (= (length mutants) (getf report :detected)) :ok :failed))
      (save-campaign report directory)
      (write (if (dedicated-scope-p scope) report results) :pretty t) (terpri)
      (unless (eq (getf report :status) :ok)
        (error "foundation-mutation.lisp: COD-61, campagna ~A incompleta; ~A"
               scope (merge-pathnames "report.lisp" directory))))))

(defun expect-error (function)
  "Il self-test deve rilevare anche le configurazioni e i worker intenzionalmente invalidi."
  (let ((caught nil))
    (handler-case (funcall function) (error () (setf caught t)))
    (unless caught (error "foundation-mutation.lisp: COD-60, errore atteso non rilevato."))))

(defun classifier-self-test ()
  "Rifiuta marker nel backtrace, marker dell'altro ambito e guasti di compilazione."
  (dolist (scope '("decisions" "manifest"))
    (multiple-value-bind (start complete) (scope-markers scope)
      (let ((started (concatenate 'string start "TEST")))
        (unless (and (eq :detected (decision-result started 1 scope))
                     (eq :survived (decision-result (format nil "~A~%~A1~%" started complete) 0 scope))
                     (eq :worker-error
                         (decision-result (format nil "~A~%~A1~%" started complete) 1 scope))
                     (eq :before-tests (decision-result started 0 scope))
                     (eq :before-tests (decision-result started nil scope))
                     (eq :before-tests (decision-result "ok    ARCDOCDB:*VERSION*" 1 scope))
                     (eq :before-tests (decision-result (format nil "0: (FORMAT T ~S)" started) 1 scope))
                     (eq :before-tests (decision-result (format nil "prefix ~A" started) 1 scope))
                     (eq :before-tests (decision-result
                                         (format nil "~A~%0: (FORMAT T ~S)" started complete) 0 scope))
                     (eq :compilation-failure (decision-result "COMPILE-FILE-ERROR" 1 scope))
                     (eq :compilation-failure (decision-result
                                                 (format nil "~A~%compilation aborted" started) 1 scope)))
          (error "foundation-mutation.lisp: COD-60, classificazione ~A errata." scope)))))
  (unless (eq :before-tests (decision-result "decision-test-start TEST" 1 "manifest"))
    (error "foundation-mutation.lisp: COD-60, marker di un altro ambito accettato.")))

(defun configuration-self-test ()
  "CLI precedente conservata; default seriale, jobs limitati e argomenti malformati rifiutati."
  (unless (and (equal '(:run "out/" "foundation" 1)
                      (multiple-value-list (parse-options '("--run" "out/"))))
               (equal '(:run "out/" "manifest" 4)
                      (multiple-value-list (parse-options '("--run" "out/" "manifest" "--jobs" "4"))))
               (equal '(:run "out/" "decisions" 2)
                      (multiple-value-list (parse-options '("--jobs" "2" "--run" "out/" "decisions")))))
    (error "foundation-mutation.lisp: COD-60, parsing CLI errato."))
  (dolist (args '(nil ("--run") ("--run" "out/" "unknown")
                  ("--run" "out/" "--jobs") ("--run" "out/" "--jobs" "0")
                  ("--run" "out/" "--jobs" "5") ("--run" "out/" "--jobs" "-1")
                  ("--run" "out/" "--jobs" "1x") ("--run" "out/" "--jobs" "1.5")
                  ("--run" "out/" "--jobs" "2" "--jobs" "2")
                  ("--run" "out/" "manifest" "extra")))
    (expect-error (lambda () (parse-options args))))
  (expect-error (lambda () (parallel-results nil 5 #'identity #'identity))))

(defun write-worker-fixture (directory)
  "Il primo worker attende il segnale del secondo: un avvio seriale fallirebbe il test."
  (let ((source (merge-pathnames "worker-fixture.lisp" directory)))
    (with-open-file (stream source :direction :output :if-exists :error)
      (write '(let* ((args (rest sb-ext:*posix-argv*)) (mode (first args))
                    (release (merge-pathnames "release" (second args))))
                (cond ((string= mode "waiting")
                       (loop repeat 500 until (probe-file release) do (sleep 0.01))
                       (sb-ext:exit :code (if (probe-file release) 0 11)))
                      ((string= mode "failing")
                       (with-open-file (output release :direction :output :if-exists :error)
                         (write-line "rilasciato" output))
                       (format t "worker-fixture-failure~%")
                       (sb-ext:exit :code 7))
                      (t (sb-ext:exit :code 0)))) :stream stream :pretty t))
    source))

(defun parallel-self-test ()
  "Verifica avvio concorrente, exit nonzero, guasti di avvio/raccolta e ordine stabile."
  (let* ((directory (new-directory
                      (format nil "spikes/out/~D-mutation-self-test-~D/"
                              (get-universal-time) (sb-posix:getpid))))
         (source (write-worker-fixture directory))
         (tasks (loop for name in '("waiting" "failing" "launch-error" "collect-error")
                      for index from 0
                      collect (list :name name :directory
                                    (new-directory (merge-pathnames (format nil "~D/" index) directory)))))
         (results
           (parallel-results tasks 2
             (lambda (task)
               (when (string= (getf task :name) "launch-error") (error "Guasto avvio fixture."))
               (uiop:launch-program
                 (list "sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
                       (namestring source) (getf task :name) (namestring directory))
                 :output (merge-pathnames "test.log" (getf task :directory)) :error-output :output))
             (lambda (task exit)
               (when (string= (getf task :name) "collect-error") (error "Guasto raccolta fixture."))
               (list :name (getf task :name) :result (if (zerop exit) :detected :worker-error)
                     :exit-code exit)))))
    (save-campaign (list :kind :parallel-self-test :jobs 2 :results results) directory)
    (unless (and (equal '("waiting" "failing" "launch-error" "collect-error")
                        (mapcar (lambda (result) (getf result :name)) results))
                 (equal '(:detected :worker-error :worker-error :worker-error)
                        (mapcar (lambda (result) (getf result :result)) results))
                 (= 0 (getf (first results) :exit-code)) (= 7 (getf (second results) :exit-code)))
      (error "foundation-mutation.lisp: COD-60, worker concorrenti o fallimenti non rilevati; ~A"
             directory))
    (format t "Worker: concorrenza, fallimenti e ordine verificati; ~A~%" directory)))

(defun self-test ()
  "Sostituzione, classificazioni, CLI, concorrenza e fallimenti worker sono verificati."
  (unless (and (string= "xAxB" (substitute-first "xBxB" "B" "A"))
               (detected-p "ok    ARCDOCDB:*VERSION*" 1)
               (not (detected-p "ok    ARCDOCDB:*VERSION*" 0))
               (not (detected-p "compilation aborted" 1)))
    (error "foundation-mutation.lisp: COD-60, sostituzione o classificazione errata."))
  (classifier-self-test)
  (configuration-self-test)
  (validate-decision-mutants)
  (validate-decision-mutants *manifest-mutants*)
  (parallel-self-test)
  (format t "Mutazioni: self-test superato.~%"))

(defun scope-mutants (scope)
  "Selezione esplicita delle campagne supportate."
  (cond ((string= scope "foundation") *mutants*)
        ((string= scope "storage") *storage-mutants*)
        ((string= scope "recovery") *recovery-mutants*)
        ((string= scope "decisions") *decision-mutants*)
        ((string= scope "manifest") *manifest-mutants*)
        ((string= scope "io") *io-mutants*)
        ((string= scope "wal") *wal-mutants*)
        (t (error "foundation-mutation.lisp: COD-61, ambito non supportato: ~A" scope))))

(multiple-value-bind (mode directory scope jobs) (parse-options (rest sb-ext:*posix-argv*))
  (if (eq mode :self-test) (self-test) (run-campaign (scope-mutants scope) directory scope jobs)))
