;;; OWNER: un worker possiede contesto, run e analisi; nessuna mutazione dopo il prestito DONE.
;;; SHARED: solo configurazione immutabile e tabelle Unicode fra Serie (INV-P6).
(in-package #:arcdocdb.fulltext.document)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010
(defstruct (preparazione-full-text
             (:constructor %preparazione-full-text (config cbor analysis run begins ends present)) (:copier nil))
  "Task preallocato: input prestato fino a DONE/FAILED/CANCELLED, run prestato dopo DONE.
Ripartire invalida il risultato precedente; il proprietario deve averne terminato l'uso."
  (config nil :type (or null configurazione-full-text) :read-only t)
  (cbor (cb:crea-spazio-cbor) :type cb:spazio-cbor :read-only t)
  (analysis (a:crea-spazio-full-text) :type a:spazio-full-text :read-only t)
  (run (r:crea-indice-posizionale) :type r:indice-posizionale :read-only t)
  (begins (make-array 0 :element-type 'u32) :type (simple-array (unsigned-byte 32) (*)) :read-only t)
  (ends (make-array 0 :element-type 'u32) :type (simple-array (unsigned-byte 32) (*)) :read-only t)
  (present #* :type simple-bit-vector :read-only t)
  (masks (make-array 102 :element-type 'u16 :initial-element 0)
         :type (simple-array (unsigned-byte 16) (102)) :read-only t)
  (pending (make-array 102 :element-type 'u16 :initial-element 0)
           :type (simple-array (unsigned-byte 16) (102)) :read-only t)
  (seen (make-array 102 :element-type 'u16 :initial-element 0)
        :type (simple-array (unsigned-byte 16) (102)) :read-only t)
  (levels (make-array 102 :element-type '(unsigned-byte 8) :initial-element 0)
          :type (simple-array (unsigned-byte 8) (102)) :read-only t)
  (input nil :type (or null octets)) (start 0 :type index) (end 0 :type index) (row 0 :type u32)
  (borrower nil :type t)
  (phase :idle :type keyword) (field 0 :type index) (measure 0 :type index)
  (input-bytes 0 :type index) (prepared-bytes 0 :type index) (bound 0 :type index)
  (work 0 :type index) (work-limit 268435456 :type index)
  (node-limit 16777216 :type (integer 1 16777216))
  (file-limit 17179869184 :type index))

;;; REQ: REQ-SEC-006 REQ-SEC-010
(declaim (ftype (function (t &key (:max-scalars t) (:max-tokens t) (:token-bytes t) (:max-memory t))
                         preparazione-full-text) crea-preparazione-full-text))
(defun crea-preparazione-full-text (config &key (max-scalars 65536) (max-tokens 65536)
                                           (token-bytes 4194304) (max-memory 67108864))
  "Pre: configurazione immutabile, capacita fredde positive. Post: task/scratch esclusivi.
Budget conservativo prima di allocare: scalari, run, analisi, frame e overhead 64KiB.
Non conta configurazione/input gia posseduti o RSS. INVALID-ARGUMENT/RESOURCE-EXHAUSTED."
  (unless (and (typep config 'configurazione-full-text)
               (typep max-scalars '(integer 1 4294967295)) (typep max-tokens '(integer 1 4294967295))
               (typep token-bytes '(integer 1 4294967295)) (typep max-memory 'index))
    (error 'invalid-argument :reason :fulltext-document-capacity))
  (let* ((fields (length (configurazione-full-text-fields config)))
         (memory (+ (* 20 max-scalars) (* 28 max-tokens) (* 2 token-bytes) (* 12 fields) 65536)))
    (when (> memory max-memory) (error 'resource-exhausted :reason :fulltext-document-memory))
    (%preparazione-full-text
     config (cb:crea-spazio-cbor)
     (a:crea-spazio-full-text :max-scalars max-scalars :max-tokens max-tokens
                             :token-bytes token-bytes :max-memory max-memory)
     (r:crea-indice-posizionale :max-tokens max-tokens :max-bytes token-bytes
                               :max-fields fields :max-memory max-memory)
     (make-array fields :element-type 'u32 :initial-element 0)
     (make-array fields :element-type 'u32 :initial-element 0)
     (make-array fields :element-type 'bit :initial-element 0))))

;;; REQ: REQ-SEC-010
(declaim (ftype (function (preparazione-full-text &optional index) null) lavoro-documento))
(defun lavoro-documento (task &optional (units 1))
  "Pre: task esclusivo. Post: contatore entro limite; rifiuto prima del superamento."
  (unless (<= (preparazione-full-text-work task) (preparazione-full-text-work-limit task))
    (error 'invariant-violation :reason :fulltext-document-work-state))
  (when (> units (- (preparazione-full-text-work-limit task) (preparazione-full-text-work task)))
    (error 'resource-exhausted :reason :fulltext-document-work))
  (incf (preparazione-full-text-work task) units) nil)
