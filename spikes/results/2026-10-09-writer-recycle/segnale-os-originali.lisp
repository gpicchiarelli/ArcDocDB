(:SCHEMA-VERSION 1 :KIND :PROCESS-SIGNAL-RAW-SOURCES :SOURCES
 ((:PATH
   #A((61) BASE-CHAR
      . "spikes/out/4000528529-recycle-signal-self-test-77690/test.log")
   :BYTES 36 :SHA256
   "275c36c75259976e070c5416ec142e5dcde2dc7df2244bd704530a651100be66" :GIT-BLOB
   "40aed4a7df2f6642a2e70f2c304471ee2a7b4e6a" :TEXT
   "execution-test-start SIGNAL-FIXTURE
")
  (:PATH
   #A((93) BASE-CHAR
      . "spikes/out/4000528529-recycle-signal-self-test-77690/tools/writer-recycle-isolated-build.lisp")
   :BYTES 140 :SHA256
   "e49e7d9f5d188e0c7d3031d8c63bb5fb86827020254e8e29a6728199179f6639" :GIT-BLOB
   "d7f606312912fae5d1e5347d236fe42c19a5b057" :TEXT "(REQUIRE :SB-POSIX)
(FORMAT T \"~&execution-test-start SIGNAL-FIXTURE~%\")
(FINISH-OUTPUT)
(SB-POSIX:KILL (SB-POSIX:GETPID) SB-POSIX:SIGKILL)
")))
