(:CASE "index-read-eval" :EXPECTED-REASON :EVIDENCE-READ :OBSERVED-EXIT-CODE 1
 :STATUS :OK :STDOUT
 "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-read-eval.stdout.log"
 :STDERR
 "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/index-read-eval.stderr.log"
 :REPORT
 (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
  :EVIDENCE-READ :PATH
  "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/index-read-eval/archive-index.lisp"
  :DIAGNOSTIC
  "Evidenza non valida /Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/index-read-eval/archive-index.lisp: can't read #. while *READ-EVAL* is NIL

  Stream: #<SB-SYS:FD-STREAM for \"descriptor 6\" {8005966573}>"))
