;;; OWNER: un registro snapshot per Archivio, legato al suo unico registro CSN.
;;; SHARED: metadati sotto mutex; salute solo verso FAULTED, anche dal confine Archivio senza attesa.
(in-package #:arcdocdb.mvcc)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-004 REQ-MVC-007 REQ-AFF-008
(defconstant +snapshot-free+ 0)
(defconstant +snapshot-waiting+ 1)
(defconstant +snapshot-active+ 2)
(defconstant +snapshot-closed+ 3)
(defconstant +snapshot-wait-expired+ 4)
(defconstant +snapshot-age-expired+ 5)

;;; REQ: REQ-MVC-007 REQ-AFF-008
(defstruct (registro-snapshot
            (:constructor %make-registro-snapshot
                (csns lifetime wait csns-array generations deadlines wait-deadlines states words mutex))
            (:copier nil))
  "Pre: array privati preallocati. Post: registro vuoto, soglia=MAX-U64.
WORDS[0]=ultima generazione, WORDS[1]=soglia. Generazione zero indica mutazione/non assegnato."
  (csns nil :type registro-csn :read-only t)
  (lifetime 1 :type u64 :read-only t) (wait 1 :type u64 :read-only t)
  (csns-array #() :type csn-words :read-only t)
  (generations #() :type csn-words :read-only t)
  (deadlines #() :type csn-words :read-only t)
  (wait-deadlines #() :type csn-words :read-only t)
  (states #() :type (simple-array (unsigned-byte 8) (*)) :read-only t)
  (words #() :type csn-words :read-only t)
  (mutex nil :type sb-thread:mutex :read-only t)
  (count 0 :type (integer 0 65536))
  (cursor 0 :type csn-slot) (sweep-cursor 0 :type csn-slot)
  (health :open :type (member :open :faulted)))

;;; REQ: REQ-MVC-004 REQ-MVC-007
(defstruct (contesto-snapshot (:constructor %make-contesto-snapshot (registry word)) (:copier nil))
  "Pre: contesto riutilizzabile, legato a un solo Archivio. Post: identità non assegnata.
WORD[0]=generazione, WORD[1]=CSN. Il consumatore conserva l'identità originale prima del riuso."
  (registry nil :type registro-snapshot :read-only t)
  (word #() :type csn-words :read-only t)
  (slot 0 :type csn-slot))

;;; REQ: REQ-MVC-004 REQ-MVC-007 REQ-AFF-008
(declaim (ftype (function (registro-csn integer integer integer) registro-snapshot)
                crea-registro-snapshot))
(defun crea-registro-snapshot (csns capacity lifetime-ticks wait-ticks)
  "Pre: una base monotona di tempo per tutte le chiamate; durate nelle stesse unità.
Post: K slot fissi, zero snapshot. INVALID-ARGUMENT prima di allocare per budget/intervalli.
Nessun clock globale o thread; il chiamante fornisce NOW dall'ambiente iniettabile."
  (unless (and (<= 1 capacity +max-csn-slots+)
               (<= 1 wait-ticks lifetime-ticks +max-csn+))
    (error 'invalid-argument :reason :snapshot-registry-configuration))
  (let ((words (make-array 2 :element-type '(unsigned-byte 64) :initial-element 0)))
    (setf (aref words 1) +max-csn+)
    (%make-registro-snapshot
     csns lifetime-ticks wait-ticks
     (make-array capacity :element-type '(unsigned-byte 64) :initial-element 0)
     (make-array capacity :element-type '(unsigned-byte 64) :initial-element 0)
     (make-array capacity :element-type '(unsigned-byte 64) :initial-element 0)
     (make-array capacity :element-type '(unsigned-byte 64) :initial-element 0)
     (make-array capacity :element-type '(unsigned-byte 8) :initial-element +snapshot-free+)
     words (sb-thread:make-mutex :name "ArcDocDB: snapshot Archivio"))))

;;; REQ: REQ-MVC-007 REQ-AFF-008
(declaim (ftype (function (registro-snapshot) contesto-snapshot) crea-contesto-snapshot))
(defun crea-contesto-snapshot (registry)
  "Pre: registro dell'Archivio. Post: contesto preallocato, senza slot o pin riservato.
La salute si verifica alla registrazione; nessun array viene esportato."
  (%make-contesto-snapshot registry
                          (make-array 2 :element-type '(unsigned-byte 64) :initial-element 0)))
