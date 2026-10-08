;;;; Mutazioni mirate in copie isolate; nessun sorgente del repository viene riscritto.
;;;; Uso: --run directory-nuova/ oppure --self-test
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

(defun read-text (path)
  (uiop:read-file-string path :external-format :utf-8))

(defun substitute-first (text before after)
  (let ((pos (search before text)))
    (unless pos (error "foundation-mutation.lisp: mutazione non applicabile: ~S" before))
    (concatenate 'string (subseq text 0 pos) after (subseq text (+ pos (length before))))))

(defun copy-foundations (directory)
  (dolist (file (append '("arcdocdb.asd" "src/package.lisp" "tests/smoke.lisp" "tools/build.lisp")
                       (mapcar #'enough-namestring (directory "src/foundation/*.lisp"))
                       (mapcar #'enough-namestring (directory "tests/foundation/*.lisp"))))
    (let ((target (merge-pathnames file directory)))
      (ensure-directories-exist target)
      (uiop:copy-file file target))))

(defun run-mutant (mutant directory)
  (destructuring-bind (name file before after) mutant
    (let* ((path (merge-pathnames "src/foundation/" directory))
           (source (merge-pathnames file path)) (log (merge-pathnames "test.log" directory)))
      (copy-foundations directory)
      (let ((modified (substitute-first (read-text source) before after)))
        (with-open-file (stream source :direction :output :if-exists :supersede)
          (write-string modified stream)))
      (multiple-value-bind (out err exit)
          (uiop:run-program '("sbcl" "--noinform" "--no-userinit" "--script" "tools/build.lisp")
                            :directory directory :output log :error-output :output
                            :ignore-error-status t)
        (declare (ignore out err))
        (let* ((text (read-text log))
               (detected (and (not (zerop exit)) (search "ok    ARCDOCDB:*VERSION*" text))))
          (unless detected
            (error "foundation-mutation.lisp: COD-61, ~A sopravvissuto o non compilabile; ~A" name log))
          (list :name name :result :detected :exit-code exit))))))

(let ((args (rest sb-ext:*posix-argv*)))
  (cond ((equal args '("--self-test"))
         (unless (string= "xAxB" (substitute-first "xBxB" "B" "A"))
           (error "foundation-mutation.lisp: COD-60, sostituzione errata."))
         (format t "Mutazioni: self-test superato.~%"))
        ((and (= (length args) 2) (string= (first args) "--run"))
         (let ((directory (uiop:ensure-directory-pathname (second args))))
           (when (probe-file directory)
             (error "foundation-mutation.lisp: destinazione già presente: ~A" directory))
           (ensure-directories-exist directory)
           (write (loop for mutant in *mutants* for i from 0
                        collect (run-mutant mutant (merge-pathnames (format nil "~D/" i) directory)))
                  :pretty t)
           (terpri)))
        (t (error "foundation-mutation.lisp: usare --self-test o --run directory-nuova/."))))
