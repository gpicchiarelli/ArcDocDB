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
(declaim (ftype (function (contesto-snapshot csn-slot u64 u64 u64)
                         (values u64 u64 boolean &optional)) pubblica-registrazione-snapshot))
(defun pubblica-registrazione-snapshot (context slot generation now announcement-horizon)
  "Pre: mutex posseduto, preflight completo. Post: pin annunciato prima del CSN; identità pubblicata.
Uscita non locale durante mutazione: registro FAULTED, niente rollback o riuso automatico."
  (let* ((registry (contesto-snapshot-registry context)) (word (contesto-snapshot-word context))
         (words (registro-snapshot-words registry)) (capacity (length (registro-snapshot-states registry)))
         (complete nil))
    (unwind-protect
         (progn
           ;; Invalida vecchie letture PRIMA di cambiare qualsiasi campo del contesto/slot.
           (setf (aref word 0) 0 (aref (registro-snapshot-generations registry) slot) 0)
           (sb-thread:barrier (:memory))
           (setf (aref words 1) (min (aref words 1) announcement-horizon))
           (sb-thread:barrier (:memory))
           (multiple-value-bind (horizon csn) (leggi-orizzonte (registro-snapshot-csns registry))
             (declare (type u64 horizon csn))
             (let ((ready (>= horizon csn)))
               (setf (aref (registro-snapshot-csns-array registry) slot) csn
                     (aref (registro-snapshot-deadlines registry) slot) (+ now (registro-snapshot-lifetime registry))
                     (aref (registro-snapshot-wait-deadlines registry) slot) (+ now (registro-snapshot-wait registry))
                     (aref (registro-snapshot-states registry) slot)
                     (if ready +snapshot-active+ +snapshot-waiting+)
                     (aref words 0) generation (aref word 1) csn (contesto-snapshot-slot context) slot
                     (registro-snapshot-cursor registry) (if (= (1+ slot) capacity) 0 (1+ slot)))
               (incf (registro-snapshot-count registry))
               (sb-thread:barrier (:write))
               (setf (aref (registro-snapshot-generations registry) slot) generation)
               (sb-thread:barrier (:write))
               (setf (aref word 0) generation complete t)
               (values generation csn ready))))
      (unless complete
        (sb-thread:barrier (:write))
        (setf (registro-snapshot-health registry) :faulted)))))

;;; REQ: REQ-MVC-007 REQ-MVC-005 REQ-MVC-004 REQ-AFF-008
(declaim (ftype (function (contesto-snapshot u64) (values u64 u64 boolean &optional)) registra-snapshot))
(defun registra-snapshot (context now)
  "Pre: NOW fresco dalla stessa base monotona, contesto senza vecchi consumatori o pin attivo.
Post: generazione, CSN e flag di attività. Soglia annunciata prima della cattura del CSN.
Non attende flush; se non pronto il proprietario parcheggia il contesto con budget e deadline."
  (let ((registry (contesto-snapshot-registry context)))
    (sb-thread:with-mutex ((registro-snapshot-mutex registry))
      (let* ((slot (prepara-registrazione-snapshot context now))
             (generation (1+ (aref (registro-snapshot-words registry) 0)))
             (horizon (leggi-orizzonte (registro-snapshot-csns registry))))
        (declare (type u64 generation horizon))
        (pubblica-registrazione-snapshot context slot generation now horizon)))))
