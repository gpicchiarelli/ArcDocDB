;;; OWNER: manutenzione prenota prima della rilocazione; pubblica solo dopo rimozione di ogni riferimento.
;;; SHARED: mutex una volta per segmento ritirato; il registro conserva la risorsa senza callback/I/O.
(in-package #:arcdocdb.epochs)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (registro-epoche t) (values ritiro u64 &optional)) prenota-ritiro))
(defun prenota-ritiro (registry resource)
  "Pre: RESOURCE descrittore canonico non NIL, ancora referenziato; nessuno swap già eseguito.
Post: ticket e generazione originale, riferimento forte e crediti per slot/avanzamento E.
RESOURCE-EXHAUSTED prima di mutare per K/u64; INVALID-ARGUMENT per NIL o duplicato."
  (when (null resource) (error 'invalid-argument :reason :retirement-resource-null))
  (sb-thread:with-mutex ((registro-epoche-mutex registry))
    (verifica-contatori-epoche registry)
    (let* ((words (registro-epoche-words registry)) (capacity (length (registro-epoche-states registry)))
           (last (aref words +word-generation+)) (epoch (aref words +word-epoch+)))
      (declare (type u64 last epoch))
      (when (= (registro-epoche-count registry) capacity)
        (error 'resource-exhausted :reason :retirement-capacity))
      (when (or (= last +max-epoca+) (= (registro-epoche-reserved registry) (- +max-epoca+ epoch)))
        (error 'resource-exhausted :reason :retirement-sequence-exhausted))
      (let ((slot (trova-slot-ritiro registry resource)) (generation (1+ last)) (complete nil))
        (declare (type u64 generation))
        (unwind-protect
             (progn
               (setf (aref (registro-epoche-generations registry) slot) generation
                     (aref (registro-epoche-epochs registry) slot) 0
                     (aref (registro-epoche-resources registry) slot) resource
                     (aref (registro-epoche-states registry) slot) +retirement-reserved+
                     (aref words +word-generation+) generation
                     (registro-epoche-cursor registry) (if (= (1+ slot) capacity) 0 (1+ slot)))
               (incf (registro-epoche-count registry))
               (incf (registro-epoche-reserved registry))
               (setf complete t)
               (values (aref (registro-epoche-retirements registry) slot) generation))
          (unless complete (marca-guasto-epoche registry)))))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (registro-epoche retirement-slot (unsigned-byte 8)) null) libera-ritiro))
(defun libera-ritiro (registry slot terminal-state)
  "Pre: mutex, stato/originalità verificati dal chiamante. Post: risorsa e credito rilasciati.
Solo annullamento prima dello swap o completamento dopo reclaim; interruzione fail-stop."
  (let ((complete nil))
    (unwind-protect
         (progn
           (when (= terminal-state +retirement-cancelled+) (decf (registro-epoche-reserved registry)))
           (setf (aref (registro-epoche-resources registry) slot) nil
                 (aref (registro-epoche-states registry) slot) terminal-state)
           (decf (registro-epoche-count registry))
           (setf complete t))
      (unless complete (marca-guasto-epoche registry))))
  nil)

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (ritiro u64) null) annulla-ritiro))
(defun annulla-ritiro (ticket expected-generation)
  "Pre: nessuno swap/riferimento rimosso; evento originale. Post: credito libero, stessa identità idempotente.
INVALID-ARGUMENT se il ritiro è già pubblicato, riusato o concluso con un altro esito."
  (let ((registry (ritiro-registry ticket)))
    (sb-thread:with-mutex ((registro-epoche-mutex registry))
      (verifica-contatori-epoche registry)
      (let* ((slot (esigi-identita-ritiro ticket expected-generation))
             (state (aref (registro-epoche-states registry) slot)))
        (cond ((= state +retirement-reserved+) (libera-ritiro registry slot +retirement-cancelled+))
              ((= state +retirement-cancelled+) nil)
              (t (error 'invalid-argument :reason :retirement-cannot-cancel))))))
  nil)

;;; REQ: REQ-CMP-005 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (ritiro u64) null) pubblica-ritiro))
(defun pubblica-ritiro (ticket expected-generation)
  "Pre: ogni riferimento da indice/versioni trattenute rimosso; risorsa ancora leggibile e ticket riservato.
Post: r=E, E avanzata senza wrap; gli eventi di reclaim devono conservare la generazione.
Non rende nulla durevole e non elimina file. Duplicato/riuso: INVALID-ARGUMENT; interruzione: FAULTED."
  (let ((registry (ritiro-registry ticket)))
    (sb-thread:with-mutex ((registro-epoche-mutex registry))
      (verifica-contatori-epoche registry)
      (let* ((slot (esigi-identita-ritiro ticket expected-generation)) (words (registro-epoche-words registry))
             (epoch (aref words +word-epoch+)) (complete nil))
        (declare (type u64 epoch))
        (unless (= (aref (registro-epoche-states registry) slot) +retirement-reserved+)
          (error 'invalid-argument :reason :retirement-not-reserved))
        (unless (and (plusp (registro-epoche-reserved registry)) (< epoch +max-epoca+))
          (guasto-epoche registry :retirement-epoch-credit))
        (unwind-protect
             (progn
               ;; Unlink->E: i reader della nuova epoca devono vedere la rimozione dei riferimenti.
               (sb-thread:barrier (:memory))
               (setf (aref (registro-epoche-epochs registry) slot) epoch
                     (aref (registro-epoche-states registry) slot) +retirement-retired+
                     (aref words +word-epoch+) (1+ epoch))
               (sb-thread:barrier (:memory))
               (decf (registro-epoche-reserved registry))
               (setf complete t))
          (unless complete (marca-guasto-epoche registry))))))
  nil)
