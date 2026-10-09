(:SCHEMA-VERSION 1 :KIND :SOURCE-SNAPSHOT :STATUS :OK :PATH
 "tools/check-evidence-storage.lisp" :GIT-BLOB
 "eeb5ca22b614959d60e2b05da2b5c5778d0d056c" :SOURCE
 ";;;; Test isolati del solo modulo evidence-storage; nessuna scansione dei cataloghi.
;;;; Uso: sbcl --script tools/check-evidence-storage.lisp
;;;; REQ: REQ-VAL-001 REQ-AFF-012
;;;; Fixture mkdtemp esclusive, gzip -n -9 -c senza shell, SHA-256 indipendenti.
;;;; I lettori negativi girano in processi separati con timeout e raccolta del figlio.
(require :asdf)
(require :sb-posix)
(declaim (optimize (safety 3) (debug 3)))

(defpackage #:arcdocdb.evidence.tests (:use #:cl))
(in-package #:arcdocdb.evidence.tests)

(defparameter *script-path* *load-truename*)
(defparameter *module-path* (merge-pathnames \"evidence-storage.lisp\" *script-path*))
(defvar *checks* 0)
(defvar *cases* nil)
(defvar *files* nil)
(defvar *directories* nil)
(defvar *root* nil)
(defvar *serial* 0)
(defparameter +process-seconds+ 10)

(define-condition callback-test-error (error) ())

(defun check (predicate description)
  \"Conta soltanto asserzioni effettivamente riuscite.\"
  (unless predicate (error \"Asserzione fallita: ~A\" description))
  (incf *checks*))

(defun case-run (name function)
  (let ((before *checks*))
    (handler-case
        (progn (funcall function)
               (push (list :name name :status :ok :checks (- *checks* before)) *cases*))
      (serious-condition (condition)
        (push (list :name name :status :failed :checks (- *checks* before)
                    :diagnostic (princ-to-string condition)) *cases*)))))

(defun api-symbol (name)
  (multiple-value-bind (symbol visibility) (find-symbol name \"ARCDOCDB.EVIDENCE\")
    (unless (eq visibility :external) (error \"Export assente: ~A\" name))
    symbol))

(defun api (name &rest arguments)
  (sb-ext:with-timeout +process-seconds+
    (apply (symbol-function (api-symbol name)) arguments)))

(defun load-module ()
  (unless (probe-file *module-path*)
    (error \"Modulo non disponibile: ~A\" *module-path*))
  ;; Caricamento della libreria senza argomenti CLI e senza output sul report.
  (let ((sb-ext:*posix-argv* (list (first sb-ext:*posix-argv*)))
        (*standard-output* (make-string-output-stream)))
    (load *module-path* :verbose nil :print nil)))

(defun owned-path (name &optional (directory *root*))
  (let ((path (merge-pathnames name directory)))
    (push path *files*)
    path))

(defun fresh-log (suffix)
  (owned-path (format nil \"process-~D.~A\" (incf *serial*) suffix)))

(defun file-octets (path)
  (with-open-file (stream path :element-type '(unsigned-byte 8))
    (let ((bytes (make-array (file-length stream) :element-type '(unsigned-byte 8))))
      (unless (= (read-sequence bytes stream) (length bytes))
        (error \"Lettura incompleta: ~A\" path))
      bytes)))

(defun file-text (path)
  (sb-ext:octets-to-string (file-octets path) :external-format :utf-8))

(defun write-octets (path bytes)
  (with-open-file (stream path :direction :output :if-exists :error
                              :if-does-not-exist :create :element-type '(unsigned-byte 8))
    (write-sequence bytes stream))
  path)

(defun write-text (path text)
  (write-octets path (sb-ext:string-to-octets text :external-format :utf-8)))

(defun data-text (data)
  (let ((*print-readably* t) (*print-pretty* nil) (*print-circle* nil)
        (*print-length* nil) (*print-level* nil))
    (format nil \"~S~%\" data)))

(defun bounded-program (argv &key input output)
  \"ARGV esterno, mai una stringa shell; kill/reap anche in caso di timeout.\"
  (let ((stdout (or output (fresh-log \"out\")))
        (stderr (fresh-log \"err\")) (process nil))
    (unwind-protect
         (progn
           (setf process
                 (uiop:launch-program argv :input input :output stdout :error-output stderr
                                           :if-output-exists :error
                                           :if-error-output-exists :error
                                           :element-type '(unsigned-byte 8) :force-shell nil))
           (values (sb-ext:with-timeout +process-seconds+ (uiop:wait-process process))
                   stdout stderr))
      (when process
        (when (uiop:process-alive-p process) (uiop:terminate-process process :urgent t))
        (sb-ext:with-timeout +process-seconds+ (uiop:wait-process process))
        (uiop:close-streams process)))))

(defun independent-sha256 (path)
  (multiple-value-bind (code output diagnostic)
      (bounded-program (list \"shasum\" \"-a\" \"256\" \"--\" (namestring path)))
    (unless (eql code 0) (error \"SHA-256: ~A\" (file-text diagnostic)))
    (let ((text (file-text output)))
      (unless (and (> (length text) 64)
                   (every (lambda (char) (digit-char-p char 16)) (subseq text 0 64))
                   (find (char text 64) '(#\\Space #\\Tab)))
        (error \"Output SHA-256 non valido: ~S\" text))
      (string-downcase (subseq text 0 64)))))

(defun gzip-file (source payload)
  (multiple-value-bind (code output diagnostic)
      (bounded-program '(\"gzip\" \"-n\" \"-9\" \"-c\") :input source :output payload)
    (declare (ignore output))
    (unless (eql code 0) (error \"gzip: ~A\" (file-text diagnostic))))
  payload)

(defun descriptor-data (source payload)
  (list :schema-version 1 :kind :compressed-evidence :codec :gzip
        :payload (file-namestring payload)
        :uncompressed-bytes (length (file-octets source))
        :uncompressed-sha256 (independent-sha256 source)
        :compressed-bytes (length (file-octets payload))
        :compressed-sha256 (independent-sha256 payload)))

(defun bundle (name source directory)
  (let* ((payload (owned-path (format nil \"~A.lisp.gz\" name) directory))
         (descriptor (owned-path (format nil \"~A.descriptor.lisp\" name) directory)))
    (gzip-file source payload)
    (let ((data (descriptor-data source payload)))
      (write-text descriptor (data-text data))
      (values descriptor payload data))))

(defun descriptor-variant (name data directory &rest overrides)
  (let ((copy (copy-list data)) (path (owned-path (format nil \"~A.lisp\" name) directory)))
    (loop for (key value) on overrides by #'cddr do (setf (getf copy key) value))
    (write-text path (data-text copy))))

(defun changed-hash (hash)
  (let ((copy (copy-seq hash)))
    (setf (char copy 0) (if (char= (char copy 0) #\\0) #\\1 #\\0))
    copy))

(defun single-result (path)
  (let ((*read-eval* nil) (eof (gensym \"EOF\")))
    (with-open-file (stream path :external-format :utf-8)
      (let ((result (read stream nil eof)))
        (unless (and (listp result) result (eq (read stream nil eof) eof))
          (error \"Il figlio non ha prodotto una sola plist: ~A\" path))
        result))))

(defun sbcl-command (script &rest arguments)
  (append (list (namestring sb-ext:*runtime-pathname*) \"--noinform\" \"--no-userinit\"
                \"--no-sysinit\" \"--disable-debugger\" \"--script\" (namestring script))
          arguments))

(defun reject-path (path &key budget)
  (multiple-value-bind (code output diagnostic)
      (bounded-program (apply #'sbcl-command *script-path* \"--expect-invalid\"
                              (namestring path)
                              (when budget (list (write-to-string budget)))))
    (check (eql code 0) (format nil \"INVALID-EVIDENCE atteso per ~A; exit ~A; ~A\"
                               path code (file-text diagnostic)))
    (let ((result (single-result output)))
      (check (equal result '(:schema-version 1 :kind :evidence-storage-rejection :status :ok))
             \"Rifiuto osservato dal figlio, senza errori estranei\"))))

(defun negative-case (name path &key budget marker)
  (case-run name
            (lambda ()
              (reject-path path :budget budget)
              (when marker (check (not (probe-file marker)) \"#.: nessuna valutazione\")))))

(defun eval-attempt (marker)
  ;; Se *read-eval* fosse lasciato abilitato, questo file proverebbe l'esecuzione.
  (concatenate 'string \"#.\"
               (data-text
                `(progn
                   (with-open-file (stream ,(namestring marker) :direction :output
                                           :if-exists :supersede :if-does-not-exist :create)
                     (write-string \"EVALUATED\" stream))
                   '(:schema-version 1 :kind :fixture)))))

(defun callback-case (name path original original-sha &key temporary fail)
  (case-run
   name
   (lambda ()
     (let ((seen nil) (calls 0) (propagated nil))
       (handler-case
           (api \"CALL-WITH-EVIDENCE-BYTES\" path
                (lambda (validated)
                  (incf calls)
                  (check (pathnamep validated) \"Callback su pathname\")
                  (setf seen validated)
                  (check (probe-file validated) \"File presente durante la callback\")
                  (check (equalp (file-octets validated) original) \"Byte originali esatti\")
                  (check (string-equal (independent-sha256 validated) original-sha)
                         \"SHA-256 indipendente dei byte originali\")
                  (when fail (error 'callback-test-error))
                  :callback-result))
         (callback-test-error () (setf propagated t)))
       (check (= calls 1) \"Callback invocata esattamente una volta\")
       (check (eq propagated (not (null fail))) \"Errore della callback propagato\")
       (check (if temporary (not (probe-file seen)) (probe-file seen))
              \"Cleanup del tempfile; conservazione del file plain\")))))

(defun exercise (directory)
  (let* ((text (format nil \"; fixture: byte UTF-8, CRLF e #A~C~C~
                            (:schema-version 1 :kind :fixture~%
                             :unicode \\\"caffè, città, Ελληνικά, 日本語, 😀\\\"~%
                             :special #A((4) BASE-CHAR . \\\"SBCL\\\")~%
                             :nested (:values (1 -2 3/4) :vector #(1 2 3)))~%
                            ; commento finale e spazi conservati  ~%\"
                       #\\Return #\\Newline))
         (source (write-text (owned-path \"original.lisp\") text))
         (original (file-octets source))
         (original-sha (independent-sha256 source))
         (expected '(:schema-version 1 :kind :fixture
                     :unicode \"caffè, città, Ελληνικά, 日本語, 😀\"
                     :special \"SBCL\" :nested (:values (1 -2 3/4) :vector #(1 2 3)))))
    (multiple-value-bind (descriptor payload data) (bundle \"original\" source directory)
      (case-run :plain-and-compressed-equivalent
                (lambda ()
                  (check (equalp (api \"READ-EVIDENCE\" source) expected) \"Dati plain attesi\")
                  (check (equalp (api \"READ-EVIDENCE\" descriptor) expected) \"Dati compressi attesi\")
                  (check (equalp (api \"READ-EVIDENCE\" source) (api \"READ-EVIDENCE\" descriptor))
                         \"Equivalenza equalp\")
                  (check (> (length original) (length text)) \"Fixture realmente multibyte\")
                  (check (= (api \"FILE-BYTES\" source) (length original)) \"FILE-BYTES plain\")
                  (check (= (api \"FILE-BYTES\" payload) (getf data :compressed-bytes))
                         \"FILE-BYTES gzip\")
                  (check (string-equal (api \"FILE-SHA256\" source) original-sha) \"SHA-256 plain\")
                  (check (string-equal (api \"FILE-SHA256\" payload)
                                       (getf data :compressed-sha256)) \"SHA-256 gzip\")
                  (check (equalp (api \"READ-EVIDENCE\" descriptor
                                     :max-expanded-bytes (length original)) expected)
                         \"Budget esattamente uguale alla dimensione originale\")))
      (callback-case :plain-original-bytes source original original-sha)
      (callback-case :compressed-original-bytes descriptor original original-sha :temporary t)
      (callback-case :compressed-callback-error-cleanup descriptor original original-sha
                     :temporary t :fail t)
      (case-run :callback-preserves-input-files
                (lambda ()
                  (check (equalp (file-octets source) original) \"Originale conservato\")
                  (check (probe-file descriptor) \"Descriptor conservato\")
                  (check (string-equal (independent-sha256 payload)
                                       (getf data :compressed-sha256)) \"Payload conservato\")))
      (let* ((foreign-name \"ARCDOCDB.EVIDENCE.TESTS.LEGACY.UNDEFINED\")
             (legacy (write-text (owned-path \"legacy.lisp\")
                                 (format nil \"(:schema-version 1 :kind :legacy :value ~A:VALUE)~%\"
                                         foreign-name)))
             (bytes (file-octets legacy)) (sha (independent-sha256 legacy)))
        (case-run :foreign-package-fixture
                  (lambda () (check (not (find-package foreign-name)) \"Package legacy assente\")))
        (multiple-value-bind (legacy-descriptor) (bundle \"legacy\" legacy directory)
          (callback-case :legacy-plain-byte-callback legacy bytes sha)
          (callback-case :legacy-compressed-byte-callback legacy-descriptor bytes sha :temporary t)
          (callback-case :legacy-callback-error-cleanup legacy-descriptor bytes sha
                         :temporary t :fail t)))
      (let ((missing (copy-list data)))
        (remf missing :payload)
        (negative-case :missing-payload-field
                       (write-text (owned-path \"missing-field.lisp\" directory) (data-text missing))))
      (negative-case :missing-payload-file
                     (descriptor-variant \"missing-file\" data directory :payload \"absent.lisp.gz\"))
      (let ((outside (owned-path \"outside.lisp.gz\")))
        (gzip-file source outside)
        (dolist (entry (list (list :parent-path-escape \"../outside.lisp.gz\")
                            (list :backslash-path-escape \"..\\\\outside.lisp.gz\")
                            (list :absolute-path-escape (namestring outside))))
          (negative-case (first entry)
                         (descriptor-variant (string-downcase (symbol-name (first entry)))
                                             data directory :payload (second entry))))
        (let ((link (owned-path \"escape.lisp.gz\" directory)))
          (sb-posix:symlink (namestring outside) (namestring link))
          (case-run :symlink-fixture
                    (lambda () (check (equal (truename link) (truename outside))
                                      \"Symlink reale fuori dalla directory del descriptor\")))
          (negative-case :symlink-path-escape
                         (descriptor-variant \"symlink-escape\" data directory
                                             :payload (file-namestring link)))))
      (dolist (key '(:uncompressed-sha256 :compressed-sha256))
        (negative-case key (descriptor-variant (string-downcase (symbol-name key)) data directory
                                              key (changed-hash (getf data key)))))
      (dolist (key '(:uncompressed-bytes :compressed-bytes))
        (dolist (delta '(-1 1))
          (let ((name (format nil \"~(~A~)-~A\" key (if (minusp delta) \"short\" \"long\"))))
            (negative-case (intern (string-upcase name) :keyword)
                           (descriptor-variant name data directory key (+ (getf data key) delta))))))
      (let ((bytes (file-octets payload)) (tampered (owned-path \"tampered.lisp.gz\" directory)))
        ;; Mtime del gzip: contenuto espanso invariato, dimensione invariata, hash diverso.
        (setf (aref bytes 4) (logxor 1 (aref bytes 4)))
        (write-octets tampered bytes)
        (negative-case :tampered-compressed-bytes
                       (descriptor-variant \"tampered-compressed\" data directory
                                           :payload (file-namestring tampered))))
      (let* ((bytes (copy-seq original)) (changed (owned-path \"changed-original.lisp\")))
        ;; Cambia solo un byte ASCII nel commento: equalp dei dati non può rilevarlo.
        (setf (aref bytes 2) (char-code #\\F))
        (write-octets changed bytes)
        (multiple-value-bind (changed-descriptor changed-payload changed-data)
            (bundle \"changed-original\" changed directory)
          (declare (ignore changed-descriptor changed-payload))
          (negative-case :tampered-original-bytes
                         (descriptor-variant \"tampered-original\" changed-data directory
                                             :uncompressed-sha256 original-sha))))
      (let ((truncated (owned-path \"truncated.lisp.gz\" directory)))
        (write-octets truncated (subseq (file-octets payload) 0 (- (getf data :compressed-bytes) 8)))
        ;; Metadati compressi veri: il test deve arrivare alla validazione del gzip.
        (negative-case :truncated-gzip
                       (descriptor-variant \"truncated\" data directory
                                           :payload (file-namestring truncated)
                                           :compressed-bytes (length (file-octets truncated))
                                           :compressed-sha256 (independent-sha256 truncated))))
      (let ((trailing (write-text (owned-path \"multiple-forms.lisp\")
                                  (concatenate 'string text (format nil \"(:second t)~%\")))))
        (negative-case :plain-multiple-forms trailing)
        (multiple-value-bind (wrapped) (bundle \"multiple-forms\" trailing directory)
          (negative-case :compressed-multiple-forms wrapped)))
      (dolist (position '(:leading :trailing))
        (let* ((name (string-downcase (symbol-name position)))
               (marker (owned-path (format nil \"evaluated-~A.marker\" name)))
               (attempt (eval-attempt marker))
               (hostile (write-text (owned-path (format nil \"read-eval-~A.lisp\" name))
                                    (if (eq position :leading) attempt
                                        (concatenate 'string text attempt)))))
          (negative-case (intern (format nil \"PLAIN-READ-EVAL-~A\" position) :keyword)
                         hostile :marker marker)
          (multiple-value-bind (wrapped) (bundle (format nil \"read-eval-~A\" name) hostile directory)
            (negative-case (intern (format nil \"COMPRESSED-READ-EVAL-~A\" position) :keyword)
                           wrapped :marker marker))))
      ;; Catene finite di descriptor validi, fino al record originale.
      ;; Un lettore che segue ricorsivamente i descriptor accetterebbe queste fixture.
      (multiple-value-bind (nested) (bundle \"nested\" descriptor directory)
        (negative-case :nested-descriptor nested)
        (multiple-value-bind (recursive) (bundle \"recursive-chain\" nested directory)
          (negative-case :recursive-descriptor-chain recursive)))
      (negative-case :expanded-budget-too-small descriptor :budget (1- (length original)))
      (negative-case :expanded-budget-underdeclared
                     (descriptor-variant \"underdeclared\" data directory :uncompressed-bytes 16)
                     :budget 16)
      (case-run :callback-expanded-budget-too-small
                (lambda ()
                  (let ((called nil) (caught nil))
                    (handler-case
                        (api \"CALL-WITH-EVIDENCE-BYTES\" descriptor
                             (lambda (path) (declare (ignore path)) (setf called t))
                             :max-expanded-bytes (1- (length original)))
                      (error (condition)
                        (unless (typep condition (api-symbol \"INVALID-EVIDENCE\")) (error condition))
                        (setf caught t)))
                    (check caught \"Budget callback rifiutato da INVALID-EVIDENCE\")
                    (check (not called) \"Callback non chiamata su dati non validi\")))))))

(defun cleanup ()
  \"Unlink dei nomi posseduti, mai dei truename: non segue i symlink della fixture.\"
  (let ((errors nil))
    (dolist (path *files*)
      (handler-case (sb-posix:unlink (namestring path))
        (sb-posix:syscall-error (condition)
          (unless (= (sb-posix:syscall-errno condition) sb-posix:enoent)
            (push (princ-to-string condition) errors)))))
    (dolist (path *directories*)
      (handler-case (sb-posix:rmdir (namestring path))
        (error (condition) (push (princ-to-string condition) errors))))
    (when errors (error \"Cleanup incompleto: ~{~A~^; ~}\" (nreverse errors)))))

(defun emit (record)
  (let ((*print-readably* t) (*print-pretty* nil) (*print-length* nil) (*print-level* nil))
    (write record)
    (terpri)))

(defun rejection-child (arguments)
  (handler-case
      (progn
        (unless (<= 2 (length arguments) 3) (error \"Argomenti del figlio non validi\"))
        (load-module)
        ;; Il lettore deve disabilitare read-eval anche se il chiamante lo abilita.
        (let ((*read-eval* t))
          (handler-case
              (progn
                (apply #'api \"READ-EVIDENCE\" (pathname (second arguments))
                       (when (third arguments)
                         (list :max-expanded-bytes (parse-integer (third arguments)))))
                (error \"Evidenza negativa accettata\"))
            (error (condition)
              (unless (typep condition (api-symbol \"INVALID-EVIDENCE\")) (error condition)))))
        (emit '(:schema-version 1 :kind :evidence-storage-rejection :status :ok)))
    (serious-condition (condition)
      (emit (list :schema-version 1 :kind :evidence-storage-rejection :status :failed
                  :diagnostic (princ-to-string condition)))
      (sb-ext:exit :code 1))))

(defun main ()
  (let ((*checks* 0) (*cases* nil) (*files* nil) (*directories* nil)
        (*root* nil) (*serial* 0) (fatal nil))
    (handler-case
        (unwind-protect
             (progn
               (when (uiop:command-line-arguments) (error \"Questo harness non accetta argomenti\"))
               (load-module)
               (case-run :public-api
                         (lambda ()
                           (dolist (name '(\"READ-EVIDENCE\" \"FILE-BYTES\" \"FILE-SHA256\"
                                           \"CALL-WITH-EVIDENCE-BYTES\"))
                             (check (fboundp (api-symbol name)) (format nil \"Export funzione ~A\" name)))
                           (check (find-class (api-symbol \"INVALID-EVIDENCE\") nil)
                                  \"Export condizione INVALID-EVIDENCE\")))
               (setf *root* (uiop:ensure-directory-pathname
                            (sb-posix:mkdtemp
                             (namestring (merge-pathnames \"arcdocdb-evidence-tests-XXXXXX\"
                                                          (uiop:temporary-directory))))))
               (push *root* *directories*)
               (let ((directory (merge-pathnames \"evidence/\" *root*)))
                 (sb-posix:mkdir (namestring directory) #o700)
                 (push directory *directories*)
                 (exercise directory)))
          (when *root* (case-run :fixture-cleanup
                                 (lambda () (cleanup)
                                   (check (not (probe-file *root*)) \"Directory temporanea rimossa\")))))
      (serious-condition (condition) (setf fatal (princ-to-string condition))))
    (let* ((cases (nreverse *cases*))
           (ok (and (not fatal) cases (every (lambda (item) (eq (getf item :status) :ok)) cases)))
      (emit (append (list :schema-version 1 :kind :evidence-storage-tests
                          :status (if ok :ok :failed) :checks *checks* :cases cases)
                    (when fatal (list :diagnostic fatal))))
      (unless ok (sb-ext:exit :code 1)))))

(if (equal (first (uiop:command-line-arguments)) \"--expect-invalid\")
    (rejection-child (uiop:command-line-arguments))
    (main))
"
 :METHOD :RECONSTRUCTED-AND-VERIFIED-AGAINST-RECORDED-GIT-BLOB)
