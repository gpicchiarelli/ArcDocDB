;;;; Corpus indipendente REQ-CBR-008, prima dei nuovi sorgenti di prodotto.
(defpackage #:arcdocdb.cbor.item.read.tests
  (:use #:cl)
  (:import-from #:arcdocdb.foundation.tests #:is #:bytes)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:corruption-detected #:error-reason #:error-offset)
  (:import-from #:arcdocdb.cbor.structure.tests #:cs-snapshot #:cs-unchanged-p
                #:cs-wait #:cs-join #:cs-stop-workers)
  (:export #:run))
(in-package #:arcdocdb.cbor.item.read.tests)

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test della lettura del primo item CBOR minimo superati.~%" (length *tests*))
  t)

(defun cir-fixture (contents tail &key (prefix 7) (suffix 5))
  "Finestra contents+tail; sentinelle posizionali anche oltre END."
  (let* ((end (+ prefix (length contents) (length tail)))
         (buffer (make-array (+ end suffix) :element-type '(unsigned-byte 8))))
    (dotimes (i (length buffer)) (setf (aref buffer i) (mod (+ #xa7 (* i 37)) 256)))
    (replace buffer contents :start1 prefix)
    (replace buffer tail :start1 (+ prefix (length contents)))
    (values buffer prefix end)))

(defun cir-argument (major argument)
  "Testata fredda aritmetica, mai encoder/lettore del prodotto."
  (let* ((width (cond ((< argument 24) 0) ((< argument 256) 1)
                      ((< argument 65536) 2) ((< argument #x100000000) 4) (t 8)))
         (ai (if (zerop width) argument (case width (1 24) (2 25) (4 26) (8 27)))))
    (cons (+ (* major 32) ai)
          (loop for power from (1- width) downto 0
                collect (mod (floor argument (expt 256 power)) 256)))))

(defun cir-space-snapshot (space)
  (arcdocdb.cbor.minimal.scan.tests::cms-space-snapshot space))
(defun cir-dirty-space ()
  (arcdocdb.cbor.minimal.scan.tests::cms-dirty-space (arcdocdb.cbor:crea-spazio-cbor)))

(defun cir-accept (buffer start end space nodes peak next &rest keys)
  "Tre valori esatti/fixnum, oracolo letterale di frontiera e intero buffer immutato."
  (let ((before (cs-snapshot buffer)))
    (unwind-protect
         (let ((actual (multiple-value-list
                        (apply #'arcdocdb.cbor:leggi-item-cbor-minimo buffer start end space keys))))
           (is (= 3 (length actual))) (is (equal (list nodes peak next) actual))
           (is (every (lambda (value) (and (typep value 'fixnum) (<= 0 value))) actual))
           (is (< start next)) (is (<= next end))
           (is (= next (arcdocdb.cbor::spazio-cbor-cursor space)))
           (is (= nodes (arcdocdb.cbor::spazio-cbor-nodes space)))
           (is (= peak (arcdocdb.cbor::spazio-cbor-peak-depth space)))
           (is (zerop (arcdocdb.cbor::spazio-cbor-top space)))
           (is (zerop (arcdocdb.cbor::spazio-cbor-depth space)))
           (is (not (arcdocdb.cbor::spazio-cbor-pending-tag space))) actual)
      (is (cs-unchanged-p buffer before)))))

(defun cir-reject (buffer start end space type reason offset &rest keys)
  "Errore typed/offset assoluto, nessun ritorno parziale, intero array fisico immutato."
  (let ((before (cs-snapshot buffer)) (returned nil) (observed nil))
    (unwind-protect
         (progn
           (handler-case
               (progn (multiple-value-list
                       (apply #'arcdocdb.cbor:leggi-item-cbor-minimo buffer start end space keys))
                      (setf returned t))
             (arcdocdb-error (condition) (setf observed condition)))
           (is (not returned)) (is (typep observed type))
           (is (eq reason (error-reason observed))) (is (eql offset (error-offset observed))) t)
      (is (cs-unchanged-p buffer before)))))

(defun cir-cold-reject (buffer start end space type reason offset &rest keys)
  "Ogni rifiuto di preflight conserva tutti gli slot e array scratch gia sporchi."
  (let ((before (cir-space-snapshot space)))
    (apply #'cir-reject buffer start end space type reason offset keys)
    (is (equalp before (cir-space-snapshot space)))))

(defun cir-probe (contents nodes peak &rest keys)
  "Due allineamenti e quattro code, compresa vuota; scanner esatto solo secondario."
  (dolist (prefix '(0 7))
    (dolist (tail '(nil (#xff) (#x1c) (#x18 0)))
      (multiple-value-bind (buffer start end) (cir-fixture contents tail :prefix prefix)
        (let ((next (+ start (length contents))))
          (apply #'cir-accept buffer start end (cir-dirty-space) nodes peak next keys)
          (is (equal (list nodes peak next)
                     (multiple-value-list
                      (arcdocdb.cbor:verifica-struttura-cbor-minima
                       buffer start next (arcdocdb.cbor:crea-spazio-cbor)))))
          (when tail
            (arcdocdb.cbor.minimal.scan.tests::cms-reject
             buffer start end (arcdocdb.cbor:crea-spazio-cbor)
             'corruption-detected :cbor-trailing next)))))))

(defun cir-token (buffer nodes peak next)
  (+ (* 17 nodes) (* 31 peak) next
     (loop for i below (length buffer) sum (* (1+ i) (aref buffer i)))))

(defun cir-worker (index buffer start end space expected token before rounds
                   ready go done starts firsts finishes sinks)
  "WALL con rendezvous dopo la prima lettura e controlli; nessun tempo puro del decoder."
  (handler-case
      (progn
        (dotimes (wave 2)
          (setf (aref starts index wave) (get-internal-real-time))
          (let ((sink 0))
            (dotimes (iteration rounds)
              (let ((actual (multiple-value-list
                             (arcdocdb.cbor:leggi-item-cbor-minimo buffer start end space))))
                (is (= 3 (length actual))) (is (equal expected actual))
                (is (every (lambda (value) (typep value 'fixnum)) actual))
                (is (equalp before buffer))
                (is (= (third expected) (arcdocdb.cbor::spazio-cbor-cursor space)))
                (is (= 6 (arcdocdb.cbor::spazio-cbor-nodes space)))
                (is (= 2 (arcdocdb.cbor::spazio-cbor-peak-depth space)))
                (is (zerop (arcdocdb.cbor::spazio-cbor-top space)))
                (is (zerop (arcdocdb.cbor::spazio-cbor-depth space)))
                (is (not (arcdocdb.cbor::spazio-cbor-pending-tag space)))
                (incf sink (apply #'cir-token buffer actual)))
              (when (zerop iteration)
                (setf (aref firsts index wave) (get-internal-real-time))
                (sb-thread:signal-semaphore (svref ready wave)) (cs-wait (svref go wave))))
            (is (= sink (* rounds token))) (setf (aref sinks index wave) sink))
          (setf (aref finishes index wave) (get-internal-real-time))
          (sb-thread:signal-semaphore (svref done wave)))
        :ok)
    (error (condition) condition)))
