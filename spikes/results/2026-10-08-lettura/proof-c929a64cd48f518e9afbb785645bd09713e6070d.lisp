(:SCHEMA-VERSION 1 :ID "SPK-01" :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "4096" "--noinform" "--no-userinit" "--no-sysinit"
  "--script" "spikes/SPK-01-primary-index/run.lisp"
  #A((7) BASE-CHAR . "--bench") #A((9) BASE-CHAR . "--variant")
  #A((6) BASE-CHAR . "buffer") #A((12) BASE-CHAR . "--operations")
  #A((1) BASE-CHAR . "0"))
 :EXIT-CODE 1 :STARTED-AT-UNIVERSAL-TIME 4000484170 :FINISHED-AT-UNIVERSAL-TIME
 4000484171 :WALL-SECONDS 1.139984d0 :STATUS :FAILED :SOURCE-BLOBS-BEFORE
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "b35a1610b39dac7775230bc351e088ade5580a99")
  (:PATH "spikes/SPK-01-primary-index/run.lisp" :GIT-BLOB
   "b6e680b0c2d1a96c1d7fc3b0e133c80b6564a01e")
  (:PATH #A((37) BASE-CHAR . "spikes/SPK-01-primary-index/core.lisp") :GIT-BLOB
   "c019f6ad53e173a0d336a4dbfaf903e274a66f08")
  (:PATH "spikes/SPK-01-primary-index/lettura-buffer.lisp" :GIT-BLOB
   "28002439f931387cd6baebcf57adde7e88e2961b")
  (:PATH "spikes/SPK-01-primary-index/check-lettura-buffer.lisp" :GIT-BLOB
   "fd32c5260ffb7c6e96cf1a420765eb01effe70bc")
  (:PATH "spikes/SPK-01-primary-index/bench-lettura-buffer.lisp" :GIT-BLOB
   "2fd1b13855a94dc946f9f1b5e1c7556558b7e0c0"))
 :SOURCE-BLOBS-AFTER
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "b35a1610b39dac7775230bc351e088ade5580a99")
  (:PATH "spikes/SPK-01-primary-index/run.lisp" :GIT-BLOB
   "b6e680b0c2d1a96c1d7fc3b0e133c80b6564a01e")
  (:PATH #A((37) BASE-CHAR . "spikes/SPK-01-primary-index/core.lisp") :GIT-BLOB
   "c019f6ad53e173a0d336a4dbfaf903e274a66f08")
  (:PATH "spikes/SPK-01-primary-index/lettura-buffer.lisp" :GIT-BLOB
   "28002439f931387cd6baebcf57adde7e88e2961b")
  (:PATH "spikes/SPK-01-primary-index/check-lettura-buffer.lisp" :GIT-BLOB
   "fd32c5260ffb7c6e96cf1a420765eb01effe70bc")
  (:PATH "spikes/SPK-01-primary-index/bench-lettura-buffer.lisp" :GIT-BLOB
   "2fd1b13855a94dc946f9f1b5e1c7556558b7e0c0"))
 :SOURCE-CONSISTENCY :STABLE :RESULT
 (:SPIKE :SPK-01 :STATUS :ERROR :CONDITION
  #A((32) BASE-CHAR . "BENCH lettura buffer: OPERATIONS"))
 :STDOUT "(:SPIKE :SPK-01 :STATUS :ERROR :CONDITION
 #A((32) BASE-CHAR . \"BENCH lettura buffer: OPERATIONS\"))
"
 :STDERR "")
