(:schema-version 1
 :kind :code-review
 :review :second-reading
 :reviewer "independent bounded C1 reviewer"
 :recorded-at "2026-10-09T07:38:05+00:00"
 :workspace "/Users/gpicchiarelli/.codex/worktrees/sequenze-commit/ArcDocDB"
 :git-head "92d8b0ebf498800e4847bc4828560c6dac879c0e"
 :scope :current-workspace-static-reading
 :initial-status :findings-open-evidence-pending
 :status :static-findings-resolved-evidence-pending
 :readonly-product t
 :tests-executed nil
 :project-tools-executed nil
 :campaigns-run-by-reviewer nil
 :commits-created nil
 :approval-claimed nil
 :deviation-approved nil
 :source-frozen nil
 :runtime-docs-or-source-audited nil
 :owned-files
 ("docs/implementazione/csn-revisione.md" "/tmp/arcdocdb-csn-review.lisp")
 :document "docs/implementazione/csn-revisione.md"
 :fingerprint-kind :sha256
 :fingerprints
 (
  (:path "src/csn/package.lisp" :sha256 "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0" :read-scope :full-text)
  (:path "src/csn/registry.lisp" :sha256 "81fcc0181b883f299c6fe33b3b1bc05a8a6f0d756ef06717eaff1fdde73050a6" :read-scope :full-text)
  (:path "docs/implementazione/csn.md" :sha256 "c46cce29aa8fc6ae5f8390eb9cc8d1023b98328dfa6ec33d8c88fbaf2a42cecf" :read-scope :full-text)
  (:path "docs/implementazione/csn-metodo.md" :sha256 "f2b18cdf170478141c955c1d77f5393daf23c27888abd6e6dbd2f219a5de604c" :read-scope :full-text)
  (:path "docs/implementazione/csn-decisioni.md" :sha256 "ade75b4b0bb050f79b2f8ded23b21745c9a939839b35d1e521c1632ba80aaab6" :read-scope :full-text)
  (:path "docs/adr/0046-orizzonte-con-registro-limitato.md" :sha256 "246929296e3bae50366d6805aaca8e5b0ef1664ad17f1787215bde440fc15ca3" :read-scope :full-text)
  (:path "docs/adr/0038-orizzonte-di-visibilita.md" :sha256 "4657eec6d785c6c29596fab20d86ee5237deaed7eafde84e84bd58b906c0e895" :read-scope :full-text)
  (:path "docs/adr/0045-modello-di-esecuzione.md" :sha256 "7860c6dfb2d54e9c0ce714d05bf655416ca90af5521a36159b83f1ef209e3bb9" :read-scope :relevant-sections)
  (:path "docs/affidabilita/standard-di-codifica.md" :sha256 "1fd0a21b61b68079a42256f555d675b8a35d6599dad4206720d38f9b29d89c21" :read-scope :full-text)
  (:path "docs/affidabilita/piano-di-verifica.md" :sha256 "e4832c1ac92025176866b392ab02916a1675dd3aa07a8434cb8acd3c4dd53aff" :read-scope :full-text)
  (:path "docs/affidabilita/deviazioni.md" :sha256 "1f7326be6828abfcf20db10303d731b4ddf57cb27a36885f836d195653a65d99" :read-scope :full-text)
  (:path "tests/csn/support.lisp" :sha256 "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db" :read-scope :full-text)
  (:path "tools/csn-bench.lisp" :sha256 "d825a04b1ba488153ba8f0fb73c6aa2555c3bb0c9b2cafba3bcbf483d39aef47" :read-scope :selected-sections)
  (:path "arcdocdb.asd" :sha256 "683d74a939be4ce0e05e7615583cf366bd91819285f6826c323c4c7882b32542" :read-scope :full-text)
  (:path "docs/tracciabilita/requisiti.lisp" :sha256 "c17d456210c8976c6946fd33968e28e0d7054eca2bae4defe599c5d4112749fa" :read-scope :relevant-sections)
  (:path "docs/tracciabilita/matrice.md" :sha256 "682ac367084ca6c4b64b1d99eca4cbc30433eb84b651eb1db713bdc7f51f6856" :read-scope :relevant-sections)
  (:path "docs/invarianti.md" :sha256 "c3c1b7b4f5eb7ea1adfddf9957aa9c11846684d029467aea88f5c1ef94958ea7" :read-scope :relevant-sections))
 :absence-observed-at "2026-10-09T07:38:05+00:00"
 :absent-files
 ("tests/csn/registry.lisp" "tests/csn/threads.lisp" "tools/csn-mutation.lisp")
 :additional-context-read
 ("docs/adr/0020-csn-snapshot-isolamento.md"
  "docs/adr/0047-verifica-csn-dei-record-prepared.md"
  "src/foundation/binary.lisp")
 :initial-checks
 (
  (:point 1 :name :requirements-and-adr :status :static-coherence
   :evidence "REQ-MVC-005/008 e REQ-AFF-008; ADR-0046, INV-M4/M6/A8. Nessuna qualifica snapshot.")
  (:point 2 :name :invariants-and-tests :status :evidence-pending
   :evidence "Transizioni sane e controesempio K=2 analizzati; oracolo a interi/lista presente solo nel supporto. Suite effettiva assente.")
  (:point 3 :name :typed-errors :status :static-with-contract-limits
   :evidence "Rifiuti ordinari prima degli store; busy conserva obbligo. Fail-stop al controller; full precede exhausted.")
  (:point 4 :name :bounded-work :status :static-coherence
   :evidence "Scansioni al piu K<=65536; with-mutex wait-p nil una volta; nessun retry/I/O nel prodotto. Thread test assenti.")
  (:point 5 :name :hot-path-allocation :status :measurement-pending
   :evidence "Array preallocati, parole u32 fixnum su SBCL 64 bit, nessun u64 combinato. Nessun benchmark eseguito o risultato acquisito.")
  (:point 6 :name :verified-output :status :contract-limited
   :evidence "Range/identita token controllati; registro associato dal chiamante; effetti e recovery non verificati qui. used esatto verificato solo alla risoluzione.")
  (:point 7 :name :compound-decisions :status :inventory-read-evidence-pending
   :evidence "Decisioni composte nel documento; coppie di indipendenza, copertura e mutanti della suite finale da acquisire.")
  (:point 8 :name :ownership :status :static-coherence
   :evidence "OWNER/SHARED e un registro per Archivio; stessa guardia per API, copier assente, campi fissi read-only.")
  (:point 9 :name :integration-and-checks :status :evidence-pending
   :evidence "ASDF enumera support/registry/threads; due file test assenti. Trace/matrice progettato; nessun check eseguito.")
  (:point 10 :name :coding-rules :status :open-finding
   :evidence "Safety 3, FTYPE, tipi/docstring/REQ e funzioni brevi; COD-13: 12 e 11 percorsi con cortocircuito. COD-53 test espansione da acquisire; nessuna deroga.")
  (:point 11 :name :series-parallelism :status :scope-limited
   :evidence "Coordinamento condiviso per lotto/decisione e lettura frontiere; nessun accesso per documento nel contratto; scheduler e scalabilita esclusi.")
  (:point 12 :name :durable-atomicity :status :not-applicable
   :evidence "Solo stato volatile, nessun I/O/eliminazione; H non e frontiera durevole, risoluzione non conferma commit."))
 :initial-findings
 ((:id "CSN-C1-01" :priority :p2 :status :open :rule "COD-13"
   :kind :coding-standard
   :locations
   ((:path "src/csn/registry.lisp" :line 130 :end-line 146
     :function "%check-token-csn" :independent-paths 12
     :count (:base 1 :unless 3 :and-short-circuit-edges 7 :or-short-circuit-edges 1))
    (:path "src/csn/registry.lisp" :line 150 :end-line 171
     :function "%frontiera-risolta-csn" :independent-paths 11
     :count (:base 1 :dotimes 1 :unless 4 :when 2 :if 1 :and-short-circuit-edges 2)))
   :counting-method :manual-written-control-flow-including-short-circuit
   :macroexpansion-counted nil :coverage-measured nil :standard-limit 10
   :evidence "Due helper superano 10 includendo and/or. Tabella decisioni priva del conteggio; registro deviazioni Nessuna."
   :required-followup "Ridurre la complessita o documentare e motivare un diverso criterio. Nessuna deroga approvata dal revisore."))
 :observations
 ((:id "CSN-OBS-01" :kind :manual-source-trace :executed nil
   :note "Base (0,fffffffe), take (0,ffffffff), take (1,0), risolvi primo -> H (0,ffffffff): carry e borrow corretti.")
  (:id "CSN-OBS-02" :kind :manual-source-trace :executed nil
   :note "K=2: 1 pendente, 2..5 presi/risolti nello slot libero, H=0; risolvi 1 -> H=5. Nessun csn mod K.")
  (:id "CSN-OBS-03" :kind :guard
   :note "Registry valutato una volta; owner corrente rifiutato; with-mutex wait-p nil; acquired distingue NIL del corpo; multiple-value-prog1 conserva valori. Cleanup delegato al runtime, non provato qui.")
  (:id "CSN-OBS-04" :kind :error-priority
   :note "Full precede exhausted; K=1 al massimo con token pendente -> full, dopo risoluzione -> exhausted. Rifiuti senza store.")
  (:id "CSN-OBS-05" :kind :defensive-contract-limitation
   :location (:path "src/csn/registry.lisp" :line 53)
   :note "%check-registro-csn verifica used<=K, non cardinalita degli slot. Con FI K=2, un pendente, used=2: check generale accetta e take segnala full; risolvi rileva il conteggio prima di mutare."
   :public-valid-call-defect-claimed nil :probe-executed nil
   :required-followup "Delimitare la docstring conteggio coerente e la copertura FI: controllo esatto solo nella risoluzione.")
  (:id "CSN-OBS-06" :kind :caller-obligation
   :note "Token numerico associato dal chiamante al registro; due registri possono emettere identici slot/high/low. Nessuna capability o owner-cookie promessa."))
 :functional-conclusion
 (:valid-completed-api-transitions :no-defect-found-by-static-reading
  :all-interleavings-proven nil :arbitrary-private-state-corruption-covered nil)
 :initial-pending-evidence
 (:actual-registry-tests :absent-at-observation
  :actual-thread-tests :absent-at-observation
  :macro-expansion-tests :not-present-in-read-support
  :benchmark-sensor-positive-control :not-executed
  :serial-zero-heap-small-and-high-csn :not-measured
  :oldest-pinned-reuse :not-executed
  :thread-uniqueness-and-horizon-convergence :not-executed
  :mutation-driver :absent-at-observation
  :compiled-mutation-kills :not-acquired
  :raw-coverage-and-condition-pairs :not-acquired
  :build-lint-trace-links-make-check :not-executed)
 :limits
 ("Review of mutable workspace, not a frozen baseline; hashes identify only observed content."
  "No compilation, tests, project tools, benchmarks, mutation or coverage executed."
  "No measured zero-heap, runtime interruption proof, MC/DC, C1 approval or deviation."
  "Controller must preserve take success and resolution obligation on busy; lost token can hold credit/H indefinitely."
  "Resolve requires valid publication or abort; module cannot validate effects or infer abort from Serie failure."
  "Archive-wide validated maximum must precede registry creation and write admission."
  "Late Serie opening, WAL, recovery integration, index publication, fail-stop, shutdown and parking remain external."
  "No lock-free H, snapshot registration/awakening, durable frontier or commit acknowledgement implemented."
  "No complete engine, Linux/x86-64, P99, fairness or scaling qualification.")
 :initial-parent-followup
 ("Resolve CSN-C1-01 and delimit the defensive cardinality contract."
  "Finish and freeze tests/tools, then reread any production diff."
  "Acquire registered campaigns/checks and attach evidence to matching source hashes.")
 :latest-reading
 (:recorded-at "2026-10-09T07:44:59+00:00"
  :kind :static-refactor-and-new-tests-addendum
  :parent-requested-reread t
  :initial-finding-and-hashes-preserved t
  :source-frozen nil :executed nil
  :fingerprints
  (
   (:path "src/csn/registry.lisp" :sha256 "56262b96c0b3fdfc92289e37e80dadb17c49870c57c57e89ab7afba4bb74f14a" :read-scope :full-text)
   (:path "src/csn/package.lisp" :sha256 "b9fa9bac97e89dd43bd91e6050ac7f6bbba47109403350478b2df8ca851f01a0" :read-scope :full-text)
   (:path "docs/implementazione/csn-decisioni.md" :sha256 "ade75b4b0bb050f79b2f8ded23b21745c9a939839b35d1e521c1632ba80aaab6" :read-scope :full-text)
   (:path "tests/csn/support.lisp" :sha256 "6b19e1c80a8b2e91b4a6bfc6b3cfeae962ed9cd919d6df1a92b58ab3b49255db" :read-scope :full-text)
   (:path "tests/csn/registry.lisp" :sha256 "c4e24c711f0ac63e33149bc866d8a62c0eb6e92528b2710a09b74ffc4c78a950" :read-scope :full-text)
   (:path "tests/csn/threads.lisp" :sha256 "0470dc35f8c5cd4ca294712fd439e7865e3702fe243a72b9f57194d099f2b5d2" :read-scope :full-text))
  :decision-document-sha256 "ade75b4b0bb050f79b2f8ded23b21745c9a939839b35d1e521c1632ba80aaab6"
  :decision-document-changed nil
  :resolution
  (:id "CSN-C1-01" :status :resolved-by-static-reading :rule "COD-13"
   :counting-method :manual-written-control-flow-including-short-circuit
   :limit 10
   :counts
   ((:function "%check-forma-token-csn" :line 131 :independent-paths 7
     :count (:base 1 :unless 1 :and-short-circuit-edges 4 :or-short-circuit-edges 1))
    (:function "%check-pendente-csn" :line 141 :independent-paths 4
     :count (:base 1 :unless 1 :and-short-circuit-edges 2))
    (:function "%check-token-csn" :line 154 :independent-paths 3
     :count (:base 1 :unless 1 :and-short-circuit-edges 1))
    (:function "%frontiera-risolta-csn" :line 167 :independent-paths 9
     :count (:base 1 :dotimes 1 :unless 3 :when 2 :if 1 :and-short-circuit-edges 1))
    (:function "%check-registro-csn" :line 53 :independent-paths 10
     :count (:base 1 :when-and-unless 4 :and-short-circuit-edges 4 :or-short-circuit-edges 1)))
   :static-standard-limit-satisfied t
   :api-state-and-semantics-change-found nil
   :coverage-measured nil :deviation-approved nil)
  :cardinality-documentation
  (:initial-observation "CSN-OBS-05" :status :resolved-documentation-precision
   :note "Docstring ora dichiara limiti del conteggio e cardinalita esatta verificata alla risoluzione; difesa non ampliata.")
  :refactor-observations
  ("Forma del token ancora validata prima degli accessi agli array."
   "Identita high/low ancora controllata prima delle frontiere."
   "Nuovo used>0 nel residuo ridondante: controllo del token eseguito prima sotto lo stesso mutex."
   "Nessuno store nei due helper; scansione valida residui/conteggio prima della mutazione."
   "Carry/borrow, try-lock wait-p nil, token numerici, full prima di exhausted e API invariati alla lettura.")
  :new-tests-statically-read
  (:registry :full-text :threads :full-text :executed nil
   :cases (:u32-carry :horizon-borrow :fixnum-boundary :u64-exhaustion
           :reverse-completion :oldest-pinned-adr0046 :full-and-credit
           :stale-and-double-resolution :invalid-config-and-token
           :private-shape-frontier-count-fi :numeric-registry-binding)
   :finite-explorer (:capacity (2 3) :commits 6 :executed nil)
   :deterministic-actions (:count 10000 :seed "#x46c5a71b" :executed nil)
   :guard-macro-behavior (:single-evaluation t :nil-result t :zero-values t
                          :multiple-values t :body-error t :nonlocal-exit t
                          :recursive-busy t :other-thread-busy t
                          :macroexpanded-by-reviewer nil :tests-executed nil)
   :real-thread-fixture (:workers 4 :assignments-per-worker 1000 :capacity 3
                         :forced-saturation-waves 2 :deadline-seconds 20
                         :bounded-cleanup-join t :checks-thread-cessation t
                         :executed nil)
   :held-mutex-fixture (:probe-joined-before-holder-release t
                        :independent-registry-progress-tested-in-source t
                        :executed nil))
  :mutation-tool (:present t :read-scope :selected-sections :executed nil
                  :qualified-by-this-review nil)
  :checklist-updates
  ((:point 2 :status :tests-present-static-reading-only)
   (:point 3 :status :typed-refusal-and-fi-tests-present-not-executed)
   (:point 4 :status :bounded-thread-fixtures-present-not-executed)
   (:point 5 :status :zero-heap-measurement-pending-on-new-hash)
   (:point 7 :status :inventory-retained-final-condition-and-mutation-evidence-pending)
   (:point 9 :status :asdf-test-files-present-integrated-checks-pending)
   (:point 10 :status :static-complexity-finding-resolved-macro-tests-not-executed))
  :current-open-static-findings nil
  :functional-defect-found-by-static-reading nil
  :approval-claimed nil)
 :current-pending-evidence
 (:actual-registry-tests :present-not-executed
  :actual-thread-tests :present-not-executed
  :macro-behavior-tests :present-not-executed
  :mutation-driver :present-not-executed
  :serial-zero-heap-and-sensor-control :not-measured-on-refactored-hash
  :thread-uniqueness-and-horizon-convergence :not-executed
  :compiled-mutation-kills :not-acquired-on-refactored-hash
  :raw-coverage-and-condition-pairs :not-acquired-on-refactored-hash
  :build-lint-trace-links-make-check :not-executed)
 :current-parent-followup
 ("Freeze the reviewed production hash and test files before campaigns."
  "Acquire execution, zero-heap, mutation, coverage and integrated check evidence on matching hashes."
  "Reread any later production diff; lifecycle/recovery/snapshot obligations remain external.")
)
