;;;; Scratch CBOR fisso; creazione soltanto prima del percorso caldo.
;;; OWNER: chiamante esclusivo; ogni worker usa un proprio spazio, mai concorrente.
;;; SHARED: nessuno stato scrivibile condiviso tra Serie o worker (INV-P6).
(in-package #:arcdocdb.cbor)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-008
(defconstant +cbor-scan-max-bytes+ 16777216)
;;; REQ: REQ-LIM-002 REQ-AFF-008
(defconstant +cbor-scan-max-depth+ 100)
;;; REQ: REQ-LIM-002 REQ-AFF-008
(defconstant +cbor-scan-frames+ 102)

;;; REQ: REQ-LIM-002 REQ-AFF-008
(defstruct (spazio-cbor (:constructor %crea-spazio-cbor ()) (:copier nil))
  "Scratch esclusivo: 102 frame, nessun riferimento al buffer; riusabile dopo errore.
KINDS: 0 root, 1/2 array/map definiti, 3/4 indefiniti, 5/6 bytes/testo indefiniti.
REMAINING: figli residui; per mappa indefinita 0 chiave, 1 valore atteso."
  (kinds (make-array +cbor-scan-frames+ :element-type '(unsigned-byte 8)
                    :initial-element 0)
         :type (simple-array (unsigned-byte 8) (102)) :read-only t)
  (remaining (make-array +cbor-scan-frames+ :element-type '(unsigned-byte 32)
                        :initial-element 0)
             :type (simple-array (unsigned-byte 32) (102)) :read-only t)
  (cursor 0 :type index)
  (top 0 :type (integer 0 101))
  (nodes 0 :type (integer 0 16777216))
  (depth 0 :type (integer 0 100))
  (peak-depth 0 :type (integer 0 100))
  (pending-tag nil :type boolean))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function () (values spazio-cbor &optional))
                %crea-spazio-cbor crea-spazio-cbor))
(defun crea-spazio-cbor ()
  "Pre: percorso freddo del worker. Post: spazio privato fisso senza buffer trattenuto.
Alloca struttura e due array solo qui; INVARIANT-VIOLATION per forma iniziale errata.
Il chiamante non condivide lo spazio tra verifiche concorrenti."
  (let ((space (%crea-spazio-cbor)))
    (unless (and (= +cbor-scan-frames+ (length (spazio-cbor-kinds space)))
                 (= +cbor-scan-frames+ (length (spazio-cbor-remaining space))))
      (error 'invariant-violation :reason :cbor-workspace-capacity))
    (unless (and (zerop (spazio-cbor-top space)) (zerop (spazio-cbor-depth space))
                 (not (eq (spazio-cbor-kinds space) (spazio-cbor-remaining space))))
      (error 'invariant-violation :reason :cbor-workspace-initial))
    space))

;;; REQ: REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (spazio-cbor index) (values null &optional)) azzera-spazio-cbor))
(defun azzera-spazio-cbor (space start)
  "Pre: preflight concluso e scratch esclusivo. Post: tutti i frame azzerati, root=1.
Nessuna allocazione o riferimento al buffer; INVARIANT-VIOLATION per capacita errata."
  (unless (= +cbor-scan-frames+ (length (spazio-cbor-kinds space)))
    (error 'invariant-violation :reason :cbor-workspace-capacity))
  (unless (= +cbor-scan-frames+ (length (spazio-cbor-remaining space)))
    (error 'invariant-violation :reason :cbor-workspace-capacity))
  (fill (spazio-cbor-kinds space) 0)
  (fill (spazio-cbor-remaining space) 0)
  (setf (aref (spazio-cbor-remaining space) 0) 1
        (spazio-cbor-cursor space) start (spazio-cbor-top space) 0
        (spazio-cbor-nodes space) 0 (spazio-cbor-depth space) 0
        (spazio-cbor-peak-depth space) 0 (spazio-cbor-pending-tag space) nil)
  nil)
