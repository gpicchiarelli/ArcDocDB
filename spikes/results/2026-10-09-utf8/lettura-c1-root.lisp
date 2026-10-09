(:schema-version 1 :kind :c1-review :formats nil :status :local-agent-reading
 :reviewer "/root" :mode :read-only-source-contract-audit
 :recorded-at 4000512767
 :source-files ((:file "src/codec/package.lisp" :md5 "d885bd2a9860eb60aec1a775e5031d5e") (:file "src/codec/utf8.lisp" :md5 "0f67dd5c51bf6a63bc292ab4e2a280c2"))
 :checks (
  (:item 1 :status :coherent :finding "REQ-LIM-001/002 e AFF-004/008: kernel di testo entro budget, senza attestazione del parser CBOR o del documento completo.")
  (:item 2 :status :guarded :finding "Range e budget precedono byte/THE. Width dentro span prima delle continuazioni; scalar dopo tutte le continuazioni; progresso/conteggio con guardie interne.")
  (:item 3 :status :typed-with-integration-limit :finding "Errori input, risorse, corruzione e invarianti distinti. Offset end per truncation, first-bad per continuation, second per scalar. Controller FAULTED ancora da integrare.")
  (:item 4 :status :bounded :finding "Loop repeat span<=16777216, cursor crescente; dotimes width-1<=3; nessuna attesa o ricorsione.")
  (:item 5 :status :measurement-pending :finding "Percorso riuscito usa soli byte e fixnum locali; nessuna stringa/cons/allocation esplicita. Zero heap richiede campagna separata.")
  (:item 6 :status :validated :finding "Nessun count restituito prima della verifica integrale. Indici private helper derivati da range guardato e width<=end-cursor.")
  (:item 7 :status :table-present-coverage-pending :finding "utf8-decisioni.md elenca range AND, budget AND e progresso AND. False delle guardie interne restano distinte da input malformed; nessuna MC/DC completa.")
  (:item 8 :status :immutable-caller-ownership :finding "OWNER caller immutable buffer; solo letture AREf, nessun SETF su dati o mutabile globale.")
  (:item 9 :status :integrated-evidence-pending :finding "REQ source coerenti; build/lint/trace/check saranno registrati dopo freeze tests e driver.")
  (:item 10 :status :no-source-rule-defect-found :finding "Ftype completi, safety3, funzioni<=60righe, >=2guardie significative, nessun broad handler. COND finale malformed previsto segnala corruption.")
  (:item 11 :status :parallel-callable :finding "Nessuna scrittura/attesa/lock comune per chiamata. Thread runtime, immutabilita input e prestazioni vanno verificati separatamente.")
  (:item 12 :status :no-durable-operation :finding "Nessun I/O, conferma, pubblicazione o eliminazione; atomicita durevole fuori scope."))
 :limits (:local-agent-reading-not-human-approval :runtime-evidence-pending :not-mcdc :no-waiver :no-parser-no-worker-controller-no-release-gate))
