(:SCHEMA-VERSION 1 :KIND :ORIGINAL-COMMAND-ARCHIVE :METADATA-POLICY
 :READ-WITHOUT-RESULT-INFERENCE :PROCESSES
 ((:LABEL "collection" :RECORD-PATH "processes/collection/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((47) BASE-CHAR . "spikes/out/cbor-minimal-collection/collect.lisp")
    #A((9) BASE-CHAR . "--collect")
    #A((40) BASE-CHAR . "spikes/out/scan-collection-manifest.lisp")
    #A((44) BASE-CHAR . "spikes/results/2026-10-09-cbor-minimal-scan/")))
  (:LABEL "manifest-v2" :RECORD-PATH "processes/manifest-v2/report.lisp"
   :STATUS :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((51) BASE-CHAR
       . "spikes/out/cbor-minimal-scan-build-manifest-v2.lisp")))
  (:LABEL "initial-publication-audit" :RECORD-PATH
   "processes/initial-publication-audit/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/check-command-archive.lisp")
    #A((9) BASE-CHAR . "--archive")
    #A((44) BASE-CHAR . "spikes/results/2026-10-09-cbor-minimal-scan/")))
  (:LABEL "full-check" :RECORD-PATH "processes/full-check/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((55) BASE-CHAR
       . "/Applications/Xcode.app/Contents/Developer/usr/bin/make")
    #A((10) BASE-CHAR . "check-core")))
  (:LABEL "data-audit-first" :RECORD-PATH
   "processes/data-audit-first/report.lisp" :STATUS :FAILED :EXIT-CODE 1
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((18) BASE-CHAR . "--disable-debugger") #A((8) BASE-CHAR . "--script")
    #A((45) BASE-CHAR . "spikes/out/cbor-minimal-scan-data-reader.lisp")
    #A((54) BASE-CHAR
       . "spikes/out/cbor-minimal-scan-data-audit-attempt-1.lisp")
    #A((49) BASE-CHAR . "spikes/out/4000552318-command-65001-0/report.lisp")
    #A((49) BASE-CHAR . "spikes/out/4000552339-command-65155-0/report.lisp")
    #A((48) BASE-CHAR . "spikes/out/cbor-minimal-scan-mutations-20261009/")
    #A((49) BASE-CHAR . "spikes/out/4000552339-command-65156-0/report.lisp")
    #A((47) BASE-CHAR . "spikes/out/cbor-minimal-scan-coverage-20261009/")
    #A((57) BASE-CHAR
       . "spikes/out/cbor-minimal-scan-coverage-state-original.lisp")))
  (:LABEL "data-audit-second" :RECORD-PATH
   "processes/data-audit-second/report.lisp" :STATUS :FAILED :EXIT-CODE 1
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((18) BASE-CHAR . "--disable-debugger") #A((8) BASE-CHAR . "--script")
    #A((45) BASE-CHAR . "spikes/out/cbor-minimal-scan-data-reader.lisp")
    #A((54) BASE-CHAR
       . "spikes/out/cbor-minimal-scan-data-audit-attempt-2.lisp")
    #A((49) BASE-CHAR . "spikes/out/4000552318-command-65001-0/report.lisp")
    #A((49) BASE-CHAR . "spikes/out/4000552339-command-65155-0/report.lisp")
    #A((48) BASE-CHAR . "spikes/out/cbor-minimal-scan-mutations-20261009/")
    #A((49) BASE-CHAR . "spikes/out/4000552339-command-65156-0/report.lisp")
    #A((47) BASE-CHAR . "spikes/out/cbor-minimal-scan-coverage-20261009/")
    #A((57) BASE-CHAR
       . "spikes/out/cbor-minimal-scan-coverage-state-original.lisp")))
  (:LABEL "data-audit" :RECORD-PATH "processes/data-audit/report.lisp" :STATUS
   :OK :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((18) BASE-CHAR . "--disable-debugger") #A((8) BASE-CHAR . "--script")
    #A((45) BASE-CHAR . "spikes/out/cbor-minimal-scan-data-reader.lisp")
    #A((54) BASE-CHAR
       . "spikes/out/cbor-minimal-scan-data-audit-attempt-3.lisp")
    #A((49) BASE-CHAR . "spikes/out/4000552318-command-65001-0/report.lisp")
    #A((49) BASE-CHAR . "spikes/out/4000552339-command-65155-0/report.lisp")
    #A((48) BASE-CHAR . "spikes/out/cbor-minimal-scan-mutations-20261009/")
    #A((49) BASE-CHAR . "spikes/out/4000552339-command-65156-0/report.lisp")
    #A((47) BASE-CHAR . "spikes/out/cbor-minimal-scan-coverage-20261009/")
    #A((57) BASE-CHAR
       . "spikes/out/cbor-minimal-scan-coverage-state-original.lisp")))
  (:LABEL "coverage-byte-audit" :RECORD-PATH
   "processes/coverage-byte-audit/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((18) BASE-CHAR . "--disable-debugger") #A((8) BASE-CHAR . "--script")
    #A((53) BASE-CHAR
       . "spikes/out/cbor-minimal-scan-data-summary-reader.lisp")))
  (:LABEL #A((16) BASE-CHAR . "final-collection") :RECORD-PATH
   "processes/final-collection/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((47) BASE-CHAR . "spikes/out/cbor-minimal-collection/collect.lisp")
    #A((9) BASE-CHAR . "--collect")
    #A((46) BASE-CHAR . "spikes/out/scan-final-collection-manifest.lisp")
    #A((50) BASE-CHAR . "spikes/results/2026-10-09-cbor-minimal-scan-final/")))
  (:LABEL #A((20) BASE-CHAR . "final-links-evidence") :RECORD-PATH
   "processes/final-links-evidence/report.lisp" :STATUS :OK :EXIT-CODE 0
   :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "make") #A((5) BASE-CHAR . "links")
    #A((8) BASE-CHAR . "evidence")))
  (:LABEL #A((31) BASE-CHAR . "publication-audit-before-append") :RECORD-PATH
   "processes/publication-audit-before-append/report.lisp" :STATUS :OK
   :EXIT-CODE 0 :SOURCE-CONSISTENCY :STABLE :COMMAND
   (#A((4) BASE-CHAR . "sbcl") #A((10) BASE-CHAR . "--noinform")
    #A((13) BASE-CHAR . "--no-userinit") #A((12) BASE-CHAR . "--no-sysinit")
    #A((8) BASE-CHAR . "--script")
    #A((32) BASE-CHAR . "tools/check-command-archive.lisp")
    #A((9) BASE-CHAR . "--archive")
    #A((50) BASE-CHAR
       . "spikes/results/2026-10-09-cbor-minimal-scan-final/"))))
 :FILES
 ((:PATH "collection-manifest.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/scan-final-collection-manifest.lisp")
   :BYTES 9115 :SHA256
   "8ac7b1950f76e03c410acdd8ac1ceffc2dae87a18e626c0f9b21fa3fd4fe2e80")
  (:PATH "collection-source.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-collection/collect.lisp")
   :BYTES 9657 :SHA256
   "09adae7145af41bbb8bd6fd91d33d5cbdfa47d4b10908f004d46b70f1ae6597a")
  (:PATH "processes/collection/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552649-command-74116-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "708260df62b05f940e1ad31b64c8aa668252d4a279ae7fad7885cecddb9490c6")
  (:PATH "processes/collection/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552649-command-74116-0/report.lisp")
   :BYTES 111657 :SHA256
   "4c61203567926ff3169d71e732bcf4863600fd740e5d6215aeff0b9c6a0eff93")
  (:PATH "processes/coverage-byte-audit/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000553094-command-89492-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "a8a0651a633c6b802a4370aa30d7ff99a9d699984be74d80a9c803ceaa40cb1b")
  (:PATH "processes/coverage-byte-audit/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000553094-command-89492-0/report.lisp")
   :BYTES 123532 :SHA256
   "92666e5a456c2f65ae053dd8077cdca72fb97deb656fcca8c7e728f19f57883f")
  (:PATH "processes/data-audit-first/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552876-command-80674-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "953efd9002bdcda3fbbfb7455f304e65c3133436df0fed0f0a4209085e533452")
  (:PATH "processes/data-audit-first/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552876-command-80674-0/report.lisp")
   :BYTES 112353 :SHA256
   "96417ed1f70049e8df45f827892e441e04b260b9317b528d0f8ae8ffce3db69b")
  (:PATH "processes/data-audit-second/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552959-command-83078-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "478d685327833441c2e1b16594d409080743d079a7139d30940b2dedb425b5ce")
  (:PATH "processes/data-audit-second/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552959-command-83078-0/report.lisp")
   :BYTES 112391 :SHA256
   "368f6e1f65e852781ccf3fb809eb4e5564ca29d1dd692a1e9961f3f3c4bb01be")
  (:PATH "processes/data-audit/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000553029-command-85919-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "45b162c8a530c831754fb01cee8b4a852ed359d00f1ebee3b209e5b042920594")
  (:PATH "processes/data-audit/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000553029-command-85919-0/report.lisp")
   :BYTES 112176 :SHA256
   "bd7a39daf8a74665a29b3212d34e8191c116ed6a3ec24042f944b3e28ea4d38b")
  (:PATH "processes/full-check/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552850-command-80037-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "b0ef089d4e7ffe1498c1efb41d0bec55cbe437a7742e02ae1a17656d0e528f7e")
  (:PATH "processes/full-check/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552850-command-80037-0/report.lisp")
   :BYTES 303709 :SHA256
   "c40698535a3f286fe1355011401b371fbc63d110f1c043518540ff38ca664301")
  (:PATH "processes/initial-publication-audit/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552733-command-77433-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "d4129a4751c4bfc2a1f813c262e8dd297f9f17bda96460ab1450ed6622895531")
  (:PATH "processes/initial-publication-audit/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552733-command-77433-0/report.lisp")
   :BYTES 115499 :SHA256
   "6826abda30bf527ad69fde1311cfe1a5d21d781bb64b4f376b1f8e196f0346c0")
  (:PATH "processes/manifest-v2/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552734-command-77489-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "309b2f192929725e528e9ad2ff573962c5f999d96c6d6a9c8d27cd6406828b37")
  (:PATH "processes/manifest-v2/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552734-command-77489-0/report.lisp")
   :BYTES 111545 :SHA256
   "843c0674b040f7c9efed0b6bbcec8ded3771f3865eec420d98f9f9952b0c2bf0")
  (:PATH "raw/cbor-minimal-mutation-before-upstream.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-mutation-before-upstream.lisp")
   :BYTES 21628 :SHA256
   "d237ce344b2c8087689aa4d55b0b19348decf45ec7344963c4bbe7a3608b0821")
  (:PATH "raw/cbor-minimal-mutation-integration-reader.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-mutation-integration-reader.lisp")
   :BYTES 4440 :SHA256
   "a8926dc7cf1b881441ba54a4293ed790276c04ea2c7d9bedb1636c95f88bbe89")
  (:PATH "raw/cbor-minimal-mutation-upstream-engine.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-mutation-upstream-engine.lisp")
   :BYTES 29386 :SHA256
   "e9c3a57a430880dab8c01cf63d607ea882cca5df402276bc6b7e583a6a4f5da7")
  (:PATH "raw/cbor-minimal-scan-bench-arity-finding.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-bench-arity-finding.lisp")
   :BYTES 970 :SHA256
   "a64625fe0286cea0c2b0ac7ba03ba2f53c61463a78f70ab83586e1a7d202cbd2")
  (:PATH "raw/cbor-minimal-scan-bench-before-arity.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-bench-before-arity.lisp")
   :BYTES 10125 :SHA256
   "41121c679169eff7857231f675b3eff81d586e084cd7b0d1791c9a000d7e021d")
  (:PATH "raw/cbor-minimal-scan-build-manifest-v2.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-build-manifest-v2.lisp")
   :BYTES 4268 :SHA256
   "100733db631d4f52e2a594591fd2d1b64fc59ebe067edeeb806cac298858690e")
  (:PATH "raw/cbor-minimal-scan-build-manifest.lisp" :SOURCE
   #A((113) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-build-manifest.lisp")
   :BYTES 4241 :SHA256
   "a7f67c10a09b1e3fe443b66d914008c0d6f2d2601d6be26eed4769fe816070a9")
  (:PATH "raw/cbor-minimal-scan-coverage-transcript.stderr.log" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-transcript.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-scan-coverage-transcript.stdout.log" :SOURCE
   #A((124) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-coverage-transcript.stdout.log")
   :BYTES 4211 :SHA256
   "44e6aecec515084afab847125d1ea76e6cfc4ff8efef91bb5f107aaffe424b9c")
  (:PATH "raw/cbor-minimal-scan-data-audit-attempt-1.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-audit-attempt-1.lisp")
   :BYTES 3285 :SHA256
   "25c7ed213499108606872b3098a3b37d827e3bb878303ea09c24191e9f76a3f6")
  (:PATH "raw/cbor-minimal-scan-data-audit-attempt-2.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-audit-attempt-2.lisp")
   :BYTES 37543 :SHA256
   "151fc8ef3dbcd5801a44c035169ca2fa32a71de25b41db6e2ea14b1ba6870e93")
  (:PATH "raw/cbor-minimal-scan-data-audit-attempt-3.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-audit-attempt-3.lisp")
   :BYTES 37378 :SHA256
   "e0445b0d681933f8207c56b2a693d057b6a7c19c21ae90ddf50b807bb107122a")
  (:PATH "raw/cbor-minimal-scan-data-bytewise-supplement.lisp" :SOURCE
   #A((123) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-bytewise-supplement.lisp")
   :BYTES 930 :SHA256
   "131896ceff05dbcc20797b25a66f7c8940b9d1922d8a0d38ff635a03de9e8e9b")
  (:PATH "raw/cbor-minimal-scan-data-reader-attempt-1.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-attempt-1.lisp")
   :BYTES 29710 :SHA256
   "fcf2c8a1102de11d9e774c46c22dc3ff9a1245c4d10fd353d9f84e0b6ca9a8f9")
  (:PATH "raw/cbor-minimal-scan-data-reader-attempt-2.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-attempt-2.lisp")
   :BYTES 30162 :SHA256
   "47115928cb7e4884b40c940bbecadeb3497f04d2efaa523af4199f57307af634")
  (:PATH "raw/cbor-minimal-scan-data-reader-attempt-3.lisp" :SOURCE
   #A((120) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-attempt-3.lisp")
   :BYTES 30386 :SHA256
   "723b1a21b40b95f492a8e9331a49d67fc3f659872dc97da0575430fb8764100c")
  (:PATH "raw/cbor-minimal-scan-data-reader-attempts.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-attempts.lisp")
   :BYTES 3696 :SHA256
   "f8720030bbe7a446c3f65cbb891041af6b5a7e775e43a40e086f0dcfda4a6dbf")
  (:PATH "raw/cbor-minimal-scan-data-reader-runtime-attempt-1.stderr.log"
   :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-1.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-scan-data-reader-runtime-attempt-1.stdout.log"
   :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-1.stdout.log")
   :BYTES 610 :SHA256
   "7de9b6066340e7756dfda907fc5fc3cf74318bb802d91f9df508b448ff9adaa4")
  (:PATH "raw/cbor-minimal-scan-data-reader-runtime-attempt-2.stderr.log"
   :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-2.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-scan-data-reader-runtime-attempt-2.stdout.log"
   :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-2.stdout.log")
   :BYTES 610 :SHA256
   "1f509bb2a584d24b5811130ce52df16dd48eebb628a3a835b86ecda1a2b6f1de")
  (:PATH "raw/cbor-minimal-scan-data-reader-runtime-attempt-3.stderr.log"
   :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-3.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-scan-data-reader-runtime-attempt-3.stdout.log"
   :SOURCE
   #A((134) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-runtime-attempt-3.stdout.log")
   :BYTES 606 :SHA256
   "36a2dc7695d16b0fa368235895545aeae0f629be6fcf4f273675ba3f7ed40872")
  (:PATH "raw/cbor-minimal-scan-data-reader-syntax-attempt-1.stderr.log"
   :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-syntax-attempt-1.stderr.log")
   :BYTES 6198 :SHA256
   "c020ef7d7a25ee4a1149cc789c7d79335eb927da0dbe0f123d1513c115b2b2c3")
  (:PATH "raw/cbor-minimal-scan-data-reader-syntax-attempt-1.stdout.log"
   :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-syntax-attempt-1.stdout.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-scan-data-reader-syntax-attempt-2.stderr.log"
   :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-syntax-attempt-2.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-scan-data-reader-syntax-attempt-2.stdout.log"
   :SOURCE
   #A((133) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader-syntax-attempt-2.stdout.log")
   :BYTES 34 :SHA256
   "637b0429567b57c155d50efc039d5876c4a91324e9b573fbb4eaedc06a358118")
  (:PATH "raw/cbor-minimal-scan-data-reader.lisp" :SOURCE
   #A((110) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-reader.lisp")
   :BYTES 30386 :SHA256
   "723b1a21b40b95f492a8e9331a49d67fc3f659872dc97da0575430fb8764100c")
  (:PATH "raw/cbor-minimal-scan-data-summary-reader.lisp" :SOURCE
   #A((118) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-summary-reader.lisp")
   :BYTES 4254 :SHA256
   "02d652d96c25c40dc04416df7f65c0561c3dd4e9ba60fb44bcc17d97cb12231d")
  (:PATH "raw/cbor-minimal-scan-data-summary.stderr.log" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-summary.stderr.log")
   :BYTES 0 :SHA256
   "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855")
  (:PATH "raw/cbor-minimal-scan-data-summary.stdout.log" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-data-summary.stdout.log")
   :BYTES 254 :SHA256
   "62fa6d6d344536ac8b792262b9c7ea8ef9056589007a5674b583001f2e7da987")
  (:PATH "raw/cbor-minimal-scan-final-build-manifest.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-final-build-manifest.lisp")
   :BYTES 1652 :SHA256
   "3cd292a8d763cf4351c47e1badbfc063503d5bf04e15f0f6d028b338f73e7a81")
  (:PATH "raw/cbor-minimal-scan-full-check.stderr.log" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-full-check.stderr.log")
   :BYTES 80433 :SHA256
   "760a0f1523ac0d42f7d904b221ddd8d4ca31ea68590a15879c192aaa36fca479")
  (:PATH "raw/cbor-minimal-scan-full-check.stdout.log" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-full-check.stdout.log")
   :BYTES 111150 :SHA256
   "ced238f01e87386b560394f93d8c81a6f112c3820789d2022b28a80b0f6d3338")
  (:PATH "raw/cbor-minimal-scan-independent-review.lisp" :SOURCE
   #A((117) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-independent-review.lisp")
   :BYTES 6576 :SHA256
   "23923b771ac5f8a1d5c96d5f89669e3544d522f7386db70546c1680ede95cf7a")
  (:PATH "raw/cbor-minimal-scan-manifest-finding.lisp" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-manifest-finding.lisp")
   :BYTES 499 :SHA256
   "ce322fca2fa6246e3f8774776cdf0a8717d5d4248867eb1ae915db3522662298")
  (:PATH "raw/cbor-minimal-scan-preliminary.stderr.log" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-preliminary.stderr.log")
   :BYTES 80283 :SHA256
   "dde287a01823beadf3858dc43bcaf73e45137f7c414ab47c5c7a96cb178608f3")
  (:PATH "raw/cbor-minimal-scan-preliminary.stdout.log" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-preliminary.stdout.log")
   :BYTES 93776 :SHA256
   "bfb3137cda6b780509d10834d4b09ce99e8a39b1ada8fefab1fec1928019ce81")
  (:PATH "raw/cbor-minimal-scan-read-command.lisp" :SOURCE
   #A((111) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-read-command.lisp")
   :BYTES 1231 :SHA256
   "437414e53f3beffaa2a5a8d806f62b11b164fe8c424eed655c411fd05f43e953")
  (:PATH "raw/cbor-minimal-scan-test-audit-reader-final.log" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-test-audit-reader-final.log")
   :BYTES 67 :SHA256
   "78125618a4466d024ce6f80c62ca34e26c58fc75a92481961fcec7e2f0bc6584")
  (:PATH "raw/cbor-minimal-scan-test-audit-reader-first.lisp" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-test-audit-reader-first.lisp")
   :BYTES 11872 :SHA256
   "2cad20551c18cfde309934ee67ce3f6d68a0f6442d569ae47474efbfe82cffb1")
  (:PATH "raw/cbor-minimal-scan-test-audit-reader-first.log" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-test-audit-reader-first.log")
   :BYTES 6014 :SHA256
   "73db58a7739dd0e448e2a0ec2dfe47fab2d92f87667ea51fb3032d0ee39b9f1a")
  (:PATH "raw/cbor-minimal-scan-test-audit-reader-syntax-v2.log" :SOURCE
   #A((125) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-test-audit-reader-syntax-v2.log")
   :BYTES 39 :SHA256
   "8f87e53c4550bad025baca67d48e7b55f99a77dccf522f63c45e29485b978263")
  (:PATH "raw/cbor-minimal-scan-test-audit-reader-syntax.log" :SOURCE
   #A((122) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-test-audit-reader-syntax.log")
   :BYTES 6021 :SHA256
   "b68cf8a29a5dd29d212c490bb8e0e87a167fb86f5efa8a7b3d375c3abb37d716")
  (:PATH "raw/cbor-minimal-scan-test-audit-reader.lisp" :SOURCE
   #A((116) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-test-audit-reader.lisp")
   :BYTES 13636 :SHA256
   "75075d04d355b1d6de3d165688edac8b0cff52bdb7db93d30eec0f32fcac1faf")
  (:PATH "raw/cbor-minimal-scan-test-audit.lisp" :SOURCE
   #A((109) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-test-audit.lisp")
   :BYTES 12554 :SHA256
   "d9d6c8a1757e96291c44f0d5114ac2fff9f05a825ea293942e0ff161082692b1")
  (:PATH "raw/full-spikes/SPK-01.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-01.lisp")
   :BYTES 27227 :SHA256
   "2e11f41850ebaf791b0eff3fedbded838053614e4f68b9f78c921adf91b3fe1a")
  (:PATH "raw/full-spikes/SPK-02.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-02.lisp")
   :BYTES 1607 :SHA256
   "1eb7b3c1ebadb88d1252cc6957fab58bca517ab54d906c303b05ffba7a3ce375")
  (:PATH "raw/full-spikes/SPK-03.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-03.lisp")
   :BYTES 3646 :SHA256
   "8cfcb42954378062258cf178c4413814747bfca7463f370587487f60bf522250")
  (:PATH "raw/full-spikes/SPK-04.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-04.lisp")
   :BYTES 6750 :SHA256
   "7a6cffb271ffb3638d4e60ef3201337d0b87993218d29aa2c54ca0276a0a6241")
  (:PATH "raw/full-spikes/SPK-05.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-05.lisp")
   :BYTES 10067 :SHA256
   "0ec0695e4451d492f05951c9426d5e12ac32237e9eb7e8d80ec45d851e804707")
  (:PATH "raw/full-spikes/SPK-06.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-06.lisp")
   :BYTES 24136 :SHA256
   "95b6c1ab2d53d4dad7e1f07912c8acf409566136268dd998da82eec94d3388da")
  (:PATH "raw/full-spikes/SPK-07.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-07.lisp")
   :BYTES 318 :SHA256
   "218ae2f8ed5e0d96079cc2541eb35e21269f89827f6ff9fedb3a1953767f9d09")
  (:PATH "raw/full-spikes/SPK-07.lisp.gz" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-07.lisp.gz")
   :BYTES 410626 :SHA256
   "f8527b27d1f21748a9d6ad278b6dc6578eca3f1deba83a10a17aa2b8807b6940")
  (:PATH "raw/full-spikes/SPK-08.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-08.lisp")
   :BYTES 292334 :SHA256
   "20f460971ddca8ff3f16e6f900e54f56f8140eef447c0f533ffd7306bc38e577")
  (:PATH "raw/full-spikes/SPK-09.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-09.lisp")
   :BYTES 2472 :SHA256
   "8a3284ec54547955eabd80b883f2a783beabbccf1dbd251744a297121c86bb53")
  (:PATH "raw/full-spikes/SPK-10.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/SPK-10.lisp")
   :BYTES 22977 :SHA256
   "46595ed5596e5289c5916987b38f2760ec89dbce76bd063d25ebeb25c8d1c183")
  (:PATH "raw/full-spikes/conservazione.lisp" :SOURCE
   #A((119) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/conservazione.lisp")
   :BYTES 2306 :SHA256
   "2805bdd092135eb7d076e07cce687199a837d916e0e49e076af8cecce6164f13")
  (:PATH "raw/full-spikes/report.lisp" :SOURCE
   #A((112) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/report.lisp")
   :BYTES 318 :SHA256
   "f3f038e1c950a0f82494119f8d9d3af43b1260c7c2633c6c5c555d55b9da51ac")
  (:PATH "raw/full-spikes/report.lisp.gz" :SOURCE
   #A((115) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000552955-check-82980-0/report.lisp.gz")
   :BYTES 467159 :SHA256
   "d65d7a467ae8cc2ccfabfc6ee7fc038e9f3b391afbbb1c52cb6b5d9ee0ec864d")
  (:PATH "processes/final-collection/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000553343-command-95568-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "6b4e5d158f777971e9ef2aeca8ba6c349b0fd6cffaf162a008c62ba554d85657")
  (:PATH "processes/final-collection/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000553343-command-95568-0/report.lisp")
   :BYTES 112123 :SHA256
   "787dbd3d310f88cb776c0f189030742599bfdf6e1536b9f59528a64f6852fafa")
  (:PATH "processes/final-links-evidence/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000553384-command-98787-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "dd9705c4c28298f12a87b8d8be995d3af9a3c7bb55a59ca625de021d0b9de6c0")
  (:PATH "processes/final-links-evidence/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000553384-command-98787-0/report.lisp")
   :BYTES 112161 :SHA256
   "f17a0bacc01825bf888257348d904b149977533646909a04d11e2e2c799c6c01")
  (:PATH "processes/publication-audit-before-append/conservazione.lisp" :SOURCE
   #A((121) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000553385-command-98883-0/conservazione.lisp")
   :BYTES 1156 :SHA256
   "36e13c701c6a098eb37493fb98b7613d7d8dba9baf0acea62cfa8615405a7337")
  (:PATH "processes/publication-audit-before-append/report.lisp" :SOURCE
   #A((114) BASE-CHAR
      . "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/4000553385-command-98883-0/report.lisp")
   :BYTES 116567 :SHA256
   "fab0897e290d4b9e8ea89cf7bf9c5ad1199e1244dcad69b6fa9b8829c585d80c"))
 :LIMITS
 (:SHA256-BYTE-COPY-CHECK :RAW-ORIGINALS-PRESERVED
  :FASL-EXCLUDED-FROM-PUBLISHED-MUTATION-TREES
  :NO-REQUIREMENT-OR-RELEASE-PROMOTION))
