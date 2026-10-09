(:SCHEMA-VERSION 1 :KIND :INDEPENDENT-C1-FINAL-INTEGRATION-ADDENDUM :SCOPE
 :V3-SOURCE-AND-EXISTING-RECORD-READING :BASELINE
 "cf6091367853ec311fed7b05961a2812fd05a8f1" :UPSTREAM
 "e07d77271758f3134b1977caf394fe38532b54ed" :PREVIOUS-REPORTS-PRESERVED T
 :AUDIT
 (:SCHEMA-VERSION 1 :KIND "independent-worker-v3-byte-audit" :BASELINE
  "cf6091367853ec311fed7b05961a2812fd05a8f1" :UPSTREAM
  "e07d77271758f3134b1977caf394fe38532b54ed" :WORKER-IDENTITY
  ((:PATH "src/execution/handoff.lisp" :SHA256
    "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607"
    :GIT-BLOB "a030e7af1afd6db760088f74615fe2396d928b64" :EQUAL-TO-V1 T)
   (:PATH "src/execution/package.lisp" :SHA256
    "bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643"
    :GIT-BLOB "cdc776ff97c2b500b3b8a802a3b1e0e69fc19cee" :EQUAL-TO-V1 T)
   (:PATH "src/execution/queue.lisp" :SHA256
    "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90"
    :GIT-BLOB "bb4d4d6f222aa360ec64ef2f45ee6ba0524dd2f0" :EQUAL-TO-V1 T)
   (:PATH "src/execution/ready-recycle.lisp" :SHA256
    "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b"
    :GIT-BLOB "58981c7e41ce2694dbfcaed99010a3a53e3c1dea" :EQUAL-TO-V1 T)
   (:PATH "src/execution/ready-types.lisp" :SHA256
    "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f"
    :GIT-BLOB "5b3c26f78d5c4aa53ca200abdd3e0f753f926b54" :EQUAL-TO-V1 T)
   (:PATH "src/execution/ready.lisp" :SHA256
    "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327"
    :GIT-BLOB "4119f86231b7d8698fc3558868ff8a5bcbdf3090" :EQUAL-TO-V1 T)
   (:PATH "src/execution/worker-boundary.lisp" :SHA256
    "4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a"
    :GIT-BLOB "720f16e96203f00e308727b430b66b28689dc7bb" :EQUAL-TO-V1 T)
   (:PATH "src/execution/worker-claim.lisp" :SHA256
    "62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e"
    :GIT-BLOB "4f34d18152d77fbf63bf708ebd0aabac178c3ac1" :EQUAL-TO-V1 T)
   (:PATH "src/execution/worker-run.lisp" :SHA256
    "60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847"
    :GIT-BLOB "b1137f303cb707f8bf322f9deea764f716424d77" :EQUAL-TO-V1 T)
   (:PATH "src/execution/worker-types.lisp" :SHA256
    "62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317"
    :GIT-BLOB "6d36e1f64d79f24c95209fd70551953e40c62335" :EQUAL-TO-V1 T)
   (:PATH "src/execution/writer.lisp" :SHA256
    "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105"
    :GIT-BLOB "8e5102497f628796fa8faffa2085a165496af230" :EQUAL-TO-V1 T)
   (:PATH "tests/execution/handoff.lisp" :SHA256
    "7f6403baba22b175d3047cfd0ba92d7f5ca8313668242a884e5954627f3d5e6e"
    :GIT-BLOB "ba702352ee63241b9ac993b0aca8f162c3deef1b" :EQUAL-TO-V1 T)
   (:PATH "tests/execution/queue.lisp" :SHA256
    "fd71ebd45d556fdb5212129000eee628a003cb624b48607bc744145455a8a722"
    :GIT-BLOB "546d4215f9f63007f632c522f0f8c1e75ac4bbeb" :EQUAL-TO-V1 T)
   (:PATH "tests/execution/ready-recycle.lisp" :SHA256
    "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae"
    :GIT-BLOB "1dff8707436ca52f20f62e9946621ca1037f33d2" :EQUAL-TO-V1 T)
   (:PATH "tests/execution/ready.lisp" :SHA256
    "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e"
    :GIT-BLOB "9f81552333f86fe0b20f2d5e8ba48b20634f5a09" :EQUAL-TO-V1 T)
   (:PATH "tests/execution/support.lisp" :SHA256
    "2b43544d8a1a18fd0e68e3576dc5e33189af52f5c725566b1665632548564a43"
    :GIT-BLOB "b8bac07926727a644f0246f6b57d600332288310" :EQUAL-TO-V1 T)
   (:PATH "tests/execution/threads.lisp" :SHA256
    "e864cd4d99064d2b63823b5541fe123fc8186d632400629fb50841e123b2d359"
    :GIT-BLOB "4212f8cc4be686e923cdbec9ded24f42f1da74ba" :EQUAL-TO-V1 T)
   (:PATH "tests/execution/worker.lisp" :SHA256
    "ccb4c6d8f8f588fe57ba3f9bab3a018f8eb1e9f9f27dd47a99ef444b43d7ad06"
    :GIT-BLOB "2a14573906b94b254712a1e9322058ec1081f6f8" :EQUAL-TO-V1 T)
   (:PATH "tools/writer-worker-bench.lisp" :SHA256
    "aebc3bdec6ac3ee4ad427f31c60a48c0885f917d64343b124f25d4943b3848f1"
    :GIT-BLOB "1208ddc9971179fc3fcb9300a9ba3c22fcd4a8b9" :EQUAL-TO-V1 T)
   (:PATH "tools/writer-worker-mutation.lisp" :SHA256
    "5f8d8135b3a7f8c39ca30bd21e556ea58c68f11959af5c142671b19b7a54df1c"
    :GIT-BLOB "568bccdb1229b124e43e5c1b756cf726ead6fcbc" :EQUAL-TO-V1 T))
  :EXECUTION-FOUNDATION-CSN-UPSTREAM-UNCHANGED T
  :MERGED-ASD-UPSTREAM-PLUS-WORKERS-ONLY T
  :MERGED-README-UPSTREAM-PLUS-WORKER-ROW-ONLY T :MERGED-FILES
  ((:PATH "arcdocdb.asd" :SHA256
    "2a164afdd524e601320b8094e5d25aeb5c3dba081da8157f5849802cd9d28185"
    :GIT-BLOB "e3a6fbb33dfa82eb0022d444fa1a37f63442e938")
   (:PATH "docs/affidabilita/copertura-eccezioni.md" :SHA256
    "8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019"
    :GIT-BLOB "fdb928d6caf051a0341c162d537ca5d6351acfd9")
   (:PATH "docs/implementazione/README.md" :SHA256
    "cfde5ccb1980c15f27f13e0f81db9a574168505cee411c4d93a213d55285eb77"
    :GIT-BLOB "c8380f6b19b90d349f21d0a6ff8c880317ce08c1")
   (:PATH "src/execution/package.lisp" :SHA256
    "bbe8cdb6f7e74d7139f5e472a915cc74b43e34bd27ecac1c5fd364f723a2a643"
    :GIT-BLOB "cdc776ff97c2b500b3b8a802a3b1e0e69fc19cee"))
  :UPSTREAM-PRESERVED-FILE-COUNT 3517 :UPSTREAM-GIT-BLOB-MANIFEST-SHA256
  "7f34c5d424f7a2612befdbfb4697096a1afcf9e79ceeb2dc4805a8bec205e483"
  :UPSTREAM-CONTRACT-DEPENDENCY-CHANGES
  ((:PATH "src/codec/cbor-float-minimal.lisp" :SHA256
    "d8711c16b431ab46653d02103bec2bf644780fea3d5766bb1f2724cf350790db"
    :GIT-BLOB "ca6215b30010d3d2eb90eaa6fd09dd5a9ac7778f")
   (:PATH "src/codec/cbor-minimal.lisp" :SHA256
    "33e54196ecade6bfa476f0781f4c0c8799530a94ee4c7251095d3d788319c449"
    :GIT-BLOB "761302dad1073c841397f6c88d595b114af8d9ef")
   (:PATH "src/codec/cbor-package.lisp" :SHA256
    "e9e69d8d5a4047ef82abc38c95e143a5a5ebbea045516af33f1336d6322eac2b"
    :GIT-BLOB "0d014e499f0862f13674bd934070c166c286f256")
   (:PATH "src/recovery/inventory-build.lisp" :SHA256
    "cc486c3dcb7e83656301a0bea59442f8e654543740b0d6950290450f5e2f415e"
    :GIT-BLOB "60057f6a50c657f016bee3c21c21911b582f86fe")
   (:PATH "src/recovery/inventory-query.lisp" :SHA256
    "8b151ca6e8cee66a4e9035398349e21f0f3b4d1fdb564557ed60d3cf52fe7bfb"
    :GIT-BLOB "47810fb2944b4b5c18d9a9c8e60dfdc1c5f19db4")
   (:PATH "src/recovery/inventory-types.lisp" :SHA256
    "df84220d8e679322bc1a68d9e279e25985e6a07d64c95782191d9085987624e9"
    :GIT-BLOB "68c357d2d522fcabe79284c540c2631e5fa87780")
   (:PATH "src/recovery/manifest-package.lisp" :SHA256
    "0575efe36245b73db5c99f53577f3ed17039b8b796fa1e9095bdb8a0c6cdc5dc"
    :GIT-BLOB "5405bd515df8b26b792bd0430c9ec3dbadce63e7")
   (:PATH "tests/codec/cbor-minimal-edges.lisp" :SHA256
    "67a249100bc6bb68319a0ba4b7fd7cb32ef2a883f27bd49a381178f2be582d70"
    :GIT-BLOB "c6f891dff335a37689ddbfabccf793d2e9f2f143")
   (:PATH "tests/codec/cbor-minimal-support.lisp" :SHA256
    "96e4fedbf7d351fe6bdb57624182dc8ddf8fc547296ac98202801f80a44e785a"
    :GIT-BLOB "774e6cd0bec4a9d2242ad4dede878ffa2afca90c")
   (:PATH "tests/codec/cbor-minimal-threads.lisp" :SHA256
    "e5ecd31dee3f9b26f1577a5cacda5fce78a9a2ff894afb24cfc29e502e3972c2"
    :GIT-BLOB "e613ea025c2a886cdae7fd5e119cf80593c6b72e")
   (:PATH "tests/codec/cbor-minimal.lisp" :SHA256
    "d129cd217f345a707d06090aecc899555fba007044005b4da7a90e0a56236ef3"
    :GIT-BLOB "b863ace9a22e8b7508b7c9d8f91465ebfbcd4e98")
   (:PATH "tests/recovery/inventory-support.lisp" :SHA256
    "2c6e1e6fb7a641c17f08b9dc4f425c86b6feb03f871496d918a08215957bcb27"
    :GIT-BLOB "06eeff2101a97f9abdec6b6f14aa621c2fec29fd")
   (:PATH "tests/recovery/inventory.lisp" :SHA256
    "e6342511c85b67ba9f1bef190bbf141e7e2fbcb92005ea3e43851488988c7fb9"
    :GIT-BLOB "0d5722e4f5ba0025d3a6fb38f0bd056a3ea0b8e9")
   (:PATH "tools/cbor-minimal-bench.lisp" :SHA256
    "8dfc9320885be47cf7bc1a05ecbdc9c9c7796539ea5604560fdc5ea52bcdd123"
    :GIT-BLOB "fd85474e6bbc781a0e5df7c6df3a4891b4da29f7")
   (:PATH "tools/cbor-minimal-mutation.lisp" :SHA256
    "0e23b19b5665983b9b4e0943810245f6ce593051f73aeee0b08e4e0124c8ec41"
    :GIT-BLOB "f9400b3b12b5f31189c28b64782e29cf16e8b6e4")
   (:PATH "tools/foundation-coverage.lisp" :SHA256
    "6d5024519fc90c9e0a6ddc4bf7d59f6da4d558ae582a8fc8261837a943b619d2"
    :GIT-BLOB "554b840090373179043aa39dd6491cd35433552a")
   (:PATH "tools/foundation-mutation.lisp" :SHA256
    "88ce773e9c0f1c3c64cddb6a84f21df178228792d43a867df05f43609bdd1a1d"
    :GIT-BLOB "fd285d0ae73d312d7234a2a142d16897c9adbcf7"))
  :COPY-RECEIPT-SHA256
  "0d30128b2f5384e2a765c0c6b3894fc22aedbfdec5c0554846a1cdc357b3f92b"
  :HISTORICAL-COPY-TARGETS-CHECKED 101 :MUTABLE-DOCUMENT-SNAPSHOTS
  ((:PATH
    "/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-metodo.md"
    :HISTORICAL-SHA256
    "e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7"
    :CURRENT-SHA256
    "e5bc559f5a317b5dea8e191f9672a2ede1c33aa3d61181a97a957604917a1cf7"
    :UNCHANGED T)
   (:PATH
    "/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker.md"
    :HISTORICAL-SHA256
    "404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a"
    :CURRENT-SHA256
    "404a7f863e252ca77c62beae9de3f662b2ace767f5592b72a21a0b0580a2f57a"
    :UNCHANGED T)
   (:PATH
    "/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-decisioni.md"
    :HISTORICAL-SHA256
    "d19173a7a0216148f2f8e734802d39289a59ede98bb33456a43ecddc660b44df"
    :CURRENT-SHA256
    "d19173a7a0216148f2f8e734802d39289a59ede98bb33456a43ecddc660b44df"
    :UNCHANGED T)
   (:PATH
    "/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-risultati.md"
    :HISTORICAL-SHA256
    "e8d2a90ab6e437dea1bc8102a6504d6f115863b1bb407f62bc61a00503271c55"
    :CURRENT-SHA256
    "db82651f35f5a43b6fb96a4e3d8d79a3c06db4d936751f9a6ac0be629afabda1"
    :UNCHANGED NIL)
   (:PATH
    "/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/implementazione/writer-worker-revisione.md"
    :HISTORICAL-SHA256
    "c3b92211867cafa233f9ef07524107c9ebbe626bf1f98c20987b736a80357c5c"
    :CURRENT-SHA256
    "c3b92211867cafa233f9ef07524107c9ebbe626bf1f98c20987b736a80357c5c"
    :UNCHANGED T)
   (:PATH
    "/Users/gpicchiarelli/.codex/worktrees/writer-worker/ArcDocDB/docs/affidabilita/copertura-eccezioni.md"
    :HISTORICAL-SHA256
    "8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019"
    :CURRENT-SHA256
    "8cc4e470868e258cec111471201ac0825fcaa8215d7419b7a3e9381680bea019"
    :UNCHANGED T))
  :PRIOR-REPORTS
  ((:PATH
    "spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale.lisp"
    :SHA256 "a5807e8cb34c050eccc6c356e915f59cd53ef7528dd439df9fda204269f71562"
    :PRESERVED T)
   (:PATH
    "spikes/results/2026-10-09-writer-worker/revisione-indipendente-iniziale-chiusa.lisp"
    :SHA256 "bdcfb920c82d244c5c113c27949bf1ff0c970176786f46e532cff4dde53fd1df"
    :PRESERVED T)
   (:PATH
    "spikes/results/2026-10-09-writer-worker/revisione-indipendente-finale.lisp"
    :SHA256 "2d66711d9735af8a57cfce2baa6389f08bfc9922892d6abe4a91cbe1925a72d1"
    :PRESERVED T)
   (:PATH
    "spikes/results/2026-10-09-writer-worker/revisione-indipendente-integrazione.lisp"
    :SHA256 "2ec65640f828df4c681620a21c190beaa9c64a25480836422eb2c0c00705d2ed"
    :PRESERVED T))
  :PREPARATION-SHA256
  "fb334af1b40f16290d9bda5c3ff99597f511e18e0f7bebc7a7a27dd394623ffa" :JUDGEMENT
  "CBOR uses its own package and pure local readers; execution, conditions and binary contracts remain unchanged."
  :LIMITS
  ("byte and namespace/dependency review, not a second CBOR qualification"
   "no worker campaign rerun or new coverage/MC-DC inference"
   "no whole-pool liveness, wait/park, Series-fault or durability claim"))
 :READER-ATTEMPTS-PRESERVED
 (("4000550739-command-16126-0" :FAILED :STABLE :PATH-ALIAS-NORMALIZATION)
  ("4000550806-command-19882-0" :FAILED :STABLE
   :MUTABLE-WT-DOCUMENT-ASSUMPTION)
  ("4000550861-command-22217-0" :FAILED :STABLE :COMMAND-WRAPPER-ASSUMPTION))
 :READER-PYTHON-SHA256
 "95f77aabc50eb546247c0963a02298d96d93ba9a1d6e06989210440eb5f8c45a" :FULL-CHECK
 (:PROCESS "4000550386-command-90070-0" :PATH
  "spikes/out/4000550386-command-90070-0/report.lisp" :SHA256
  "575d62253b6387a4bb9572465aafbfe4e800d018a69b0cc62c9e5f4450955d28" :COMMAND
  (#A((3) BASE-CHAR . "env")
   #A((148) BASE-CHAR
      . "XDG_CACHE_HOME=/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/spikes/out/worker-final-integration-cache")
   #A((35) BASE-CHAR . "SBCL=sbcl --dynamic-space-size 4096")
   #A((4) BASE-CHAR . "make") #A((10) BASE-CHAR . "check-core"))
  :STATUS :OK :SOURCE-CONSISTENCY :STABLE :EXIT-CODE 0 :WALL-SECONDS
  164.552415d0 :STDOUT-SUMMARY
  ("build e test: nessun avviso, tutti i controlli superati"
   "68 file, 0 violazioni"
   "sbcl --dynamic-space-size 4096 --script tools/check-links.lisp ."
   "232 file, 2044 link controllati, 0 rotti"))
 :LIMITS
 (:NO-SOURCE-OR-DOCUMENT-EDIT :NO-PRODUCT-TEST-RERUN
  :SCOPED-WORKER-CAMPAIGNS-RETAIN-CF60913
  :PRIOR-DOC-SNAPSHOTS-RETAIN-THEIR-OWN-RECORDS
  :NO-NEW-COVERAGE-OR-MCDC-QUALIFICATION
  :NO-WHOLE-POOL-OR-SERIES-CONTROLLER-QUALIFICATION))
