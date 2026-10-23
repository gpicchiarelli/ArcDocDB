;;; OWNER: controller mantiene nuovi e vecchi file congelati; preflight senza I/O o allocazione di array.
;;; SHARED: nessuna scrittura nelle capacità o nel manifest; nessuna nuova autorità globale.
(in-package #:arcdocdb.recovery.checkpoint)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (active-recuperato segmento-attivo-preparato)
                         (values arcdocdb.recovery.manifest::manifest u64 u64 (member 1 2) &optional))
                verifica-fonti-checkpoint))
(defun verifica-fonti-checkpoint (recovered active)
  "Pre: recovery esclusivo, fonti autorevoli e capacità mantenute aperte dal controller.
Post: stessa vista canonica, nuovo ACTIVE ancora solo header, ID fresco e next-id rappresentabile.
INVALID-ARGUMENT per vista/riuso, RESOURCE-EXHAUSTED per ID esauriti; nessuna syscall o scrittura."
  (arcdocdb.control::verifica-active-checkpoint active)
  (let* ((control (arcdocdb.recovery.active::active-recuperato-control recovered))
         (old-segment (arcdocdb.recovery.active::active-recuperato-segment recovered))
         (new-segment (arcdocdb.active::segmento-attivo-preparato-segment active))
         (manifest (arcdocdb.control:manifest-control-recuperato control))
         (id (arcdocdb.control::id-active-checkpoint active)))
    (unless (eq (arcdocdb.control::control-recuperato-view control)
                (arcdocdb.get::segmento-get-owner new-segment))
      (error 'invalid-argument :reason :recovery-checkpoint-view))
    (arcdocdb.io::esigi-aperto (arcdocdb.control::control-recuperato-input control) :input)
    (arcdocdb.io::esigi-aperto (arcdocdb.get::segmento-get-file old-segment) :input)
    (multiple-value-bind (available next) (prossimo-id-segmento manifest)
      (unless available (error 'resource-exhausted :reason :recovery-segment-ids))
      (unless (>= id next) (error 'invalid-argument :reason :recovery-active-reused)))
    (unless (typep (1+ id) 'u64)
      (error 'resource-exhausted :reason :recovery-checkpoint-next-id))
    (values manifest id (1+ id) (arcdocdb.get::segmento-get-version new-segment))))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-TXM-007 REQ-AFF-008
(declaim (ftype (function (active-recuperato arcdocdb.recovery.manifest::manifest
                          (member 1 2) index u32 u32 index) (values index index index &optional))
                misura-payload-checkpoint))
(defun misura-payload-checkpoint (recovered manifest version max-payload max-segments max-outcomes workspace)
  "Pre: fonti valide e stabili. Post: byte CLOSED/REMOVED/payload e budget completi prima di allocare.
Workspace conta array propri e chiavi u64, esclusi SORT, builder CONTROL, oggetti Lisp e GC.
Errori tipizzati di configurazione/risorse; cicli limitati ai CLOSED già contati."
  (unless (<= +edit-min-bytes+ max-payload +metadata-max-bytes+)
    (error 'invalid-argument :reason :recovery-checkpoint-budget))
  (let* ((closed (1+ (numero-segmenti-chiusi manifest))) (removed (numero-segmenti-rimossi manifest))
         (derived (length (arcdocdb.recovery.active::active-recuperato-ids recovered)))
         (outcomes 0) (closed-bytes (lunghezza-chiusura-active recovered)))
    (when (> (+ 1 closed removed) max-segments)
      (error 'resource-exhausted :reason :recovery-checkpoint-segments))
    (loop for entry being the hash-values of (arcdocdb.recovery.manifest::%manifest-closed manifest)
          do (arcdocdb.recovery.manifest::check-closed-shape entry)
             (incf outcomes (hash-table-count (arcdocdb.recovery.manifest::%closed-outcomes entry)))
             (incf closed-bytes +closed-fixed-bytes+))
    (when (> (+ outcomes derived) max-outcomes)
      (error 'resource-exhausted :reason :recovery-checkpoint-outcomes))
    (incf closed-bytes (* outcomes +closure-outcome-bytes+))
    (let* ((removed-bytes (* removed +removed-id-bytes+))
           (payload (+ +edit-min-bytes+ closed-bytes removed-bytes))
           (arrays (+ payload closed-bytes removed-bytes (* 8 (+ closed removed outcomes)))))
      (when (or (> payload max-payload)
                (> payload (- (nth-value 1 (arcdocdb.record::format-limits version)) arcdocdb.record:+header-bytes+)))
        (error 'resource-exhausted :reason :recovery-checkpoint-payload))
      (when (> arrays workspace) (error 'resource-exhausted :reason :recovery-checkpoint-workspace))
      (values closed-bytes removed-bytes payload))))
