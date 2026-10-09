;;; OWNER: lease del thread corrente; cleanup rilascia solo la proprietà locale.
;;; SHARED: CAS owner per tratto di Serie; nessuno stato comune tra Serie.
(in-package #:arcdocdb.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (controllore-serie (member :serie :archive)) null) %mark-fault))
(defun %mark-fault (controller scope)
  "Pre: proprietario o cleanup del suo effetto. Post: fault terminale, scope mai ridotto.
Non elimina dati, non risolve token e non riapre log; nessun errore ordinario."
  (if (eq scope :archive)
      (setf (controllore-serie-state controller) :archive-faulted)
      (case (sb-ext:compare-and-swap (controllore-serie-state controller) :healthy :faulted)
        ((:healthy :faulted :archive-faulted) nil)
        (otherwise
         (setf (controllore-serie-state controller) :archive-faulted)
         (error 'invariant-violation :reason :serie-health))))
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (controllore-serie keyword) nil) %serie-invariant))
(defun %serie-invariant (controller reason)
  "Pre: invariante interna falsa. Post: Serie FAULTED, ambito Archivio, condizione propagata.
Non promette rollback; il coordinatore deve fermare l'Archivio e conservare il contesto."
  (%mark-fault controller :archive)
  (error 'invariant-violation :reason reason))

;;; REQ: REQ-AFF-008 REQ-CON-002
(declaim (ftype (function (controllore-serie) null) %check-ring))
(defun %check-ring (controller)
  "Pre: lease o costruzione esclusiva. Post: cursori e contatori entro capacità.
INVARIANT-VIOLATION rende FAULTED prima di usare un indice incoerente."
  (let ((capacity (length (controllore-serie-slots controller))))
    (unless (and (<= 1 capacity +max-serie-commits+)
                 (< (controllore-serie-head controller) capacity)
                 (< (controllore-serie-tail controller) capacity)
                 (< (controllore-serie-publish-head controller) capacity))
      (%serie-invariant controller :serie-ring))
    (unless (and (<= (controllore-serie-count controller) capacity)
                 (<= (controllore-serie-unresolved controller) (controllore-serie-count controller))
                 (<= (controllore-serie-active-io controller) (controllore-serie-count controller)))
      (%serie-invariant controller :serie-count)))
  (%check-geometry controller)
  nil)

;;; REQ: REQ-CON-002 REQ-AFF-008
(declaim (ftype (function (controllore-serie index index) index) %position-after)
         (ftype (function (controllore-serie) null) %check-geometry))
(defun %position-after (controller position amount)
  "Pre: position nel ring, amount al più capacity. Post: somma modulo capacità.
Due limiti verificati prima della somma<=2047; invarianti => FAULTED."
  (let ((capacity (length (controllore-serie-slots controller))))
    (unless (< position capacity) (%serie-invariant controller :serie-ring))
    (unless (<= amount capacity) (%serie-invariant controller :serie-count))
    (let ((sum (+ position amount)))
      (if (>= sum capacity) (- sum capacity) sum))))

;;; REQ: REQ-CON-002 REQ-WAL-006 REQ-MVC-008
(defun %check-geometry (controller)
  "Pre: limiti di cursori/count già verificati. Post: tail=head+count e
tail=publish-head+unresolved modulo capacità; nessuna lettura di slot non verificati."
  (unless (= (controllore-serie-tail controller)
             (%position-after controller (controllore-serie-head controller) (controllore-serie-count controller)))
    (%serie-invariant controller :serie-ring-geometry))
  (unless (= (controllore-serie-tail controller)
             (%position-after controller (controllore-serie-publish-head controller)
                              (controllore-serie-unresolved controller)))
    (%serie-invariant controller :serie-ring-geometry))
  nil)

;;; REQ: REQ-CON-002 REQ-AFF-004
(declaim (ftype (function (controllore-serie t) null) %check-owner))
(defun %check-owner (controller lease)
  "Pre: token del chiamante. Post: thread/generation correnti e ring valido.
INVALID-ARGUMENT per lease vecchia/estranea; invarianti => FAULTED."
  (unless (and (typep lease 'index) (plusp lease)
               (= lease (controllore-serie-lease-generation controller))
               (eq (controllore-serie-owner controller) sb-thread:*current-thread*))
    (error 'invalid-argument :reason :serie-lease))
  (%check-ring controller)
  nil)

;;; REQ: REQ-CON-002 REQ-AFF-001
(declaim (ftype (function (controllore-serie sb-thread:thread) null) %release-owner))
(defun %release-owner (controller thread)
  "Pre: THREAD possiede owner. Post: un CAS rilascia la capacità senza attesa.
INVARIANT-VIOLATION su owner incoerente; nessun retry né liberazione di token."
  (unless (eq (controllore-serie-owner controller) thread)
    (%serie-invariant controller :serie-owner))
  (unless (eq (sb-ext:compare-and-swap (controllore-serie-owner controller) thread nil) thread)
    (%serie-invariant controller :serie-owner))
  nil)

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (controllore-serie) index) acquisisci-controllore-serie))
(defun acquisisci-controllore-serie (controller)
  "Pre: un nuovo tratto del writer. Post: lease del thread, generazione senza wrap.
RESOURCE-EXHAUSTED per busy/esaurimento; un errore di acquisizione rilascia owner."
  (let ((thread sb-thread:*current-thread*) (committed nil))
    (unless (null (sb-ext:compare-and-swap (controllore-serie-owner controller) nil thread))
      (error 'resource-exhausted :reason :serie-busy))
    (unwind-protect
         (progn
           (%check-ring controller)
           (when (= (controllore-serie-lease-generation controller) most-positive-fixnum)
             (error 'resource-exhausted :reason :serie-lease-generation))
           (incf (controllore-serie-lease-generation controller))
           (%check-owner controller (controllore-serie-lease-generation controller))
           (setf committed t)
           (controllore-serie-lease-generation controller))
      (unless committed (%release-owner controller thread)))))

;;; REQ: REQ-CON-002 REQ-AFF-004
(declaim (ftype (function (controllore-serie t) null) rilascia-controllore-serie))
(defun rilascia-controllore-serie (controller lease)
  "Pre: tratto finito, nessun effetto locale incompleto. Post: lease rilasciata.
INVALID-ARGUMENT per lease; INVARIANT-VIOLATION per effetto rimasto in volo."
  (%check-owner controller lease)
  (when (controllore-serie-effect-active controller)
    (%serie-invariant controller :serie-effect))
  (%release-owner controller sb-thread:*current-thread*))

;;; REQ: REQ-AFF-001 REQ-WAL-006
(declaim (ftype (function (controllore-serie) null) %require-healthy))
(defun %require-healthy (controller)
  "Pre: lease posseduta. Post: Serie e log sani prima di accettare/pubblicare.
IO-FAULT terminale; un guasto noto del log viene riflesso nel controller."
  (unless (eq (controllore-serie-state controller) :healthy)
    (error 'io-fault :reason :serie-faulted :operation :series))
  (unless (eq (stato-log (controllore-serie-log controller)) :open)
    (%mark-fault controller :serie)
    (error 'io-fault :reason :log-faulted :operation :series))
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (controllore-serie) null) %begin-effect))
(defun %begin-effect (controller)
  "Pre: lease e precondizioni validate. Post: proprietà locale dell'effetto acquisita.
INVARIANT-VIOLATION sulla rientranza; il cleanup rilascia questa risorsa."
  (when (controllore-serie-effect-active controller)
    (%serie-invariant controller :serie-effect))
  (%check-ring controller)
  (setf (controllore-serie-effect-active controller) t)
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (controllore-serie boolean) null) %end-effect))
(defun %end-effect (controller complete)
  "Pre: cleanup del proprietario dell'effetto. Post: risorsa locale rilasciata.
Uscita incompleta => FAULTED Archivio, riferimenti/token conservati; mai rollback
né soppressione della condizione o del trasferimento di controllo originale."
  (unless complete (%mark-fault controller :archive))
  (setf (controllore-serie-effect-active controller) nil)
  nil)

;;; REQ: REQ-AFF-008 REQ-CON-002
(declaim (ftype (function (controllore-serie index) index) %next-position))
(defun %next-position (controller position)
  "Pre: indice nel ring corrente. Post: successore modulo capacità, senza wrap intero.
INVARIANT-VIOLATION per indice/capacità incoerenti."
  (let ((capacity (length (controllore-serie-slots controller))))
    (unless (<= 1 capacity +max-serie-commits+) (%serie-invariant controller :serie-ring))
    (unless (< position capacity) (%serie-invariant controller :serie-ring))
    (if (= (1+ position) capacity) 0 (1+ position))))
