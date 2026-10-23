;;; OWNER: copie locali delle sole chiavi; tabelle del manifest sempre in sola lettura.
;;; SHARED: nessuno stato mutabile tra Serie; ordinamento esclusivo del percorso di apertura.
(in-package #:arcdocdb.recovery.checkpoint)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (hash-table (or null u64)) (simple-array (unsigned-byte 64) (*)))
                ordina-id-checkpoint))
(defun ordina-id-checkpoint (table extra)
  "Pre: tabella privata EQL immutabile e budget già verificati; EXTRA NIL oppure nuovo ID assente.
Post: copia u64 strettamente crescente delle chiavi, incluso EXTRA anche zero, senza mutare TABLE.
INVARIANT-VIOLATION per forma, conteggio o duplicato; cicli limitati alla cardinalità iniziale."
  (unless (eq (hash-table-test table) 'eql)
    (error 'invariant-violation :reason :recovery-checkpoint-table))
  (when (and extra (nth-value 1 (gethash extra table)))
    (error 'invariant-violation :reason :recovery-checkpoint-duplicate))
  (let* ((count (+ (hash-table-count table) (if extra 1 0)))
         (ids (make-array count :element-type '(unsigned-byte 64))) (pos 0))
    (loop for id being the hash-keys of table
          do (unless (and (< pos count) (typep id 'u64))
               (error 'invariant-violation :reason :recovery-checkpoint-key))
             (setf (aref ids pos) id) (incf pos))
    (when extra
      (unless (< pos count) (error 'invariant-violation :reason :recovery-checkpoint-count))
      (setf (aref ids pos) extra) (incf pos))
    (unless (= pos count) (error 'invariant-violation :reason :recovery-checkpoint-count))
    (setf ids (sort ids #'<))
    (loop for i from 1 below count
          do (unless (< (aref ids (1- i)) (aref ids i))
               (error 'invariant-violation :reason :recovery-checkpoint-order)))
    ids))
