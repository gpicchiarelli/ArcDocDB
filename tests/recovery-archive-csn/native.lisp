;;;; Piano CSN Archivio da FD nativi readonly, v1/v2; ponte al solo registro CSN esistente.
;;; OWNER: ct::rp-run possiede root 0700 e registri CT; <=32 FD, <=4 Serie, <=4096 byte/file.
;;; SHARED: prove seriali con deadline 30s; nessun worker, FI globale o nuovo allocatore di prodotto.
;;; Il catalogo completo e il ruolo Registri sono precondizioni dichiarate della fixture.
;;; Nessuna ammissione del traffico, qualifica power loss o attestazione di prestazioni.
(in-package #:arcdocdb.recovery.archive.csn.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defstruct (acn-fixture (:constructor acn-make-fixture))
  native deadline version archive scope views registri set decisions decision-input
  controls control-inputs active active-inputs active-prefixes closed closed-inputs
  (images nil) (scratch nil) (identities nil))

(defun acn-readonly (input)
  (is (eq :input (io:mode-file input)))
  (is (eq :open (io:stato-file input)))
  (is (zerop (io:posizione-scritta input)))
  (is (zerop (io:posizione-durevole input)))
  (is (= sb-posix:o-rdonly
         (logand (sb-posix:fcntl (io::file-fd input) sb-posix:f-getfl)
                 (logior sb-posix:o-wronly sb-posix:o-rdwr)))))

(defun acn-seed (f directory path name bytes)
  "Create esclusiva .tmp, flush, rename e fsync parent; tutti i FD restano registrati in CT."
  (is (<= (length bytes) 4096))
  (let ((input (av::apub-seed (acn-fixture-native f) path directory name bytes (acn-fixture-deadline f))))
    (is (<= (length (ct::native-fixture-files (acn-fixture-native f))) 32))
    (acn-readonly input)
    (is (equal (ct::native-identity input)
               (ct::native-path-identity (merge-pathnames name path))))
    (push (list input (copy-seq bytes)) (acn-fixture-images f))
    input))

