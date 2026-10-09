;;; OWNER: worker con contesto esclusivo; il writer possiede root e frammenti.
;;; SHARED: solo load e barriere sul successo; controllo finale anche sul miss.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-003 REQ-CON-004 REQ-AFF-008
(declaim (inline esigi-contesto-libero))
(declaim (ftype (function (contesto-indice) null) esigi-contesto-libero))
(defun esigi-contesto-libero (context)
  "Pre: worker/controller proprietario. Post: contesto libero, nessuna modifica.
Rientro rifiutato prima di toccare lo scratch; non sincronizza due worker che violano l'ownership."
  (when (contesto-indice-busy context) (error 'invalid-argument :reason :primary-context-busy))
  nil)

;;; REQ: REQ-IDX-007 REQ-AFF-004
(declaim (inline root-confermata-p))
(declaim (ftype (function (indice-primario root-indice) boolean) root-confermata-p))
(defun root-confermata-p (index original)
  "Pre: risultato provvisorio hit o miss. Post: stessa identità/generazione dopo le letture.
Non rende la location un pin EBR e non verifica l'orizzonte di commit o uno snapshot."
  (sb-thread:barrier (:read))
  (let ((current (acquisisci-root index)))
    (and (eq original current) (= (root-indice-generation original) (root-indice-generation current)))))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-IDX-007 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (indice-primario octets integer integer u32 u32 contesto-indice contenuto-slot)
                         (member :live :absent :retry-limit)) leggi-indice-primario))
(defun leggi-indice-primario (index key start end high low context destination)
  "Pre: chiave/digest fidati coerenti per Serie, contesto e DESTINATION privati distinti.
Post: LIVE copia il payload dopo conferma della root; ABSENT/RETRY-LIMIT non toccano DESTINATION.
Otto campioni slot/cambi root complessivi, nessun lock, attesa o ripiego interno.
Errori/uscite non locali invalidano il risultato; EBR, MVCC e inoltro al writer sono del chiamante."
  (esigi-indice-sano index)
  (esigi-chiave key start end)
  (when (eq destination (contesto-indice-words context))
    (error 'invalid-argument :reason :primary-output-alias))
  (esigi-contesto-libero context)
  (unwind-protect
       (progn
         (setf (contesto-indice-busy context) t (contesto-indice-remaining context) +lookup-budget+)
         (dotimes (attempt +lookup-budget+)
           (when (zerop (contesto-indice-remaining context)) (return))
           (let* ((root (acquisisci-root index))
                  (fragment (aref (root-indice-directory root) (prefix-hash high (root-indice-depth root)))))
             (esigi-frammento-sano index fragment)
             (let ((result (sonda-reader fragment key start end low context)))
               (esigi-frammento-sano index fragment)
               (when (= result -3) (return))
               (when (>= result -1)
                 (if (root-confermata-p index root)
                     (progn
                       (when (>= result 0) (copia-contenuto (contesto-indice-words context) destination))
                       (esigi-frammento-sano index fragment)
                       (return-from leggi-indice-primario (if (>= result 0) :live :absent)))
                     (when (plusp (contesto-indice-remaining context))
                       (decf (contesto-indice-remaining context))))))))
         (esigi-indice-sano index)
         :retry-limit)
    (setf (contesto-indice-busy context) nil)))
