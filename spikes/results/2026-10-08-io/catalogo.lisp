(:SCHEMA-VERSION 1 :KIND :EVIDENCE-CATALOG :DATE "2026-10-08" :PATH-BASE
 "spikes/results/2026-10-08-io/" :LIMITS
 (:LOCAL-IO-BOUNDARY-ONLY :NOT-INTEGRATED-ENGINE :NOT-C1-QUALIFICATION)
 :ENTRIES
 ((:KIND :FAILED-ATTEMPT :FORMATS (1 2) :VARIANT :INITIAL-TYPE-CONTRACT
   :ARTIFACT "compilazione-iniziale-fallita.lisp")
  (:KIND :CHECK :FORMATS (1 2) :VARIANT :INITIAL-BUILD :ARTIFACT
   "compilazione-iniziale.lisp")
  (:KIND :FAILED-ATTEMPT :FORMATS (1 2) :VARIANT :INITIAL-TEST-FIXTURES
   :ARTIFACT "test-iniziali-falliti.lisp")
  (:KIND :CHECK :FORMATS (1 2) :VARIANT :INITIAL-IO :ARTIFACT
   "test-iniziali.lisp")
  (:KIND :CHECK :FORMATS (1 2) :VARIANT :SEALED-BATCHES :ARTIFACT
   "test-lotti.lisp")
  (:KIND :TOOL-SELF-TEST :FORMATS NIL :VARIANT :IO :ARTIFACT
   "mutazioni-self-test.lisp")
  (:KIND :MUTATION :FORMATS (1 2) :VARIANT :INITIAL-IO :ARTIFACT
   "mutazioni-iniziali.lisp")
  (:KIND :TOOL-SELF-TEST :FORMATS NIL :VARIANT :IO :ARTIFACT
   "benchmark-self-test-iniziale.lisp")
  (:KIND :BENCHMARK :FORMATS NIL :VARIANT :HEAP-CRITERION-NOT-MET :ARTIFACT
   "benchmark-iniziale.lisp")
  (:KIND :CHECK :FORMATS (1 2) :VARIANT :DIRECTORY-FINAL-COMPONENT :ARTIFACT
   "test-symlink.lisp")
  (:KIND :TOOL-SELF-TEST :FORMATS NIL :VARIANT :IO :ARTIFACT
   "copertura-self-test.lisp")
  (:KIND :COVERAGE :FORMATS (1 2) :VARIANT :INITIAL-IO :ARTIFACT
   "copertura-iniziale.lisp")
  (:KIND :CHECK :FORMATS (1 2) :VARIANT :INLINE-NATIVE-FIXNUM :ARTIFACT
   "test-zero-heap.lisp")
  (:KIND :BENCHMARK :FORMATS NIL :VARIANT :INLINE-NATIVE-FIXNUM :ARTIFACT
   "benchmark-zero-heap-iniziale.lisp")
  (:KIND :COVERAGE :FORMATS (1 2) :VARIANT :INLINE-NATIVE-FIXNUM :ARTIFACT
   "copertura-intermedia.lisp")
  (:KIND :MUTATION :FORMATS (1 2) :VARIANT :INLINE-NATIVE-FIXNUM :ARTIFACT
   "mutazioni-intermedie.lisp")
  (:KIND :CHECK :FORMATS (1 2) :VARIANT :TRACED-CANDIDATE :ARTIFACT
   "test-candidato.lisp")
  (:KIND :TOOL-SELF-TEST :FORMATS NIL :VARIANT :TRACED-CANDIDATE :ARTIFACT
   "benchmark-self-test-candidato.lisp")
  (:KIND :BENCHMARK :FORMATS NIL :VARIANT :TRACED-CANDIDATE :ARTIFACT
   "benchmark-zero-heap.lisp")
  (:KIND :COVERAGE :FORMATS (1 2) :VARIANT :TRACED-CANDIDATE :ARTIFACT
   "copertura-candidato.lisp")
  (:KIND :MUTATION :FORMATS (1 2) :VARIANT :TRACED-CANDIDATE :ARTIFACT
   "mutazioni-candidato.lisp")
  (:KIND :RAW-COVERAGE :FORMATS (1 2) :ARTIFACT "copertura-dati-iniziali.lisp"
   :PROCESS-ARTIFACT "copertura-iniziale.lisp")
  (:KIND :RAW-COVERAGE :FORMATS (1 2) :ARTIFACT "copertura-dati-intermedi.lisp"
   :PROCESS-ARTIFACT "copertura-intermedia.lisp")
  (:KIND :RAW-COVERAGE :FORMATS (1 2) :ARTIFACT "copertura-dati-candidato.lisp"
   :PROCESS-ARTIFACT "copertura-candidato.lisp")
  (:KIND :HISTORICAL-OUTPUT-IMPORT :FORMATS NIL :ARTIFACT
   "lint-iniziale-importato.lisp")
  (:KIND :MUTATION-REGRESSION :FORMATS (1 2) :ARTIFACT
   #A((37) BASE-CHAR . "mutazioni-regressione-fondazioni.lisp"))
  (:KIND :MUTATION-REGRESSION :FORMATS (1 2) :ARTIFACT
   #A((34) BASE-CHAR . "mutazioni-regressione-storage.lisp"))
  (:KIND :SOURCE-CHANGED-ATTEMPT :FORMATS (1 2) :ARTIFACT
   #A((42) BASE-CHAR . "verifica-integrata-sorgenti-variati-1.lisp"))
  (:KIND :SOURCE-CHANGED-ATTEMPT :FORMATS (1 2) :ARTIFACT
   #A((42) BASE-CHAR . "verifica-integrata-sorgenti-variati-2.lisp"))
  (:KIND :INTEGRATED-MUTATION :FORMATS (1 2) :ARTIFACT
   #A((24) BASE-CHAR . "mutazioni-integrate.lisp"))
  (:KIND :TOOL-SELF-TEST :FORMATS (1 2) :ARTIFACT
   #A((34) BASE-CHAR . "benchmark-self-test-integrato.lisp"))
  (:KIND :FAILED-ATTEMPT :FORMATS (1 2) :ARTIFACT
   #A((37) BASE-CHAR . "verifica-integrata-heap-esaurito.lisp"))
  (:KIND :INTEGRATED-CHECK :FORMATS (1 2) :ARTIFACT
   #A((30) BASE-CHAR . "verifica-integrata-finale.lisp"))
  (:KIND :INTEGRATED-DOCUMENTATION-CHECK :FORMATS (1 2) :ARTIFACT
   #A((29) BASE-CHAR . "verifica-catalogo-finale.lisp"))
  (:KIND :RAW-MUTATION :FORMATS (1 2) :ARTIFACT "mutazioni-dati-grezzi.lisp")
  (:kind :publication-check :formats (1 2) :artifact "verifica-pubblicazione.lisp")))
