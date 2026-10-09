(:schema-version 1 :kind :local-static-reading :date "2026-10-09"
 :reading :payload-controls-arena :independent-review nil :qualification nil
 :source-paths ("src/index/primary-probe.lisp" "src/index/primary-read.lisp"
                "src/index/primary-write.lisp" "src/index/primary-relocate.lisp")
 :observations
 ((:id :group-miss :finding "Il gruppo esamina i fingerprint prima di decidere EMPTY; DELETED non termina.")
  (:id :shared-budget :finding "Ogni campione seqlock e cambio root consuma il contesto; niente otto tentativi per slot.")
  (:id :arena :finding "Arena acquisita dopo payload; byte precedenti mai sovrascritti; crescita preserva offset.")
  (:id :output :finding "Copia esterna dopo conferma root su hit; miss/retry-limit non copiano.")
  (:id :reentry :finding "Contesto occupato rifiutato prima del cleanup; uscita non locale libera solo il proprio contesto.")
  (:id :relocation :finding "Messaggio risolto per chiave corrente; offset arena vecchio ignorato; confronto include versione/location.")
  (:id :publication :finding "Preflight prima della prima mutazione condivisa; cleanup composto invalida indice/banco."))
 :open (:functional-cases :concurrent-interleavings :fault-injection :allocation-measurements
        :request-hash :snapshot-retention :transaction-reservations :integrated-get))
