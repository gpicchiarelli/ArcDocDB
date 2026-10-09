(defpackage #:arcdocdb.storage.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:signals #:bytes #:reference-crc)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:corruption-detected
                #:resource-exhausted #:unsupported-format #:invariant-violation)
  (:import-from #:arcdocdb.storage.format #:scrivi-header-segmento #:verifica-header-segmento
                #:valida-valore-edit #:valida-valore-decision
                #:scrivi-valore-edit #:scrivi-valore-decision
                #:verifica-record-edit #:verifica-record-decision)
  (:export #:run))
(in-package #:arcdocdb.storage.tests)
(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))

(defun run ()
  (dolist (test (reverse *tests*))
    (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test dei metadati storage superati.~%" (length *tests*))
  t)

(defun zeros (n)
  (make-array n :element-type '(unsigned-byte 8) :initial-element 0))

(defun pack-le (buffer offset value width)
  "Packing dell'oracolo, distinto dalle primitive del prodotto."
  (dotimes (i width) (setf (aref buffer (+ offset i)) (ldb (byte 8 (* 8 i)) value))))

(defun header-oracle (version origin id-serie segment-id created)
  (let ((buffer (zeros 64)))
    (loop for char across "ARCDSEG1" for i from 0 do (setf (aref buffer i) (char-code char)))
    (pack-le buffer 8 version 2)
    (setf (aref buffer 10) origin)
    (replace buffer id-serie :start1 16)
    (pack-le buffer 32 segment-id 8)
    (pack-le buffer 40 created 8)
    (pack-le buffer 56 (reference-crc buffer 0 56) 4)
    buffer))

(defun header-fixture (&key (version 2) (origin 1) (prefix 7)
                           (segment-id #xfedcba9876543210) (created #xffffffffffffffff))
  (let ((buffer (make-array (+ prefix 64 5) :element-type '(unsigned-byte 8)
                            :initial-element #xcc))
        (serie (bytes 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15)))
    (scrivi-header-segmento buffer prefix serie segment-id created :version version :origine origin)
    (values buffer prefix (+ prefix 64) serie segment-id created)))

(defun closed-fixture (&optional (rows '((11 512 ((101 19) (102 20))) (12 64 nil))))
  "Sezione manuale; il count e gli esiti non provengono dall'encoder del prodotto."
  (let* ((size (loop for row in rows sum (+ 20 (* 16 (length (third row))))))
         (buffer (zeros size)) (pos 0))
    (dolist (row rows)
      (pack-le buffer pos (first row) 8)
      (pack-le buffer (+ pos 8) (second row) 8)
      (pack-le buffer (+ pos 16) (length (third row)) 4)
      (incf pos 20)
      (dolist (outcome (third row))
        (pack-le buffer pos (first outcome) 8)
        (pack-le buffer (+ pos 8) (second outcome) 8)
        (incf pos 16)))
    buffer))

(defun edit-fixture (&key (prefix 5) (complete nil))
  (let* ((closed (closed-fixture)) (removed (zeros 16))
         (end (+ prefix 24 (length closed) (length removed)))
         (buffer (make-array (+ end 5) :element-type '(unsigned-byte 8) :initial-element #xcc)))
    (pack-le removed 0 17 8) (pack-le removed 8 18 8)
    (scrivi-valore-edit buffer prefix (if complete #xffffffffffffffff 0) 13 closed 2 removed
                       :completo complete)
    (values buffer prefix end closed removed)))

(defun decision-fixture (&key (count 2) (prefix 3))
  (let* ((parts (zeros (* 16 count))) (end (+ prefix 10 (length parts)))
         (buffer (make-array (+ end 5) :element-type '(unsigned-byte 8) :initial-element #xcc)))
    (dotimes (i count) (pack-le parts (* 16 i) (1+ i) 8))
    (scrivi-valore-decision buffer prefix #xffffffffffffffff parts)
    (values buffer prefix end parts)))

(defun control-record (payload start end kind &key (version 2) (flags 0))
  (let* ((value (subseq payload start end)) (record (zeros (+ 24 (length value)))))
    (arcdocdb.record:scrivi-record record 0 kind #xffffffffffffffff (bytes) value
                                 :version version :flags flags)
    record))
