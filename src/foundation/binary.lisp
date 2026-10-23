;;;; Interi little-endian su vettori contigui; tutti i range sono half-open.
(in-package #:arcdocdb.binary)
(declaim (optimize (safety 3) (debug 2)))
(deftype octets () '(simple-array (unsigned-byte 8) (*)))
(deftype index () '(integer 0 #.most-positive-fixnum))
(deftype u8 () '(unsigned-byte 8))
(deftype u16 () '(unsigned-byte 16))
(deftype u32 () '(unsigned-byte 32))
(deftype u64 () '(unsigned-byte 64))

;;; REQ: REQ-LIM-001 REQ-AFF-004
(declaim (ftype (function (octets integer integer) (values index &optional))
                check-range))
(defun check-range (buffer start end)
  "Pre: BUFFER octets. Post: restituisce END se 0<=START<=END<=length.
Segnala INVALID-ARGUMENT su intervallo invalido; non modifica BUFFER."
  (unless (<= 0 start end (length buffer))
    (error 'invalid-argument :reason :buffer-range))
  end)

;;; REQ: REQ-FOR-003
(declaim (inline leggi-u16 leggi-u32))
(declaim (ftype (function (octets index) (values u16 &optional)) leggi-u16)
         (ftype (function (octets index) (values u32 &optional)) leggi-u32)
         (ftype (function (octets index) (values u64 &optional)) leggi-u64))
(defun leggi-u16 (buffer start)
  "Pre: range di due byte valido. Post: u16 LE; nessuna modifica.
Segnala INVALID-ARGUMENT se fuori range."
  (check-range buffer start (+ start 2))
  (logior (aref buffer start) (ash (aref buffer (+ start 1)) 8)))

;;; REQ: REQ-FOR-003
(defun leggi-u32 (buffer start)
  "Pre: range di quattro byte valido. Post: u32 LE; nessuna modifica.
Segnala INVALID-ARGUMENT se fuori range."
  (check-range buffer start (+ start 4))
  (logior (aref buffer start) (ash (aref buffer (+ start 1)) 8)
          (ash (aref buffer (+ start 2)) 16) (ash (aref buffer (+ start 3)) 24)))

;;; REQ: REQ-FOR-003
(defun leggi-u64 (buffer start)
  "Pre: range di otto byte valido. Post: u64 LE; nessuna modifica.
Segnala INVALID-ARGUMENT se fuori range; u64 alto può essere un bignum."
  (check-range buffer start (+ start 8))
  (logior (leggi-u32 buffer start) (ash (leggi-u32 buffer (+ start 4)) 32)))

;;; REQ: REQ-FOR-003
(declaim (ftype (function (octets index u16) (values u16 &optional)) scrivi-u16)
         (ftype (function (octets index u32) (values u32 &optional)) scrivi-u32)
         (ftype (function (octets index u64) (values u64 &optional)) scrivi-u64))
(defun scrivi-u16 (buffer start value)
  "Pre: VALUE u16 e range di due byte valido. Post: due byte LE scritti.
Segnala INVALID-ARGUMENT prima di modificare se il range non è valido."
  (check-range buffer start (+ start 2))
  (dotimes (i 2 value) (setf (aref buffer (+ start i)) (ldb (byte 8 (* i 8)) value))))

;;; REQ: REQ-FOR-003
(defun scrivi-u32 (buffer start value)
  "Pre: VALUE u32 e range di quattro byte valido. Post: quattro byte LE scritti.
Segnala INVALID-ARGUMENT prima di modificare se il range non è valido."
  (check-range buffer start (+ start 4))
  (dotimes (i 4 value) (setf (aref buffer (+ start i)) (ldb (byte 8 (* i 8)) value))))

;;; REQ: REQ-FOR-003
(defun scrivi-u64 (buffer start value)
  "Pre: VALUE u64 e range di otto byte valido. Post: otto byte LE scritti.
Segnala INVALID-ARGUMENT prima di modificare se il range non è valido."
  (check-range buffer start (+ start 8))
  (dotimes (i 8 value) (setf (aref buffer (+ start i)) (ldb (byte 8 (* i 8)) value))))
