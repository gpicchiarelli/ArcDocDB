;;; OWNER: coordinatore Archivio, vettori e capacita' prestati esclusivi/stabili nel pool I/O.
;;; SHARED: controlli scalari senza nuovi contenitori o stato condiviso fra Serie.
(in-package #:arcdocdb.recovery.bootstrap)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-AFF-008
(declaim (ftype (function (t t t t) null) verifica-riga-stabilizzazione-archivio))
(defun verifica-riga-stabilizzazione-archivio (directory sources active closed)
  "Pre: riga di quattro vettori paralleli stabili. Post: tipi canonici prima di accessori e scansioni.
INVALID-ARGUMENT per riga errata; nessuna lettura dei file, modifica di capacita' o allocazione."
  (unless (and (typep directory 'arcdocdb.io:file-io) (typep sources 'recovery-sources)
               (typep active 'arcdocdb.recovery.active:active-recuperato) (typep closed 'simple-vector))
    (error 'invalid-argument :reason :archive-stabilization-row))
  nil)

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-REC-004 REQ-TXM-005 REQ-AFF-008
(declaim (ftype (function (insieme-serie-recovery decisioni-recuperate t t t t index) index)
                verifica-forma-stabilizzazione-archivio))
(defun verifica-forma-stabilizzazione-archivio (set decisions directories sources active closed total)
  "Pre: catalogo completo e stesso replay; vettori/capacita' stabili. Post: count e tipi di tutte le righe.
INVALID-ARGUMENT per autorita'/forma/count; RESOURCE-EXHAUSTED per budget minimo prima delle righe.
FD decisioni ancora aperto; nessun effetto o nuovo vettore, ownership invariata."
  (unless (eq (arcdocdb.recovery.archive.csn::insieme-serie-recovery-archive set)
              (arcdocdb.recovery.archive::decisioni-recuperate-archive decisions))
    (error 'invalid-argument :reason :archive-stabilization-decision-owner))
  (unless (and (typep directories 'simple-vector) (typep sources 'simple-vector)
               (typep active 'simple-vector) (typep closed 'simple-vector))
    (error 'invalid-argument :reason :archive-stabilization-vectors))
  (let ((count (arcdocdb.recovery.archive.csn:numero-serie-recovery set)))
    (unless (and (= count (length directories)) (= count (length sources))
                 (= count (length active)) (= count (length closed)))
      (error 'invalid-argument :reason :archive-stabilization-series-count))
    (when (> count total) (error 'resource-exhausted :reason :archive-stabilization-segment-budget))
    (dotimes (i count)
      (verifica-riga-stabilizzazione-archivio
       (svref directories i) (svref sources i) (svref active i) (svref closed i)))
    (arcdocdb.io::esigi-aperto (arcdocdb.recovery.archive::decisioni-recuperate-input decisions) :input)
    count))
