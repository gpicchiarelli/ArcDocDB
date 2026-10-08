(:SCHEMA 1 :MODULE :CODEC :STATUS :OK :COMMAND
 (:ARGV
  ("sbcl" "--noinform" "--script"
   #A((58) BASE-CHAR
      . "/private/tmp/arcdocdb-spk10-codec.DFuRp6/strict-check.lisp"))
  :RUNNER "(in-package #:cl-user)
(declaim (optimize (safety 3) (debug 1)))
(setf *read-eval* nil)
(defun comando-git-codec (argomenti)
  (let ((uscita (make-string-output-stream)) (diagnostica (make-string-output-stream)))
    (let ((processo (sb-ext:run-program \"git\" argomenti :search t :wait t
                                      :output uscita :error diagnostica)))
      (unless (zerop (sb-ext:process-exit-code processo))
        (error \"Git metadati: ~A\" (get-output-stream-string diagnostica)))
      (string-trim '(#\\Space #\\Newline #\\Return #\\Tab) (get-output-stream-string uscita)))))
(defun testo-runner-codec (path)
  (with-open-file (stream path :direction :input)
    (let ((testo (make-string (file-length stream))))
      (read-sequence testo stream)
      testo)))
(let* ((root #P\"/Users/gpicchiarelli/Documents/ArcDocDB/\")
       (directory-temporanea (make-pathname :name nil :type nil :defaults *load-truename*))
       (fonti (list (merge-pathnames \"spikes/SPK-09-integrity/core.lisp\" root)
                    (merge-pathnames \"spikes/SPK-10-v2-limits/codec.lisp\" root)))
       (destinazioni (list (merge-pathnames \"crc.fasl\" directory-temporanea)
                          (merge-pathnames \"codec.fasl\" directory-temporanea)))
       (registro (merge-pathnames \"spikes/SPK-10-v2-limits/out/codec-check.lisp\" root))
       (stdout (make-string-output-stream)) (stderr (make-string-output-stream))
       (avvisi 0) (style-avvisi 0) (unita nil) (blobs nil) (risultato nil)
       (fallimenti nil) (fase :metadata) (sorgente-corrente nil)
       (inizio (get-universal-time)) (clock-inizio (get-internal-real-time))
       (head nil))
  (handler-case
      (let ((*standard-output* stdout) (*error-output* stderr) (*trace-output* stderr)
            (*compile-verbose* nil) (*compile-print* nil) (*load-verbose* nil) (*load-print* nil))
        (setf head (comando-git-codec (list \"-C\" (namestring root) \"rev-parse\" \"HEAD\")))
        (dolist (fonte fonti)
          (push (list :path (namestring fonte)
                      :git-blob (comando-git-codec (list \"-C\" (namestring root) \"hash-object\"
                                                       \"--\" (namestring fonte)))) blobs))
        (handler-bind ((warning (lambda (condizione)
                                 (if (typep condizione 'style-warning) (incf style-avvisi) (incf avvisi))
                                 (error \"Strict compile/load rifiutato: ~A\" condizione))))
          (loop for fonte in fonti for destinazione in destinazioni do
            (setf fase :compile sorgente-corrente (namestring fonte))
            (multiple-value-bind (fasl warning-p failure-p)
                (compile-file fonte :output-file destinazione :verbose nil :print nil)
              (push (list :source (namestring fonte) :fasl (and fasl (namestring fasl))
                          :warnings warning-p :failure failure-p
                          :status (if (or warning-p failure-p (null fasl)) :failed :ok)) unita)
              (when (or warning-p failure-p (null fasl)) (error \"Strict compile fallito: ~A\" fonte))
              (setf fase :load)
              (load fasl)))
          (setf fase :check sorgente-corrente (namestring (second fonti)))
          (let ((api (find-symbol \"CHECK\" \"ARCDOCDB.SPK10.CODEC\")))
            (unless (and api (fboundp api)) (error \"API CHECK codec assente.\"))
            (setf risultato (funcall api)))
          (unless (eq (getf risultato :status) :ok) (error \"CHECK senza :status :ok: ~S\" risultato))))
    (error (condizione)
      (push (list :phase fase :source sorgente-corrente
                  :type (prin1-to-string (type-of condizione)) :message (princ-to-string condizione)) fallimenti)
      (format stderr \"~A~%\" condizione)))
  (let* ((ambiente (list :sbcl (lisp-implementation-version) :lisp (lisp-implementation-type)
                        :machine-type (machine-type) :machine-version (machine-version)
                        :os (software-type) :os-version (software-version)
                        :repository (namestring root) :head head
                        :policy '(:speed 2 :safety 3 :debug 1) :read-eval nil))
         (artifact (list :schema 1 :module :codec :status (if fallimenti :failed :ok)
                         :command (list :argv (list \"sbcl\" \"--noinform\" \"--script\" (namestring *load-truename*))
                                        :runner (testo-runner-codec *load-truename*))
                         :environment ambiente :source-blobs (nreverse blobs)
                         :compile-status (list :status (if fallimenti :failed :ok)
                                               :warnings avvisi :style-warnings style-avvisi :units (nreverse unita))
                         :result risultato :limits (getf risultato :limits)
                         :time (list :start-universal-time inizio :end-universal-time (get-universal-time)
                                     :elapsed-seconds (/ (- (get-internal-real-time) clock-inizio)
                                                         (float internal-time-units-per-second 1d0)))
                         :stdout (get-output-stream-string stdout) :stderr (get-output-stream-string stderr)
                         :failures (nreverse fallimenti))))
    (ensure-directories-exist registro)
    (let ((*print-readably* t) (*print-pretty* t) (*print-length* nil) (*print-level* nil))
      (with-open-file (stream registro :direction :output :if-exists :supersede :if-does-not-exist :create)
        (write artifact :stream stream) (terpri stream)))
    (with-open-file (stream registro :direction :input)
      (let* ((*read-eval* nil) (eof (gensym)) (riletto (read stream nil eof)))
        (unless (and (equalp artifact riletto) (eq (read stream nil eof) eof))
          (error \"Registro codec non rileggibile fedelmente: ~A\" registro))))
    (format t \"Registro: ~A~%\" registro)
    (format t \"Compilazione: ~S~%Risultato: ~S~%Tempo: ~S~%\" (getf artifact :compile-status)
            risultato (getf artifact :time))
    (when fallimenti (format t \"Fallimenti: ~S~%\" (getf artifact :failures)))
    (sb-ext:exit :code (if fallimenti 1 0))))
")
 :ENVIRONMENT
 (:SBCL #A((5) BASE-CHAR . "2.6.9") :LISP #A((4) BASE-CHAR . "SBCL")
  :MACHINE-TYPE #A((5) BASE-CHAR . "ARM64") :MACHINE-VERSION
  #A((8) BASE-CHAR . "Apple M4") :OS #A((6) BASE-CHAR . "Darwin") :OS-VERSION
  #A((6) BASE-CHAR . "27.0.0") :REPOSITORY
  #A((40) BASE-CHAR . "/Users/gpicchiarelli/Documents/ArcDocDB/") :HEAD
  "07cfd031b08b45e0eb8afcd2cba788e42454e03b" :POLICY
  (:SPEED 2 :SAFETY 3 :DEBUG 1) :READ-EVAL NIL)
 :SOURCE-BLOBS
 ((:PATH
   #A((73) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-09-integrity/core.lisp")
   :GIT-BLOB "80cdac4c0e52703618e1f274413b2ecbe00e6b14")
  (:PATH
   #A((74) BASE-CHAR
      . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-10-v2-limits/codec.lisp")
   :GIT-BLOB "baca070063883de9719d12fc2e9b4aabc3db3a02"))
 :COMPILE-STATUS
 (:STATUS :OK :WARNINGS 0 :STYLE-WARNINGS 0 :UNITS
  ((:SOURCE
    #A((73) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-09-integrity/core.lisp")
    :FASL
    #A((49) BASE-CHAR . "/private/tmp/arcdocdb-spk10-codec.DFuRp6/crc.fasl")
    :WARNINGS NIL :FAILURE NIL :STATUS :OK)
   (:SOURCE
    #A((74) BASE-CHAR
       . "/Users/gpicchiarelli/Documents/ArcDocDB/spikes/SPK-10-v2-limits/codec.lisp")
    :FASL
    #A((51) BASE-CHAR . "/private/tmp/arcdocdb-spk10-codec.DFuRp6/codec.fasl")
    :WARNINGS NIL :FAILURE NIL :STATUS :OK)))
 :RESULT
 (:STATUS :OK :CASES 416 :COUNTS
  (:CRC 122 :RECORD-GOLDEN 9 :KEYS 21 :DOCUMENTS 27 :MALFORMED 51 :INTERVALS 43
   :HINT-GOLDEN 6 :HINTS 101 :PARAMETERS 36)
  :LIMITS
  (:VERSIONS (1 2) :KEY-V1 255 :KEY-V2 65535 :DOCUMENT-V2 16777216 :RECORD-V1
   16777215 :RECORD-V2 16842775 :HEADER 24 :HINT 24)
  :MAXIMUM-DOCUMENT
  (:CASES 27 :DOCUMENT-BYTES 16777216 :RECORD-BYTES 16842775 :V1-RECORD-BYTES
   16777215 :REJECTION-BYTES-CONSED 0)
  :PREPARED-RECORDS :PREPARED-NOT-SUPPORTED :CBOR-VALIDATION :SEPARATE-MODULE
  :HINT-SECTION-CRC :CALLER-RESPONSIBILITY)
 :LIMITS
 (:VERSIONS (1 2) :KEY-V1 255 :KEY-V2 65535 :DOCUMENT-V2 16777216 :RECORD-V1
  16777215 :RECORD-V2 16842775 :HEADER 24 :HINT 24)
 :TIME
 (:START-UNIVERSAL-TIME 4000474590 :END-UNIVERSAL-TIME 4000474591
  :ELAPSED-SECONDS 0.846542d0)
 :STDOUT "" :STDERR "" :FAILURES NIL)
