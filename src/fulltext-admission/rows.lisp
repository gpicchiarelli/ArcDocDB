;;; OWNER: writer sotto lease; directory privata, non condivisa con reader o altre Serie.
;;; SHARED: nessuno stato tra Serie; entry trasferite mai rimosse da questa API.
(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text u32) index) posizione-riga-riserve))
(defun posizione-riga-riserve (pool row)
  "Pre: pool verificato, directory ordinata privata, capacita <=1024.
Post: lower-bound in 0..count con al piu 11 confronti; non legge slot o body.
INVARIANT-VIOLATION => pool FAULTED se contatori o convergenza incoerenti."
  (let ((low 0) (high (riserve-full-text-row-count pool)) (rows (riserve-full-text-rows pool)))
    (unless (<= high (length rows) 1024) (errore-interno-riserve pool :fulltext-row-count))
    (dotimes (i 11)
      (when (= low high) (return))
      (let ((middle (floor (+ low high) 2)))
        (if (< (aref rows middle) row) (setf low (1+ middle)) (setf high middle))))
    (unless (<= 0 low high (riserve-full-text-row-count pool))
      (errore-interno-riserve pool :fulltext-row-search))
    (unless (= low high) (errore-interno-riserve pool :fulltext-row-search))
    low))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-CON-002
(declaim (ftype (function (riserve-full-text index u32) riserva-full-text) slot-riga-riserve))
(defun slot-riga-riserve (pool position row)
  "Pre: lower-bound corrispondente a ROW. Post: slot vivo canonico e stessa row/generation.
Non espone dati; mapping perso o slot cancellato => pool FAULTED prima del ritorno."
  (unless (and (< position (riserve-full-text-row-count pool))
               (= row (aref (riserve-full-text-rows pool) position)))
    (errore-interno-riserve pool :fulltext-row-entry))
  (let ((index (aref (riserve-full-text-row-slots pool) position)))
    (unless (< index (length (riserve-full-text-slots pool))) (errore-interno-riserve pool :fulltext-row-slot))
    (let ((slot (svref (riserve-full-text-slots pool) index)))
      (unless (and (typep slot 'riserva-full-text)
                   (= index (riserva-full-text-position slot)) (eq pool (riserva-full-text-pool slot))
                   (= row (riserva-full-text-row slot)) (plusp (riserva-full-text-generation slot))
                   (member (riserva-full-text-state slot) '(:copying :ready :transferred)))
        (errore-interno-riserve pool :fulltext-row-slot))
      slot)))

;;; REQ: REQ-SEC-003 REQ-SEC-004 REQ-SEC-006 REQ-CON-002
(declaim (ftype (function (t t t) (values (member :absent :pending :transferred) (or null riserva-full-text) index &optional))
                trova-riga-trasferita-full-text))
(defun trova-riga-trasferita-full-text (pool lease row)
  "Pre: lease del writer e row u32. Post: stato, slot trasferito/generation oppure NIL/0.
COPYING/READY restituiscono PENDING senza handle: il ponte PUT conserva ownership privata.
ABSENT non certifica uno snapshot. Nessuna allocazione, attesa, I/O o visibilita MVCC."
  (verifica-writer-riserve pool lease)
  (unless (typep row 'u32) (error 'invalid-argument :reason :fulltext-row-input))
  (let ((position (posizione-riga-riserve pool row)))
    (if (and (< position (riserve-full-text-row-count pool)) (= row (aref (riserve-full-text-rows pool) position)))
        (let ((slot (slot-riga-riserve pool position row)))
          (if (eq :transferred (riserva-full-text-state slot))
              (values :transferred slot (riserva-full-text-generation slot)) (values :pending nil 0)))
        (values :absent nil 0))))
