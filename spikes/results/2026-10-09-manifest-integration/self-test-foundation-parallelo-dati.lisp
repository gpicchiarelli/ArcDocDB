(:SCHEMA-VERSION 1 :KIND :PARALLEL-SELF-TEST-OUTPUT :PROCESS-ARTIFACT
 "self-test-foundation.lisp" :ORIGINAL-DIRECTORY
 "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520112-mutation-self-test-75716/"
 :ORIGINAL-REPORT
 (:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
  ((:NAME "waiting" :RESULT :DETECTED :EXIT-CODE 0)
   (:NAME "failing" :RESULT :WORKER-ERROR :EXIT-CODE 7)
   (:NAME "launch-error" :RESULT :WORKER-ERROR :EXIT-CODE NIL :DIAGNOSTIC
    "Guasto avvio fixture." :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520112-mutation-self-test-75716/2/test.log")
   (:NAME "collect-error" :RESULT :WORKER-ERROR :EXIT-CODE 0 :DIAGNOSTIC
    "Guasto raccolta fixture." :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520112-mutation-self-test-75716/3/test.log")))
 :RAW-FILES
 ((:PATH "report.lisp" :BYTE-COUNT 622 :GIT-BLOB
   "cf71639cca9cd879b4cd82a3b1dc844946f2b4c1" :CONTENT
   "(:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
 ((:NAME \"waiting\" :RESULT :DETECTED :EXIT-CODE 0)
  (:NAME \"failing\" :RESULT :WORKER-ERROR :EXIT-CODE 7)
  (:NAME \"launch-error\" :RESULT :WORKER-ERROR :EXIT-CODE NIL :DIAGNOSTIC
   \"Guasto avvio fixture.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520112-mutation-self-test-75716/2/test.log\")
  (:NAME \"collect-error\" :RESULT :WORKER-ERROR :EXIT-CODE 0 :DIAGNOSTIC
   \"Guasto raccolta fixture.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520112-mutation-self-test-75716/3/test.log\")))
")
  (:PATH "worker-fixture.lisp" :BYTE-COUNT 603 :GIT-BLOB
   "239628efdfec72708c7c06e5759f0b7ee27279a1" :CONTENT
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
  (:PATH "release" :BYTE-COUNT 11 :GIT-BLOB
   "415f5972f9ae59dd576e547d78ce35516f1c517b" :CONTENT "rilasciato
")
  (:PATH "0/test.log" :BYTE-COUNT 0 :GIT-BLOB
   "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391" :CONTENT "")
  (:PATH "1/test.log" :BYTE-COUNT 23 :GIT-BLOB
   "2af63261ff69d496cafb64fdb00f4cc91045cecc" :CONTENT "worker-fixture-failure
")
  (:PATH "3/test.log" :BYTE-COUNT 0 :GIT-BLOB
   "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391" :CONTENT ""))
 :MISSING-FILES ((:PATH "2/test.log" :REASON :WORKER-LAUNCH-ERROR)))
