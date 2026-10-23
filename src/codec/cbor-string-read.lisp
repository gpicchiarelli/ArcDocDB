;;;; Vista readonly del primo payload MT2/3 minimo, senza copie.
;;; OWNER: buffer stabile del chiamante; cursori e parole locali.
;;; SHARED: sola lettura del buffer, nessuna attesa o scrittura tra Serie (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CBR-009 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t) (values index &optional)) check-input-string-cbor-read))
(defun check-input-string-cbor-read (buffer start end max-bytes)
  "Pre: argomenti esterni. Post: span verificato entro il budget dell'intera finestra.
INVALID-ARGUMENT per range, poi :cbor-byte-limit; RESOURCE-EXHAUSTED
:cbor-byte-budget, offset NIL, prima di leggere byte. Nessuna mutazione.
INVARIANT-VIOLATION per span oltre il limite interno di lavoro."
  (let ((span (check-span-string-cbor-write buffer start end :cbor-range)))
    (declare (type index span))
    (unless (and (typep max-bytes 'index) (<= max-bytes +cbor-scan-max-bytes+))
      (error 'invalid-argument :reason :cbor-byte-limit))
    (when (> span max-bytes)
      (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-byte-budget))
    (unless (<= span +cbor-scan-max-bytes+)
      (error 'invariant-violation :reason :cbor-string-read-span))
    span))

;;; REQ: REQ-CBR-009 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t &key (:max-bytes t))
                         (values (integer 2 3) index index &optional)) leggi-stringa-cbor-minima))
(defun leggi-stringa-cbor-minima (buffer start end &key (max-bytes +cbor-scan-max-bytes+))
  "Pre: simple u8 stabile e finestra verificati dal preflight, budget 0..16MiB.
Post: esattamente MAJOR, PAYLOAD-START, NEXT; START<PAYLOAD-START<=NEXT<=END.
MT2 opaco, MT3 UTF-8 valido; payload vuoto ammesso e coda non letta.
MAX-BYTES limita tutta la finestra, inclusa la coda. Nessuna copia o scratch.
Propaga INVALID-ARGUMENT, RESOURCE-EXHAUSTED, errori header minimo e UTF-8;
CORRUPTION-DETECTED :cbor-string-type a START, :cbor-truncated a END prima
dell'UTF-8; INVARIANT-VIOLATION per forma, conteggio o frontiere incoerenti.
Lavoro: testata fino a nove byte, UTF-8 entro il payload; nessuna attesa o I/O."
  (check-input-string-cbor-read buffer start end max-bytes)
  (let ((bytes (the octets buffer)) (begin (the index start)) (limit (the index end)))
    (multiple-value-bind (major ai high low payload-start form)
        (leggi-header-cbor-minimo bytes begin limit)
      (declare (ignore ai))
      (unless (eq form :argument)
        (error 'invariant-violation :reason :cbor-string-read-form :offset begin))
      (unless (typep major '(integer 2 3))
        (error 'corruption-detected :reason :cbor-string-type :offset begin))
      (unless (zerop high)
        (error 'corruption-detected :reason :cbor-truncated :offset limit))
      (when (> low (- limit payload-start))
        (error 'corruption-detected :reason :cbor-truncated :offset limit))
      (let ((next (+ payload-start low)))
        (declare (type index next))
        (when (= major 3)
          (let ((count (arcdocdb.utf8:verifica-utf8 bytes payload-start next :max-bytes low)))
            (unless (<= count low)
              (error 'invariant-violation :reason :cbor-string-read-count :offset payload-start))))
        (unless (< begin payload-start)
          (error 'invariant-violation :reason :cbor-string-read-progress :offset begin))
        (unless (<= payload-start next)
          (error 'invariant-violation :reason :cbor-string-read-payload :offset payload-start))
        (unless (<= next limit)
          (error 'invariant-violation :reason :cbor-string-read-range :offset next))
        (values major payload-start next)))))
