;;;; Runner della copia isolata; avvia la build rigorosa originale.
(REQUIRE :ASDF)
(ASDF/OUTPUT-TRANSLATIONS:INITIALIZE-OUTPUT-TRANSLATIONS
 '(:OUTPUT-TRANSLATIONS
   ("/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/"
    "/Users/gpicchiarelli/.codex/worktrees/cbor-preferred/ArcDocDB/spikes/out/cbor-minimal-mutations/3/fasl/")
   :IGNORE-INHERITED-CONFIGURATION))
(LOAD "tools/build.lisp")
