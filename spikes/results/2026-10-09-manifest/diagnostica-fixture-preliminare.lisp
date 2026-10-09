(:SCHEMA-VERSION 1 :KIND :DEVELOPMENT-DIAGNOSTIC :DATE "2026-10-09" :PROVENANCE
 :REPORTED-BY-TEST-AUTHOR :CWD
 "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/" :ATTEMPTS
 ((:COMMAND
   ("sbcl" "--noinform" "--non-interactive" "--eval" "(require :asdf)" "--eval"
    "(asdf:load-asd (truename \"arcdocdb.asd\"))" "--eval"
    "(asdf:load-system \"arcdocdb/tests\")" "--eval"
    "(load \"src/recovery/manifest-package.lisp\")" "--eval"
    "(let ((*read-eval* nil)) (dolist (name (quote (\"manifest-support\" \"manifest\" \"manifest-audit\"))) (with-open-file (in (concatenate (quote string) \"tests/recovery/\" name \".lisp\")) (loop for form = (read in nil :eof) until (eq form :eof) count form into n finally (format t \"~A: ~D forms~%\" name n)))))"
    "--eval" "(describe (symbol-function (quote sb-thread:signal-semaphore)))"
    "--eval" "(describe (symbol-function (quote sb-thread:join-thread)))")
   :OBSERVED-EXIT-CODE 1 :OUTPUT-EXCERPT
   "Unhandled SB-INT:SIMPLE-FILE-ERROR ... Failed to find the TRUENAME of /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/src/recovery/manifest-fold.lisp: No such file or directory."
   :CAUSE :INCOMPLETE-SOURCE-WRITE-BEFORE-FREEZE)
  (:COMMAND
   ("sbcl" "--noinform" "--non-interactive" "--load"
    "src/foundation/package.lisp" "--load" "src/storage/package.lisp" "--load"
    "src/recovery/package.lisp" "--load" "src/recovery/manifest-package.lisp"
    "--eval"
    "(let ((*read-eval* nil)) (dolist (name (quote (\"manifest-support\" \"manifest\" \"manifest-audit\"))) (with-open-file (in (concatenate (quote string) \"tests/recovery/\" name \".lisp\")) (loop for form = (read in nil :eof) until (eq form :eof) count form into n finally (format t \"~A: ~D forms~%\" name n)))))"
    "--eval" "(describe (symbol-function (quote sb-thread:signal-semaphore)))"
    "--eval" "(describe (symbol-function (quote sb-thread:join-thread)))")
   :OBSERVED-EXIT-CODE 1 :OUTPUT-EXCERPT
   "While evaluating the form starting at line 3, column 0 of #P\"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/src/recovery/package.lisp\": Unhandled SB-KERNEL:SIMPLE-PACKAGE-ERROR ... no symbol named \"+SEAL-BYTES+\" in \"ARCDOCDB.RECORD\"."
   :CAUSE :PARTIAL-PACKAGE-LOAD-MISSING-RECORD-BATCH)
  (:COMMAND
   ("sbcl" "--noinform" "--non-interactive" "--eval"
    "(dolist (file (quote (\"src/foundation/package.lisp\" \"src/foundation/conditions.lisp\" \"src/foundation/binary.lisp\" \"src/foundation/crc32c.lisp\" \"src/foundation/record.lisp\" \"src/foundation/batch.lisp\" \"src/storage/package.lisp\" \"src/storage/formats.lisp\" \"src/recovery/package.lisp\" \"src/recovery/manifest-package.lisp\"))) (load file))"
    "--eval"
    "(let ((*read-eval* nil)) (dolist (name (quote (\"manifest-support\" \"manifest\" \"manifest-audit\"))) (with-open-file (in (concatenate (quote string) \"tests/recovery/\" name \".lisp\")) (loop for form = (read in nil :eof) until (eq form :eof) count form into n finally (format t \"~A: ~D forms~%\" name n)))))"
    "--eval" "(describe (symbol-function (quote sb-thread:signal-semaphore)))"
    "--eval" "(describe (symbol-function (quote sb-thread:join-thread)))")
   :OBSERVED-EXIT-CODE 1 :OUTPUT-EXCERPT
   "manifest-support: 13 forms / manifest: 11 forms / Unhandled SB-INT:SIMPLE-READER-ERROR ... unmatched close parenthesis / Line: 16, Column: 84, File-Position: 936 / Stream: #<SB-SYS:FD-STREAM for \"file /Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/tests/recovery/manifest-audit.lisp\" ...>."
   :CAUSE :FIXTURE-PARENTHESIS-FIXED))
 :FULL-STDOUT :NOT-COLLECTED :FULL-STDERR :NOT-COLLECTED :ENVIRONMENT
 :NOT-COLLECTED :SOURCE-BLOBS :NOT-COLLECTED :TIMINGS :NOT-COLLECTED :LIMITS
 (:NOT-FULL-COMMAND-RECORD :BEFORE-FREEZE :NO-PRODUCT-FAILURE-INFERRED))
