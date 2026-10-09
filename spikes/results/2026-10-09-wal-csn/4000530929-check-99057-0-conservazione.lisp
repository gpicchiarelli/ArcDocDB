(:FINISHED-AT-UNIVERSAL-TIME 4000530964 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((100) BASE-CHAR
    . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000530929-check-99057-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.797728d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106245 :STORED-BYTES 878036
 :RESULTS
 ((:PATH
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000530929-check-99057-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144051 :STORED-BYTES 410954 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144051 :UNCOMPRESSED-SHA256
    \"3abd4b33d16448857e3486c3fd97be65e0b784319abf1b0836bd085727b9fa24\"
    :COMPRESSED-BYTES 410636 :COMPRESSED-SHA256
    \"b9d8fb55f35605253eca3433b90b0d38f0fa13df15c3a1428456f9cd8cc56f07\"))
  (:PATH
   #A((111) BASE-CHAR
      . \"/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000530929-check-99057-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962194 :STORED-BYTES 467082 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962194 :UNCOMPRESSED-SHA256
    \"120ba1b63004ddd8495d5e217ed529a12641f1bcdd0702f2ef5717bbf054dc54\"
    :COMPRESSED-BYTES 466764 :COMPRESSED-SHA256
    \"c8dd263a093c157699934b1dd2d2c102c5f6e881740e31d43dcc0016206b89de\")))
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
  #A((100) BASE-CHAR
     . "/Users/gpicchiarelli/.codex/worktrees/chiusura-csn-wal/ArcDocDB/spikes/out/4000530929-check-99057-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "99057"))
 :STARTED-AT-UNIVERSAL-TIME 4000530962)
