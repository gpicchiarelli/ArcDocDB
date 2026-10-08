(:SCHEMA-VERSION 1 :MODULE :CBOR :CAMPAIGN :ALLOCATION-CHECK :STATUS :OK
 :ATTEMPTS
 ((:SCHEMA-VERSION 1 :ATTEMPT 1 :MODULE :CBOR :MODE :CHECK :STATUS :OK :COMMAND
   (:ARGV
    ("/opt/homebrew/bin/sbcl" "--noinform" "--no-userinit" "--script"
     "/dev/stdin")
    :STDIN
    #A((7512) BASE-CHAR . "(in-package #:cl-user)
(setf *read-eval* nil)
(declaim (optimize (safety 3) (debug 1)))
(let* ((directory #p\"/Users/gpicchiarelli/Documents/ArcDocDB/\")
       (output (merge-pathnames \"spikes/SPK-10-v2-limits/out/cbor-allocation-check.lisp\" directory))
       (fasl #p\"/tmp/arcdocdb-spk10-cbor-allocation.fasl\")
       (inizio (get-internal-real-time)) (inizio-universale (get-universal-time))
       (stdout (make-string-output-stream)) (stderr (make-string-output-stream))
       (note 0) (avvisi 0) (avvisi-stile 0)
       (stadio :metadata) (blob nil) (risultato nil) (fallimenti nil)
       (compilazione (list :status :pending))
       (precedente
         (when (probe-file output)
           (with-open-file (stream output :external-format :utf-8)
             (let ((*read-eval* nil))
               (let ((prova (read stream nil :eof)))
                 (unless (and (listp prova) (= (getf prova :schema-version) 1)
                              (eq (getf prova :campaign) :allocation-check)
                              (eq (read stream nil :eof) :eof))
                   (error \"Artefatto precedente non valido: non viene sostituito.\"))
                 prova)))))
       (tentativo (1+ (length (getf precedente :attempts)))))
  (let ((*standard-output* stdout) (*error-output* stderr) (*trace-output* stderr)
        (*print-pretty* t) (*print-readably* t) (*print-length* nil) (*print-level* nil))
    (handler-case
        (progn
          (setf blob
                (loop for relativo in '(\"spikes/SPK-10-v2-limits/cbor.lisp\"
                                        \"spikes/SPK-10-v2-limits/metodo-cbor.md\")
                      collect
                      (let* ((stream (make-string-output-stream))
                             (processo (sb-ext:run-program \"/usr/bin/git\"
                                          (list \"-C\" (namestring directory) \"hash-object\" relativo)
                                          :output stream :error stderr :wait t)))
                        (unless (zerop (sb-ext:process-exit-code processo))
                          (error \"git hash-object fallito: ~A\" relativo))
                        (list :path relativo :git-blob
                              (string-trim '(#\\Space #\\Newline #\\Return)
                                           (get-output-stream-string stream))))))
          (setf stadio :compile)
          (let ((inizio-compilazione (get-internal-real-time)))
            (handler-bind
                ((style-warning (lambda (c) (incf avvisi-stile)
                                  (error \"Style-warning fatale: ~A\" c)))
                 (warning (lambda (c) (incf avvisi) (error \"Warning fatale: ~A\" c)))
                 (sb-ext:compiler-note (lambda (c) (incf note) (muffle-warning c))))
              (multiple-value-bind (compilato warning-p failure-p)
                  (compile-file (merge-pathnames \"spikes/SPK-10-v2-limits/cbor.lisp\" directory)
                                :output-file fasl :verbose nil :print nil)
                (setf compilazione
                      (list :status (if (or warning-p failure-p (null compilato)) :failed :ok)
                            :warnings-p warning-p :failure-p failure-p
                            :warning-count avvisi :style-warning-count avvisi-stile
                            :compiler-note-count note :fasl (namestring fasl)
                            :seconds (/ (- (get-internal-real-time) inizio-compilazione)
                                        (coerce internal-time-units-per-second 'double-float))))
                (when (or warning-p failure-p (null compilato))
                  (error \"Compile-file fallita: warning ~S, failure ~S.\" warning-p failure-p))
                (setf stadio :load) (load compilato :verbose nil :print nil)))
            (format t \"~S~%\" compilazione))
          (setf stadio :check)
          (let ((api (find-symbol \"CHECK\" \"ARCDOCDB.SPK10.CBOR\")))
            (unless (and api (fboundp api)) (error \"API check mancante.\"))
            (setf risultato (funcall api))
            (unless (eq (getf risultato :status) :ok) (error \"Check non :ok.\"))
            (write risultato) (terpri)))
      (error (condizione)
        (when (eq stadio :compile)
          (setf compilazione (list :status :failed :warning-count avvisi
                                   :style-warning-count avvisi-stile :compiler-note-count note)))
        (push (list :stage stadio :condition (princ-to-string (type-of condizione))
                    :message (princ-to-string condizione)) fallimenti)
        (format *error-output* \"~A~%\" condizione))))
  (let* ((voce
           (list :schema-version 1 :attempt tentativo :module :cbor :mode :check
                 :status (if fallimenti :failed :ok)
                 :command (list :argv '(\"/opt/homebrew/bin/sbcl\" \"--noinform\"
                                        \"--no-userinit\" \"--script\" \"/dev/stdin\")
                                :stdin (sb-ext:posix-getenv \"ARCDOCDB_SPK10_ALLOCATION_CHECK_SOURCE\"))
                 :environment (list :lisp (lisp-implementation-type)
                                    :version (lisp-implementation-version)
                                    :machine-type (machine-type) :machine-version (machine-version)
                                    :software-type (software-type)
                                    :software-version (software-version)
                                    :features (intersection '(:sbcl :64-bit :arm64 :x86-64) *features*)
                                    :repository (namestring directory)
                                    :internal-time-units-per-second internal-time-units-per-second)
                 :source-blobs blob :compile-status compilazione :result risultato
                 :limits (getf risultato :limits)
                 :time (list :started-universal-time inizio-universale
                             :elapsed-seconds (/ (- (get-internal-real-time) inizio)
                                                 (coerce internal-time-units-per-second 'double-float))
                             :check-seconds (getf risultato :elapsed-seconds))
                 :stdout (get-output-stream-string stdout)
                 :stderr (get-output-stream-string stderr) :failures (nreverse fallimenti)))
         (artefatto
           (list :schema-version 1 :module :cbor :campaign :allocation-check
                 :status (getf voce :status)
                 :attempts (append (getf precedente :attempts) (list voce)))))
    (ensure-directories-exist output)
    (with-open-file (stream output :direction :output :if-exists :supersede
                                   :if-does-not-exist :create :external-format :utf-8)
      (let ((*print-pretty* t) (*print-readably* t) (*print-length* nil) (*print-level* nil)
            (*print-circle* nil) (*package* (find-package \"CL-USER\")))
        (write artefatto :stream stream) (terpri stream)))
    (with-open-file (stream output :external-format :utf-8)
      (let ((*read-eval* nil))
        (unless (and (equalp artefatto (read stream nil :eof))
                     (eq (read stream nil :eof) :eof))
          (error \"Artefatto non rileggibile come singola plist.\"))))
    (format t \"~S~%\" (list :artifact (namestring output) :attempt tentativo
                          :status (getf voce :status) :compile-status compilazione
                          :result risultato :read-eval nil :read-back :ok))
    (when fallimenti (sb-ext:exit :code 1))))
"))
   :ENVIRONMENT
   (:LISP #A((4) BASE-CHAR . "SBCL") :VERSION #A((5) BASE-CHAR . "2.6.9")
    :MACHINE-TYPE #A((5) BASE-CHAR . "ARM64") :MACHINE-VERSION
    #A((8) BASE-CHAR . "Apple M4") :SOFTWARE-TYPE #A((6) BASE-CHAR . "Darwin")
    :SOFTWARE-VERSION #A((6) BASE-CHAR . "27.0.0") :FEATURES
    (:ARM64 :64-BIT :SBCL) :REPOSITORY
    #A((40) BASE-CHAR . "/Users/gpicchiarelli/Documents/ArcDocDB/")
    :INTERNAL-TIME-UNITS-PER-SECOND 1000000)
   :SOURCE-BLOBS
   ((:PATH "spikes/SPK-10-v2-limits/cbor.lisp" :GIT-BLOB
     "1e61d547f054c61bad1c8d2cf31b1ced1d24761a")
    (:PATH "spikes/SPK-10-v2-limits/metodo-cbor.md" :GIT-BLOB
     "f4eae4dc64758a61870ea194724ef24529aa7931"))
   :COMPILE-STATUS
   (:STATUS :OK :WARNINGS-P NIL :FAILURE-P NIL :WARNING-COUNT 0
    :STYLE-WARNING-COUNT 0 :COMPILER-NOTE-COUNT 125 :FASL
    #A((40) BASE-CHAR . "/tmp/arcdocdb-spk10-cbor-allocation.fasl") :SECONDS
    0.2421d0)
   :RESULT
   (:SPIKE :SPK-10 :MODULE :CBOR :STATUS :OK :SCOPE :PARTIAL :SAFETY 3 :CASES
    629 :FIXTURES (:VALID 21 :REJECTED 47) :DEPTH-CASES 12 :BUDGET-CASES 19
    :SIZE
    (:CASES 3 :ENCODED-BYTES 16777216 :PAYLOAD-BYTES 16777211 :OVERSIZE-BYTES
     16777217 :LIVE-FIXTURE-BYTES 33554433)
    :MUTATIONS
    (:SEEDS (1 48 8949 20261008) :CASES 512 :VALID 128 :REJECTED 384 :ORACLE
     :KNOWN-TRANSFORMATIONS)
    :STACK-ALLOCATION-CHECKS
    (:CASES 15 :VERIFICATION :OBJECT-COUNTS :RESULTS
     ((:CASE (:REQ-AFF-008 :SCALARE) :OUTCOME :OK :FRAMES-CREATED 0
       :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 0)
      (:CASE (:REQ-AFF-008 :BINARIO) :OUTCOME :OK :FRAMES-CREATED 0
       :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 0)
      (:CASE (:REQ-AFF-008 :ARRAY-VUOTO) :OUTCOME :OK :FRAMES-CREATED 0
       :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 1)
      (:CASE (:REQ-AFF-008 :MAPPA-VUOTA) :OUTCOME :OK :FRAMES-CREATED 0
       :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 1)
      (:CASE (:REQ-AFF-008 :POCO-PROFONDO) :OUTCOME :OK :FRAMES-CREATED 1
       :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 4 :DEPTH 1)
      (:CASE (:REQ-AFF-008 :FIGLIO-VUOTO) :OUTCOME :OK :FRAMES-CREATED 1
       :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 2 :DEPTH 2)
      (:CASE (:REQ-AFF-008 :RIUSO-MAPPA-ARRAY-MAPPA) :OUTCOME :OK
       :FRAMES-CREATED 2 :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 9 :DEPTH
       2)
      (:CASE (:REQ-AFF-008 :SCALARE-LIMITE-ZERO) :OUTCOME :OK :FRAMES-CREATED 0
       :STACK-CAPACITY 0 :STACK-LIMIT 0 :NODES 1 :DEPTH 0)
      (:CASE (:REQ-AFF-008 :VUOTO-LIMITE-ZERO) :OUTCOME :DEPTH-LIMIT
       :FRAMES-CREATED 0 :STACK-CAPACITY 0 :STACK-LIMIT 0 :NODES 1 :DEPTH 0)
      (:CASE (:REQ-AFF-008 :TRONCATO-PRIMA-PILA) :OUTCOME :TRUNCATED
       :FRAMES-CREATED 0 :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 1)
      (:CASE (:REQ-AFF-008 :BUDGET-PRIMA-PILA) :OUTCOME :NODE-BUDGET
       :FRAMES-CREATED 0 :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 1)
      (:CASE (:REQ-AFF-008 :PROFONDITA-RIDOTTA) :OUTCOME :DEPTH-LIMIT
       :FRAMES-CREATED 1 :STACK-CAPACITY 1 :STACK-LIMIT 1 :NODES 2 :DEPTH 1)
      (:CASE :REQ-LIM-002-PILA-100-VUOTO :OUTCOME :OK :FRAMES-CREATED 99
       :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 100 :DEPTH 100)
      (:CASE :REQ-LIM-002-PILA-100-NONVUOTO :OUTCOME :OK :FRAMES-CREATED 100
       :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 101 :DEPTH 100)
      (:CASE :REQ-LIM-002-PILA-101 :OUTCOME :DEPTH-LIMIT :FRAMES-CREATED 100
       :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 101 :DEPTH 100)))
    :LIMITS
    (:DOCUMENT-BYTES 16777216 :CONTAINER-DEPTH 100 :NODES 16777216 :INPUT-BYTES
     16777216 :STACK-FRAMES 100)
    :UNSUPPORTED (:TAGS :FLOATING-POINT :OTHER-SIMPLE-VALUES) :ELAPSED-SECONDS
    0.005228d0)
   :LIMITS
   (:DOCUMENT-BYTES 16777216 :CONTAINER-DEPTH 100 :NODES 16777216 :INPUT-BYTES
    16777216 :STACK-FRAMES 100)
   :TIME
   (:STARTED-UNIVERSAL-TIME 4000475715 :ELAPSED-SECONDS 0.373473d0
    :CHECK-SECONDS 0.005228d0)
   :STDOUT "(:STATUS :OK :WARNINGS-P NIL :FAILURE-P NIL :WARNING-COUNT 0
 :STYLE-WARNING-COUNT 0 :COMPILER-NOTE-COUNT 125 :FASL
 #A((40) BASE-CHAR . \"/tmp/arcdocdb-spk10-cbor-allocation.fasl\") :SECONDS
 0.2421d0)
(:SPIKE :SPK-10 :MODULE :CBOR :STATUS :OK :SCOPE :PARTIAL :SAFETY 3 :CASES 629
 :FIXTURES (:VALID 21 :REJECTED 47) :DEPTH-CASES 12 :BUDGET-CASES 19 :SIZE
 (:CASES 3 :ENCODED-BYTES 16777216 :PAYLOAD-BYTES 16777211 :OVERSIZE-BYTES
  16777217 :LIVE-FIXTURE-BYTES 33554433)
 :MUTATIONS
 (:SEEDS (1 48 8949 20261008) :CASES 512 :VALID 128 :REJECTED 384 :ORACLE
  :KNOWN-TRANSFORMATIONS)
 :STACK-ALLOCATION-CHECKS
 (:CASES 15 :VERIFICATION :OBJECT-COUNTS :RESULTS
  ((:CASE (:REQ-AFF-008 :SCALARE) :OUTCOME :OK :FRAMES-CREATED 0
    :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 0)
   (:CASE (:REQ-AFF-008 :BINARIO) :OUTCOME :OK :FRAMES-CREATED 0
    :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 0)
   (:CASE (:REQ-AFF-008 :ARRAY-VUOTO) :OUTCOME :OK :FRAMES-CREATED 0
    :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 1)
   (:CASE (:REQ-AFF-008 :MAPPA-VUOTA) :OUTCOME :OK :FRAMES-CREATED 0
    :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 1)
   (:CASE (:REQ-AFF-008 :POCO-PROFONDO) :OUTCOME :OK :FRAMES-CREATED 1
    :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 4 :DEPTH 1)
   (:CASE (:REQ-AFF-008 :FIGLIO-VUOTO) :OUTCOME :OK :FRAMES-CREATED 1
    :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 2 :DEPTH 2)
   (:CASE (:REQ-AFF-008 :RIUSO-MAPPA-ARRAY-MAPPA) :OUTCOME :OK :FRAMES-CREATED
    2 :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 9 :DEPTH 2)
   (:CASE (:REQ-AFF-008 :SCALARE-LIMITE-ZERO) :OUTCOME :OK :FRAMES-CREATED 0
    :STACK-CAPACITY 0 :STACK-LIMIT 0 :NODES 1 :DEPTH 0)
   (:CASE (:REQ-AFF-008 :VUOTO-LIMITE-ZERO) :OUTCOME :DEPTH-LIMIT
    :FRAMES-CREATED 0 :STACK-CAPACITY 0 :STACK-LIMIT 0 :NODES 1 :DEPTH 0)
   (:CASE (:REQ-AFF-008 :TRONCATO-PRIMA-PILA) :OUTCOME :TRUNCATED
    :FRAMES-CREATED 0 :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 1)
   (:CASE (:REQ-AFF-008 :BUDGET-PRIMA-PILA) :OUTCOME :NODE-BUDGET
    :FRAMES-CREATED 0 :STACK-CAPACITY 0 :STACK-LIMIT 100 :NODES 1 :DEPTH 1)
   (:CASE (:REQ-AFF-008 :PROFONDITA-RIDOTTA) :OUTCOME :DEPTH-LIMIT
    :FRAMES-CREATED 1 :STACK-CAPACITY 1 :STACK-LIMIT 1 :NODES 2 :DEPTH 1)
   (:CASE :REQ-LIM-002-PILA-100-VUOTO :OUTCOME :OK :FRAMES-CREATED 99
    :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 100 :DEPTH 100)
   (:CASE :REQ-LIM-002-PILA-100-NONVUOTO :OUTCOME :OK :FRAMES-CREATED 100
    :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 101 :DEPTH 100)
   (:CASE :REQ-LIM-002-PILA-101 :OUTCOME :DEPTH-LIMIT :FRAMES-CREATED 100
    :STACK-CAPACITY 100 :STACK-LIMIT 100 :NODES 101 :DEPTH 100)))
 :LIMITS
 (:DOCUMENT-BYTES 16777216 :CONTAINER-DEPTH 100 :NODES 16777216 :INPUT-BYTES
  16777216 :STACK-FRAMES 100)
 :UNSUPPORTED (:TAGS :FLOATING-POINT :OTHER-SIMPLE-VALUES) :ELAPSED-SECONDS
 0.005228d0)
"
   :STDERR "" :FAILURES NIL)))
