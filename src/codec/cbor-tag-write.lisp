;;;; MT6 minimo e contenuto wire completo, senza interpretazione dei tag.
;;; OWNER: destinazione/scratch privati; sorgente stabile fino al ritorno.
;;; SHARED: sorgente condivisibile in lettura, nessuna scrittura/attesa/I/O (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CBR-007 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets index index spazio-cbor index index (integer 0 100))
                         (values null &optional)) verifica-contenuto-tag-cbor))
(defun verifica-contenuto-tag-cbor (source start end space span max-nodes max-depth)
  "Pre: contenuto non vuoto, scratch esclusivo, budget validi inclusa radice.
Post: un item esatto/minimo, nodi figli <= MAX-NODES-1 e picco <= MAX-DEPTH.
Il tag non aggiunge profondita o frame. Propaga errori scanner con offset SOURCE;
dati intatti, scratch riusabile. INVARIANT-VIOLATION per contratto interno."
  (unless (and (< start end) (<= end (length source)))
    (error 'invariant-violation :reason :cbor-tag-child-range))
  (unless (= span (- end start))
    (error 'invariant-violation :reason :cbor-tag-child-span))
  (unless (<= 2 max-nodes +cbor-scan-max-bytes+)
    (error 'invariant-violation :reason :cbor-tag-child-budget))
  (multiple-value-bind (nodes peak next)
      (verifica-struttura-cbor-minima source start end space
                                   :max-bytes span :max-nodes (1- max-nodes) :max-depth max-depth)
    (unless (= next end)
      (error 'invariant-violation :reason :cbor-tag-child-progress))
    (unless (<= 1 nodes (1- max-nodes))
      (error 'invariant-violation :reason :cbor-tag-child-nodes))
    (unless (<= peak max-depth)
      (error 'invariant-violation :reason :cbor-tag-child-depth)))
  nil)

;;; REQ: REQ-CBR-007 REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t t t t t t
                          &key (:max-bytes t) (:max-nodes t) (:max-depth t))
                         (values index &optional)) scrivi-tag-cbor-minimo))
(defun scrivi-tag-cbor-minimo (buffer start end source source-start source-end high low space
                              &key (max-bytes +cbor-scan-max-bytes+)
                                (max-nodes +cbor-scan-max-bytes+) (max-depth +cbor-scan-max-depth+))
  "Pre: simple u8, span half-open, contenuto non vuoto/minimo, parole u32 stabili;
destinazione/scratch esclusivi. Post: header MT6 minimo e contenuto esatto,
un solo NEXT, solo [START,NEXT) cambia. Budget byte/nodi includono il tag;
MAX-DEPTH conta solo array/map e rimane invariato per il contenuto.
Tutti gli errori pubblici precedono la scrittura e preservano gli interi array;
offset NIL nel preflight o assoluto SOURCE nello scanner. Preflight conserva
SPACE; parsing fallito lo puo sporcare, riusabile dopo reset. A successo
descrive il contenuto, senza il nodo tag aggiunto. BUFFER=SOURCE solo disgiunto
dal footprint completo, alias scratch rifiutati. Nessuna semantica dei tag.
INVARIANT-VIOLATION interno senza rollback, anche dalla copia MT2/3.
Lavoro limitato a SPAN*102; nessun AST, thread, attesa, I/O o pubblicazione."
  (multiple-value-bind (span header-size item-size)
      (check-input-tag-cbor buffer start end source source-start source-end high low space
                            max-bytes max-nodes max-depth)
    (let ((bytes (the octets buffer)) (begin (the index start))
          (src (the octets source)) (source-begin (the index source-start))
          (source-limit (the index source-end)) (scratch (the spazio-cbor space))
          (hi (the u32 high)) (lo (the u32 low)) (next (+ (the index start) item-size)))
      (declare (type index next))
      (verifica-contenuto-tag-cbor src source-begin source-limit scratch span max-nodes max-depth)
      (let ((payload-start (scrivi-header-cbor-minimo bytes begin next 6 hi lo)))
        (declare (type index payload-start))
        (unless (= payload-start (+ begin header-size))
          (error 'invariant-violation :reason :cbor-tag-header-progress))
        (unless (= (- next payload-start) span)
          (error 'invariant-violation :reason :cbor-tag-payload-span))
        (let ((result (copia-stringa-cbor-write bytes payload-start next src source-begin source-limit)))
          (unless (= result next)
            (error 'invariant-violation :reason :cbor-tag-write-progress))
          result)))))
