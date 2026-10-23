;;; OWNER: un writer con lease locale; riferimenti evento usati solo dopo handoff.
;;; SHARED: binding unico sul log all'avvio; radice per CAS, registro CSN per lotto.
(in-package #:arcdocdb.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-008 REQ-CON-005
(defconstant +max-serie-commits+ 1024)

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-MVC-008 REQ-AFF-008
(defstruct (controllore-serie
             (:constructor %make-controllore-serie (registry log slots root planned-root next-offset))
             (:copier nil))
  "Pre: registro, log e slots esclusivi della Serie. Post: HEALTHY e ring vuoto.
Le radici sono riferimenti immutabili; nessun contesto allocato per lotto."
  (registry nil :type registro-csn :read-only t)
  (log nil :type log-io :read-only t)
  (slots #() :type simple-vector :read-only t)
  (root nil :type t) (planned-root nil :type t) (next-offset 0 :type index)
  (owner nil :type (or null sb-thread:thread))
  (lease-generation 0 :type index) (event-generation 0 :type index)
  (last-high 0 :type u32) (last-low 0 :type u32)
  (head 0 :type index) (tail 0 :type index) (publish-head 0 :type index)
  (count 0 :type index) (unresolved 0 :type index) (active-io 0 :type index)
  (state :healthy :type (member :healthy :faulted :archive-faulted))
  (effect-active nil :type boolean))

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-MVC-008 REQ-AFF-008
(defstruct (commit-serie (:constructor %make-commit-serie (controller position)) (:copier nil))
  "Pre: slot costruito una volta. Post: capacità legata al controller e posizione.
Il messaggio conserva l'oggetto e generation catturata, mai riletta dopo il riuso."
  (controller nil :type controllore-serie :read-only t)
  (position 0 :type index :read-only t)
  (generation 0 :type index) (lotto nil :type (or null lotto))
  (slot 0 :type index) (high 0 :type u32) (low 0 :type u32)
  (expected-root nil :type t) (root nil :type t)
  (level :group :type (member :async :group :strong))
  (phase :libero :type (member :libero :preparato :pubblicando :pubblicato :risolto :annullato))
  (io-state :idle :type (member :idle :active :retired)))

;;; OWNER: getter senza lease; legge solo il binding e il legame immutabile al log.
;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-AFF-008
(declaim (ftype (function (log-io) (or null controllore-serie)) trova-controllore-serie))
(defun trova-controllore-serie (log)
  "Pre: oggetto log canonico conservato dal caller. Post: NIL o stesso controller dopo acquire.
Un solo caricamento; recupera il binding anche se il ritorno della factory è interrotto.
INVARIANT-VIOLATION :SERIE-LOG-BINDING per tipo estraneo o legame inverso incoerente.
Il coordinatore arresta bootstrap/adozione senza ammissione; un riferimento estraneo non viene mutato.
Nessuna verifica di salute, ring o lease; nessuna mutazione, I/O o assegnazione CSN."
  (let ((controller (arcdocdb.wal::log-io-controller log)))
    (sb-thread:barrier (:read))
    (unless (typep controller '(or null controllore-serie))
      (error 'invariant-violation :reason :serie-log-binding))
    (when controller
      (unless (eq (controllore-serie-log controller) log)
        (error 'invariant-violation :reason :serie-log-binding)))
    controller))

;;; OWNER: candidato privato fino al CAS; il binding sul log non viene mai azzerato.
;;; REQ: REQ-AFF-008 REQ-CON-002 REQ-WAL-006
(declaim (ftype (function (controllore-serie) null) %check-ring))
(declaim (ftype (function (controllore-serie keyword) nil) %serie-invariant))
(declaim (ftype (function (controllore-serie) (member :healthy :faulted)) stato-controllore-serie))
(declaim (ftype (function (registro-csn log-io &key (:capacity t) (:root t) (:next-offset t))
                         controllore-serie) crea-controllore-serie))
(defun crea-controllore-serie (registry log &key (capacity 64) (root nil) (next-offset 0))
  "Pre: log segmento canonico, radice immutabile e offset iniziale noto; ammissione chiusa.
Post: un solo controller legato al log, ring preallocato; NIL radice valida.
INVALID-ARGUMENT per budget/offset o :SERIE-LOG-BOUND al doppio avvio; IO-FAULT per log guasto.
Tutti i preflight precedono il CAS: errore prima del CAS non pubblica il candidato.
Dopo il CAS riuscito solo ritorno; TROVA-CONTROLLORE-SERIE recupera il binding senza reset.
Nessun I/O, assegnazione CSN o lease mutata; il binding non ammette traffico.
Esclusione fisica e canonicalità del log restano al caller; la rotazione crea un nuovo log."
  (unless (and (typep capacity 'index) (<= 1 capacity +max-serie-commits+)
               (typep next-offset 'index))
    (error 'invalid-argument :reason :serie-budget))
  (when (trova-controllore-serie log)
    (error 'invalid-argument :reason :serie-log-bound))
  (verifica-log-segmento log)
  (let* ((slots (make-array capacity :element-type t :initial-element nil))
         (controller (%make-controllore-serie registry log slots root root next-offset)))
    (dotimes (i capacity) (setf (svref slots i) (%make-commit-serie controller i)))
    (%check-ring controller)
    (unless (and (eq (controllore-serie-registry controller) registry)
                 (eq (controllore-serie-log controller) log))
      (%serie-invariant controller :serie-log-binding))
    (unless (and (eq (controllore-serie-slots controller) slots)
                 (= (controllore-serie-next-offset controller) next-offset))
      (%serie-invariant controller :serie-log-binding))
    (sb-thread:barrier (:write))
    (unless (null (sb-ext:compare-and-swap (arcdocdb.wal::log-io-controller log) nil controller))
      (error 'invalid-argument :reason :serie-log-bound))
    controller))
