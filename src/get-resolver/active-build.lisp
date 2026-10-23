;;; OWNER: writer con lease alloca il delta e lo adotta nel ring prima dell'I/O.
;;; SHARED: CAS/ring del controller esistente; nessuna modifica a worker, scheduler o WAL.
(in-package #:arcdocdb.get.resolver)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-008 REQ-IDX-001
(declaim (ftype (function (integer integer integer integer integer) null) verifica-budget-attivo))
(defun verifica-budget-attivo (pages puts records bytes budget)
  "Pre: configurazione esplicita prima dei compiti. Post: budget finiti rappresentabili.
INVALID-ARGUMENT prima di creare capacità o array; non cambia limiti dei documenti."
  (unless (and (<= 1 pages +active-max-pages+) (<= 1 puts #xffffffff)
               (<= 1 records arcdocdb.wal::+max-lotto-records+)
               (<= arcdocdb.wal::+seal-total+ bytes arcdocdb.wal::+max-lotto-bytes+)
               (<= 0 budget most-positive-fixnum))
    (error 'invalid-argument :reason :active-configuration))
  nil)

;;; REQ: REQ-WAL-006 REQ-FOR-001 REQ-AFF-008
(declaim (ftype (function (controllore-serie t segmento-get
                         &key (:max-pages integer) (:max-puts integer) (:batch-records integer)
                              (:batch-bytes integer) (:budget-payload integer)
                              (:associazione-file (or null associazione-file))) sorgente-get-attiva)
                crea-sorgente-get-attiva))
(defun crea-sorgente-get-attiva (controller lease segment
                                &key (max-pages 65536) (max-puts 1048576) (batch-records 65536)
                                     (batch-bytes 67108864) (budget-payload 67108864) associazione-file)
  "Pre: lease, nuovo ACTIVE con header verificato nel pool I/O; append/readonly dello STESSO file.
Post: sorgente locale pronta, nessun I/O/frontiera/pubblicazione. Header/id/versione confrontati.
INVALID-ARGUMENT per associazione/root già avviata; salute/invarianti propagano dal controller.
ASSOCIAZIONE-FILE verifica le capacità esatte senza I/O; nil mantiene la precondizione del caller.
Il caller conserva i FD fino al reclaim; il solo header non attesta identità fisica."
  (verifica-budget-attivo max-pages max-puts batch-records batch-bytes budget-payload)
  (arcdocdb.series::%check-owner controller lease) (arcdocdb.series::%require-healthy controller)
  (let ((log (arcdocdb.series::controllore-serie-log controller)))
    (verifica-log-segmento log)
    (when associazione-file
      (verifica-associazione-file associazione-file (segmento-get-file segment)
                                 (arcdocdb.wal::log-io-file log)))
    (unless (and (zerop (segmento-get-high segment)) (plusp (segmento-get-low segment))
                 (= (segmento-get-origin segment) +writer-origin+)
                 (= (segmento-get-low segment) (arcdocdb.wal::log-io-file-id log))
                 (= (segmento-get-version segment) (arcdocdb.wal::log-io-version log)))
      (error 'invalid-argument :reason :active-source-identity)))
  (unless (and (eq (mode-file (segmento-get-file segment)) :input)
               (eq (stato-file (segmento-get-file segment)) :open))
    (error 'invalid-argument :reason :active-source-file))
  (unless (and (null (arcdocdb.series::controllore-serie-planned-root controller))
               (zerop (arcdocdb.series::controllore-serie-count controller))
               (= (arcdocdb.series::controllore-serie-next-offset controller) +segment-header-bytes+))
    (error 'invalid-argument :reason :active-source-started))
  (%make-sorgente-get-attiva controller segment max-pages max-puts batch-records batch-bytes budget-payload))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-AFF-008
(declaim (ftype (function (sorgente-get-attiva (or null radice-get-attiva) index u32) null)
                verifica-delta-attivo))
(defun verifica-delta-attivo (source previous start puts)
  "Pre: root pianificata/lotto verificati. Post: contiguità, cardinalità e picco autorizzati prima degli array.
Picco = payload precedente + 24/new PUT + quattro vettori da 128 byte; nessuna copia dei vecchi PUT.
Esclude altre radici trattenute/eventi/oggetti: budget complessivo resta al controller.
INVALID-ARGUMENT per fonte/offset, RESOURCE-EXHAUSTED per saturazione, senza adozione."
  (when previous
    (unless (eq (radice-get-attiva-source previous) source)
      (error 'invalid-argument :reason :active-root-source)))
  (unless (= start (if previous (radice-get-attiva-end previous) +segment-header-bytes+))
    (error 'invalid-argument :reason :active-root-frontier))
  (when (>= (if previous (radice-get-attiva-count previous) 0) (sorgente-get-attiva-max-pages source))
    (error 'resource-exhausted :reason :active-page-budget))
  (when (> puts (- (sorgente-get-attiva-max-puts source) (if previous (radice-get-attiva-puts previous) 0)))
    (error 'resource-exhausted :reason :active-put-budget))
  (when (> (+ (if previous (payload-radice-get-attiva previous) 0) (* +active-row-payload+ puts)
              (* +active-directory-levels+ +active-node-payload+)) (sorgente-get-attiva-budget source))
    (error 'resource-exhausted :reason :active-payload-budget))
  nil)

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-AFF-008
(declaim (ftype (function (sorgente-get-attiva (or null radice-get-attiva) lotto u32 t) radice-get-attiva)
                costruisci-delta-attivo))
(defun costruisci-delta-attivo (source previous batch puts content)
  "Pre: delta ammesso e buffer sealed stabile. Post: root privata condividendo solo pagine immutabili.
Costruisce una pagina, quattro vettori e una root per lotto, senza catena di root precedenti.
Invarianti o allocazione incompleta non espongono la root e non adottano il lotto."
  (verifica-delta-attivo source previous (inizio-lotto batch) puts)
  (let* ((rows (make-array (* puts +row-words+) :element-type '(unsigned-byte 32) :initial-element 0))
         (end (+ (inizio-lotto batch) (lunghezza-lotto batch)))
         (rank (if previous (radice-get-attiva-count previous) 0)))
    (copia-put-attivi source batch rows)
    (multiple-value-bind (directory added)
        (appendi-pagina-attiva (if previous (radice-get-attiva-directory previous) nil) rank
                              (%make-mappa-segmento-get (sorgente-get-attiva-segment source) end rows)
                              +active-directory-shift+)
      (%make-radice-get-attiva source directory (1+ rank)
                              (+ puts (if previous (radice-get-attiva-puts previous) 0))
                              (+ added (if previous (radice-get-attiva-nodes previous) 0)) end content))))

;;; REQ: REQ-WAL-005 REQ-WAL-006 REQ-IDX-001 REQ-AFF-001
(declaim (ftype (function (sorgente-get-attiva t lotto (or null radice-get-attiva) t
                          (member :async :group :strong)) (values commit-serie index radice-get-attiva &optional))
                registra-lotto-get-attivo))
(defun registra-lotto-get-attivo (source lease batch previous content level)
  "Pre: lease e lotto SEALED con token CSN, prima dell'I/O; content/grafo del caller immutabili.
Post: evento/generation catturati e root pianificata; NON ancora acquisibile dai reader.
Il normale PUBBLICA-COMMIT-SERIE verifica copertura/durability e CAS prima di esporre la root.
Rifiuti pre-adozione conservano lotto/CSN al caller; interruzione nell'adozione => fail-stop Archivio."
  (let ((controller (sorgente-get-attiva-controller source)))
    (arcdocdb.series::%check-owner controller lease) (arcdocdb.series::%require-healthy controller)
    (arcdocdb.series::%check-admission controller batch previous level)
    (arcdocdb.series::%capture-token controller batch)
    (handler-case
        (let* ((puts (verifica-lotto-attivo source batch))
               (root (costruisci-delta-attivo source previous batch puts content)))
          (multiple-value-bind (event generation) (registra-commit-serie controller lease batch previous root level)
            (values event generation root)))
      ;; Il buffer sealed è del writer: integrità/forma impossibili sono un guasto interno.
      (corruption-detected (condition) (arcdocdb.series::%mark-fault controller :archive) (error condition))
      (invariant-violation (condition) (arcdocdb.series::%mark-fault controller :archive) (error condition)))))
