(:schema-version 1
 :kind :independent-c1-reading
 :component :writer-worker
 :reading :initial
 :base "cf6091367853ec311fed7b05961a2812fd05a8f1"
 :scope :source-reading-only
 :source-hashes
 ((:path "src/execution/worker-types.lisp"
   :sha256 "db42690ceabe1c2ed0dd28c2aeaa99244ed745565197cf52fb127c1356194e3b")
  (:path "src/execution/worker-claim.lisp"
   :sha256 "b8e35a594f8b225ca69ca06310efb3ae7683460c2480781acebd2f68197553ab")
  (:path "src/execution/worker-run.lisp"
   :sha256 "feedbeb14815d546d234bf9eed69002aa6bf0d1a82daad81d3f154b41410c379"))
 :findings
 ((:id :permanent-fault-retry
   :status :open-at-initial-reading
   :text "Nessun poison locale: not-ready lascia claimed e permette un retry futuro o una cessione impropria. Fail-stop del caller è necessario; per il contratto forte serve gate terminale persistente.")
  (:id :batch-debt-upper-bound
   :status :open-at-initial-reading
   :text "Pending positivo e generation positiva sono verificati, ma pending non è limitato a extracted/quantum. Ack può cancellare debito sovrastimato corrotto senza rilevamento."))
 :checklist
 ((:point 1 :status :source-consistent
   :text "REQ-CON-001/002/004/005 e REQ-AFF-008; INV-P1/P2/P5/P6, INV-A8, INV-V4; ADR-0005 e ADR-0045 §§6/8. Solo contesto locale, nessuna qualificazione del pool.")
  (:point 2 :status :pending-fi-and-improvement
   :text "Owner, fase, lease, obbligo e debito espliciti. Aggiungere limite pending<=extracted e leggere le fixture congelate.")
  (:point 3 :status :pending-boundary-improvement
   :text "Condizioni typed e preflight corretti; contese conservano obblighi. Fault permanenti richiedono fail-stop esterno; nessun poison locale in questa versione.")
  (:point 4 :status :source-consistent
   :text "Nessun nuovo ciclo, attesa o ricorsione. Delegate ready <=64 shard/128 CAS; copia batch bounded dalla quota e dal range.")
  (:point 5 :status :measurement-pending
   :text "Factory all'avvio; percorsi locali scalari. Nessun esito heap attribuito prima della misura frozen.")
  (:point 6 :status :source-consistent
   :text "Ftype e slots typed; esiti/count/token controllati. Getter diagnostici owner-only e non trasferiscono obblighi.")
  (:point 7 :status :inventory-present
   :text "Nessuna decisione composta COD-54 nei tre nuovi file. Controlli scalari/case inventariati, nessuna MC/DC dedotta.")
  (:point 8 :status :source-consistent
   :text "Owner e ready read-only; campi locali esclusivi non rientranti; ring sotto protocolli delegati. Work/ack fuori dalle guard.")
  (:point 9 :status :execution-pending
   :text "Commenti REQ presenti; test finali, trace e make check ancora da leggere.")
  (:point 10 :status :pending-boundary-improvement
   :text "Safety 3, ftype completi, pre/post delegate e funzioni brevi; nessun handler generico. FAULTED non realizzato in questa versione.")
  (:point 11 :status :source-consistent
   :text "Nessuna coda globale per messaggio o nuova attesa. Ready per tratto. Fairness, scalabilità e admission non qualificati.")
  (:point 12 :status :not-applicable-to-local-memory
   :text "Nessun cambiamento durevole, rimozione o nuovo punto di atomicità persistente."))
 :coverage
 (:status :pending-new-campaign
  :historical-execution-files 7
  :historical-marked-expressions 929 :historical-total-expressions 1060
  :historical-marked-branches 134 :historical-total-branches 154
  :exclusions nil :mcdc-inferred nil)
 :limitations
 ("Test, compilazione, strict C4, mutazioni, benchmark, raw coverage e check finali non ancora letti."
  "Full recycle elimina il blocco dovuto alla sola capienza nel protocollo legale, non dimostra fairness/pool liveness."
  "Uniqueness degli obblighi e buffer privati sono precondizioni del caller; ack è una sua attestazione."))
