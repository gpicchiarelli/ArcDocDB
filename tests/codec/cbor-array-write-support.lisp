;;;; Corpus dal metodo REQ-CBR-005, prima della scrittura del nuovo prodotto.
(defpackage #:arcdocdb.cbor.array.write.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:corruption-detected #:error-reason #:error-offset)
  (:import-from #:arcdocdb.cbor.structure.tests #:cs-snapshot #:cs-unchanged-p
                #:cs-wait #:cs-join #:cs-stop-workers)
  (:export #:run))
(in-package #:arcdocdb.cbor.array.write.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test della composizione degli array CBOR superati.~%" (length *tests*))
  t)

(defun caw-header (major count)
  "Testata fredda aritmetica, senza encoder o parser del prodotto."
  (let* ((width (cond ((< count 24) 0) ((< count 256) 1)
                      ((< count 65536) 2) (t 4)))
         (ai (if (zerop width) count (case width (1 24) (2 25) (4 26)))))
    (cons (+ (* major 32) ai)
          (loop for power from (1- width) downto 0
                collect (mod (floor count (expt 256 power)) 256)))))

(defun caw-destination (capacity &key (prefix 3) (suffix 7))
  (let* ((end (+ prefix capacity))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8))))
    (dotimes (i (length buffer)) (setf (aref buffer i) (mod (+ #xa7 (* i 37)) 256)))
    (values buffer prefix end)))

(defun caw-fixture (children &key (prefix 7))
  "Figli letterali distinti: source con sentinelle, fini relative e due entry non lette."
  (let* ((count (length children)) (span (reduce #'+ children :key #'length :initial-value 0))
         (end (+ prefix span))
         (source (make-array (+ end 5) :element-type '(unsigned-byte 8) :initial-element #xff))
         (item-ends (make-array (+ count 2) :element-type '(unsigned-byte 32)
                               :initial-element #xffffffff))
         (cursor 0))
    (loop for child in children for index from 0
          do (replace source child :start1 (+ prefix cursor))
             (incf cursor (length child)) (setf (aref item-ends index) cursor))
    (values source prefix end item-ends count)))

(defun caw-space-snapshot (space)
  (arcdocdb.cbor.minimal.scan.tests::cms-space-snapshot space))
(defun caw-dirty-space ()
  (arcdocdb.cbor.minimal.scan.tests::cms-dirty-space (arcdocdb.cbor:crea-spazio-cbor)))

(defun caw-accept (buffer start end source source-start source-end item-ends count space &rest keys)
  "Un solo NEXT, byte freddi e interi array; EQ preserva il solo span sorgente."
  (let* ((before (copy-seq buffer)) (source-before (copy-seq source))
         (table-before (copy-seq item-ends))
         (scratch-before (when (zerop count) (caw-space-snapshot space)))
         (header (caw-header 4 count))
         (next (+ start (length header) (- source-end source-start)))
         (expected (copy-seq before)))
    (replace expected header :start1 start)
    (replace expected source-before :start1 (+ start (length header))
                                    :start2 source-start :end2 source-end)
    (let ((actual (multiple-value-list
                   (apply #'arcdocdb.cbor:scrivi-array-cbor-minimo buffer start end
                          source source-start source-end item-ends count space keys))))
      (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
      (is (= next (first actual))) (is (<= start next end))
      (is (equalp expected buffer)) (is (equalp table-before item-ends))
      (is (equalp (subseq source-before source-start source-end)
                  (subseq source source-start source-end)))
      (unless (eq source buffer) (is (equalp source-before source)))
      (if (zerop count) (is (equalp scratch-before (caw-space-snapshot space)))
          (progn (is (= source-end (arcdocdb.cbor::spazio-cbor-cursor space)))
                 (is (zerop (arcdocdb.cbor::spazio-cbor-top space)))
                 (is (zerop (arcdocdb.cbor::spazio-cbor-depth space)))
                 (is (not (arcdocdb.cbor::spazio-cbor-pending-tag space)))))
      next)))

(defun caw-reject (buffer start end source source-start source-end item-ends count space
                    type reason offset &rest keys)
  "Rifiuto typed e offset assoluto; destinazione, source e tabella fisiche intatte."
  (let ((before (cs-snapshot buffer)) (source-before (cs-snapshot source))
        (table-before (cs-snapshot item-ends)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (apply #'arcdocdb.cbor:scrivi-array-cbor-minimo buffer start end
                             source source-start source-end item-ends count space keys)
                      (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed)))
           (is (eql offset (error-offset observed))) t)
      (is (cs-unchanged-p buffer before)) (is (cs-unchanged-p source source-before))
      (is (cs-unchanged-p item-ends table-before)))))

(defun caw-cold-reject (buffer start end source source-start source-end item-ends count space
                         type reason offset &rest keys)
  "Tutte le fasi di preflight preservano anche lo scratch gia sporco."
  (let ((before (caw-space-snapshot space)))
    (apply #'caw-reject buffer start end source source-start source-end item-ends count space
           type reason offset keys)
    (is (equalp before (caw-space-snapshot space)))))

(defun caw-probe (children &rest keys)
  (multiple-value-bind (source ss se table count) (caw-fixture children)
    (let ((size (+ (length (caw-header 4 count)) (- se ss))))
      (dolist (prefix '(0 1 7 31))
        (multiple-value-bind (buffer start end) (caw-destination size :prefix prefix)
          (apply #'caw-accept buffer start end source ss se table count (caw-dirty-space) keys)
          (apply #'caw-cold-reject buffer start (1- end) source ss se table count
                 (caw-dirty-space) 'resource-exhausted :cbor-array-capacity nil keys))))))

(defun caw-token (buffer next)
  (+ next (loop for i below (length buffer) sum (* (1+ i) (aref buffer i)))))

(defun caw-worker (index buffer start end source ss se table count space expected next token
                   source-before table-before rounds ready go done starts firsts finishes sinks)
  "Due ondate: rendezvous dopo il primo item verificato, risorse private e input immutabili.
Il WALL della fixture include rendezvous e controlli; non misura il tempo puro dell'encoder."
  (handler-case
      (progn
        (dotimes (wave 2)
          (setf (aref starts index wave) (get-internal-real-time))
          (let ((sink 0))
            (dotimes (iteration rounds)
              (let ((actual (multiple-value-list
                             (arcdocdb.cbor:scrivi-array-cbor-minimo
                              buffer start end source ss se table count space))))
                (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
                (is (= next (first actual))) (is (equalp expected buffer))
                (is (equalp source source-before)) (is (equalp table table-before))
                (is (= se (arcdocdb.cbor::spazio-cbor-cursor space)))
                (is (= 1 (arcdocdb.cbor::spazio-cbor-nodes space)))
                (is (zerop (arcdocdb.cbor::spazio-cbor-peak-depth space)))
                (incf sink (caw-token buffer (first actual))))
              ;; Rendezvous dopo il primo item e i suoi controlli, senza chiamate prodotto aggiuntive.
              (when (zerop iteration)
                (setf (aref firsts index wave) (get-internal-real-time))
                (sb-thread:signal-semaphore (svref ready wave))
                (cs-wait (svref go wave))))
            (is (= sink (* rounds token))) (setf (aref sinks index wave) sink))
          (setf (aref finishes index wave) (get-internal-real-time))
          (sb-thread:signal-semaphore (svref done wave)))
        :ok)
    (error (condition) condition)))
