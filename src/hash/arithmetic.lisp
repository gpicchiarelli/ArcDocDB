;;; OWNER: solo valori locali del chiamante; nessuna risorsa o scratch condiviso.
;;; SHARED: costanti immutabili XXH64, non un hash crittografico.
(in-package #:arcdocdb.hash64)
(declaim (optimize (safety 3) (speed 3) (debug 2)))

;;; REQ: REQ-IDX-001
(defconstant +mask64+ #xffffffffffffffff)
(defconstant +prime1+ #x9e3779b185ebca87)
(defconstant +prime2+ #xc2b2ae3d27d4eb4f)
(defconstant +prime3+ #x165667b19e3779f9)
(defconstant +prime4+ #x85ebca77c2b2ae63)
(defconstant +prime5+ #x27d4eb2f165667c5)

;;; REQ: REQ-LIM-003
(deftype hash-length () '(integer 0 #.arcdocdb.record:+max-key-bytes+))

(declaim (inline read32 read64 rotate64 round64 merge64 avalanche64))

;;; REQ: REQ-IDX-001 REQ-AFF-004
(declaim (ftype (function (octets index) u32) read32))
(defun read32 (buffer position)
  "Pre: quattro byte nello span gia verificato. Post: u32 little-endian, input immutato.
I controlli di tipo e di ciascun accesso restano attivi con safety 3."
  (logior (aref buffer position) (ash (aref buffer (+ position 1)) 8)
          (ash (aref buffer (+ position 2)) 16) (ash (aref buffer (+ position 3)) 24)))

;;; REQ: REQ-IDX-001 REQ-AFF-004
(declaim (ftype (function (octets index) u64) read64))
(defun read64 (buffer position)
  "Pre: otto byte nello span verificato. Post: parola LE nativa nel codice inline.
Non restituita attraverso il confine pubblico; nessuna modifica del buffer."
  (logior (read32 buffer position) (ash (read32 buffer (+ position 4)) 32)))

;;; REQ: REQ-IDX-001
(declaim (ftype (function (u64 (integer 1 63)) u64) rotate64))
(defun rotate64 (value count)
  "Pre: u64 e rotazione tra 1 e 63. Post: rotazione circolare modulo 2^64.
Helper inline; i chiamanti fissano COUNT a una costante dell'algoritmo."
  (logand +mask64+ (logior (ash value count) (ash value (- count 64)))))

;;; REQ: REQ-IDX-001
(declaim (ftype (function (u64 u64) u64) round64))
(defun round64 (accumulator lane)
  "Pre: due u64. Post: round XXH64 modulo 2^64, puro e inline.
Overflow modulari intenzionali; nessun valore u64 attraversa la API pubblica."
  (logand +mask64+ (* (rotate64 (logand +mask64+ (+ accumulator (* lane +prime2+))) 31)
                      +prime1+)))

;;; REQ: REQ-IDX-001
(declaim (ftype (function (u64 u64) u64) merge64))
(defun merge64 (accumulator lane)
  "Pre: accumulatori u64. Post: convergenza XXH64 modulo 2^64, pura e inline.
Non segnala condizioni su argomenti conformi; non possiede risorse."
  (logand +mask64+ (+ (* (logxor accumulator (round64 0 lane)) +prime1+) +prime4+)))

;;; REQ: REQ-IDX-001
(declaim (ftype (function (u64) u64) avalanche64))
(defun avalanche64 (value)
  "Pre: u64. Post: diffusione finale XXH64 modulo 2^64, pura e inline.
Non segnala condizioni su argomenti conformi; nessun risultato boxed pubblico."
  (let ((accumulator value))
    (declare (type u64 accumulator))
    (setf accumulator (logand +mask64+ (* (logxor accumulator (ash accumulator -33)) +prime2+)))
    (setf accumulator (logand +mask64+ (* (logxor accumulator (ash accumulator -29)) +prime3+)))
    (logxor accumulator (ash accumulator -32))))
