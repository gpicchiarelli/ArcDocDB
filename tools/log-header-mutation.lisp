;;;; Otto mutazioni degli header log in copie isolate; il checkout non è modificato.
;;;; Uso: --self-test oppure --run directory-nuova/.
;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-AFF-002 REQ-VAL-001
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.log-header.mutation (:use #:cl))
(in-package #:arcdocdb.log-header.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *mutants*
  '(("log-crc" "(unless (= (leggi-u32 buffer (+ start +log-crc-offset+))"
               "(unless (/= (leggi-u32 buffer (+ start +log-crc-offset+))")
    ("log-magic-low-skip" "(= (leggi-u32 buffer start) +log-magic-low+)" "t")
    ("log-magic-high-skip" "(= (leggi-u32 buffer (+ start +log-magic-high-offset+)) magic)"
                           "(= magic magic)")
    ("log-identity" "always (= (aref buffer (+ start +log-identity-offset+ i)) (aref identity i))"
                    "always (/= (aref buffer (+ start +log-identity-offset+ i)) (aref identity i))")
    ("log-truncated-boundary" "(< (- end start) +log-header-bytes+)"
                              "(<= (- end start) +log-header-bytes+)")
    ("log-reserved-a-skip"
     "(zero-range-p buffer (+ start +log-reserved-a-start+) (+ start +log-reserved-a-end+))" "t")
    ("log-reserved-b-skip"
     "(zero-range-p buffer (+ start +log-reserved-b-start+) (+ start +log-crc-offset+))" "t")
    ("log-reserved-c-skip" "(zero-range-p buffer (+ start +log-reserved-c-start+) next)" "t")))

(define-condition target-invalido (error)
  ((motivo :initarg :motivo :reader motivo-target))
  (:report (lambda (condizione flusso)
             (format flusso "Bersaglio della mutazione header log invalido: ~S."
                     (motivo-target condizione)))))

