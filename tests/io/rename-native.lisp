;;;; Fixture C4: byte grezzi distinti, senza attestazioni di EDIT, codec o checkpoint.
;;;; Solo lettura/scrittura/rinomina/fsync reali; nessuna misura prestazionale.
;;; OWNER: ogni fixture e i suoi FD appartengono a un solo worker durante il lavoro.
;;; SHARED: soltanto i gate di avvio; il controller riprende le fixture dopo tutti i join.
(in-package #:arcdocdb.io.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defconstant +rename-native-workers+ 4)
(defconstant +rename-native-rounds+ 8)
(defconstant +rename-native-file-limit+ 32)
(defconstant +rename-native-leaf-limit+ 32)
(defconstant +rename-native-directory-limit+ 8)

(define-condition rename-fixture-timeout (error)
  ((phase :initarg :phase :reader rename-fixture-timeout-phase))
  (:report (lambda (condition stream)
             (format stream "Fixture IO rename: timeout nella fase ~S."
                     (rename-fixture-timeout-phase condition)))))

(defstruct (rename-native-fixture (:constructor %make-rename-native-fixture (root)))
  "Risorse private C4; FD trattenuti fino alla fine di tutti i worker."
  (root #p"/" :type pathname :read-only t)
  (files nil :type list)
  (leaves nil :type list)
  (directories nil :type list))

(defun rename-native-make-fixture ()
  "Directory esclusiva 0700; la creazione ha il limite di 1000 tentativi del supporto."
  (let ((root (fresh-directory)) (complete nil))
    (unwind-protect
         (progn
           (is (= #o700 (logand #o777 (sb-posix:stat-mode (sb-posix:stat root)))))
           (prog1 (%make-rename-native-fixture root) (setf complete t)))
      (unless complete (sb-posix:rmdir (namestring root))))))

(defun rename-native-deadline (seconds)
  (+ (get-internal-real-time) (* seconds internal-time-units-per-second)))

(defun rename-native-seconds-left (deadline phase)
  (let ((ticks (- deadline (get-internal-real-time))))
    (unless (plusp ticks) (error 'rename-fixture-timeout :phase phase))
    (/ ticks (float internal-time-units-per-second 1d0))))

(defun rename-native-wait (gate deadline phase &optional (count 1))
  (unless (sb-thread:wait-on-semaphore
           gate :n count :timeout (rename-native-seconds-left deadline phase))
    (error 'rename-fixture-timeout :phase phase))
  nil)

(defun rename-native-leaf (fixture name &optional directory)
  "Registra prima dell'effetto un nome noto della fixture, mai scandisce il filesystem."
  (let ((path (merge-pathnames name (or directory (rename-native-fixture-root fixture)))))
    (unless (member path (rename-native-fixture-leaves fixture) :test #'equal)
      (is (< (length (rename-native-fixture-leaves fixture)) +rename-native-leaf-limit+))
      (push path (rename-native-fixture-leaves fixture)))
    path))

(defun rename-native-subdirectory (fixture name)
  "Solo directory interne alla root esclusiva; ordine inverso per rmdir bounded."
  (let ((path (merge-pathnames name (rename-native-fixture-root fixture))))
    (unless (member path (rename-native-fixture-directories fixture) :test #'equal)
      (is (< (length (rename-native-fixture-directories fixture))
             +rename-native-directory-limit+))
      (push path (rename-native-fixture-directories fixture)))
    (sb-posix:mkdir (namestring path) #o700)
    (is (= #o700 (logand #o777 (sb-posix:stat-mode (sb-posix:stat path)))))
    path))

(defun rename-native-open (fixture path mode &optional backend)
  "Il controller chiude dopo quiescenza; nessun with-file dentro il worker."
  (is (< (length (rename-native-fixture-files fixture)) +rename-native-file-limit+))
  (let ((file (case mode
                (:input (apri-lettura path :backend backend))
                (:append (crea-temporaneo path :backend backend))
                (:directory (apri-directory path :backend backend))
                (otherwise (error 'invariant-violation :reason :rename-fixture-mode)))))
    (push file (rename-native-fixture-files fixture))
    file))

(defun rename-native-create (fixture path contents &optional backend)
  "Frontiera durevole non nulla e inferiore alla scritta, per rilevare flush impliciti."
  (is (< 1 (length contents)))
  (let ((file (rename-native-open fixture path :append backend)))
    (is (= 1 (append-esatto file contents 0 1)))
    (is (= 1 (durable-flush file)))
    (is (= (length contents) (append-esatto file contents 1 (length contents))))
    file))

(defun rename-native-seed (fixture directory contents &optional backend)
  "Setup C4 del target esistente; writer e reader restano aperti."
  (let* ((temporary (rename-native-leaf fixture "seed.tmp" directory))
         (target (rename-native-leaf fixture "control.log" directory))
         (writer (rename-native-create fixture temporary contents backend)))
    (is (zerop (sb-posix:rename (namestring temporary) (namestring target))))
    (values writer (rename-native-open fixture target :input backend))))

(defun rename-native-state (file)
  (list (stato-file file) (posizione-scritta file) (posizione-durevole file)))

(defun rename-native-file-observation (file)
  (list (rename-native-state file)
        (sb-posix:lseek (arcdocdb.io::file-fd file) 0 sb-posix:seek-cur)))

(defun rename-native-identity (file)
  "Oracolo POSIX C4 indipendente dal binding di identità di prodotto."
  (let ((stat (sb-posix:fstat (arcdocdb.io::file-fd file))))
    (list (sb-posix:stat-dev stat) (sb-posix:stat-ino stat))))

(defun rename-native-check-bytes (file expected)
  (let ((actual (zeros (length expected))))
    (is (= (length expected) (sb-posix:stat-size (sb-posix:fstat (arcdocdb.io::file-fd file)))))
    (is (= (length expected) (leggi-esatto file actual 0 (length expected) 0)))
    (is (equalp expected actual)))
  nil)

(defun rename-native-check-path (fixture path expected)
  (rename-native-check-bytes (rename-native-open fixture path :input) expected))

(defun rename-native-check-absent (path)
  (handler-case
      (progn (sb-posix:lstat (namestring path))
             (error 'invariant-violation :reason :rename-fixture-unexpected-leaf))
    (sb-posix:syscall-error (condition)
      (is (= sb-posix:enoent (sb-posix:syscall-errno condition)))))
  nil)

(defun rename-native-counted-backend ()
  "Contatori locali: rename, flush file, fsync directory e close, tutti nativi."
  (let ((calls (make-array 4 :element-type 'fixnum :initial-element 0)))
    (values
     (make-backend
      #'arcdocdb.io::native-open #'arcdocdb.io::native-read #'arcdocdb.io::native-write
      (lambda (fd) (incf (aref calls 1)) (arcdocdb.io::native-flush fd))
      (lambda (fd) (incf (aref calls 2)) (arcdocdb.io::native-directory-flush fd))
      (lambda (fd) (incf (aref calls 3)) (arcdocdb.io::native-close fd))
      :rename (lambda (fd source destination)
                (incf (aref calls 0)) (arcdocdb.io::native-replace fd source destination)))
     calls)))

(defun rename-native-remove-leaf (path)
  (handler-case (sb-posix:unlink (namestring path))
    (sb-posix:syscall-error (condition)
      (unless (= sb-posix:enoent (sb-posix:syscall-errno condition)) (error condition)))))

(defun rename-native-remove-directory (path)
  (handler-case (sb-posix:rmdir (namestring path))
    (sb-posix:syscall-error (condition)
      (unless (= sb-posix:enoent (sb-posix:syscall-errno condition)) (error condition)))))

(defun rename-native-cleanup (fixture deadline)
  "Confine C4 dopo quiescenza: <=32 close, <=32 unlink, <=8 rmdir e root, con deadline."
  (let ((failures nil))
    (labels ((attempt (thunk)
               (handler-case (funcall thunk)
                 (sb-ext:timeout () (error 'rename-fixture-timeout :phase :cleanup))
                 (rename-fixture-timeout (condition) (error condition))
                 (error (condition) (push condition failures)))))
      (handler-case
          (sb-ext:with-timeout (rename-native-seconds-left deadline :cleanup)
            (is (<= (length (rename-native-fixture-files fixture)) +rename-native-file-limit+))
            (is (<= (length (rename-native-fixture-leaves fixture)) +rename-native-leaf-limit+))
            (is (<= (length (rename-native-fixture-directories fixture))
                    +rename-native-directory-limit+))
            (dolist (file (rename-native-fixture-files fixture))
              (attempt (lambda () (chiudi file))))
            ;; COD-36: cleanup C4 dei soli nomi creati nella nostra root 0700.
            ;; Nessuna scansione ricorsiva o percorso di storage esterno alla fixture.
            (dolist (path (rename-native-fixture-leaves fixture))
              (attempt (lambda () (rename-native-remove-leaf path))))
            (dolist (path (rename-native-fixture-directories fixture))
              (attempt (lambda () (rename-native-remove-directory path))))
            (attempt (lambda () (rename-native-remove-directory
                                 (rename-native-fixture-root fixture)))))
        (sb-ext:timeout () (error 'rename-fixture-timeout :phase :cleanup))))
    ;; Non nasconde errno: il runner distingue i guasti I/O dagli assert di prodotto.
    (when failures (error (first (last failures)))))
  nil)

(defun rename-native-replace (fixture directory old-writer old-input source-name old new)
  "Un round nativo: verifica namespace, inode, offset e capacità append prima del fsync."
  (let* ((source (rename-native-leaf fixture source-name))
         (target (rename-native-leaf fixture "control.log"))
         (writer (rename-native-create fixture source new))
         (old-identity (rename-native-identity old-input))
         (new-identity (rename-native-identity writer))
         (directory-before (rename-native-state directory))
         (old-before (rename-native-file-observation old-writer))
         (input-before (rename-native-file-observation old-input))
         (new-before (rename-native-file-observation writer)))
    (is (not (equal old-identity new-identity)))
    (rename-native-check-bytes old-input old)
    (is (null (arcdocdb.io:rinomina-nella-directory directory source-name "control.log")))
    (is (equal directory-before (rename-native-state directory)))
    (is (equal old-before (rename-native-file-observation old-writer)))
    (is (equal input-before (rename-native-file-observation old-input)))
    (is (equal new-before (rename-native-file-observation writer)))
    (rename-native-check-absent source)
    (let ((input (rename-native-open fixture target :input)))
      (is (equal old-identity (rename-native-identity old-input)))
      (is (equal old-identity (rename-native-identity old-writer)))
      (is (equal new-identity (rename-native-identity input)))
      (rename-native-check-bytes old-input old)
      (rename-native-check-bytes input new)
      ;; Le due capacità append originarie scrivono ancora nei rispettivi inode.
      (let ((old-tail (bytes #xe1 #xe2)) (new-tail (bytes #xf1)))
        (is (= (+ (length old) 2) (append-esatto old-writer old-tail 0 2)))
        (is (= (1+ (length new)) (append-esatto writer new-tail 0 1)))
        (is (= 1 (posizione-durevole old-writer)))
        (is (= 1 (posizione-durevole writer)))
        (rename-native-check-bytes old-input (concatenate 'arcdocdb.binary:octets old old-tail))
        (let ((visible (concatenate 'arcdocdb.binary:octets new new-tail)))
          (rename-native-check-bytes input visible)
          (let ((old-state (rename-native-state old-writer))
                (new-state (rename-native-state writer)))
            (is (zerop (durable-flush directory)))
            (is (equal directory-before (rename-native-state directory)))
            (is (equal old-state (rename-native-state old-writer)))
            (is (equal new-state (rename-native-state writer))))
          (values writer input visible))))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-001 REQ-AFF-002
(deftest test-REQ-REC-001-IO-RENAME-NATIVE-replacement-keeps-old-inode-and-append
  (let* ((fixture (rename-native-make-fixture))
         (root (rename-native-fixture-root fixture))
         (old (bytes #x10 #x20 #x30 #x40)) (new (bytes #x91 #x82 #x73 #x64 #x55)))
    (unwind-protect
         (let ((directory (rename-native-open fixture root :directory)))
           (multiple-value-bind (writer input) (rename-native-seed fixture root old)
             (rename-native-replace fixture directory writer input "replacement.tmp" old new)))
      (rename-native-cleanup fixture (rename-native-deadline 10)))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-001
(deftest test-REQ-REC-001-IO-RENAME-NATIVE-fsync-directory-is-explicit
  (let* ((fixture (rename-native-make-fixture))
         (root (rename-native-fixture-root fixture)))
    (unwind-protect
         (multiple-value-bind (backend calls) (rename-native-counted-backend)
           (let* ((directory (rename-native-open fixture root :directory backend))
                  (source (rename-native-leaf fixture "replacement.tmp"))
                  (new (bytes 71 72 73 74))
                  (writer (rename-native-create fixture source new backend)))
             (multiple-value-bind (old-writer old-input)
                 (rename-native-seed fixture root (bytes 11 12 13) backend)
               (let ((before (mapcar #'rename-native-state (list directory old-writer old-input writer))))
                 (fill calls 0)
                 (is (null (arcdocdb.io:rinomina-nella-directory
                            directory "replacement.tmp" "control.log")))
                 (is (equalp calls #(1 0 0 0)))
                 (is (equal before (mapcar #'rename-native-state
                                          (list directory old-writer old-input writer))))
                 (rename-native-check-path fixture (merge-pathnames "control.log" root) new)
                 (is (zerop (durable-flush directory)))
                 (is (equalp calls #(1 0 1 0)))
                 (is (equal before (mapcar #'rename-native-state
                                          (list directory old-writer old-input writer))))))))
      (rename-native-cleanup fixture (rename-native-deadline 10)))))

(defun rename-native-moved-parent-case (fixture)
  "Ricrea file esca sotto il vecchio percorso, senza cambiare il cwd del processo."
  (let* ((cwd (sb-posix:getcwd))
         (parent (rename-native-subdirectory fixture "parent/"))
         (owned (rename-native-subdirectory fixture "parent/owned/"))
         (moved (merge-pathnames "moved/" (rename-native-fixture-root fixture)))
         (moved-owned (merge-pathnames "owned/" moved))
         (directory (rename-native-open fixture owned :directory))
         (old (bytes 1 2 3)) (new (bytes 81 82 83 84))
         (decoy (bytes 51 52 53)) (decoy-source (bytes 61 62 63)))
    ;; Registra i percorsi di cleanup prima dello spostamento del parent.
    (push moved (rename-native-fixture-directories fixture))
    (push moved-owned (rename-native-fixture-directories fixture))
    (rename-native-leaf fixture "control.log" moved-owned)
    (rename-native-leaf fixture "replacement.tmp" moved-owned)
    (multiple-value-bind (old-writer old-input) (rename-native-seed fixture owned old)
      (let* ((writer (rename-native-create fixture
                     (rename-native-leaf fixture "replacement.tmp" owned) new))
             (identity (rename-native-identity writer))
             (before (mapcar #'rename-native-state (list directory old-writer old-input writer))))
        (is (zerop (sb-posix:rename (string-right-trim "/" (namestring parent))
                                   (string-right-trim "/" (namestring moved)))))
        (rename-native-subdirectory fixture "parent/")
        (rename-native-subdirectory fixture "parent/owned/")
        (rename-native-seed fixture owned decoy)
        (rename-native-create fixture (rename-native-leaf fixture "replacement.tmp" owned) decoy-source)
        (is (null (arcdocdb.io:rinomina-nella-directory
                   directory "replacement.tmp" "control.log")))
        (is (equal before (mapcar #'rename-native-state (list directory old-writer old-input writer))))
        (rename-native-check-bytes old-input old)
        (let ((input (rename-native-open fixture (merge-pathnames "control.log" moved-owned) :input)))
          (is (equal identity (rename-native-identity input)))
          (rename-native-check-bytes input new))
        (rename-native-check-absent (merge-pathnames "replacement.tmp" moved-owned))
        (rename-native-check-path fixture (merge-pathnames "control.log" owned) decoy)
        (rename-native-check-path fixture (merge-pathnames "replacement.tmp" owned) decoy-source)
        (is (equal cwd (sb-posix:getcwd)))
        (is (zerop (durable-flush directory)))))))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-001
(deftest test-REQ-REC-001-IO-RENAME-NATIVE-parent-move-keeps-fd-namespace-and-cwd
  (let ((fixture (rename-native-make-fixture)))
    (unwind-protect (rename-native-moved-parent-case fixture)
      (rename-native-cleanup fixture (rename-native-deadline 10)))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-IO-RENAME-NATIVE-missing-source-preserves-target-and-faults
  (let* ((fixture (rename-native-make-fixture))
         (root (rename-native-fixture-root fixture)) (old (bytes 31 32 33)))
    (unwind-protect
         (multiple-value-bind (backend calls) (rename-native-counted-backend)
           (let ((directory (rename-native-open fixture root :directory backend)))
             (multiple-value-bind (writer input) (rename-native-seed fixture root old backend)
               (let* ((survivor (rename-native-leaf fixture "survivor.tmp"))
                      (survivor-data (bytes 91 92 93 94))
                      (source-writer (rename-native-create fixture survivor survivor-data backend))
                      (identity (rename-native-identity input))
                      (before (mapcar #'rename-native-state (list writer input source-writer))))
                 (fill calls 0)
                 (check-io-error
                  (lambda () (arcdocdb.io:rinomina-nella-directory directory "missing.tmp" "control.log"))
                  :rename sb-posix:enoent 0)
                 (is (eq :faulted (stato-file directory)))
                 (is (equalp calls #(1 0 0 0)))
                 (is (sb-posix:s-isdir (sb-posix:stat-mode
                                       (sb-posix:fstat (arcdocdb.io::file-fd directory)))))
                 (is (zerop (posizione-scritta directory)))
                 (is (zerop (posizione-durevole directory)))
                 (is (equal identity (rename-native-identity input)))
                 (rename-native-check-bytes input old)
                 (let ((target-input (rename-native-open fixture
                                     (merge-pathnames "control.log" root) :input)))
                   (is (equal identity (rename-native-identity target-input)))
                   (rename-native-check-bytes target-input old))
                 (signals io-fault (arcdocdb.io:rinomina-nella-directory
                                    directory "survivor.tmp" "control.log") :io-unavailable)
                 (signals io-fault (durable-flush directory) :io-unavailable)
                 (is (equalp calls #(1 0 0 0)))
                 (rename-native-check-path fixture survivor survivor-data)
                 (is (equal before (mapcar #'rename-native-state (list writer input source-writer))))))))
      (rename-native-cleanup fixture (rename-native-deadline 10)))))

(defun rename-native-invalid-names ()
  ;; Nomi STRING come richiesto dal contratto dell'API.
  (list "" "." ".." "/" "/absolute.tmp" "child/source.tmp" "../control.log"
        (string #\Null) (concatenate 'string "a" (string #\Null) "b")
        (string (code-char 128)) (string (code-char #x20ac))
        (make-string 256 :initial-element #\x)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-IO-RENAME-NATIVE-invalid-names-precede-syscall
  (let* ((fixture (rename-native-make-fixture))
         (root (rename-native-fixture-root fixture))
         (old (bytes 41 42 43)) (new (bytes 71 72 73 74)))
    (unwind-protect
         (multiple-value-bind (backend calls) (rename-native-counted-backend)
           (let* ((directory (rename-native-open fixture root :directory backend))
                  (writer (rename-native-create fixture
                           (rename-native-leaf fixture "replacement.tmp") new backend)))
             (multiple-value-bind (old-writer input) (rename-native-seed fixture root old backend)
               (let ((before (mapcar #'rename-native-state (list directory writer old-writer input))))
                 (fill calls 0)
                 (dolist (name (rename-native-invalid-names))
                   (signals invalid-argument
                            (arcdocdb.io:rinomina-nella-directory directory name "control.log")
                            :io-rename-name)
                   (signals invalid-argument
                            (arcdocdb.io:rinomina-nella-directory directory "replacement.tmp" name)
                            :io-rename-name)
                   (is (equal before (mapcar #'rename-native-state
                                            (list directory writer old-writer input))))
                   (is (equalp calls #(0 0 0 0))))
                 (signals invalid-argument
                          (arcdocdb.io:rinomina-nella-directory
                           directory "control.log" (copy-seq "control.log")) :io-rename-same-name)
                 (is (equal before (mapcar #'rename-native-state
                                          (list directory writer old-writer input))))
                 (is (equalp calls #(0 0 0 0)))
                 (rename-native-check-bytes input old)
                 (rename-native-check-path fixture (merge-pathnames "replacement.tmp" root) new)
                 (is (null (arcdocdb.io:rinomina-nella-directory
                            directory "replacement.tmp" "control.log")))
                 (is (equalp calls #(1 0 0 0)))
                 (rename-native-check-path fixture (merge-pathnames "control.log" root) new)))))
      (rename-native-cleanup fixture (rename-native-deadline 10)))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-IO-RENAME-NATIVE-name-length-boundaries
  (let* ((fixture (rename-native-make-fixture))
         (root (rename-native-fixture-root fixture))
         (long (concatenate 'string (make-string 251 :initial-element #\n) ".tmp"))
         (data (bytes 1 17 33 49)))
    (unwind-protect
         (let* ((directory (rename-native-open fixture root :directory))
                (temporary (rename-native-leaf fixture "boundary.tmp"))
                (one (rename-native-leaf fixture "a"))
                (long-path (rename-native-leaf fixture long))
                (last-path (rename-native-leaf fixture "b"))
                (writer (rename-native-create fixture temporary data))
                (before (rename-native-state writer)))
           (is (= 255 (length long)))
           (is (zerop (sb-posix:rename (namestring temporary) (namestring one))))
           (is (null (arcdocdb.io:rinomina-nella-directory directory "a" long)))
           (rename-native-check-absent one)
           (rename-native-check-path fixture long-path data)
           (is (null (arcdocdb.io:rinomina-nella-directory directory long "b")))
           (rename-native-check-absent long-path)
           (rename-native-check-path fixture last-path data)
           (is (equal before (rename-native-state writer)))
           (is (zerop (durable-flush directory))))
      (rename-native-cleanup fixture (rename-native-deadline 10)))))

(defun rename-native-general-name (name)
  "Stringa ASCII attiva, adjustable/displaced/fillpointer, su storage CHARACTER generale."
  (let* ((size (length name))
         (storage (make-array (+ size 8) :element-type 'character
                                        :initial-element (code-char #x20ac))))
    (replace storage name :start1 2)
    ;; Prefisso e coda non ASCII appartengono allo storage, non al nome attivo.
    (make-array (+ size 4) :element-type 'character :displaced-to storage
                         :displaced-index-offset 2 :adjustable t :fill-pointer size)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-IO-RENAME-NATIVE-adjustable-displaced-fillpointer-names
  (let* ((fixture (rename-native-make-fixture))
         (root (rename-native-fixture-root fixture))
         (source (rename-native-general-name "general.tmp"))
         (destination (rename-native-general-name "control.log"))
         (source-before (copy-seq source)) (destination-before (copy-seq destination))
         (old (bytes 21 22 23)) (new (bytes 81 82 83 84)))
    (unwind-protect
         (let* ((directory (rename-native-open fixture root :directory))
                (path (rename-native-leaf fixture "general.tmp"))
                (writer (rename-native-create fixture path new)))
           (multiple-value-bind (old-writer old-input) (rename-native-seed fixture root old)
             (dolist (name (list source destination))
               (is (stringp name))
               (is (adjustable-array-p name))
               (is (array-has-fill-pointer-p name))
               (is (nth-value 0 (array-displacement name)))
               (is (= 2 (nth-value 1 (array-displacement name)))))
             (let ((before (mapcar #'rename-native-state (list directory writer old-writer old-input))))
               (is (null (arcdocdb.io:rinomina-nella-directory directory source destination)))
               (is (equal before (mapcar #'rename-native-state
                                        (list directory writer old-writer old-input))))
               (is (string= source-before source))
               (is (string= destination-before destination))
               (is (= (length source-before) (fill-pointer source)))
               (is (= (length destination-before) (fill-pointer destination)))
               (rename-native-check-absent path)
               (rename-native-check-bytes old-input old)
               (rename-native-check-path fixture (merge-pathnames "control.log" root) new)
               (is (zerop (durable-flush directory))))))
      (rename-native-cleanup fixture (rename-native-deadline 10)))))

(defun rename-native-worker (fixture id ready start entered proceed deadline)
  "Confine worker: trasporta la condizione originale, compresi timeout e guasti I/O."
  (let ((ready-p nil) (entered-p nil))
    (handler-case
        (let* ((root (rename-native-fixture-root fixture))
               (directory (rename-native-open fixture root :directory))
               (contents (bytes (+ 10 id) 20 30)))
          (multiple-value-bind (writer input) (rename-native-seed fixture root contents)
            (setf ready-p t)
            (sb-thread:signal-semaphore ready)
            (rename-native-wait start deadline :start)
            (dotimes (round +rename-native-rounds+)
              (rename-native-seconds-left deadline :round)
              (multiple-value-bind (new-writer new-input visible)
                  (rename-native-replace fixture directory writer input
                                         (format nil "round-~D.tmp" round) contents
                                         (bytes (+ 100 id) (+ 40 round) 70 80))
                (setf writer new-writer input new-input contents visible))
              (when (zerop round)
                ;; Tutti hanno rinominato una volta prima della seconda barriera.
                (setf entered-p t)
                (sb-thread:signal-semaphore entered)
                (rename-native-wait proceed deadline :proceed)))
            (rename-native-check-bytes input contents)
            (is (eq :open (stato-file directory)))
            :ok))
      (error (condition)
        ;; Un errore prima dei gate deve arrivare al join, senza diventare timeout.
        (unless ready-p (sb-thread:signal-semaphore ready))
        (unless entered-p (sb-thread:signal-semaphore entered))
        condition))))

(defun rename-native-join (thread deadline)
  (let ((result (sb-thread:join-thread
                 thread :timeout (rename-native-seconds-left deadline :join)
                        :default :rename-join-timeout)))
    (when (eq result :rename-join-timeout) (error 'rename-fixture-timeout :phase :join))
    (when (typep result 'error) (error result))
    (is (eq :ok result))
    (is (not (sb-thread:thread-alive-p thread))))
  nil)

(defun rename-native-stop-workers (threads deadline)
  "Termina tutti i superstiti, poi join limitato di tutti prima della prima close."
  (is (<= (length threads) +rename-native-workers+))
  (dolist (thread threads)
    (rename-native-seconds-left deadline :cleanup-stop)
    (when (sb-thread:thread-alive-p thread)
      (handler-case (sb-thread:terminate-thread thread)
        (error (condition)
          ;; Fine naturale concorrente: errore tollerato solo se il thread è morto.
          (when (sb-thread:thread-alive-p thread) (error condition))))))
  (dolist (thread threads)
    (let ((result (sb-thread:join-thread
                   thread :timeout (rename-native-seconds-left deadline :cleanup-join)
                          :default :rename-cleanup-ended)))
      (when (sb-thread:thread-alive-p thread)
        (error 'rename-fixture-timeout :phase :cleanup-join))
      ;; Condizione trasportata al join; un abort appartiene al cleanup della fixture.
      (is (or (typep result 'error) (member result '(:ok :rename-cleanup-ended))))))
  nil)

;;; REQ: REQ-REC-001 REQ-CON-004 REQ-AFF-001 REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-CON-004-IO-RENAME-NATIVE-four-independent-workers-bounded-rounds
  (let ((fixtures (make-array +rename-native-workers+ :initial-element nil))
        (threads nil) (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
        (entered (sb-thread:make-semaphore)) (proceed (sb-thread:make-semaphore))
        (deadline (rename-native-deadline 30)))
    (unwind-protect
         (progn
           ;; Quattro root create prima dei thread, con namespace e FD privati.
           (dotimes (id +rename-native-workers+)
             (setf (aref fixtures id) (rename-native-make-fixture)))
           (is (= +rename-native-workers+
                  (length (remove-duplicates
                           (map 'list #'rename-native-fixture-root fixtures) :test #'equal))))
           (dotimes (worker +rename-native-workers+)
             (let ((id worker))
               (push (sb-thread:make-thread
                      (lambda () (rename-native-worker (aref fixtures id) id ready start
                                                       entered proceed deadline))
                      :name (format nil "IO rename native private worker ~D" id)) threads)))
           (rename-native-wait ready deadline :ready +rename-native-workers+)
           (sb-thread:signal-semaphore start +rename-native-workers+)
           (rename-native-wait entered deadline :entered +rename-native-workers+)
           (sb-thread:signal-semaphore proceed +rename-native-workers+)
           (dolist (thread threads) (rename-native-join thread deadline))
           (is (notany #'sb-thread:thread-alive-p threads))
           ;; Il controllo dopo tutti i join rileva una chiusura dentro un worker.
           (dotimes (id +rename-native-workers+)
             (let ((fixture (aref fixtures id)))
               (is (= (+ 3 (* 2 +rename-native-rounds+))
                      (length (rename-native-fixture-files fixture))))
               (dolist (file (rename-native-fixture-files fixture))
                 (is (eq :open (stato-file file)))
                 (is (not (minusp (sb-posix:fcntl (arcdocdb.io::file-fd file) sb-posix:f-getfd))))))))
      (sb-thread:signal-semaphore start +rename-native-workers+)
      (sb-thread:signal-semaphore proceed +rename-native-workers+)
      (let ((cleanup-deadline (rename-native-deadline 10)))
        ;; Se stop/join scade, nessun FD viene chiuso: le risorse restano al runner isolato.
        (rename-native-stop-workers threads cleanup-deadline)
        (dotimes (id +rename-native-workers+)
          (when (aref fixtures id)
            (rename-native-cleanup (aref fixtures id) cleanup-deadline)))))))

;;;; Sostituzione verificata: nomi legati ai FD INPUT, senza prova di EDIT o checkpoint.

(defun rename-native-verified-backend (&optional after-rename)
  "Backend con identità reali e contatori locali; il solo hook può interrompere dopo rename."
  (let ((calls (make-array 4 :element-type 'fixnum :initial-element 0)))
    (values
     (make-backend
      #'arcdocdb.io::native-open #'arcdocdb.io::native-read #'arcdocdb.io::native-write
      (lambda (fd) (incf (aref calls 1)) (arcdocdb.io::native-flush fd))
      (lambda (fd) (incf (aref calls 2)) (arcdocdb.io::native-directory-flush fd))
      (lambda (fd) (incf (aref calls 3)) (arcdocdb.io::native-close fd))
      :identity #'arcdocdb.io::native-identity
      :entry-identity #'arcdocdb.io::native-entry-identity
      :rename (lambda (fd source target)
                (incf (aref calls 0))
                (let ((result (arcdocdb.io::native-replace fd source target)))
                  (when (and (eql result 0) after-rename) (funcall after-rename))
                  result)))
     calls)))

(defun rename-native-path-identity (path)
  "Oracolo lstat C4 sui nomi posseduti: mantiene distinto il namespace dalle capacità."
  (let ((stat (sb-posix:lstat (namestring path))))
    (is (sb-posix:s-isreg (sb-posix:stat-mode stat)))
    (list (sb-posix:stat-dev stat) (sb-posix:stat-ino stat))))

(defun rename-native-verified-success (fixture backend calls)
  "Identità distinte, FD originali vivi e frontiere/offset fermi; fsync successiva esplicita."
  (let* ((root (rename-native-fixture-root fixture))
         (directory (rename-native-open fixture root :directory backend))
         (source-path (rename-native-leaf fixture "control.log.tmp"))
         (target-path (rename-native-leaf fixture "control.log"))
         (old (bytes #x11 #x22 #x33)) (new (bytes #x84 #x75 #x66 #x57))
         (source-writer (rename-native-create fixture source-path new backend)))
    (multiple-value-bind (target-writer target) (rename-native-seed fixture root old backend)
      ;; La preparazione rende durevoli entrambi i file prima della verifica del namespace.
      (is (= (length new) (durable-flush source-writer)))
      (is (= (length old) (durable-flush target-writer)))
      (let* ((source (rename-native-open fixture source-path :input backend))
             (source-identity (rename-native-identity source))
             (target-identity (rename-native-identity target))
             (files (list source target source-writer target-writer))
             (before (mapcar #'rename-native-file-observation files))
             (directory-before (rename-native-state directory)))
        (is (not (equal source-identity target-identity)))
        (is (equal source-identity (rename-native-path-identity source-path)))
        (is (equal target-identity (rename-native-path-identity target-path)))
        (when calls (fill calls 0))
        (is (null (arcdocdb.io:sostituisci-temporaneo
                   directory source target "control.log.tmp" "control.log")))
        (when calls (is (equalp calls #(1 0 0 0))))
        (is (equal before (mapcar #'rename-native-file-observation files)))
        (is (equal directory-before (rename-native-state directory)))
        (rename-native-check-absent source-path)
        (is (equal source-identity (rename-native-path-identity target-path)))
        (is (equal target-identity (rename-native-identity target)))
        (rename-native-check-bytes target old)
        (rename-native-check-bytes source new)
        (let ((current (rename-native-open fixture target-path :input backend)))
          (is (equal source-identity (rename-native-identity current)))
          (rename-native-check-bytes current new))
        (is (zerop (durable-flush directory)))
        (when calls (is (equalp calls #(1 0 1 0))))
        (is (equal directory-before (rename-native-state directory)))
        (is (equal before (mapcar #'rename-native-file-observation files)))
        (dolist (file files)
          (is (eq :open (stato-file file)))
          (is (not (minusp (sb-posix:fcntl (arcdocdb.io::file-fd file) sb-posix:f-getfd))))))))
  nil)

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-001 REQ-AFF-002
(deftest test-REQ-REC-001-IO-RENAME-NATIVE-VERIFIED-distinct-inodes-and-separate-fsync
  ;; Una passata nel percorso nativo diretto, una con gli stessi I/O nativi contati.
  (dolist (observe '(nil t))
    (let ((fixture (rename-native-make-fixture)))
      (unwind-protect
           (multiple-value-bind (backend calls)
               (if observe (rename-native-verified-backend) (values nil nil))
             (rename-native-verified-success fixture backend calls))
        (rename-native-cleanup fixture (rename-native-deadline 10))))))

(defun rename-native-verified-mismatch (fixture backend calls)
  "Rifiuta separatamente source/target con contenuto uguale ma inode estraneo al nome."
  (let* ((root (rename-native-fixture-root fixture))
         (directory (rename-native-open fixture root :directory backend))
         (source-path (rename-native-leaf fixture "control.log.tmp"))
         (target-path (rename-native-leaf fixture "control.log"))
         (old (bytes 17 18 19)) (new (bytes 97 98 99 100))
         (source-writer (rename-native-create fixture source-path new backend))
         (wrong-source-path (rename-native-leaf fixture "wrong-source.tmp"))
         (wrong-target-path (rename-native-leaf fixture "wrong-target.tmp"))
         (wrong-source-writer (rename-native-create fixture wrong-source-path new backend))
         (wrong-target-writer (rename-native-create fixture wrong-target-path old backend)))
    (multiple-value-bind (target-writer target) (rename-native-seed fixture root old backend)
      (dolist (writer (list source-writer target-writer wrong-source-writer wrong-target-writer))
        (is (= (posizione-scritta writer) (durable-flush writer))))
      (let* ((source (rename-native-open fixture source-path :input backend))
             (wrong-source (rename-native-open fixture wrong-source-path :input backend))
             (wrong-target (rename-native-open fixture wrong-target-path :input backend))
             (source-identity (rename-native-identity source))
             (target-identity (rename-native-identity target))
             (files (copy-list (rename-native-fixture-files fixture)))
             (before (mapcar #'rename-native-state files)))
        (is (not (equal source-identity (rename-native-identity wrong-source))))
        (is (not (equal target-identity (rename-native-identity wrong-target))))
        (when calls (fill calls 0))
        (dolist (pair (list (list wrong-source target) (list source wrong-target)))
          (signals invalid-argument
                   (arcdocdb.io:sostituisci-temporaneo
                    directory (first pair) (second pair) "control.log.tmp" "control.log")
                   :io-replacement-identity)
          (when calls (is (equalp calls #(0 0 0 0))))
          (is (equal before (mapcar #'rename-native-state files)))
          (is (equal source-identity (rename-native-path-identity source-path)))
          (is (equal target-identity (rename-native-path-identity target-path)))
          (rename-native-check-bytes source new)
          (rename-native-check-bytes target old)
          (rename-native-check-bytes wrong-source new)
          (rename-native-check-bytes wrong-target old)))))
  nil)

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-AFF-008
(deftest test-REQ-AFF-008-IO-RENAME-NATIVE-VERIFIED-fd-name-mismatches-before-rename
  (dolist (observe '(nil t))
    (let ((fixture (rename-native-make-fixture)))
      (unwind-protect
           (multiple-value-bind (backend calls)
               (if observe (rename-native-verified-backend) (values nil nil))
             (rename-native-verified-mismatch fixture backend calls))
        (rename-native-cleanup fixture (rename-native-deadline 10))))))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-AFF-008
(deftest test-REQ-AFF-008-IO-RENAME-NATIVE-VERIFIED-hardlink-alias-before-rename
  (let* ((fixture (rename-native-make-fixture))
         (root (rename-native-fixture-root fixture)) (data (bytes 51 52 53)))
    (unwind-protect
         (multiple-value-bind (backend calls) (rename-native-verified-backend)
           (let ((directory (rename-native-open fixture root :directory backend)))
             (multiple-value-bind (writer target) (rename-native-seed fixture root data backend)
               (is (= (length data) (durable-flush writer)))
               (let* ((source-path (rename-native-leaf fixture "control.log.tmp"))
                      (target-path (merge-pathnames "control.log" root)))
                 ;; Due FD INPUT distinti e due nomi legati allo stesso inode reale.
                 (is (zerop (sb-posix:link (namestring target-path) (namestring source-path))))
                 (let* ((source (rename-native-open fixture source-path :input backend))
                        (identity (rename-native-identity target))
                        (files (copy-list (rename-native-fixture-files fixture)))
                        (before (mapcar #'rename-native-state files)))
                   (is (not (= (arcdocdb.io::file-fd source) (arcdocdb.io::file-fd target))))
                   (is (equal identity (rename-native-identity source)))
                   (fill calls 0)
                   (signals invalid-argument
                            (arcdocdb.io:sostituisci-temporaneo
                             directory source target "control.log.tmp" "control.log")
                            :io-replacement-alias)
                   (is (equalp calls #(0 0 0 0)))
                   (is (equal before (mapcar #'rename-native-state files)))
                   (is (equal identity (rename-native-path-identity source-path)))
                   (is (equal identity (rename-native-path-identity target-path)))
                   (is (= 2 (sb-posix:stat-nlink (sb-posix:fstat (arcdocdb.io::file-fd target)))))
                   (rename-native-check-bytes source data)
                   (rename-native-check-bytes target data))))))
      (rename-native-cleanup fixture (rename-native-deadline 10)))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-IO-RENAME-NATIVE-VERIFIED-exit-after-effect-faults-without-rollback
  (let* ((fixture (rename-native-make-fixture))
         (root (rename-native-fixture-root fixture))
         (failure (make-condition 'invariant-violation :reason :rename-verified-injected-exit))
         (old (bytes 27 28 29)) (new (bytes 77 78 79 80)))
    (unwind-protect
         (multiple-value-bind (backend calls)
             (rename-native-verified-backend (lambda () (error failure)))
           (let* ((directory (rename-native-open fixture root :directory backend))
                  (source-path (rename-native-leaf fixture "control.log.tmp"))
                  (target-path (rename-native-leaf fixture "control.log"))
                  (source-writer (rename-native-create fixture source-path new backend)))
             (multiple-value-bind (target-writer target) (rename-native-seed fixture root old backend)
               (is (= (length new) (durable-flush source-writer)))
               (is (= (length old) (durable-flush target-writer)))
               (let* ((source (rename-native-open fixture source-path :input backend))
                      (identity (rename-native-identity source))
                      (old-identity (rename-native-identity target))
                      (files (list source target source-writer target-writer))
                      (before (mapcar #'rename-native-file-observation files)))
                 (fill calls 0)
                 (let ((caught (handler-case
                                   (arcdocdb.io:sostituisci-temporaneo
                                    directory source target "control.log.tmp" "control.log")
                                 (invariant-violation (condition) condition))))
                   (is (eq failure caught)))
                 (is (eq :faulted (stato-file directory)))
                 (is (zerop (posizione-scritta directory)))
                 (is (zerop (posizione-durevole directory)))
                 (is (equalp calls #(1 0 0 0)))
                 (is (sb-posix:s-isdir (sb-posix:stat-mode
                                       (sb-posix:fstat (arcdocdb.io::file-fd directory)))))
                 (is (equal before (mapcar #'rename-native-file-observation files)))
                 (rename-native-check-absent source-path)
                 (is (equal identity (rename-native-path-identity target-path)))
                 (is (equal old-identity (rename-native-identity target)))
                 (rename-native-check-bytes source new)
                 (rename-native-check-bytes target old)
                 (rename-native-check-path fixture target-path new)
                 (signals io-fault
                          (arcdocdb.io:sostituisci-temporaneo
                           directory source target "control.log.tmp" "control.log") :io-unavailable)
                 (signals io-fault (durable-flush directory) :io-unavailable)
                 (is (equalp calls #(1 0 0 0)))))))
      (rename-native-cleanup fixture (rename-native-deadline 10)))))
