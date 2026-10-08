(:DIAGNOSTIC
 #A((601) BASE-CHAR . "SPK-05 fallito (exit 1):
(:STATUS :ERROR :SPIKE :SPK-05 :MESSAGE
 #A((106) BASE-CHAR
    . \"Compilazione SPK-05 fallita: /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-05-segment-read/core.lisp.\"))

; 
; caught ERROR:
;   READ error during COMPILE-FILE:
;   
;     unmatched close parenthesis
;   
;       Line: 332, Column: 94, File-Position: 18884
;   
;       Stream: #<SB-INT:FORM-TRACKING-STREAM for \"file /Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-05-segment-read/core.lisp\" {800D1B4673}>
; 
; compilation unit aborted
;   caught 1 fatal ERROR condition
;   caught 1 ERROR condition
")
 :SCHEMA-VERSION 1 :ENVIRONMENT
 (:LISP #A((4) BASE-CHAR . "SBCL") :VERSION #A((5) BASE-CHAR . "2.6.9") :OS
  #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
  :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU "Apple M4" :MEMORY-BYTES
  17179869184 :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED
  :LOAD-AVERAGE "{ 9.74 11.94 12.49 }" :COMMIT
  "eca1ab5d878ce6675777cff09381237a3f01d7c8" :WORKING-TREE
  "M tools/run-spikes.lisp
?? spikes/SPK-05-segment-read/
?? spikes/SPK-07-protocols/compaction.lisp
?? spikes/SPK-07-protocols/memoria.lisp
?? spikes/SPK-07-protocols/metodo-compaction.md
?? spikes/SPK-07-protocols/metodo-memoria.md
?? spikes/SPK-07-protocols/metodo-pubblicazione.md
?? spikes/SPK-07-protocols/metodo-scadenza.md
?? spikes/SPK-07-protocols/pubblicazione.lisp
?? spikes/SPK-07-protocols/scadenza.lisp"
  :SOURCE-BLOBS
  ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
    "b4df3c7ba8d13e24794e3dbc6ac794eab4e5a6a1")
   (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
    "cbec51aad2b64fb8c5be026891eff859ba371c18")
   (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
    "c0fee7b738395fcaf3359f297282cd266ce6dfad")
   (:PATH "spikes/SPK-05-segment-read/io.lisp" :GIT-BLOB
    "8c7bf2cab38fa7027dea6faed3257bef50b0ccbf")
   (:PATH "spikes/SPK-05-segment-read/record.lisp" :GIT-BLOB
    "16e4eba7d9aecb42abfe4721fcedf7138241a009")
   (:PATH "spikes/SPK-01-primary-index/profile.lisp" :GIT-BLOB
    "a71fde100e32072b6e7b010228683b640ea4ff9a")
   (:PATH "spikes/SPK-10-v2-limits/codec.lisp" :GIT-BLOB
    "567c84546d29e1b8ddc5cd9e1a31b4e93519c75d")
   (:PATH "spikes/SPK-10-v2-limits/indice.lisp" :GIT-BLOB
    "bc978eb16aa7f0d69e3deac2df86057a650f8551")
   (:PATH "spikes/SPK-10-v2-limits/cbor.lisp" :GIT-BLOB
    "d6a5c93e34a0444d64b206df875a25b380545631")
   (:PATH "spikes/SPK-10-v2-limits/migrazione.lisp" :GIT-BLOB
    "cab850dc32ff9908b487b24edf3e1df2cc90008c")
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
   (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
    "77056cc1f695574ed0f4d34795b99aaea736f378")
   (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp") :GIT-BLOB
    "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
   (:PATH "spikes/SPK-05-segment-read/run.lisp" :GIT-BLOB
    "c67a3ae8e672f96d9105deb935fb621b07d67afb")
   (:PATH #A((36) BASE-CHAR . "spikes/SPK-05-segment-read/core.lisp") :GIT-BLOB
    "86959aeff6d931c451705622fed06686d47cf67e")
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
    "c5b7cfd27c663734b7d5fae481dde939418566b5"))
  :DYNAMIC-SPACE-MIB 4096 :DATE-UNIVERSAL-TIME 4000478621)
 :MODE #A((7) BASE-CHAR . "--check") :STATUS :FAILED :RUNS NIL :RUN-ARTIFACTS
 (#A((87) BASE-CHAR
     . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000478619-check-88775-0/SPK-05.lisp")))
