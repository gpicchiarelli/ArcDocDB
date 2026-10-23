;;; OWNER: il controllore configura prima dell'uso; nessuna mutazione successiva.
;;; SHARED: configurazione read-only; nessun accesso al percorso GET (INV-P6).
(in-package #:arcdocdb.index.mode)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-008 REQ-AFF-008
(defconstant +max-byte-indice+ #.(1- (ash 1 60)))
(deftype byte-indice () '(integer 0 #.+max-byte-indice+))
(deftype modo-indice () '(member :iniziale :residente :paginato))
(deftype destinazione-indice () '(member :residente :paginato))
(deftype azione-indice () '(member :avvia :mantieni :prepara :budget-insufficiente))

;;; REQ: REQ-IDX-008 REQ-AFF-008
(defstruct (politica-indice (:constructor %make-politica-indice (rientro)) (:copier nil))
  "Pre: percentuale 1..99 verificata. Post: politica automatica immutabile.
Nessuna condizione oltre ai tipi del costruttore privato; nessuna risorsa acquisita."
  (rientro 75 :type (integer 1 99) :read-only t))

;;; REQ: REQ-IDX-008 REQ-AFF-008
(declaim (ftype (function (&key (:rientro-percentuale t)) politica-indice) crea-politica-indice))
(defun crea-politica-indice (&key (rientro-percentuale 75))
  "Pre: configurazione fuori dal lookup. Post: politica automatica con deadband.
INVALID-ARGUMENT per percentuale non intera o fuori 1..99; alloca solo la configurazione."
  (unless (and (typep rientro-percentuale 'fixnum) (<= 1 rientro-percentuale 99))
    (error 'invalid-argument :reason :index-mode-return-percent))
  (%make-politica-indice rientro-percentuale))
