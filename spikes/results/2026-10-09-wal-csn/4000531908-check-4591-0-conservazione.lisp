(:FINISHED-AT-UNIVERSAL-TIME 4000531944 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((99) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000531908-check-4591-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.817982d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106103 :STORED-BYTES 877945
 :RESULTS
 ((:PATH
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000531908-check-4591-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144051 :STORED-BYTES 410953 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144051 :UNCOMPRESSED-SHA256
    \"eae4f95dcfed6eaa16f268c2b3f2ce7657eb3f8f49372f77f3f7929aafe55648\"
    :COMPRESSED-BYTES 410635 :COMPRESSED-SHA256
    \"3b3a0dd845142d4e5c0cadf674fbdded6387e29d4f29ec44cc0a62878ac0bd98\"))
  (:PATH
   #A((110) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000531908-check-4591-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962052 :STORED-BYTES 466992 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962052 :UNCOMPRESSED-SHA256
    \"4938ea843c324fd7da344997206971549a9f410744f023981267051f4ca8e5e8\"
    :COMPRESSED-BYTES 466674 :COMPRESSED-SHA256
    \"a65a88498d1699e6d37eb6d6fbd45e2241d2589b807d6c7107b6e6244c17f739\")))
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
  #A((99) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000531908-check-4591-0/")
  "--jobs" "4" "--finished-owner-pid" #A((4) BASE-CHAR . "4591"))
 :STARTED-AT-UNIVERSAL-TIME 4000531942)
