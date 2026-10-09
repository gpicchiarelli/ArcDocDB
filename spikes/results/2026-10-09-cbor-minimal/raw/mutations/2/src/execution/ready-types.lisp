;;;; Lista pronta partizionata: nessun contatore comune fra i ring.
;;; OWNER: scheduler dell'Archivio; ogni partizione possiede indici e slots.
;;; SHARED: lista Serie pronte (ADR-0045 §8), solo pubblicazione/prelievo per tratto.
(in-package #:arcdocdb.execution)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defconstant +max-partizioni-pronte+ 64)
;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defconstant +max-capacita-pronta+ 65536)

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (partizione-pronta (:constructor %make-partizione-pronta (slots capacity))
                             (:copier nil))
  "Pre: ring privato preallocato e capacity bounded. Post: vuoto, guard libera.
Slots/indici sono mutati soltanto dal proprietario della guard locale."
  (slots #() :type simple-vector :read-only t)
  (capacity 1024 :type index :read-only t)
  (head 0 :type index) (tail 0 :type index) (count 0 :type index)
  (guard nil :type (or null sb-thread:thread)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(defstruct (lista-writer-pronti (:constructor %make-lista-writer-pronti (partitions))
                              (:copier nil))
  "Pre: partizioni private, indipendenti e bounded. Post: lista pronta vuota.
Non deduplica obblighi :SCHEDULE né governa stato o risvegli dei worker."
  (partitions #() :type simple-vector :read-only t))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta) null) %check-forma-pronta))
(defun %check-forma-pronta (partition)
  "Pre: ring appena creato oppure guard posseduta. Post: forma e FIFO coerenti.
INVARIANT-VIOLATION per limiti, indici o relazione head/count/tail errati."
  (let ((capacity (partizione-pronta-capacity partition)))
    (unless (<= 1 capacity +max-capacita-pronta+)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (= (length (partizione-pronta-slots partition)) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (< (partizione-pronta-head partition) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (< (partizione-pronta-tail partition) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (<= (partizione-pronta-count partition) capacity)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (= (partizione-pronta-tail partition)
               (mod (+ (partizione-pronta-head partition)
                       (partizione-pronta-count partition)) capacity))
      (error 'invariant-violation :reason :ready-queue-invariant)))
  nil)

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (partizione-pronta) null) %check-pronta))
(defun %check-pronta (partition)
  "Pre: guard locale acquisita. Post: proprietario corrente e forma valida.
INVARIANT-VIOLATION per guard estranea o incoerenza interna."
  (unless (eq (partizione-pronta-guard partition) sb-thread:*current-thread*)
    (error 'invariant-violation :reason :ready-queue-guard))
  (%check-forma-pronta partition))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (lista-writer-pronti t) partizione-pronta) %partizione-verificata))
(defun %partizione-verificata (ready shard)
  "Pre: lista costruita con la factory. Post: partizione dell'indice verificato.
INVALID-ARGUMENT per indice errato; INVARIANT-VIOLATION per lista privata invalida."
  (let ((partitions (lista-writer-pronti-partitions ready)))
    (unless (<= 1 (length partitions) +max-partizioni-pronte+)
      (error 'invariant-violation :reason :ready-queue-invariant))
    (unless (typep shard 'index) (error 'invalid-argument :reason :ready-target))
    (unless (< shard (length partitions)) (error 'invalid-argument :reason :ready-target))
    (let ((partition (svref partitions shard)))
      (unless (typep partition 'partizione-pronta)
        (error 'invariant-violation :reason :ready-queue-invariant))
      partition)))

;;; REQ: REQ-CON-004 REQ-CON-005 REQ-AFF-008
(declaim (ftype (function (&key (:shards t) (:capacity t)) lista-writer-pronti)
                crea-lista-writer-pronti))
(defun crea-lista-writer-pronti (&key (shards 4) (capacity 1024))
  "Pre: shards 1..64, capacity per ring 1..65536. Post: ring privati preallocati.
INVALID-ARGUMENT per budget errati; nessuna allocazione sul percorso normale per compito."
  (unless (typep shards 'index) (error 'invalid-argument :reason :ready-configuration))
  (unless (<= 1 shards +max-partizioni-pronte+)
    (error 'invalid-argument :reason :ready-configuration))
  (unless (typep capacity 'index) (error 'invalid-argument :reason :ready-configuration))
  (unless (<= 1 capacity +max-capacita-pronta+)
    (error 'invalid-argument :reason :ready-configuration))
  (let ((partitions (make-array shards :initial-element nil)))
    (dotimes (i shards)
      (let ((partition (%make-partizione-pronta
                        (make-array capacity :initial-element nil) capacity)))
        (%check-forma-pronta partition)
        (setf (svref partitions i) partition)))
    (let ((ready (%make-lista-writer-pronti partitions)))
      (%partizione-verificata ready 0)
      ready)))
