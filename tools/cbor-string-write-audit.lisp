;;;; Audit C4 indipendente dei dati del benchmark stringhe CBOR.
;;;; Uso: --self-test oppure --bench <report-wrapper.lisp>.
;;;; Nessun prodotto, driver, builder o oracolo di test viene caricato.
;;;; OWNER: dati freddi locali; il contatore appartiene alla singola esecuzione.
;;;; REQ: REQ-CBR-002 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
(require :asdf)
(let ((*load-verbose* nil) (*load-print* nil) (*standard-output* *error-output*))
  (load (merge-pathnames "evidence-storage.lisp" *load-truename*)))
(defpackage #:arcdocdb.cbor-string-write.audit (:use #:cl))
(in-package #:arcdocdb.cbor-string-write.audit)
(declaim (optimize (safety 3) (debug 2)))

(defconstant +driver-blob+ "c4bd98e145d13deb47b7eedb0f4581a241f1d0e1")
(defconstant +product-blob+ "a2c5c77dd51bff760bff4508e998d94370921eda")
(defconstant +driver-md5+ "fce9240d1890ada3d21a7966352b34d9")
(defconstant +product-md5+ "b13e92b5f24a42fe283c17b649722b6a")
(defparameter *checks* 0)
(defparameter *catalog*
  '((:bytes-23 2 :bytes 23) (:bytes-24 2 :bytes 24)
    (:bytes-256 2 :bytes 256) (:bytes-65536 2 :bytes 65536)
    (:text-23 3 :text 23) (:text-24 3 :text 24)
    (:text-256 3 :text 256) (:text-65536 3 :text 65536)
    (:unicode-16 3 :unicode 16)))
(defparameter *benchmark-limits*
  '(:success-path-only :serial :preallocated-private-buffers-and-sources
    :minimal-definite-strings-major-2-and-3-only
    :counter-not-absolute-nonallocation-proof :external-load-uncontrolled
    :output-check-cost-included :no-pool-or-device-throughput
    :no-scaling-or-latency-threshold))

(define-condition audit-rejection (error)
  ((reason :initarg :reason :reader rejection-reason)
   (detail :initarg :detail :initform nil :reader rejection-detail))
  (:report (lambda (condition stream)
             (let ((*print-circle* t) (*print-level* 5) (*print-length* 10))
               (format stream "Audit stringhe CBOR rifiutato: ~S~@[ (~S)~]."
                       (rejection-reason condition) (rejection-detail condition))))))

