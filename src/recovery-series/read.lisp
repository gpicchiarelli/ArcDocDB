;;; OWNER: compito I/O esclusivo; scratch riusato serialmente, ogni reader restituisce dati posseduti.
;;; SHARED: capacità prestate dal set e decisioni readonly; nessuna close o pubblicazione qui.
(in-package #:arcdocdb.recovery.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (control-recuperato recovery-sources index decisioni-recuperate octets
                          limiti-recovery-serie) active-recuperato) recupera-active-serie))
(defun recupera-active-serie (control sources position decisions scratch limits)
  "Pre: insieme preflight completo, POSITION è l'ACTIVE, pool I/O e scratch esclusivo.
Post: ACTIVE canonico con lo stesso replay decisioni e EOF del FD acquisito; nessun buffer trattenuto.
Riga incoerente INVARIANT-VIOLATION; condizioni del reader propagate senza retry o close."
  (multiple-value-bind (id state form file size) (fonte-recovery sources position)
    (declare (ignore form)) ; metadata del nome; riconciliazione fisica esterna.
    (unless (and (eq state :active) (= id (segmento-attivo (manifest-control-recuperato control))))
      (error 'invariant-violation :reason :series-recovery-active-entry))
    (leggi-active-con-decisioni control file size decisions scratch
     :chunk-bytes (limits-chunk limits) :max-bytes (limits-bytes limits)
     :max-batches (limits-batches limits) :max-records (limits-records limits)
     :max-batch-records (limits-batch-records limits) :max-batch-bytes (limits-batch-bytes limits)
     :max-prepared (limits-prepared limits) :max-outcomes (limits-outcomes limits))))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-STO-006 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (control-recuperato recovery-sources index octets limiti-recovery-serie)
                         arcdocdb.recovery.closed:closed-recuperato) recupera-closed-serie))
(defun recupera-closed-serie (control sources position scratch limits)
  "Pre: insieme preflight completo, POSITION è CLOSED, scratch riusabile e capacità readonly vive.
Post: prefisso e prepared risolti dal reader CLOSED canonico; nessuna coda oltre P letta.
INVARIANT-VIOLATION per riga cambiata; condizioni originali propagate, FD ancora del proprietario del set."
  (multiple-value-bind (id state form file size) (fonte-recovery sources position)
    (declare (ignore form size)) ; nome al planner; EOF già confrontato con P nel preflight completo.
    (unless (eq state :closed) (error 'invariant-violation :reason :series-recovery-closed-entry))
    (leggi-closed-recuperato control file id scratch
     :chunk-bytes (limits-chunk limits) :max-bytes (limits-bytes limits)
     :max-batches (limits-batches limits) :max-records (limits-records limits)
     :max-batch-records (limits-batch-records limits) :max-batch-bytes (limits-batch-bytes limits)
     :max-prepared (limits-prepared limits) :max-outcomes (limits-outcomes limits)
     :max-esiti-chiusura (limits-closure limits))))
