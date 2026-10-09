(:SCHEMA-VERSION 1 :KIND :EVIDENCE-CATALOG :DATE "2026-10-09" :PATH-BASE
 "spikes/results/2026-10-09-index-slots/" :ENTRIES
 ((:KIND :COMPILE-ONLY :ARTIFACT
   #A((26) BASE-CHAR . "compilazione-iniziale.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT #A((18) BASE-CHAR . "lint-iniziale.lisp")
   :VARIANT :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT
   #A((27) BASE-CHAR . "tracciabilita-iniziale.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT
   #A((26) BASE-CHAR . "collegamenti-iniziali.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :SOURCE-SUPPORT :ARTIFACT "disassemblato-sorgente.lisp" :VARIANT
   :VERBATIM-SOURCE-TEXT)
  (:KIND :SOURCE-SUPPORT :ARTIFACT "conservazione-sorgente.lisp" :VARIANT
   :VERBATIM-SOURCE-TEXT)
  (:KIND :HISTORICAL-CATALOG :ARTIFACT "catalogo-prima-percorsi.lisp" :VARIANT
   :REJECTED-RELATIVE-PATHS)
  (:KIND :COMPILE-ONLY :ARTIFACT
   #A((24) BASE-CHAR . "compilazione-finale.lisp") :PROCESS-ARTIFACT
   #A((38) BASE-CHAR . "compilazione-finale-conservazione.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT #A((16) BASE-CHAR . "lint-finale.lisp")
   :PROCESS-ARTIFACT #A((30) BASE-CHAR . "lint-finale-conservazione.lisp")
   :VARIANT :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT
   #A((25) BASE-CHAR . "tracciabilita-finale.lisp") :PROCESS-ARTIFACT
   #A((39) BASE-CHAR . "tracciabilita-finale-conservazione.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT #A((22) BASE-CHAR . "cataloghi-rifiuto.lisp")
   :PROCESS-ARTIFACT
   #A((36) BASE-CHAR . "cataloghi-rifiuto-conservazione.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-INSPECTION :ARTIFACT
   #A((24) BASE-CHAR . "disassemblato-arm64.lisp") :PROCESS-ARTIFACT
   #A((38) BASE-CHAR . "disassemblato-arm64-conservazione.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :SOURCE-SUPPORT :ARTIFACT "conservazione-finale-sorgente.lisp"
   :VARIANT :VERBATIM-SOURCE-TEXT)
  (:KIND :SOURCE-SUPPORT :ARTIFACT "migrazione-sorgente.lisp" :VARIANT
   :VERBATIM-SOURCE-TEXT)
  (:KIND :COMPILE-ONLY :ARTIFACT
   #A((26) BASE-CHAR . "compilazione-chiusura.lisp") :PROCESS-ARTIFACT
   #A((40) BASE-CHAR . "compilazione-chiusura-conservazione.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT #A((18) BASE-CHAR . "lint-chiusura.lisp")
   :PROCESS-ARTIFACT #A((32) BASE-CHAR . "lint-chiusura-conservazione.lisp")
   :VARIANT :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT
   #A((27) BASE-CHAR . "tracciabilita-chiusura.lisp") :PROCESS-ARTIFACT
   #A((41) BASE-CHAR . "tracciabilita-chiusura-conservazione.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT
   #A((26) BASE-CHAR . "collegamenti-chiusura.lisp") :PROCESS-ARTIFACT
   #A((40) BASE-CHAR . "collegamenti-chiusura-conservazione.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT #A((23) BASE-CHAR . "cataloghi-chiusura.lisp")
   :PROCESS-ARTIFACT
   #A((37) BASE-CHAR . "cataloghi-chiusura-conservazione.lisp") :VARIANT
   :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-INSPECTION :ARTIFACT
   #A((31) BASE-CHAR . "disassemblato-finale-arm64.lisp") :PROCESS-ARTIFACT
   #A((45) BASE-CHAR . "disassemblato-finale-arm64-conservazione.lisp")
   :VARIANT :SOURCE-SNAPSHOT-IN-RECORD)
  (:KIND :STATIC-CHECK :ARTIFACT #A((21) BASE-CHAR . "cataloghi-finali.lisp")
   :PROCESS-ARTIFACT #A((35) BASE-CHAR . "cataloghi-finali-conservazione.lisp")
   :VARIANT :SOURCE-SNAPSHOT-IN-RECORD))
 :LIMITS
 (:PRODUCT-COMPILATION-AND-STATIC-INSPECTION-ONLY :NO-FUNCTIONAL-TESTS
  :NO-BENCHMARKS :NOT-C1-QUALIFIED))
