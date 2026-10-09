;;; OWNER: registrazione/rinnovo solo dopo che tutti i vecchi consumatori sono terminati.
;;; SHARED: annuncio della soglia precede la cattura del CSN; generazione zero invalida i reader.
(in-package #:arcdocdb.mvcc)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-007 REQ-MVC-004 REQ-AFF-008
(declaim (ftype (function (contesto-snapshot u64) csn-slot) prepara-registrazione-snapshot))
(defun prepara-registrazione-snapshot (context now)
  "Pre: mutex snapshot posseduto. Post: slot libero e tutti i budget prevalidati, senza mutazione.
INVALID-ARGUMENT per contesto con pin; RESOURCE-EXHAUSTED per K, generazioni o deadline u64."
  (let* ((registry (contesto-snapshot-registry context))
         (generation (aref (contesto-snapshot-word context) 0)) (slot (contesto-snapshot-slot context))
         (capacity (length (registro-snapshot-states registry))))
    (verifica-contatori-snapshot registry)
    (when (and (plusp generation) (< slot capacity)
               (= generation (aref (registro-snapshot-generations registry) slot))
               (snapshot-pinned-p (aref (registro-snapshot-states registry) slot)))
      (error 'invalid-argument :reason :snapshot-context-pinned))
    (when (= capacity (registro-snapshot-count registry))
      (error 'resource-exhausted :reason :snapshot-capacity))
    (when (= +max-csn+ (aref (registro-snapshot-words registry) 0))
      (error 'resource-exhausted :reason :snapshot-generation-exhausted))
    (when (> now (- +max-csn+ (registro-snapshot-lifetime registry)))
      (error 'resource-exhausted :reason :snapshot-deadline-overflow))
    (trova-slot-snapshot registry)))

;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-MVC-004
(declaim (ftype (function (contesto-snapshot csn-slot u64 u64 u64 u64) boolean)
                pubblica-registrazione-snapshot))
(defun pubblica-registrazione-snapshot (context slot generation now horizon csn)
  "Pre: mutex snapshot, soglia già annunciata, frontiere catturate dal registro canonico.
Post: pin e identità pubblicati, T se H>=CSN. Nessun accesso CSN o errore di contesa nel corpo.
Uscita non locale durante mutazione: registro FAULTED, niente rollback della pubblicazione."
  (let* ((registry (contesto-snapshot-registry context)) (word (contesto-snapshot-word context))
         (words (registro-snapshot-words registry)) (capacity (length (registro-snapshot-states registry)))
         (ready (>= horizon csn)) (complete nil))
    (esigi-snapshot-sano registry)
    (unwind-protect
         (progn
           ;; Nessuna vecchia identità cambia prima che entrambe le catture CSN siano riuscite.
           (setf (aref word 0) 0 (aref (registro-snapshot-generations registry) slot) 0)
           (sb-thread:barrier (:memory))
           (setf (aref (registro-snapshot-csns-array registry) slot) csn
                 (aref (registro-snapshot-deadlines registry) slot) (+ now (registro-snapshot-lifetime registry))
                 (aref (registro-snapshot-wait-deadlines registry) slot) (+ now (registro-snapshot-wait registry))
                 (aref (registro-snapshot-states registry) slot) (if ready +snapshot-active+ +snapshot-waiting+)
                 (aref words 0) generation (aref word 1) csn (contesto-snapshot-slot context) slot
                 (registro-snapshot-cursor registry) (if (= (1+ slot) capacity) 0 (1+ slot)))
           (incf (registro-snapshot-count registry))
           (sb-thread:barrier (:write))
           (setf (aref (registro-snapshot-generations registry) slot) generation)
           (sb-thread:barrier (:write))
           (setf (aref word 0) generation)
           (verifica-contatori-snapshot registry)
           (setf complete t)
           ready)
      (unless complete (invalida-registro-snapshot registry)))))

;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-MVC-004 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (contesto-snapshot u64) (values u64 u64 boolean &optional))
                registra-snapshot-sotto-mutex))
(defun registra-snapshot-sotto-mutex (context now)
  "Pre: mutex snapshot posseduto. Post: pin nato dopo annuncio e cattura coerente del CSN.
CSN-BUSY nella seconda cattura ripristina solo la soglia: nessun pin/identità/cursore consumato.
Ogni altra interruzione dopo l'annuncio rende FAULTED; nessun rollback di metadata pubblicati."
  (let* ((registry (contesto-snapshot-registry context))
         (slot (prepara-registrazione-snapshot context now))
         (words (registro-snapshot-words registry)) (generation (1+ (aref words 0)))
         (announcement (frontiere-snapshot registry)) (previous (aref words 1)) (complete nil))
    (declare (type u64 generation announcement previous))
    (unwind-protect
         (progn
           (setf (aref words 1) (min previous announcement))
           (sb-thread:barrier (:memory))
           (multiple-value-bind (captured horizon csn) (tenta-cattura-snapshot registry)
             (declare (type u64 horizon csn))
             (unless captured
               ;; Nessun pin o metadata modificato: annuncio provvisorio revocabile sotto lo stesso mutex.
               (sb-thread:barrier (:memory))
               (setf (aref words 1) previous)
               (sb-thread:barrier (:memory))
               (esigi-snapshot-sano registry)
               (setf complete t)
               (error 'resource-exhausted :reason :csn-busy))
             (unless (<= announcement horizon csn)
               (guasto-snapshot registry :snapshot-csn-frontier-regression))
             (let ((ready (pubblica-registrazione-snapshot context slot generation now horizon csn)))
               (esigi-snapshot-sano registry)
               (setf complete t)
               (values generation csn ready))))
      (unless complete (invalida-registro-snapshot registry)))))

;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-MVC-004 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (contesto-snapshot u64) (values u64 u64 boolean &optional)) registra-snapshot))
(defun registra-snapshot (context now)
  "Pre: NOW fresco dalla stessa base monotona; nessun vecchio consumatore o pin del contesto.
Post: generazione, CSN e attività dal solo registro canonico, soglia annunciata prima della cattura.
SNAPSHOT-BUSY/CSN-BUSY senza attesa: conservare e riprogrammare la richiesta con NOW nuovo."
  (let ((registry (contesto-snapshot-registry context)) (acquired nil))
    (esigi-ingresso-snapshot registry)
    (multiple-value-prog1
        (sb-thread:with-mutex ((registro-snapshot-mutex registry) :wait-p nil)
          (setf acquired t)
          (registra-snapshot-sotto-mutex context now))
      (unless acquired (error 'resource-exhausted :reason :snapshot-busy)))))
