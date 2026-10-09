;;; OWNER: un writer con lease locale; riferimenti evento usati solo dopo handoff.
;;; SHARED: radice immutabile pubblicata per CAS; registro CSN toccato per lotto.
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

;;; REQ: REQ-AFF-008 REQ-CON-002 REQ-WAL-006
(declaim (ftype (function (controllore-serie) null) %check-ring))
(declaim (ftype (function (controllore-serie) (member :healthy :faulted)) stato-controllore-serie))
(declaim (ftype (function (registro-csn log-io &key (:capacity t) (:root t) (:next-offset t))
                         controllore-serie) crea-controllore-serie))
(defun crea-controllore-serie (registry log &key (capacity 64) (root nil) (next-offset 0))
  "Pre: un controller per log segmento, radice immutable e offset iniziale noto.
Post: ring eventi preallocato, nessun I/O/assegnazione CSN; NIL radice valida.
INVALID-ARGUMENT per budget/offset; IO-FAULT per log già guasto."
  (unless (and (typep capacity 'index) (<= 1 capacity +max-serie-commits+)
               (typep next-offset 'index))
    (error 'invalid-argument :reason :serie-budget))
  (verifica-log-segmento log)
  (let* ((slots (make-array capacity :element-type t :initial-element nil))
         (controller (%make-controllore-serie registry log slots root root next-offset)))
    (dotimes (i capacity) (setf (svref slots i) (%make-commit-serie controller i)))
    (%check-ring controller)
    controller))
