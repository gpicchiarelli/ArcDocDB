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

(defun classify-baseline-result (text exit &optional signal)
  "Una baseline è OK solo con exit zero; segnali e guasti dopo completamento sono worker."
  (cond (signal (values :worker-error :process-signal))
        ((and (integerp exit) (not (zerop exit)) (build-completed-p text))
         (values :worker-error :after-build-completion))
        ((compilation-failure-p text) (values :invalid :compilation-failure))
        ((or (not (integerp exit)) (not (zerop exit))) (values :invalid :baseline-exit))
        ((not (smoke-started-p text)) (values :invalid :before-smoke))
        ((not (build-completed-p text)) (values :invalid :missing-build-completion))
        (t (values :ok nil))))

(defun classify-result (text exit &optional signal)
  "Solo errore runtime dopo smoke rileva il mutante; segnali e guasti finali sono worker."
  (cond (signal (values :worker-error :process-signal))
        ((and (integerp exit) (not (zerop exit)) (build-completed-p text))
         (values :worker-error :after-build-completion))
        ((compilation-failure-p text) (values :invalid :compilation-failure))
        ((or (not (integerp exit)) (not (smoke-started-p text)))
         (values :invalid :before-smoke))
        ((zerop exit) (if (build-completed-p text) (values :survived nil)
                         (values :invalid :missing-build-completion)))
        (t (values :detected nil))))

(defun detected-p (text exit &optional signal)
  "Rilevato solo con exit nonzero dopo smoke, senza segnale o completamento precedente."
  (eq :detected (classify-result text exit signal)))

(defun esigi-target-invalido (funzione motivo)
  "Verifica il self-test dei bersagli, distinguendo assenza e ambiguità."
  (let ((rilevato nil))
    (handler-case (funcall funzione)
      (target-invalido (condizione)
        (unless (eq motivo (motivo-target condizione)) (error condizione))
        (setf rilevato t)))
    (unless rilevato (error "Self-test: bersaglio invalido non rilevato."))))

(declaim (ftype (function () (values string &optional)) self-test-process-signal))

