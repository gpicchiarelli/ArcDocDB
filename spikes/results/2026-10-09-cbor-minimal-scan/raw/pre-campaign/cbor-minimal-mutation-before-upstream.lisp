;;;; Mutazioni del verificatore CBOR in copie isolate; il checkout non è modificato.
;;;; Uso header invariato: --self-test | --run directory-nuova/.
;;;; Gruppo scanner separato: --scan --self-test | --scan --run directory-nuova/.
;;; REQ: REQ-LIM-001 REQ-LIM-002 REQ-AFF-004 REQ-AFF-008
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.cbor-minimal.mutation (:use #:cl))
(in-package #:arcdocdb.cbor-minimal.mutation)
(declaim (optimize (safety 3) (debug 2)))

(defparameter *mutants*
  '(("src/codec/cbor-minimal.lisp" "integer-u8-boundary"
     "(24 (>= low 24))" "(24 (>= low 25))")
    ("src/codec/cbor-minimal.lisp" "integer-u16-boundary"
     "(25 (>= low 256))" "(25 (>= low 257))")
    ("src/codec/cbor-minimal.lisp" "integer-u32-boundary"
     "(26 (>= low 65536))" "(26 (>= low 65537))")
    ("src/codec/cbor-minimal.lisp" "integer-u64-low-instead-high"
     "(27 (not (zerop high)))" "(27 (not (zerop low)))")
    ("src/codec/cbor-float-minimal.lisp" "float32-half-normal-upper-bound"
     "(<= 113 exponent 142)" "(<= 113 exponent 141)")
    ("src/codec/cbor-float-minimal.lisp" "float32-half-subnormal-shift"
     "(- 126 exponent)" "(- 127 exponent)")
    ("src/codec/cbor-float-minimal.lisp" "float64-nonfinite-exponent"
     "((= exponent 2047)" "((= exponent 2046)")
    ("src/codec/cbor-float-minimal.lisp" "float64-single-subnormal-lower-bound"
     "(<= 874 exponent 896)" "(<= 875 exponent 896)")))

;;; Catalogo scan fissato sul prodotto congelato, indipendente dai nuovi test.
;;; Tutte le sostituzioni mantengono parametri usati e range dichiarati;
;;; la compilabilita effettiva e il kill saranno verificati solo nella campagna.
(defparameter *scan-mutants*
  '(("src/codec/cbor-scan-minimal.lisp" "scan-minimal-wrapper-bypass"
     "(verifica-struttura-cbor-interna buffer start end space max-bytes max-nodes max-depth t)"
     "(verifica-struttura-cbor-interna buffer start end space max-bytes max-nodes max-depth nil)")
    ("src/codec/cbor-scan.lisp" "scan-minimal-root-only"
     "(passo-struttura-cbor bytes scratch limit node-limit depth-limit minimal)"
     "(passo-struttura-cbor bytes scratch limit node-limit depth-limit (and minimal (zerop (spazio-cbor-nodes scratch))))")
    ("src/codec/cbor-scan.lisp" "scan-minimal-disabled-after-tag"
     "(if minimal (leggi-header-cbor-minimo buffer lead end)"
     "(if (and minimal (not (spazio-cbor-pending-tag space))) (leggi-header-cbor-minimo buffer lead end)")
    ("src/codec/cbor-scan.lisp" "scan-reset-only-unused-space"
     "(azzera-spazio-cbor scratch begin)"
     "(when (zerop (spazio-cbor-nodes scratch)) (azzera-spazio-cbor scratch begin))")
    ("src/codec/cbor-scan.lisp" "scan-node-budget-plus-one"
     "(conta-nodo-cbor space max-nodes lead)"
     "(conta-nodo-cbor space (min +cbor-scan-max-bytes+ (1+ max-nodes)) lead)")
    ("src/codec/cbor-scan.lisp" "scan-depth-budget-plus-one"
     "(tratta-item-cbor buffer space major high low next end form max-depth lead)"
     "(tratta-item-cbor buffer space major high low next end form (min +cbor-scan-max-depth+ (1+ max-depth)) lead)")
    ("src/codec/cbor-scan.lisp" "scan-reported-nodes-minus-one"
     "(values (spazio-cbor-nodes space) (spazio-cbor-peak-depth space) end)"
     "(values (max 0 (1- (spazio-cbor-nodes space))) (spazio-cbor-peak-depth space) end)")
    ("src/codec/cbor-scan.lisp" "scan-reported-end-minus-one"
     "(values (spazio-cbor-nodes space) (spazio-cbor-peak-depth space) end)"
     "(values (spazio-cbor-nodes space) (spazio-cbor-peak-depth space) (max 0 (1- end)))")))

