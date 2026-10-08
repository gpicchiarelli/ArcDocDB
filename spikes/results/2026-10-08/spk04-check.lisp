(:SCHEMA-VERSION 1 :ENVIRONMENT
 (:LISP #A((4) BASE-CHAR . "SBCL") :VERSION #A((5) BASE-CHAR . "2.6.9") :OS
  #A((6) BASE-CHAR . "Darwin") :OS-VERSION #A((6) BASE-CHAR . "27.0.0")
  :MACHINE #A((5) BASE-CHAR . "ARM64") :CPU "Apple M4" :MEMORY-BYTES
  17179869184 :LOGICAL-CPUS 10 :EXTERNAL-LOAD-STATUS :UNCONTROLLED
  :LOAD-AVERAGE "{ 9.63 11.20 11.24 }" :COMMIT
  "691331857d50482dbf2dcf64c27a324d4907ef9e" :WORKING-TREE
  "M .github/workflows/ci.yml
 D AGENTS.md
 M CHANGELOG.md
 D CLAUDE.md
 M CONTRIBUTING.md
 M Makefile
 M arcdocdb.asd
 M assets/README.md
 M docs/01-visione-e-obiettivi.md
 M docs/02-modello-logico.md
 M docs/03-storage.md
 M docs/04-wal-e-durability.md
 M docs/05-transazioni.md
 M docs/06-mvcc-e-snapshot.md
 M docs/07-compaction.md
 M docs/08-indici.md
 M docs/09-cache.md
 M docs/10-concorrenza-e-scheduling.md
 M docs/11-recovery.md
 M docs/12-osservabilita.md
 M docs/13-benchmark.md
 M docs/14-fault-injection.md
 M docs/15-ottimizzazioni-native.md
 M docs/16-moduli.md
 M docs/README.md
 M docs/adr/README.md
 M docs/architettura.md
 M docs/invarianti.md
 M docs/questioni-aperte.md
 M docs/roadmap.md
 D docs/specifica/prompt-originale.md
 M docs/tracciabilita/matrice.md
 M docs/tracciabilita/requisiti.lisp
 M docs/valutazione/README.md
 M docs/valutazione/piano-spike.md
 M docs/valutazione/registro-delle-prove.md
 M docs/valutazione/registro-rischi.md
 M docs/valutazione/risultati-2026-10-08.md
 M spikes/README.md
 M spikes/SPK-01-primary-index/README.md
 M spikes/SPK-02-gc/README.md
 M spikes/SPK-03-group-commit/README.md
 M spikes/SPK-09-integrity/README.md
 M spikes/SPK-10-v2-limits/README.md
 M spikes/SPK-10-v2-limits/cbor.lisp
 M spikes/SPK-10-v2-limits/codec.lisp
 M spikes/SPK-10-v2-limits/core.lisp
 M spikes/SPK-10-v2-limits/indice.lisp
 M spikes/SPK-10-v2-limits/metodo-cbor.md
 M spikes/SPK-10-v2-limits/metodo-codec.md
 M spikes/SPK-10-v2-limits/metodo-indice.md
 M spikes/SPK-10-v2-limits/metodo-migrazione.md
 M tools/run-spikes.lisp
?? docs/adr/0051-presentazione-della-documentazione.md
?? docs/guida-al-repository.md
?? docs/implementazione/
?? docs/specifica/specifica-originale.md
?? spikes/SPK-04-writer-pool/
?? spikes/results/2026-10-08/catalogo.lisp
?? spikes/results/2026-10-08/crc-inline-structured.lisp
?? spikes/results/2026-10-08/evidence-check-failed.lisp
?? spikes/results/2026-10-08/evidence-check.lisp
?? spikes/results/2026-10-08/full-spikes-check.lisp
?? spikes/results/2026-10-08/full-verification.lisp
?? spikes/results/2026-10-08/index-inline-100k-structured.lisp
?? spikes/results/2026-10-08/index-inline-10m-structured.lisp
?? spikes/results/2026-10-08/protocols-check.lisp
?? spikes/results/2026-10-08/publication-verification.lisp
?? spikes/results/2026-10-08/record-command-expected-failure.lisp
?? spikes/results/2026-10-08/spk04-check-initial-failed-process.lisp
?? spikes/results/2026-10-08/spk04-check-initial-failed.lisp
?? spikes/results/2026-10-08/spk04-check-parking-failed-process.lisp
?? spikes/results/2026-10-08/spk04-check-parking-failed.lisp
?? spikes/results/2026-10-08/v2-bench-initial.lisp
?? spikes/results/2026-10-08/v2-bench-lazy-stack-replica.lisp
?? spikes/results/2026-10-08/v2-bench-lazy-stack.lisp
?? spikes/results/2026-10-08/v2-cbor-allocation-check.lisp
?? spikes/results/2026-10-08/v2-cbor-allocations.lisp
?? spikes/results/2026-10-08/v2-indice-check.lisp
?? spikes/results/2026-10-08/v2-integration-check.lisp
?? spikes/results/2026-10-08/v2-migrazione-check.lisp
?? spikes/results/README.md
?? src/foundation/
?? tests/foundation/
?? tools/check-evidence.lisp
?? tools/foundation-bench.lisp
?? tools/foundation-coverage.lisp
?? tools/foundation-mutation.lisp
?? tools/record-command.lisp"
  :SOURCE-BLOBS
  ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
    "2e4b1f8ab3dc2e90eb6c4119c855bbb6865a770d")
   (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
    "cbec51aad2b64fb8c5be026891eff859ba371c18")
   (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
    "c0fee7b738395fcaf3359f297282cd266ce6dfad")
   (:PATH "spikes/SPK-01-primary-index/profile.lisp" :GIT-BLOB
    "a71fde100e32072b6e7b010228683b640ea4ff9a")
   (:PATH "spikes/SPK-10-v2-limits/codec.lisp" :GIT-BLOB
    "567c84546d29e1b8ddc5cd9e1a31b4e93519c75d")
   (:PATH "spikes/SPK-10-v2-limits/indice.lisp" :GIT-BLOB
    "bc978eb16aa7f0d69e3deac2df86057a650f8551")
   (:PATH "spikes/SPK-10-v2-limits/cbor.lisp" :GIT-BLOB
    "d6a5c93e34a0444d64b206df875a25b380545631")
   (:PATH "spikes/SPK-10-v2-limits/migrazione.lisp" :GIT-BLOB
    "cab850dc32ff9908b487b24edf3e1df2cc90008c")
   (:PATH "spikes/SPK-01-primary-index/run.lisp" :GIT-BLOB
    "9b32673c5bda223ba7783ec082af0890078d1e25")
   (:PATH #A((37) BASE-CHAR . "spikes/SPK-01-primary-index/core.lisp")
    :GIT-BLOB "c019f6ad53e173a0d336a4dbfaf903e274a66f08")
   (:PATH "spikes/SPK-02-gc/run.lisp" :GIT-BLOB
    "9fbe499100da40c2f7a14072af67c35c734949c5")
   (:PATH #A((26) BASE-CHAR . "spikes/SPK-02-gc/core.lisp") :GIT-BLOB
    "01f6760c75fa6e96a480fca41b1426941a9f703d")
   (:PATH "spikes/SPK-03-group-commit/run.lisp" :GIT-BLOB
    "c0b093e87028dd587c43d3cd52e59492270fdc38")
   (:PATH #A((36) BASE-CHAR . "spikes/SPK-03-group-commit/core.lisp") :GIT-BLOB
    "d3c58f2866e299ba27b0fa820c20317438774410")
   (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
    "77056cc1f695574ed0f4d34795b99aaea736f378")
   (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp") :GIT-BLOB
    "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
   (:PATH "spikes/SPK-07-protocols/run.lisp" :GIT-BLOB
    "0aa8d4a0a6cc59dbf5deae28395be85f61377ea4")
   (:PATH #A((33) BASE-CHAR . "spikes/SPK-07-protocols/core.lisp") :GIT-BLOB
    "489e2732cf5bfed4cd11251bb686a5d4f4e10b3e")
   (:PATH "spikes/SPK-09-integrity/run.lisp" :GIT-BLOB
    "c95660a4df5f2e6f6eb93e1078c2c36df6dabc85")
   (:PATH #A((33) BASE-CHAR . "spikes/SPK-09-integrity/core.lisp") :GIT-BLOB
    "80cdac4c0e52703618e1f274413b2ecbe00e6b14")
   (:PATH "spikes/SPK-10-v2-limits/run.lisp" :GIT-BLOB
    "6aa63afeac91c3b75174b76daba61e354bb7fe4d")
   (:PATH #A((33) BASE-CHAR . "spikes/SPK-10-v2-limits/core.lisp") :GIT-BLOB
    "c5b7cfd27c663734b7d5fae481dde939418566b5"))
  :DYNAMIC-SPACE-MIB 4096 :DATE-UNIVERSAL-TIME 4000477117)
 :MODE #A((7) BASE-CHAR . "--check") :STATUS :COMPLETE :RUNS
 ((:SCHEMA-VERSION 1 :ID "SPK-04" :COMMAND
   (#A((48) BASE-CHAR . "/opt/homebrew/Cellar/sbcl/2.6.9/libexec/bin/sbcl")
    "--dynamic-space-size" "4096" "--noinform" "--no-userinit" "--no-sysinit"
    "--script" "spikes/SPK-04-writer-pool/run.lisp"
    #A((7) BASE-CHAR . "--check"))
   :EXIT-CODE 0 :STARTED-AT-UNIVERSAL-TIME 4000477117
   :FINISHED-AT-UNIVERSAL-TIME 4000477117 :WALL-SECONDS 0.857851d0 :STATUS :OK
   :SOURCE-BLOBS-BEFORE
   ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
     "2e4b1f8ab3dc2e90eb6c4119c855bbb6865a770d")
    (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
     "77056cc1f695574ed0f4d34795b99aaea736f378")
    (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp") :GIT-BLOB
     "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
    (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
     "cbec51aad2b64fb8c5be026891eff859ba371c18")
    (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
     "c0fee7b738395fcaf3359f297282cd266ce6dfad"))
   :SOURCE-BLOBS-AFTER
   ((:PATH "tools/run-spikes.lisp" :GIT-BLOB
     "2e4b1f8ab3dc2e90eb6c4119c855bbb6865a770d")
    (:PATH "spikes/SPK-04-writer-pool/run.lisp" :GIT-BLOB
     "77056cc1f695574ed0f4d34795b99aaea736f378")
    (:PATH #A((35) BASE-CHAR . "spikes/SPK-04-writer-pool/core.lisp") :GIT-BLOB
     "557b32e6378290c46c7d9b128fc8e59a0e7e0a44")
    (:PATH "spikes/SPK-04-writer-pool/pool.lisp" :GIT-BLOB
     "cbec51aad2b64fb8c5be026891eff859ba371c18")
    (:PATH "spikes/SPK-04-writer-pool/parcheggi.lisp" :GIT-BLOB
     "c0fee7b738395fcaf3359f297282cd266ce6dfad"))
   :SOURCE-CONSISTENCY :STABLE :RESULT
   (:STATUS :OK :SPIKE :SPK-04 :POOL
    (:SPIKE :SPK-04 :MODULE :WRITER-POOL :STATUS :OK :RING
     (:STATUS :OK :CAPACITY 2 :REJECTED 1 :WRAPPED T) :MPSC
     (:STATUS :OK :SERIES 4 :PRODUCERS 8 :WORKERS 4 :OPERATIONS 256 :TRAITS 40
      :READY-LIST-ACCESSES 44)
     :WORKER-REPLACEMENT
     (:STATUS :OK :WORKER-SEQUENCE (0 1 0 1) :OPERATIONS 4 :JOINED-THREAD-COUNT
      4)
     :BURST
     (:STATUS :OK :HOT-OPERATIONS 64 :COLD-OPERATIONS (4 4 4) :FIRST-TRAITS
      (0 1 2 3) :COLD-COMPLETE-BY-TRAIT 4 :BOUND :ROUND-ROBIN-TRAITS
      :WALL-TIME-GUARANTEE NIL)
     :WORKER-ERRORS (:STATUS :OK :PROPAGATED :INJECTED :JOINED-THREAD-COUNT 4))
    :PARKING
    (:STATUS :OK :CASES
     ((:CASE "REQ-CON-004/eventi-fifo-idempotenti" :TIPO :CLIENTI-LOTTO :STATUS
       :OK)
      (:CASE "REQ-CON-004/scadenza-inclusiva-evento-tardivo" :TIPO
       :CLIENTI-LOTTO :STATUS :OK)
      (:CASE "REQ-CON-004/riuso-token-generazionale" :TIPO :CLIENTI-LOTTO
       :STATUS :OK)
      (:CASE "REQ-AFF-008/rifiuti-atomici-generazione-senza-wrap" :TIPO
       :CLIENTI-LOTTO :STATUS :OK)
      (:CASE "REQ-AFF-008/capacita-massima-crediti-coda" :TIPO :CLIENTI-LOTTO
       :STATUS :OK)
      (:CASE "REQ-CON-004/eventi-fifo-idempotenti" :TIPO :SNAPSHOT :STATUS :OK)
      (:CASE "REQ-CON-004/scadenza-inclusiva-evento-tardivo" :TIPO :SNAPSHOT
       :STATUS :OK)
      (:CASE "REQ-CON-004/riuso-token-generazionale" :TIPO :SNAPSHOT :STATUS
       :OK)
      (:CASE "REQ-AFF-008/rifiuti-atomici-generazione-senza-wrap" :TIPO
       :SNAPSHOT :STATUS :OK)
      (:CASE "REQ-AFF-008/capacita-massima-crediti-coda" :TIPO :SNAPSHOT
       :STATUS :OK)
      (:CASE "REQ-CON-004/eventi-fifo-idempotenti" :TIPO :COORDINATORI :STATUS
       :OK)
      (:CASE "REQ-CON-004/scadenza-inclusiva-evento-tardivo" :TIPO
       :COORDINATORI :STATUS :OK)
      (:CASE "REQ-CON-004/riuso-token-generazionale" :TIPO :COORDINATORI
       :STATUS :OK)
      (:CASE "REQ-AFF-008/rifiuti-atomici-generazione-senza-wrap" :TIPO
       :COORDINATORI :STATUS :OK)
      (:CASE "REQ-AFF-008/capacita-massima-crediti-coda" :TIPO :COORDINATORI
       :STATUS :OK))
     :LIMITS
     (:CONTESTI-PER-LISTA 4 :GENERAZIONE-MASSIMA 16 :CLOCK-LOGICO-MASSIMO 255
      :EVENTO-MASSIMO 31 :CODA-RIPRESE :CREDITO-RISERVATO-PER-CONTESTO :TIMEOUT
      :CLOCK-LOGICO-INIETTATO :ORDINE-RIPRESE :FIFO-DI-PUBBLICAZIONE :MODELLO
      :FLUSSO-UNICO-DETERMINISTICO :ESCLUSIONI
      (:THREAD-REALI :ATTESE-CLOCK-REALE :CALLBACK-ESTERNE
       :ALLOCAZIONI-MISURATE :DURABILITA :PRESTAZIONI)))
    :READ-RESTART
    (:STATUS :OK :CASES 9 :ASSERTIONS 54 :LIMITS
     (:FINITE-MODEL :NO-REAL-IO :NO-MVCC-RESOLUTION :NO-EPOCH-RECLAMATION))
    :PRODUCTION-GATE-COMPLETE NIL)
   :STDOUT "(:STATUS :OK :SPIKE :SPK-04 :POOL
 (:SPIKE :SPK-04 :MODULE :WRITER-POOL :STATUS :OK :RING
  (:STATUS :OK :CAPACITY 2 :REJECTED 1 :WRAPPED T) :MPSC
  (:STATUS :OK :SERIES 4 :PRODUCERS 8 :WORKERS 4 :OPERATIONS 256 :TRAITS 40
   :READY-LIST-ACCESSES 44)
  :WORKER-REPLACEMENT
  (:STATUS :OK :WORKER-SEQUENCE (0 1 0 1) :OPERATIONS 4 :JOINED-THREAD-COUNT 4)
  :BURST
  (:STATUS :OK :HOT-OPERATIONS 64 :COLD-OPERATIONS (4 4 4) :FIRST-TRAITS
   (0 1 2 3) :COLD-COMPLETE-BY-TRAIT 4 :BOUND :ROUND-ROBIN-TRAITS
   :WALL-TIME-GUARANTEE NIL)
  :WORKER-ERRORS (:STATUS :OK :PROPAGATED :INJECTED :JOINED-THREAD-COUNT 4))
 :PARKING
 (:STATUS :OK :CASES
  ((:CASE \"REQ-CON-004/eventi-fifo-idempotenti\" :TIPO :CLIENTI-LOTTO :STATUS
    :OK)
   (:CASE \"REQ-CON-004/scadenza-inclusiva-evento-tardivo\" :TIPO :CLIENTI-LOTTO
    :STATUS :OK)
   (:CASE \"REQ-CON-004/riuso-token-generazionale\" :TIPO :CLIENTI-LOTTO :STATUS
    :OK)
   (:CASE \"REQ-AFF-008/rifiuti-atomici-generazione-senza-wrap\" :TIPO
    :CLIENTI-LOTTO :STATUS :OK)
   (:CASE \"REQ-AFF-008/capacita-massima-crediti-coda\" :TIPO :CLIENTI-LOTTO
    :STATUS :OK)
   (:CASE \"REQ-CON-004/eventi-fifo-idempotenti\" :TIPO :SNAPSHOT :STATUS :OK)
   (:CASE \"REQ-CON-004/scadenza-inclusiva-evento-tardivo\" :TIPO :SNAPSHOT
    :STATUS :OK)
   (:CASE \"REQ-CON-004/riuso-token-generazionale\" :TIPO :SNAPSHOT :STATUS :OK)
   (:CASE \"REQ-AFF-008/rifiuti-atomici-generazione-senza-wrap\" :TIPO :SNAPSHOT
    :STATUS :OK)
   (:CASE \"REQ-AFF-008/capacita-massima-crediti-coda\" :TIPO :SNAPSHOT :STATUS
    :OK)
   (:CASE \"REQ-CON-004/eventi-fifo-idempotenti\" :TIPO :COORDINATORI :STATUS
    :OK)
   (:CASE \"REQ-CON-004/scadenza-inclusiva-evento-tardivo\" :TIPO :COORDINATORI
    :STATUS :OK)
   (:CASE \"REQ-CON-004/riuso-token-generazionale\" :TIPO :COORDINATORI :STATUS
    :OK)
   (:CASE \"REQ-AFF-008/rifiuti-atomici-generazione-senza-wrap\" :TIPO
    :COORDINATORI :STATUS :OK)
   (:CASE \"REQ-AFF-008/capacita-massima-crediti-coda\" :TIPO :COORDINATORI
    :STATUS :OK))
  :LIMITS
  (:CONTESTI-PER-LISTA 4 :GENERAZIONE-MASSIMA 16 :CLOCK-LOGICO-MASSIMO 255
   :EVENTO-MASSIMO 31 :CODA-RIPRESE :CREDITO-RISERVATO-PER-CONTESTO :TIMEOUT
   :CLOCK-LOGICO-INIETTATO :ORDINE-RIPRESE :FIFO-DI-PUBBLICAZIONE :MODELLO
   :FLUSSO-UNICO-DETERMINISTICO :ESCLUSIONI
   (:THREAD-REALI :ATTESE-CLOCK-REALE :CALLBACK-ESTERNE :ALLOCAZIONI-MISURATE
    :DURABILITA :PRESTAZIONI)))
 :READ-RESTART
 (:STATUS :OK :CASES 9 :ASSERTIONS 54 :LIMITS
  (:FINITE-MODEL :NO-REAL-IO :NO-MVCC-RESOLUTION :NO-EPOCH-RECLAMATION))
 :PRODUCTION-GATE-COMPLETE NIL)
"
   :STDERR ""))
 :RUN-ARTIFACTS
 (#A((87) BASE-CHAR
     . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/out/4000477115-check-10042-0/SPK-04.lisp")))
