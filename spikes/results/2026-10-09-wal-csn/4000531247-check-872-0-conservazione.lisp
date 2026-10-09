(:FINISHED-AT-UNIVERSAL-TIME 4000531282 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((98) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000531247-check-872-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.754738d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106359 :STORED-BYTES 878106
 :RESULTS
 ((:PATH
   #A((109) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000531247-check-872-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144214 :STORED-BYTES 410991 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144214 :UNCOMPRESSED-SHA256
    \"429353c2e438f20dc5c233182cbc675214e835a88a8572e5424d2e5da5eecc8b\"
    :COMPRESSED-BYTES 410673 :COMPRESSED-SHA256
    \"58b5475e6cdf601afa88213723787b99679df5e770ada60a4aa402ce09ff7ad4\"))
  (:PATH
   #A((109) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000531247-check-872-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962145 :STORED-BYTES 467115 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962145 :UNCOMPRESSED-SHA256
    \"899dbcc2906458c3b0d1059eb0c575be29fdb07ed193445f7b411cbe5987f402\"
    :COMPRESSED-BYTES 466797 :COMPRESSED-SHA256
    \"26747d937d3f61abc7e8b202afa7f454388cbcf8aaba5b535aa79ab01873349d\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((91) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((98) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000531247-check-872-0/")
  "--jobs" "4" "--finished-owner-pid" #A((3) BASE-CHAR . "872"))
 :STARTED-AT-UNIVERSAL-TIME 4000531280)
