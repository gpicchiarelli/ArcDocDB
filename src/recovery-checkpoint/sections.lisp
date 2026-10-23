;;; OWNER: builder scrive soltanto sezioni private dopo la misura del workspace.
;;; SHARED: vecchie entry/esiti restano immutabili; nessuna pubblicazione o operazione I/O.
(in-package #:arcdocdb.recovery.checkpoint)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (arcdocdb.recovery.manifest::manifest-closed u64 octets index) index)
                scrivi-chiuso-checkpoint))
(defun scrivi-chiuso-checkpoint (entry id buffer start)
  "Pre: entry posseduta valida, BUFFER privato e budget autorizzati. Post: copia canonica CLOSED con esiti ordinati.
Range prima di scrivere, CSN zero conservato tramite presenza distinta; nessun array sorgente esportato.
Errori tipizzati propagati; un fallimento modifica solo sezioni private mai consegnate."
  (arcdocdb.recovery.manifest::check-closed-shape entry)
  (let* ((outcomes (arcdocdb.recovery.manifest::%closed-outcomes entry))
         (count (hash-table-count outcomes))
         (end (+ start +closed-fixed-bytes+ (* count +closure-outcome-bytes+))))
    (unless (typep count 'u32) (error 'invariant-violation :reason :recovery-checkpoint-outcome-count))
    (check-range buffer start end)
    (let ((ids (ordina-id-checkpoint outcomes nil)))
      (scrivi-u64 buffer start id)
      (scrivi-u64 buffer (+ start +closed-valid-bytes-offset+) (arcdocdb.recovery.manifest::%closed-valid-bytes entry))
      (scrivi-u32 buffer (+ start +closed-outcome-count-offset+) count)
      (loop for txid across ids for pos from (+ start +closed-fixed-bytes+) by +closure-outcome-bytes+
            do (multiple-value-bind (csn present) (gethash txid outcomes)
                 (unless (and present (typep csn 'u64))
                   (error 'invariant-violation :reason :recovery-checkpoint-outcome))
                 (scrivi-u64 buffer pos txid)
                 (scrivi-u64 buffer (+ pos (/ +closure-outcome-bytes+ 2)) csn))))
    end))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-TXM-007 REQ-FOR-003 REQ-AFF-018
(declaim (ftype (function (active-recuperato arcdocdb.recovery.manifest::manifest index) octets)
                codifica-chiusi-checkpoint))
(defun codifica-chiusi-checkpoint (recovered manifest size)
  "Pre: SIZE misurata su fonti congelate. Post: tutti i vecchi CLOSED più la chiusura ACTIVE, ordinati per ID.
Riusa il serializer ACTIVE per P ed esiti derivati; controlla avanzamento e consumo esatto.
INVARIANT-VIOLATION per fonte mutata/incoerente; nessun risultato parziale o buffer esterno modificato."
  (let* ((id (arcdocdb.recovery.active::id-active-recuperato recovered))
         (table (arcdocdb.recovery.manifest::%manifest-closed manifest))
         (ids (ordina-id-checkpoint table id))
         (buffer (make-array size :element-type '(unsigned-byte 8) :initial-element 0)) (pos 0))
    (loop for current across ids
          do (let ((next (if (= current id) (scrivi-chiusura-active recovered buffer pos)
                             (scrivi-chiuso-checkpoint
                              (the arcdocdb.recovery.manifest::manifest-closed (gethash current table))
                              current buffer pos))))
               (unless (< pos next (1+ size))
                 (error 'invariant-violation :reason :recovery-checkpoint-closed-progress))
               (setf pos next)))
    (unless (= pos size) (error 'invariant-violation :reason :recovery-checkpoint-closed-size))
    buffer))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-018
(declaim (ftype (function (arcdocdb.recovery.manifest::manifest index) octets) codifica-rimossi-checkpoint))
(defun codifica-rimossi-checkpoint (manifest size)
  "Pre: SIZE misurata, manifest congelato. Post: tutti e soli gli ID REMOVED in ordine u64, zero incluso.
Controlla dimensione e range prima delle scritture private; nessuna eliminazione o riconciliazione fisica.
INVARIANT-VIOLATION per conteggi discordanti, altri errori tipizzati propagati."
  (let* ((table (arcdocdb.recovery.manifest::%manifest-removed manifest))
         (ids (ordina-id-checkpoint table nil))
         (buffer (make-array size :element-type '(unsigned-byte 8) :initial-element 0)))
    (unless (= size (* (length ids) +removed-id-bytes+))
      (error 'invariant-violation :reason :recovery-checkpoint-removed-size))
    (check-range buffer 0 size)
    (loop for id across ids for pos from 0 by +removed-id-bytes+ do (scrivi-u64 buffer pos id))
    buffer))
