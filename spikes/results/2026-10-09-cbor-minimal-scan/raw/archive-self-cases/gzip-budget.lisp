(:CASE "gzip-budget" :EXPECTED-REASON :FILE-BUDGET :OBSERVED-EXIT-CODE 1
 :STATUS :OK :STDOUT
 "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/gzip-budget.stdout.log"
 :STDERR
 "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/gzip-budget.stderr.log"
 :REPORT
 (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
  :FILE-BUDGET :PATH "unindexed.gz" :DIAGNOSTIC
  "8388609 byte, limite 8388608."))
