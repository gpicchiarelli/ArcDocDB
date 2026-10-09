(:SCHEMA-VERSION 1 :KIND :EVIDENCE-CATALOG :DATE "2026-10-09" :PATH-BASE
 "spikes/results/2026-10-09-decisions/" :ENTRIES
 ((:KIND :C1-REVIEW :ARTIFACT "letture-c1.lisp")
  (:KIND :TOOL-SELF-TEST :ARTIFACT "mutazioni-self-test.lisp")
  (:KIND :TOOL-SELF-TEST :ARTIFACT "copertura-self-test.lisp")
  (:KIND :IMPORTED-OUTPUT :ARTIFACT "mutazioni-iniziali.lisp")
  (:KIND :DEVELOPMENT-DIAGNOSTIC :ARTIFACT "diagnostica-fixture.lisp")
  (:KIND :MUTATION :FORMATS (1 2) :ARTIFACT "mutazioni-finale.lisp")
  (:KIND :RAW-MUTATION-OUTPUT :ARTIFACT "mutazioni-dati.lisp" :PROCESS-ARTIFACT
   "mutazioni-finale.lisp")
  (:KIND :COVERAGE :FORMATS (1 2) :ARTIFACT "copertura-finale.lisp")
  (:KIND :RAW-COVERAGE :ARTIFACT "copertura-dati.lisp" :PROCESS-ARTIFACT
   "copertura-finale.lisp")))
