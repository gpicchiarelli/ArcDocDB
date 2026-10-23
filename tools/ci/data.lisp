;;;; C4: wire limitato, dati inerti e trasporto argv senza shell.
;;; REQ: REQ-VAL-001 REQ-AFF-012
;;; Il coordinator crea ARCDOCDB.CI (:USE CL) e carica ASDF/SB-POSIX.
(in-package #:arcdocdb.ci)
(declaim (optimize (safety 3) (debug 3)))

(defvar *ci-root*
  (uiop:ensure-directory-pathname
   (truename (merge-pathnames "../../" (uiop:pathname-directory-pathname *load-truename*)))))
(defparameter *ci-wire-max-bytes* 1048576)
(defparameter *ci-wire-max-depth* 32)
(defparameter *ci-wire-max-elements* 100000)
(defparameter *ci-wire-max-string* 65536)
(defparameter *ci-wire-max-token* 128)
(defparameter *ci-command-max-bytes* 67108864)
(defparameter *ci-command-timeout-seconds* 120)
(defconstant +ci-integer-min+ (- (expt 2 127)))
(defconstant +ci-integer-max+ (1- (expt 2 127)))

;; Vocabolario canonico finito, letto soltanto da questo sorgente trusted.
;; Include i report dei figli/checker: il publisher NON carica prodotto o test.
;; Il parser usa sempre FIND-SYMBOL; chiavi/forme di ogni record devono inoltre
;; passare CI-PLIST-CHECK e il validatore del relativo schema. Non è un INTERN
;; dei token ricevuti e non ammette estensioni del protocollo da un payload.
(defparameter *ci-wire-canonical-keywords*
  '(:schema-version :kind :status :reason :diagnostic :limits :id :name :path
    :mode :blob :bytes :sha256 :encoding :plain :gzip :codec :compressed-evidence
    :uncompressed-bytes :uncompressed-sha256 :compressed-bytes :compressed-sha256
    :expanded-bytes :expanded-sha256 :files :sources :source-files :source-bytes
    :lisp-files :physical-lines :modules :tested-sha :source-id :policy-id
    :head-sha :base-sha :publisher-sha :publication-parent :source-attribution
    :source-before :source-after :source-changed :source-commit :source-contract
    :source-tag :source-tag-object :source-tag-type :source :identity :context
    :github-run-commit-v1 :github-pr-merge-source-v1 :run-head-sha :github-merge-sha
    :pull-request :github-verified :ci-publication-self-test
    :run-id :attempt :run-attempt :job-id :job :jobs :profile :event :ref
    :repository :url :workflow :workflow-id :run :producer :publisher
    :os :architecture :image :cpu :lisp-version :version :runner :machine
    :planned :known-planned :started :passed :failed :not-run :not-started :skipped
    :running :ready :missing :pending :unknown :unsupported :not-implemented
    :measured :partial :complete :ok :budget-exhausted :timeout :runner-stopped
    :condition :duration-ticks :duration-unit :internal-time-ticks :ticks-per-second
    :tests :suites :suite :test :events :sequence :tick :detail :data :inventory
    :suite-started :suite-passed :suite-failed :test-error :cases :checks :counts
    :ci-tests :ci-test-plan :ci-test-inventory :ci-test-self-test :ci-data-self-test
    :ci-check :ci-audit :ci-job-result :ci-packet :ci-collection :ci-workflow-self-test
    :ci-coverage :ci-coverage-plan :ci-coverage-worker :ci-measure :ci-measure-replica
    :ci-measure-worker :ci-measure-self-test :ci-toolchain-lock :ci-self-test
    :adapter :registry :package :explicit :smoke :symbol-list :alist
    :excluded-tests :coverage-allocation-exclusion :cases-not-loaded
    :scope :expected-files :known-files :totals :known-subtotal :expected :observed
    :expected-jobs :collections :collection-closed :metrics-complete :verification-passed
    :packets :payload :record :result :report :report-path :command :exit-code
    :raw-file :normal-report :normal-report-sha256 :normal-status :normal-reason
    :tests-status :normal-verification-same-sha-required :input-unchanged
    ;; Il child coverage legge il risultato verify senza caricare il producer.
    :metrics :metrics-status :execution :unit :value :method :samples :statistics :numerator :denominator
    :lines-covered :lines-total :branches-covered :branches-total
    :expressions-covered :expressions-total :lcov :lcov-sha256 :lcov-dialect
    :lcov-da-exact-counts :lcov-ba-exact-counts :lcov-branches-covered :lcov-branches-total
    :sbcl-da-ba :sbcl-2 :not-instrumented :unknown-denominator
    :coverage-reset-after-load :uninstrumented-children :partial-child-process-coverage
    :instrumentation-changes-allocation :not-c1-qualification :not-mcdc
    :replica :replicas :replicas-planned :replicas-started :replicas-completed
    :iterations :operations :total-operations :bytes-per-operation :total-bytes
    :warmup :warmup-operations :wall-ticks :cpu-ticks :elapsed-ticks :total-wall-ticks
    :wall-ticks-min :wall-ticks-max :wall-ticks-median :operations-per-second :bytes-per-second
    :bytes-consed :owned-buffer-bytes :max-owned-buffer-bytes :measurement-window
    :budget-seconds :worker-budget-seconds :dynamic-space-mib :fresh-processes
    :product-calls-and-harness :product-kernel :product-source-files :sample-protocol
    :gc-count :gc-count-status :gc-count-reason :gc-counter-source
    :gc-cpu-ticks :gc-cpu-reason :gc-wall-ticks :gc-wall-reason
    :crc32c-check-vector :crc32c-4096 :crc32c-empty :utf8-mixed-4090 :utf8-known-count
    :rss :fsync-latency :p99-latency :p999-latency :engine-throughput :engine-compaction
    :time-unit :nanoseconds :tick :ticks :exploratory :performance-gate
    :github-hosted-exploratory-performance :child-failed :counter-unavailable
    :partial-observations-retained :zero-denominator :zero-time-rate-absent
    :rate-reason :clock-backwards :clock-scale-zero :counter-reset
    :lint :trace :links :check :self-test :violations :token-violations :by-rule :rule
    :requirements :errors :invariants :invariants-covered :fi-scenarios :fi-covered
    :adrs :matrix-current :matrix-written :requirements-with-verification
    :requirements-without-verification :by-class :class :by-status :by-verification-method
    :specificato :progettato :implementato :verificato :code-references :directory
    :references :unique-requirements :unknown-references :missing-implementation-references
    :missing-test-references :checked :broken :missing-files :missing-anchors
    :markdown-targets :html-targets :prop :diff :model :fi :fuzz :corr :mut :soak :bench :rev :analisi
    :invariant-references :unknown-invariant-references :adr-references :unknown-adr-references
    :fi-references :unknown-fi-references :invalid-classes :invalid-statuses
    :platforms :arch :sbcl-version :distribution :recipe-id :recipe-path :digest
    :digest-method :observed-date :upstream :source-commit :bootstrap :bootstrap-sha256
    :compiler-origin :compiler-version :compiler-provenance-sha256 :build-instructions
    :installed-output-policy :installed-output-sha256 :record-at-installation
    :sha256-of-downloaded-bytes :runner-apple-clang :runner-os :platform-table
    :recorded-at :action :actions :commit :api-ref :ref-type :tag
    :fixture-data-only :raw-not-evaluated :private-git-fixture :not-run-at-load
    :no-runtime-product-measurement))

