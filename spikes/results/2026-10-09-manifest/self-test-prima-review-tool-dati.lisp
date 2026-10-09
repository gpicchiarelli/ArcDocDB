(:SCHEMA-VERSION 1 :KIND :PARALLEL-SELF-TEST-OUTPUT :PROCESS-ARTIFACT
 "self-test-prima-review-tool.lisp" :ORIGINAL-REPORT
 (:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
  ((:NAME "waiting" :RESULT :DETECTED :EXIT-CODE 0)
   (:NAME "failing" :RESULT :WORKER-ERROR :EXIT-CODE 7)
   (:NAME "launch-error" :RESULT :WORKER-ERROR :EXIT-CODE NIL :DIAGNOSTIC
    "Guasto avvio fixture." :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509493-mutation-self-test-22245/2/test.log")
   (:NAME "collect-error" :RESULT :WORKER-ERROR :EXIT-CODE 0 :DIAGNOSTIC
    "Guasto raccolta fixture." :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509493-mutation-self-test-22245/3/test.log")))
 :RAW-FILES
 ((:PATH "report.lisp" :CONTENT "(:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
 ((:NAME \"waiting\" :RESULT :DETECTED :EXIT-CODE 0)
  (:NAME \"failing\" :RESULT :WORKER-ERROR :EXIT-CODE 7)
  (:NAME \"launch-error\" :RESULT :WORKER-ERROR :EXIT-CODE NIL :DIAGNOSTIC
   \"Guasto avvio fixture.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509493-mutation-self-test-22245/2/test.log\")
  (:NAME \"collect-error\" :RESULT :WORKER-ERROR :EXIT-CODE 0 :DIAGNOSTIC
   \"Guasto raccolta fixture.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000509493-mutation-self-test-22245/3/test.log\")))
")
  (:PATH "worker-fixture.lisp" :CONTENT
   "(LET* ((ARGS (REST SB-EXT:*POSIX-ARGV*))
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
  (:PATH "release" :CONTENT "rilasciato
")
  (:PATH "0/test.log" :CONTENT "")
  (:PATH "1/test.log" :CONTENT "worker-fixture-failure
")
  (:PATH "3/test.log" :CONTENT "")))
