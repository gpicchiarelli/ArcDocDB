;;;; Applicabilità degli EDIT e fold locale dopo il preflight del prefisso intero.
;;; OWNER: workspace della chiamata; hash table possedute, pubblicate solo alla fine.
;;; SHARED: nessuna modifica a log, file, Serie o strutture condivise.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-STO-006 REQ-AFF-018
(declaim (ftype (function (u64 hash-table hash-table u64) null) check-edit-sections))
(defun check-edit-sections (open closed removed offset)
  "Pre: liste possedute canoniche. Post: OPEN, CLOSED e REMOVED disgiunti nell'EDIT.
CORRUPTION-DETECTED con offset assoluto; iterazione limitata al numero noto di CLOSED."
  (when (and (not (zerop open)) (or (gethash open closed) (gethash open removed)))
    (error 'corruption-detected :reason :manifest-section-conflict :offset offset))
  (loop for id being the hash-keys of closed
        do (when (gethash id removed)
             (error 'corruption-detected :reason :manifest-section-conflict :offset offset)))
  nil)

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-STO-006 REQ-AFF-018
(declaim (ftype (function (manifest-edit hash-table hash-table u64 u64)
                         (values manifest-state &optional)) initial-manifest-state))
(defun initial-manifest-state (edit closed removed maximum offset)
  "Pre: primo EDIT con sezioni disgiunte. Post: snapshot completo, ACTIVE nonzero e high-water.
CORRUPTION-DETECTED per snapshot assente, ACTIVE zero o NEXT-ID non maggiore di ogni ID."
  (unless (= (%edit-flags edit) +edit-complete+)
    (error 'corruption-detected :reason :manifest-missing-snapshot :offset offset))
  (when (zerop (%edit-open-id edit))
    (error 'corruption-detected :reason :manifest-active-id :offset offset))
  (unless (> (%edit-next-id edit) maximum)
    (error 'corruption-detected :reason :manifest-next-id :offset offset))
  (%make-manifest-state (%edit-open-id edit) (%edit-next-id edit) closed removed))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-017 REQ-AFF-018
(declaim (ftype (function (manifest-state u64 hash-table u64) null) check-active-rotation))
(defun check-active-rotation (state open closed offset)
  "Pre: delta con sezioni disgiunte. Post: nuovo ACTIVE e chiusura del precedente coincidono.
OPEN zero o uguale al corrente è invariato; riapertura di CLOSED/REMOVED vietata.
CORRUPTION-DETECTED con offset assoluto; nessun vincolo OPEN rispetto al high-water."
  (let ((changed (and (not (zerop open)) (/= open (%state-active state))))
        (closing (not (null (gethash (%state-active state) closed)))))
    (unless (eq changed closing)
      (error 'corruption-detected :reason :manifest-active-rotation :offset offset))
    (when (and changed (or (gethash open (%state-closed state))
                          (gethash open (%state-removed state))))
      (error 'corruption-detected :reason :manifest-reopen :offset offset)))
  nil)

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-AFF-018
(declaim (ftype (function (manifest-state hash-table u64) null) check-closed-additions))
(defun check-closed-additions (state closed offset)
  "Pre: delta disgiunto; CLOSED canonici. Post: nuovi output ammessi, CLOSED noti solo identici.
CORRUPTION-DETECTED per riattivazione REMOVED o lunghezza/insieme esiti discordante.
L'iterazione è limitata al numero noto di CLOSED nel delta."
  (loop for id being the hash-keys of closed using (hash-value entry)
        do (when (gethash id (%state-removed state))
             (error 'corruption-detected :reason :manifest-reopen :offset offset))
           (multiple-value-bind (previous present) (gethash id (%state-closed state))
             (when (and present (not (same-closed-p previous entry)))
               (error 'corruption-detected :reason :manifest-closed-conflict :offset offset))))
  nil)

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-018
(declaim (ftype (function (manifest-state hash-table u64) null) check-removed-additions))
(defun check-removed-additions (state removed offset)
  "Pre: delta disgiunto; REMOVED canonici. Post: nessuna rimozione ACTIVE o sconosciuta.
Rimozioni già registrate idempotenti; CORRUPTION-DETECTED con offset assoluto.
L'iterazione è limitata al numero noto di REMOVED nel delta."
  (loop for id being the hash-keys of removed
        do (when (= id (%state-active state))
             (error 'corruption-detected :reason :manifest-remove-active :offset offset))
           (unless (or (gethash id (%state-closed state)) (gethash id (%state-removed state)))
             (error 'corruption-detected :reason :manifest-remove-unknown :offset offset)))
  nil)

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-AFF-018
(declaim (ftype (function (manifest-state u64 hash-table hash-table u64) null) apply-manifest-delta))
(defun apply-manifest-delta (state open closed removed maximum)
  "Pre: intero delta applicabile verificato; tabelle del delta distinte da quelle dello stato.
Post: solo workspace locale aggiornato; high-water non decresce, 2^64 significa esaurimento.
INVARIANT-VIOLATION per workspace incoerente; cicli limitati ai conteggi delle liste."
  (when (or (eq closed (%state-closed state)) (eq removed (%state-removed state)))
    (error 'invariant-violation :reason :manifest-workspace-alias))
  (let ((previous-next (%state-next-id state)))
    (loop for id being the hash-keys of closed using (hash-value entry)
          do (setf (gethash id (%state-closed state)) entry))
    (loop for id being the hash-keys of removed
          do (remhash id (%state-closed state))
             (setf (gethash id (%state-removed state)) t))
    (unless (zerop open) (setf (%state-active state) open))
    (setf (%state-next-id state) (max previous-next (1+ maximum)))
    (unless (and (not (zerop (%state-active state))) (<= previous-next (%state-next-id state)))
      (error 'invariant-violation :reason :manifest-workspace-state)))
  nil)

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-STO-006 REQ-TXM-007 REQ-AFF-018
(declaim (ftype (function ((or null manifest-state) manifest-edit hash-table hash-table u64 u64)
                         (values manifest-state &optional)) fold-manifest-edit))
(defun fold-manifest-edit (state edit closed removed maximum offset)
  "Pre: payload e budget del prefisso verificati, liste possedute e canoniche.
Post: stato iniziale o delta applicato interamente; nessun risultato parziale esportato.
CORRUPTION-DETECTED per applicabilità; prima il primo/unico snapshot, poi transizioni."
  (check-edit-sections (%edit-open-id edit) closed removed offset)
  (if (null state)
      (initial-manifest-state edit closed removed maximum offset)
      (progn
        (when (= (%edit-flags edit) +edit-complete+)
          (error 'corruption-detected :reason :manifest-repeated-snapshot :offset offset))
        (check-active-rotation state (%edit-open-id edit) closed offset)
        (check-closed-additions state closed offset)
        (check-removed-additions state removed offset)
        (apply-manifest-delta state (%edit-open-id edit) closed removed maximum)
        state)))
