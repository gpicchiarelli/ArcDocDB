(:SCHEMA-VERSION 1 :ID "SPK-04" :COMMAND
 (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
  "--dynamic-space-size" "4096" "--noinform" "--no-userinit" "--no-sysinit"
  "--script" "spikes/SPK-04-writer-pool/run.lisp"
  #A((7) BASE-CHAR . "--check"))
 :EXIT-CODE 1 :STARTED-AT-UNIVERSAL-TIME 4000476985 :FINISHED-AT-UNIVERSAL-TIME
 4000476986 :WALL-SECONDS 0.910433d0 :STATUS :FAILED :SOURCE-BLOBS-BEFORE
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "2e4b1f8ab3dc2e90eb6c4119c855bbb6865a770d")
  (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
   "77056cc1f695574ed0f4d34795b99aaea736f378")
  (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp") :GIT-BLOB
   "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
  (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
   "6f26cd62e87912aa8ef8fafb5555ea1190d18dc7")
  (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
   "2050948e1856ce9814195156e7be1a4516dffa52"))
 :SOURCE-BLOBS-AFTER
 ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
   "2e4b1f8ab3dc2e90eb6c4119c855bbb6865a770d")
  (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
   "77056cc1f695574ed0f4d34795b99aaea736f378")
  (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp") :GIT-BLOB
   "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
  (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
   "6f26cd62e87912aa8ef8fafb5555ea1190d18dc7")
  (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
   "2050948e1856ce9814195156e7be1a4516dffa52"))
 :SOURCE-CONSISTENCY :STABLE :RESULT
 (:STATUS :ERROR :SPIKE :SPK-04 :MESSAGE
  #A((84) BASE-CHAR
     . "Compilazione SPK-04: redefining ARCDOCDB.SPK04.POOL::CON-MUTEX-LIMITATO in DEFMACRO."))
 :STDOUT "(:STATUS :ERROR :SPIKE :SPK-04 :MESSAGE
 #A((84) BASE-CHAR
    . \"Compilazione SPK-04: redefining ARCDOCDB.SPK04.POOL::CON-MUTEX-LIMITATO in DEFMACRO.\"))
"
 :STDERR "")
