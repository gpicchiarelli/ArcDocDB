;;; OWNER: un registro per Archivio; una prenotazione preallocata per contesto di commit.
;;; SHARED: ogni campo mutabile si consulta/modifica sotto il mutex del suo registro.
(in-package #:arcdocdb.mvcc)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-008 REQ-AFF-008
(defconstant +max-csn+ #xffffffffffffffff)
(defconstant +max-csn-slots+ 65536)
(deftype csn-words () '(simple-array (unsigned-byte 64) (*)))
(deftype csn-slot () '(integer 0 65535))

;;; REQ: REQ-MVC-008 REQ-AFF-008
(defstruct (registro-csn (:constructor %make-registro-csn (slots counters mutex)) (:copier nil))
  "Pre: array privati, mutex per Archivio. Post: registro limitato inizialmente vuoto.
SLOTS contiene solo CSN in volo; COUNTERS[0]=ultimo, COUNTERS[1]=orizzonte."
  (slots #() :type csn-words :read-only t)
  (counters #() :type csn-words :read-only t)
  (mutex nil :type sb-thread:mutex :read-only t)
  (pending 0 :type (integer 0 65536))
  (cursor 0 :type csn-slot)
  (state :open :type (member :open :faulted)))

;;; REQ: REQ-MVC-008
(defstruct (prenotazione-csn (:constructor %make-prenotazione-csn (registry word)) (:copier nil))
  "Pre: contesto preallocato legato a un solo registro. Post: prenotazione libera.
WORD[0] conserva il CSN; slot riusabile solo con identità CSN verificata."
  (registry nil :type registro-csn :read-only t)
  (word #() :type csn-words :read-only t)
  (slot 0 :type csn-slot)
  (state :libera :type (member :libera :attiva :conclusa)))

;;; REQ: REQ-MVC-008 REQ-AFF-004
(declaim (ftype (function (registro-csn) null) esigi-registro-csn))
(defun esigi-registro-csn (registry)
  "Pre: mutex del registro posseduto. Post: registro sano.
INVARIANT-VIOLATION dopo un'interruzione di una transizione; nessuna riparazione in memoria."
  (unless (eq (registro-csn-state registry) :open)
    (error 'invariant-violation :reason :csn-registry-faulted))
  (let* ((capacity (length (registro-csn-slots registry)))
         (pending (registro-csn-pending registry)) (counters (registro-csn-counters registry))
         (last (aref counters 0)) (horizon (aref counters 1)))
    (declare (type u64 last horizon))
    (unless (and (<= pending capacity) (< (registro-csn-cursor registry) capacity)
                 (if (zerop pending) (= horizon last) (< horizon last)))
      (guasto-registro-csn registry :csn-counters-inconsistent)))
  nil)

;;; REQ: REQ-MVC-008 REQ-AFF-004
(declaim (ftype (function (registro-csn keyword) nil) guasto-registro-csn))
(defun guasto-registro-csn (registry reason)
  "Pre: mutex posseduto, incoerenza interna. Post: registro FAULTED e errore tipizzato.
Il proprietario isola l'Archivio; nessun successivo orizzonte viene restituito."
  (setf (registro-csn-state registry) :faulted)
  (error 'invariant-violation :reason reason))

;;; REQ: REQ-MVC-008 REQ-AFF-008
(declaim (ftype (function (&key (:capacity integer) (:recovered-max integer)) registro-csn)
                crea-registro-csn))
(defun crea-registro-csn (&key (capacity 256) (recovered-max 0))
  "Pre: recovery concluso, RECOVERED-MAX comprende ogni CSN osservato nell'Archivio.
Post: ultimo=H=massimo recuperato, zero pendenti; INVALID-ARGUMENT per budget/intervallo.
Allocazioni solo all'inizializzazione; mai un secondo allocatore per lo stesso Archivio."
  (unless (and (<= 1 capacity +max-csn-slots+) (<= 0 recovered-max +max-csn+))
    (error 'invalid-argument :reason :csn-registry-configuration))
  (%make-registro-csn
   (make-array capacity :element-type '(unsigned-byte 64) :initial-element 0)
   (make-array 2 :element-type '(unsigned-byte 64) :initial-element recovered-max)
   (sb-thread:make-mutex :name "ArcDocDB: orizzonte Archivio")))

;;; REQ: REQ-MVC-008
(declaim (ftype (function (registro-csn) prenotazione-csn) crea-prenotazione-csn))
(defun crea-prenotazione-csn (registry)
  "Pre: registro dell'Archivio. Post: contesto privato preallocato, senza credito riservato.
La salute è verificata alla riserva; nessun buffer del registro è esportato."
  (%make-prenotazione-csn registry
                         (make-array 1 :element-type '(unsigned-byte 64) :initial-element 0)))

;;; REQ: REQ-MVC-008
(declaim (ftype (function (registro-csn) (integer 1 65536)) capienza-registro-csn))
(defun capienza-registro-csn (registry)
  "Pre: registro esistente. Post: capacità immutabile, leggibile anche dopo FAULTED."
  (length (registro-csn-slots registry)))

;;; REQ: REQ-MVC-008 REQ-AFF-004
(declaim (ftype (function (registro-csn) (member :open :faulted)) stato-registro-csn))
(defun stato-registro-csn (registry)
  "Pre: registro esistente. Post: salute letta sotto mutex; nessuna syscall o callback."
  (sb-thread:with-mutex ((registro-csn-mutex registry))
    (registro-csn-state registry)))
