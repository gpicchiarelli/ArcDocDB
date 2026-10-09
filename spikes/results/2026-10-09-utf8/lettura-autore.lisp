(:schema-version 1
 :formats nil
 :kind :c1-review
 :status :local-agent-reading
 :recorded-at 4000512676
 :reviewer "/root/development_next"
 :mode :source-author-reading-and-c4-audit
 :workspace "/Users/gpicchiarelli/.codex/worktrees/utf8-validation/ArcDocDB/"
 :human-approval nil
 :independent-of-root-reading t
 :independent-of-source-author nil
 :tests-read nil
 :campaigns-run nil
 :source-fingerprint-provenance
 "MD5 alla congelazione dopo la scrittura e dopo la lettura; entrambi coincidono. Non sono firme o prova di autenticita."
 :source-fingerprints
 ((:file "src/codec/package.lisp" :md5 "d885bd2a9860eb60aec1a775e5031d5e")
  (:file "src/codec/utf8.lisp" :md5 "0f67dd5c51bf6a63bc292ab4e2a280c2"))
 :reviewed-files
 ((:file "tools/utf8-bench.lisp" :md5 "bc6fca009ef204ec7a34d20c41d9796b")
  (:file "tools/foundation-coverage.lisp" :md5 "ceb8b3296a421027833294e83b21cfe0")
  (:file "docs/implementazione/utf8-metodo.md" :md5 "c055f4224cd59f84318011326b993d77"))
 :additional-documents-read
 ("docs/implementazione/utf8-decisioni.md" "docs/implementazione/utf8.md"
  "docs/affidabilita/standard-di-codifica.md"
  "docs/adr/0029-interfacce-protocollo-query-contratto.md"
  "docs/adr/0048-limiti-documentali-e-formato-v2.md"
  "docs/tracciabilita/requisiti.lisp")
 :normative-sources
 ("https://datatracker.ietf.org/doc/html/rfc3629#section-4"
  "https://www.rfc-editor.org/rfc/rfc8949.html#section-3.1")
 :scope
 "Kernel UTF-8 puro e limitato: count di scalari, nessuna decodifica di stringhe. Lettura autore svolta senza consultare tests/codec; tabella decisioni letta dopo la congelazione del prodotto."
 :c1-checks
 ((:item 1 :status :verified-by-reading
   :observation "REQ-LIM-001/002 e REQ-AFF-004/008 coerenti come supporto parziale; ADR-0029/0048. Non promossi i requisiti del decoder completo.")
  (:item 2 :status :needs-test-evidence
   :observation "INV-A4/A8/P6: controlli attivi su confini, progresso, conteggio e budget. Ogni helper non banale ha almeno due guardie significative. Mancano qui prove negative eseguite.")
  (:item 3 :status :needs-test-evidence
   :observation "Argomenti e budget: invalid-argument; superamento: resource-exhausted; UTF-8 malformato: corruption-detected; incoerenze interne: invariant-violation. Nessun errore ignorato; futuro worker deve applicare FAULTED. Priorita e offset conformi da lettura.")
  (:item 4 :status :verified-by-reading
   :observation "Ciclo principale al piu span<=16777216; continuazioni al piu 3. Nessuna ricorsione, attesa, retry o I/O.")
  (:item 5 :status :needs-allocation-evidence
   :observation "Nessuna costruzione di oggetti sul percorso normale evidente nel sorgente: interi, cursori e count locali, nessun scalare materializzato. Zero heap non attestato senza misura.")
  (:item 6 :status :verified-by-reading
   :observation "Solo count restituito dopo fine esatta e conteggio limitato. Nessun risultato parziale e nessuna scrittura nel buffer.")
  (:item 7 :status :needs-coverage-evidence
   :observation "Tabella letta: AND del range, AND del budget, AND del progresso; catene numeriche e loro confini inventariati. Nessun OR nel prodotto; MC/DC completa non dichiarata.")
  (:item 8 :status :verified-by-reading
   :observation "OWNER chiamante mantiene buffer immutabile; SHARED sola lettura. Cursore/count locali, unica costante immutabile; nessun globale mutabile.")
  (:item 9 :status :needs-root-check-evidence
   :observation "Tag REQ e documenti di scope coerenti; aggiornamento matrice e make check devono essere attestati dal runner. Nessuna campagna avviata da questo revisore.")
  (:item 10 :status :needs-build-and-lint-evidence
   :observation "Da lettura safety3, ftype completi, funzioni sotto60righe e complessita contenuta, niente costrutti vietati. Nessuna deviazione proposta. Il COND finale gestisce lead malformato previsto, non uno stato interno inatteso.")
  (:item 11 :status :verified-by-reading
   :observation "Nessun lock, attesa o scrittura condivisa per operazione tra Serie. Pura chiamata locale eseguibile da worker differenti; non dimostra scaling, fairness o comportamento del pool.")
  (:item 12 :status :not-applicable-readonly-kernel
   :observation "Nessun cambiamento durevole o eliminazione; API readonly senza punto di atomicita su disco."))
 :c4-audit
 (:status :no-concrete-defect-found-by-reading
  :benchmark
  (:cells 5 :replicas-per-cell 5 :calls-per-sample 64 :warmup-per-sample 128
   :fixtures
   ((:name :ascii :unit-bytes 1 :scalars-per-unit 1 :span-bytes 32768 :token 32768)
    (:name :two-byte :unit-bytes 2 :scalars-per-unit 1 :span-bytes 32768 :token 16384)
    (:name :three-byte :unit-bytes 3 :scalars-per-unit 1 :span-bytes 32766 :token 10922)
    (:name :four-byte :unit-bytes 4 :scalars-per-unit 1 :span-bytes 32768 :token 8192)
    (:name :mixed :unit-bytes 10 :scalars-per-unit 4 :span-bytes 32760 :token 13104))
   :sink "Somma count+indice chiamata, modulo most-positive-fixnum; atteso N*token+N*(N-1)/2. Token manuali indipendenti dal prodotto."
   :sensor "Warmup/GC fuori dalla misura; baseline0 e controllo positivo16x1MiB, oggetto finale vivo e heap>=16777216. I controlli sono presenti; non eseguiti da questo revisore."
   :clock "Tick grezzi e risoluzione registrati; zero tick produce rate NIL, nessuna velocita fittizia o soglia temporale."
   :immutability "Copia completa della fixture e sentinelle esterne confrontate fuori misura."
   :provenance "Snapshot MD5 prima del load-product e dopo la campagna; cambiamento sorgente rende esito source-changed. Caricamento prima delle forme qualificate, avvisi fatali, diagnostica su stderr."
   :correction "Nel primo messaggio del revisore il token misto11912 era un errore di conteggio manuale. Fonte congelata corretta: pattern10byte,3276ripetizioni,token13104. Nessuna modifica al driver.")
  :coverage
  (:scope "codec: run dei test arcdocdb.utf8.tests e report completo di tutti src/codec, package incluso."
   :state "coverage-state salvato prima del report filtrato; build prodotto/tests forzato e cache ASDF locale; warning fatale."
   :limits "Il driver coverage non rende esclusiva la directory e non calcola fingerprint. Runner deve usare destinazione nuova e wrapper con snapshot, conservando tutti HTML/state e tentativi; questa lettura non inventa esclusivita o provenienza non presenti nel driver."))
 :observations
 ("Preflight range/budget/esaurimento avviene prima di byte e THE locali. Buffer/start/end/max-bytes pubblici sono T, non rifiutati da FTYPE stretti prima del controllo tipizzato."
  "Ordine verificato: lead, width nello span, ogni continuazione da sinistra a destra, restrizione E0/ED/F0/F4. Troncatura usa offset end; scalar usa secondo byte."
  "NUL/BOM/noncaratteri sono accettati dalla grammatica; nessuna conversione, NFC, sostituzione o interpretazione CBOR."
  "Non letti tests/codec in scrittura; non sono attestati test, build, heap, coverage o mutanti PASS.")
 :limits
 (:author-reading :no-human-approval :no-campaign-execution :tests-not-read
  :not-a-cbor-parser :no-document-budget-overhead-proof :no-depth-proof
  :no-complete-mcdc-claim :no-faulted-controller :no-engine-release-gate
  :no-scheduler-or-pool-scaling-claim))
