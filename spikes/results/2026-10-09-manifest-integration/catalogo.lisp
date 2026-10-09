(:SCHEMA-VERSION 1 :KIND :EVIDENCE-CATALOG :DATE "2026-10-09" :PATH-BASE
 "spikes/results/2026-10-09-manifest-integration/" :ENTRIES
 ((:KIND :SPIKE-CHECK :ARTIFACT "SPK-01.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "SPK-02.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "SPK-03.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "SPK-04.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "SPK-05.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "SPK-06.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "SPK-07.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "SPK-08.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "SPK-09.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "SPK-10.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "check-completo.lisp")
  (:KIND :EVIDENCE-FINALIZATION :ARTIFACT "conservazione.lisp")
  (:KIND :DEVELOPMENT-DIAGNOSTIC :ARTIFACT "diagnostica-reader.lisp")
  (:KIND :C1-REVIEW :ARTIFACT "letture-c1.lisp")
  (:KIND :INTEGRATION-METHOD :ARTIFACT "metodo.lisp")
  (:KIND :MUTATION-OUTPUT :ARTIFACT "mutazioni-decisions-dati.lisp"
   :PROCESS-ARTIFACT "mutazioni-decisions.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "mutazioni-decisions.lisp")
  (:KIND :MUTATION-OUTPUT :ARTIFACT "mutazioni-handoff-dati.lisp"
   :PROCESS-ARTIFACT "mutazioni-handoff.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "mutazioni-handoff.lisp")
  (:KIND :MUTATION-OUTPUT :ARTIFACT "mutazioni-manifest-dati.lisp"
   :PROCESS-ARTIFACT "mutazioni-manifest.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "mutazioni-manifest.lisp")
  (:KIND :MUTATION-OUTPUT :ARTIFACT "mutazioni-utf8-dati.lisp"
   :PROCESS-ARTIFACT "mutazioni-utf8.lisp")
  (:KIND :PROCESS-SIGNAL-SELF-TEST-OUTPUT :ARTIFACT
   "mutazioni-utf8-self-test-segnale-dati.lisp" :PROCESS-ARTIFACT
   "mutazioni-utf8.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "mutazioni-utf8.lisp")
  (:KIND :SPIKE-CHECK :ARTIFACT "report.lisp")
  (:KIND :COPIER-SELF-TEST-OUTPUT :ARTIFACT
   "self-test-foundation-copier-dati.lisp" :PROCESS-ARTIFACT
   "self-test-foundation.lisp")
  (:KIND :PARALLEL-SELF-TEST-OUTPUT :ARTIFACT
   "self-test-foundation-parallelo-dati.lisp" :PROCESS-ARTIFACT
   "self-test-foundation.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "self-test-foundation.lisp")
  (:KIND :PROCESS-SIGNAL-SELF-TEST-OUTPUT :ARTIFACT
   "self-test-handoff-segnale-dati.lisp" :PROCESS-ARTIFACT
   "self-test-handoff.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "self-test-handoff.lisp")
  (:KIND :PROCESS-SIGNAL-SELF-TEST-OUTPUT :ARTIFACT
   "self-test-utf8-segnale-dati.lisp" :PROCESS-ARTIFACT "self-test-utf8.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "self-test-utf8.lisp")
  (:KIND :COMMAND-VERIFICATION :ARTIFACT "catalogo-verifica.lisp"))
 :LIMITS
 (:STRUCTURE-PRESENCE-SIZE-AND-COMPRESSED-INTEGRITY
  :NO-AUTOMATIC-GATE-PROMOTION))
