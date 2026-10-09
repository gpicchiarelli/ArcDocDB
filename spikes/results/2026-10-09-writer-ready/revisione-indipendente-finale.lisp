(:CLOSURE-APPENDICES
 ((:BASE-COMMIT "201562dffd8c48e5d2047f73ef905f64b447e663" :REPORT
   "Appendice locale storica, base 201562dffd8c48e5d2047f73ef905f64b447e663. Il report originale e la chiusura fd96 restano verbatim.
ASDF SHA-256 3bc16fe72222b2adfcad7d7fe862a3f8a05d3ae8fa395f0deeabc6e22290edde; registrazioni execution/ready conservate, sorgenti ready/test/bench/runner invariati. Non è una lettura C1 dei sorgenti CBOR.
Check 4000522514-command-56618-0 letto via evidence:read-evidence: :OK/:STABLE, exit 0, wall 102.063356 s; 274 test degli otto moduli (26+17 UTF-8+17 CBOR+51 execution+44 storage+18 I/O+82 recovery+19 WAL), oltre allo smoke; lint 50 file/0 violazioni; trace 114 REQ/65 INV/13 FI/52 ADR/0 errori; links 193 file/1899 link/0 rotti. Stderr note del compilatore/progresso spike, nessun warning/style-warning reale.
Master 4000522582-check-59441-0: :COMPLETE, --check, 10 run/10 artifact; SPK-01..10 exit 0/:STABLE, nove :OK e SPK-07 :PASS, statuti interni corrispondenti. Metadati raw: SBCL 2.6.9, Darwin 27.0.0, ARM64 Apple M4, RAM 17179869184 byte, 10 CPU logiche, dynamic-space 4096 MiB, carico esterno :UNCONTROLLED, load-average { 3.89 3.37 3.63 }, commit 201562dffd8c48e5d2047f73ef905f64b447e663, date-universal-time 4000522586.
Nessun finding ready aperto. I check precedenti e le campagne mirate mantengono la propria provenienza; nessuna qualifica di pool, prestazioni o motore integrato.")
  (:BASE-COMMIT "33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691" :REPORT
   "Appendice locale definitiva, base 33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691. Il report originale 92d8 e le appendici fd96/201562 restano verbatim.
ASDF SHA-256 6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc; registrazioni ready conservate. Ready-types, ready, test e strumenti ready sono byte-identici alle letture precedenti. Non è una lettura C1 dei sorgenti CSN.
Check 4000522904-command-41347-0 letto via evidence:read-evidence: :OK/:STABLE, exit 0, wall 109.725672 s; 294 test dei nove moduli (26+17 UTF-8+17 CBOR+20 CSN+51 execution+44 storage+18 I/O+82 recovery+19 WAL), oltre allo smoke; lint 52 file/0 violazioni; trace 114 REQ/65 INV/13 FI/52 ADR/0 errori; links 198 file/1918 link/0 rotti. Stderr 27215 byte, senza righe di warning/style-warning reali.
Master 4000522979-check-41982-0: :COMPLETE, --check, 10 run/10 artifact; SPK-01..10 exit 0/:STABLE, nove :OK e SPK-07 :PASS, statuti interni corrispondenti. Metadati raw: SBCL 2.6.9, Darwin 27.0.0, ARM64 Apple M4, RAM 17179869184 byte, 10 CPU logiche, dynamic-space 4096 MiB, carico esterno :UNCONTROLLED, load-average { 2.10 2.88 3.34 }, commit 33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691, date-universal-time 4000522983.
La verifica locale dei dodici punti è chiusa senza finding ready aperti. I due rilievi testuali iniziali e il rilievo C4 del runner sono chiusi. Native/HTML restano 848/974 espressioni e 126/146 esiti, con lacune nuove e legacy conservate; nessuna esclusione approvata o MC/DC dedotta. Mutazioni finali 12/12 detected senza altri esiti e allocazioni seriali 10/10 heap zero mantengono le basi originali e non qualificano pool, wakeup, shutdown, FAULTED, throughput/P99, scalabilità o motore integrato. Nessuna campagna eseguita dal revisore."))
 :INVENTORY
 (:PATH "docs/implementazione/writer-ready-decisioni.md" :SHA256
  "cc432094d4c5916c22401c38189a5a690b557ef6bd5394313d93af2e8a95183a")
 :RAW-COVERAGE
 (:EXPRESSIONS 848 :EXPRESSION-TOTAL 974 :BRANCHES 126 :BRANCH-TOTAL 146
  :EXCLUSIONS-APPROVED NIL :MCDC-QUALIFIED NIL)
 :SOURCE-HASHES
 ((:FILE "arcdocdb.asd" :SHA256
   "6589f8ca1eea521c5bb57f9ee42a44fbedbe70fe6ef5524199eab67216a6b3cc")
  (:FILE "src/execution/package.lisp" :SHA256
   "97704f44544084b6823924a48724f4fc54fdbda60df1b0891c5066afaf183af8")
  (:FILE "src/execution/queue.lisp" :SHA256
   "244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90")
  (:FILE "src/execution/writer.lisp" :SHA256
   "8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105")
  (:FILE "src/execution/handoff.lisp" :SHA256
   "ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607")
  (:FILE "src/execution/ready-types.lisp" :SHA256
   "0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f")
  (:FILE "src/execution/ready.lisp" :SHA256
   "a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327")
  (:FILE "tests/execution/ready.lisp" :SHA256
   "4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e")
  (:FILE "tools/writer-ready-bench.lisp" :SHA256
   "9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4")
  (:FILE "tools/writer-ready-mutation.lisp" :SHA256
   "06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb"))
 :OPEN-FINDINGS NIL :FD96-DELTA-HASHES
 ((:FILE "arcdocdb.asd" :SHA256
   "4fc264ec2638b5d3b778890405942fadb3857180ab7c3818d8377e6a2f50e458")
  (:FILE "tools/writer-ready-mutation.lisp" :SHA256
   "06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb")
  (:FILE "docs/implementazione/writer-ready-metodo.md" :SHA256
   "6f778d4eccdc5d8fccc0b63d8677956a13837991e9a915ab4ad79d1592b4952f"))
 :INITIAL-INTEGRATION-BASE "fd96fb3145f593f31552de26a8fd93478b69fc8f"
 :REPORT-ORIGINAL
 "Revisione C1 indipendente finale della lista writer pronti, base 92d8b0e.

Esito: nessun finding funzionale aperto. Le due precisazioni della prima lettura sono chiuse nelle docstring finali. La verifica integrata make check rimane in attesa; copertura incompleta e limiti di qualificazione restano espliciti.

1. Requisiti e ADR: REQ-CON-001/002/004/005 e REQ-AFF-008 sono coerenti con ADR-0005 e ADR-0045 §§6/8. Il componente trasporta soltanto obblighi :schedule; handoff conserva stato e lease. ASDF registra sorgenti e 17 test, package esporta le quattro API.

2. Invarianti: INV-P1/P2/P5/P6, INV-A8 e INV-V4 sono elencati. Gli oracoli pubblici generano un obbligo legale prima della pubblicazione, conservano pending dopo full e completano prima del riuso. FI private verificano bounds, relazione FIFO, vettori e payload; prove concorrenti verificano servizio di altro shard e un unico dequeue per ondata. La sola fixture opaca duplicata usa un ring privato dichiarato, fuori dal protocollo handoff.

3. Errori: invalid-argument per configurazione/shard/writer; resource-exhausted full/busy di pubblicazione; invariant-violation per forma, slot, proprietà o statuto interno. I rifiuti ordinari precedono la mutazione e il cleanup segue l’acquisizione verificata. I due esiti difensivi CAS non marcati richiedono guasto della proprietà; non sono esclusi né dichiarati provati. Il controller FAULTED del motore resta da integrare.

4. Limiti: factory <=64 partizioni; scansione <=K<=64 tentativi CAS di acquisizione e <=K rilasci, massimo 128 CAS totali. Capacity <=65536 per shard, <=4194304 riferimenti complessivi. Nessuno spin, ricorsione, I/O, callback o attesa nel prodotto. Semafori e join del solo harness hanno timeout e worker riusati.

5. Allocazioni: campagna composta handoff+ready 4000520933-command-3549-0 :OK/:STABLE, exit 0. Dieci campioni, 4096 cicli e warmup 128: heap 0 in tutti; sink esatti 9246720/12797952 per token indipendenti 210/1077. Controllo positivo 16777472 byte, wrong sink rifiutato, clock zero distinto, dati parziali e destinazione conservati. La misura riguarda percorsi normali seriali, senza garanzia universale, contesa, scaling, throughput o P99.

6. Dati in uscita: shard/configurazione/writer verificati prima delle scritture; ring verificato prima e dopo; riferimento prelevato controllato come writer-programmabile, slot liberato. La validità semantica e l’unicità dell’obbligo restano precondizioni del caller, senza membership o deduplicazione nascoste.

7. Decisioni: inventario completo in writer-ready-decisioni.md, scalari/default/CASE/guard/cleanup e deleghe. Nessun nuovo and/or decisionale; le unioni di tipo restano nel raw. Complessità locale massima 7/10. Ricalcolo native e HTML concorde: package 0/1,0/0; queue 142/184,24/34; writer 190/218,36/44; handoff 173/190,16/16; ready-types 170/187,30/30; ready 173/194,20/22. Totale 848/974 espressioni,126/146 esiti. Tutte le forme/esiti mancanti nuovi e legacy sono mappati nell’inventario; nessun denominatore ridotto o MC/DC completa dedotta.

8. Proprietà: commenti OWNER/SHARED coerenti; ogni ring possiede indici e slots sotto la propria guard, vettore e identità read-only dopo factory. Il caller possiede l’obbligo prima di publish, il ring dopo successo, il worker dopo pop; busy all’avvio conserva il riferimento. Mapping stabile e cursore appartengono al chiamante. Nessun cleanup sul writer che possa cancellare una nuova ondata.

9. Tracciabilità e verifica integrata: requisiti presenti nella matrice, mantenuti progettati rispetto al motore completo. Build/test 4000520747-command-93257-0 :OK/:STABLE, exit 0, 237 test dei sette moduli oltre allo smoke, 51 execution; nessun warning/style-warning. Coverage/export e strict self-test C4 PASS. Verifica integrata finale make check IN ATTESA al momento del report; nessun suo successo viene anticipato.

10. Regole e mutazioni: nessun difetto funzionale o violazione statica identificata nella lettura dei sorgenti finali safety 3, con ftype, tipi slot, funzioni brevi e pre/post significativi. Due rilievi testuali iniziali chiusi. Mutazioni 4000520822-command-96904-0 :OK/:STABLE, baseline completa 51,12/12 rilevate,zero survived/compilation-failures/before-tests; letti tutti i 13 log, guasti dopo avvio di un test ready, nessuna diagnostica compilatore. Nessuna esclusione C1 approvata e nessuna qualifica del motore implicita.

11. Parallelismo: guard indipendenti serializzano soltanto brevi aggiornamenti della lista pronta per tratto; il lavoro del writer avviene fuori dalle guard scheduler. Nessuno stato condiviso fra Serie per singolo messaggio, contatore comune, thread per Serie/richiesta o attesa di un altro shard. Quattro thread riusati per sei ondate con 36 payload/checksum e due consumer per otto ondate attestano gli scenari; non provano starvation-freedom, adattività o scalability universale.

12. Durabilità: nessun cambiamento durevole, I/O o eliminazione introdotto. Il trasferimento dell’obbligo è locale e condizionato al protocollo del caller; parcheggio/risveglio/shutdown/fault e pool restano da integrare, senza garanzia di progresso per obbligo abbandonato.

Hash SHA-256 finali, concordi fra worktree e clone:
arcdocdb.asd 53a8a44f493e341b30da22abcb6e201f48c129142c44287af7fb67f323ba51a3
src/execution/package.lisp 97704f44544084b6823924a48724f4fc54fdbda60df1b0891c5066afaf183af8
src/execution/queue.lisp 244259780ecaf905d21a641417abf58a4368bdf3cc24a09fc0d34c4284684f90
src/execution/writer.lisp 8ba19e24501c2eb1ae1f42bdafccb97781472737073325d6b0db452edaa8a105
src/execution/handoff.lisp ee90c809ef51134efa21e08b819e5530304efaf9f9e26b63c7e4afbf6d48e607
src/execution/ready-types.lisp 0f1ae77ec5fb90ac747e63e82af8dfab19634c05f8876eddce2c1ee874e0dc4f
src/execution/ready.lisp a13238ba41ac63575d8ba2beebcfdb3ec4853d9d5ec138b848f2978715fe7327
tests/execution/ready.lisp 4ca29c076e8c7ad6b5f243419bedbfe6f754b5ddb6858a1568cec3e0474f476e
tools/writer-ready-bench.lisp 9dae2c5aa057e95e722213baa2227d7feeceec4ed6d3f0d249c4a8595200a7b4
tools/writer-ready-mutation.lisp e22f1e32f1c4dd98ebe84af818145c22fb8b4c386f3bf04bc235edc7a7257829

Inventario worktree SHA-256 81f8c9d4d2dd35b1aeba3e26f1e84d5310830c49e10e77a6071fca18125aad91.
Probe di sola lettura conservati: spikes/out/ready-review-probes.lisp SHA-256 ac85c2d445ea976e6b326d1aa492b6cb3752006433f84be05e10706aa8d4b952. Il preload ASDF/UIOP mancante, il percorso baseline errato e la selezione iniziale degli eventi sono corretti e conservati come probe dell’agente, senza attribuzione a prodotto o strumenti. Nessuna campagna aggiuntiva eseguita dal revisore.
"
 :SCHEMA-VERSION 1 :KIND :C1-REVIEW-IMPORT :ROLE :INDEPENDENT :SCOPE
 :WRITER-READY-HARDENED-INTEGRATION :STATUS
 :FINAL-LOCALLY-VERIFIED-NO-ENGINE-QUALIFICATION :BASE-COMMIT
 "33aa2244ca8e1920fcb0d72bbdf8651f9a3c0691" :ORIGINAL-REVIEW
 (:PATH "spikes/out/ready-independent-review.lisp" :SHA256
  "2d344b8a0447e6c6277ab4cef3a41c4780799bfc620a32cc5d69a35c68e04d79")
 :EVIDENCE-REFERENCES
 ("spikes/out/4000521809-command-41045-0/report.lisp"
  "spikes/out/4000521810-ready-signal-self-test-41080/report.lisp"
  "spikes/out/4000521888-command-44171-0/report.lisp"
  "spikes/out/4000521907-command-44843-0/report.lisp"
  "spikes/out/4000521968-check-46180-0/report.lisp"
  "spikes/out/4000521918-command-45102-0/report.lisp"
  "spikes/out/ready-mutations-final/report.lisp"
  "spikes/out/4000522063-command-47453-0/report.lisp"
  "spikes/out/4000522514-command-56618-0/report.lisp"
  "spikes/out/4000522582-check-59441-0/report.lisp"
  "spikes/out/4000522904-command-41347-0/report.lisp"
  "spikes/out/4000522979-check-41982-0/report.lisp")
 :HARDENED-TOOL-READING
 "Appendice indipendente alla revisione storica writer-ready, base integrata fd96fb3145f593f31552de26a8fd93478b69fc8f.

La lettura storica sui 12 punti e la sua base 92d8b0e rimangono immutate in ready-independent-review.lisp, SHA-256 2d344b8a0447e6c6277ab4cef3a41c4780799bfc620a32cc5d69a35c68e04d79. Questa appendice registra l’integrazione e la correzione del classificatore C4; non è una nuova revisione C1 del manifest.

La verifica indipendente in worktree e clone conferma identici package execution, queue, writer, handoff, ready-types, ready, test ready e bench. ASDF cambia a SHA-256 4fc264ec2638b5d3b778890405942fadb3857180ab7c3818d8377e6a2f50e458 e mantiene entrambe le registrazioni ready accanto al manifest. Il metodo aggiunge l’appendice di correzione, SHA-256 6f778d4eccdc5d8fccc0b63d8677956a13837991e9a915ab4ad79d1592b4952f.

Il runner ready corretto, SHA-256 06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb, attribuisce qualsiasi segnale OS a worker-error prima degli altri esiti; exit nonzero dopo completion autentica è worker-error. I marker citati o prefissati nel backtrace non sono eventi autentici. Exit/signal passano da wait-process a baseline e mutanti; il report conserva baseline-signal, signal per risultato e worker-errors separati; il gate finale richiede tutti i dodici detected. I mutanti semantici non cambiano.

Strict finale 4000521809-command-41045-0 letto tramite evidence:read-evidence: :OK/:STABLE, exit 0, stderr vuoto; COMPILE-FILE completo con warning/failure fatali, preload contrib e argv espliciti, poi self-test del FASL. Il self-test copre completion fallita, marker citati, suite incompleta, exit assente, compilation failure, sostituzioni invalide, dati parziali/destinazione esistente e SIGKILL reale.

Letti report, runner e log originali 4000521810-ready-signal-self-test-41080: il child emette execution-test-start SIGNAL-FIXTURE, flush, poi si termina con SIGKILL. Il rapporto :PASSED/:STABLE registra exit 137, signal 9, result :worker-error, detected 0, worker-errors 1. La baseline pending appartiene soltanto alla fixture di segnale, senza campagna implicita.

Prima conservazione della revisione 4000521888-command-44171-0: :OK/:STABLE, exit 0, stderr vuoto. Nessun rilievo funzionale aggiuntivo nella lettura del tool/adapter. La campagna finale sulla base integrata e il make check sono ancora IN ATTESA; questa appendice non ne anticipa il risultato e non promuove la copertura raw incompleta a qualifica.
"
 :CLOSURE-APPENDIX
 "Appendice di chiusura dell’integrazione locale fd96fb3145f593f31552de26a8fd93478b69fc8f. I report e le letture precedenti rimangono verbatim. Questa chiusura non anticipa il nuovo check sulla successiva base 201562dffd8c48e5d2047f73ef905f64b447e663.

1. REQ-CON-001/002/004/005 e REQ-AFF-008, ADR-0005 e ADR-0045 §§6/8 restano coerenti; registrazioni ready conservate accanto al manifest. L’integrazione manifest viene verificata dal check, senza una nuova C1 del suo sorgente da questo revisore.
2. I 17 test ready rimangono byte-identici, con obblighi pubblici legali, FI privata separata, retry conservativo e prove concorrenti con thread riusati.
3. Errori e cleanup del prodotto invariati. Il finding C4 sulla classificazione è chiuso: segnale OS e completion seguita da exit nonzero sono worker-error; exit/signal sono conservati, senza contarli come rilevamento.
4. Factory e scansione rimangono bounded: K<=64, fino a K acquisizioni e K rilasci CAS, nessuno spin/attesa. Capacity per shard <=65536.
5. Le prove mirate iniziali su 92d8b0e restano attribuite a quella base: dieci campioni composti con heap zero, sink verificati e controllo positivo. Prodotto/test/bench sono invariati; nessuna nuova misura universale o di scaling viene inferita.
6. Controlli di input, forma e riferimento in uscita invariati; unicità e conservazione dell’obbligo restano precondizioni del chiamante, senza deduplicazione.
7. Inventario scalari/default/CASE/guard/cleanup invariato; complessità massima 7/10. Native/HTML iniziali concordano 848/974 espressioni e126/146 esiti nei sei file. Due esiti CAS nuovi e le lacune legacy restano mappati, senza esclusioni o MC/DC dedotta.
8. OWNER/SHARED e guard indipendenti invariati; nessun cleanup sul writer dopo il termine che possa cancellare una nuova ondata.
9. make check, registrato dal Makefile come comando check-core, 4000521907-command-44843-0: :OK/:STABLE, exit0, wall96.821713s. 257 test dei sette moduli (26+17+51+44+18+82+19) oltre allo smoke; lint48 file/0violazioni; trace114REQ/65INV/13FI/52ADR/0errori; links187file/1880link/0rotti. Stderr conserva note compiler e progresso spike, senza warning/style-warning reali; i fallimenti sintetici dei self-test sono dati attesi.
10. Due finding testuali della prima lettura chiusi, nessun finding funzionale aperto. Strict tool finale 4000521809 PASS/STABLE; SIGKILL reale exit137/signal9 produce worker-error, detected0/worker-errors1. Campagna hardened 4000521918 :OK/:STABLE, 12/12 detected, baseline exit0/signalNIL, tutti mutanti exit1/signalNIL, zero survived/compilation-failures/before-tests/worker-errors. Data SHA-256 c1db98e2b8538444381254f0fc79cf3ebc1fdfa4ffc2445f101d6ccb49ac6d87. Letti indipendentemente tutti i 13 log: baseline 51 completati, mutanti falliti dopo avvio di un test ready e prima di completion, nessuna compilation failure. Probe conservato 4000522063 PASS/STABLE.
11. Master4000521968-check-46180-0 letto via evidence:read-evidence: :COMPLETE, mode --check,10run/10artifact. SPK-01..10 tutti exit0/:STABLE; nove :OK e SPK-07 :PASS, inclusi statuti dei risultati interni normalizzati. Metadata raw: SBCL2.6.9, Darwin27.0.0 ARM64 AppleM4, RAM17179869184byte,10CPUlogiche, dynamic-space4096MiB, carico esterno :UNCONTROLLED, load-average {5.50 4.85 4.22}, commitfd96fb3, date-universal-time4000521973. Non si promuovono questi spike a qualifica del pool, latenza o scalabilità del componente.
12. Nessun cambiamento durevole o eliminazione introdotto nel componente. Pool, wakeup/parcheggio, shutdown e controller FAULTED restano da integrare.

Hash invariati del prodotto/test/bench sono quelli della lettura storica. Delta fd96 confermati: ASDF4fc264ec2638b5d3b778890405942fadb3857180ab7c3818d8377e6a2f50e458; runner06c326c4211e4a691d817a031db35795c68291fa639e0304fa542aad689b58bb; metodo6f778d4eccdc5d8fccc0b63d8677956a13837991e9a915ab4ad79d1592b4952f. Nessuna campagna eseguita dal revisore.
"
 :LIMITS
 (:ORIGINAL-REPORT-NOT-REWRITTEN
  :HISTORICAL-PENDING-STATEMENTS-RETAINED-AS-HISTORY :COVERAGE-GAPS-RETAINED
  :NO-MCDC-EXCLUSIONS-APPROVED :NO-MANIFEST-CBOR-OR-CSN-SOURCE-C1-REVIEW
  :NO-POOL-OR-PERFORMANCE-QUALIFICATION :NO-ENGINE-QUALIFICATION
  :NO-CAMPAIGN-EXECUTED-BY-REVIEWER))
