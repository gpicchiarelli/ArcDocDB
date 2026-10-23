;;; OWNER: coordinatore Archivio nel pool I/O, prima di checkpoint, binding runtime e ammissione.
;;; SHARED: piano scalare e conteggi privati; nessun lock, thread o nuovo registro fra Serie.
(in-package #:arcdocdb.recovery.bootstrap)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-TXM-005 REQ-TXM-007 REQ-MVC-006 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (insieme-serie-recovery decisioni-recuperate t t t t
                          &key (:max-segmenti-serie index) (:max-segmenti-totali index))
                         (values piano-csn-archivio index index &optional)) stabilizza-nomi-archivio-recuperato))
(defun stabilizza-nomi-archivio-recuperato (set decisions directories sources active closed
                                         &key (max-segmenti-serie 65536) (max-segmenti-totali 1048576))
  "Pre: catalogo completo, stesso replay, vettori paralleli; FD e namespace esclusivi/stabili nel pool I/O.
Post: piano CSN riconfermato e conteggi rinominati/gia' definitivi completi, somma uguale ai segmenti.
Tutti i budget/metadata, gate Archivio e preflight nomi prima di effetti, ordine del catalogo.
Guasti originali senza risultato parziale/rollback/retry/close; completamenti precedenti conservati.
Nessun nuovo ACTIVE, rimozione, checkpoint, indice, CSN operativo o ammissione del traffico."
  (let* ((count (verifica-forma-stabilizzazione-archivio
                 set decisions directories sources active closed max-segmenti-totali))
         (segments (verifica-capienza-stabilizzazione-archivio
                    sources active closed count max-segmenti-serie max-segmenti-totali)))
    (verifica-metadata-stabilizzazione-archivio sources active closed count max-segmenti-serie)
    (let ((plan (crea-piano-csn-archivio set decisions active closed
                  :max-segmenti-serie max-segmenti-serie :max-segmenti-totali max-segmenti-totali))
          (renamed 0) (final 0))
      (multiple-value-bind (actual-series actual-segments) (statistiche-piano-csn-archivio plan)
        (unless (and (= actual-series count) (= actual-segments segments))
          (error 'invariant-violation :reason :archive-stabilization-plan-count)))
      (verifica-nomi-stabilizzazione-archivio directories sources count)
      (dotimes (i count)
        (multiple-value-bind (r f)
            (arcdocdb.recovery.series:stabilizza-nomi-serie-recuperata
             (the arcdocdb.io:file-io (svref directories i)) (the recovery-sources (svref sources i))
             (the arcdocdb.recovery.active:active-recuperato (svref active i))
             (the simple-vector (svref closed i)) :max-segmenti max-segmenti-serie)
          (incf renamed r) (incf final f)))
      (unless (= (+ renamed final) segments)
        (error 'invariant-violation :reason :archive-stabilization-result-count))
      (arcdocdb.io::esigi-aperto (arcdocdb.recovery.archive::decisioni-recuperate-input decisions) :input)
      (values plan renamed final))))
