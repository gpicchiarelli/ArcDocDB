;;; OWNER: un writer con la lease della coda canonica della Serie.
;;; SHARED: nessuna scrittura fra Serie; sorgenti dopo handoff esclusivo dal worker.
(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-CON-002
(defstruct (riserve-full-text
             (:constructor %riserve-full-text (queue configs slots rows row-slots fixed used file-limits delta-limit staging-limit segment))
             (:copier nil))
  "Pool preallocato per un ACTIVE nuovo; solo il writer muta contatori e prestiti.
Costi trasferiti restano posseduti: nessun reclaim per assenza o riduzione delle versioni storiche."
  (queue nil :type ex:coda-writer :read-only t)
  (configs #() :type simple-vector :read-only t) (slots #() :type simple-vector :read-only t)
  (rows #() :type (simple-array (unsigned-byte 32) (*)) :read-only t)
  (row-slots #() :type (simple-array (unsigned-byte 32) (*)) :read-only t)
  (row-count 0 :type index)
  (fixed (make-array 0 :element-type 'fixnum) :type contatori-full-text :read-only t)
  (used (make-array 0 :element-type 'fixnum) :type contatori-full-text :read-only t)
  (file-limits (make-array 0 :element-type 'fixnum) :type contatori-full-text :read-only t)
  (delta-limit 0 :type index :read-only t) (staging-limit 0 :type index :read-only t)
  (segment 0 :type u32 :read-only t)
  (delta-used 0 :type index) (staging-used 0 :type index) (count 0 :type index)
  (generation 0 :type index) (effect nil :type boolean)
  (state :healthy :type (member :healthy :faulted)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(defstruct (riserva-full-text (:constructor %riserva-full-text (pool position runs sources costs)) (:copier nil))
  "Slot stabile con generation senza wrap; run privati fino a READY, immutabili dopo trasferimento.
SOURCES e i borrower impediscono il riuso dei task durante la copia riprendibile."
  (pool nil :type riserve-full-text :read-only t) (position 0 :type index :read-only t)
  (runs #() :type simple-vector :read-only t) (sources #() :type simple-vector :read-only t)
  (costs (make-array 0 :element-type 'fixnum) :type contatori-full-text :read-only t)
  (generation 0 :type index) (row 0 :type u32) (bytes 0 :type index)
  ;; Il ponte PUT, caricato dopo WAL, cattura solo un lotto validato e posseduto.
  ;; Trasferiti mai riusati: il legame resta stabile, nessun prestito del frame worker.
  (record-source nil :type t) (record-incarnation 0 :type index) (record-number 0 :type index)
  (record-start 0 :type index) (record-end 0 :type index)
  (put-flags 0 :type (unsigned-byte 8)) (put-high 0 :type u32) (put-low 0 :type u32)
  ;; Campi nella riserva preallocata: il ponte li fissa prima dell'I/O, mai riusati.
  (physical-offset 0 :type index) (physical-version 2 :type (integer 1 2))
  (physical-state :absent :type (member :absent :capturing :sealed))
  (config-index 0 :type index) (part 0 :type (integer 0 2)) (cursor 0 :type index)
  (state :free :type (member :free :copying :ready :transferred :cancelled)))
