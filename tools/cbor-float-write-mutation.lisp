;;;; Mutazioni della scrittura float raw CBOR in copie isolate; checkout immutato.
;;;; Uso: --self-test | --run directory-nuova/.
;;; REQ: REQ-CBR-004 REQ-AFF-004 REQ-AFF-008
(require :asdf)
(require :sb-md5)
(require :sb-posix)
(defpackage #:arcdocdb.cbor-float-write.mutation (:use #:cl))
(in-package #:arcdocdb.cbor-float-write.mutation)
(declaim (optimize (safety 3) (debug 2)))

;;; Nomi preregistrati prima del prodotto; frammenti allineati solo al prodotto congelato.
;;; Ogni sostituzione richiede una sola occorrenza; il prodotto reale resta immutato.
(defparameter *planned-mutant-names*
  '("omit-single-reduction" "omit-double-reduction" "half-sign-lost"
    "half-normal-fraction" "single-subnormal" "physical-capacity"
    "wrong-float-lead" "extra-return-value"))
(defparameter *catalogue-source-blob* "03c6aed61e2c243d8b1a6c4332ce1837c4e9a77c")
(defparameter *catalogue-source-files*
  '(("src/codec/cbor-float-narrow.lisp" "cd5749edc0a757ee3a5b470eda566a6685d32fd8")
    ("src/codec/cbor-float-write.lisp" "03c6aed61e2c243d8b1a6c4332ce1837c4e9a77c")))
