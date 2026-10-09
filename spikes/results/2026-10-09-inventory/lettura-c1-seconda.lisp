(:schema-version 1
 :kind :c1-review
 :recorded-at "2026-10-09 09:56:41 UTC"
 :reviewer "/root/decisions_tests"
 :role :second-product-reading-by-test-author
 :workspace "/Users/gpicchiarelli/.codex/worktrees/recovery-inventory/ArcDocDB"
 :revision "673987ad819dd48741a7c0a4ff259137a1ed0bef"
 :status :no-functional-source-finding-after-recorded-syntax-fix
 :product-edited-by-reviewer nil
 :tests-executed-by-reviewer nil
 :source-hash-method :git-hash-object
 :runtime :not-collected
 :metadata (:build :not-collected-by-reviewer :make-check :not-collected
            :coverage :not-collected :mutation :not-collected
            :heap :not-collected :performance :not-collected)
 :source-files
 ((:path "src/recovery/manifest-package.lisp" :git-blob "5405bd515df8b26b792bd0430c9ec3dbadce63e7")
  (:path "src/recovery/inventory-types.lisp" :git-blob "68c357d2d522fcabe79284c540c2631e5fa87780")
  (:path "src/recovery/inventory-build.lisp" :git-blob "60057f6a50c657f016bee3c21c21911b582f86fe")
  (:path "src/recovery/inventory-query.lisp" :git-blob "47810fb2944b4b5c18d9a9c8e60dfdc1c5f19db4")
  (:path "arcdocdb.asd" :git-blob "e3eba2b0baf54d851e71c0eeb7eb837930ff7fc5"))
 :test-files
 ((:path "tests/recovery/inventory-support.lisp" :git-blob "06eeff2101a97f9abdec6b6f14aa621c2fec29fd")
  (:path "tests/recovery/inventory.lisp" :git-blob "0d5722e4f5ba0025d3a6fb38f0bd056a3ea0b8e9"))
 :integration-read
 ("CONTRIBUTING.md" "docs/affidabilita/standard-di-codifica.md"
  "docs/adr/0040-manifest-a-record-unico.md"
  "docs/implementazione/inventario.md" "docs/implementazione/inventario-metodo.md"
  "docs/implementazione/inventario-decisioni.md"
  "src/recovery/manifest-types.lisp" "src/recovery/manifest-query.lisp"
  "src/foundation/binary.lisp" "tests/recovery/manifest-support.lisp")
 :oracle
 (:method :declarative-list-table :product-private-access nil
  :product-queries-for-expected-values nil :product-encoder-for-fixtures nil
  :fixture-source :independent-bytewise-edit-and-seal-with-bitwise-crc
  :nominal-inventory-tests 13 :nominal-all-recovery-tests 95
  :small-model (:ids (0 1 2 3 4) :active 3 :closed (0 1) :removed (2)
                :presence-states 4 :inventories 1024 :versions (1 2)
                :orders-per-inventory 3 :planned-comparisons 6144)
  :complete-permutations (:physical-names 6 :permutations 720
                          :versions (1 2) :planned-comparisons 1440)
  :parallel (:workers 4 :private-plans-per-worker 8 :private-plans 32 :parent-common-plans 1
             :shared-query-plan t :source-buffer-and-input-vector-reused-before-workers t
             :start-wait-seconds 10 :join-seconds 20 :cleanup-join-seconds 1
             :cleanup-checks-thread-cessation t)
  :independence-limit "Il recensore ha scritto i test e ha letto firme e sorgenti durante la preparazione. La seconda lettura e indipendente dall'autore del prodotto, non una revisione cieca dei test. L'oracolo deriva dal contratto dichiarato e non usa il risultato del planner.")
 :initial-review-preserved
 (:source-build-blob "3f72c1d81c75c0dbc70b6009ece0aa62bbcfef37"
  :support-blob "44b96ff5b1ebe6b25de2465c340425ed3ac3f3c7"
  :tests-blob "0d5722e4f5ba0025d3a6fb38f0bd056a3ea0b8e9"
  :raw-message "Seconda lettura del prodotto: nessun difetto funzionale trovato. Limite del mio harness da registrare: inventory-stop-workers fa terminate + join(1s) ma non verifica thread-alive-p dopo il join; il percorso riuscito ha quattro join T, il cleanup su errore non attesta ancora cessazione. Non cambio i file dopo freeze; se le prove non sono iniziate posso aggiungere la sola postcondizione prima di un nuovo freeze. Il report C1 indichera comunque runtime :not-collected e le guardie private non ancora coperte."
  :syntax-check-at-that-reading :not-collected
  :limit "La prima lettura visiva non ha rilevato la parentesi mancante del planner. La frase sui quattro join T descriveva il criterio di successo del test, non un esito runtime raccolto.")
 :findings-and-fix-scopes
 ((:id "C1-INV-SECOND-001" :kind :test-harness-cleanup :status :source-fixed-runtime-pending
   :path "tests/recovery/inventory-support.lisp" :function "inventory-stop-workers" :line 144
   :raw-finding "Terminate e join limitato non erano seguiti da un controllo della cessazione del thread."
   :fix-author "/root/decisions_tests"
   :fix-scope "Sola postcondizione (not (sb-thread:thread-alive-p thread)) dopo il cleanup di ciascun worker; nessun caso o conteggio modificato."
   :before-blob "44b96ff5b1ebe6b25de2465c340425ed3ac3f3c7"
   :after-blob "06eeff2101a97f9abdec6b6f14aa621c2fec29fd")
  (:id "C1-INV-SECOND-002" :kind :recorded-product-read-error :status :source-fixed-rebuild-pending
   :detected-by :root-recorded-build :fix-author "/root"
   :path "src/recovery/inventory-build.lisp" :function "pianifica-riconciliazione" :line 145
   :record "spikes/out/4000528555-command-77868-0/report.lisp"
   :observed-record-status :failed :observed-exit-code 2 :observed-source-consistency :stable
   :raw-diagnostic "READ error during COMPILE-FILE: end of file on inventory-build.lisp; in form starting at line: 145, column: 0, position: 8198."
   :fix-scope "Sola parentesi di chiusura del LET dentro DOLIST, riga 158. Nessun cambio di classificazione, budget o ownership."
   :before-blob "3f72c1d81c75c0dbc70b6009ece0aa62bbcfef37"
   :after-blob "60057f6a50c657f016bee3c21c21911b582f86fe"
   :limit "Letto il record originale come testo, senza caricarlo o valutarlo. Il fallimento e di compilazione prima delle prove; non e un rilevamento runtime o una baseline passata."))
 :checklist
 ((:id 1 :status :static-consistent
   :evidence "REQ-REC-001/002/004 e REQ-AFF-008/017/018 sono indicati. ADR0040§3 coincide con la matrice dichiarativa; temporary REMOVED e doppia forma sono contratti conservativi espliciti.")
  (:id 2 :status :public-tests-present-runtime-pending
   :evidence "INV-A7/A8/A9/A10/A11, INV-C7 e INV-P6 sono elencati. I test confrontano canonicalita, disponibilita, rifiuti, budget, ID completi e ownership. La classificazione dipende dagli insiemi vivi/rimossi, mai dal prossimo ID.")
  (:id 3 :status :typed-errors-static-consistent
   :evidence "Budget INTEGER fuori INDEX => invalid-argument :inventory-budget; non INTEGER => type-error. File fisici e 1+CLOSED hanno rifiuti resource-exhausted prima delle entry; entry errata/duplicata ha offset nell'inventario. Query INTEGER fuori range => :reconciliation-index; tipi FTYPE errati => type-error. Nessun piano parziale viene restituito."
   :limit "Guardie private invariant-violation e bound aritmetico :inventory-plan-budget non sono forzati da un inventario pubblico conforme di dimensione realisticamente allocabile; nessuna esclusione approvata.")
  (:id 4 :status :static-bounded
   :evidence "DOTIMES percorre length(FILES) verificata. MAPHASH si limita alla mappa locale e ai CLOSED del manifest; union <= file fisici+1+CLOSED, DOLIST sulla lista privata finita, SORT soltanto su tale lista. Nessun ciclo di retry, attesa, callback o ricorsione esplicita nel prodotto.")
  (:id 5 :status :opening-path-allocations-declared
   :evidence "Il planner alloca workspace, lista ID, vettore e entry nel percorso di apertura; non e un percorso caldo qualificato zero heap. Nessuna misura di heap, latenza o throughput effettuata.")
  (:id 6 :status :scalar-output-static-consistent
   :evidence "Descrittori con ID u64 e forma tipizzata; maschere private 0..3; CLOSED mancanti e ACTIVE nell'union, REMOVED assenti esclusi. Query espongono soltanto ID/forma/azione/stato e conteggi, con range controllato, nessun riferimento ai vettori privati.")
  (:id 7 :status :decision-inventory-present-runtime-pending
   :evidence "La tabella inventario-decisioni.md elenca OR/AND della prova DELETE e AND ID/stato/forma della postcondizione, cardinalita, severita e intervalli. L'oracolo ha righe esplicite per tutte le forme applicative e disponibilita calcolata separatamente dalle righe.")
  (:id 8 :status :ownership-static-consistent
   :evidence "OWNER/SHARED dichiarati. Manifest e inventario non sono scritti: presence EQL, lista sort e vettore entry sono della chiamata. Descrittori contengono solo scalari read-only, ogni piano ha entry nuove. Riuso vettore e buffer EDIT e letture del piano comune sono prescritti nei test.")
  (:id 9 :status :integration-present-recorded-success-pending
   :evidence "ASDF carica inventory-types/build/query dopo manifest e support/tests dopo manifest-support. Registrati 13 test inventory e 95 recovery per conteggio statico. Primo build registrato fallito prima dei test per sintassi, corretto dal root; make check e tracciabilita finali restano da verificare.")
  (:id 10 :status :static-scope-reviewed-rebuild-pending
   :evidence "safety3, FTYPE completi, slot tipizzati/read-only, docstring REQ e rami finali osservati; funzioni brevi. Le nuove guardie attestano implicazioni locali, senza certificare equivalenza completa della classificazione o due guardie semantiche esplicite in ogni funzione. Il primo errore di lettura e il finding del cleanup sono conservati sopra.")
  (:id 11 :status :series-independent-static-design
   :evidence "Nessun lock, thread creato dal prodotto, stato globale mutabile o scrittura condivisa fra Serie. Query senza cache mutabile; test con quattro worker e piani privati, piano comune solo letture. Esito dei worker, join e cessazione sono controllati dal test; esecuzione ancora da raccogliere.")
  (:id 12 :status :no-durable-effect-in-scope
   :evidence "Il planner non apre, legge, rinomina, tronca o elimina file. UNKNOWN final e entrambe le forme sono conservati; DELETE indica REMOVED oppure UNKNOWN temporary. Un futuro esecutore I/O dovra verificare prova, identita e stabilita prima degli effetti durevoli; nessun punto di atomicita del recovery e realizzato qui."))
 :raw-report
 "Seconda lettura del planner inventory: nessun difetto funzionale trovato nella tabella, nell'ordine unsigned, nei budget o nell'ownership. I risultati coincidono staticamente con il contratto e l'oracolo a liste.

La prima compilazione registrata ha rilevato un errore di lettura prima dei test: mancava la chiusura del LET nel DOLIST del planner. La prima lettura visiva non lo aveva individuato. Root ha aggiunto la sola parentesi, senza cambiare comportamento. Ho riletto la chiusura e i punti di costruzione/ritorno, senza eseguire build o test.

Il mio finding iniziale sul cleanup dei worker resta conservato: il join di un secondo non attestava cessazione. Su autorizzazione del root ho aggiunto la sola postcondizione thread non vivo. Il test non conta come successo un errore del worker, un timeout o un thread residuo.

Checklist 1..12 completata sopra: requisiti/ADR, invarianti e test, errori tipizzati, cicli limitati, apertura con allocazioni dichiarate, output scalari, decisioni inventariate, proprietari privati, integrazione ASDF, regole di codifica, Serie indipendenti e assenza di effetti durevoli. Verifiche registrate successive, copertura e mutazioni restano da raccogliere; nessuna eccezione o qualifica MC/DC.

I test sono 13, con 6144 confronti del modello piccolo, 1440 permutazioni complete, u64/zero/max, doppie forme conservative, duplicati dopo :both, budget esatti/superati/zero, contratti FTYPE, input riusati e quattro worker con 32 piani privati oltre al piano comune. Questi sono conteggi dei casi prescritti nel codice, non risultati runtime raccolti dal recensore."
 :limits
 (:source-review-and-test-body-inspection-only :runtime-not-collected
  :recorded-initial-build-failure-preserved :recorded-final-checks-pending
  :public-input-stability-and-completeness-are-preconditions
  :no-file-content-header-crc-or-physical-identity-verification
  :no-controller-faulted-transition :no-plan-execution-or-durable-recovery
  :no-private-guard-coverage-exclusions :no-mcdc-qualification
  :no-complete-recovery-qualification :no-human-c1-approval
  :no-zero-heap-or-performance-claim))
