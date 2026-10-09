(:SCHEMA-VERSION 1 :KIND :PARALLEL-SELF-TEST-OUTPUT :PROCESS-ARTIFACT
 "integrazione-self-test-foundation.lisp" :ORIGINAL-DIRECTORY
 "spikes/out/4000512283-mutation-self-test-6606/" :ORIGINAL-REPORT
 (:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
  ((:NAME "waiting" :RESULT :DETECTED :EXIT-CODE 0)
   (:NAME "failing" :RESULT :WORKER-ERROR :EXIT-CODE 7)
   (:NAME "launch-error" :RESULT :WORKER-ERROR :EXIT-CODE NIL :DIAGNOSTIC
    "Guasto avvio fixture." :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000512283-mutation-self-test-6606/2/test.log")
   (:NAME "collect-error" :RESULT :WORKER-ERROR :EXIT-CODE 0 :DIAGNOSTIC
    "Guasto raccolta fixture." :LOG
    "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000512283-mutation-self-test-6606/3/test.log")))
 :RAW-FILES
 ((:PATH "report.lisp" :BYTE-COUNT 620 :GIT-BLOB
   "254807bf22d6b7d3bb351d07cc3decfc326b7138" :CONTENT
   "(:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
 ((:NAME \"waiting\" :RESULT :DETECTED :EXIT-CODE 0)
  (:NAME \"failing\" :RESULT :WORKER-ERROR :EXIT-CODE 7)
  (:NAME \"launch-error\" :RESULT :WORKER-ERROR :EXIT-CODE NIL :DIAGNOSTIC
   \"Guasto avvio fixture.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000512283-mutation-self-test-6606/2/test.log\")
  (:NAME \"collect-error\" :RESULT :WORKER-ERROR :EXIT-CODE 0 :DIAGNOSTIC
   \"Guasto raccolta fixture.\" :LOG
   \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000512283-mutation-self-test-6606/3/test.log\")))
")
  (:PATH "0/test.log" :BYTE-COUNT 0 :GIT-BLOB
   "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391" :CONTENT "")
  (:PATH "1/test.log" :BYTE-COUNT 23 :GIT-BLOB
   "2af63261ff69d496cafb64fdb00f4cc91045cecc" :CONTENT "worker-fixture-failure
")
  (:PATH "3/test.log" :BYTE-COUNT 0 :GIT-BLOB
   "e69de29bb2d1d6434b8b29ae775ad8c2e48c5391" :CONTENT ""))
 :MISSING-FILES ((:PATH "2/test.log" :REASON :WORKER-LAUNCH-ERROR)))
