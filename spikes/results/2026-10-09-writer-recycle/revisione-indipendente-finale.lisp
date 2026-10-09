(:schema-version 1
 :kind :c1-independent-final-reading
 :base "673987ad819dd48741a7c0a4ff259137a1ed0bef"
 :reviewer "/root/next_execution_design"
 :source "src/execution/ready-recycle.lisp"
 :initial-source-sha256 "51ddbf06d1639427317ac25d00140ec2020be14b315ed364fd1ae425ebed145c"
 :final-source-sha256 "2873a5f4bb34a5e0119af41bdc1220c4c02767b985ade16c7437e4e7d13e525b"
 :source-change "Solo commento iniziale: publica corretto in pubblica."
 :test-sha256 "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae"
 :mutation-tool-sha256 "365912245d23c7e2f75539b85c8c34c50ec799bf152ca7e8954c4c7fedc1a3ec"
 :benchmark-tool-sha256 "4f0f1e2feef4079e6b4582a3d1380a05b6c3cf146bb331cc1ca1af08070a4d82"
 :functional-findings ()
 :open-findings ()
 :result :local-review-completed
 :checks
 ((:point 1 :status :reviewed
   :report "REQ-CON-001/002/004/005 e REQ-AFF-008, INV-P1/P2/P5/P6/A8/V4 e ADR-0005/0045 sono coerenti con il trasferimento bounded di obblighi. Non si promuove REQ-THR-001 o un gate del motore: controller adattivo, thread, wake/park e I/O non appartengono al ricircolo.")
  (:point 2 :status :reviewed-with-executed-evidence
   :report "Forma/proprietà del ring, FIFO, count, tipo della testa, unicità dell'obbligo e della lease hanno fixture eseguite. La baseline completa ha 66 test execution, inclusi 15 recycle. Oracolo a liste con seme: 8 configurazioni, 1000 passi ciascuna, obblighi legali e drain; capacità 1/2/3/9, wrap e riuso. La fixture conserva il controesempio full per tutti i consumer e poi verifica il ricircolo. I thread riusati elaborano 48 payload in 8 ondate con producer vivo; altra partizione progredisce con una guard trattenuta. Tutti gli undici mutanti sono detected dopo avvio di un test recycle e prima del completion.")
  (:point 3 :status :reviewed-with-executed-evidence
   :report "invalid-argument :ready-target/:ready-writer precede acquisizione e scritture. resource-exhausted :ready-queue-busy conserva A prima della mutazione, full o room. Invariant-violation per guard/forma/testa e :ready-recycle-full per helper full su ring vuoto: FI verifica snapshot e cleanup. Nessun rifiuto full nel nuovo ricircolo, nessun errore nascosto o rollback promesso dopo guasto interno. Il proprietario deve applicare fail-stop della Serie: il controller non è implementato da questo modulo.")
  (:point 4 :status :reviewed
   :report "Le tre funzioni non contengono cicli, ricorsione o attese. Una acquisizione CAS e un rilascio CAS, senza retry; verificatori scalari bounded. Sul pieno si scrive uno slot e si avanzano due indici modulo capacity. Il caso capacity 1 è verificato e non aggiunge loop o buffer.")
  (:point 5 :status :reviewed-with-measurement
   :report "Benchmark composto handoff/ready/ricircolo, 4 configurazioni K=1/4 e C=1/3, 5 campioni di 4096 cicli ciascuna: 20 campioni heap 0. Token ricalcolati indipendentemente 257/558/1223/3231; sink 9439232/10672128/13395968/21620736. Positive control 16777472 byte; sink errato rifiutato, clock zero below-resolution, report parziale ed existing destination preservati. Misura del percorso normale preallocato seriale; non zero universale, non misura del pool o di throughput/P99.")
  (:point 6 :status :reviewed-with-executed-evidence
   :report "Shard e input verificati prima della guard; la testa full è verificata prima di lasciare il ring. %check-pronta è pre/post dello scambio, o transitive del helper ordinario room. Test FI verificano testa NIL/foreign e free-tail occupata, senza mutazione. I riferimenti rimangono opachi: nessuna verifica dell'eleggibilità o dedup globale, e nessuna promessa su payload non toccati dal ring.")
  (:point 7 :status :reviewed-with-raw-coverage
   :report "Nessun nuovo and/or di controllo, or nei ftype è unione di tipi. Le decisioni scalari e i controlli transitive sono inventariati. Native ricalcolato indipendentemente e HTMLParser concordano sui sette file: 929/1060 espressioni, 134/154 esiti. Recycle 81/86 e 8/8; cinque forme top-level mancanti (0)(1)(2)(4)(6), definizioni mantenute. Tutti i 131 missing expression e i 20 missing branch sono nel raw e mappati nell'inventario. Nessuna esclusione e nessuna inferenza MC/DC da sb-cover.")
  (:point 8 :status :reviewed-with-executed-evidence
   :report "Guard locale possiede ring/indici/slots. Prima di successo A è del caller; room lo trasferisce al ring. Full trasferisce A al ring e C al caller nello stesso accesso; un successo non autorizza ripubblicazione di A. C viene conservato durante begin busy. Nessuna membership o cleanup del writer dopo end: la nuova ondata rimane valida. Il caso A=C è FI privata dichiarata fuori dagli obblighi pubblici unici, senza dedup claim.")
  (:point 9 :status :reviewed-with-integrated-check
   :report "ASDF e package registrano API/prodotto/test; REQ nei nomi dei test e nel prodotto. Check 4000528494-command-77199-0 è OK/STABLE/exit0, wall107.748252: 309 test dei nove moduli più smoke (26+17UTF8+17CBOR+20CSN+66execution+44storage+18IO+82recovery+19WAL). Lint53file/0violazioni; trace114REQ/65INV/13FI/52ADR/0errori; links199file/1921link/0rotti. Master4000528568-check-78100-0 complete, 10run/10artifact, tutti exit0/stable; 9ok e SPK07pass. Nessun warning/style-warning reale nei processi letti. Check precede i soli aggiornamenti editoriali finali dell'inventario.")
  (:point 10 :status :reviewed-with-integrated-check
   :report "Safety3, ftype completi, docstring e funzioni brevi, nessuna global mutabile nuova, syscall o gestore generico. %ricircola-pronto delega le postcondizioni ai due helper con pre/post verificate. Lint prodotto e build rigoroso passano. C4 compilati interamente e self-test dei FASL passati, senza warning/style-warning. Fixture SIGKILL exit137/signal9 classificata worker-error, 0detected; non conteggiata come mutazione rilevata. Nessuna deviazione o esclusione approvata.")
  (:point 11 :status :reviewed
   :report "Ricircolo O(1) serializza soltanto il breve accesso al ring della partizione per tratto, nessuna scrittura comune per messaggio o guard tra shard. Elimina il blocco dovuto alla sola capienza nel protocollo modellato, senza seconda coda. Full count invariato e candidato locale non provano fairness globale o admission; guard perpetuamente contesa e obblighi abbandonati restano limiti. Empty non autorizza park, shutdown o ritiro di worker.")
  (:point 12 :status :reviewed
   :report "Nessun cambiamento persistente, eliminazione, syscall o punto di atomicità durevole. Lo scambio è atomico soltanto rispetto agli accessi al ring sotto la guard. Non vengono aggiunte promesse su recovery, durability o conferme del motore."))
 :evidence
 (:coverage-process "4000528494-command-77200-0"
  :coverage-export-process "4000528526-command-77598-0"
  :strict-benchmark-process "4000528528-command-77652-0"
  :strict-mutation-process "4000528528-command-77653-0"
  :mutation-process "4000528603-command-78553-0"
  :benchmark-process "4000528603-command-78552-0"
  :signal-fixture "4000528529-recycle-signal-self-test-77690"
  :full-check-process "4000528494-command-77199-0"
  :spike-master "4000528568-check-78100-0"
  :independent-audit-process "4000528971-command-81260-0"
  :failed-independent-audit-process "4000528942-command-81018-0")
 :audit-adapters
 ("spikes/out/recycle-review-audit-native-reader-failed.lisp"
  "spikes/out/recycle-review-audit.lisp"
  "spikes/out/recycle-review-html.py")
 :auxiliary-probe-failure
 "Primo audit ha passato il native sb-cover, che non è plist, al lettore evidence. Versione fallita conservata; corretto a read diretto con *read-eval*NIL. Probe fallito e corretto sono record distinti; non guasto prodotto o C4."
 :coverage (:expressions-hit 929 :expressions-total 1060 :branches-hit 134 :branches-total 154
            :new-expressions-hit 81 :new-expressions-total 86 :new-branches-hit 8 :new-branches-total 8
            :new-missing-expressions ((0) (1) (2) (4) (6)) :new-missing-branches ())
 :approved-exclusions ()
 :mcdc-qualified nil
 :requirements-promoted ()
 :limits (:local-component-only :no-general-pool-liveness :no-admission-fairness
          :no-global-fairness :no-park-wake :no-shutdown :no-series-fault-controller
          :no-universal-zero-allocation :no-throughput-or-p99-qualification))
