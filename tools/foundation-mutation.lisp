;;;; Mutazioni mirate in copie isolate; nessun sorgente del repository viene riscritto.
;;;; Uso: --run directory-nuova/ [foundation|storage|recovery|io] oppure --self-test
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
                       (mapcar #'enough-namestring (directory "tests/io/*.lisp"))))
    (let ((target (merge-pathnames file directory)))
      (ensure-directories-exist target)
      (uiop:copy-file file target))))

(defun detected-p (text exit)
  "Un errore prima dell'avvio dei test non conta come rilevamento."
  (and (not (zerop exit)) (search "ok    ARCDOCDB:*VERSION*" text)))

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
         (format t "Mutazioni: self-test superato.~%"))
        ((and (<= 2 (length args) 3) (string= (first args) "--run")
              (or (= (length args) 2)
                  (member (third args) '("foundation" "storage" "recovery" "io") :test #'string=)))
         (let ((directory (uiop:ensure-directory-pathname (second args)))
               (scope (or (third args) "foundation")))
           (when (probe-file directory)
             (error "foundation-mutation.lisp: destinazione già presente: ~A" directory))
           (ensure-directories-exist directory)
           (write (loop for mutant in (cond ((string= scope "storage") *storage-mutants*)
                                           ((string= scope "recovery") *recovery-mutants*)
                                           ((string= scope "io") *io-mutants*)
                                           (t *mutants*))
                        for i from 0 collect (run-mutant mutant
                                               (merge-pathnames (format nil "~D/" i) directory) scope))
                  :pretty t)
           (terpri)))
        (t (error "foundation-mutation.lisp: usare --self-test o --run directory-nuova/ [foundation|storage|recovery|io]."))))
