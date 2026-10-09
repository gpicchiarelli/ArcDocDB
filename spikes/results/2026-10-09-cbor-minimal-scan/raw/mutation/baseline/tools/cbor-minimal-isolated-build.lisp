;;;; Runner della copia isolata; avvia la build rigorosa originale.
(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   ("/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/baseline/"
    "/Users/gpicchiarelli/.codex/worktrees/cbor-minimal-scan/ArcDocDB/spikes/out/cbor-minimal-scan-mutations-20261009/baseline/fasl/")
   :IGNORE-INHERITED-CONFIGURATION))
(LOAD "tools/build.lisp")
