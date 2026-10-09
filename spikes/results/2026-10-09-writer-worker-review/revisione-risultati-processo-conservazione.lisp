(:FINISHED-AT-UNIVERSAL-TIME 4000547698 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((127) BASE-CHAR
    . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000547689-command-21967-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 1 :WALL-SECONDS 1.619838d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 27447514 :STORED-BYTES 485215
 :RESULTS
 ((:PATH
   #A((138) BASE-CHAR
      . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000547689-command-21967-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 27447514 :STORED-BYTES 485215 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 27447514 :UNCOMPRESSED-SHA256
    \"221810d54c77ae53d7fdf7f4ae5b03219ace10ec46b199f8e01f431a6875798f\"
    :COMPRESSED-BYTES 484897 :COMPRESSED-SHA256
    \"a21a27d791a0820baf6729e6860882d85831a6f37daedc159ebb3bb2d104d92c\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((116) BASE-CHAR
     . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/tools/compact-evidence.lisp")
  "--root"
  #A((127) BASE-CHAR
     . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000547689-command-21967-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "21967"))
 :STARTED-AT-UNIVERSAL-TIME 4000547695)
