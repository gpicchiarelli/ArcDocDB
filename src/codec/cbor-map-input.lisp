;;;; Preflight MT5: tutte le coppie verificate prima di parsing, reset o write.
;;; OWNER: destinazione e scratch esclusivi, sorgente e tabella stabili.
;;; SHARED: sola lettura, anche tra worker distinti (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CBR-006 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t index) (values index &optional)) check-tabella-mappa-cbor))
(defun check-tabella-mappa-cbor (item-ends count span)
  "Pre: SPAN verificato, tabella e COUNT esterni. Post: numero item senza overflow.
COUNT conta coppie: confronti con meta tabella e SPAN prima del raddoppio.
INVALID-ARGUMENT :cbor-map-item-ends o :cbor-map-count, offset NIL;
nessuna entry letta e nessun limite imposto alla coda inattiva."
  (unless (typep item-ends '(simple-array (unsigned-byte 32) (*)))
    (error 'invalid-argument :reason :cbor-map-item-ends))
  (unless (and (typep count 'index) (<= count (floor (length item-ends) 2))
               (<= count (floor span 2)))
    (error 'invalid-argument :reason :cbor-map-count))
  (when (and (zerop count) (plusp span))
    (error 'invalid-argument :reason :cbor-map-count))
  (the index (* 2 count)))

;;; REQ: REQ-CBR-006 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets octets (simple-array (unsigned-byte 32) (*)) t)
                         (values null &optional)) check-spazio-mappa-cbor))
(defun check-spazio-mappa-cbor (buffer source item-ends space)
  "Pre: tipi array verificati, SPACE esterno. Post: scratch separato dai dati.
INVALID-ARGUMENT :cbor-workspace o :cbor-map-workspace-alias, offset NIL;
alias rifiutati anche per mappa vuota, senza leggere dati o resettare."
  (unless (typep space 'spazio-cbor)
    (error 'invalid-argument :reason :cbor-workspace))
  (when (or (eq buffer (spazio-cbor-kinds space))
            (eq source (spazio-cbor-kinds space))
            (eq item-ends (spazio-cbor-remaining space)))
    (error 'invalid-argument :reason :cbor-map-workspace-alias))
  nil)

;;; REQ: REQ-CBR-006 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (index index index index index)
                         (values (member 1 2 3 5) index &optional)) dimensioni-mappa-cbor))
(defun dimensioni-mappa-cbor (start end span count max-bytes)
  "Pre: range/COUNT/configurazione verificati. Post: dimensione completa MT5.
SPAN verificato prima di somma/cast u32; testata per COUNT coppie.
RESOURCE-EXHAUSTED :cbor-map-byte-budget o :cbor-map-capacity, offset NIL;
INVARIANT-VIOLATION per confini interni; nessuna entry/byte letta o scritta."
  (unless (<= start end)
    (error 'invariant-violation :reason :cbor-map-dimension-range))
  (unless (<= count (floor span 2))
    (error 'invariant-violation :reason :cbor-map-dimension-pairs))
  (when (> span max-bytes)
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-map-byte-budget))
  (let* ((header-size (the (member 1 2 3 5)
                          (nth-value 1 (seleziona-header-cbor 0 (the u32 count)))))
         (item-size (+ header-size span)))
    (declare (type index item-size))
    (when (> item-size max-bytes)
      (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-map-byte-budget))
    (when (> item-size (- end start))
      (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-map-capacity))
    (values header-size item-size)))

;;; REQ: REQ-CBR-006 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index octets index index)
                         (values null &optional)) check-overlap-mappa-cbor))
(defun check-overlap-mappa-cbor (buffer start next source source-start source-end)
  "Pre: span verificati, NEXT include testata. Post: footprint disgiunto.
INVALID-ARGUMENT :cbor-map-overlap, offset NIL; confini toccanti/vuoti ammessi.
INVARIANT-VIOLATION per range interni; nessun byte letto o scritto."
  (unless (<= start next (length buffer))
    (error 'invariant-violation :reason :cbor-map-target-span))
  (unless (<= source-start source-end (length source))
    (error 'invariant-violation :reason :cbor-map-source-span))
  (when (and (eq buffer source) (< source-start source-end)
             (< start source-end) (< source-start next))
    (error 'invalid-argument :reason :cbor-map-overlap))
  nil)

;;; REQ: REQ-CBR-006 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function ((simple-array (unsigned-byte 32) (*)) u32 index)
                         (values null &optional)) check-fini-mappa-cbor))
(defun check-fini-mappa-cbor (item-ends items span)
  "Pre: ITEMS=2*COUNT e budget verificati, tabella stabile. Post: partizione esatta.
Solo ITEMS entry lette; fini relative crescenti, ultima uguale a SPAN.
INVALID-ARGUMENT :cbor-map-item-ends, offset NIL; INVARIANT-VIOLATION interno.
ITEMS0 non legge entry; scratch e byte intatti, coda inattiva ignorata."
  (unless (<= items (length item-ends))
    (error 'invariant-violation :reason :cbor-map-table-bound))
  (unless (<= items span +cbor-scan-max-bytes+)
    (error 'invariant-violation :reason :cbor-map-table-budget))
  (let ((previous 0))
    (declare (type u32 previous))
    (loop for position below items
          for stop of-type u32 = (aref item-ends position)
          do (unless (and (< previous stop) (<= stop span))
               (error 'invalid-argument :reason :cbor-map-item-ends))
             (setf previous stop))
    (unless (= previous span)
      (error 'invalid-argument :reason :cbor-map-item-ends)))
  nil)

;;; REQ: REQ-CBR-006 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (u32 index index) (values null &optional)) check-radice-mappa-cbor))
(defun check-radice-mappa-cbor (items max-nodes max-depth)
  "Pre: ITEMS=2*COUNT/configurazione validi. Post: minimo radice e tutti gli item.
RESOURCE-EXHAUSTED :cbor-map-node-budget prima di :cbor-map-depth-budget,
offset NIL; nessuna lettura di byte, reset o scrittura."
  (when (> items (1- max-nodes))
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-map-node-budget))
  (when (zerop max-depth)
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-map-depth-budget))
  nil)

;;; REQ: REQ-CBR-006 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t t t t t t t)
                         (values index (member 1 2 3 5) index u32 &optional)) check-input-mappa-cbor))
(defun check-input-mappa-cbor (buffer start end source source-start source-end item-ends count space
                             max-bytes max-nodes max-depth)
  "Pre: argomenti esterni. Post: span/testata/dimensione e 2*COUNT pronti.
Precedenza range/source/tabella-count/space-alias/limiti/byte/capacita/overlap/
entry/nodi/depth. Errori tipizzati, offset NIL, dati e scratch intatti;
INVARIANT-VIOLATION per risultato interno incoerente, senza parsing."
  (check-span-string-cbor-write buffer start end :cbor-range)
  (let* ((span (check-span-string-cbor-write source source-start source-end :cbor-map-source-range))
         (items (check-tabella-mappa-cbor item-ends count span)))
    (declare (type index span items))
    (check-spazio-mappa-cbor buffer source item-ends space)
    (check-limiti-struttura-cbor max-bytes max-nodes max-depth)
    (multiple-value-bind (header-size item-size)
        (dimensioni-mappa-cbor start end span count max-bytes)
      (check-overlap-mappa-cbor buffer start (+ start item-size) source source-start source-end)
      (check-fini-mappa-cbor item-ends (the u32 items) span)
      (check-radice-mappa-cbor items max-nodes max-depth)
      (unless (= span (- source-end source-start))
        (error 'invariant-violation :reason :cbor-map-input-span))
      (unless (<= item-size (- end start))
        (error 'invariant-violation :reason :cbor-map-input-capacity))
      (unless (= items (* 2 count))
        (error 'invariant-violation :reason :cbor-map-input-pairs))
      (values span header-size item-size (the u32 items)))))
