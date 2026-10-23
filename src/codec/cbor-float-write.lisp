;;;; Float MT7 minimi: preflight completo, parole raw e destinazione esclusiva.
;;; OWNER: buffer del chiamante fino al ritorno; cursori e parole locali.
;;; SHARED: nessuna scrittura, attesa o I/O tra Serie (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CBR-004 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t) (values index &optional)) check-float-cbor-range))
(defun check-float-cbor-range (buffer start end ai)
  "Pre: destinazione/range/AI esterni. Post: span index e AI25/26/27.
INVALID-ARGUMENT :cbor-range poi :cbor-float-ai, offset NIL, nessuna mutazione.
INVARIANT-VIOLATION per span incoerente; span vuoto ammesso."
  (unless (and (typep buffer 'octets) (typep start 'index) (typep end 'index)
               (<= start end (length buffer)))
    (error 'invalid-argument :reason :cbor-range))
  (unless (typep ai '(member 25 26 27))
    (error 'invalid-argument :reason :cbor-float-ai))
  (let ((span (- (the index end) (the index start))))
    (declare (type index span))
    (unless (= (+ start span) end)
      (error 'invariant-violation :reason :cbor-float-write-span))
    span))

;;; REQ: REQ-CBR-004 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function ((member 25 26 27) t t) (values u32 u32 &optional))
                check-float-cbor-words))
(defun check-float-cbor-words (ai high low)
  "Pre: AI verificato, parole esterne. Post: HIGH/LOW u32 coerenti con AI.
INVALID-ARGUMENT :cbor-float-high poi :cbor-float-low poi :cbor-float-words,
offset NIL e nessuna lettura/scrittura del buffer; caso interno inatteso viola invariante."
  (unless (typep high 'u32)
    (error 'invalid-argument :reason :cbor-float-high))
  (unless (typep low 'u32)
    (error 'invalid-argument :reason :cbor-float-low))
  (unless (case ai
            (25 (and (zerop high) (<= low #xffff)))
            (26 (zerop high))
            (27 t)
            (otherwise (error 'invariant-violation :reason :cbor-float-write-ai)))
    (error 'invalid-argument :reason :cbor-float-words))
  (values high low))

;;; REQ: REQ-CBR-004 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function ((member 25 26 27) u32 u32)
                         (values (member 25 26 27) u32 u32 (member 3 5 9) &optional))
                seleziona-float-cbor))
(defun seleziona-float-cbor (ai high low)
  "Pre: parole coerenti e AI25/26/27. Post: forma minima esatta e size3/5/9.
Riduce64 poi32, con guardie di coerenza prima/dopo; nessun arrotondamento.
INVARIANT-VIOLATION per parola alta incoerente; tutti i bit speciali preservati."
  (unless (or (= ai 27) (zerop high))
    (error 'invariant-violation :reason :cbor-float-selection-input))
  (let ((chosen-ai ai) (hi high) (lo low))
    (declare (type (member 25 26 27) chosen-ai) (type u32 hi lo))
    (when (and (= chosen-ai 27) (binary64-accorciabile-cbor-p hi lo))
      (setf lo (riduci-binary64-cbor hi lo) hi 0 chosen-ai 26))
    (when (and (= chosen-ai 26) (binary32-accorciabile-cbor-p lo))
      (setf lo (riduci-binary32-cbor lo) chosen-ai 25))
    (unless (or (= chosen-ai 27) (zerop hi))
      (error 'invariant-violation :reason :cbor-float-selection-output))
    (values chosen-ai hi lo (1+ (ash 1 (- chosen-ai 24))))))

;;; REQ: REQ-CBR-004 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t) (values index &optional)) scrivi-float-cbor-minimo))
(defun scrivi-float-cbor-minimo (buffer start end ai high low)
  "Pre: simple u8 esclusivo, span half-open e bit IEEE AI25/26/27 in HIGH/LOW.
Post: un solo NEXT, 3/5/9 byte BE minimi; fuori [START,NEXT) intero array invariato.
Preflight range/AI/HIGH/LOW/coerenza/capacita prima di scrivere; INVALID-ARGUMENT
oppure RESOURCE-EXHAUSTED :cbor-float-capacity, offset NIL e array intatto.
INVARIANT-VIOLATION interno senza rollback; proprietario fail-stop.
Nessun float/u64/AST, heap previsto, attesa, I/O o pubblicazione atomica/durevole;
budget e profilo documentale superiori, al massimo nove byte."
  (let ((span (check-float-cbor-range buffer start end ai)))
    (multiple-value-bind (hi lo) (check-float-cbor-words ai high low)
      (multiple-value-bind (chosen-ai chosen-hi chosen-lo size) (seleziona-float-cbor ai hi lo)
        (when (> size span)
          (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-float-capacity))
        (let* ((bytes (the octets buffer)) (begin (the index start)) (limit (the index end))
               (next (+ begin size)) (cursor (1+ begin)))
          (declare (type index next cursor))
          (unless (<= begin cursor next limit)
            (error 'invariant-violation :reason :cbor-float-write-target-span))
          (setf (aref bytes begin) (logior #xe0 chosen-ai))
          (when (= size 9)
            (setf cursor (scrivi-parola-header-cbor bytes cursor next chosen-hi 4)))
          (setf cursor (scrivi-parola-header-cbor bytes cursor next chosen-lo
                                                (if (= size 3) 2 4)))
          (unless (= cursor next)
            (error 'invariant-violation :reason :cbor-float-write-progress))
          (values next))))))
