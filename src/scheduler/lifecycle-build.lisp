;;; OWNER: costruzione e binding sul coordinator; porte create sul rispettivo worker.
;;; SHARED: configurazione pubblicata dal chiamante dopo handshake di avvio.
(in-package #:arcdocdb.scheduler)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-THR-001 REQ-CON-001 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (arcdocdb.execution:contesto-worker-writer
                          &key (:coordinator t) (:active t)) porta-worker-pool)
                crea-porta-worker-pool))
(defun crea-porta-worker-pool (context &key (coordinator sb-thread:*current-thread*) (active t))
  "Pre: worker owner corrente, contesto IDLE verificato; nessun altro compito/epoca.
Post: porta preallocata, stato iniziale confermato. INVALID-ARGUMENT coordinator/bit;
propaga barriera C1 read-only. Pubblicazione tra thread a carico dell'handshake di avvio."
  (unless (typep coordinator 'sb-thread:thread)
    (error 'invalid-argument :reason :pool-owner))
  (unless (typep active 'boolean) (error 'invalid-argument :reason :pool-active))
  (arcdocdb.execution::%richiedi-worker context :idle)
  (let ((word (if active 1 0)))
    (%make-porta-worker-pool sb-thread:*current-thread* coordinator context word word)))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (controllore-pool t fixnum) sb-thread:thread) %pool-startup-owner))
(defun %pool-startup-owner (controller port position)
  "Pre: controller owner corrente, indice bounded. Post: porta stabile e owner restituito.
INVALID-ARGUMENT tipo, coordinatore, binding o stato iniziale non conforme."
  (unless (typep port 'porta-worker-pool) (error 'invalid-argument :reason :pool-ports))
  (unless (eq (porta-worker-pool-coordinator port) sb-thread:*current-thread*)
    (error 'invalid-argument :reason :pool-owner))
  (when (porta-worker-pool-bound port) (error 'invalid-argument :reason :pool-binding))
  (unless (and (<= (porta-worker-pool-request port) 1)
               (= (porta-worker-pool-request port) (porta-worker-pool-ack port))
               (eq (oddp (porta-worker-pool-request port))
                   (< position (controllore-pool-target controller))))
    (error 'invalid-argument :reason :pool-port-state))
  (porta-worker-pool-owner port))

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (controllore-pool t) simple-vector) %pool-validate-ports))
(defun %pool-validate-ports (controller ports)
  "Pre: controller owner verificato. Post: tutte le porte validabili senza binding.
INVALID-ARGUMENT forma, owner duplicato, coordinatore, pending, prefix o binding.
Hash EQ solo all'avvio: scansione bounded O(N), nessuna ricerca quadratica."
  (unless (and (typep ports 'simple-vector)
               (= (controllore-pool-maximum controller) (length ports)))
    (error 'invalid-argument :reason :pool-ports))
  (let ((owners (make-hash-table :test #'eq :size (length ports))))
    (dotimes (i (length ports))
      (let ((owner (%pool-startup-owner controller (svref ports i) i)))
        (when (gethash owner owners)
          (error 'invalid-argument :reason :pool-ports))
        (setf (gethash owner owners) t))))
  ports)

;;; REQ: REQ-THR-001 REQ-CON-005 REQ-AFF-008 REQ-AFF-013
(declaim (ftype (function (controllore-pool t) registro-pool) crea-registro-pool))
(defun crea-registro-pool (controller ports)
  "Pre: controller locale, startup stabile con worker distinti; target attivo a prefisso.
Post: copia privata e binding permanente delle porte, allocazioni solo all'avvio.
Tutti i rifiuti typed precedono il binding; usare solo wrapper dopo il collegamento."
  (%check-pool controller)
  (%pool-validate-ports controller ports)
  (let* ((copy (copy-seq ports))
         (registry (%make-registro-pool controller copy sb-thread:*current-thread*
                                      (controllore-pool-target controller))))
    (dotimes (i (length copy)) (setf (porta-worker-pool-bound (svref copy i)) t))
    registry))
