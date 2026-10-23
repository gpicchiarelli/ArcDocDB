;;; OWNER: motore registra subito ogni capacita', set chiusi prima dei FD espliciti/parent.
;;; SHARED: nomi e array solo di startup; nessun file esistente aperto in scrittura.
(in-package #:arcdocdb.engine)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-004
(declaim (ftype (function (motore io:file-io) io:file-io) possiedi-file-motore))
(defun possiedi-file-motore (engine file)
  "Pre: nuova capacita' restituita all'owner, nessuna cancellazione asincrona del thread.
Post: risorsa registrata per cleanup completo; nessun FD esportato o secondo proprietario."
  (push file (motore-fds engine)) file)

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-004
(declaim (ftype (function (motore string) (values io:file-io index &optional)) input-motore))
(defun input-motore (engine name)
  "Pre: namespace esclusivo, parent posseduto. Post: readonly ed EOF sul medesimo FD, registrato.
Errori originali delle aperture relative; nessuna riapertura in scrittura."
  (multiple-value-bind (file size)
      (io:apri-lettura-nella-directory (motore-directory engine) name
                                     :max-transfer (motore-max-file-bytes engine)
                                     :max-file-bytes (motore-max-file-bytes engine))
    (values (possiedi-file-motore engine file) size)))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-004
(declaim (ftype (function (motore string) io:file-io) output-motore))
(defun output-motore (engine name)
  "Pre: temporaneo nuovo riservato nel namespace esclusivo. Post: append O_EXCL registrato.
Collisioni preservate e condizioni originali; nessun file esistente troncato o riaperto."
  (possiedi-file-motore engine
    (io:crea-temporaneo-nella-directory (motore-directory engine) name
       :max-transfer (motore-max-file-bytes engine) :max-file-bytes (motore-max-file-bytes engine))))

;;; REQ: REQ-FOR-001 REQ-REC-001
(declaim (ftype (function (u64 (member :temporary :final)) simple-base-string) nome-segmento-motore))
(defun nome-segmento-motore (id form)
  "Pre: ID u64 e forma canonica. Post: foglia di formato unica della recovery, nessun pathname derivato."
  (arcdocdb.recovery.manifest::nome-fonte-recovery id form))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-001
(declaim (ftype (function (motore u64) a:segmento-attivo-preparato) prepara-active-motore))
(defun prepara-active-motore (engine id)
  "Pre: ID fresco <=u32 dal planner, namespace esclusivo. Post: nuovo header durevole e riletto.
Append/readonly registrati; prima dell'EDIT autorevole, nessuna admission o distruzione."
  (unless (<= 1 id #xffffffff) (error 'resource-exhausted :reason :engine-segment-id-range))
  (let* ((name (nome-segmento-motore id :temporary)) (append (output-motore engine name))
         (input (input-motore engine name)))
    (a:prepara-segmento-attivo (motore-view engine) input append (motore-directory engine) id 0
                             (make-array f:+segment-header-bytes+ :element-type '(unsigned-byte 8))
                             (motore-scratch engine) :version (motore-version engine))))

;;; REQ: REQ-REC-001 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (motore) c:control-recuperato) leggi-control-motore))
(defun leggi-control-motore (engine)
  "Pre: CONTROL autorevole, namespace esclusivo. Post: intero EOF verificato sullo stesso FD.
Nessun byte o manifest pubblicato al client; limiti M1 applicati dal reader canonico."
  (multiple-value-bind (file size) (input-motore engine "control.log")
    (c:leggi-control-recuperato (motore-view engine) file size (motore-scratch engine)
       :max-bytes (motore-max-file-bytes engine) :max-segmenti (motore-max-segments engine))))

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (motore c:control-recuperato) mf::recovery-sources) fonti-motore))
(defun fonti-motore (engine control)
  "Pre: CONTROL canonico, namespace esclusivo. Post: set completo posseduto e registrato.
EOF/file budget prima dei reader; nessuna capacita' figlia chiusa separatamente."
  (let ((set (mf:apri-fonti-recovery (c:manifest-control-recuperato control) (motore-directory engine)
               :max-segmenti (motore-max-segments engine) :max-files (* 2 (motore-max-segments engine))
               :max-file-bytes (motore-max-file-bytes engine)
               :max-transfer (motore-max-file-bytes engine)
               :max-total-file-bytes (* (motore-max-segments engine) (motore-max-file-bytes engine)))))
    (push set (motore-recovery-sets engine)) set))
