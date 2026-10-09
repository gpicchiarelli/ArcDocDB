;;; OWNER: writer riceve eventi solo dopo handoff sincronizzato dal compito I/O.
;;; SHARED: un contatore di consumatori per Serie, nessuna scrittura comune per documento.
(in-package #:arcdocdb.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-AFF-008
(declaim (ftype (function (controllore-serie t t t) null) inizia-io-commit-serie))
(defun inizia-io-commit-serie (controller lease event generation)
  "Pre: evento preparato, prima dell'unico dispatch al pool I/O. Post: consumer attivo.
Rifiuto duplicate/stale/fault prima di mutare. Il caller conserva il dispatch accettato;
se lo scheduler rifiuta, riprogramma lo stesso compito, senza ripetere questo ingresso."
  (%check-owner controller lease) (%live-event controller event generation)
  (%require-healthy controller)
  (unless (eq (commit-serie-phase event) :preparato)
    (error 'invalid-argument :reason :serie-event-state))
  (unless (eq (commit-serie-io-state event) :idle)
    (error 'invalid-argument :reason :serie-io-state))
  (%check-captured-token controller event)
  (let ((complete nil))
    (%begin-effect controller)
    (unwind-protect
         (progn
           (setf (commit-serie-io-state event) :active)
           (incf (controllore-serie-active-io controller))
           (%check-ring controller)
           (unless (eq (commit-serie-io-state event) :active) (%serie-invariant controller :serie-io-state))
           (setf complete t) nil)
      (%end-effect controller complete))))

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-AFF-008 REQ-AFF-001
(declaim (ftype (function (controllore-serie t t t) null) completa-io-commit-serie))
(defun completa-io-commit-serie (controller lease event generation)
  "Pre: messaggio di FINE I/O, consumatore ritirato; consente il drenaggio dopo fault.
Post: consumer retired, conteggio ridotto una volta; written da solo non basta.
INVALID-ARGUMENT per evento/stato; guasto osservato => Serie FAULTED."
  (%check-owner controller lease) (%live-event controller event generation)
  (unless (eq (commit-serie-io-state event) :active)
    (error 'invalid-argument :reason :serie-io-state))
  (unless (member (stato-lotto (the lotto (commit-serie-lotto event))) '(:durable :faulted))
    (error 'invalid-argument :reason :serie-io-in-flight))
  (unless (plusp (controllore-serie-active-io controller)) (%serie-invariant controller :serie-io-count))
  (let ((complete nil))
    (%begin-effect controller)
    (unwind-protect
         (progn
           (when (eq (stato-log (controllore-serie-log controller)) :faulted) (%mark-fault controller :serie))
           (setf (commit-serie-io-state event) :retired)
           (decf (controllore-serie-active-io controller))
           (%check-ring controller)
           (unless (eq (commit-serie-io-state event) :retired) (%serie-invariant controller :serie-io-state))
           (setf complete t) nil)
      (%end-effect controller complete))))

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-AFF-008 REQ-AFF-001
(declaim (ftype (function (controllore-serie t t t) null) ritira-io-commit-serie))
(defun ritira-io-commit-serie (controller lease event generation)
  "Pre: Serie FAULTED; caller conserva il dispatch mai accettato oppure ne ha
ricevuto il ritiro definitivo sincronizzato; gruppo già annullato e lotto sealed.
Post: obbligo I/O retired senza write/flush, token ancora pendente. Non revoca
un compito autonomamente; INVALID-ARGUMENT per salute/stato/owner, invarianti => Archivio."
  (%check-owner controller lease) (%live-event controller event generation)
  (when (eq (stato-controllore-serie controller) :healthy)
    (error 'invalid-argument :reason :serie-not-faulted))
  (unless (eq (commit-serie-phase event) :preparato)
    (error 'invalid-argument :reason :serie-event-state))
  (unless (eq (commit-serie-io-state event) :active)
    (error 'invalid-argument :reason :serie-io-state))
  (%check-captured-token controller event)
  (%check-lotto-release controller (the lotto (commit-serie-lotto event)) :ritiro)
  (unless (plusp (controllore-serie-active-io controller)) (%serie-invariant controller :serie-io-count))
  (let ((complete nil))
    (%begin-effect controller)
    (unwind-protect
         (progn
           (setf (commit-serie-io-state event) :retired)
           (decf (controllore-serie-active-io controller))
           (%check-ring controller)
           (unless (eq (commit-serie-io-state event) :retired) (%serie-invariant controller :serie-io-state))
           (setf complete t) nil)
      (%end-effect controller complete))))

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-WAL-006
(declaim (ftype (function (controllore-serie) null) %require-quiescent))
(defun %require-quiescent (controller)
  "Pre: lease, Serie faulted. Post: nessun consumatore attivo in TUTTI gli slot.
INVALID-ARGUMENT se I/O ancora dovuto; contatore incoerente => FAULTED Archivio.
Scansione al più capacity<=1024, solo sul percorso di guasto."
  (unless (zerop (controllore-serie-active-io controller))
    (error 'invalid-argument :reason :serie-io-active))
  (dotimes (i (length (controllore-serie-slots controller)))
    (let ((event (svref (controllore-serie-slots controller) i)))
      (unless (typep event 'commit-serie) (%serie-invariant controller :serie-event-slot))
      (when (eq (commit-serie-io-state event) :active) (%serie-invariant controller :serie-io-count))))
  nil)
