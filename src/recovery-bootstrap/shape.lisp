;;; OWNER: controllo delle autorità e della forma prima di scansioni delle fonti o allocazioni.
;;; SHARED: solo letture; il set del catalogo possiede già le viste ordinate.
(in-package #:arcdocdb.recovery.bootstrap)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (insieme-serie-recovery decisioni-recuperate t t t index index) index)
                verifica-ingressi-bootstrap))
(defun verifica-ingressi-bootstrap (set decisions controls sources limits max-segments references)
  "Pre: set completo autorevole del catalogo, fonti e vettori congelati. Post: count e budget vettori esterni.
Stesso oggetto Archivio delle decisioni, tre simple-vector paralleli alle viste; nessuna copia o I/O.
INVALID-ARGUMENT per autorità/forma/count; RESOURCE-EXHAUSTED prima di scansioni o array risultato."
  (unless (eq (arcdocdb.recovery.archive.csn::insieme-serie-recovery-archive set)
              (arcdocdb.recovery.archive::decisioni-recuperate-archive decisions))
    (error 'invalid-argument :reason :archive-bootstrap-decision-owner))
  (unless (and (typep controls 'simple-vector) (typep sources 'simple-vector) (typep limits 'simple-vector))
    (error 'invalid-argument :reason :archive-bootstrap-vectors))
  (let ((count (arcdocdb.recovery.archive.csn:numero-serie-recovery set)))
    (unless (and (= count (length controls)) (= count (length sources)) (= count (length limits)))
      (error 'invalid-argument :reason :archive-bootstrap-series-count))
    (when (> count max-segments) (error 'resource-exhausted :reason :archive-bootstrap-segment-budget))
    (when (> (* 16 count) references) (error 'resource-exhausted :reason :archive-bootstrap-reference-budget))
    count))
