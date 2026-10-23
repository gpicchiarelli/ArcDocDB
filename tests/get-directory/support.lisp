;;;; Fixture CLOSED autonome; questo file definisce soltanto package, dati e funzioni.
;;; OWNER: controller per setup/chiusura, un contesto esclusivo per worker.
;;; SHARED: vista/directory/mappe immutabili; FD readonly mantenuti fino ai join.
(defpackage #:arcdocdb.get.directory.tests
  (:use #:cl)
  (:local-nicknames (#:d #:arcdocdb.get.directory) (#:r #:arcdocdb.get.resolver)
                    (#:g #:arcdocdb.get) (#:p #:arcdocdb.index.primary)
                    (#:io #:arcdocdb.io) (#:m #:arcdocdb.mvcc)
                    (#:e #:arcdocdb.epochs) (#:c #:arcdocdb.cache))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:corruption-detected #:snapshot-too-old #:error-reason)
  (:export #:run #:*get-directory-tests*
           #:directory-fixture #:make-directory-fixture #:close-directory-fixture
           #:with-directory-fixture #:directory-fixture-view #:directory-fixture-directory
           #:directory-fixture-maps #:directory-fixture-keys #:directory-fixture-values
           #:directory-fixture-contexts #:directory-fixture-outputs #:directory-fixture-epochs
           #:directory-fixture-index #:directory-fixture-files #:directory-fixture-paths
           #:directory-fixture-ids #:directory-fixture-ends #:directory-fixture-images
           #:directory-fixture-manifest #:directory-fixture-cache #:directory-fixture-scope
           #:directory-fixture-snapshots #:directory-fixture-snapshot #:directory-fixture-generation
           #:directory-fixture-version #:directory-fixture-csn #:directory-fixture-prepared-p
           #:directory-fixture-missing-key #:directory-fixture-timeout #:directory-fixture-error
           #:directory-begin #:directory-register-snapshot #:directory-read-events
           #:directory-close-events
           #:directory-clear-read-events #:directory-checked-read #:directory-check-clean
           #:directory-check-output #:+directory-output-start+ #:+directory-sentinel+))
(in-package #:arcdocdb.get.directory.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defconstant +directory-output-start+ 3)
(defconstant +directory-sentinel+ #xcc)
(defconstant +directory-max-csn+ #xffffffffffffffff)
(defconstant +directory-txid+ #xfedcba9876543210)

(define-condition directory-fixture-error (error)
  ((reason :initarg :reason :reader directory-fixture-error-reason))
  (:report (lambda (condition stream)
             (format stream "Fixture directory GET: ~A." (directory-fixture-error-reason condition)))))
(define-condition directory-fixture-timeout (directory-fixture-error) ())

(defun directory-octets (count &optional (initial 0))
  (make-array count :element-type '(unsigned-byte 8) :initial-element initial))
(defun directory-words (count &optional (initial 0))
  (make-array count :element-type '(unsigned-byte 64) :initial-element initial))
(defun directory-write-le (buffer start width number)
  "Encoding bytewise indipendente dal prodotto, inclusi u64 non fixnum."
  (dotimes (i width buffer)
    (setf (aref buffer (+ start i)) (ldb (byte 8 (* 8 i)) number))))
(defun directory-reference-crc (buffer start end &optional (seed 0))
  "CRC32C bitwise indipendente, con concatenazione dei CRC header per SEAL."
  (let ((crc (logxor seed #xffffffff)))
    (loop for i from start below end do
      (setf crc (logxor crc (aref buffer i)))
      (dotimes (bit 8)
        (setf crc (logxor (ash crc -1) (if (oddp crc) #x82f63b78 0)))))
    (logxor crc #xffffffff)))
(defun directory-reference-record (kind flags stamp key value)
  "Cornice nativa 24+K+V; key16 ha identico layout v1/v2."
  (let* ((end (+ 24 (length key) (length value))) (record (directory-octets end)))
    (setf (aref record 8) kind (aref record 9) flags)
    (directory-write-le record 10 2 (length key))
    (directory-write-le record 12 4 (length value))
    (directory-write-le record 16 8 stamp)
    (replace record key :start1 24)
    (replace record value :start1 (+ 24 (length key)))
    (directory-write-le record 4 4 (directory-reference-crc record 24 end))
    (directory-write-le record 0 4 (directory-reference-crc record 4 24))
    record))
(defun directory-reference-seal (records file-id start stamp)
  (let ((body (directory-octets 32)) (checksum 0))
    (dolist (record records)
      (setf checksum (directory-reference-crc record 0 4 checksum)))
    (directory-write-le body 0 8 file-id)
    (directory-write-le body 8 8 start)
    (directory-write-le body 16 8 start)
    (directory-write-le body 24 4 (length records))
    (directory-write-le body 28 4 checksum)
    (directory-reference-record 3 0 stamp (directory-octets 0) body)))
(defun directory-key (ordinal)
  (let ((key (directory-octets 16)))
    (replace key #(0 255 17 34 51 68 85 102 119 136 153 170 187 204 221 238))
    (directory-write-le key 0 4 ordinal)
    key))
(defun directory-value (ordinal size)
  (let ((value (directory-octets size)))
    (dotimes (i size value)
      (setf (aref value i) (mod (+ 29 (* 31 ordinal) (* 73 i)) 256)))))
(defun directory-reference-image (version id identity key value csn prepared-p)
  "Header reale, PUT ordinario compaction oppure writer PREPARED/OUTCOME/SEAL.
Undici byte invalidi oltre END esercitano la frontiera autorevole del manifest."
  (let* ((put (directory-reference-record 1 (if prepared-p 1 0)
                                           (if prepared-p +directory-txid+ csn) key value))
         (outcome (when prepared-p
                    (directory-reference-record 4 0 +directory-txid+ (directory-octets 0)
                                                (directory-write-le (directory-octets 8) 0 8 csn))))
         (seal (when prepared-p (directory-reference-seal (list put outcome) id 64 csn)))
         (end (+ 64 (length put) (if prepared-p (+ (length outcome) (length seal)) 0)))
         (image (directory-octets (+ end 11))))
    (replace image #(65 82 67 68 83 69 71 49)) ; ARCDSEG1
    (directory-write-le image 8 2 version)
    (setf (aref image 10) (if prepared-p 1 2))
    (replace image identity :start1 16)
    (directory-write-le image 32 8 id)
    (directory-write-le image 40 8 123456)
    (directory-write-le image 56 4 (directory-reference-crc image 0 56))
    (replace image put :start1 64)
    (when prepared-p
      (replace image outcome :start1 (+ 64 (length put)))
      (replace image seal :start1 (+ 64 (length put) (length outcome))))
    (fill image #xee :start end)
    (values image end)))

(defun directory-reference-manifest (ids ends version)
  "EDIT completo + SEAL indipendenti; nessuna entry OUTCOME aggiunta nell'EDIT.
L'ACTIVE richiesto dal formato del manifest resta fuori dalla directory CLOSED."
  (let* ((count (length ids)) (body (directory-octets (+ 24 (* 20 count))))
         ;; ID u64 distinto da tutti gli ID u32 CLOSED, incluso #xffffffff.
         (active #x100000001))
    (directory-write-le body 0 8 (1+ active))
    (directory-write-le body 8 8 active)
    (directory-write-le body 16 4 count)
    (dotimes (i count)
      (directory-write-le body (+ 20 (* 20 i)) 8 (aref ids i))
      (directory-write-le body (+ 28 (* 20 i)) 8 (aref ends i)))
    (let* ((edit (directory-reference-record 5 8 17 (directory-octets 0) body))
           (seal (directory-reference-seal (list edit) 0 64 17))
           (buffer (directory-octets (+ (length edit) (length seal)))))
      (replace buffer edit)
      (replace buffer seal :start1 (length edit))
      (multiple-value-bind (manifest next status)
          (arcdocdb.recovery.manifest:ricostruisci-manifest
           buffer 0 (length buffer) :version version :file-offset 64 :file-size (+ 64 (length buffer)))
        (unless (and (= next (length buffer)) (eq status :complete))
          (error 'directory-fixture-error :reason :manifest-result))
        manifest))))

(defstruct (directory-observer (:constructor make-directory-observer ()))
  (events nil) (close-events nil) (hook nil)
  (mutex (sb-thread:make-mutex :name "directory fixture pread")))
(defun directory-observed-backend (observer id)
  (io:make-backend
   #'io::native-open
   (lambda (fd buffer start count offset)
     (sb-thread:with-mutex ((directory-observer-mutex observer))
       (push (list id offset count) (directory-observer-events observer)))
     ;; Hook FI del solo worker proprietario, installato prima della sua operazione.
     (when (directory-observer-hook observer)
       (funcall (directory-observer-hook observer) id offset count))
     (io::native-read fd buffer start count offset))
   #'io::native-write #'io::native-flush #'io::native-directory-flush
   (lambda (fd)
     ;; Il conteggio segue una close nativa riuscita: non conta richieste o no-op CHIUDI.
     (let ((result (io::native-close fd)))
       (when (eql result 0)
         (sb-thread:with-mutex ((directory-observer-mutex observer))
           (push (list id fd :closed) (directory-observer-close-events observer))))
       result))))

(defstruct (directory-fixture (:constructor %make-directory-fixture))
  view directory index scope cache epochs snapshots snapshot (generation 0)
  (maps #() :type simple-vector) (keys #() :type simple-vector) (values #() :type simple-vector)
  (contexts #() :type simple-vector) (outputs #() :type simple-vector)
  (files #() :type simple-vector) (paths #() :type simple-vector) (images #() :type simple-vector)
  (ids #() :type simple-vector) (ends #() :type simple-vector)
  root manifest missing-key observer (version 2) (csn +directory-max-csn+) (prepared-p nil))

(defun directory-fresh-root ()
  (loop for attempt below 1000
        for path = (merge-pathnames
                    (format nil "arcdocdb-directory-~D-~D-~D/"
                            (get-universal-time) (sb-posix:getpid) attempt)
                    (uiop:temporary-directory)) do
    (handler-case
        (progn (sb-posix:mkdir (namestring path) #o700) (return-from directory-fresh-root path))
      (sb-posix:syscall-error (condition)
        (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error 'directory-fixture-error :reason :namespace-budget))

(defun directory-read-events (fixture)
  "Copia delle triple (segment-id offset count); header/setup esclusi dal driver."
  (let ((observer (directory-fixture-observer fixture)))
    (when observer
      (sb-thread:with-mutex ((directory-observer-mutex observer))
        (reverse (copy-tree (directory-observer-events observer)))))))
(defun directory-clear-read-events (fixture)
  (let ((observer (directory-fixture-observer fixture)))
    (when observer
      (sb-thread:with-mutex ((directory-observer-mutex observer))
        (setf (directory-observer-events observer) nil))))
  nil)

;;; REQ: REQ-CMP-007 REQ-AFF-001
(defun directory-close-events (fixture)
  "Pre: osservatore locale. Post: copia delle close native riuscite (segment-id FD :CLOSED).
Mutex solo per osservazione C4; non autorizza chiusura o reclaim e non azzera la storia."
  (let ((observer (directory-fixture-observer fixture)))
    (when observer
      (sb-thread:with-mutex ((directory-observer-mutex observer))
        (reverse (copy-tree (directory-observer-close-events observer)))))))

(defun close-directory-fixture (fixture)
  "Solo controller DOPO tutti i join; idempotente, nessun join implicito."
  (unwind-protect
       (progn
         (map nil (lambda (context) (when context (g:abbandona-get context)))
              (directory-fixture-contexts fixture))
         (when (plusp (directory-fixture-generation fixture))
           (m:termina-snapshot (directory-fixture-snapshot fixture) (directory-fixture-generation fixture))
           (setf (directory-fixture-generation fixture) 0)))
    (unwind-protect
         (map nil (lambda (file) (when file (io:chiudi file))) (directory-fixture-files fixture))
      (map nil (lambda (path) (when (and path (probe-file path)) (sb-posix:unlink (namestring path))))
           (directory-fixture-paths fixture))
      (let ((root (directory-fixture-root fixture)))
        (when (and root (probe-file root)) (sb-posix:rmdir (namestring root)))
        (setf (directory-fixture-root fixture) nil))))
  nil)

(defun make-directory-fixture (&key (count 1) (value-bytes 16) (workers 4) (version 2)
                                   (csn +directory-max-csn+) (cache-p t)
                                   (prepared-p nil) (record-csn csn) (record-bytes (+ 40 value-bytes))
                                   (observe-io-p nil) image-mutator)
  "Contratto stabile per test e benchmark: N file reali readonly, un PUT key16 per file.
COUNT 0..32768, WORKERS 1..4; OUTPUTS ha sempre quattro u8 privati di V+6, #xcc, start3.
Ultimo ID #xffffffff, precedenti 17+2*i; indice con seme fisso, pubblicazione API pubblica.
Cache: una classe di almeno 1024 byte, 256 set/otto posti, una stripe, budget esplicito.
Snapshot creato ma non registrato; niente thread, misure o test eseguiti da questa funzione.
Extra keyword FI di setup: PREPARED-P, RECORD-CSN, RECORD-BYTES, OBSERVE-IO-P,
IMAGE-MUTATOR(image, ordinal), chiamato prima dell'apertura readonly. Chiusura obbligatoria."
  (unless (and (typep count '(integer 0 32768)) (typep value-bytes '(integer 1 16777216))
               (typep workers '(integer 1 4)) (member version '(1 2))
               (typep csn '(integer 1 #xffffffffffffffff))
               (typep record-csn '(integer 1 #xffffffffffffffff))
               (typep record-bytes '(integer 1 16842775))
               (or (/= version 1) (<= (+ 40 value-bytes) #xffffff)))
    (error 'directory-fixture-error :reason :configuration))
  (let ((fixture (%make-directory-fixture)) (ready nil))
    (unwind-protect
         (let* ((csns (arcdocdb.csn:crea-registro-csn
                       :capacity 4 :initial-high (ldb (byte 32 32) csn) :initial-low (ldb (byte 32 0) csn)))
                (snapshots (m:crea-registro-snapshot csns 4 20 5))
                (epochs (e:crea-registro-epoche workers 4))
                (scope (g:crea-ambito-get epochs snapshots))
                (capacity (loop for candidate = 16 then (* 2 candidate)
                                repeat 13 when (>= candidate (* 2 count)) return candidate))
                (index (p:crea-indice-primario
                        :capacity capacity :arena-bytes (* (+ count 4) 16) :max-depth 1
                        :directory-budget-bytes 4096 :fragment-budget-bytes (+ (* 41 capacity) (* (+ count 4) 16))
                        :hash-seed-high #x12345678 :hash-seed-low #x9abcdef0))
                (cache-size (loop for candidate = 1024 then (* 2 candidate)
                                  repeat 16 when (>= candidate (+ 40 value-bytes)) return candidate))
                (cache (when cache-p
                         (c:crea-cache-serie
                          (make-array 1 :element-type '(unsigned-byte 32) :initial-element cache-size)
                          (make-array 1 :element-type '(unsigned-byte 32) :initial-element 256)
                          (+ (* 256 8 (+ cache-size 29)) 256 16) :stripes 1)))
                (identity (directory-octets 16))
                (observer (when observe-io-p (make-directory-observer))))
           (dotimes (i 16) (setf (aref identity i) (+ 32 i)))
           (setf (directory-fixture-view fixture) (g:crea-vista-get-serie scope index cache identity)
                 (directory-fixture-index fixture) index (directory-fixture-scope fixture) scope
                 (directory-fixture-cache fixture) cache (directory-fixture-epochs fixture) epochs
                 (directory-fixture-snapshots fixture) snapshots
                 (directory-fixture-snapshot fixture) (m:crea-contesto-snapshot snapshots)
                 (directory-fixture-version fixture) version (directory-fixture-csn fixture) csn
                 (directory-fixture-prepared-p fixture) prepared-p (directory-fixture-observer fixture) observer
                 (directory-fixture-missing-key fixture) (directory-key #xffffffff)
                 (directory-fixture-contexts fixture) (make-array workers :initial-element nil)
                 (directory-fixture-outputs fixture) (make-array 4 :initial-element nil))
           (dotimes (worker workers)
             (setf (aref (directory-fixture-contexts fixture) worker)
                   (g:crea-contesto-get scope worker :record-bytes record-bytes :budget-payload (+ record-bytes 152))))
           (dotimes (worker 4)
             (setf (aref (directory-fixture-outputs fixture) worker)
                   (directory-octets (+ value-bytes 6) +directory-sentinel+)))
           (setf (directory-fixture-maps fixture) (make-array count :initial-element nil)
                 (directory-fixture-files fixture) (make-array count :initial-element nil)
                 (directory-fixture-paths fixture) (make-array count :initial-element nil)
                 (directory-fixture-images fixture) (make-array count :initial-element nil)
                 (directory-fixture-keys fixture) (make-array count :initial-element nil)
                 (directory-fixture-values fixture) (make-array count :initial-element nil)
                 (directory-fixture-ids fixture) (make-array count :initial-element nil)
                 (directory-fixture-ends fixture) (make-array count :initial-element nil)
                 (directory-fixture-root fixture) (directory-fresh-root))
           (dotimes (i count)
             (let ((id (if (= i (1- count)) #xffffffff (+ 17 (* 2 i))))
                   (key (directory-key i)) (value (directory-value i value-bytes)))
               (multiple-value-bind (image end)
                   (directory-reference-image version id identity key value record-csn prepared-p)
                 (setf (aref (directory-fixture-ids fixture) i) id
                       (aref (directory-fixture-keys fixture) i) key
                       (aref (directory-fixture-values fixture) i) value
                       (aref (directory-fixture-images fixture) i) image
                       (aref (directory-fixture-ends fixture) i) end))))
           (setf (directory-fixture-manifest fixture)
                 (directory-reference-manifest (directory-fixture-ids fixture) (directory-fixture-ends fixture) version))
           (dotimes (i count)
             (let* ((id (aref (directory-fixture-ids fixture) i))
                    (image (aref (directory-fixture-images fixture) i))
                    (path (merge-pathnames (format nil "segment-~D.tmp" id) (directory-fixture-root fixture))))
               (when image-mutator (funcall image-mutator image i))
               ;; Percorso registrato dopo la creazione esclusiva: il cleanup tocca solo file propri.
               (let ((writer (io:crea-temporaneo path)))
                 (setf (aref (directory-fixture-paths fixture) i) path)
                 (unwind-protect
                      (progn (io:append-esatto writer image 0 (length image)) (io:durable-flush writer))
                   (io:chiudi writer)))
               (let ((file (io:apri-lettura path :backend (when observer (directory-observed-backend observer id)))))
                 (setf (aref (directory-fixture-files fixture) i) file
                       (aref (directory-fixture-maps fixture) i)
                       (r:crea-mappa-segmento-get
                        (directory-fixture-view fixture) file (directory-fixture-manifest fixture) id
                        (directory-octets (aref (directory-fixture-ends fixture) i))
                        :max-bytes (max 120 (aref (directory-fixture-ends fixture) i))
                        :max-batch-bytes (max 56 (aref (directory-fixture-ends fixture) i))
                        :max-records 2 :max-batches 1 :max-batch-records 2 :budget-payload 44)))))
           (setf (directory-fixture-directory fixture)
                 (d:crea-directory-get-serie (directory-fixture-view fixture) (directory-fixture-maps fixture)))
           ;; Directory completa prima della pubblicazione delle location nel primary.
           (dotimes (i count)
             (directory-publish-key fixture (aref (directory-fixture-keys fixture) i)
                                    csn (aref (directory-fixture-ids fixture) i) 64 (+ 40 value-bytes)))
           (directory-clear-read-events fixture)
           (setf ready t)
           fixture)
      (unless ready (close-directory-fixture fixture)))))

(defun directory-publish-key (fixture key csn segment-id offset size)
  "Setup writer via sole API pubbliche; nessuna scrittura su contesti GET."
  (let ((index (directory-fixture-index fixture)) (content (directory-words 5)))
    (setf (aref content 0) csn (aref content 1) (logior (ash segment-id 32) offset)
          (aref content 2) (logior (ash (length key) 32) (ash 1 48)) (aref content 3) size)
    (multiple-value-bind (high low) (p:digest-chiave-indice index key 0 (length key))
      (p:pubblica-chiave-indice index (p:frammento-corrente-indice index high) key 0 (length key)
                               high low content (p:crea-contesto-indice)))))
(defmacro with-directory-fixture ((fixture &rest options) &body body)
  `(let ((,fixture (make-directory-fixture ,@options)))
     (unwind-protect (progn ,@body) (close-directory-fixture ,fixture))))
(defun directory-register-snapshot (fixture &optional (now 10))
  (setf (directory-fixture-generation fixture)
        (nth-value 0 (m:registra-snapshot (directory-fixture-snapshot fixture) now))))
(defun directory-begin (fixture &key (worker 0) (ordinal 0) missing-p (now 11))
  (g:avvia-get (aref (directory-fixture-contexts fixture) worker) (directory-fixture-view fixture)
               (if missing-p (directory-fixture-missing-key fixture) (aref (directory-fixture-keys fixture) ordinal))
               (when (plusp (directory-fixture-generation fixture)) (directory-fixture-snapshot fixture))
               (directory-fixture-generation fixture) now))
(defun directory-check-clean (fixture &optional (worker 0) (state :idle))
  "Oracolo controller dopo join, o del worker proprietario; comprende pin e residui privati."
  (let ((context (aref (directory-fixture-contexts fixture) worker)))
    (unless (and (eq state (g:stato-contesto-get context))
                 (not (e:epoca-attiva-p (e:contesto-epoca (directory-fixture-epochs fixture) worker)))
                 (null (g::contesto-get-view context)) (null (g::contesto-get-key context))
                 (not (g::contesto-get-snapshot-p context))
                 (zerop (g::contesto-get-value-start context)) (zerop (g::contesto-get-value-end context))
                 (every #'zerop (g::contesto-get-content context)) (every #'zerop (g::contesto-get-limit context)))
      (error 'directory-fixture-error :reason :cleanup)))
  t)
(defun directory-check-output (fixture worker ordinal)
  (let* ((output (aref (directory-fixture-outputs fixture) worker))
         (value (aref (directory-fixture-values fixture) ordinal))
         (end (+ +directory-output-start+ (length value))))
    (unless (and (loop for i below +directory-output-start+ always (= +directory-sentinel+ (aref output i)))
                 (loop for i below (length value) always (= (aref value i) (aref output (+ 3 i))))
                 (loop for i from end below (length output) always (= +directory-sentinel+ (aref output i))))
      (error 'directory-fixture-error :reason :output)))
  t)
(defun directory-checked-read (fixture &key (worker 0) (ordinal 0) (finish-now 12))
  "Driver di correttezza, non loop misurato: acquisisce DIRECTORY solo dopo AVVIA-GET.
Restituisce FOUND, size, e i cinque enum/boolean del nucleo come lista, dopo pin zero."
  (let ((context (aref (directory-fixture-contexts fixture) worker))
        (output (aref (directory-fixture-outputs fixture) worker)))
    (fill output +directory-sentinel+)
    (unwind-protect
         (progn
           (unless (eq :candidate (directory-begin fixture :worker worker :ordinal ordinal))
             (error 'directory-fixture-error :reason :candidate))
           (let ((statuses (multiple-value-list
                            (d:leggi-record-directory-get context (directory-fixture-directory fixture)))))
             (unless (and (= 5 (length statuses)) (member (first statuses) '(:cache :segment)))
               (error 'directory-fixture-error :reason :read-result))
             (g:copia-valore-get context output +directory-output-start+)
             (multiple-value-bind (result size) (g:concludi-get context finish-now)
               (unless (and (eq result :found) (= size (length (aref (directory-fixture-values fixture) ordinal))))
                 (error 'directory-fixture-error :reason :finish-result))
               (directory-check-output fixture worker ordinal)
               (directory-check-clean fixture worker)
               (values result size statuses))))
      (g:abbandona-get context))))
