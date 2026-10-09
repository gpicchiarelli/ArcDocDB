;;; OWNER: controller costruisce il registro prima di avviare i worker; nessun ridimensionamento.
;;; SHARED: word reader distanti 128 byte; word E e soglia separate dai contatori di manutenzione.
(in-package #:arcdocdb.epochs)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(defconstant +max-epoca+ #xffffffffffffffff)
(defconstant +max-workers+ 4096)
(defconstant +max-ritiri+ 65536)
(defconstant +stride-epoca+ 16)
(defconstant +word-generation+ 0)
(defconstant +word-epoch+ 16)
(defconstant +word-threshold+ 32)
(deftype epoch-words () '(simple-array (unsigned-byte 64) (*)))
(deftype retirement-slot () '(integer 0 65535))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(defconstant +retirement-free+ 0)
(defconstant +retirement-reserved+ 1)
(defconstant +retirement-retired+ 2)
(defconstant +retirement-claimed+ 3)
(defconstant +retirement-cancelled+ 4)
(defconstant +retirement-completed+ 5)

;;; REQ: REQ-CMP-005 REQ-CMP-007 REQ-AFF-008
(defstruct (registro-epoche
            (:constructor %make-registro-epoche
                (announcements readers generations epochs states resources retirements words mutex))
            (:copier nil))
  "Pre: array privati e pool di capacità fissa. Post: E=1, soglia=1, nessun reader/ritiro.
Zero negli annunci significa inattivo. Solo la manutenzione modifica contatori e WORDS."
  (announcements #() :type epoch-words :read-only t)
  (readers #() :type simple-vector :read-only t)
  (generations #() :type epoch-words :read-only t)
  (epochs #() :type epoch-words :read-only t)
  (states #() :type (simple-array (unsigned-byte 8) (*)) :read-only t)
  (resources #() :type simple-vector :read-only t)
  (retirements #() :type simple-vector :read-only t)
  (words #() :type epoch-words :read-only t)
  (mutex nil :type sb-thread:mutex :read-only t)
  (count 0 :type (integer 0 65536))
  (reserved 0 :type (integer 0 65536))
  (cursor 0 :type retirement-slot)
  (health :open :type (member :open :faulted)))

;;; REQ: REQ-CMP-005 REQ-CMP-007
(defstruct (lettore-epoca (:constructor %make-lettore-epoca (registry offset)) (:copier nil))
  "Pre: contesto canonico assegnato a un solo worker vivo. Post: offset fisso nel dominio EBR.
Nessuna epoca o location attraversa una migrazione; non ammette sezioni annidate."
  (registry nil :type registro-epoche :read-only t)
  (offset 16 :type (integer 16 65536) :read-only t))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(defstruct (ritiro (:constructor %make-ritiro (registry slot)) (:copier nil))
  "Pre: ticket canonico preallocato. Post: identità di slot stabile; evento conserva la generazione.
Il registro conserva la risorsa finché annullata prima del ritiro o completata dopo reclaim."
  (registry nil :type registro-epoche :read-only t)
  (slot 0 :type retirement-slot :read-only t))

;;; REQ: REQ-CMP-005 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (integer integer) registro-epoche) crea-registro-epoche))
(defun crea-registro-epoche (worker-capacity retirement-capacity)
  "Pre: W=1..4096 comprende calcolo e I/O; K=1..65536. Post: tutti i contesti preallocati.
INVALID-ARGUMENT prima delle allocazioni per capacità invalida; nessun thread o I/O avviato."
  (unless (and (<= 1 worker-capacity +max-workers+) (<= 1 retirement-capacity +max-ritiri+))
    (error 'invalid-argument :reason :epoch-registry-capacity))
  (let* ((words (make-array (* 3 +stride-epoca+) :element-type '(unsigned-byte 64) :initial-element 0))
         (readers (make-array worker-capacity :initial-element nil))
         (retirements (make-array retirement-capacity :initial-element nil))
         (registry (%make-registro-epoche
                    (make-array (* (1+ worker-capacity) +stride-epoca+)
                                :element-type '(unsigned-byte 64) :initial-element 0)
                    readers
                    (make-array retirement-capacity :element-type '(unsigned-byte 64) :initial-element 0)
                    (make-array retirement-capacity :element-type '(unsigned-byte 64) :initial-element 0)
                    (make-array retirement-capacity :element-type '(unsigned-byte 8)
                                :initial-element +retirement-free+)
                    (make-array retirement-capacity :initial-element nil) retirements words
                    (sb-thread:make-mutex :name "ArcDocDB: ritiri Archivio"))))
    (setf (aref words +word-epoch+) 1 (aref words +word-threshold+) 1)
    (dotimes (worker worker-capacity)
      (setf (aref readers worker) (%make-lettore-epoca registry (* (1+ worker) +stride-epoca+))))
    (dotimes (slot retirement-capacity)
      (setf (aref retirements slot) (%make-ritiro registry slot)))
    registry))

;;; REQ: REQ-CMP-005 REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (registro-epoche integer) lettore-epoca) contesto-epoca))
(defun contesto-epoca (registry worker-id)
  "Pre: il controller assegna WORKER-ID esclusivo in tutti i pool dell'Archivio.
Post: stesso contesto preallocato per ID; riuso solo dopo join del precedente worker.
INVALID-ARGUMENT per ID fuori capacità. Non è una registrazione concorrente di thread."
  (unless (<= 0 worker-id (1- (length (registro-epoche-readers registry))))
    (error 'invalid-argument :reason :epoch-worker-range))
  (aref (registro-epoche-readers registry) worker-id))