(defun acn-scratch (f size)
  (is (<= size 4096))
  (let ((scratch (ct::crr-bytes (+ size 7) #xcc)))
    (push scratch (acn-fixture-scratch f)) scratch))

(defun acn-consumed (scratch expected prefix)
  "Canary oltre il limite autorevole, poi distruzione dello scratch ancora posseduto dal caller."
  (is (equalp (subseq scratch 0 prefix) (subseq expected 0 prefix)))
  (is (every (lambda (byte) (= byte #xcc)) (subseq scratch prefix)))
  (fill scratch #xa5))

(defun acn-check-files (f)
  "Oracoli successivi al piano: le loro pread sono tenute fuori dalla finestra zero I/O."
  (dolist (image (acn-fixture-images f))
    (destructuring-bind (input expected) image
      (unless (eq :closed (io:stato-file input))
        (acn-readonly input)
        (ct::native-read-bytes input expected (acn-fixture-deadline f))))))

(defun acn-noio (f thunk)
  "Snapshot POSIX e byte indipendenti; qualsiasi callback del piano rende falsa la prova."
  (let* ((native (acn-fixture-native f)) (before (ct::rp-observations native))
         (namespace (av::apub-namespace native)))
    (ct::native-reset-calls native)
    (multiple-value-prog1 (ct::native-bounded (acn-fixture-deadline f) :archive-csn-native-plan thunk)
      (is (every #'zerop (ct::native-observer-calls (ct::native-fixture-observer native))))
      (is (equal before (ct::rp-observations native)))
      (is (equal namespace (av::apub-namespace native)))
      (acn-check-files f))))

(defun acn-plan (f &rest options)
  (apply #'ac:crea-piano-csn-archivio (acn-fixture-set f) (acn-fixture-decisions f)
         (acn-fixture-active f) (acn-fixture-closed f) options))

(defun acn-check-plan (plan present maximum series segments)
  "Massimo matematico dichiarato prima del replay, distinto dagli stamp TXID e dai contatori CONTROL."
  (is (typep plan 'ac:piano-csn-archivio))
  (is (equal (list present maximum) (multiple-value-list (ac:massimo-csn-archivio plan))))
  (is (equal (list series segments) (multiple-value-list (ac:statistiche-piano-csn-archivio plan))))
  (multiple-value-bind (high low) (floor maximum #x100000000)
    (is (equal (list high low) (multiple-value-list (ac:parole-base-csn-archivio plan)))))
  plan)

(defun acn-register (plan capacity)
  "Ponte solo TEST: la base e M, il primo token viene assegnato dall'allocatore CSN gia esistente."
  (multiple-value-bind (high low) (ac:parole-base-csn-archivio plan)
    (arcdocdb.csn:crea-registro-csn :capacity capacity :initial-high high :initial-low low)))

(defun acn-first-csn (plan base)
  "Oracolo aritmetico u64, frontiera pendente e risoluzione pubblica; nessuna lettura di slot privati."
  (let ((registry (acn-register plan 1)))
    (multiple-value-bind (high low) (floor base #x100000000)
      (is (equal (list high low high low) (cs::csn-frontiers registry))))
    (let ((token (multiple-value-list (arcdocdb.csn:prendi-csn registry))))
      (is (= 3 (length token)))
      (is (= (1+ base) (cs::csn-token-number token)))
      (let ((frontiers (cs::csn-frontiers registry)))
        (is (= (1+ base) (cs::csn-number (first frontiers) (second frontiers))))
        (is (= base (cs::csn-number (third frontiers) (fourth frontiers)))))
      (multiple-value-bind (high low) (floor (1+ base) #x100000000)
        (is (equal (list high low)
                   (multiple-value-list (apply #'arcdocdb.csn:risolvi-csn registry token))))
        (is (equal (list high low high low) (cs::csn-frontiers registry)))))
    registry))

(defun acn-view (f number)
  "Vista pubblica con UUID del caller conservato separatamente per la prova di copia."
  (let* ((identity (acr-identity number))
         (primary (arcdocdb.index.primary:crea-indice-primario
                    :capacity 16 :arena-bytes 2048 :hash-seed-high 23 :hash-seed-low 29))
         (view (g:crea-vista-get-serie (acn-fixture-scope f) primary nil identity)))
    (push identity (acn-fixture-identities f)) view))

(defun acn-size (f input)
  (let ((size (sb-posix:stat-size (sb-posix:fstat (io::file-fd input)))))
    (is (<= 64 size 4096))
    (is (eq (io::file-backend input) (ct::native-fixture-backend (acn-fixture-native f))))
    (acn-readonly input) size))

(defun acn-image (f input)
  (second (assoc input (acn-fixture-images f) :test #'eq)))

(defun acn-read-control (f i &optional (view (aref (acn-fixture-views f) i)))
  (let* ((input (aref (acn-fixture-control-inputs f) i)) (size (acn-size f input))
         (scratch (acn-scratch f size))
         (result (ct::native-bounded (acn-fixture-deadline f) :archive-csn-native-control
                   (lambda () (c:leggi-control-recuperato view input size scratch
                                :chunk-bytes 31 :max-bytes 4096 :max-batches 2
                                :max-batch-records 1 :max-edits 2 :max-segmenti 8 :max-esiti 8)))))
    (is (equal (list size size :complete (acn-fixture-version f))
               (multiple-value-list (c:frontiere-control-recuperato result))))
    (acn-consumed scratch (acn-image f input) size) result))

(defun acn-read-decisions (f &optional (archive (acn-fixture-archive f)))
  "Nuovo replay pubblico degli stessi byte/FD; il suo marker deve restare distinto."
  (let* ((input (acn-fixture-decision-input f)) (size (acn-size f input))
         (scratch (acn-scratch f size))
         (result (ct::native-bounded (acn-fixture-deadline f) :archive-csn-native-decisions
                   (lambda () (da:leggi-decisioni-recuperate archive input size scratch
                                :chunk-bytes 31 :max-bytes 4096 :max-batches 3
                                :max-batch-records 8 :max-batch-bytes 4096
                                :max-decisions 8 :max-participants 32 :max-participants-per-decision 4)))))
    (multiple-value-bind (eof prefix status version) (da:frontiere-decisioni-recuperate result)
      (is (= eof size)) (is (= version (acn-fixture-version f)))
      (is (<= 64 prefix size)) (is (eq (eq status :complete) (= prefix size))))
    (acn-consumed scratch (acn-image f input) size) result))

(defun acn-read-active (f i decisions &optional (control (aref (acn-fixture-controls f) i)))
  (let* ((input (aref (acn-fixture-active-inputs f) i)) (size (acn-size f input))
         (scratch (acn-scratch f size))
         (result (ct::native-bounded (acn-fixture-deadline f) :archive-csn-native-active
                   (lambda () (da:leggi-active-con-decisioni control input size decisions scratch
                                :chunk-bytes 31 :max-bytes 4096 :max-batches 8 :max-records 16
                                :max-batch-records 8 :max-batch-bytes 4096 :max-prepared 8 :max-outcomes 8)))))
    (let ((prefix (aref (acn-fixture-active-prefixes f) i)))
      (is (equal (list size prefix (if (= prefix size) :complete :tail) (acn-fixture-version f))
                 (multiple-value-list (arcdocdb.recovery.active:frontiere-active-recuperato result)))))
    (acn-consumed scratch (acn-image f input) size) result))

(defun acn-read-closed (f i j id prefix)
  (let* ((input (aref (aref (acn-fixture-closed-inputs f) i) j))
         (size (acn-size f input)) (scratch (acn-scratch f prefix))
         (result (ct::native-bounded (acn-fixture-deadline f) :archive-csn-native-closed
                   (lambda () (cr:leggi-closed-recuperato (aref (acn-fixture-controls f) i) input id scratch
                                :chunk-bytes 31 :max-bytes 4096 :max-batches 8 :max-records 16
                                :max-batch-records 8 :max-batch-bytes 4096 :max-prepared 8
                                :max-outcomes 8 :max-esiti-chiusura 8)))))
    (is (<= prefix size))
    (is (= id (nth-value 0 (cr:frontiere-closed-recuperato result))))
    (is (= prefix (nth-value 1 (cr:frontiere-closed-recuperato result))))
    (acn-consumed scratch (acn-image f input) prefix) result))

(defun acn-seed-serie (f i spec)
  "Una directory nativa per Serie; CLOSED e CONTROL autorevoli precedono il replay ACTIVE."
  (let* ((native (acn-fixture-native f)) (deadline (acn-fixture-deadline f))
         (version (acn-fixture-version f)) (number (getf spec :number))
         (path (ct::native-directory native (format nil "serie-~D/" number) deadline))
         (directory (ct::native-open native path :directory deadline))
         (view (acn-view f number)) (identity (acr-identity number))
         (closed (getf spec :closed)) (entries nil) (prefixes nil)
         (inputs (make-array (length closed) :initial-element nil)))
    (is (<= (length closed) 4))
    (setf (aref (acn-fixture-views f) i) view (aref (acn-fixture-closed-inputs f) i) inputs)
    (loop for source in closed for j from 0
          do (multiple-value-bind (bytes prefix) (acr-closed-bytes identity version source)
               (let ((id (getf source :id)))
                 (push (list id prefix (getf source :outcomes)) entries) (push (list id prefix) prefixes)
                 (setf (aref inputs j) (acn-seed f directory path (format nil "~D.seg" id) bytes)))))
    (let* ((bytes (acr-control-bytes identity version (nreverse entries)))
           (input (acn-seed f directory path "control.log" bytes))
           (active (rac::ra-active-bytes version identity (getf spec :active)))
           (source (ct::crr-cat active (or (getf spec :tail) (ct::zeros 0)))))
      (setf (aref (acn-fixture-control-inputs f) i) input
            (aref (acn-fixture-controls f) i) (acn-read-control f i)
            (aref (acn-fixture-active-prefixes f) i) (length active)
            (aref (acn-fixture-active-inputs f) i) (acn-seed f directory path "9.seg" source)))
    (nreverse prefixes)))

(defun acn-setup (native deadline version specs registri decisions decision-tail)
  "Solo letture pubbliche da FD nativi: decisioni, ACTIVE e tutti i CLOSED nello stesso scope."
  (let* ((count (length specs)) (scope (g::vista-get-serie-scope (acr-view 0)))
         (f (acn-make-fixture :native native :deadline deadline :version version :scope scope
              :archive (da:crea-archivio-recovery scope (acr-archive-id))
              :views (make-array count :initial-element nil) :controls (make-array count :initial-element nil)
              :control-inputs (make-array count :initial-element nil) :active (make-array count :initial-element nil)
              :active-prefixes (make-array count :initial-element nil)
              :active-inputs (make-array count :initial-element nil) :closed (make-array count :initial-element nil)
              :closed-inputs (make-array count :initial-element nil)))
         (directory (ct::native-open native (ct::native-fixture-root native) :directory deadline))
         (prefixes nil))
    (is (<= 1 count 4)) (is (<= 0 registri (1- count)))
    (is (<= (+ 3 (* 5 count)
               (* 2 (loop for spec in specs sum (length (getf spec :closed))))) 32))
    (loop for spec in specs for i from 0 do (push (acn-seed-serie f i spec) prefixes))
    (setf prefixes (nreverse prefixes)
          (acn-fixture-decision-input f)
          (acn-seed f directory (ct::native-fixture-root native) "multiserie.log"
                    (dar::dar-log (when decisions (list decisions)) :version version
                                  :identity (acr-archive-id) :tail decision-tail))
          (acn-fixture-decisions f) (acn-read-decisions f)
          (acn-fixture-registri f) (aref (acn-fixture-views f) registri)
          (acn-fixture-set f)
          (ac:crea-insieme-serie-recovery (acn-fixture-archive f) (acn-fixture-registri f)
                                        (acn-fixture-views f) :max-series 4 :budget-riferimenti 32))
    (dotimes (i count)
      (setf (aref (acn-fixture-active f) i) (acn-read-active f i (acn-fixture-decisions f))
            (aref (acn-fixture-closed f) i)
            (coerce (loop for entry in (nth i prefixes) for j from 0
                          collect (acn-read-closed f i j (first entry) (second entry)))
                    'simple-vector)))
    (acn-check-files f)
    f))

(defun acn-run (version specs registri decisions thunk &key decision-tail)
  (ct::rp-run (lambda (native deadline)
                (funcall thunk (acn-setup native deadline version specs registri decisions decision-tail)))))

(defun acn-decision (txid csn)
  "UUID16 in ordine crescente, due partecipanti dello stesso Archivio dichiarato dalla fixture."
  (rt::decision-spec txid csn (list (acr-identity 1) (acr-identity 2))))

(defun acn-tail (version)
  "Record completo senza SEAL: il suo CSN massimo non appartiene al prefisso recuperato."
  (rac::ra-encode-record (cd::cdr-record :put #xffffffffffffffff :value #(246)) version))

(defun acn-rich-series (version)
  "Tre Serie: writer con esiti EDIT, compaction, e ACTIVE di Registri con massimo distinto."
  (list
   (acr-serie 1
     :active (list (cd::cdr-batch #x100000003
                     (cd::cdr-record :put #x100000003 :value #(246))
                     (cd::cdr-record :prepared-put #xffffffffffffffff :value #(245))))
     :closed (list (acr-closed 2
                     :batches (list (cd::cdr-batch #x100000004 (cd::cdr-record :tombstone #x100000004)))
                     :outcomes '((101 #x100000007)) :tail (acn-tail version)))
     :tail (acn-tail version))
   (acr-serie 2
     :closed (list (acr-closed 7 :origin 2
                     :records (list (cd::cdr-record :put #x100000008 :value #(246))
                                    (cd::cdr-record :tombstone #x100000009))
                     :tail (acn-tail version))))
   (acr-serie 3
     :active (list (cd::cdr-batch #x10000000b (cd::cdr-record :tombstone #x10000000b)))
     :closed (list (acr-closed 2 :tail (acn-tail version))))))

(defun acn-rich (version registri decision-maximum)
  (let ((maximum (max #x10000000b decision-maximum)))
    (acn-run version (acn-rich-series version) registri (list (acn-decision 501 decision-maximum))
      (lambda (f)
        (is (eq (acn-fixture-registri f) (aref (acn-fixture-views f) registri)))
        (is (= 3 (ac:numero-serie-recovery (acn-fixture-set f))))
        (dotimes (i 3)
          (is (eq (acn-fixture-scope f) (g::vista-get-serie-scope (aref (acn-fixture-views f) i)))))
        (let ((plan (acn-noio f (lambda () (acn-plan f)))))
          (acn-check-plan plan t maximum 3 6)
          (acn-noio f (lambda () (acn-first-csn plan maximum)))))
      :decision-tail (rt::reference-decision-record (acn-decision 502 #xffffffffffffffff) version))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-MVC-006 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-MVC-006-ARCHIVE-CSN-native-v1-registri-last-all-series-tail-excluded
  (acn-rich 1 2 #x100000005))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-MVC-006 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-MVC-006-ARCHIVE-CSN-native-v2-registri-nonfixed-unreferenced-decision-wins
  (dolist (registri '(0 1 2)) (acn-rich 2 registri #x200000005)))

;;; REQ: REQ-MVC-006 REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-MVC-006-ARCHIVE-CSN-native-absence-versus-present-zero-base-first-one
  (dolist (version '(1 2))
    (dolist (present '(nil t))
      (acn-run version
        (list (acr-serie 1 :closed (list (acr-closed 2)))
              (acr-serie 2 :active (when present
                                    (list (cd::cdr-batch 0 (cd::cdr-record :put 0 :value #(246)))))))
        1 nil
        (lambda (f)
          (let ((plan (acn-noio f (lambda () (acn-plan f)))))
            (acn-check-plan plan present 0 2 3)
            (acn-noio f (lambda () (acn-first-csn plan 0)))))))))

(defun acn-base-series (source maximum)
  "Ogni origine puo imporre la base, inclusi EDIT senza prepared e stamp compaction."
  (list (acr-serie 1
          :active (case source
                    (:active (list (cd::cdr-batch maximum
                                     (cd::cdr-record :prepared-put 777 :value #(246)))))
                    (:local-outcome (list (cd::cdr-batch 0 (cd::cdr-record :outcome 777 :csn maximum))))
                    (otherwise nil))
          :closed (list (acr-closed 2
                          :outcomes (when (eq source :edit) (list (list 101 maximum))))))
        (acr-serie 2
          :closed (list (acr-closed 7 :origin 2
                          :records (list (cd::cdr-record :tombstone
                                          (if (eq source :compaction) maximum 0))))))))

;;; REQ: REQ-MVC-006 REQ-MVC-008 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-MVC-006-ARCHIVE-CSN-native-each-source-base-u32-carry-first-M-plus-one
  (dolist (version '(1 2))
    (dolist (source '(:decision :active :local-outcome :edit :compaction))
      (let ((maximum #x12345678ffffffff))
        (acn-run version (acn-base-series source maximum) 1
          (when (eq source :decision) (list (acn-decision 601 maximum)))
          (lambda (f)
            (let ((plan (acn-noio f (lambda () (acn-plan f)))))
              (acn-check-plan plan t maximum 2 4)
              (let ((registry (acn-noio f (lambda () (acn-first-csn plan maximum)))))
                (is (equal '(#x12345679 0 #x12345679 0) (cs::csn-frontiers registry)))))))))))

;;; REQ: REQ-MVC-006 REQ-MVC-008 REQ-AFF-008
(deftest test-REQ-MVC-006-ARCHIVE-CSN-native-u64-limit-emits-last-once-then-exhausted-no-wrap
  (dolist (version '(1 2))
    (dolist (base '(#xfffffffffffffffe #xffffffffffffffff))
      (acn-run version (acn-base-series :compaction base) 1 nil
        (lambda (f)
          (let* ((plan (acn-noio f (lambda () (acn-plan f))))
                 (registry (acn-noio f (lambda ()
                                        (if (= base #xffffffffffffffff)
                                            (acn-register plan 1) (acn-first-csn plan base))))))
            (acn-check-plan plan t base 2 4)
            (dotimes (attempt 2)
              (let ((before (cs::csn-frontiers registry)))
                (acn-noio f (lambda ()
                              (acr-expect 'resource-exhausted :csn-exhausted
                                (lambda () (arcdocdb.csn:prendi-csn registry)))))
                (is (equal before (cs::csn-frontiers registry)))))
            (is (equal '(#xffffffff #xffffffff #xffffffff #xffffffff) (cs::csn-frontiers registry)))))))))

(defun acn-gate-series ()
  "Due Serie e due CLOSED: writer prepared deciso da EDIT e compaction ordinaria."
  (list (acr-serie 1
          :active (list (cd::cdr-batch 23 (cd::cdr-record :put 23 :value #(246))))
          :closed (list (acr-closed 2
                          :batches (list (cd::cdr-batch 7 (cd::cdr-record :prepared-tombstone 101)))
                          :outcomes '((101 11)))
                        (acr-closed 7 :origin 2 :records (list (cd::cdr-record :tombstone 13)))))
        (acr-serie 2)))

(defun acn-reject (f type reason thunk)
  "Nessun piano parziale consegnato; osservazioni immutate e zero callback anche sul rifiuto."
  (let ((delivered nil))
    (acn-noio f (lambda ()
                  (acr-expect type reason (lambda () (setf delivered (funcall thunk))) nil)))
    (is (null delivered))))

;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-AFF-008
(deftest test-REQ-MVC-006-ARCHIVE-CSN-native-caller-vectors-uuid-scratch-plan-remain-independent
  (dolist (version '(1 2))
    (let ((specs (acn-gate-series)))
      (acn-run version specs 1 nil
        (lambda (f)
          ;; L'insieme possiede la copia delle viste; i risultati possiedono scalari, non gli scratch.
          (fill (acn-fixture-views f) nil)
          (dolist (identity (acn-fixture-identities f)) (fill identity #xee))
          (dolist (scratch (acn-fixture-scratch f)) (fill scratch #x55))
          (let ((record (first (getf (first (getf (first specs) :active)) :records))))
            (fill (getf record :key) #xee) (fill (getf record :value) #xee))
          (let ((plan (acn-noio f (lambda () (acn-plan f)))))
            (acn-check-plan plan t 23 2 4)
            ;; Il piano scalare resta utilizzabile dopo mutazione dei vettori e chiusura delle fonti.
            (fill (acn-fixture-active f) nil)
            (loop for sources across (acn-fixture-closed f) do (fill sources nil))
            (fill (acn-fixture-closed f) nil)
            (dolist (image (acn-fixture-images f)) (is (null (io:chiudi (first image)))))
            (acn-noio f (lambda () (acn-check-plan plan t 23 2 4)))
            (acn-noio f (lambda () (acn-first-csn plan 23)))))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-MVC-006 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-native-gates-count-closed-duplicates-budgets-registri-scope
  (dolist (version '(1 2))
    (acn-run version (acn-gate-series) 1 nil
      (lambda (f)
        (let ((set (acn-fixture-set f)) (decisions (acn-fixture-decisions f))
              (active (acn-fixture-active f)) (closed (acn-fixture-closed f)))
          (acn-reject f 'invalid-argument :archive-csn-recovery-count
            (lambda () (ac:crea-piano-csn-archivio set decisions (subseq active 0 1) closed)))
          (acn-reject f 'invalid-argument :archive-csn-recovery-count
            (lambda () (ac:crea-piano-csn-archivio set decisions active (subseq closed 0 1))))
          (dolist (bad (list #() (vector (aref (aref closed 0) 0))
                            (vector (aref (aref closed 0) 0) (aref (aref closed 0) 0))))
            (let ((sources (copy-seq closed)))
              (setf (aref sources 0) bad)
              (acn-reject f 'invalid-argument
                (if (= 2 (length bad)) :closed-recovery-set-duplicate :closed-recovery-set-count)
                (lambda () (ac:crea-piano-csn-archivio set decisions active sources)))))
          (dolist (options '((:max-segmenti-serie 1) (:max-segmenti-totali 1) (:max-segmenti-totali 3)))
            (acn-reject f 'resource-exhausted :archive-csn-segment-budget
              (lambda () (apply #'acn-plan f options))))
          (let* ((archive (acn-fixture-archive f)) (registri (acn-fixture-registri f))
                 (views (acn-fixture-views f)) (first (aref views 0))
                 (foreign (acr-view 99)) (duplicate (acr-view 1 (acn-fixture-scope f))))
            (acn-reject f 'invalid-argument :archive-csn-registri-missing
              (lambda () (ac:crea-insieme-serie-recovery archive registri (vector first))))
            (acn-reject f 'invalid-argument :archive-csn-series-scope
              (lambda () (ac:crea-insieme-serie-recovery archive registri (vector first foreign))))
            (acn-reject f 'invalid-argument :archive-csn-series-duplicate
              (lambda () (ac:crea-insieme-serie-recovery archive registri (vector first duplicate))))
            (dolist (options '((:max-series 1) (:budget-riferimenti 15)))
              (acn-reject f 'resource-exhausted :archive-csn-series-budget
                (lambda () (apply #'ac:crea-insieme-serie-recovery archive registri views options)))))
          (acn-check-plan (acn-noio f (lambda () (acn-plan f :max-segmenti-serie 2 :max-segmenti-totali 4)))
                          t 23 2 4))))))

(defun acn-lifetime-input (f kind)
  (ecase kind
    (:decision (acn-fixture-decision-input f))
    (:control (aref (acn-fixture-control-inputs f) 1))
    (:active (aref (acn-fixture-active-inputs f) 1))
    (:writer (aref (aref (acn-fixture-closed-inputs f) 0) 0))
    (:compaction (aref (aref (acn-fixture-closed-inputs f) 0) 1))))

;;; REQ: REQ-REC-001 REQ-MVC-006 REQ-AFF-002 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-native-closed-decision-control-active-writer-compaction-fd
  (dolist (version '(1 2))
    (dolist (kind '(:decision :control :active :writer :compaction))
      (acn-run version (acn-gate-series) 1 nil
        (lambda (f)
          (let ((completed (acn-noio f (lambda () (acn-plan f))))
                (input (acn-lifetime-input f kind)))
            (is (null (io:chiudi input)))
            (dotimes (attempt 2)
              (acn-reject f 'io-fault :io-unavailable (lambda () (acn-plan f))))
            (is (eq :closed (io:stato-file input)))
            ;; Un piano gia consegnato e un riepilogo; non attesta la salute futura dei FD.
            (acn-noio f (lambda () (acn-check-plan completed t 23 2 4)))))))))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-MVC-006 REQ-TXM-005 REQ-AFF-008
(deftest test-REQ-AFF-008-ARCHIVE-CSN-native-replay-marker-archive-owner-canonical-view-gates
  (dolist (version '(1 2))
    (acn-run version (acn-gate-series) 1 (list (acn-decision 901 19))
      (lambda (f)
        (let* ((replay (acn-read-decisions f)) (active (acn-fixture-active f))
               (set (acn-fixture-set f)) (closed (acn-fixture-closed f))
               (foreign-archive (da:crea-archivio-recovery (acn-fixture-scope f) (acr-archive-id)))
               (foreign-decisions (acn-read-decisions f foreign-archive))
               (alias-view (acr-view 1 (acn-fixture-scope f)))
               (alias-control (acn-read-control f 0 alias-view))
               (alias-active (acn-read-active f 0 (acn-fixture-decisions f) alias-control)))
          (is (not (eq replay (acn-fixture-decisions f))))
          (is (equal (multiple-value-list (da:massimo-csn-decisioni-recuperate replay))
                     (multiple-value-list (da:massimo-csn-decisioni-recuperate (acn-fixture-decisions f)))))
          (acn-reject f 'invalid-argument :archive-csn-active-decision-source
            (lambda () (ac:crea-piano-csn-archivio set replay active closed)))
          (acn-reject f 'invalid-argument :archive-csn-decision-owner
            (lambda () (ac:crea-piano-csn-archivio set foreign-decisions active closed)))
          (let ((sources (copy-seq active)))
            (setf (aref sources 0) alias-active)
            (acn-reject f 'invalid-argument :archive-csn-active-view
              (lambda () (ac:crea-piano-csn-archivio set (acn-fixture-decisions f) sources closed))))
          (let* ((control (acn-read-control f 0))
                 (reread (acn-read-active f 0 (acn-fixture-decisions f) control))
                 (sources (copy-seq active)))
            (setf (aref sources 0) reread)
            (acn-reject f 'invalid-argument :closed-recovery-set-control
              (lambda () (ac:crea-piano-csn-archivio set (acn-fixture-decisions f) sources closed))))
          ;; Rileggere tutti gli ACTIVE con lo stesso nuovo replay ripristina una catena coerente.
          (let ((fresh (map 'simple-vector (lambda (i) (acn-read-active f i replay)) '(0 1))))
            (acn-check-plan
             (acn-noio f (lambda () (ac:crea-piano-csn-archivio set replay fresh closed))) t 23 2 4))
          (acn-check-plan (acn-noio f (lambda () (acn-plan f))) t 23 2 4))))))