(defun source-files ()
  "Tutti i file richiesti dall'ASD, test e build; nessuna evidenza o checkout Git copiato."
  (append '(#p"arcdocdb.asd" #p"tools/build.lisp")
          (sort (append (directory "src/**/*.lisp") (directory "tests/**/*.lisp"))
                #'string< :key #'namestring)))

(defun fingerprints ()
  "MD5 dei file realmente copiati e del driver, per confrontare prima e dopo."
  (loop for file in (append (source-files) '(#p"tools/log-header-mutation.lisp"))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun read-text (path)
  "Legge esclusivamente sorgenti e log come dati UTF-8."
  (uiop:read-file-string path :external-format :utf-8))

(defun substitute-first (text before after)
  "Sostituisce solo la prima occorrenza, senza riscrivere il testo sorgente originale."
  (let ((pos (search before text)))
    (unless pos (error 'target-invalido :motivo :assente))
    (concatenate 'string (subseq text 0 pos) after (subseq text (+ pos (length before))))))

(defun unique-position (text before)
  "Ogni bersaglio della campagna deve essere presente e non ambiguo."
  (let ((pos (search before text)))
    (unless pos (error 'target-invalido :motivo :assente))
    (when (search before text :start2 (1+ pos)) (error 'target-invalido :motivo :ambiguo))
    pos))

(defun validate-mutants ()
  "Ogni frammento bersaglio deve apparire una sola volta nel codec congelato."
  (let ((source (read-text "src/storage/log-header.lisp")))
    (unless (= 8 (length *mutants*)) (error "Numero mutanti header log inatteso."))
    (dolist (mutant *mutants*)
      (destructuring-bind (name before after) mutant
        (declare (ignore after))
        (handler-case (unique-position source before)
          (target-invalido (condizione)
            (error "Mutazione header log ~A: ~A." name condizione))))))
  nil)

(defun compilation-failure-p (text)
  "Una diagnostica di compilazione non costituisce prova di rilevamento del mutante."
  (or (search "compilation aborted" text :test #'char-equal)
      (search "COMPILE-FILE-ERROR" text :test #'char-equal)
      (search "COMPILE-FILE-WARNED" text :test #'char-equal)))

(defun classify-result (text exit)
  "Solo errore runtime dopo smoke rileva il mutante; gli altri guasti sono INVALID."
  (cond ((compilation-failure-p text) (values :invalid :compilation-failure))
        ((or (not (integerp exit)) (not (search "ok    ARCDOCDB:*VERSION*" text)))
         (values :invalid :before-smoke))
        ((zerop exit) (values :survived nil))
        (t (values :detected nil))))

(defun detected-p (text exit)
  "Rilevato solo con exit nonzero dopo smoke; compilazione fallita non conta."
  (eq :detected (classify-result text exit)))

(defun esigi-target-invalido (funzione motivo)
  "Verifica il self-test dei bersagli, distinguendo assenza e ambiguità."
  (let ((rilevato nil))
    (handler-case (funcall funzione)
      (target-invalido (condizione)
        (unless (eq motivo (motivo-target condizione)) (error condizione))
        (setf rilevato t)))
    (unless rilevato (error "Self-test: bersaglio invalido non rilevato."))))

(defun self-test ()
  "Verifica prima sostituzione, classificazioni e applicabilità al codec corrente."
  (unless (and (string= "xAxB" (substitute-first "xBxB" "B" "A"))
               (detected-p "ok    ARCDOCDB:*VERSION*" 1)
               (not (detected-p "ok    ARCDOCDB:*VERSION*" 0))
               (not (detected-p "compilation aborted" 1))
               (not (detected-p "ok    ARCDOCDB:*VERSION* compilation aborted" 1))
               (eq :invalid (classify-result "compilation aborted" 1))
               (eq :invalid (classify-result "runtime prima dello smoke" 1)))
    (error "Mutazioni header log: self-test di sostituzione/classificazione fallito."))
  (esigi-target-invalido (lambda () (substitute-first "abc" "Z" "A")) :assente)
  (esigi-target-invalido (lambda () (unique-position "xBxB" "B")) :ambiguo)
  (esigi-target-invalido (lambda () (unique-position "abc" "Z")) :assente)
  (validate-mutants)
  (list :status :ok :substitution :first-only :classification :after-smoke
        :invalid-targets '(:missing :ambiguous) :compilation-failure :invalid
        :applicable-mutants 8))

(defun new-directory (name)
  "Crea con mkdir esclusivo, dopo aver creato solo i genitori; non riutilizza directory."
  (let* ((directory (merge-pathnames (uiop:ensure-directory-pathname name) (truename "./")))
         (parent (make-pathname :defaults directory :directory (butlast (pathname-directory directory))
                                :name "segnaposto" :type nil)))
    (ensure-directories-exist parent)
    (sb-posix:mkdir directory #o700)
    directory))

(defun copy-test-system (directory)
  "Copia ASD, sorgenti, test e build; ogni destinazione è nuova e appartiene alla campagna."
  (dolist (file (source-files))
    (let ((target (merge-pathnames (enough-namestring file) directory)))
      (ensure-directories-exist target)
      (uiop:copy-file file target))))

(defun isolated-runner (directory)
  "Salva il runner della copia; output ASDF in fasl locale, distinto dalle altre prove."
  (let ((runner (merge-pathnames "tools/log-header-isolated-build.lisp" directory)))
    (with-open-file (stream runner :direction :output :if-exists :error :if-does-not-exist :create)
      (write-line ";;;; Runner della copia isolata; avvia la build rigorosa originale." stream)
      (write '(require :asdf) :stream stream) (terpri stream)
      (write `(asdf:initialize-output-translations
               '(:output-translations (,(namestring directory)
                                      ,(namestring (merge-pathnames "fasl/" directory)))
                                      :ignore-inherited-configuration)) :stream stream)
      (terpri stream)
      (write '(load "tools/build.lisp") :stream stream) (terpri stream))
    runner))

(defun execute-copy (directory)
  "Esegue la build rigorosa della copia con cache locale e log conservato."
  (let ((log (merge-pathnames "test.log" directory)))
    (isolated-runner directory)
    (multiple-value-bind (out err exit)
        (uiop:run-program '("sbcl" "--noinform" "--no-userinit" "--script"
                            "tools/log-header-isolated-build.lisp")
                          :directory directory :output log :error-output :output
                          :ignore-error-status t)
      (declare (ignore out err))
      (values (read-text log) exit log))))

(defun run-baseline (directory)
  "La copia invariata deve completare smoke e test con exit zero prima dei mutanti."
  (copy-test-system directory)
  (multiple-value-bind (text exit log) (execute-copy directory)
    (let ((passed (and (integerp exit) (zerop exit) (not (compilation-failure-p text))
                       (search "ok    ARCDOCDB:*VERSION*" text)
                       (search "build e test: nessun avviso, tutti i controlli superati" text))))
      (list :status (if passed :ok :invalid) :exit-code exit :log (namestring log)
            :diagnostic (unless passed :baseline-failed)))))

(defun run-mutant (mutant directory)
  "Conserva copia e log anche in caso di sopravvivenza, errore di setup o compilazione."
  (destructuring-bind (name before after) mutant
    (let ((log (merge-pathnames "test.log" directory)))
      (handler-case
          (progn
            (copy-test-system directory)
            (let* ((source (merge-pathnames "src/storage/log-header.lisp" directory))
                   (modified (substitute-first (read-text source) before after)))
              (with-open-file (stream source :direction :output :if-exists :supersede)
                (write-string modified stream)))
            (multiple-value-bind (text exit path-log) (execute-copy directory)
              (multiple-value-bind (result diagnostic) (classify-result text exit)
                (list :name name :detected (eq result :detected) :exit-code exit
                      :result result :diagnostic diagnostic :log (namestring path-log)))))
        (error (condizione)
          (list :name name :detected nil :exit-code nil :result :infrastructure-error
                :diagnostic (princ-to-string condizione) :log (namestring log)))))))

(defun save-report (report directory)
  "Aggiorna solo il report della directory esclusiva; nessun risultato tentato viene perduto."
  (when directory
    (with-open-file (stream (merge-pathnames "report.lisp" directory)
                           :direction :output :if-exists :supersede :if-does-not-exist :create)
      (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))))

(defun main ()
  "Self-test o otto copie nuove; plist finale e exit nonzero per campagna non valida."
  (let* ((args (rest sb-ext:*posix-argv*)) (before (fingerprints)) (directory nil)
         (report (list :schema-version 1 :kind :log-header-mutations :status :running
                       :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
                       :source-fingerprints-before before
                       :limits '(:targeted-mutants-only :in-memory-header-tests
                                 :compile-failure-not-detection :no-durability-or-engine-qualification))))
    (handler-case
        (progn
          (unless (or (equal args '("--self-test"))
                      (and (= (length args) 2) (string= (first args) "--run")))
            (error "Usare --self-test oppure --run directory-nuova/."))
          (setf (getf report :self-test) (self-test))
          (when (string= (first args) "--run")
            (setf directory (new-directory (second args)))
            (save-report report directory)
            (setf (getf report :baseline)
                  (run-baseline (new-directory (merge-pathnames "baseline/" directory))))
            (save-report report directory)
            (unless (eq (getf (getf report :baseline) :status) :ok)
              (error "Mutazioni header log: baseline invariata non riuscita."))
            (loop for mutant in *mutants* for i from 0
                  do (let* ((child (new-directory (merge-pathnames (format nil "~D/" i) directory)))
                            (result (run-mutant mutant child)))
                       (setf (getf report :mutants) (append (getf report :mutants) (list result)))
                       (save-report report directory)))
            (unless (and (= 8 (length (getf report :mutants)))
                         (every (lambda (result) (getf result :detected)) (getf report :mutants)))
              (error "Mutazioni header log: sopravvivenza o errore prima dello smoke.")))
          (setf (getf report :status) :ok))
      (error (condizione) (setf (getf report :status) :failed
                               (getf report :diagnostic) (princ-to-string condizione))))
    (let ((after (fingerprints)))
      (setf (getf report :source-fingerprints-after) after
            (getf report :source-consistency) (if (equal before after) :stable :changed))
      (when (and (eq (getf report :status) :ok) (not (equal before after)))
        (setf (getf report :status) :source-changed)))
    (save-report report directory)
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(main)
