;;; OWNER: coordinatore conserva vettori, token e file readonly stabili per l'intero calcolo.
;;; SHARED: sola lettura delle capacità, nessun append, callback I/O o pubblicazione.
(in-package #:arcdocdb.recovery.archive.csn)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (insieme-serie-recovery decisioni-recuperate simple-vector simple-vector index index)
                         index) verifica-piano-csn-preflight))
(defun verifica-piano-csn-preflight (set decisions active closed per-series total)
  "Pre: token canonici e vettori stabili. Post: count esatti e somma ACTIVE+CLOSED entro budget prima dei gate.
Richiede proprio lo stesso contesto Archivio del decision log, non solo UUID uguale.
INVALID-ARGUMENT per autorità/count; RESOURCE-EXHAUSTED per segmenti; nessuna allocazione di contenitori."
  (unless (eq (insieme-serie-recovery-archive set)
              (arcdocdb.recovery.archive::decisioni-recuperate-archive decisions))
    (error 'invalid-argument :reason :archive-csn-decision-owner))
  (let ((count (length (insieme-serie-recovery-views set))) (segments 0))
    (unless (and (= count (length active)) (= count (length closed)))
      (error 'invalid-argument :reason :archive-csn-recovery-count))
    (setf segments count)
    (when (> segments total) (error 'resource-exhausted :reason :archive-csn-segment-budget))
    (loop for item across closed
          do (let ((n (length (the simple-vector item))))
               (when (or (> n per-series) (> n (- total segments)))
                 (error 'resource-exhausted :reason :archive-csn-segment-budget))
               (incf segments n)))
    (unless (<= count segments total)
      (error 'invariant-violation :reason :archive-csn-segment-count))
    segments))

;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (vista-get-serie decisioni-recuperate active-recuperato) null)
                verifica-origine-active-csn))
(defun verifica-origine-active-csn (view decisions active)
  "Pre: risultato ACTIVE canonico e decision log dell'Archivio dell'insieme.
Post: stessa vista per EQ e stessa origine del replay usato realmente per risolvere i prepared.
Un secondo replay degli stessi byte non è la stessa autorità; INVALID-ARGUMENT prima del gate CLOSED.
Il marker privato non trattiene entry, FD o tabella decisioni nel risultato ACTIVE."
  (unless (eq view (arcdocdb.control::control-recuperato-view
                   (arcdocdb.recovery.active::active-recuperato-control active)))
    (error 'invalid-argument :reason :archive-csn-active-view))
  (unless (eq (arcdocdb.recovery.active::active-recuperato-decision-origin active)
              (arcdocdb.recovery.decisions::%table-origin
               (arcdocdb.recovery.archive::decisioni-recuperate-table decisions)))
    (error 'invalid-argument :reason :archive-csn-active-decision-source))
  nil)
