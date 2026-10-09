;;; OWNER: mutazioni del registro sotto mutex snapshot; ordine dei lock: snapshot poi CSN.
;;; SHARED: soglia e identità pubblicate con barriere; nessuna callback sotto lock.
(in-package #:arcdocdb.mvcc)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-007 REQ-AFF-004
(declaim (inline snapshot-pinned-p))
(declaim (ftype (function ((unsigned-byte 8)) boolean) snapshot-pinned-p))
(defun snapshot-pinned-p (state)
  "Pre: stato numerico. Post: attesa e attività trattengono versioni; gli altri stati no."
  (or (= state +snapshot-waiting+) (= state +snapshot-active+)))

;;; REQ: REQ-MVC-007 REQ-AFF-004
(declaim (inline esigi-snapshot-sano))
(declaim (ftype (function (registro-snapshot) null) esigi-snapshot-sano))
(defun esigi-snapshot-sano (registry)
  "Pre: registro esistente. Post: salute snapshot/CSN campionata con barriera acquire.
INVARIANT-VIOLATION dopo FAULTED; non legge contatori CSN in mutazione e non prende mutex."
  (sb-thread:barrier (:read)
    (unless (and (eq (registro-snapshot-health registry) :open)
                 (eq (registro-csn-state (registro-snapshot-csns registry)) :open))
      (error 'invariant-violation :reason :snapshot-registry-faulted)))
  nil)

;;; REQ: REQ-MVC-007 REQ-AFF-004
(declaim (ftype (function (registro-snapshot keyword) nil) guasto-snapshot))
(defun guasto-snapshot (registry reason)
  "Pre: mutex snapshot posseduto. Post: FAULTED pubblicato, errore tipizzato, nessun rollback."
  (sb-thread:barrier (:write))
  (setf (registro-snapshot-health registry) :faulted)
  (error 'invariant-violation :reason reason))

;;; REQ: REQ-MVC-007 REQ-AFF-008
(declaim (ftype (function (registro-snapshot) null) verifica-contatori-snapshot))
(defun verifica-contatori-snapshot (registry)
  "Pre: mutex snapshot posseduto. Post: contatori/cursori compatibili con K.
INVARIANT-VIOLATION con fail-stop per incoerenza; nessuna scansione sul percorso reader."
  (esigi-snapshot-sano registry)
  (let ((capacity (length (registro-snapshot-states registry))))
    (unless (and (<= (registro-snapshot-count registry) capacity)
                 (< (registro-snapshot-cursor registry) capacity)
                 (< (registro-snapshot-sweep-cursor registry) capacity)
                 (if (zerop (registro-snapshot-count registry))
                     (= (aref (registro-snapshot-words registry) 1) +max-csn+)
                     (plusp (aref (registro-snapshot-words registry) 0))))
      (guasto-snapshot registry :snapshot-counters-inconsistent)))
  nil)

;;; REQ: REQ-MVC-007 REQ-AFF-008
(declaim (ftype (function (registro-snapshot) csn-slot) trova-slot-snapshot))
(defun trova-slot-snapshot (registry)
  "Pre: mutex posseduto e credito disponibile. Post: slot privo di pin, al massimo K visite.
INVARIANT-VIOLATION se stato o contabilità non sono coerenti."
  (let* ((states (registro-snapshot-states registry)) (capacity (length states))
         (cursor (registro-snapshot-cursor registry)))
    (dotimes (step capacity)
      (let* ((candidate (+ cursor step))
             (slot (if (< candidate capacity) candidate (- candidate capacity)))
             (state (aref states slot)))
        (unless (<= state +snapshot-age-expired+)
          (guasto-snapshot registry :snapshot-slot-state))
        (unless (snapshot-pinned-p state) (return-from trova-slot-snapshot slot))))
    (guasto-snapshot registry :snapshot-credit-accounting)))

;;; REQ: REQ-MVC-007 REQ-MVC-004
(declaim (ftype (function (contesto-snapshot u64) csn-slot) esigi-identita-snapshot))
(defun esigi-identita-snapshot (context expected-generation)
  "Pre: mutex snapshot posseduto. Post: slot dell'identità originale, anche se già terminato.
SNAPSHOT-TOO-OLD per contesto/slot riusato; nessun accesso a una nuova incarnazione."
  (let* ((registry (contesto-snapshot-registry context)) (slot (contesto-snapshot-slot context)))
    (unless (and (plusp expected-generation)
                 (= expected-generation (aref (contesto-snapshot-word context) 0))
                 (< slot (length (registro-snapshot-generations registry)))
                 (= expected-generation (aref (registro-snapshot-generations registry) slot)))
      (error 'snapshot-too-old :reason :snapshot-stale-identity))
    slot))

;;; REQ: REQ-MVC-007 REQ-MVC-003
(declaim (ftype (function (registro-snapshot) null) ricalcola-soglia-snapshot))
(defun ricalcola-soglia-snapshot (registry)
  "Pre: mutex posseduto, stati aggiornati. Post: minimo CSN dei pin oppure MAX-U64.
Verifica conteggio e metadati prima di alzare la soglia; fail-stop su incoerenza."
  (let ((states (registro-snapshot-states registry)) (minimum +max-csn+) (count 0)
        (last-generation (aref (registro-snapshot-words registry) 0)))
    (declare (type u64 minimum last-generation))
    (dotimes (slot (length states))
      (let ((state (aref states slot)))
        (unless (<= state +snapshot-age-expired+)
          (guasto-snapshot registry :snapshot-slot-state))
        (when (snapshot-pinned-p state)
          (unless (and (<= 1 (aref (registro-snapshot-generations registry) slot) last-generation)
                       (<= (aref (registro-snapshot-wait-deadlines registry) slot)
                           (aref (registro-snapshot-deadlines registry) slot)))
            (guasto-snapshot registry :snapshot-slot-metadata))
          (incf count)
          (setf minimum (min minimum (aref (registro-snapshot-csns-array registry) slot))))))
    (unless (= count (registro-snapshot-count registry))
      (guasto-snapshot registry :snapshot-credit-accounting))
    (unless (<= (aref (registro-snapshot-words registry) 1) minimum)
      (guasto-snapshot registry :snapshot-threshold-regression))
    (sb-thread:barrier (:write))
    (setf (aref (registro-snapshot-words registry) 1) minimum))
  nil)

;;; REQ: REQ-MVC-004 REQ-MVC-003 REQ-MVC-007
(declaim (ftype (function (registro-snapshot csn-slot (unsigned-byte 8)) null)
                ritira-slot-snapshot))
(defun ritira-slot-snapshot (registry slot terminal-state)
  "Pre: mutex posseduto, slot con pin, stato terminale noto. Post: pin rimosso e soglia aggiornata.
Uscita non locale durante mutazione marca FAULTED; non cancella record né riferimenti EBR."
  (let ((complete nil))
    (unwind-protect
         (progn
           (setf (aref (registro-snapshot-states registry) slot) terminal-state)
           (sb-thread:barrier (:memory))
           (decf (registro-snapshot-count registry))
           (ricalcola-soglia-snapshot registry)
           (setf complete t))
      (unless complete
        (sb-thread:barrier (:write))
        (setf (registro-snapshot-health registry) :faulted))))
  nil)
