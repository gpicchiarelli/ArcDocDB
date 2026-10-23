;;; OWNER: writer con lease verifica il lotto OPEN prima di assegnare CSN o adottare un evento.
;;; SHARED: nessuna prenotazione/radice mutata; header del solo lotto locale.
(in-package #:arcdocdb.get.resolver)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-WAL-005 REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (sorgente-get-attiva lotto) u32) conta-put-aperti-attivi))
(defun conta-put-aperti-attivi (source batch)
  "Pre: OPEN esclusivo senza token, count/byte entro budget. Post: header/forma ordinari e count esatti.
Al più count header, nessuna verifica body o attestazione di commit; CSN verrà fissato dal SEAL.
Prepared/OUTCOME validi rifiutati prima del CSN; integrità completa ripetuta solo dopo la chiusura."
  (let ((pos 0) (puts 0) (buffer (arcdocdb.wal::lotto-buffer batch))
        (end (lunghezza-lotto batch)) (version (segmento-get-version (sorgente-get-attiva-segment source))))
    (declare (type u32 pos puts))
    (dotimes (i (arcdocdb.wal::lotto-count batch))
      (multiple-value-bind (next kind flags ks vs ve)
          (checked-header buffer pos end version +max-document-bytes+)
        (declare (ignore ks vs ve)) ; lunghezze/forma già controllate, non esiti.
        (unless (< pos next (1+ end)) (error 'invariant-violation :reason :active-open-progress))
        (when (logtest flags +prepared+) (error 'invalid-argument :reason :active-prepared-unsupported))
        (case kind
          (#.+put+ (incf puts)) (#.+tombstone+ nil)
          (#.+outcome+ (error 'invalid-argument :reason :active-outcome-unsupported))
          (otherwise (error 'invariant-violation :reason :active-open-kind)))
        (setf pos next)))
    (unless (= pos end) (error 'invariant-violation :reason :active-open-count))
    puts))

;;; REQ: REQ-WAL-005 REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (sorgente-get-attiva lotto index) null) verifica-misure-aperte-attive))
(defun verifica-misure-aperte-attive (source batch start)
  "Pre: OPEN senza token. Post: ID/versione, count, byte compreso SEAL e spazio segmento ammessi.
Rifiuti prima del CSN; nessun buffer/evento/indice mutato, nessun I/O o allocazione di array."
  (let* ((segment (sorgente-get-attiva-segment source))
         (size (+ (lunghezza-lotto batch) arcdocdb.wal::+seal-total+)))
    (unless (and (= (arcdocdb.wal::lotto-file-id batch) (segmento-get-low segment))
                 (= (arcdocdb.wal::lotto-version batch) (segmento-get-version segment)))
      (error 'invalid-argument :reason :active-batch-identity))
    (when (zerop (arcdocdb.wal::lotto-count batch)) (error 'invalid-argument :reason :active-open-empty))
    (when (> (arcdocdb.wal::lotto-count batch) (sorgente-get-attiva-batch-records source))
      (error 'resource-exhausted :reason :active-batch-record-budget))
    (when (> size (sorgente-get-attiva-batch-bytes source))
      (error 'resource-exhausted :reason :active-batch-byte-budget))
    (unless (<= +segment-header-bytes+ start (- +segment-max-bytes+ size))
      (error 'resource-exhausted :reason :active-segment-budget)))
  nil)

;;; REQ: REQ-WAL-005 REQ-WAL-006 REQ-IDX-001 REQ-AFF-008 REQ-AFF-001
(declaim (ftype (function (sorgente-get-attiva t lotto (or null radice-get-attiva)) u32)
                verifica-capienza-get-attiva))
(defun verifica-capienza-get-attiva (source lease batch previous)
  "Pre: lease esclusiva, lotto OPEN senza token; chiamare PRIMA di sigilla-lotto-con-csn.
Post: ring, forma supportata, contiguità e picco ammessi; ritorna numero PUT, niente prenotazione.
Mantenere lease, contenuto e previous stabili fino a sigillatura/adozione, che ricontrolla tutto.
Rifiuti senza CSN/evento; integrità/invarianti interne => FAULTED Archivio, causa originale propagata."
  (let ((controller (sorgente-get-attiva-controller source)))
    (arcdocdb.series::%check-owner controller lease) (arcdocdb.series::%require-healthy controller)
    (handler-case
        (arcdocdb.wal::esigi-lotto batch :open)
      (invariant-violation (condition) (arcdocdb.series::%mark-fault controller :archive) (error condition)))
    (when (arcdocdb.wal::lotto-csn-registry batch) (error 'invalid-argument :reason :active-open-bound))
    (unless (eq previous (arcdocdb.series::controllore-serie-planned-root controller))
      (error 'invalid-argument :reason :active-root-order))
    (when (= (arcdocdb.series::controllore-serie-count controller)
             (length (arcdocdb.series::controllore-serie-slots controller)))
      (error 'resource-exhausted :reason :serie-full))
    (when (= (arcdocdb.series::controllore-serie-event-generation controller) most-positive-fixnum)
      (error 'resource-exhausted :reason :serie-event-generation))
    (handler-case
        (let ((start (arcdocdb.series::controllore-serie-next-offset controller)))
          (verifica-misure-aperte-attive source batch start)
          (let ((puts (conta-put-aperti-attivi source batch)))
            (verifica-delta-attivo source previous start puts)
            puts))
      (corruption-detected (condition) (arcdocdb.series::%mark-fault controller :archive) (error condition))
      (invariant-violation (condition) (arcdocdb.series::%mark-fault controller :archive) (error condition)))))
