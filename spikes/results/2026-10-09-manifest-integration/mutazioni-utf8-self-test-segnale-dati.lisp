(:SCHEMA-VERSION 1 :KIND :PROCESS-SIGNAL-SELF-TEST-OUTPUT :SCOPE :UTF8
 :PROCESS-ARTIFACT "mutazioni-utf8.lisp" :ORIGINAL-DIRECTORY
 #A((115) BASE-CHAR
    . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520203-utf8-signal-self-test-78812/")
 :ORIGINAL-REPORT
 (:SCHEMA-VERSION 1 :KIND :PROCESS-SIGNAL-SELF-TEST :SCOPE :UTF8 :STATUS
  :PASSED :WORKER-ERRORS 1 :MUTANTS
  ((:NAME "signal-fixture" :RESULT :WORKER-ERROR :DETECTED NIL :EXIT-CODE 137
    :SIGNAL 9 :DIAGNOSTIC :PROCESS-SIGNAL :LOG
    #A((123) BASE-CHAR
       . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520203-utf8-signal-self-test-78812/test.log")))
  :RUNNER
  #A((145) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520203-utf8-signal-self-test-78812/tools/utf8-isolated-build.lisp"))
 :RAW-FILES
 ((:PATH "report.lisp" :BYTE-COUNT 574 :GIT-BLOB
   "1b7865ec347ea9ac09988dc6d3ba12f9dceabd02" :CONTENT
   "(:SCHEMA-VERSION 1 :KIND :PROCESS-SIGNAL-SELF-TEST :SCOPE :UTF8 :STATUS :PASSED
 :WORKER-ERRORS 1 :MUTANTS
 ((:NAME \"signal-fixture\" :RESULT :WORKER-ERROR :DETECTED NIL :EXIT-CODE 137
   :SIGNAL 9 :DIAGNOSTIC :PROCESS-SIGNAL :LOG
   #A((123) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520203-utf8-signal-self-test-78812/test.log\")))
 :RUNNER
 #A((145) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/recovery-manifest/ArcDocDB/spikes/out/4000520203-utf8-signal-self-test-78812/tools/utf8-isolated-build.lisp\"))
")
  (:PATH "test.log" :BYTE-COUNT 40 :GIT-BLOB
   "3fefda2f0f38eeb4c70bc179c677c935655802b9" :CONTENT
   "ok    ARCDOCDB:*VERSION* è una stringa
")
  (:PATH "tools/utf8-isolated-build.lisp" :BYTE-COUNT 142 :GIT-BLOB
   "92cd0e371a8e19ba99b5d11cbb5c759156ddcb16" :CONTENT "(REQUIRE :SB-POSIX)
(FORMAT T \"ok    ARCDOCDB:*VERSION* è una stringa~%\")
(FINISH-OUTPUT)
(SB-POSIX:KILL (SB-POSIX:GETPID) SB-POSIX:SIGKILL)
")))
