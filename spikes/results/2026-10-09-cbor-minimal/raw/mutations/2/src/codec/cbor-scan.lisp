;;;; Un item esatto, scansione bounded e solo scratch esclusivo del chiamante.
;;; OWNER: buffer immutabile del chiamante; spazio privato di una sola chiamata/worker.
;;; SHARED: nessuna scrittura, attesa o I/O tra Serie (INV-P6); nessun thread creato.
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (octets spazio-cbor index (integer 1 16777216)
                          (integer 0 100)) (values null &optional)) passo-struttura-cbor))
(defun passo-struttura-cbor (buffer space end max-nodes max-depth)
  "Pre: frame da completare, cursore entro END. Post: almeno un byte consumato.
Header prima di contesto/budget, break escluso dai nodi; propaga condizioni tipizzate.
INVARIANT-VIOLATION per range, forma o progresso interno; nessuna allocazione prevista."
  (let ((lead (spazio-cbor-cursor space)))
    (declare (type index lead))
    (unless (<= lead end (length buffer))
      (error 'invariant-violation :reason :cbor-step-range))
    (multiple-value-bind (major ai high low next form) (leggi-header-cbor buffer lead end)
      (unless (if (eq form :argument) (< ai 28) (= ai 31))
        (error 'invariant-violation :reason :cbor-step-form))
      (check-contesto-cbor space major form lead)
      (if (eq form :break)
          (progn (chiudi-break-cbor space lead) (setf (spazio-cbor-cursor space) next))
          (progn (conta-nodo-cbor space max-nodes lead)
                 (tratta-item-cbor buffer space major high low next end form max-depth lead))))
    (unless (and (< lead (spazio-cbor-cursor space)) (<= (spazio-cbor-cursor space) end))
      (error 'invariant-violation :reason :cbor-step-progress :offset lead)))
  nil)

;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor index (integer 1 16777216) (integer 0 100))
                         (values index (integer 0 100) index &optional)) risultato-struttura-cbor))
(defun risultato-struttura-cbor (space end max-nodes max-depth)
  "Pre: root completata. Post: nodi/picco/END solo dopo verifica integrale.
INVARIANT-VIOLATION per fine, conteggi o stato attivo residuo; nessun dato decodificato."
  (unless (= (spazio-cbor-cursor space) end)
    (error 'invariant-violation :reason :cbor-result-range))
  (unless (and (<= 1 (spazio-cbor-nodes space) max-nodes)
               (<= (spazio-cbor-peak-depth space) max-depth))
    (error 'invariant-violation :reason :cbor-result-count))
  (unless (and (zerop (spazio-cbor-top space)) (zerop (spazio-cbor-depth space))
               (not (spazio-cbor-pending-tag space)))
    (error 'invariant-violation :reason :cbor-result-state))
  (values (spazio-cbor-nodes space) (spazio-cbor-peak-depth space) end))

;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (t t t t &key (:max-bytes t) (:max-nodes t) (:max-depth t))
                         (values index (integer 0 100) index &optional)) verifica-struttura-cbor))
(defun verifica-struttura-cbor (buffer start end space
                               &key (max-bytes +cbor-scan-max-bytes+)
                                 (max-nodes +cbor-scan-max-bytes+)
                                 (max-depth +cbor-scan-max-depth+))
  "Pre: simple u8 immutabile, span half-open, scratch esclusivo e budget verificati.
Post: NODES, picco soli array/map, END per un item esatto; nessuna mutazione del buffer.
Preflight rifiutato non modifica lo spazio; errore runtime puo lasciarlo sporco,
riusabile al prossimo reset. Propaga INVALID-ARGUMENT, RESOURCE-EXHAUSTED,
CORRUPTION-DETECTED (inclusi motivi UTF8 assoluti), INVARIANT-VIOLATION.
Nonminimi, float raw, tag e mappe duplicate conservati; nessuna canonicalita,
semantica tag o decodifica. Al piu SPAN passi e drain102; nessuna attesa/I/O."
  (let ((span (check-input-struttura-cbor buffer start end space max-bytes max-nodes max-depth)))
    (declare (type index span))
    (unless (<= span +cbor-scan-max-bytes+)
      (error 'invariant-violation :reason :cbor-loop-span))
    (let ((bytes (the octets buffer)) (begin (the index start)) (limit (the index end))
          (scratch (the spazio-cbor space))
          (node-limit (the (integer 1 16777216) max-nodes))
          (depth-limit (the (integer 0 100) max-depth)))
      (azzera-spazio-cbor scratch begin)
      (loop repeat span
            do (when (svuota-frame-cbor scratch limit) (return))
               (passo-struttura-cbor bytes scratch limit node-limit depth-limit))
      (unless (svuota-frame-cbor scratch limit)
        (unless (= (spazio-cbor-cursor scratch) limit)
          (error 'invariant-violation :reason :cbor-loop-bound))
        (leggi-header-cbor bytes limit limit)
        (error 'invariant-violation :reason :cbor-empty-header))
      (risultato-struttura-cbor scratch limit node-limit depth-limit))))
