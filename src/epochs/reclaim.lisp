;;; OWNER: scheduler avanza la soglia una volta per gruppo; un solo proprietario reclama un ticket.
;;; SHARED: scansione W e controllo ticket sotto mutex; nessun I/O o callback nella sezione.
(in-package #:arcdocdb.epochs)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CMP-005 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (registro-epoche) null) aggiorna-soglia-reclaim))
(defun aggiorna-soglia-reclaim (registry)
  "Pre: compito di manutenzione. Post: frontiera monotona sicura per r < soglia.
Una scansione W serve più ticket; nessun reader bloccato e nessun file eliminato."
  (sb-thread:with-mutex ((registro-epoche-mutex registry))
    (verifica-contatori-epoche registry)
    (let* ((words (registro-epoche-words registry)) (epoch (aref words +word-epoch+))
           (minimum epoch) (announcements (registro-epoche-announcements registry)))
      (declare (type u64 epoch minimum))
      (sb-thread:barrier (:memory))
      (dotimes (worker (length (registro-epoche-readers registry)))
        (let ((pin (aref announcements (* (1+ worker) +stride-epoca+))))
          (declare (type u64 pin))
          (when (> pin epoch) (guasto-epoche registry :epoch-reader-future))
          (unless (zerop pin) (setf minimum (min minimum pin)))))
      ;; Un annuncio vecchio non ancora confermato può arrivare tardi; non abbassa una prova già acquisita.
      (sb-thread:barrier (:memory))
      (setf (aref words +word-threshold+) (max (aref words +word-threshold+) minimum))))
  nil)

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (ritiro u64) boolean) acquisisci-reclaim))
(defun acquisisci-reclaim (ticket expected-generation)
  "Pre: ritiro pubblicato, evento originale; soglia aggiornata dal compito di manutenzione.
Post: T assegna il reclaim esclusivo se r<soglia; NIL lascia il ticket in attesa.
Nessuna scansione W per ticket. Un secondo claim è INVALID-ARGUMENT, non duplica l'I/O."
  (let ((registry (ritiro-registry ticket)))
    (sb-thread:with-mutex ((registro-epoche-mutex registry))
      (verifica-contatori-epoche registry)
      (let* ((slot (esigi-identita-ritiro ticket expected-generation))
             (epoch (aref (registro-epoche-epochs registry) slot)))
        (declare (type u64 epoch))
        (unless (= (aref (registro-epoche-states registry) slot) +retirement-retired+)
          (error 'invalid-argument :reason :retirement-not-available))
        (when (zerop epoch) (guasto-epoche registry :retirement-epoch-zero))
        (when (< epoch (aref (registro-epoche-words registry) +word-threshold+))
          (setf (aref (registro-epoche-states registry) slot) +retirement-claimed+)
          t)))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (ritiro u64) null) completa-reclaim))
(defun completa-reclaim (ticket expected-generation)
  "Pre: reclaim già acquisito, descrittore chiuso/file rimosso secondo la prova del manifest.
Post: riferimento forte e credito liberati; idempotente per la stessa identità completata.
INVALID-ARGUMENT per mancato claim/riuso; fallimento I/O conserva ticket claimed e risorsa."
  (let ((registry (ritiro-registry ticket)))
    (sb-thread:with-mutex ((registro-epoche-mutex registry))
      (verifica-contatori-epoche registry)
      (let* ((slot (esigi-identita-ritiro ticket expected-generation))
             (state (aref (registro-epoche-states registry) slot)))
        (cond ((= state +retirement-claimed+) (libera-ritiro registry slot +retirement-completed+))
              ((= state +retirement-completed+) nil)
              (t (error 'invalid-argument :reason :retirement-not-claimed))))))
  nil)

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (ritiro u64) t) leggi-risorsa-ritiro))
(defun leggi-risorsa-ritiro (ticket expected-generation)
  "Pre: proprietario della compaction/reclaim, evento originale. Post: riferimento forte al descrittore.
INVALID-ARGUMENT dopo annullamento/completamento/riuso; leggere non assegna il diritto di chiuderlo."
  (let ((registry (ritiro-registry ticket)))
    (sb-thread:with-mutex ((registro-epoche-mutex registry))
      (verifica-contatori-epoche registry)
      (let ((slot (esigi-identita-ritiro ticket expected-generation)))
        (unless (<= +retirement-reserved+ (aref (registro-epoche-states registry) slot) +retirement-claimed+)
          (error 'invalid-argument :reason :retirement-resource-released))
        (or (aref (registro-epoche-resources registry) slot)
            (guasto-epoche registry :retirement-resource-missing))))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (ritiro u64) (values keyword u64 &optional)) leggi-ritiro))
(defun leggi-ritiro (ticket expected-generation)
  "Pre: evento con generazione originale. Post: stato keyword ed epoca coerenti, per osservabilità.
INVALID-ARGUMENT per identità vecchia; nessun claim e nessuna risorsa liberata."
  (let ((registry (ritiro-registry ticket)))
    (sb-thread:with-mutex ((registro-epoche-mutex registry))
      (verifica-contatori-epoche registry)
      (let* ((slot (esigi-identita-ritiro ticket expected-generation))
             (state (aref (registro-epoche-states registry) slot)))
        (values (cond ((= state +retirement-reserved+) :reserved)
                      ((= state +retirement-retired+) :retired)
                      ((= state +retirement-claimed+) :claimed)
                      ((= state +retirement-cancelled+) :cancelled)
                      ((= state +retirement-completed+) :completed)
                      (t (guasto-epoche registry :retirement-slot-state)))
                (aref (registro-epoche-epochs registry) slot))))))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (registro-epoche)
                         (values u64 u64 (integer 0 65536) (integer 0 65536) &optional)) leggi-registro-epoche))
(defun leggi-registro-epoche (registry)
  "Pre: registro sano. Post: E, soglia, crediti occupati e riservati coerenti sotto mutex.
La soglia è una prova conservativa acquisita, non un censimento dei reader attualmente vivi."
  (sb-thread:with-mutex ((registro-epoche-mutex registry))
    (verifica-contatori-epoche registry)
    (let ((words (registro-epoche-words registry)))
      (values (aref words +word-epoch+) (aref words +word-threshold+)
              (registro-epoche-count registry) (registro-epoche-reserved registry)))))
