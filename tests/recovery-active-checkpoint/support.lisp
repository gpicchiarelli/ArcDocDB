;;;; C4 RECOVERY ACTIVE: namespace 0700, file <=4096 byte, deadline seriale 30s.
;;;; OWNER: CT registra tutti i FD/leaf e conserva la causa originale nel cleanup.
;;;; PRE: identita Archivio e completezza del suo log sono fatti dichiarati della fixture.
;;;; Nessun inventario globale o wrapper/tabella di prodotto fabbricati; nessun override globale.
(defpackage #:arcdocdb.recovery.active.checkpoint.tests
  (:use #:cl)
  (:local-nicknames (#:ra #:arcdocdb.recovery.active) (#:ct #:arcdocdb.control.tests)
                   (#:rt #:arcdocdb.recovery.tests) (#:io #:arcdocdb.io)
                   (#:c #:arcdocdb.control) (#:g #:arcdocdb.get)
                   (#:d #:arcdocdb.recovery.decisions))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:corruption-detected #:invariant-violation #:unsupported-format
                #:io-fault #:error-reason #:error-offset)
  (:export #:run))
(in-package #:arcdocdb.recovery.active.checkpoint.tests)
(declaim (optimize (safety 3) (speed 2) (debug 3)))

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*))
    (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test RECOVERY ACTIVE superati.~%" (length *tests*))
  t)

(defstruct (ra-case (:constructor %ra-case))
  native deadline path directory identity archive-identity view version (id 9)
  control control-input control-bytes input append bytes prefix layouts decisions
  decision-input decision-bytes decision-specs scratch initial-observations)

(defun ra-octets (sequence)
  (is (<= (length sequence) 4096))
  (let ((copy (ct::zeros (length sequence)))) (replace copy sequence) copy))

(defun ra-record (kind stamp &key (flags (if (member kind '(:prepared-put :prepared-tombstone)) 1 0))
                                (key #(11 22)) (value #(161 178 195)) (csn 0))
  "Spec fredda: frame24+K+V, nessun padding, identico per chiavi piccole v1/v2."
  (let ((wire-kind (ecase kind ((:put :prepared-put) 1)
                             ((:tombstone :prepared-tombstone) 2) (:outcome 4))))
    (list :kind wire-kind :flags flags :stamp stamp
          :key (ra-octets (if (eq kind :outcome) #() key))
          :value (if (eq kind :outcome)
                     (ct::control-pack (ct::zeros 8) 0 csn 8)
                     (ra-octets (if (= wire-kind 2) #() value))))))

(defun ra-batch (csn &rest records)
  "SEAL CSN esplicito; :DURABLE opzionale nella plist, default START assoluto."
  (list :csn csn :records records))

(defun ra-decision (txid csn &optional (participants '(:self :other)))
  "Solo fatti della fixture; :SELF e :OTHER vengono sostituiti prima del packing."
  (list txid csn participants))

(defun ra-encode-record (spec version)
  (let ((key (getf spec :key)) (value (getf spec :value)))
    (is (<= (+ 24 (length key) (length value)) 4096))
    (rt::reference-record (getf spec :kind) (getf spec :stamp) key value
                          :version version :flags (getf spec :flags))))

(defun ra-seal (records start durable csn version)
  "Packing e CRC bitwise gia qualificati RT/CT; file-id ACTIVE9, non zero."
  (let ((body (ct::zeros 32)) (checksum 0))
    (dolist (record records)
      (setf checksum (rt::reference-crc record 0 4 checksum)))
    (ct::control-pack body 0 9 8) (ct::control-pack body 8 start 8)
    (ct::control-pack body 16 durable 8)
    (ct::control-pack body 24 (length records) 4)
    (ct::control-pack body 28 checksum 4)
    (rt::reference-record 3 csn #() body :version version)))

(defun ra-active-bytes (version identity batches)
  "Layout assoluti indipendenti: start, records, seal, end; EOF include solo byte dichiarati."
  (let ((header (ct::control-reference-header identity version t))
        (chunks nil) (layouts nil) (position 64))
    (ct::control-pack header 32 9 8)
    (ct::control-pack header 56 (ct::control-crc header 0 56) 4)
    (push header chunks)
    (dolist (batch batches)
      (let ((start position) (offsets nil)
            (records (mapcar (lambda (spec) (ra-encode-record spec version)) (getf batch :records))))
        (dolist (record records)
          (push position offsets) (push record chunks) (incf position (length record)))
        (let* ((seal-start position)
               (seal (ra-seal records start (getf batch :durable start) (getf batch :csn) version)))
          (push seal chunks) (incf position (length seal))
          (is (<= position 4096))
          (push (list :start start :records (nreverse offsets) :seal seal-start :end position) layouts))))
    (values (apply #'ct::crr-cat (nreverse chunks)) (nreverse layouts))))

(defun ra-decision-log (version archive-id identity specs)
  "Un intero multiserie.log della fixture; header MSL1 e tutti i SEAL, anche log vuoto."
  (let* ((resolved (mapcar (lambda (spec)
                           (destructuring-bind (txid csn participants) spec
                             (list txid csn
                                   (mapcar (lambda (id)
                                             (case id (:self (copy-seq identity))
                                                   (:other (rt::participant-id 999 128))
                                                   (otherwise (ra-octets id)))) participants)))) specs))
         (header (ct::control-reference-header archive-id version)))
    (is (<= (length resolved) 16))
    (dolist (spec resolved) (is (<= (length (third spec)) 8)))
    (ct::control-pack header 4 #x314c534d 4)
    (ct::control-pack header 56 (ct::control-crc header 0 56) 4)
    (multiple-value-bind (bytes start end)
        (rt::decision-log-fixture (when resolved (list resolved))
                                  :version version :prefix 64 :file-offset 0)
      (is (= start 64)) (is (= end (length bytes))) (is (<= end 4096))
      (replace bytes header)
      (values bytes resolved))))

(defun ra-control (native directory path view identity version deadline)
  "Seed canonico C4 prima del freeze: poi soltanto il decoder pubblico CONTROL."
  (let* ((bytes (ct::control-reference-checkpoint identity version (ct::rp-previous-payload) 19))
         (target (ct::native-leaf native path "control.log")))
    (ct::rp-seed native path "control-seed.tmp" bytes deadline)
    (ct::native-seconds-left deadline :control-seed-rename)
    (sb-posix:rename (namestring (merge-pathnames "control-seed.tmp" path)) (namestring target))
    (ct::native-bounded deadline :control-seed-directory (lambda () (io:durable-flush directory)))
    (let* ((input (ct::native-open native target :input deadline))
           (control (ct::rp-read native view input bytes (length bytes) :complete version deadline)))
      (values control input bytes))))

(defun ra-decode-decisions (native input expected archive-id version deadline)
  "Lettura reale fino al FSTAT EOF; tabella sempre ricostruita, mai NIL/constructor privato."
  (let ((bytes (ct::native-read-bytes input expected deadline)))
    (multiple-value-bind (start actual-version)
        (arcdocdb.storage.format:verifica-header-log bytes 0 (length bytes) :multiserie archive-id)
      (is (= start 64)) (is (= actual-version version))
      (multiple-value-bind (table prefix status)
          (ct::native-bounded deadline :decision-decode
            (lambda () (d:ricostruisci-decisioni bytes start (length bytes)
                          :version actual-version :file-offset 0 :file-size (length bytes)
                          :max-bytes 4096 :max-batches 1 :max-batch-records 16
                          :max-batch-bytes 4096 :max-search-bytes 4096
                          :max-decisions 16 :max-participants 128 :max-participants-per-decision 8)))
        (is (= prefix (length bytes))) (is (eq status :complete))
        (is (eq (io::file-backend input) (ct::native-fixture-backend native)))
        table))))

(defun ra-observations (case)
  "FD, flags, stato, inode, EOF, offset POSIX e frontiere; nessun contatore che cambia con le read."
  (ct::rp-observations (ra-case-native case)))
(defun ra-calls (case)
  (copy-seq (ct::native-observer-calls (ct::native-fixture-observer (ra-case-native case)))))
(defun ra-reset-calls (case)
  (ct::native-reset-calls (ra-case-native case)))
(defun ra-no-writes (case)
  "Assertion: nessuna open/write/flush/close/entry/rename; pread e identity sono lecite."
  (let ((calls (ra-calls case)))
    (dolist (index '(0 2 3 4 5 7 8)) (is (zerop (aref calls index))))))

(defun ra-check-bytes (case)
  "Oracoli nativi aggiungono pread veri: nessun reset o ripristino dei contatori."
  (let ((before (ra-observations case)) (deadline (ra-case-deadline case)))
    (ct::native-read-bytes (ra-case-control-input case) (ra-case-control-bytes case) deadline)
    (ct::native-read-bytes (ra-case-input case) (ra-case-bytes case) deadline)
    (ct::native-read-bytes (ra-case-decision-input case) (ra-case-decision-bytes case) deadline)
    (is (equal before (ra-observations case)))
    (is (equal before (ra-case-initial-observations case)))))

(defun ra-read (case &rest options)
  "Solo API pubblica, EOF della fixture e scratch con sette canary oltre EOF; nessun reset implicito."
  (ct::native-bounded (ra-case-deadline case) :active-recovery-read
    (lambda ()
      (apply #'ra:leggi-active-recuperato (ra-case-control case) (ra-case-input case)
             (length (ra-case-bytes case)) (ra-case-decisions case) (ra-case-scratch case)
             (append options '(:chunk-bytes 31 :max-bytes 4096 :max-batches 16
                               :max-batch-records 32 :max-batch-bytes 4096 :max-records 64
                               :max-prepared 32 :max-outcomes 32))))))

(defun ra-setup (native deadline version batches decisions tail mutate)
  "Tutte le modifiche C4 precedono THUNK; la namespace poi resta stabile durante le letture."
  (let* ((path (ct::native-fixture-root native))
         (directory (ct::native-open native path :directory deadline))
         (identity (ct::crr-uuid)) (archive-id (rt::participant-id 77 64))
         (view (ct::native-view identity)))
    (multiple-value-bind (control control-input control-bytes)
        (ra-control native directory path view identity version deadline)
      (multiple-value-bind (prefix-bytes layouts) (ra-active-bytes version identity batches)
        (let* ((prefix (length prefix-bytes))
               (bytes (ct::crr-cat prefix-bytes (ra-octets (or tail #())))))
          (when mutate (funcall mutate bytes layouts))
          (multiple-value-bind (input append) (ct::rp-seed native path "active-9.tmp" bytes deadline)
            (multiple-value-bind (decision-bytes specs) (ra-decision-log version archive-id identity decisions)
              (let* ((decision-input (ct::rp-seed native path "multiserie.log.tmp" decision-bytes deadline))
                     (case (%ra-case :native native :deadline deadline :path path :directory directory
                                     :identity identity :archive-identity archive-id :view view :version version
                                     :control control :control-input control-input :control-bytes control-bytes
                                     :input input :append append :bytes bytes :prefix prefix :layouts layouts
                                     :decisions (ra-decode-decisions native decision-input decision-bytes archive-id version deadline)
                                     :decision-input decision-input :decision-bytes decision-bytes :decision-specs specs
                                     :scratch (make-array (+ 7 (length bytes)) :element-type '(unsigned-byte 8)
                                                          :initial-element #xcc))))
                (is (not (equal (ct::native-identity input) (ct::native-identity control-input))))
                (is (eq (io::file-backend input) (io::file-backend control-input)))
                (setf (ra-case-initial-observations case) (ra-observations case))
                (ra-reset-calls case)
                case))))))))

(defun ra-with-case (version batches decisions thunk &key tail mutate)
  "CT serial30s/4096B et registres/cleanup, y compris setup partiel et sortie non locale."
  (ct::rp-run
   (lambda (native deadline)
     (funcall thunk (ra-setup native deadline version batches decisions tail mutate) deadline))))
