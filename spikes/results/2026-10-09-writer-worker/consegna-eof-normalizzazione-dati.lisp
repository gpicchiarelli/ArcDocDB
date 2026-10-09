(:SCHEMA-VERSION 1 :KIND :QUALIFIED-SOURCE-FORMATTING-PROOF :STATUS :PASSED :QUALIFIED-RECORD
 "4000550386-command-90070-0" :QUALIFIED-SOURCE
 (:PATH
  #A((121) BASE-CHAR
     . "/var/folders/07/57bk4fl91n9_9gk_j124c_q80000gn/T/arcdocdb-worker-final-integration-xtoppcbn/src/execution/worker-run.lisp")
  :BYTES 5125 :SHA256 "60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847" :GIT-BLOB
  "b1137f303cb707f8bf322f9deea764f716424d77" :TEXT
  ";;;; Contesto preallocato di un worker: nessuna migrazione o reentrancy.
;;; OWNER: campi locali al thread creatore; obbligo e lease mai abbandonati su busy.
;;; SHARED: soltanto lista pronta per tratto (ADR-0045 §8); nessuna scrittura globale.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t t t) (values index (member :messages :empty :yield) index &optional)) preleva-lavori-worker))
(defun preleva-lavori-worker (context target start end)
  \"Pre: RUNNING senza batch; target privato, span valido. Post: BATCH con token
locale nuovo se messaggi, RUNNING/token0 se empty/yield. Busy/target invalido non
estraggono; RESOURCE-EXHAUSTED generation prima del pop, anche empty/yield.
Token non globale: ack usa la coppia contesto/token; condizioni writer delegate.\"
  (%passo-worker (context (:worker-state :worker-generation :writer-queue-busy) (:writer-target))
  (%richiedi-worker context :running)
  (%check-target (writer-programmabile-queue (contesto-worker-writer-writer context))
                 target start end)
  (when (= (contesto-worker-writer-batch-generation context) most-positive-fixnum)
    (error 'resource-exhausted :reason :worker-generation))
  (multiple-value-bind (count status)
      (preleva-lavori-writer (contesto-worker-writer-writer context)
                             (contesto-worker-writer-lease context) target start end)
    (case status
      (:messages
       (unless (plusp count) (error 'invariant-violation :reason :worker-state))
       (incf (contesto-worker-writer-batch-generation context))
       (setf (contesto-worker-writer-pending context) count
             (contesto-worker-writer-state context) :batch))
      ((:empty :yield)
       (unless (zerop count) (error 'invariant-violation :reason :worker-state)))
      (otherwise (error 'invariant-violation :reason :worker-state)))
    (%check-worker context)
    (values count status (if (plusp count) (contesto-worker-writer-batch-generation context) 0)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t) null) conferma-lavori-worker))
(defun conferma-lavori-worker (context token)
  \"Pre: BATCH elaborato completamente dal caller, token corrente locale.
Post: RUNNING senza debito; INVALID-ARGUMENT token errato/stale prima delle
scritture, fase/owner/verificatori typed. Attesta il caller, non effetti esterni.\"
  (%passo-worker (context (:worker-state) (:worker-batch))
  (%richiedi-worker context :batch)
  (unless (typep token 'index) (error 'invalid-argument :reason :worker-batch))
  (unless (plusp token) (error 'invalid-argument :reason :worker-batch))
  (unless (= token (contesto-worker-writer-batch-generation context))
    (error 'invalid-argument :reason :worker-batch))
  (setf (contesto-worker-writer-pending context) 0
        (contesto-worker-writer-state context) :running)
  (%check-worker context)
  nil))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer (member :idle :schedule)) null) %concludi-worker))
(defun %concludi-worker (context action)
  \"Pre: handoff terminato, contesto FINISHING senza debito. Post: IDLE libero
o RESCHEDULE con obbligo; INVARIANT-VIOLATION fase/debito/esito incoerenti.\"
  (%check-owner-worker context)
  (unless (eq (contesto-worker-writer-state context) :finishing)
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  (setf (contesto-worker-writer-lease context) 0)
  (case action
    (:idle (setf (contesto-worker-writer-writer context) nil
                 (contesto-worker-writer-state context) :idle))
    (:schedule (setf (contesto-worker-writer-state context) :reschedule))
    (otherwise (error 'invariant-violation :reason :worker-state)))
  (%check-worker context)
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (member :idle :schedule)) termina-tratto-worker))
(defun termina-tratto-worker (context)
  \"Pre: RUNNING dopo ack oppure FINISHING da ritentare. Post: IDLE/RESCHEDULE.
Prima della chiamata fissa FINISHING: busy conserva lease/riferimento e impedisce
nuovi pop/ack. Solo retry del termine; condizioni handoff/verificatori typed.
Nessun cleanup sul writer dopo end, nessun cambiamento durevole o callback.\"
  (%passo-worker (context (:worker-state :writer-queue-busy) ())
  (%check-worker context)
  (case (contesto-worker-writer-state context)
    ((:running :finishing) nil)
    (otherwise (error 'resource-exhausted :reason :worker-state)))
  (setf (contesto-worker-writer-state context) :finishing)
  (%check-worker context)
  (let ((action (termina-tratto-writer (contesto-worker-writer-writer context)
                                      (contesto-worker-writer-lease context))))
    (%concludi-worker context action)
    action)))

")
 :FINAL-SOURCE
 (:PATH #A((29) BASE-CHAR . "src/execution/worker-run.lisp") :BYTES 5124 :SHA256
  "fc106a26204144a5d3f66113f9cac3443234b7086885752c565e6649e6c1e542" :GIT-BLOB
  "65a3f3c9e84c83b900c1dd8c9cc2fc21cec36c52" :TEXT
  ";;;; Contesto preallocato di un worker: nessuna migrazione o reentrancy.
;;; OWNER: campi locali al thread creatore; obbligo e lease mai abbandonati su busy.
;;; SHARED: soltanto lista pronta per tratto (ADR-0045 §8); nessuna scrittura globale.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t t t) (values index (member :messages :empty :yield) index &optional)) preleva-lavori-worker))
(defun preleva-lavori-worker (context target start end)
  \"Pre: RUNNING senza batch; target privato, span valido. Post: BATCH con token
locale nuovo se messaggi, RUNNING/token0 se empty/yield. Busy/target invalido non
estraggono; RESOURCE-EXHAUSTED generation prima del pop, anche empty/yield.
Token non globale: ack usa la coppia contesto/token; condizioni writer delegate.\"
  (%passo-worker (context (:worker-state :worker-generation :writer-queue-busy) (:writer-target))
  (%richiedi-worker context :running)
  (%check-target (writer-programmabile-queue (contesto-worker-writer-writer context))
                 target start end)
  (when (= (contesto-worker-writer-batch-generation context) most-positive-fixnum)
    (error 'resource-exhausted :reason :worker-generation))
  (multiple-value-bind (count status)
      (preleva-lavori-writer (contesto-worker-writer-writer context)
                             (contesto-worker-writer-lease context) target start end)
    (case status
      (:messages
       (unless (plusp count) (error 'invariant-violation :reason :worker-state))
       (incf (contesto-worker-writer-batch-generation context))
       (setf (contesto-worker-writer-pending context) count
             (contesto-worker-writer-state context) :batch))
      ((:empty :yield)
       (unless (zerop count) (error 'invariant-violation :reason :worker-state)))
      (otherwise (error 'invariant-violation :reason :worker-state)))
    (%check-worker context)
    (values count status (if (plusp count) (contesto-worker-writer-batch-generation context) 0)))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t) null) conferma-lavori-worker))
(defun conferma-lavori-worker (context token)
  \"Pre: BATCH elaborato completamente dal caller, token corrente locale.
Post: RUNNING senza debito; INVALID-ARGUMENT token errato/stale prima delle
scritture, fase/owner/verificatori typed. Attesta il caller, non effetti esterni.\"
  (%passo-worker (context (:worker-state) (:worker-batch))
  (%richiedi-worker context :batch)
  (unless (typep token 'index) (error 'invalid-argument :reason :worker-batch))
  (unless (plusp token) (error 'invalid-argument :reason :worker-batch))
  (unless (= token (contesto-worker-writer-batch-generation context))
    (error 'invalid-argument :reason :worker-batch))
  (setf (contesto-worker-writer-pending context) 0
        (contesto-worker-writer-state context) :running)
  (%check-worker context)
  nil))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer (member :idle :schedule)) null) %concludi-worker))
(defun %concludi-worker (context action)
  \"Pre: handoff terminato, contesto FINISHING senza debito. Post: IDLE libero
o RESCHEDULE con obbligo; INVARIANT-VIOLATION fase/debito/esito incoerenti.\"
  (%check-owner-worker context)
  (unless (eq (contesto-worker-writer-state context) :finishing)
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  (setf (contesto-worker-writer-lease context) 0)
  (case action
    (:idle (setf (contesto-worker-writer-writer context) nil
                 (contesto-worker-writer-state context) :idle))
    (:schedule (setf (contesto-worker-writer-state context) :reschedule))
    (otherwise (error 'invariant-violation :reason :worker-state)))
  (%check-worker context)
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (member :idle :schedule)) termina-tratto-worker))
(defun termina-tratto-worker (context)
  \"Pre: RUNNING dopo ack oppure FINISHING da ritentare. Post: IDLE/RESCHEDULE.
Prima della chiamata fissa FINISHING: busy conserva lease/riferimento e impedisce
nuovi pop/ack. Solo retry del termine; condizioni handoff/verificatori typed.
Nessun cleanup sul writer dopo end, nessun cambiamento durevole o callback.\"
  (%passo-worker (context (:worker-state :writer-queue-busy) ())
  (%check-worker context)
  (case (contesto-worker-writer-state context)
    ((:running :finishing) nil)
    (otherwise (error 'resource-exhausted :reason :worker-state)))
  (setf (contesto-worker-writer-state context) :finishing)
  (%check-worker context)
  (let ((action (termina-tratto-writer (contesto-worker-writer-writer context)
                                      (contesto-worker-writer-lease context))))
    (%concludi-worker context action)
    action)))
")
 :TRANSFORMATION :REMOVE-ONE-TERMINAL-LINE-FEED :ALL-OTHER-BYTES-IDENTICAL T :LIMITS
 (:NO-LISP-FORM-OR-LINE-LOCATION-CHANGE :NO-TEST-RERUN-FOR-EOF-WHITESPACE
  :ORIGINAL-QUALIFIED-SOURCE-AND-RECORD-PRESERVED))
