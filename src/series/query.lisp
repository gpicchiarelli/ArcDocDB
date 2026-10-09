;;; OWNER: radici immutabili del caller; query di metadati solo con handoff/lease.
;;; SHARED: lettura root con barriera acquire, nessuna scrittura sul percorso GET.
(in-package #:arcdocdb.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-CON-002
(declaim (ftype (function (controllore-serie) (member :healthy :faulted)) stato-controllore-serie)
         (ftype (function (controllore-serie) (member :none :serie :archive)) ambito-fault-serie))
(defun stato-controllore-serie (controller)
  "Pre: capacità del controller. Post: salute osservata atomicamente con barriera.
Non coordina altri controller né prova quiescenza."
  (let ((state (controllore-serie-state controller)))
    (sb-thread:barrier (:read))
    (if (eq state :healthy) :healthy :faulted)))

;;; REQ: REQ-AFF-001 REQ-CON-002
(defun ambito-fault-serie (controller)
  "Pre: capacità del controller. Post: ambito dalla STESSA parola atomica della salute.
INVARIANT-VIOLATION per enum incoerente; nessuna risoluzione o attesa."
  (let ((state (controllore-serie-state controller)))
    (sb-thread:barrier (:read))
    (case state
      (:healthy :none) (:faulted :serie) (:archive-faulted :archive)
      (otherwise (%serie-invariant controller :serie-health)))))

;;; REQ: REQ-WAL-006 REQ-CON-002 REQ-AFF-001
(declaim (ftype (function (controllore-serie) t) leggi-radice-serie))
(defun leggi-radice-serie (controller)
  "Pre: reader conserva il riferimento alla radice immutabile. Post: vista pubblicata
con barriera acquire, nessuna allocazione o consultazione CSN condivisa.
IO-FAULT per salute/log guasti osservati; non promette snapshot o reclaim."
  (unless (eq (stato-controllore-serie controller) :healthy)
    (error 'io-fault :reason :serie-faulted :operation :series))
  (unless (eq (stato-log (controllore-serie-log controller)) :open)
    (error 'io-fault :reason :log-faulted :operation :series))
  (let ((root (controllore-serie-root controller)))
    (sb-thread:barrier (:read))
    root))

;;; REQ: REQ-CON-002 REQ-MVC-008
(declaim (ftype (function (controllore-serie t t) keyword) stato-commit-serie)
         (ftype (function (controllore-serie t t) (values index u32 u32 &optional)) leggi-csn-commit-serie)
         (ftype (function (controllore-serie t) (values index index index &optional)) conta-commit-serie))
(defun stato-commit-serie (controller event generation)
  "Pre: writer/evento dopo handoff. Post: fase locale corrente, nessuna lettura concorrente libera.
INVALID-ARGUMENT per identità/generation; non osserva H o durability."
  (%check-event controller event generation)
  (case (commit-serie-phase event)
    ((:libero :preparato :pubblicato :risolto :annullato) (commit-serie-phase event))
    (otherwise (%serie-invariant controller :serie-event-uncertain))))

;;; REQ: REQ-MVC-008 REQ-CON-002
(defun leggi-csn-commit-serie (controller event generation)
  "Pre: writer/evento dopo handoff. Post: token catturato, conservato dopo risoluzione.
INVALID-ARGUMENT per libero/stale; mai ricostruzione da lotto riusato o boxing u64."
  (%live-event controller event generation)
  (values (commit-serie-slot event) (commit-serie-high event) (commit-serie-low event)))

;;; REQ: REQ-CON-002 REQ-AFF-008
(defun conta-commit-serie (controller lease)
  "Pre: lease corrente. Post: conteggi coerenti di slot, irrisolti e consumatori I/O.
INVALID-ARGUMENT per lease; invarianti portano FAULTED."
  (%check-owner controller lease)
  (values (controllore-serie-count controller) (controllore-serie-unresolved controller)
          (controllore-serie-active-io controller)))
