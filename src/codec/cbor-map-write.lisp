;;;; MT5 minimo da chiavi/valori wire completi, senza modifica dell'ordine.
;;; OWNER: destinazione e scratch privati, sorgente e tabella stabili.
;;; SHARED: nessuna scrittura condivisa, attesa o I/O (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CBR-006 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index spazio-cbor index index)
                         (values index index &optional)) verifica-figlio-mappa-cbor))
(defun verifica-figlio-mappa-cbor (source start end space remaining child-depth)
  "Pre: item non vuoto, scratch esclusivo e budget residui. Post: nodi/picco.
Residuo0: RESOURCE-EXHAUSTED :cbor-map-node-budget all'offset START, prima
del reset. Errori scanner propagati con offset SOURCE; dati sempre intatti,
scratch riusabile. INVARIANT-VIOLATION per confini/risultato interni."
  (unless (<= start end (length source))
    (error 'invariant-violation :reason :cbor-map-child-range))
  (when (zerop remaining)
    (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-map-node-budget :offset start))
  (let ((span (- end start)))
    (declare (type index span))
    (unless (plusp span)
      (error 'invariant-violation :reason :cbor-map-child-empty))
    (multiple-value-bind (nodes peak next)
        (verifica-struttura-cbor-minima source start end space
                                     :max-bytes span :max-nodes remaining :max-depth child-depth)
      (unless (= next end)
        (error 'invariant-violation :reason :cbor-map-child-progress))
      (unless (<= 1 nodes remaining)
        (error 'invariant-violation :reason :cbor-map-child-nodes))
      (unless (<= peak child-depth)
        (error 'invariant-violation :reason :cbor-map-child-depth))
      (values nodes peak))))

;;; REQ: REQ-CBR-006 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index (simple-array (unsigned-byte 32) (*)) u32
                                spazio-cbor index index) (values index index &optional))
                verifica-figli-mappa-cbor))
(defun verifica-figli-mappa-cbor (source start end item-ends items space max-nodes max-depth)
  "Pre: partizione/radice/budget verificati, ITEMS=2*COUNT e input stabili.
Post: nodi/picco inclusa radice e tutti gli item esatti/minimi.
Loop ITEMS limitato a16MiB; reset/drain102 per item. Errori scanner propagati,
residuo0 prima del prossimo reset; INVARIANT-VIOLATION per contratto interno.
ITEMS0 non usa SPACE; nessun byte/tabella/destinazione modificato."
  (unless (<= start end (length source))
    (error 'invariant-violation :reason :cbor-map-children-range))
  (unless (<= items (length item-ends))
    (error 'invariant-violation :reason :cbor-map-children-bound))
  (unless (<= items +cbor-scan-max-bytes+)
    (error 'invariant-violation :reason :cbor-map-children-budget))
  (unless (<= 1 max-depth +cbor-scan-max-depth+)
    (error 'invariant-violation :reason :cbor-map-children-root-depth))
  (let ((nodes 1) (peak 1) (cursor start) (child-depth (1- max-depth)))
    (declare (type index nodes peak cursor child-depth))
    (loop for position below items
          for stop of-type index = (+ start (aref item-ends position))
          do (multiple-value-bind (child-nodes child-peak)
                 (verifica-figlio-mappa-cbor source cursor stop space (- max-nodes nodes) child-depth)
               (incf nodes child-nodes)
               (setf peak (max peak (1+ child-peak)) cursor stop)))
    (unless (= cursor end)
      (error 'invariant-violation :reason :cbor-map-children-progress))
    (unless (<= (1+ items) nodes max-nodes)
      (error 'invariant-violation :reason :cbor-map-children-nodes))
    (unless (<= 1 peak max-depth)
      (error 'invariant-violation :reason :cbor-map-children-depth))
    (values nodes peak)))

;;; REQ: REQ-CBR-006 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t t t t
                          &key (:max-bytes t) (:max-nodes t) (:max-depth t))
                         (values index &optional)) scrivi-mappa-cbor-minima))
(defun scrivi-mappa-cbor-minima (buffer start end source source-start source-end item-ends count space
                               &key (max-bytes +cbor-scan-max-bytes+)
                                 (max-nodes +cbor-scan-max-bytes+) (max-depth +cbor-scan-max-depth+))
  "Pre: simple u8, span half-open, fini simple u32; COUNT coppie e dati stabili,
destinazione/scratch esclusivi. Post: testata MT5 minima per COUNT e payload
esatto nello stesso ordine, un solo NEXT; solo [START,NEXT) cambia.
Budget includono radice e testata. Preflight e scansione di chiavi/valori
prima di scrivere: errori pubblici preservano interi array, offset NIL
o assoluto SOURCE per scanner. Scratch intatto nel preflight, riusabile
dopo parsing fallito; mappa vuota non lo usa. BUFFER=SOURCE solo disgiunto
dal footprint completo; alias scratch rifiutati. Nessun ordinamento/unicita.
INVARIANT-VIOLATION interno senza rollback, anche dalla copia MT2/3.
Costo O(SPAN+2*COUNT*102); nessun AST, thread, attesa, I/O o pubblicazione."
  (multiple-value-bind (span header-size item-size item-count)
      (check-input-mappa-cbor buffer start end source source-start source-end item-ends count space
                             max-bytes max-nodes max-depth)
    (let ((bytes (the octets buffer)) (begin (the index start))
          (src (the octets source)) (source-begin (the index source-start))
          (source-limit (the index source-end)) (items (the u32 item-count))
          (pairs (the u32 count)) (scratch (the spazio-cbor space))
          (next (+ (the index start) item-size)))
      (declare (type index next))
      (multiple-value-bind (nodes peak)
          (verifica-figli-mappa-cbor src source-begin source-limit item-ends items scratch max-nodes max-depth)
        (unless (<= nodes max-nodes)
          (error 'invariant-violation :reason :cbor-map-result-nodes))
        (unless (<= peak max-depth)
          (error 'invariant-violation :reason :cbor-map-result-depth)))
      (let ((payload-start (scrivi-header-cbor-minimo bytes begin next 5 0 pairs)))
        (declare (type index payload-start))
        (unless (= payload-start (+ begin header-size))
          (error 'invariant-violation :reason :cbor-map-header-progress))
        (unless (= (- next payload-start) span)
          (error 'invariant-violation :reason :cbor-map-payload-span))
        (let ((result (copia-stringa-cbor-write bytes payload-start next src source-begin source-limit)))
          (unless (= result next)
            (error 'invariant-violation :reason :cbor-map-write-progress))
          result)))))
