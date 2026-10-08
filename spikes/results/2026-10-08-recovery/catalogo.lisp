(:schema-version 1 :kind :evidence-catalog :date "2026-10-08"
 :path-base "spikes/results/2026-10-08-recovery/"
 :entries
 ((:kind :check :formats (1 2) :variant :initial-18-tests :artifact "check-iniziale.lisp")
  (:kind :tool-self-test :artifact "mutazioni-self-test.lisp")
  (:kind :tool-self-test :artifact "copertura-self-test.lisp")
  (:kind :failed-attempt :variant :unused-mutant-argument
   :artifact "mutazioni-iniziali-fallite.lisp")
  (:kind :failed-attempt :variant :relative-output-path
   :artifact "copertura-iniziale-fallita.lisp")
  (:kind :coverage :formats (1 2) :variant :before-final-budget-case
   :artifact "copertura-intermedia.lisp")
  (:kind :raw-coverage :formats (1 2) :artifact "copertura-dati-intermedi.lisp"
   :process-artifact "copertura-intermedia.lisp")
  (:kind :mutation :formats (1 2) :variant :nine-detected-before-final-budget-case
   :artifact "mutazioni-intermedie.lisp")
  (:kind :c1-review :artifact "letture-c1.lisp")
  (:kind :integrated-check :formats (1 2) :variant :final-19-tests
   :artifact "check-integrato-39b87b9.lisp")
  (:kind :coverage :formats (1 2) :artifact "copertura-finale.lisp")
  (:kind :raw-coverage :formats (1 2) :artifact "copertura-dati.lisp"
   :process-artifact "copertura-finale.lisp")
  (:kind :mutation :formats (1 2) :variant :nine-detected
   :artifact "mutazioni-finali.lisp")
  (:kind :tool-self-test :artifact "mutazioni-self-test-finale.lisp")
  (:kind :tool-self-test :artifact "copertura-self-test-finale.lisp")
  (:kind :documentation-check :artifact "verifica-documentazione.lisp")
  (:kind :integrated-check :formats (1 2) :variant :final-with-ten-spikes
   :artifact "check-finale.lisp")))
