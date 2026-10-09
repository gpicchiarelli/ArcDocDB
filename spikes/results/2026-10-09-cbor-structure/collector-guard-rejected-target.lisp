(:schema-version 1 :kind :collector-rejected-attempt :status :failed
 :statement-source "root: risultato exec_command della seconda invocazione del guard"
 :command ("sbcl" "--noinform" "--no-userinit" "--no-sysinit" "--script" "/tmp/cbor-structure-collector-guard-test.lisp")
 :exit-code 1 :diagnostic "Target esistente conservato: /tmp/cbor-structure-collector-self-test.lisp"
 :original-tool-output-complete nil :original-tool-output-truncated t
 :consequence "Preflight rifiuta il target già esistente; nessuna fixture o report viene sovrascritto."
 :limits (:tool-result-transcription-not-original-byte-stream))
