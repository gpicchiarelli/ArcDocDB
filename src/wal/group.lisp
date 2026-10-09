;;; OWNER: writer prepara il gruppo; il compito I/O lo possiede da write a flush.
;;; SHARED: CAS solo sul log/gruppo; nessuno stato mutabile tra Serie.
(in-package #:arcdocdb.wal)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-WAL-002 REQ-AFF-008
(declaim (ftype (function (gruppo keyword) null) esigi-gruppo))
(defun esigi-gruppo (group state)
  "Pre: gruppo posseduto. Post: stato richiesto e log sano, senza I/O.
INVALID-ARGUMENT per ciclo errato; IO-FAULT dopo un guasto del log."
  (unless (eq (gruppo-state group) state) (error 'invalid-argument :reason :group-state))
  (unless (eq (log-io-state (gruppo-log group)) :open)
    (error 'io-fault :reason :log-faulted :operation :wal))
  nil)

;;; REQ: REQ-WAL-002 REQ-WAL-005 REQ-MVC-008
(declaim (ftype (function (gruppo lotto) null) verifica-identita-lotto))
(defun verifica-identita-lotto (group lotto)
  "Pre: gruppo building, lotto sealed. Post: stesso log e layout, posizione contigua.
INVALID-ARGUMENT prima di acquisire il lotto; un token del ponte resta legato al log originale."
  (let ((log (gruppo-log group)) (count (gruppo-count group)))
    (unless (and (eq (lotto-kind lotto) (log-io-kind log))
                 (= (lotto-file-id lotto) (log-io-file-id log))
                 (= (lotto-version lotto) (log-io-version log)))
      (error 'invalid-argument :reason :group-identity-or-order))
    (when (and (lotto-csn-log lotto) (not (eq (lotto-csn-log lotto) log)))
      (error 'invalid-argument :reason :lotto-csn-log))
    (unless (or (zerop count)
                (= (lotto-start lotto) (+ (gruppo-start group) (gruppo-bytes group))))
      (error 'invalid-argument :reason :group-identity-or-order)))
  nil)

;;; REQ: REQ-WAL-002 REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (gruppo lotto) index) aggiungi-lotto))
(defun aggiungi-lotto (group lotto)
  "Pre: gruppo in costruzione, lotto sigillato esclusivo, mai riusato in volo.
Post: lotto contiguo e budget rispettati; INVALID-ARGUMENT/RESOURCE-EXHAUSTED senza mutazione."
  (esigi-gruppo group :building)
  (esigi-lotto lotto :sealed)
  (verifica-identita-lotto group lotto)
  (let ((count (gruppo-count group)))
    (when (or (= count (length (gruppo-slots group)))
              (> (lotto-used lotto) (- (gruppo-max-bytes group) (gruppo-bytes group))))
      (error 'resource-exhausted :reason :group-capacity))
    (when (loop for i below count thereis (eq lotto (svref (gruppo-slots group) i)))
      (error 'invalid-argument :reason :group-duplicate))
    (unless (null (sb-ext:compare-and-swap (lotto-owner lotto) nil group))
      (error 'invalid-argument :reason :lotto-owned))
    (when (zerop count) (setf (gruppo-start group) (lotto-start lotto)))
    (setf (svref (gruppo-slots group) count) lotto)
    (incf (gruppo-count group))
    (incf (gruppo-bytes group) (lotto-used lotto))
    (unless (<= (gruppo-bytes group) (gruppo-max-bytes group))
      (error 'invariant-violation :reason :group-byte-budget))
    (gruppo-count group)))

;;; REQ: REQ-WAL-002
(declaim (ftype (function (gruppo) null) chiudi-gruppo))
(defun chiudi-gruppo (group)
  "Pre: gruppo in costruzione. Post: snapshot chiuso e non vuoto per il compito I/O.
INVALID-ARGUMENT per gruppo vuoto; nessuna syscall o conferma."
  (esigi-gruppo group :building)
  (when (zerop (gruppo-count group)) (error 'invalid-argument :reason :group-empty))
  (setf (gruppo-state group) :ready)
  nil)

;;; REQ: REQ-WAL-002 REQ-AFF-008
(declaim (ftype (function (gruppo) null) svuota-gruppo))
(defun svuota-gruppo (group)
  "Pre: nessun consumatore, gruppo ritirato/durevole. Post: proprietà e slot rilasciati.
INVARIANT-VIOLATION per riferimenti incoerenti, verificati prima di rilasciare il primo."
  (dotimes (i (gruppo-count group))
    (unless (eq group (lotto-owner (the lotto (svref (gruppo-slots group) i))))
      (error 'invariant-violation :reason :lotto-owner)))
  (dotimes (i (gruppo-count group))
    (let ((lotto (the lotto (svref (gruppo-slots group) i))))
      (unless (eq group (sb-ext:compare-and-swap (lotto-owner lotto) group nil))
        (error 'invariant-violation :reason :lotto-owner))
      (setf (svref (gruppo-slots group) i) nil)))
  (setf (gruppo-count group) 0 (gruppo-bytes group) 0 (gruppo-start group) 0
        (gruppo-state group) :building)
  nil)

;;; REQ: REQ-WAL-002 REQ-AFF-008
(declaim (ftype (function (gruppo) null) riusa-gruppo))
(defun riusa-gruppo (group)
  "Pre: gruppo durevole, nessun consumatore in volo. Post: slot rilasciati, stesso gruppo vuoto.
INVALID-ARGUMENT al riuso prematuro; non riapre automaticamente i lotti referenziati."
  (esigi-gruppo group :durable)
  (svuota-gruppo group))

;;; REQ: REQ-WAL-006 REQ-WAL-003
(declaim (ftype (function (gruppo) null) annulla-gruppo))
(defun annulla-gruppo (group)
  "Pre: ritirato dallo scheduler, nessun consumatore; building/ready mai scritto.
Post: riferimenti rilasciati, lotti ancora sealed per un altro gruppo. INVALID-ARGUMENT
se in volo; nessuna cancellazione di dati su disco o riapertura del buffer."
  (unless (member (gruppo-state group) '(:building :ready))
    (error 'invalid-argument :reason :group-in-flight))
  (when (eq group (log-io-active (gruppo-log group)))
    (error 'invalid-argument :reason :group-in-flight))
  (svuota-gruppo group))

;;; REQ: REQ-WAL-006 REQ-WAL-003
(declaim (ftype (function (lotto (member :async :group :strong)) boolean) coperto-p))
(defun coperto-p (lotto level)
  "Pre: stato letto dal proprietario/evento sincronizzato. Post: byte coperti al livello.
Non è pubblicazione, commit 2PC o conferma. INVALID-ARGUMENT per async su log di controllo."
  (when (and (eq level :async) (not (eq (lotto-kind lotto) :segment)))
    (error 'invalid-argument :reason :async-control-log))
  (not (null (if (eq level :async) (member (lotto-state lotto) '(:written :durable))
                (eq (lotto-state lotto) :durable)))))

;;; REQ: REQ-WAL-002 REQ-AFF-001
(declaim (ftype (function (gruppo) keyword) stato-gruppo)
         (ftype (function (log-io) keyword) stato-log))
(defun stato-gruppo (group)
  "Pre: osservazione del proprietario/evento. Post: stato locale, senza modifica." (gruppo-state group))
;;; REQ: REQ-AFF-001
(defun stato-log (log)
  "Pre: log posseduto. Post: salute locale, senza syscall né modifica." (log-io-state log))
