;;; OWNER: attore di startup, directory vuota posseduta ed esclusiva prima di ogni nuovo file.
;;; SHARED: nessuna pubblicazione runtime; i file mantengono i formati definitivi del prodotto.
(in-package #:arcdocdb.engine)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-STO-003 REQ-AFF-008
(declaim (ftype (function (motore c:checkpoint-control) c:control-preparato) prepara-control-motore))
(defun prepara-control-motore (engine plan)
  "Pre: piano completo, control.log.tmp assente e namespace esclusivo. Post: temporaneo durevole verificato.
File registrati per cleanup; punto di atomicita' resta la successiva pubblicazione CONTROL."
  (let* ((append (output-motore engine "control.log.tmp")) (input (input-motore engine "control.log.tmp")))
    (c:prepara-checkpoint-control plan input append (motore-directory engine) (motore-scratch engine))))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-AFF-001
(declaim (ftype (function (motore) null) inizializza-decisioni-motore))
(defun inizializza-decisioni-motore (engine)
  "Pre: directory nuova esclusiva. Post: header decision log canonico durevole e nome completato.
Nessuna DECISION o admission; atomicita' di creazione al nome esclusivo, poi fsync parent."
  (let ((append (output-motore engine "multiserie.log.tmp")) (buffer (motore-scratch engine)))
    (unless (= f:+log-header-bytes+
               (f:scrivi-header-log buffer 0 :multiserie (motore-archive-id engine)
                                   :version (motore-version engine)))
      (error 'invariant-violation :reason :engine-decision-header))
    (unless (= f:+log-header-bytes+ (io:append-esatto append buffer 0 f:+log-header-bytes+)
               (io:durable-flush append))
      (error 'invariant-violation :reason :engine-decision-durable))
    (io:pubblica-temporaneo (motore-directory engine) (input-motore engine "multiserie.log.tmp")
                           "multiserie.log.tmp" "multiserie.log")
    (io:durable-flush (motore-directory engine)))
  nil)

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-FOR-003 REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (motore) null) inizializza-storage-motore))
(defun inizializza-storage-motore (engine)
  "Pre: init esplicito e lock directory posseduto. Post: file canonici iniziali durevoli, admission chiusa.
Rifiuta directory non vuota prima degli effetti; non inizializza o cancella uno storage preesistente.
Punto di decisione: pubblicazione CONTROL completo; guasti conservano i preparati senza rollback."
  (unless (zerop (length (io:elenca-directory (motore-directory engine))))
    (error 'invalid-argument :reason :engine-initialization-not-empty))
  (let* ((prepared (prepara-active-motore engine 1))
         (payload (make-array f::+edit-min-bytes+ :element-type '(unsigned-byte 8) :initial-element 0)))
    (unless (= (length payload) (f:scrivi-valore-edit payload 0 2 1 (motore-empty engine) 0
                                                     (motore-empty engine) :completo t))
      (error 'invariant-violation :reason :engine-initial-edit))
    (inizializza-decisioni-motore engine)
    (prepara-control-motore engine (c:crea-checkpoint-control prepared payload 1))
    (io:pubblica-temporaneo (motore-directory engine) (input-motore engine "control.log.tmp")
                           "control.log.tmp" "control.log")
    (io:durable-flush (motore-directory engine)))
  (osserva-motore engine :storage-created)
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (motore u64) null) conserva-control-incompleto-motore))
(defun conserva-control-incompleto-motore (engine fresh-id)
  "Pre: vecchio CONTROL autorevole verificato, ID fresco riservato da nuovo segmento e lock posseduto.
Post: control.log.tmp precedente conservato sotto nome distinto, target assente verificato.
Nessun file eliminato; rename relativo seguito da fsync, prima del nuovo checkpoint atomico."
  (let ((names (io:elenca-directory (motore-directory engine)))
        (target (format nil "control.unpublished.~16,'0x.tmp" fresh-id)))
    (when (find "control.log.tmp" names :test #'string=)
      (when (find target names :test #'string=)
        (error 'invalid-argument :reason :engine-control-quarantine-collision))
      (input-motore engine "control.log.tmp")
      (io:rinomina-nella-directory (motore-directory engine) "control.log.tmp" target)
      (io:durable-flush (motore-directory engine))
      (osserva-motore engine :unpublished-control-preserved)))
  nil)
