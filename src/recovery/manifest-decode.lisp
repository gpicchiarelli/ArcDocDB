;;;; Copie possedute e coalescenza delle liste di un EDIT già verificato.
;;; OWNER: una ricostruzione; tutte le hash table sono locali e possedute.
;;; SHARED: nessuna scrittura tra Serie; le liste non espongono alias all'input.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-TXM-007 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (manifest-closed) null) check-closed-shape))
(defun check-closed-shape (entry)
  "Pre: entry CLOSED privata. Post: lunghezza nel formato e mappa indicizzata con EQL.
INVARIANT-VIOLATION per costruzione interna incoerente; nessuna modifica."
  (unless (<= +segment-header-bytes+ (%closed-valid-bytes entry) +segment-max-bytes+)
    (error 'invariant-violation :reason :manifest-closed-shape))
  (unless (eq (hash-table-test (%closed-outcomes entry)) 'eql)
    (error 'invariant-violation :reason :manifest-closed-shape))
  nil)

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (manifest-closed manifest-closed) boolean) same-closed-p))
(defun same-closed-p (left right)
  "Pre: entry private con mappe esiti canoniche. Post: lunghezza e insieme TXID/CSN identici.
INVARIANT-VIOLATION per forma interna; confronto limitato al numero noto di esiti."
  (check-closed-shape left)
  (check-closed-shape right)
  (and (= (%closed-valid-bytes left) (%closed-valid-bytes right))
       (= (hash-table-count (%closed-outcomes left)) (hash-table-count (%closed-outcomes right)))
       (loop for txid being the hash-keys of (%closed-outcomes left) using (hash-value csn)
             always (multiple-value-bind (other present) (gethash txid (%closed-outcomes right))
                      (and present (= csn other))))))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (octets index index u32 u64)
                         (values hash-table index &optional)) decode-closure-outcomes))
(defun decode-closure-outcomes (buffer start end count offset)
  "Pre: COUNT coppie TXID/CSN verificate nel payload. Post: mappa posseduta, fine delle coppie.
Duplicati identici coalescono; CORRUPTION-DETECTED al record assoluto per CSN discordanti.
Zero e tutti i bit u64 sono significativi; ciclo limitato da COUNT e dai byte disponibili."
  (check-range buffer start end)
  (unless (<= count (floor (- end start) +closure-outcome-bytes+))
    (error 'invariant-violation :reason :manifest-outcome-range :offset start))
  (let ((result (make-hash-table :test 'eql)) (pos start))
    (dotimes (i count)
      (let ((txid (leggi-u64 buffer pos))
            (csn (leggi-u64 buffer (+ pos (/ +closure-outcome-bytes+ 2)))))
        (multiple-value-bind (previous present) (gethash txid result)
          (when (and present (/= previous csn))
            (error 'corruption-detected :reason :manifest-outcome-conflict :offset offset))
          (setf (gethash txid result) csn)))
      (incf pos +closure-outcome-bytes+))
    (unless (and (= pos (+ start (* count +closure-outcome-bytes+)))
                 (<= (hash-table-count result) count))
      (error 'invariant-violation :reason :manifest-outcome-count :offset start))
    (values result pos)))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (octets manifest-edit u64)
                         (values hash-table u64 &optional)) decode-edit-closed))
(defun decode-edit-closed (buffer edit offset)
  "Pre: EDIT strutturalmente valido e budget già verificati. Post: CLOSED posseduti e massimo ID.
CORRUPTION-DETECTED se duplicati dello stesso ID differiscono in lunghezza o insieme esiti.
Il ciclo ha CLOSED-COUNT iterazioni e il consumo finale è controllato."
  (let ((start (%edit-closed-start edit)) (end (- (%edit-removed-start edit) +count-bytes+))
        (result (make-hash-table :test 'eql)) (maximum (%edit-open-id edit)))
    (check-range buffer start end)
    (let ((pos start))
      (dotimes (i (%edit-closed-count edit))
        (unless (<= (+ pos +closed-fixed-bytes+) end)
          (error 'invariant-violation :reason :manifest-closed-range :offset pos))
        (let ((id (leggi-u64 buffer pos))
              (valid (leggi-u64 buffer (+ pos +closed-valid-bytes-offset+)))
              (count (leggi-u32 buffer (+ pos +closed-outcome-count-offset+))))
          (multiple-value-bind (outcomes next)
              (decode-closure-outcomes buffer (+ pos +closed-fixed-bytes+) end count offset)
            (let ((entry (%make-manifest-closed valid outcomes)))
              (multiple-value-bind (previous present) (gethash id result)
                (when (and present (not (same-closed-p previous entry)))
                  (error 'corruption-detected :reason :manifest-closed-conflict :offset offset))
                (unless present (setf (gethash id result) entry))))
            (setf pos next maximum (max maximum id)))))
      (unless (and (= pos end) (<= (hash-table-count result) (%edit-closed-count edit)))
        (error 'invariant-violation :reason :manifest-closed-count :offset start)))
    (values result maximum)))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (octets manifest-edit index u64)
                         (values hash-table u64 &optional)) decode-edit-removed))
(defun decode-edit-removed (buffer edit end maximum)
  "Pre: span REMOVED verificato. Post: mappa posseduta idempotente e massimo ID nominato.
INVARIANT-VIOLATION per consumo incoerente; ciclo limitato da REMOVED-COUNT."
  (let ((start (%edit-removed-start edit)) (result (make-hash-table :test 'eql)))
    (check-range buffer start end)
    (unless (= (- end start) (* (%edit-removed-count edit) +removed-id-bytes+))
      (error 'invariant-violation :reason :manifest-removed-range :offset start))
    (dotimes (i (%edit-removed-count edit))
      (let ((id (leggi-u64 buffer (+ start (* i +removed-id-bytes+)))))
        (setf (gethash id result) t maximum (max maximum id))))
    (unless (<= (hash-table-count result) (%edit-removed-count edit))
      (error 'invariant-violation :reason :manifest-removed-count :offset start))
    (values result maximum)))
