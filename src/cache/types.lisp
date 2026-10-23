;;; OWNER: controller per capacità; mutex di striscia per tag, byte, CLOCK e sequenze.
;;; SHARED: reader scrivono solo calore/rilettura e rifiuto conservativo di dati corrotti.
(in-package #:arcdocdb.cache)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(defconstant +cache-ways+ 8)
(defconstant +cache-tag-words+ 4)
(defconstant +cache-sequence-limit+ (ash 1 62))
(defconstant +cache-max-classes+ 16)
(defconstant +cache-max-sets+ 65536)
(defconstant +cache-max-slot-bytes+ (ash 1 25))
(deftype cache-u32s () '(simple-array (unsigned-byte 32) (*)))
(deftype cache-u64s () '(simple-array (unsigned-byte 64) (*)))
(deftype cache-slot () '(integer 0 524287))
(deftype cache-set () '(integer 0 65535))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(defstruct (classe-cache (:constructor %make-classe-cache)
                        (:copier nil))
  "Pre: array privati all'avvio, capacità fissa e otto posti per insieme.
Post: slot contigui senza oggetti per entry; sequenze senza wrap, mutex solo in inserimento.
REJECTED scarta un dato dubbio; DISABLED è terminale dopo interruzione/esaurimento."
  (size 1024 :type (integer 1024 33554432) :read-only t)
  (sets 1 :type (integer 1 65536) :read-only t)
  (arena (make-array 0 :element-type 'u8) :type octets :read-only t)
  (tags (make-array 0 :element-type 'u32) :type cache-u32s :read-only t)
  (sequences (make-array 0 :element-type 'u64) :type cache-u64s :read-only t)
  (references (make-array 0 :element-type 'u8) :type octets :read-only t)
  (origins (make-array 0 :element-type 'u8) :type octets :read-only t)
  (reread (make-array 0 :element-type 'u8) :type octets :read-only t)
  (rejected (make-array 0 :element-type 'u8) :type octets :read-only t)
  (disabled (make-array 0 :element-type 'u8) :type octets :read-only t)
  (hands (make-array 0 :element-type 'u8) :type octets :read-only t)
  (locks #() :type simple-vector :read-only t))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(defstruct (cache-serie (:constructor %make-cache-serie (classes payload)) (:copier nil))
  "Pre: controller possiede una partizione indipendente per Serie e la pubblica una volta.
Post: budget del payload preallocato; nessun riferimento a indice, file, snapshot o altre Serie.
Con classi vuote tutte le richieste saltano la cache; nessuna risorsa persistente."
  (classes #() :type simple-vector :read-only t)
  (payload 0 :type index :read-only t))
