(:FINISHED-AT-UNIVERSAL-TIME 4000529209 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((102) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000529175-check-83141-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.813578d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106582 :STORED-BYTES 878282
 :RESULTS
 ((:PATH
   #A((113) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000529175-check-83141-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144051 :STORED-BYTES 410949 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144051 :UNCOMPRESSED-SHA256
    \"4e9ecaee4b6c02b0964973bf40b28cf9d0afc077d4b69ecea647282436fbf7e8\"
    :COMPRESSED-BYTES 410631 :COMPRESSED-SHA256
    \"f4785204cfcc692a33e406d9a903f53d48569c1c03ff616c6b38d5f7d6938aff\"))
  (:PATH
   #A((113) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000529175-check-83141-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962531 :STORED-BYTES 467333 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962531 :UNCOMPRESSED-SHA256
    \"fa0381265da5555c36398d83f8b42bb8ddd564003db4335c2130db39884fc0a5\"
    :COMPRESSED-BYTES 467015 :COMPRESSED-SHA256
    \"84f76fa760d9b75bdbf9245424ea3c6a5495e6bb7cfd70fd7faab05338772a01\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((93) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((102) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB/spikes/out/4000529175-check-83141-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "83141"))
 :STARTED-AT-UNIVERSAL-TIME 4000529207)
