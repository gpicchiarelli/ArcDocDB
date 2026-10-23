;;;; Capacità readonly possedute dal recovery, mai esposte come vettore mutabile.
;;; OWNER: un compito I/O possiede il set e ne esegue il cleanup dopo l'ultimo reader.
;;; SHARED: child readonly prestati ai reader; nessun registro o lock fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-004
(define-condition recovery-sources-cleanup-error (arcdocdb.conditions:arcdocdb-error)
  ((primary :initarg :primary :reader recovery-sources-primary
            :type (or null arcdocdb.conditions:arcdocdb-error))
   (cleanup :initarg :cleanup :reader recovery-sources-cleanup :type arcdocdb.conditions:io-fault)
   (count :initarg :count :reader recovery-sources-cleanup-count :type (integer 1 *)))
  (:documentation "Cleanup completato con guasti: causa originale, primo IO-FAULT e numero totale."))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-008
(defstruct (recovery-source (:constructor %make-recovery-source (id state form name))
                            (:conc-name %rs-) (:copier nil))
  "Pre: riga viva verificata del piano. Post: nome e fatti privati, capacità assegnata una volta.
FILE/SIZE sono scritti soltanto dall'acquisitore prima della pubblicazione; safety3 attiva."
  (id 0 :type u64 :read-only t)
  (state :active :type (member :active :closed) :read-only t)
  (form :final :type (member :final :temporary) :read-only t)
  (name "" :type simple-base-string :read-only t)
  (file nil :type (or null arcdocdb.io:file-io))
  (size 0 :type index))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-008
(defstruct (recovery-sources (:constructor %make-recovery-sources (entries))
                             (:conc-name %rss-) (:copier nil))
  "Pre: entry possedute e nessun lettore durante acquisizione/close. Post: insieme a proprietario unico.
CLOSED passa a T prima del primo close e non torna NIL; nessun parent o manifest trattenuto."
  (entries #() :type simple-vector :read-only t)
  (closed nil :type boolean))
