(:SCHEMA-VERSION 1 :KIND :UTF8-COMPRESSED-EVIDENCE-AUDIT :FORMATS NIL :STATUS
 :OK :REVIEWER "/root/spk06_io" :STATEMENT-SOURCE "/root/spk06_io" :RECORDED-AT
 4000513124 :BASE-COMMIT "4215fca415c15d64bd56b1aa17d5c09fe6083713"
 :REVIEW-MODE :READONLY :COLLECTOR-MODIFIED NIL :SOURCE-HASHES-AT-REVIEW
 ((:SOURCE "tools/evidence-storage.lisp" :SHA256
   "8f287772a41b1ebe0e7b3ecc3826a4148082efed428a9749655977e62a9c15a6")
  (:SOURCE "tools/finish-evidence.lisp" :SHA256
   "edf55b633c98a494b0c2f2f0c7a037ee89c65b3b415ce792662f5c151a46f69b")
  (:SOURCE "tools/record-command.lisp" :SHA256
   "fae7e2a630e10ae6a1073d072065f9ae0ccef132f6221cb8b91c75124537cb16")
  (:SOURCE "tools/compact-evidence.lisp" :SHA256
   "7f70f251fc3a5188eb09a32645a410e9f1b0d7b9c334df88a74232f8535d5e3e")
  (:SOURCE "tools/check-evidence-storage.lisp" :SHA256
   "cf3b437c21bc79a93ea5d8ba7a0595f644a7663cd6e0dca001ab24c413e042e2")
  (:SOURCE "/tmp/collect-utf8-evidence.lisp" :SHA256
   "53042499e27a24937cb35ce5d79ce674e7767f445fd4a49af8a69b9274211dd9"))
 :OBSERVED-WRAPPER-FILES
 ((:SOURCE "spikes/out/4000512738-command-17861-0/report.lisp" :PHYSICAL-BYTES
   87411 :KIND :COMMAND-VERIFICATION :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE)
  (:SOURCE "spikes/out/4000512960-command-22018-0/report.lisp" :PHYSICAL-BYTES
   128314 :KIND :COMMAND-VERIFICATION :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE))
 :COMPRESSION-POLICY
 (:ELIGIBLE-EXTENSION "lisp" :THRESHOLD-BYTES 1048576 :COMPARISON
  :STRICTLY-GREATER :FINALIZATION :AFTER-LAST-RUN-WRITE)
 :INTEGRATION-RISK
 (:COLLECTOR-EXPECTS-PLAIN-COMMAND-VERIFICATION
  :DESCRIPTOR-IS-NOT-WRAPPER-METADATA
  :DIRECT-DESCRIPTOR-INPUT-REJECTED-BY-COLLECT-PROCESS
  :OTHER-RAW-DATA-INPUTS-ALSO-REQUIRE-CONDITIONAL-EXPANSION-IF-COMPRESSED)
 :WORKFLOW
 (:UNCHANGED-PATH
  "Se il dato è plain, usare il percorso originale nel config del collector."
  :COMPRESSED-PATH
  "Invocare CALL-WITH-EVIDENCE-BYTES sul descriptor con MAX-EXPANDED-BYTES fissato; nel callback copiare i byte in un file plain esclusivo sotto /tmp."
  :BYTE-VERIFICATION
  "Verificare size e SHA256 della copia contro il file callback già verificato e contro UNCOMPRESSED-BYTES/UNCOMPRESSED-SHA256 del descriptor. Non riscrivere la plist."
  :TEMPORARY-LIFETIME
  "Il pathname temporaneo dell'API non è valido dopo il callback. La copia distinta del chiamante deve restare stabile fino al termine del collector."
  :COLLECTOR-CONFIG
  "Cambiare solo :source dei process-reports in copie plain persistenti; nessuna modifica al collector. I metadata vengono letti dalla plist wrapper originale espansa."
  :RAW-PRESERVATION
  "Copiare bytewise descriptor e payload gzip in una stessa sottocartella associated-raw-files, mantenendo il leaf PAYLOAD del descriptor. Conservare anche conservazione.lisp del run."
  :PROVENANCE
  "Importare una plist schema1 :formats NIL con origine descriptor/plain, copie locali, dimensioni/hash originali e copie, budget e percorsi staging. Nessun valore di status dedotto dal descriptor."
  :PUBLICATION
  "Collector su target nuovo; catalogo top-level solo basename Lisp schema1, raw descriptor/gzip tra associated-raw-files. Rilettura bytewise e metadati prima di eliminare lo staging."
  :LIMITS
  (:FIXED-EXPANDED-BUDGET-134217728 :IMMUTABLE-FINISHED-RUN-INPUTS
   :EXCLUSIVE-STAGING-FILES :NO-CONCURRENCY-WITH-RUN-COMPACTOR))
 :FIXTURE
 (:SOURCE "/tmp/utf8-compressed-evidence-fixture-report.lisp" :SHA256
  "cb724c8d6d9ee61c4bf1df75d6216da687c9920d4d17b530b37a4ce978920dd2" :DATA
  (:SCHEMA-VERSION 1 :KIND :UTF8-EVIDENCE-ADAPTER-FIXTURE :FORMATS NIL :STATUS
   :OK :RECORDED-AT 4000513062 :FIXTURE-DIRECTORY
   #A((34) BASE-CHAR . "/tmp/utf8-evidence-adapter-Vs42ZL/") :CASES
   ((:INPUT
     #A((47) BASE-CHAR . "/tmp/utf8-evidence-adapter-Vs42ZL/original.lisp")
     :PLAIN-COPY
     #A((50) BASE-CHAR . "/tmp/utf8-evidence-adapter-Vs42ZL/plain-input.lisp")
     :BYTES 201 :SHA256
     "65a5905da18e77cfad5bf3264655010df4b085b228f968c5871f1fa72f295262" :STATUS
     :OK)
    (:INPUT
     #A((49) BASE-CHAR . "/tmp/utf8-evidence-adapter-Vs42ZL/descriptor.lisp")
     :PLAIN-COPY
     #A((55) BASE-CHAR
        . "/tmp/utf8-evidence-adapter-Vs42ZL/compressed-input.lisp")
     :BYTES 201 :SHA256
     "65a5905da18e77cfad5bf3264655010df4b085b228f968c5871f1fa72f295262" :STATUS
     :OK))
   :API-TEMPORARY-FILES-CLEANED
   (#A((73) BASE-CHAR
       . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-evidence-kmo1Lg"))
   :ORIGINAL-FILES-PRESERVED T :RAW-DESCRIPTOR
   (:SCHEMA-VERSION 1 :KIND :COMPRESSED-EVIDENCE :CODEC :GZIP :PAYLOAD
    "original.lisp.gz" :UNCOMPRESSED-BYTES 201 :UNCOMPRESSED-SHA256
    "65a5905da18e77cfad5bf3264655010df4b085b228f968c5871f1fa72f295262"
    :COMPRESSED-BYTES 166 :COMPRESSED-SHA256
    "99f68ee45d1e4f6b5a5f52745ab8b7fb35163b91f17d01ec19c59f40c1630278")
   :MODULE-SHA256
   "8f287772a41b1ebe0e7b3ecc3826a4148082efed428a9749655977e62a9c15a6" :LIMITS
   (:ONE-PLAIN-AND-ONE-COMPRESSED-FIXTURE :TOOL-DATA-ONLY
    :NO-COLLECTOR-MODIFICATION :NO-PRODUCT-CAMPAIGN :TRUSTED-LIBRARY-LOADED
    :RAW-DATA-READ-EVAL-NIL-AND-EOF))
  :SCRIPT "/tmp/utf8-compressed-evidence-fixture.lisp" :SCRIPT-SHA256
  "c1605f10a57faf0d317ca714d244c05725ea8956ff06affcdc39218b6508340f" :LOG
  "/tmp/utf8-compressed-evidence-fixture.log" :LOG-SHA256
  "1a4b819ce9e4e6ab1a247d4b495c8cdc319619216cb13d0fdeaa644e9636be16")
 :LIMITS
 (:TWO-OBSERVED-WRAPPERS-ONLY :LATER-CAMPAIGN-SIZES-NOT-PREDICTED
  :CONDITIONAL-ADAPTER-ONLY-IF-DESCRIPTOR-PRESENT
  :NO-EVIDENCE-COLLECTOR-MODIFICATION :NO-REPOSITORY-FILE-EDITS
  :MINIMAL-TOOL-DATA-FIXTURE-ONLY :NO-PRODUCT-CAMPAIGNS
  :NO-TESTS-CODEC-CONTENT-READ :READ-EVAL-NIL-AND-EOF
  :TRUSTED-EVIDENCE-LIBRARY-LOADED :NO-RAW-DATA-LOAD-OR-EVAL
  :NOT-A-RELEASE-QUALIFICATION :NO-POWER-LOSS-DURABILITY-CLAIM))
