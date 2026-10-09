(:SCHEMA-VERSION 1 :KIND :CBOR-STRUCTURE-WRITER-RECYCLE-INTEGRATION-AUDIT
 :STATUS :OK :STATEMENT-SOURCE
 "root: integrazione su75ada9d, lettura protetta wrapper make check e master compresso, nove blob CBOR invariati"
 :INTEGRATION-BASE "75ada9d686390ee03223336801d9905e7f297407"
 :VERIFIED-CODE-COMMIT "63ee21df1457f714aaacb6daf40ed2a7a3ffa89a" :RECORDED-AT
 4000530438 :DATA-READ-EVAL NIL :DATA-EOF-CHECKED T
 :RAW-DATA-LOADED-OR-EVALUATED NIL :PRODUCT-RERUN-BY-AUDIT NIL :WRAPPER
 #A((49) BASE-CHAR . "spikes/out/4000530203-command-93074-0/report.lisp")
 :SOURCE-CONSISTENCY :STABLE :SNAPSHOT-COUNT 424 :BEFORE-AFTER-EQUAL T
 :FROZEN-NINE-BLOBS-MATCH-BEFORE-AFTER-CURRENT T :SOURCES
 (("src/codec/cbor-package.lisp" "411212b04f96be32516425aa2a7ac53aac5b921d")
  ("src/codec/cbor-space.lisp" "a8330e50a77b52a6b9044ebbb48f62bb4b3222a3")
  ("src/codec/cbor-scan-input.lisp" "57ffc48cc688a4de8ebec5cb14c1e69c4209704a")
  ("src/codec/cbor-scan-stack.lisp" "c574e87af5e195ddf3f596a4ae527e69c7a3c6a6")
  ("src/codec/cbor-scan-items.lisp" "70272936e323b3e0cb05173c9fb68cb2b614c355")
  ("src/codec/cbor-scan.lisp" "1f89112b43a39d98cf25dc6dfb34e412428ba843")
  ("tests/codec/cbor-structure-support.lisp"
   "e9cc8a08917903cab7b7f5617225884b7d89e6c4")
  ("tests/codec/cbor-structure.lisp"
   "7e9b7a518bc3a260d721e85d62ff986553bb06de")
  ("tests/codec/cbor-structure-threads.lisp"
   "3624e1dde5f5a484a117f4c783d4e6b88027cc89"))
 :TESTS 335 :CBOR-STRUCTURE-TESTS 24 :SPIKES 10 :MASTER
 #A((47) BASE-CHAR . "spikes/out/4000530281-check-93758-0/report.lisp")
 :MASTER-STATUS :COMPLETE :RUNS
 ((:ID "SPK-01" :STATUS :OK :EXIT-CODE 0)
  (:ID "SPK-02" :STATUS :OK :EXIT-CODE 0)
  (:ID "SPK-03" :STATUS :OK :EXIT-CODE 0)
  (:ID "SPK-04" :STATUS :OK :EXIT-CODE 0)
  (:ID "SPK-05" :STATUS :OK :EXIT-CODE 0)
  (:ID "SPK-06" :STATUS :OK :EXIT-CODE 0)
  (:ID "SPK-07" :STATUS :PASS :EXIT-CODE 0)
  (:ID "SPK-08" :STATUS :OK :EXIT-CODE 0)
  (:ID "SPK-09" :STATUS :OK :EXIT-CODE 0)
  (:ID "SPK-10" :STATUS :OK :EXIT-CODE 0))
 :DESCRIPTOR-DERIVATION
 (:ORIGINAL-PRESERVED-IN "writer-recycle-integration-master/"
  :ONLY-CHANGED-FIELD :PAYLOAD :ORIGINAL-PAYLOAD "report.lisp.gz"
  :DERIVED-PAYLOAD "writer-recycle-integration-report.lisp.gz"
  :GZIP-BYTES-AND-CHECKSUMS-UNCHANGED T)
 :LIMITS
 (:RUNTIME-LOCAL-ONLY :NOT-FULL-CBOR-SEMANTIC-PROFILE :NOT-HUMAN-APPROVAL
  :NOT-ENGINE-RELEASE-QUALIFICATION))
