;;;; Qualifica C4 del bridge: lettura reale -> checkpoint -> rename/fsync, v1/v2.
;;;; Caricare dopo publication, native e recovery-read; integrazione ASDF del coordinatore.
;;;; Metodo: byte attesi da packing/CRC bitwise di publication, mai dai buffer del piano.
;;;; Il vecchio CONTROL nasce dall'oracolo; la lettura pubblica precede il nuovo piano.
;;;; CLOSED2/128 conserva TXID101/CSN alto e TXID102/CSN zero; REMOVED3 conservato.
;;;; Vecchio ACTIVE9 reale header-only, scansionato fino a EOF64; nuovo ACTIVE13.
;;;; Nuovo manifest: CLOSED2 invariato + CLOSED9/64 senza esiti, REMOVED3, next14.
;;;; I CLOSED storici sono fatti della fixture: non si qualifica qui il loro inventario.
;;;; Oracoli: query pubbliche, FD/inode/EOF/offset/frontiere, byte e recovery dopo riapertura.
;;;; Eventi del solo publisher isolati dagli oracoli: 3 identity, 3 entry, 1 rename, 1 fsync.
;;;; CRV-D07: stessa vista, altra vista con UUID uguale, input CLOSED/FAULTED prima del claim.
;;;; CRV-D03..06: percorso valido e sei rifiuti; non è la matrice completa del confronto manifest.
;;;; Fuori suite: UUID diverso, CAS conteso e FI in ogni callback rename (publisher generico).
;;;; Limiti: quelli dei registri native (128 FD/64 leaf/16 directory/4096 byte per fixture),
;;;; 30s seriali; 4 worker x 2 round, gate entro 60s e join con deadline comune di 10s.
;;;; Nessun terminate-thread; senza quiescenza si trattengono TUTTI i FD e namespace.
;;;; Non prova power loss, esclusività verso altri processi, prestazioni o motore completo.
;;; OWNER: fixture 0700 privata; registri native e capacità posseduti da un solo worker.
;;; SHARED: solo semafori bounded; il controller riprende ownership dopo tutti i join.
(in-package #:arcdocdb.control.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defstruct (rp-case (:constructor rp-make-case))
  path directory identity view version old-active active old-input old-append
  old-bytes old-prefix old-inode recovered new)

(define-condition rp-directory-escape (condition) ())

(defun rp-release (fixture)
  "Cleanup native bounded: registra i guasti senza sostituire condizione/uscita non locale."
  (let ((failures (native-cleanup fixture (native-deadline 10))))
    (dolist (condition failures)
      (format *error-output* "CONTROL recovery-publication cleanup: ~A~%" condition))
    failures))

(defun rp-run (thunk)
  "Nessun catch generico seriale; UNWIND-PROTECT conserva anche uscite non locali."
  (let* ((deadline (native-deadline 30)) (fixture (native-fixture deadline))
         (complete nil) (cleanup-failures nil))
    (unwind-protect
         (progn (funcall thunk fixture deadline) (setf complete t))
      (setf cleanup-failures (rp-release fixture)))
    (when (and complete cleanup-failures) (error (first cleanup-failures)))
    nil))

(defun rp-payload (active next closed removed)
  "Oracolo EDIT indipendente: entry (ID SIZE ((TXID CSN)...)); liste finite della fixture."
  (let* ((closed-size (loop for entry in closed sum (+ 20 (* 16 (length (third entry))))))
         (bytes (zeros (+ 24 closed-size (* 8 (length removed))))) (pos 20))
    (is (<= (length bytes) +native-byte-limit+))
    (control-pack bytes 0 next 8) (control-pack bytes 8 active 8)
    (control-pack bytes 16 (length closed) 4)
    (dolist (entry closed)
      (control-pack bytes pos (first entry) 8)
      (control-pack bytes (+ pos 8) (second entry) 8)
      (control-pack bytes (+ pos 16) (length (third entry)) 4)
      (incf pos 20)
      (dolist (outcome (third entry))
        (control-pack bytes pos (first outcome) 8)
        (control-pack bytes (+ pos 8) (second outcome) 8)
        (incf pos 16)))
    (control-pack bytes pos (length removed) 4) (incf pos 4)
    (dolist (id removed) (control-pack bytes pos id 8) (incf pos 8))
    (is (= pos (length bytes)))
    bytes))

