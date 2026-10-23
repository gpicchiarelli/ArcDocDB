;;;; Testate MT0..6: larghezza minima, argomento in due u32, nessun payload.
;;; OWNER: destinazione esclusiva del chiamante fino al ritorno della funzione.
;;; SHARED: nessuna scrittura, attesa o I/O tra Serie (INV-P6); solo variabili locali.
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (u32 u32)
                         (values (integer 0 27) (member 1 2 3 5 9) &optional))
                seleziona-header-cbor))
(defun seleziona-header-cbor (high low)
  "Pre: argomento wire in parole u32. Post: AI e dimensione minima totale.
INVARIANT-VIOLATION per parole/larghezza incoerenti; nessun u64 ricomposto."
  (multiple-value-bind (ai size)
      (cond ((not (zerop high)) (values 27 9))
            ((< low 24) (values low 1))
            ((< low 256) (values 24 2))
            ((< low 65536) (values 25 3))
            (t (values 26 5)))
    (unless (if (zerop high) (< ai 27) (= ai 27))
      (error 'invariant-violation :reason :cbor-write-selection-words))
    (unless (= size (if (< ai 24) 1 (1+ (ash 1 (- ai 24)))))
      (error 'invariant-violation :reason :cbor-write-selection-size))
    (values ai size)))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index u32 (member 1 2 4))
                         (values index &optional)) scrivi-parola-header-cbor))
(defun scrivi-parola-header-cbor (buffer start end word width)
  "Pre: parola u32 e WIDTH 1/2/4 che la contiene; spazio gia verificato.
Post: WIDTH byte BE in [START,NEXT), NEXT crescente entro END.
INVARIANT-VIOLATION per confini, parola troppo larga o progresso; massimo quattro passi."
  (unless (<= start end (length buffer))
    (error 'invariant-violation :reason :cbor-write-word-range))
  (unless (and (<= width (- end start))
               (or (= width 4) (< word (ash 1 (* 8 width)))))
    (error 'invariant-violation :reason :cbor-write-word-capacity))
  (let ((next (+ start width)))
    (declare (type index next))
    (dotimes (i width)
      (setf (aref buffer (+ start i)) (ldb (byte 8 (* 8 (- width i 1))) word)))
    (unless (and (< start next) (<= next end))
      (error 'invariant-violation :reason :cbor-write-word-progress))
    next))

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t) (values index &optional))
                check-input-header-cbor-write))
(defun check-input-header-cbor-write (buffer start end major high low)
  "Pre: argomenti esterni non verificati. Post: END index, simple u8, MT0..6, u32.
INVALID-ARGUMENT :cbor-range/:cbor-write-major/:cbor-write-high/:cbor-write-low
nell'ordine indicato, offset NIL; nessun byte letto o scritto."
  (unless (and (typep buffer 'octets) (typep start 'index) (typep end 'index)
               (<= start end (length buffer)))
    (error 'invalid-argument :reason :cbor-range))
  (unless (typep major '(integer 0 6))
    (error 'invalid-argument :reason :cbor-write-major))
  (unless (typep high 'u32)
    (error 'invalid-argument :reason :cbor-write-high))
  (unless (typep low 'u32)
    (error 'invalid-argument :reason :cbor-write-low))
  end)

;;; REQ: REQ-CBR-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t) (values index &optional))
                scrivi-header-cbor-minimo))
(defun scrivi-header-cbor-minimo (buffer start end major high low)
  "Pre: destinazione simple u8 esclusiva, span half-open, MT0..6 e parole u32.
Post: esattamente NEXT, testata minima BE in [START,NEXT); resto immutato.
MT1 riceve l'argomento wire non negativo -1-n; nessun payload o limite documentale.
Preflight range/major/high/low/capacita prima di scrivere: INVALID-ARGUMENT
:cbor-range/:cbor-write-major/:cbor-write-high/:cbor-write-low oppure
RESOURCE-EXHAUSTED :cbor-write-capacity, tutti offset NIL e buffer invariato.
INVARIANT-VIOLATION interno senza rollback; nessuna pubblicazione durevole/atomica,
allocazione prevista, attesa, I/O o stato condiviso; al massimo nove byte."
  (check-input-header-cbor-write buffer start end major high low)
  (let ((bytes (the octets buffer)) (begin (the index start)) (limit (the index end))
        (mt (the (integer 0 6) major)) (hi (the u32 high)) (lo (the u32 low)))
    (multiple-value-bind (ai size) (seleziona-header-cbor hi lo)
      (when (> size (- limit begin))
        (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-write-capacity))
      (let ((next (+ begin size)) (cursor (1+ begin)))
        (declare (type index next cursor))
        (unless (<= begin cursor next limit)
          (error 'invariant-violation :reason :cbor-write-header-range))
        (setf (aref bytes begin) (logior (ash mt 5) ai))
        (when (= size 9)
          (setf cursor (scrivi-parola-header-cbor bytes cursor next hi 4)))
        (when (> size 1)
          (setf cursor (scrivi-parola-header-cbor bytes cursor next lo
                                                (if (= size 9) 4 (1- size)))))
        (unless (= cursor next)
          (error 'invariant-violation :reason :cbor-write-header-progress))
        next))))