(defun self-test ()
  "Verifica sostituzione, classificazioni, processi figli e applicabilità al codec congelato."
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
                 (not (detected-p (format nil "; ~A~%" smoke) 1))
                 (not (detected-p (concatenate 'string "  " smoke) 1))
                 (not (detected-p (concatenate 'string smoke " citato") 1))
                 (eq :ok (classify-baseline-result full 0))
                 (eq :invalid (classify-baseline-result smoke 0))
                 (eq :invalid (classify-baseline-result completion 0))
                 (eq :invalid (classify-baseline-result full nil))
                 (equal '(:worker-error :after-build-completion)
                        (multiple-value-list (classify-baseline-result full 1)))
                 (eq :worker-error (classify-baseline-result completion 7))
                 (eq :invalid (classify-baseline-result
                               (format nil "~Acompilation aborted" full) 0))
                 (eq :invalid (classify-baseline-result
                               (format nil "~A~%0: (SEARCH ~S TEST-LOG)" smoke completion) 0))
                 (eq :invalid (classify-baseline-result
                               (format nil "~A~%  ~A" smoke completion) 0))
                 (eq :invalid (classify-baseline-result
                               (format nil "~A~%~A citato" smoke completion) 0))
                 (eq :survived (classify-result full 0))
                 (equal '(:worker-error :after-build-completion)
                        (multiple-value-list (classify-result full 7)))
                 (eq :worker-error (classify-result completion 7))
                 (eq :worker-error (classify-result
                                   (format nil "~Acompilation aborted~%" full) 7))
                 (eq :worker-error (classify-baseline-result
                                   (format nil "~Acompilation aborted~%" full) 7))
                 (eq :detected (classify-result
                                (format nil "~A~%0: (SEARCH ~S TEST-LOG)" smoke completion) 7))
                 (eq :detected (classify-result (format nil "~A~%; ~A~%" smoke completion) 7))
                 (eq :detected (classify-result (format nil "~A~%  ~A~%" smoke completion) 7))
                 (eq :detected (classify-result (format nil "~A~%~A citato~%" smoke completion) 7))
                 (eq :survived (classify-result
                               (format nil "~A~C~%~A~C~%" smoke #\Return completion #\Return) 0))
                 (eq :ok (classify-baseline-result
                          (format nil "~A~C~%~A~C~%" smoke #\Return completion #\Return) 0))
                 (eq :worker-error (classify-result
                                   (format nil "~A~C~%~A~C~%" smoke #\Return completion #\Return) 7))
                 (eq :worker-error (classify-baseline-result
                                   (format nil "~A~C~%~A~C~%" smoke #\Return completion #\Return) 7))
                 (equal '(:worker-error :process-signal)
                        (multiple-value-list (classify-result smoke 1 sb-posix:sigkill)))
                 (equal '(:worker-error :process-signal)
                        (multiple-value-list (classify-baseline-result smoke 1 sb-posix:sigkill)))
                 (not (detected-p smoke 1 sb-posix:sigkill))
                 (eq :worker-error (classify-result "compilation aborted" 1 sb-posix:sigkill))
                 (eq :worker-error (classify-baseline-result "compilation aborted" 1 sb-posix:sigkill))
                 (eq :worker-error (classify-result full 0 sb-posix:sigkill))
                 (eq :worker-error (classify-baseline-result full 0 sb-posix:sigkill))
                 (eq :invalid (classify-result smoke nil))
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
        :after-completion-failure :worker-error :os-signal :worker-error
        :signal-fixture-report (self-test-process-signal)
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

(defun execute-runner (directory)
  "Conserva log, exit code e segnale OS del runner preparato, compresa la fixture."
  (let* ((log (merge-pathnames "test.log" directory))
         (process (uiop:launch-program
                   '("sbcl" "--noinform" "--no-userinit" "--no-sysinit"
                     "--disable-debugger" "--script" "tools/cbor-minimal-isolated-build.lisp")
                   :directory directory :output log :error-output :output)))
    (multiple-value-bind (exit signal) (uiop:wait-process process)
      (values (read-text log) exit log signal))))

(defun execute-copy (directory)
  "Esegue la build rigorosa della copia con cache locale e log conservato."
  (isolated-runner directory)
  (execute-runner directory))

(defun preserve-setup-error (log condition)
  "Conserva anche la diagnostica di setup, senza troncare un log eventualmente già scritto."
  (with-open-file (stream log :direction :output :if-exists :append :if-does-not-exist :create
                              :external-format :utf-8)
    (format stream "~&Errore di infrastruttura della campagna: ~A~%" condition)))

(defun run-baseline (directory)
  "Conserva anche guasti di setup/trasporto; nessun exit o segnale viene inventato."
  (let ((log (merge-pathnames "test.log" directory)))
    (handler-case
        (progn
          (copy-test-system directory)
          (multiple-value-bind (text exit path-log signal) (execute-copy directory)
            (multiple-value-bind (result diagnostic) (classify-baseline-result text exit signal)
              (list :status result :result result :exit-code exit :signal signal
                    :log (namestring path-log) :diagnostic diagnostic))))
      (error (condition)
        (preserve-setup-error log condition)
        (list :status :worker-error :result :worker-error :exit-code nil :signal nil
              :diagnostic :infrastructure-error :detail (princ-to-string condition)
              :log (namestring log))))))

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
            (multiple-value-bind (text exit path-log signal) (execute-copy directory)
              (multiple-value-bind (result diagnostic) (classify-result text exit signal)
                (list :name name :source-file path :detected (eq result :detected) :exit-code exit
                      :signal signal :result result :diagnostic diagnostic :log (namestring path-log)))))
        (error (condizione)
          (preserve-setup-error log condizione)
          (list :name name :source-file path :detected nil :exit-code nil :signal nil :result :worker-error
                :diagnostic :infrastructure-error :detail (princ-to-string condizione)
                :log (namestring log)))))))

(defun save-report (report directory)
  "Aggiorna solo il report della directory esclusiva; nessun risultato tentato viene perduto."
  (when directory
    (with-open-file (stream (merge-pathnames "report.lisp" directory)
                           :direction :output :if-exists :supersede :if-does-not-exist :create)
      (let ((*print-readably* t)) (write report :stream stream :pretty t) (terpri stream)))))

(defun record-baseline-result (report result)
  "Conserva la baseline e conta i suoi guasti worker prima di interrompere la campagna."
  (setf (getf report :baseline) result)
  (when (eq :worker-error (getf result :status))
    (incf (getf report :worker-errors 0)))
  report)

(defun append-mutation-result (report result)
  "Registra ogni risultato e conta i guasti worker separatamente dai mutanti rilevati."
  (setf (getf report :mutants) (append (getf report :mutants) (list result)))
  (when (eq :worker-error (getf result :result))
    (incf (getf report :worker-errors 0)))
  report)

(defun write-worker-fixture (directory mode)
  "Scrive un child che emette marker reali e termina solo se stesso, senza caricare il prodotto."
  (let ((runner (merge-pathnames "tools/cbor-minimal-isolated-build.lisp" directory)))
    (ensure-directories-exist runner)
    (with-open-file (output runner :direction :output :if-exists :error :external-format :utf-8)
      (dolist (form (append '((require :sb-posix)
                             (format t "ok    ARCDOCDB:*VERSION* è una stringa~%"))
                           (when (eq mode :completion-exit)
                             '((format t "build e test: nessun avviso, tutti i controlli superati~%")))
                           '((finish-output))
                           (ecase mode
                             (:signal '((sb-posix:kill (sb-posix:getpid) sb-posix:sigkill)))
                             (:completion-exit '((sb-ext:exit :code 7))))))
        (write form :stream output :pretty t) (terpri output)))
    (namestring runner)))

(defun execute-worker-fixture (directory mode)
  "Usa il trasporto reale; restituisce tutte le osservazioni prima delle asserzioni del parent."
  (let ((runner (write-worker-fixture directory mode)))
    (multiple-value-bind (text exit log signal) (execute-runner directory)
      (multiple-value-bind (result diagnostic) (classify-result text exit signal)
        (multiple-value-bind (baseline baseline-diagnostic) (classify-baseline-result text exit signal)
          (list :name mode :result result :detected (eq result :detected)
                :baseline-status baseline :baseline-diagnostic baseline-diagnostic
                :exit-code exit :signal signal :diagnostic diagnostic
                :runner runner :log (namestring log)))))))

(defun check-worker-fixture (entry)
  "Valida osservazioni già salvate: entrambi i classificatori rifiutano i due guasti reali."
  (let* ((mode (getf entry :name)) (text (read-text (getf entry :log)))
         (expected (ecase mode (:signal :process-signal) (:completion-exit :after-build-completion)))
         (counter-report (list :worker-errors 0)))
    (setf counter-report
          (record-baseline-result counter-report (list :status (getf entry :baseline-status))))
    (unless (and (eq :worker-error (getf entry :result))
                 (eq :worker-error (getf entry :baseline-status))
                 (eq expected (getf entry :diagnostic)) (eq expected (getf entry :baseline-diagnostic))
                 (= 1 (getf counter-report :worker-errors)) (smoke-started-p text)
                 (ecase mode
                   (:signal (and (eql (getf entry :signal) sb-posix:sigkill)
                                 (not (eql (getf entry :exit-code) 0)) (not (build-completed-p text))))
                   (:completion-exit (and (eql (getf entry :exit-code) 7)
                                          (null (getf entry :signal)) (build-completed-p text)))))
      (error "Self-test CBOR: segnale/guasto finale perso o contato come rilevamento.")))
  nil)

(defun verify-worker-fixture-report (directory report)
  "Rilegge senza read-eval: due guasti, nessun rilevamento ed exit/segnale/percorsi salvati."
  (let* ((*read-eval* nil)
         (saved (with-open-file (input (merge-pathnames "report.lisp" directory) :external-format :utf-8)
                  (let ((data (read input)))
                    (unless (eq :eof (read input nil :eof))
                      (error "Self-test CBOR: forme aggiuntive nel report."))
                    data)))
         (entries (getf saved :mutants))
         (signal-entry (first entries)) (completion-entry (second entries)))
    (unless (and (= 2 (getf saved :worker-errors)) (= 2 (length entries))
                 (equal entries (getf report :mutants))
                 (every (lambda (entry) (and (eq :worker-error (getf entry :result))
                                            (not (getf entry :detected)))) entries)
                 (eql sb-posix:sigkill (getf signal-entry :signal))
                 (not (eql 0 (getf signal-entry :exit-code)))
                 (null (getf completion-entry :signal)) (eql 7 (getf completion-entry :exit-code)))
      (error "Self-test CBOR: esiti, exit, segnale o contatori non conservati.")))
  nil)

(defun self-test-baseline-infrastructure (directory)
  "Inietta rifiuti dichiarati prima/dopo la copia; non compila prodotto o avvia altri child."
  (let ((copy-function (symbol-function 'copy-test-system))
        (execute-function (symbol-function 'execute-copy)) (paths nil))
    (unwind-protect
         (dolist (mode '(:copy :transport))
           (let* ((child (new-directory (merge-pathnames (format nil "baseline-~(~A~)/" mode) directory)))
                  (report (list :schema-version 1 :kind :baseline-infrastructure-self-test :status :running
                                :stage :setup :worker-errors 0 :injected-boundary mode)))
             (setf (symbol-function 'copy-test-system)
                   (if (eq mode :copy)
                       (lambda (target) (declare (ignore target)) (error "Fixture baseline copy refusal."))
                       (lambda (target) (declare (ignore target)) nil))
                   (symbol-function 'execute-copy)
                   (lambda (target) (declare (ignore target)) (error "Fixture baseline transport refusal.")))
             (setf report (record-baseline-result report (run-baseline child)))
             (save-report report child)
             (let ((baseline (getf report :baseline)))
               (unless (and (eq :worker-error (getf baseline :status))
                            (eq :worker-error (getf baseline :result))
                            (eq :infrastructure-error (getf baseline :diagnostic))
                            (null (getf baseline :exit-code)) (null (getf baseline :signal))
                            (= 1 (getf report :worker-errors))
                            (search "Fixture baseline" (read-text (getf baseline :log))))
                 (error "Self-test CBOR: guasto baseline senza log/esito/contatore.")))
             (setf (getf report :status) :passed (getf report :stage) :complete)
             (save-report report child)
             (push (namestring (merge-pathnames "report.lisp" child)) paths)))
      (setf (symbol-function 'copy-test-system) copy-function
            (symbol-function 'execute-copy) execute-function))
    (nreverse paths)))

(defun self-test-process-signal ()
  "Conserva runner/log/report di SIGKILL ed exit7 reali; soltanto i child vengono terminati."
  (let* ((directory (new-directory
                     (format nil "spikes/out/~D-cbor-minimal-worker-self-test-~D/"
                             (get-universal-time) (sb-posix:getpid))))
         (report (list :schema-version 1 :kind :process-signal-self-test :scope :cbor-minimal
                       :status :running :stage :runner :worker-errors 0 :mutants nil)))
    (save-report report directory)
    (handler-case
        (progn
          (dolist (mode '(:signal :completion-exit))
            (let ((entry (execute-worker-fixture
                          (new-directory (merge-pathnames (format nil "~(~A~)/" mode) directory)) mode)))
              (setf report (append-mutation-result report entry))
              (save-report report directory)
              (check-worker-fixture entry)))
          (verify-worker-fixture-report directory report)
          (setf (getf report :baseline-fixture-reports) (self-test-baseline-infrastructure directory))
          (setf (getf report :status) :passed (getf report :stage) :complete)
          (save-report report directory))
      (error (condition)
        (setf (getf report :status) :failed (getf report :diagnostic) (princ-to-string condition))
        (save-report report directory)
        (error condition)))
    (format t "~&CBOR minimo: self-test worker superato; ~A~%"
            (merge-pathnames "report.lisp" directory))
    (namestring (merge-pathnames "report.lisp" directory))))

(defun initial-report (before)
  "Rapporto privato inizialmente header; solo MAIN seleziona l'altro catalogo."
  (list :schema-version 1 :kind :cbor-minimal-mutations :status :running
        :worker-errors 0 :mutants nil
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
            (setf report (record-baseline-result
                          report (run-baseline (new-directory (merge-pathnames "baseline/" directory)))))
            (save-report report directory)
            (unless (eq (getf (getf report :baseline) :status) :ok)
              (error "Mutazioni CBOR: baseline invariata non riuscita."))
            (loop for mutant in *mutants* for i from 0
                  do (let* ((child (new-directory (merge-pathnames (format nil "~D/" i) directory)))
                            (result (run-mutant mutant child)))
                       (append-mutation-result report result)
                       (save-report report directory)))
            (unless (and (= 8 (length (getf report :mutants)))
                         (every (lambda (result) (getf result :detected)) (getf report :mutants)))
              (error "Mutazioni CBOR: sopravvivenza, worker-error o errore prima dello smoke.")))
          (setf (getf report :status) :ok))
      (error (condizione) (setf (getf report :status) :failed
                               (getf report :diagnostic)
                               (format nil "tools/cbor-minimal-mutation.lisp COD-61: ~A" condizione))))
    (let ((after (fingerprints)))
      (setf (getf report :source-fingerprints-after) after
            (getf report :source-consistency) (if (equal before after) :stable :changed))
      (when (and (eq (getf report :status) :ok) (not (equal before after)))
        (setf (getf report :status) :source-changed
              (getf report :diagnostic)
              "tools/cbor-minimal-mutation.lisp COD-61: sorgenti cambiati durante l'esecuzione.")))
    (save-report report directory)
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(main)
