;;; OWNER: builder costruisce dati privati; publisher possiede il gettone locale durante lo swap.
;;; SHARED: buffer non esportati; manifest posseduto, consultato soltanto tramite query.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-FOR-003 REQ-REC-001 REQ-AFF-008
(defstruct (checkpoint-control
             (:constructor %make-checkpoint-control (active bytes identity manifest version)) (:copier nil))
  "Pre: header, EDIT completo e SEAL verificati; manifest riferisce ACTIVE preparato.
Post: piano posseduto immutabile, senza I/O; nessuna API esporta il buffer.
Non attesta l'inventario CLOSED, l'allocatore degli ID o la decisione del catalogo."
  (active nil :type segmento-attivo-preparato :read-only t)
  (bytes #() :type octets :read-only t)
  (identity #() :type (simple-array (unsigned-byte 8) (#.+log-identity-bytes+)) :read-only t)
  (manifest nil :type arcdocdb.recovery.manifest::manifest :read-only t)
  (version 2 :type (member 1 2) :read-only t))

;;; REQ: REQ-AFF-001 REQ-REC-001 REQ-FOR-003
(defstruct (control-preparato
             (:constructor %make-control-preparato (log manifest active association directory end)) (:copier nil))
  "Pre: checkpoint scritto, sincronizzato, riletto uguale; parent sincronizzato.
Post: log/manifest, directory canonica e frontiera attesa, senza buffer del piano/scratch.
Il caller mantiene capacità e dipendenze fino al punto di atomicità previsto dal catalogo."
  (log nil :type log-io :read-only t)
  (manifest nil :type arcdocdb.recovery.manifest::manifest :read-only t)
  (active nil :type segmento-attivo-preparato :read-only t)
  (association nil :type associazione-file :read-only t)
  (directory nil :type file-io :read-only t)
  (end 0 :type index :read-only t)
  (publication-owner nil :type t)
  (publication-state :prepared :type (member :prepared :publishing :published :faulted))
  (rename-observed nil :type boolean))

;;; REQ: REQ-REC-001 REQ-AFF-001
(defstruct (control-pubblicato (:constructor %make-control-pubblicato (prepared)) (:copier nil))
  "Pre: wrapper privato prima dell'I/O, consegnato solo dopo rinomina verificata e fsync del parent.
Post: capacità di pubblicazione riuscita, senza vecchio FD o buffer; non chiude il recovery completo.
Nessuna API costruisce questo risultato da un nome o da un manifest non preparato."
  (prepared nil :type control-preparato :read-only t))

;;; REQ: REQ-AFF-008
(declaim (ftype (function (checkpoint-control) index) lunghezza-checkpoint-control))
(defun lunghezza-checkpoint-control (plan)
  "Pre: piano completo. Post: byte esatti di header/EDIT/SEAL, senza I/O o mutazione."
  (length (checkpoint-control-bytes plan)))

;;; REQ: REQ-REC-001
(declaim (ftype (function (checkpoint-control) arcdocdb.recovery.manifest::manifest)
                manifest-checkpoint-control))
(defun manifest-checkpoint-control (plan)
  "Pre: piano completo. Post: manifest posseduto da consultare tramite query scalari.
Nessuna esposizione di buffer o prova di durability del control log."
  (checkpoint-control-manifest plan))

;;; REQ: REQ-WAL-002 REQ-AFF-001
(declaim (ftype (function (control-preparato) log-io) log-control-preparato))
(defun log-control-preparato (prepared)
  "Pre: risultato completo e capacità ancora possedute. Post: unico log canonico CONTROL.
Non certifica salute corrente, rinomina o adozione nel server."
  (control-preparato-log prepared))

;;; REQ: REQ-REC-001
(declaim (ftype (function (control-preparato) arcdocdb.recovery.manifest::manifest)
                manifest-control-preparato))
(defun manifest-control-preparato (prepared)
  "Pre: risultato completo. Post: manifest validato del checkpoint riletto uguale.
Query in sola lettura; non verifica presenza o prefisso dei file CLOSED nominati."
  (control-preparato-manifest prepared))
