;;; OWNER: costruttore scrive righe private una volta; prove temporanee ordinate.
;;; SHARED: nessuno stato dell'indice o del registro delle transazioni consultato.
(in-package #:arcdocdb.get.resolver)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-FOR-004 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (octets u32 u32 u8 resolver-words resolver-words index) null)
                copia-riga-resolver))
(defun copia-riga-resolver (buffer pos next flags proofs rows base)
  "Pre: PUT verificato, riga privata completa; prove ordinate e immutabili.
Post: offset/size/flag e CSN/prova, zero proof per ordinario o prepared senza esito.
Prepared senza esito resta irraggiungibile: non inventa abort o commit nell'indice.
CORRUPTION-DETECTED per esito precedente al PUT; INVARIANT-VIOLATION per range/forma."
  (unless (and (< pos next) (<= (+ base +row-words+) (length rows)))
    (error 'invariant-violation :reason :resolver-row-range))
  (let ((low (leggi-u32 buffer (+ pos +stamp-offset+)))
        (high (leggi-u32 buffer (+ pos +stamp-offset+ 4))))
    (setf (aref rows (+ base +row-offset+)) pos (aref rows (+ base +row-size+)) (- next pos)
          (aref rows (+ base +row-flags+)) flags (aref rows (+ base +row-proof+)) 0)
    (if (zerop (logand flags +prepared+))
        (setf (aref rows (+ base +row-csn-low+)) low (aref rows (+ base +row-csn-high+)) high)
        (multiple-value-bind (found proof) (trova-prova-resolver proofs high low)
          (when found
            (let ((offset (aref proofs (+ proof +proof-offset+))))
              (unless (<= next offset)
                (error 'corruption-detected :reason :resolver-outcome-before-put :offset offset))
              (setf (aref rows (+ base +row-proof+)) offset
                    (aref rows (+ base +row-csn-low+)) (aref proofs (+ proof +proof-csn-low+))
                    (aref rows (+ base +row-csn-high+)) (aref proofs (+ proof +proof-csn-high+))))))))
  nil)

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-AFF-008
(declaim (ftype (function (octets u32 (member 1 2) resolver-words resolver-words) null)
                copia-righe-resolver))
(defun copia-righe-resolver (buffer end version proofs rows)
  "Pre: prefisso stabile verificato, array privati dimensionati/azzerati, prove ordinate.
Post: righe PUT in ordine fisico stretto, solo parole copiate; nessun alias sorgente.
INVARIANT-VIOLATION per conteggio/progresso; errori codec e risoluzione propagati.
Scansione limitata dai byte; ogni lookup TXID ha al più 33 passi."
  (unless (zerop (mod (length rows) +row-words+))
    (error 'invariant-violation :reason :resolver-row-shape))
  (let ((pos +segment-header-bytes+) (used 0))
    (declare (type u32 pos) (type index used))
    (loop repeat (1+ (floor (- end +segment-header-bytes+) +header-bytes+))
          do (when (= pos end)
               (unless (= used (length rows)) (error 'invariant-violation :reason :resolver-row-count))
               (return-from copia-righe-resolver nil))
             (multiple-value-bind (next kind flags) (prossima-cornice-resolver buffer pos end version)
               (when (= kind +put+)
                 (copia-riga-resolver buffer pos next flags proofs rows used)
                 (incf used +row-words+))
               (setf pos next)))
    (error 'invariant-violation :reason :resolver-scan-bound)))
