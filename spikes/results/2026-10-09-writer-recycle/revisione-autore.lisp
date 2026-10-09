(:SCHEMA-VERSION 1 :KIND :C1-AUTHOR-REVIEW :SCOPE :WRITER-RECYCLE :SOURCE
 "src/execution/ready-recycle.lisp" :SOURCE-GIT-BLOB
 "58981c7e41ce2694dbfcaed99010a3a53e3c1dea" :SOURCE-TEXT
 ";;;; Ricircolo bounded: pubblica e prende una testa nello stesso ring pieno.
;;; OWNER: il ring possiede A dopo successo; il chiamante possiede la testa restituita.
;;; SHARED: lista Serie pronte (ADR-0045 §8), una operazione per tratto, mai per messaggio.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta writer-programmabile)
                         (values writer-programmabile (member :writer) index &optional))
                %scambia-pronto))
(defun %scambia-pronto (partition writer)
  \"Pre: guard corrente, ring pieno, obbligo unico. Post: testa al caller e WRITER
in coda, count invariato. INVARIANT-VIOLATION per forma, capienza o testa invalida.\"
  (%check-pronta partition)
  (unless (= (partizione-pronta-count partition) (partizione-pronta-capacity partition))
    (error 'invariant-violation :reason :ready-recycle-full))
  (let* ((head (partizione-pronta-head partition))
         (old (svref (partizione-pronta-slots partition) head))
         (next (mod (1+ head) (partizione-pronta-capacity partition))))
    (unless (typep old 'writer-programmabile)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (setf (svref (partizione-pronta-slots partition) head) writer
          (partizione-pronta-head partition) next
          (partizione-pronta-tail partition) next)
    (%check-pronta partition)
    (values old :writer (partizione-pronta-count partition))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta writer-programmabile)
                         (values (or null writer-programmabile)
                                 (member :published :writer) index &optional))
                %ricircola-pronto))
(defun %ricircola-pronto (partition writer)
  \"Pre: guard corrente e obbligo unico. Post: pubblicato, o testa e slot scambiati.
INVARIANT-VIOLATION per ring o payload incoerenti; nessun rifiuto per ring pieno.\"
  (%check-pronta partition)
  (if (= (partizione-pronta-count partition) (partizione-pronta-capacity partition))
      (%scambia-pronto partition writer)
      (values nil :published (%pubblica-pronto partition writer))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t t)
                         (values (or null writer-programmabile)
                                 (member :published :writer) index &optional))
                ricircola-writer-pronto))
