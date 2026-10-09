;;;; Consegna locale del writer: la guard del ring protegge anche lo scheduling.
;;; OWNER: ogni wrapper e la sua coda privata appartengono a una sola Serie.
;;; SHARED: stato/count sotto la stessa guard; owner/generation con protocollo lease.
;;; Nessuno stato fra Serie: :schedule trasferisce un obbligo al chiamante.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (writer-programmabile (:constructor %make-writer-programmabile (queue))
                                (:copier nil))
  "Pre: coda privata, mai esposta né usata tramite le API basse. Post: writer IDLE.
Le API trasferiscono obblighi :SCHEDULE, non creano thread né inviano notifiche."
  (queue (error 'invariant-violation :reason :writer-scheduling)
         :type coda-writer :read-only t)
  (state :idle :type (member :idle :ready :running)))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (coda-writer) null) %check-writer-inattivo))
(defun %check-writer-inattivo (queue)
  "Pre: guard posseduta, stato IDLE o READY. Post: nessuna lease e quota zero.
INVARIANT-VIOLATION per guard, owner o quota incompatibili con il passaggio."
  (unless (eq (coda-writer-guard queue) sb-thread:*current-thread*)
    (error 'invariant-violation :reason :writer-guard))
  (unless (null (coda-writer-owner queue))
    (error 'invariant-violation :reason :writer-scheduling))
  (unless (zerop (coda-writer-extracted queue))
    (error 'invariant-violation :reason :writer-scheduling))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile) null) %check-programmabile))
(defun %check-programmabile (writer)
  "Pre: guard della coda privata posseduta. Post: ring e stato/owner coerenti.
INVARIANT-VIOLATION per guard errata o stato che non rappresenta il lavoro."
  (let* ((queue (writer-programmabile-queue writer))
         (count (coda-writer-count queue)) (owner (coda-writer-owner queue)))
    (unless (eq (coda-writer-guard queue) sb-thread:*current-thread*)
      (error 'invariant-violation :reason :writer-guard))
    (%check-queue queue)
    (case (writer-programmabile-state writer)
      (:idle
       (unless (zerop count) (error 'invariant-violation :reason :writer-scheduling))
       (%check-writer-inattivo queue))
      (:ready
       (unless (plusp count) (error 'invariant-violation :reason :writer-scheduling))
       (%check-writer-inattivo queue))
      (:running
       (unless owner (error 'invariant-violation :reason :writer-scheduling)))
      (otherwise (error 'invariant-violation :reason :writer-scheduling))))
  nil)

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (&key (:capacity t) (:quantum t)) writer-programmabile)
                crea-writer-programmabile))
(defun crea-writer-programmabile (&key (capacity 1024) (quantum 64))
  "Pre: capacity/quantum nei limiti di CREA-CODA-WRITER. Post: wrapper IDLE
con ring esclusivo preallocato; INVALID-ARGUMENT per configurazione errata."
  (let* ((queue (crea-coda-writer :capacity capacity :quantum quantum))
         (writer (%make-writer-programmabile queue)) (thread (%acquisisci-guard queue)))
    (unwind-protect (progn (%check-programmabile writer) writer)
      (%rilascia-guard queue thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile t)
                         (values index (member :schedule :queued) &optional))
                accoda-lavoro-writer))
(defun accoda-lavoro-writer (writer message)
  "Pre: payload posseduto dal chiamante. Post: accettazione FIFO; :SCHEDULE solo
su IDLE→READY, :QUEUED se già READY/RUNNING. Il chiamante conserva ed esegue una
sola volta l'obbligo :SCHEDULE; un retry della notifica non ripete l'accettazione.
RESOURCE-EXHAUSTED full/busy prima dell'accettazione; invarianti impongono fail-stop."
  (let* ((queue (writer-programmabile-queue writer)) (thread (%acquisisci-guard queue)))
    (unwind-protect
         (progn
           (%check-programmabile writer)
           (let* ((schedule (eq (writer-programmabile-state writer) :idle))
                  (count (%accoda-sotto-guard queue message)))
             (when schedule (setf (writer-programmabile-state writer) :ready))
             (%check-programmabile writer)
             (values count (if schedule :schedule :queued))))
      (%rilascia-guard queue thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile) index) inizia-tratto-writer))
(defun inizia-tratto-writer (writer)
  "Pre: compito pronto assegnato dal chiamante. Post: READY→RUNNING con lease
del thread corrente; nessun messaggio estratto. RESOURCE-EXHAUSTED conserva lo
stato: busy richiede retry del compito; not-ready rifiuta un'assegnazione non
eleggibile/duplicata; generation è esaurimento permanente, senza wrap."
  (let* ((queue (writer-programmabile-queue writer)) (thread (%acquisisci-guard queue)))
    (unwind-protect
         (progn
           (%check-programmabile writer)
           (unless (eq (writer-programmabile-state writer) :ready)
             (error 'resource-exhausted :reason :writer-not-ready))
           (let ((lease (acquisisci-writer queue)))
             (setf (writer-programmabile-state writer) :running)
             (%check-programmabile writer)
             lease))
      (%rilascia-guard queue thread))))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile t t t t)
                         (values index (member :messages :empty :yield) &optional))
                preleva-lavori-writer))
(defun preleva-lavori-writer (writer lease target start end)
  "Pre: lease corrente del tratto e target privato. Post: prelievo FIFO bounded
e quota cumulativa come PRELEVA-MESSAGGI; le medesime condizioni al rifiuto.
La lease impedisce una fine-tratto concorrente; la coda interna resta privata."
  (preleva-messaggi (writer-programmabile-queue writer) lease target start end))

;;; REQ: REQ-CON-001 REQ-CON-002 REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (writer-programmabile t) (member :schedule :idle))
                termina-tratto-writer))
(defun termina-tratto-writer (writer lease)
  "Pre: messaggi estratti elaborati, lease corrente. Post: quota/gettone rilasciati
e READY/:SCHEDULE se resta lavoro, IDLE/:IDLE se vuoto, sotto la guard del ring.
Il chiamante conserva l'obbligo :SCHEDULE. Busy conserva lease e stato: ritentare
solo il termine, senza rielaborare payload. INVALID-ARGUMENT lease; invarianti
impongono fail-stop. Nessuna notifica o attesa; nessun cambiamento durevole."
  (let ((queue (writer-programmabile-queue writer)))
    (%check-lease queue lease)
    (let ((thread (%acquisisci-guard queue)))
      (unwind-protect
           (progn
             (%check-programmabile writer)
             (let ((pending (plusp (coda-writer-count queue))))
               (rilascia-writer queue lease)
               (setf (writer-programmabile-state writer) (if pending :ready :idle))
               (%check-programmabile writer)
               (if pending :schedule :idle)))
        (%rilascia-guard queue thread)))))
