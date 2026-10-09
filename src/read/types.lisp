;;; OWNER: il controller costruisce un contesto per slot EBR; solo il worker lo modifica.
;;; SHARED: legami immutabili ai registri dello stesso Archivio, nessun contatore comune.
(in-package #:arcdocdb.read)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-MVC-005 REQ-AFF-008
(defconstant +word-generation+ 0)
(defconstant +word-snapshot-csn+ 1)
(defconstant +word-start-time+ 2)
(defconstant +word-confirmed-csn+ 3)
(deftype read-words () '(simple-array (unsigned-byte 64) (*)))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-MVC-004 REQ-AFF-004 REQ-AFF-008
(defstruct (contesto-lettura
            (:constructor %make-contesto-lettura (reader snapshots words)) (:copier nil))
  "Pre: reader esclusivo, registri dello stesso Archivio, quattro word private.
Post: inattivo, nessuno snapshot o risultato conservato. Non attraversa code o migrazioni.
FAULTED impedisce il riuso; il cleanup resta consentito dopo la fine del compito."
  (reader nil :type lettore-epoca :read-only t)
  (snapshots nil :type registro-snapshot :read-only t)
  (words #() :type (simple-array (unsigned-byte 64) (4)) :read-only t)
  (snapshot nil :type (or null contesto-snapshot))
  (state :idle :type (member :idle :entering :active :faulted)))

;;; REQ: REQ-CON-004 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (lettore-epoca registro-snapshot) contesto-lettura) crea-contesto-lettura))
(defun crea-contesto-lettura (reader snapshots)
  "Pre: controller assegna un solo contesto a READER e registri dello stesso Archivio.
Post: contesto e buffer preallocati prima dell'avvio dei pool; nessun pin o thread creato.
INVALID-ARGUMENT se il reader è già attivo. Capacità totale limitata dai worker del dominio EBR."
  (when (epoca-attiva-p reader) (error 'invalid-argument :reason :read-worker-busy))
  (%make-contesto-lettura reader snapshots
                        (make-array 4 :element-type '(unsigned-byte 64) :initial-element 0)))

;;; REQ: REQ-CON-004 REQ-AFF-004
(declaim (ftype (function (contesto-lettura) (member :idle :entering :active :faulted))
                stato-contesto-lettura))
(defun stato-contesto-lettura (context)
  "Pre: worker proprietario o controller dopo join. Post: stato locale, senza pin o mutex.
Non è un controllo concorrente del worker; nessuna risorsa esterna viene restituita."
  (contesto-lettura-state context))
