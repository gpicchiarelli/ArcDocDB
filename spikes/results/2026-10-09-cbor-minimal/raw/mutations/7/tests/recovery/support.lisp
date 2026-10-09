;;;; Harness recovery: fixture bytewise, CRC indipendente e nessun I/O.
(defpackage #:arcdocdb.recovery.tests
  (:use #:cl)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:unsupported-format
                #:corruption-detected #:resource-exhausted #:error-reason #:error-offset)
  (:import-from #:arcdocdb.recovery.scan #:scansiona-log #:log-corruption
                #:corruption-prefix-end #:corruption-witness-offset
                #:corruption-durable-offset #:corruption-first-reason)
  (:import-from #:arcdocdb.foundation.tests #:bytes #:reference-crc)
  (:export #:run))
(in-package #:arcdocdb.recovery.tests)
(defvar *tests* nil)

(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))

(defmacro is (expression)
  `(unless ,expression (error "Asserzione recovery fallita: ~S" ',expression)))

(defmacro signals (type form &optional reason)
  `(let ((condition (handler-case (progn ,form nil)
                      (,type (caught) caught))))
     (is (typep condition ',type))
     ,@(when reason `((is (eq (error-reason condition) ,reason))))
     condition))

(defun reference-le (buffer start width value)
  "Packing bytewise indipendente dalle primitive binarie del prodotto."
  (dotimes (i width)
    (setf (aref buffer (+ start i)) (ldb (byte 8 (* i 8)) value))))

(defun repair-reference-record (buffer start end)
  "CRC bitwise su corpo e header, anche per semantica malformata."
  (reference-le buffer (+ start 4) 4 (reference-crc buffer (+ start 24) end))
  (reference-le buffer start 4 (reference-crc buffer (+ start 4) (+ start 24))))

(defun reference-record (kind stamp key value &key (version 2) (flags 0))
  "Cornice della specifica, senza scrivi-record né scrivi-uXX del prodotto."
  (let ((buffer (make-array (+ 24 (length key) (length value))
                            :element-type '(unsigned-byte 8) :initial-element 0)))
    (setf (aref buffer 8) kind (aref buffer 9) flags)
    (reference-le buffer 10 (if (= version 1) 1 2) (length key))
    (reference-le buffer 12 4 (length value))
    (reference-le buffer 16 8 stamp)
    (replace buffer key :start1 24)
    (replace buffer value :start1 (+ 24 (length key)))
    (repair-reference-record buffer 0 (length buffer))
    buffer))

(defun reference-batch (start file-offset file-id kind count version durable)
  "Lotto indipendente: gli offset sono assoluti nel file, i CRC sono bitwise."
  (let* ((key (if (= kind 1) (bytes 21 22) (bytes)))
         (value (make-array (case kind (1 3) (5 24) (6 26))
                            :element-type '(unsigned-byte 8) :initial-element 0))
         (record (reference-record kind (if (= kind 6) 101 17) key value
                                   :version version))
         (body (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0))
         (checksum 0))
    (dotimes (i count)
      (setf checksum (reference-crc record 0 4 checksum)))
    (reference-le body 0 8 file-id)
    (reference-le body 8 8 (+ file-offset start))
    (reference-le body 16 8 durable)
    (reference-le body 24 4 count)
    (reference-le body 28 4 checksum)
    (let* ((seal (reference-record 3 17 (bytes) body :version version))
           (seal-start (+ start (* count (length record))))
           (end (+ seal-start (length seal)))
           (batch (make-array (- end start) :element-type '(unsigned-byte 8)))
           (record-starts nil))
      (dotimes (i count)
        (replace batch record :start1 (* i (length record)))
        (push (+ start (* i (length record))) record-starts))
      (replace batch seal :start1 (- seal-start start))
      (values batch (list :start start :records (nreverse record-starts)
                          :seal seal-start :end end)))))

(defun log-fixture (&key (version 2) (log-kind :segment) (file-id 31)
                        (file-offset 64) (prefix 7) (batches 3) (records 2)
                        durables)
  "Restituisce buffer, inizio, fine e posizioni note senza parser del prodotto."
  (let ((chunks nil) (layouts nil) (pos prefix)
        (kind (case log-kind (:segment 1) (:control 5) (:multiserie 6))))
    (dotimes (i batches)
      (multiple-value-bind (batch layout)
          (reference-batch pos file-offset file-id kind records version
                           (if durables (nth i durables) (+ file-offset pos)))
        (push batch chunks) (push layout layouts) (setf pos (getf layout :end))))
    (let ((buffer (make-array pos :element-type '(unsigned-byte 8)
                             :initial-element #xcc)) (next prefix))
      (dolist (chunk (nreverse chunks))
        (replace buffer chunk :start1 next) (incf next (length chunk)))
      (values buffer prefix pos (nreverse layouts)))))

(defun set-durable (buffer layout durable)
  "Cambia la frontiera della fixture e ripara i CRC con l'oracolo indipendente."
  (let ((seal-start (getf layout :seal)))
    (reference-le buffer (+ seal-start 40) 8 durable)
    (repair-reference-record buffer seal-start (getf layout :end))))

(defun fixture-scan (buffer start end file-id
                     &key (version 2) (log-kind :segment) (file-offset 64)
                          (file-size (+ file-offset end)) (max-bytes 67108864)
                          (max-batches 65536) (max-batch-records 65536)
                          (max-batch-bytes 67108864) (max-search-bytes 67108864))
  "Invoca lo scanner con versione esplicita ed EOF completo della fixture."
  (scansiona-log buffer start end file-id :version version :log-kind log-kind
                :file-offset file-offset :file-size file-size :max-bytes max-bytes
                :max-batches max-batches :max-batch-records max-batch-records
                :max-batch-bytes max-batch-bytes :max-search-bytes max-search-bytes))

(defun run ()
  (dolist (test (reverse *tests*))
    (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test recovery superati.~%" (length *tests*))
  t)
