;;; OWNER: writer possiede il lotto SEALED prima dell'adozione/dispatch; copia solo metadati.
;;; SHARED: nessun indice/FD modificato; la verifica in memoria non prova write o fsync.
(in-package #:arcdocdb.get.resolver)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-FOR-003 REQ-FOR-004 REQ-AFF-008
(declaim (ftype (function (octets u32 (member 1 2) u32) u32) conta-put-attivi))
(defun conta-put-attivi (buffer end version records)
  "Pre: lotto interamente verificato/stabile, count SEAL noto. Post: numero PUT ordinari.
Prepared/OUTCOME validi sono rifiutati esplicitamente come integrazione non ancora supportata.
Al più records+1 header; RESOURCE/INVALID/INVARIANT propagati, nessuna copia del valore."
  (let ((pos 0) (puts 0))
    (declare (type u32 pos puts))
    (dotimes (i (1+ records))
      (multiple-value-bind (next kind flags) (prossima-cornice-resolver buffer pos end version)
        (when (logtest flags +prepared+)
          (error 'invalid-argument :reason :active-prepared-unsupported))
        (case kind
          (#.+put+ (incf puts)) (#.+tombstone+ nil)
          (#.+outcome+ (error 'invalid-argument :reason :active-outcome-unsupported))
          (#.+seal+
           (unless (and (= i records) (= next end))
             (error 'invariant-violation :reason :active-seal-position))
           (return-from conta-put-attivi puts))
          (otherwise (error 'invariant-violation :reason :active-frame-kind)))
        (setf pos next)))
    (error 'invariant-violation :reason :active-scan-bound)))

;;; REQ: REQ-WAL-005 REQ-FOR-003 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (sorgente-get-attiva lotto) u32) verifica-lotto-attivo))
(defun verifica-lotto-attivo (source batch)
  "Pre: lease e token già controllati, lotto sealed esclusivo. Post: CRC/SEAL/CSN esatti e PUT contati.
Legge soltanto il nuovo lotto: non rilegge l'ACTIVE e non assume EOF o durability.
Errori tipizzati prima dell'adozione; i byte non vengono trattenuti nel risultato."
  (verifica-ritiro-lotto batch)
  (let* ((segment (sorgente-get-attiva-segment source)) (size (lunghezza-lotto batch))
         (start (inizio-lotto batch)) (buffer (arcdocdb.wal::lotto-buffer batch)))
    (unless (and (= (arcdocdb.wal::lotto-file-id batch) (segmento-get-low segment))
                 (= (arcdocdb.wal::lotto-version batch) (segmento-get-version segment)))
      (error 'invalid-argument :reason :active-batch-identity))
    (unless (<= +segment-header-bytes+ start (- +segment-max-bytes+ size))
      (error 'resource-exhausted :reason :active-segment-budget))
    (when (> size (sorgente-get-attiva-batch-bytes source))
      (error 'resource-exhausted :reason :active-batch-byte-budget))
    (multiple-value-bind (next stamp durable count)
        (verifica-lotto buffer 0 size (segmento-get-low segment) :version (segmento-get-version segment)
                        :file-offset start :max-records (sorgente-get-attiva-batch-records source)
                        :max-bytes (sorgente-get-attiva-batch-bytes source))
      (unless (and (= next size) (= count (arcdocdb.wal::lotto-count batch)) (<= durable start))
        (error 'invariant-violation :reason :active-batch-result))
      (multiple-value-bind (slot high low) (leggi-csn-lotto batch)
        (declare (ignore slot)) ; identità del token già verificata dal controller, non un esito.
        (unless (and (= high (ldb (byte 32 32) stamp)) (= low (ldb (byte 32 0) stamp)))
          (error 'invariant-violation :reason :active-batch-csn)))
      (conta-put-attivi buffer size (segmento-get-version segment) count))))

;;; REQ: REQ-IDX-001 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (sorgente-get-attiva lotto resolver-words) null) copia-put-attivi))
(defun copia-put-attivi (source batch rows)
  "Pre: lotto ordinario già verificato, buffer stabile, righe private esattamente dimensionate.
Post: offset assoluti/size/flag/CSN copiati, proof zero; nessun riferimento a byte/evento riusabili.
Al più count+1 header; INVARIANT-VIOLATION per count/range, nessuna pubblicazione parziale."
  (unless (zerop (mod (length rows) +row-words+))
    (error 'invariant-violation :reason :active-row-shape))
  (let ((pos 0) (used 0) (buffer (arcdocdb.wal::lotto-buffer batch))
        (end (lunghezza-lotto batch)) (start (inizio-lotto batch))
        (version (segmento-get-version (sorgente-get-attiva-segment source))))
    (declare (type u32 pos) (type index used))
    (loop repeat (1+ (arcdocdb.wal::lotto-count batch))
          do (multiple-value-bind (next kind flags) (prossima-cornice-resolver buffer pos end version)
               (when (= kind +seal+)
                 (unless (and (= next end) (= used (length rows)))
                   (error 'invariant-violation :reason :active-row-count))
                 (return-from copia-put-attivi nil))
               (when (= kind +put+)
                 (unless (<= (+ used +row-words+) (length rows))
                   (error 'invariant-violation :reason :active-row-count))
                 (setf (aref rows (+ used +row-offset+)) (+ start pos)
                       (aref rows (+ used +row-size+)) (- next pos)
                       (aref rows (+ used +row-flags+)) flags
                       (aref rows (+ used +row-csn-low+)) (leggi-u32 buffer (+ pos +stamp-offset+))
                       (aref rows (+ used +row-csn-high+)) (leggi-u32 buffer (+ pos +stamp-offset+ 4)))
                 (incf used +row-words+))
               (setf pos next)))
    (error 'invariant-violation :reason :active-scan-bound)))
