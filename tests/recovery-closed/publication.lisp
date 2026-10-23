;;;; Catena nativa readonly CLOSED -> insieme completo -> publisher CONTROL canonico, v1/v2.
;;;; Byte attesi da packing/CRC indipendenti; piani dal builder pubblico da ACTIVE.
;;;; CLOSED writer con CSN zero/alto e abort; compaction senza SEAL; code fisiche oltre P.
;;; OWNER: ct::rp-run possiede root 0700, <=128 FD/64 nomi/16 directory; deadline seriale 30s.
;;; SHARED: nessun worker o FI globale; l'observer privato conserva i contatori del backend.
;;; Limiti: file <=4096 byte; non qualifica power loss, inventario globale o motore completo.
(in-package #:arcdocdb.recovery.closed.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defstruct (cpub-segment (:constructor cpub-make-segment))
  id prefix version origin bytes outcomes statistics input)

(defstruct (cpub-case (:constructor cpub-make-case))
  path directory identity view version control-input control-bytes control
  input bytes prefix recovered active checkpoint decision-input decision-bytes segments closed)

(defun cpub-writer (version tail-p)
  "CLOSED2: due commit solo EDIT, un presumed abort; nessun DECISION necessario."
  (let* ((bytes (cdr-log
                 (list (cdr-batch 41
                         (cdr-record :prepared-put 101 :value #(246))
                         (cdr-record :prepared-tombstone 102)
                         (cdr-record :prepared-put 103 :value #(245))))
                 :version version :id 2))
         (prefix (length bytes)))
    (cpub-make-segment :id 2 :prefix prefix :version version :origin 1
      :bytes (if tail-p (ct::crr-cat bytes (ct::zeros 17)) bytes)
      :outcomes '((101 4294967298) (102 0)) :statistics '(1 3 3 0 2 1))))

(defun cpub-compaction (version tail-p)
  "CLOSED7: sole cornici ordinarie, senza SEAL; EOF fisico distinto da P."
  (let* ((bytes (cdr-log nil :version version :id 7 :origin 2
                 :records (list (cdr-record :put #x100000003 :value #(246))
                                (cdr-record :tombstone 0))))
         (prefix (length bytes)))
    (cpub-make-segment :id 7 :prefix prefix :version version :origin 2
      :bytes (if tail-p (ct::crr-cat bytes (ct::zeros 19)) bytes)
      :outcomes nil :statistics '(0 2 0 0 0 0))))

(defun cpub-segments (version history tail-p)
  (ecase history
    (:mixed (list (cpub-writer version tail-p) (cpub-compaction version tail-p)))
    (:empty nil)
    (:header (list (cpub-make-segment :id 2 :prefix 64 :version version :origin 1
                    :bytes (cdr-log nil :version version :id 2
                             :tail (when tail-p (ct::zeros 23)))
                    :outcomes nil :statistics '(0 0 0 0 0 0))))))

(defun cpub-entries (case)
  "Fatti dichiarati prima delle factory, non estratti da risultati CLOSED."
  (mapcar (lambda (segment)
            (list (cpub-segment-id segment) (cpub-segment-prefix segment)
                  (cpub-segment-outcomes segment)))
          (cpub-case-segments case)))

(defun cpub-readonly (input)
  (is (eq :input (io:mode-file input)))
  (is (eq :open (io:stato-file input)))
  (is (= sb-posix:o-rdonly
         (logand (sb-posix:fcntl (io::file-fd input) sb-posix:f-getfl)
                 (logior sb-posix:o-wronly sb-posix:o-rdwr)))))

(defun cpub-read-control (fixture case input deadline)
  "CONTROL reale readonly; stesso decoder per il primo ingresso e la riapertura finale."
  (let* ((size (sb-posix:stat-size (sb-posix:fstat (io::file-fd input))))
         (scratch (ct::zeros size))
         (before (ct::rp-observations fixture))
         (result (ct::native-bounded deadline :closed-publication-control-read
                   (lambda ()
                     (c:leggi-control-recuperato (cpub-case-view case) input size scratch
                       :chunk-bytes 31 :max-bytes 4096 :max-batches 2 :max-batch-records 1
                       :max-edits 1 :max-segmenti 8 :max-esiti 8)))))
    (cpub-readonly input)
    (is (equal before (ct::rp-observations fixture)))
    (is (equal (list size size :complete (cpub-case-version case))
               (multiple-value-list (c:frontiere-control-recuperato result))))
    (fill scratch #xa5)
    result))

(defun cpub-read-segment (fixture case segment deadline
                          &optional (control (cpub-case-control case))
                                    (input (cpub-segment-input segment)))
  "Legge P dal manifest, controlla canary oltre P e nessuna syscall diversa da pread."
  (let* ((prefix (cpub-segment-prefix segment)) (scratch (ct::crr-bytes (+ prefix 7) #xcc))
         (before (ct::rp-observations fixture)))
    (cpub-readonly input)
    (is (= (length (cpub-segment-bytes segment))
           (sb-posix:stat-size (sb-posix:fstat (io::file-fd input)))))
    (ct::native-reset-calls fixture)
    (let ((result (ct::native-bounded deadline :closed-publication-segment-read
                    (lambda ()
                      (cr:leggi-closed-recuperato control input (cpub-segment-id segment) scratch
                        :chunk-bytes 31 :max-bytes 4096 :max-batches 2 :max-records 8
                        :max-batch-records 8 :max-batch-bytes 4096
                        :max-prepared 8 :max-outcomes 8 :max-esiti-chiusura 8)))))
      (is (equalp (vector 0 (1+ (ceiling (- prefix 64) 31)) 0 0 0 0 0 0 0)
                  (ct::native-observer-calls (ct::native-fixture-observer fixture))))
      (is (equal before (ct::rp-observations fixture)))
      (is (equalp (subseq scratch 0 prefix) (subseq (cpub-segment-bytes segment) 0 prefix)))
      (is (every (lambda (byte) (= byte #xcc)) (subseq scratch prefix)))
      (is (equal (list (cpub-segment-id segment) prefix (cpub-segment-version segment)
                       (cpub-segment-origin segment))
                 (multiple-value-list (cr:frontiere-closed-recuperato result))))
      (is (equal (cpub-segment-statistics segment)
                 (multiple-value-list (cr:statistiche-closed-recuperato result))))
      (fill scratch #xa5)
      result)))

(defun cpub-read-decisions (case deadline)
  "Intero log dell'Archivio letto dal FD reale, con ambito canonico della Serie."
  (let* ((input (cpub-case-decision-input case)) (bytes (cpub-case-decision-bytes case))
         (size (sb-posix:stat-size (sb-posix:fstat (io::file-fd input))))
         (scratch (ct::zeros size))
         (archive (da:crea-archivio-recovery
                    (arcdocdb.get::vista-get-serie-scope (cpub-case-view case))
                    (rt::participant-id 77 64)))
         (result (ct::native-bounded deadline :closed-publication-decisions
                   (lambda ()
                     (da:leggi-decisioni-recuperate archive input size scratch
                       :chunk-bytes 31 :max-bytes 4096 :max-batches 1
                       :max-batch-records 2 :max-batch-bytes 4096 :max-decisions 2
                       :max-participants 4 :max-participants-per-decision 2)))))
    (is (= size (length bytes))) (is (equalp bytes scratch))
    (is (equal (list size size :complete (cpub-case-version case))
               (multiple-value-list (da:frontiere-decisioni-recuperate result))))
    (is (= 2 (da:numero-decisioni-recuperate result)))
    (is (equal '(t 0 2) (multiple-value-list (da:trova-decisione-recuperata result 201))))
    (is (equal '(t #xfedcba9876543210 2)
               (multiple-value-list (da:trova-decisione-recuperata result 202))))
    (fill scratch #xa5)
    result))

(defun cpub-read-active (fixture case decisions deadline)
  "Ingresso autorevole pubblico; il risultato sopravvive alla distruzione dello scratch."
  (let* ((input (cpub-case-input case)) (size (length (cpub-case-bytes case)))
         (scratch (ct::zeros size)) (before (ct::rp-observations fixture))
         (result (ct::native-bounded deadline :closed-publication-active
                   (lambda ()
                     (da:leggi-active-con-decisioni (cpub-case-control case) input size decisions scratch
                       :chunk-bytes 31 :max-bytes 4096 :max-batches 2 :max-batch-records 3
                       :max-batch-bytes 4096 :max-records 3 :max-prepared 3 :max-outcomes 2)))))
    (cpub-readonly input)
    (is (= size (sb-posix:stat-size (sb-posix:fstat (io::file-fd input)))))
    (is (equalp scratch (cpub-case-bytes case)))
    (is (equal before (ct::rp-observations fixture)))
    (is (equal (list size (cpub-case-prefix case)
                     (if (= size (cpub-case-prefix case)) :complete :tail) (cpub-case-version case))
               (multiple-value-list (arcdocdb.recovery.active:frontiere-active-recuperato result))))
    (is (equal '(1 3 3 0 2 1)
               (multiple-value-list (arcdocdb.recovery.active:statistiche-active-recuperato result))))
    (dolist (fact '((201 0) (202 #xfedcba9876543210)))
      (is (equal (cons t (rest fact))
                 (multiple-value-list
                  (arcdocdb.recovery.active:esito-chiusura-active result (first fact))))))
    (fill scratch #xa5)
    result))

(defun cpub-setup (fixture version deadline &key (history :mixed) (tail-p t))
  "Seed .tmp/flush/rename/dirflush; solo lettori pubblici costruiscono i risultati."
  (let* ((path (ct::native-fixture-root fixture))
         (directory (ct::native-open fixture path :directory deadline))
         (case (cpub-make-case :path path :directory directory :identity (ct::crr-uuid)
                 :view (ct::native-view (ct::crr-uuid)) :version version
                 :segments (cpub-segments version history tail-p))))
    (setf (cpub-case-control-bytes case)
          (ct::control-reference-checkpoint (cpub-case-identity case) version
            (ct::rp-payload 9 10 (cpub-entries case) '(3)) 19)
          (cpub-case-control-input case)
          (av::apub-seed fixture path directory "control.log" (cpub-case-control-bytes case) deadline)
          (cpub-case-control case)
          (cpub-read-control fixture case (cpub-case-control-input case) deadline))
    (dolist (segment (cpub-case-segments case))
      (setf (cpub-segment-input segment)
            (av::apub-seed fixture path directory (format nil "~D.seg" (cpub-segment-id segment))
                           (cpub-segment-bytes segment) deadline)))
    (let ((bytes (cdr-log
                  (list (cdr-batch 43 (cdr-record :prepared-put 201 :value #(246))
                                     (cdr-record :prepared-tombstone 202)
                                     (cdr-record :prepared-put 203 :value #(245))))
                  :version version :id 9)))
      (setf (cpub-case-prefix case) (length bytes)
            (cpub-case-bytes case) (if tail-p (ct::crr-cat bytes (ct::zeros 17)) bytes)
            (cpub-case-input case)
            (av::apub-seed fixture path directory "9.seg" (cpub-case-bytes case) deadline)))
    (setf (cpub-case-decision-bytes case)
          (rac::ra-decision-log version (rt::participant-id 77 64) (cpub-case-identity case)
            (list (rac::ra-decision 201 0) (rac::ra-decision 202 #xfedcba9876543210)))
          (cpub-case-decision-input case)
          (av::apub-seed fixture path directory "multiserie.log" (cpub-case-decision-bytes case) deadline)
          (cpub-case-recovered case)
          (cpub-read-active fixture case (cpub-read-decisions case deadline) deadline))
    ;; Da questo punto CLOSED e publisher devono riuscire con DECISION non disponibile.
    (is (null (io:chiudi (cpub-case-decision-input case))))
    (setf (cpub-case-closed case)
          (map 'simple-vector (lambda (segment) (cpub-read-segment fixture case segment deadline))
               (cpub-case-segments case)))
    case))

(defun cpub-prepare (fixture case deadline)
  "Il builder conserva tutte le vecchie entry e chiude ACTIVE9 al suo P verificato."
  (let* ((active (ct::native-active fixture (cpub-case-directory case) (cpub-case-path case)
                                  (cpub-case-view case) 13 (cpub-case-version case) deadline))
         (expected (ct::control-reference-checkpoint (cpub-case-identity case) (cpub-case-version case)
                     (ct::rp-payload 13 14
                       (append (cpub-entries case)
                               (list (list 9 (cpub-case-prefix case) '((201 0) (202 #xfedcba9876543210)))))
                       '(3)) 23))
         (before (ct::rp-observations fixture)))
    (ct::native-reset-calls fixture)
    (let ((plan (arcdocdb.recovery.checkpoint:crea-checkpoint-da-active
                 (cpub-case-recovered case) active 23
                 :max-payload 4096 :max-segmenti 8 :max-esiti 8 :budget-workspace 4096)))
      (is (every #'zerop (ct::native-observer-calls (ct::native-fixture-observer fixture))))
      (is (equal before (ct::rp-observations fixture)))
      (is (= (length expected) (c:lunghezza-checkpoint-control plan)))
      (let ((checkpoint (ct::native-prepare-plan fixture (cpub-case-path case) (cpub-case-directory case)
                                                "control.log.tmp" plan deadline)))
        (is (equalp expected (ct::native-checkpoint-bytes checkpoint)))
        (ct::native-read-bytes (ct::native-checkpoint-input checkpoint) expected deadline)
        (setf (cpub-case-active case) active (cpub-case-checkpoint case) checkpoint)))
    case))

(defun cpub-prepared (case)
  (ct::native-checkpoint-prepared (cpub-case-checkpoint case)))

(defun cpub-state (case state renamed-p)
  (is (equal (list state renamed-p)
             (multiple-value-list (c:stato-pubblicazione-control (cpub-prepared case)))))
  (when (eq state :prepared)
    (is (null (c::control-preparato-publication-owner (cpub-prepared case))))))

(defun cpub-publish (case deadline closed &key (max-segmenti 8))
  (ct::native-bounded deadline :closed-publication
    (lambda () (cr:pubblica-control-con-closed (cpub-prepared case) (cpub-case-recovered case)
                                              closed :max-segmenti max-segmenti))))

(defun cpub-reject (fixture case deadline closed type reason
                   &key (max-segmenti 8) (state :prepared) renamed-p)
  "Rifiuto senza claim: stessi byte, nomi, FD/frontiere; nessuna callback del backend."
  (let ((before (ct::rp-observations fixture)) (namespace (av::apub-namespace fixture))
        (bytes (av::apub-file-bytes fixture deadline)) (delivered nil))
    (ct::native-reset-calls fixture)
    (let ((condition (ct::native-capture-product-error
                      (lambda () (setf delivered (cpub-publish case deadline closed
                                                  :max-segmenti max-segmenti))))))
      (is (typep condition type)) (is (eq reason (error-reason condition)))
      (is (null delivered)))
    (is (every #'zerop (ct::native-observer-calls (ct::native-fixture-observer fixture))))
    (is (equal before (ct::rp-observations fixture)))
    (is (equal namespace (av::apub-namespace fixture)))
    (cpub-state case state renamed-p)
    (is (equalp bytes (av::apub-file-bytes fixture deadline)))))

(defun cpub-check-manifest (case manifest)
  "Oracolo scalare: tutti i CLOSED precedenti, REMOVED3 e la chiusura esatta di ACTIVE9."
  (is (= 13 (arcdocdb.recovery.manifest:segmento-attivo manifest)))
  (is (equal '(t 14) (multiple-value-list (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))
  (is (= (1+ (length (cpub-case-segments case)))
         (arcdocdb.recovery.manifest:numero-segmenti-chiusi manifest)))
  (is (= 1 (arcdocdb.recovery.manifest:numero-segmenti-rimossi manifest)))
  (dolist (fact '((13 :active 0 0) (3 :removed 0 0)))
    (is (equal (rest fact)
               (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest (first fact))))))
  (dolist (entry (append (cpub-entries case)
                        (list (list 9 (cpub-case-prefix case) '((201 0) (202 #xfedcba9876543210))))))
    (destructuring-bind (id prefix outcomes) entry
      (is (equal (list :closed prefix (length outcomes))
                 (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest id))))
      (dolist (outcome outcomes)
        (is (equal (list t (second outcome))
                   (multiple-value-list
                    (arcdocdb.recovery.manifest:trova-esito-chiusura manifest id (first outcome))))))))
  (dolist (fact '((2 103) (7 101) (9 203) (9 999)))
    (is (equal '(nil 0)
               (multiple-value-list
                (arcdocdb.recovery.manifest:trova-esito-chiusura manifest (first fact) (second fact))))))
  nil)

(defun cpub-original-bytes (case deadline)
  "Legge solo capacità ancora vive; il decision log resta chiuso durante l'intera catena CLOSED."
  (ct::native-read-bytes (cpub-case-control-input case) (cpub-case-control-bytes case) deadline)
  (ct::native-read-bytes (cpub-case-input case) (cpub-case-bytes case) deadline)
  (dolist (segment (cpub-case-segments case))
    (cpub-readonly (cpub-segment-input segment))
    (ct::native-read-bytes (cpub-segment-input segment) (cpub-segment-bytes segment) deadline)
    (is (equal (ct::native-identity (cpub-segment-input segment))
               (ct::native-path-identity
                (merge-pathnames (format nil "~D.seg" (cpub-segment-id segment)) (cpub-case-path case))))))
  (is (eq :closed (io:stato-file (cpub-case-decision-input case)))))

(defun cpub-oracle (fixture case deadline)
  "Riapre il nome installato; byte indipendenti e manifest ricostruito dal nuovo FD readonly."
  (let* ((checkpoint (cpub-case-checkpoint case))
         (target (merge-pathnames "control.log" (cpub-case-path case)))
         (input (ct::native-open fixture target :input deadline))
         (expected (ct::native-checkpoint-bytes checkpoint)))
    (cpub-readonly input)
    (is (equal (ct::native-path-identity target) (ct::native-identity input)))
    (is (equal (ct::native-identity input) (ct::native-identity (ct::native-checkpoint-input checkpoint))))
    (is (not (equal (ct::native-identity input) (ct::native-identity (cpub-case-control-input case)))))
    (ct::native-absent (merge-pathnames "control.log.tmp" (cpub-case-path case)))
    (ct::native-read-bytes input expected deadline)
    (cpub-check-manifest case
      (c:manifest-control-recuperato (cpub-read-control fixture case input deadline)))
    (cpub-original-bytes case deadline)))

(defun cpub-success (fixture case deadline &optional (closed (cpub-case-closed case)))
  "Unico rename/fsync; nessuna pread, scrittura, chiusura o variazione dei vecchi FD."
  (let* ((before (ct::rp-observations fixture)) (namespace (av::apub-namespace fixture))
         (bytes (av::apub-file-bytes fixture deadline))
         (source (merge-pathnames "control.log.tmp" (cpub-case-path case)))
         (target (merge-pathnames "control.log" (cpub-case-path case)))
         (checkpoint (cpub-case-checkpoint case)))
    (ct::native-reset-calls fixture)
    (is (null (cr:verifica-closed-completi (cpub-case-control case) closed :max-segmenti 8)))
    (is (every #'zerop (ct::native-observer-calls (ct::native-fixture-observer fixture))))
    (let ((published (cpub-publish case deadline closed)))
      (is (typep published 'c:control-pubblicato))
      (is (equalp #(0 0 0 0 1 0 3 3 1)
                  (ct::native-observer-calls (ct::native-fixture-observer fixture))))
      (cpub-state case :published t)
      (is (eq (cpub-case-active case) (c:active-control-pubblicato published)))
      (is (eq (c:manifest-control-preparato (cpub-prepared case)) (c:manifest-control-pubblicato published)))
      (is (eq (c:log-control-preparato (cpub-prepared case)) (c:log-control-pubblicato published)))
      (cpub-check-manifest case (c:manifest-control-pubblicato published)))
    (is (equal before (ct::rp-observations fixture)))
    (is (equalp bytes (av::apub-file-bytes fixture deadline)))
    (is (equal (second (assoc source namespace :test #'equal)) (ct::native-path-identity target)))
    (dolist (entry namespace)
      (unless (member (first entry) (list source target) :test #'equal)
        (is (equal entry (assoc (first entry) (av::apub-namespace fixture) :test #'equal)))))
    (is (= (length (ct::native-checkpoint-bytes checkpoint))
           (io:posizione-scritta (ct::native-checkpoint-append checkpoint))
           (io:posizione-durevole (ct::native-checkpoint-append checkpoint))))
    (cpub-oracle fixture case deadline)
    (cpub-reject fixture case deadline closed 'invalid-argument :control-publication-state
                 :state :published :renamed-p t)))

(defun cpub-success-case (version &key (history :mixed) (tail-p t) reverse-p)
  (ct::rp-run
   (lambda (fixture deadline)
     (let ((case (cpub-setup fixture version deadline :history history :tail-p tail-p)))
       (cpub-prepare fixture case deadline)
       (cpub-success fixture case deadline
                     (if reverse-p (reverse (cpub-case-closed case)) (cpub-case-closed case)))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-STO-006 REQ-AFF-018
(deftest test-REQ-REC-001-CLOSED-publication-native-v1-writer-compaction-tail-readonly
  (cpub-success-case 1)
  (cpub-success-case 1 :tail-p nil :reverse-p t))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-STO-006 REQ-AFF-018
(deftest test-REQ-REC-001-CLOSED-publication-native-v2-complete-set-unordered
  (cpub-success-case 2 :reverse-p t)
  (cpub-success-case 2 :tail-p nil))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-008
(deftest test-REQ-REC-001-CLOSED-publication-empty-set-and-header-prefix-v1-v2
  (dolist (version '(1 2))
    (dolist (history '(:empty :header))
      (cpub-success-case version :history history))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-REC-001-CLOSED-publication-missing-extra-before-claim-token-reusable
  (dolist (version '(1 2))
    (ct::rp-run
     (lambda (fixture deadline)
       (let* ((case (cpub-setup fixture version deadline)) (closed (cpub-case-closed case)))
         (cpub-prepare fixture case deadline)
         (dolist (bad (list #() (vector (aref closed 0))
                           (concatenate 'simple-vector closed (vector (aref closed 0)))))
           (cpub-reject fixture case deadline bad 'invalid-argument :closed-recovery-set-count))
         (cpub-success fixture case deadline))))))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-008
(deftest test-REQ-REC-001-CLOSED-publication-duplicate-id-same-result-or-distinct-readonly-alias
  (dolist (version '(1 2))
    (ct::rp-run
     (lambda (fixture deadline)
       (let* ((case (cpub-setup fixture version deadline)) (closed (cpub-case-closed case))
              (segment (first (cpub-case-segments case)))
              (alias (ct::native-open fixture (merge-pathnames "2.seg" (cpub-case-path case)) :input deadline))
              (duplicate (cpub-read-segment fixture case segment deadline (cpub-case-control case) alias)))
         (is (not (eq duplicate (aref closed 0))))
         (is (equal (ct::native-identity alias) (ct::native-identity (cpub-segment-input segment))))
         (cpub-prepare fixture case deadline)
         (dolist (bad (list (vector (aref closed 0) (aref closed 0)) (vector (aref closed 0) duplicate)))
           (cpub-reject fixture case deadline bad 'invalid-argument :closed-recovery-set-duplicate))
         (cpub-success fixture case deadline))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-018
(deftest test-REQ-REC-001-CLOSED-publication-different-control-same-bytes-same-or-alias-fd
  (dolist (version '(1 2))
    (ct::rp-run
     (lambda (fixture deadline)
       (let* ((case (cpub-setup fixture version deadline)) (closed (cpub-case-closed case))
              (segment (first (cpub-case-segments case))))
         (cpub-prepare fixture case deadline)
         (dolist (alias-p '(nil t))
           (let* ((input (if alias-p
                             (ct::native-open fixture (merge-pathnames "control.log" (cpub-case-path case))
                                              :input deadline)
                             (cpub-case-control-input case)))
                  (other (cpub-read-control fixture case input deadline))
                  (foreign (cpub-read-segment fixture case segment deadline other)))
             (is (not (eq other (cpub-case-control case))))
             (is (equal (ct::native-identity input) (ct::native-identity (cpub-case-control-input case))))
             (ct::native-read-bytes input (cpub-case-control-bytes case) deadline)
             (cpub-reject fixture case deadline (vector foreign (aref closed 1))
                          'invalid-argument :closed-recovery-set-control)))
         (cpub-success fixture case deadline))))))

;;; REQ: REQ-REC-001 REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-008-CLOSED-publication-closed-writer-or-compaction-fd-preclaim-reread-alias
  (dolist (version '(1 2))
    (dotimes (index 2)
      (ct::rp-run
       (lambda (fixture deadline)
         (let* ((case (cpub-setup fixture version deadline)) (closed (cpub-case-closed case))
                (segment (nth index (cpub-case-segments case))) (old (cpub-segment-input segment))
                (alias (ct::native-open fixture
                         (merge-pathnames (format nil "~D.seg" (cpub-segment-id segment)) (cpub-case-path case))
                         :input deadline)))
           (cpub-prepare fixture case deadline)
           (is (equal (ct::native-identity old) (ct::native-identity alias)))
           (is (null (io:chiudi old)))
           (cpub-reject fixture case deadline closed 'io-fault :io-unavailable)
           (setf (cpub-segment-input segment) alias
                 (aref closed index) (cpub-read-segment fixture case segment deadline))
           (cpub-success fixture case deadline)
           (is (eq :closed (io:stato-file old)))))))))

(defun cpub-refresh-active (fixture case deadline)
  "Riparazione della fixture: rilegge DECISION e ACTIVE, poi richiude DECISION prima dei CLOSED."
  (setf (cpub-case-decision-input case)
        (ct::native-open fixture (merge-pathnames "multiserie.log" (cpub-case-path case)) :input deadline)
        (cpub-case-recovered case)
        (cpub-read-active fixture case (cpub-read-decisions case deadline) deadline))
  (is (null (io:chiudi (cpub-case-decision-input case)))))

;;; REQ: REQ-REC-001 REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-008-CLOSED-publication-closed-control-or-active-fd-preclaim-recovery
  (dolist (version '(1 2))
    (dolist (kind '(:control :active))
      (ct::rp-run
       (lambda (fixture deadline)
         (let* ((case (cpub-setup fixture version deadline)) (control-p (eq kind :control))
                (old (if control-p (cpub-case-control-input case) (cpub-case-input case)))
                (alias (ct::native-open fixture
                         (merge-pathnames (if control-p "control.log" "9.seg") (cpub-case-path case))
                         :input deadline)))
           (cpub-prepare fixture case deadline)
           (is (equal (ct::native-identity old) (ct::native-identity alias)))
           (is (null (io:chiudi old)))
           (cpub-reject fixture case deadline (cpub-case-closed case) 'io-fault :io-unavailable)
           (if control-p
               (setf (cpub-case-control-input case) alias
                     (cpub-case-control case) (cpub-read-control fixture case alias deadline))
               (setf (cpub-case-input case) alias))
           (cpub-refresh-active fixture case deadline)
           (setf (cpub-case-closed case)
                 (map 'simple-vector (lambda (segment) (cpub-read-segment fixture case segment deadline))
                      (cpub-case-segments case)))
           (cpub-success fixture case deadline)
           (is (eq :closed (io:stato-file old)))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-AFF-008-CLOSED-publication-set-budget-before-count-and-exact-boundary
  (dolist (version '(1 2))
    (ct::rp-run
     (lambda (fixture deadline)
       (let* ((case (cpub-setup fixture version deadline)) (closed (cpub-case-closed case))
              (extra (concatenate 'simple-vector closed (vector (aref closed 0)))))
         (cpub-prepare fixture case deadline)
         (dolist (limit '(0 1))
           (cpub-reject fixture case deadline closed 'resource-exhausted :closed-recovery-set-budget
                        :max-segmenti limit))
         ;; Budget precede anche il rifiuto per cardinalita errata/duplicato.
         (cpub-reject fixture case deadline extra 'resource-exhausted :closed-recovery-set-budget
                      :max-segmenti 2)
         (ct::native-reset-calls fixture)
         (is (null (cr:verifica-closed-completi (cpub-case-control case) closed :max-segmenti 2)))
         (is (every #'zerop (ct::native-observer-calls (ct::native-fixture-observer fixture))))
         (cpub-success fixture case deadline))))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004 REQ-AFF-018
(deftest test-REQ-AFF-004-CLOSED-publication-private-directory-fsync-original-fault-after-rename
  (dolist (version '(1 2))
    (ct::rp-run
     (lambda (fixture deadline)
       (let* ((case (cpub-setup fixture version deadline))
              (observer (ct::native-fixture-observer fixture))
              (original (make-condition 'io-fault :reason :closed-publication-sync
                                        :operation :flush :errno sb-posix:eio))
              (delivered nil) (observed nil))
         (cpub-prepare fixture case deadline)
         (let ((before (ct::rp-data-observations fixture))
               (namespace (av::apub-namespace fixture)) (bytes (av::apub-file-bytes fixture deadline)))
           (setf (ct::native-observer-directory-failure observer) original)
           (ct::native-reset-calls fixture)
           (let ((condition (ct::native-capture-product-error
                             (lambda ()
                               (handler-bind ((io-fault (lambda (failure) (setf observed failure))))
                                 (setf delivered (cpub-publish case deadline (cpub-case-closed case))))))))
             (is (eq original condition)) (is (eq observed condition)) (is (null delivered))
             (is (eq :closed-publication-sync (error-reason condition)))
             (is (eq :flush (arcdocdb.conditions:error-operation condition)))
             (is (= sb-posix:eio (arcdocdb.conditions:error-errno condition))))
           (is (equalp #(0 0 0 0 1 0 3 3 1) (ct::native-observer-calls observer)))
           (cpub-state case :faulted t)
           (is (eq :faulted (io:stato-file (cpub-case-directory case))))
           (is (equal before (ct::rp-data-observations fixture)))
           (is (equalp bytes (av::apub-file-bytes fixture deadline)))
           (is (equal (second (assoc (merge-pathnames "control.log.tmp" (cpub-case-path case))
                                    namespace :test #'equal))
                      (ct::native-path-identity (merge-pathnames "control.log" (cpub-case-path case)))))
           (setf (ct::native-observer-directory-failure observer) nil)
           ;; Riapertura prova rename osservato e leggibilita, senza attestare durability.
           (cpub-oracle fixture case deadline)
           (cpub-reject fixture case deadline (cpub-case-closed case)
                        'invalid-argument :control-publication-state :state :faulted :renamed-p t)))))))
