;;;; Mutazioni mirate in copie isolate; nessun sorgente del repository viene riscritto.
;;;; Uso: --run directory-nuova/ [foundation|storage|recovery|decisions|io|wal] oppure --self-test
;;;; REQ: REQ-FOR-003 REQ-FOR-004 REQ-AFF-002 REQ-LIM-001 REQ-LIM-003 REQ-VAL-001
(require :asdf)
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

(defun decision-result (text exit)
  "Compilazione e guasti prima dei test DECISION non rilevano il mutante."
  (cond ((or (search "compilation aborted" text :test #'char-equal)
             (search "COMPILE-FILE-ERROR" text :test #'char-equal)
             (search "COMPILE-FILE-WARNED" text :test #'char-equal)
             (search "non ammesso (COD-01)" text))
         :compilation-failure)
        ((or (not (integerp exit))
             (not (decision-event-p text "decision-test-start "))) :before-tests)
        ((not (zerop exit)) :detected)
        ((decision-event-p text "decision-tests-complete ") :survived)
        (t :before-tests)))

(defun decision-source-directory () "src/recovery/")

(defun validate-decision-mutants ()
  "Ogni bersaglio DECISION esiste una volta e la sostituzione ne cambia il testo."
  (dolist (mutant *decision-mutants*)
    (destructuring-bind (name file before after) mutant
      (let* ((source (read-text (merge-pathnames file (decision-source-directory))))
             (position (search before source)))
        (unless (and position (not (search before source :start2 (1+ position)))
                     (not (string= before after)))
          (error "foundation-mutation.lisp: COD-60, bersaglio DECISION assente/ambiguo: ~A" name)))))
  nil)

(defun write-decision-runner (directory)
  "Runner rigoroso con cache privata; seleziona i test dai due file DECISION caricati."
  (let ((runner (merge-pathnames "tools/decisions-isolated-build.lisp" directory)))
    (with-open-file (stream runner :direction :output :if-exists :error)
      (dolist (form
               `((require :asdf)
                 (asdf:initialize-output-translations
                  '(:output-translations (,(namestring directory)
                                         ,(namestring (merge-pathnames "fasl/" directory)))
                                         :ignore-inherited-configuration))
                 (setf asdf:*compile-file-failure-behaviour* :error
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
                        (*read-eval* nil)
                        (deftest (find-symbol "DEFTEST" *package*))
                        (tests nil))
                   (dolist (file '("tests/recovery/decisions.lisp"
                                   "tests/recovery/decisions-audit.lisp"))
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
                     (format t "~&decision-test-start ~A~%" test)
                     (finish-output)
                     (funcall test)
                     (format t "ok    ~A~%" test))
                   (format t "~&decision-tests-complete ~D~%" (length tests)))))
        (write form :stream stream :pretty t) (terpri stream)))
    runner))

(defun execute-decisions (directory)
  "Compila tutti i componenti e invoca solo i test dedicati; conserva il log."
  (let ((log (merge-pathnames "test.log" directory)))
    (write-decision-runner directory)
    (multiple-value-bind (out err exit)
        (uiop:run-program '("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
                            "tools/decisions-isolated-build.lisp")
                          :directory directory :output log :error-output :output
                          :ignore-error-status t)
      (declare (ignore out err))
      (values (decision-result (read-text log) exit) exit log))))

(defun run-decision-mutant (mutant directory)
  "Ogni esito viene conservato; i mutanti non compilabili restano separati."
  (destructuring-bind (name file before after) mutant
    (copy-test-system directory)
    (let ((source (merge-pathnames file
                   (merge-pathnames (decision-source-directory) directory))))
      (let ((modified (substitute-first (read-text source) before after)))
        (with-open-file (stream source :direction :output :if-exists :supersede
                                      :external-format :utf-8)
          (write-string modified stream))))
    (multiple-value-bind (result exit log) (execute-decisions directory)
      (list :name name :result result :exit-code exit :log (namestring log)))))

(defun run-decision-campaign (directory)
  "La baseline deve passare; tutti i mutanti sono eseguiti e il riepilogo è salvato."
  (validate-decision-mutants)
  (let ((baseline-directory (merge-pathnames "baseline/" directory)))
    (copy-test-system baseline-directory)
    (multiple-value-bind (result exit log) (execute-decisions baseline-directory)
      (unless (eq result :survived)
        (error "foundation-mutation.lisp: COD-61, baseline DECISION ~A, exit ~A; ~A"
               result exit log))))
  (let* ((results (loop for mutant in *decision-mutants* for i from 0
                        collect (run-decision-mutant mutant
                                  (merge-pathnames (format nil "~D/" i) directory))))
         (report (list :scope :decisions :baseline :passed :mutants results
                       :detected (count :detected results :key (lambda (result) (getf result :result)))
                       :survived (count :survived results :key (lambda (result) (getf result :result)))
                       :compilation-failures
                       (count :compilation-failure results :key (lambda (result) (getf result :result)))
                       :before-tests (count :before-tests results
                                            :key (lambda (result) (getf result :result))))))
    (with-open-file (stream (merge-pathnames "report.lisp" directory)
                            :direction :output :if-exists :error :external-format :utf-8)
      (write report :stream stream :pretty t) (terpri stream))
    (write report :pretty t) (terpri)
    (unless (= (length results) (getf report :detected))
      (error "foundation-mutation.lisp: COD-61, campagna DECISION incompleta; ~A"
             (merge-pathnames "report.lisp" directory)))))

(defun run-mutant (mutant directory scope)
  (destructuring-bind (name file before after) mutant
    (let* ((path (merge-pathnames (format nil "src/~A/" scope) directory))
           (source (merge-pathnames file path)) (log (merge-pathnames "test.log" directory)))
      (copy-test-system directory)
      (let ((modified (substitute-first (read-text source) before after)))
        (with-open-file (stream source :direction :output :if-exists :supersede)
          (write-string modified stream)))
      (multiple-value-bind (out err exit)
          (uiop:run-program '("sbcl" "--noinform" "--no-userinit" "--script" "tools/build.lisp")
                            :directory directory :output log :error-output :output
                            :ignore-error-status t)
        (declare (ignore out err))
        (let* ((text (read-text log))
               (detected (detected-p text exit)))
          (unless detected
            (error "foundation-mutation.lisp: COD-61, ~A sopravvissuto o non compilabile; ~A" name log))
          (list :name name :result :detected :exit-code exit))))))

(let ((args (rest sb-ext:*posix-argv*)))
  (cond ((equal args '("--self-test"))
         (unless (and (string= "xAxB" (substitute-first "xBxB" "B" "A"))
                      (detected-p "ok    ARCDOCDB:*VERSION*" 1)
                      (not (detected-p "ok    ARCDOCDB:*VERSION*" 0))
                      (not (detected-p "compilation aborted" 1)))
           (error "foundation-mutation.lisp: COD-60, sostituzione o classificazione errata."))
         (unless (and (eq :detected (decision-result "decision-test-start TEST" 1))
                      (eq :survived (decision-result
                                      (format nil "decision-test-start TEST~%decision-tests-complete 1~%")
                                      0))
                      (eq :before-tests (decision-result "ok    ARCDOCDB:*VERSION*" 1))
                      (eq :before-tests (decision-result "decision-test-start TEST" 0))
                      (eq :before-tests (decision-result "decision-test-start TEST" nil))
                      (eq :before-tests
                          (decision-result
                            "6: (SB-C::%COMPILE-IN-LEXENV
 (LET* ((TESTS (ERROR \"Harness recovery non caricato.\")))
   (FORMAT T \"~&decision-test-start ~A~%\" TEST)
   (FORMAT T \"~&decision-tests-complete ~D~%\" (LENGTH TESTS))))" 1))
                      (eq :before-tests
                          (decision-result "prefix decision-test-start TEST" 1))
                      (eq :before-tests
                          (decision-result
                            (format nil "decision-test-start TEST~%6: (FORMAT T \"decision-tests-complete 1\")~%")
                            0))
                      (eq :compilation-failure (decision-result "COMPILE-FILE-ERROR" 1))
                      (eq :compilation-failure (decision-result
                                                 "decision-test-start TEST compilation aborted" 1)))
           (error "foundation-mutation.lisp: COD-60, classificazione DECISION errata."))
         (validate-decision-mutants)
         (format t "Mutazioni: self-test superato.~%"))
        ((and (<= 2 (length args) 3) (string= (first args) "--run")
              (or (= (length args) 2)
                  (member (third args) '("foundation" "storage" "recovery" "decisions" "io" "wal") :test #'string=)))
         (let ((directory (uiop:ensure-directory-pathname (second args)))
               (scope (or (third args) "foundation")))
           (when (probe-file directory)
             (error "foundation-mutation.lisp: destinazione già presente: ~A" directory))
           (ensure-directories-exist directory)
           (if (string= scope "decisions")
               (run-decision-campaign (merge-pathnames directory (truename "./")))
               (progn
                 (write (loop for mutant in (cond ((string= scope "storage") *storage-mutants*)
                                                 ((string= scope "recovery") *recovery-mutants*)
                                                 ((string= scope "io") *io-mutants*)
                                                 ((string= scope "wal") *wal-mutants*)
                                                 (t *mutants*))
                              for i from 0 collect (run-mutant mutant
                                                     (merge-pathnames (format nil "~D/" i) directory)
                                                     scope))
                        :pretty t)
                 (terpri)))))
        (t (error "foundation-mutation.lisp: usare --self-test o --run directory-nuova/ [foundation|storage|recovery|decisions|io|wal]."))))
