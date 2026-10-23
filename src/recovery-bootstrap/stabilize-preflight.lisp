;;; OWNER: coordinatore mantiene tutte le Serie e i risultati canonici aperti, esclusivi e stabili.
;;; SHARED: solo conteggi privati e gate esistenti; nessun piano per fonte o scrittura condivisa.
(in-package #:arcdocdb.recovery.bootstrap)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-STO-006 REQ-AFF-008
(declaim (ftype (function (simple-vector simple-vector simple-vector index index index) index)
                verifica-capienza-stabilizzazione-archivio))
(defun verifica-capienza-stabilizzazione-archivio (sources active closed count per-series total)
  "Pre: forma/count/tipi di tutte le righe verificati, vettori stabili. Post: somma segmenti ammessa.
Cardinalita' canoniche e budget includono ACTIVE, prima delle scansioni delle fonti e degli effetti.
Condizioni delle guardie canoniche propagate; nessun nuovo contenitore o risultato parziale."
  (let ((segments 0))
    (dotimes (i count)
      (multiple-value-bind (control n)
          (arcdocdb.recovery.series::verifica-ampiezza-stabilizzazione
           (the recovery-sources (svref sources i))
           (the arcdocdb.recovery.active:active-recuperato (svref active i))
           (the simple-vector (svref closed i)) per-series)
        (declare (ignore control)) ; guardia del CONTROL gia' eseguita, non esito d'errore.
        (when (> n (- total segments))
          (error 'resource-exhausted :reason :archive-stabilization-segment-budget))
        (incf segments n)))
    (unless (<= count segments total)
      (error 'invariant-violation :reason :archive-stabilization-segment-count))
    segments))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-STO-006 REQ-AFF-008
(declaim (ftype (function (simple-vector simple-vector simple-vector index index) null)
                verifica-metadata-stabilizzazione-archivio))
(defun verifica-metadata-stabilizzazione-archivio (sources active closed count per-series)
  "Pre: tutti i count ammessi prima delle scansioni, token/vettori/FD stabili. Post: metadata di tutte le fonti.
Ordine u64, unico ACTIVE, consumo CLOSED e CONTROL/FD/EOF/P riusano le guardie per Serie.
Nessun nome osservato o effetto; condizioni originali propagate senza close o retry."
  (dotimes (i count)
    (let ((source (the recovery-sources (svref sources i)))
          (a (the arcdocdb.recovery.active:active-recuperato (svref active i)))
          (c (the simple-vector (svref closed i))))
      (multiple-value-bind (control n)
          (arcdocdb.recovery.series::verifica-ampiezza-stabilizzazione source a c per-series)
        (arcdocdb.recovery.series::verifica-token-stabilizzazione-serie control source a c n))))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (simple-vector simple-vector index) null) verifica-nomi-stabilizzazione-archivio))
(defun verifica-nomi-stabilizzazione-archivio (directories sources count)
  "Pre: metadata di tutte le Serie e gate canonico Archivio conclusi, namespace esclusivi/stabili.
Post: ogni nome/FD di tutte le Serie ammesso prima della prima rinomina o fsync.
Il risultato non prenota il namespace; nessun effetto o gestione implicita delle capacita'."
  (dotimes (i count)
    (let ((source (the recovery-sources (svref sources i))))
      (arcdocdb.recovery.series::verifica-nomi-fonti-stabilizzabili
       (the arcdocdb.io:file-io (svref directories i)) source
       (arcdocdb.recovery.manifest:numero-fonti-recovery source))))
  nil)
