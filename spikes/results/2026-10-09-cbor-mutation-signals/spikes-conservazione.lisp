(:FINISHED-AT-UNIVERSAL-TIME 4000546831 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((105) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546799-check-74770-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.691875d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106928 :STORED-BYTES 878659
 :RESULTS
 ((:PATH
   #A((116) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546799-check-74770-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144119 :STORED-BYTES 410937 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144119 :UNCOMPRESSED-SHA256
    \"6a1310ae8dbe35e3c69874b175d3588150bd4ce2b72d0f93ab11f58c02d89b1c\"
    :COMPRESSED-BYTES 410619 :COMPRESSED-SHA256
    \"51b1bb608f189e1b767f817801f046efeb2231a01642da1b20f38494a4333f0f\"))
  (:PATH
   #A((116) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546799-check-74770-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962809 :STORED-BYTES 467722 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962809 :UNCOMPRESSED-SHA256
    \"d0dd7515eacae7c7f895a8c284fa0855d722afcd7730efe7e2f8a78b0c5ab6cc\"
    :COMPRESSED-BYTES 467404 :COMPRESSED-SHA256
    \"75648e1adc9ea3c411d3f57a5c8dbeb6456d11659d18817e4ce9a3d071b6c35c\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((96) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((105) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/cbor-mutation-signals/ArcDocDB/spikes/out/4000546799-check-74770-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "74770"))
 :STARTED-AT-UNIVERSAL-TIME 4000546829)
