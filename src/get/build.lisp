;;; OWNER: configurazione prima dei pool; capacità segmenti costruite solo nel pool I/O.
;;; SHARED: nessuna pubblicazione, apertura, chiusura o modifica di log in queste funzioni.
(in-package #:arcdocdb.get)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-CCH-002 REQ-FOR-001
(declaim (ftype (function (ambito-get indice-primario (or null cache-serie) octets) vista-get-serie)
                crea-vista-get-serie))
(defun crea-vista-get-serie (scope primary cache identity)
  "Pre: controller, indice/cache della stessa Serie, ID canonico stabile di sedici byte.
Post: vista immutabile con copia posseduta dell'identità; NIL disattiva la cache.
INVALID-ARGUMENT per ID di altra lunghezza; nessun oggetto per documento."
  (unless (= (length identity) +serie-id-bytes+) (error 'invalid-argument :reason :get-serie-identity))
  (%make-vista-get-serie scope primary cache (copy-seq identity)))

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (ambito-get integer
                         &key (:record-bytes integer) (:budget-payload integer)) contesto-get)
                crea-contesto-get))
(defun crea-contesto-get (scope worker-id &key (record-bytes 65536) (budget-payload 65688))
  "Pre: controller, ambito canonico dell'Archivio e ID worker esclusivo in tutti i pool.
Post: scratch fisso allocato prima del pool; nessun pin. Payload controllato prima di allocare.
INVALID-ARGUMENT per configurazione, RESOURCE-EXHAUSTED per budget; non cambia il limite documenti."
  (unless (and (<= 1 record-bytes +max-record-bytes+) (<= 0 budget-payload most-positive-fixnum))
    (error 'invalid-argument :reason :get-worker-configuration))
  (when (> (+ record-bytes +get-fixed-payload+) budget-payload)
    (error 'resource-exhausted :reason :get-worker-budget))
  (%make-contesto-get
   scope (crea-contesto-lettura (contesto-epoca (ambito-get-epochs scope) worker-id)
                               (ambito-get-snapshots scope)) (crea-contesto-indice)
   (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0)
   (make-array 1 :element-type '(unsigned-byte 64) :initial-element 0)
   (make-array record-bytes :element-type '(unsigned-byte 8) :initial-element 0)
   (make-array +get-proof-bytes+ :element-type '(unsigned-byte 8) :initial-element 0)))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-AFF-002 REQ-CON-004
(declaim (ftype (function (vista-get-serie file-io u64 octets) segmento-get) crea-segmento-get))
(defun crea-segmento-get (view file segment-id scratch)
  "Pre: pool I/O, file readonly aperto, ID autorevole, scratch esclusivo di almeno un header.
Post: header letto dal medesimo FD, CRC/Serie/segmento/formato verificati; capacità immutabile.
Propaga IO-FAULT/CORRUPTION-DETECTED/UNSUPPORTED-FORMAT; non apre o chiude FILE né certifica commit."
  (unless (and (plusp segment-id) (eq (mode-file file) :input) (eq (stato-file file) :open))
    (error 'invalid-argument :reason :get-segment-capability))
  (when (eq scratch (vista-get-serie-identity view))
    (error 'invalid-argument :reason :get-header-alias))
  (check-range scratch 0 +segment-header-bytes+)
  (unless (= (leggi-esatto file scratch 0 +segment-header-bytes+ 0) +segment-header-bytes+)
    (error 'invariant-violation :reason :get-header-read))
  (multiple-value-bind (next version origin created-offset)
      (verifica-header-segmento scratch 0 +segment-header-bytes+
                               (vista-get-serie-identity view) segment-id)
    (unless (and (= next +segment-header-bytes+) (< created-offset next))
      (error 'invariant-violation :reason :get-header-result))
    (%make-segmento-get view file (ldb (byte 32 32) segment-id) (ldb (byte 32 0) segment-id)
                       version origin)))