(define-condition ci-data-error (error)
  ((detail :initarg :detail :reader ci-data-error-detail))
  (:report (lambda (condition stream)
             (write-string (ci-data-error-detail condition) stream))))

(defun %ci-fail (control &rest arguments)
  (error 'ci-data-error :detail (apply #'format nil control arguments)))

(defun %ci-limit (value name)
  (unless (and (integerp value) (<= 0 value) (< value array-dimension-limit))
    (%ci-fail "Limite ~A non valido." name))
  value)

(defun %ci-utf8 (text)
  (sb-ext:string-to-octets text :external-format :utf-8))

(defun %ci-utf8-text (octets)
  ;; Il round trip esclude sostituzioni silenziose di sequenze UTF-8 invalide.
  (let ((text (sb-ext:octets-to-string octets :external-format :utf-8)))
    (unless (equalp octets (%ci-utf8 text)) (%ci-fail "UTF-8 non canonico."))
    text))

(defun %ci-utf8-width (character)
  (let ((code (char-code character)))
    (cond ((< code #x80) 1) ((< code #x800) 2)
          ((<= #xd800 code #xdfff) (%ci-fail "Surrogato Unicode vietato."))
          ((< code #x10000) 3) ((<= code #x10ffff) 4)
          (t (%ci-fail "Carattere fuori Unicode.")))))

(defun %ci-space-p (character)
  (and character (find (char-code character) '(9 10 12 13 32))))

(defun %ci-key-character-p (character)
  (or (char<= #\A character #\Z) (char<= #\a character #\z)
      (char<= #\0 character #\9) (find character "-_")))

(defun %ci-list-length (data)
  ;; LIST-LENGTH riconosce i cicli; il TYPE-ERROR per una coda dotted è rifiuto.
  (let ((size (handler-case (list-length data) (type-error () nil))))
    (unless (and size (<= size *ci-wire-max-elements*))
      (%ci-fail "Lista impropria, ciclica o oltre il limite elementi."))
    size))

(defun ci-plist-check (data allowed required)
  "Valida forma, chiavi uniche, insieme ammesso e campi presenti; ritorna DATA."
  (unless (evenp (%ci-list-length data)) (%ci-fail "Plist di lunghezza dispari."))
  (%ci-list-length allowed)
  (%ci-list-length required)
  (unless (and (every #'keywordp allowed) (every #'keywordp required)
               (subsetp required allowed :test #'eq))
    (%ci-fail "Schema plist non valido."))
  (let ((seen (make-hash-table :test #'eq)))
    (loop for tail on data by #'cddr for key = (first tail)
          do (unless (and (keywordp key) (member key allowed :test #'eq))
               (%ci-fail "Chiave plist non ammessa: ~S." key))
             (when (gethash key seen) (%ci-fail "Chiave plist duplicata: ~S." key))
             (setf (gethash key seen) t))
    (dolist (key required)
      (unless (gethash key seen) (%ci-fail "Campo obbligatorio assente: ~S." key))))
  data)

(defun %ci-parse-wire (text &key (max-bytes *ci-wire-max-bytes*))
  "Grammatica dedicata: nessuna chiamata al reader Lisp, INTERN o EVAL."
  (%ci-limit max-bytes :bytes)
  (%ci-limit *ci-wire-max-depth* :depth)
  (%ci-limit *ci-wire-max-elements* :elements)
  (%ci-limit *ci-wire-max-string* :string)
  (%ci-limit *ci-wire-max-token* :token)
  (unless (stringp text) (%ci-fail "Wire testuale richiesto."))
  (let ((bytes 0) (position 0) (size (length text)) (elements 0))
    (loop for character across text
          do (incf bytes (%ci-utf8-width character))
             (when (> bytes max-bytes) (%ci-fail "Wire oltre il limite byte.")))
    (labels ((peek () (when (< position size) (char text position)))
             (take () (or (prog1 (peek) (incf position))
                          (%ci-fail "EOF inatteso nel wire.")))
             (spaces () (loop while (%ci-space-p (peek)) do (incf position)))
             (delimiter-p (character)
               (or (null character) (%ci-space-p character)
                   (find character "()\"")))
             (string-value ()
               (take)
               (let ((output (make-array 0 :element-type 'character
                                         :adjustable t :fill-pointer 0))
                     (count 0))
                 (loop for character = (take)
                       do (when (char= character #\") (return (coerce output 'string)))
                          (when (char= character #\\)
                            (setf character (take))
                            (unless (find character "\\\"")
                              (%ci-fail "Escape stringa non ammesso.")))
                          (incf count (%ci-utf8-width character))
                          (when (> count *ci-wire-max-string*)
                            (%ci-fail "Stringa oltre il limite byte."))
                          (vector-push-extend character output))))
             (token-value ()
               (let ((start position))
                 (loop until (delimiter-p (peek))
                       do (incf position)
                          (when (> (- position start) *ci-wire-max-token*)
                            (%ci-fail "Token oltre il limite.")))
                 (when (= start position) (%ci-fail "Token vuoto."))
                 (let ((token (subseq text start position)))
                   (cond
                     ((string-equal token "NIL") nil)
                     ((string-equal token "T") t)
                     ((char= (char token 0) #\:)
                      (unless (and (> (length token) 1)
                                   (every #'%ci-key-character-p (subseq token 1)))
                        (%ci-fail "Keyword semplice richiesta."))
                      (multiple-value-bind (symbol status)
                          (find-symbol (string-upcase (subseq token 1)) "KEYWORD")
                        (unless (and status (keywordp symbol))
                          (%ci-fail "Keyword sconosciuta; nessun INTERN di input."))
                        symbol))
                     (t
                      (let* ((negative (char= (char token 0) #\-))
                             (first (if negative 1 0)) (value 0)
                             (limit (if negative (- +ci-integer-min+) +ci-integer-max+)))
                        (unless (< first (length token)) (%ci-fail "Intero vuoto."))
                        (loop for index from first below (length token)
                              for character = (char token index)
                              do (unless (char<= #\0 character #\9)
                                   (%ci-fail "Token vietato: solo NIL/T, keyword o decimale."))
                                 (setf value (+ (* value 10) (- (char-code character) 48)))
                                 (when (> value limit) (%ci-fail "Intero fuori signed-128.")))
                        (if negative (- value) value)))))))
             (value (depth)
               (when (> depth *ci-wire-max-depth*) (%ci-fail "Wire troppo profondo."))
               (when (> (incf elements) *ci-wire-max-elements*)
                 (%ci-fail "Wire oltre il limite elementi."))
               (spaces)
               (let ((character (peek)))
                 (cond
                   ((null character) (%ci-fail "EOF prima del valore."))
                   ((char= character #\()
                    (take) (spaces)
                    (let ((items nil))
                      (loop
                        (when (eql (peek) #\)) (take) (return (nreverse items)))
                        (push (value (1+ depth)) items)
                        (unless (or (null (peek)) (%ci-space-p (peek)) (eql (peek) #\)))
                          (%ci-fail "Separatore lista richiesto."))
                        (spaces))))
                   ((char= character #\") (string-value))
                   ((char= character #\)) (%ci-fail "Parentesi inattesa."))
                   (t (token-value))))))
      (let ((data (value 0)))
        (spaces)
        (unless (= position size) (%ci-fail "Dati dopo il valore wire; EOF richiesto."))
        data))))

(defun ci-wire-string (data)
  "Writer canonico indipendente da *PRINT-ARRAY* e dalle impostazioni reader."
  (let ((output (make-array 0 :element-type 'character :adjustable t :fill-pointer 0))
        (bytes 0) (elements 0) (active (make-hash-table :test #'eq)))
    (labels ((emit (character)
               (incf bytes (%ci-utf8-width character))
               (when (> bytes *ci-wire-max-bytes*) (%ci-fail "Wire oltre il limite byte."))
               (vector-push-extend character output))
             (text (string) (loop for character across string do (emit character)))
             (value (item depth)
               (when (> depth *ci-wire-max-depth*) (%ci-fail "Wire troppo profondo."))
               (when (> (incf elements) *ci-wire-max-elements*)
                 (%ci-fail "Wire oltre il limite elementi."))
               (cond
                 ((null item) (text "NIL"))
                 ((eq item t) (text "T"))
                 ((stringp item)
                  (when (> (length item) *ci-wire-max-string*)
                    (%ci-fail "Stringa oltre il limite."))
                  (emit #\")
                  (let ((count 0))
                    (loop for character across item
                          do (incf count (%ci-utf8-width character))
                             (when (> count *ci-wire-max-string*)
                               (%ci-fail "Stringa oltre il limite byte."))
                             (when (find character "\\\"") (emit #\\))
                             (emit character)))
                  (emit #\"))
                 ((keywordp item)
                  (let ((name (symbol-name item)))
                    (unless (and (plusp (length name))
                                 (<= (1+ (length name)) *ci-wire-max-token*)
                                 (string= name (string-upcase name))
                                 (every #'%ci-key-character-p name)
                                 (eq item (find-symbol name "KEYWORD")))
                      (%ci-fail "Keyword non rappresentabile nel wire."))
                    (emit #\:) (text name)))
                 ((integerp item)
                  (unless (<= +ci-integer-min+ item +ci-integer-max+)
                    (%ci-fail "Intero fuori signed-128."))
                  (let ((digits (format nil "~D" item)))
                    (when (> (length digits) *ci-wire-max-token*)
                      (%ci-fail "Intero oltre il limite token."))
                    (text digits)))
                 ((consp item)
                  (%ci-list-length item)
                  (when (gethash item active) (%ci-fail "Struttura wire ciclica."))
                  (setf (gethash item active) t)
                  (unwind-protect
                       (progn
                         (emit #\()
                         (loop for tail on item
                               do (unless (eq tail item) (emit #\Space))
                                  (value (car tail) (1+ depth)))
                         (emit #\)))
                    (remhash item active)))
                 (t (%ci-fail "Tipo non ammesso nel wire.")))))
      (value data 0)
      (coerce output 'string))))

(defun ci-relative-path (path)
  "Valida un path di payload semplice, relativo e profondo al massimo 16."
  (unless (and (stringp path) (<= 1 (length path) 4096)
               (<= (length (%ci-utf8 path)) 4096)
               (not (find-if (lambda (character)
                               (or (< (char-code character) 32)
                                   (= (char-code character) 127)
                                   (find character "\\:*?[]"))) path)))
    (%ci-fail "Path relativo non ammesso."))
  (let ((parts (uiop:split-string path :separator "/")))
    (unless (and (<= (length parts) 16)
                 (every (lambda (part) (and (plusp (length part))
                                            (not (member part '("." "..") :test #'equal))))
                        parts))
      (%ci-fail "Path assoluto, vuoto, troppo profondo o con escape.")))
  path)

(defun %ci-absolute-file (path)
  ;; Non usa TRUENAME: nessuna risoluzione implicita di un symlink ricevuto.
  (let* ((pathname (pathname path))
         (absolute (merge-pathnames pathname (uiop:getcwd))))
    (unless (and (not (wild-pathname-p absolute))
                 (eq :absolute (first (pathname-directory absolute)))
                 (notany (lambda (part) (member part '(:up :back :wild :wild-inferiors)))
                         (pathname-directory absolute))
                 (pathname-name absolute))
      (%ci-fail "Path file assoluto concreto richiesto."))
    (namestring absolute)))

(defun %ci-check-parents (absolute)
  (loop for index from 1 below (length absolute)
        when (char= (char absolute index) #\/)
          do (unless (sb-posix:s-isdir
                      (sb-posix:stat-mode (sb-posix:lstat (subseq absolute 0 index))))
               (%ci-fail "Directory non regolare o symlink nel path.")))
  absolute)

(defun %ci-regular-stat (path)
  (let* ((absolute (%ci-check-parents (%ci-absolute-file path)))
         (stat (sb-posix:lstat absolute)))
    (unless (and (sb-posix:s-isreg (sb-posix:stat-mode stat))
                 (= 1 (sb-posix:stat-nlink stat)))
      (%ci-fail "File regolare senza symlink/link fisici richiesto: ~A." absolute))
    (values stat absolute)))

(defun ci-regular-file-p (path)
  (handler-case (progn (%ci-regular-stat path) t) (error () nil)))

(defun %ci-call-file (path function &key output replace)
  ;; NOFOLLOW protegge il leaf; LSTAT/FSTAT verificano identità e link count.
  ;; Le directory devono appartenere al job, senza writer ostili concorrenti.
  (let* ((absolute (%ci-check-parents (%ci-absolute-file path)))
         (before (unless output (nth-value 0 (%ci-regular-stat absolute))))
         (flags (logior sb-posix:o-nofollow sb-posix:o-nonblock
                        (if output (logior sb-posix:o-wronly sb-posix:o-creat
                                           (if replace 0 sb-posix:o-excl))
                            sb-posix:o-rdonly)))
         (fd (sb-posix:open absolute flags #o600)))
    (unwind-protect
         (let ((stat (sb-posix:fstat fd)))
           (unless (and (sb-posix:s-isreg (sb-posix:stat-mode stat))
                        (= 1 (sb-posix:stat-nlink stat))
                        (or (null before)
                            (and (= (sb-posix:stat-dev before) (sb-posix:stat-dev stat))
                                 (= (sb-posix:stat-ino before) (sb-posix:stat-ino stat)))))
             (%ci-fail "File sostituito, speciale o con link fisici."))
           (when (and output replace) (sb-posix:ftruncate fd 0))
           (with-open-stream
               (stream (sb-sys:make-fd-stream fd :input (not output) :output output
                                                :element-type '(unsigned-byte 8)
                                                :auto-close t))
             (setf fd nil)
             (funcall function stream stat)))
      (when fd (sb-posix:close fd)))))

(defun ci-bytes (path)
  "Dimensione di un file regolare, non espanso né interpretato."
  (%ci-call-file path (lambda (stream stat)
                       (declare (ignore stream)) (sb-posix:stat-size stat))))

(defun ci-read (path &key (max-bytes *ci-wire-max-bytes*))
  "Legge un solo valore wire UTF-8 limitato, con EOF obbligatorio."
  (%ci-limit max-bytes :bytes)
  (%ci-call-file
   path
   (lambda (stream stat)
     (let ((size (sb-posix:stat-size stat)))
       (unless (<= 0 size max-bytes) (%ci-fail "File wire oltre il limite byte."))
       (%ci-limit size :allocation)
       (let ((octets (make-array size :element-type '(unsigned-byte 8))))
         (unless (and (= size (read-sequence octets stream))
                      (eq :eof (read-byte stream nil :eof)))
           (%ci-fail "File wire cambiato durante la lettura."))
         (%ci-parse-wire (%ci-utf8-text octets) :max-bytes max-bytes))))))

(defun ci-save (path data &key replace)
  "Scrittura esclusiva di default; REPLACE esplicito consente la riscrittura."
  (let ((octets (%ci-utf8 (ci-wire-string data))))
    (%ci-call-file path
                   (lambda (stream stat)
                     (declare (ignore stat))
                     (write-sequence octets stream) (finish-output stream))
                   :output t :replace replace))
  path)

(defun %ci-check-argv (argv)
  (unless (and (listp argv) (plusp (%ci-list-length argv))
               (every (lambda (argument)
                        (and (stringp argument) (not (find #\Null argument)))) argv)
               (plusp (length (first argv))))
    (%ci-fail "ARGV non vuoto di stringhe senza NUL richiesto."))
  argv)

(defun %ci-call-program (argv input function)
  (%ci-check-argv argv)
  (unless (and (integerp *ci-command-timeout-seconds*)
               (<= 1 *ci-command-timeout-seconds* 600))
    (%ci-fail "Timeout comando non valido."))
  (let ((process nil))
    (unwind-protect
         (sb-ext:with-timeout *ci-command-timeout-seconds*
           (setf process
                 (sb-ext:run-program (first argv) (rest argv) :search t :wait nil
                                     :input input :output :stream :error nil
                                     :external-format :latin-1))
           (unless process (%ci-fail "Avvio comando fallito."))
           (let ((result (funcall function (sb-ext:process-output process))))
             (sb-ext:process-wait process)
             (unless (and (eq :exited (sb-ext:process-status process))
                          (eql 0 (sb-ext:process-exit-code process)))
               (%ci-fail "Comando ~A fallito: stato ~S, codice ~S."
                         (first argv) (sb-ext:process-status process)
                         (sb-ext:process-exit-code process)))
             result))
      (when process
        (unwind-protect
             (progn
               (when (member (sb-ext:process-status process) '(:running :stopped))
                 (sb-ext:process-kill process sb-posix:sigkill))
               (sb-ext:process-wait process))
          (sb-ext:process-close process))))))

(defun %ci-command-octets (argv &key input (max-bytes *ci-command-max-bytes*))
  (%ci-limit max-bytes :command-output)
  (%ci-call-program
   argv input
   (lambda (stream)
     (let ((output (make-array 0 :element-type '(unsigned-byte 8)
                                :adjustable t :fill-pointer 0)))
       (loop for character = (read-char stream nil nil) while character
             do (when (>= (length output) max-bytes)
                  (%ci-fail "Output comando oltre il limite byte."))
                (vector-push-extend (char-code character) output))
       output))))

(defun ci-command-output (argv)
  "Stdout UTF-8 esatto, inclusi NUL/newline; errore per uscita non zero."
  (%ci-utf8-text (%ci-command-octets argv)))

(defun %ci-git-argv (argv root)
  (%ci-check-argv (cons "git" argv))
  (append (list "git" "--no-pager" "--no-replace-objects" "--literal-pathspecs"
                "-c" "core.fsmonitor=false" "-c" "core.untrackedCache=false"
                "-c" "core.hooksPath=/dev/null" "-C"
                (namestring (uiop:ensure-directory-pathname root)))
          argv))

(defun ci-git (argv &optional (root *ci-root*))
  "Git tramite argv; nessuna shell, replace ref, hook o fsmonitor."
  (ci-command-output (%ci-git-argv argv root)))

(defun %ci-sha256-output (octets)
  (let ((text (%ci-utf8-text octets)))
    (unless (and (= (length text) 68) (string= (subseq text 64) (format nil "  -~%"))
                 (every (lambda (character)
                          (or (char<= #\0 character #\9) (char<= #\a character #\f)))
                        (subseq text 0 64)))
      (%ci-fail "Output SHA-256 non valido."))
    (string-downcase (subseq text 0 64))))

(defun ci-sha256 (path)
  "SHA-256 dei byte opachi: shasum con stdin regolare e argv fisso."
  (%ci-call-file path
                 (lambda (stream stat)
                   (declare (ignore stat))
                   (%ci-sha256-output
                    (%ci-command-octets '("shasum" "-a" "256")
                                        :input stream :max-bytes 128)))))

(defun ci-digest-string (text)
  "SHA-256 dei byte UTF-8 esatti della stringa, senza newline aggiunta."
  (unless (stringp text) (%ci-fail "Stringa richiesta per il digest."))
  (let ((octets (%ci-utf8 text)))
    (when (> (length octets) *ci-command-max-bytes*)
      (%ci-fail "Ingresso digest oltre il limite byte."))
    ;; RUN-PROGRAM trasporta Latin-1: una posizione per ciascun byte UTF-8.
    (with-input-from-string (stream (map 'string #'code-char octets))
      (%ci-sha256-output (%ci-command-octets '("shasum" "-a" "256")
                                            :input stream :max-bytes 128)))))
