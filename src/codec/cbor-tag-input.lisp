;;;; Preflight MT6: contenuto singolo e budget completo prima di ogni effetto.
;;; OWNER: destinazione/scratch esclusivi; sorgente stabile fino al ritorno.
;;; SHARED: sola lettura tra worker; nessuna scrittura, attesa o I/O (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CBR-007 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets octets t) (values null &optional)) check-spazio-tag-cbor))
(defun check-spazio-tag-cbor (buffer source space)
  "Pre: array verificati, SPACE esterno. Post: scratch separato dai dati.
INVALID-ARGUMENT :cbor-workspace o :cbor-tag-workspace-alias, offset NIL.
Nessuna lettura di contenuto, reset o mutazione degli array."
  (unless (typep space 'spazio-cbor)
    (error 'invalid-argument :reason :cbor-workspace))
  (when (or (eq buffer (spazio-cbor-kinds space)) (eq source (spazio-cbor-kinds space)))
    (error 'invalid-argument :reason :cbor-tag-workspace-alias))
  nil)

;;; REQ: REQ-CBR-007 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (index index index u32 u32 index)
                         (values (member 1 2 3 5 9) index &optional)) dimensioni-tag-cbor))
(defun dimensioni-tag-cbor (start end span high low max-bytes)
  "Pre: range, contenuto non vuoto, parole e limite verificati. Post: dimensioni MT6.
SPAN verificato prima della somma; nessun numero u64 ricomposto.
RESOURCE-EXHAUSTED :cbor-tag-byte-budget o :cbor-tag-capacity, offset NIL;
INVARIANT-VIOLATION per precondizioni interne; nessun byte letto o scritto."
  (unless (<= start end)
    (error 'invariant-violation :reason :cbor-tag-dimension-range))
  (unless (plusp span)
    (error 'invariant-violation :reason :cbor-tag-dimension-empty))
  (when (> span max-bytes)
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-tag-byte-budget))
  (let* ((header-size (the (member 1 2 3 5 9) (nth-value 1 (seleziona-header-cbor high low))))
         (item-size (+ header-size span)))
    (declare (type index item-size))
    (when (> item-size max-bytes)
      (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-tag-byte-budget))
    (when (> item-size (- end start))
      (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-tag-capacity))
    (values header-size item-size)))

;;; REQ: REQ-CBR-007 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index octets index index)
                         (values null &optional)) check-overlap-tag-cbor))
(defun check-overlap-tag-cbor (buffer start next source source-start source-end)
  "Pre: footprint completo e contenuto verificati. Post: span disgiunti.
INVALID-ARGUMENT :cbor-tag-overlap, offset NIL; confini toccanti ammessi.
INVARIANT-VIOLATION per range interni; nessun byte letto o scritto."
  (unless (and (< start next) (<= next (length buffer)))
    (error 'invariant-violation :reason :cbor-tag-target-span))
  (unless (and (< source-start source-end) (<= source-end (length source)))
    (error 'invariant-violation :reason :cbor-tag-source-span))
  (when (and (eq buffer source) (< start source-end) (< source-start next))
    (error 'invalid-argument :reason :cbor-tag-overlap))
  nil)

;;; REQ: REQ-CBR-007 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t t t t t t t)
                         (values index (member 1 2 3 5 9) index &optional)) check-input-tag-cbor))
(defun check-input-tag-cbor (buffer start end source source-start source-end high low space
                            max-bytes max-nodes max-depth)
  "Pre: argomenti esterni. Post: span/testata/dimensione pronti alla scansione.
Precedenza range/source-vuoto/parole/space-alias/limiti/byte/capacita/overlap/nodi.
INVALID-ARGUMENT o RESOURCE-EXHAUSTED typed, offset NIL, dati e scratch intatti.
INVARIANT-VIOLATION per risultati interni incoerenti; nessun parsing o reset."
  (check-span-string-cbor-write buffer start end :cbor-range)
  (let ((span (check-span-string-cbor-write source source-start source-end :cbor-tag-source-range)))
    (declare (type index span))
    (when (zerop span)
      (error 'invalid-argument :reason :cbor-tag-source-empty))
    (check-input-header-cbor-write buffer start end 6 high low)
    (check-spazio-tag-cbor buffer source space)
    (check-limiti-struttura-cbor max-bytes max-nodes max-depth)
    (multiple-value-bind (header-size item-size)
        (dimensioni-tag-cbor start end span high low max-bytes)
      (check-overlap-tag-cbor buffer start (+ start item-size) source source-start source-end)
      (when (< max-nodes 2)
        (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-tag-node-budget))
      (unless (= span (- source-end source-start))
        (error 'invariant-violation :reason :cbor-tag-input-span))
      (unless (<= item-size (- end start))
        (error 'invariant-violation :reason :cbor-tag-input-capacity))
      (values span header-size item-size))))
