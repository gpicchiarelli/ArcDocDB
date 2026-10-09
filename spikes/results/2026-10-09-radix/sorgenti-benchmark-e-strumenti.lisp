(:SCHEMA-VERSION 1 :KIND :SOURCE-ARCHIVE :ENTRIES
 ((:SOURCE-PATH "spikes/out/decisions-sort-benchmark/candidate.lisp" :GIT-BLOB
   "d11d5d280ac148ef0b37b8892289256214b82310" :TEXT
   ";;;; Candidati LSD privati, non collegati alle API di ricostruzione.
;;; OWNER: singola ricostruzione; input e scratch sono copie private.
;;; SHARED: nessuna scrittura condivisa, nessun I/O o pubblicazione.
(in-package #:arcdocdb.recovery.decisions)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-TXM-005 REQ-AFF-008
(defconstant +decision-radix-buckets+ 256 \"Numero di classi dell'algoritmo per un ottetto.\")
;;; REQ: REQ-TXM-005 REQ-AFF-008
(deftype radix-histogram () '(simple-array (unsigned-byte 64) (256)))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (radix-histogram index) (values boolean &optional))
                radix-prefix-starts))
(defun radix-prefix-starts (histogram count)
  \"Pre: conteggi privati di 256 classi. Post: somme verificate, prefissi se necessari.
Restituisce NIL per zero o una classe occupata: la passata non serve.
INVARIANT-VIOLATION per conteggi incompatibili; due cicli limitati a 256.\"
  (let ((total 0) (occupied 0))
    (declare (type index total occupied))
    (dotimes (digit +decision-radix-buckets+)
      (let ((frequency (aref histogram digit)))
        (unless (<= frequency (- count total))
          (error 'invariant-violation :reason :decision-radix-count))
        (incf total frequency)
        (unless (zerop frequency) (incf occupied))))
    (unless (= total count)
      (error 'invariant-violation :reason :decision-radix-consumption))
    (when (> occupied 1)
      (let ((start 0))
        (declare (type index start))
        (dotimes (digit +decision-radix-buckets+)
          (let ((frequency (aref histogram digit)))
            (setf (aref histogram digit) start)
            (incf start frequency))))
      t)))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets u16 index radix-histogram)
                         (values boolean &optional)) radix-id-starts))
(defun radix-id-starts (source count digit histogram)
  \"Pre: copia privata di COUNT ID16, DIGIT byte dell'ID. Post: histogram verificato.
Restituisce se occorre distribuire; INVARIANT-VIOLATION per misura o byte incoerente.
SOURCE invariato; conteggio limitato a COUNT, prefissi a 256 classi.\"
  (unless (= (length source) (* count +participant-id-bytes+))
    (error 'invariant-violation :reason :decision-participant-size))
  (unless (< digit +participant-id-bytes+)
    (error 'invariant-violation :reason :decision-radix-digit))
  (fill histogram 0)
  (dotimes (i count)
    (incf (aref histogram (aref source (+ (* i +participant-id-bytes+) digit)))))
  (radix-prefix-starts histogram count))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector index radix-histogram)
                         (values boolean &optional)) radix-entry-starts))
(defun radix-entry-starts (source digit histogram)
  \"Pre: entry private verificate, DIGIT ottetto del TXID u64. Post: conteggi verificati.
Restituisce se occorre distribuire; INVARIANT-VIOLATION per ottetto incoerente.
SOURCE invariato; conteggio limitato alla lunghezza, prefissi a 256 classi.\"
  (unless (< digit 8)
    (error 'invariant-violation :reason :decision-radix-digit))
  (unless (typep (length source) 'u64)
    (error 'invariant-violation :reason :decision-radix-count))
  (fill histogram 0)
  (dotimes (i (length source))
    (incf (aref histogram
                (ldb (byte 8 (* digit 8)) (%entry-txid (the decision-entry (aref source i)))))))
  (radix-prefix-starts histogram (length source)))

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (radix-histogram index) null) radix-check-cursors))
(defun radix-check-cursors (histogram count)
  \"Pre: cursori dopo distribuzione stabile. Post: estremi crescenti entro COUNT.
Ultima classe termina esattamente a COUNT; INVARIANT-VIOLATION altrimenti.
Nessuna modifica, ciclo limitato a 256 classi.\"
  (let ((previous 0))
    (declare (type index previous))
    (dotimes (digit +decision-radix-buckets+)
      (let ((cursor (aref histogram digit)))
        (unless (<= previous cursor count)
          (error 'invariant-violation :reason :decision-radix-position))
        (setf previous cursor)))
    (unless (= previous count)
      (error 'invariant-violation :reason :decision-radix-consumption)))
  nil)

;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets octets u16 index radix-histogram) null)
                radix-scatter-ids))
(defun radix-scatter-ids (source target count digit histogram)
  \"Pre: copie private distinte, prefissi della passata corrente. Post: ID distribuiti.
Stabile nell'ordine della sorgente, nessuna modifica a SOURCE; cursori consumati.
INVARIANT-VIOLATION per misure, byte o posizione; ciclo limitato a COUNT.\"
  (unless (and (= (length source) (* count +participant-id-bytes+))
               (= (length target) (length source)) (not (eq source target)))
    (error 'invariant-violation :reason :decision-radix-arrays))
  (unless (< digit +participant-id-bytes+)
    (error 'invariant-violation :reason :decision-radix-digit))
  (dotimes (i count)
    (let* ((key (aref source (+ (* i +participant-id-bytes+) digit)))
           (position (aref histogram key)))
      (unless (< position count)
        (error 'invariant-violation :reason :decision-radix-position))
      (copy-id16 target (the index position) source i)
      (incf (aref histogram key))))
  (radix-check-cursors histogram count))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector simple-vector index radix-histogram) null)
                radix-scatter-entries))
(defun radix-scatter-entries (source target digit histogram)
  \"Pre: vettori privati distinti, entry verificate e prefissi correnti. Post: run stabile.
TXID uguali conservano l'ordine fisico; SOURCE invariato, cursori consumati.
INVARIANT-VIOLATION per misure, ottetto o posizione; ciclo limitato alla lunghezza.\"
  (unless (and (= (length source) (length target)) (not (eq source target)))
    (error 'invariant-violation :reason :decision-radix-arrays))
  (unless (< digit 8)
    (error 'invariant-violation :reason :decision-radix-digit))
  (dotimes (i (length source))
    (let* ((entry (the decision-entry (aref source i)))
           (key (ldb (byte 8 (* digit 8)) (%entry-txid entry)))
           (position (aref histogram key)))
      (unless (< position (length source))
        (error 'invariant-violation :reason :decision-radix-position))
      (setf (aref target (the index position)) entry)
      (incf (aref histogram key))))
  (radix-check-cursors histogram (length source)))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (octets u16 u64) (values octets &optional))
                radix-sort-participants))
(defun radix-sort-participants (participants count source-offset)
  \"Pre: copia privata di COUNT ID16. Post: risultato posseduto, ordinato e distinto.
Propaga duplicati tipizzati; INVARIANT-VIOLATION per misura interna incoerente.
LSD stabile: al più 16 passate, uniformi saltate; input privato può essere riordinato.
Scratch sulla misura effettiva; percorso di apertura, nessuna promessa zero heap.\"
  (unless (= (length participants) (* count +participant-id-bytes+))
    (error 'invariant-violation :reason :decision-participant-size))
  (let ((source participants)
        (target (make-array (length participants) :element-type '(unsigned-byte 8)))
        (histogram (make-array +decision-radix-buckets+
                               :element-type '(unsigned-byte 64) :initial-element 0)))
    (dotimes (pass +participant-id-bytes+)
      (let ((digit (- +participant-id-bytes+ 1 pass)))
        (when (radix-id-starts source count digit histogram)
          (radix-scatter-ids source target count digit histogram)
          (rotatef source target))))
    (check-participant-order source count source-offset)
    source))

;;; REQ: REQ-TXM-005 REQ-TXM-001 REQ-AFF-008 REQ-VAL-001
(declaim (ftype (function (simple-vector) (values simple-vector &optional))
                radix-sort-entries))
(defun radix-sort-entries (entries)
  \"Pre: vettore privato di entry possedute. Post: ordine TXID non decrescente e stabile.
INVARIANT-VIOLATION per entry o ordine incoerente; nessun I/O o stato condiviso.
Al più otto passate LSD, uniformi saltate; input privato può essere riordinato.
Scratch sulla lunghezza effettiva; allocazioni ammesse sul percorso di apertura.\"
  (dotimes (i (length entries))
    (unless (typep (aref entries i) 'decision-entry)
      (error 'invariant-violation :reason :decision-entry-shape))
    (check-entry-shape (aref entries i)))
  (let ((source entries) (target (make-array (length entries) :element-type t))
        (histogram (make-array +decision-radix-buckets+
                               :element-type '(unsigned-byte 64) :initial-element 0)))
    (dotimes (digit 8)
      (when (radix-entry-starts source digit histogram)
        (radix-scatter-entries source target digit histogram)
        (rotatef source target)))
    (loop for i from 1 below (length source)
          unless (<= (%entry-txid (the decision-entry (aref source (1- i))))
                     (%entry-txid (the decision-entry (aref source i))))
            do (error 'invariant-violation :reason :decision-entry-order))
    source))
")
  (:SOURCE-PATH "spikes/out/decisions-sort-benchmark/driver.lisp" :GIT-BLOB
   "14688ad5af55cc0db2f9199cc3c0d271d7a8a3c9" :TEXT
   ";;;; Confronto riproducibile merge/radix; solo ordinamento nel tempo misurato.
;;;; Uso: --self-test oppure --bench directory-nuova/.
;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
(require :asdf)
(require :sb-posix)
(defpackage #:arcdocdb.decisions.sort-bench (:use #:cl))
(in-package #:arcdocdb.decisions.sort-bench)
(declaim (optimize (safety 3) (debug 2)))

(defun load-product ()
  (let ((root (truename \"./\")) (*standard-output* *error-output*))
    (asdf:initialize-output-translations
     `(:output-translations (,root ,(merge-pathnames \"spikes/out/decisions-bench-fasl/\" root))
                            :ignore-inherited-configuration))
    (setf asdf:*compile-file-warnings-behaviour* :error asdf:*compile-file-failure-behaviour* :error)
    (handler-bind ((warning (lambda (c) (if (typep c 'sb-kernel:redefinition-warning)
                                          (muffle-warning c) (error c)))))
      (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" root))
      (asdf:load-system \"arcdocdb\" :force t)
      (unless (fboundp (find-symbol \"RADIX-SORT-ENTRIES\" \"ARCDOCDB.RECOVERY.DECISIONS\"))
        (ensure-directories-exist \"spikes/out/decisions-bench-fasl/radix.fasl\")
        (load (compile-file \"src/recovery/decisions-radix.lisp\"
                            :output-file \"spikes/out/decisions-bench-fasl/radix.fasl\"))))))
(load-product)

(defconstant +seed+ #x123456789abcdef0)
(defconstant +mask+ #xffffffffffffffff)
(defconstant +max-copy-bytes+ 67108864)
(defconstant +max-iterations+ 65536)
(defconstant +replicas+ 3)
(defconstant +minimum-duration-ticks+ (ceiling internal-time-units-per-second 20))

(define-condition incorrect-sort (error) ()
  (:documentation \"Il risultato misurato differisce dall'oracolo indipendente.\")
  (:report (lambda (condition stream)
             (declare (ignore condition))
             (write-string \"Ordinamento diverso dall'oracolo.\" stream))))
(define-condition reporter-probe-failure (error) ()
  (:documentation \"Errore intenzionale del self-test del reporter.\"))

(defun scrambled (number)
  (logand +mask+ (+ +seed+ (* number #x9e3779b97f4a7c15))))

(defun store-be64 (buffer start number)
  (dotimes (i 8) (setf (aref buffer (+ start i)) (ldb (byte 8 (* 8 (- 7 i))) number))))

(defun fixture (scope count pattern)
  \"Fixture univoche; duplicati ammessi solo nei TXID, con identità fisica preservata.\"
  (ecase scope
    (:participants
     (let ((buffer (make-array (* 16 count) :element-type '(unsigned-byte 8) :initial-element 0)))
       (dotimes (i count)
         (let ((key (ecase pattern (:ordered i) (:reverse (- count i 1))
                                  (:mixed (scrambled i)) (:full (scrambled i)))))
           (when (eq pattern :full) (store-be64 buffer (* 16 i) key))
           (store-be64 buffer (+ (* 16 i) 8) (if (eq pattern :full) (scrambled key) key))))
       buffer))
    (:entries
     (let ((entries (make-array count))
           (participants (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)))
       (setf (aref participants 31) 1)
       (dotimes (i count)
         (setf (aref entries i)
               (arcdocdb.recovery.decisions::%make-decision-entry
                (ecase pattern (:ordered i) (:reverse (- count i 1)) (:mixed (scrambled i))
                               (:duplicates (scrambled (floor i 4))) (:uniform 0))
                0 2 participants i)))
       entries))))

(defun id-less-p (buffer a b)
  (dotimes (i 16 nil)
    (let ((left (aref buffer (+ (* a 16) i))) (right (aref buffer (+ (* b 16) i))))
      (when (/= left right) (return (< left right))))))

(defun oracle (scope input)
  \"Oracolo a stable-sort indipendente dai due algoritmi del prodotto.\"
  (ecase scope
    (:entries (stable-sort (copy-seq input) #'< :key #'arcdocdb.recovery.decisions::%entry-txid))
    (:participants
     (let* ((count (/ (length input) 16)) (indexes (make-array count)) (result (copy-seq input)))
       (dotimes (i count) (setf (aref indexes i) i))
       (stable-sort indexes (lambda (a b) (id-less-p input a b)))
       (dotimes (i count)
         (replace result input :start1 (* i 16) :end1 (* (1+ i) 16)
                               :start2 (* (aref indexes i) 16) :end2 (* (1+ (aref indexes i)) 16)))
       result))))

(defun matches-p (scope expected actual)
  (and (= (length expected) (length actual))
       (ecase scope
         (:participants (equalp expected actual))
         (:entries (loop for a across expected for b across actual always (eq a b))))))

(defun algorithm (scope name count)
  (ecase scope
    (:entries (ecase name (:merge #'arcdocdb.recovery.decisions::sort-entries)
                         (:radix #'arcdocdb.recovery.decisions::radix-sort-entries)))
    (:participants
     (let ((function (ecase name (:merge #'arcdocdb.recovery.decisions::sort-participants)
                                (:radix #'arcdocdb.recovery.decisions::radix-sort-participants))))
       (lambda (input) (funcall function input count 64))))))

(defun duration-kind (ticks)
  (unless (>= ticks 0) (error \"Durata negativa.\"))
  (if (plusp ticks) :measured :below-resolution))

(defun measurement (ticks heap iterations)
  \"Tick grezzi conservati; meno di 50 ms non autorizza una soglia.\"
  (unless (and (>= ticks 0) (>= heap 0) (plusp iterations))
    (error \"Contatore o iterazioni invalidi.\"))
  (let ((seconds (/ ticks (float internal-time-units-per-second 1d0)))
        (usable (>= ticks +minimum-duration-ticks+)))
    (list :iterations iterations :ticks ticks :seconds seconds :heap-bytes heap
          :status (duration-kind ticks)
          :quality (if usable :target-reached :insufficient-duration)
          :threshold-usable-p usable
          :seconds-per-sort (when (plusp ticks) (/ seconds iterations))
          :heap-bytes-per-sort (/ heap iterations))))

(defun sample (scope input expected function iterations &key (clock #'get-internal-real-time))
  \"Copie/oracolo/GC iniziale fuori misura; scratch e GC del sort inclusi.
CLOCK è iniettabile per dimostrare il percorso di durata nulla nel self-test.\"
  (unless (plusp iterations) (error \"Iterazioni non positive.\"))
  (let ((copies (make-array iterations)) (outputs (make-array iterations)))
    (dotimes (i iterations) (setf (aref copies i) (copy-seq input)))
    (sb-ext:gc :full t)
    (let* ((before (sb-ext:get-bytes-consed)) (start (funcall clock)))
      (dotimes (i iterations) (setf (aref outputs i) (funcall function (aref copies i))))
      (let ((ticks (- (funcall clock) start)) (heap (- (sb-ext:get-bytes-consed) before)))
        (dotimes (i iterations)
          (unless (matches-p scope expected (aref outputs i)) (error 'incorrect-sort)))
        (measurement ticks heap iterations)))))

(defun iteration-cap (scope input)
  \"Limita il payload delle copie, non l'heap totale del campione.\"
  (let ((bytes (* (length input) (if (eq scope :entries) 8 1))))
    (when (> bytes +max-copy-bytes+) (error \"Una copia supera il budget.\"))
    (min +max-iterations+ (floor +max-copy-bytes+ (max 1 bytes)))))

(defun calibrate (scope input expected function progress checkpoint)
  \"Al massimo 17 tentativi; progress conserva warmup e ogni prova completata.\"
  (setf (getf progress :stage) :warmup (getf progress :warmups-completed) 0)
  (when checkpoint (funcall checkpoint))
  (dotimes (i 2)
    (unless (matches-p scope expected (funcall function (copy-seq input))) (error 'incorrect-sort))
    (incf (getf progress :warmups-completed))
    (when checkpoint (funcall checkpoint)))
  (let ((cap (iteration-cap scope input)) (iterations 1))
    (setf (getf progress :iteration-cap) cap
          (getf progress :target-ticks) +minimum-duration-ticks+)
    (dotimes (attempt 17)
      (setf (getf progress :stage) :measurement (getf progress :attempt) attempt
            (getf progress :iterations) iterations)
      (when checkpoint (funcall checkpoint))
      (let ((result (sample scope input expected function iterations)))
        (setf (getf progress :probes) (append (getf progress :probes) (list result))
              (getf progress :probe) result)
        (when checkpoint (funcall checkpoint))
        (when (or (getf result :threshold-usable-p) (= iterations cap))
          (setf (getf progress :quality) (getf result :quality)
                (getf progress :stage) :complete)
          (when checkpoint (funcall checkpoint))
          (return-from calibrate progress)))
      (setf iterations (min cap (* 2 iterations))))
    (error \"Calibrazione oltre il limite.\")))

(defun campaign (scope count pattern progress checkpoint)
  \"Aggiorna uno scenario già posseduto dal report prima di ogni passo fallibile.\"
  (setf (getf progress :stage) :fixtures)
  (when checkpoint (funcall checkpoint))
  (let* ((input (fixture scope count pattern)) (original (copy-seq input)) (expected (oracle scope input))
         (merge (algorithm scope :merge count)) (radix (algorithm scope :radix count)))
    (dolist (name '(:merge :radix))
      (let ((state (list :algorithm name :stage :pending :warmups-completed 0
                         :iteration-cap nil :target-ticks nil :attempt nil :iterations nil
                         :probes nil :probe nil :quality nil)))
        (setf (getf progress :stage) :calibration (getf progress :algorithm) name
              (getf progress :calibrations) (append (getf progress :calibrations) (list (cons name state))))
        (calibrate scope input expected (if (eq name :merge) merge radix) state checkpoint)))
    (dotimes (replica +replicas+)
      (dolist (name (if (evenp replica) '(:merge :radix) '(:radix :merge)))
        (setf (getf progress :stage) :replica (getf progress :algorithm) name
              (getf progress :replica) replica)
        (when checkpoint (funcall checkpoint))
        (let* ((calibration (cdr (assoc name (getf progress :calibrations))))
               (result (sample scope input expected (if (eq name :merge) merge radix)
                               (getf calibration :iterations))))
          (unless (eq (getf calibration :quality) :target-reached)
            (setf (getf result :threshold-usable-p) nil))
          (setf (getf progress :samples)
                (append (getf progress :samples)
                        (list (list :algorithm name :replica replica :measurement result))))
          (when checkpoint (funcall checkpoint)))))
    (setf (getf progress :stage) :fixture-check)
    (unless (equalp input original) (error \"Fixture modificata.\"))
    (setf (getf progress :stage) :complete (getf progress :status) :ok)
    (when checkpoint (funcall checkpoint))
    progress))

(defun campaign-specifications ()
  (loop for scope in '(:participants :entries) append
        (loop for count in '(16 64 256 1024 4096 16384 65535) append
              (loop for pattern in (if (eq scope :participants)
                                       '(:ordered :reverse :mixed :full)
                                       '(:ordered :reverse :mixed :duplicates :uniform))
                    collect (list scope count pattern)))))

(defun run-campaigns (report &key checkpoint (runner #'campaign)
                                (specifications (campaign-specifications)))
  \"Collega anche lo scenario corrente al report; gli errori lasciano tutte le prove.\"
  (dolist (spec specifications)
    (destructuring-bind (scope count pattern) spec
      (let ((progress (list :scope scope :count count :pattern pattern :seed +seed+
                            :status :running :stage :pending :algorithm nil :replica nil
                            :calibrations nil :samples nil :diagnostic nil)))
        (setf (getf report :current-campaign) progress
              (getf report :campaigns) (append (getf report :campaigns) (list progress)))
        (when checkpoint (funcall checkpoint))
        (funcall runner scope count pattern progress checkpoint))))
  report)

(defun make-report ()
  (list :schema-version 1 :driver-version 2 :kind :decision-sort-benchmark :status :running
        :diagnostic nil :self-test nil :campaigns nil :current-campaign nil
        :seed +seed+ :replicas +replicas+ :workers 1 :safety 3
        :timer-units-per-second internal-time-units-per-second
        :timer-unit-seconds (/ 1 internal-time-units-per-second)
        :minimum-duration-ticks +minimum-duration-ticks+
        :max-copy-bytes +max-copy-bytes+ :max-iterations +max-iterations+
        :threshold-policy '(:metric :median-seconds-per-sort :max-radix-over-merge 9/10
                            :separate-scopes t :all-patterns-at-or-above-threshold t
                            :insufficient-duration :keep-merge)
        :limits '(:sort-only :copies-and-oracle-outside-timing :gc-inside-sort-included
                  :copy-payload-budget-is-not-total-heap-budget :full-id-halves-correlated
                  :cold-recovery-allocation-permitted :macos-local-is-not-linux-qualification
                  :external-load-uncontrolled :no-engine-throughput-or-p99-claim)))

(defun claim-directory (requested)
  \"Restituisce solo una directory nuova creata da questo run; non scrive se esiste.\"
  (let* ((directory (uiop:ensure-directory-pathname requested))
         (parent (make-pathname :directory (butlast (pathname-directory directory))
                                :name nil :type nil :defaults directory)))
    (ensure-directories-exist (merge-pathnames \"parent.marker\" parent))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun write-report (report owned-directory &key (if-exists :error))
  \"La directory è già stata creata dal run, mai una destinazione rifiutata.\"
  (unless owned-directory (error \"Directory non posseduta.\"))
  (with-open-file (stream (merge-pathnames \"report.lisp\" owned-directory)
                          :direction :output :if-exists if-exists)
    (write report :stream stream :pretty t) (terpri stream)))

(defun mark-failed (report condition)
  (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
  (let ((current (getf report :current-campaign)))
    (when current
      (setf (getf current :status) :failed (getf current :diagnostic) (princ-to-string condition))))
  report)

(defun run-driver (args &key (report (make-report)) (self-tester #'self-test)
                            (campaign-runner #'run-campaigns))
  \"Gli errori producono un report; solo una destinazione reclamata può essere scritta.\"
  (let ((owned-directory nil))
    (handler-case
        (progn
          (unless (or (equal args '(\"--self-test\"))
                      (and (= (length args) 2) (string= (first args) \"--bench\")))
            (error \"Usare --self-test oppure --bench directory-nuova/.\"))
          (when (= (length args) 2) (setf owned-directory (claim-directory (second args))))
          (setf (getf report :self-test) (funcall self-tester))
          (when owned-directory
            (funcall campaign-runner report
                     :checkpoint (lambda () (write-report report owned-directory :if-exists :supersede))))
          (setf (getf report :status) :ok)
          (when owned-directory (write-report report owned-directory :if-exists :supersede)))
      (error (condition)
        (mark-failed report condition)
        (when owned-directory (write-report report owned-directory :if-exists :supersede))))
    report))

(defun self-test-partial-run (report &key checkpoint)
  \"Un primo scenario completo e un secondo con prova parziale prima dell'errore.\"
  (run-campaigns report :checkpoint checkpoint :specifications '((:entries 16 :ordered) (:entries 16 :reverse))
    :runner (lambda (scope count pattern progress persist)
              (unless (and (eq scope :entries) (= count 16)) (error \"Spec self-test errata.\"))
              (setf (getf progress :samples) '((:algorithm :merge :measurement (:ticks 7))))
              (when persist (funcall persist))
              (if (eq pattern :ordered)
                  (setf (getf progress :stage) :complete (getf progress :status) :ok)
                  (progn (setf (getf progress :stage) :replica)
                         (error 'reporter-probe-failure))))))

(defun self-test-reporter ()
  \"Verifica i report parziali e l'intangibilità della destinazione già esistente.\"
  (uiop:with-temporary-file (:pathname marker :stream stream)
    (write-line \"marker\" stream)
    (let* ((base (append (pathname-directory marker) (list (concatenate 'string (pathname-name marker) \"-bench\"))))
           (fresh (make-pathname :directory base :name nil :type nil :defaults marker))
           (existing (make-pathname :directory (append base '(\"existing\")) :name nil :type nil :defaults marker))
           (owned-base nil))
      (unwind-protect
           (progn
             (setf owned-base (claim-directory fresh))
             (claim-directory existing)
             (write-report '(:sentinel :unchanged) existing)
             (let ((refused (run-driver (list \"--bench\" (namestring existing))
                                       :self-tester (constantly :passed))))
               (unless (eq (getf refused :status) :failed) (error \"Destinazione esistente accettata.\")))
             (with-open-file (input (merge-pathnames \"report.lisp\" existing))
               (let ((*read-eval* nil))
                 (unless (equal (read input) '(:sentinel :unchanged)) (error \"Report precedente modificato.\"))))
             (let* ((failed-directory (make-pathname :directory (append base '(\"failed\"))
                                                      :name nil :type nil :defaults marker))
                    (failed (run-driver (list \"--bench\" (namestring failed-directory))
                                        :self-tester (constantly :passed) :campaign-runner #'self-test-partial-run)))
               (unless (eq (getf failed :status) :failed) (error \"Errore del reporter non rilevato.\"))
               (with-open-file (input (merge-pathnames \"report.lisp\" failed-directory))
                 (let* ((*read-eval* nil) (saved (read input)) (cases (getf saved :campaigns)))
                   (unless (and (= (length cases) 2) (eq (getf (first cases) :status) :ok)
                                (eq (getf (second cases) :status) :failed)
                                (eq (getf (second cases) :stage) :replica)
                                (equal (getf (second cases) :samples)
                                       '((:algorithm :merge :measurement (:ticks 7)))))
                     (error \"Precedenti o prove parziali persi.\"))))))
        (when owned-base (uiop:delete-directory-tree owned-base :validate t))))))

(defun self-test ()
  (unless (and (eq (duration-kind 0) :below-resolution) (eq (duration-kind 1) :measured)
               (not (getf (measurement (1- +minimum-duration-ticks+) 0 1) :threshold-usable-p))
               (getf (measurement +minimum-duration-ticks+ 0 1) :threshold-usable-p))
    (error \"Classificazione del tempo errata.\"))
  (dolist (scope '(:participants :entries))
    (let* ((input (fixture scope 17 :mixed)) (expected (oracle scope input)))
      (unless (and (equalp input (fixture scope 17 :mixed)) (not (matches-p scope expected input)))
        (error \"Fixture/oracolo incapace di rilevare algoritmo identità.\"))
      (unless (handler-case (progn (sample scope input expected #'identity 2) nil)
                (incorrect-sort () t))
        (error \"Driver incapace di rifiutare algoritmo identità.\"))
      (dolist (name '(:merge :radix))
        (sample scope input expected (algorithm scope name 17) 2))
      (let ((zero (sample scope input expected (algorithm scope :merge 17) 2 :clock (constantly 0))))
        (unless (and (eq (getf zero :status) :below-resolution)
                     (eq (getf zero :quality) :insufficient-duration)
                     (null (getf zero :seconds-per-sort)) (null (getf zero :threshold-usable-p)))
          (error \"Tempo nullo utilizzato come misura.\")))))
  (self-test-reporter)
  :passed)

(defun main ()
  (let ((report (run-driver (uiop:command-line-arguments))))
    (if (eq (getf report :status) :ok)
        (format t \"Benchmark ordinamenti: self-test superato~A.~%\"
                (if (getf report :campaigns)
                    (format nil \", ~D scenari conservati\" (length (getf report :campaigns))) \"\"))
        (progn (format *error-output* \"~A~%\" (getf report :diagnostic))
               (sb-ext:exit :code 1)))))

(main)
")
  (:SOURCE-PATH "spikes/out/decisions-sort-benchmark/method.md" :GIT-BLOB
   "e01a68ebe53c1af05f3bf6952ba0a6aa3b1e3bf2" :TEXT
   "# Metodo: ordinamento delle decisioni e consultazioni parallele

Registrato prima delle misure del 2026-10-09. Ambito: ordinamento in
memoria del recovery, senza I/O, applicazione dei prepared o modifica del
formato persistente. La tabella pubblica resta posseduta e immutabile.

## Candidati e criterio

Baseline: merge bottom-up stabile già verificato. Candidato: LSD radix
stabile a base 256, otto cifre per TXID u64 e sedici per ID16. Le passate
con una sola classe occupata non cambiano l'ordine e possono essere saltate.
Il workspace resta limitato ai dati effettivi più 256 contatori, senza
allocazione in proporzione ai budget inutilizzati.

Per una larghezza fissa `w`, radix richiede `O(w × (N + 256))` lavoro;
merge richiede `O(N log N)` confronti. La distribuzione stabile di ogni
cifra conserva l'ordine fisico dei TXID uguali e quindi la provenienza del
primo conflitto. Riferimento primario: [Sedgewick e Wayne, LSD](https://algs4.cs.princeton.edu/code/edu/princeton/cs/algs4/LSD.java.html).
L'adattamento usa interi **unsigned** u64, senza il riordino del segno
necessario agli interi Java del riferimento.

Nessuna adozione sulla sola complessità asintotica. Si misurano cardinalità
piccole, medie e grandi, ID16 a prefisso comune e con tutti i byte variabili
(le due metà sono correlate), TXID ordinati, inversi, dispersi, duplicati
e uniformi. Si scelgono soglie separate per ID16 e TXID. Per ogni scenario
con `N >= soglia`, mediana radix deve essere al massimo il 90% della mediana
merge. La soglia stessa deve essere una cardinalità misurata. In caso di risultati discordanti si
mantiene merge nel relativo percorso; il candidato non viene lasciato
come codice di prodotto inutilizzato.

## Correttezza e concorrenza

Oracolo indipendente a `stable-sort` nei test, confrontando tutti i byte
e l'identità delle entry, compresi i duplicati. Valori estremi u64,
cardinalità dispari e confini delle cifre; passate uniformi, input già
ordinato e inverso, ID differenti in ciascuno dei 128 bit.
Si ripetono i contratti pubblici: duplicati idempotenti o discordanti,
primo conflitto fisico, budget e ownership, senza risultati parziali.

Worker reali consultano in parallelo la stessa tabella pubblicata prima
dello start: ogni worker possiede input, output e stato d'errore. Nessuna
scrittura nella tabella, contatore globale o lock nel percorso della
query. Il test confronta gli output con un oracolo seriale e attende i
thread con timeout. Questi worker appartengono all'harness; non introducono
thread per richiesta nel motore o un nuovo pool globale.

## Misure e conservazione

Solo ordinamento nelle finestre misurate; fixture, copie da ripristinare,
compilazione, warmup e confronto con l'oracolo sono fuori dalla finestra.
Le allocazioni interne dell'algoritmo e gli eventuali GC restano inclusi.
Repliche alternate tra merge/radix, seme fisso, contatori heap e tick grezzi,
risoluzione e durata effettiva conservati. Tre repliche per algoritmo,
con iterazioni calibrate separatamente, alternano l'ordine di esecuzione.
Campioni sotto la risoluzione o più brevi del target di 50 ms, anche dopo
raggiungimento del tetto, rendono inconcludente la scelta per quel suffisso
di cardinalità: non producono rapporti utilizzabili per l'adozione.
La calibrazione ha un numero massimo di tentativi, iterazioni e byte delle
copie. Il limite di 64 MiB riguarda il payload delle copie (otto byte per
riferimento a entry); non comprende header, output, oracolo e scratch.

Self-test del driver: fixture/oracolo deterministici, algoritmo errato
rilevato e corretta classificazione del tempo nullo. Due letture, lint,
mutanti mirati, copertura grezza e `make check`; comandi, hash e tentativi
falliti vengono conservati nel catalogo. La misura locale macOS/ARM64
non qualifica prestazioni Linux/x86-64, P99, zero heap o il motore completo.
")
  (:SOURCE-PATH "tools/decisions-sort-bench.lisp" :GIT-BLOB
   "a1bee0418d542eae3800213fc23df402ccd75a41" :TEXT
   ";;;; Confronto riproducibile merge/radix; solo ordinamento nel tempo misurato.
;;;; Uso: --self-test oppure --bench directory-nuova/.
;;; REQ: REQ-TXM-005 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
(require :asdf)
(require :sb-posix)
(defpackage #:arcdocdb.decisions.sort-bench (:use #:cl))
(in-package #:arcdocdb.decisions.sort-bench)
(declaim (optimize (safety 3) (debug 2)))

(defun load-product ()
  (let ((root (truename \"./\")) (*standard-output* *error-output*))
    (asdf:initialize-output-translations
     `(:output-translations (,root ,(merge-pathnames \"spikes/out/decisions-bench-fasl/\" root))
                            :ignore-inherited-configuration))
    (setf asdf:*compile-file-warnings-behaviour* :error asdf:*compile-file-failure-behaviour* :error)
    (handler-bind ((warning (lambda (c) (if (typep c 'sb-kernel:redefinition-warning)
                                          (muffle-warning c) (error c)))))
      (asdf:load-asd (merge-pathnames \"arcdocdb.asd\" root))
      (asdf:load-system \"arcdocdb\" :force t)
      (unless (fboundp (find-symbol \"RADIX-SORT-ENTRIES\" \"ARCDOCDB.RECOVERY.DECISIONS\"))
        (ensure-directories-exist \"spikes/out/decisions-bench-fasl/radix.fasl\")
        (load (compile-file \"src/recovery/decisions-radix.lisp\"
                            :output-file \"spikes/out/decisions-bench-fasl/radix.fasl\"))))))
(load-product)

(defconstant +seed+ #x123456789abcdef0)
(defconstant +mask+ #xffffffffffffffff)
(defconstant +max-copy-bytes+ 67108864)
(defconstant +max-iterations+ 65536)
(defconstant +replicas+ 3)
(defconstant +minimum-duration-ticks+ (ceiling internal-time-units-per-second 20))
(defconstant +calibration-target-ticks+ (ceiling internal-time-units-per-second 10))

(define-condition incorrect-sort (error) ()
  (:documentation \"Il risultato misurato differisce dall'oracolo indipendente.\")
  (:report (lambda (condition stream)
             (declare (ignore condition))
             (write-string \"Ordinamento diverso dall'oracolo.\" stream))))
(define-condition reporter-probe-failure (error) ()
  (:documentation \"Errore intenzionale del self-test del reporter.\"))

(defun scrambled (number)
  (logand +mask+ (+ +seed+ (* number #x9e3779b97f4a7c15))))

(defun store-be64 (buffer start number)
  (dotimes (i 8) (setf (aref buffer (+ start i)) (ldb (byte 8 (* 8 (- 7 i))) number))))

(defun fixture (scope count pattern)
  \"Fixture univoche; duplicati ammessi solo nei TXID, con identità fisica preservata.\"
  (ecase scope
    (:participants
     (let ((buffer (make-array (* 16 count) :element-type '(unsigned-byte 8) :initial-element 0)))
       (dotimes (i count)
         (let ((key (ecase pattern (:ordered i) (:reverse (- count i 1))
                                  (:mixed (scrambled i)) (:full (scrambled i)))))
           (when (eq pattern :full) (store-be64 buffer (* 16 i) key))
           (store-be64 buffer (+ (* 16 i) 8) (if (eq pattern :full) (scrambled key) key))))
       buffer))
    (:entries
     (let ((entries (make-array count))
           (participants (make-array 32 :element-type '(unsigned-byte 8) :initial-element 0)))
       (setf (aref participants 31) 1)
       (dotimes (i count)
         (setf (aref entries i)
               (arcdocdb.recovery.decisions::%make-decision-entry
                (ecase pattern (:ordered i) (:reverse (- count i 1)) (:mixed (scrambled i))
                               (:duplicates (scrambled (floor i 4))) (:uniform 0))
                0 2 participants i)))
       entries))))

(defun id-less-p (buffer a b)
  (dotimes (i 16 nil)
    (let ((left (aref buffer (+ (* a 16) i))) (right (aref buffer (+ (* b 16) i))))
      (when (/= left right) (return (< left right))))))

(defun oracle (scope input)
  \"Oracolo a stable-sort indipendente dai due algoritmi del prodotto.\"
  (ecase scope
    (:entries (stable-sort (copy-seq input) #'< :key #'arcdocdb.recovery.decisions::%entry-txid))
    (:participants
     (let* ((count (/ (length input) 16)) (indexes (make-array count)) (result (copy-seq input)))
       (dotimes (i count) (setf (aref indexes i) i))
       (stable-sort indexes (lambda (a b) (id-less-p input a b)))
       (dotimes (i count)
         (replace result input :start1 (* i 16) :end1 (* (1+ i) 16)
                               :start2 (* (aref indexes i) 16) :end2 (* (1+ (aref indexes i)) 16)))
       result))))

(defun matches-p (scope expected actual)
  (and (= (length expected) (length actual))
       (ecase scope
         (:participants (equalp expected actual))
         (:entries (loop for a across expected for b across actual always (eq a b))))))

(defun algorithm (scope name count)
  (ecase scope
    (:entries (ecase name (:merge #'arcdocdb.recovery.decisions::sort-entries)
                         (:radix #'arcdocdb.recovery.decisions::radix-sort-entries)))
    (:participants
     (let ((function (ecase name (:merge #'arcdocdb.recovery.decisions::sort-participants)
                                (:radix #'arcdocdb.recovery.decisions::radix-sort-participants))))
       (lambda (input) (funcall function input count 64))))))

(defun duration-kind (ticks)
  (unless (>= ticks 0) (error \"Durata negativa.\"))
  (if (plusp ticks) :measured :below-resolution))

(defun measurement (ticks heap iterations)
  \"Tick grezzi conservati; meno di 50 ms non autorizza una soglia.\"
  (unless (and (>= ticks 0) (>= heap 0) (plusp iterations))
    (error \"Contatore o iterazioni invalidi.\"))
  (let ((seconds (/ ticks (float internal-time-units-per-second 1d0)))
        (usable (>= ticks +minimum-duration-ticks+)))
    (list :iterations iterations :ticks ticks :seconds seconds :heap-bytes heap
          :status (duration-kind ticks)
          :quality (if usable :target-reached :insufficient-duration)
          :threshold-usable-p usable
          :seconds-per-sort (when (plusp ticks) (/ seconds iterations))
          :heap-bytes-per-sort (/ heap iterations))))

(defun sample (scope input expected function iterations &key (clock #'get-internal-real-time))
  \"Copie/oracolo/GC iniziale fuori misura; scratch e GC del sort inclusi.
CLOCK è iniettabile per dimostrare il percorso di durata nulla nel self-test.\"
  (unless (plusp iterations) (error \"Iterazioni non positive.\"))
  (let ((copies (make-array iterations)) (outputs (make-array iterations)))
    (dotimes (i iterations) (setf (aref copies i) (copy-seq input)))
    (sb-ext:gc :full t)
    (let* ((before (sb-ext:get-bytes-consed)) (start (funcall clock)))
      (dotimes (i iterations) (setf (aref outputs i) (funcall function (aref copies i))))
      (let ((ticks (- (funcall clock) start)) (heap (- (sb-ext:get-bytes-consed) before)))
        (dotimes (i iterations)
          (unless (matches-p scope expected (aref outputs i)) (error 'incorrect-sort)))
        (measurement ticks heap iterations)))))

(defun iteration-cap (scope input)
  \"Limita il payload delle copie, non l'heap totale del campione.\"
  (let ((bytes (* (length input) (if (eq scope :entries) 8 1))))
    (when (> bytes +max-copy-bytes+) (error \"Una copia supera il budget.\"))
    (min +max-iterations+ (floor +max-copy-bytes+ (max 1 bytes)))))

(defun calibrate (scope input expected function progress checkpoint)
  \"Al massimo 17 tentativi; progress conserva warmup e ogni prova completata.\"
  (setf (getf progress :stage) :warmup (getf progress :warmups-completed) 0)
  (when checkpoint (funcall checkpoint))
  (dotimes (i 2)
    (unless (matches-p scope expected (funcall function (copy-seq input))) (error 'incorrect-sort))
    (incf (getf progress :warmups-completed))
    (when checkpoint (funcall checkpoint)))
  (let ((cap (iteration-cap scope input)) (iterations 1))
    (setf (getf progress :iteration-cap) cap
          (getf progress :target-ticks) +calibration-target-ticks+)
    (dotimes (attempt 17)
      (setf (getf progress :stage) :measurement (getf progress :attempt) attempt
            (getf progress :iterations) iterations)
      (when checkpoint (funcall checkpoint))
      (let ((result (sample scope input expected function iterations)))
        (setf (getf progress :probes) (append (getf progress :probes) (list result))
              (getf progress :probe) result)
        (when checkpoint (funcall checkpoint))
        (when (or (>= (getf result :ticks) +calibration-target-ticks+) (= iterations cap))
          (setf (getf progress :quality)
                (if (>= (getf result :ticks) +calibration-target-ticks+)
                    :target-reached :insufficient-duration)
                (getf progress :stage) :complete)
          (when checkpoint (funcall checkpoint))
          (return-from calibrate progress)))
      (setf iterations (min cap (* 2 iterations))))
    (error \"Calibrazione oltre il limite.\")))

(defun campaign (scope count pattern progress checkpoint)
  \"Aggiorna uno scenario già posseduto dal report prima di ogni passo fallibile.\"
  (setf (getf progress :stage) :fixtures)
  (when checkpoint (funcall checkpoint))
  (let* ((input (fixture scope count pattern)) (original (copy-seq input)) (expected (oracle scope input))
         (merge (algorithm scope :merge count)) (radix (algorithm scope :radix count)))
    (dolist (name '(:merge :radix))
      (let ((state (list :algorithm name :stage :pending :warmups-completed 0
                         :iteration-cap nil :target-ticks nil :attempt nil :iterations nil
                         :probes nil :probe nil :quality nil)))
        (setf (getf progress :stage) :calibration (getf progress :algorithm) name
              (getf progress :calibrations) (append (getf progress :calibrations) (list (cons name state))))
        (calibrate scope input expected (if (eq name :merge) merge radix) state checkpoint)))
    (dotimes (replica +replicas+)
      (dolist (name (if (evenp replica) '(:merge :radix) '(:radix :merge)))
        (setf (getf progress :stage) :replica (getf progress :algorithm) name
              (getf progress :replica) replica)
        (when checkpoint (funcall checkpoint))
        (let* ((calibration (cdr (assoc name (getf progress :calibrations))))
               (result (sample scope input expected (if (eq name :merge) merge radix)
                               (getf calibration :iterations))))
          (unless (eq (getf calibration :quality) :target-reached)
            (setf (getf result :threshold-usable-p) nil))
          (setf (getf progress :samples)
                (append (getf progress :samples)
                        (list (list :algorithm name :replica replica :measurement result))))
          (when checkpoint (funcall checkpoint)))))
    (setf (getf progress :stage) :fixture-check)
    (unless (equalp input original) (error \"Fixture modificata.\"))
    (setf (getf progress :stage) :complete (getf progress :status) :ok)
    (when checkpoint (funcall checkpoint))
    progress))

(defun campaign-specifications ()
  (loop for scope in '(:participants :entries) append
        (loop for count in '(16 64 256 1024 4096 16384 65535) append
              (loop for pattern in (if (eq scope :participants)
                                       '(:ordered :reverse :mixed :full)
                                       '(:ordered :reverse :mixed :duplicates :uniform))
                    collect (list scope count pattern)))))

(defun run-campaigns (report &key checkpoint (runner #'campaign)
                                (specifications (campaign-specifications)))
  \"Collega anche lo scenario corrente al report; gli errori lasciano tutte le prove.\"
  (dolist (spec specifications)
    (destructuring-bind (scope count pattern) spec
      (let ((progress (list :scope scope :count count :pattern pattern :seed +seed+
                            :status :running :stage :pending :algorithm nil :replica nil
                            :calibrations nil :samples nil :diagnostic nil)))
        (setf (getf report :current-campaign) progress
              (getf report :campaigns) (append (getf report :campaigns) (list progress)))
        (when checkpoint (funcall checkpoint))
        (funcall runner scope count pattern progress checkpoint))))
  report)

(defun make-report ()
  (list :schema-version 1 :driver-version 2 :kind :decision-sort-benchmark :status :running
        :diagnostic nil :self-test nil :campaigns nil :current-campaign nil
        :seed +seed+ :replicas +replicas+ :workers 1 :safety 3
        :timer-units-per-second internal-time-units-per-second
        :timer-unit-seconds (/ 1 internal-time-units-per-second)
        :minimum-duration-ticks +minimum-duration-ticks+
        :calibration-target-ticks +calibration-target-ticks+
        :max-copy-bytes +max-copy-bytes+ :max-iterations +max-iterations+
        :threshold-policy '(:metric :median-seconds-per-sort :max-radix-over-merge 9/10
                            :separate-scopes t :all-patterns-at-or-above-threshold t
                            :insufficient-duration :keep-merge)
        :limits '(:sort-only :copies-and-oracle-outside-timing :gc-inside-sort-included
                  :copy-payload-budget-is-not-total-heap-budget :full-id-halves-correlated
                  :cold-recovery-allocation-permitted :macos-local-is-not-linux-qualification
                  :external-load-uncontrolled :no-engine-throughput-or-p99-claim)))

(defun claim-directory (requested)
  \"Restituisce solo una directory nuova creata da questo run; non scrive se esiste.\"
  (let* ((directory (uiop:ensure-directory-pathname requested))
         (parent (make-pathname :directory (butlast (pathname-directory directory))
                                :name nil :type nil :defaults directory)))
    (ensure-directories-exist (merge-pathnames \"parent.marker\" parent))
    (sb-posix:mkdir (namestring directory) #o700)
    directory))

(defun write-report (report owned-directory &key (if-exists :error))
  \"La directory è già stata creata dal run, mai una destinazione rifiutata.\"
  (unless owned-directory (error \"Directory non posseduta.\"))
  (with-open-file (stream (merge-pathnames \"report.lisp\" owned-directory)
                          :direction :output :if-exists if-exists)
    (write report :stream stream :pretty t) (terpri stream)))

(defun mark-failed (report condition)
  (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
  (let ((current (getf report :current-campaign)))
    (when current
      (setf (getf current :status) :failed (getf current :diagnostic) (princ-to-string condition))))
  report)

(defun run-driver (args &key (report (make-report)) (self-tester #'self-test)
                            (campaign-runner #'run-campaigns))
  \"Gli errori producono un report; solo una destinazione reclamata può essere scritta.\"
  (let ((owned-directory nil))
    (handler-case
        (progn
          (unless (or (equal args '(\"--self-test\"))
                      (and (= (length args) 2) (string= (first args) \"--bench\")))
            (error \"Usare --self-test oppure --bench directory-nuova/.\"))
          (when (= (length args) 2) (setf owned-directory (claim-directory (second args))))
          (setf (getf report :self-test) (funcall self-tester))
          (when owned-directory
            (funcall campaign-runner report
                     :checkpoint (lambda () (write-report report owned-directory :if-exists :supersede))))
          (setf (getf report :status) :ok)
          (when owned-directory (write-report report owned-directory :if-exists :supersede)))
      (error (condition)
        (mark-failed report condition)
        (when owned-directory (write-report report owned-directory :if-exists :supersede))))
    report))

(defun self-test-partial-run (report &key checkpoint)
  \"Un primo scenario completo e un secondo con prova parziale prima dell'errore.\"
  (run-campaigns report :checkpoint checkpoint :specifications '((:entries 16 :ordered) (:entries 16 :reverse))
    :runner (lambda (scope count pattern progress persist)
              (unless (and (eq scope :entries) (= count 16)) (error \"Spec self-test errata.\"))
              (setf (getf progress :samples) '((:algorithm :merge :measurement (:ticks 7))))
              (when persist (funcall persist))
              (if (eq pattern :ordered)
                  (setf (getf progress :stage) :complete (getf progress :status) :ok)
                  (progn (setf (getf progress :stage) :replica)
                         (error 'reporter-probe-failure))))))

(defun self-test-reporter ()
  \"Verifica i report parziali e l'intangibilità della destinazione già esistente.\"
  (uiop:with-temporary-file (:pathname marker :stream stream)
    (write-line \"marker\" stream)
    (let* ((base (append (pathname-directory marker) (list (concatenate 'string (pathname-name marker) \"-bench\"))))
           (fresh (make-pathname :directory base :name nil :type nil :defaults marker))
           (existing (make-pathname :directory (append base '(\"existing\")) :name nil :type nil :defaults marker))
           (owned-base nil))
      (unwind-protect
           (progn
             (setf owned-base (claim-directory fresh))
             (claim-directory existing)
             (write-report '(:sentinel :unchanged) existing)
             (let ((refused (run-driver (list \"--bench\" (namestring existing))
                                       :self-tester (constantly :passed))))
               (unless (eq (getf refused :status) :failed) (error \"Destinazione esistente accettata.\")))
             (with-open-file (input (merge-pathnames \"report.lisp\" existing))
               (let ((*read-eval* nil))
                 (unless (equal (read input) '(:sentinel :unchanged)) (error \"Report precedente modificato.\"))))
             (let* ((failed-directory (make-pathname :directory (append base '(\"failed\"))
                                                      :name nil :type nil :defaults marker))
                    (failed (run-driver (list \"--bench\" (namestring failed-directory))
                                        :self-tester (constantly :passed) :campaign-runner #'self-test-partial-run)))
               (unless (eq (getf failed :status) :failed) (error \"Errore del reporter non rilevato.\"))
               (with-open-file (input (merge-pathnames \"report.lisp\" failed-directory))
                 (let* ((*read-eval* nil) (saved (read input)) (cases (getf saved :campaigns)))
                   (unless (and (= (length cases) 2) (eq (getf (first cases) :status) :ok)
                                (eq (getf (second cases) :status) :failed)
                                (eq (getf (second cases) :stage) :replica)
                                (equal (getf (second cases) :samples)
                                       '((:algorithm :merge :measurement (:ticks 7)))))
                     (error \"Precedenti o prove parziali persi.\"))))))
        (when owned-base (uiop:delete-directory-tree owned-base :validate t))))))

(defun self-test ()
  (unless (and (eq (duration-kind 0) :below-resolution) (eq (duration-kind 1) :measured)
               (not (getf (measurement (1- +minimum-duration-ticks+) 0 1) :threshold-usable-p))
               (getf (measurement +minimum-duration-ticks+ 0 1) :threshold-usable-p))
    (error \"Classificazione del tempo errata.\"))
  (dolist (scope '(:participants :entries))
    (let* ((input (fixture scope 17 :mixed)) (expected (oracle scope input)))
      (unless (and (equalp input (fixture scope 17 :mixed)) (not (matches-p scope expected input)))
        (error \"Fixture/oracolo incapace di rilevare algoritmo identità.\"))
      (unless (handler-case (progn (sample scope input expected #'identity 2) nil)
                (incorrect-sort () t))
        (error \"Driver incapace di rifiutare algoritmo identità.\"))
      (dolist (name '(:merge :radix))
        (sample scope input expected (algorithm scope name 17) 2))
      (let ((zero (sample scope input expected (algorithm scope :merge 17) 2 :clock (constantly 0))))
        (unless (and (eq (getf zero :status) :below-resolution)
                     (eq (getf zero :quality) :insufficient-duration)
                     (null (getf zero :seconds-per-sort)) (null (getf zero :threshold-usable-p)))
          (error \"Tempo nullo utilizzato come misura.\")))))
  (self-test-reporter)
  :passed)

(defun main ()
  (let ((report (run-driver (uiop:command-line-arguments))))
    (if (eq (getf report :status) :ok)
        (format t \"Benchmark ordinamenti: self-test superato~A.~%\"
                (if (getf report :campaigns)
                    (format nil \", ~D scenari conservati\" (length (getf report :campaigns))) \"\"))
        (progn (format *error-output* \"~A~%\" (getf report :diagnostic))
               (sb-ext:exit :code 1)))))

(main)
")
  (:SOURCE-PATH "/tmp/arcdocdb-radix-selection.lisp" :GIT-BLOB
   "2f39606812e5ba85a914bc1e4ac3b1a6c51ff4f7" :TEXT "(defun median3 (values)
  (unless (and (= 3 (length values)) (every #'numberp values)) (error \"Tre misure necessarie.\"))
  (second (sort (copy-list values) #'<)))
(let* ((*read-eval* nil)
       (path \"spikes/out/decisions-sort-benchmark/report.lisp\")
       (report (with-open-file (s path) (read s)))
       (rows nil))
  (unless (and (eq (getf report :status) :ok) (= 63 (length (getf report :campaigns))))
    (error \"Campagna incompleta.\"))
  (dolist (c (getf report :campaigns))
    (let ((medians nil) (heaps nil) (usable t))
      (unless (and (eq (getf c :status) :ok) (= 6 (length (getf c :samples))))
        (error \"Scenario incompleto.\"))
      (dolist (name '(:merge :radix))
        (let ((times nil) (bytes nil))
          (dolist (x (getf c :samples))
            (when (eq name (getf x :algorithm))
              (let ((m (getf x :measurement)))
                (unless (getf m :threshold-usable-p) (setf usable nil))
                (push (getf m :seconds-per-sort) times)
                (push (getf m :heap-bytes-per-sort) bytes))))
          (push (cons name (when (every #'numberp times) (median3 times))) medians)
          (push (cons name (median3 bytes)) heaps)))
      (let* ((merge (cdr (assoc :merge medians))) (radix (cdr (assoc :radix medians)))
             (ratio (when (and merge radix (plusp merge)) (/ radix merge)))
             (row (list :scope (getf c :scope) :count (getf c :count) :pattern (getf c :pattern)
                        :usable usable :median-merge-seconds merge :median-radix-seconds radix
                        :radix-over-merge ratio :merge-heap-bytes (cdr (assoc :merge heaps))
                        :radix-heap-bytes (cdr (assoc :radix heaps))
                        :passes (and usable ratio (<= ratio 9/10)))))
        (push row rows)
        (format t \"~A ~D ~A usable=~A ratio=~,4F~%\"
                (getf row :scope) (getf row :count) (getf row :pattern) usable (or ratio 0)))))
  (setf rows (nreverse rows))
  (let ((selections nil))
    (dolist (scope '(:participants :entries))
      (let* ((selected (remove-if-not (lambda (r) (eq scope (getf r :scope))) rows))
             (counts (sort (remove-duplicates (mapcar (lambda (r) (getf r :count)) selected)) #'<))
             (threshold (find-if (lambda (n) (every (lambda (r) (or (< (getf r :count) n) (getf r :passes))) selected)) counts)))
        (push (list :scope scope :threshold threshold :adopted (not (null threshold))) selections)
        (format t \"SELECTION ~A threshold=~A~%\" scope threshold)))
    (with-open-file (out \"spikes/out/decisions-sort-selection.lisp\" :direction :output :if-exists :error)
      (write (list :schema-version 1 :kind :decision-sort-selection :source-benchmark path
                   :policy '(:separate-scopes :all-patterns-at-or-above-threshold :minimum-50ms :median-ratio-at-most-9/10)
                   :selections (nreverse selections) :scenarios rows
                   :limits '(:local-sort-only :no-extrapolated-performance :no-heap-or-engine-qualification))
             :stream out :pretty t)
      (terpri out))))
")
  (:SOURCE-PATH "/tmp/arcdocdb-radix-selection-100ms.lisp" :GIT-BLOB
   "a9372963f6a34e975d23dad0e06240134167ac55" :TEXT "(defun median3 (values)
  (unless (and (= 3 (length values)) (every #'numberp values)) (error \"Tre misure necessarie.\"))
  (second (sort (copy-list values) #'<)))
(let* ((*read-eval* nil)
       (path \"spikes/out/decisions-sort-benchmark-100ms/report.lisp\")
       (report (with-open-file (s path) (read s)))
       (rows nil))
  (unless (and (eq (getf report :status) :ok) (= 63 (length (getf report :campaigns))))
    (error \"Campagna incompleta.\"))
  (dolist (c (getf report :campaigns))
    (let ((medians nil) (heaps nil) (usable t))
      (unless (and (eq (getf c :status) :ok) (= 6 (length (getf c :samples))))
        (error \"Scenario incompleto.\"))
      (dolist (name '(:merge :radix))
        (let ((times nil) (bytes nil))
          (dolist (x (getf c :samples))
            (when (eq name (getf x :algorithm))
              (let ((m (getf x :measurement)))
                (unless (getf m :threshold-usable-p) (setf usable nil))
                (push (getf m :seconds-per-sort) times)
                (push (getf m :heap-bytes-per-sort) bytes))))
          (push (cons name (when (every #'numberp times) (median3 times))) medians)
          (push (cons name (median3 bytes)) heaps)))
      (let* ((merge (cdr (assoc :merge medians))) (radix (cdr (assoc :radix medians)))
             (ratio (when (and merge radix (plusp merge)) (/ radix merge)))
             (row (list :scope (getf c :scope) :count (getf c :count) :pattern (getf c :pattern)
                        :usable usable :median-merge-seconds merge :median-radix-seconds radix
                        :radix-over-merge ratio :merge-heap-bytes (cdr (assoc :merge heaps))
                        :radix-heap-bytes (cdr (assoc :radix heaps))
                        :passes (and usable ratio (<= ratio 9/10)))))
        (push row rows)
        (format t \"~A ~D ~A usable=~A ratio=~,4F~%\"
                (getf row :scope) (getf row :count) (getf row :pattern) usable (or ratio 0)))))
  (setf rows (nreverse rows))
  (let ((selections nil))
    (dolist (scope '(:participants :entries))
      (let* ((selected (remove-if-not (lambda (r) (eq scope (getf r :scope))) rows))
             (counts (sort (remove-duplicates (mapcar (lambda (r) (getf r :count)) selected)) #'<))
             (threshold (find-if (lambda (n) (every (lambda (r) (or (< (getf r :count) n) (getf r :passes))) selected)) counts)))
        (push (list :scope scope :threshold threshold :adopted (not (null threshold))) selections)
        (format t \"SELECTION ~A threshold=~A~%\" scope threshold)))
    (with-open-file (out \"spikes/out/decisions-sort-selection-100ms.lisp\" :direction :output :if-exists :error)
      (write (list :schema-version 1 :kind :decision-sort-selection :source-benchmark path
                   :policy '(:separate-scopes :all-patterns-at-or-above-threshold :minimum-50ms :median-ratio-at-most-9/10)
                   :selections (nreverse selections) :scenarios rows
                   :limits '(:local-sort-only :no-extrapolated-performance :no-heap-or-engine-qualification))
             :stream out :pretty t)
      (terpri out))))
")
  (:SOURCE-PATH "spikes/out/radix-strict-tools.lisp" :GIT-BLOB
   "7ca81e8288401927dc4493bf7617d573b9483e17" :TEXT "(require :asdf)
(require :sb-posix)
(proclaim '(optimize (safety 3) (debug 2)))
(asdf:initialize-output-translations
 `(:output-translations (,(truename \"./\") ,(merge-pathnames \"spikes/out/radix-strict-fasl/\" (truename \"./\"))) :ignore-inherited-configuration))
(setf asdf:*compile-file-warnings-behaviour* :error asdf:*compile-file-failure-behaviour* :error)
(handler-bind ((warning (lambda (c) (unless (typep c 'sb-kernel:redefinition-warning) (error c)))))
 (asdf:load-asd (truename \"arcdocdb.asd\")) (asdf:load-system \"arcdocdb\")
 (dolist (source '(\"tools/decisions-sort-bench.lisp\" \"tools/decisions-radix-mutation.lisp\"))
  (let ((target (merge-pathnames (make-pathname :name (pathname-name source) :type \"fasl\") \"spikes/out/radix-strict-fasl/\")))
   (ensure-directories-exist target)
   (multiple-value-bind (fasl warnings failure) (compile-file source :output-file target)
    (when (or warnings failure) (error \"Compilazione tool non rigorosa: ~A\" source))
    (load fasl)))))
"))
 :LIMITS (:SOURCE-TEXT-ONLY :READ-WITH-READ-EVAL-NIL :DO-NOT-LOAD-EVIDENCE))
