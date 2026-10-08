(:SCHEMA-VERSION 1 :ID "SPK-06" :COMMAND
 (#A((46) BASE-CHAR . "/home/runner/work/_temp/arcdocdb-sbcl/bin/sbcl")
  "--dynamic-space-size" "4096" "--noinform" "--no-userinit" "--no-sysinit"
  "--script" "spikes/SPK-06-compaction-load/run.lisp"
  #A((7) BASE-CHAR . "--check"))
 :EXIT-CODE 1 :STARTED-AT-UNIVERSAL-TIME 4000486538 :FINISHED-AT-UNIVERSAL-TIME
 4000486538 :WALL-SECONDS 0.569995d0 :STATUS :FAILED :SOURCE-BLOBS-BEFORE
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "04e1cd5c1a3c63c9fc47e307f7dfdb2cc3316540")
  (:PATH "spikes/SPK-06-compaction-load/run.lisp" :GIT-BLOB
   "b2863cbac49d0988b850bdeeae1713108a21bfca")
  (:PATH #A((39) BASE-CHAR . "spikes/SPK-06-compaction-load/core.lisp")
   :GIT-BLOB "375cb97e1490e0252c04fd1a3076a17342cefd68")
  (:PATH "spikes/SPK-06-compaction-load/controllore.lisp" :GIT-BLOB
   "4602972e2400d31d4d3b771f60703c68e23f0804")
  (:PATH "spikes/SPK-06-compaction-load/interferenza.lisp" :GIT-BLOB
   "6fe454e8018bcf21b40726f928bf4380b5d06a9d")
  (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
   "ba470bce3cae0ce14888dbec6e26c5656e9bbd1a")
  (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
   "baea7833c8e6f9a49b5ea2f8ee15f76fe35f93fe"))
 :SOURCE-BLOBS-AFTER
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "04e1cd5c1a3c63c9fc47e307f7dfdb2cc3316540")
  (:PATH "spikes/SPK-06-compaction-load/run.lisp" :GIT-BLOB
   "b2863cbac49d0988b850bdeeae1713108a21bfca")
  (:PATH #A((39) BASE-CHAR . "spikes/SPK-06-compaction-load/core.lisp")
   :GIT-BLOB "375cb97e1490e0252c04fd1a3076a17342cefd68")
  (:PATH "spikes/SPK-06-compaction-load/controllore.lisp" :GIT-BLOB
   "4602972e2400d31d4d3b771f60703c68e23f0804")
  (:PATH "spikes/SPK-06-compaction-load/interferenza.lisp" :GIT-BLOB
   "6fe454e8018bcf21b40726f928bf4380b5d06a9d")
  (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
   "ba470bce3cae0ce14888dbec6e26c5656e9bbd1a")
  (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
   "baea7833c8e6f9a49b5ea2f8ee15f76fe35f93fe"))
 :SOURCE-CONSISTENCY :STABLE :RESULT
 (:STATUS :ERROR :SPIKE :SPK-06 :MESSAGE
  #A((53) BASE-CHAR . "SPK-06: oracolo non soddisfatto: :INTERVALLO-LETTURE."))
 :STDOUT "(:STATUS :ERROR :SPIKE :SPK-06 :MESSAGE
 #A((53) BASE-CHAR . \"SPK-06: oracolo non soddisfatto: :INTERVALLO-LETTURE.\"))
"
 :STDERR "")
