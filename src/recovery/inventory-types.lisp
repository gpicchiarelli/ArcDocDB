;;;; Descrittori e piani di riconciliazione dei nomi; nessun accesso al filesystem.
;;; OWNER: il chiamante possiede l'inventario; ogni piano possiede le proprie entry.
;;; SHARED: manifest e piani pubblicati immutabili; nessuna scrittura fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008
(defstruct (segment-file (:constructor %make-segment-file (id form)) (:conc-name %file-))
  "Pre: ID u64 e forma verificata dal chiamante. Post: descrittore immutabile di un nome.
Zero è un ID valido per CLOSED/REMOVED; i tipi sono controllati con safety3."
  (id 0 :type u64 :read-only t)
  (form :final :type (member :temporary :final) :read-only t))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (u64 (member :temporary :final))
                         (values segment-file &optional)) file-segmento))
(defun file-segmento (id forma)
  "Pre: identità completa u64 e nome interpretato come .seg.tmp o .seg dal chiamante.
Post: descrittore posseduto read-only; TYPE-ERROR per tipi invalidi, nessun parsing o I/O."
  (%make-segment-file id forma))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(defstruct (reconciliation-entry
            (:constructor %make-reconciliation-entry (id form action state))
            (:conc-name %re-))
  "Pre: un ID unico del piano, presenza e stato verificati. Post: decisione scalare immutabile.
I tipi runtime impediscono stati fuori dal contratto; nessuna prova di integrità dei contenuti."
  (id 0 :type u64 :read-only t)
  (form :absent :type (member :temporary :final :absent :both) :read-only t)
  (action :missing :type (member :use :rename :delete :anomaly :missing :conflict) :read-only t)
  (state :unknown :type (member :active :closed :removed :unknown) :read-only t))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-AFF-008 REQ-AFF-018
(defstruct (reconciliation-plan
            (:constructor %make-reconciliation-plan (entries health)) (:conc-name %plan-))
  "Pre: entry ordinate per ID u64 e possedute, stato aggregato verificato.
Post: piano read-only; nessun vettore dell'inventario o hash del manifest esposto.
I tipi safety3 sono sempre attivi; le query non eseguono azioni sul filesystem."
  (entries #() :type simple-vector :read-only t)
  (health :ready :type (member :ready :degraded :faulted) :read-only t))
