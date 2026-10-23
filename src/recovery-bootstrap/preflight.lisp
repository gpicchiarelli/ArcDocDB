;;; OWNER: coordinatore esclusivo verifica tutte le Serie prima del primo header.
;;; SHARED: nessuna nuova tabella, copia o risorsa; limiti Serie immutabili prestati dal catalogo.
(in-package #:arcdocdb.recovery.bootstrap)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (insieme-serie-recovery decisioni-recuperate t t t octets index index index)
                         (values index index &optional)) verifica-bootstrap-archivio))
(defun verifica-bootstrap-archivio (set decisions controls sources limits scratch byte-budget segment-budget references-budget)
  "Pre: recovery esclusivo dell'Archivio, nessun writer o close concorrente. Post: count Serie/segmenti completi.
Ogni vista EQ, insieme Serie e preflight file prima dei dati; budget globali prima degli array.
Byte: somma EOF ACTIVE + P CLOSED. Riferimenti nuovi: 8*(Serie+segmenti), non RSS.
Propaga condizioni canoniche; nessuna lettura di header/corpi o consegna di dati parziali."
  (let* ((count (verifica-ingressi-bootstrap set decisions controls sources limits segment-budget references-budget))
         (views (arcdocdb.recovery.archive.csn::insieme-serie-recovery-views set))
         (segments 0) (references (* 16 count)) (bytes 0))
    (dotimes (i count)
      (let ((control (the control-recuperato (svref controls i)))
            (source (the recovery-sources (svref sources i)))
            (local (the limiti-recovery-serie (svref limits i))))
        (unless (eq (arcdocdb.control::control-recuperato-view control) (svref views i))
          (error 'invalid-argument :reason :archive-bootstrap-control-view))
        (multiple-value-bind (n closed) (arcdocdb.recovery.series::verifica-capienza-fonti-serie control source local)
          (when (> n (- segment-budget segments))
            (error 'resource-exhausted :reason :archive-bootstrap-segment-budget))
          (when (> (* 8 closed) (- references-budget references))
            (error 'resource-exhausted :reason :archive-bootstrap-reference-budget))
          (multiple-value-bind (position checked row-bytes)
              (arcdocdb.recovery.series::verifica-fonti-serie control source decisions scratch local)
            (declare (ignore position)) ; indice valido già verificato, non esito d'errore.
            (unless (= checked closed) (error 'invariant-violation :reason :archive-bootstrap-preflight-count))
            (when (> row-bytes (- byte-budget bytes))
              (error 'resource-exhausted :reason :archive-bootstrap-byte-budget))
            (incf bytes row-bytes))
          (incf segments n)
          (incf references (* 8 closed)))))
    (unless (and (<= count segments segment-budget) (= references (* 8 (+ count segments))) (<= bytes byte-budget))
      (error 'invariant-violation :reason :archive-bootstrap-preflight-result))
    (values count segments)))
