(:FINISHED-AT-UNIVERSAL-TIME 4000547317 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((125) BASE-CHAR
    . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000547284-check-97964-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.81731d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57106953 :STORED-BYTES 878505
 :RESULTS
 ((:PATH
   #A((136) BASE-CHAR
      . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000547284-check-97964-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144187 :STORED-BYTES 410985 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144187 :UNCOMPRESSED-SHA256
    \"d71430af742bc42c42d40ce6f7f4a86d52c9c1dd3889354ac43a599ca5c9ecaf\"
    :COMPRESSED-BYTES 410667 :COMPRESSED-SHA256
    \"f89db87b67aabc799c5bb80fee7f68e9a3b47b09d851c6e1dccd9fd7d7c64796\"))
  (:PATH
   #A((136) BASE-CHAR
      . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000547284-check-97964-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28962766 :STORED-BYTES 467520 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28962766 :UNCOMPRESSED-SHA256
    \"3d2861701d51e6a5c42397f7968f371ed4d91c26e984d7c1aaeea1fdecce5773\"
    :COMPRESSED-BYTES 467202 :COMPRESSED-SHA256
    \"aaba2220d5294a6e0cd801d5febfd87ca78befaf2f131c1a52a690db827e8392\")))
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
  #A((125) BASE-CHAR
     . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-verify-hzghjzb6/spikes/out/4000547284-check-97964-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "97964"))
 :STARTED-AT-UNIVERSAL-TIME 4000547314)
