;;; OWNER: gettone writer della Serie e scratch esclusivo, nessun altro mutatore.
;;; SHARED: chiave prima del payload, payload prima del controllo; nessun ritorno a EMPTY.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice octets fixnum fixnum u32
                                         contenuto-slot contenuto-slot)
                         (values fixnum boolean fixnum &optional)) prepara-chiave-writer))
(defun prepara-chiave-writer (index fragment key start end low source work)
  "Pre: writer, SOURCE privata valida, WORK scratch distinto. Post: slot, trovato-p e offset chiave.
Verifica capacità, arena, monotonia CSN e credito prima dei cambi; WORK contiene il nuovo payload.
Non prenota risorse dei lotti pendenti e non autorizza un commit durevole."
  (multiple-value-bind (slot found) (sonda-writer fragment key start end low work)
    (let* ((size (- end start)) (bank (frammento-indice-bank fragment))
           (offset (if found (ldb (byte 32 0) (aref work 2)) (frammento-indice-used fragment))))
      (when (minusp slot) (error 'resource-exhausted :reason :primary-fragment-full))
      (unless found
        (when (>= (frammento-indice-live fragment) (* 7 (ash (banco-slot-capacity bank) -3)))
          (error 'resource-exhausted :reason :primary-fragment-load))
        (when (> (+ offset size) (length (frammento-indice-arena fragment)))
          (error 'resource-exhausted :reason :primary-key-arena-full)))
      (when (and found (<= (aref source 0) (aref work 0)))
        (error 'invalid-argument :reason :primary-csn-not-increasing))
      (when (zerop (credito-scrittura-slot bank slot))
        (error 'resource-exhausted :reason :primary-slot-rebuild-required))
      (esigi-revisione index)
      (copia-contenuto source work)
      (setf (aref work 2) (logior offset (ash size 32) (ash 1 48)))
      (values slot found offset))))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-AFF-004
(declaim (ftype (function (indice-primario frammento-indice octets fixnum fixnum u32 fixnum
                                         boolean fixnum contenuto-slot) null) applica-chiave-writer))
(defun applica-chiave-writer (index fragment key start end low slot found offset work)
  "Pre: preflight completo e writer esclusivo. Post: payload e controllo pubblicati in ordine.
Interruzione composta rende FAULTED indice/banco, anche dopo payload pari; niente rollback."
  (let ((bank (frammento-indice-bank fragment)) (complete nil))
    (unwind-protect
         (progn
           (incf (indice-primario-revision index))
           (unless found
             (replace (frammento-indice-arena fragment) key :start1 offset :start2 start :end2 end)
             (incf (frammento-indice-used fragment) (- end start)))
           (pubblica-slot-v2 bank slot work)
           (sb-thread:barrier (:write))
           (setf (aref (frammento-indice-controls fragment) slot) (logand low 127))
           (unless found (incf (frammento-indice-live fragment)))
           (esigi-frammento-sano index fragment)
           (setf complete t))
      (unless complete (invalida-banco-slot bank) (invalida-indice-primario index))))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-005 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice octets integer integer u32 u32
                                         contenuto-slot contesto-indice) null) pubblica-chiave-indice))
(defun pubblica-chiave-indice (index fragment key start end high low source context)
  "Pre: writer, digest coerente; retention, conflitti, commit e prenotazioni dei lotti risolti fuori.
SOURCE v2 vivo con key-len dello span, offset arena sostituito internamente; scratch distinto.
Post: una chiave viva, CSN strettamente crescente su update; nessun I/O o commit attestato.
Capacità/sequenza/arena insufficienti rifiutate prima della mutazione; rebuild/split esterni."
  (esigi-frammento-writer index fragment high)
  (esigi-chiave key start end)
  (esigi-contenuto-slot (frammento-indice-bank fragment) source)
  (unless (= (- end start) (ldb (byte 16 32) (aref source 2)))
    (error 'invalid-argument :reason :primary-source-key-length))
  (when (eq source (contesto-indice-words context))
    (error 'invalid-argument :reason :primary-source-alias))
  (esigi-contesto-libero context)
  (unwind-protect
       (progn
         (setf (contesto-indice-busy context) t)
         (multiple-value-bind (slot found offset)
             (prepara-chiave-writer index fragment key start end low source (contesto-indice-words context))
           (applica-chiave-writer index fragment key start end low slot found offset
                                 (contesto-indice-words context))))
    (setf (contesto-indice-busy context) nil)))

;;; REQ: REQ-IDX-003 REQ-IDX-006 REQ-AFF-004
(declaim (ftype (function (indice-primario frammento-indice fixnum) null) applica-rimozione-writer))
(defun applica-rimozione-writer (index fragment slot)
  "Pre: slot vivo verificato, credito e revisione disponibili. Post: slot zero poi DELETED.
Non modifica le chiavi e non crea tombstone persistenti; interruzione => dominio FAULTED."
  (let ((bank (frammento-indice-bank fragment)) (complete nil))
    (unwind-protect
         (progn
           (incf (indice-primario-revision index))
           (rimuovi-slot-v2 bank slot)
           (sb-thread:barrier (:write))
           (setf (aref (frammento-indice-controls fragment) slot) +ctrl-deleted+)
           (decf (frammento-indice-live fragment))
           (esigi-frammento-sano index fragment)
           (setf complete t))
      (unless complete (invalida-banco-slot bank) (invalida-indice-primario index))))
  nil)

;;; REQ: REQ-IDX-003 REQ-IDX-006 REQ-AFF-008
(declaim (ftype (function (indice-primario frammento-indice octets integer integer u32 u32 contesto-indice)
                         boolean) rimuovi-chiave-indice))
(defun rimuovi-chiave-indice (index fragment key start end high low context)
  "Pre: writer, retention/tombstone e prenotazioni esterni già gestiti. Post: T rimossa, NIL assente.
L'assenza non consuma sequenza/revisione; slot e chiavi non attraversano una migrazione."
  (esigi-frammento-writer index fragment high)
  (esigi-chiave key start end)
  (esigi-contesto-libero context)
  (unwind-protect
       (progn
         (setf (contesto-indice-busy context) t)
         (multiple-value-bind (slot found)
             (sonda-writer fragment key start end low (contesto-indice-words context))
           (esigi-frammento-sano index fragment)
           (unless found (return-from rimuovi-chiave-indice nil))
           (when (zerop (credito-scrittura-slot (frammento-indice-bank fragment) slot))
             (error 'resource-exhausted :reason :primary-slot-rebuild-required))
           (esigi-revisione index)
           (applica-rimozione-writer index fragment slot)
           t))
    (setf (contesto-indice-busy context) nil)))
