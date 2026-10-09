(:SCHEMA-VERSION 1 :KIND :ORIGINAL-COMMAND-ARCHIVE :METADATA-POLICY
 :READ-WITHOUT-RESULT-INFERENCE :PROCESSES
 ((:LABEL "plain" :RECORD-PATH "processes/plain/report.lisp" :STATUS :OK
   :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   ("synthetic-guard-fixture" "plain"))
  (:LABEL "compressed" :RECORD-PATH "processes/compressed/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   ("synthetic-guard-fixture" "compressed")))
 :FILES
 ((:PATH "collection-manifest.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/manifest.lisp")
   :BYTES 793 :SHA256
   "4e6688a4854d8c5cda540048595d9099c37f82280239eaa3b911fa7d8120271f")
  (:PATH "collection-source.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/collect.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH "processes/compressed/original.lisp" :SOURCE
   #A((143) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/compressed/original.lisp")
   :BYTES 4389 :SHA256
   "26c8fd82568e4818f00fd59dba14f8ea69f326bde42101cea81a850d93ad389d")
  (:PATH "processes/compressed/raw.log" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/compressed/raw.log")
   :BYTES 19 :SHA256
   "d7be16f40d8230b96f0db682866f29734bf6b0614fc68fd6682ea784c3c3764f")
  (:PATH "processes/compressed/report.lisp" :SOURCE
   #A((141) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/compressed/report.lisp")
   :BYTES 311 :SHA256
   "acb19269e43a493ccc5f5d78a59f68136935131badce614f0b9a85c295d78077")
  (:PATH "processes/compressed/report.lisp.gz" :SOURCE
   #A((144) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/compressed/report.lisp.gz")
   :BYTES 259 :SHA256
   "05c23cbf610dda4c2951379b6640ae3c8ecb093aee7b2f0426eb622e83d4550e")
  (:PATH "processes/plain/extra.txt" :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/plain/extra.txt")
   :BYTES 25 :SHA256
   "632bad64d7a4c7f9c78d8c8c9fb15a4bc5e0be85070bbbf58e5232751e34027e")
  (:PATH "processes/plain/raw.log" :SOURCE
   #A((132) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/plain/raw.log")
   :BYTES 41 :SHA256
   "371bd4a3f41da86f8a2ce0a6340dac380b58eec94b62e920abda755a40acf22e")
  (:PATH "processes/plain/report.lisp" :SOURCE
   #A((136) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/plain/report.lisp")
   :BYTES 4379 :SHA256
   "ebb17214170a3a2a16cac55c446b69baf338738e50636846eba17a6c0f1de8c6")
  (:PATH "raw/extra.bin" :SOURCE
   #A((128) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/extra.bin")
   :BYTES 7 :SHA256
   "8eac2ccf9dced01a7be7de3c222660df5eb932cf2ba56ddd798383bd6811236f")
  (:PATH "raw/gzip-tree/original.lisp" :SOURCE
   #A((137) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/original.lisp")
   :BYTES 76 :SHA256
   "27aeeb5011b4c0efa0aa29986ed32346cb0ed104221a137d2f1b26c8ff2ade93")
  (:PATH "raw/gzip-tree/raw.log" :SOURCE
   #A((131) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/raw.log")
   :BYTES 22 :SHA256
   "bed68a942d6ebf2a06917e48038a3e307e4b1efb54272269a3cab4b8422384c5")
  (:PATH "raw/gzip-tree/report.lisp" :SOURCE
   #A((135) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/report.lisp")
   :BYTES 308 :SHA256
   "3cd4231c1d656a61bce9c20fc83f34ee9d2cce09eb4874bee6d779519e305b20")
  (:PATH "raw/gzip-tree/report.lisp.gz" :SOURCE
   #A((138) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-collection/guard-run-02/fixtures/tree/report.lisp.gz")
   :BYTES 95 :SHA256
   "eb463c06cb1d5d2667a12a33eea1b2814996a62a04fd9b4b089a07b92fc1173d"))
 :LIMITS
 (:SHA256-BYTE-COPY-CHECK :RAW-ORIGINALS-PRESERVED
  :FASL-EXCLUDED-FROM-PUBLISHED-MUTATION-TREES
  :NO-REQUIREMENT-OR-RELEASE-PROMOTION))