(defun require-check (predicate reason &optional detail)
  "Conta un controllo; il fallimento conserva un motivo specifico verificabile."
  (incf *checks*)
  (unless predicate (error 'audit-rejection :reason reason :detail detail))
  t)

(defun proper-length (value)
  "Lunghezza soltanto per liste proprie e acicliche; zero e distinto da NIL."
  (handler-case (list-length value) (type-error () nil)))

(defun checked-plist (data fields)
  "Rifiuta liste improprie/cicliche, chiavi duplicate e campi richiesti assenti."
  (let ((size (proper-length data)) (seen nil) (absent (gensym "ABSENT")))
    (require-check (and (consp data) size (evenp size)) :plist-shape)
    (loop for key in data by #'cddr
          do (require-check (keywordp key) :plist-key key)
             (require-check (not (member key seen)) :duplicate-key key)
             (push key seen))
    (dolist (field fields)
      (require-check (not (eq absent (getf data field absent))) :missing-field field))
    data))

(defun read-one (text)
  "Una forma dati e EOF, con readtable standard e READ-EVAL NIL."
  (require-check (stringp text) :stdout-type)
  (let ((*read-eval* nil) (*readtable* (copy-readtable nil)) (*read-base* 10)
        (*read-suppress* nil) (*package* (find-package :cl-user)) (eof (gensym "EOF")))
    (handler-case
        (with-input-from-string (stream text)
          (let ((data (read stream nil eof)))
            (require-check (not (eq data eof)) :reader-empty)
            (require-check (eq eof (read stream nil eof)) :reader-trailing)
            (checked-plist data nil)))
      (audit-rejection (condition) (error condition))
      (error (condition)
        (error 'audit-rejection :reason :reader-error :detail (princ-to-string condition))))))

(defun hex-string-p (value size)
  "Verifica la forma esadecimale, senza trattare un hash come autenticazione."
  (and (stringp value) (= size (length value))
       (every (lambda (character) (digit-char-p character 16)) value)))

(defun nonempty-string-p (value)
  "Predicato sui metadata testuali, senza conversioni o valutazione."
  (and (stringp value) (plusp (length value))))

(defun relative-path-p (value)
  "Un nome relativo non ambiguo, senza NUL, wildcard o traversamento."
  (and (nonempty-string-p value) (not (char= #\/ (char value 0)))
       (not (find-if (lambda (character) (find character '(#\Null #\\ #\* #\? #\[ #\]))) value))
       (not (member ".." (uiop:split-string value :separator '(#\/)) :test #'string=))))

(defun source-table (entries path-key hash-key size &optional absent-allowed)
  "Indicizza esclusivamente i nomi dichiarati; non attesta un inventario completo."
  (require-check (let ((count (proper-length entries))) (and count (plusp count)))
                 :source-table-shape)
  (let ((table (make-hash-table :test 'equal)))
    (dolist (entry entries table)
      (checked-plist entry (list path-key hash-key))
      (require-check (= 4 (length entry)) :source-entry-fields)
      (let ((path (getf entry path-key)) (hash (getf entry hash-key)))
        (require-check (relative-path-p path) :source-path path)
        (require-check (not (nth-value 1 (gethash path table))) :source-path-duplicate path)
        (require-check (or (and absent-allowed (eq hash :absent)) (hex-string-p hash size))
                       :source-hash path)
        (setf (gethash path table) hash)))))

(defun close-number-p (actual expected)
  "Tolleranza numerica relativa per ricostruzioni del clock, senza soglia di velocita."
  (and (realp actual) (<= 0 actual)
       (<= (abs (- actual expected)) (* 1d-9 (max 1d0 (abs expected))))))

(defun arithmetic-header (major length)
  "Codifica fredda matematica: divisione base 256, nessun helper del codec."
  (let* ((width (cond ((< length 24) 0) ((< length 256) 1)
                      ((< length 65536) 2) (t 4)))
         (ai (case width (0 length) (1 24) (2 25) (4 26)
               (otherwise (error 'audit-rejection :reason :reference-width)))))
    (cons (+ (* 32 major) ai)
          (loop for power downfrom (1- width) to 0
                collect (mod (floor length (expt 256 power)) 256)))))

(defun reference-cell (spec)
  "Ricostruisce payload, buffer intero e token; UTF-8 e una sequenza letterale."
  (destructuring-bind (name major kind length) spec
    (let* ((header (arithmetic-header major length))
           (payload (case kind
                      (:bytes (make-list length :initial-element 255))
                      (:text (make-list length :initial-element 97))
                      (:unicode (list 0 195 169 226 130 172 240 159
                                      153 130 239 187 191 239 191 190))
                      (otherwise (error 'audit-rejection :reason :reference-kind))))
           (size (+ (length header) length)) (next (+ 2 size))
           (full (append (list 165 165) header payload (list 165 165 165 165)))
           (token (+ next (loop for byte in full for weight from 1 sum (* weight byte)))))
      (require-check (= length (length payload)) :reference-length name)
      (list :name name :major major :kind kind :length length :header header
            :size size :next next :end (+ next 2) :full full :token token))))

(defun independent-sink (iterations token)
  "Residuo della somma dei token piu gli indici 0..ITERATIONS-1."
  (mod (+ (* iterations token) (floor (* iterations (1- iterations)) 2))
       (1+ most-positive-fixnum)))

(defun audit-sample (sample iterations warmup token timer heap-mode)
  "Verifica parametri, heap, sink e relazioni del clock per un campione."
  (checked-plist sample '(:iterations :warmup-iterations :heap-bytes :raw-ticks :seconds
                          :sink :expected-sink :expected-return-token :calls-per-second))
  (require-check (eql iterations (getf sample :iterations)) :sample-iterations)
  (require-check (eql warmup (getf sample :warmup-iterations)) :sample-warmup)
  (require-check (eql token (getf sample :expected-return-token)) :sample-token)
  (let ((heap (getf sample :heap-bytes)) (ticks (getf sample :raw-ticks))
        (sink (independent-sink iterations token)))
    (require-check (and (integerp heap) (not (minusp heap))) :sample-heap-shape)
    (require-check (case heap-mode
                     (:zero (zerop heap)) (:positive (>= heap 16777216))
                     (otherwise nil))
                   (if (eq heap-mode :zero) :sample-heap :positive-counter))
    (require-check (and (eql sink (getf sample :sink)) (eql sink (getf sample :expected-sink)))
                   :sample-sink)
    (require-check (and (integerp ticks) (not (minusp ticks))) :sample-ticks)
    (let ((seconds (/ ticks (float timer 1d0))))
      (require-check (close-number-p (getf sample :seconds) seconds) :sample-time)
      (require-check (if (zerop ticks) (null (getf sample :calls-per-second))
                        (close-number-p (getf sample :calls-per-second) (/ iterations seconds)))
                     :sample-rate)
      seconds)))

(defun audit-self-controls (controls timer)
  "Sensori indipendenti: baseline zero, 16 MiB deliberati e checker con marker esatti."
  (checked-plist controls '(:status :baseline :positive-control :output-checker :arity-checker))
  (require-check (eq :ok (getf controls :status)) :self-control-status)
  (let ((baseline (getf controls :baseline)) (positive (getf controls :positive-control))
        (checker (getf controls :output-checker)) (arity (getf controls :arity-checker)))
    (checked-plist baseline '(:heap-bytes))
    (require-check (eql 0 (getf baseline :heap-bytes)) :baseline-heap)
    (checked-plist checker '(:status :expected-token :altered-next-rejected
                            :altered-prefix-payload-suffix-rejected))
    (require-check (and (eq :ok (getf checker :status))
                        (= (getf checker :expected-token)
                           (+ 4 (loop for byte in '(165 165 65 255 165 165)
                                      for weight from 1 sum (* weight byte))))
                        (eq t (getf checker :altered-next-rejected))
                        (eql 3 (getf checker :altered-prefix-payload-suffix-rejected)))
                   :checker-self-test)
    (checked-plist arity '(:status :single-value-accepted :wrong-arity-or-next-rejected))
    (require-check (and (eq :ok (getf arity :status)) (eq t (getf arity :single-value-accepted))
                        (eql 4 (getf arity :wrong-arity-or-next-rejected))) :arity-self-test)
    (+ (audit-sample baseline 4096 128 0 timer :zero)
       (audit-sample positive 16 0 1048576 timer :positive))))

(defun audit-cell (cell spec timer)
  "Controlla tutti i byte attesi, sentinelle comprese, e le cinque repliche."
  (checked-plist cell '(:name :major :payload-kind :payload-bytes :unit-bytes
                       :expected-header-bytes :expected-full-buffer :expected-next :expected-token
                       :cold-values :cold-value-count :start :end :source-start :source-end
                       :source-unchanged :private-preallocated-buffer-and-source
                       :complete-output-checked-per-call :samples))
  (let* ((ref (reference-cell spec)) (next (getf ref :next)) (token (getf ref :token))
         (cold (getf cell :cold-values)) (samples (getf cell :samples)))
    (dolist (mapping '((:name :name) (:major :major) (:payload-kind :kind)
                       (:payload-bytes :length) (:unit-bytes :size)))
      (require-check (equal (getf cell (first mapping)) (getf ref (second mapping)))
                     :fixture-definition (getf ref :name)))
    (require-check (equal (getf ref :header) (getf cell :expected-header-bytes)) :fixture-header)
    (require-check (equal (getf ref :full) (getf cell :expected-full-buffer)) :fixture-buffer)
    (require-check (eql next (getf cell :expected-next)) :fixture-next)
    (require-check (eql token (getf cell :expected-token)) :fixture-token)
    (require-check (and (eql 1 (proper-length cold)) (eql 1 (getf cell :cold-value-count))
                        (eql next (first cold))) :fixture-arity)
    (require-check (and (eql 2 (getf cell :start)) (eql (getf ref :end) (getf cell :end))
                        (eql 3 (getf cell :source-start))
                        (eql (+ 3 (getf ref :length)) (getf cell :source-end))) :fixture-span)
    (dolist (key '(:source-unchanged :private-preallocated-buffer-and-source
                   :complete-output-checked-per-call))
      (require-check (eq t (getf cell key)) :fixture-observation key))
    (require-check (eql 5 (proper-length samples)) :fixture-sample-count)
    (loop for sample in samples sum (audit-sample sample 4096 128 token timer :zero))))

(defun audit-benchmark (report wrapper)
  "Audit dei dati freddi; non prova autenticita, esecuzione o completezza dell'inventario."
  (checked-plist report '(:schema-version :kind :status :campaigns :self-test :recorded-at
                         :sbcl :machine :os :os-version :workers :safety :timer-units-per-second
                         :limits :source-fingerprints-before :source-fingerprints-after
                         :source-consistency))
  (require-check (and (eql 1 (getf report :schema-version))
                      (eq :cbor-string-write-benchmark (getf report :kind))) :benchmark-schema)
  (require-check (eq :ok (getf report :status)) :benchmark-status)
  (require-check (eql 3 (getf report :safety)) :metadata-safety)
  (require-check (eql 1 (getf report :workers)) :metadata-workers)
  (require-check (equal *benchmark-limits* (getf report :limits)) :metadata-limits)
  (dolist (key '(:sbcl :machine :os :os-version))
    (require-check (nonempty-string-p (getf report key)) :metadata-text key))
  (let ((environment (getf wrapper :environment)))
    (dolist (mapping '((:sbcl :version) (:machine :machine) (:os :os) (:os-version :os-version)))
      (require-check (equal (getf report (first mapping)) (getf environment (second mapping)))
                     :metadata-environment (first mapping))))
  (let* ((before (getf report :source-fingerprints-before))
         (after (getf report :source-fingerprints-after))
         (table (source-table before :file :md5 32))
         (timer (getf report :timer-units-per-second)) (cells (getf report :campaigns)))
    (source-table after :file :md5 32)
    (require-check (and (eq :stable (getf report :source-consistency)) (equal before after))
                   :fingerprint-stability)
    (require-check (equal +driver-md5+ (gethash "tools/cbor-string-write-bench.lisp" table))
                   :fingerprint-driver)
    (require-check (equal +product-md5+ (gethash "src/codec/cbor-string-write.lisp" table))
                   :fingerprint-product)
    (require-check (nth-value 1 (gethash "arcdocdb.asd" table)) :fingerprint-asdf)
    (require-check (and (integerp timer) (plusp timer)) :metadata-timer)
    (require-check (and (eql 9 (proper-length cells))
                        (every (lambda (cell) (checked-plist cell '(:name))) cells)
                        (equal (mapcar #'first *catalog*) (mapcar (lambda (cell) (getf cell :name)) cells)))
                   :fixture-catalog)
    (let* ((control-seconds (audit-self-controls (getf report :self-test) timer))
           (sample-seconds (loop for cell in cells for spec in *catalog*
                                 sum (audit-cell cell spec timer)))
           (recorded (getf report :recorded-at))
           (started (getf wrapper :started-at-universal-time))
           (finished (getf wrapper :finished-at-universal-time)))
      (require-check (and (integerp recorded) (<= started recorded finished)) :metadata-recorded-time)
      (require-check (<= (+ control-seconds sample-seconds)
                         (+ (getf wrapper :wall-seconds) (/ 47d0 timer))) :sample-wall-time)
      (list :cells 9 :samples 45 :heap-bytes 0 :cold-arity 1 :sink-mask most-positive-fixnum
            :sample-seconds sample-seconds :self-control-seconds control-seconds
            :baseline-heap-bytes 0
            :positive-control-heap-bytes (getf (getf (getf report :self-test) :positive-control) :heap-bytes)
            :timer-units-per-second timer :recorded-at recorded
            :source-fingerprint-count (length before)))))

(defun audit-wrapper (wrapper)
  "Verifica processo, snapshot, argv, metadata e una sola forma STDOUT."
  (checked-plist wrapper '(:schema-version :kind :status :exit-code :source-consistency
                          :source-blobs-before :source-blobs-after :stdout :stderr :command
                          :environment :started-at-universal-time :finished-at-universal-time
                          :wall-seconds))
  (require-check (and (eql 1 (getf wrapper :schema-version))
                      (eq :command-verification (getf wrapper :kind))) :wrapper-schema)
  (require-check (eq :ok (getf wrapper :status)) :wrapper-status)
  (require-check (eql 0 (getf wrapper :exit-code)) :wrapper-exit)
  (require-check (stringp (getf wrapper :stderr)) :wrapper-stderr)
  (let* ((before (getf wrapper :source-blobs-before)) (after (getf wrapper :source-blobs-after))
         (table (source-table before :path :git-blob 40 t)) (command (getf wrapper :command))
         (environment (getf wrapper :environment))
         (started (getf wrapper :started-at-universal-time))
         (finished (getf wrapper :finished-at-universal-time)) (wall (getf wrapper :wall-seconds)))
    (source-table after :path :git-blob 40 t)
    (require-check (and (eq :stable (getf wrapper :source-consistency)) (equal before after))
                   :wrapper-source-stability)
    (require-check (equal +driver-blob+ (gethash "tools/cbor-string-write-bench.lisp" table))
                   :wrapper-driver-blob)
    (require-check (equal +product-blob+ (gethash "src/codec/cbor-string-write.lisp" table))
                   :wrapper-product-blob)
    (require-check (let ((size (proper-length command)))
                     (and size (>= size 3) (every #'stringp command)
                          (equal '("--script" "tools/cbor-string-write-bench.lisp" "--bench")
                                 (last command 3)))) :wrapper-command)
    (checked-plist environment '(:lisp :version :machine :os :os-version :commit :cwd
                                 :date-universal-time :external-load-status))
    (require-check (equal "SBCL" (getf environment :lisp)) :wrapper-lisp)
    (require-check (eq :uncontrolled (getf environment :external-load-status)) :wrapper-external-load)
    (dolist (key '(:version :machine :os :os-version :cwd))
      (require-check (nonempty-string-p (getf environment key)) :wrapper-environment key))
    (require-check (hex-string-p (getf environment :commit) 40) :wrapper-commit)
    (require-check (and (integerp started) (plusp started) (integerp finished) (<= started finished)
                        (integerp (getf environment :date-universal-time))
                        (<= (1- started) (getf environment :date-universal-time) finished)
                        (realp wall) (not (minusp wall))
                        ;; Il contatore wall parte prima di AMBIENTE/STARTED.
                        ;; Overhead metadata lecito, con un secondo di quantizzazione.
                        (<= (- finished started 1) wall)) :wrapper-time)
    (audit-benchmark (read-one (getf wrapper :stdout)) wrapper)))

(defun serialized (data)
  "Imprime soltanto dati sintetici con una rappresentazione leggibile."
  (let ((*print-readably* t) (*print-circle* nil) (*print-pretty* nil))
    (write-to-string data)))

(defun synthetic-sample (iterations warmup token heap &optional (ticks 1024))
  "Costruisce metadata di campione sintetici, senza misure o codice di prodotto."
  (let ((seconds (/ ticks 1000000d0)) (sink (independent-sink iterations token)))
    (list :iterations iterations :warmup-iterations warmup :heap-bytes heap
          :raw-ticks ticks :seconds seconds :sink sink :expected-sink sink
          :expected-return-token token :calls-per-second (when (plusp ticks) (/ iterations seconds)))))

(defun synthetic-report ()
  "Report positivo per falsificare l'auditor; non e una prova di esecuzione del prodotto."
  (let ((fingerprints (list (list :file "arcdocdb.asd" :md5 (make-string 32 :initial-element #\0))
                            (list :file "tools/cbor-string-write-bench.lisp" :md5 +driver-md5+)
                            (list :file "src/codec/cbor-string-write.lisp" :md5 +product-md5+))))
    (list :schema-version 1 :kind :cbor-string-write-benchmark :status :ok
          :recorded-at 1000 :sbcl "synthetic-version" :machine "synthetic-machine"
          :os "synthetic-os" :os-version "synthetic-os-version" :workers 1 :safety 3
          :timer-units-per-second 1000000 :limits (copy-list *benchmark-limits*)
          :source-fingerprints-before fingerprints :source-fingerprints-after (copy-tree fingerprints)
          :source-consistency :stable
          :self-test (list :status :ok :baseline (synthetic-sample 4096 128 0 0)
                           :positive-control (synthetic-sample 16 0 1048576 16777472)
                           :output-checker (list :status :ok :expected-token 3529 :altered-next-rejected t
                                                 :altered-prefix-payload-suffix-rejected 3)
                           :arity-checker (list :status :ok :single-value-accepted t
                                                :wrong-arity-or-next-rejected 4))
          :campaigns
          (loop for spec in *catalog* for ref = (reference-cell spec)
                collect (list :name (getf ref :name) :major (getf ref :major) :payload-kind (getf ref :kind)
                              :payload-bytes (getf ref :length) :unit-bytes (getf ref :size)
                              :expected-header-bytes (getf ref :header) :expected-full-buffer (getf ref :full)
                              :expected-next (getf ref :next) :expected-token (getf ref :token)
                              :cold-values (list (getf ref :next)) :cold-value-count 1
                              :start 2 :end (getf ref :end) :source-start 3 :source-end (+ 3 (getf ref :length))
                              :source-unchanged t :private-preallocated-buffer-and-source t
                              :complete-output-checked-per-call t
                              :samples (loop repeat 5 collect (synthetic-sample 4096 128 (getf ref :token) 0)))))))

(defun synthetic-wrapper (report)
  "Wrapper representativo; i soli hash non affermano completezza o autenticita."
  (let ((blobs (list (list :path "tools/cbor-string-write-bench.lisp" :git-blob +driver-blob+)
                     (list :path "src/codec/cbor-string-write.lisp" :git-blob +product-blob+))))
    (list :schema-version 1 :kind :command-verification :status :ok :exit-code 0
          :source-consistency :stable :source-blobs-before blobs :source-blobs-after (copy-tree blobs)
          :stdout (serialized report) :stderr ""
          :command '("sbcl" "--script" "tools/cbor-string-write-bench.lisp" "--bench")
          :environment (list :lisp "SBCL" :version "synthetic-version" :machine "synthetic-machine"
                             :os "synthetic-os" :os-version "synthetic-os-version"
                             :commit (make-string 40 :initial-element #\0) :cwd "/synthetic/"
                             :date-universal-time 1000 :external-load-status :uncontrolled)
          :started-at-universal-time 1000 :finished-at-universal-time 1001 :wall-seconds 1d0)))

(defun expected-rejection (reason function)
  "Accetta soltanto il motivo atteso; errori di programmazione non sono rilevamenti."
  (let ((observed nil))
    (handler-case (funcall function)
      (audit-rejection (condition) (setf observed (rejection-reason condition))))
    (require-check (eq observed reason) :self-test-missed-rejection (list :expected reason :observed observed))))

(defun first-cell (report)
  "Accesso ai dati sintetici, senza dipendenze dai builder del benchmark."
  (first (getf report :campaigns)))

(defun (setf first-cell) (value report)
  "Sostituisce la testa della prima plist di :CAMPAIGNS nelle fixture sintetiche."
  (setf (car (getf report :campaigns)) value))

(defun first-sample (report)
  "Accesso al campione sintetico da alterare individualmente."
  (first (getf (first-cell report) :samples)))

(defun (setf first-sample) (value report)
  "Sostituisce la testa della prima plist di :SAMPLES nelle fixture sintetiche."
  (setf (car (getf (first-cell report) :samples)) value))

(defun self-test ()
  "Fixture positive e alterazioni individuali; nessun prodotto o sottoprocesso benchmark."
  (let* ((good (synthetic-report)) (wrapper (synthetic-wrapper good)) (fixtures nil))
    (audit-wrapper wrapper)
    ;; AMBIENTE e raccolto prima di STARTED; un cambio del secondo e lecito.
    (let ((earlier (copy-tree wrapper)))
      (setf (getf (getf earlier :environment) :date-universal-time) 999)
      (audit-wrapper earlier))
    (let ((metadata-overhead (copy-tree wrapper)))
      (setf (getf metadata-overhead :wall-seconds) 5d0)
      (audit-wrapper metadata-overhead))
    ;; Una misura sotto la risoluzione del clock conserva rate NIL, non zero.
    (let ((zero-clock (copy-tree good)))
      (setf (getf (first-sample zero-clock) :raw-ticks) 0
            (getf (first-sample zero-clock) :seconds) 0d0
            (getf (first-sample zero-clock) :calls-per-second) nil)
      (audit-benchmark zero-clock wrapper))
    (labels ((bad-report (name reason mutator)
               (let ((data (copy-tree good)))
                 (funcall mutator data)
                 (expected-rejection reason (lambda () (audit-benchmark data wrapper)))
                 (push (list :name name :reason reason) fixtures)))
             (bad-wrapper (name reason mutator)
               (let ((data (copy-tree wrapper)))
                 (funcall mutator data)
                 (expected-rejection reason (lambda () (audit-wrapper data)))
                 (push (list :name name :reason reason) fixtures))))
      (bad-report :header :fixture-header
                  (lambda (r) (incf (first (getf (first-cell r) :expected-header-bytes)))))
      (dolist (index '(0 3 29))
        (bad-report (list :full-buffer-byte index) :fixture-buffer
                    (lambda (r) (incf (nth index (getf (first-cell r) :expected-full-buffer))))))
      (bad-report :next :fixture-next (lambda (r) (incf (getf (first-cell r) :expected-next))))
      (bad-report :arity-count :fixture-arity (lambda (r) (setf (getf (first-cell r) :cold-value-count) 2)))
      (bad-report :extra-nil :fixture-arity
                  (lambda (r) (setf (getf (first-cell r) :cold-values)
                                   (append (getf (first-cell r) :cold-values) (list nil)))))
      (bad-report :zero-values :fixture-arity (lambda (r) (setf (getf (first-cell r) :cold-values) nil)))
      (bad-report :cold-next :fixture-arity (lambda (r) (incf (first (getf (first-cell r) :cold-values)))))
      (bad-report :fixture-token :fixture-token (lambda (r) (incf (getf (first-cell r) :expected-token))))
      (bad-report :sample-token :sample-token (lambda (r) (incf (getf (first-sample r) :expected-return-token))))
      (bad-report :sink :sample-sink (lambda (r) (incf (getf (first-sample r) :sink))))
      (bad-report :expected-sink :sample-sink (lambda (r) (incf (getf (first-sample r) :expected-sink))))
      (bad-report :heap :sample-heap (lambda (r) (setf (getf (first-sample r) :heap-bytes) 1)))
      (bad-report :negative-heap :sample-heap-shape (lambda (r) (setf (getf (first-sample r) :heap-bytes) -1)))
      (bad-report :sample-count :fixture-sample-count
                  (lambda (r) (pop (getf (first-cell r) :samples))))
      (bad-report :extra-sample :fixture-sample-count
                  (lambda (r) (push (copy-tree (first-sample r)) (getf (first-cell r) :samples))))
      (bad-report :missing-fixture :fixture-catalog (lambda (r) (pop (getf r :campaigns))))
      (bad-report :duplicate-fixture :fixture-catalog
                  (lambda (r) (setf (second (getf r :campaigns)) (copy-tree (first-cell r)))))
      (bad-report :iterations :sample-iterations (lambda (r) (incf (getf (first-sample r) :iterations))))
      (bad-report :warmup :sample-warmup (lambda (r) (incf (getf (first-sample r) :warmup-iterations))))
      (bad-report :seconds :sample-time (lambda (r) (incf (getf (first-sample r) :seconds) 1d0)))
      (bad-report :negative-ticks :sample-ticks (lambda (r) (setf (getf (first-sample r) :raw-ticks) -1)))
      (bad-report :rate :sample-rate (lambda (r) (setf (getf (first-sample r) :calls-per-second) 0)))
      (bad-report :sample-exceeds-wall :sample-wall-time
                  (lambda (r) (setf (getf (first-sample r) :raw-ticks) 2000000
                                   (getf (first-sample r) :seconds) 2d0
                                   (getf (first-sample r) :calls-per-second) 2048d0)))
      (bad-report :span :fixture-span (lambda (r) (incf (getf (first-cell r) :source-start))))
      (bad-report :source-observation :fixture-observation
                  (lambda (r) (setf (getf (first-cell r) :source-unchanged) nil)))
      (bad-report :baseline-counter :baseline-heap
                  (lambda (r) (setf (getf (getf (getf r :self-test) :baseline) :heap-bytes) 1)))
      (bad-report :positive-counter :positive-counter
                  (lambda (r) (setf (getf (getf (getf r :self-test) :positive-control) :heap-bytes) 16777215)))
      (bad-report :checker-counter :checker-self-test
                  (lambda (r) (setf (getf (getf (getf r :self-test) :output-checker)
                                         :altered-prefix-payload-suffix-rejected) 2)))
      (bad-report :arity-counter :arity-self-test
                  (lambda (r) (setf (getf (getf (getf r :self-test) :arity-checker)
                                         :wrong-arity-or-next-rejected) 3)))
      (bad-report :source-changed :fingerprint-stability (lambda (r) (setf (getf r :source-consistency) :changed)))
      (bad-report :fingerprint-drift :fingerprint-stability
                  (lambda (r) (setf (getf (first (getf r :source-fingerprints-after)) :md5)
                                   (make-string 32 :initial-element #\1))))
      (bad-report :frozen-driver-md5 :fingerprint-driver
                  (lambda (r)
                    (dolist (key '(:source-fingerprints-before :source-fingerprints-after))
                      (setf (getf (second (getf r key)) :md5)
                            (make-string 32 :initial-element #\1)))))
      (bad-report :frozen-product-md5 :fingerprint-product
                  (lambda (r)
                    (dolist (key '(:source-fingerprints-before :source-fingerprints-after))
                      (setf (getf (third (getf r key)) :md5)
                            (make-string 32 :initial-element #\1)))))
      (bad-report :benchmark-status :benchmark-status (lambda (r) (setf (getf r :status) :failed)))
      (bad-report :safety :metadata-safety (lambda (r) (setf (getf r :safety) 2)))
      (bad-report :workers :metadata-workers (lambda (r) (setf (getf r :workers) 2)))
      (bad-report :timer :metadata-timer (lambda (r) (setf (getf r :timer-units-per-second) 0)))
      (bad-report :metadata-mismatch :metadata-environment (lambda (r) (setf (getf r :sbcl) "other")))
      (bad-wrapper :exit :wrapper-exit (lambda (r) (setf (getf r :exit-code) 1)))
      (bad-wrapper :status :wrapper-status (lambda (r) (setf (getf r :status) :failed)))
      (bad-wrapper :outer-source-changed :wrapper-source-stability
                   (lambda (r) (setf (getf r :source-consistency) :changed)))
      (bad-wrapper :outer-source-drift :wrapper-source-stability
                   (lambda (r) (setf (getf (first (getf r :source-blobs-after)) :git-blob)
                                    (make-string 40 :initial-element #\1))))
      (bad-wrapper :frozen-driver-blob :wrapper-driver-blob
                   (lambda (r)
                     (dolist (key '(:source-blobs-before :source-blobs-after))
                       (setf (getf (first (getf r key)) :git-blob)
                             (make-string 40 :initial-element #\1)))))
      (bad-wrapper :frozen-product-blob :wrapper-product-blob
                   (lambda (r)
                     (dolist (key '(:source-blobs-before :source-blobs-after))
                       (setf (getf (second (getf r key)) :git-blob)
                             (make-string 40 :initial-element #\1)))))
      (bad-wrapper :command :wrapper-command (lambda (r) (setf (getf r :command) '("sbcl" "--self-test"))))
      (bad-wrapper :wall-time :wrapper-time (lambda (r) (setf (getf r :wall-seconds) -1)))
      (bad-wrapper :environment-too-early :wrapper-time
                   (lambda (r) (setf (getf (getf r :environment) :date-universal-time) 998)))
      (bad-wrapper :duplicate-key :duplicate-key (lambda (r) (setf r (nconc r (list :status :ok)))))
      (expected-rejection :reader-error (lambda () (read-one "#.(list :schema-version 1)")))
      (push (list :name :reader-eval :reason :reader-error) fixtures)
      (expected-rejection :reader-trailing (lambda () (read-one "(:a 1) (:b 2)")))
      (push (list :name :trailing-data :reason :reader-trailing) fixtures)
      (expected-rejection :plist-shape (lambda () (read-one "(:a . 1)")))
      (push (list :name :improper-list :reason :plist-shape) fixtures)
      (expected-rejection :plist-shape (lambda () (read-one "#1=(:a 1 . #1#)")))
      (push (list :name :circular-list :reason :plist-shape) fixtures))
    (list :synthetic-only t :positive-report-accepted t :positive-fixture-count 4
          :environment-before-start-accepted t :wall-includes-metadata-accepted t
          :zero-tick-sample-accepted t
          :negative-fixture-count (length fixtures)
          :negative-fixtures (nreverse fixtures))))

(defun file-observation (path)
  "Osservazione dei byte originali, descriptor incluso; non e prova di atomicita."
  (list :path (namestring (truename path)) :bytes (arcdocdb.evidence:file-bytes path)
        :sha256 (arcdocdb.evidence:file-sha256 path)))

(defun audit-file (path)
  "Legge evidenza plain/gzip verificata, osservando i byte prima e dopo l'audit."
  (let* ((before (file-observation path))
         (wrapper (arcdocdb.evidence:read-evidence path :max-expanded-bytes 67108864))
         (result (audit-wrapper wrapper)) (after (file-observation path)))
    (require-check (equal before after) :evidence-byte-stability)
    (list :wrapper-before before :wrapper-after after :result result
          :wrapper-started-at (getf wrapper :started-at-universal-time)
          :wrapper-finished-at (getf wrapper :finished-at-universal-time))))

(defun main ()
  "Un solo rapporto anche sul rifiuto; exit non nullo, nessuna campagna avviata."
  (let ((report (list :schema-version 1 :kind :cbor-string-write-bench-audit :status :running
                      :recorded-at (get-universal-time) :client-date "2026-10-11"
                      :sbcl (lisp-implementation-version) :driver-blob +driver-blob+
                      :product-blob +product-blob+
                      :limits '(:data-consistency-only :no-product-or-driver-loaded
                                :no-authenticity-or-execution-proof :declared-source-inventory-only
                                :raw-runtime-dates-preserved :no-speed-or-scaling-threshold
                                :local-before-after-byte-observations))))
    (handler-case
        (let ((args (rest sb-ext:*posix-argv*)))
          (setf (getf report :result)
                (cond ((equal args '("--self-test")) (self-test))
                      ((and (= 2 (length args)) (string= "--bench" (first args)))
                       (audit-file (second args)))
                      (t (error 'audit-rejection :reason :usage
                                :detail "Usare --self-test oppure --bench <report-wrapper.lisp>."))))
          (setf (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed
              (getf report :reason) (if (typep condition 'audit-rejection)
                                        (rejection-reason condition) :unexpected-error)
              (getf report :diagnostic) (princ-to-string condition))))
    (setf (getf report :checks) *checks*)
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq :ok (getf report :status)) (sb-ext:exit :code 1))))

(main)