(defun rp-previous-payload (&optional (variant :canonical))
  "Varianti contraddittorie lette da file separati; non sostituiscono il log autorevole."
  (let ((active 9) (next 10) (closed '((2 128 ((101 4294967298) (102 0))))) (removed '(3)))
    (ecase variant
      (:canonical nil)
      (:active-reused (setf next 14))
      (:active-not-closed (setf active 8))
      (:segment-counts (setf closed nil))
      (:closed-changed (setf closed '((2 136 ((101 4294967298) (102 0))))))
      (:outcome-changed (setf closed '((2 128 ((101 4294967299) (102 0))))))
      (:removed-changed (setf removed '(4))))
    (rp-payload active next closed removed)))

(defun rp-next-payload ()
  (rp-payload 13 14 '((2 128 ((101 4294967298) (102 0))) (9 64 nil)) '(3)))

(defun rp-manifest (manifest new-p)
  "Fatti scalari indipendenti dal codec, solo query pubbliche; CSN zero distinto da assenza."
  (let ((active (if new-p 13 9)))
    (is (= active (arcdocdb.recovery.manifest:segmento-attivo manifest)))
    (is (equal (list t (if new-p 14 10))
               (multiple-value-list (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))
    (is (= (if new-p 2 1) (arcdocdb.recovery.manifest:numero-segmenti-chiusi manifest)))
    (is (= 1 (arcdocdb.recovery.manifest:numero-segmenti-rimossi manifest)))
    (dolist (fact (list (list active :active 0 0) '(2 :closed 128 2) '(3 :removed 0 0)
                       '(999 :unknown 0 0) (if new-p '(9 :closed 64 0) '(13 :unknown 0 0))))
      (is (equal (rest fact)
                 (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest (first fact))))))
    (dolist (fact '((101 t 4294967298) (102 t 0) (999 nil 0)))
      (is (equal (rest fact)
                 (multiple-value-list
                  (arcdocdb.recovery.manifest:trova-esito-chiusura manifest 2 (first fact))))))
    (is (equal '(nil 0)
               (multiple-value-list (arcdocdb.recovery.manifest:trova-esito-chiusura manifest 9 102)))))
  nil)

(defun rp-observation (file)
  "Oracolo POSIX fuori callback; include FD, modo e flag, anche per capacità FAULTED."
  (list (io::file-fd file) (io:mode-file file) (io:stato-file file)
        (io:posizione-scritta file) (io:posizione-durevole file)
        (if (eq :closed (io:stato-file file)) :closed
            (list (sb-posix:fcntl (io::file-fd file) sb-posix:f-getfl)
                  (native-observation file)))))

(defun rp-observations (fixture)
  (mapcar (lambda (slot) (when (car slot) (rp-observation (car slot))))
          (native-fixture-files fixture)))

(defun rp-data-observations (fixture)
  "Esclude soltanto il parent che deve diventare FAULTED nella FI dopo rename."
  (loop for slot in (native-fixture-files fixture) for file = (car slot)
        when (and file (not (eq :directory (io:mode-file file)))) collect (rp-observation file)))

(defun rp-read (fixture view input expected prefix status version deadline)
  "EOF da FSTAT del FD reale congelato; lo scratch viene poi sovrascritto intenzionalmente."
  (let* ((size (sb-posix:stat-size (sb-posix:fstat (io::file-fd input))))
         (before (rp-observation input)) (scratch (zeros size)))
    (is (= size (length expected))) (is (eq :input (io:mode-file input)))
    (is (= sb-posix:o-rdonly
           (logand (sb-posix:fcntl (io::file-fd input) sb-posix:f-getfl)
                   (logior sb-posix:o-wronly sb-posix:o-rdwr))))
    (native-reset-calls fixture)
    (let ((recovered (native-bounded deadline :recovery-read
                       (lambda ()
                         (c:leggi-control-recuperato
                          view input size scratch :chunk-bytes 31 :max-bytes +native-byte-limit+
                          :max-batches 2 :max-batch-records 1 :max-edits 1 :max-segmenti 4 :max-esiti 2)))))
      (is (typep recovered 'c:control-recuperato))
      (is (equalp (native-observer-calls (native-fixture-observer fixture))
                  (vector 0 (ceiling size 31) 0 0 0 0 0 0 0)))
      (is (equalp scratch expected)) (is (equal before (rp-observation input)))
      (is (equal (list size prefix status version)
                 (multiple-value-list (c:frontiere-control-recuperato recovered))))
      (fill scratch #xa5)
      recovered)))

(defun rp-seed (fixture path name bytes deadline)
  "Create esclusiva e registrata, append e flush controllati; nessun piano prodotto forgiato."
  (let* ((leaf (native-leaf fixture path name))
         (append (native-open fixture leaf :append deadline)))
    (native-bounded deadline :seed
      (lambda ()
        (is (= (length bytes) (io:append-esatto append bytes 0 (length bytes))))
        (is (= (length bytes) (io:durable-flush append)))))
    (values (native-open fixture leaf :input deadline) append)))

(defun rp-active-oracle (fixture case id deadline)
  "Verifica il vero header writer e il suo EOF fisico; nessun record o esito da inventare."
  (let* ((input (native-open fixture
                             (merge-pathnames (format nil "active-~D.tmp" id) (rp-case-path case))
                             :input deadline))
         (expected (control-reference-header (rp-case-identity case) (rp-case-version case) t)))
    (control-pack expected 32 id 8) (control-pack expected 40 17 8)
    (control-pack expected 56 (control-crc expected 0 56) 4)
    (let ((bytes (native-read-bytes input expected deadline)))
      (multiple-value-bind (end version origin created-offset)
          (arcdocdb.storage.format:verifica-header-segmento bytes 0 64 (rp-case-identity case) id)
        (is (= 64 end)) (is (= (rp-case-version case) version))
        (is (= 1 origin)) (is (= 40 created-offset)))
      (is (equal '(64 :complete 0 0)
                 (multiple-value-list
                  (arcdocdb.recovery.scan:scansiona-log
                   bytes 64 64 id :version (rp-case-version case) :log-kind :segment :file-size 64
                   :max-bytes 64 :max-batches 1 :max-batch-records 1
                   :max-batch-bytes 64 :max-search-bytes 64)))))
    nil))

(defun rp-prepare (fixture case deadline)
  "Le factory reali scrivono il nuovo file DOPO la lettura del vecchio CONTROL."
  (let* ((active (native-active fixture (rp-case-directory case) (rp-case-path case)
                                (rp-case-view case) 13 (rp-case-version case) deadline))
         (payload (rp-next-payload))
         (expected (control-reference-checkpoint (rp-case-identity case) (rp-case-version case) payload 23))
         (plan (c:crea-checkpoint-control active payload 23 :max-segmenti 4 :max-esiti 2))
         (leaf (native-leaf fixture (rp-case-path case) "control.log.tmp"))
         (append (native-open fixture leaf :append deadline))
         (input (native-open fixture leaf :input deadline))
         (prepared (native-bounded deadline :checkpoint
                     (lambda () (c:prepara-checkpoint-control
                                 plan input append (rp-case-directory case) (zeros 37) :chunk-bytes 37)))))
    (is (= (length expected) (c:lunghezza-checkpoint-control plan)))
    (rp-manifest (c:manifest-checkpoint-control plan) t)
    (rp-manifest (c:manifest-control-preparato prepared) t)
    (native-read-bytes input expected deadline)
    (setf (rp-case-active case) active
          (rp-case-new case) (native-make-checkpoint plan prepared input append expected))
    case))

(defun rp-setup (fixture path version deadline &optional tail-p (identity-base 32))
  "Namespace posseduto stabile; coda non sigillata di 17 byte inclusa nell'EOF autorevole."
  (let* ((identity (zeros 16)) (directory (native-open fixture path :directory deadline)))
    (dotimes (i 16) (setf (aref identity i) (+ identity-base i)))
    (let* ((view (native-view identity))
           (old-active (native-active fixture directory path view 9 version deadline))
           (prefix-bytes (control-reference-checkpoint identity version (rp-previous-payload) 19))
           (old-bytes (if tail-p (concatenate '(vector (unsigned-byte 8)) prefix-bytes (zeros 17))
                          prefix-bytes))
           (case (rp-make-case :path path :directory directory :identity identity :view view
                              :version version :old-active old-active :old-bytes old-bytes
                              :old-prefix (length prefix-bytes))))
      (multiple-value-bind (seed-input append) (rp-seed fixture path "previous-control.tmp" old-bytes deadline)
        (let ((target (native-leaf fixture path "control.log")))
          (native-seconds-left deadline :seed-rename)
          (sb-posix:rename (namestring (merge-pathnames "previous-control.tmp" path)) (namestring target))
          (is (zerop (native-bounded deadline :seed-directory (lambda () (io:durable-flush directory)))))
          (let ((input (native-open fixture target :input deadline)))
            (is (equal (native-identity seed-input) (native-identity input)))
            (setf (rp-case-old-input case) input (rp-case-old-append case) append
                  (rp-case-old-inode case) (native-identity input)
                  (rp-case-recovered case)
                  (rp-read fixture view input old-bytes (length prefix-bytes)
                           (if tail-p :tail :complete) version deadline)))))
      (rp-manifest (c:manifest-control-recuperato (rp-case-recovered case)) nil)
      (rp-active-oracle fixture case 9 deadline)
      (rp-prepare fixture case deadline))))

(defun rp-state (case state observed)
  (is (equal (list state observed)
             (multiple-value-list
              (c:stato-pubblicazione-control (native-checkpoint-prepared (rp-case-new case)))))))

(defun rp-publish (case deadline &optional (recovered (rp-case-recovered case)))
  (native-bounded deadline :validated-publication
    (lambda () (c:pubblica-control-validato (native-checkpoint-prepared (rp-case-new case)) recovered))))

(defun rp-reject (fixture case deadline recovered type reason &optional (state :prepared) observed)
  "Rifiuto senza callback, frontiere o FD mutati; nessun timeout/assert catturato come prodotto."
  (let ((before (rp-observations fixture)) (delivered nil))
    (native-reset-calls fixture)
    (let ((condition (native-capture-product-error
                      (lambda () (setf delivered (rp-publish case deadline recovered))))))
      (is (typep condition type)) (is (eq reason (error-reason condition)))
      (is (null delivered))
      (when (eq reason :io-unavailable) (is (eq :input (error-operation condition)))))
    (is (every #'zerop (native-observer-calls (native-fixture-observer fixture))))
    (is (equal before (rp-observations fixture)))
    (rp-state case state observed)))

(defun rp-success (fixture case deadline &optional (recovered (rp-case-recovered case)))
  (let* ((before (rp-observations fixture)) (new (rp-case-new case))
         (append (native-checkpoint-append new)))
    (native-reset-calls fixture)
    (let ((published (rp-publish case deadline recovered)))
      (is (typep published 'c:control-pubblicato))
      (is (equalp #(0 0 0 0 1 0 3 3 1)
                  (native-observer-calls (native-fixture-observer fixture))))
      (is (equal before (rp-observations fixture)))
      (is (= (length (native-checkpoint-bytes new))
             (io:posizione-scritta append) (io:posizione-durevole append)))
      (rp-state case :published t)
      (is (eq (rp-case-active case) (c:active-control-pubblicato published)))
      (is (eq (c:log-control-preparato (native-checkpoint-prepared new)) (c:log-control-pubblicato published)))
      (is (eq (c:manifest-control-preparato (native-checkpoint-prepared new))
              (c:manifest-control-pubblicato published)))
      (rp-manifest (c:manifest-control-pubblicato published) t)
      published)))

(defun rp-oracle (fixture case deadline &optional (previous (rp-case-old-input case)))
  "Reopen del nome installato; vecchio FD ancora sul vecchio inode, byte/EOF invariati."
  (let* ((new (rp-case-new case)) (path (merge-pathnames "control.log" (rp-case-path case)))
         (input (native-open fixture path :input deadline))
         (expected (native-checkpoint-bytes new)))
    (is (equal (native-path-identity path) (native-identity input)))
    (is (equal (native-identity input) (native-identity (native-checkpoint-input new))))
    (is (not (equal (rp-case-old-inode case) (native-identity input))))
    (native-absent (merge-pathnames "control.log.tmp" (rp-case-path case)))
    (let ((bytes (native-read-bytes input expected deadline)))
      (multiple-value-bind (start version)
          (arcdocdb.storage.format:verifica-header-log bytes 0 (length bytes) :control (rp-case-identity case))
        (is (= 64 start)) (is (= (rp-case-version case) version))))
    (rp-manifest (c:manifest-control-recuperato
                  (rp-read fixture (rp-case-view case) input expected (length expected) :complete
                           (rp-case-version case) deadline)) t)
    (is (equal (rp-case-old-inode case) (native-identity previous)))
    (native-read-bytes previous (rp-case-old-bytes case) deadline)
    (rp-manifest (c:manifest-control-recuperato
                  (rp-read fixture (rp-case-view case) previous (rp-case-old-bytes case)
                           (rp-case-old-prefix case)
                           (if (= (rp-case-old-prefix case) (length (rp-case-old-bytes case))) :complete :tail)
                           (rp-case-version case) deadline)) nil)
    (is (equal (native-path-identity path) (native-identity input)))
    (rp-active-oracle fixture case 9 deadline)
    (rp-active-oracle fixture case 13 deadline))
  nil)

(defun rp-decoy (fixture case variant deadline)
  "File indipendente realmente letto con la vista canonica; mai falsifica wrapper di prodotto."
  (let ((bytes (control-reference-checkpoint (rp-case-identity case) (rp-case-version case)
                                             (rp-previous-payload variant) 19)))
    (multiple-value-bind (input append)
        (rp-seed fixture (rp-case-path case) "decoy-control.tmp" bytes deadline)
      (is (= (length bytes) (io:posizione-scritta append) (io:posizione-durevole append)))
      (is (not (equal (native-identity input) (rp-case-old-inode case))))
      (rp-read fixture (rp-case-view case) input bytes (length bytes) :complete (rp-case-version case) deadline))))

(defun rp-unavailable (state)
  "FI locale sullo stato readonly, senza riaprirlo artificialmente; retry da un altro FD reale."
  (dolist (version '(1 2))
    (rp-run
     (lambda (fixture deadline)
       (let* ((case (rp-setup fixture (native-fixture-root fixture) version deadline))
              (old (rp-case-old-input case))
              (alias (native-open fixture (merge-pathnames "control.log" (rp-case-path case)) :input deadline)))
         (is (equal (native-identity old) (native-identity alias)))
         (ecase state
           (:closed (is (null (io:chiudi old))))
           (:faulted (setf (io::file-state old) :faulted)))
         (rp-reject fixture case deadline (rp-case-recovered case) 'io-fault :io-unavailable)
         (is (eq state (io:stato-file old))) (is (eq :open (io:stato-file alias)))
         (let ((retry (rp-read fixture (rp-case-view case) alias (rp-case-old-bytes case)
                               (rp-case-old-prefix case) :complete version deadline)))
           (rp-success fixture case deadline retry)
           (is (eq state (io:stato-file old)))
           (rp-oracle fixture case deadline alias)))))))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-003 REQ-AFF-001 REQ-AFF-018
(deftest test-REQ-REC-001-CONTROL-RECOVERY-publication-success-v1-real-inodes-frontiers
  (rp-run (lambda (fixture deadline)
            (let ((case (rp-setup fixture (native-fixture-root fixture) 1 deadline)))
              (rp-success fixture case deadline) (rp-oracle fixture case deadline)))))

;;; REQ: REQ-REC-001 REQ-FOR-001 REQ-FOR-003 REQ-AFF-001 REQ-AFF-018
(deftest test-REQ-REC-001-CONTROL-RECOVERY-publication-success-v2-real-inodes-frontiers
  (rp-run (lambda (fixture deadline)
            (let ((case (rp-setup fixture (native-fixture-root fixture) 2 deadline)))
              (rp-success fixture case deadline) (rp-oracle fixture case deadline)))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-008
(deftest test-REQ-AFF-001-CONTROL-RECOVERY-publication-readonly-capability-exact-no-append-substitution
  (dolist (version '(1 2))
    (rp-run
     (lambda (fixture deadline)
       (let* ((case (rp-setup fixture (native-fixture-root fixture) version deadline))
              (before (rp-observations fixture)) (delivered nil))
         (native-reset-calls fixture)
         (let ((condition (native-capture-product-error
                           (lambda ()
                             (setf delivered
                                   (c:leggi-control-recuperato
                                    (rp-case-view case) (rp-case-old-append case)
                                    (length (rp-case-old-bytes case)) (zeros (length (rp-case-old-bytes case)))
                                    :chunk-bytes 31 :max-bytes 4096 :max-batches 1 :max-batch-records 1
                                    :max-edits 1 :max-segmenti 4 :max-esiti 2))))))
           (is (typep condition 'invalid-argument)) (is (eq :io-mode (error-reason condition)))
           (is (null delivered)))
         (is (every #'zerop (native-observer-calls (native-fixture-observer fixture))))
         (is (equal before (rp-observations fixture)))
         (rp-state case :prepared nil)
         (rp-success fixture case deadline) (rp-oracle fixture case deadline))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-AFF-018-CONTROL-RECOVERY-publication-same-uuid-different-view-preclaim-valid-retry
  (dolist (version '(1 2))
    (rp-run
     (lambda (fixture deadline)
       (let* ((case (rp-setup fixture (native-fixture-root fixture) version deadline))
              (other (native-view (copy-seq (rp-case-identity case))))
              (recovered (rp-read fixture other (rp-case-old-input case) (rp-case-old-bytes case)
                                  (rp-case-old-prefix case) :complete version deadline)))
         (is (not (eq other (rp-case-view case))))
         (rp-manifest (c:manifest-control-recuperato recovered) nil)
         (rp-reject fixture case deadline recovered 'invalid-argument :control-recovery-view)
         (rp-success fixture case deadline) (rp-oracle fixture case deadline))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-AFF-018-CONTROL-RECOVERY-publication-different-uuid-view-preclaim-valid-retry
  (dolist (version '(1 2))
    (rp-run
     (lambda (fixture deadline)
       (let* ((case (rp-setup fixture (native-fixture-root fixture) version deadline))
              (identity (copy-seq (rp-case-identity case))))
         (setf (aref identity 0) (logxor 1 (aref identity 0)))
         (let* ((other (native-view identity))
                (bytes (control-reference-checkpoint identity version (rp-previous-payload) 19))
                (input (rp-seed fixture (rp-case-path case) "foreign-control.tmp" bytes deadline))
                (recovered (rp-read fixture other input bytes (length bytes) :complete version deadline)))
           (is (not (equalp identity (rp-case-identity case))))
           (rp-manifest (c:manifest-control-recuperato recovered) nil)
           (rp-reject fixture case deadline recovered 'invalid-argument :control-recovery-view)
           (rp-success fixture case deadline) (rp-oracle fixture case deadline)))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-AFF-018-CONTROL-RECOVERY-publication-invalid-transition-no-effects-token-usable
  ;; Ogni risultato contraddittorio proviene da un file reale separato; il retry usa quello autorevole.
  (dolist (version '(1 2))
    (dolist (variant '(:active-reused :active-not-closed :segment-counts :closed-changed :outcome-changed :removed-changed))
      (rp-run
       (lambda (fixture deadline)
         (let* ((case (rp-setup fixture (native-fixture-root fixture) version deadline))
                (bad (rp-decoy fixture case variant deadline))
                (reason (ecase variant
                          (:active-reused :recovery-active-reused) (:active-not-closed :recovery-active-not-closed)
                          (:segment-counts :recovery-segment-counts) (:closed-changed :recovery-closed-changed)
                          (:outcome-changed :recovery-outcome-changed) (:removed-changed :recovery-removed-changed))))
           (rp-reject fixture case deadline bad 'invalid-argument reason)
           (rp-success fixture case deadline) (rp-oracle fixture case deadline)))))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-018
(deftest test-REQ-AFF-001-CONTROL-RECOVERY-publication-closed-exact-old-input-preclaim-alias-valid-retry
  (rp-unavailable :closed))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-018
(deftest test-REQ-AFF-001-CONTROL-RECOVERY-publication-faulted-exact-old-input-preclaim-alias-valid-retry
  (rp-unavailable :faulted))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-018
(deftest test-REQ-AFF-018-CONTROL-RECOVERY-publication-false-association-rename-binding-still-guards
  (dolist (version '(1 2))
    (rp-run
     (lambda (fixture deadline)
       (let* ((case (rp-setup fixture (native-fixture-root fixture) version deadline))
              (decoy (rp-decoy fixture case :canonical deadline))
              (before (rp-observations fixture)) (delivered nil))
         (is (null (arcdocdb.recovery.manifest:verifica-transizione-recovery
                    (c:manifest-control-recuperato decoy)
                    (c:manifest-control-preparato (native-checkpoint-prepared (rp-case-new case))))))
         (native-reset-calls fixture)
         (let ((condition (native-capture-product-error
                           (lambda () (setf delivered (rp-publish case deadline decoy))))))
           (is (typep condition 'invalid-argument))
           (is (eq :io-replacement-identity (error-reason condition))) (is (null delivered)))
         (is (equalp #(0 0 0 0 0 0 2 2 0)
                     (native-observer-calls (native-fixture-observer fixture))))
         (rp-state case :faulted nil)
         (is (equal before (rp-observations fixture)))
         (is (equal (rp-case-old-inode case)
                    (native-path-identity (merge-pathnames "control.log" (rp-case-path case)))))
         (native-read-bytes (rp-case-old-input case) (rp-case-old-bytes case) deadline)
         (native-read-bytes (native-checkpoint-input (rp-case-new case))
                            (native-checkpoint-bytes (rp-case-new case)) deadline)
         (rp-reject fixture case deadline (rp-case-recovered case)
                    'invalid-argument :control-publication-state :faulted nil))))))

;;; REQ: REQ-REC-001 REQ-AFF-009 REQ-AFF-017 REQ-AFF-018
(deftest test-REQ-AFF-017-CONTROL-RECOVERY-publication-old-tail-authoritative-stable-eof-allowed
  (dolist (version '(1 2))
    (rp-run
     (lambda (fixture deadline)
       (let ((case (rp-setup fixture (native-fixture-root fixture) version deadline t)))
         (is (= (length (rp-case-old-bytes case)) (+ 17 (rp-case-old-prefix case))))
         (rp-success fixture case deadline) (rp-oracle fixture case deadline))))))

(defun rp-sync-fault (original-p)
  (dolist (version '(1 2))
    (rp-run
     (lambda (fixture deadline)
       (let* ((case (rp-setup fixture (native-fixture-root fixture) version deadline))
              (observer (native-fixture-observer fixture))
              (failure (if original-p
                           (make-condition 'io-fault :reason :rp-directory-sync :operation :flush :errno sb-posix:eio)
                           (make-condition 'sb-posix:syscall-error :errno sb-posix:eio :name 'rp-injected-fsync)))
              (before (rp-data-observations fixture)) (observed nil) (delivered nil))
         (setf (native-observer-directory-failure observer) failure)
         (native-reset-calls fixture)
         (let ((condition (native-capture-product-error
                           (lambda ()
                             (handler-bind ((io-fault (lambda (original) (setf observed original))))
                               (setf delivered (rp-publish case deadline)))))))
           (is (typep condition 'io-fault)) (is (eq condition observed))
           (when original-p (is (eq failure condition)))
           (is (eq (if original-p :rp-directory-sync :io-syscall) (error-reason condition)))
           (is (eq :flush (error-operation condition))) (is (= sb-posix:eio (error-errno condition)))
           (is (null delivered)))
         (is (equalp #(0 0 0 0 1 0 3 3 1) (native-observer-calls observer)))
         (rp-state case :faulted t) (is (eq :faulted (io:stato-file (rp-case-directory case))))
         (is (equal before (rp-data-observations fixture)))
         (setf (native-observer-directory-failure observer) nil)
         ;; Il rename è visibile; fsync fallito non viene presentato come durability confermata.
         (rp-oracle fixture case deadline)
         (rp-reject fixture case deadline (rp-case-recovered case)
                    'invalid-argument :control-publication-state :faulted t))))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-RECOVERY-publication-postclaim-directory-syscall-fault-no-wrapper
  (rp-sync-fault nil))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(deftest test-REQ-AFF-004-CONTROL-RECOVERY-publication-postclaim-original-directory-condition-preserved
  (rp-sync-fault t))

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-AFF-018
(deftest test-REQ-AFF-004-CONTROL-RECOVERY-publication-postclaim-nonlocal-values-preserved
  ;; CATCH/THROW soltanto come FI: uscita dal callback fsync, mai flusso ordinario.
  (dolist (version '(1 2))
    (rp-run
     (lambda (fixture deadline)
       (let* ((case (rp-setup fixture (native-fixture-root fixture) version deadline))
              (observer (native-fixture-observer fixture)) (tag (gensym "RP-ESCAPE-"))
              (marker (list :original-nonlocal)) (escape (make-condition 'rp-directory-escape))
              (before (rp-data-observations fixture)) (delivered nil))
         (setf (native-observer-directory-failure observer) escape)
         (native-reset-calls fixture)
         (let ((result (multiple-value-list
                        (catch tag
                          (handler-bind ((rp-directory-escape
                                          (lambda (condition)
                                            (is (eq escape condition))
                                            (throw tag (values marker :second-value)))))
                            (setf delivered (rp-publish case deadline)))))))
           (is (eq marker (first result))) (is (equal (list marker :second-value) result)))
         (is (null delivered)) (rp-state case :faulted t)
         (is (eq :faulted (io:stato-file (rp-case-directory case))))
         (is (equalp #(0 0 0 0 1 0 3 3 1) (native-observer-calls observer)))
         (is (equal before (rp-data-observations fixture)))
         (setf (native-observer-directory-failure observer) nil)
         (rp-oracle fixture case deadline))))))

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-AFF-018
(deftest test-REQ-AFF-018-CONTROL-RECOVERY-publication-recovery-result-used-twice-token-consumed
  (dolist (version '(1 2))
    (rp-run
     (lambda (fixture deadline)
       (let ((case (rp-setup fixture (native-fixture-root fixture) version deadline)))
         (rp-success fixture case deadline)
         (rp-reject fixture case deadline (rp-case-recovered case)
                    'invalid-argument :control-publication-state :published t)
         (rp-oracle fixture case deadline))))))

(defun rp-worker (fixture id ready start entered proceed deadline)
  "Unico catch generico nuovo: confine worker FI, restituisce la condizione originale."
  (let ((ready-p nil) (entered-p nil))
    (handler-case
        (progn
          (setf ready-p t) (sb-thread:signal-semaphore ready)
          (native-wait start deadline :rp-worker-start)
          (dotimes (round 2)
            (let* ((path (native-directory fixture (format nil "round-~D/" round) deadline))
                   (case (rp-setup fixture path (if (evenp (+ id round)) 1 2)
                                   deadline nil (+ 64 (* id 16) (* round 2)))))
              (rp-success fixture case deadline) (rp-oracle fixture case deadline))
            (when (zerop round)
              (setf entered-p t) (sb-thread:signal-semaphore entered)
              (native-wait proceed deadline :rp-worker-proceed)))
          :ok)
      (error (condition)
        (unless ready-p (sb-thread:signal-semaphore ready))
        (unless entered-p (sb-thread:signal-semaphore entered))
        condition))))

(defun rp-join (threads deadline)
  "Visita TUTTI i thread; timeout e JOIN-THREAD-ERROR distinti dagli errori del worker."
  (let ((failures nil) (marker (gensym "RP-JOIN-")))
    (dolist (thread threads)
      (let* ((seconds (max 0d0 (/ (- deadline (get-internal-real-time))
                                  (float internal-time-units-per-second 1d0))))
             (result (handler-case (sb-thread:join-thread thread :timeout seconds :default marker)
                       (sb-thread:join-thread-error (condition) condition))))
        (cond
          ((eq result :ok) nil)
          ((eq result marker) (push (make-condition 'native-fixture-timeout :phase :rp-join) failures))
          ((typep result 'condition) (push result failures))
          (t (push (make-condition 'invariant-violation :reason :rp-worker-result) failures)))))
    (values (nreverse failures) (notany #'sb-thread:thread-alive-p threads))))

(defun rp-parallel ()
  "Quattro Serie indipendenti, due round; tutti i join precedono qualsiasi close/cleanup."
  (let ((fixtures (make-array 4 :initial-element nil)) (threads nil) (failures nil)
        (ready (sb-thread:make-semaphore)) (start (sb-thread:make-semaphore))
        (entered (sb-thread:make-semaphore)) (proceed (sb-thread:make-semaphore))
        (deadline (native-deadline 60)))
    (unwind-protect
         (progn
           (dotimes (id 4) (setf (aref fixtures id) (native-fixture deadline)))
           (is (= 4 (length (remove-duplicates (map 'list #'native-fixture-root fixtures) :test #'equal))))
           (dotimes (id 4)
             (let ((worker id))
               (setf (native-fixture-quiescent-p (aref fixtures worker)) nil)
               (push (sb-thread:make-thread
                      (lambda () (rp-worker (aref fixtures worker) worker ready start entered proceed deadline))
                      :name (format nil "CONTROL recovery private worker ~D" worker)) threads)))
           (native-wait ready deadline :rp-ready 4)
           (sb-thread:signal-semaphore start 4)
           (native-wait entered deadline :rp-entered 4)
           (sb-thread:signal-semaphore proceed 4))
      (sb-thread:signal-semaphore start 4) (sb-thread:signal-semaphore proceed 4)
      (multiple-value-bind (worker-failures quiescent) (rp-join threads (native-deadline 10))
        (setf failures worker-failures)
        (dolist (condition worker-failures)
          (format *error-output* "CONTROL recovery-publication worker: ~A~%" condition))
        (if quiescent
            (dotimes (id 4)
              (let ((fixture (aref fixtures id)))
                (when fixture
                  (setf (native-fixture-quiescent-p fixture) t)
                  (setf failures (nconc failures (rp-release fixture))))))
            ;; Tutte le risorse restano al runner isolato, anche quelle dei worker già terminati.
            (push (make-condition 'native-fixture-timeout :phase :rp-quiescence) failures))))
    (when failures
      (error (or (find-if-not (lambda (c) (typep c 'native-fixture-timeout)) failures) (first failures))))
    nil))

;;; REQ: REQ-REC-001 REQ-CON-004 REQ-AFF-002 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-CON-004-CONTROL-RECOVERY-publication-independent-four-workers-two-rounds-v1-v2
  (rp-parallel))
