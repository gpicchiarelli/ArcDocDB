;;; OWNER: controller attiva/ritira contesti; timer visita al più un budget di slot per compito.
;;; SHARED: ordine mutex snapshot->CSN; nessun parcheggio, I/O o callback dentro la sezione.
(in-package #:arcdocdb.mvcc)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-004 REQ-MVC-005 REQ-MVC-007 REQ-CON-004
(declaim (ftype (function (contesto-snapshot u64 u64) boolean) attiva-snapshot))
(defun attiva-snapshot (context expected-generation now)
  "Pre: evento con generazione originale e NOW fresco. Post: T solo quando H>=CSN e non scaduto.
NIL se ancora in attesa; RESOURCE-EXHAUSTED per busy/timeout, SNAPSHOT-TOO-OLD dopo la fine."
  (let ((registry (contesto-snapshot-registry context)) (acquired nil))
    (esigi-ingresso-snapshot registry)
    (multiple-value-prog1
        (sb-thread:with-mutex ((registro-snapshot-mutex registry) :wait-p nil)
          (setf acquired t)
          (verifica-contatori-snapshot registry)
          (let* ((slot (esigi-identita-snapshot context expected-generation))
                 (states (registro-snapshot-states registry)) (state (aref states slot)))
            (cond
              ((= state +snapshot-waiting+)
               (when (>= now (aref (registro-snapshot-wait-deadlines registry) slot))
                 (ritira-slot-snapshot registry slot +snapshot-wait-expired+)
                 (error 'resource-exhausted :reason :snapshot-wait-timeout))
               (when (orizzonte-snapshot-raggiunto-p registry
                                                  (aref (registro-snapshot-csns-array registry) slot))
                 (esigi-snapshot-sano registry)
                 (sb-thread:barrier (:write))
                 (setf (aref states slot) +snapshot-active+)
                 (esigi-snapshot-sano registry)
                 (return-from attiva-snapshot t))
               nil)
              ((= state +snapshot-active+)
               (when (>= now (aref (registro-snapshot-deadlines registry) slot))
                 (ritira-slot-snapshot registry slot +snapshot-age-expired+)
                 (error 'snapshot-too-old :reason :snapshot-age-expired))
               t)
              ((= state +snapshot-wait-expired+)
               (error 'resource-exhausted :reason :snapshot-wait-timeout))
              ((or (= state +snapshot-closed+) (= state +snapshot-age-expired+))
               (error 'snapshot-too-old :reason :snapshot-ended))
              (t (guasto-snapshot registry :snapshot-slot-state)))))
      (unless acquired (error 'resource-exhausted :reason :snapshot-busy)))))

;;; REQ: REQ-MVC-003 REQ-MVC-004 REQ-MVC-007 REQ-CMP-007 REQ-CON-004
(declaim (ftype (function (contesto-snapshot u64) null) termina-snapshot))
(defun termina-snapshot (context expected-generation)
  "Pre: evento originale; stop a nuove letture, reader già ammessi protetti da EBR.
Post: pin rimosso; idempotente per la stessa identità già terminata/scaduta.
SNAPSHOT-TOO-OLD su riuso; SNAPSHOT-BUSY conserva il pin e l'obbligo di terminazione."
  (let ((registry (contesto-snapshot-registry context)) (acquired nil))
    (esigi-ingresso-snapshot registry)
    (multiple-value-prog1
        (sb-thread:with-mutex ((registro-snapshot-mutex registry) :wait-p nil)
          (setf acquired t)
          (verifica-contatori-snapshot registry)
          (let* ((slot (esigi-identita-snapshot context expected-generation))
                 (state (aref (registro-snapshot-states registry) slot)))
            (cond ((snapshot-pinned-p state) (ritira-slot-snapshot registry slot +snapshot-closed+))
                  ((<= +snapshot-closed+ state +snapshot-age-expired+) nil)
                  (t (guasto-snapshot registry :snapshot-slot-state)))))
      (unless acquired (error 'resource-exhausted :reason :snapshot-busy))))
  nil)

;;; REQ: REQ-MVC-004 REQ-MVC-003 REQ-AFF-008
(declaim (ftype (function (registro-snapshot csn-slot u64) boolean) scadi-slot-snapshot))
(defun scadi-slot-snapshot (registry slot now)
  "Pre: mutex posseduto e mutazione protetta dal chiamante. Post: scadenza di un solo slot.
Aggiorna il conteggio, non la soglia; T se un pin è stato rimosso. Nessun reader fisico liberato."
  (let ((state (aref (registro-snapshot-states registry) slot)))
    (unless (<= state +snapshot-age-expired+)
      (guasto-snapshot registry :snapshot-slot-state))
    (let ((terminal-state
            (cond ((and (= state +snapshot-waiting+)
                        (>= now (aref (registro-snapshot-wait-deadlines registry) slot)))
                   +snapshot-wait-expired+)
                  ((and (= state +snapshot-active+)
                        (>= now (aref (registro-snapshot-deadlines registry) slot)))
                   +snapshot-age-expired+))))
      (when terminal-state
        (setf (aref (registro-snapshot-states registry) slot) terminal-state)
        (decf (registro-snapshot-count registry)))
      (not (null terminal-state)))))

;;; REQ: REQ-MVC-004 REQ-MVC-003 REQ-AFF-008 REQ-CON-004
(declaim (ftype (function (registro-snapshot u64 integer)
                         (values (integer 1 65536) (integer 0 65536) &optional)) scadi-snapshot))
(defun scadi-snapshot (registry now max-slots)
  "Pre: NOW fresco, budget 1..K. Post: visite, pin scaduti; cursore circolare per equità.
Una sola scansione K per ricalcolare la soglia; SNAPSHOT-BUSY senza attesa, interruzione fail-stop."
  (esigi-ingresso-snapshot registry)
  (let ((acquired nil))
    (multiple-value-prog1
        (sb-thread:with-mutex ((registro-snapshot-mutex registry) :wait-p nil)
          (setf acquired t)
          (verifica-contatori-snapshot registry)
          (let ((capacity (length (registro-snapshot-states registry)))
                (cursor (registro-snapshot-sweep-cursor registry)) (expired 0) (complete nil))
            (unless (<= 1 max-slots capacity)
              (error 'invalid-argument :reason :snapshot-sweep-budget))
            (unwind-protect
                 (progn
                   (dotimes (step max-slots)
                     (when (scadi-slot-snapshot registry cursor now) (incf expired))
                     (setf cursor (if (= (1+ cursor) capacity) 0 (1+ cursor))))
                   (when (plusp expired)
                     (sb-thread:barrier (:memory))
                     (ricalcola-soglia-snapshot registry))
                   (setf (registro-snapshot-sweep-cursor registry) cursor complete t)
                   (values max-slots expired))
              (unless complete (invalida-registro-snapshot registry)))))
      (unless acquired (error 'resource-exhausted :reason :snapshot-busy)))))
