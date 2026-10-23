;;; OWNER: recovery usa una tabella completa e autorevole dell'Archivio, congelata per la chiamata.
;;; SHARED: sole query della tabella decisioni; esiti derivati privati, nessun CSN preso o pubblicato.
(in-package #:arcdocdb.recovery.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-TXM-005 REQ-TXM-007 REQ-REC-001
(declaim (ftype (function (workspace-active arcdocdb.recovery.decisions::decision-table octets u64) null)
                risolvi-txid-active))
(defun risolvi-txid-active (workspace decisions identity txid)
  "Pre: TXID prepared noto e tabella dell'Archivio completa. Post: OUTCOME, DECISION o presumed abort.
Una DECISION presente deve nominare questa Serie e concordare con l'eventuale OUTCOME.
CORRUPTION-DETECTED per partecipante/CSN incoerente; esiti da DECISION senza OUTCOME copiati nel workspace."
  (multiple-value-bind (local-csn local-present) (gethash txid (workspace-active-outcomes workspace))
    (multiple-value-bind (decision-present decision-csn participants) (trova-decisione decisions txid)
      (when decision-present
        (unless (and (>= participants 2) (partecipante-decisione-p decisions txid identity 0 (length identity)))
          (error 'corruption-detected :reason :active-recovery-participant))
        (when (and local-present (/= local-csn decision-csn))
          (error 'corruption-detected :reason :active-recovery-decision-conflict)))
      (cond
        (local-present (incf (workspace-active-local workspace)))
        (decision-present
         (setf (gethash txid (workspace-active-derived workspace)) decision-csn)
         (registra-csn-active workspace decision-csn))
        (t (incf (workspace-active-aborted workspace))))))
  nil)

;;; REQ: REQ-TXM-005 REQ-TXM-007 REQ-REC-001 REQ-AFF-008
(declaim (ftype (function (workspace-active arcdocdb.recovery.decisions::decision-table octets) null)
                risolvi-prepared-active))
(defun risolvi-prepared-active (workspace decisions identity)
  "Pre: workspace completo privato e tabella autorevole, ID della Serie canonico.
Post: ogni TXID prepared classificato esattamente una volta; solo esiti mancanti sul file da conservare.
Ciclo limitato ai TXID distinti già contati; zero è CSN presente, non assenza.
INVARIANT-VIOLATION per contatori già utilizzati o conteggi discordanti; corruzione propagata."
  (unless (and (zerop (workspace-active-local workspace)) (zerop (workspace-active-aborted workspace))
               (zerop (hash-table-count (workspace-active-derived workspace))))
    (error 'invariant-violation :reason :active-recovery-already-resolved))
  (loop for txid being the hash-keys of (workspace-active-prepared workspace)
        do (risolvi-txid-active workspace decisions identity txid))
  (unless (= (hash-table-count (workspace-active-prepared workspace))
             (+ (workspace-active-local workspace) (workspace-active-aborted workspace)
                (hash-table-count (workspace-active-derived workspace))))
    (error 'invariant-violation :reason :active-recovery-resolution-count))
  nil)

;;; REQ: REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (workspace-active) (values parole-esiti parole-esiti &optional))
                impacchetta-esiti-active))
(defun impacchetta-esiti-active (workspace)
  "Pre: risoluzione completa privata. Post: due array u64 posseduti, TXID crescenti unici e CSN corrispondenti.
SORT su vettore privato come nell'inventario, seguito da controllo d'ordine; nessuna tabella trattenuta.
Cicli limitati al numero di esiti derivati; RESOURCE-EXHAUSTED prima degli array se la entry supera il codec.
INVARIANT-VIOLATION per count/presenza/tipo discordanti."
  (let* ((table (workspace-active-derived workspace)) (count (hash-table-count table)) (used 0))
    (when (> (+ arcdocdb.storage.format::+closed-fixed-bytes+
                (* count arcdocdb.storage.format::+closure-outcome-bytes+))
             arcdocdb.storage.format::+metadata-max-bytes+)
      (error 'resource-exhausted :reason :active-recovery-closure-budget))
    (let ((ids (make-array count :element-type '(unsigned-byte 64) :initial-element 0))
          (csns (make-array count :element-type '(unsigned-byte 64) :initial-element 0)))
      (loop for txid being the hash-keys of table
            do (unless (< used count) (error 'invariant-violation :reason :active-recovery-pack-count))
               (setf (aref ids used) txid) (incf used))
      (unless (= used count) (error 'invariant-violation :reason :active-recovery-pack-count))
      (setf ids (sort ids #'<))
      (dotimes (i count)
        (when (and (plusp i) (>= (aref ids (1- i)) (aref ids i)))
          (error 'invariant-violation :reason :active-recovery-pack-order))
        (multiple-value-bind (csn present) (gethash (aref ids i) table)
          (unless (and present (typep csn 'u64))
            (error 'invariant-violation :reason :active-recovery-pack-value))
          (setf (aref csns i) csn)))
      (values ids csns))))
