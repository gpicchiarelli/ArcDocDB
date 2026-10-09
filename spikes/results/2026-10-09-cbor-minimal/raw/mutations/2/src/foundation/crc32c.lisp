;;;; CRC32C slicing-by-8 in Lisp; seme e risultato sono checksum finalizzati.
(in-package #:arcdocdb.binary)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-FOR-003
(defconstant +crc32c-polynomial+ #x82f63b78)

;;; OWNER: modulo binary, costruzione al caricamento; tabelle private immutabili dopo init.
;;; SHARED: nessuna scrittura per operazione; sole letture tra Serie.
;;; REQ: REQ-FOR-003
(declaim (ftype (function () (simple-array u32 (8 256))) make-crc32c-tables))
(defun make-crc32c-tables ()
  "Pre: nessuna. Post: otto tabelle private coerenti col polinomio CRC32C.
Allocazione solo all'avvio; nessun dato esterno, nessun errore recuperabile."
  (let ((tables (make-array '(8 256) :element-type 'u32 :initial-element 0)))
    (dotimes (i 256)
      (let ((crc i))
        (dotimes (bit 8)
          (setf crc (logxor (ash crc -1)
                           (if (oddp crc) +crc32c-polynomial+ 0))))
        (setf (aref tables 0 i) crc)))
    (dotimes (row 7)
      (dotimes (i 256)
        (let ((crc (aref tables row i)))
          (setf (aref tables (1+ row) i)
                (logxor (ash crc -8) (aref tables 0 (logand crc 255)))))))
    tables))

;;; OWNER: binary; inizializzazione unica, mai modificato dopo pubblicazione.
;;; SHARED: sole letture; nessun lock, contatore o scrittura condivisa tra Serie.
;;; REQ: REQ-FOR-003
(defparameter +crc32c-tables+ (make-crc32c-tables))
(declaim (type (simple-array u32 (8 256)) +crc32c-tables+))

;;; REQ: REQ-FOR-003 REQ-AFF-002
(declaim (ftype (function (octets index index &optional u32) (values u32 &optional))
                crc32c))
(defun crc32c (buffer start end &optional (seed 0))
  "Pre: [START,END) valido; SEED checksum finalizzato (zero per primo blocco).
Post: CRC32C finalizzato; concatenazione incrementale equivalente alla sequenza unica.
Segnala INVALID-ARGUMENT sul range; nessuna copia, allocazione o modifica del buffer."
  (declare (type octets buffer) (type index start end) (type u32 seed)
           (optimize (speed 3) (safety 3)))
  (check-range buffer start end)
  (let ((crc (logxor seed #xffffffff)) (i start) (table +crc32c-tables+))
    (declare (type u32 crc) (type index i)
             (type (simple-array u32 (8 256)) table))
    (loop repeat (floor (- end start) 8)
          do (let ((word (logxor crc
                                (aref buffer i)
                                (ash (aref buffer (+ i 1)) 8)
                                (ash (aref buffer (+ i 2)) 16)
                                (ash (aref buffer (+ i 3)) 24))))
               (setf crc
                     (logxor (aref table 7 (ldb (byte 8 0) word))
                             (aref table 6 (ldb (byte 8 8) word))
                             (aref table 5 (ldb (byte 8 16) word))
                             (aref table 4 (ldb (byte 8 24) word))
                             (aref table 3 (aref buffer (+ i 4)))
                             (aref table 2 (aref buffer (+ i 5)))
                             (aref table 1 (aref buffer (+ i 6)))
                             (aref table 0 (aref buffer (+ i 7))))))
             (incf i 8))
    (loop for pos from i below end
          do (setf crc (logxor (ash crc -8)
                              (aref table 0 (logand 255 (logxor crc (aref buffer pos)))))))
    (logxor crc #xffffffff)))
