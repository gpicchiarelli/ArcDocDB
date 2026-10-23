;;; OWNER: effetto esclusivo della prenotazione/cancellazione; nessun reader della directory.
;;; SHARED: nessuno stato tra Serie; costo limitato a coppie u32, mai ai byte del documento.
(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text u32 index) null) verifica-posizione-inserimento-riga))
(defun verifica-posizione-inserimento-riga (pool row position)
  "Pre: lower-bound calcolato prima degli effetti. Post: spazio e vicini stretti.
Directory incoerente => pool FAULTED prima di spostare coppie; nessuna allocazione."
  (let ((count (riserve-full-text-row-count pool)) (rows (riserve-full-text-rows pool)))
    (unless (and (<= position count) (< count (length rows)))
      (errore-interno-riserve pool :fulltext-row-insert))
    (unless (and (or (zerop position) (< (aref rows (1- position)) row))
                 (or (= position count) (< row (aref rows position))))
      (errore-interno-riserve pool :fulltext-row-insert)))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text riserva-full-text index) null) inserisci-riga-riserva))
(defun inserisci-riga-riserva (pool slot position)
  "Pre: effetto esclusivo, lower-bound libero verificato prima della mutazione.
Post: entry univoca ordinata nello stesso pool, prima di completare adozione/costi.
Spostamento limitato alla capacita; incoerenza => FAULTED, nessun rollback."
  (let ((count (riserve-full-text-row-count pool)) (row (riserva-full-text-row slot))
        (rows (riserve-full-text-rows pool)) (slots (riserve-full-text-row-slots pool)))
    (unless (and (riserve-full-text-effect pool) (eq pool (riserva-full-text-pool slot))
                 (eq :copying (riserva-full-text-state slot)))
      (errore-interno-riserve pool :fulltext-row-insert))
    (verifica-posizione-inserimento-riga pool row position)
    (dotimes (offset (- count position))
      (let ((target (- count offset)))
        (setf (aref rows target) (aref rows (1- target)) (aref slots target) (aref slots (1- target)))))
    (setf (aref rows position) row (aref slots position) (riserva-full-text-position slot))
    (incf (riserve-full-text-row-count pool))
    (unless (eq slot (slot-riga-riserve pool position row)) (errore-interno-riserve pool :fulltext-row-insert))
    nil))

;;; REQ: REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (riserve-full-text riserva-full-text) null) rimuovi-riga-riserva))
(defun rimuovi-riga-riserva (pool slot)
  "Pre: effetto di cancellazione pre-append, slot COPYING/READY canonico.
Post: sola entry dello slot rimossa, trasferiti mai eliminati; tail azzerata.
Ordine e count preservati entro capacita; mapping incoerente => pool FAULTED."
  (unless (and (riserve-full-text-effect pool) (member (riserva-full-text-state slot) '(:copying :ready)))
    (errore-interno-riserve pool :fulltext-row-remove))
  (let* ((count (riserve-full-text-row-count pool)) (row (riserva-full-text-row slot))
         (position (posizione-riga-riserve pool row)) (rows (riserve-full-text-rows pool)) (slots (riserve-full-text-row-slots pool)))
    (unless (eq slot (slot-riga-riserve pool position row)) (errore-interno-riserve pool :fulltext-row-remove))
    (dotimes (offset (- count position 1))
      (let ((target (+ position offset)))
        (setf (aref rows target) (aref rows (1+ target)) (aref slots target) (aref slots (1+ target)))))
    (decf (riserve-full-text-row-count pool))
    (setf (aref rows (1- count)) 0 (aref slots (1- count)) 0)
    (unless (= (riserve-full-text-row-count pool) (1- count)) (errore-interno-riserve pool :fulltext-row-remove))
    nil))
