;;; OWNER: controller fuori dal percorso caldo, input di configurazione stabili.
;;; SHARED: nessuno durante costruzione; mutex locali pubblicati con la partizione.
(in-package #:arcdocdb.cache)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CCH-001 REQ-AFF-008
(declaim (ftype (function (integer) boolean) potenza-due-cache-p))
(defun potenza-due-cache-p (number)
  "Pre: intero. Post: T solo per potenza di due positiva; nessuna mutazione o errore."
  (and (plusp number) (zerop (logand number (1- number)))))

;;; REQ: REQ-CCH-001 REQ-AFF-008
(declaim (ftype (function (integer integer integer) integer) payload-classe-cache))
(defun payload-classe-cache (size sets stripes)
  "Pre: configurazione verificata, sets positivo. Post: payload arena, metadata, mani e lock-vector.
Calcolo cold con interi esatti; esclude header Lisp, oggetti mutex e allineamento del runtime."
  (+ (* sets +cache-ways+ (+ size 29)) sets (* 8 (min sets stripes))))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(declaim (ftype (function (cache-u32s cache-u32s integer integer)
                         (values index index &optional)) preflight-cache))
(defun preflight-cache (sizes counts budget stripes)
  "Pre: configurazioni stabili del controller. Post: payload e numero classi attive prima di allocare.
INVALID-ARGUMENT per ordine/potenze/limiti; RESOURCE-EXHAUSTED per budget o indice non rappresentabile."
  (unless (and (= (length sizes) (length counts))
               (<= (length sizes) +cache-max-classes+) (<= 0 budget most-positive-fixnum)
               (<= 1 stripes 256) (potenza-due-cache-p stripes))
    (error 'invalid-argument :reason :cache-configuration))
  (let ((previous 0) (payload 0) (active 0))
    (dotimes (i (length sizes))
      (let ((size (aref sizes i)) (sets (aref counts i)))
        (unless (and (< previous size) (<= 1024 size +cache-max-slot-bytes+)
                     (potenza-due-cache-p size) (<= sets +cache-max-sets+)
                     (or (zerop sets) (potenza-due-cache-p sets)))
          (error 'invalid-argument :reason :cache-class-configuration))
        (setf previous size)
        (when (plusp sets)
          (incf active)
          (incf payload (+ 8 (payload-classe-cache size sets stripes))))))
    (unless (<= payload budget)
      (error 'resource-exhausted :reason :cache-payload-budget))
    (values payload active)))

;;; REQ: REQ-CCH-001 REQ-AFF-008
(declaim (ftype (function ((integer 1024 33554432) (integer 1 65536) (integer 1 256))
                         classe-cache) alloca-classe-cache))
(defun alloca-classe-cache (size sets stripes)
  "Pre: preflight completo, controller esclusivo. Post: tutti gli array azzerati e mutex privati.
Alloca solo in costruzione; un errore lascia oggetti non pubblicati e scartabili dal GC."
  (let* ((slots (* sets +cache-ways+)) (locks (make-array (min sets stripes))))
    (dotimes (i (length locks)) (setf (aref locks i) (sb-thread:make-mutex :name "cache-stripe")))
    (%make-classe-cache
     :size size :sets sets :arena (make-array (* slots size) :element-type 'u8 :initial-element 0)
     :tags (make-array (* slots +cache-tag-words+) :element-type 'u32 :initial-element 0)
     :sequences (make-array slots :element-type 'u64 :initial-element 0)
     :references (make-array slots :element-type 'u8 :initial-element 0)
     :origins (make-array slots :element-type 'u8 :initial-element 0)
     :reread (make-array slots :element-type 'u8 :initial-element 0)
     :rejected (make-array slots :element-type 'u8 :initial-element 0)
     :disabled (make-array slots :element-type 'u8 :initial-element 0)
     :hands (make-array sets :element-type 'u8 :initial-element 0) :locks locks)))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(declaim (ftype (function (cache-u32s cache-u32s integer &key (:stripes integer)) cache-serie)
                crea-cache-serie))
(defun crea-cache-serie (sizes counts budget &key (stripes 16))
  "Pre: vettori u32 di classi crescenti e quantità di insiemi, stabili durante la chiamata.
Post: partizione fissa senza trattenere i vettori input; counts tutti zero consente budget zero.
Propaga preflight tipizzato prima delle allocazioni; non ridimensiona partizioni pubblicate."
  (multiple-value-bind (payload active) (preflight-cache sizes counts budget stripes)
    (let ((classes (make-array active)) (position 0))
      (dotimes (i (length sizes))
        (when (plusp (aref counts i))
          (setf (aref classes position)
                (alloca-classe-cache (aref sizes i) (aref counts i) stripes))
          (incf position)))
      (%make-cache-serie classes payload))))

;;; REQ: REQ-CCH-001 REQ-OBS-002
(declaim (ftype (function (cache-serie) index) payload-cache-serie))
(defun payload-cache-serie (cache)
  "Pre: partizione pubblicata. Post: payload fisso riservato; nessuna scansione, lock o scrittura.
Non rappresenta RSS, header del runtime o budget dello scheduler."
  (cache-serie-payload cache))
