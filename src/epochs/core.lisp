;;; OWNER: mutex EBR protegge la manutenzione; i worker possiedono gli annunci del proprio slot.
;;; SHARED: nessuna callback o I/O sotto mutex; salute letta con acquire sui reader.
(in-package #:arcdocdb.epochs)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CMP-007 REQ-AFF-004
(declaim (inline esigi-epoche-sane))
(declaim (ftype (function (registro-epoche) null) esigi-epoche-sane))
(defun esigi-epoche-sane (registry)
  "Pre: registro costruito. Post: salute campionata acquire, senza mutex.
INVARIANT-VIOLATION dopo FAULTED; non modifica annunci o risorse."
  (sb-thread:barrier (:read)
    (unless (eq (registro-epoche-health registry) :open)
      (error 'invariant-violation :reason :epoch-registry-faulted)))
  nil)

;;; REQ: REQ-CMP-007 REQ-AFF-004
(declaim (ftype (function (registro-epoche) null) marca-guasto-epoche))
(defun marca-guasto-epoche (registry)
  "Pre: mutex manutenzione posseduto. Post: FAULTED pubblicato; cleanup non ripara nulla."
  (sb-thread:barrier (:write))
  (setf (registro-epoche-health registry) :faulted)
  nil)

;;; REQ: REQ-CMP-007 REQ-AFF-004
(declaim (ftype (function (registro-epoche keyword) nil) guasto-epoche))
(defun guasto-epoche (registry reason)
  "Pre: mutex posseduto, incoerenza interna. Post: FAULTED ed errore tipizzato; nessun reclaim."
  (marca-guasto-epoche registry)
  (error 'invariant-violation :reason reason))

;;; REQ: REQ-CMP-007 REQ-AFF-004
(declaim (ftype (function (registro-epoche keyword) nil) guasto-reader-epoca))
(defun guasto-reader-epoca (registry reason)
  "Pre: incoerenza osservata dal worker. Post: fail-stop sotto mutex, soltanto su errore."
  (sb-thread:with-mutex ((registro-epoche-mutex registry)) (guasto-epoche registry reason)))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (registro-epoche) null) verifica-contatori-epoche))
(defun verifica-contatori-epoche (registry)
  "Pre: mutex posseduto. Post: budget di slot/epoche e frontiere compatibili, verifica O(1).
Le prenotazioni riservano anche un avanzamento di E; nessun overflow dopo lo swap."
  (esigi-epoche-sane registry)
  (let* ((capacity (length (registro-epoche-states registry))) (words (registro-epoche-words registry))
         (epoch (aref words +word-epoch+)) (threshold (aref words +word-threshold+)))
    (declare (type u64 epoch threshold))
    (unless (and (<= (registro-epoche-reserved registry) (registro-epoche-count registry) capacity)
                 (< (registro-epoche-cursor registry) capacity) (<= 1 threshold epoch)
                 (<= (registro-epoche-reserved registry) (- +max-epoca+ epoch)))
      (guasto-epoche registry :epoch-counters-inconsistent)))
  nil)

;;; REQ: REQ-CMP-007 REQ-AFF-008 REQ-AFF-004
(declaim (ftype (function (registro-epoche retirement-slot) null) verifica-slot-ritiro))
(defun verifica-slot-ritiro (registry slot)
  "Pre: mutex posseduto, slot nel range. Post: stato, identità, epoca e radice forte compatibili.
INVARIANT-VIOLATION con fail-stop se i metadati del ticket sono incoerenti."
  (let ((state (aref (registro-epoche-states registry) slot))
        (generation (aref (registro-epoche-generations registry) slot))
        (epoch (aref (registro-epoche-epochs registry) slot))
        (resource (aref (registro-epoche-resources registry) slot))
        (words (registro-epoche-words registry)))
    (declare (type u64 generation epoch))
    (unless (and (<= 1 generation (aref words +word-generation+))
                 (cond ((= state +retirement-reserved+) (and (zerop epoch) resource))
                       ((<= +retirement-retired+ state +retirement-claimed+)
                        (and (< 0 epoch (aref words +word-epoch+)) resource))
                       ((= state +retirement-cancelled+) (and (zerop epoch) (null resource)))
                       ((= state +retirement-completed+)
                        (and (< 0 epoch (aref words +word-epoch+)) (null resource)))
                       (t nil)))
      (guasto-epoche registry :retirement-metadata-inconsistent)))
  nil)

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (ritiro u64) retirement-slot) esigi-identita-ritiro))
(defun esigi-identita-ritiro (ticket expected-generation)
  "Pre: mutex posseduto. Post: slot dell'evento originale, anche su ticket già concluso.
INVALID-ARGUMENT per zero/riuso; un evento vecchio non modifica la nuova incarnazione."
  (let ((registry (ritiro-registry ticket)) (slot (ritiro-slot ticket)))
    (unless (and (< slot (length (registro-epoche-generations registry)))
                 (plusp expected-generation)
                 (= expected-generation (aref (registro-epoche-generations registry) slot)))
      (error 'invalid-argument :reason :retirement-stale-identity))
    (verifica-slot-ritiro registry slot)
    slot))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (registro-epoche t) retirement-slot) trova-slot-ritiro))
(defun trova-slot-ritiro (registry resource)
  "Pre: mutex posseduto e almeno un credito. Post: slot libero; al più K visite.
Rifiuta lo stesso descrittore canonico già prenotato; verifica tutti gli stati incontrati."
  (let* ((states (registro-epoche-states registry)) (capacity (length states))
         (cursor (registro-epoche-cursor registry)) (first-free nil))
    (dotimes (step capacity)
      (let* ((candidate (+ cursor step)) (slot (if (< candidate capacity) candidate (- candidate capacity)))
             (state (aref states slot)))
        (unless (<= state +retirement-completed+) (guasto-epoche registry :retirement-slot-state))
        (if (<= +retirement-reserved+ state +retirement-claimed+)
            (when (eq resource (aref (registro-epoche-resources registry) slot))
              (error 'invalid-argument :reason :retirement-resource-duplicate))
            (unless first-free (setf first-free slot)))))
    (or first-free (guasto-epoche registry :retirement-credit-accounting))))
