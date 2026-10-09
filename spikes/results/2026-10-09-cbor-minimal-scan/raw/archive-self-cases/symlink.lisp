(:CASE "symlink" :EXPECTED-REASON :NONREGULAR-PATH :OBSERVED-EXIT-CODE 1
 :STATUS :OK :STDOUT
 "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/symlink.stdout.log"
 :STDERR
 "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/logs/symlink.stderr.log"
 :REPORT
 (:SCHEMA-VERSION 1 :KIND :COMMAND-ARCHIVE-AUDIT :STATUS :FAILED :REASON
  :NONREGULAR-PATH :PATH
  "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/command-archive-check-self-20261009-a/symlink/raw/data.bin"
  :DIAGNOSTIC "Inventario con file speciale o symlink."))
