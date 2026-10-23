;;;; Query e cleanup limitato: tutte le capacità acquisite ricevono un tentativo di close.
;;; OWNER: set e close esclusivi; query/letture soltanto prima della chiusura.
;;; SHARED: nessuna mutazione fra Serie, nessuna chiusura del parent prestato.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-004
(declaim (ftype (function (recovery-sources)
                         (values (or null arcdocdb.conditions:io-fault) index &optional))
                cleanup-fonti-recovery))
(defun cleanup-fonti-recovery (sources)
  "Pre: nessun reader né cancellazione asincrona; entry anche parziali. Post: set chiuso, tutti tentati.
Ritorna primo IO-FAULT e numero totale; seconda chiamata no-op, nessun retry o errore nascosto."
  (let ((first-error nil) (failures 0))
    (unless (%rss-closed sources)
      (setf (%rss-closed sources) t)
      (let ((entries (%rss-entries sources)))
        (dotimes (i (length entries))
          (let ((file (%rs-file (the recovery-source (aref entries i)))))
            (when file
              (handler-case (arcdocdb.io:chiudi file)
                (arcdocdb.conditions:io-fault (condition)
                  (unless first-error (setf first-error condition))
                  (incf failures))))))))
    (values first-error failures)))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-004
(declaim (ftype (function (recovery-sources) null) chiudi-fonti-recovery))
(defun chiudi-fonti-recovery (sources)
  "Pre: proprietario esclusivo, tutti i reader terminati. Post: tutti i child chiusi una volta, parent intatto.
RECOVERY-SOURCES-CLEANUP-ERROR dopo tutti i tentativi; primaria NIL. Ripetizione idempotente."
  (multiple-value-bind (cleanup count) (cleanup-fonti-recovery sources)
    (when cleanup
      (error 'recovery-sources-cleanup-error :reason :recovery-sources-cleanup
             :primary nil :cleanup cleanup :count count)))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-008
(declaim (ftype (function (recovery-sources) (values index &optional)) numero-fonti-recovery))
(defun numero-fonti-recovery (sources)
  "Pre: set pubblicato, anche chiuso. Post: cardinalità immutabile, nessuna capacità esposta."
  (length (%rss-entries sources)))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-008
(declaim (ftype (function (recovery-sources integer)
                         (values u64 (member :active :closed) (member :final :temporary)
                                 arcdocdb.io:file-io index &optional)) fonte-recovery))
(defun fonte-recovery (sources position)
  "Pre: set aperto, indice valido e nessun close concorrente. Post: ID/stato/forma/child prestato/EOF.
INVALID-ARGUMENT per set chiuso o indice; IO-FAULT per child chiuso; guardia interna se assente.
Il caller non chiude il child: termina i reader e chiude l'intero set. Nessuna validazione dei byte."
  (when (%rss-closed sources) (error 'invalid-argument :reason :recovery-sources-closed))
  (unless (<= 0 position (1- (numero-fonti-recovery sources)))
    (error 'invalid-argument :reason :recovery-sources-index))
  (let* ((entry (the recovery-source (aref (%rss-entries sources) position)))
         (file (%rs-file entry)))
    (unless file (error 'invariant-violation :reason :recovery-source-unopened))
    (arcdocdb.io::esigi-aperto file :input)
    (values (%rs-id entry) (%rs-state entry) (%rs-form entry) file (%rs-size entry))))
