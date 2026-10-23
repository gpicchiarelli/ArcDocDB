;;; OWNER: visita sincrona nel compito I/O della Serie; nessun buffer o continuation conservato.
;;; SHARED: solo letture di prove readonly; l'effetto del visitor rimane privato fino al gate esterno.
(in-package #:arcdocdb.recovery.replay)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-IDX-006 REQ-AFF-008
(declaim (ftype (function (closed-recuperato index index index index index index) null)
                verifica-consumo-visita-closed))
(defun verifica-consumo-visita-closed (recovered pos records batches data delivered aborted)
  "Pre: attraversamento limitato terminato; conteggi privati, prova canonica stabile.
Post: dati entro i record, consegnati+abortiti esatti, frontiera e conteggi canonici raggiunti.
INVARIANT-VIOLATION per discordanza dopo gli eventuali effetti privati del visitor."
  (unless (<= data records) (error 'invariant-violation :reason :recovery-replay-data-count))
  (unless (and (= pos (closed-recuperato-prefix recovered)) (= records (closed-recuperato-records recovered))
               (= batches (closed-recuperato-batches recovered)) (= (+ delivered aborted) data))
    (error 'invariant-violation :reason :recovery-replay-consumption :offset pos))
  nil)

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-IDX-006 REQ-AFF-008
(declaim (ftype (function (closed-recuperato (or null workspace-active) octets function)
                         (values index index &optional)) attraversa-closed-per-visita))
(defun attraversa-closed-per-visita (recovered workspace scratch visitor)
  "Pre: intero prefisso e risoluzione verificati, nessuna mutazione/reentrata su scratch/prove dal visitor.
Post: tutti PUT/TOMBSTONE committed consegnati in ordine fisico; OUTCOME/SEAL esclusi, abortiti contati.
Ciclo esatto BATCHES+RECORDS e consumo finale obbligatorio; header riletti senza ripetere CRC dei body.
Errori/uscite del visitor propagati senza rollback; nessun risultato parziale autorizza pubblicazione."
  (let* ((prefix (closed-recuperato-prefix recovered))
         (frames (+ (closed-recuperato-batches recovered) (closed-recuperato-records recovered)))
         (pos +segment-header-bytes+) (records 0) (batches 0) (data 0) (delivered 0) (aborted 0))
    (unless (and (<= +segment-header-bytes+ prefix (length scratch))
                 (<= frames (floor (- prefix +segment-header-bytes+) +header-bytes+)))
      (error 'invariant-violation :reason :recovery-replay-frame-count))
    (loop repeat frames
          do (multiple-value-bind (next kind flags value-start)
                 (cornice-active-verificata scratch pos prefix (closed-recuperato-version recovered))
               (declare (ignore value-start)) ; range del valore verificato; nessun esito d'errore.
               (case kind
                 ((#.+put+ #.+tombstone+)
                  (multiple-value-bind (copied skipped)
                      (visita-dato-closed recovered workspace scratch pos next flags visitor)
                    (incf delivered copied) (incf aborted skipped))
                  (incf records) (incf data))
                 (#.+outcome+ (incf records))
                 (#.+seal+ (incf batches))
                 (otherwise (error 'invariant-violation :reason :recovery-replay-kind :offset pos)))
               (setf pos next)))
    (verifica-consumo-visita-closed recovered pos records batches data delivered aborted)
    (values delivered aborted)))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-IDX-006 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (closed-recuperato octets limiti-recovery-serie function)
                         (values index index &optional)) visita-record-closed-recuperato))
(defun visita-record-closed-recuperato (recovered scratch limits visitor)
  "Pre: prova CLOSED canonica e fonti congelate, scratch e visitor esclusivi nel pool I/O; ammissione chiusa.
Visitor sincrono sui soli dati committed, destinazioni private e bytes readonly prestati durante la chiamata.
Post: intero P riverificato PRIMA del primo callback, consegna PUT/TOMBSTONE in ordine e contatori esatti.
Prepared da OUTCOME/EDIT, mai dal log globale; zero/u64 preservati. Nessun file chiuso o modificato.
Condizioni/uscite originali propagate: scartare o invalidare il candidato incompleto, nessun retry implicito."
  (multiple-value-bind (current workspace) (rileggi-closed-per-visita recovered scratch limits)
    (multiple-value-bind (delivered aborted) (attraversa-closed-per-visita current workspace scratch visitor)
      (arcdocdb.io::esigi-aperto (closed-recuperato-input current) :input)
      (arcdocdb.io::esigi-aperto
       (arcdocdb.control::control-recuperato-input (closed-recuperato-control current)) :input)
      (values delivered aborted))))
