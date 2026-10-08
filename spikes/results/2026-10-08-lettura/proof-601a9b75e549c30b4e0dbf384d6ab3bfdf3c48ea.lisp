(:SCHEMA-VERSION 1 :ID "SPK-01" :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "4096" "--noinform" "--no-userinit" "--no-sysinit"
  "--script" "spikes/SPK-01-primary-index/run.lisp"
  #A((7) BASE-CHAR . "--bench") #A((9) BASE-CHAR . "--variant")
  #A((11) BASE-CHAR . "sconosciuta"))
 :EXIT-CODE 1 :STARTED-AT-UNIVERSAL-TIME 4000483627 :FINISHED-AT-UNIVERSAL-TIME
 4000483628 :WALL-SECONDS 0.375908d0 :STATUS :FAILED :SOURCE-BLOBS-BEFORE
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "ae44fcad821c929fc970d70c7990460011d96e0c")
  (:PATH "spikes/SPK-01-primary-index/run.lisp" :GIT-BLOB
   "b6e680b0c2d1a96c1d7fc3b0e133c80b6564a01e")
  (:PATH #A((37) BASE-CHAR . "spikes/SPK-01-primary-index/core.lisp") :GIT-BLOB
   "c019f6ad53e173a0d336a4dbfaf903e274a66f08")
  (:PATH "spikes/SPK-01-primary-index/lettura-buffer.lisp" :GIT-BLOB
   "899021815a7b1415d225ce5ba712564593504402")
  (:PATH "spikes/SPK-01-primary-index/check-lettura-buffer.lisp" :GIT-BLOB
   :ABSENT)
  (:PATH "spikes/SPK-01-primary-index/bench-lettura-buffer.lisp" :GIT-BLOB
   :ABSENT))
 :SOURCE-BLOBS-AFTER
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "ae44fcad821c929fc970d70c7990460011d96e0c")
  (:PATH "spikes/SPK-01-primary-index/run.lisp" :GIT-BLOB
   "b6e680b0c2d1a96c1d7fc3b0e133c80b6564a01e")
  (:PATH #A((37) BASE-CHAR . "spikes/SPK-01-primary-index/core.lisp") :GIT-BLOB
   "c019f6ad53e173a0d336a4dbfaf903e274a66f08")
  (:PATH "spikes/SPK-01-primary-index/lettura-buffer.lisp" :GIT-BLOB
   "899021815a7b1415d225ce5ba712564593504402")
  (:PATH "spikes/SPK-01-primary-index/check-lettura-buffer.lisp" :GIT-BLOB
   :ABSENT)
  (:PATH "spikes/SPK-01-primary-index/bench-lettura-buffer.lisp" :GIT-BLOB
   :ABSENT))
 :SOURCE-CONSISTENCY :STABLE :RESULT
 (:SPIKE :SPK-01 :STATUS :ERROR :CONDITION
  #A((43) BASE-CHAR . "Variante SPK-01 sconosciuta: \"sconosciuta\"."))
 :STDOUT "(:SPIKE :SPK-01 :STATUS :ERROR :CONDITION
 #A((43) BASE-CHAR . \"Variante SPK-01 sconosciuta: \\\"sconosciuta\\\".\"))
"
 :STDERR "")
