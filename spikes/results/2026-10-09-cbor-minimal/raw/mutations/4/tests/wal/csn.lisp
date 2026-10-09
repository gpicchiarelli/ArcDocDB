;;;; OWNER: harness sequenziale; backend e pubblicazione sono fixture deterministiche.
;;;; SHARED: nessun worker; contesa forzata sul mutex dello stesso thread, senza retry.
;;;; L'indice e il controller di Serie sono precondizioni esterne modellate qui.
;;;; Le immagini private servono solo a provare rifiuti prima della mutazione.
(in-package #:arcdocdb.wal.tests)
(declaim (optimize (safety 3) (debug 3)))

(defun wal-csn-open (&key (version 2) (kind :segment) (file-id 31) (capacity 512))
  (let ((lotto (crea-lotto kind file-id :version version :capacity capacity :max-records 8)))
    (case kind
      (:segment (aggiungi-record lotto 1 (bytes 17) (bytes 21) :txid 7))
      (:control (aggiungi-record lotto 5 (bytes) (buffer 24) :txid 7))
      (:multiserie (aggiungi-record lotto 6 (bytes) (buffer 26) :txid 7))
      (otherwise (error "Tipo inatteso nella fixture WAL/CSN.")))
    lotto))

(defun call-with-wal-csn-fixture (thunk &key (base 0) (capacity 3) (version 2))
  (let ((file (fixture-file)))
    (unwind-protect
         (multiple-value-bind (registry model)
             (arcdocdb.csn.tests::csn-fixture :base base :capacity capacity)
           (declare (ignore model))
           (funcall thunk registry (crea-log-io file :segment 31 :version version) file))
      (arcdocdb.io:chiudi file))))

(defun wal-csn-lot-image (lotto)
  (list (copy-seq (arcdocdb.wal::lotto-buffer lotto))
        (copy-seq (arcdocdb.wal::lotto-offsets lotto))
        (copy-seq (arcdocdb.wal::lotto-seal-value lotto))
        (arcdocdb.wal::lotto-used lotto) (arcdocdb.wal::lotto-count lotto)
        (arcdocdb.wal::lotto-start lotto) (arcdocdb.wal::lotto-state lotto)
        (arcdocdb.wal::lotto-owner lotto) (arcdocdb.wal::lotto-csn-registry lotto)
        (arcdocdb.wal::lotto-csn-log lotto) (arcdocdb.wal::lotto-csn-slot lotto)
        (arcdocdb.wal::lotto-csn-high lotto) (arcdocdb.wal::lotto-csn-low lotto)
        (arcdocdb.wal::lotto-csn-pending lotto)))

(defun wal-csn-image (lotto registry log)
  (let ((file (arcdocdb.wal::log-io-file log)))
    (list (wal-csn-lot-image lotto) (arcdocdb.csn.tests::csn-private-image registry)
          (stato-log log) (arcdocdb.wal::log-io-active log)
          (arcdocdb.io:stato-file file) (arcdocdb.io:posizione-scritta file)
          (arcdocdb.io:posizione-durevole file))))

(defun wal-csn-refusal (lotto registry log thunk type reason)
  "Un rifiuto previsto conserva tutti i byte, associazioni, crediti e frontiere."
  (let ((before (wal-csn-image lotto registry log)))
    (is (handler-case (progn (funcall thunk) nil)
          (arcdocdb.conditions:arcdocdb-error (condition)
            (is (typep condition type))
            (is (eq reason (arcdocdb.conditions:error-reason condition)))
            t)))
    (is (equalp before (wal-csn-image lotto registry log))))
  t)

(defun wal-csn-frontiers (registry last horizon)
  "Oracolo matematico del solo harness, indipendente dalle parole del prodotto."
  (multiple-value-bind (last-high last-low) (arcdocdb.csn.tests::csn-words last)
    (multiple-value-bind (h-high h-low) (arcdocdb.csn.tests::csn-words horizon)
      (is (equal (list last-high last-low h-high h-low)
                 (arcdocdb.csn.tests::csn-frontiers registry)))))
  t)

(defun wal-csn-event (lotto registry)
  "Evento catturato alla chiusura, mai ricostruito dal lotto a un callback tardivo."
  (cons registry (multiple-value-list (arcdocdb.wal:leggi-csn-lotto lotto))))

(defun wal-csn-publish (index lotto)
  "Precondizione esterna: pubblicazione atomica del descrittore nella fixture."
  (is (null (sb-ext:compare-and-swap (svref index 0) nil lotto)))
  t)

(defun wal-csn-retire (index lotto)
  (is (eq lotto (sb-ext:compare-and-swap (svref index 0) lotto nil)))
  t)

(defun wal-csn-resolve (lotto event level)
  (apply #'arcdocdb.wal:risolvi-lotto-pubblicato lotto (append event (list level))))

(defun wal-csn-annul (lotto event controller)
  "Il controller dichiara Serie FAULTED e consumer/I/O conclusi prima del ponte."
  (is (eq :faulted (svref controller 0)))
  (is (eq :completed (svref controller 1)))
  (apply #'arcdocdb.wal:annulla-csn-lotto lotto event))

(defun wal-csn-controller-completed ()
  ;; Chiamato solo dopo il ritorno sincrono del worker I/O che ha segnalato il fault.
  (make-array 2 :initial-contents '(:faulted :completed)))

(defun wal-csn-check-h (values expected)
  (is (= 2 (length values)))
  (is (every (lambda (word) (typep word '(unsigned-byte 32))) values))
  (is (= expected (apply #'arcdocdb.csn.tests::csn-number values)))
  t)

(defun wal-csn-check-stamp (data pos stamp)
  "Byte little-endian e CRC header controllati con oracoli indipendenti."
  (dotimes (byte 8)
    (is (= (ldb (byte 8 (* byte 8)) stamp) (aref data (+ pos 16 byte)))))
  (is (= (arcdocdb.binary:leggi-u32 data pos)
         (arcdocdb.foundation.tests::reference-crc data (+ pos 4) (+ pos 24))))
  t)

(defun wal-csn-group-image (group)
  (list (stato-gruppo group) (arcdocdb.wal::gruppo-count group)
        (arcdocdb.wal::gruppo-bytes group) (arcdocdb.wal::gruppo-start group)
        (copy-seq (arcdocdb.wal::gruppo-slots group))))

(deftest test-REQ-MVC-008-wal-csn-free-association-rejections
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (let ((lotto (wal-csn-open)) (event (list registry 0 0 1)))
       (is (eq :libero (arcdocdb.wal:stato-csn-lotto lotto)))
       (wal-csn-refusal lotto registry log (lambda () (arcdocdb.wal:leggi-csn-lotto lotto))
                        'invalid-argument :lotto-csn-free)
       (wal-csn-refusal lotto registry log (lambda () (wal-csn-resolve lotto event :async))
                        'invalid-argument :lotto-csn-not-pending)
       (wal-csn-refusal lotto registry log
                        (lambda () (apply #'arcdocdb.wal:annulla-csn-lotto lotto event))
                        'invalid-argument :lotto-csn-not-pending)
       (wal-csn-frontiers registry 0 0)))))

(deftest test-REQ-MVC-008-wal-csn-limb-boundaries-v1-v2
  (dolist (version '(1 2))
    (dolist (stamp '(1 #xffffffff #x100000000 #x4000000000000000
                    #xfffffffffffffffe #xffffffffffffffff))
      (call-with-wal-csn-fixture
       (lambda (registry log file)
         (declare (ignore file))
         (let* ((lotto (wal-csn-open :version version)) (manual (wal-csn-open :version version))
                (index (make-array 1 :initial-element nil)))
           (multiple-value-bind (used high low)
               (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
             (is (= 82 used (lunghezza-lotto lotto)))
             (is (every (lambda (word) (typep word '(unsigned-byte 32))) (list high low)))
             (is (= stamp (arcdocdb.csn.tests::csn-number high low))))
           (let* ((event (wal-csn-event lotto registry)) (token (rest event))
                  (group (fixture-group log lotto)) (data (arcdocdb.wal::lotto-buffer lotto)))
             (is (= 3 (length token))) (is (typep (first token) 'fixnum))
             (is (eq registry (arcdocdb.wal::lotto-csn-registry lotto)))
             (is (eq log (arcdocdb.wal::lotto-csn-log lotto)))
             (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lotto)))
             (wal-csn-check-stamp data 0 stamp) (wal-csn-check-stamp data 26 stamp)
             (sigilla-lotto manual stamp 0 0)
             (is (equalp data (arcdocdb.wal::lotto-buffer manual)))
             (multiple-value-bind (end actual durable count)
                 (arcdocdb.record:verifica-lotto data 0 82 31 :version version)
               (is (= 82 end)) (is (= stamp actual)) (is (zerop durable)) (is (= 1 count)))
             (wal-csn-frontiers registry stamp (1- stamp))
             (esegui-gruppo group) (wal-csn-publish index lotto)
             (wal-csn-check-h (multiple-value-list (wal-csn-resolve lotto event :group)) stamp)
             (is (equal token (multiple-value-list (arcdocdb.wal:leggi-csn-lotto lotto))))
             (wal-csn-frontiers registry stamp stamp))))
       :base (1- stamp) :version version))))

(deftest test-REQ-WAL-005-wal-csn-prepared-and-ordinary-stamps
  (dolist (version '(1 2))
    (call-with-wal-csn-fixture
     (lambda (registry log file)
       (declare (ignore file))
       (let ((lots (loop repeat 2 collect (crea-lotto :segment 31 :version version :capacity 512)))
             (outcome (buffer 8)) (stamp #x8000000100000000) (txid #xffffffffffffffff))
         (arcdocdb.binary:scrivi-u64 outcome 0 stamp)
         (dolist (lotto lots)
           (aggiungi-record lotto 1 (bytes 17) (bytes 21) :flags 1 :txid txid)
           (aggiungi-record lotto 2 (bytes 18) (bytes) :flags 1 :txid txid)
           (aggiungi-record lotto 4 (bytes) outcome :txid txid)
           (aggiungi-record lotto 1 (bytes 19) (bytes 22) :txid 7))
         (arcdocdb.wal:sigilla-lotto-con-csn (first lots) registry log 64 0)
         (sigilla-lotto (second lots) stamp 64 0)
         (let ((data (arcdocdb.wal::lotto-buffer (first lots))))
           (is (equalp data (arcdocdb.wal::lotto-buffer (second lots))))
           (dolist (pos '(0 26 51)) (wal-csn-check-stamp data pos txid))
           (dolist (pos '(83 109)) (wal-csn-check-stamp data pos stamp))
           (is (= stamp (arcdocdb.binary:leggi-u64 data 75)))
           (multiple-value-bind (end actual durable count)
               (arcdocdb.record:verifica-lotto data 0 165 31 :version version :file-offset 64)
             (is (= 165 end)) (is (= stamp actual)) (is (zerop durable)) (is (= 4 count))))))
     :base #x80000000ffffffff :version version)))

(deftest test-REQ-WAL-005-wal-csn-manual-api-remains-unbound
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (let ((lotto (wal-csn-open)))
       (sigilla-lotto lotto #xffffffffffffffff 0 0)
       (is (eq :libero (arcdocdb.wal:stato-csn-lotto lotto)))
       (let ((group (fixture-group log lotto)))
         (esegui-gruppo group) (riusa-gruppo group) (riusa-lotto lotto))
       (is (eq :libero (arcdocdb.wal:stato-csn-lotto lotto)))
       (is (eq :open (stato-lotto lotto))) (is (zerop (lunghezza-lotto lotto)))
       (wal-csn-frontiers registry 0 0)))))

(deftest test-REQ-MVC-008-wal-csn-empty-and-control-content-before-assignment
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (dolist (lotto (list (crea-lotto :segment 31 :capacity 512)
                         (wal-csn-open :kind :control :file-id 0)
                         (wal-csn-open :kind :multiserie :file-id 0)))
       (wal-csn-refusal lotto registry log
                        (lambda () (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0))
                        'invalid-argument :lotto-csn-content)
       (is (eq :libero (arcdocdb.wal:stato-csn-lotto lotto))))
     (wal-csn-frontiers registry 0 0))))

(deftest test-REQ-MVC-008-wal-csn-log-layout-before-assignment
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore log))
     (dolist (entry '((:segment 32 2) (:segment 31 1) (:control 0 2) (:multiserie 0 2)))
       (destructuring-bind (kind file-id version) entry
         (let ((wrong (crea-log-io file kind file-id :version version)) (lotto (wal-csn-open)))
           (wal-csn-refusal lotto registry wrong
                            (lambda () (arcdocdb.wal:sigilla-lotto-con-csn lotto registry wrong 0 0))
                            'invalid-argument :lotto-csn-log))))
     (wal-csn-frontiers registry 0 0))))

(deftest test-REQ-AFF-008-wal-csn-offsets-before-assignment
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (dolist (entry (list (list 0 1 :lotto-offset)
                         (list most-positive-fixnum 0 :lotto-offset)
                         (list 1 1 :lotto-future-durable)))
       (destructuring-bind (start durable reason) entry
         (let ((lotto (wal-csn-open)))
           (wal-csn-refusal lotto registry log
                            (lambda () (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log start durable))
                            'invalid-argument reason))))
     (wal-csn-frontiers registry 0 0))))

(deftest test-REQ-AFF-004-wal-csn-private-shape-and-seal-budget-before-assignment
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (dolist (mode '(:used :count :space))
       (let ((lotto (wal-csn-open)))
         (ecase mode
           (:used (setf (arcdocdb.wal::lotto-used lotto) 513))
           (:count (setf (arcdocdb.wal::lotto-count lotto) 9))
           (:space (setf (arcdocdb.wal::lotto-used lotto) 457)))
         (wal-csn-refusal lotto registry log
                          (lambda () (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0))
                          'invariant-violation (if (eq mode :used) :lotto-length :lotto-seal-space))))
     (wal-csn-frontiers registry 0 0)
     (let ((lotto (wal-csn-open :capacity 82)))
       (wal-csn-refusal lotto registry log
                        (lambda () (aggiungi-record lotto 1 (bytes 18) (bytes 22)))
                        'resource-exhausted :lotto-capacity)
       (is (= 82 (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)))
       (wal-csn-frontiers registry 1 0)))))

(deftest test-REQ-AFF-001-wal-csn-faulted-log-before-assignment
  (let ((file (fixture-file :writer (lambda (fd data start count)
                                    (declare (ignore fd data start count))
                                    (error 'sb-posix:syscall-error :errno sb-posix:eio :name 'write)))))
    (unwind-protect
         (let* ((registry (arcdocdb.csn:crea-registro-csn)) (log (crea-log-io file :segment 31))
                (lotto (wal-csn-open)) (group (fixture-group log (fixture-lotto))))
           (signals io-fault (scrivi-gruppo group) :io-syscall)
           (wal-csn-refusal lotto registry log
                            (lambda () (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0))
                            'io-fault :log-faulted)
           (wal-csn-frontiers registry 0 0))
      (arcdocdb.io:chiudi file))))

(deftest test-REQ-AFF-008-wal-csn-full-busy-and-exhausted-before-assignment
  (dolist (reason '(:csn-full :csn-busy :csn-exhausted))
    (call-with-wal-csn-fixture
     (lambda (registry log file)
       (declare (ignore file))
       (let ((lotto (wal-csn-open)))
         (when (eq reason :csn-full) (arcdocdb.csn:prendi-csn registry))
         (flet ((probe ()
                  (wal-csn-refusal lotto registry log
                                   (lambda () (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0))
                                   'resource-exhausted reason)))
           (if (eq reason :csn-busy)
               (sb-thread:with-mutex ((arcdocdb.csn::registro-csn-mutex registry)) (probe))
               (probe)))
         (is (eq :open (stato-lotto lotto)))
         (is (eq :libero (arcdocdb.wal:stato-csn-lotto lotto)))))
     :capacity 1 :base (if (eq reason :csn-exhausted) #xffffffffffffffff 0))))

(deftest test-REQ-MVC-008-wal-csn-repeat-seal-before-assignment
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (let ((lotto (wal-csn-open)))
       (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
       (wal-csn-refusal lotto registry log
                        (lambda () (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0))
                        'invalid-argument :lotto-state)
       (wal-csn-refusal lotto registry log (lambda () (sigilla-lotto lotto 2 0 0))
                        'invalid-argument :lotto-state)
       (wal-csn-frontiers registry 1 0)))))

(deftest test-REQ-WAL-006-wal-csn-full-write-and-publication-levels
  (let ((output (buffer 82)) (position 0) (calls 0) (flushes 0))
    (let ((file (fixture-file :writer (lambda (fd data start count)
                                      (declare (ignore fd))
                                      (let ((n (min 7 count)))
                                        (replace output data :start1 position :start2 start :end2 (+ start n))
                                        (incf position n) (incf calls) n))
                              :flush (lambda (fd) (declare (ignore fd)) (incf flushes) 0))))
      (unwind-protect
           (let* ((registry (arcdocdb.csn:crea-registro-csn)) (log (crea-log-io file :segment 31))
                  (lotto (wal-csn-open)) (index (make-array 1 :initial-element nil)))
             (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
             (let ((event (wal-csn-event lotto registry)) (group (fixture-group log lotto)))
               (wal-csn-publish index lotto)
               (wal-csn-refusal lotto registry log (lambda () (wal-csn-resolve lotto event :async))
                                'invalid-argument :lotto-not-covered)
               (is (= 82 (scrivi-gruppo group) position)) (is (= 12 calls)) (is (zerop flushes))
               (wal-csn-frontiers registry 1 0)
               (is (equalp output (subseq (arcdocdb.wal::lotto-buffer lotto) 0 82)))
               (dolist (level '(:group :strong))
                 (wal-csn-refusal lotto registry log (lambda () (wal-csn-resolve lotto event level))
                                  'invalid-argument :lotto-not-covered))
               (is (= 82 (sincronizza-gruppo group))) (is (= 1 flushes))
               (wal-csn-frontiers registry 1 0)
               (wal-csn-check-h (multiple-value-list (wal-csn-resolve lotto event :strong)) 1)
               (is (eq lotto (svref index 0))) (is (= 12 calls)) (is (= 1 flushes))))
        (arcdocdb.io:chiudi file)))))

(deftest test-REQ-WAL-006-wal-csn-async-before-flush-cannot-reuse
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (let ((lotto (wal-csn-open)) (index (make-array 1 :initial-element nil)))
       (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
       (let ((event (wal-csn-event lotto registry)) (group (fixture-group log lotto)))
         (scrivi-gruppo group) (wal-csn-publish index lotto)
         (wal-csn-check-h (multiple-value-list (wal-csn-resolve lotto event :async)) 1)
         (is (eq :risolto (arcdocdb.wal:stato-csn-lotto lotto)))
         (is (zerop (arcdocdb.io:posizione-durevole file)))
         (wal-csn-refusal lotto registry log (lambda () (riusa-lotto lotto))
                          'invalid-argument :lotto-state)
         (signals invalid-argument (riusa-gruppo group) :group-state)
         (sincronizza-gruppo group) (wal-csn-frontiers registry 1 1)
         (wal-csn-retire index lotto) (riusa-gruppo group) (riusa-lotto lotto)
         (is (eq :libero (arcdocdb.wal:stato-csn-lotto lotto))))))))

(deftest test-REQ-MVC-008-wal-csn-durable-before-publication-and-reuse
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (let* ((lotto (wal-csn-open)) (data (arcdocdb.wal::lotto-buffer lotto))
            (index (make-array 1 :initial-element nil)))
       (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
       (let ((event (wal-csn-event lotto registry)) (group (fixture-group log lotto)))
         (esegui-gruppo group) (wal-csn-frontiers registry 1 0)
         (is (null (svref index 0))) (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lotto)))
         (riusa-gruppo group)
         (is (null (arcdocdb.wal::lotto-owner lotto)))
         (wal-csn-refusal lotto registry log (lambda () (riusa-lotto lotto))
                          'invalid-argument :lotto-csn-pending)
         (wal-csn-publish index lotto)
         (wal-csn-check-h (multiple-value-list (wal-csn-resolve lotto event :group)) 1)
         (wal-csn-retire index lotto) (riusa-lotto lotto)
         (is (eq data (arcdocdb.wal::lotto-buffer lotto)))
         (is (eq :libero (arcdocdb.wal:stato-csn-lotto lotto)))
         (is (null (arcdocdb.wal::lotto-csn-registry lotto)))
         (is (null (arcdocdb.wal::lotto-csn-log lotto)))
         (is (zerop (arcdocdb.wal::lotto-csn-slot lotto)))
         (is (zerop (arcdocdb.wal::lotto-csn-high lotto)))
         (is (zerop (arcdocdb.wal::lotto-csn-low lotto)))
         (aggiungi-record lotto 1 (bytes 18) (bytes 22))
         (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 82 (arcdocdb.io:posizione-durevole file))
         (wal-csn-frontiers registry 2 1))))))

(deftest test-REQ-MVC-008-wal-csn-horizon-gap-across-independent-logs
  (call-with-wal-csn-fixture
   (lambda (registry first-log first-file)
     (declare (ignore first-file))
     (let ((file (fixture-file)))
       (unwind-protect
            (let* ((second-log (crea-log-io file :segment 32)) (a (wal-csn-open))
                   (b (wal-csn-open :file-id 32)) (ia (make-array 1 :initial-element nil))
                   (ib (make-array 1 :initial-element nil)))
              (arcdocdb.wal:sigilla-lotto-con-csn a registry first-log 0 0)
              (arcdocdb.wal:sigilla-lotto-con-csn b registry second-log 0 0)
              (let ((ea (wal-csn-event a registry)) (eb (wal-csn-event b registry)))
                (esegui-gruppo (fixture-group first-log a)) (esegui-gruppo (fixture-group second-log b))
                (wal-csn-publish ia a) (wal-csn-publish ib b)
                (wal-csn-check-h (multiple-value-list (wal-csn-resolve b eb :strong)) #xfffffffe)
                (wal-csn-frontiers registry #x100000000 #xfffffffe)
                (wal-csn-check-h (multiple-value-list (wal-csn-resolve a ea :group)) #x100000000)
                (wal-csn-frontiers registry #x100000000 #x100000000)))
         (arcdocdb.io:chiudi file))))
   :base #xfffffffe :capacity 2))

(deftest test-REQ-MVC-008-wal-csn-busy-publication-keeps-token
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (let ((lotto (wal-csn-open)) (index (make-array 1 :initial-element nil)))
       (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
       (let ((event (wal-csn-event lotto registry)))
         (esegui-gruppo (fixture-group log lotto)) (wal-csn-publish index lotto)
         (sb-thread:with-mutex ((arcdocdb.csn::registro-csn-mutex registry))
           (wal-csn-refusal lotto registry log (lambda () (wal-csn-resolve lotto event :group))
                            'resource-exhausted :csn-busy))
         (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lotto)))
         (is (eq lotto (svref index 0))) (wal-csn-frontiers registry 1 0)
         (wal-csn-check-h (multiple-value-list (wal-csn-resolve lotto event :group)) 1))))))

(deftest test-REQ-MVC-008-wal-csn-double-resolver-and-owned-reuse
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (let ((lotto (wal-csn-open)) (index (make-array 1 :initial-element nil)))
       (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
       (let ((event (wal-csn-event lotto registry)) (group (fixture-group log lotto)))
         (esegui-gruppo group) (wal-csn-publish index lotto)
         (wal-csn-check-h (multiple-value-list (wal-csn-resolve lotto event :group)) 1)
         (wal-csn-refusal lotto registry log (lambda () (wal-csn-resolve lotto event :group))
                          'invalid-argument :lotto-csn-not-pending)
         (wal-csn-refusal lotto registry log
                          (lambda () (apply #'arcdocdb.wal:annulla-csn-lotto lotto event))
                          'invalid-argument :lotto-csn-not-pending)
         (wal-csn-refusal lotto registry log (lambda () (riusa-lotto lotto))
                          'invalid-argument :lotto-owned)
         (wal-csn-retire index lotto) (riusa-gruppo group) (riusa-lotto lotto))))))

(deftest test-REQ-MVC-008-wal-csn-stale-event-after-reuse
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (let ((lotto (wal-csn-open)) (index (make-array 1 :initial-element nil)))
       (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
       (let ((old (wal-csn-event lotto registry)) (group (fixture-group log lotto)))
         (esegui-gruppo group) (wal-csn-publish index lotto)
         (wal-csn-check-h (multiple-value-list (wal-csn-resolve lotto old :group)) 1)
         (wal-csn-retire index lotto) (riusa-gruppo group) (riusa-lotto lotto)
         (aggiungi-record lotto 1 (bytes 18) (bytes 22))
         (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 82 82)
         (let ((current (wal-csn-event lotto registry)))
           (is (= (second old) (second current)))
           (aggiungi-lotto group lotto) (chiudi-gruppo group) (esegui-gruppo group)
           (wal-csn-publish index lotto)
           (wal-csn-refusal lotto registry log (lambda () (wal-csn-resolve lotto old :group))
                            'invalid-argument :lotto-csn-stale)
           (wal-csn-refusal lotto registry log
                            (lambda () (apply #'arcdocdb.wal:annulla-csn-lotto lotto old))
                            'invalid-argument :lotto-csn-stale)
           (wal-csn-frontiers registry 2 1)
           (wal-csn-check-h (multiple-value-list (wal-csn-resolve lotto current :group)) 2)))))
   :capacity 1))

(deftest test-REQ-MVC-008-wal-csn-wrong-registry-and-token-identity
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (let ((other (arcdocdb.csn:crea-registro-csn :capacity 1)) (lotto (wal-csn-open))
           (index (make-array 1 :initial-element nil)))
       (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
       (let* ((event (wal-csn-event lotto registry)) (other-token (multiple-value-list (arcdocdb.csn:prendi-csn other)))
              (other-before (arcdocdb.csn.tests::csn-private-image other)))
         (is (equal (rest event) other-token))
         (esegui-gruppo (fixture-group log lotto)) (wal-csn-publish index lotto)
         (dolist (wrong (list (cons other other-token)
                              (list registry 1 0 1) (list registry 0 1 1) (list registry 0 0 2)))
           (wal-csn-refusal lotto registry log (lambda () (wal-csn-resolve lotto wrong :group))
                            'invalid-argument :lotto-csn-stale)
           (wal-csn-refusal lotto registry log
                            (lambda () (apply #'arcdocdb.wal:annulla-csn-lotto lotto wrong))
                            'invalid-argument :lotto-csn-stale)
           (is (equalp other-before (arcdocdb.csn.tests::csn-private-image other))))
         (wal-csn-check-h (multiple-value-list (wal-csn-resolve lotto event :group)) 1))))
   :capacity 1))

(deftest test-REQ-MVC-008-wal-csn-nonlive-registry-token
  ;; FI di protocollo: un risolutore esterno ha consumato il credito senza aggiornare il lotto.
  ;; Il ponte deve rifiutare, conservando il token per il fail-stop del proprietario.
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (let ((lotto (wal-csn-open)) (index (make-array 1 :initial-element nil)))
       (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
       (let ((event (wal-csn-event lotto registry)))
         (esegui-gruppo (fixture-group log lotto)) (wal-csn-publish index lotto)
         (wal-csn-check-h (multiple-value-list (apply #'arcdocdb.csn:risolvi-csn event)) 1)
         (wal-csn-refusal lotto registry log (lambda () (wal-csn-resolve lotto event :group))
                          'invalid-argument :csn-token)
         (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lotto)))
         (wal-csn-frontiers registry 1 1))))))

(deftest test-REQ-WAL-006-wal-csn-healthy-annulment-always-refused
  (dolist (stage '(:sealed :written :durable))
    (call-with-wal-csn-fixture
     (lambda (registry log file)
       (declare (ignore file))
       (let ((lotto (wal-csn-open)))
         (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
         (let ((event (wal-csn-event lotto registry)) (group (fixture-group log lotto)))
           (unless (eq stage :sealed) (scrivi-gruppo group))
           (when (eq stage :durable) (sincronizza-gruppo group))
           (wal-csn-refusal lotto registry log
                            (lambda () (apply #'arcdocdb.wal:annulla-csn-lotto lotto event))
                            'invalid-argument :lotto-log-not-faulted)
           (wal-csn-frontiers registry 1 0)))))))

(deftest test-REQ-AFF-001-wal-csn-partial-write-fault-annulment
  (let ((calls 0) (flushes 0))
    (let ((file (fixture-file :writer (lambda (fd data start count)
                                      (declare (ignore fd data start count))
                                      (incf calls)
                                      (if (= calls 1) 7
                                          (error 'sb-posix:syscall-error :errno sb-posix:eio :name 'write)))
                              :flush (lambda (fd) (declare (ignore fd)) (incf flushes) 0))))
      (unwind-protect
           (let* ((registry (arcdocdb.csn:crea-registro-csn)) (log (crea-log-io file :segment 31))
                  (lotto (wal-csn-open)))
             (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
             (let ((event (wal-csn-event lotto registry)) (group (fixture-group log lotto)))
               (signals io-fault (scrivi-gruppo group) :io-syscall)
               (is (= 2 calls)) (is (zerop flushes)) (is (= 7 (arcdocdb.io:posizione-scritta file)))
               (is (zerop (arcdocdb.io:posizione-durevole file)))
               (wal-csn-frontiers registry 1 0)
               (is (eq :pendente (arcdocdb.wal:stato-csn-lotto lotto)))
               (wal-csn-check-h (multiple-value-list
                                 (wal-csn-annul lotto event (wal-csn-controller-completed))) 1)
               (is (eq :faulted (stato-lotto lotto))) (is (eq :faulted (stato-log log)))
               (wal-csn-refusal lotto registry log (lambda () (riusa-lotto lotto))
                                'invalid-argument :lotto-state)
               (wal-csn-frontiers registry 1 1)))
        (arcdocdb.io:chiudi file)))))

(deftest test-REQ-AFF-001-wal-csn-flush-fault-busy-annulment
  (let ((flushes 0))
    (let ((file (fixture-file :flush (lambda (fd) (declare (ignore fd)) (incf flushes)
                                     (error 'sb-posix:syscall-error :errno sb-posix:eio :name 'flush)))))
      (unwind-protect
           (let* ((registry (arcdocdb.csn:crea-registro-csn)) (log (crea-log-io file :segment 31))
                  (lotto (wal-csn-open)))
             (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
             (let ((event (wal-csn-event lotto registry)) (group (fixture-group log lotto)))
               (scrivi-gruppo group) (signals io-fault (sincronizza-gruppo group) :io-syscall)
               (let ((controller (wal-csn-controller-completed)))
                 (sb-thread:with-mutex ((arcdocdb.csn::registro-csn-mutex registry))
                   (wal-csn-refusal lotto registry log (lambda () (wal-csn-annul lotto event controller))
                                    'resource-exhausted :csn-busy))
                 (wal-csn-frontiers registry 1 0)
                 (wal-csn-check-h (multiple-value-list (wal-csn-annul lotto event controller)) 1))
               (is (= 1 flushes)) (is (zerop (arcdocdb.io:posizione-durevole file)))
               (wal-csn-refusal lotto registry log
                                (lambda () (apply #'arcdocdb.wal:annulla-csn-lotto lotto event))
                                'invalid-argument :lotto-csn-not-pending)))
        (arcdocdb.io:chiudi file)))))

(deftest test-REQ-AFF-001-wal-csn-later-log-fault-rejects-old-publication
  (let ((flushes 0))
    (let ((file (fixture-file :flush (lambda (fd) (declare (ignore fd))
                                     (incf flushes)
                                     (if (= flushes 1) 0
                                         (error 'sb-posix:syscall-error :errno sb-posix:eio :name 'flush))))))
      (unwind-protect
           (let* ((registry (arcdocdb.csn:crea-registro-csn)) (log (crea-log-io file :segment 31))
                  (a (wal-csn-open)) (b (wal-csn-open)) (index (make-array 1 :initial-element nil)))
             (arcdocdb.wal:sigilla-lotto-con-csn a registry log 0 0)
             (let ((ea (wal-csn-event a registry)) (first (fixture-group log a)))
               (esegui-gruppo first) (riusa-gruppo first)
               (wal-csn-publish index a)
               (arcdocdb.wal:sigilla-lotto-con-csn b registry log 82 82)
               (let ((eb (wal-csn-event b registry)) (second (fixture-group log b)))
                 (scrivi-gruppo second) (signals io-fault (sincronizza-gruppo second) :io-syscall)
                 (is (coperto-p a :strong)) (is (eq :durable (stato-lotto a)))
                 (is (= 82 (arcdocdb.io:posizione-durevole file)))
                 (wal-csn-refusal a registry log (lambda () (wal-csn-resolve a ea :strong))
                                  'io-fault :log-faulted)
                 (wal-csn-frontiers registry 2 0)
                 (let ((controller (wal-csn-controller-completed)))
                   (wal-csn-retire index a)
                   (wal-csn-check-h (multiple-value-list (wal-csn-annul b eb controller)) 0)
                   (wal-csn-check-h (multiple-value-list (wal-csn-annul a ea controller)) 2))
                 (is (= 2 flushes)) (wal-csn-frontiers registry 2 2))))
        (arcdocdb.io:chiudi file)))))

(deftest test-REQ-MVC-008-wal-csn-bound-log-identity-before-ownership
  (call-with-wal-csn-fixture
   (lambda (registry log file)
     (declare (ignore file))
     (let ((other-file (fixture-file)))
       (unwind-protect
            (let* ((other-log (crea-log-io other-file :segment 31)) (lotto (wal-csn-open))
                   (wrong-group (crea-gruppo other-log)) (right-group (crea-gruppo log)))
              (arcdocdb.wal:sigilla-lotto-con-csn lotto registry log 0 0)
              (let ((before (wal-csn-group-image wrong-group)))
                (wal-csn-refusal lotto registry log (lambda () (aggiungi-lotto wrong-group lotto))
                                 'invalid-argument :lotto-csn-log)
                (is (equalp before (wal-csn-group-image wrong-group)))
                (is (null (arcdocdb.wal::lotto-owner lotto)))
                (is (null (arcdocdb.wal::log-io-active other-log)))
                (is (zerop (arcdocdb.io:posizione-scritta other-file)))
                (is (zerop (arcdocdb.io:posizione-durevole other-file)))
                (is (= 1 (aggiungi-lotto right-group lotto)))
                (is (eq right-group (arcdocdb.wal::lotto-owner lotto)))))
         (arcdocdb.io:chiudi other-file))))))
