(:SCHEMA-VERSION 1 :KIND :C1-AUTHOR-REVIEW :COMPONENT :WRITER-WORKER :SOURCES
 ((:PATH "src/execution/worker-types.lisp" :SHA256
   "62412828a90415bfef28c42f3e839c436c53652f86ffbf9a970d52682c769317" :GIT-BLOB
   "6d36e1f64d79f24c95209fd70551953e40c62335" :TEXT
   ";;;; Contesto preallocato di un worker: nessuna migrazione o reentrancy.
;;; OWNER: campi locali al thread creatore; obbligo e lease mai abbandonati su busy.
;;; SHARED: soltanto lista pronta per tratto (ADR-0045 §8); nessuna scrittura globale.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (contesto-worker-writer
             (:constructor %make-contesto-worker-writer (ready owner cursor)) (:copier nil))
  \"Pre: lista valida e proprietario unico non rientrante. Post: IDLE senza obblighi.
Nessun thread creato; batch generation locale monotona e mai azzerata.\"
  (ready (error 'invariant-violation :reason :worker-state) :type lista-writer-pronti :read-only t)
  (owner (error 'invariant-violation :reason :worker-state) :type sb-thread:thread :read-only t)
  (cursor 0 :type index) (home 0 :type index)
  (writer nil :type (or null writer-programmabile))
  (lease 0 :type index) (pending 0 :type index) (batch-generation 0 :type index)
  (fault nil :type (or null condition))
  (state :idle :type (member :idle :claimed :running :batch :finishing :reschedule :faulted)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-owner-worker))
(defun %check-owner-worker (context)
  \"Pre: contesto locale. Post: thread corrente proprietario; INVALID-ARGUMENT altrimenti.\"
  (unless (eq (contesto-worker-writer-owner context) sb-thread:*current-thread*)
    (error 'invalid-argument :reason :worker-owner))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-libero-worker))
(defun %check-libero-worker (context)
  \"Pre: owner verificato, IDLE. Post: riferimento, lease e debito vuoti; invarianti typed.\"
  (unless (null (contesto-worker-writer-writer context))
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-lease context))
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-obbligo-worker))
(defun %check-obbligo-worker (context)
  \"Pre: owner verificato, CLAIMED/RESCHEDULE. Post: writer senza lease/debito; invarianti typed.\"
  (unless (typep (contesto-worker-writer-writer context) 'writer-programmabile)
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-lease context))
    (error 'invariant-violation :reason :worker-state))
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-lease-worker))
(defun %check-lease-worker (context)
  \"Pre: owner verificato. Post: writer e lease correnti; invarianti o lease invalida typed.\"
  (let ((writer (contesto-worker-writer-writer context)))
    (unless (typep writer 'writer-programmabile)
      (error 'invariant-violation :reason :worker-state))
    (%check-lease (writer-programmabile-queue writer) (contesto-worker-writer-lease context)))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-attivo-worker))
(defun %check-attivo-worker (context)
  \"Pre: owner verificato, RUNNING/FINISHING. Post: lease corrente senza batch; invarianti typed.\"
  (%check-lease-worker context)
  (unless (zerop (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-batch-worker))
(defun %check-batch-worker (context)
  \"Pre: owner verificato, BATCH. Post: lease corrente e batch positivo; invarianti typed.\"
  (%check-lease-worker context)
  (unless (plusp (contesto-worker-writer-pending context))
    (error 'invariant-violation :reason :worker-state))
  (unless (<= (contesto-worker-writer-pending context)
              (coda-writer-extracted
               (writer-programmabile-queue (contesto-worker-writer-writer context))))
    (error 'invariant-violation :reason :worker-state))
  (unless (plusp (contesto-worker-writer-batch-generation context))
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) null) %check-worker))
(defun %check-worker (context)
  \"Pre: accesso esclusivo non rientrante. Post: owner, indici e stato coerenti.
INVALID-ARGUMENT owner; indici privati sono invarianti, lease come verificatori delegati.\"
  (%check-owner-worker context)
  (unless (null (contesto-worker-writer-fault context))
    (error 'invariant-violation :reason :worker-state))
  (let ((size (length (lista-writer-pronti-partitions (contesto-worker-writer-ready context)))))
    (unless (< (contesto-worker-writer-cursor context) size)
      (error 'invariant-violation :reason :worker-state))
    (unless (< (contesto-worker-writer-home context) size)
      (error 'invariant-violation :reason :worker-state)))
  (%partizione-verificata (contesto-worker-writer-ready context) (contesto-worker-writer-cursor context))
  (%partizione-verificata (contesto-worker-writer-ready context) (contesto-worker-writer-home context))
  (case (contesto-worker-writer-state context)
    (:idle (%check-libero-worker context))
    ((:claimed :reschedule) (%check-obbligo-worker context))
    ((:running :finishing) (%check-attivo-worker context))
    (:batch (%check-batch-worker context))
    (otherwise (error 'invariant-violation :reason :worker-state)))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer symbol) null) %richiedi-worker))
(defun %richiedi-worker (context state)
  \"Pre: owner esclusivo e fase richiesta. Post: forma e fase verificate.
RESOURCE-EXHAUSTED :WORKER-STATE per operazione fuori fase; verificatori typed.\"
  (%check-worker context)
  (unless (eq (contesto-worker-writer-state context) state)
    (error 'resource-exhausted :reason :worker-state))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti &key (:start t)) contesto-worker-writer) crea-contesto-worker-writer))
(defun crea-contesto-worker-writer (ready &key (start 0))
  \"Pre: lista valida; creazione sul thread proprietario prima del percorso caldo.
Post: IDLE preallocato con cursore START; INVALID-ARGUMENT indice, invarianti lista.\"
  (%partizione-verificata ready start)
  (let ((context (%make-contesto-worker-writer ready sb-thread:*current-thread* (the index start))))
    (%check-worker context)
    context))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (member :idle :claimed :running :batch :finishing :reschedule :faulted)) stato-worker-writer))
(defun stato-worker-writer (context)
  \"Pre: owner corrente. Post: fase locale, leggibile anche per diagnosi di fault.
INVALID-ARGUMENT owner; nessuna mutazione o verifica del writer sotto guard.\"
  (%check-owner-worker context)
  (contesto-worker-writer-state context))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (or null writer-programmabile)) writer-worker-writer))
(defun writer-worker-writer (context)
  \"Pre: owner corrente. Post: riferimento locale opaco per diagnosi/integrazione.
INVALID-ARGUMENT owner; non trasferisce obblighi né consente di duplicarli.\"
  (%check-owner-worker context)
  (contesto-worker-writer-writer context))


;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (or null condition)) errore-worker-writer))
(defun errore-worker-writer (context)
  \"Pre: owner corrente. Post: condizione originale del fault locale o NIL.
INVALID-ARGUMENT owner; non resetta il fault né trasferisce lease/obblighi.\"
  (%check-owner-worker context)
  (contesto-worker-writer-fault context))
")
  (:PATH "src/execution/worker-boundary.lisp" :SHA256
   "4a01d44c33c4019f8d6e98e26d37d2b36c96f63370951859f8c3adfb5eddb39a" :GIT-BLOB
   "720f16e96203f00e308727b430b66b28689dc7bb" :TEXT
   ";;;; Confine del worker: fault locale persistente, campi diagnostici conservati.
;;; OWNER: solo thread creatore; il controller della Serie resta da integrare.
;;; SHARED: nessuno stato globale o tra worker; handler solo in questo confine.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer list list error) null) %classifica-guasto-worker))
(defun %classifica-guasto-worker (context resources arguments condition)
  \"Pre: owner verificato e errore nel passo. Post: recuperabile propagato oppure
FAULTED con condizione e campi conservati; non nasconde né risolleva l'errore.
Liste di ragioni letterali bounded; solo resource/invalid attesi sono recuperabili.\"
  (when (typep condition 'resource-exhausted)
    (when (member (arcdocdb.conditions:error-reason condition) resources)
      (return-from %classifica-guasto-worker nil)))
  (when (typep condition 'invalid-argument)
    (when (member (arcdocdb.conditions:error-reason condition) arguments)
      (return-from %classifica-guasto-worker nil)))
  (setf (contesto-worker-writer-fault context) condition
        (contesto-worker-writer-state context) :faulted)
  (unless (eq (contesto-worker-writer-fault context) condition)
    (error 'invariant-violation :reason :worker-state))
  (unless (eq (contesto-worker-writer-state context) :faulted)
    (error 'invariant-violation :reason :worker-state))
  nil)

;;; REQ: REQ-CON-004 REQ-AFF-008
(defmacro %passo-worker ((context resources arguments) &body body)
  \"Pre: contesto owner-only non rientrante, ragioni letterali bounded. Post:
valori del corpo oppure errore propagato e fault locale registrato se inatteso.
Owner e FAULTED rifiutati prima del handler; nessun callback applicativo o retry.\"
  (let ((value (gensym \"WORKER\")) (handler (gensym \"WORKER-ERROR\")))
    `(let ((,value ,context))
       (%check-owner-worker ,value)
       (when (eq (contesto-worker-writer-state ,value) :faulted)
         (error 'resource-exhausted :reason :worker-state))
       (flet ((,handler (condition)
                (%classifica-guasto-worker ,value ',resources ',arguments condition)))
         (declare (dynamic-extent #',handler))
         (handler-bind ((error #',handler)) ,@body)))))
")
  (:PATH "src/execution/worker-claim.lisp" :SHA256
   "62804d27d1c5f734f16a0b498a7870afd8b9654c0140ce75bb98209f3834cb7e" :GIT-BLOB
   "4f34d18152d77fbf63bf708ebd0aabac178c3ac1" :TEXT
   ";;;; Contesto preallocato di un worker: nessuna migrazione o reentrancy.
;;; OWNER: campi locali al thread creatore; obbligo e lease mai abbandonati su busy.
;;; SHARED: soltanto lista pronta per tratto (ADR-0045 §8); nessuna scrittura globale.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t index) null) %assegna-worker))
(defun %assegna-worker (context writer home)
  \"Pre: IDLE/RESCHEDULE verificato, trasferimento riuscito dal ring. Post: CLAIMED.
INVARIANT-VIOLATION writer/fase incoerenti; nessun rollback dopo fault interno.\"
  (%check-worker context)
  (unless (typep writer 'writer-programmabile)
    (error 'invariant-violation :reason :worker-state))
  (case (contesto-worker-writer-state context)
    ((:idle :reschedule) nil)
    (otherwise (error 'invariant-violation :reason :worker-state)))
  (setf (contesto-worker-writer-writer context) writer
        (contesto-worker-writer-home context) home
        (contesto-worker-writer-state context) :claimed)
  (%check-worker context)
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (values (or null writer-programmabile) (member :claimed :empty :busy) index &optional)) prendi-writer-worker))
(defun prendi-writer-worker (context)
  \"Pre: IDLE e owner corrente. Post: CLAIMED con obbligo/home, oppure IDLE con
cursore ruotato per EMPTY/BUSY. Verificatori typed, fase errata RESOURCE-EXHAUSTED;
EMPTY resta locale, mai prova di quiescenza per parcheggio o arresto.\"
  (%passo-worker (context (:worker-state) ())
  (%richiedi-worker context :idle)
  (let ((ready (contesto-worker-writer-ready context)))
    (multiple-value-bind (writer status next)
        (preleva-writer-pronto ready (contesto-worker-writer-cursor context))
      (setf (contesto-worker-writer-cursor context) next)
      (case status
        (:writer
         (%assegna-worker context writer
           (mod (+ next (1- (length (lista-writer-pronti-partitions ready))))
                (length (lista-writer-pronti-partitions ready))))
         (values writer :claimed next))
        ((:empty :busy) (%check-worker context) (values nil status next))
        (otherwise (error 'invariant-violation :reason :worker-state)))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) index) inizia-tratto-worker))
(defun inizia-tratto-worker (context)
  \"Pre: CLAIMED senza lease. Post: RUNNING con lease del thread corrente.
Busy conserva CLAIMED; not-ready/generation restano fault permanenti del compito;
condizioni handoff e verificatori typed, nessun retry o perdita del riferimento.\"
  (%passo-worker (context (:worker-state :writer-queue-busy) ())
  (%richiedi-worker context :claimed)
  (let ((lease (inizia-tratto-writer (contesto-worker-writer-writer context))))
    (setf (contesto-worker-writer-lease context) lease
          (contesto-worker-writer-state context) :running)
    (%check-worker context)
    lease)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer) (values (or null writer-programmabile) (member :claimed :published) index &optional)) ricircola-worker))
(defun ricircola-worker (context)
  \"Pre: RESCHEDULE, obbligo unico, owner corrente. Post: full trasferisce nuova
testa al contesto CLAIMED; room pubblica e libera IDLE. Busy conserva obbligo.
Condizioni ready/verificatori typed; nessun retry o dedup, count full invariato.\"
  (%passo-worker (context (:worker-state :ready-queue-busy) ())
  (%richiedi-worker context :reschedule)
  (multiple-value-bind (writer status count)
      (ricircola-writer-pronto (contesto-worker-writer-ready context)
                              (contesto-worker-writer-home context)
                              (contesto-worker-writer-writer context))
    (case status
      (:writer (%assegna-worker context writer (contesto-worker-writer-home context))
               (values writer :claimed count))
      (:published
       (unless (null writer) (error 'invariant-violation :reason :worker-state))
       (setf (contesto-worker-writer-writer context) nil
             (contesto-worker-writer-state context) :idle)
       (%check-worker context)
       (values nil :published count))
      (otherwise (error 'invariant-violation :reason :worker-state))))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer t t) null) adotta-writer-worker))
(defun adotta-writer-worker (context writer home)
  \"Pre: IDLE, obbligo unico non nel ring affidato al caller e home stabile.
Post: CLAIMED sul contesto, obbligo trasferito dal caller; INVALID-ARGUMENT
writer/home prima delle scritture, fase/owner/verificatori typed. Nessun dedup.\"
  (%passo-worker (context (:worker-state) (:worker-writer :ready-target))
  (%richiedi-worker context :idle)
  (unless (typep writer 'writer-programmabile)
    (error 'invalid-argument :reason :worker-writer))
  (%partizione-verificata (contesto-worker-writer-ready context) home)
  (%assegna-worker context writer (the index home))
  nil))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer)
                         (values writer-programmabile index &optional)) cede-writer-worker))
(defun cede-writer-worker (context)
  \"Pre: CLAIMED/RESCHEDULE senza lease o batch. Post: IDLE, obbligo al caller
con home, generation conservata; mai cedere una lease attiva. Fase/owner e
verificatori typed; nessuna pubblicazione implicita, il caller non abbandona il ref.\"
  (%passo-worker (context (:worker-state) ())
  (%check-worker context)
  (case (contesto-worker-writer-state context)
    ((:claimed :reschedule) nil)
    (otherwise (error 'resource-exhausted :reason :worker-state)))
  (let ((writer (contesto-worker-writer-writer context))
        (home (contesto-worker-writer-home context)))
    (unless (typep writer 'writer-programmabile)
      (error 'invariant-violation :reason :worker-state))
    (setf (contesto-worker-writer-writer context) nil
          (contesto-worker-writer-state context) :idle)
    (%check-worker context)
    (values writer home))))
")
  (:PATH "src/execution/worker-run.lisp" :SHA256
   "60b71475e7f765cc305e034e07fa2a3b3683e9b8b60090c56b8f97e99d2d3847" :GIT-BLOB
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

"))
 :CHECKLIST
 ("| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0005 e ADR-0045 §§6/8. Contesto locale per tratto, senza coda globale per messaggio. |"
  "| 2. Invarianti | Obbligo unico, owner immutabile, lease singola, debito batch positivo≤extracted e ack corrente; stati controllati prima/dopo. Oracolo 8000 passi, fixture parallele e 12 mutanti rilevati. |"
  "| 3. Errori | Recuperabili solo tipo/ragione espliciti per API; owner e faulted prima del handler. Inattesi/permanenti conservano condition originale e campi in faulted terminale; nessun retry cieco o reset. |"
  "| 4. Limiti | Nuove API senza cicli, ricorsione, retry o attese. Take delegato≤64 shard/128 CAS; altri passi O(1), oltre copia batch bounded. Fixture bounded e thread con timeout. |"
  "| 5. Allocazioni | Contesto e buffer preallocati, handler interno dynamic-extent. Venti campioni locali composti heap0 e controllo positivo 16777472 byte; startup/errori esclusi dalla misura, nessuna promessa universale. |"
  "| 6. Dati | Riferimenti typed opachi; target/span/alias verificati prima dell'overflow e del pop. Token locale alla coppia contesto/token, generazioni monotone senza wrap; payload e buffer restano al caller. |"
  "| 7. Decisioni | Inventario di quattro file, predicati nuovi scalari; macro con fixture espansione/valori/errore originale. Raw 11 file: 1427/1660 espressioni e 199/230 esiti, nuovi 498/600 e 65/76; tutte le lacune nel denominatore, nessuna MC/DC dedotta. |"
  "| 8. Proprietà | Owner read-only uguale al thread creatore, non rientrante. Claim/recycle assumono obbligo; cede/adopt lo trasferiscono solo senza lease/batch. Getter diagnostici non trasferiscono proprietà; unicità obbligo precondizione caller. |"
  "| 9. Check | Processo 4000547204-command-93189-0 OK/STABLE/exit0: 387 test più smoke, lint 63/zero, trace/link/evidenze e 10 spike. Integrazione distinta4000548048-command-40192-0 su e2f7a75: 400 test più smoke, lint66/zero. C4 strict compile/FASL self-test e 12/12 mutanti; copertura e benchmark in cache separate. |"
  "| 10. Standard | Safety3, ftype per funzioni, slot typed, docstring pre/post/condition; corpi≤60 righe e complessità ≤10. Macro boundary conserva valori multipli/valutazione unica e intercetta errori solo per stato/diagnosi definiti (COD-21). |"
  "| 11. Parallelismo | Nessuna scrittura globale per messaggio, nuovo lock o thread di prodotto. Contesti locali; guard ready una volta per tratto. Thread riusati/produttori vivi e progresso su shard indipendente; fairness e scalabilità del pool non qualificate. |"
  "| 12. Atomicità | Nessun I/O o modifica durevole. Finishing latched prima di end; busy conserva lease. Dopo end si cambiano soltanto campi locali: nessun cleanup del writer può cancellare una nuova ondata. Ricircolo full atomico delegato; fault interno fail-stop senza rollback promesso. |")
 :REVIEW-TEXT "# Revisione del contesto worker dei writer

Ambito C1: quattro nuovi sorgenti worker, export/ASDF e composizione con
writer, handoff, ready e recycle. Prima lettura indipendente e chiusura dei
finding conservate; seconda lettura sul codice e sulle campagne congelate.
[Inventario delle decisioni](writer-worker-decisioni.md),
[risultati](writer-worker-risultati.md) e
[catalogo](../../spikes/results/2026-10-09-writer-worker/catalogo.lisp)
mantengono denominatori e dati originali, senza esclusioni approvate.

## Lettura dell'autore

| Punto C1 | Esito e ambito |
|---|---|
| 1. Requisiti/ADR | REQ-CON-001/002/004/005 e REQ-AFF-008; ADR-0005 e ADR-0045 §§6/8. Contesto locale per tratto, senza coda globale per messaggio. |
| 2. Invarianti | Obbligo unico, owner immutabile, lease singola, debito batch positivo≤extracted e ack corrente; stati controllati prima/dopo. Oracolo 8000 passi, fixture parallele e 12 mutanti rilevati. |
| 3. Errori | Recuperabili solo tipo/ragione espliciti per API; owner e faulted prima del handler. Inattesi/permanenti conservano condition originale e campi in faulted terminale; nessun retry cieco o reset. |
| 4. Limiti | Nuove API senza cicli, ricorsione, retry o attese. Take delegato≤64 shard/128 CAS; altri passi O(1), oltre copia batch bounded. Fixture bounded e thread con timeout. |
| 5. Allocazioni | Contesto e buffer preallocati, handler interno dynamic-extent. Venti campioni locali composti heap0 e controllo positivo 16777472 byte; startup/errori esclusi dalla misura, nessuna promessa universale. |
| 6. Dati | Riferimenti typed opachi; target/span/alias verificati prima dell'overflow e del pop. Token locale alla coppia contesto/token, generazioni monotone senza wrap; payload e buffer restano al caller. |
| 7. Decisioni | Inventario di quattro file, predicati nuovi scalari; macro con fixture espansione/valori/errore originale. Raw 11 file: 1427/1660 espressioni e 199/230 esiti, nuovi 498/600 e 65/76; tutte le lacune nel denominatore, nessuna MC/DC dedotta. |
| 8. Proprietà | Owner read-only uguale al thread creatore, non rientrante. Claim/recycle assumono obbligo; cede/adopt lo trasferiscono solo senza lease/batch. Getter diagnostici non trasferiscono proprietà; unicità obbligo precondizione caller. |
| 9. Check | Processo 4000547204-command-93189-0 OK/STABLE/exit0: 387 test più smoke, lint 63/zero, trace/link/evidenze e 10 spike. Integrazione distinta4000548048-command-40192-0 su e2f7a75: 400 test più smoke, lint66/zero. C4 strict compile/FASL self-test e 12/12 mutanti; copertura e benchmark in cache separate. |
| 10. Standard | Safety3, ftype per funzioni, slot typed, docstring pre/post/condition; corpi≤60 righe e complessità ≤10. Macro boundary conserva valori multipli/valutazione unica e intercetta errori solo per stato/diagnosi definiti (COD-21). |
| 11. Parallelismo | Nessuna scrittura globale per messaggio, nuovo lock o thread di prodotto. Contesti locali; guard ready una volta per tratto. Thread riusati/produttori vivi e progresso su shard indipendente; fairness e scalabilità del pool non qualificate. |
| 12. Atomicità | Nessun I/O o modifica durevole. Finishing latched prima di end; busy conserva lease. Dopo end si cambiano soltanto campi locali: nessun cleanup del writer può cancellare una nuova ondata. Ricircolo full atomico delegato; fault interno fail-stop senza rollback promesso. |

La prima lettura ha chiuso tre finding prima del congelamento: fault
permanente che deve impedire retry su una nuova ondata, debito batch oltre
extracted e indici privati malformati che non devono essere classificati
come input adozione recuperabile. Le regressioni usano FI dichiarata,
conservano la condition originale e verificano i gate terminali.
Una correzione della fixture macro alle keyword delle allowlist avviene
nella bozza, prima di qualsiasi esecuzione o congelamento.

La postcondizione dopo end non consulta una lease già rilasciata: il
helper locale verifica finishing/debito, elimina la lease locale e passa
idle o reschedule. Busy del primo end cambia solo la fase in finishing;
retry successivi non permettono pop/ack o cessione. La generazione batch
esaurita impedisce pop, ma lascia disponibile end e cessione senza lease,
seguita da adozione in un contesto fresco.

Faulted è il confine di questo contesto, non il controller della Serie.
Il caller deve elaborare tutto il batch prima dell'ack e non abbandonare
obblighi ceduti. Wake/park, admission, quote globali, fairness, retirement
del pool, shutdown, fault cleanup e applicazione WAL restano da integrare.
Nessuna esclusione, gate del motore o qualificazione globale viene chiuso.
"
 :INTEGRATION-VERIFICATION-RECORD
 #A((26) BASE-CHAR . "4000548048-command-40192-0")
 :EXECUTION-VERIFICATION-RECORD "4000547204-command-93189-0" :EXECUTION-TESTS
 89 :NEW-TESTS 23 :MUTATION-RECORD "4000547268-command-97067-0" :DETECTED 12
 :ALLOCATION-RECORD "4000547268-command-97066-0" :SAMPLES 20 :COVERAGE-PROBE
 "4000547296-command-98426-0" :COVERAGE (1427 1660 199 230) :WORKER-COVERAGE
 (498 600 65 76) :HISTORICAL-BASE "cf6091367853ec311fed7b05961a2812fd05a8f1"
 :INTEGRATION-BASE "e2f7a75f3c7a45dffd91343b91d3a889fc3ee056" :LIMITS
 (:LOCAL-COMPONENT :NO-MCDC :NO-APPROVED-EXCLUSIONS :NOT-FULL-POOL
  :FAULTED-LOCAL-ONLY :ACK-CALLER-ATTESTATION))
