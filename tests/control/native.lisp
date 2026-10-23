;;;; Prove funzionali C4 di checkpoint e pubblicazione su file reali v1/v2.
;;;; Nessuna attestazione di prestazioni, zero heap, power loss o motore completo.
;;; OWNER: una root 0700 e tutti i suoi FD per fixture; un solo worker per fixture.
;;; SHARED: solo gate bounded; il controller riprende le risorse dopo tutti i join.
(in-package #:arcdocdb.control.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +native-workers+ 4)
(defconstant +native-rounds+ 4)
(defconstant +native-file-limit+ 128)
(defconstant +native-leaf-limit+ 64)
(defconstant +native-directory-limit+ 16)
(defconstant +native-byte-limit+ 4096)

(define-condition native-fixture-timeout (error)
  ((phase :initarg :phase :reader native-fixture-timeout-phase))
  (:report (lambda (condition stream)
             (format stream "Fixture CONTROL native: timeout nella fase ~S."
                     (native-fixture-timeout-phase condition)))))

(defstruct (native-observer (:constructor native-make-observer))
  "Contatori e iniezione posseduti da un solo worker, letti dal controller dopo join."
  (calls (make-array 9 :element-type 'fixnum :initial-element 0)
         :type (simple-array fixnum (9)) :read-only t)
  (directory-failure nil :type (or null condition)))

(defstruct (native-fixture (:constructor %native-make-fixture (root observer backend)))
  "Registri bounded C4: nessuna scansione o rimozione fuori dalla root posseduta."
  (root #p"/" :type pathname :read-only t)
  (observer nil :type native-observer :read-only t)
  (backend nil :type io::backend :read-only t)
  (files nil :type list)
  (leaves nil :type list)
  (directories nil :type list)
  (quiescent-p t :type boolean))

(defstruct (native-checkpoint (:constructor native-make-checkpoint (plan prepared input append bytes)))
  "Risultato delle factory reali e copia dei byte attesi prima della scrittura."
  (plan nil :type c:checkpoint-control :read-only t)
  (prepared nil :type c:control-preparato :read-only t)
  (input nil :type io:file-io :read-only t)
  (append nil :type io:file-io :read-only t)
  (bytes #() :type arcdocdb.binary:octets :read-only t))

(defstruct (native-case (:constructor native-make-case
                           (path directory identity version next-id active old new previous old-observations)))
  "Stato iniziale dichiarato; non fabbrica né modifica wrapper di prodotto."
  (path #p"/" :type pathname :read-only t)
  (directory nil :type io:file-io :read-only t)
  (identity #() :type arcdocdb.binary:octets :read-only t)
  (version 2 :type (member 1 2) :read-only t)
  (next-id 31 :type arcdocdb.binary:u64 :read-only t)
  (active nil :type a:segmento-attivo-preparato :read-only t)
  (old nil :type native-checkpoint :read-only t)
  (new nil :type native-checkpoint :read-only t)
  (previous nil :type io:file-io :read-only t)
  (old-observations nil :type list :read-only t))

(defun native-deadline (seconds)
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))

(defun native-seconds-left (deadline phase)
  (let ((ticks (- deadline (get-internal-real-time))))
    (unless (plusp ticks) (error 'native-fixture-timeout :phase phase))
    (/ ticks (float internal-time-units-per-second 1d0))))

(defun native-bounded (deadline phase thunk)
  "Timer su operazioni con capacità già registrate; mai interrompe un'apertura."
  (handler-case
      (sb-ext:with-timeout (native-seconds-left deadline phase) (funcall thunk))
    (sb-ext:timeout () (error 'native-fixture-timeout :phase phase))))

(defun native-wait (gate deadline phase &optional (count 1))
  (unless (sb-thread:wait-on-semaphore
           gate :n count :timeout (native-seconds-left deadline phase))
    (error 'native-fixture-timeout :phase phase))
  nil)

(defun native-observed-backend (observer)
  "Tutti gli adattatori sono nativi; iniezione locale solo sul fsync della directory."
  (let ((calls (native-observer-calls observer)))
    (io:make-backend
     (lambda (path mode) (incf (aref calls 0)) (io::native-open path mode))
     (lambda (fd bytes start count offset)
       (incf (aref calls 1)) (io::native-read fd bytes start count offset))
     (lambda (fd bytes start count)
       (incf (aref calls 2)) (io::native-write fd bytes start count))
     (lambda (fd) (incf (aref calls 3)) (io::native-flush fd))
     (lambda (fd)
       (incf (aref calls 4))
       (let ((failure (native-observer-directory-failure observer)))
         (when failure (error failure)))
       (io::native-directory-flush fd))
     (lambda (fd) (incf (aref calls 5)) (io::native-close fd))
     :identity (lambda (fd) (incf (aref calls 6)) (io::native-identity fd))
     :entry-identity (lambda (fd leaf)
                       (incf (aref calls 7)) (io::native-entry-identity fd leaf))
     :rename (lambda (fd source target)
               (incf (aref calls 8)) (io::native-replace fd source target)))))

(defun native-fresh-root (deadline)
  "Al massimo 1000 mkdir esclusivi; EEXIST non attribuisce proprietà sul percorso."
  (loop for attempt below 1000
        for path = (merge-pathnames
                    (format nil "arcdocdb-control-native-~D-~D-~D/"
                            (sb-posix:getpid) (get-universal-time) attempt)
                    (uiop:temporary-directory))
        do (native-seconds-left deadline :mkdir)
           (handler-case
               (progn (sb-posix:mkdir (namestring path) #o700)
                      (return-from native-fresh-root path))
             (sb-posix:syscall-error (condition)
               (unless (= sb-posix:eexist (sb-posix:syscall-errno condition)) (error condition)))))
  (error 'arcdocdb.conditions:resource-exhausted :reason :native-fixture-root))

(defun native-fixture (deadline)
  (let* ((observer (native-make-observer))
         (backend (native-observed-backend observer))
         (root (native-fresh-root deadline)) (complete nil))
    (unwind-protect
         (progn
           (is (= #o700 (logand #o777 (sb-posix:stat-mode (sb-posix:stat root)))))
           (prog1 (%native-make-fixture root observer backend) (setf complete t)))
      (unless complete (sb-posix:rmdir (namestring root))))))

(defun native-register-directory (fixture path)
  (unless (member path (native-fixture-directories fixture) :test #'equal)
    (is (< (length (native-fixture-directories fixture)) +native-directory-limit+))
    (push path (native-fixture-directories fixture)))
  path)

(defun native-directory (fixture name deadline)
  (let ((path (native-register-directory
               fixture (merge-pathnames name (native-fixture-root fixture)))))
    (native-seconds-left deadline :mkdir)
    (sb-posix:mkdir (namestring path) #o700)
    (is (= #o700 (logand #o777 (sb-posix:stat-mode (sb-posix:stat path)))))
    path))

(defun native-leaf (fixture directory name)
  "Il nome posseduto è registrato prima di create, rename, link o symlink."
  (let ((path (merge-pathnames name directory)))
    (unless (member path (native-fixture-leaves fixture) :test #'equal)
      (is (< (length (native-fixture-leaves fixture)) +native-leaf-limit+))
      (push path (native-fixture-leaves fixture)))
    path))

(defun native-open (fixture path mode deadline &optional (backend (native-fixture-backend fixture)))
  "Prenota la registrazione prima dell'apertura; capacità registrata prima degli effetti sui dati.
Nessun timer/terminate-thread attraversa l'apertura o il trasferimento di ownership."
  (native-seconds-left deadline :open)
  (is (< (length (native-fixture-files fixture)) +native-file-limit+))
  (let ((slot (list nil)))
    (push slot (native-fixture-files fixture))
    (setf (car slot)
          (ecase mode
            (:input (io:apri-lettura path :backend backend :max-transfer +native-byte-limit+))
            (:append (io:crea-temporaneo path :backend backend
                                        :max-transfer +native-byte-limit+
                                        :max-file-bytes +native-byte-limit+))
            (:directory (io:apri-directory path :backend backend))))
    (car slot)))

(defun native-identity (file)
  "Oracolo POSIX C4 sui FD, indipendente dai callback di prodotto."
  (let ((stat (sb-posix:fstat (io::file-fd file))))
    (list (sb-posix:stat-dev stat) (sb-posix:stat-ino stat))))

(defun native-path-identity (path)
  (let ((stat (sb-posix:lstat (namestring path))))
    (is (sb-posix:s-isreg (sb-posix:stat-mode stat)))
    (list (sb-posix:stat-dev stat) (sb-posix:stat-ino stat))))

(defun native-observation (file)
  "La dimensione fisica della directory può cambiare con rename: non è una frontiera del log."
  (let ((directory-p (eq (io:mode-file file) :directory)))
    (list (io:stato-file file) (io:posizione-scritta file) (io:posizione-durevole file)
          (if directory-p :directory (sb-posix:lseek (io::file-fd file) 0 sb-posix:seek-cur))
          (native-identity file)
          (if directory-p :directory (sb-posix:stat-size (sb-posix:fstat (io::file-fd file)))))))

(defun native-read-bytes (file expected deadline)
  (let ((actual (zeros (length expected))))
    (is (<= (length expected) +native-byte-limit+))
    (is (= (length expected) (sb-posix:stat-size (sb-posix:fstat (io::file-fd file)))))
    (let ((end (native-bounded deadline :read
                (lambda () (io:leggi-esatto file actual 0 (length actual) 0)))))
      (is (= end (length expected))))
    (is (equalp expected actual))
    actual))

(defun native-absent (path)
  (handler-case
      (progn (sb-posix:lstat (namestring path))
             (error 'arcdocdb.conditions:invariant-violation :reason :native-unexpected-leaf))
    (sb-posix:syscall-error (condition)
      (is (= sb-posix:enoent (sb-posix:syscall-errno condition)))))
  nil)

(defun native-view (identity)
  "Configurazione reale privata: EBR, snapshot e indice piccoli, nessun GET in corso."
  (let* ((csns (arcdocdb.csn:crea-registro-csn :capacity 1))
         (snapshots (arcdocdb.mvcc:crea-registro-snapshot csns 1 100 10))
         (epochs (arcdocdb.epochs:crea-registro-epoche 1 1))
         (scope (g:crea-ambito-get epochs snapshots))
         (primary (arcdocdb.index.primary:crea-indice-primario
                   :capacity 16 :arena-bytes 2048 :hash-seed-high 23 :hash-seed-low 29)))
    (g:crea-vista-get-serie scope primary nil identity)))

(defun native-active (fixture directory path view id version deadline)
  (let* ((leaf (native-leaf fixture path (format nil "active-~D.tmp" id)))
         (append (native-open fixture leaf :append deadline))
         (input (native-open fixture leaf :input deadline))
         (header (zeros 64)) (scratch (zeros 64)))
    (native-bounded deadline :active
      (lambda () (a:prepara-segmento-attivo view input append directory id 17
                                          header scratch :version version)))))

(defun native-payload (active next-id &optional previous-p)
  "Fatti dichiarati: nuovo CLOSED 2/128 con (101,201)/(102,0), CLOSED 7/64, REMOVED 3.
Non attesta l'inventario dei file CLOSED: verifica il contenuto del checkpoint CONTROL."
  (let* ((closed (zeros (if previous-p 20 72)))
         (removed (zeros (if previous-p 0 8)))
         (payload (zeros (+ 24 (length closed) (length removed)))))
    (arcdocdb.binary:scrivi-u64 closed 0 2)
    (arcdocdb.binary:scrivi-u64 closed 8 (if previous-p 64 128))
    (unless previous-p
      (arcdocdb.binary:scrivi-u32 closed 16 2)
      (arcdocdb.binary:scrivi-u64 closed 20 101)
      (arcdocdb.binary:scrivi-u64 closed 28 201)
      (arcdocdb.binary:scrivi-u64 closed 36 102)
      (arcdocdb.binary:scrivi-u64 closed 44 0)
      (arcdocdb.binary:scrivi-u64 closed 52 7)
      (arcdocdb.binary:scrivi-u64 closed 60 64)
      (arcdocdb.binary:scrivi-u64 removed 0 3))
    (let ((end (arcdocdb.storage.format:scrivi-valore-edit
                payload 0 next-id active closed (if previous-p 1 2) removed :completo t)))
      (is (= end (length payload))))
    payload))

(defun native-prepare-plan (fixture path directory name plan deadline)
  (let* ((leaf (native-leaf fixture path name))
         (append (native-open fixture leaf :append deadline))
         (input (native-open fixture leaf :input deadline))
         (expected (copy-seq (c::checkpoint-control-bytes plan)))
         (prepared (native-bounded deadline :checkpoint
                     (lambda () (c:prepara-checkpoint-control
                                 plan input append directory (zeros 37) :chunk-bytes 37)))))
    (native-make-checkpoint plan prepared input append expected)))

(defun native-check-manifest (manifest active next-id previous-p)
  "Oracolo scalare noto prima della codifica, compreso CSN zero presente."
  (is (= active (arcdocdb.recovery.manifest:segmento-attivo manifest)))
  (is (equal (list t next-id)
             (multiple-value-list (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))
  (is (= (if previous-p 1 2) (arcdocdb.recovery.manifest:numero-segmenti-chiusi manifest)))
  (is (= (if previous-p 0 1) (arcdocdb.recovery.manifest:numero-segmenti-rimossi manifest)))
  (is (equal '(:active 0 0)
             (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest active))))
  (is (equal (if previous-p '(:closed 64 0) '(:closed 128 2))
             (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest 2))))
  (unless previous-p
    (is (equal '(:closed 64 0)
               (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest 7))))
    (is (equal '(:removed 0 0)
               (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest 3))))
    (dolist (outcome '((101 201) (102 0)))
      (is (equal (list t (second outcome))
                 (multiple-value-list
                  (arcdocdb.recovery.manifest:trova-esito-chiusura manifest 2 (first outcome)))))))
  (is (equal '(nil 0)
             (multiple-value-list (arcdocdb.recovery.manifest:trova-esito-chiusura manifest 2 999))))
  (is (equal '(:unknown 0 0)
             (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest 999))))
  nil)

(defun native-recover (file expected identity version active next-id previous-p deadline)
  "Legge il FD riaperto, verifica l'header e usa il recovery reale con EOF e budget espliciti."
  (let ((bytes (native-read-bytes file expected deadline)))
    (native-bounded deadline :recovery
      (lambda ()
        (multiple-value-bind (start actual-version)
            (arcdocdb.storage.format:verifica-header-log bytes 0 (length bytes) :control identity)
          (is (= start 64)) (is (= version actual-version))
          (multiple-value-bind (manifest prefix status)
              (arcdocdb.recovery.manifest:ricostruisci-manifest
               bytes start (length bytes) :version actual-version :file-offset 0
               :file-size (length bytes) :max-bytes +native-byte-limit+
               :max-batches 1 :max-batch-records 1 :max-batch-bytes +native-byte-limit+
               :max-search-bytes +native-byte-limit+ :max-edits 1 :max-segmenti 4 :max-esiti 2
               :max-chiusi-per-edit 2 :max-rimossi-per-edit 1 :max-esiti-per-edit 2
               :max-metadata-bytes +native-byte-limit+)
            (is (= prefix (length bytes))) (is (eq status :complete))
            (native-check-manifest manifest active next-id previous-p)
            manifest))))))

(defun native-setup (fixture path version next-id deadline &optional (identity-base 32))
  "Setup C4: previous canonico preparato dalle factory, rinominato; nuovo ACTIVE sempre 13."
  (let* ((directory (native-open fixture path :directory deadline))
         (identity (zeros 16)))
    (dotimes (i 16) (setf (aref identity i) (+ identity-base i)))
    (let* ((view (native-view identity))
           (old-active (native-active fixture directory path view 9 version deadline))
           (old-plan (c:crea-checkpoint-control old-active (native-payload 9 10 t) 1))
           (old (native-prepare-plan fixture path directory "previous-control.tmp" old-plan deadline))
           (target (native-leaf fixture path "control.log")))
      ;; Solo setup C4: il vecchio checkpoint canonico è preparato dalle factory reali.
      (sb-posix:rename (namestring (merge-pathnames "previous-control.tmp" path)) (namestring target))
      (let ((frontier (native-bounded deadline :seed-fsync
                        (lambda () (io:durable-flush directory)))))
        (is (zerop frontier)))
      (let* ((previous (native-open fixture target :input deadline))
             (active (native-active fixture directory path view 13 version deadline))
             (plan (c:crea-checkpoint-control active (native-payload 13 next-id) next-id))
             (new (native-prepare-plan fixture path directory "control.log.tmp" plan deadline)))
        (native-recover previous (native-checkpoint-bytes old) identity version 9 10 t deadline)
        (is (not (equalp (native-checkpoint-bytes old) (native-checkpoint-bytes new))))
        (is (not (equal (native-identity previous) (native-identity (native-checkpoint-input new)))))
        (native-make-case path directory identity version next-id active old new previous
                          (mapcar #'native-observation
                                  (list previous (native-checkpoint-append old))))))))

(defun native-check-previous (case deadline)
  (let ((old (native-case-old case)) (previous (native-case-previous case)))
    (is (equal (native-case-old-observations case)
               (mapcar #'native-observation (list previous (native-checkpoint-append old)))))
    (native-read-bytes previous (native-checkpoint-bytes old) deadline))
  nil)

(defun native-publication-state (case state observed)
  (is (equal (list state observed)
             (multiple-value-list
              (c:stato-pubblicazione-control (native-checkpoint-prepared (native-case-new case)))))))

(defun native-reset-calls (fixture)
  (fill (native-observer-calls (native-fixture-observer fixture)) 0))

(defun native-check-effects (fixture rename directory-flush)
  "Dopo la chiamata, prima dell'oracolo: nessun open, read, write, flush file o close implicito."
  (let ((calls (native-observer-calls (native-fixture-observer fixture))))
    (dolist (slot '(0 1 2 3 5)) (is (zerop (aref calls slot))))
    (is (= rename (aref calls 8))) (is (= directory-flush (aref calls 4)))))

(defun native-publish (case deadline &optional (previous (native-case-previous case)))
  (native-bounded deadline :publication
    (lambda () (c:pubblica-control-recuperato
                (native-checkpoint-prepared (native-case-new case)) previous))))

(defun native-oracle (fixture case deadline &optional (path (native-case-path case)))
  "Riapre control.log dopo pubblicazione; ricostruisce manifest, verifica identità e vecchio FD."
  (let* ((new (native-case-new case))
         (input (native-open fixture (merge-pathnames "control.log" path) :input deadline)))
    (is (equal (native-identity input) (native-identity (native-checkpoint-input new))))
    (is (equal (native-path-identity (merge-pathnames "control.log" path)) (native-identity input)))
    (native-absent (merge-pathnames "control.log.tmp" path))
    (native-recover input (native-checkpoint-bytes new) (native-case-identity case)
                    (native-case-version case) 13 (native-case-next-id case) nil deadline)
    (native-check-previous case deadline))
  nil)

(defun native-success (fixture case deadline)
  (let* ((new (native-case-new case))
         (before (mapcar #'native-observation
                         (list (native-case-directory case) (native-checkpoint-input new)
                               (native-checkpoint-append new)))))
    (native-reset-calls fixture)
    (let ((published (native-publish case deadline)))
      (is (typep published 'c:control-pubblicato))
      (native-check-effects fixture 1 1)
      (is (equalp (native-observer-calls (native-fixture-observer fixture)) #(0 0 0 0 1 0 3 3 1)))
      (native-publication-state case :published t)
      (is (eq (native-case-active case) (c:active-control-pubblicato published)))
      (is (eq (c:log-control-preparato (native-checkpoint-prepared new))
              (c:log-control-pubblicato published)))
      (native-check-manifest (c:manifest-control-pubblicato published) 13 (native-case-next-id case) nil)
      (is (equal before (mapcar #'native-observation
                               (list (native-case-directory case) (native-checkpoint-input new)
                                     (native-checkpoint-append new)))))
      published)))

(defun native-capture-product-error (thunk)
  "Trasporta la condizione originale; timeout e assert non diventano rifiuti attesi."
  (handler-case (progn (funcall thunk) nil)
    (arcdocdb.conditions:arcdocdb-error (condition) condition)))

(defun native-rejection (fixture case deadline type reason &optional (previous (native-case-previous case)))
  (let* ((files (remove nil (mapcar #'car (native-fixture-files fixture))))
         (before (mapcar #'native-observation files))
         (delivered nil))
    (native-reset-calls fixture)
    (let ((condition (native-capture-product-error
                      (lambda () (setf delivered (native-publish case deadline previous))))))
      (is (typep condition type))
      (is (eq reason (arcdocdb.conditions:error-reason condition)))
      (is (null delivered)))
    (native-check-effects fixture 0 0)
    (is (equal before (mapcar #'native-observation files)))
    (native-publication-state case :faulted nil)
    (native-check-previous case deadline)
    (native-read-bytes (native-checkpoint-input (native-case-new case))
                       (native-checkpoint-bytes (native-case-new case)) deadline))
  nil)

(defun native-remove (path directory-p)
  (handler-case
      (if directory-p (sb-posix:rmdir (namestring path)) (sb-posix:unlink (namestring path)))
    (sb-posix:syscall-error (condition)
      (unless (= sb-posix:enoent (sb-posix:syscall-errno condition)) (error condition)))))

(defun native-cleanup (fixture deadline)
  "Confine C4: tutti i guasti registrati, FD solo dopo quiescenza; nessun percorso scoperto."
  (unless (native-fixture-quiescent-p fixture)
    (error 'arcdocdb.conditions:invariant-violation :reason :native-cleanup-before-join))
  (let ((failures nil))
    (labels ((attempt (thunk)
               (handler-case (funcall thunk)
                 (sb-ext:timeout () (error 'native-fixture-timeout :phase :cleanup))
                 (native-fixture-timeout (condition) (error condition))
                 (error (condition) (push condition failures)))))
      (handler-case
          (native-bounded deadline :cleanup
            (lambda ()
              (dolist (slot (native-fixture-files fixture))
                (when (car slot) (attempt (lambda () (io:chiudi (car slot))))))
              ;; COD-36: solo nomi registrati nella root esclusiva C4, nessuna scansione.
              (dolist (path (native-fixture-leaves fixture))
                (attempt (lambda () (native-remove path nil))))
              (dolist (path (native-fixture-directories fixture))
                (attempt (lambda () (native-remove path t))))
              (attempt (lambda () (native-remove (native-fixture-root fixture) t)))))
        (native-fixture-timeout (condition) (push condition failures))))
    (nreverse failures)))

(defun native-finish (primary cleanup-failures)
  "Non maschera la condizione originale con un guasto di cleanup; registra entrambi al confine C4."
  (dolist (condition cleanup-failures)
    (format *error-output* "CONTROL native cleanup: ~A~%" condition))
  (when primary (error primary))
  (when cleanup-failures (error (first cleanup-failures)))
  nil)

(defun native-run-case (thunk)
  "Confine harness seriale: risorse possedute fino a ritorno/errore, poi cleanup bounded."
  (let* ((deadline (native-deadline 30)) (fixture (native-fixture deadline)) (primary nil))
    (handler-case (funcall thunk fixture deadline)
      (error (condition) (setf primary condition)))
    (native-finish primary (native-cleanup fixture (native-deadline 10)))))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-003 REQ-AFF-001 REQ-AFF-002
(deftest test-REQ-REC-001-CONTROL-NATIVE-success-v1-real-recovery
  (native-run-case
   (lambda (fixture deadline)
     (let ((case (native-setup fixture (native-fixture-root fixture) 1 31 deadline)))
       (native-success fixture case deadline) (native-oracle fixture case deadline)))))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-003 REQ-AFF-001 REQ-AFF-002
(deftest test-REQ-REC-001-CONTROL-NATIVE-success-v2-real-recovery
  (native-run-case
   (lambda (fixture deadline)
     (let ((case (native-setup fixture (native-fixture-root fixture) 2 31 deadline)))
       (native-success fixture case deadline) (native-oracle fixture case deadline)))))

(defun native-write-copy (fixture path bytes deadline)
  "Solo esche C4 canoniche; capacità registrata prima di append e flush reali."
  (let ((file (native-open fixture path :append deadline)))
    (native-bounded deadline :copy
      (lambda ()
        (let ((end (io:append-esatto file bytes 0 (length bytes)))) (is (= end (length bytes))))
        (let ((end (io:durable-flush file))) (is (= end (length bytes))))))
    file))

(defun native-moved-parent (fixture version deadline)
  (let* ((cwd (sb-posix:getcwd))
         (parent (native-directory fixture "parent/" deadline))
         (owned (native-directory fixture "parent/owned/" deadline))
         (case (native-setup fixture owned version 31 deadline))
         (moved (native-register-directory fixture (merge-pathnames "moved/" (native-fixture-root fixture))))
         (moved-owned (native-register-directory fixture (merge-pathnames "owned/" moved))))
    ;; Destinazioni registrate prima dello spostamento degli antenati; FD conservati.
    (dolist (leaf '("active-9.tmp" "active-13.tmp" "previous-control.tmp" "control.log" "control.log.tmp"))
      (native-leaf fixture moved-owned leaf))
    (sb-posix:rename (string-right-trim "/" (namestring parent))
                     (string-right-trim "/" (namestring moved)))
    (native-directory fixture "parent/" deadline)
    (native-directory fixture "parent/owned/" deadline)
    (let* ((seed (native-leaf fixture owned "decoy-target.tmp"))
           (target (native-leaf fixture owned "control.log"))
           (source (native-leaf fixture owned "control.log.tmp")))
      (native-write-copy fixture seed (native-checkpoint-bytes (native-case-old case)) deadline)
      (sb-posix:rename (namestring seed) (namestring target))
      (native-write-copy fixture source (native-checkpoint-bytes (native-case-new case)) deadline)
      (let ((target-id (native-path-identity target)) (source-id (native-path-identity source)))
        (native-success fixture case deadline)
        (native-oracle fixture case deadline moved-owned)
        (is (equal target-id (native-path-identity target)))
        (is (equal source-id (native-path-identity source)))
        (native-read-bytes (native-open fixture target :input deadline)
                           (native-checkpoint-bytes (native-case-old case)) deadline)
        (native-read-bytes (native-open fixture source :input deadline)
                           (native-checkpoint-bytes (native-case-new case)) deadline)))
    (is (string= cwd (sb-posix:getcwd)))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-REC-001-CONTROL-NATIVE-moved-parent-fd-anchored-v1-v2
  (dolist (version '(1 2))
    (native-run-case (lambda (fixture deadline) (native-moved-parent fixture version deadline)))))

(defun native-symlink-case (fixture source-p deadline)
  (let* ((path (native-fixture-root fixture)) (case (native-setup fixture path 2 31 deadline))
         (name (if source-p "control.log.tmp" "control.log"))
         (saved-name (if source-p "source.saved.tmp" "target.saved"))
         (original (native-leaf fixture path name)) (saved (native-leaf fixture path saved-name))
         (before-id (native-path-identity original)))
    (sb-posix:rename (namestring original) (namestring saved))
    (sb-posix:symlink saved-name (namestring original))
    (native-rejection fixture case deadline 'arcdocdb.conditions:io-fault :io-entry-kind)
    (is (sb-posix:s-islnk (sb-posix:stat-mode (sb-posix:lstat (namestring original)))))
    (is (equal before-id (native-path-identity saved)))
    (native-read-bytes (native-open fixture saved :input deadline)
                       (native-checkpoint-bytes (if source-p (native-case-new case) (native-case-old case)))
                       deadline)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-NATIVE-source-symlink-rejected-before-effects
  (native-run-case (lambda (fixture deadline) (native-symlink-case fixture t deadline))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-NATIVE-target-symlink-rejected-before-effects
  (native-run-case (lambda (fixture deadline) (native-symlink-case fixture nil deadline))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-FOR-001
(deftest test-REQ-AFF-008-CONTROL-NATIVE-source-name-mismatch-identical-bytes
  (native-run-case
   (lambda (fixture deadline)
     (let* ((path (native-fixture-root fixture)) (case (native-setup fixture path 2 31 deadline))
            (saved (native-leaf fixture path "displaced-source.tmp"))
            (source (native-leaf fixture path "control.log.tmp"))
            (new (native-case-new case)) (target-id (native-path-identity (merge-pathnames "control.log" path))))
       (sb-posix:rename (namestring source) (namestring saved))
       (let ((replacement (native-prepare-plan fixture path (native-case-directory case)
                                               "control.log.tmp" (native-checkpoint-plan new) deadline)))
         (is (equalp (native-checkpoint-bytes new) (native-checkpoint-bytes replacement)))
         (is (not (equal (native-identity (native-checkpoint-input new)) (native-path-identity source))))
         (native-rejection fixture case deadline 'arcdocdb.conditions:invalid-argument :io-replacement-identity)
         (is (equal target-id (native-path-identity (merge-pathnames "control.log" path))))
         (is (equal (native-identity (native-checkpoint-input replacement)) (native-path-identity source))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-FOR-001
(deftest test-REQ-AFF-008-CONTROL-NATIVE-wrong-previous-other-inode-identical-bytes
  (native-run-case
   (lambda (fixture deadline)
     (let* ((path (native-fixture-root fixture)) (case (native-setup fixture path 2 31 deadline))
            (old (native-case-old case))
            (wrong (native-prepare-plan fixture path (native-case-directory case)
                                        "other-target.tmp" (native-checkpoint-plan old) deadline))
            (source-id (native-path-identity (merge-pathnames "control.log.tmp" path)))
            (target-id (native-path-identity (merge-pathnames "control.log" path))))
       (is (equalp (native-checkpoint-bytes old) (native-checkpoint-bytes wrong)))
       (is (not (equal target-id (native-identity (native-checkpoint-input wrong)))))
       (native-rejection fixture case deadline 'arcdocdb.conditions:invalid-argument
                         :io-replacement-identity (native-checkpoint-input wrong))
       (is (equal source-id (native-path-identity (merge-pathnames "control.log.tmp" path))))
       (is (equal target-id (native-path-identity (merge-pathnames "control.log" path))))
       (native-read-bytes (native-checkpoint-input wrong) (native-checkpoint-bytes old) deadline)))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-NATIVE-hardlink-alias-rejected-before-effects
  (native-run-case
   (lambda (fixture deadline)
     (let* ((path (native-fixture-root fixture)) (case (native-setup fixture path 2 31 deadline))
            (source (native-leaf fixture path "control.log.tmp"))
            (target (native-leaf fixture path "control.log"))
            (saved (native-leaf fixture path "previous.saved")))
       (sb-posix:rename (namestring target) (namestring saved))
       (sb-posix:link (namestring source) (namestring target))
       (let ((alias (native-open fixture target :input deadline)) (identity (native-path-identity source)))
         (is (equal identity (native-identity alias)))
         (is (/= (io::file-fd alias) (io::file-fd (native-checkpoint-input (native-case-new case)))))
         (native-rejection fixture case deadline 'arcdocdb.conditions:invalid-argument :io-replacement-alias alias)
         (is (equal identity (native-path-identity source)))
         (is (equal identity (native-path-identity target))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-NATIVE-backend-mismatch-preflight-keeps-prepared
  (native-run-case
   (lambda (fixture deadline)
     (let* ((path (native-fixture-root fixture)) (case (native-setup fixture path 2 31 deadline))
            (wrong (native-open fixture (merge-pathnames "control.log" path) :input deadline nil))
            (delivered nil))
       (native-reset-calls fixture)
       (let ((condition (native-capture-product-error
                         (lambda () (setf delivered (native-publish case deadline wrong))))))
         (is (typep condition 'arcdocdb.conditions:invalid-argument))
         (is (eq :io-identity-backend (arcdocdb.conditions:error-reason condition)))
         (is (null delivered)))
       (is (every #'zerop (native-observer-calls (native-fixture-observer fixture))))
       (native-publication-state case :prepared nil)
       (native-check-previous case deadline)))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-NATIVE-fsync-failure-after-rename-no-wrapper-readable-file
  (native-run-case
   (lambda (fixture deadline)
     (let* ((case (native-setup fixture (native-fixture-root fixture) 2 31 deadline))
            (observer (native-fixture-observer fixture))
            (failure (make-condition 'sb-posix:syscall-error :errno sb-posix:eio :name 'native-injected-fsync))
            (observed nil) (delivered nil))
       (setf (native-observer-directory-failure observer) failure)
       (native-reset-calls fixture)
       (let ((condition (native-capture-product-error
                         (lambda ()
                           (handler-bind ((arcdocdb.conditions:io-fault
                                           (lambda (original) (setf observed original))))
                             (setf delivered (native-publish case deadline)))))))
         (is (typep condition 'arcdocdb.conditions:io-fault))
         (is (eq condition observed))
         (is (eq :io-syscall (arcdocdb.conditions:error-reason condition)))
         (is (eq :flush (arcdocdb.conditions:error-operation condition)))
         (is (= sb-posix:eio (arcdocdb.conditions:error-errno condition)))
         (is (null delivered)))
       (native-check-effects fixture 1 1)
       (native-publication-state case :faulted t)
       (is (eq :faulted (io:stato-file (native-case-directory case))))
       (setf (native-observer-directory-failure observer) nil)
       (native-oracle fixture case deadline)
       ;; Leggibilità immediata dopo rename, senza prova di durability dopo il fsync fallito.
       (native-reset-calls fixture)
       (let ((condition (native-capture-product-error (lambda () (native-publish case deadline)))))
         (is (typep condition 'arcdocdb.conditions:invalid-argument))
         (is (eq :control-publication-state (arcdocdb.conditions:error-reason condition))))
       (is (every #'zerop (native-observer-calls observer)))))))

(defun native-worker (fixture cases ready start entered proceed deadline)
  "Confine worker: nessuna close o cleanup; ritorna la condizione originale, inclusi timeout."
  (let ((ready-p nil) (entered-p nil))
    (handler-case
        (progn
          (setf ready-p t) (sb-thread:signal-semaphore ready)
          (native-wait start deadline :worker-start)
          (dotimes (round +native-rounds+)
            (native-seconds-left deadline :round)
            (let ((case (aref cases round)))
              (native-success fixture case deadline)
              (native-oracle fixture case deadline))
            (when (zerop round)
              (setf entered-p t) (sb-thread:signal-semaphore entered)
              (native-wait proceed deadline :worker-proceed)))
          :ok)
      (error (condition)
        (unless ready-p (sb-thread:signal-semaphore ready))
        (unless entered-p (sb-thread:signal-semaphore entered))
        condition))))

(defun native-collect-workers (threads deadline)
  "Raccoglie tutti i worker prima di propagare/chiudere; senza quiescenza trattiene ogni FD."
  (let ((failures nil) (timeout-marker (gensym "NATIVE-JOIN-")))
    (dolist (thread threads)
      (let* ((seconds (max 0d0 (/ (- deadline (get-internal-real-time))
                                  (float internal-time-units-per-second 1d0))))
             (result (handler-case
                         (sb-thread:join-thread thread :timeout seconds :default timeout-marker)
                       ;; Confine controller: anche un errore di join non salta gli altri worker.
                       (error (condition) condition))))
        (cond
          ((eq result timeout-marker)
           (push (make-condition 'native-fixture-timeout :phase :join) failures))
          ((typep result 'error) (push result failures))
          ((eq result :ok) nil)
          (t (push (make-condition 'arcdocdb.conditions:invariant-violation
                                  :reason :native-worker-result) failures)))))
    (values (nreverse failures) (notany #'sb-thread:thread-alive-p threads))))

(defun native-check-workers-open (fixtures)
  (dotimes (worker +native-workers+)
    (let ((fixture (aref fixtures worker)))
      (is (zerop (aref (native-observer-calls (native-fixture-observer fixture)) 5)))
      (dolist (slot (native-fixture-files fixture))
        (is (typep (car slot) 'io:file-io))
        (is (eq :open (io:stato-file (car slot))))
        (is (not (minusp (sb-posix:fcntl (io::file-fd (car slot)) sb-posix:f-getfd)))))))
  nil)

(defun native-prepare-workers (fixtures cases deadline)
  "Prepara quattro namespace indipendenti prima di affidare le capacità ai worker."
  (dotimes (worker +native-workers+)
    (let* ((fixture (native-fixture deadline))
           (rounds (make-array +native-rounds+ :initial-element nil)))
      (setf (aref fixtures worker) fixture (aref cases worker) rounds)
      (dotimes (round +native-rounds+)
        (let ((path (native-directory fixture (format nil "round-~D/" round) deadline)))
          (setf (aref rounds round)
                (native-setup fixture path (if (evenp (+ worker round)) 1 2)
                              (+ 31 (* worker 4) round) deadline (+ 32 (* worker 16))))))))
  (is (= +native-workers+
         (length (remove-duplicates (map 'list #'native-fixture-root fixtures) :test #'equal))))
  nil)

(defun native-start-workers (fixtures cases threads ready start entered proceed deadline)
  "La lista mutabile dei thread appartiene al controller, mai ai worker."
  (dotimes (worker +native-workers+)
    (let ((id worker))
      (setf (native-fixture-quiescent-p (aref fixtures id)) nil)
      (push (sb-thread:make-thread
             (lambda () (native-worker (aref fixtures id) (aref cases id)
                                       ready start entered proceed deadline))
             :name (format nil "CONTROL native private worker ~D" id)) (car threads))))
  nil)

(defun native-parallel ()
  (let ((fixtures (make-array +native-workers+ :initial-element nil))
        (cases (make-array +native-workers+ :initial-element nil)) (threads (list nil))
        (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
        (entered (sb-thread:make-semaphore)) (proceed (sb-thread:make-semaphore))
        (primary nil) (cleanup-failures nil) (deadline (native-deadline 60)))
    ;; Confine controller: conserva la condizione, poi raccoglie TUTTI i worker.
    (handler-case
        (progn
          (native-prepare-workers fixtures cases deadline)
          (native-start-workers fixtures cases threads ready start entered proceed deadline)
          (native-wait ready deadline :ready +native-workers+)
          (sb-thread:signal-semaphore start +native-workers+)
          (native-wait entered deadline :entered +native-workers+)
          (sb-thread:signal-semaphore proceed +native-workers+))
      (error (condition) (setf primary condition)))
    (sb-thread:signal-semaphore start +native-workers+)
    (sb-thread:signal-semaphore proceed +native-workers+)
    (multiple-value-bind (worker-failures quiescent)
        (native-collect-workers (car threads) (native-deadline 10))
      (when worker-failures
        (dolist (condition worker-failures)
          (format *error-output* "CONTROL native worker: ~A~%" condition))
        (let ((original (find-if-not (lambda (c) (typep c 'native-fixture-timeout)) worker-failures)))
          (when (or (null primary) (typep primary 'native-fixture-timeout))
            (setf primary (or original (first worker-failures))))))
      (unless quiescent
        ;; Nessun abort asincrono o close concorrente: risorse conservate al runner isolato.
        (native-finish (or primary (make-condition 'native-fixture-timeout :phase :quiescence)) nil))
      (unless primary
        (handler-case (native-check-workers-open fixtures)
          (error (condition) (setf primary condition))))
      (dotimes (worker +native-workers+)
        (let ((fixture (aref fixtures worker)))
          (when fixture
            (setf (native-fixture-quiescent-p fixture) t)
            (setf cleanup-failures
                  (nconc cleanup-failures (native-cleanup fixture (native-deadline 10))))))))
    (native-finish primary cleanup-failures)))

;;; REQ: REQ-REC-001 REQ-CON-004 REQ-AFF-001 REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-CON-004-CONTROL-NATIVE-four-workers-four-rounds-v1-v2
  (native-parallel))

;;; REQ: REQ-CON-004 REQ-AFF-008
(deftest test-REQ-AFF-008-CONTROL-NATIVE-timeout-is-typed-separate-from-assert
  (let ((condition (handler-case (native-wait (sb-thread:make-semaphore) 0 :fixture-gate)
                     (native-fixture-timeout (original) original))))
    (is (typep condition 'native-fixture-timeout))
    (is (eq :fixture-gate (native-fixture-timeout-phase condition)))))
