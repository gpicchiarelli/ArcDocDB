(:FINISHED-AT-UNIVERSAL-TIME 4001683816 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((81) BASE-CHAR
    . \"/home/runner/work/ArcDocDB/ArcDocDB/spikes/out/ci/verify-linux/work/commands/job/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 0 :WALL-SECONDS 0.0d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 0 :STORED-BYTES 0 :RESULTS NIL
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((65) BASE-CHAR
     . "/home/runner/work/_temp/arcdocdb-sbcl.IaEmgyFZ/installed/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((63) BASE-CHAR
     . "/home/runner/work/ArcDocDB/ArcDocDB/tools/compact-evidence.lisp")
  "--root"
  #A((81) BASE-CHAR
     . "/home/runner/work/ArcDocDB/ArcDocDB/spikes/out/ci/verify-linux/work/commands/job/")
  "--jobs" "4" "--finished-owner-pid" #A((4) BASE-CHAR . "3118"))
 :STARTED-AT-UNIVERSAL-TIME 4001683815)
