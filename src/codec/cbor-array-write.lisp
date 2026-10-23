;;;; MT4 minimo da item wire completi: verifica prima dell'emissione.
;;; OWNER: destinazione e scratch privati; sorgente e tabella stabili.
;;; SHARED: nessuna scrittura condivisa, attesa o I/O (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CBR-005 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index spazio-cbor index index)
                         (values index index &optional)) verifica-figlio-array-cbor))
(defun verifica-figlio-array-cbor (source start end space remaining child-depth)
  "Pre: figlio non vuoto, scratch esclusivo, budget residui. Post: nodi e picco.
Residuo0: RESOURCE-EXHAUSTED :cbor-array-node-budget all'offset START, prima
del reset. Errori scanner propagati con offset SOURCE; dati sempre intatti,
scratch riusabile dopo errore. INVARIANT-VIOLATION per confini/risultato interni."
  (unless (<= start end (length source))
    (error 'invariant-violation :reason :cbor-array-child-range))
  (when (zerop remaining)
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-array-node-budget :offset start))
  (let ((span (- end start)))
    (declare (type index span))
    (unless (plusp span)
      (error 'invariant-violation :reason :cbor-array-child-empty))
    (multiple-value-bind (nodes peak next)
        (verifica-struttura-cbor-minima source start end space
                                     :max-bytes span :max-nodes remaining :max-depth child-depth)
      (unless (= next end)
        (error 'invariant-violation :reason :cbor-array-child-progress))
      (unless (<= 1 nodes remaining)
        (error 'invariant-violation :reason :cbor-array-child-nodes))
      (unless (<= peak child-depth)
        (error 'invariant-violation :reason :cbor-array-child-depth))
      (values nodes peak))))

;;; REQ: REQ-CBR-005 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index (simple-array (unsigned-byte 32) (*)) u32
                                spazio-cbor index index) (values index index &optional))
                verifica-figli-array-cbor))
(defun verifica-figli-array-cbor (source start end item-ends count space max-nodes max-depth)
  "Pre: partizione/budget/radice verificati, sorgente e tabella stabili.
Post: nodi totali e picco inclusa radice; tutti i figli esatti e minimi.
Loop COUNT limitato a16MiB; reset/drain102 per figlio. Errori scanner propagati,
residuo0 intercettato prima del prossimo reset; INVARIANT-VIOLATION interno.
COUNT0 non usa SPACE; nessun byte/tabella/destinazione modificato."
  (unless (<= start end (length source))
    (error 'invariant-violation :reason :cbor-array-children-range))
  (unless (<= count (length item-ends))
    (error 'invariant-violation :reason :cbor-array-children-bound))
  (unless (<= count +cbor-scan-max-bytes+)
    (error 'invariant-violation :reason :cbor-array-children-budget))
  (let ((nodes 1) (peak 1) (cursor start) (child-depth (1- max-depth)))
    (declare (type index nodes peak cursor child-depth))
    (loop for position below count
          for stop of-type index = (+ start (aref item-ends position))
          do (multiple-value-bind (child-nodes child-peak)
                 (verifica-figlio-array-cbor source cursor stop space (- max-nodes nodes) child-depth)
               (incf nodes child-nodes)
               (setf peak (max peak (1+ child-peak)) cursor stop)))
    (unless (= cursor end)
      (error 'invariant-violation :reason :cbor-array-children-progress))
    (unless (<= (1+ count) nodes max-nodes)
      (error 'invariant-violation :reason :cbor-array-children-nodes))
    (unless (<= 1 peak max-depth)
      (error 'invariant-violation :reason :cbor-array-children-depth))
    (values nodes peak)))

;;; REQ: REQ-CBR-005 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t t t t
                          &key (:max-bytes t) (:max-nodes t) (:max-depth t))
                         (values index &optional)) scrivi-array-cbor-minimo))
(defun scrivi-array-cbor-minimo (buffer start end source source-start source-end item-ends count space
                               &key (max-bytes +cbor-scan-max-bytes+)
                                 (max-nodes +cbor-scan-max-bytes+) (max-depth +cbor-scan-max-depth+))
  "Pre: simple u8, span half-open, fini relative simple u32; dati stabili,
destinazione/scratch esclusivi. Post: testata MT4 minima e payload esatto,
un solo NEXT; solo [START,NEXT) cambia. Budget includono radice e testata.
Preflight e scansione integrale prima di scrivere: errori pubblici preservano
tutti gli array fisici, offset NIL o assoluto SOURCE per gli errori scanner.
Scratch intatto nel preflight, riusabile dopo parsing fallito; vuoto non lo usa.
BUFFER=SOURCE ammesso solo disgiunto dal footprint, alias scratch rifiutati.
INVARIANT-VIOLATION interno senza rollback, anche dalla copia condivisa MT2/3.
Costo O(SPAN+COUNT*102); nessun AST, thread, attesa, I/O o pubblicazione."
  (multiple-value-bind (span header-size item-size)
      (check-input-array-cbor buffer start end source source-start source-end item-ends count space
                             max-bytes max-nodes max-depth)
    (let ((bytes (the octets buffer)) (begin (the index start))
          (src (the octets source)) (source-begin (the index source-start))
          (source-limit (the index source-end)) (items (the u32 count))
          (scratch (the spazio-cbor space)) (next (+ (the index start) item-size)))
      (declare (type index next))
      (multiple-value-bind (nodes peak)
          (verifica-figli-array-cbor src source-begin source-limit item-ends items scratch max-nodes max-depth)
        (unless (<= nodes max-nodes)
          (error 'invariant-violation :reason :cbor-array-result-nodes))
        (unless (<= peak max-depth)
          (error 'invariant-violation :reason :cbor-array-result-depth)))
      (let ((payload-start (scrivi-header-cbor-minimo bytes begin next 4 0 items)))
        (declare (type index payload-start))
        (unless (= payload-start (+ begin header-size))
          (error 'invariant-violation :reason :cbor-array-header-progress))
        (unless (= (- next payload-start) span)
          (error 'invariant-violation :reason :cbor-array-payload-span))
        (let ((result (copia-stringa-cbor-write bytes payload-start next src source-begin source-limit)))
          (unless (= result next)
            (error 'invariant-violation :reason :cbor-array-write-progress))
          result)))))
