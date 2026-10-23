;;;; Fixture autonome del contratto usato dal benchmark GET, senza misure di heap.
;;; OWNER: fixture/controller per file e registri; un contesto e output per worker.
;;; SHARED: indice pubblicato, vista, FD readonly, snapshot e cache della sola fixture.
(defpackage #:arcdocdb.get.performance.tests
  (:use #:cl)
  (:local-nicknames (#:g #:arcdocdb.get) (#:p #:arcdocdb.index.primary)
                    (#:io #:arcdocdb.io) (#:m #:arcdocdb.mvcc)
                    (#:e #:arcdocdb.epochs) (#:c #:arcdocdb.cache))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:corruption-detected
                #:invariant-violation #:snapshot-too-old #:error-reason)
  (:export #:run #:*get-performance-tests*
           #:make-get-performance-fixture #:close-get-performance-fixture
           #:with-get-performance-fixture #:get-performance-fixture
           #:get-performance-fixture-key #:get-performance-fixture-missing-key
           #:get-performance-fixture-value #:get-performance-fixture-view
           #:get-performance-fixture-segment #:get-performance-fixture-valid-bytes
           #:get-performance-fixture-contexts #:get-performance-fixture-outputs
           #:get-performance-fixture-epochs #:get-performance-fixture-snapshot
           #:get-performance-fixture-generation #:get-performance-fixture-cache
           #:get-performance-fixture-version #:get-performance-fixture-csn
           #:performance-read-events #:performance-clear-read-events
           #:performance-checked-get))
(in-package #:arcdocdb.get.performance.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defvar *get-performance-tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *get-performance-tests*)))
(defun run ()
  (dolist (test (reverse *get-performance-tests*))
    (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test del contratto GET per benchmark superati.~%"
          (length *get-performance-tests*))
  t)

(defconstant +performance-max-csn+ #xffffffffffffffff)
(defconstant +performance-segment-id+ 17)
(defconstant +performance-put-offset+ 64)
(defconstant +performance-output-start+ 3)
(defconstant +performance-output-sentinel+ #xcc)

(define-condition performance-fixture-timeout (error)
  ((phase :initarg :phase :reader performance-fixture-timeout-phase))
  (:report (lambda (condition stream)
             (format stream "Budget fixture GET performance esaurito: ~A."
                     (performance-fixture-timeout-phase condition)))))

(defun performance-octets (size &optional (initial 0))
  (make-array size :element-type '(unsigned-byte 8) :initial-element initial))
(defun performance-words (size &optional (initial 0))
  (make-array size :element-type '(unsigned-byte 64) :initial-element initial))
(defun performance-key ()
  ;; Sedici byte, inclusi NUL e ottetti non ASCII; non dipende da un codec testuale.
  (make-array 16 :element-type '(unsigned-byte 8)
              :initial-contents '(0 255 17 34 51 68 85 102 119 136 153 170 187 204 221 238)))
(defun performance-value (size)
  (let ((value (performance-octets size)))
    (dotimes (i size value) (setf (aref value i) (mod (+ 29 (* 73 i)) 256)))))

(defun performance-write-le (bytes start width number)
  "Oracolo di encoding indipendente dalle primitive binarie del prodotto."
  (dotimes (i width) (setf (aref bytes (+ start i)) (ldb (byte 8 (* 8 i)) number)))
  bytes)
(defun performance-reference-crc (bytes start end)
  "CRC32C bit per bit: nessuna tabella o chiamata al CRC del prodotto."
  (let ((crc #xffffffff))
    (loop for i from start below end do
      (setf crc (logxor crc (aref bytes i)))
      (dotimes (bit 8)
        (setf crc (logxor (ash crc -1) (if (oddp crc) #x82f63b78 0)))))
    (logxor crc #xffffffff)))
(defun performance-repair-record-header (image)
  (performance-write-le image 64 4 (performance-reference-crc image 68 88)))
(defun performance-image (version key value csn)
  "Header 64 e PUT 24+K+V nativi v1/v2, più undici byte oltre la frontiera.
I byte attesi e le CRC sono costruiti senza writer/header/CRC del prodotto."
  (let* ((size (+ 24 (length key) (length value)))
         (end (+ 64 size)) (image (performance-octets (+ end 11))))
    (replace image #(65 82 67 68 83 69 71 49)) ; ARCDSEG1
    (performance-write-le image 8 2 version)
    (setf (aref image 10) 1) ; origine writer
    (loop for i below 16 do (setf (aref image (+ 16 i)) (+ 32 i)))
    (performance-write-le image 32 8 +performance-segment-id+)
    (performance-write-le image 40 8 123456)
    (performance-write-le image 56 4 (performance-reference-crc image 0 56))
    (setf (aref image 72) 1 (aref image 73) 0) ; PUT ordinario, LIVE indice != PREPARED
    (performance-write-le image 74 2 (length key))
    (performance-write-le image 76 4 (length value))
    (performance-write-le image 80 8 csn)
    (replace image key :start1 88)
    (replace image value :start1 (+ 88 (length key)))
    (performance-write-le image 68 4 (performance-reference-crc image 88 end))
    (performance-repair-record-header image)
    (fill image #xee :start end)
    image))

(defstruct (performance-observer (:constructor make-performance-observer ()))
  (events nil)
  ;; Una sola lock della fixture per osservazioni; non appartiene al percorso misurato.
  (mutex (sb-thread:make-mutex :name "GET performance fixture observations")))
(defun performance-observed-backend (observer)
  "Backend POSIX reale; l'osservatore conta ogni tentativo pread, anche fallito."
  (io:make-backend
   #'io::native-open
   (lambda (fd buffer start count offset)
     (sb-thread:with-mutex ((performance-observer-mutex observer))
       (push (list offset count) (performance-observer-events observer)))
     (io::native-read fd buffer start count offset))
   #'io::native-write #'io::native-flush #'io::native-directory-flush #'io::native-close))

(defstruct (get-performance-fixture (:constructor %make-get-performance-fixture))
  directory path file observer image
  key missing-key value view segment valid-bytes cache epochs snapshots snapshot
  (generation 0) (version 2) (csn 7)
  contexts outputs)

(defun performance-fresh-directory ()
  ;; Il namespace cambia, i dati e gli esiti no. Nessun percorso condiviso fra fixture.
  (loop for attempt below 1000
        for path = (merge-pathnames
                    (format nil "arcdocdb-get-performance-~D-~D-~D/"
                            (get-universal-time) (sb-posix:getpid) attempt)
                    (uiop:temporary-directory)) do
    (handler-case
        (progn (sb-posix:mkdir (namestring path) #o700)
               (return-from performance-fresh-directory path))
      (sb-posix:syscall-error (condition)
        (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error "Namespace esclusivo della fixture GET non disponibile."))

(defun performance-read-events (fixture)
  "Copia (offset count) in ordine delle syscall tentate, oppure NIL se non osservate."
  (let ((observer (get-performance-fixture-observer fixture)))
    (when observer
      (sb-thread:with-mutex ((performance-observer-mutex observer))
        (reverse (copy-tree (performance-observer-events observer)))))))
(defun performance-clear-read-events (fixture)
  "Solo controller senza reader in volo; header escluso dai contatori delle operazioni."
  (let ((observer (get-performance-fixture-observer fixture)))
    (when observer
      (sb-thread:with-mutex ((performance-observer-mutex observer))
        (setf (performance-observer-events observer) nil))))
  nil)

(defun close-get-performance-fixture (fixture)
  "Solo controller, DOPO ogni join: libera contesti/snapshot, chiude FD e directory proprie.
Idempotente; nessun join o cancellazione di thread implicita."
  (unwind-protect
       (progn
         (map nil #'g:abbandona-get (get-performance-fixture-contexts fixture))
         (when (plusp (get-performance-fixture-generation fixture))
           (m:termina-snapshot (get-performance-fixture-snapshot fixture)
                              (get-performance-fixture-generation fixture))
           (setf (get-performance-fixture-generation fixture) 0)))
    (unwind-protect
         (when (get-performance-fixture-file fixture)
           (io:chiudi (get-performance-fixture-file fixture))
           (setf (get-performance-fixture-file fixture) nil))
      (let ((path (get-performance-fixture-path fixture))
            (directory (get-performance-fixture-directory fixture)))
        (when (and path (probe-file path)) (sb-posix:unlink (namestring path)))
        (when (and directory (probe-file directory))
          (sb-posix:rmdir (namestring directory)))
        (setf (get-performance-fixture-directory fixture) nil))))
  nil)

(defun make-get-performance-fixture (&key (version 2) (value-bytes 16) (csn 7)
                                        (record-csn csn) (cache-p nil) (workers 1)
                                        (record-bytes (+ 40 value-bytes))
                                        (snapshot-p nil) (snapshot-csn csn)
                                        (observe-io-p t) image-mutator)
  "Setup prima della misura: key16, V=16/256/4096, CSN esplicito, indice con seme fisso.
Cache con una classe 8192/otto posti; record scratch e output esclusivi per worker.
Snapshot registrato a NOW=10, lifetime=20: GET a 11, conclusione a 12, deadline=30.
IMAGE-MUTATOR è FI di setup seriale, prima dell'apertura readonly; nessun file modificato live.
OBSERVE-IO-P NIL usa il backend nativo senza raccolta eventi, per riuso nel benchmark.
Chiusura obbligatoria in UNWIND-PROTECT; la fixture non avvia thread."
  (unless (and (member version '(1 2)) (member value-bytes '(16 256 4096))
               (typep csn '(integer 1 #xffffffffffffffff))
               (typep record-csn '(integer 1 #xffffffffffffffff))
               (typep snapshot-csn '(unsigned-byte 64)) (<= 1 workers 4))
    (error "Configurazione della fixture GET performance non valida."))
  (let ((fixture (%make-get-performance-fixture)) (ready nil))
    (unwind-protect
         (let* ((key (performance-key)) (missing (copy-seq key))
                (value (performance-value value-bytes))
                (image (performance-image version key value record-csn))
                (csns (arcdocdb.csn:crea-registro-csn
                       :capacity 4 :initial-high (ldb (byte 32 32) snapshot-csn)
                       :initial-low (ldb (byte 32 0) snapshot-csn)))
                (snapshots (m:crea-registro-snapshot csns 4 20 5))
                (snapshot (m:crea-contesto-snapshot snapshots))
                (epochs (e:crea-registro-epoche workers 4))
                (scope (g:crea-ambito-get epochs snapshots))
                (index (p:crea-indice-primario
                        :capacity 16 :arena-bytes 256 :max-depth 1
                        :directory-budget-bytes 4096 :fragment-budget-bytes 4096
                        :hash-seed-high #x12345678 :hash-seed-low #x9abcdef0))
                (cache (when cache-p
                         (c:crea-cache-serie
                          (make-array 1 :element-type '(unsigned-byte 32) :initial-element 8192)
                          (make-array 1 :element-type '(unsigned-byte 32) :initial-element 1)
                          70000 :stripes 1)))
                (identity (subseq image 16 32))
                (view (g:crea-vista-get-serie scope index cache identity))
                (contexts (make-array workers)) (outputs (make-array workers))
                (valid-bytes (+ 104 value-bytes)))
           (setf (aref missing 0) 1)
           (dotimes (worker workers)
             (setf (aref contexts worker)
                   (g:crea-contesto-get scope worker :record-bytes record-bytes
                                       :budget-payload (+ record-bytes 152))
                   (aref outputs worker)
                   (performance-octets (+ value-bytes 8) +performance-output-sentinel+)))
           (setf (get-performance-fixture-key fixture) key
                 (get-performance-fixture-missing-key fixture) missing
                 (get-performance-fixture-value fixture) value
                 (get-performance-fixture-image fixture) image
                 (get-performance-fixture-view fixture) view
                 (get-performance-fixture-cache fixture) cache
                 (get-performance-fixture-contexts fixture) contexts
                 (get-performance-fixture-outputs fixture) outputs
                 (get-performance-fixture-epochs fixture) epochs
                 (get-performance-fixture-snapshots fixture) snapshots
                 (get-performance-fixture-snapshot fixture) snapshot
                 (get-performance-fixture-version fixture) version
                 (get-performance-fixture-csn fixture) csn
                 (get-performance-fixture-valid-bytes fixture) valid-bytes)
           (multiple-value-bind (high low) (p:digest-chiave-indice index key 0 16)
             (let ((content (performance-words 5)))
               (setf (aref content 0) csn (aref content 1) #x1100000040
                     (aref content 2) (logior (ash 16 32) (ash 1 48))
                     (aref content 3) (+ 40 value-bytes))
               (p:pubblica-chiave-indice index (p:frammento-corrente-indice index high)
                                        key 0 16 high low content (p:crea-contesto-indice))))
           (when snapshot-p
             (setf (get-performance-fixture-generation fixture)
                   (nth-value 0 (m:registra-snapshot snapshot 10))))
           (when image-mutator (funcall image-mutator image))
           (setf (get-performance-fixture-directory fixture) (performance-fresh-directory)
                 (get-performance-fixture-path fixture)
                 (merge-pathnames "segment.tmp" (get-performance-fixture-directory fixture)))
           (let ((writer (io:crea-temporaneo (get-performance-fixture-path fixture))))
             (unwind-protect
                  (progn (io:append-esatto writer image 0 (length image)) (io:durable-flush writer))
               (io:chiudi writer)))
           (let* ((observer (when observe-io-p (make-performance-observer)))
                  (backend (when observer (performance-observed-backend observer))))
             (setf (get-performance-fixture-observer fixture) observer
                   (get-performance-fixture-file fixture)
                   (io:apri-lettura (get-performance-fixture-path fixture) :backend backend)))
           (setf (get-performance-fixture-segment fixture)
                 (g:crea-segmento-get view (get-performance-fixture-file fixture)
                                      +performance-segment-id+ (performance-octets 64)))
           (performance-clear-read-events fixture)
           (setf ready t)
           fixture)
      (unless ready (close-get-performance-fixture fixture)))))

(defmacro with-get-performance-fixture ((fixture &rest options) &body body)
  `(let ((,fixture (make-get-performance-fixture ,@options)))
     (unwind-protect (progn ,@body) (close-get-performance-fixture ,fixture))))

(defun performance-check-unpinned (fixture &optional (worker 0) (state :idle))
  "Osservazioni pubbliche del proprietario, o controller dopo join."
  (is (eq state (g:stato-contesto-get
                  (aref (get-performance-fixture-contexts fixture) worker))))
  (is (not (e:epoca-attiva-p (e:contesto-epoca
                             (get-performance-fixture-epochs fixture) worker)))))

(defun performance-check-response (fixture output &optional (start +performance-output-start+))
  "Oracolo byte per byte: valore completo e sentinelle da entrambi i lati."
  (let* ((value (get-performance-fixture-value fixture)) (end (+ start (length value))))
    (is (loop for i below start always (= +performance-output-sentinel+ (aref output i))))
    (is (loop for i below (length value) always (= (aref value i) (aref output (+ start i)))))
    (is (loop for i from end below (length output)
              always (= +performance-output-sentinel+ (aref output i))))))

(defun performance-begin (fixture &optional (worker 0) missing-p)
  (g:avvia-get (aref (get-performance-fixture-contexts fixture) worker)
               (get-performance-fixture-view fixture)
               (if missing-p (get-performance-fixture-missing-key fixture)
                   (get-performance-fixture-key fixture))
               (when (plusp (get-performance-fixture-generation fixture))
                 (get-performance-fixture-snapshot fixture))
               (get-performance-fixture-generation fixture) 11))

(defun performance-check-candidate (fixture context)
  "Lookup/digest osservati attraverso l'API GET, cinque word attese indipendenti."
  (let ((output (performance-words 5 #xdeadbeef)))
    (g:copia-candidato-get context output)
    (is (= (get-performance-fixture-csn fixture) (aref output 0)))
    (is (= #x1100000040 (aref output 1)))
    ;; La chiave unica è pubblicata al primo offset dell'arena.
    (is (= (logior (ash 16 32) (ash 1 48)) (aref output 2)))
    (is (= (+ 40 (length (get-performance-fixture-value fixture))) (aref output 3)))
    (is (zerop (aref output 4)))))

(defun performance-checked-get (fixture &key (worker 0) (path :file)
                                           (expected-cache :disabled)
                                           (expected-insertion :not-attempted)
                                           (finish-now 12))
  "Driver di correttezza, NON corpo da cronometrare. Ogni operazione verifica tutte le fasi.
PATH :FILE passa da leggi-record-get; :CACHE-HIT richiede hit dalla sonda;
:CACHE-RECORD richiede hit dal percorso I/O senza leggere il PUT;
:ABSENT conferma un miss corrente. Output privato riempito e confrontato integralmente.
Restituisce :FOUND/:ABSENT e size soltanto dopo conclusione riuscita e pin zero."
  (let* ((context (aref (get-performance-fixture-contexts fixture) worker))
         (output (aref (get-performance-fixture-outputs fixture) worker))
         (expected-size (if (eq path :absent) 0 (length (get-performance-fixture-value fixture)))))
    (fill output +performance-output-sentinel+)
    (unwind-protect
         (progn
           (is (eq (if (eq path :absent) :absent :candidate)
                   (performance-begin fixture worker (eq path :absent))))
           (is (e:epoca-attiva-p (e:contesto-epoca (get-performance-fixture-epochs fixture) worker)))
           (if (eq path :absent)
               (is (every (lambda (byte) (= byte +performance-output-sentinel+)) output))
               (progn
                 (performance-check-candidate fixture context)
                 (ecase path
                   (:file
                    (is (equal (list :segment expected-cache expected-insertion nil nil)
                               (multiple-value-list
                                (g:leggi-record-get context (get-performance-fixture-segment fixture)
                                                   (get-performance-fixture-valid-bytes fixture) 0)))))
                   (:cache-hit
                    (is (eq :hit (g:sonda-cache-get context (get-performance-fixture-segment fixture)
                                                   (get-performance-fixture-valid-bytes fixture) 0))))
                   (:cache-record
                    (is (equal '(:cache :hit :not-attempted nil nil)
                               (multiple-value-list
                                (g:leggi-record-get context (get-performance-fixture-segment fixture)
                                                   (get-performance-fixture-valid-bytes fixture) 0))))))
                 (is (eq :verified (g:stato-contesto-get context)))
                 (is (= (+ +performance-output-start+ expected-size)
                        (g:copia-valore-get context output +performance-output-start+)))
                 (is (eq :copied (g:stato-contesto-get context)))
                 (performance-check-response fixture output)))
           (multiple-value-bind (result size) (g:concludi-get context finish-now)
             (is (eq (if (eq path :absent) :absent :found) result))
             (is (= expected-size size))
             (performance-check-unpinned fixture worker)
             (values result size)))
      (g:abbandona-get context))))

(defun performance-check-file-case (version value-bytes)
  (with-get-performance-fixture (fixture :version version :value-bytes value-bytes)
    (let ((key-before (copy-seq (get-performance-fixture-key fixture)))
          (image-before (copy-seq (get-performance-fixture-image fixture))))
      (dotimes (operation 3)
        (performance-clear-read-events fixture)
        (performance-checked-get fixture)
        (is (equal (list (list 64 (+ 40 value-bytes))) (performance-read-events fixture)))
        (is (equalp key-before (get-performance-fixture-key fixture)))
        (is (equalp image-before (get-performance-fixture-image fixture)))))))

(defun performance-warm-cache (fixture)
  "Un GET da segmento, verificato come tutte le operazioni, poi contatori azzerati."
  (performance-checked-get fixture :expected-cache :miss :expected-insertion :inserted)
  (performance-clear-read-events fixture))

(defun performance-check-cache-case (version)
  (dolist (size '(16 256 4096))
    (with-get-performance-fixture (fixture :version version :value-bytes size :cache-p t)
      (performance-warm-cache fixture)
      (dotimes (operation 3)
        (performance-checked-get fixture :path (if (evenp operation) :cache-hit :cache-record))
        (is (null (performance-read-events fixture)))))))

(defun performance-corrupt-cache (fixture)
  "FI seriale, prima dei reader: cambia il valore nel solo slot col tag autorevole.
Non usa lo scratch GET o la risposta come oracolo. Non modifica CRC/tag/seqlock."
  (let* ((cache (get-performance-fixture-cache fixture))
         (class (aref (c::cache-serie-classes cache) 0))
         (size (+ 40 (length (get-performance-fixture-value fixture))))
         (slot (loop for i below 8
                     when (c::tag-cache-p class i 0 17 64 size) return i)))
    (unless slot (error "Slot cache caldo della fixture non trovato."))
    (let ((position (+ (* slot (c::classe-cache-size class)) 40)))
      (setf (aref (c::classe-cache-arena class) position)
            (logxor 1 (aref (c::classe-cache-arena class) position))))))
