;;;; Recovery ACTIVE -> entry CLOSED -> checkpoint reale -> rename/fsync, v1/v2.
;;;; Dipendenze: support ACTIVE, fixture CONTROL native/recovery-publication e DECISION.
;;;; CONTROL iniziale: ACTIVE9/next10, CLOSED2 con due esiti storici, REMOVED3.
;;;; ACTIVE9: due lotti, sette record, quattro TXID prepared distinti; locale1/derivati2/abort1.
;;;; Derivati: TXID17/CSN0 e TXID massimo/CSN alto; ordine fisico diverso da quello CLOSED.
;;;; La coda contiene prepared777 deciso e OUTCOME61, entrambi fuori dal prefisso P.
;;;; DECISION nasce dall'intero log autorevole della fixture, con header e CRC verificati.
;;;; File nativi <=4096 byte, registri/deadline/cleanup di ct::rp-run; nessun thread nuovo.
;;;; ARV-D13/D14: CLOSED assente, P/count/esiti errati, vecchi FD chiusi prima del claim.
;;;; FI locale dopo rename: condizione originale, token FAULTED, nessun wrapper consegnato.
;;;; Oracoli: byte indipendenti, query pubbliche, FD/inode/flag/offset/EOF e namespace posseduto.
;;;; Nessuna prova di power loss, inventario CLOSED storico, EBR o motore completo.
;;; OWNER: fixture nativa privata; FD, directory, scratch e decisioni appartengono al test.
;;; SHARED: nessuna sostituzione globale o concorrenza; runner esterno dopo freeze.
(in-package #:arcdocdb.recovery.active.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defstruct (apub-case (:constructor apub-make-case))
  path directory identity view version control-input control-bytes control-prefix control
  input bytes prefix recovered active checkpoint)

