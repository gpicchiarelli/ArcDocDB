(:schema-version 1
 :kind :independent-c1-reading
 :component :writer-worker
 :reading :initial-after-source-corrections
 :base "cf6091367853ec311fed7b05961a2812fd05a8f1"
 :scope :source-reading-only
 :prior-report "spikes/out/worker-c1-initial.lisp"
 :source-hashes
 ((:path "src/execution/worker-types.lisp"
   :sha256 "6f3209f1ba390e4fb38d9bd6250dc1f1a5d34daa0510e65f7b8ef85310777754")
  (:path "src/execution/worker-boundary.lisp"
   :sha256 "4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a")
  (:path "src/execution/worker-claim.lisp"
   :sha256 "62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e")
  (:path "src/execution/worker-run.lisp"
   :sha256 "60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847"))
 :findings
 ((:id :permanent-fault-retry :status :closed-in-source
   :text "Boundary registra la condition originale, passa a faulted e blocca ogni passo successivo; nessun reset o cessione dopo fault permanente.")
  (:id :batch-debt-upper-bound :status :closed-in-source
   :text "Pending<=extracted aggiunto prima di ack; lease verificata implica extracted<=quantum.")
  (:id :private-index-classification :status :closed-in-source
   :text "Cursor/home privati fuori range segnalano invariant-violation prima di ready-target delegato, separando FI interna dall'argomento adozione recuperabile.")
  (:id :private-index-docstring :status :editorial-correction-requested
   :text "Docstring %check-worker menziona ancora invalid-argument indice; gli indici privati ora generano invariant-violation. Correzione chiesta all'autore."))
 :checklist
 ((:point 1 :status :source-consistent
   :text "REQ-CON-001/002/004/005, REQ-AFF-008; ADR-0005 e ADR-0045 §§6/8. Solo componente bounded locale, no pool completo.")
  (:point 2 :status :source-findings-closed-tests-pending
   :text "Owner/fase/lease/obbligo/debito, pending<=extracted e indici privati espliciti. Fixture finali FI, new-wave, full e batch da leggere.")
  (:point 3 :status :source-consistent-tests-pending
   :text "Allowlist solo tipo/ragione attesi per API; writer-not-ready/generation/lease e runtime errors diventano faulted. Wrong-thread/fault-gate fuori handler preservano diagnosi. Nessun rollback promesso.")
  (:point 4 :status :source-consistent
   :text "Nessun nuovo ciclo esplicito/attesa/ricorsione. MEMBER su liste letterali di massimo tre risorse e due argomenti; scansione/copia bounded delegate.")
  (:point 5 :status :measurement-pending
   :text "Factory all'avvio; handler dynamic-extent e campi scalari non sostituiscono misura heap frozen.")
  (:point 6 :status :source-consistent
   :text "Ftype e slot typed; esiti/count/token controllati, condition originale conservata. Getter diagnostici owner-only senza trasferimento.")
  (:point 7 :status :inventory-present
   :text "Nessuna nuova decisione composta COD-54. Tutti i controlli scalari/case e la allowlist per API inventariati. Nessuna MC/DC dedotta.")
  (:point 8 :status :source-consistent
   :text "Owner e ready read-only; campi locali esclusivi e non rientranti. Ring protetti da guard delegate; work/ack fuori guard.")
  (:point 9 :status :execution-pending
   :text "REQ nei sorgenti; make check/trace/test finali e raw execution ancora pending.")
  (:point 10 :status :source-consistent-execution-pending
   :text "Safety 3, ftype completi, slot typed, pre/post delegate e funzioni brevi. Handler error soltanto al boundary worker con registrazione/transizione definita COD-21; macro necessita test espansione. Controller FAULTED Serie non qualificato.")
  (:point 11 :status :source-consistent
   :text "Ready per tratto e nessuna nuova scrittura globale per messaggio o attesa. Fairness/scalabilità/pool liveness non qualificati.")
  (:point 12 :status :not-applicable-to-local-memory
   :text "Nessun cambiamento durevole, rimozione o nuovo punto di atomicità persistente."))
 :coverage
 (:status :pending-new-campaign :execution-files-required 11
  :historical-execution-files 7
  :historical-marked-expressions 929 :historical-total-expressions 1060
  :historical-marked-branches 134 :historical-total-branches 154
  :exclusions nil :mcdc-inferred nil)
 :required-final-evidence
 (:tests :macro-expansion :strict-c4 :make-check :mutations :benchmark
  :native-coverage :html-comparison :export-comparison :all-missing-paths)
 :limitations
 ("Questa lettura non attribuisce risultati di compilazione, test, heap, mutazioni o copertura non ancora congelati/letti."
  "FAULTED del contesto è locale; controller Serie, wake/park, shutdown, admission e pool completo rimangono da integrare."
  "Obblighi unici e buffer privati sono precondizioni del caller; ack è attestazione del caller."
  "Mutazione già riuscita seguita da errore interno non viene annullata; campi conservati sono diagnostici, non prova per replay."))
