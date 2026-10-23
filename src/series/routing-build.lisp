;;;; Costruzione bounded all'avvio; input copiati, controller unici per EQ.
;;; OWNER: caller esclusivo fino alla pubblicazione; nessun writer/Serie mutato.
;;; SHARED: hash temporaneo solo all'avvio, mai pubblicato o letto dal percorso caldo.
(in-package #:arcdocdb.execution.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (t t) index) %routing-input-size))
(defun %routing-input-size (writers controllers)
  "Pre: input caller esclusivi. Post: SIMPLE-VECTOR pari, dimensione 1..65536.
INVALID-ARGUMENT shape/budget prima di copie o accessi agli elementi."
  (unless (typep writers 'simple-vector)
    (error 'invalid-argument :reason :worker-serie-routing-configuration))
  (unless (typep controllers 'simple-vector)
    (error 'invalid-argument :reason :worker-serie-routing-configuration))
  (let ((size (length writers)))
    (unless (<= 1 size +max-worker-series-routes+)
      (error 'invalid-argument :reason :worker-serie-routing-configuration))
    (unless (= size (length controllers))
      (error 'invalid-argument :reason :worker-serie-routing-configuration))
    size))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (t t index hash-table) null) %routing-input-entry))
(defun %routing-input-entry (writer controller ordinal seen)
  "Pre: ordinal nel budget, hash EQ temporaneo. Post: coppia valida, Serie unica.
INVALID-ARGUMENT entry/ordinal/duplicato prima della pubblicazione; hash solo startup."
  (unless (typep writer 'writer-programmabile)
    (error 'invalid-argument :reason :worker-serie-routing-binding))
  (unless (eql (arcdocdb.execution:indice-routing-writer writer) ordinal)
    (error 'invalid-argument :reason :worker-serie-routing-binding))
  (unless (typep controller 'controllore-serie)
    (error 'invalid-argument :reason :worker-serie-routing-binding))
  (when (gethash controller seen)
    (error 'invalid-argument :reason :worker-serie-routing-binding))
  (setf (gethash controller seen) t)
  nil)

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (t t) registro-worker-serie) crea-registro-worker-serie))
(defun crea-registro-worker-serie (writers controllers)
  "Pre: avvio, input esclusivi, ordinal densi fissati dal caller senza contatore globale.
Post: mapping copiato, un writer/Serie per slot; INVALID-ARGUMENT shape/entry.
Nessuna lease o stato vivo letto; non ammette inserimenti o riuso degli ordinal."
  (let* ((size (%routing-input-size writers controllers))
         (own-writers (copy-seq writers)) (own-controllers (copy-seq controllers))
         (seen (make-hash-table :test 'eq :size size)))
    (dotimes (i size)
      (%routing-input-entry (svref own-writers i) (svref own-controllers i) i seen))
    (let ((registry (%make-registro-worker-serie own-writers own-controllers)))
      (unless (= (%routing-size registry) size)
        (error 'invariant-violation :reason :worker-serie-routing))
      registry)))

;;; REQ: REQ-CON-002 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (contesto-worker-writer registro-worker-serie) tabella-worker-serie)
                crea-tabella-worker-serie))
(defun crea-tabella-worker-serie (context registry)
  "Pre: thread del contesto IDLE, registro immutabile condiviso all'avvio.
Post: un link privato per slot; owner/fase typed, INVARIANT-VIOLATION shape.
Factory O(N), spazio O(N) per worker; non assume o trasferisce obblighi."
  (arcdocdb.execution::%richiedi-worker context :idle)
  (let* ((size (%routing-size registry)) (links (make-array size :initial-element nil)))
    (dotimes (i size)
      (setf (svref links i)
            (crea-collegamento-worker-serie context (svref (registro-worker-serie-writers registry) i)
                                          (svref (registro-worker-serie-controllers registry) i))))
    (unless (= (length links) size)
      (error 'invariant-violation :reason :worker-serie-routing))
    (%make-tabella-worker-serie context registry links)))
