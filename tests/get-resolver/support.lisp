;;;; Fixture native del resolver CLOSED, senza dipendenza dalla suite directory.
;;; OWNER: un solo autore della fixture; contesto, buffer e namespace esclusivi.
;;; SHARED: FD readonly e mappa immutabile protetti dal normale ingresso GET.
(defpackage #:arcdocdb.get.resolver.tests
  (:use #:cl)
  (:local-nicknames (#:r #:arcdocdb.get.resolver) (#:g #:arcdocdb.get)
                    (#:io #:arcdocdb.io) (#:e #:arcdocdb.epochs)
                    (#:m #:arcdocdb.mvcc) (#:p #:arcdocdb.index.primary)
                    (#:c #:arcdocdb.cache))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:corruption-detected #:snapshot-too-old #:error-reason)
  (:export #:run #:*get-resolver-tests*))
(in-package #:arcdocdb.get.resolver.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defvar *get-resolver-tests* nil)
(defmacro deftest (name &body body)
  `(progn
     (defun ,name () ,@body)
     (setf *get-resolver-tests*
           (acons ',name #',name (remove ',name *get-resolver-tests* :key #'car)))))
(defun run ()
  (dolist (test (reverse *get-resolver-tests*))
    (funcall (cdr test))
    (format t "ok    ~A~%" (car test)))
  (format t "~D test resolver GET superati.~%" (length *get-resolver-tests*))
  t)

(defconstant +resolver-output-start+ 3)
(defconstant +resolver-sentinel+ #xcc)
(defconstant +resolver-default-txid+ #xfedcba9876543210)

(define-condition resolver-fixture-error (error)
  ((reason :initarg :reason :reader resolver-fixture-error-reason))
  (:report (lambda (condition stream)
             (format stream "Fixture resolver CLOSED: ~A." (resolver-fixture-error-reason condition)))))

;;; Encoding copiato da tests/get-directory/support.lisp e rinominato.
;;; CRC bitwise e layout letterale indipendenti dai writer/verificatori prodotto.
(defun resolver-octets (count &optional (initial 0))
  (make-array count :element-type '(unsigned-byte 8) :initial-element initial))
(defun resolver-write-le (buffer start width number)
  (dotimes (i width buffer)
    (setf (aref buffer (+ start i)) (ldb (byte 8 (* 8 i)) number))))
(defun resolver-reference-crc (buffer start end &optional (seed 0))
  (let ((crc (logxor seed #xffffffff)))
    (loop for i from start below end do
      (setf crc (logxor crc (aref buffer i)))
      (dotimes (bit 8)
        (setf crc (logxor (ash crc -1) (if (oddp crc) #x82f63b78 0)))))
    (logxor crc #xffffffff)))
(defun resolver-reference-record (kind flags stamp key value)
  "Cornice 24+K+V; le chiavi delle fixture sono <=255, identiche in v1/v2."
  (let* ((end (+ 24 (length key) (length value))) (record (resolver-octets end)))
    (setf (aref record 8) kind (aref record 9) flags)
    (resolver-write-le record 10 2 (length key))
    (resolver-write-le record 12 4 (length value))
    (resolver-write-le record 16 8 stamp)
    (replace record key :start1 24)
    (replace record value :start1 (+ 24 (length key)))
    (resolver-write-le record 4 4 (resolver-reference-crc record 24 end))
    (resolver-write-le record 0 4 (resolver-reference-crc record 4 24))
    record))
(defun resolver-reference-seal (records file-id start stamp)
  (let ((body (resolver-octets 32)) (checksum 0))
    (dolist (record records)
      (setf checksum (resolver-reference-crc record 0 4 checksum)))
    (resolver-write-le body 0 8 file-id)
    (resolver-write-le body 8 8 start)
    (resolver-write-le body 16 8 start)
    (resolver-write-le body 24 4 (length records))
    (resolver-write-le body 28 4 checksum)
    (resolver-reference-record 3 0 stamp (resolver-octets 0) body)))
(defun resolver-key (ordinal)
  (let ((key (resolver-octets 16)))
    (replace key #(0 255 17 34 51 68 85 102 119 136 153 170 187 204 221 238))
    (resolver-write-le key 0 4 ordinal)
    key))
(defun resolver-value (ordinal &optional (size 16))
  (let ((value (resolver-octets size)))
    (dotimes (i size value)
      (setf (aref value i) (mod (+ 29 (* 31 ordinal) (* 73 i)) 256)))))

(defun resolver-reference-image (version id identity batches)
  "BATCHES liste di plist :kind :prepared/:ordinary/:outcome/:tombstone.
Un SEAL letterale completa ogni lotto; l'ordine fisico dei record è quello dato.
Restituisce immagine, END, metadati PUT e offset OUTCOME, senza API prodotto."
  (let ((position 64) (chunks nil) (puts nil) (proof-offsets nil) (ordinal 0))
    (dolist (batch batches)
      (let ((start position) (records nil) (stamp 7))
        (dolist (entry batch)
          (let* ((kind (getf entry :kind)) (csn (getf entry :csn 7))
                 (prepared-p (eq kind :prepared))
                 (key (if (eq kind :outcome) (resolver-octets 0)
                          (or (getf entry :key) (resolver-key ordinal))))
                 (value (case kind
                          (:outcome (resolver-write-le (resolver-octets 8) 0 8 csn))
                          (:tombstone (resolver-octets 0))
                          (otherwise (or (getf entry :value) (resolver-value ordinal)))))
                 (record (resolver-reference-record
                          (case kind ((:prepared :ordinary) 1) (:outcome 4) (:tombstone 2)
                            (otherwise (error 'resolver-fixture-error :reason :record-kind)))
                          (if prepared-p 1 0)
                          (if (or prepared-p (eq kind :outcome))
                              (getf entry :txid +resolver-default-txid+) csn) key value)))
            (when (member kind '(:ordinary :tombstone)) (setf stamp csn))
            (when (member kind '(:prepared :ordinary))
              (push (list key value position (length record) csn prepared-p) puts)
              (incf ordinal))
            (when (eq kind :outcome) (push position proof-offsets))
            (push record records) (push (cons position record) chunks)
            (incf position (length record))))
        (let ((seal (resolver-reference-seal (nreverse records) id start stamp)))
          (push (cons position seal) chunks) (incf position (length seal)))))
    (let ((image (resolver-octets (+ position 11))))
      (replace image #(65 82 67 68 83 69 71 49))
      (resolver-write-le image 8 2 version)
      (setf (aref image 10) 1)
      (replace image identity :start1 16)
      (resolver-write-le image 32 8 id)
      (resolver-write-le image 40 8 123456)
      (resolver-write-le image 56 4 (resolver-reference-crc image 0 56))
      (dolist (chunk chunks) (replace image (cdr chunk) :start1 (car chunk)))
      (fill image #xee :start position)
      (values image position (nreverse puts) (nreverse proof-offsets)))))

(defun resolver-reference-manifest (id end version)
  "EDIT completo e SEAL indipendenti: un CLOSED, nessuna prova aggiuntiva EDIT."
  (let ((body (resolver-octets 44)) (active #x100000001))
    (resolver-write-le body 0 8 (1+ active))
    (resolver-write-le body 8 8 active)
    (resolver-write-le body 16 4 1)
    (resolver-write-le body 20 8 id)
    (resolver-write-le body 28 8 end)
    (let* ((edit (resolver-reference-record 5 8 17 (resolver-octets 0) body))
           (seal (resolver-reference-seal (list edit) 0 64 17))
           (buffer (resolver-octets (+ (length edit) (length seal)))))
      (replace buffer edit) (replace buffer seal :start1 (length edit))
      (multiple-value-bind (manifest next status)
          (arcdocdb.recovery.manifest:ricostruisci-manifest
           buffer 0 (length buffer) :version version :file-offset 64 :file-size (+ 64 (length buffer)))
        (unless (and (= next (length buffer)) (eq status :complete))
          (error 'resolver-fixture-error :reason :manifest-result))
        manifest))))

(defstruct (resolver-observer (:constructor make-resolver-observer ())) events hook)
(defun resolver-observed-backend (observer)
  "Osservatore locale: conserva FD/offset/count e delega all'adattatore nativo invariato."
  (io:make-backend
   #'io::native-open
   (lambda (fd buffer start count offset)
     (push (list fd offset count) (resolver-observer-events observer))
     (when (resolver-observer-hook observer)
       (funcall (resolver-observer-hook observer) fd offset count))
     (io::native-read fd buffer start count offset))
   #'io::native-write #'io::native-flush #'io::native-directory-flush #'io::native-close))

(defstruct (resolver-fixture (:constructor %make-resolver-fixture) (:conc-name rf-))
  map view context file path root image buffer manifest observer epochs snapshots snapshot index scope cache
  (generation 0) (version 2) (id 17) (end 0) (budget-payload 0)
  (keys #() :type simple-vector) (values #() :type simple-vector)
  (offsets #() :type simple-vector) (sizes #() :type simple-vector)
  (candidate-csns #() :type simple-vector) (prepared #() :type simple-vector)
  (proof-offsets #() :type simple-vector) output)

(defun resolver-fresh-root ()
  (loop for attempt below 1000
        for path = (merge-pathnames
                    (format nil "arcdocdb-resolver-~D-~D-~D/"
                            (get-universal-time) (sb-posix:getpid) attempt)
                    (uiop:temporary-directory)) do
    (handler-case
        (progn (sb-posix:mkdir (namestring path) #o700) (return-from resolver-fresh-root path))
      (sb-posix:syscall-error (condition)
        (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error 'resolver-fixture-error :reason :namespace-budget))
(defun resolver-reads (fixture)
  (reverse (copy-tree (resolver-observer-events (rf-observer fixture)))))
(defun resolver-clear-reads (fixture)
  (setf (resolver-observer-events (rf-observer fixture)) nil)
  nil)
(defun close-resolver-fixture (fixture)
  "Cleanup del solo namespace posseduto; prima termina GET/snapshot, poi chiude FD."
  (unwind-protect
       (progn
         (when (rf-context fixture) (g:abbandona-get (rf-context fixture)))
         (when (plusp (rf-generation fixture))
           (m:termina-snapshot (rf-snapshot fixture) (rf-generation fixture))
           (setf (rf-generation fixture) 0)))
    (unwind-protect
         (when (rf-file fixture) (io:chiudi (rf-file fixture)))
      (when (and (rf-path fixture) (probe-file (rf-path fixture)))
        (sb-posix:unlink (namestring (rf-path fixture))))
      (when (and (rf-root fixture) (probe-file (rf-root fixture)))
        (sb-posix:rmdir (namestring (rf-root fixture))))
      (setf (rf-root fixture) nil)))
  nil)

(defun resolver-build-map (fixture &rest options)
  "Setup nel pool I/O; OPTIONS sostituisce singoli budget, END resta dal manifest."
  (setf (rf-map fixture)
        (apply #'r:crea-mappa-segmento-get
               (rf-view fixture) (rf-file fixture) (rf-manifest fixture) (rf-id fixture) (rf-buffer fixture)
               (append options
                       (list :max-bytes (max 120 (rf-end fixture)) :max-records 64 :max-batches 8
                             :max-batch-records 64 :max-batch-bytes (max 56 (rf-end fixture))
                             :budget-payload (rf-budget-payload fixture))))))
(defun resolver-publish (fixture ordinal &key (csn (aref (rf-candidate-csns fixture) ordinal)))
  "Pubblica il candidato tramite indice pubblico; update richiede CSN crescente."
  (let* ((key (aref (rf-keys fixture) ordinal)) (index (rf-index fixture))
         (content (make-array 5 :element-type '(unsigned-byte 64) :initial-element 0)))
    (setf (aref content 0) csn
          (aref content 1) (logior (ash (rf-id fixture) 32) (aref (rf-offsets fixture) ordinal))
          (aref content 2) (logior (ash (length key) 32) (ash 1 48))
          (aref content 3) (aref (rf-sizes fixture) ordinal))
    (multiple-value-bind (high low) (p:digest-chiave-indice index key 0 (length key))
      (p:pubblica-chiave-indice index (p:frammento-corrente-indice index high) key 0 (length key)
                               high low content (p:crea-contesto-indice)))))

(defun make-resolver-fixture (&key (version 2) (cache-p t) (build-p t) (record-bytes 256)
                                 (records (list (list :kind :prepared :txid +resolver-default-txid+ :csn 7)))
                                 (proofs (list (list :txid +resolver-default-txid+ :csn 7)))
                                 (batches nil batches-p) candidate-csns (snapshot-csn 7)
                                 (budget-payload nil budget-p) image-transform)
  "RECORDS plist PUT/TOMBSTONE poi PROOFS OUTCOME; BATCHES sostituisce l'ordine completo.
Un file readonly con header/SEAL/manifest reali; buffer esclusivo di esattamente END.
Gli accessor RF-* osservano la fixture, non forniscono gli oracoli del resolver."
  (unless (and (member version '(1 2)) (typep record-bytes '(integer 1 16842775))
               (typep snapshot-csn '(integer 1 #xffffffffffffffff)))
    (error 'resolver-fixture-error :reason :configuration))
  (let ((fixture (%make-resolver-fixture)) (ready nil)
        (entries (if batches-p batches
                     (list (append records
                                   (mapcar (lambda (proof) (list :kind :outcome :txid (getf proof :txid)
                                                                 :csn (getf proof :csn))) proofs)))))
        (identity (resolver-octets 16)))
    (dotimes (i 16) (setf (aref identity i) (+ 32 i)))
    (unwind-protect
         (multiple-value-bind (image end puts proof-offsets)
             (resolver-reference-image version 17 identity entries)
           (let* ((count (length puts)) (outcomes (length proof-offsets))
                  (csns (or candidate-csns (mapcar #'fifth puts)))
                  (capacity (loop for n = 16 then (* 2 n) repeat 5 when (>= n (* 2 count)) return n))
                  (peak (+ (* 24 count) (* 20 outcomes) (if (> outcomes 1) (+ (* 20 outcomes) 1024) 0)))
                  (register-csn (max snapshot-csn (reduce #'max csns :initial-value 0))))
             (unless (and capacity (<= count 64) (<= (length entries) 8) (= count (length csns))
                          (every (lambda (csn) (typep csn '(integer 1 #xffffffffffffffff))) csns))
               (error 'resolver-fixture-error :reason :cardinality))
             (setf (rf-image fixture) image (rf-end fixture) end (rf-version fixture) version
                   (rf-budget-payload fixture) (if budget-p budget-payload peak)
                   (rf-keys fixture) (make-array count :initial-contents (mapcar #'first puts))
                   (rf-values fixture) (make-array count :initial-contents (mapcar #'second puts))
                   (rf-offsets fixture) (make-array count :initial-contents (mapcar #'third puts))
                   (rf-sizes fixture) (make-array count :initial-contents (mapcar #'fourth puts))
                   (rf-prepared fixture) (make-array count :initial-contents (mapcar #'sixth puts))
                   (rf-candidate-csns fixture) (make-array count :initial-contents csns)
                   (rf-proof-offsets fixture) (make-array outcomes :initial-contents proof-offsets)
                   (rf-buffer fixture) (resolver-octets end)
                   (rf-observer fixture) (make-resolver-observer))
             (let* ((registry (arcdocdb.csn:crea-registro-csn
                               :capacity 4 :initial-high (ldb (byte 32 32) register-csn)
                               :initial-low (ldb (byte 32 0) register-csn)))
                    (snapshots (m:crea-registro-snapshot registry 4 20 5))
                    (epochs (e:crea-registro-epoche 1 4))
                    (scope (g:crea-ambito-get epochs snapshots))
                    (index (p:crea-indice-primario
                            :capacity capacity :arena-bytes (* (+ count 4) 255) :max-depth 1
                            :directory-budget-bytes 4096
                            :fragment-budget-bytes (+ (* 41 capacity) (* (+ count 4) 255))
                            :hash-seed-high #x12345678 :hash-seed-low #x9abcdef0))
                    (cache (when cache-p
                             (c:crea-cache-serie
                              (make-array 1 :element-type '(unsigned-byte 32) :initial-element 1024)
                              (make-array 1 :element-type '(unsigned-byte 32) :initial-element 1)
                              (+ (* 8 (+ 1024 29)) 1 16) :stripes 1)))
                    (max-value (reduce #'max puts :key (lambda (put) (length (second put))) :initial-value 0)))
               (setf (rf-index fixture) index (rf-scope fixture) scope (rf-cache fixture) cache
                     (rf-epochs fixture) epochs (rf-snapshots fixture) snapshots
                     (rf-snapshot fixture) (m:crea-contesto-snapshot snapshots)
                     (rf-view fixture) (g:crea-vista-get-serie scope index cache identity)
                     (rf-context fixture) (g:crea-contesto-get scope 0 :record-bytes record-bytes
                                                           :budget-payload (+ record-bytes 152))
                     (rf-output fixture) (resolver-octets (+ max-value 6) +resolver-sentinel+)
                     (rf-manifest fixture) (resolver-reference-manifest 17 end version)
                     (rf-root fixture) (resolver-fresh-root))
               (let* ((path (merge-pathnames "segment-17.tmp" (rf-root fixture)))
                      (writer (io:crea-temporaneo path)))
                 (setf (rf-path fixture) path)
                 (unwind-protect
                      (progn
                        (when image-transform (funcall image-transform image))
                        (io:append-esatto writer image 0 (length image)) (io:durable-flush writer))
                   (io:chiudi writer))
                 (setf (rf-file fixture)
                       (io:apri-lettura path :backend (resolver-observed-backend (rf-observer fixture)))))
               (when build-p (resolver-build-map fixture))
               (dotimes (ordinal count) (resolver-publish fixture ordinal))
               (resolver-clear-reads fixture)
               (setf ready t)
               fixture)))
      (unless ready (close-resolver-fixture fixture)))))

(defmacro with-resolver-fixture ((fixture &rest options) &body body)
  `(let ((,fixture (make-resolver-fixture ,@options)))
     (unwind-protect (progn ,@body) (close-resolver-fixture ,fixture))))
(defun resolver-register-snapshot (fixture &optional (now 10))
  (setf (rf-generation fixture) (nth-value 0 (m:registra-snapshot (rf-snapshot fixture) now))))
(defun resolver-begin (fixture ordinal &key (now 11) (snapshot-p (plusp (rf-generation fixture))))
  (g:avvia-get (rf-context fixture) (rf-view fixture) (aref (rf-keys fixture) ordinal)
               (when snapshot-p (rf-snapshot fixture)) (if snapshot-p (rf-generation fixture) 0) now))
(defun resolver-clean-p (fixture &optional (state :idle))
  "Stato privato usato soltanto come witness di cleanup, mai come oracolo di valore."
  (let ((context (rf-context fixture)))
    (and (eq state (g:stato-contesto-get context))
         (not (e:epoca-attiva-p (e:contesto-epoca (rf-epochs fixture) 0)))
         (null (g::contesto-get-view context)) (null (g::contesto-get-key context))
         (not (g::contesto-get-snapshot-p context))
         (zerop (g::contesto-get-value-start context)) (zerop (g::contesto-get-value-end context))
         (every #'zerop (g::contesto-get-content context)) (every #'zerop (g::contesto-get-limit context)))))
(defun resolver-copy-and-finish (fixture ordinal &key (now 12))
  "Copia output privato e controlla ogni byte/sentinella; ritorna T dopo autorizzazione."
  (let* ((value (aref (rf-values fixture) ordinal)) (output (rf-output fixture))
         (end (+ +resolver-output-start+ (length value))))
    (fill output +resolver-sentinel+)
    (is (= end (g:copia-valore-get (rf-context fixture) output +resolver-output-start+)))
    (multiple-value-bind (result size) (g:concludi-get (rf-context fixture) now)
      (is (eq :found result)) (is (= size (length value))))
    (is (loop for i below +resolver-output-start+ always (= +resolver-sentinel+ (aref output i))))
    (is (loop for i below (length value) always (= (aref value i) (aref output (+ 3 i)))))
    (is (loop for i from end below (length output) always (= +resolver-sentinel+ (aref output i))))
    (is (resolver-clean-p fixture))
    t))
