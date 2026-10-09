(:SCHEMA-VERSION 1 :KIND :EVIDENCE-CATALOG :DATE "2026-10-09" :PATH-BASE
 "spikes/results/2026-10-09-manifest/" :ENTRIES
 ((:KIND :COMMAND-VERIFICATION :ARTIFACT "build-finale.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "build-fixture-fallito.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "catalogo-verifica-finale.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "catalogo-verifica-intermedia.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "catalogo-verifica-prima-spike.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "check-finale.lisp")
  (:KIND :RAW-COVERAGE :ARTIFACT "copertura-dati.lisp" :PROCESS-ARTIFACT
   "copertura.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "copertura.lisp")
  (:KIND :DEVELOPMENT-DIAGNOSTIC :ARTIFACT
   "diagnostica-fixture-preliminare.lisp")
  (:KIND :C1-REVIEW :ARTIFACT "letture-c1.lisp")
  (:KIND :MUTATION-OUTPUT :ARTIFACT "mutazioni-decisions-dati.lisp"
   :PROCESS-ARTIFACT "mutazioni-decisions-regressione.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT
   "mutazioni-decisions-regressione.lisp")
  (:KIND :MUTATION-OUTPUT :ARTIFACT "mutazioni-manifest-dati.lisp"
   :PROCESS-ARTIFACT "mutazioni-manifest.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "mutazioni-manifest.lisp")
  (:KIND :DEVELOPMENT-DIAGNOSTIC :ARTIFACT
   "mutazioni-self-test-preliminare.lisp")
  (:KIND :PARALLEL-SELF-TEST-OUTPUT :ARTIFACT "self-test-finale-dati.lisp"
   :PROCESS-ARTIFACT "self-test-finale.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "self-test-finale.lisp")
  (:KIND :PARALLEL-SELF-TEST-OUTPUT :ARTIFACT
   "self-test-prima-review-tool-dati.lisp" :PROCESS-ARTIFACT
   "self-test-prima-review-tool.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "self-test-prima-review-tool.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "spike-SPK-01.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "spike-SPK-02.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "spike-SPK-03.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "spike-SPK-04.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "spike-SPK-05.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "spike-SPK-06.lisp")
  (:KIND :COMPRESSED-ORIGINAL-RECORD :ARTIFACT "spike-SPK-07.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "spike-SPK-08.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "spike-SPK-09.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "spike-SPK-10.lisp")
  (:KIND :COMPRESSED-ORIGINAL-RECORD :ARTIFACT "spike-report.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "statici-iniziali.lisp"))
 :LIMITS (:STRUCTURE-AND-PRESENCE-ONLY :NO-AUTOMATIC-GATE-PROMOTION))
