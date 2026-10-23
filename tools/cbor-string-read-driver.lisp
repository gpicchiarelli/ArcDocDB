;;;; Driver cieco della lettura stringhe CBOR: fixture, confronto e misure locali.
;;;; Uso: --self-test | --diff | --fuzz | --bench | --all; stdout e una sola plist DATA.
;;;; Fixture e denominatori fissati prima del kernel; nessun writer del prodotto.
;;;; OWNER: buffer privati preallocati; prodotto soltanto in lettura durante le chiamate.
;;;; REQ: REQ-CBR-009 REQ-AFF-008 REQ-BEN-001 REQ-BEN-002 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(defpackage #:arcdocdb.cbor-string-read.driver (:use #:cl))
(in-package #:arcdocdb.cbor-string-read.driver)
(declaim (optimize (safety 3) (debug 2)))

(defconstant +iterations+ 1024)
(defconstant +warmup+ 64)
(defconstant +replicas+ 5)
(defconstant +fuzz-cases+ 1024)
(defconstant +seed+ #x43535239)
(defparameter *root* (truename (merge-pathnames "../" (uiop:pathname-directory-pathname *load-truename*))))
(defparameter *reader-function* nil)
(defparameter *fixture-specifications*
  '((:bytes-empty 2 :bytes 0 (64)) (:bytes-23 2 :bytes 23 (87))
    (:bytes-24 2 :bytes 24 (88 24)) (:bytes-256 2 :bytes 256 (89 1 0))
    (:bytes-65536 2 :bytes 65536 (90 0 1 0 0))
    (:text-empty 3 :ascii 0 (96)) (:text-23 3 :ascii 23 (119))
    (:text-24 3 :ascii 24 (120 24)) (:text-256 3 :ascii 256 (121 1 0))
    (:text-65536 3 :ascii 65536 (122 0 1 0 0))
    (:raw-256 2 :raw 256 (89 1 0)) (:unicode-16 3 :unicode 16 (112))))
(defparameter *unicode-octets* '(0 195 169 226 130 172 240 159 153 130 239 187 191 239 191 190))

(defstruct (fixture (:constructor %make-fixture)) name major buffer original start end payload next header-size)

(defun demand (predicate text &rest arguments)
  "Ogni confronto fallito arresta la campagna; nessuna normalizzazione dei risultati."
  (unless predicate (error (apply #'format nil text arguments))))

(defun fingerprints ()
  "Stabilita delle fonti locali; MD5 non e presentato come autenticazione."
  (loop for path in (append (list (merge-pathnames "arcdocdb.asd" *root*)
                                 (merge-pathnames "tools/cbor-string-read-driver.lisp" *root*))
                           (sort (directory (merge-pathnames "src/**/*.lisp" *root*))
                                 #'string< :key #'namestring))
        collect (list :file (enough-namestring path *root*)
                      :md5 (format nil "~(~{~2,'0X~}~)" (coerce (sb-md5:md5sum-file path) 'list)))))

(defun load-product ()
  "Caricamento fuori misura; warning e style-warning sono errori della campagna."
  (setf asdf:*compile-file-failure-behaviour* :error asdf:*compile-file-warnings-behaviour* :error)
  (let ((*standard-output* *error-output*))
    (handler-bind ((warning (lambda (condition) (error condition))))
      (asdf:load-asd (merge-pathnames "arcdocdb.asd" *root*))
      (asdf:load-system "arcdocdb")))
  (let ((symbol (find-symbol "LEGGI-STRINGA-CBOR-MINIMA" "ARCDOCDB.CBOR")))
    (demand (and symbol (fboundp symbol)) "API di lettura stringhe non disponibile.")
    (setf *reader-function* (symbol-function symbol))))

(defun octets (contents)
  (make-array (length contents) :element-type '(unsigned-byte 8) :initial-contents contents))

(defun checksum (buffer)
  "Somma fisica pesata: rilevazione locale, senza pretesa crittografica."
  (let ((sum 0))
    (dotimes (i (length buffer) sum) (incf sum (* (1+ i) (aref buffer i))))))

(defun arithmetic-header (major size)
  "Oracolo base 256 indipendente, limitato alle lunghezze della campagna."
  (demand (and (member major '(2 3)) (<= 0 size 65536)) "Header freddo fuori dominio.")
  (let* ((width (cond ((< size 24) 0) ((< size 256) 1) ((< size 65536) 2) (t 4)))
         (ai (case width (0 size) (1 24) (2 25) (4 26))))
    (cons (+ (* 32 major) ai)
          (loop for power downfrom (1- width) to 0
                collect (mod (floor size (expt 256 power)) 256)))))

(defun payload (kind size &optional (state 0))
  "Byte generati a freddo: raw completo, ASCII oppure sequenza UTF-8 letterale."
  (let ((buffer (make-array size :element-type '(unsigned-byte 8))))
    (dotimes (i size buffer)
      (setf (aref buffer i)
            (ecase kind
              (:bytes 255) (:ascii (if (zerop state) 97 (mod (+ state (* 13 i)) 128)))
              (:raw (mod (+ state i) 256))
              (:unicode (nth (mod i 16) *unicode-octets*)))))))

(defun build-fixture (name major bytes header &optional (start 3))
  "Prefisso e suffisso fisici, quattro byte di coda invalida entro END."
  (demand (equal header (arithmetic-header major (length bytes))) "Header letterale errato: ~S." name)
  (let* ((payload-start (+ start (length header))) (next (+ payload-start (length bytes)))
         (end (+ next 4))
         (buffer (make-array (+ end 3) :element-type '(unsigned-byte 8) :initial-element 165)))
    (replace buffer header :start1 start)
    (replace buffer bytes :start1 payload-start)
    (replace buffer '(255 127 97 192) :start1 next)
    (%make-fixture :name name :major major :buffer buffer :original (copy-seq buffer)
                   :start start :end end :payload payload-start :next next :header-size (length header))))

(defun fixtures ()
  (loop for (name major kind size header) in *fixture-specifications*
        collect (build-fixture name major (payload kind size) header)))

(declaim (notinline receive-values runtime-values))
(defun receive-values (expected-major expected-payload expected-next major payload-start next &rest extra)
  "Consumer esatto: i tre fixnum osservati alimentano il token; anche un quarto NIL e illecito."
  (declare (dynamic-extent extra))
  (unless (and (null extra) (typep major 'fixnum) (typep payload-start 'fixnum) (typep next 'fixnum)
               (= expected-major major) (= expected-payload payload-start) (= expected-next next))
    (error "Arita o tre risultati diversi dall'oracolo: ~S." (list major payload-start next extra)))
  (+ major (* 17 payload-start) (* 31 next)))

(defun runtime-values (values) (values-list values))

(defun checked-call (fixture)
  "Controllo di tutti i valori a ogni invocazione, senza costruire una lista sul successo."
  (multiple-value-call #'receive-values
    (values (fixture-major fixture) (fixture-payload fixture) (fixture-next fixture))
    (funcall *reader-function* (fixture-buffer fixture) (fixture-start fixture) (fixture-end fixture))))

(defun expected-token (fixture)
  (+ (fixture-major fixture) (* 17 (fixture-payload fixture)) (* 31 (fixture-next fixture))))

(defun unchanged (fixture)
  (demand (equalp (fixture-original fixture) (fixture-buffer fixture))
          "Buffer fisico mutato: ~S." (fixture-name fixture))
  t)

(defun fixture-data (fixture)
  (list :name (fixture-name fixture) :major (fixture-major fixture)
        :start (fixture-start fixture) :end (fixture-end fixture)
        :expected-values (list (fixture-major fixture) (fixture-payload fixture) (fixture-next fixture))
        :header-bytes (fixture-header-size fixture)
        :payload-bytes (- (fixture-next fixture) (fixture-payload fixture))
        :item-bytes (- (fixture-next fixture) (fixture-start fixture))
        :authorized-window-bytes (- (fixture-end fixture) (fixture-start fixture))
        :expected-token (expected-token fixture)))

(defun rejected-call (name buffer start end class reason offset &key (max-bytes 16777216))
  "Un solo errore atteso, con classe/motivo/offset e immutabilita dell'intero input."
  (let* ((before (copy-seq buffer))
         (condition (handler-case
                        (progn (funcall *reader-function* buffer start end :max-bytes max-bytes) nil)
                      (error (caught) caught)))
         (expected-class (find-symbol (symbol-name class) "ARCDOCDB.CONDITIONS")))
    (demand (equalp before buffer) "Input mutato sul rifiuto ~S." name)
    (demand (and condition expected-class (typep condition expected-class))
            "Classe di rifiuto inattesa ~S: ~A." name condition)
    (let ((actual-reason (funcall (symbol-function (find-symbol "ERROR-REASON" "ARCDOCDB.CONDITIONS")) condition))
          (actual-offset (funcall (symbol-function (find-symbol "ERROR-OFFSET" "ARCDOCDB.CONDITIONS")) condition)))
      (demand (and (eq reason actual-reason) (eql offset actual-offset))
              "Motivo/offset inattesi ~S: ~S/~S." name actual-reason actual-offset)
      (list :name name :class class :reason actual-reason :offset actual-offset :input-unchanged t))))

(defparameter *rejection-specifications*
  '((:empty-window () :corruption-detected :cbor-truncated 2)
    (:integer (0) :corruption-detected :cbor-string-type 2)
    (:array (128) :corruption-detected :cbor-string-type 2)
    (:tag (192) :corruption-detected :cbor-string-type 2)
    (:simple (246) :corruption-detected :cbor-string-type 2)
    (:reserved-wrong-major (156) :corruption-detected :cbor-reserved 2)
    (:nonminimal-wrong-major (152 0) :corruption-detected :cbor-nonminimal 2)
    (:indefinite (95) :corruption-detected :cbor-nonminimal 2)
    (:break (255) :corruption-detected :cbor-nonminimal 2)
    (:header-cut (89 1) :corruption-detected :cbor-truncated 4)
    (:high-length (91 0 0 0 1 0 0 0 0) :corruption-detected :cbor-truncated 11)
    (:bytes-cut (66 255) :corruption-detected :cbor-truncated 4)
    (:text-cut-before-utf8 (98 255) :corruption-detected :cbor-truncated 4)
    (:utf8-leading (97 255) :corruption-detected :utf8-leading 3)
    (:utf8-continuation (98 194 32) :corruption-detected :utf8-continuation 4)
    (:utf8-scalar (99 237 160 128) :corruption-detected :utf8-scalar 4)
    (:utf8-cut (97 194) :corruption-detected :utf8-truncated 4)
    (:budget-tail (64 255) :resource-exhausted :cbor-byte-budget nil :max-bytes 1)
    (:budget-nil-before-syntax (156) :invalid-argument :cbor-byte-limit nil :max-bytes nil)
    (:budget-too-large (64) :invalid-argument :cbor-byte-limit nil :max-bytes 16777217)
    (:budget-negative (64) :invalid-argument :cbor-byte-limit nil :max-bytes -1)
    (:range-before-budget (64) :invalid-argument :cbor-range nil :start -1 :max-bytes nil)
    (:buffer-type (64) :invalid-argument :cbor-range nil :list-buffer t)
    (:range-end (64) :invalid-argument :cbor-range nil :end-extra 1 :max-bytes 0)))

(defun differential ()
  "Dodici successi e ventiquattro rifiuti; nessun altro codec e usato come riferimento."
  (let ((successes nil) (rejections nil))
    (dolist (fixture (fixtures))
      (let ((before (checksum (fixture-buffer fixture))) (token (checked-call fixture)))
        (unchanged fixture)
        (push (append (fixture-data fixture)
                      (list :observed-token token :buffer-checksum-before before
                            :buffer-checksum-after (checksum (fixture-buffer fixture)) :input-unchanged t)) successes)))
    (dolist (spec *rejection-specifications*)
      (destructuring-bind (name bytes class reason offset &rest options) spec
        (let* ((buffer (octets (append '(165 165) bytes)))
               (input (if (getf options :list-buffer) (coerce buffer 'list) buffer)))
          (push (rejected-call name input (getf options :start 2)
                               (+ (length buffer) (getf options :end-extra 0)) class reason offset
                               :max-bytes (getf options :max-bytes 16777216)) rejections))))
    (demand (and (= 12 (length successes)) (= 24 (length rejections))) "Denominatore diff diverso.")
    (list :status :ok :declared-product-calls 36 :declared-successes 12 :declared-rejections 24
          :successes (nreverse successes) :rejections (nreverse rejections))))

(defun next-state (state) (mod (+ (* 1664525 state) 1013904223) 4294967296))

(defun fuzz-negative (index fixture)
  "Otto famiglie fissate, ciascuna 128 volte: tail-budget, span, tipo e precedenze."
  (let ((start (fixture-start fixture)) (buffer (copy-seq (fixture-buffer fixture))))
    (case (mod index 8)
      (0 (rejected-call :tail-budget buffer start (fixture-end fixture)
                        :resource-exhausted :cbor-byte-budget nil
                        :max-bytes (1- (- (fixture-end fixture) start))))
      (1 (rejected-call :payload-cut buffer start (1- (fixture-next fixture))
                        :corruption-detected :cbor-truncated (1- (fixture-next fixture))))
      (2 (setf (aref buffer start) (+ 128 (mod (aref buffer start) 32)))
         (rejected-call :wrong-major buffer start (fixture-end fixture)
                        :corruption-detected :cbor-string-type start))
      (otherwise
       (destructuring-bind (name bytes reason relative-offset)
           (nth (- (mod index 8) 3)
                '((:nonminimal-wrong-major (152 0) :cbor-nonminimal 0)
                  (:utf8-leading (97 255) :utf8-leading 1)
                  (:payload-cut-before-utf8 (98 255) :cbor-truncated 2)
                  (:header-cut-wrong-major (153 1) :cbor-truncated 2)
                  (:reserved-wrong-major (156) :cbor-reserved 0)))
         (let ((input (make-array (+ start (length bytes) 3) :element-type '(unsigned-byte 8)
                                 :initial-element 165)))
           (replace input bytes :start1 start)
           (rejected-call name input start (+ start (length bytes)) :corruption-detected reason
                          (+ start relative-offset))))))))

(defun fuzz ()
  "1024 coppie determinate dal seed, con header aritmetico e payload costruito a freddo."
  (let ((state +seed+) (observed 0) (expected 0) (item-bytes 0) (kinds (make-array 8 :initial-element 0)))
    (dotimes (i +fuzz-cases+)
      (setf state (next-state state))
      (let* ((major (+ 2 (ldb (byte 1 7) state)))
             (kind (if (= major 2) :raw (if (zerop (mod i 4)) :unicode :ascii)))
             (size (if (eq kind :unicode) (* 16 (1+ (mod state 16))) (1+ (mod state 257))))
             (start (1+ (mod (floor state 256) 7)))
             (fixture (build-fixture i major (payload kind size state) (arithmetic-header major size) start))
             (before (checksum (fixture-buffer fixture))))
        (incf observed (checked-call fixture))
        (incf expected (expected-token fixture))
        (incf item-bytes (- (fixture-next fixture) start))
        (unchanged fixture)
        (demand (= before (checksum (fixture-buffer fixture))) "Checksum fuzz differente al caso ~D." i)
        (fuzz-negative i fixture)
        (incf (aref kinds (mod i 8)))))
    (demand (= observed expected) "Sink fuzz inatteso.")
    (list :status :ok :seed +seed+ :final-state state :iterations +fuzz-cases+
          :declared-product-calls 2048 :declared-successes 1024 :declared-rejections 1024
          :successful-item-bytes item-bytes :negative-family-counts (coerce kinds 'list)
          :observed-token-sum observed :expected-token-sum expected :physical-input-checks 2048
          :oracle :arithmetic-known-header-and-payload :invalid-tail-ignored-on-all-successes t)))

(defun sample (function count token &optional (warmup +warmup+))
  "Warmup/GC esclusi; clock e heap locali includono consumer dei tre valori."
  (demand (and (<= 1 count +iterations+) (<= 0 warmup +warmup+)) "Campione fuori budget.")
  (dotimes (i warmup) (funcall function))
  (sb-ext:gc :full t)
  (let ((ticks-before (get-internal-real-time)) (heap-before (sb-ext:get-bytes-consed)) (sink 0))
    (declare (type fixnum sink))
    (dotimes (i count) (setf sink (logand most-positive-fixnum (+ sink i (the fixnum (funcall function))))))
    (let* ((heap (- (sb-ext:get-bytes-consed) heap-before))
           (ticks (- (get-internal-real-time) ticks-before))
           (expected (logand most-positive-fixnum (+ (* count token) (/ (* count (1- count)) 2)))))
      (demand (and (<= 0 heap) (<= 0 ticks) (= sink expected)) "Sensore/sink benchmark incoerente.")
      (list :iterations count :warmup-iterations warmup :heap-bytes heap :raw-ticks ticks
            :seconds (/ ticks (float internal-time-units-per-second 1d0))
            :sink sink :expected-sink expected :expected-return-token token))))

(defun expect-rejection (function)
  (let ((caught nil))
    (handler-case (funcall function) (error () (setf caught t)))
    (demand caught "Consumer accetta output sintetico alterato.")))

(defun self-test ()
  "Sensore nullo/positivo e consumer su arita variabile ottenuta solo a runtime."
  (let ((baseline (sample (lambda () 0) +iterations+ 0)) (probe nil))
    (demand (zerop (getf baseline :heap-bytes)) "Baseline del sensore non nulla.")
    (let ((positive (sample (lambda ()
                              (setf probe (make-array 1048576 :element-type '(unsigned-byte 8) :initial-element 0))
                              (length probe)) 16 1048576 0)))
      (demand (and (= 1048576 (length probe)) (>= (getf positive :heap-bytes) 16777216))
              "Allocazioni deliberate non rilevate.")
      (demand (= 194 (multiple-value-call #'receive-values (values 2 4 4) (runtime-values '(2 4 4))))
              "Consumer positivo errato.")
      (dolist (values '(nil (2 4) (2 4 4 nil) (2 4 4 9) (3 4 4) (2 5 4) (2 4 5) (2 4 4.0d0)))
        (expect-rejection (lambda ()
                            (multiple-value-call #'receive-values (values 2 4 4) (runtime-values values)))))
      (let* ((fixture (first (fixtures))) (index (1- (length (fixture-buffer fixture)))))
        (setf (aref (fixture-buffer fixture) index) 0)
        (expect-rejection (lambda () (unchanged fixture))))
      (list :status :ok :declared-product-calls 0 :baseline baseline :positive-control positive
            :exact-three-fixnum-values-accepted t :altered-or-wrong-arity-rejected 8
            :physical-suffix-mutation-rejected t))))

(defun benchmark ()
  "60 campioni; nessuna soglia di velocita o inferenza sul throughput del motore."
  (let ((rows nil) (all-item-bytes 0) (all-window-bytes 0))
    (dolist (fixture (fixtures))
      (let ((cold (checked-call fixture)) (samples nil))
        (unchanged fixture)
        (dotimes (replica +replicas+)
          (let* ((before (checksum (fixture-buffer fixture)))
                 (measurement (sample (lambda () (checked-call fixture)) +iterations+ (expected-token fixture))))
            (unchanged fixture)
            (demand (zerop (getf measurement :heap-bytes)) "Heap non nullo: ~S." (fixture-name fixture))
            (push (append (list :replica replica :declared-product-calls +iterations+
                                :declared-nodes +iterations+
                                :declared-item-bytes (* +iterations+ (- (fixture-next fixture) (fixture-start fixture)))
                                :buffer-checksum-before before
                                :buffer-checksum-after (checksum (fixture-buffer fixture)) :input-unchanged t)
                          measurement) samples)))
        (incf all-item-bytes (- (fixture-next fixture) (fixture-start fixture)))
        (incf all-window-bytes (- (fixture-end fixture) (fixture-start fixture)))
        (push (append (fixture-data fixture) (list :cold-token cold :samples (nreverse samples))) rows)))
    (demand (and (= 12 (length rows)) (= all-item-bytes 131978) (= all-window-bytes 132026))
            "Denominatore byte/fixture benchmark diverso.")
    (list :status :ok :fixture-count 12 :replicas 5 :samples 60 :iterations 1024 :warmup-iterations 64
          :declared-timed-product-calls 61440 :declared-warmup-product-calls 3840 :declared-cold-product-calls 12
          :declared-total-product-calls 65292 :declared-timed-nodes 61440
          :declared-timed-item-bytes 675727360 :declared-timed-authorized-window-bytes 675973120
          :bytes-are-item-denominators-not-a-claim-of-bytes-read t :campaigns (nreverse rows))))

(defun main ()
  "Una sola forma DATA anche su errore; output di caricamento separato su stderr."
  (let* ((args (rest sb-ext:*posix-argv*)) (before (fingerprints))
         (report (list :schema-version 1 :kind :cbor-string-read-driver :status :running
                       :mode args :recorded-at (get-universal-time) :phase :arguments
                       :source-fingerprints-before before :sbcl (lisp-implementation-version)
                       :workers 1 :safety 3 :timer-units-per-second internal-time-units-per-second
                       :limits '(:blind-fixtures-no-product-writer :serial-measurements
                                 :readonly-private-inputs :counter-not-absolute-nonallocation-proof
                                 :consumer-cost-included :checksums-outside-timing
                                 :no-speed-or-scaling-threshold :no-complete-cbor-profile))))
    (handler-case
        (progn
          (demand (member args '(("--self-test") ("--diff") ("--fuzz") ("--bench") ("--all")) :test #'equal)
                  "Usare --self-test, --diff, --fuzz, --bench oppure --all.")
          (setf (getf report :phase) :sensor-self-test (getf report :self-test) (self-test))
          (unless (equal args '("--self-test"))
            (setf (getf report :phase) :load-product)
            (load-product)
            (when (member (first args) '("--diff" "--all") :test #'string=)
              (setf (getf report :phase) :differential (getf report :differential) (differential)))
            (when (member (first args) '("--fuzz" "--all") :test #'string=)
              (setf (getf report :phase) :fuzz (getf report :fuzz) (fuzz)))
            (when (member (first args) '("--bench" "--all") :test #'string=)
              (setf (getf report :phase) :benchmark (getf report :benchmark) (benchmark))))
          (setf (getf report :phase) :complete (getf report :status) :ok))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))))
    (let ((after (fingerprints)))
      (setf (getf report :source-fingerprints-after) after
            (getf report :source-consistency) (if (equal before after) :stable :changed))
      (when (and (eq (getf report :status) :ok) (not (equal before after)))
        (setf (getf report :status) :source-changed)))
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(main)
