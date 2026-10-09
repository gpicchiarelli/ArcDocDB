(:KIND :PARALLEL-SELF-TEST :JOBS 2 :RESULTS
 ((:NAME "waiting" :RESULT :DETECTED :EXIT-CODE 0)
  (:NAME "failing" :RESULT :WORKER-ERROR :EXIT-CODE 7)
  (:NAME "launch-error" :RESULT :WORKER-ERROR :EXIT-CODE NIL :SIGNAL NIL
   :DIAGNOSTIC "Guasto avvio fixture." :LOG
   "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000545862-mutation-self-test-50495/2/test.log")
  (:NAME "collect-error" :RESULT :WORKER-ERROR :EXIT-CODE 0 :SIGNAL NIL
   :DIAGNOSTIC "Guasto raccolta fixture." :LOG
   "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000545862-mutation-self-test-50495/3/test.log")
  (:NAME "signaled" :RESULT :WORKER-ERROR :EXIT-CODE 137 :SIGNAL 9 :DIAGNOSTIC
   "Worker terminato dal segnale 9." :LOG
   "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000545862-mutation-self-test-50495/4/test.log")))
