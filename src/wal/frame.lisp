;;; OWNER: writer esclusivo del lotto; sorgente immutabile durante preflight e copia.
;;; SHARED: nessuno stato fra Serie; cornice gia codificata dal worker, nessun I/O.
(in-package #:arcdocdb.wal)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (lotto index) null) verifica-capacita-cornice))
(defun verifica-capacita-cornice (lotto size)
  "Pre: dimensione attestata dal worker, writer esclusivo. Post: capienza e lifetime validi.
Solo metadati costanti; nessun accesso ai byte o CRC del body. Rifiuti prima degli effetti."
  (esigi-lotto lotto :open)
  (when (lotto-csn-registry lotto) (error 'invalid-argument :reason :lotto-csn-bound))
  (unless (<= (lotto-count lotto) (length (lotto-offsets lotto)))
    (error 'invariant-violation :reason :lotto-record-count))
  (when (or (= (lotto-count lotto) (length (lotto-offsets lotto)))
            (> (+ size +seal-total+) (- (length (lotto-buffer lotto)) (lotto-used lotto))))
    (error 'resource-exhausted :reason :lotto-capacity))
  nil)

;;; REQ: REQ-WAL-005 REQ-AFF-008 REQ-FOR-003
(declaim (ftype (function (t t t t) index) verifica-append-cornice))
(defun verifica-append-cornice (lotto buffer start end)
  "Pre: writer esclusivo, input immutabile. Post: una cornice completa del formato del lotto,
CRC/tipo validi, spazio per record e SEAL. Rifiuti tipizzati prima di qualsiasi effetto.
Non attesta CBOR, contratto o commit; scansione limitata a un record del formato."
  (unless (and (typep lotto 'lotto) (typep buffer 'octets) (typep start 'index) (typep end 'index)
               (<= start end (length buffer)) (not (eq buffer (lotto-buffer lotto))))
    (error 'invalid-argument :reason :lotto-frame-input))
  (esigi-lotto lotto :open)
  (when (lotto-csn-registry lotto) (error 'invalid-argument :reason :lotto-csn-bound))
  (multiple-value-bind (key-limit record-limit) (format-limits (lotto-version lotto))
    (declare (ignore key-limit)) ; verifica-cornice applica entrambi i limiti del formato.
    (when (> (- end start) record-limit) (error 'resource-exhausted :reason :lotto-frame-bytes)))
  (multiple-value-bind (next kind flags ks ke vs ve)
      (arcdocdb.record:verifica-cornice buffer start end :version (lotto-version lotto))
    (declare (ignore flags ks ke vs ve)) ; verificati dal decoder; qui conta il tipo ammesso dal log.
    (unless (and (= next end) (log-record-p (lotto-kind lotto) kind))
      (error 'invalid-argument :reason :lotto-frame-kind)))
  (verifica-capacita-cornice lotto (- end start))
  (- end start))

;;; REQ: REQ-WAL-005 REQ-AFF-008
(declaim (ftype (function (lotto octets index index) index) append-cornice-verificata))
(defun append-cornice-verificata (lotto buffer start end)
  "Pre: preflight completo sullo stesso lotto/sorgente immutabili, ownership esclusiva.
Post: cornice esatta aggiunta, ordinali/used aggiornati, spazio SEAL conservato.
Ingresso interno del ponte full text; errore/interruzione dopo avvio richiede fail-stop."
  (unless (and (eq :open (lotto-state lotto)) (< (lotto-count lotto) (length (lotto-offsets lotto)))
               (<= (+ (- end start) +seal-total+) (- (length (lotto-buffer lotto)) (lotto-used lotto))))
    (error 'invariant-violation :reason :lotto-frame-preflight))
  (let* ((position (lotto-used lotto)) (next (+ position (- end start))))
    (replace (lotto-buffer lotto) buffer :start1 position :end1 next :start2 start :end2 end)
    (setf (aref (lotto-offsets lotto) (lotto-count lotto)) position (lotto-used lotto) next)
    (incf (lotto-count lotto))
    (unless (<= (+ next +seal-total+) (length (lotto-buffer lotto)))
      (error 'invariant-violation :reason :lotto-seal-space))
    next))

;;; REQ: REQ-WAL-005 REQ-AFF-008 REQ-FOR-003
(declaim (ftype (function (t t t t) index) aggiungi-cornice))
(defun aggiungi-cornice (lotto buffer start end)
  "Pre: cornice immutabile, writer esclusivo. Post: append di un record con CRC verificati.
Prepara solo memoria; il punto durevole rimane il successivo SEAL scritto/sincronizzato.
Rifiuti ordinari prima della copia; non e una verifica di validita documentale."
  (verifica-append-cornice lotto buffer start end)
  (append-cornice-verificata lotto buffer start end))
