(:FINISHED-AT-UNIVERSAL-TIME 4000550758 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((73) BASE-CHAR
    . \"/home/runner/work/ArcDocDB/ArcDocDB/spikes/out/4000550715-command-2152-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 0 :WALL-SECONDS 0.0d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 0 :STORED-BYTES 0 :RESULTS NIL
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((46) BASE-CHAR . "/home/runner/work/_temp/arcdocdb-sbcl/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((63) BASE-CHAR
     . "/home/runner/work/ArcDocDB/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((73) BASE-CHAR
     . "/home/runner/work/ArcDocDB/ArcDocDB/spikes/out/4000550715-command-2152-0/")
  "--jobs" "4" "--finished-owner-pid" #A((4) BASE-CHAR . "2152"))
 :STARTED-AT-UNIVERSAL-TIME 4000550758)
