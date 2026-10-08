(:SCHEMA-VERSION 1 :ENVIRONMENT
 (:LISP #A((4) BASE-CHAR . "SBCL") :VERSION #A((5) BASE-CHAR . "2.6.9") :OS
  #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
  :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU "Apple M4" :MEMORY-BYTES
  17179869184 :COMMIT "07cfd031b08b45e0eb8afcd2cba788e42454e03b" :WORKING-TREE
  "M docs/roadmap.md
 M docs/valutazione/README.md
 M docs/valutazione/piano-spike.md
 M docs/valutazione/registro-rischi.md
 M docs/valutazione/stime-ordine-di-grandezza.md
 M spikes/README.md
 M spikes/SPK-01-primary-index/README.md
 M spikes/SPK-01-primary-index/core.lisp
 M spikes/SPK-01-primary-index/run.lisp
 M spikes/SPK-09-integrity/README.md
 M tools/run-spikes.lisp
?? docs/valutazione/risultati-2026-10-08.md
?? spikes/SPK-01-primary-index/profile.lisp
?? spikes/SPK-10-v2-limits/
?? spikes/results/2026-10-08/index-inline-100k.lisp
?? spikes/results/2026-10-08/index-inline-10m.lisp
?? spikes/results/2026-10-08/profile-speed3.lisp"
  :SOURCE-BLOBS
  ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
    "4850d0e64b3f8023c2e261de04f54876af08beee")
   (:PATH "spikes/SPK-01-primary-index/profile.lisp" :GIT-BLOB
    "a71fde100e32072b6e7b010228683b640ea4ff9a")
   (:PATH "spikes/SPK-10-v2-limits/codec.lisp" :GIT-BLOB
    "baca070063883de9719d12fc2e9b4aabc3db3a02")
   (:PATH "spikes/SPK-10-v2-limits/indice.lisp" :GIT-BLOB
    "5c00e62352164e2616dfc2b942dbc7ec9d34f992")
   (:PATH "spikes/SPK-10-v2-limits/cbor.lisp" :GIT-BLOB
    "6aad9fed888646851dd28dd7df084db39d4b72a6")
   (:PATH "spikes/SPK-10-v2-limits/migrazione.lisp" :GIT-BLOB
    "8e6cc0fa719541aeb9f886b61f83ae5d014394ac")
   (:PATH "spikes/SPK-01-primary-index/run.lisp" :GIT-BLOB
    "9b32673c5bda223ba7783ec082af0890078d1e25")
   (:PATH #A((37) BASE-CHAR . "spikes/SPK-01-primary-index/core.lisp")
    :GIT-BLOB "c019f6ad53e173a0d336a4dbfaf903e274a66f08")
   (:PATH "spikes/SPK-02-gc/run.lisp" :GIT-BLOB
    "9fbe499100da40c2f7a14072af67c35c734949c5")
   (:PATH #A((26) BASE-CHAR . "spikes/SPK-02-gc/core.lisp") :GIT-BLOB
    "01f6760c75fa6e96a480fca41b1426941a9f703d")
   (:PATH "spikes/SPK-03-group-commit/run.lisp" :GIT-BLOB
    "c0b093e87028dd587c43d3cd52e59492270fdc38")
   (:PATH #A((36) BASE-CHAR . "spikes/SPK-03-group-commit/core.lisp") :GIT-BLOB
    "d3c58f2866e299ba27b0fa820c20317438774410")
   (:PATH "spikes/SPK-07-protocols/run.lisp" :GIT-BLOB
    "0aa8d4a0a6cc59dbf5deae28395be85f61377ea4")
   (:PATH #A((33) BASE-CHAR . "spikes/SPK-07-protocols/core.lisp") :GIT-BLOB
    "489e2732cf5bfed4cd11251bb686a5d4f4e10b3e")
   (:PATH "spikes/SPK-09-integrity/run.lisp" :GIT-BLOB
    "c95660a4df5f2e6f6eb93e1078c2c36df6dabc85")
   (:PATH #A((33) BASE-CHAR . "spikes/SPK-09-integrity/core.lisp") :GIT-BLOB
    "80cdac4c0e52703618e1f274413b2ecbe00e6b14")
   (:PATH "spikes/SPK-10-v2-limits/run.lisp" :GIT-BLOB
    "6aa63afeac91c3b75174b76daba61e354bb7fe4d")
   (:PATH #A((33) BASE-CHAR . "spikes/SPK-10-v2-limits/core.lisp") :GIT-BLOB
    "ae1d2e86f05d33d50fa3101d743b313ae10e230e"))
  :DYNAMIC-SPACE-MIB 4096 :DATE-UNIVERSAL-TIME 4000474566)
 :MODE #A((9) BASE-CHAR . "--profile") :STATUS :COMPLETE :RUNS
 ((:SCHEMA-VERSION 1 :ID "SPK-01" :COMMAND
   (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
    "--dynamic-space-size" "4096" "--noinform" "--no-userinit" "--no-sysinit"
    "--script" "spikes/SPK-01-primary-index/run.lisp"
    #A((9) BASE-CHAR . "--profile"))
   :EXIT-CODE 0 :STARTED-AT-UNIVERSAL-TIME 4000474566
   :FINISHED-AT-UNIVERSAL-TIME 4000474566 :WALL-SECONDS 0.57093d0 :STATUS :OK
   :RESULT
   (:SPIKE :SPK-01 :STATUS :OK :KIND :ALLOCATION-PROFILE :PARAMETERS
    (:CAPACITY 8192 :WORDS 4 :FIXED-ID 0 :SAFETY 3 :READER-SPEED 2) :CASES
    ((:CASE :KEY-GENERATION :OPERATIONS 1000000 :WARMUP-OPERATIONS 10000
      :WALL-SECONDS 0.019799d0 :ALLOCATION-BYTES 0
      :ALLOCATION-BYTES-PER-OPERATION 0.0d0 :SINK 159)
     (:CASE :HASH-TO-U64-ARRAY :OPERATIONS 1000000 :WARMUP-OPERATIONS 10000
      :WALL-SECONDS 0.017751d0 :ALLOCATION-BYTES 0
      :ALLOCATION-BYTES-PER-OPERATION 0.0d0 :SINK 12083707897552849873)
     (:CASE :LOOKUP-FIXED-KEY :OPERATIONS 1000000 :WARMUP-OPERATIONS 10000
      :WALL-SECONDS 0.122783d0 :ALLOCATION-BYTES 47960640
      :ALLOCATION-BYTES-PER-OPERATION 47.96064d0 :SINK 1))
    :LIMITS
    (:SINGLE-KEY :PROCESS-ALLOCATION-COUNTER :NO-ZERO-ALLOCATION-GUARANTEE
     :NO-GC-ATTRIBUTION :NO-DATABASE-THROUGHPUT :FORMAT-V1))
   :STDOUT "(:SPIKE :SPK-01 :STATUS :OK :KIND :ALLOCATION-PROFILE :PARAMETERS
 (:CAPACITY 8192 :WORDS 4 :FIXED-ID 0 :SAFETY 3 :READER-SPEED 2) :CASES
 ((:CASE :KEY-GENERATION :OPERATIONS 1000000 :WARMUP-OPERATIONS 10000
   :WALL-SECONDS 0.019799d0 :ALLOCATION-BYTES 0 :ALLOCATION-BYTES-PER-OPERATION
   0.0d0 :SINK 159)
  (:CASE :HASH-TO-U64-ARRAY :OPERATIONS 1000000 :WARMUP-OPERATIONS 10000
   :WALL-SECONDS 0.017751d0 :ALLOCATION-BYTES 0 :ALLOCATION-BYTES-PER-OPERATION
   0.0d0 :SINK 12083707897552849873)
  (:CASE :LOOKUP-FIXED-KEY :OPERATIONS 1000000 :WARMUP-OPERATIONS 10000
   :WALL-SECONDS 0.122783d0 :ALLOCATION-BYTES 47960640
   :ALLOCATION-BYTES-PER-OPERATION 47.96064d0 :SINK 1))
 :LIMITS
 (:SINGLE-KEY :PROCESS-ALLOCATION-COUNTER :NO-ZERO-ALLOCATION-GUARANTEE
  :NO-GC-ATTRIBUTION :NO-DATABASE-THROUGHPUT :FORMAT-V1))
"
   :STDERR ""))
 :RUN-ARTIFACTS
 (#A((89) BASE-CHAR
     . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000474564-profile-44873-0/SPK-01.lisp")))
