(:SCHEMA-VERSION 1 :ID "SPK-05" :COMMAND
 (#A((46) BASE-CHAR . "/home/runner/work/_temp/arcdocdb-sbcl/bin/sbcl")
  "--dynamic-space-size" "4096" "--noinform" "--no-userinit" "--no-sysinit"
  "--script" "spikes/SPK-05-segment-read/run.lisp"
  #A((7) BASE-CHAR . "--check"))
 :EXIT-CODE 1 :STARTED-AT-UNIVERSAL-TIME 4000486162 :FINISHED-AT-UNIVERSAL-TIME
 4000486162 :WALL-SECONDS 0.268d0 :STATUS :FAILED :SOURCE-BLOBS-BEFORE
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "04e1cd5c1a3c63c9fc47e307f7dfdb2cc3316540")
  (:PATH "spikes/SPK-05-segment-read/run.lisp" :GIT-BLOB
   "c67a3ae8e672f96d9105deb935fb621b07d67afb")
  (:PATH #A((36) BASE-CHAR . "spikes/SPK-05-segment-read/core.lisp") :GIT-BLOB
   "2c0c5a6b5c75a56a4db72fa88ff867cdb3db8508")
  (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
   "ba470bce3cae0ce14888dbec6e26c5656e9bbd1a")
  (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
   "baea7833c8e6f9a49b5ea2f8ee15f76fe35f93fe"))
 :SOURCE-BLOBS-AFTER
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "04e1cd5c1a3c63c9fc47e307f7dfdb2cc3316540")
  (:PATH "spikes/SPK-05-segment-read/run.lisp" :GIT-BLOB
   "c67a3ae8e672f96d9105deb935fb621b07d67afb")
  (:PATH #A((36) BASE-CHAR . "spikes/SPK-05-segment-read/core.lisp") :GIT-BLOB
   "2c0c5a6b5c75a56a4db72fa88ff867cdb3db8508")
  (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
   "ba470bce3cae0ce14888dbec6e26c5656e9bbd1a")
  (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
   "baea7833c8e6f9a49b5ea2f8ee15f76fe35f93fe"))
 :SOURCE-CONSISTENCY :STABLE :RESULT
 (:STATUS :ERROR :SPIKE :SPK-05 :MESSAGE
  #A((41) BASE-CHAR . "SPK-05: conteggi o intervallo incoerenti."))
 :STDOUT "(:STATUS :ERROR :SPIKE :SPK-05 :MESSAGE
 #A((41) BASE-CHAR . \"SPK-05: conteggi o intervallo incoerenti.\"))
"
 :STDERR "")
