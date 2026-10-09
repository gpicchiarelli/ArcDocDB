(:SCHEMA-VERSION 1 :KIND :PROCESS-FIXTURE-OUTPUT :SCOPE
 :CBOR-MUTATION-PROCESSES :ORIGINAL-DIRECTORY
 #A((129) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/")
 :ORIGINAL-REPORTS
 ((:PATH "baseline-copy/report.lisp" :ORIGINAL-REPORT
   (:BASELINE
    (:STATUS :WORKER-ERROR :RESULT :WORKER-ERROR :EXIT-CODE NIL :SIGNAL NIL
     :DIAGNOSTIC :INFRASTRUCTURE-ERROR :DETAIL
     #A((30) BASE-CHAR . "Fixture baseline copy refusal.") :LOG
     #A((151) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-copy/test.log"))
    :SCHEMA-VERSION 1 :KIND :BASELINE-INFRASTRUCTURE-SELF-TEST :STATUS :PASSED
    :STAGE :COMPLETE :WORKER-ERRORS 1 :INJECTED-BOUNDARY :COPY))
  (:PATH "baseline-transport/report.lisp" :ORIGINAL-REPORT
   (:BASELINE
    (:STATUS :WORKER-ERROR :RESULT :WORKER-ERROR :EXIT-CODE NIL :SIGNAL NIL
     :DIAGNOSTIC :INFRASTRUCTURE-ERROR :DETAIL
     #A((35) BASE-CHAR . "Fixture baseline transport refusal.") :LOG
     #A((156) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-transport/test.log"))
    :SCHEMA-VERSION 1 :KIND :BASELINE-INFRASTRUCTURE-SELF-TEST :STATUS :PASSED
    :STAGE :COMPLETE :WORKER-ERRORS 1 :INJECTED-BOUNDARY :TRANSPORT))
  (:PATH "report.lisp" :ORIGINAL-REPORT
   (:BASELINE-FIXTURE-REPORTS
    (#A((154) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-copy/report.lisp")
     #A((159) BASE-CHAR
        . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-transport/report.lisp"))
    :SCHEMA-VERSION 1 :KIND :PROCESS-SIGNAL-SELF-TEST :SCOPE :CBOR-STRUCTURE
    :STATUS :PASSED :STAGE :COMPLETE :WORKER-ERRORS 2 :MUTANTS
    ((:NAME :SIGNAL :RESULT :WORKER-ERROR :DETECTED NIL :BASELINE-STATUS
      :WORKER-ERROR :BASELINE-DIAGNOSTIC :PROCESS-SIGNAL :EXIT-CODE 137 :SIGNAL
      9 :DIAGNOSTIC :PROCESS-SIGNAL :RUNNER
      #A((176) BASE-CHAR
         . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/signal/tools/cbor-structure-isolated-build.lisp")
      :LOG
      #A((144) BASE-CHAR
         . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/signal/test.log"))
     (:NAME :COMPLETION-EXIT :RESULT :WORKER-ERROR :DETECTED NIL
      :BASELINE-STATUS :WORKER-ERROR :BASELINE-DIAGNOSTIC
      :AFTER-BUILD-COMPLETION :EXIT-CODE 7 :SIGNAL NIL :DIAGNOSTIC
      :AFTER-BUILD-COMPLETION :RUNNER
      #A((185) BASE-CHAR
         . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/completion-exit/tools/cbor-structure-isolated-build.lisp")
      :LOG
      #A((153) BASE-CHAR
         . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/completion-exit/test.log"))))))
 :RAW-FILES
 ((:PATH "baseline-copy/report.lisp" :ORIGINAL-PATH
   #A((154) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-copy/report.lisp")
   :BYTE-COUNT 510 :GIT-BLOB "314ecb429dff8f6a9d86778fb84c6bbcc3b3f3ba"
   :CONTENT "(:BASELINE
 (:STATUS :WORKER-ERROR :RESULT :WORKER-ERROR :EXIT-CODE NIL :SIGNAL NIL
  :DIAGNOSTIC :INFRASTRUCTURE-ERROR :DETAIL
  #A((30) BASE-CHAR . \"Fixture baseline copy refusal.\") :LOG
  #A((151) BASE-CHAR
     . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-copy/test.log\"))
 :SCHEMA-VERSION 1 :KIND :BASELINE-INFRASTRUCTURE-SELF-TEST :STATUS :PASSED
 :STAGE :COMPLETE :WORKER-ERRORS 1 :INJECTED-BOUNDARY :COPY)
")
  (:PATH "baseline-copy/test.log" :ORIGINAL-PATH
   #A((151) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-copy/test.log")
   :BYTE-COUNT 72 :GIT-BLOB "bdbe5a1837ba1db2100fb1abdb6bd4c64a1063a3" :CONTENT
   "Errore di infrastruttura della campagna: Fixture baseline copy refusal.
")
  (:PATH "baseline-transport/report.lisp" :ORIGINAL-PATH
   #A((159) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-transport/report.lisp")
   :BYTE-COUNT 525 :GIT-BLOB "0ec97c4a31fbe577f07a6dbeb6320e632ffe2e9b"
   :CONTENT "(:BASELINE
 (:STATUS :WORKER-ERROR :RESULT :WORKER-ERROR :EXIT-CODE NIL :SIGNAL NIL
  :DIAGNOSTIC :INFRASTRUCTURE-ERROR :DETAIL
  #A((35) BASE-CHAR . \"Fixture baseline transport refusal.\") :LOG
  #A((156) BASE-CHAR
     . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-transport/test.log\"))
 :SCHEMA-VERSION 1 :KIND :BASELINE-INFRASTRUCTURE-SELF-TEST :STATUS :PASSED
 :STAGE :COMPLETE :WORKER-ERRORS 1 :INJECTED-BOUNDARY :TRANSPORT)
")
  (:PATH "baseline-transport/test.log" :ORIGINAL-PATH
   #A((156) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-transport/test.log")
   :BYTE-COUNT 77 :GIT-BLOB "a6f25b160a8c7b98d184b73450cc60f285313402" :CONTENT
   "Errore di infrastruttura della campagna: Fixture baseline transport refusal.
")
  (:PATH "completion-exit/test.log" :ORIGINAL-PATH
   #A((153) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/completion-exit/test.log")
   :BYTE-COUNT 96 :GIT-BLOB "f6f72ff8c25126f1febf62b165bbd662e9eb6332" :CONTENT
   "ok    ARCDOCDB:*VERSION* è una stringa
build e test: nessun avviso, tutti i controlli superati
")
  (:PATH "completion-exit/tools/cbor-structure-isolated-build.lisp"
   :ORIGINAL-PATH
   #A((185) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/completion-exit/tools/cbor-structure-isolated-build.lisp")
   :BYTE-COUNT 184 :GIT-BLOB "bb12d39e6e7dc467b009ae75a522a6081caa84b7"
   :CONTENT "(REQUIRE :SB-POSIX)
(FORMAT T \"ok    ARCDOCDB:*VERSION* è una stringa~%\")
(FORMAT T \"build e test: nessun avviso, tutti i controlli superati~%\")
(FINISH-OUTPUT)
(SB-EXT:EXIT :CODE 7)
")
  (:PATH "report.lisp" :ORIGINAL-PATH
   #A((140) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/report.lisp")
   :BYTE-COUNT 1754 :GIT-BLOB "3424e54aa1f65b3ba93bf121b42bc8aee260c396"
   :CONTENT "(:BASELINE-FIXTURE-REPORTS
 (#A((154) BASE-CHAR
     . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-copy/report.lisp\")
  #A((159) BASE-CHAR
     . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/baseline-transport/report.lisp\"))
 :SCHEMA-VERSION 1 :KIND :PROCESS-SIGNAL-SELF-TEST :SCOPE :CBOR-STRUCTURE
 :STATUS :PASSED :STAGE :COMPLETE :WORKER-ERRORS 2 :MUTANTS
 ((:NAME :SIGNAL :RESULT :WORKER-ERROR :DETECTED NIL :BASELINE-STATUS
   :WORKER-ERROR :BASELINE-DIAGNOSTIC :PROCESS-SIGNAL :EXIT-CODE 137 :SIGNAL 9
   :DIAGNOSTIC :PROCESS-SIGNAL :RUNNER
   #A((176) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/signal/tools/cbor-structure-isolated-build.lisp\")
   :LOG
   #A((144) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/signal/test.log\"))
  (:NAME :COMPLETION-EXIT :RESULT :WORKER-ERROR :DETECTED NIL :BASELINE-STATUS
   :WORKER-ERROR :BASELINE-DIAGNOSTIC :AFTER-BUILD-COMPLETION :EXIT-CODE 7
   :SIGNAL NIL :DIAGNOSTIC :AFTER-BUILD-COMPLETION :RUNNER
   #A((185) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/completion-exit/tools/cbor-structure-isolated-build.lisp\")
   :LOG
   #A((153) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/completion-exit/test.log\"))))
")
  (:PATH "signal/test.log" :ORIGINAL-PATH
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/signal/test.log")
   :BYTE-COUNT 40 :GIT-BLOB "3fefda2f0f38eeb4c70bc179c677c935655802b9" :CONTENT
   "ok    ARCDOCDB:*VERSION* è una stringa
")
  (:PATH "signal/tools/cbor-structure-isolated-build.lisp" :ORIGINAL-PATH
   #A((176) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546716-cbor-structure-worker-self-test-69053/signal/tools/cbor-structure-isolated-build.lisp")
   :BYTE-COUNT 142 :GIT-BLOB "92cd0e371a8e19ba99b5d11cbb5c759156ddcb16"
   :CONTENT "(REQUIRE :SB-POSIX)
(FORMAT T \"ok    ARCDOCDB:*VERSION* è una stringa~%\")
(FINISH-OUTPUT)
(SB-POSIX:KILL (SB-POSIX:GETPID) SB-POSIX:SIGKILL)
"))
 :LIMITS
 (:ORIGINAL-BYTES-AND-STATUSES-PRESERVED :NO-STATUS-PROMOTION
  :TOOL-VERIFICATION-ONLY :NOT-C1-OR-MCDC))
