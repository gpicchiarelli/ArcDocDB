;;; OWNER: controller associa una volta UUID autorevole e ambito canonico; copie possedute.
;;; SHARED: identità immutabile; binding runtime una sola volta via CAS, solo nel bootstrap.
(in-package #:arcdocdb.recovery.archive)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-TXM-005 REQ-AFF-008
(defstruct (archivio-recovery (:constructor %make-archivio-recovery (scope identity)) (:copier nil))
  "Pre: controller associa UUID autorevole e ambito dello stesso Archivio prima del recovery.
Post: legami immutabili e binding runtime inizialmente NIL; non certifica unicità del catalogo.
TYPE-ERROR per tipi invalidi; nessun accessor di array esportato."
  (scope nil :type ambito-get :read-only t)
  (identity #() :type (simple-array (unsigned-byte 8) (#.+log-identity-bytes+)) :read-only t)
  ;; Tipo opaco per evitare dipendenza circolare: il solo writer è ARCDOCDB.RUNTIME.
  ;; Nessun reset o accesso sul percorso delle operazioni delle Serie.
  (runtime nil :type t))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (ambito-get octets) archivio-recovery) crea-archivio-recovery))
(defun crea-archivio-recovery (scope identity)
  "Pre: bootstrap esclusivo, UUID canonico stabile, ambito GET del medesimo Archivio.
Post: copia posseduta dei sedici byte, senza alias con ID del caller o scratch futuri.
INVALID-ARGUMENT per lunghezza diversa; associazione iniziale garantita dal controller."
  (unless (= (length identity) +log-identity-bytes+)
    (error 'invalid-argument :reason :archive-recovery-identity))
  (%make-archivio-recovery scope (copy-seq identity)))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-FOR-003 REQ-AFF-008
(defstruct (decisioni-recuperate
             (:constructor %make-decisioni-recuperate (archive input table size prefix status version))
             (:copier nil))
  "Pre: stesso FD readonly letto fino a EOF attestato, header e intero prefisso DECISION verificati.
Post: risultato posseduto legato all'Archivio, senza alias allo scratch; nessuna tabella parziale.
Non misura EOF, certifica catalogo o salute futura; TYPE-ERROR per tipi invalidi."
  (archive nil :type archivio-recovery :read-only t)
  (input nil :type file-io :read-only t)
  (table nil :type arcdocdb.recovery.decisions::decision-table :read-only t)
  (size 0 :type index :read-only t)
  (prefix 0 :type index :read-only t)
  (status :complete :type (member :complete :tail) :read-only t)
  (version 2 :type (member 1 2) :read-only t))