(define-condition invalid-options (error)
  ((arguments :initarg :arguments :reader invalid-options-arguments))
  (:report (lambda (condition stream)
             (format stream "Opzioni mutazioni CBOR invalide: ~S."
                     (invalid-options-arguments condition)))))

(defun parse-options (arguments)
  "Dispatcher puro: sintassi header precedente o prefisso --scan esatto."
  (let* ((scan-p (and arguments (string= (first arguments) "--scan")))
         (rest (if scan-p (rest arguments) arguments))
         (group (if scan-p :scan :header)))
    (cond ((equal rest '("--self-test")) (values group :self-test nil))
          ((and (= 2 (length rest)) (string= (first rest) "--run"))
           (values group :run (second rest)))
          (t (error 'invalid-options :arguments arguments)))))

(defun dispatch-self-test ()
  "Quattro chiamate valide e dodici negative; nessun I/O o directory creata."
  (dolist (fixture '((("--self-test") (:header :self-test nil))
                     (("--run" "new/") (:header :run "new/"))
                     (("--scan" "--self-test") (:scan :self-test nil))
                     (("--scan" "--run" "new/") (:scan :run "new/"))))
    (unless (equal (second fixture) (multiple-value-list (parse-options (first fixture))))
      (error "Dispatcher mutazioni CBOR: chiamata valida interpretata diversamente.")))
  (let ((negative '(nil ("--run") ("--self-test" "extra") ("--run" "x" "extra")
                    ("--unknown") ("--scan") ("--scan" "--run")
                    ("--scan" "--self-test" "extra") ("--scan" "--run" "x" "extra")
                    ("--scan" "--scan" "--self-test") ("--scan" "--unknown")
                    ("--run" "x" "--scan"))))
    (dolist (arguments negative)
      (let ((rejected nil))
        (handler-case (parse-options arguments)
          (invalid-options () (setf rejected t)))
        (unless rejected (error "Dispatcher mutazioni CBOR accetta ~S." arguments))))
    (list :status :ok :legacy-and-scan-valid 4 :negative-rejected (length negative)
          :rejection-before-directory-creation t)))

(define-condition target-invalido (error)
  ((motivo :initarg :motivo :reader motivo-target))
  (:report (lambda (condizione flusso)
             (format flusso "Bersaglio della mutazione CBOR invalido: ~S."
                     (motivo-target condizione)))))

(defun source-files ()
  "Tutti i file richiesti dall'ASD, test e build; nessuna evidenza o checkout Git copiato."
  (append '(#p"arcdocdb.asd" #p"tools/build.lisp")
          (sort (append (directory "src/**/*.lisp") (directory "tests/**/*.lisp"))
                #'string< :key #'namestring)))

(defun fingerprints ()
  "MD5 dei file realmente copiati e del driver, per confrontare prima e dopo."
  (loop for file in (append (source-files) '(#p"tools/cbor-minimal-mutation.lisp"))
        collect (list :file (enough-namestring file)
                      :md5 (format nil "~(~{~2,'0X~}~)"
                                   (coerce (sb-md5:md5sum-file file) 'list)))))

(defun read-text (path)
  "Legge esclusivamente sorgenti e log come dati CBOR."
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
  "Ogni frammento bersaglio deve apparire una sola volta nel proprio file congelato."
  (unless (= 8 (length *mutants*)) (error "Numero mutanti CBOR inatteso."))
  (dolist (mutant *mutants*)
    (destructuring-bind (path name before after) mutant
      (declare (ignore after))
      (handler-case (unique-position (read-text path) before)
        (target-invalido (condizione)
          (error "Mutazione CBOR ~A in ~A: ~A." name path condizione)))))
  nil)

(defun compilation-failure-p (text)
  "Una diagnostica di compilazione non costituisce prova di rilevamento del mutante."
  (or (search "compilation aborted" text :test #'char-equal)
      (search "COMPILE-FILE-ERROR" text :test #'char-equal)
      (search "COMPILE-FILE-WARNED" text :test #'char-equal)))

(defun line-present-p (text expected)
  "Richiede una riga esatta, ammettendo solo il terminatore CR di un flusso CRLF."
  (loop for line in (uiop:split-string text :separator '(#\Newline))
        thereis (string= (string-right-trim '(#\Return) line) expected)))

(defun smoke-started-p (text)
  "Esito smoke su riga esatta; una citazione nel backtrace non costituisce smoke."
  (line-present-p text "ok    ARCDOCDB:*VERSION* è una stringa"))

(defun build-completed-p (text)
  "Una riga esatta dimostra il completamento della build e di tutti i test copiati."
  (line-present-p text "build e test: nessun avviso, tutti i controlli superati"))

(defun classify-baseline-result (text exit)
  "Una baseline è OK solo con exit zero, smoke esatto e completamento esatto."
  (cond ((compilation-failure-p text) (values :invalid :compilation-failure))
        ((or (not (integerp exit)) (not (zerop exit))) (values :invalid :baseline-exit))
        ((not (smoke-started-p text)) (values :invalid :before-smoke))
        ((not (build-completed-p text)) (values :invalid :missing-build-completion))
        (t (values :ok nil))))

(defun classify-result (text exit)
  "Solo errore runtime dopo smoke rileva il mutante; gli altri guasti sono INVALID."
  (cond ((compilation-failure-p text) (values :invalid :compilation-failure))
        ((or (not (integerp exit)) (not (smoke-started-p text)))
         (values :invalid :before-smoke))
        ((zerop exit) (if (build-completed-p text) (values :survived nil)
                         (values :invalid :missing-build-completion)))
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
  "Verifica prima sostituzione, classificazioni e applicabilità al codec congelato."
  (let* ((smoke "ok    ARCDOCDB:*VERSION* è una stringa")
         (completion "build e test: nessun avviso, tutti i controlli superati")
         (full (format nil "~A~%~A~%" smoke completion))
         (backtrace (format nil "0: (SEARCH ~S TEST-LOG)" smoke)))
    (unless (and (string= "xAxB" (substitute-first "xBxB" "B" "A"))
                 (detected-p smoke 1) (not (detected-p smoke 0))
                 (not (detected-p "compilation aborted" 1))
                 (not (detected-p (format nil "~A~%compilation aborted" smoke) 1))
                 (not (detected-p (format nil "~A~%COMPILE-FILE-ERROR" smoke) 1))
                 (not (detected-p (format nil "~A~%COMPILE-FILE-WARNED" smoke) 1))
                 (not (detected-p backtrace 1))
                 (not (detected-p (concatenate 'string "  " smoke) 1))
                 (not (detected-p (concatenate 'string smoke " citato") 1))
                 (eq :ok (classify-baseline-result full 0))
                 (eq :invalid (classify-baseline-result smoke 0))
                 (eq :invalid (classify-baseline-result completion 0))
                 (eq :invalid (classify-baseline-result full nil))
                 (eq :invalid (classify-baseline-result full 1))
                 (eq :invalid (classify-baseline-result
                               (format nil "~Acompilation aborted" full) 0))
                 (eq :invalid (classify-baseline-result
                               (format nil "~A~%0: (SEARCH ~S TEST-LOG)" smoke completion) 0))
                 (eq :invalid (classify-baseline-result
                               (format nil "~A~%  ~A" smoke completion) 0))
                 (eq :invalid (classify-baseline-result
                               (format nil "~A~%~A citato" smoke completion) 0))
                 (eq :survived (classify-result full 0))
                 (eq :invalid (classify-result smoke 0))
                 (eq :invalid (classify-result backtrace 1))
                 (eq :invalid (classify-result "compilation aborted" 1))
                 (eq :invalid (classify-result "runtime prima dello smoke" 1)))
      (error "Mutazioni CBOR: self-test di sostituzione/classificazione fallito.")))
  (esigi-target-invalido (lambda () (substitute-first "abc" "Z" "A")) :assente)
  (esigi-target-invalido (lambda () (unique-position "xBxB" "B")) :ambiguo)
  (esigi-target-invalido (lambda () (unique-position "abc" "Z")) :assente)
  (validate-mutants)
  (list :status :ok :substitution :first-only :classification :after-exact-smoke-line
        :dispatch (dispatch-self-test)
        :backtrace-marker :invalid
        :invalid-targets '(:missing :ambiguous) :compilation-failure :invalid
        :baseline-completion :exact-build-end-line :missing-baseline-completion :invalid
        :zero-exit-without-completion :invalid
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
  (let ((runner (merge-pathnames "tools/cbor-minimal-isolated-build.lisp" directory)))
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
        (uiop:run-program '("sbcl" "--noinform" "--no-userinit" "--no-sysinit"
                            "--disable-debugger" "--script" "tools/cbor-minimal-isolated-build.lisp")
                          :directory directory :output log :error-output :output
                          :ignore-error-status t)
      (declare (ignore out err))
      (values (read-text log) exit log))))

(defun run-baseline (directory)
  "La copia invariata deve completare smoke e test con exit zero prima dei mutanti."
  (copy-test-system directory)
  (multiple-value-bind (text exit log) (execute-copy directory)
    (multiple-value-bind (result diagnostic) (classify-baseline-result text exit)
      (list :status result :exit-code exit :log (namestring log) :diagnostic diagnostic))))

(defun preserve-setup-error (log condition)
  "Conserva anche la diagnostica di setup, senza troncare un log eventualmente già scritto."
  (with-open-file (stream log :direction :output :if-exists :append :if-does-not-exist :create
                              :external-format :utf-8)
    (format stream "~&Errore di infrastruttura della campagna: ~A~%" condition)))

(defun run-mutant (mutant directory)
  "Conserva copia e log anche in caso di sopravvivenza, errore di setup o compilazione."
  (destructuring-bind (path name before after) mutant
    (let ((log (merge-pathnames "test.log" directory)))
      (handler-case
          (progn
            (copy-test-system directory)
            (let* ((source (merge-pathnames path directory)) (text (read-text source)))
              (unique-position text before)
              (with-open-file (stream source :direction :output :if-exists :supersede
                                            :external-format :utf-8)
                (write-string (substitute-first text before after) stream)))
            (multiple-value-bind (text exit path-log) (execute-copy directory)
              (multiple-value-bind (result diagnostic) (classify-result text exit)
                (list :name name :source-file path :detected (eq result :detected) :exit-code exit
                      :result result :diagnostic diagnostic :log (namestring path-log)))))
        (error (condizione)
          (preserve-setup-error log condizione)
          (list :name name :source-file path :detected nil :exit-code nil :result :invalid
                :diagnostic :infrastructure-error :detail (princ-to-string condizione)
                :log (namestring log)))))))

(defun save-report (report directory)
  "Aggiorna solo il report della directory esclusiva; nessun risultato tentato viene perduto."
  (when directory
    (with-open-file (stream (merge-pathnames "report.lisp" directory)
                           :direction :output :if-exists :supersede :if-does-not-exist :create)
      (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))))

(defun initial-report (before)
  "Rapporto privato inizialmente header; solo MAIN seleziona l'altro catalogo."
  (list :schema-version 1 :kind :cbor-minimal-mutations :status :running
        :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
        :source-fingerprints-before before
        :targets (loop for (path name old new) in *mutants*
                       collect (list :source-file path :name name :before old :after new))
        :limits '(:targeted-mutants-only :bounded-minimum-header-tests
                  :compile-failure-not-detection :no-materialized-document-or-semantic-tag-profile
                  :no-durability-engine-or-release-qualification)))

(defun main ()
  "Self-test o otto copie nuove; plist finale e exit nonzero per campagna non valida."
  (let* ((args (rest sb-ext:*posix-argv*)) (before (fingerprints)) (directory nil)
         (*mutants* *mutants*) (action nil) (output nil) (group :header)
         (report (initial-report before)))
    (handler-case
        (progn
          (multiple-value-setq (group action output) (parse-options args))
          (when (eq group :scan)
            (setf *mutants* *scan-mutants* (getf report :kind) :cbor-minimal-scan-mutations
                  (getf report :limits) '(:targeted-scan-mutants-only :bounded-minimal-structure-tests
                                         :compile-failure-not-detection :full-asdf-private-baseline
                                         :no-engine-or-release-qualification)))
          (setf (getf report :campaign-group) group
                (getf report :targets)
                (loop for (path name old new) in *mutants*
                      collect (list :source-file path :name name :before old :after new)))
          (setf (getf report :self-test) (self-test))
          (when (eq action :run)
            (setf directory (new-directory output))
            (save-report report directory)
            (setf (getf report :baseline)
                  (run-baseline (new-directory (merge-pathnames "baseline/" directory))))
            (save-report report directory)
            (unless (eq (getf (getf report :baseline) :status) :ok)
              (error "Mutazioni CBOR: baseline invariata non riuscita."))
            (loop for mutant in *mutants* for i from 0
                  do (let* ((child (new-directory (merge-pathnames (format nil "~D/" i) directory)))
                            (result (run-mutant mutant child)))
                       (setf (getf report :mutants) (append (getf report :mutants) (list result)))
                       (save-report report directory)))
            (unless (and (= 8 (length (getf report :mutants)))
                         (every (lambda (result) (getf result :detected)) (getf report :mutants)))
              (error "Mutazioni CBOR: sopravvivenza o errore prima dello smoke.")))
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