(defparameter *mutants*
  '(("src/codec/cbor-float-write.lisp" "omit-single-reduction" "(when (and (= chosen-ai 26) (binary32-accorciabile-cbor-p lo))" "(when (and (= chosen-ai 26) (binary32-accorciabile-cbor-p lo) nil)")
    ("src/codec/cbor-float-write.lisp" "omit-double-reduction" "(when (and (= chosen-ai 27) (binary64-accorciabile-cbor-p hi lo))" "(when (and (= chosen-ai 27) (binary64-accorciabile-cbor-p hi lo) nil)")
    ("src/codec/cbor-float-narrow.lisp" "half-sign-lost" "(result (logior (ash sign 15) body))" "(result (logior (ash sign 14) body))")
    ("src/codec/cbor-float-narrow.lisp" "half-normal-fraction" "((<= 113 exponent 142)
                      (logior (ash (- exponent 112) 10) (ash fraction -13)))" "((<= 113 exponent 142)
                      (logior (ash (- exponent 112) 10) (ash fraction -14)))")
    ("src/codec/cbor-float-narrow.lisp" "single-subnormal" "(let ((result (if (< shift 32)
                    (logior (ash high (- 32 shift)) (ash low (- shift)))
                    (ash high (- 32 shift)))))" "(let ((result (ash (if (< shift 32)
                         (logior (ash high (- 32 shift)) (ash low (- shift)))
                         (ash high (- 32 shift))) -1)))")
    ("src/codec/cbor-float-write.lisp" "physical-capacity" "(when (> size span)" "(when (> size (max span (- (length (the octets buffer)) (the index start))))")
    ("src/codec/cbor-float-write.lisp" "wrong-float-lead" "(logior #xe0 chosen-ai)" "(logior #xc0 chosen-ai)")
    ("src/codec/cbor-float-write.lisp" "extra-return-value" "(declaim (ftype (function (t t t t t t) (values index &optional)) scrivi-float-cbor-minimo))
(defun scrivi-float-cbor-minimo (buffer start end ai high low)
  \"Pre: simple u8 esclusivo, span half-open e bit IEEE AI25/26/27 in HIGH/LOW.
Post: un solo NEXT, 3/5/9 byte BE minimi; fuori [START,NEXT) intero array invariato.
Preflight range/AI/HIGH/LOW/coerenza/capacita prima di scrivere; INVALID-ARGUMENT
oppure RESOURCE-EXHAUSTED :cbor-float-capacity, offset NIL e array intatto.
INVARIANT-VIOLATION interno senza rollback; proprietario fail-stop.
Nessun float/u64/AST, heap previsto, attesa, I/O o pubblicazione atomica/durevole;
budget e profilo documentale superiori, al massimo nove byte.\"
  (let ((span (check-float-cbor-range buffer start end ai)))
    (multiple-value-bind (hi lo) (check-float-cbor-words ai high low)
      (multiple-value-bind (chosen-ai chosen-hi chosen-lo size) (seleziona-float-cbor ai hi lo)
        (when (> size span)
          (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-float-capacity))
        (let* ((bytes (the octets buffer)) (begin (the index start)) (limit (the index end))
               (next (+ begin size)) (cursor (1+ begin)))
          (declare (type index next cursor))
          (unless (<= begin cursor next limit)
            (error 'invariant-violation :reason :cbor-float-write-target-span))
          (setf (aref bytes begin) (logior #xe0 chosen-ai))
          (when (= size 9)
            (setf cursor (scrivi-parola-header-cbor bytes cursor next chosen-hi 4)))
          (setf cursor (scrivi-parola-header-cbor bytes cursor next chosen-lo
                                                (if (= size 3) 2 4)))
          (unless (= cursor next)
            (error 'invariant-violation :reason :cbor-float-write-progress))
          (values next))))))
" "(declaim (ftype (function (t t t t t t) (values index null &optional)) scrivi-float-cbor-minimo))
(defun scrivi-float-cbor-minimo (buffer start end ai high low)
  \"Pre: simple u8 esclusivo, span half-open e bit IEEE AI25/26/27 in HIGH/LOW.
Post: un solo NEXT, 3/5/9 byte BE minimi; fuori [START,NEXT) intero array invariato.
Preflight range/AI/HIGH/LOW/coerenza/capacita prima di scrivere; INVALID-ARGUMENT
oppure RESOURCE-EXHAUSTED :cbor-float-capacity, offset NIL e array intatto.
INVARIANT-VIOLATION interno senza rollback; proprietario fail-stop.
Nessun float/u64/AST, heap previsto, attesa, I/O o pubblicazione atomica/durevole;
budget e profilo documentale superiori, al massimo nove byte.\"
  (let ((span (check-float-cbor-range buffer start end ai)))
    (multiple-value-bind (hi lo) (check-float-cbor-words ai high low)
      (multiple-value-bind (chosen-ai chosen-hi chosen-lo size) (seleziona-float-cbor ai hi lo)
        (when (> size span)
          (error 'arcdocdb.conditions:resource-exhausted :reason :cbor-float-capacity))
        (let* ((bytes (the octets buffer)) (begin (the index start)) (limit (the index end))
               (next (+ begin size)) (cursor (1+ begin)))
          (declare (type index next cursor))
          (unless (<= begin cursor next limit)
            (error 'invariant-violation :reason :cbor-float-write-target-span))
          (setf (aref bytes begin) (logior #xe0 chosen-ai))
          (when (= size 9)
            (setf cursor (scrivi-parola-header-cbor bytes cursor next chosen-hi 4)))
          (setf cursor (scrivi-parola-header-cbor bytes cursor next chosen-lo
                                                (if (= size 3) 2 4)))
          (unless (= cursor next)
            (error 'invariant-violation :reason :cbor-float-write-progress))
          (values next nil))))))
")))
;;; Extra arita: unico frammento pubblico DECLAIM + DEFUN nella sola copia;
;;; FTYPE dichiara il secondo NIL. Un difetto runtime, nessun avviso mascherato.

(define-condition invalid-options (error)
  ((arguments :initarg :arguments :reader invalid-options-arguments))
  (:report (lambda (condition stream)
             (format stream "Opzioni mutazioni CBOR invalide: ~S."
                     (invalid-options-arguments condition)))))

(defun parse-options (arguments)
  "Dispatcher puro: self-test oppure run con directory; rifiuto prima di creare output."
  (cond ((equal arguments '("--self-test")) (values :self-test nil))
        ((and (= 2 (length arguments)) (string= (first arguments) "--run"))
         (values :run (second arguments)))
        (t (error 'invalid-options :arguments arguments))))

(defun dispatch-self-test ()
  "Due chiamate valide e sei negative; nessun I/O o directory creata."
  (dolist (fixture '((("--self-test") (:self-test nil))
                     (("--run" "new/") (:run "new/"))))
    (unless (equal (second fixture) (multiple-value-list (parse-options (first fixture))))
      (error "Dispatcher scrittura CBOR: chiamata valida interpretata diversamente.")))
  (let ((negative '(nil ("--run") ("--self-test" "extra") ("--run" "x" "extra")
                    ("--unknown") ("--scan" "--self-test"))))
    (dolist (arguments negative)
      (let ((rejected nil))
        (handler-case (parse-options arguments)
          (invalid-options () (setf rejected t)))
        (unless rejected (error "Dispatcher scrittura CBOR accetta ~S." arguments))))
    (list :status :ok :valid 2 :negative-rejected (length negative)
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
  (loop for file in (append (source-files) '(#p"tools/cbor-float-write-mutation.lisp"))
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
  (unless (and (stringp *catalogue-source-blob*) (= 40 (length *catalogue-source-blob*))
               (= 8 (length *mutants*))
               (equal *planned-mutant-names* (mapcar #'second *mutants*)))
    (error "Catalogo mutazioni float CBOR non allineato al prodotto congelato."))
  (dolist (mutant *mutants*)
    (destructuring-bind (path name before after) mutant
      (unless (and (assoc path *catalogue-source-files* :test #'string=)
                   (stringp before) (plusp (length before))
                   (stringp after) (not (string= before after)))
        (error "Mutazione float CBOR ~A: sostituzione fuori catalogo." name))
      (handler-case (unique-position (read-text path) before)
        (target-invalido (condizione)
          (error "Mutazione CBOR ~A in ~A: ~A." name path condizione)))))
  nil)

(defun compilation-failure-p (text)
  "Avvisi o diagnostiche del compilatore invalidano la copia, mai un rilevamento."
  (or (search "compilation aborted" text :test #'char-equal)
      (search "COMPILE-FILE-ERROR" text :test #'char-equal)
      (search "COMPILE-FILE-WARNED" text :test #'char-equal)
      (search "WARNING:" text :test #'char-equal)
      (search "STYLE-WARNING:" text :test #'char-equal)))

(defun line-position (text expected)
  "Posizione di riga esatta; ammette solo CR del terminatore CRLF, non citazioni."
  (loop with start = 0
        for end = (position #\Newline text :start start)
        for stop = (or end (length text))
        for line = (string-right-trim '(#\Return) (subseq text start stop))
        when (string= line expected) return start
        while end do (setf start (1+ end))))

(defun smoke-position (text)
  "Lo smoke deve essere una riga esatta precedente al rifiuto runtime."
  (line-position text "ok    ARCDOCDB:*VERSION* è una stringa"))

(defun completion-position (text)
  "Fine della build completa su riga esatta, non stringa citata nel backtrace."
  (line-position text "build e test: nessun avviso, tutti i controlli superati"))

(defun smoke-started-p (text)
  "Presenza del marker smoke esatto, anche se posto in posizione zero."
  (not (null (smoke-position text))))

(defun build-completed-p (text)
  "Presenza del marker di fine esatto."
  (not (null (completion-position text))))

(defun unhandled-position (text)
  "Accetta il solo marker SBCL a inizio riga, non citato dopo altri caratteri."
  (loop with start = 0
        for end = (position #\Newline text :start start)
        for stop = (or end (length text))
        when (and (<= (+ start 10) stop)
                  (string= "Unhandled " text :start2 start :end2 (+ start 10)))
          return start
        while end do (setf start (1+ end))))

(defun frame-start-p (line)
  "Inizio frame SBCL numerico N: (, senza accettare marker citati o testo libero."
  (let ((colon (position #\: line)))
    (and colon (plusp colon) (< (+ colon 2) (length line))
         (every #'digit-char-p (subseq line 0 colon))
         (string= ": (" line :start2 colon :end2 (+ colon 3)))))

(defun corpus-backtrace-p (text unhandled)
  "Richiede namespace e REQ-CBR-004 nello stesso frame, anche stampato su più righe."
  (let ((frame nil))
    (flet ((corpus-p (lines)
             (let ((body (format nil "~{~A~%~}" (reverse lines))))
               (and (search "ARCDOCDB.CBOR.FLOAT.WRITE.TESTS::" body)
                    (search "REQ-CBR-004" body)))))
      (dolist (line (uiop:split-string (subseq text unhandled) :separator '(#\Newline)))
        (when (frame-start-p line)
          (when (and frame (corpus-p frame)) (return-from corpus-backtrace-p t))
          (setf frame nil))
        (when (or frame (frame-start-p line)) (push line frame)))
      (not (null (and frame (corpus-p frame)))))))

(defun classify-baseline-result (text exit &optional signal)
  "Baseline OK solo dopo smoke e fine ordinati, exit zero e assenza di avvisi/rifiuti."
  (let ((smoke (smoke-position text)) (completion (completion-position text)))
    (cond (signal (values :worker-error :process-signal))
          ((and (integerp exit) (not (zerop exit)) completion)
           (values :worker-error :after-build-completion))
          ((compilation-failure-p text) (values :invalid :compilation-failure))
          ((or (not (integerp exit)) (not (zerop exit))) (values :invalid :baseline-exit))
          ((null smoke) (values :invalid :before-smoke))
          ((null completion) (values :invalid :missing-build-completion))
          ((>= smoke completion) (values :invalid :reversed-build-markers))
          ((unhandled-position text) (values :invalid :unexpected-unhandled))
          (t (values :ok nil)))))

(defun classify-result (text exit &optional signal)
  "Rilevamento solo con smoke prima di Unhandled e frame REQ-CBR-004 del corpus."
  (let ((smoke (smoke-position text)) (completion (completion-position text))
        (unhandled (unhandled-position text)))
    (cond (signal (values :worker-error :process-signal))
          ((and (integerp exit) (not (zerop exit)) completion)
           (values :worker-error :after-build-completion))
          ((compilation-failure-p text) (values :invalid :compilation-failure))
          ((or (not (integerp exit)) (null smoke)) (values :invalid :before-smoke))
          ((zerop exit)
           (multiple-value-bind (status reason) (classify-baseline-result text exit)
             (if (eq status :ok) (values :survived nil) (values :invalid reason))))
          ((null unhandled) (values :invalid :missing-unhandled))
          ((>= smoke unhandled) (values :invalid :reversed-runtime-markers))
          ((not (corpus-backtrace-p text unhandled)) (values :invalid :unrelated-runtime))
          (t (values :detected nil)))))

(defun detected-p (text exit &optional signal)
  "Rilevato solo da un rifiuto runtime attribuito al corpus congelato."
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

(defun classification-fixtures ()
  "Dati sintetici: ordine e origine, citazioni, warning, segnali e guasti dopo fine."
  (let* ((smoke "ok    ARCDOCDB:*VERSION* è una stringa")
         (end "build e test: nessun avviso, tutti i controlli superati")
         (frame "0: (ARCDOCDB.CBOR.FLOAT.WRITE.TESTS::CFW-ACCEPT \"REQ-CBR-004\" NIL)")
         (failure (format nil "Unhandled SIMPLE-ERROR~%~A~%" frame))
         (runtime (format nil "~A~%~A" smoke failure))
         (full (format nil "~A~%~A~%" smoke end))
         (cases (list
                 (list runtime 1 nil '(:detected nil))
                 (list full 0 nil '(:survived nil))
                 (list runtime 0 nil '(:invalid :missing-build-completion))
                 (list runtime nil nil '(:invalid :before-smoke))
                 (list smoke 1 nil '(:invalid :missing-unhandled))
                 (list failure 1 nil '(:invalid :before-smoke))
                 (list (format nil "~A~A~%" failure smoke) 1 nil
                       '(:invalid :reversed-runtime-markers))
                 (list (format nil "~A~%Unhandled SIMPLE-ERROR~%0: (UNRELATED)~%" smoke) 1 nil
                       '(:invalid :unrelated-runtime))
                 (list (format nil "~A~%Unhandled SIMPLE-ERROR~%0: (REQ-CBR-004)~%" smoke) 1 nil
                       '(:invalid :unrelated-runtime))
                 (list (format nil "~A~%Unhandled SIMPLE-ERROR~%0: (ARCDOCDB.CBOR.FLOAT.WRITE.TESTS::OTHER)~%"
                               smoke) 1 nil '(:invalid :unrelated-runtime))
                 (list (format nil "; ~A~%~A" smoke failure) 1 nil '(:invalid :before-smoke))
                 (list (format nil "  ~A~%~A" smoke failure) 1 nil '(:invalid :before-smoke))
                 (list (format nil "~A citato~%~A" smoke failure) 1 nil '(:invalid :before-smoke))
                 (list (format nil "0: (SEARCH ~S LOG)~%~A" smoke failure) 1 nil
                       '(:invalid :before-smoke))
                 (list (format nil "~A~%; Unhandled SIMPLE-ERROR~%~A" smoke frame) 1 nil
                       '(:invalid :missing-unhandled))
                 (list (format nil "~A~%WARNING: foo~%~A" smoke failure) 1 nil
                       '(:invalid :compilation-failure))
                 (list (format nil "~A~%STYLE-WARNING: foo~%~A" smoke failure) 1 nil
                       '(:invalid :compilation-failure))
                 (list (format nil "~Acompilation aborted~%" runtime) 1 nil
                       '(:invalid :compilation-failure))
                 (list (format nil "~ACOMPILE-FILE-ERROR~%" runtime) 1 nil
                       '(:invalid :compilation-failure))
                 (list (format nil "~ACOMPILE-FILE-WARNED~%" runtime) 1 nil
                       '(:invalid :compilation-failure))
                 (list full 7 nil '(:worker-error :after-build-completion))
                 (list (format nil "~AWARNING: x~%" full) 7 nil
                       '(:worker-error :after-build-completion))
                 (list runtime 1 sb-posix:sigkill '(:worker-error :process-signal))
                 (list full 0 sb-posix:sigkill '(:worker-error :process-signal))
                 (list (format nil "~A~C~%Unhandled SIMPLE-ERROR~C~%~A~C~%"
                               smoke #\Return #\Return frame #\Return)
                       1 nil '(:detected nil))
                 (list (format nil "~A~%Unhandled SIMPLE-ERROR~%0: (ARCDOCDB.CBOR.FLOAT.WRITE.TESTS::CFW-ACCEPT~%     ~S NIL)~%"
                               smoke "REQ-CBR-004") 1 nil '(:detected nil))
                 (list (format nil "~A~%Unhandled SIMPLE-ERROR~%0: (ARCDOCDB.CBOR.FLOAT.WRITE.TESTS::CFW-ACCEPT NIL)~%1: (UNRELATED ~S)~%"
                               smoke "REQ-CBR-004") 1 nil '(:invalid :unrelated-runtime))
                 (list (format nil "~A~%Unhandled SIMPLE-ERROR~%; ~A~%" smoke frame) 1 nil
                       '(:invalid :unrelated-runtime)))))
    (dolist (case cases)
      (unless (equal (fourth case) (multiple-value-list
                                    (classify-result (first case) (second case) (third case))))
        (error "Classificatore float CBOR: caso non rispettato ~S." case)))
    (dolist (case (list (list full 0 nil '(:ok nil))
                       (list (format nil "~A~%~A~%" end smoke) 0 nil
                             '(:invalid :reversed-build-markers))
                       (list runtime 0 nil '(:invalid :missing-build-completion))
                       (list (format nil "~A~A" full failure) 0 nil
                             '(:invalid :unexpected-unhandled))
                       (list full 7 nil '(:worker-error :after-build-completion))
                       (list full 0 sb-posix:sigkill '(:worker-error :process-signal))
                       (list (format nil "~A~C~%~A~C~%" smoke #\Return end #\Return)
                             0 nil '(:ok nil))))
      (unless (equal (fourth case) (multiple-value-list
                                    (classify-baseline-result
                                     (first case) (second case) (third case))))
        (error "Baseline float CBOR: caso non rispettato ~S." case)))
    (list :status :ok :mutant-fixtures (length cases) :baseline-fixtures 7
          :exact-marker-order-required t :corpus-req-frame-required t
          :warning-or-unrelated-runtime-rejected t :reason-specific-rejection t)))

(defun self-test ()
  "Sostituzione unica, motivi specifici, classificazioni e trasporto child conservato."
  (unless (string= "xAxB" (substitute-first "xBxB" "B" "A"))
    (error "Mutazioni float CBOR: sostituzione fuori dalla prima occorrenza."))
  (esigi-target-invalido (lambda () (substitute-first "abc" "Z" "A")) :assente)
  (esigi-target-invalido (lambda () (unique-position "xBxB" "B")) :ambiguo)
  (esigi-target-invalido (lambda () (unique-position "abc" "Z")) :assente)
  (validate-mutants)
  (list :status :ok :substitution :first-only :dispatch (dispatch-self-test)
        :classification (classification-fixtures)
        :invalid-targets '(:missing :ambiguous)
        :signal-fixture-report (self-test-process-signal)
        :applicable-mutants (length *mutants*)))

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
  (let ((runner (merge-pathnames "tools/cbor-float-write-isolated-build.lisp" directory)))
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
                     "--disable-debugger" "--script" "tools/cbor-float-write-isolated-build.lisp")
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
  (let ((runner (merge-pathnames "tools/cbor-float-write-isolated-build.lisp" directory)))
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
                     (format nil "spikes/out/~D-cbor-float-write-worker-self-test-~D/"
                             (get-universal-time) (sb-posix:getpid))))
         (report (list :schema-version 1 :kind :process-signal-self-test :scope :cbor-float-write
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
    (format t "~&Scrittura CBOR: self-test worker superato; ~A~%"
            (merge-pathnames "report.lisp" directory))
    (namestring (merge-pathnames "report.lisp" directory))))

(defun initial-report (before)
  "Rapporto del solo catalogo congelato della scrittura, prima di qualunque child."
  (list :schema-version 1 :kind :cbor-float-write-mutations :status :running
        :worker-errors 0 :mutants nil
        :catalogue-source-blob *catalogue-source-blob*
        :catalogue-source-files *catalogue-source-files*
        :planned-mutant-names *planned-mutant-names*
        :catalogue-status (if (and *catalogue-source-blob* (= 8 (length *mutants*)))
                              :aligned :awaiting-frozen-product)
        :recorded-at (get-universal-time) :sbcl (lisp-implementation-version)
        :source-fingerprints-before before
        :targets (loop for (path name old new) in *mutants*
                       collect (list :source-file path :name name :before old :after new))
        :limits '(:targeted-mutants-only :raw-ieee-words
                  :compile-failure-not-detection :warning-not-detection
                  :ordered-smoke-and-runtime-markers :req-in-corpus-backtrace-frame
                  :full-asdf-private-baseline
                  :nan-sign-and-significand-preserved
                  :no-durability-engine-or-release-qualification)))

(defun main ()
  "Self-test o otto copie nuove; plist finale e exit nonzero per campagna non valida."
  (let* ((args (rest sb-ext:*posix-argv*)) (before (fingerprints)) (directory nil)
         (action nil) (output nil)
         (report (initial-report before)))
    (handler-case
        (progn
          (multiple-value-setq (action output) (parse-options args))
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
                       (setf report (append-mutation-result report result))
                       (save-report report directory)))
            (unless (and (= 8 (length (getf report :mutants)))
                         (every (lambda (result) (getf result :detected)) (getf report :mutants)))
              (error "Mutazioni CBOR: sopravvivenza, worker-error o errore prima dello smoke.")))
          (setf (getf report :status) :ok))
      (error (condizione) (setf (getf report :status) :failed
                               (getf report :diagnostic)
                               (format nil "tools/cbor-float-write-mutation.lisp COD-61: ~A" condizione))))
    (let ((after (fingerprints)))
      (setf (getf report :source-fingerprints-after) after
            (getf report :source-consistency) (if (equal before after) :stable :changed))
      (when (and (eq (getf report :status) :ok) (not (equal before after)))
        (setf (getf report :status) :source-changed
              (getf report :diagnostic)
              "tools/cbor-float-write-mutation.lisp COD-61: sorgenti cambiati durante l'esecuzione.")))
    (save-report report directory)
    (let ((*print-readably* t)) (write report :pretty t) (terpri))
    (unless (eq (getf report :status) :ok) (sb-ext:exit :code 1))))

(main)
