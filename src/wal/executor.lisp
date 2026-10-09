;;; OWNER: compito del pool I/O, da acquisizione a flush; buffer tenuti vivi per tutto il compito.
;;; SHARED: active appartiene al log; CAS senza attesa, nessuna scrittura tra Serie.
(in-package #:arcdocdb.wal)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-WAL-006
(declaim (ftype (function (log-io) null) marca-log-faulted))
(defun marca-log-faulted (log)
  "Pre: controller ha ritirato/completato tutti i compiti I/O del log, oppure
il compito proprietario segnala il proprio guasto. Post: log terminale FAULTED.
Non libera active né buffer, non riapre file, non esegue I/O o risolve CSN."
  (setf (log-io-state log) :faulted)
  nil)

;;; REQ: REQ-WAL-002 REQ-AFF-001
(declaim (ftype (function (gruppo) null) acquisisci-gruppo))
(defun acquisisci-gruppo (group)
  "Pre: gruppo pronto e buffer esclusivi. Post: solo questo gruppo possiede il log.
RESOURCE-EXHAUSTED se occupato; INVALID-ARGUMENT per offset/frontiera prima di scrivere."
  (esigi-gruppo group :ready)
  (let* ((log (gruppo-log group)) (file (log-io-file log)))
    (unless (null (sb-ext:compare-and-swap (log-io-active log) nil group))
      (error 'resource-exhausted :reason :log-io-busy))
    (handler-case
        (progn
          (verifica-capienza-append file (gruppo-bytes group)
                                   (loop for i below (gruppo-count group)
                                         maximize (lotto-used (the lotto (svref (gruppo-slots group) i)))))
          (unless (= (gruppo-start group) (posizione-scritta file))
            (error 'invalid-argument :reason :group-file-offset))
          (dotimes (i (gruppo-count group))
            (let* ((lotto (the lotto (svref (gruppo-slots group) i)))
                   (seal-start (- (lotto-used lotto) +seal-bytes+)))
              (esigi-lotto lotto :sealed)
              (unless (<= (arcdocdb.binary:leggi-u64 (lotto-buffer lotto)
                                (+ seal-start +seal-durable-offset+)) (posizione-durevole file))
                (error 'invalid-argument :reason :group-future-durable))))
          (setf (gruppo-state group) :writing))
      (invalid-argument (c)
        (unless (eq group (sb-ext:compare-and-swap (log-io-active log) group nil))
          (error 'invariant-violation :reason :group-owner))
        (error c))
      (resource-exhausted (c)
        (unless (eq group (sb-ext:compare-and-swap (log-io-active log) group nil))
          (error 'invariant-violation :reason :group-owner))
        (error c))
      (io-fault (c) (fault-gruppo group) (error c))
      (invariant-violation (c) (fault-gruppo group) (error c))))
  nil)

;;; REQ: REQ-AFF-001 REQ-WAL-006
(declaim (ftype (function (gruppo) null) fault-gruppo))
(defun fault-gruppo (group)
  "Pre: guasto in volo. Post: log/gruppo/lotti FAULTED, proprietà non rilasciata.
Nessun retry, nessuna ulteriore copertura; il worker propaga l'evento alla Serie/Archivio."
  (marca-log-faulted (gruppo-log group))
  (setf (gruppo-state group) :faulted)
  (dotimes (i (gruppo-count group))
    (setf (lotto-state (the lotto (svref (gruppo-slots group) i))) :faulted))
  nil)

;;; REQ: REQ-WAL-002 REQ-WAL-006 REQ-AFF-001
(declaim (ftype (function (gruppo) file-offset) scrivi-gruppo))
(defun scrivi-gruppo (group)
  "Pre: compito I/O, gruppo pronto; nessuna mutazione/riuso dei buffer in volo.
Post: tutti i lotti scritti, ancora non durevoli; proprietà resta al gruppo fino al flush.
Punti SEAL preparati sono appesi; IO-FAULT/INVARIANT-VIOLATION => fail-stop, nessuna conferma."
  (acquisisci-gruppo group)
  (handler-case
      (let ((file (log-io-file (gruppo-log group))))
        (dotimes (i (gruppo-count group))
          (let* ((lotto (the lotto (svref (gruppo-slots group) i)))
                 (end (append-esatto file (lotto-buffer lotto) 0 (lotto-used lotto))))
            (unless (= end (+ (lotto-start lotto) (lotto-used lotto)))
              (error 'invariant-violation :reason :group-write-frontier))
            (setf (lotto-state lotto) :written)))
        (setf (gruppo-state group) :written)
        (posizione-scritta file))
    (io-fault (c) (fault-gruppo group) (error c))
    (invariant-violation (c) (fault-gruppo group) (error c))))

;;; REQ: REQ-WAL-002 REQ-WAL-006 REQ-AFF-001
(declaim (ftype (function (gruppo) file-offset) sincronizza-gruppo))
(defun sincronizza-gruppo (group)
  "Pre: compito I/O, write completata e proprietà mantenuta. Post: un solo flush copre il gruppo.
Il SEAL è il punto atomico; questo completa durability, non pubblica né conferma.
IO-FAULT/INVARIANT-VIOLATION => FAULTED; un secondo flush dello stesso gruppo è rifiutato."
  (esigi-gruppo group :written)
  (let ((log (gruppo-log group)))
    (unless (eq :written (sb-ext:compare-and-swap (gruppo-state group) :written :flushing))
      (error 'resource-exhausted :reason :group-flush-busy))
    (handler-case
        (progn
          (unless (eq (log-io-active log) group)
            (error 'invariant-violation :reason :group-owner))
          (let ((end (durable-flush (log-io-file log))))
            (unless (= end (+ (gruppo-start group) (gruppo-bytes group)))
              (error 'invariant-violation :reason :group-flush-frontier))
            (dotimes (i (gruppo-count group))
              (setf (lotto-state (the lotto (svref (gruppo-slots group) i))) :durable))
            (setf (gruppo-state group) :durable)
            (unless (eq group (sb-ext:compare-and-swap (log-io-active log) group nil))
              (error 'invariant-violation :reason :group-owner))
            end))
      (io-fault (c) (fault-gruppo group) (error c))
      (invariant-violation (c) (fault-gruppo group) (error c)))))

;;; REQ: REQ-WAL-002
(declaim (ftype (function (gruppo) file-offset) esegui-gruppo))
(defun esegui-gruppo (group)
  "Pre: compito I/O, gruppo pronto. Post: write di N lotti e un flush; errori fail-stop.
Preparazione del SEAL già conclusa; completa durability, mai pubblicazione/conferma."
  (scrivi-gruppo group)
  (sincronizza-gruppo group))
