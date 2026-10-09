;;;; Verifica di un lotto in memoria; non decide se una coda sia recuperabile.
(in-package #:arcdocdb.record)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-003
(declaim (ftype (function (keyword u8) boolean) log-record-p))
(defun log-record-p (log-kind kind)
  "Pre: log-kind dichiarato. Post: tipo ammesso nel log prima del SEAL.
Segnala INVALID-ARGUMENT per un log sconosciuto."
  (case log-kind
    (:segment (not (null (member kind '(1 2 4)))))
    (:control (= kind +edit+))
    (:multiserie (= kind +decision+))
    (otherwise (error 'invalid-argument :reason :log-kind))))

;;; REQ: REQ-FOR-003
(declaim (ftype (function (octets index index u64 u64 u32 u32) (values u64 &optional))
                check-seal))
(defun check-seal (buffer value-start record-start file-id batch-start count checksum)
  "Pre: corpo SEAL già integro. Post: file, inizio, count e CRC coincidenti.
Segnala CORRUPTION-DETECTED se la prova non riguarda il lotto verificato."
  (let ((durable (leggi-u64 buffer (+ value-start +seal-durable-offset+))))
    (unless (and (= (leggi-u64 buffer (+ value-start +seal-file-id-offset+)) file-id)
                 (= (leggi-u64 buffer (+ value-start +seal-batch-start-offset+)) batch-start)
                 (<= durable batch-start)
                 (= (leggi-u32 buffer (+ value-start +seal-count-offset+)) count)
                 (= (leggi-u32 buffer (+ value-start +seal-checksum-offset+)) checksum))
      (error 'corruption-detected :reason :seal-mismatch :offset record-start))
    durable))

;;; REQ: REQ-FOR-003 REQ-LIM-003
(declaim (ftype (function (octets index index integer index)
                         (values index u8 u8 u64 index index index index &optional))
                verifica-record-nel-budget))
(defun verifica-record-nel-budget (buffer pos end version remaining)
  "Pre: range verificato, budget residuo non negativo. Post: record integro nel budget.
Controlla header e dimensione prima di scandire il body; RESOURCE-EXHAUSTED per budget,
CORRUPTION-DETECTED per cornice errata. Nessuna allocazione dipendente dalle lunghezze."
  (let ((next (checked-header buffer pos end version +max-document-bytes+)))
    (when (> (- next pos) remaining)
      (error 'resource-exhausted :reason :batch-byte-budget :offset pos))
    (verifica-record buffer pos next :version version)))

;;; REQ: REQ-FOR-003 REQ-AFF-002
(declaim (ftype (function (octets index index u64
                                &key (:version integer) (:log-kind keyword)
                                (:file-offset u64) (:max-records u32)
                                (:max-bytes index))
                         (values index u64 u64 u32 &optional)) verifica-lotto))
(defun verifica-lotto (buffer start end file-id
                      &key (version 2) (log-kind :segment) (file-offset 0)
                           (max-records 65536) (max-bytes 67108864))
  "Pre: range stabile; FILE-OFFSET posizione assoluta di buffer[0]; budget finiti.
Post: primo lotto interamente verificato, fine, stamp del SEAL, frontiera, count.
Segnala corruzione o budget; nessun record applicato, nessuna durability attestata.
Punto di atomicità rappresentato: SEAL; questa funzione è sola lettura."
  (check-range buffer start end)
  (log-record-p log-kind +seal+)
  (unless (and (plusp max-records) (>= max-bytes (+ +header-bytes+ +seal-bytes+))
               (<= (+ file-offset end) #xffffffffffffffff)
               (or (eq log-kind :segment) (zerop file-id)))
    (error 'invalid-argument :reason :batch-arguments))
  (let ((pos start) (count 0) (checksum 0) (stamp 0) (stamp-known nil))
    (loop repeat (1+ max-records)
          do (multiple-value-bind (next kind flags actual-stamp ks ke vs ve)
                 (verifica-record-nel-budget buffer pos end version
                                             (- max-bytes (- pos start)))
               (declare (ignore ks ke ve))
               (when (= kind +seal+)
                 (when (and stamp-known (/= stamp actual-stamp))
                   (error 'corruption-detected :reason :batch-stamp :offset pos))
                 (return-from verifica-lotto
                   (values next actual-stamp
                           (check-seal buffer vs pos file-id (+ file-offset start)
                                       count checksum) count)))
               (when (= count max-records)
                 (error 'resource-exhausted :reason :batch-record-budget :offset pos))
               (unless (log-record-p log-kind kind)
                 (error 'corruption-detected :reason :batch-record-type :offset pos))
               ;; OUTCOME e DECISION portano TXID, non il CSN del SEAL.
               (when (and (or (= kind +put+) (= kind +tombstone+) (= kind +edit+))
                          (not (logbitp 0 flags)))
                 (when (and stamp-known (/= stamp actual-stamp))
                   (error 'corruption-detected :reason :batch-stamp :offset pos))
                 (setf stamp actual-stamp stamp-known t))
               (setf checksum (crc32c buffer pos (+ pos +header-crc-bytes+) checksum)
                     pos next)
               (incf count)))
    (error 'invariant-violation :reason :batch-loop-bound :offset pos)))
