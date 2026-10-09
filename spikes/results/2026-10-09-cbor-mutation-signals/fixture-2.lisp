(:SCHEMA-VERSION 1 :KIND :PROCESS-FIXTURE-OUTPUT :SCOPE
 :CBOR-MUTATION-PROCESSES :ORIGINAL-DIRECTORY
 #A((127) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/")
 :ORIGINAL-REPORTS
 ((:PATH "report.lisp" :ORIGINAL-REPORT
   (:SCHEMA-VERSION 1 :KIND :PROCESS-FAILURE-SELF-TEST :SCOPE :CBOR-HEADER
    :STATUS :PASSED :WORKER-ERRORS 2 :MUTANTS
    ((:NAME #A((14) BASE-CHAR . "signal-fixture") :RESULT :WORKER-ERROR
      :DETECTED NIL :EXIT-CODE 137 :SIGNAL 9 :DIAGNOSTIC :PROCESS-SIGNAL :LOG
      #A((142) BASE-CHAR
         . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/signal/test.log")
      :RUNNER
      #A((171) BASE-CHAR
         . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/signal/tools/cbor-header-isolated-build.lisp")
      :BASELINE-CLASSIFIER (:WORKER-ERROR :PROCESS-SIGNAL))
     (:NAME #A((18) BASE-CHAR . "completion-fixture") :RESULT :WORKER-ERROR
      :DETECTED NIL :EXIT-CODE 7 :SIGNAL NIL :DIAGNOSTIC
      :AFTER-BUILD-COMPLETION :LOG
      #A((146) BASE-CHAR
         . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/completion/test.log")
      :RUNNER
      #A((175) BASE-CHAR
         . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/completion/tools/cbor-header-isolated-build.lisp")
      :BASELINE-CLASSIFIER (:WORKER-ERROR :AFTER-BUILD-COMPLETION))))))
 :RAW-FILES
 ((:PATH "completion/test.log" :ORIGINAL-PATH
   #A((146) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/completion/test.log")
   :BYTE-COUNT 96 :GIT-BLOB "f6f72ff8c25126f1febf62b165bbd662e9eb6332" :CONTENT
   "ok    ARCDOCDB:*VERSION* è una stringa
build e test: nessun avviso, tutti i controlli superati
")
  (:PATH "completion/tools/cbor-header-isolated-build.lisp" :ORIGINAL-PATH
   #A((175) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/completion/tools/cbor-header-isolated-build.lisp")
   :BYTE-COUNT 184 :GIT-BLOB "bb12d39e6e7dc467b009ae75a522a6081caa84b7"
   :CONTENT "(REQUIRE :SB-POSIX)
(FORMAT T \"ok    ARCDOCDB:*VERSION* è una stringa~%\")
(FORMAT T \"build e test: nessun avviso, tutti i controlli superati~%\")
(FINISH-OUTPUT)
(SB-EXT:EXIT :CODE 7)
")
  (:PATH "report.lisp" :ORIGINAL-PATH
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/report.lisp")
   :BYTE-COUNT 1334 :GIT-BLOB "8367bbc2df1f6054dbafea6621db9ab7f8659ab1"
   :CONTENT
   "(:SCHEMA-VERSION 1 :KIND :PROCESS-FAILURE-SELF-TEST :SCOPE :CBOR-HEADER :STATUS
 :PASSED :WORKER-ERRORS 2 :MUTANTS
 ((:NAME #A((14) BASE-CHAR . \"signal-fixture\") :RESULT :WORKER-ERROR :DETECTED
   NIL :EXIT-CODE 137 :SIGNAL 9 :DIAGNOSTIC :PROCESS-SIGNAL :LOG
   #A((142) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/signal/test.log\")
   :RUNNER
   #A((171) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/signal/tools/cbor-header-isolated-build.lisp\")
   :BASELINE-CLASSIFIER (:WORKER-ERROR :PROCESS-SIGNAL))
  (:NAME #A((18) BASE-CHAR . \"completion-fixture\") :RESULT :WORKER-ERROR
   :DETECTED NIL :EXIT-CODE 7 :SIGNAL NIL :DIAGNOSTIC :AFTER-BUILD-COMPLETION
   :LOG
   #A((146) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/completion/test.log\")
   :RUNNER
   #A((175) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/completion/tools/cbor-header-isolated-build.lisp\")
   :BASELINE-CLASSIFIER (:WORKER-ERROR :AFTER-BUILD-COMPLETION))))
")
  (:PATH "signal/test.log" :ORIGINAL-PATH
   #A((142) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/signal/test.log")
   :BYTE-COUNT 40 :GIT-BLOB "3fefda2f0f38eeb4c70bc179c677c935655802b9" :CONTENT
   "ok    ARCDOCDB:*VERSION* è una stringa
")
  (:PATH "signal/tools/cbor-header-isolated-build.lisp" :ORIGINAL-PATH
   #A((171) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546757-cbor-header-process-self-test-71588/signal/tools/cbor-header-isolated-build.lisp")
   :BYTE-COUNT 142 :GIT-BLOB "92cd0e371a8e19ba99b5d11cbb5c759156ddcb16"
   :CONTENT "(REQUIRE :SB-POSIX)
(FORMAT T \"ok    ARCDOCDB:*VERSION* è una stringa~%\")
(FINISH-OUTPUT)
(SB-POSIX:KILL (SB-POSIX:GETPID) SB-POSIX:SIGKILL)
"))
 :LIMITS
 (:ORIGINAL-BYTES-AND-STATUSES-PRESERVED :NO-STATUS-PROMOTION
  :TOOL-VERIFICATION-ONLY :NOT-C1-OR-MCDC))
