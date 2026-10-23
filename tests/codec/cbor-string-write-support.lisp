;;;; Corpus delle stringhe CBOR dal contratto, prima della lettura del nuovo prodotto.
(defpackage #:arcdocdb.cbor.string.write.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:corruption-detected #:error-reason #:error-offset)
  (:import-from #:arcdocdb.cbor.tests #:cbor-snapshot #:cbor-unchanged-p
                #:cbor-wait #:cbor-join #:cbor-stop-workers)
  (:import-from #:arcdocdb.cbor.structure.tests #:cs-ref-utf8)
  (:import-from #:arcdocdb.utf8.tests #:utf8-encode-scalars)
  (:export #:run))
(in-package #:arcdocdb.cbor.string.write.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test della scrittura delle stringhe CBOR minime superati.~%" (length *tests*))
  t)

(defun cws-header (major length)
  "Testata aritmetica fredda, senza encoder o decoder del prodotto."
  (let* ((width (cond ((< length 24) 0) ((< length 256) 1)
                      ((< length 65536) 2) (t 4)))
         (ai (if (zerop width) length (case width (1 24) (2 25) (4 26)))))
    (cons (+ (* major 32) ai)
          (loop for power from (1- width) downto 0
                collect (mod (floor length (expt 256 power)) 256)))))

(defun cws-destination (capacity &key (prefix 3) (suffix 7))
  (let* ((end (+ prefix capacity))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8))))
    (dotimes (i (length buffer)) (setf (aref buffer i) (mod (+ #xa7 (* i 37)) 256)))
    (values buffer prefix end)))

(defun cws-source (length &key (prefix 7) (suffix 5) (binary nil))
  "Sentinelle UTF-8 illegali fuori span; payload ASCII o pattern arbitrario distinto."
  (let* ((end (+ prefix length))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8)
                             :initial-element #xff)))
    (dotimes (i length)
      (setf (aref buffer (+ prefix i)) (if binary (mod (+ 11 (* i 53)) 256)
                                          (if (zerop (mod i 17)) 0 (+ 32 (mod i 95))))))
    (values buffer prefix end)))

(defun cws-literal-source (contents &key (prefix 7) (suffix 5))
  (multiple-value-bind (source start end) (cws-source (length contents) :prefix prefix :suffix suffix)
    (replace source contents :start1 start)
    (values source start end)))

(defun cws-accept (buffer start end major source source-start source-end &rest keys)
  "Un solo NEXT fixnum e intera destinazione attesa; sorgente disgiunta preservata.
Con EQ, il resto dell'array comune e lo span sorgente restano invariati."
  (let* ((before (copy-seq buffer)) (source-before (copy-seq source))
         (header (cws-header major (- source-end source-start)))
         (next (+ start (length header) (- source-end source-start)))
         (expected (copy-seq before)))
    (replace expected header :start1 start)
    (replace expected source-before :start1 (+ start (length header))
                                    :start2 source-start :end2 source-end)
    (let ((actual (multiple-value-list
                   (apply #'arcdocdb.cbor:scrivi-stringa-cbor-minima
                          buffer start end major source source-start source-end keys))))
      (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
      (is (= next (first actual))) (is (<= start next end))
      (is (equalp buffer expected))
      (is (equalp (subseq source source-start source-end)
                  (subseq source-before source-start source-end)))
      (unless (eq source buffer) (is (equalp source source-before)))
      (first actual))))

(defun cws-reject (buffer start end major source source-start source-end type reason offset &rest keys)
  "Rifiuto tipizzato/offset assoluto e nessuna mutazione di entrambi gli array fisici."
  (let ((before (cbor-snapshot buffer)) (source-before (cbor-snapshot source))
        (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (apply #'arcdocdb.cbor:scrivi-stringa-cbor-minima
                             buffer start end major source source-start source-end keys)
                      (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed))) (is (eql offset (error-offset observed))) t)
      (is (cbor-unchanged-p buffer before))
      (is (cbor-unchanged-p source source-before)))))

(defun cws-compare (buffer start end major source source-start source-end)
  "Solo argomenti validi, budget/capacita sufficienti e array distinti nel fuzz freddo."
  (multiple-value-bind (valid reason offset)
      (if (= major 2) (values t nil nil) (cs-ref-utf8 source source-start source-end))
    (if valid (progn (cws-accept buffer start end major source source-start source-end) t)
        (progn (cws-reject buffer start end major source source-start source-end
                          'corruption-detected reason offset) nil))))

(defun cws-shared-worker-source ()
  "1024 byte di scalari validi distinti; stessa sorgente read-only per entrambi i worker."
  (multiple-value-bind (source start end) (cws-source 1024 :prefix 5)
    (let ((unit '#(#x41 #x00 #xc2 #xa2 #xe2 #x82 #xac #x42)))
      (dotimes (i 1024) (setf (aref source (+ start i)) (aref unit (mod i 8)))))
    (values source start end)))

(defun cws-worker (index major buffer start end source source-start source-end expected next
                   token rounds ready go done starts firsts ends sinks)
  "Due ondate: rendezvous dopo il primo item verificato, risorse private e input immutabili.
Il WALL della fixture include rendezvous e controlli; non misura il tempo puro dell'encoder."
  (handler-case
      (progn
        (dotimes (wave 2)
          (setf (aref starts index wave) (get-internal-real-time))
          (let ((sink 0))
            (dotimes (iteration rounds)
              (let ((actual (multiple-value-list
                             (arcdocdb.cbor:scrivi-stringa-cbor-minima
                              buffer start end major source source-start source-end))))
                (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
                (is (= next (first actual))) (is (equalp expected buffer))
                (incf sink (+ (first actual) (aref buffer start) (aref buffer (1- next)))))
              ;; Rendezvous dopo il primo item e i suoi controlli, senza chiamate prodotto aggiuntive.
              (when (zerop iteration)
                (setf (aref firsts index wave) (get-internal-real-time))
                (sb-thread:signal-semaphore (svref ready wave))
                (cbor-wait (svref go wave))))
            (is (= sink (* rounds token))) (setf (aref sinks index wave) sink))
          (setf (aref ends index wave) (get-internal-real-time))
          (sb-thread:signal-semaphore (svref done wave)))
        :ok)
    (error (condition) condition)))
