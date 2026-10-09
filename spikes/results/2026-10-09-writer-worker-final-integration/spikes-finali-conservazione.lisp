(:FINISHED-AT-UNIVERSAL-TIME 4000550551 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((135) BASE-CHAR
    . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/4000550501-check-1579-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.723759d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57107292 :STORED-BYTES 878503
 :RESULTS
 ((:PATH
   #A((146) BASE-CHAR
      . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/4000550501-check-1579-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144120 :STORED-BYTES 410943 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144120 :UNCOMPRESSED-SHA256
    \"89c19ea5e1666d20d8cecf92c86d19343c71001cb4027de2cf1bda517e19f828\"
    :COMPRESSED-BYTES 410625 :COMPRESSED-SHA256
    \"1aa39cfb75b4010d94c67c630dad0c2438c8fcbc336d1834f9c72ef91afa0b61\"))
  (:PATH
   #A((146) BASE-CHAR
      . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/4000550501-check-1579-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28963172 :STORED-BYTES 467560 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28963172 :UNCOMPRESSED-SHA256
    \"8cf03cb6ff76bc38a74cb6c49200fbb5ccaf01b15b4f054226e7ee6f228f6332\"
    :COMPRESSED-BYTES 467242 :COMPRESSED-SHA256
    \"438e64411b756bbeaa8ca58f3bb64bc3231e3640ac287dbcb32f28236653e0b4\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((127) BASE-CHAR
     . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/tools/compact-evidence.lisp")
  "--root"
  #A((135) BASE-CHAR
     . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/4000550501-check-1579-0/")
  "--jobs" "4" "--finished-owner-pid" #A((4) BASE-CHAR . "1579"))
 :STARTED-AT-UNIVERSAL-TIME 4000550549)
