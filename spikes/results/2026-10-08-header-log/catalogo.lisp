(:SCHEMA-VERSION 1 :KIND :EVIDENCE-CATALOG :DATE "2026-10-08" :PATH-BASE
 "spikes/results/2026-10-08-header-log/" :METADATA-POLICY
 :READ-FROM-ARTIFACT-WITHOUT-INFERENCE :ENTRIES
 ((:KIND :CHECK :FORMATS (1 2) :ARTIFACT "test-e-lint.lisp")
  (:KIND :CHECK :FORMATS (1 2) :ARTIFACT "test-e-lint-finali.lisp")
  (:KIND :TOOL-SELF-TEST :FORMATS NIL :ARTIFACT "copertura-self-test.lisp")
  (:KIND :COVERAGE :FORMATS (1 2) :VARIANT :INITIAL :ARTIFACT "copertura.lisp")
  (:KIND :RAW-COVERAGE :FORMATS (1 2) :VARIANT :INITIAL :ARTIFACT
   "copertura-dati.lisp")
  (:KIND :COVERAGE :FORMATS (1 2) :ARTIFACT "copertura-finale.lisp")
  (:KIND :RAW-COVERAGE :FORMATS (1 2) :ARTIFACT "copertura-dati-finali.lisp")
  (:KIND :TOOL-SELF-TEST :FORMATS (1 2) :ARTIFACT "benchmark-self-test.lisp")
  (:KIND :TOOL-SELF-TEST :FORMATS (1 2) :ARTIFACT "mutazioni-self-test.lisp")
  (:KIND :BENCHMARK :FORMATS (1 2) :ARTIFACT "benchmark.lisp")
  (:KIND :MUTATION :FORMATS (1 2) :ARTIFACT "mutazioni.lisp")
  (:KIND :RAW-MUTATION :FORMATS (1 2) :ARTIFACT "mutazioni-dati.lisp")
  (:KIND :INTEGRATED-CHECK :FORMATS (1 2) :ARTIFACT "verifica-integrata.lisp")
  (:KIND :EVIDENCE-CHECK :FORMATS NIL :ARTIFACT "verifica-catalogo.lisp")))