(defun ricircola-writer-pronto (ready shard writer)
  \"Pre: obbligo :SCHEDULE unico e caller capace di prendere un altro writer.
Post: NIL/:PUBLISHED/count se spazio; testa/:WRITER/capacity se pieno: nuovo
obbligo al ring, testa al caller. INVALID-ARGUMENT shard/writer; RESOURCE-EXHAUSTED
busy conserva obbligo. Invarianti fail-stop; nessun retry, attesa o deduplicazione.\"
  (let ((partition (%partizione-verificata ready shard)))
    (unless (typep writer 'writer-programmabile)
      (error 'invalid-argument :reason :ready-writer))
    (let ((thread (%prendi-guard-pronta partition)))
      (unless thread (error 'resource-exhausted :reason :ready-queue-busy))
      (unwind-protect (%ricircola-pronto partition writer)
        (%rilascia-guard-pronta partition thread)))))
"
 :CHECKLIST
 ("| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0005 e ADR-0045 §§6/8. Ricircolo della lista condivisa per tratto, senza coda comune per messaggio. |"
  "| 2. Invarianti | Obbligo unico, FIFO locale, count e capacità invariati in full, guard esclusiva, lease singola. Oracolo 8.000 passi, regressione della saturazione e thread reali; undici mutanti rilevati. |"
  "| 3. Errori | Input e busy prima della mutazione; invarianti typed/fail-stop, senza rollback dopo guasto interno. Busy conserva l'obbligo, anche nell'avvio del riferimento restituito; controller FAULTED ancora da integrare. |"
  "| 4. Limiti | Nessun ciclo, retry, ricorsione o attesa nel nuovo sorgente. Una acquisizione CAS più rilascio, O(1); ring e shard mantengono i limiti esistenti. Harness/thread con timeout e numero di tentativi finito. |"
  "| 5. Allocazioni | Nessuna allocazione esplicita nel normale ricircolo; composizione preallocata con heap osservato zero in 20 campioni locali. Controllo positivo riuscito; startup/errori fuori misura, nessuna promessa universale. |"
  "| 6. Dati | Tipo del nuovo riferimento e vecchia testa verificati; indici/forma sotto guard. Il ring trasporta riferimenti opachi senza interpretare payload o dati persistenti. |"
  "| 7. Decisioni | Cinque predicati scalari; nessuna nuova decisione composta. Copertura 81/86 espressioni, 8/8 esiti; top-level e lacune legacy restano nel denominatore 929/1060 e 134/154. Nessuna esclusione o MC/DC dedotta. |"
  "| 8. Proprietà | Guard/ring locali; successo trasferisce A→ring e C→caller insieme. Caller capace di assumere C, obbligo unico come precondizione, nessuna membership o dedup nuova. |"
  "| 9. Check | 309 test più smoke, lint53/zero violazioni, trace/link/evidenze e dieci spike. Processo4000528494-command-77199-0 OK/STABLE/exit0; chiusure editoriali controllate separatamente. |"
  "| 10. Standard | Safety3, ftype completi, docstring, massimo20 righe per funzione e complessità locale≤3. Pre/post attraverso %check-pronta e helper delegati; unwind-protect solo rilascio. Due C4 compilati integralmente con avvisi fatali e self-test FASL. |"
  "| 11. Parallelismo | Nessun nuovo lock globale o scrittura comune per messaggio. La guard serializza solo la breve operazione del proprio ring, una volta per tratto. Progresso dell'altro shard verificato; nessuna fairness o lock-freedom promessa. |"
  "| 12. Atomicità | Nessun cambiamento durevole, I/O o eliminazione. Full sostituisce lo slot head=tail e avanza gli indici sotto guard; count invariato. Nessun cleanup può cancellare un'ondata successiva del writer. |")
 :REVIEW-TEXT "# Revisione del ricircolo dei writer pronti

Ambito C1: nuovo `ready-recycle.lisp`, export/ASDF e composizione con handoff
ed elenco pronto. Le due letture indipendenti, iniziale e conclusiva, sono
conservate nell'[inventario](writer-recycle-decisioni.md) e nel
[catalogo](../../spikes/results/2026-10-09-writer-recycle/catalogo.lisp).

## Lettura dell'autore

| Punto C1 | Esito e ambito |
|---|---|
| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0005 e ADR-0045 §§6/8. Ricircolo della lista condivisa per tratto, senza coda comune per messaggio. |
| 2. Invarianti | Obbligo unico, FIFO locale, count e capacità invariati in full, guard esclusiva, lease singola. Oracolo 8.000 passi, regressione della saturazione e thread reali; undici mutanti rilevati. |
| 3. Errori | Input e busy prima della mutazione; invarianti typed/fail-stop, senza rollback dopo guasto interno. Busy conserva l'obbligo, anche nell'avvio del riferimento restituito; controller FAULTED ancora da integrare. |
| 4. Limiti | Nessun ciclo, retry, ricorsione o attesa nel nuovo sorgente. Una acquisizione CAS più rilascio, O(1); ring e shard mantengono i limiti esistenti. Harness/thread con timeout e numero di tentativi finito. |
| 5. Allocazioni | Nessuna allocazione esplicita nel normale ricircolo; composizione preallocata con heap osservato zero in 20 campioni locali. Controllo positivo riuscito; startup/errori fuori misura, nessuna promessa universale. |
| 6. Dati | Tipo del nuovo riferimento e vecchia testa verificati; indici/forma sotto guard. Il ring trasporta riferimenti opachi senza interpretare payload o dati persistenti. |
| 7. Decisioni | Cinque predicati scalari; nessuna nuova decisione composta. Copertura 81/86 espressioni, 8/8 esiti; top-level e lacune legacy restano nel denominatore 929/1060 e 134/154. Nessuna esclusione o MC/DC dedotta. |
| 8. Proprietà | Guard/ring locali; successo trasferisce A→ring e C→caller insieme. Caller capace di assumere C, obbligo unico come precondizione, nessuna membership o dedup nuova. |
| 9. Check | 309 test più smoke, lint53/zero violazioni, trace/link/evidenze e dieci spike. Processo4000528494-command-77199-0 OK/STABLE/exit0; chiusure editoriali controllate separatamente. |
| 10. Standard | Safety3, ftype completi, docstring, massimo20 righe per funzione e complessità locale≤3. Pre/post attraverso %check-pronta e helper delegati; unwind-protect solo rilascio. Due C4 compilati integralmente con avvisi fatali e self-test FASL. |
| 11. Parallelismo | Nessun nuovo lock globale o scrittura comune per messaggio. La guard serializza solo la breve operazione del proprio ring, una volta per tratto. Progresso dell'altro shard verificato; nessuna fairness o lock-freedom promessa. |
| 12. Atomicità | Nessun cambiamento durevole, I/O o eliminazione. Full sostituisce lo slot head=tail e avanza gli indici sotto guard; count invariato. Nessun cleanup può cancellare un'ondata successiva del writer. |

Il helper `%ricircola-pronto` verifica la precondizione e delega la
postcondizione ai due rami `%scambia-pronto` e `%pubblica-pronto`, entrambi
con controlli significativi prima e dopo la mutazione. La proprietà della
guard è verificata all'acquisizione e al rilascio della API pubblica.

La prima lettura indipendente non ha trovato difetti funzionali; il solo
commento `publica` è corretto in `pubblica` prima delle campagne. La seconda
lettura considera sorgenti congelati e raw di build, copertura, mutazioni e
allocazioni. Nessuna esclusione approvata o chiusura dei gate del motore.

La capacità piena non impedisce lo scambio nel protocollo modellato. Questo
non prova liveness con guard perpetuamente occupate, obblighi invalidi o
controller assente. Catene full sullo stesso shard possono affamare altre
attività. Pool, quote globali, risvegli, parcheggio, admission e shutdown
richiedono integrazione; empty resta un'osservazione locale.
"
 :VERIFICATION-RECORD "4000528494-command-77199-0" :TESTS 309 :EXECUTION-TESTS
 66 :MUTATION-RECORD "4000528603-command-78553-0" :DETECTED 11
 :ALLOCATION-RECORD "4000528603-command-78552-0" :SAMPLES 20 :LIMITS
 (:LOCAL-COMPONENT :NO-MCDC :NO-APPROVED-EXCLUSIONS
  :NO-FULL-ENGINE-QUALIFICATION))
