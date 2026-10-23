;;;; Prefisso CLOSED di un segmento compattato; nessun I/O, replay o classificazione TAIL.
;;; OWNER: chiamante; buffer stabile, identità e limite valido da fonte autorevole.
;;; SHARED: nessuna scrittura condivisa tra Serie, lock o contatore globale.
(in-package #:arcdocdb.storage.format)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-AFF-008
(declaim (ftype (function (octets integer octets integer integer) (values index &optional))
                check-compaction-arguments))
(defun check-compaction-arguments (buffer valid-bytes id-serie max-bytes max-records)
  "Pre: argomenti tipizzati. Post: limite autorevole e budget finiti validati anche sul vuoto.
INVALID-ARGUMENT per configurazione; RESOURCE-EXHAUSTED per byte oltre budget,
prima di verificare l'header. Nessun byte letto o modificato."
  (unless (and (typep valid-bytes 'index)
               (<= +segment-header-bytes+ valid-bytes +segment-max-bytes+)
               (<= valid-bytes (length buffer))
               (<= +segment-header-bytes+ max-bytes +segment-max-bytes+)
               (typep max-records 'index) (= (length id-serie) +serie-id-bytes+))
    (error 'invalid-argument :reason :compaction-arguments :offset 0))
  (check-range buffer 0 valid-bytes)
  (when (> valid-bytes max-bytes)
    (error 'resource-exhausted :reason :compaction-byte-budget :offset 0))
  (the index valid-bytes))

;;; REQ: REQ-FOR-003 REQ-CMP-009
(declaim (ftype (function (octets index index u16) (values index u8 &optional))
                verifica-record-compattato))
(defun verifica-record-compattato (buffer pos end version)
  "Pre: range stabile e versione dall'header. Post: cornice ordinaria PUT/TOMBSTONE,
fine crescente e tipo; non materializza lo stamp u64. Propaga errori del codec,
CORRUPTION-DETECTED per tipo/prepared, INVARIANT-VIOLATION per progresso impossibile."
  (multiple-value-bind (next kind flags ks ke vs ve)
      (verifica-cornice buffer pos end :version version)
    (declare (ignore ks ke vs ve))
    (unless (and (< pos next) (<= next end))
      (error 'invariant-violation :reason :compaction-progress :offset pos))
    (unless (or (= kind +put+) (= kind +tombstone+))
      (error 'corruption-detected :reason :compaction-record-kind :offset pos))
    (when (logtest flags +prepared+)
      (error 'corruption-detected :reason :compaction-prepared :offset pos))
    (values next kind)))

;;; REQ: REQ-FOR-003 REQ-CMP-009 REQ-AFF-008
(declaim (ftype (function (octets index index u16 index)
                         (values index index index index &optional)) scansiona-compattato))
(defun scansiona-compattato (buffer start end version max-records)
  "Pre: header verificato, confini autorevoli e budget validi. Post: fine esatta e conteggi,
solo dopo cornici contigue complete; coda oltre END ignorata. RESOURCE-EXHAUSTED
prima del record oltre budget; INVARIANT-VIOLATION per conteggi o limite interno."
  (check-range buffer start end)
  (let ((pos start) (count 0) (puts 0) (tombstones 0))
    (declare (type index pos count puts tombstones))
    (loop repeat (1+ (floor (- end start) +header-bytes+))
          do (when (= pos end)
               (return-from scansiona-compattato (values pos count puts tombstones)))
             (when (>= count max-records)
               (error 'resource-exhausted :reason :compaction-record-budget :offset pos))
             (multiple-value-bind (next kind) (verifica-record-compattato buffer pos end version)
               (if (= kind +put+) (incf puts) (incf tombstones))
               (incf count)
               (unless (and (= count (+ puts tombstones))
                            (<= count (floor (- next start) +header-bytes+)))
                 (error 'invariant-violation :reason :compaction-count :offset pos))
               (setf pos next)))
    (error 'invariant-violation :reason :compaction-loop-bound :offset start)))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-FOR-003 REQ-CMP-009 REQ-AFF-008
(declaim (ftype (function (octets integer octets u64
                                &key (:max-bytes integer) (:max-records integer))
                         (values index u16 index index index &optional))
                verifica-segmento-compattato))
(defun verifica-segmento-compattato (buffer valid-bytes id-serie segment-id
                                   &key (max-bytes 67108864) (max-records 65536))
  "Pre: BUFFER stabile dal byte zero, identità autorevoli, VALID-BYTES nel buffer.
Post: VALID-BYTES, versione, count totale/PUT/TOMBSTONE dopo verifica integrale;
solo origine compaction, CSN opachi, nessuna lettura della coda fisica o mutazione.
INVALID-ARGUMENT per configurazione/origine writer; errori tipizzati di header,
cornice, prepared e budget propagati. Nessuna semantica CBOR, visibilità o durability."
  (let ((end (check-compaction-arguments buffer valid-bytes id-serie max-bytes max-records)))
    (multiple-value-bind (start version origine created-at)
        (verifica-header-segmento buffer 0 end id-serie segment-id)
      (declare (ignore created-at))
      (unless (= origine +compaction-origin+)
        (error 'invalid-argument :reason :compaction-origin :offset 0))
      (multiple-value-bind (next count puts tombstones)
          (scansiona-compattato buffer start end version max-records)
        (unless (and (= next end) (= count (+ puts tombstones)))
          (error 'invariant-violation :reason :compaction-result :offset next))
        (values next version count puts tombstones)))))
