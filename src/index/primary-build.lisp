;;; OWNER: controller/solo writer; tutte le allocazioni fuori dal lookup.
;;; SHARED: nuovi array non esposti prima della root; budget payload distinto da RSS.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-LIM-001 REQ-AFF-008
(declaim (ftype (function (indice-primario &key (:depth integer) (:prefix integer)
                                         (:arena-bytes integer)) frammento-indice)
                crea-frammento-indice))
(defun crea-frammento-indice (index &key (depth 0) (prefix 0) (arena-bytes 65536))
  "Pre: controller/writer, geometria desiderata del rebuild/split. Post: BUILDING vuoto.
Budget di 41*C + arena verificato prima di allocare; la capacità non cresce in-place."
  (esigi-indice-sano index)
  (unless (and (<= 0 depth (indice-primario-max-depth index))
               (<= 0 prefix (1- (ash 1 depth))) (<= 1 arena-bytes #x100000000))
    (error 'invalid-argument :reason :primary-fragment-configuration))
  (let ((capacity (indice-primario-capacity index)) (budget (indice-primario-fragment-budget index)))
    (when (> (+ (* 41 capacity) arena-bytes) budget)
      (error 'resource-exhausted :reason :primary-fragment-memory-budget))
    (%make-frammento-indice index depth prefix (crea-banco-slot :capacity capacity :budget-bytes budget)
                           (make-array capacity :element-type '(unsigned-byte 8)
                                                :initial-element +ctrl-empty+)
                           (make-array arena-bytes :element-type '(unsigned-byte 8) :initial-element 0))))

;;; REQ: REQ-IDX-001 REQ-IDX-007 REQ-AFF-008
(declaim (ftype (function (&key (:capacity integer) (:max-depth integer)
                               (:directory-budget-bytes integer) (:fragment-budget-bytes integer)
                               (:arena-bytes integer)) indice-primario) crea-indice-primario))
(defun crea-indice-primario (&key (capacity 8192) (max-depth 20)
                                (directory-budget-bytes 8388608) (fragment-budget-bytes 8388608)
                                (arena-bytes 65536))
  "Pre: controller; limiti della configurazione locale, non della dimensione totale di una Serie.
Post: root iniziale G=0, generazione 0, un frammento vuoto. Nessun thread o I/O."
  (unless (and (<= 16 capacity 65536) (zerop (logand capacity (1- capacity)))
               (<= 0 max-depth 30) (<= 8 directory-budget-bytes most-positive-fixnum)
               (<= 1 fragment-budget-bytes most-positive-fixnum))
    (error 'invalid-argument :reason :primary-index-configuration))
  (let* ((index (%make-indice-primario capacity max-depth directory-budget-bytes fragment-budget-bytes))
         (fragment (crea-frammento-indice index :arena-bytes arena-bytes)))
    (setf (frammento-indice-exposure fragment) :published
          (indice-primario-root index) (%make-root-indice 0 0 (vector fragment)))
    index))

;;; REQ: REQ-IDX-003 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function () contesto-indice) crea-contesto-indice))
(defun crea-contesto-indice ()
  "Pre: controller prima dell'avvio dei worker. Post: scratch privato, riusabile senza allocazione.
La quantita di contesti è limitata dal pool; nessun collegamento a una Serie o pin acquisito."
  (%make-contesto-indice (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0)))

;;; REQ: REQ-IDX-005 REQ-AFF-004
(declaim (inline esigi-frammento-writer))
(declaim (ftype (function (indice-primario frammento-indice u32) null) esigi-frammento-writer))
(defun esigi-frammento-writer (index fragment high)
  "Pre: gettone writer esclusivo. Post: dominio, prefisso del digest e stato scrivibile verificati.
RETIRED non si riapre; digest incoerente con il frammento rifiutato prima dei cambi."
  (esigi-frammento-sano index fragment)
  (when (eq (frammento-indice-exposure fragment) :retired)
    (error 'invalid-argument :reason :primary-fragment-retired))
  (unless (= (frammento-indice-prefix fragment) (prefix-hash high (frammento-indice-depth fragment)))
    (error 'invalid-argument :reason :primary-fragment-prefix))
  (esigi-banco-writer (frammento-indice-bank fragment))
  nil)

;;; REQ: REQ-IDX-007 REQ-AFF-004
(declaim (ftype (function (indice-primario u32) frammento-indice) frammento-corrente-indice))
(defun frammento-corrente-indice (index high)
  "Pre: writer con gettone della Serie; digest della chiave. Post: frammento corrente canonico.
Solo per preflight/mutazioni del writer; non autorizza un reader a conservare slot o location."
  (esigi-indice-sano index)
  (let* ((root (acquisisci-root index))
         (fragment (aref (root-indice-directory root) (prefix-hash high (root-indice-depth root)))))
    (esigi-frammento-writer index fragment high)
    fragment))
