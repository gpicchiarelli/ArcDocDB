;;;; Scanner completo, preflight strutturale/cumulativo, poi fold del manifest.
;;; OWNER: una chiamata; workspace e risultato possiedono tutta la memoria derivata.
;;; SHARED: nessuna pubblicazione, applicazione o scrittura condivisa tra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (integer integer integer integer integer integer integer)
                         (values manifest-limits &optional)) checked-manifest-limits))
(defun checked-manifest-limits (edits segments outcomes closed removed per-edit bytes)
  "Pre: budget interi del chiamante. Post: conteggi cumulativi index, per EDIT u32, byte entro16MiB.
INVALID-ARGUMENT per configurazione invalida; zero è ammesso per tutti i budget."
  (unless (and (typep edits 'index) (typep segments 'index) (typep outcomes 'index))
    (error 'invalid-argument :reason :manifest-arguments))
  (unless (and (typep closed 'u32) (typep removed 'u32) (typep per-edit 'u32))
    (error 'invalid-argument :reason :manifest-arguments))
  (unless (and (typep bytes 'index) (<= bytes +metadata-max-bytes+))
    (error 'invalid-argument :reason :manifest-arguments))
  (%make-manifest-limits edits segments outcomes closed removed per-edit bytes))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets index index integer manifest-limits)
                         (values index (or null manifest-edit) &optional)) manifest-frame))
(defun manifest-frame (buffer pos end version limits)
  "Pre: record in prefisso sigillato e stabile. Post: fine e vista EDIT verificata, NIL per SEAL.
Propaga errori codec relativi al buffer; payload nel prefisso non diventa una nuova coda."
  (check-range buffer pos end)
  (unless (< pos end)
    (error 'invariant-violation :reason :manifest-frame-range :offset pos))
  (multiple-value-bind (next kind flags ks ke vs ve)
      (verifica-cornice buffer pos end :version version)
    (unless (and (< pos next) (<= next end) (= ks ke) (= next ve))
      (error 'invariant-violation :reason :manifest-control-frame :offset pos))
    (cond
      ((= kind +seal+)
       (unless (zerop flags)
         (error 'invariant-violation :reason :manifest-control-frame :offset pos))
       (values next nil))
      ((= kind +edit+)
       (multiple-value-bind (cs cc rs rc outcomes)
           (valida-valore-edit buffer vs ve flags :max-chiusi (%limits-closed-per-edit limits)
                              :max-rimossi (%limits-removed-per-edit limits)
                              :max-esiti (%limits-outcomes-per-edit limits)
                              :max-bytes (%limits-bytes limits))
         (unless (<= vs cs (- rs +count-bytes+) rs ve)
           (error 'invariant-violation :reason :manifest-payload-range :offset pos))
         (values next (%make-manifest-edit flags (leggi-u64 buffer (+ vs +edit-next-id-offset+))
                                           (leggi-u64 buffer (+ vs +edit-open-offset+))
                                           cs cc rs rc outcomes))))
      (t (error 'invariant-violation :reason :manifest-record-type :offset pos)))))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-008 REQ-AFF-009
(declaim (ftype (function (octets index index integer index index manifest-limits u64)
                         (values index index &optional)) preflight-manifest))
(defun preflight-manifest (buffer start end version frames edits limits file-offset)
  "Pre: prefisso e contatori autorevoli dello scanner. Post: payload validi e budget cumulativi.
Conta occorrenze fisiche: CLOSED+REMOVED+OPEN nonzero, e tutti gli esiti, anche duplicati.
RESOURCE-EXHAUSTED all'EDIT assoluto; errori codec conservano offset relativi al buffer.
Ciclo di FRAMES passi; nessuna entry CLOSED o copia esiti allocata in questo passaggio."
  (check-range buffer start end)
  (unless (<= edits frames (floor (- end start) +header-bytes+))
    (error 'invariant-violation :reason :manifest-frame-count :offset start))
  (let ((pos start) (count 0) (segments 0) (outcomes 0))
    (dotimes (i frames)
      (multiple-value-bind (next edit) (manifest-frame buffer pos end version limits)
        (when edit
          (let ((references (+ (%edit-closed-count edit) (%edit-removed-count edit)
                               (if (zerop (%edit-open-id edit)) 0 1)))
                (offset (+ file-offset pos)))
            (when (> (1+ count) (%limits-edits limits))
              (error 'resource-exhausted :reason :manifest-edit-budget :offset offset))
            (when (> references (- (%limits-segments limits) segments))
              (error 'resource-exhausted :reason :manifest-segment-budget :offset offset))
            (when (> (%edit-outcomes edit) (- (%limits-outcomes limits) outcomes))
              (error 'resource-exhausted :reason :manifest-outcome-budget :offset offset))
            (incf count)
            (incf segments references)
            (incf outcomes (%edit-outcomes edit))))
        (setf pos next)))
    (unless (and (= pos end) (= count edits))
      (error 'invariant-violation :reason :manifest-prefix-consumption :offset pos))
    (values segments outcomes)))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-STO-006 REQ-TXM-007 REQ-AFF-018
(declaim (ftype (function (octets index index integer index index manifest-limits u64 index index)
                         (values manifest &optional)) decode-manifest))
(defun decode-manifest (buffer start end version frames edits limits file-offset segments outcomes)
  "Pre: intero prefisso strutturale e budget già verificati, buffer stabile.
Post: fold completo posseduto; nessun alias all'input né risultato parziale esportato.
CORRUPTION-DETECTED per applicabilità; INVARIANT-VIOLATION per consumo incoerente."
  (check-range buffer start end)
  (unless (<= edits frames (floor (- end start) +header-bytes+))
    (error 'invariant-violation :reason :manifest-frame-count :offset start))
  (let ((pos start) (state nil) (count 0) (segments-read 0) (outcomes-read 0))
    (dotimes (i frames)
      (multiple-value-bind (next edit) (manifest-frame buffer pos end version limits)
        (when edit
          (let ((offset (+ file-offset pos)))
            (multiple-value-bind (closed maximum) (decode-edit-closed buffer edit offset)
              (multiple-value-bind (removed maximum) (decode-edit-removed buffer edit next maximum)
                (setf state (fold-manifest-edit state edit closed removed maximum offset)))))
          (incf count)
          (incf segments-read (+ (%edit-closed-count edit) (%edit-removed-count edit)
                                 (if (zerop (%edit-open-id edit)) 0 1)))
          (incf outcomes-read (%edit-outcomes edit)))
        (setf pos next)))
    (unless (and (= pos end) (= count edits) (= segments-read segments) (= outcomes-read outcomes))
      (error 'invariant-violation :reason :manifest-prefix-consumption :offset pos))
    (unless state
      (error 'corruption-detected :reason :manifest-missing-snapshot :offset (+ file-offset start)))
    (%make-manifest (%state-active state) (%state-next-id state)
                    (%state-closed state) (%state-removed state))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-FOR-003 REQ-STO-006 REQ-TXM-007
;;; REQ: REQ-AFF-008 REQ-AFF-009 REQ-AFF-017 REQ-AFF-018 REQ-VAL-001
(declaim (ftype (function (octets integer integer
                                &key (:version integer) (:file-offset u64) (:file-size t)
                                (:max-bytes integer) (:max-batches integer)
                                (:max-batch-records integer) (:max-batch-bytes integer)
                                (:max-search-bytes integer) (:max-edits integer)
                                (:max-segmenti integer) (:max-esiti integer)
                                (:max-chiusi-per-edit integer) (:max-rimossi-per-edit integer)
                                (:max-esiti-per-edit integer) (:max-metadata-bytes integer))
                         (values manifest index (member :complete :tail) &optional))
                ricostruisci-manifest))
(defun ricostruisci-manifest (buffer start end
                             &key (version 0) (file-offset 0) file-size
                                  (max-bytes 67108864) (max-batches 65536)
                                  (max-batch-records 65536) (max-batch-bytes 67108864)
                                  (max-search-bytes 67108864) (max-edits 65536)
                                  (max-segmenti 65536) (max-esiti 65536)
                                  (max-chiusi-per-edit 65536) (max-rimossi-per-edit 65536)
                                  (max-esiti-per-edit 65536) (max-metadata-bytes 16777216))
  "Pre: control log stabile fino a EOF attestato da FILE-SIZE, VERSION esplicita;
START dopo header verificato. Primo EDIT completo obbligatorio, poi solo delta.
Post: manifest posseduto, prefisso nel buffer, COMPLETE/TAIL; nessun I/O o buffer modificato.
Scanner dell'intera finestra prima di semantica e budget EDIT; poi preflight e fold tutto-o-niente.
Propaga errori tipizzati: applicabilità/cumulativi usano offset assoluti, codec offset nel buffer.
Percorso di apertura con allocazioni; stamp non ordinati, TXID/CSN u64 opachi."
  (let ((limits (checked-manifest-limits max-edits max-segmenti max-esiti max-chiusi-per-edit
                                       max-rimossi-per-edit max-esiti-per-edit max-metadata-bytes)))
    (multiple-value-bind (prefix status batches count)
        (scansiona-log buffer start end 0 :version version :log-kind :control
                      :file-offset file-offset :file-size file-size :max-bytes max-bytes
                      :max-batches max-batches :max-batch-records max-batch-records
                      :max-batch-bytes max-batch-bytes :max-search-bytes max-search-bytes)
      (let ((frames (+ batches count)))
        (multiple-value-bind (segments outcomes)
            (preflight-manifest buffer start prefix version frames count limits file-offset)
          (values (decode-manifest buffer start prefix version frames count limits file-offset
                                   segments outcomes)
                  prefix status))))))
