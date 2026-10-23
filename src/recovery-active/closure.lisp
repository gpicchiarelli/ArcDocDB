;;; OWNER: controller prepara una entry CLOSED in un buffer esclusivo, prima di qualunque I/O del checkpoint.
;;; SHARED: solo scalari e array privati immutabili; nessun CSN, file o stato tra Serie.
(in-package #:arcdocdb.recovery.active)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-FOR-001
(declaim (ftype (function (active-recuperato) u64) id-active-recuperato))
(defun id-active-recuperato (recovered)
  "Pre: header già verificato contro il manifest. Post: ID completo u64 del vecchio ACTIVE, senza I/O.
Nessuna identità da pathname o FD numerico."
  (let ((segment (active-recuperato-segment recovered)))
    (logior (ash (arcdocdb.get::segmento-get-high segment) 32) (arcdocdb.get::segmento-get-low segment))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (active-recuperato) index) lunghezza-chiusura-active))
(defun lunghezza-chiusura-active (recovered)
  "Pre: risultato completo. Post: byte esatti della entry CLOSED: parte fissa più coppie TXID/CSN.
Non include il count CLOSED o gli altri campi dell'EDIT; nessun buffer o modifica."
  (+ arcdocdb.storage.format::+closed-fixed-bytes+
     (* arcdocdb.storage.format::+closure-outcome-bytes+ (length (active-recuperato-ids recovered)))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (active-recuperato octets index) index) scrivi-chiusura-active))
(defun scrivi-chiusura-active (recovered buffer start)
  "Pre: risultato completo, BUFFER esclusivo. Post: entry CLOSED canonica con P e soli esiti derivati ordinati.
Alias con identità Serie, forma e range rifiutati prima di scrivere; ritorna fine, resto del buffer invariato.
Nessuna durability o punto di atomicità: prepara byte per il futuro checkpoint."
  (let* ((ids (active-recuperato-ids recovered)) (csns (active-recuperato-csns recovered))
         (count (length ids)) (end (+ start (lunghezza-chiusura-active recovered)))
         (view (arcdocdb.get::segmento-get-owner (active-recuperato-segment recovered))))
    (when (eq buffer (arcdocdb.get::vista-get-serie-identity view))
      (error 'invalid-argument :reason :active-recovery-closure-alias))
    (unless (and (= count (length csns)) (typep count 'u32))
      (error 'invariant-violation :reason :active-recovery-closure-shape))
    (check-range buffer start end)
    (scrivi-u64 buffer start (id-active-recuperato recovered))
    (scrivi-u64 buffer (+ start arcdocdb.storage.format::+closed-valid-bytes-offset+)
                (active-recuperato-prefix recovered))
    (scrivi-u32 buffer (+ start arcdocdb.storage.format::+closed-outcome-count-offset+) count)
    (loop for i below count
          for pos from (+ start arcdocdb.storage.format::+closed-fixed-bytes+)
            by arcdocdb.storage.format::+closure-outcome-bytes+
          do (scrivi-u64 buffer pos (aref ids i))
             (scrivi-u64 buffer (+ pos (/ arcdocdb.storage.format::+closure-outcome-bytes+ 2)) (aref csns i)))
    end))
