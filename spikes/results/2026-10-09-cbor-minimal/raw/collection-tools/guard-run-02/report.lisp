(:RAW-TICKS 20938073 :FINISHED-AT-UNIVERSAL-TIME 4000547442 :SOURCE-CONSISTENCY
 :STABLE :SOURCE-FINGERPRINTS-AFTER
 ((:PATH "spikes/out/cbor-minimal-collection/collect.lisp" :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH "spikes/out/cbor-minimal-collection/guard.lisp" :BYTES 22280 :SHA256
   "d12bcd9cae36a02068be3519ecc53ad5007e3159305effa7d258fce58a487494")
  (:PATH "tools/evidence-storage.lisp" :BYTES 21261 :SHA256
   "8f287772a41b1ebe0e7b3ecc3826a4148082efed428a9749655977e62a9c15a6"))
 :CASE-COUNT 8 :OUTPUT-DIRECTORY
 #A((110) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/")
 :SCHEMA-VERSION 1 :KIND :CBOR-MINIMAL-COLLECTION-GUARD :STATUS :OK :CASES
 ((:NAME :COLLECT-PRESERVES-PLAIN-AND-TWO-GZIP-FIXTURES :STATUS :OK :INVOCATION
   "collect-positive" :ORIGINAL-FILES-CHECKED 14 :BYTE-AND-SHA256-MATCH T
   :PROCESS-AND-FILTERED-TREE-GZIP-READABLE T)
  (:NAME :CLI-AUDIT-POSITIVE :STATUS :OK :INVOCATION "audit-positive")
  (:NAME :EXISTING-TARGET-REJECTED :STATUS :OK :INVOCATION "existing-target"
   :ORIGINAL-ARCHIVE-UNCHANGED T)
  (:NAME :DUPLICATE-DESTINATION-PATH-REJECTED :STATUS :OK :INVOCATION
   "duplicate-path" :GUARD :EXCLUSIVE-COPY-TARGET)
  (:NAME :MISSING-GZIP-RAW-AUDIT-REJECTED :STATUS :OK :INVOCATION "missing-raw"
   :ORIGINAL-BYTE-COPY-KEPT-AT
   #A((169) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/processes/compressed/report.lisp.gz.missing"))
  (:NAME :CORRUPTED-GZIP-RAW-AUDIT-REJECTED :STATUS :OK :INVOCATION
   "corrupted-raw" :CORRUPTION :ONE-BIT-SAME-SIZE)
  (:NAME :READER-EVAL-MANIFEST-REJECTED :STATUS :OK :INVOCATION "reader-eval"
   :SIDE-EFFECT-SENTINEL-ABSENT T)
  (:NAME :TRAILING-MANIFEST-FORM-REJECTED :STATUS :OK :INVOCATION
   "trailing-form"))
 :INVOCATIONS
 ((:LABEL "gzip-process" :PROGRAM "gzip" :ARGUMENTS
   ("-n" "-c"
    #A((143) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/compressed/original.lisp"))
   :EXIT-CODE 0 :PROCESS-STATUS :EXITED :DIAGNOSTIC NIL :TIMEOUT-SECONDS 30
   :STARTED-AT-UNIVERSAL-TIME 4000547421 :FINISHED-AT-UNIVERSAL-TIME 4000547421
   :RAW-TICKS 46789 :STDOUT-FILE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/compressed/report.lisp.gz")
   :STDERR-FILE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/gzip-process.stderr.log")
   :STDOUT-FORMAT :BINARY :LOGS-ORIGINAL-BYTE-STREAMS T)
  (:LABEL "gzip-tree" :PROGRAM "gzip" :ARGUMENTS
   ("-n" "-c"
    #A((137) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/original.lisp"))
   :EXIT-CODE 0 :PROCESS-STATUS :EXITED :DIAGNOSTIC NIL :TIMEOUT-SECONDS 30
   :STARTED-AT-UNIVERSAL-TIME 4000547421 :FINISHED-AT-UNIVERSAL-TIME 4000547421
   :RAW-TICKS 43945 :STDOUT-FILE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/report.lisp.gz")
   :STDERR-FILE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/gzip-tree.stderr.log")
   :STDOUT-FORMAT :BINARY :LOGS-ORIGINAL-BYTE-STREAMS T)
  (:LABEL "collect-positive" :PROGRAM "sbcl" :ARGUMENTS
   ("--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger" "--script"
    "spikes/out/cbor-minimal-collection/collect.lisp" "--collect"
    #A((123) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/manifest.lisp")
    #A((127) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/"))
   :EXIT-CODE 0 :PROCESS-STATUS :EXITED :DIAGNOSTIC NIL :TIMEOUT-SECONDS 30
   :STARTED-AT-UNIVERSAL-TIME 4000547422 :FINISHED-AT-UNIVERSAL-TIME 4000547425
   :RAW-TICKS 3436473 :STDOUT-FILE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/collect-positive.stdout.log")
   :STDERR-FILE
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/collect-positive.stderr.log")
   :STDOUT-FORMAT :UTF-8 :LOGS-ORIGINAL-BYTE-STREAMS T)
  (:LABEL "audit-positive" :PROGRAM "sbcl" :ARGUMENTS
   ("--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger" "--script"
    "spikes/out/cbor-minimal-collection/collect.lisp" "--audit"
    #A((127) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/"))
   :EXIT-CODE 0 :PROCESS-STATUS :EXITED :DIAGNOSTIC NIL :TIMEOUT-SECONDS 30
   :STARTED-AT-UNIVERSAL-TIME 4000547428 :FINISHED-AT-UNIVERSAL-TIME 4000547430
   :RAW-TICKS 1374332 :STDOUT-FILE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/audit-positive.stdout.log")
   :STDERR-FILE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/audit-positive.stderr.log")
   :STDOUT-FORMAT :UTF-8 :LOGS-ORIGINAL-BYTE-STREAMS T)
  (:LABEL "existing-target" :PROGRAM "sbcl" :ARGUMENTS
   ("--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger" "--script"
    "spikes/out/cbor-minimal-collection/collect.lisp" "--collect"
    #A((123) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/manifest.lisp")
    #A((127) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-positive/"))
   :EXIT-CODE 1 :PROCESS-STATUS :EXITED :DIAGNOSTIC NIL :TIMEOUT-SECONDS 30
   :STARTED-AT-UNIVERSAL-TIME 4000547431 :FINISHED-AT-UNIVERSAL-TIME 4000547431
   :RAW-TICKS 365480 :STDOUT-FILE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/existing-target.stdout.log")
   :STDERR-FILE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/existing-target.stderr.log")
   :STDOUT-FORMAT :UTF-8 :LOGS-ORIGINAL-BYTE-STREAMS T)
  (:LABEL "duplicate-path" :PROGRAM "sbcl" :ARGUMENTS
   ("--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger" "--script"
    "spikes/out/cbor-minimal-collection/collect.lisp" "--collect"
    #A((133) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/duplicate-manifest.lisp")
    #A((128) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-duplicate/"))
   :EXIT-CODE 1 :PROCESS-STATUS :EXITED :DIAGNOSTIC NIL :TIMEOUT-SECONDS 30
   :STARTED-AT-UNIVERSAL-TIME 4000547432 :FINISHED-AT-UNIVERSAL-TIME 4000547435
   :RAW-TICKS 3020415 :STDOUT-FILE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/duplicate-path.stdout.log")
   :STDERR-FILE
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/duplicate-path.stderr.log")
   :STDOUT-FORMAT :UTF-8 :LOGS-ORIGINAL-BYTE-STREAMS T)
  (:LABEL "missing-raw" :PROGRAM "sbcl" :ARGUMENTS
   ("--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger" "--script"
    "spikes/out/cbor-minimal-collection/collect.lisp" "--audit"
    #A((126) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-missing/"))
   :EXIT-CODE 1 :PROCESS-STATUS :EXITED :DIAGNOSTIC NIL :TIMEOUT-SECONDS 30
   :STARTED-AT-UNIVERSAL-TIME 4000547437 :FINISHED-AT-UNIVERSAL-TIME 4000547438
   :RAW-TICKS 679996 :STDOUT-FILE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/missing-raw.stdout.log")
   :STDERR-FILE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/missing-raw.stderr.log")
   :STDOUT-FORMAT :UTF-8 :LOGS-ORIGINAL-BYTE-STREAMS T)
  (:LABEL "corrupted-raw" :PROGRAM "sbcl" :ARGUMENTS
   ("--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger" "--script"
    "spikes/out/cbor-minimal-collection/collect.lisp" "--audit"
    #A((126) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-corrupt/"))
   :EXIT-CODE 1 :PROCESS-STATUS :EXITED :DIAGNOSTIC NIL :TIMEOUT-SECONDS 30
   :STARTED-AT-UNIVERSAL-TIME 4000547440 :FINISHED-AT-UNIVERSAL-TIME 4000547441
   :RAW-TICKS 1300084 :STDOUT-FILE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/corrupted-raw.stdout.log")
   :STDERR-FILE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/corrupted-raw.stderr.log")
   :STDOUT-FORMAT :UTF-8 :LOGS-ORIGINAL-BYTE-STREAMS T)
  (:LABEL "reader-eval" :PROGRAM "sbcl" :ARGUMENTS
   ("--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger" "--script"
    "spikes/out/cbor-minimal-collection/collect.lisp" "--collect"
    #A((135) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/reader-eval-manifest.lisp")
    #A((130) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-reader-eval/"))
   :EXIT-CODE 1 :PROCESS-STATUS :EXITED :DIAGNOSTIC NIL :TIMEOUT-SECONDS 30
   :STARTED-AT-UNIVERSAL-TIME 4000547441 :FINISHED-AT-UNIVERSAL-TIME 4000547441
   :RAW-TICKS 357591 :STDOUT-FILE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/reader-eval.stdout.log")
   :STDERR-FILE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/reader-eval.stderr.log")
   :STDOUT-FORMAT :UTF-8 :LOGS-ORIGINAL-BYTE-STREAMS T)
  (:LABEL "trailing-form" :PROGRAM "sbcl" :ARGUMENTS
   ("--noinform" "--no-userinit" "--no-sysinit" "--disable-debugger" "--script"
    "spikes/out/cbor-minimal-collection/collect.lisp" "--collect"
    #A((132) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/trailing-manifest.lisp")
    #A((127) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/archive-trailing/"))
   :EXIT-CODE 1 :PROCESS-STATUS :EXITED :DIAGNOSTIC NIL :TIMEOUT-SECONDS 30
   :STARTED-AT-UNIVERSAL-TIME 4000547441 :FINISHED-AT-UNIVERSAL-TIME 4000547442
   :RAW-TICKS 356558 :STDOUT-FILE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/trailing-form.stdout.log")
   :STDERR-FILE
   #A((139) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/logs/trailing-form.stderr.log")
   :STDOUT-FORMAT :UTF-8 :LOGS-ORIGINAL-BYTE-STREAMS T))
 :FORMATS NIL :ARGV
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  #A((11) BASE-CHAR . "--self-test")
  #A((48) BASE-CHAR . "spikes/out/cbor-minimal-collection/guard-run-02/"))
 :SOURCE-FINGERPRINTS-BEFORE
 ((:PATH "spikes/out/cbor-minimal-collection/collect.lisp" :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH "spikes/out/cbor-minimal-collection/guard.lisp" :BYTES 22280 :SHA256
   "d12bcd9cae36a02068be3519ecc53ad5007e3159305effa7d258fce58a487494")
  (:PATH "tools/evidence-storage.lisp" :BYTES 21261 :SHA256
   "8f287772a41b1ebe0e7b3ecc3826a4148082efed428a9749655977e62a9c15a6"))
 :ENVIRONMENT
 (:SBCL #A((5) BASE-CHAR . "2.6.9") :MACHINE #A((5) BASE-CHAR . "ARM64") :OS
  #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0") :PID
  7826)
 :STARTED-AT-UNIVERSAL-TIME 4000547421 :TIMER-UNITS-PER-SECOND 1000000 :LIMITS
 (:SYNTHETIC-FIXTURES-ONLY :COLLECTOR-CLI-PROCESSES :NO-PRODUCT-CAMPAIGNS
  :READ-EVAL-NIL-AND-EOF :DUPLICATES-TESTED-AT-COLLECTION-TARGET
  :NO-GENERAL-FILESYSTEM-ADVERSARY-OR-RELEASE-QUALIFICATION))
