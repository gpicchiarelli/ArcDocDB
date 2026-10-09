(:schema-version 1
 :kind :c1-independent-initial-reading
 :base "673987ad819dd48741a7c0a4ff259137a1ed0bef"
 :reviewer "/root/next_execution_design"
 :scope ("src/execution/ready-recycle.lisp"
         "tests/execution/ready-recycle.lisp"
         "src/execution/package.lisp"
         "arcdocdb.asd"
         "docs/implementazione/writer-recycle-metodo.md")
 :source-sha256 "51ddbf06d1639427317ac25d00140ec2020be14b315ed364fd1ae425ebed145c"
 :test-sha256 "c1ec12ce11df80b7679f00eed72a2a6ae3b97999eef5b20f08627a949549fbae"
 :functional-findings ()
 :textual-note "Prima riga: refuso publica, già affidato al responsabile per correzione. Il relativo hash identifica esattamente la lettura precedente alla correzione."
 :execution-claims ()
 :checks
 ((:point 1 :status :reviewed
   :report "REQ-CON-001/002/004/005 e REQ-AFF-008 sono riportati sulle tre funzioni. Il contratto è coerente con ADR-0045 §§6/8: trasferimento per tratto, nessun worker creato o bloccato, nessuno stato globale nuovo. ADR-0011 resta controller separato.")
  (:point 2 :status :reviewed-fixtures-not-executed
   :report "Guard/forma, capienza full, tipo della testa, FIFO con wrap, count invariato, unicità degli obblighi e lease singola sono gli invarianti toccati. Le fixture lette coprono room/full, capacity 1/2/3/9, oracolo a liste con seme, saturation di tutti i consumer, rifiuti busy e FI. Nessun esito di esecuzione anticipato.")
  (:point 3 :status :reviewed-fixtures-not-executed
   :report "Indice/riferimento invalidi sono invalid-argument prima della guard. Busy è resource-exhausted :ready-queue-busy prima della mutazione, conservando A. Guasti di forma, guard o testa sono invariant-violation; :ready-recycle-full identifica il helper full usato su ring non pieno. Test dedicati confrontano snapshot. Errori interni richiedono fail-stop del proprietario; il modulo non implementa ancora il controller FAULTED della Serie, e non promette rollback dopo un guasto interno.")
  (:point 4 :status :reviewed
   :report "Nessun ciclo o ricorsione nelle tre nuove funzioni. Si usa una acquisizione CAS e, dopo successo, un rilascio CAS, senza retry o attesa. Verificatori transitive scalari e bounded; lo scambio scrive un solo slot e due indici.")
  (:point 5 :status :pending-measurement
   :report "Nessuna allocazione esplicita nel percorso normale del nuovo sorgente: valori multipli, riferimenti e indici preallocati. La misura composta preregistrata è ancora da eseguire. Non si afferma zero heap osservato o universale; startup e condizioni d'errore restano fuori dalla finestra normale.")
  (:point 6 :status :reviewed
   :report "Input shard e writer sono verificati prima della mutazione. La testa full è verificata come writer-programmabile prima di restituirla; forma e proprietà sono verificate pre/post. I payload non toccati restano opachi come nella lista precedente. Nessuna lettura dello stato writer, dell'eleggibilità o della membership viene promessa.")
  (:point 7 :status :reviewed
   :report "Nessun nuovo and/or di controllo nelle tre funzioni; or nei ftype è unione di tipi. Due controlli full, tipo testa, tipo input e busy sono decisioni scalari inventariate. La nuova assenza di decisioni composte non prova MC/DC completa dei helper precedenti o del modulo execution.")
  (:point 8 :status :reviewed
   :report "Ring/indici/slots appartengono al proprietario della guard locale. Prima del successo A è del caller; room lo trasferisce al ring. Full trasferisce A al ring e C al caller sotto la stessa guard. I commenti OWNER/SHARED dichiarano frequenza per tratto. Obblighi duplicati, inclusa identità A=C, violano la precondizione pubblica; il solo duplicato opaco letto è FI privata dichiarata.")
  (:point 9 :status :pending-execution
   :report "ASDF registra prodotto e test recycle dopo ready; package esporta la nuova API. REQ sulle funzioni e nei nomi dei test sono presenti. La matrice generata, trace, links e make check devono ancora essere eseguiti sulla copia congelata; nessun requisito viene promosso.")
  (:point 10 :status :reviewed-checks-pending
   :report "Safety 3, ftype completi, tre funzioni brevi, docstring con pre/post/condizioni, nessun gestore generico, I/O, variabile globale nuova o unwind-protect che nasconda errori. La post di %ricircola-pronto è delegata ai due helper, entrambi con verifiche pre/post. Lint e compilazione rigorosa non ancora eseguiti; nessuna deviazione o esclusione approvata da questa lettura.")
  (:point 11 :status :reviewed
   :report "Nessuna scrittura comune per messaggio, lock globale o nuova attesa tra Serie. Il nuovo ricircolo serializza soltanto il breve scambio sul proprio ring per tratto. Scambio full elimina il blocco dovuto alla sola capienza nel modello preregistrato; count full invariato e candidato dallo stesso shard non dimostrano equità globale, admission fairness o liveness del pool completo.")
  (:point 12 :status :reviewed
   :report "Nessun dato persistente, syscall, eliminazione o cambiamento durevole. L'atomicità è soltanto in memoria, rispetto agli accessi sotto la guard del ring. Non viene introdotto un punto di atomicità durevole né una nuova promessa su recovery o commit."))
 :historical-coverage
 (:provenance "Campagna ready precedente, riportata come storico senza attribuirla al ricircolo."
  :files ((:file "package.lisp" :expressions-hit 0 :expressions-total 1 :branches-hit 0 :branches-total 0)
          (:file "queue.lisp" :expressions-hit 142 :expressions-total 184 :branches-hit 24 :branches-total 34)
          (:file "writer.lisp" :expressions-hit 190 :expressions-total 218 :branches-hit 36 :branches-total 44)
          (:file "handoff.lisp" :expressions-hit 173 :expressions-total 190 :branches-hit 16 :branches-total 16)
          (:file "ready-types.lisp" :expressions-hit 170 :expressions-total 187 :branches-hit 30 :branches-total 30)
          (:file "ready.lisp" :expressions-hit 173 :expressions-total 194 :branches-hit 20 :branches-total 22))
  :total (:expressions-hit 848 :expressions-total 974 :branches-hit 126 :branches-total 146))
 :pending (:strict-compilation :test-execution :raw-coverage :mutation-campaign
           :allocation-measurement :trace :links :make-check :second-independent-reading)
 :approved-exclusions ()
 :mcdc-qualified nil
 :limit "Lettura statica indipendente iniziale, non campagna. Seconda lettura sui dati congelati necessaria prima della chiusura locale C1.")
