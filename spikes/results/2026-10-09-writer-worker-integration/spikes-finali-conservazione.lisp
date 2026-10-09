(:FINISHED-AT-UNIVERSAL-TIME 4000548165 :STATUS :OK :STDERR "" :STDOUT
 "(:SCHEMA-VERSION 1 :KIND :EVIDENCE-COMPACTION :STATUS :OK :ROOT
 #A((130) BASE-CHAR
    . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/\")
 :JOBS 4 :MINIMUM-AGE-SECONDS 0 :FILES 2 :WALL-SECONDS 1.672079d0
 :CLOCK-UNITS-PER-SECOND 1000000 :ORIGINAL-BYTES 57107604 :STORED-BYTES 878710
 :RESULTS
 ((:PATH
   #A((141) BASE-CHAR
      . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/SPK-07.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28144051 :STORED-BYTES 410955 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"SPK-07.lisp.gz\" :UNCOMPRESSED-BYTES 28144051 :UNCOMPRESSED-SHA256
    \"398ff81f7ce904e296d6ed1849a50862815c1072419abac90f264623df6069e9\"
    :COMPRESSED-BYTES 410637 :COMPRESSED-SHA256
    \"90b9aa48faa7dd10264793c845f8fa3a47f421aecc2018a1608bb0d046b67e2d\"))
  (:PATH
   #A((141) BASE-CHAR
      . \"/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/report.lisp\")
   :STATUS :OK :ORIGINAL-BYTES 28963553 :STORED-BYTES 467755 :DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    \"report.lisp.gz\" :UNCOMPRESSED-BYTES 28963553 :UNCOMPRESSED-SHA256
    \"cc8ae3239e0f062c12bfac8c790b0d873ea803273b3c3f3aa1e315e6ba577db6\"
    :COMPRESSED-BYTES 467437 :COMPRESSED-SHA256
    \"8bb6048838224cda5f53f3a9c840d064977787cca7a28ebb76b7676f42aee404\")))
 :LIMITS
 (:LOSSLESS-BYTE-VERIFICATION :NO-GIT-HISTORY-REWRITE
  :REQUIRES-IMMUTABLE-INPUT-FILES :NO-POWER-LOSS-DURABILITY-CLAIM))
"
 :EXIT-CODE 0 :SCHEMA-VERSION 1 :KIND :EVIDENCE-FINALIZATION :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "2048" "--noinform" "--no-userinit" "--no-sysinit"
  "--script"
  #A((121) BASE-CHAR
     . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/tools/compact-evidence.lisp")
  "--root"
  #A((130) BASE-CHAR
     . "/private/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-integration-kk76vexc/spikes/out/4000548134-check-44515-0/")
  "--jobs" "4" "--finished-owner-pid" #A((5) BASE-CHAR . "44515"))
 :STARTED-AT-UNIVERSAL-TIME 4000548163)
