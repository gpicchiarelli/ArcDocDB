;;; OWNER: writer modifica geometria/revisione; il confine della Serie propaga i guasti.
;;; SHARED: reader acquisisce solo salute e root; nessun mutex, I/O o coordinamento tra Serie.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-004 REQ-IDX-003
(declaim (ftype (function (indice-primario) null) invalida-indice-primario))
(defun invalida-indice-primario (index)
  "Pre: guasto interno o confine fidato. Post: FAULTED terminale, nessuna cancellazione o reset.
Ripetibile senza mutex; il controller della Serie interrompe ammissione e pubblicazioni."
  (sb-thread:barrier (:write))
  (setf (indice-primario-health index) :faulted)
  nil)

;;; REQ: REQ-AFF-004 REQ-IDX-007
(declaim (ftype (function (indice-primario keyword) nil) guasto-indice))
(defun guasto-indice (index reason)
  "Pre: invariante interna violata. Post: indice FAULTED prima di INVARIANT-VIOLATION.
Nessun recupero locale o rimozione dei vecchi frammenti."
  (invalida-indice-primario index)
  (error 'invariant-violation :reason reason))

;;; REQ: REQ-IDX-003 REQ-IDX-007 REQ-AFF-004
(declaim (inline esigi-indice-sano acquisisci-root esigi-revisione prefix-hash
                 esigi-chiave esigi-frammento-sano controllo-valido-p))
(declaim (ftype (function (indice-primario) null) esigi-indice-sano))
(defun esigi-indice-sano (index)
  "Pre: indice canonico. Post: salute OPEN acquisita; su guasto nessun risultato utilizzabile."
  (let ((health (indice-primario-health index)))
    (sb-thread:barrier (:read))
    (unless (eq health :open) (guasto-indice index :primary-index-faulted)))
  nil)

;;; REQ: REQ-IDX-007 REQ-AFF-004
(declaim (ftype (function (indice-primario) root-indice) acquisisci-root))
(defun acquisisci-root (index)
  "Pre: indice inizializzato. Post: root acquisita dopo load/barriera; NIL è un guasto interno."
  (let ((root (indice-primario-root index)))
    (sb-thread:barrier (:read))
    (unless root (guasto-indice index :primary-index-missing-root))
    root))

;;; REQ: REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (indice-primario) null) esigi-revisione))
(defun esigi-revisione (index)
  "Pre: writer esclusivo prima di qualsiasi mutazione. Post: credito per revisione monotona.
Esaurimento rifiutato prima dei cambi; nessun wrap o reset dell'identità."
  (esigi-indice-sano index)
  (when (>= (indice-primario-revision index) (1- +revision-limit+))
    (error 'resource-exhausted :reason :primary-index-revision-exhausted))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-007
(declaim (ftype (function (u32 (integer 0 30)) fixnum) prefix-hash))
(defun prefix-hash (high depth)
  "Pre: metà alta del digest fidato a 64 bit. Post: DEPTH bit più alti, fixnum senza boxing u64."
  (ash high (- depth 32)))

;;; REQ: REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (octets integer integer) null) esigi-chiave))
(defun esigi-chiave (key start end)
  "Pre: span privato/immutabile per l'intera operazione. Post: chiave binaria di 1..65535 byte.
Input/range invalidi rifiutati prima di mutazioni; nessuna decodifica o normalizzazione."
  (check-range key start end)
  (unless (<= 1 (- end start) 65535) (error 'invalid-argument :reason :primary-key-length))
  nil)

;;; REQ: REQ-IDX-003 REQ-AFF-004
(declaim (ftype (function (indice-primario frammento-indice) null) esigi-frammento-sano))
(defun esigi-frammento-sano (index fragment)
  "Pre: frammento canonico della Serie. Post: dominio e banco sani acquisiti.
Un banco FAULTED rende terminale l'indice; riferimento esterno rifiutato senza mutazioni."
  (unless (eq index (frammento-indice-owner fragment))
    (error 'invalid-argument :reason :primary-fragment-owner))
  (esigi-indice-sano index)
  (let ((health (banco-slot-health (frammento-indice-bank fragment))))
    (sb-thread:barrier (:read))
    (unless (eq health :open) (guasto-indice index :primary-fragment-faulted)))
  nil)

;;; REQ: REQ-IDX-001 REQ-AFF-004
(declaim (ftype (function ((unsigned-byte 8)) boolean) controllo-valido-p))
(defun controllo-valido-p (control)
  "Pre: byte acquisito oppure writer esclusivo. Post: fingerprint 0..127, EMPTY o DELETED."
  (or (< control 128) (= control +ctrl-empty+) (= control +ctrl-deleted+)))
