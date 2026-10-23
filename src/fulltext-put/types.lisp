;;; OWNER: worker fino a PREPARED, poi writer dopo handoff sincronizzato; restituzione simmetrica.
;;; SHARED: sole configurazioni immutabili fra Serie; nessun contatore o lock condiviso per PUT.
(in-package #:arcdocdb.fulltext.put)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-WAL-005
(defstruct (preparazione-put-full-text
             (:constructor %preparazione-put-full-text (tasks frame version document-limit key-limit)) (:copier nil))
  "Contesto privato riutilizzabile; frame e task non esportati. Tutte le generazioni
analizzano gli stessi byte posseduti; la generation catturata impedisce risultati ABA."
  (tasks #() :type simple-vector :read-only t) (frame #() :type octets :read-only t)
  (version 2 :type (integer 1 2) :read-only t) (document-limit 1 :type index :read-only t)
  (key-limit 1 :type index :read-only t)
  (generation 0 :type index) (size 0 :type index) (value-start 0 :type index) (row 0 :type u32)
  (validated-generation 0 :type index)
  (current 0 :type index) (active nil :type boolean) (work 0 :type index) (work-limit 268435456 :type index)
  (pool nil :type (or null f:riserve-full-text)) (slot nil :type (or null f:riserva-full-text))
  (slot-generation 0 :type index)
  (state :idle :type (member :idle :preparing :prepared :reserving :reserved :appended :cancelled :failed :faulted)))

;;; REQ: REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (t t) preparazione-put-full-text) verifica-token-put))
(defun verifica-token-put (request generation)
  "Pre: oggetto e generation catturati dal chiamante. Post: identita corrente senza effetti.
INVALID-ARGUMENT per tipo/stale; token zero non e mai una preparazione valida."
  (unless (and (typep request 'preparazione-put-full-text) (typep generation 'index) (plusp generation)
               (= generation (preparazione-put-full-text-generation request)))
    (error 'invalid-argument :reason :fulltext-put-token))
  request)

;;; REQ: REQ-SEC-006
(declaim (ftype (function (t t) keyword) stato-put-full-text))
(defun stato-put-full-text (request generation)
  "Pre: token corrente, accesso dal proprietario. Post: stato senza frame, task o parziali."
  (verifica-token-put request generation)
  (preparazione-put-full-text-state request))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-WAL-005
(declaim (ftype (function (preparazione-put-full-text) null) esigi-cornice-put-validata))
(defun esigi-cornice-put-validata (request)
  "Pre: request esclusivo, frame/task mai esposti. Post: attestazione del worker corrente.
Il frame non cambia fra verifica CRC/analisi e append; solo inizia puo invalidarlo.
Rifiuta attestazione assente/stale senza rileggere il body sotto la lease del writer."
  (unless (and (plusp (preparazione-put-full-text-validated-generation request))
               (= (preparazione-put-full-text-generation request) (preparazione-put-full-text-validated-generation request)))
    (error 'invalid-argument :reason :fulltext-put-unvalidated))
  nil)
