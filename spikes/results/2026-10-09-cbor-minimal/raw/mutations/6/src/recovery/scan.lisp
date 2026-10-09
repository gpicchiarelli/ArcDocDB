;;;; Prefisso contiguo e testimoni durevoli; ADR-0037, senza applicare record.
;;; OWNER: chiamante; buffer stabile per l'intera scansione e per l'uso del risultato.
;;; SHARED: nessuno stato mutabile, lock o scrittura condivisa tra Serie.
(in-package #:arcdocdb.recovery.scan)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-001 REQ-FOR-003
(defconstant +seal-record-bytes+ (+ +header-bytes+ +seal-bytes+))

;;; REQ: REQ-AFF-009 REQ-AFF-017
(define-condition log-corruption (corruption-detected)
  ((prefix-end :initarg :prefix-end :reader %corruption-prefix-end :type index)
   (witness-offset :initarg :witness-offset :reader %corruption-witness-offset :type u64)
   (durable-offset :initarg :durable-offset :reader %corruption-durable-offset :type u64)
   (first-reason :initarg :first-reason :reader %corruption-first-reason :type keyword))
  (:documentation "Pre: testimone SEAL integro e frontiera oltre il primo lotto invalido.
Post: conserva prefisso nel buffer, offset assoluti e motivo iniziale; nessun effetto
durevole. Il proprietario applica fail-stop senza modificare il file esistente."))

;;; REQ: REQ-AFF-009
(declaim (ftype (function (log-corruption) (values index &optional)) corruption-prefix-end)
         (ftype (function (log-corruption) (values u64 &optional)) corruption-witness-offset)
         (ftype (function (log-corruption) (values u64 &optional)) corruption-durable-offset)
         (ftype (function (log-corruption) (values keyword &optional)) corruption-first-reason))

;;; REQ: REQ-AFF-009
(defun corruption-prefix-end (condition)
  "Pre: CONDITION log-corruption. Post: indice del prefisso, nessuna modifica.
Una violazione dei tipi del contratto segnala TYPE-ERROR con safety 3."
  (the index (%corruption-prefix-end condition)))

;;; REQ: REQ-AFF-009
(defun corruption-witness-offset (condition)
  "Pre: CONDITION log-corruption. Post: offset u64 assoluto del testimone, invariato.
Una violazione dei tipi del contratto segnala TYPE-ERROR con safety 3."
  (the u64 (%corruption-witness-offset condition)))

;;; REQ: REQ-AFF-009
(defun corruption-durable-offset (condition)
  "Pre: CONDITION log-corruption. Post: frontiera u64 assoluta dichiarata, invariata.
Una violazione dei tipi del contratto segnala TYPE-ERROR con safety 3."
  (the u64 (%corruption-durable-offset condition)))

;;; REQ: REQ-AFF-009
(defun corruption-first-reason (condition)
  "Pre: CONDITION log-corruption. Post: keyword del primo errore, nessuna modifica.
Una violazione dei tipi del contratto segnala TYPE-ERROR con safety 3."
  (the keyword (%corruption-first-reason condition)))

;;; REQ: REQ-AFF-008 REQ-AFF-009 REQ-FOR-003
(declaim (ftype (function (octets integer integer u64 integer keyword u64 t
                                integer integer integer integer integer)
                         (values index &optional)) check-scan-arguments))
(defun check-scan-arguments (buffer start end file-id version log-kind file-offset
                            file-size max-bytes max-batches max-batch-records
                            max-batch-bytes max-search-bytes)
  "Pre: input tipizzati, EOF fisico stabile attestato dal chiamante.
Post: range, versione esplicita, identità, EOF u64 e budget coerenti verificati.
Segnala INVALID-ARGUMENT, UNSUPPORTED-FORMAT o RESOURCE-EXHAUSTED prima di scandire."
  (check-range buffer start end)
  (format-limits version)
  (case log-kind
    (:segment nil)
    ((:control :multiserie)
     (unless (zerop file-id)
       (error 'invalid-argument :reason :log-scan-arguments)))
    (otherwise (error 'invalid-argument :reason :log-kind)))
  (unless (and (typep max-bytes 'index) (typep max-batches 'index)
               (plusp max-batches) (typep max-batch-records 'u32)
               (plusp max-batch-records) (typep max-batch-bytes 'index)
               (>= max-batch-bytes +seal-record-bytes+)
               (typep max-search-bytes 'index)
               (typep (+ file-offset end) 'u64))
    (error 'invalid-argument :reason :log-scan-arguments))
  (unless (and (typep file-size 'u64) (= file-size (+ file-offset end)))
    (error 'invalid-argument :reason :incomplete-log-buffer))
  (when (> (- end start) max-bytes)
    (error 'resource-exhausted :reason :log-byte-budget :offset (+ file-offset start)))
  end)

;;; REQ: REQ-AFF-009 REQ-AFF-008 REQ-FOR-003
(declaim (ftype (function (octets index index u64 integer keyword u64 u32 index)
                         (values index u32 (or null keyword) &optional)) checked-batch))
(defun checked-batch (buffer start end file-id version log-kind file-offset
                      max-records max-bytes)
  "Pre: range non vuoto e budget verificati. Post: lotto integro con avanzamento,
oppure START, zero e motivo della sola CORRUPTION-DETECTED intercettata.
Propaga gli altri errori; nessun record applicato o byte modificato."
  (check-range buffer start end)
  (unless (< start end)
    (error 'invariant-violation :reason :scan-empty-batch :offset start))
  (handler-case
      (multiple-value-bind (next stamp durable count)
          (verifica-lotto buffer start end file-id :version version :log-kind log-kind
                          :file-offset file-offset :max-records max-records :max-bytes max-bytes)
        (unless (and (< start next) (<= next end) (<= count max-records)
                     (typep stamp 'u64) (<= durable (+ file-offset start)))
          (error 'invariant-violation :reason :scan-batch-result :offset start))
        (values next count nil))
    (corruption-detected (condition)
      (values start 0 (error-reason condition)))))

;;; REQ: REQ-AFF-009 REQ-FOR-001 REQ-FOR-003
(declaim (ftype (function (octets index index u64 integer u64 u64)
                         (values boolean u64 &optional)) seal-witness))
(defun seal-witness (buffer pos end file-id version file-offset records-start)
  "Pre: candidato di 56 byte interamente disponibile, offset assoluti verificati.
Post: vero e frontiera soltanto per SEAL integro del file, con posizioni plausibili.
CORRUPTION-DETECTED del candidato produce NIL, zero; altri errori propagati.
Non attesta il lotto del testimone: count e checksum non autorizzano replay."
  (check-range buffer pos (+ pos +seal-record-bytes+))
  (unless (<= (+ pos +seal-record-bytes+) end)
    (error 'invariant-violation :reason :scan-seal-range :offset pos))
  (unless (= (aref buffer (+ pos +type-offset+)) +seal+)
    (return-from seal-witness (values nil 0)))
  (handler-case
      (multiple-value-bind (next kind flags ks ke vs ve)
          (verifica-cornice buffer pos (+ pos +seal-record-bytes+) :version version)
        (unless (and (= next (+ pos +seal-record-bytes+)) (= kind +seal+)
                     (zerop flags) (= ks ke) (= vs (+ pos +header-bytes+))
                     (= (- ve vs) +seal-bytes+))
          (error 'invariant-violation :reason :scan-seal-result :offset pos))
        (let ((batch-start (leggi-u64 buffer (+ vs +seal-batch-start-offset+)))
              (durable (leggi-u64 buffer (+ vs +seal-durable-offset+))))
          (if (and (u64-equal-p buffer (+ vs +seal-file-id-offset+) file-id)
                   (<= records-start batch-start (+ file-offset pos))
                   (<= durable batch-start))
              (values t durable)
              (values nil 0))))
    (corruption-detected () (values nil 0))))

;;; REQ: REQ-AFF-009 REQ-AFF-008 REQ-AFF-017
(declaim (ftype (function (octets index index u64 integer u64 u64 keyword index) null)
                search-durable-witness))
(defun search-durable-witness (buffer prefix-end end file-id version file-offset
                               records-start first-reason max-search-bytes)
  "Pre: P inizio del lotto invalido, EOF completo e buffer stabile.
Post: NIL solo dopo ricerca completa di ogni posizione con 56 byte disponibili.
Segnala LOG-CORRUPTION per frontiera oltre P, RESOURCE-EXHAUSTED per ricerca incompleta.
Nessun salto tra candidati, neppure dopo un SEAL valido con frontiera non oltre P."
  (check-range buffer prefix-end end)
  (unless (<= records-start (+ file-offset prefix-end))
    (error 'invariant-violation :reason :scan-search-start :offset prefix-end))
  (let* ((positions (max 0 (1+ (- end prefix-end +seal-record-bytes+))))
         (limit (min positions max-search-bytes))
         (absolute-prefix (+ file-offset prefix-end)))
    (loop for delta below limit
          do (let ((pos (+ prefix-end delta)))
               (multiple-value-bind (valid durable)
                   (seal-witness buffer pos end file-id version file-offset records-start)
                 (when (and valid (> durable absolute-prefix))
                   (error 'log-corruption :reason :log-durable-corruption
                          :offset absolute-prefix :prefix-end prefix-end
                          :witness-offset (+ file-offset pos) :durable-offset durable
                          :first-reason first-reason)))))
    (when (< limit positions)
      (error 'resource-exhausted :reason :log-search-budget
             :offset (+ absolute-prefix limit))))
  nil)

;;; REQ: REQ-AFF-009 REQ-AFF-008 REQ-AFF-017 REQ-FOR-003
(declaim (ftype (function (octets index index u64 integer keyword u64
                                index u32 index index)
                         (values index (member :complete :tail) index index &optional))
                scan-prefix))
(defun scan-prefix (buffer start end file-id version log-kind file-offset
                    max-batches max-batch-records max-batch-bytes max-search-bytes)
  "Pre: range, EOF e budget verificati. Post: solo prefisso contiguo di lotti integri;
conteggi escludono il lotto fallito e ogni SEAL. Propaga corruzione durevole e budget.
Non rende visibile alcun dato; la classificazione TAIL richiede ricerca completa."
  (check-range buffer start end)
  (unless (plusp max-batches)
    (error 'invariant-violation :reason :scan-batch-limit :offset start))
  (let ((pos start) (batches 0) (records 0))
    (loop repeat max-batches
          do (when (= pos end)
               (return-from scan-prefix (values pos :complete batches records)))
             (multiple-value-bind (next count first-reason)
                 (checked-batch buffer pos end file-id version log-kind file-offset
                                max-batch-records max-batch-bytes)
               (when first-reason
                 (search-durable-witness buffer pos end file-id version file-offset
                                         (+ file-offset start) first-reason max-search-bytes)
                 (return-from scan-prefix (values pos :tail batches records)))
               (incf batches)
               (incf records count)
               (setf pos next)
               (unless (<= records (floor (- pos start) +header-bytes+))
                 (error 'invariant-violation :reason :scan-record-count :offset pos))))
    (if (= pos end)
        (values pos :complete batches records)
        (error 'resource-exhausted :reason :log-batch-budget :offset (+ file-offset pos)))))

;;; REQ: REQ-AFF-009 REQ-AFF-008 REQ-AFF-017 REQ-FOR-001 REQ-FOR-003
(declaim (ftype (function (octets integer integer u64
                                &key (:version integer) (:log-kind keyword)
                                (:file-offset u64) (:file-size t) (:max-bytes integer)
                                (:max-batches integer) (:max-batch-records integer)
                                (:max-batch-bytes integer) (:max-search-bytes integer))
                         (values index (member :complete :tail) index index &optional))
                scansiona-log))
(defun scansiona-log (buffer start end file-id
                      &key (version 0) (log-kind :segment) (file-offset 0) file-size
                           (max-bytes 67108864) (max-batches 65536)
                           (max-batch-records 65536) (max-batch-bytes 67108864)
                           (max-search-bytes 67108864))
  "Pre: buffer stabile fino a EOF fisico; FILE-SIZE u64 autorevole dal chiamante,
uguale a FILE-OFFSET+END; START primo record dopo header verificato o checkpoint.
Versione 1/2 esplicita anche per log vuoto; tutti i budget finiti.
Post: fine nel BUFFER, COMPLETE/TAIL, numero lotti e record esclusi SEAL; solo prefisso
contiguo verificato, senza replay, I/O, mutazioni o effetti durevoli (INV-A9).
Segnala errori tipizzati di argomenti, formato, budget o LOG-CORRUPTION con testimone.
Percorso di apertura: non promette assenza di allocazioni."
  (check-scan-arguments buffer start end file-id version log-kind file-offset file-size
                        max-bytes max-batches max-batch-records max-batch-bytes max-search-bytes)
  (scan-prefix buffer start end file-id version log-kind file-offset
               max-batches max-batch-records max-batch-bytes max-search-bytes))
