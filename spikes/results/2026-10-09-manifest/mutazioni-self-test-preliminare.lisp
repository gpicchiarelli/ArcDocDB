(:SCHEMA-VERSION 1 :KIND :DEVELOPMENT-DIAGNOSTIC :STATUS :HISTORICAL-PASS
 :DESCRIPTION
 "Self-test locale preliminare dello strumento di mutazione; i guasti worker sono fixture intenzionali."
 :COMMAND
 ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script"
  "tools/foundation-mutation.lisp" "--self-test")
 :WORKING-DIRECTORY
 #A((65) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/")
 :EXIT-CODE 0 :ENVIRONMENT :NOT-COLLECTED :COMMIT :NOT-COLLECTED :WORKING-TREE
 :NOT-COLLECTED :SOURCE-BLOBS-BEFORE :NOT-COLLECTED :SOURCE-BLOBS-AFTER
 :NOT-COLLECTED :SOURCE-CONSISTENCY :NOT-COLLECTED :STARTED-AT-UNIVERSAL-TIME
 :NOT-COLLECTED :FINISHED-AT-UNIVERSAL-TIME :NOT-COLLECTED :WALL-SECONDS
 :NOT-COLLECTED :STDOUT :NOT-COLLECTED :STDERR :NOT-COLLECTED :SOURCE-STATE
 (:BEFORE-MANIFEST-MUTANT-TABLE :BEFORE-FINAL-CLASSIFIER-FIX
  :BEFORE-BASELINE-SNAPSHOT-COPY :BEFORE-WORKER-SIGNAL-CHECK)
 :ORIGINAL-DIRECTORY
 #A((112) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/")
 :ORIGINAL-REPORT
 (:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
  ((:NAME "waiting" :RESULT :DETECTED :EXIT-CODE 0)
   (:NAME "failing" :RESULT :WORKER-ERROR :EXIT-CODE 7)
   (:NAME "launch-error" :RESULT :WORKER-ERROR :EXIT-CODE NIL :DIAGNOSTIC
    "Guasto avvio fixture." :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/2/test.log")
   (:NAME "collect-error" :RESULT :WORKER-ERROR :EXIT-CODE NIL :DIAGNOSTIC
    "Guasto raccolta fixture." :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/3/test.log")))
 :ORIGINAL-ARTIFACTS
 ((:PATH
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/report.lisp")
   :PRESENCE :PRESENT :CONTENTS "(:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
 ((:NAME \"waiting\" :RESULT :DETECTED :EXIT-CODE 0)
  (:NAME \"failing\" :RESULT :WORKER-ERROR :EXIT-CODE 7)
  (:NAME \"launch-error\" :RESULT :WORKER-ERROR :EXIT-CODE NIL :DIAGNOSTIC
   \"Guasto avvio fixture.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/2/test.log\")
  (:NAME \"collect-error\" :RESULT :WORKER-ERROR :EXIT-CODE NIL :DIAGNOSTIC
   \"Guasto raccolta fixture.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/3/test.log\")))
")
  (:PATH
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/worker-fixture.lisp")
   :PRESENCE :PRESENT :CONTENTS "(LET* ((ARGS (REST SB-EXT:*POSIX-ARGV*))
       (MODE (FIRST ARGS))
       (RELEASE (MERGE-PATHNAMES \"release\" (SECOND ARGS))))
  (COND
   ((STRING= MODE \"waiting\")
    (LOOP REPEAT 500
          UNTIL (PROBE-FILE RELEASE)
          DO (SLEEP 0.01))
    (SB-EXT:EXIT :CODE
                 (IF (PROBE-FILE RELEASE)
                     0
                     11)))
   ((STRING= MODE \"failing\")
    (WITH-OPEN-FILE (OUTPUT RELEASE :DIRECTION :OUTPUT :IF-EXISTS :ERROR)
      (WRITE-LINE \"rilasciato\" OUTPUT))
    (FORMAT T \"worker-fixture-failure~%\") (SB-EXT:EXIT :CODE 7))
   (T (SB-EXT:EXIT :CODE 0))))")
  (:PATH
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/release")
   :PRESENCE :PRESENT :CONTENTS "rilasciato
")
  (:PATH
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/0/test.log")
   :PRESENCE :PRESENT :CONTENTS "")
  (:PATH
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/1/test.log")
   :PRESENCE :PRESENT :CONTENTS "worker-fixture-failure
")
  (:PATH
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/2/test.log")
   :PRESENCE :ABSENT :CONTENTS :NOT-PRODUCED)
  (:PATH
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509021-mutation-self-test-99291/3/test.log")
   :PRESENCE :PRESENT :CONTENTS ""))
 :LIMITS
 (:UNRECORDED-LOCAL-INVOCATION :EXIT-CODE-OBSERVED-IN-TOOL-RESULT
  :FULL-COMMAND-OUTPUT-NOT-RECORDED :GLOBAL-METADATA-NOT-RECONSTRUCTED
  :PRELIMINARY-TOOL-STATE :NO-FINAL-VERIFICATION-CLAIM))
