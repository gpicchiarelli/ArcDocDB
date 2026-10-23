;;;; Preflight MT4: nessun byte letto/scritto, nessun reset dello scratch.
;;; OWNER: destinazione e scratch esclusivi, sorgente e tabella stabili.
;;; SHARED: soltanto lettura, anche tra worker distinti (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CBR-005 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t index) (values null &optional)) check-tabella-array-cbor))
(defun check-tabella-array-cbor (item-ends count span)
  "Pre: SPAN verificato, tabella e COUNT esterni. Post: prefisso attivo limitato.
INVALID-ARGUMENT :cbor-array-item-ends per tipo tabella, :cbor-array-count
per COUNT o sorgente non vuota con COUNT0. Offset NIL; nessuna entry letta."
  (unless (typep item-ends '(simple-array (unsigned-byte 32) (*)))
    (error 'invalid-argument :reason :cbor-array-item-ends))
  (unless (and (typep count 'index) (<= count (length item-ends)) (<= count span))
    (error 'invalid-argument :reason :cbor-array-count))
  (when (and (zerop count) (plusp span))
    (error 'invalid-argument :reason :cbor-array-count))
  nil)

;;; REQ: REQ-CBR-005 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets octets (simple-array (unsigned-byte 32) (*)) t)
                         (values null &optional)) check-spazio-array-cbor))
(defun check-spazio-array-cbor (buffer source item-ends space)
  "Pre: tipi array verificati, SPACE esterno. Post: scratch separato dai dati.
INVALID-ARGUMENT :cbor-workspace o :cbor-array-workspace-alias, offset NIL.
Alias rifiutati anche per span vuoti; nessuna lettura di byte o reset."
  (unless (typep space 'spazio-cbor)
    (error 'invalid-argument :reason :cbor-workspace))
  (when (or (eq buffer (spazio-cbor-kinds space))
            (eq source (spazio-cbor-kinds space))
            (eq item-ends (spazio-cbor-remaining space)))
    (error 'invalid-argument :reason :cbor-array-workspace-alias))
  nil)

;;; REQ: REQ-CBR-005 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (index index index index index)
                         (values (member 1 2 3 5) index &optional)) dimensioni-array-cbor))
(defun dimensioni-array-cbor (start end span count max-bytes)
  "Pre: range, COUNT<=SPAN e configurazione validi. Post: dimensione completa.
Verifica SPAN prima della somma e del cast u32; testata inclusa nel budget.
RESOURCE-EXHAUSTED :cbor-array-byte-budget o :cbor-array-capacity, offset NIL;
nessuna entry/byte letta, nessun reset o write."
  (when (> span max-bytes)
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-array-byte-budget))
  (let* ((header-size (the (member 1 2 3 5)
                          (nth-value 1 (seleziona-header-cbor 0 (the u32 count)))))
         (item-size (+ header-size span)))
    (declare (type index item-size))
    (when (> item-size max-bytes)
      (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-array-byte-budget))
    (when (> item-size (- end start))
      (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-array-capacity))
    (values header-size item-size)))

;;; REQ: REQ-CBR-005 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index octets index index)
                         (values null &optional)) check-overlap-array-cbor))
(defun check-overlap-array-cbor (buffer start next source source-start source-end)
  "Pre: span verificati, NEXT comprende testata. Post: footprint disgiunto.
INVALID-ARGUMENT :cbor-array-overlap, offset NIL; confini toccanti/vuoti ammessi.
INVARIANT-VIOLATION per range interni; nessun byte letto/scritto."
  (unless (<= start next (length buffer))
    (error 'invariant-violation :reason :cbor-array-target-span))
  (unless (<= source-start source-end (length source))
    (error 'invariant-violation :reason :cbor-array-source-span))
  (when (and (eq buffer source) (< source-start source-end)
             (< start source-end) (< source-start next))
    (error 'invalid-argument :reason :cbor-array-overlap))
  nil)

;;; REQ: REQ-CBR-005 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function ((simple-array (unsigned-byte 32) (*)) u32 index)
                         (values null &optional)) check-fini-array-cbor))
(defun check-fini-array-cbor (item-ends count span)
  "Pre: tipi/COUNT/budget verificati, tabella stabile. Post: partizione completa.
Solo COUNT entry lette; fini relative crescenti e ultima uguale a SPAN.
INVALID-ARGUMENT :cbor-array-item-ends, offset NIL; INVARIANT-VIOLATION
per limiti interni. COUNT0 non legge entry; scratch e byte intatti."
  (unless (<= count (length item-ends))
    (error 'invariant-violation :reason :cbor-array-table-bound))
  (unless (<= count span +cbor-scan-max-bytes+)
    (error 'invariant-violation :reason :cbor-array-table-budget))
  (let ((previous 0))
    (declare (type u32 previous))
    (loop for position below count
          for stop of-type u32 = (aref item-ends position)
          do (unless (and (< previous stop) (<= stop span))
               (error 'invalid-argument :reason :cbor-array-item-ends))
             (setf previous stop))
    (unless (= previous span)
      (error 'invalid-argument :reason :cbor-array-item-ends)))
  nil)

;;; REQ: REQ-CBR-005 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (u32 index index) (values null &optional)) check-radice-array-cbor))
(defun check-radice-array-cbor (count max-nodes max-depth)
  "Pre: configurazione valida, COUNT limitato. Post: radice e minimo figli ammessi.
RESOURCE-EXHAUSTED :cbor-array-node-budget prima di :cbor-array-depth-budget,
offset NIL. Nessuna lettura di byte, reset o write."
  (when (> count (1- max-nodes))
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-array-node-budget))
  (when (zerop max-depth)
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-array-depth-budget))
  nil)

;;; REQ: REQ-CBR-005 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t t t t t t t)
                         (values index (member 1 2 3 5) index &optional)) check-input-array-cbor))
(defun check-input-array-cbor (buffer start end source source-start source-end item-ends count space
                             max-bytes max-nodes max-depth)
  "Pre: argomenti esterni. Post: span, testata e dimensione pronti alla scansione.
Precedenza range/source/tabella-count/space-alias/limiti/byte/capacita/overlap/
entry/nodi/depth. Errori tipizzati con offset NIL, dati e scratch intatti.
INVARIANT-VIOLATION per contratto interno incoerente; nessun byte parsato."
  (check-span-string-cbor-write buffer start end :cbor-range)
  (let ((span (check-span-string-cbor-write source source-start source-end :cbor-array-source-range)))
    (declare (type index span))
    (check-tabella-array-cbor item-ends count span)
    (check-spazio-array-cbor buffer source item-ends space)
    (check-limiti-struttura-cbor max-bytes max-nodes max-depth)
    (multiple-value-bind (header-size item-size)
        (dimensioni-array-cbor start end span count max-bytes)
      (check-overlap-array-cbor buffer start (+ start item-size) source source-start source-end)
      (check-fini-array-cbor item-ends (the u32 count) span)
      (check-radice-array-cbor count max-nodes max-depth)
      (unless (= span (- source-end source-start))
        (error 'invariant-violation :reason :cbor-array-input-span))
      (unless (<= item-size (- end start))
        (error 'invariant-violation :reason :cbor-array-input-capacity))
      (values span header-size item-size))))
