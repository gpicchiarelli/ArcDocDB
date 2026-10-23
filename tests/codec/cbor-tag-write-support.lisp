;;;; Corpus da REQ-CBR-007, congelato prima dei nuovi sorgenti di prodotto.
(defpackage #:arcdocdb.cbor.tag.write.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:corruption-detected #:error-reason #:error-offset)
  (:import-from #:arcdocdb.cbor.structure.tests #:cs-snapshot #:cs-unchanged-p
                #:cs-wait #:cs-join #:cs-stop-workers)
  (:export #:run))
(in-package #:arcdocdb.cbor.tag.write.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test della composizione dei tag CBOR superati.~%" (length *tests*))
  t)

(defun ctw-header (high low)
  "Oracolo aritmetico freddo su parole u32, senza encoder ne ricostruzione u64."
  (let* ((width (cond ((plusp high) 8) ((< low 24) 0) ((< low 256) 1)
                      ((< low 65536) 2) (t 4)))
         (ai (if (zerop width) low (case width (1 24) (2 25) (4 26) (8 27)))))
    (cons (+ #xc0 ai)
          (append (when (= width 8)
                    (loop for power from 3 downto 0
                          collect (mod (floor high (expt 256 power)) 256)))
                  (loop for power from (1- (min width 4)) downto 0
                        collect (mod (floor low (expt 256 power)) 256))))))

(defun ctw-destination (capacity &key (prefix 3) (suffix 7))
  (let* ((end (+ prefix capacity))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8))))
    (dotimes (i (length buffer)) (setf (aref buffer i) (mod (+ #xa7 (* i 37)) 256)))
    (values buffer prefix end)))

(defun ctw-fixture (contents &key (prefix 7))
  (let* ((end (+ prefix (length contents)))
         (source (make-array (+ end 5) :element-type '(unsigned-byte 8) :initial-element #xff)))
    (replace source contents :start1 prefix)
    (values source prefix end)))

(defun ctw-space-snapshot (space)
  (arcdocdb.cbor.minimal.scan.tests::cms-space-snapshot space))
(defun ctw-dirty-space ()
  (arcdocdb.cbor.minimal.scan.tests::cms-dirty-space (arcdocdb.cbor:crea-spazio-cbor)))

(defun ctw-accept (buffer start end source ss se high low space &rest keys)
  "Un solo NEXT; oracolo freddo sull'intera destinazione e source, sentinelle incluse."
  (let* ((before (copy-seq buffer)) (source-before (copy-seq source))
         (header (ctw-header high low)) (next (+ start (length header) (- se ss)))
         (expected (copy-seq before)))
    (replace expected header :start1 start)
    (replace expected source-before :start1 (+ start (length header)) :start2 ss :end2 se)
    (let ((actual (multiple-value-list
                   (apply #'arcdocdb.cbor:scrivi-tag-cbor-minimo
                          buffer start end source ss se high low space keys))))
      (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
      (is (= next (first actual))) (is (<= start next end))
      (is (equalp expected buffer))
      (is (equalp (subseq source-before ss se) (subseq source ss se)))
      (unless (eq source buffer) (is (equalp source-before source)))
      (is (= se (arcdocdb.cbor::spazio-cbor-cursor space)))
      (is (zerop (arcdocdb.cbor::spazio-cbor-top space)))
      (is (zerop (arcdocdb.cbor::spazio-cbor-depth space)))
      (is (not (arcdocdb.cbor::spazio-cbor-pending-tag space)))
      next)))

(defun ctw-reject (buffer start end source ss se high low space type reason offset &rest keys)
  "Rifiuto tipizzato con offset assoluto; interi array fisici intatti su ogni errore."
  (let ((before (cs-snapshot buffer)) (source-before (cs-snapshot source))
        (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (apply #'arcdocdb.cbor:scrivi-tag-cbor-minimo
                             buffer start end source ss se high low space keys)
                      (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed)))
           (is (eql offset (error-offset observed))) t)
      (is (cs-unchanged-p buffer before)) (is (cs-unchanged-p source source-before)))))

(defun ctw-cold-reject (buffer start end source ss se high low space type reason offset &rest keys)
  "Preflight senza reset dello scratch gia sporco."
  (let ((before (ctw-space-snapshot space)))
    (apply #'ctw-reject buffer start end source ss se high low space type reason offset keys)
    (is (equalp before (ctw-space-snapshot space)))))

(defun ctw-probe (contents high low nodes depth &rest keys)
  "Quattro allineamenti; lo scanner e' solo un controllo aggiuntivo su dati freddi."
  (multiple-value-bind (source ss se) (ctw-fixture contents)
    (let ((size (+ (length (ctw-header high low)) (- se ss))))
      (dolist (prefix '(0 1 7 31))
        (multiple-value-bind (buffer start end) (ctw-destination size :prefix prefix)
          (let* ((space (ctw-dirty-space))
                 (next (apply #'ctw-accept buffer start end source ss se high low space keys))
                 (roundtrip (multiple-value-list
                             (arcdocdb.cbor:verifica-struttura-cbor-minima
                              buffer start next (arcdocdb.cbor:crea-spazio-cbor)))))
            (is (= nodes (arcdocdb.cbor::spazio-cbor-nodes space)))
            (is (= depth (arcdocdb.cbor::spazio-cbor-peak-depth space)))
            (is (equal (list (1+ nodes) depth next) roundtrip)))
          (apply #'ctw-cold-reject buffer start (1- end) source ss se high low
                 (ctw-dirty-space) 'resource-exhausted :cbor-tag-capacity nil keys))))))

(defun ctw-token (buffer next)
  (+ next (loop for i below (length buffer) sum (* (1+ i) (aref buffer i)))))

(defun ctw-worker (index buffer start end source ss se high low space expected next token
                   source-before rounds ready go done starts firsts finishes sinks)
  "Due ondate: rendezvous dopo il primo item verificato, SOURCE read-only e scratch privato.
Il WALL della fixture include rendezvous e controlli; non misura il tempo puro dell'encoder."
  (handler-case
      (progn
        (dotimes (wave 2)
          (setf (aref starts index wave) (get-internal-real-time))
          (let ((sink 0))
            (dotimes (iteration rounds)
              (let ((actual (multiple-value-list
                             (arcdocdb.cbor:scrivi-tag-cbor-minimo
                              buffer start end source ss se high low space))))
                (is (= 1 (length actual))) (is (typep (first actual) 'fixnum))
                (is (= next (first actual))) (is (equalp expected buffer))
                (is (equalp source source-before))
                (is (= se (arcdocdb.cbor::spazio-cbor-cursor space)))
                (is (= 6 (arcdocdb.cbor::spazio-cbor-nodes space)))
                (is (= 2 (arcdocdb.cbor::spazio-cbor-peak-depth space)))
                (is (zerop (arcdocdb.cbor::spazio-cbor-top space)))
                (is (zerop (arcdocdb.cbor::spazio-cbor-depth space)))
                (is (not (arcdocdb.cbor::spazio-cbor-pending-tag space)))
                (incf sink (ctw-token buffer (first actual))))
              ;; Nessun worker termina l'onda prima del primo item verificato dell'altro.
              (when (zerop iteration)
                (setf (aref firsts index wave) (get-internal-real-time))
                (sb-thread:signal-semaphore (svref ready wave))
                (cs-wait (svref go wave))))
            (is (= sink (* rounds token))) (setf (aref sinks index wave) sink))
          (setf (aref finishes index wave) (get-internal-real-time))
          (sb-thread:signal-semaphore (svref done wave)))
        :ok)
    (error (condition) condition)))
