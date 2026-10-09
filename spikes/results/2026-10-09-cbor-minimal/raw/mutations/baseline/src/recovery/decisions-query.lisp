;;;; Interrogazioni scalari: nessun vettore della tabella viene esposto.
(in-package #:arcdocdb.recovery.decisions)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (decision-table) (values index &optional)) numero-decisioni))
(defun numero-decisioni (table)
  "Pre: TABLE ricostruita interamente. Post: numero dei TXID unici, nessuna modifica.
Violazioni dei tipi del contratto segnalano TYPE-ERROR con safety 3."
  (length (%table-entries table)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (decision-table u64) (values boolean index &optional)) find-decision-index))
(defun find-decision-index (table txid)
  "Pre: tabella privata ordinata con TXID unici. Post: presenza e indice, zero se assente.
Ricerca limitata a integer-length(N) passi; INVARIANT-VIOLATION se il limite non basta.
Nessuna modifica, I/O o allocazione dipendente da dati non verificati."
  (let* ((entries (%table-entries table)) (count (length entries)) (left 0) (right count))
    (loop repeat (integer-length count)
          while (< left right)
          do (let ((middle (+ left (floor (- right left) 2))))
               (unless (<= 0 left middle (1- right) (1- count))
                 (error 'invariant-violation :reason :decision-search-range))
               (let* ((entry (the decision-entry (aref entries middle)))
                      (actual (%entry-txid entry)))
                 (cond ((= txid actual) (return-from find-decision-index (values t middle)))
                       ((< txid actual) (setf right middle))
                       (t (setf left (1+ middle)))))))
    (when (< left right)
      (error 'invariant-violation :reason :decision-search-bound))
    (values nil 0)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008
(declaim (ftype (function (decision-table u64) (values boolean u64 u16 &optional)) trova-decisione))
(defun trova-decisione (table txid)
  "Pre: TABLE completa, TXID u64 opaco. Post: presenza, CSN e count, entrambi zero se assente.
Propaga errori tipizzati degli invarianti; nessun riferimento interno viene esposto."
  (multiple-value-bind (found position) (find-decision-index table txid)
    (if found
        (let ((entry (the decision-entry (aref (%table-entries table) position))))
          (check-entry-shape entry)
          (values t (%entry-csn entry) (%entry-count entry)))
        (values nil 0 0))))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (decision-entry octets index) boolean) participant-present-p))
(defun participant-present-p (entry serie-id start)
  "Pre: entry privata canonica, ID16 del chiamante disponibile e stabile.
Post: presenza esatta; ricerca limitata a integer-length(COUNT) passi.
INVALID-ARGUMENT per range, INVARIANT-VIOLATION per forma o limite interno errato."
  (check-entry-shape entry)
  (check-range serie-id start (+ start +participant-id-bytes+))
  (let ((participants (%entry-participants entry)) (left 0) (right (%entry-count entry)))
    (loop repeat (integer-length (%entry-count entry))
          while (< left right)
          do (let ((middle (+ left (floor (- right left) 2))))
               (case (compare-id16 participants (* middle +participant-id-bytes+) serie-id start)
                 (0 (return-from participant-present-p t))
                 (-1 (setf left (1+ middle)))
                 (1 (setf right middle))
                 (otherwise (error 'invariant-violation :reason :decision-participant-order)))))
    (when (< left right)
      (error 'invariant-violation :reason :decision-search-bound)))
  nil)

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (decision-table u64 octets integer integer) boolean)
                partecipante-decisione-p))
(defun partecipante-decisione-p (table txid serie-id start end)
  "Pre: TABLE completa e buffer ID della Serie stabile. Post: presenza per TXID e ID16 esatti.
Verifica il range e la lunghezza anche se TXID assente; nessuna modifica o riferimento interno.
INVALID-ARGUMENT per range o span diverso da 16 byte, con offset relativo al buffer ID."
  (check-range serie-id start end)
  (unless (= (- end start) +participant-id-bytes+)
    (error 'invalid-argument :reason :serie-id-length :offset start))
  (multiple-value-bind (found position) (find-decision-index table txid)
    (and found (participant-present-p (the decision-entry (aref (%table-entries table) position))
                                      serie-id start))))
