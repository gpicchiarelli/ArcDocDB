(:FINISHED-AT-UNIVERSAL-TIME 4000549713 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((100) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/4000549681-check-30973-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.751925d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57105943 :STORED-BYTES 878167
 :RESULTS
 ((:PATH
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/4000549681-check-30973-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144051 :STORED-BYTES 410954 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144051 :UNCOMPRESSED-SHA256
    \"e7e4eebe50d834143cf1f76d23947eb298e08481884e59b5c96fa84fe4a56876\"
    :COMPRESSED-BYTES 410636 :COMPRESSED-SHA256
    \"2e082f8c85dbb7fae80f08b32872aae3b17158adaf5e1a56a67941c0e5266ba1\"))
  (:PATH
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/4000549681-check-30973-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28961892 :STORED-BYTES 467213 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28961892 :UNCOMPRESSED-SHA256
    \"d8143a0242d5cfad22d719edbd0ff0bb1db4eef2966ae332993b2525a4795bcc\"
    :COMPRESSED-BYTES 466895 :COMPRESSED-SHA256
    \"b0dd44b0ac045de0166c5292a019cebfc78a9c47450735fcd36f6617f78be914\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((91) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((100) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/controller-serie/ArcDocDB/spikes/out/4000549681-check-30973-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "30973"))
 :STARTED-AT-UNIVERSAL-TIME 4000549711)