(defun apub-outcomes ()
  "Fatti della fixture, indipendenti dagli array e dal serializer del prodotto."
  '((17 0) (#xffffffffffffffff #xfedcba9876543210)))

(defun apub-source (version tail-p)
  "Spec solo per AV-LOG; OUTCOME duplicato identico nello stesso lotto conclusivo."
  (let* ((prepared (list (list :put #xffffffffffffffff t (rt::bytes 1) (rt::bytes #xf6))
                         (list :put 17 t (rt::bytes 2) (rt::bytes #xf5))
                         (list :tombstone 17 t (rt::bytes 3))
                         (list :put 43 t (rt::bytes 4) (rt::bytes #xf4))
                         (list :tombstone 61 t (rt::bytes 5))))
         (outcomes '((:outcome 43 #x8000000000000001) (:outcome 43 #x8000000000000001)))
         (prefix (av-log (list prepared outcomes) :version version))
         (tail (if tail-p
                   (av-cat (av-record (list :put 777 t (rt::bytes 6) (rt::bytes #xf6)) version)
                           (av-record '(:outcome 61 9) version))
                   (av-bytes 0))))
    (values (av-cat prefix tail) (length prefix))))

(defun apub-seed (fixture path directory name bytes deadline)
  "Setup privato: create esclusiva .tmp, flush, rinomina del nome di fixture e flush parent."
  (multiple-value-bind (input append)
      (ct::rp-seed fixture path (concatenate 'string name ".tmp") bytes deadline)
    (let ((target (ct::native-leaf fixture path name)))
      (ct::native-seconds-left deadline :active-fixture-seed-rename)
      (sb-posix:rename (namestring (merge-pathnames (concatenate 'string name ".tmp") path))
                       (namestring target))
      (is (zerop (ct::native-bounded deadline :active-fixture-seed-flush
                   (lambda () (io:durable-flush directory))))))
    (values input append)))

(defun apub-decisions (fixture path directory identity version deadline local-decision-p)
  "Log completo dell'Archivio della fixture: header verificato e tabella ricostruita a EOF."
  (let* ((participants (list identity (rt::participant-id 99 128)))
         (specs (append (list (rt::decision-spec #xffffffffffffffff #xfedcba9876543210 participants)
                              (rt::decision-spec 777 8 participants)
                              (rt::decision-spec 17 0 participants))
                        (when local-decision-p
                          (list (rt::decision-spec 43 #x8000000000000001 participants)))))
         (header (ct::control-reference-header identity version)))
    (ct::control-pack header 4 #x314c534d 4)
    (ct::control-pack header 56 (ct::control-crc header 0 56) 4)
    (multiple-value-bind (bytes start end)
        (rt::decision-log-fixture (list specs) :version version :prefix 64 :file-offset 0)
      (is (= start 64)) (is (= end (length bytes)))
      (replace bytes header)
      (multiple-value-bind (input append) (apub-seed fixture path directory "multiserie.log" bytes deadline)
        (is (= end (io:posizione-scritta append) (io:posizione-durevole append)))
        (let ((read (ct::native-read-bytes input bytes deadline)))
          (multiple-value-bind (body actual-version)
              (arcdocdb.storage.format:verifica-header-log read 0 end :multiserie identity)
            (is (= body start)) (is (= actual-version version)))
          (multiple-value-bind (table prefix status)
              (rt::decision-fixture-read read start end :version version :file-offset 0 :file-size end
                :max-bytes 4096 :max-batches 1 :max-batch-records 4 :max-batch-bytes 4096
                :max-search-bytes 4096 :max-decisions 4 :max-participants 8)
            (is (= prefix end)) (is (eq :complete status))
            (rt::assert-decision-table table specs '(61 999))
            (fill read #xa5)
            table))))))

(defun apub-read-control (fixture case input expected prefix deadline)
  "Stesso backend nativo; EOF attestato dal FD, scratch privato distrutto dopo la lettura."
  (let* ((size (sb-posix:stat-size (sb-posix:fstat (io::file-fd input))))
         (scratch (av-bytes size)) (before (ct::rp-observations fixture)))
    (is (= size (length expected)))
    (ct::native-reset-calls fixture)
    (let ((result (ct::native-bounded deadline :active-publication-control-read
                    (lambda ()
                      (arcdocdb.control:leggi-control-recuperato
                       (apub-case-view case) input size scratch :chunk-bytes 31 :max-bytes 4096
                       :max-batches 2 :max-batch-records 1 :max-edits 1 :max-segmenti 4 :max-esiti 6)))))
      (is (equalp expected scratch))
      (is (equal before (ct::rp-observations fixture)))
      (is (equalp (vector 0 (ceiling size 31) 0 0 0 0 0 0 0)
                  (ct::native-observer-calls (ct::native-fixture-observer fixture))))
      (is (equal (list size prefix (if (= size prefix) :complete :tail) (apub-case-version case))
                 (multiple-value-list (arcdocdb.control:frontiere-control-recuperato result))))
      (fill scratch #xa5)
      result)))

(defun apub-read-active (fixture case decisions deadline &optional (input (apub-case-input case))
                                                               (control (apub-case-control case)))
  "Lettura pubblica dal FD readonly; nessuna capacità o risultato di prodotto fabbricato."
  (let* ((size (sb-posix:stat-size (sb-posix:fstat (io::file-fd input))))
         (scratch (av-bytes size)) (before (ct::rp-observations fixture)))
    (is (= size (length (apub-case-bytes case))))
    (is (eq :input (io:mode-file input)))
    (is (= sb-posix:o-rdonly
           (logand (sb-posix:fcntl (io::file-fd input) sb-posix:f-getfl)
                   (logior sb-posix:o-wronly sb-posix:o-rdwr))))
    (ct::native-reset-calls fixture)
    (let ((result (ct::native-bounded deadline :active-publication-active-read
                    (lambda ()
                      (ar:leggi-active-recuperato control input size decisions scratch
                       :chunk-bytes 31 :max-bytes 4096 :max-batches 3 :max-batch-records 5
                       :max-batch-bytes 4096 :max-records 7 :max-prepared 4 :max-outcomes 2)))))
      (is (equalp scratch (apub-case-bytes case)))
      (is (equal before (ct::rp-observations fixture)))
      (is (equalp (vector 0 (1+ (ceiling (- size 64) 31)) 0 0 0 0 2 0 0)
                  (ct::native-observer-calls (ct::native-fixture-observer fixture))))
      (is (equal (list size (apub-case-prefix case)
                       (if (= size (apub-case-prefix case)) :complete :tail) (apub-case-version case))
                 (multiple-value-list (ar:frontiere-active-recuperato result))))
      (is (equal '(2 7 4 1 2 1) (multiple-value-list (ar:statistiche-active-recuperato result))))
      (dolist (entry (apub-outcomes))
        (is (equal (list t (second entry))
                   (multiple-value-list (ar:esito-chiusura-active result (first entry))))))
      (dolist (txid '(43 61 777 999))
        (is (equal '(nil 0) (multiple-value-list (ar:esito-chiusura-active result txid)))))
      (fill scratch #xa5)
      result)))

(defun apub-setup (fixture version deadline &key (tail-p t) local-decision-p)
  "CONTROL canonico realmente letto prima del vecchio ACTIVE; CLOSED/REMOVED sono fatti storici."
  (let* ((path (ct::native-fixture-root fixture)) (identity (av-identity))
         (directory (ct::native-open fixture path :directory deadline))
         (control-prefix (ct::control-reference-checkpoint identity version (ct::rp-previous-payload) 19))
         (control-bytes (if tail-p (av-cat control-prefix (av-bytes 17)) control-prefix))
         (case (apub-make-case :path path :directory directory :identity identity
                              :view (ct::native-view identity) :version version
                              :control-bytes control-bytes :control-prefix (length control-prefix))))
    (multiple-value-bind (seed append) (ct::rp-seed fixture path "previous-control.tmp" control-bytes deadline)
      (is (= (length control-bytes) (io:posizione-scritta append) (io:posizione-durevole append)))
      (let ((target (ct::native-leaf fixture path "control.log")))
        (ct::native-seconds-left deadline :active-publication-seed-rename)
        (sb-posix:rename (namestring (merge-pathnames "previous-control.tmp" path)) (namestring target))
        (is (zerop (ct::native-bounded deadline :active-publication-seed-flush
                     (lambda () (io:durable-flush directory)))))
        (setf (apub-case-control-input case) (ct::native-open fixture target :input deadline))
        (is (equal (ct::native-identity seed) (ct::native-identity (apub-case-control-input case))))))
    (setf (apub-case-control case)
          (apub-read-control fixture case (apub-case-control-input case) control-bytes
                             (length control-prefix) deadline))
    (ct::rp-manifest (arcdocdb.control:manifest-control-recuperato (apub-case-control case)) nil)
    (let ((decisions (apub-decisions fixture path directory identity version deadline local-decision-p)))
      (multiple-value-bind (bytes prefix) (apub-source version tail-p)
        (multiple-value-bind (input append) (apub-seed fixture path directory "9.seg" bytes deadline)
          (is (= (length bytes) (io:posizione-scritta append) (io:posizione-durevole append)))
          (setf (apub-case-input case) input (apub-case-bytes case) bytes (apub-case-prefix case) prefix)))
      (setf (apub-case-recovered case) (apub-read-active fixture case decisions deadline))
      (values case decisions))))

(defun apub-entry (case)
  "Serializer reale confrontato con una entry bytewise, sentinelle fuori dal range scritto."
  (let* ((result (apub-case-recovered case)) (length (ar:lunghezza-chiusura-active result))
         (buffer (av-bytes (+ 11 length) #xa5))
         (oracle (ct::rp-payload 13 14 (list (list 9 (apub-case-prefix case) (apub-outcomes))) nil)))
    (is (= length 52))
    (is (= (+ 5 length) (ar:scrivi-chiusura-active result buffer 5)))
    (is (every (lambda (byte) (= byte #xa5)) (subseq buffer 0 5)))
    (is (every (lambda (byte) (= byte #xa5)) (subseq buffer (+ 5 length))))
    (is (equalp (subseq oracle 20 (+ 20 length)) (subseq buffer 5 (+ 5 length))))
    (subseq buffer 5 (+ 5 length))))

(defun apub-entries (case variant)
  "Varianti persistibili da factory reali; nessuna mutazione del manifest o del risultato."
  (let ((historical '(2 128 ((101 4294967298) (102 0))))
        (prefix (apub-case-prefix case)) (outcomes (copy-tree (apub-outcomes))) (removed '(3)))
    (ecase variant
      (:canonical nil)
      (:missing-closed nil)
      (:removed-active (setf removed '(3 9)))
      (:short-prefix (decf prefix))
      (:long-prefix (incf prefix))
      (:eof-prefix (setf prefix (length (apub-case-bytes case))))
      (:fewer-outcomes (setf outcomes (subseq outcomes 0 1)))
      (:extra-outcome (setf outcomes (append outcomes '((43 #x8000000000000001)))))
      (:wrong-zero-csn (setf (second (first outcomes)) 1))
      (:wrong-high-csn (setf (second (second outcomes)) #x76543210))
      (:missing-outcome (setf (first outcomes) '(61 0)))
      (:replaced-outcome (setf (first (second outcomes)) #xfffffffffffffffe))
      (:local-outcome (setf (second outcomes) '(43 #x8000000000000001)))
      (:aborted-outcome (setf (second outcomes) '(61 9)))
      (:tail-outcome (setf (second outcomes) '(777 8)))
      (:historical-length (setf historical '(2 129 ((101 4294967298) (102 0)))))
      (:historical-csn (setf historical '(2 128 ((101 4294967298) (102 1)))))
      (:historical-removed (setf removed '(4))))
    (values (if (member variant '(:missing-closed :removed-active))
                (list historical)
                (list historical (list 9 prefix outcomes)))
            removed)))

(defun apub-payload (case variant)
  "Il checkpoint valido usa l'entry serializzata; i byte attesi restano un oracolo distinto."
  (multiple-value-bind (entries removed) (apub-entries case variant)
    (let ((expected (ct::rp-payload 13 14 entries removed)))
      (if (eq variant :canonical)
          (let* ((historical (ct::rp-payload 13 14 (list (first entries)) nil))
                 (closed (av-cat (subseq historical 20 (- (length historical) 4)) (apub-entry case)))
                 (removed-bytes (av-bytes 8)) (payload (av-bytes (length expected))))
            (ct::control-pack removed-bytes 0 3 8)
            (is (= (length payload)
                   (arcdocdb.storage.format:scrivi-valore-edit
                    payload 0 14 13 closed 2 removed-bytes :completo t)))
            (is (equalp payload expected))
            payload)
          expected))))

(defun apub-prepare (fixture case deadline &optional (variant :canonical))
  "Nuovo ACTIVE13 e checkpoint prodotti soltanto dalle factory pubbliche."
  (let* ((path (apub-case-path case)) (directory (apub-case-directory case))
         (active (ct::native-active fixture directory path (apub-case-view case) 13
                                    (apub-case-version case) deadline))
         (payload (apub-payload case variant))
         (expected (ct::control-reference-checkpoint (apub-case-identity case) (apub-case-version case) payload 23))
         (plan (arcdocdb.control:crea-checkpoint-control active payload 23 :max-segmenti 4 :max-esiti 6))
         (leaf (ct::native-leaf fixture path "control.log.tmp"))
         (append (ct::native-open fixture leaf :append deadline))
         (input (ct::native-open fixture leaf :input deadline))
         (prepared (ct::native-bounded deadline :active-publication-prepare
                     (lambda ()
                       (arcdocdb.control:prepara-checkpoint-control
                        plan input append directory (av-bytes 37) :chunk-bytes 37)))))
    (is (= (length expected) (arcdocdb.control:lunghezza-checkpoint-control plan)))
    (ct::native-read-bytes input expected deadline)
    (setf (apub-case-active case) active
          (apub-case-checkpoint case) (ct::native-make-checkpoint plan prepared input append expected))
    case))

(defun apub-prepared (case)
  (ct::native-checkpoint-prepared (apub-case-checkpoint case)))

(defun apub-state (case state renamed-p)
  (is (equal (list state renamed-p)
             (multiple-value-list (arcdocdb.control:stato-pubblicazione-control (apub-prepared case)))))
  (when (eq state :prepared)
    (is (null (arcdocdb.control::control-preparato-publication-owner (apub-prepared case))))))

(defun apub-publish (case deadline)
  (ct::native-bounded deadline :active-publication
    (lambda () (ar:pubblica-control-da-active (apub-prepared case) (apub-case-recovered case)))))

(defun apub-namespace (fixture)
  "Inventario dei soli nomi registrati, compresi quelli assenti, senza callback del backend."
  (mapcar (lambda (path)
            (list path (handler-case (ct::native-path-identity path)
                         (sb-posix:syscall-error (condition)
                           (is (= sb-posix:enoent (sb-posix:syscall-errno condition))) :absent))))
          (ct::native-fixture-leaves fixture)))

(defun apub-file-bytes (fixture deadline)
  "Snapshot indipendente di ogni capacità input aperta, inclusi DECISION e code fisiche."
  (loop for slot in (ct::native-fixture-files fixture) for file = (car slot)
        when (and file (eq :input (io:mode-file file)) (eq :open (io:stato-file file)))
          collect (let* ((size (sb-posix:stat-size (sb-posix:fstat (io::file-fd file))))
                         (bytes (av-bytes size)))
                    (is (= size (ct::native-bounded deadline :active-publication-snapshot
                                 (lambda () (io:leggi-esatto file bytes 0 size 0)))))
                    (list file bytes))))

(defun apub-reject (fixture case deadline type reason &optional (state :prepared) renamed-p)
  "Ogni rifiuto precede callback/claim: stessi FD, namespace, byte e token disponibile."
  (let ((before (ct::rp-observations fixture)) (namespace (apub-namespace fixture))
        (bytes (apub-file-bytes fixture deadline)) (delivered nil))
    (ct::native-reset-calls fixture)
    (let ((condition (ct::native-capture-product-error
                      (lambda () (setf delivered (apub-publish case deadline))))))
      (is (typep condition type)) (is (eq reason (error-reason condition)))
      (is (null delivered)))
    (is (every #'zerop (ct::native-observer-calls (ct::native-fixture-observer fixture))))
    (is (equal before (ct::rp-observations fixture)))
    (is (equal namespace (apub-namespace fixture)))
    (apub-state case state renamed-p)
    (is (equalp bytes (apub-file-bytes fixture deadline)))))

(defun apub-manifest (case manifest)
  "Query pubbliche contro fatti scalari: storici conservati e soli due esiti derivati."
  (is (= 13 (arcdocdb.recovery.manifest:segmento-attivo manifest)))
  (is (equal '(t 14) (multiple-value-list (arcdocdb.recovery.manifest:prossimo-id-segmento manifest))))
  (is (= 2 (arcdocdb.recovery.manifest:numero-segmenti-chiusi manifest)))
  (is (= 1 (arcdocdb.recovery.manifest:numero-segmenti-rimossi manifest)))
  (dolist (entry (list '(13 :active 0 0) '(2 :closed 128 2) '(3 :removed 0 0)
                       (list 9 :closed (apub-case-prefix case) 2)))
    (is (equal (rest entry)
               (multiple-value-list (arcdocdb.recovery.manifest:trova-segmento manifest (first entry))))))
  (dolist (entry (append '((2 101 4294967298) (2 102 0))
                         (mapcar (lambda (outcome) (cons 9 outcome)) (apub-outcomes))))
    (is (equal (list t (third entry))
               (multiple-value-list
                (arcdocdb.recovery.manifest:trova-esito-chiusura manifest (first entry) (second entry))))))
  (dolist (txid '(43 61 777 999))
    (is (equal '(nil 0)
               (multiple-value-list (arcdocdb.recovery.manifest:trova-esito-chiusura manifest 9 txid)))))
  nil)

(defun apub-oracle (fixture case deadline)
  "Reopen del nome installato; vecchio CONTROL e ACTIVE ancora sul loro inode originale."
  (let* ((checkpoint (apub-case-checkpoint case)) (path (merge-pathnames "control.log" (apub-case-path case)))
         (old (apub-case-control-input case)) (input (ct::native-open fixture path :input deadline))
         (expected (ct::native-checkpoint-bytes checkpoint)))
    (is (equal (ct::native-path-identity path) (ct::native-identity input)))
    (is (equal (ct::native-identity input) (ct::native-identity (ct::native-checkpoint-input checkpoint))))
    (is (not (equal (ct::native-identity old) (ct::native-identity input))))
    (ct::native-absent (merge-pathnames "control.log.tmp" (apub-case-path case)))
    (ct::native-read-bytes input expected deadline)
    (apub-manifest case (arcdocdb.control:manifest-control-recuperato
                        (apub-read-control fixture case input expected (length expected) deadline)))
    (ct::native-read-bytes old (apub-case-control-bytes case) deadline)
    (ct::rp-manifest
     (arcdocdb.control:manifest-control-recuperato
      (apub-read-control fixture case old (apub-case-control-bytes case) (apub-case-control-prefix case) deadline))
     nil)
    (ct::native-read-bytes (apub-case-input case) (apub-case-bytes case) deadline)
    (is (equal (ct::native-path-identity (merge-pathnames "9.seg" (apub-case-path case)))
               (ct::native-identity (apub-case-input case))))))

(defun apub-success (fixture case deadline)
  "Cambia soltanto il nome canonico; nessuna scrittura, lettura, chiusura o troncatura implicita."
  (let* ((before (ct::rp-observations fixture)) (bytes (apub-file-bytes fixture deadline))
         (namespace (apub-namespace fixture))
         (source (merge-pathnames "control.log.tmp" (apub-case-path case)))
         (target (merge-pathnames "control.log" (apub-case-path case)))
         (checkpoint (apub-case-checkpoint case)))
    (ct::native-reset-calls fixture)
    (let ((published (apub-publish case deadline)))
      (is (typep published 'arcdocdb.control:control-pubblicato))
      (is (equalp #(0 0 0 0 1 0 3 3 1)
                  (ct::native-observer-calls (ct::native-fixture-observer fixture))))
      (apub-state case :published t)
      (is (eq (apub-case-active case) (arcdocdb.control:active-control-pubblicato published)))
      (is (eq (arcdocdb.control:log-control-preparato (apub-prepared case))
              (arcdocdb.control:log-control-pubblicato published)))
      (is (eq (arcdocdb.control:manifest-control-preparato (apub-prepared case))
              (arcdocdb.control:manifest-control-pubblicato published)))
      (apub-manifest case (arcdocdb.control:manifest-control-pubblicato published)))
    (is (equal before (ct::rp-observations fixture)))
    (is (equalp bytes (apub-file-bytes fixture deadline)))
    (is (equal (second (assoc source namespace :test #'equal)) (ct::native-path-identity target)))
    (dolist (entry namespace)
      (unless (member (first entry) (list source target) :test #'equal)
        (is (equal entry (assoc (first entry) (apub-namespace fixture) :test #'equal)))))
    (is (= (length (ct::native-checkpoint-bytes checkpoint))
           (io:posizione-scritta (ct::native-checkpoint-append checkpoint))
           (io:posizione-durevole (ct::native-checkpoint-append checkpoint))))
    (apub-oracle fixture case deadline)
    (apub-reject fixture case deadline 'invalid-argument :control-publication-state :published t)))

(defun apub-success-case (version &key (tail-p t) local-decision-p)
  (ct::rp-run
   (lambda (fixture deadline)
     (let ((case (apub-setup fixture version deadline :tail-p tail-p :local-decision-p local-decision-p)))
       (apub-prepare fixture case deadline)
       (apub-success fixture case deadline)))))

(defun apub-rejection-cases (variants reason)
  (dolist (version '(1 2))
    (dolist (variant variants)
      (ct::rp-run
       (lambda (fixture deadline)
         (let ((case (apub-setup fixture version deadline)))
           (apub-prepare fixture case deadline variant)
           (apub-reject fixture case deadline 'invalid-argument reason)
           ;; Lo stesso prepared resta disponibile anche dopo un secondo rifiuto.
           (apub-reject fixture case deadline 'invalid-argument reason)))))))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-STO-003 REQ-AFF-009 REQ-AFF-018
(deftest test-REQ-REC-001-ACTIVE-publication-native-v1-derived-zero-high-u64-local-abort-tail
  (apub-success-case 1))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-STO-003 REQ-AFF-009 REQ-AFF-018
(deftest test-REQ-REC-001-ACTIVE-publication-native-v2-derived-zero-high-u64-local-abort-tail
  (apub-success-case 2))

;;; REQ: REQ-REC-001 REQ-TXM-005 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-REC-001-ACTIVE-publication-complete-file-local-outcome-matches-authoritative-decision
  (dolist (version '(1 2)) (apub-success-case version :tail-p nil :local-decision-p t)))

;;; REQ: REQ-TXM-007 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-FOR-003-ACTIVE-publication-closure-serialized-sorted-independent-canaries
  (dolist (version '(1 2))
    (ct::rp-run
     (lambda (fixture deadline)
       (let* ((case (apub-setup fixture version deadline))
              (before (ct::rp-observations fixture)) (entry (apub-entry case)))
         (ct::native-reset-calls fixture)
         (is (equalp entry (apub-entry case)))
         (is (every #'zerop (ct::native-observer-calls (ct::native-fixture-observer fixture))))
         (is (equal before (ct::rp-observations fixture))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008
(deftest test-REQ-REC-001-ACTIVE-publication-missing-or-removed-old-closed-preclaim
  (apub-rejection-cases '(:missing-closed :removed-active) :active-recovery-closure))

;;; REQ: REQ-REC-001 REQ-STO-003 REQ-AFF-009
(deftest test-REQ-REC-001-ACTIVE-publication-short-long-and-physical-eof-prefix-preclaim
  (apub-rejection-cases '(:short-prefix :long-prefix :eof-prefix) :active-recovery-closure))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-ACTIVE-publication-fewer-or-extra-outcome-count-preclaim
  (apub-rejection-cases '(:fewer-outcomes :extra-outcome) :active-recovery-closure))

;;; REQ: REQ-TXM-007 REQ-FOR-003 REQ-AFF-008
(deftest test-REQ-TXM-007-ACTIVE-publication-zero-or-truncated-high-csn-preclaim
  (apub-rejection-cases '(:wrong-zero-csn :wrong-high-csn) :active-recovery-closure-outcome))

;;; REQ: REQ-TXM-007 REQ-AFF-008
(deftest test-REQ-TXM-007-ACTIVE-publication-missing-zero-outcome-equal-count-preclaim
  (apub-rejection-cases '(:missing-outcome) :active-recovery-closure-outcome))

;;; REQ: REQ-TXM-007 REQ-AFF-009 REQ-AFF-008
(deftest test-REQ-TXM-007-ACTIVE-publication-replaced-outcome-local-aborted-tail-not-authority
  (apub-rejection-cases '(:replaced-outcome :local-outcome :aborted-outcome :tail-outcome)
                        :active-recovery-closure-outcome))

(defun apub-closed-input (kind)
  "Retry solo dopo una nuova lettura da un alias reale; il vecchio FD resta chiuso."
  (dolist (version '(1 2))
    (ct::rp-run
     (lambda (fixture deadline)
       (multiple-value-bind (case decisions) (apub-setup fixture version deadline)
         (apub-prepare fixture case deadline)
         (let* ((active-p (eq kind :active))
                (old (if active-p (apub-case-input case) (apub-case-control-input case)))
                (alias (ct::native-open fixture
                        (merge-pathnames (if active-p "9.seg" "control.log") (apub-case-path case)) :input deadline)))
           (is (equal (ct::native-identity old) (ct::native-identity alias)))
           (is (null (io:chiudi old)))
           (apub-reject fixture case deadline 'io-fault :io-unavailable)
           (is (eq :closed (io:stato-file old)))
           (let ((control (if active-p (apub-case-control case)
                              (apub-read-control fixture case alias (apub-case-control-bytes case)
                                                 (apub-case-control-prefix case) deadline))))
             (setf (apub-case-recovered case)
                   (apub-read-active fixture case decisions deadline
                                     (if active-p alias (apub-case-input case)) control)))
           (if active-p (setf (apub-case-input case) alias) (setf (apub-case-control-input case) alias))
           (apub-success fixture case deadline)
           (is (eq :closed (io:stato-file old)))))))))

;;; REQ: REQ-REC-001 REQ-AFF-008 REQ-AFF-001
(deftest test-REQ-AFF-008-ACTIVE-publication-closed-active-or-canonical-control-fd-token-reusable
  (dolist (kind '(:active :control)) (apub-closed-input kind)))

;;; REQ: REQ-REC-001 REQ-TXM-007 REQ-AFF-018
(deftest test-REQ-AFF-018-ACTIVE-publication-historical-closed-outcomes-and-removed-preserved
  (dolist (entry '((:historical-length :recovery-closed-changed)
                   (:historical-csn :recovery-outcome-changed)
                   (:historical-removed :recovery-removed-changed)))
    (apub-rejection-cases (list (first entry)) (second entry))))

(defun apub-sync-fault (original-p)
  "FI privata nel callback fsync; leggibilità dopo rename senza attestazione di durability."
  (dolist (version '(1 2))
    (ct::rp-run
     (lambda (fixture deadline)
       (let* ((case (apub-setup fixture version deadline))
              (observer (ct::native-fixture-observer fixture))
              (failure (if original-p
                           (make-condition 'io-fault :reason :active-publication-sync :operation :flush :errno sb-posix:eio)
                           (make-condition 'sb-posix:syscall-error :errno sb-posix:eio :name 'active-publication-sync)))
              (observed nil) (delivered nil))
         (apub-prepare fixture case deadline)
         (let ((before (ct::rp-data-observations fixture)) (bytes (apub-file-bytes fixture deadline)))
           (setf (ct::native-observer-directory-failure observer) failure)
           (ct::native-reset-calls fixture)
           (let ((condition (ct::native-capture-product-error
                             (lambda ()
                               (handler-bind ((io-fault (lambda (original) (setf observed original))))
                                 (setf delivered (apub-publish case deadline)))))))
             (is (typep condition 'io-fault)) (is (eq condition observed))
             (when original-p (is (eq condition failure)))
             (is (eq (if original-p :active-publication-sync :io-syscall) (error-reason condition)))
             (is (eq :flush (arcdocdb.conditions:error-operation condition)))
             (is (= sb-posix:eio (arcdocdb.conditions:error-errno condition)))
             (is (null delivered)))
           (is (equalp #(0 0 0 0 1 0 3 3 1) (ct::native-observer-calls observer)))
           (apub-state case :faulted t)
           (is (eq :faulted (io:stato-file (apub-case-directory case))))
           (is (equal before (ct::rp-data-observations fixture)))
           (is (equalp bytes (apub-file-bytes fixture deadline)))
           (setf (ct::native-observer-directory-failure observer) nil)
           (apub-oracle fixture case deadline)
           (apub-reject fixture case deadline 'invalid-argument :control-publication-state :faulted t)))))))

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-AFF-001
(deftest test-REQ-AFF-004-ACTIVE-publication-native-directory-fsync-fault-after-rename
  (apub-sync-fault nil))

;;; REQ: REQ-REC-001 REQ-AFF-004 REQ-AFF-001
(deftest test-REQ-AFF-004-ACTIVE-publication-original-condition-after-rename-preserved
  (apub-sync-fault t))
