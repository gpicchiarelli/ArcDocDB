;;;; Copertura diagnostica del resolver CLOSED/ACTIVE, processo e cache privati.
;;;; Uso: sbcl --script tools/get-resolver-coverage.lisp --report spikes/out/get-resolver-coverage-R1/
;;;; ACTIVE: aggiungere --suite active; il default resta CLOSED.
;;; REQ: REQ-VAL-001 REQ-AFF-002 REQ-FOR-004 REQ-CMP-007
(require :asdf)
(require :sb-cover)
(require :sb-posix)

(defpackage #:arcdocdb.get.resolver.coverage
  (:use #:cl))
(in-package #:arcdocdb.get.resolver.coverage)
(declaim (optimize (safety 3) (debug 3)))

(defparameter *closed-files*
  '("src/get-resolver/package.lisp" "src/get-resolver/types.lisp"
    "src/get-resolver/scan.lisp" "src/get-resolver/sort.lisp"
    "src/get-resolver/rows.lisp" "src/get-resolver/build.lisp"
    "src/get-resolver/read.lisp"))
(defparameter *active-files*
  '("src/get-resolver/package.lisp" "src/get-resolver/types.lisp"
    "src/get-resolver/rows.lisp" "src/get-resolver/read.lisp"
    "src/get-resolver/active-types.lisp" "src/get-resolver/active-directory.lisp"
    "src/get-resolver/active-scan.lisp" "src/get-resolver/active-build.lisp"
    "src/get-resolver/active-preflight.lisp" "src/get-resolver/active-read.lisp"))
(defconstant +state-byte-limit+ 134217728)
(defconstant +state-file-limit+ 10000)
(defconstant +state-mark-limit+ 100000)
(defconstant +source-path-limit+ 1024)

(define-condition invalid-coverage (error)
  ((reason :initarg :reason :reader coverage-reason)
   (detail :initarg :detail :reader coverage-detail))
  (:report (lambda (condition stream)
             (format stream "Copertura GET resolver ~S: ~A"
                     (coverage-reason condition) (coverage-detail condition)))))

(declaim (ftype (function (keyword string &rest t) nil) reject))
(defun reject (reason control &rest arguments)
  "Segnala formato o associazione non validi senza interpretare dati come codice."
  (error 'invalid-coverage :reason reason :detail (apply #'format nil control arguments)))

(declaim (ftype (function (keyword) list) scope-files))
(defun scope-files (scope)
  "Seleziona l'elenco esplicito dei sorgenti; nessun glob amplia lo scope."
  (ecase scope (:closed *closed-files*) (:active *active-files*)))

(declaim (ftype (function (keyword) symbol) suite-package))
(defun suite-package (scope)
  "Seleziona la sola suite da eseguire dopo il reset delle hit."
  (ecase scope
    (:closed '#:arcdocdb.get.resolver.tests)
    (:active '#:arcdocdb.get.active.tests)))

(declaim (ftype (function (keyword) string) suite-support))
(defun suite-support (scope)
  "Seleziona anche il supporto test per la verifica della cache privata."
  (ecase scope
    (:closed "tests/get-resolver/support.lisp")
    (:active "tests/get-active/support.lisp")))

(declaim (ftype (function (t (integer 0)) (integer 0)) bounded-list-size))
(defun bounded-list-size (value limit)
  "Richiede una lista propria, aciclica e con cardinalità limitata."
  (unless (listp value) (reject :state-shape "Lista richiesta."))
  (let ((size (handler-case (list-length value)
                (type-error () (reject :state-shape "Lista propria richiesta.")))))
    (unless (and size (<= size limit))
      (reject :state-shape "Lista ciclica o oltre ~D elementi." limit))
    size))

(declaim (ftype (function (pathname t) t) save-data))
(defun save-data (path data)
  "Scrive una sola forma leggibile in un file nuovo della directory posseduta."
  (with-open-file (stream path :direction :output :if-exists :error
                               :if-does-not-exist :create :external-format :utf-8)
    (with-standard-io-syntax
      (let ((*print-pretty* t)) (write data :stream stream) (terpri stream))))
  data)

(declaim (ftype (function (pathname string) pathname) fresh-directory))
(defun fresh-directory (root argument)
  "Crea esclusivamente un leaf nuovo sotto spikes/out del checkout corrente."
  (let* ((out (merge-pathnames "spikes/out/" root))
         (candidate (merge-pathnames (uiop:ensure-directory-pathname argument) root))
         (parent (uiop:pathname-parent-directory-pathname candidate))
         (leaf (car (last (pathname-directory candidate)))))
    (ensure-directories-exist out)
    (unless (and (stringp leaf) (<= 1 (length leaf) 128)
                 (every (lambda (character)
                          (or (alphanumericp character) (find character "-_"))) leaf)
                 (equal (truename parent) (truename out)))
      (reject :output-directory "Un leaf semplice sotto ~A è richiesto." out))
    (when (probe-file candidate) (reject :output-exists "Directory già esistente: ~A." candidate))
    (sb-posix:mkdir candidate #o700)
    (truename candidate)))

(declaim (ftype (function (pathname pathname keyword) t) isolate-output))
(defun isolate-output (root directory scope)
  "Mappa ricorsivamente product e tests nella sola cache FASL privata."
  (let ((destination (merge-pathnames "fasl/" directory)))
    (asdf:initialize-output-translations
     `(:output-translations
       (,(merge-pathnames "**/*.*" root) ,(merge-pathnames "**/*.*" destination))
       :ignore-inherited-configuration))
    (dolist (relative (append (scope-files scope) (list (suite-support scope))))
      (let* ((source (merge-pathnames relative root))
             (fasl (make-pathname :type "fasl" :defaults source))
             (actual (asdf:apply-output-translations fasl)))
        (unless (uiop:subpathp actual destination)
          (reject :cache-not-isolated "Cache non privata per ~A: ~A." source actual))))
    t))

(declaim (ftype (function (pathname) list) read-state))
(defun read-state (path)
  "Rilegge lo stato SB-COVER come dati, READ-EVAL NIL e EOF; nessun LOAD."
  (with-open-file (stream path :external-format :utf-8)
    (when (> (file-length stream) +state-byte-limit+)
      (reject :state-budget "Stato oltre ~D bytes." +state-byte-limit+))
    (with-standard-io-syntax
      (let* ((*read-eval* nil) (*package* (find-package '#:sb-cover))
             (eof (gensym "EOF")) (data (read stream nil eof)))
        (when (or (eq data eof) (not (eq eof (read stream nil eof))))
          (reject :state-shape "Una sola forma dati richiesta in ~A." path))
        (bounded-list-size data +state-file-limit+)
        data))))

(declaim (ftype (function (list pathname keyword) list) selected-state))
(defun selected-state (state root scope)
  "Scopre ogni sorgente del profilo soltanto al pathname esatto del checkout."
  (let ((expected (make-hash-table :test #'equal)) (found (make-hash-table :test #'equal)))
    (dolist (relative (scope-files scope))
      (setf (gethash (namestring (truename (merge-pathnames relative root))) expected) relative))
    (dolist (entry state)
      (unless (and (consp entry) (stringp (first entry)))
        (reject :state-shape "Entry con pathname stringa richiesta."))
      (when (gethash (first entry) expected)
        (when (gethash (first entry) found)
          (reject :duplicate-source "Sorgente duplicato: ~A." (first entry)))
        (setf (gethash (first entry) found) entry)))
    (loop for relative in (scope-files scope)
          for path = (namestring (truename (merge-pathnames relative root)))
          for entry = (gethash path found)
          do (unless entry (reject :missing-source "Sorgente ~A non scoperto: ~A." scope path))
          collect (cons relative entry))))

(declaim (ftype (function (cons) list) coverage-marks))
(defun coverage-marks (entry)
  "Valida le rappresentazioni SB-COVER vettori/bit e precedente lista path/stato."
  (let ((tail (rest entry)))
    (if (and (consp tail) (typep (first tail) 'simple-vector) (typep (rest tail) 'bit-vector))
        (let ((paths (first tail)) (bits (rest tail)))
          (unless (and (= (length paths) (length bits)) (<= (length paths) +state-mark-limit+))
            (reject :state-shape "Vettori path/stato non allineati o oltre il budget."))
          (loop for i below (length paths) collect (cons (svref paths i) (not (zerop (bit bits i))))))
        (progn
          (bounded-list-size tail +state-mark-limit+)
          (dolist (mark tail)
            (unless (and (consp mark) (member (cdr mark) '(nil t)))
              (reject :state-shape "Mark legacy path . booleano richiesto.")))
          tail))))

(declaim (ftype (function (t) t) check-source-path))
(defun check-source-path (path)
  "Richiede indici non negativi con eventuale direzione THEN/ELSE iniziale."
  (bounded-list-size path +source-path-limit+)
  (let ((indices (if (member (first path) '(:then :else)) (rest path) path)))
    (unless (every (lambda (value) (typep value '(integer 0))) indices)
      (reject :state-shape "Source path non riconosciuto: ~S." path)))
  t)

(declaim (ftype (function (cons) list) mark-counts))
(defun mark-counts (entry)
  "Conta le espressioni e le due direzioni per decisione, verificando i denominatori."
  (let ((seen (make-hash-table :test #'equal)) (branches (make-hash-table :test #'equal))
        (expression-total 0) (expression-covered 0) (branch-total 0) (branch-covered 0))
    (dolist (mark (coverage-marks entry))
      (let ((path (car mark)) (covered (cdr mark)))
        (check-source-path path)
        (when (gethash path seen) (reject :duplicate-mark "Mark duplicato: ~S." path))
        (setf (gethash path seen) t)
        (if (member (first path) '(:then :else))
            (setf (getf (gethash (rest path) branches) (first path)) (if covered :covered :uncovered))
            (progn (incf expression-total) (when covered (incf expression-covered))))))
    (maphash (lambda (path directions)
               (unless (and (getf directions :then) (getf directions :else))
                 (reject :branch-denominator "Coppia THEN/ELSE incompleta: ~S." path))
               (incf branch-total 2)
               (dolist (direction '(:then :else))
                 (when (eq :covered (getf directions direction)) (incf branch-covered)))) branches)
    (list :expressions-covered expression-covered :expressions-total expression-total
          :branches-covered branch-covered :branches-total branch-total)))

(declaim (ftype (function (string list) t) verify-native-counts))
(defun verify-native-counts (path counts)
  "Confronta i conteggi ricavati dai dati con gli stessi contatori usati dall'HTML SB-COVER."
  (let* ((native (sb-cover::compute-file-info path :utf-8))
         (expressions (getf native :expression)) (branches (getf native :branch)))
    (unless (and (= (getf counts :expressions-covered) (sb-cover::ok-of expressions))
                 (= (getf counts :expressions-total) (sb-cover::all-of expressions))
                 (= (getf counts :branches-covered) (sb-cover::ok-of branches))
                 (= (getf counts :branches-total) (sb-cover::all-of branches)))
      (reject :html-denominator "Contatori raw e HTML discordanti per ~A." path)))
  t)

(declaim (ftype (function (pathname list) pathname) report-selected))
(defun report-selected (directory selected)
  "Produce HTML dei soli file selezionati; verifica cardinalità e file generati."
  (let ((paths (mapcar #'cadr selected)) (seen (make-hash-table :test #'equal)))
    (let ((report (sb-cover:report
                   directory :external-format :utf-8
                   :if-matches (lambda (path)
                                 (when (member path paths :test #'equal)
                                   (setf (gethash path seen) t))))))
      (unless (and report (= (length selected) (hash-table-count seen))
                   (= (1+ (length selected))
                      (length (directory (merge-pathnames "*.html" directory))))
                   (probe-file report))
        (reject :html-scope "HTML incompleto o scope diverso dai ~D sorgenti selezionati."
                (length selected)))
      report)))

(declaim (ftype (function (pathname pathname keyword) list) coverage))
(defun coverage (root directory scope)
  "Carica senza test-op, azzera le hit e chiama soltanto la suite selezionata."
  (proclaim '(optimize (safety 3) (sb-cover:store-coverage-data 3)))
  (handler-bind ((warning (lambda (condition) (error condition))))
    (asdf:load-asd (merge-pathnames "arcdocdb.asd" root))
    (isolate-output root directory scope)
    (asdf:load-system "arcdocdb" :force t)
    (asdf:load-system "arcdocdb/tests" :force t)
    (sb-cover:reset-coverage)
    (let* ((raw (merge-pathnames "coverage-state.lisp" directory)))
      ;; Conserva anche le hit parziali se la suite fallisce; nessuna qualifica.
      (unwind-protect (uiop:symbol-call (suite-package scope) '#:run)
        (sb-cover:save-coverage-in-file raw))
      ;; Il raw precede qualsiasi verifica del formato o generazione HTML.
      (let* ((selected (selected-state (read-state raw) root scope))
             (report (report-selected directory selected))
             (files (loop for (relative . entry) in selected
                          for counts = (mark-counts entry)
                          do (verify-native-counts (first entry) counts)
                          collect (append (list :path relative :source-path (first entry)) counts)))
             (keys '(:expressions-covered :expressions-total :branches-covered :branches-total))
             (totals (loop for key in keys append
                           (list key (reduce #'+ files :key (lambda (file) (getf file key)) :initial-value 0))))
             (summary (list :schema-version 1 :kind :get-resolver-coverage :status :ok
                            :scope scope :suite (format nil "~(~A~):run" (suite-package scope))
                            :lisp-version (lisp-implementation-version) :coverage-reset-before-suite t
                            :raw-state (namestring raw) :html-index (namestring report)
                            :files files :totals totals
                            :limits '(:diagnostic-expression-and-branch-coverage
                                      :not-mcdc :no-c1-or-release-qualification
                                      :private-sb-cover-count-interface-validated-against-raw))))
        (save-data (merge-pathnames "coverage-summary.lisp" directory) summary)))))

(declaim (ftype (function (list) (values string keyword)) parse-arguments))
(defun parse-arguments (arguments)
  "Accetta --report e l'opzionale --suite closed|active, senza duplicati."
  (unless (member (length arguments) '(2 4))
    (reject :usage "Usare --report spikes/out/get-resolver-coverage-R1/ [--suite closed|active]."))
  (let ((report nil) (scope :closed) (suite-seen nil))
    (loop for (option value) on arguments by #'cddr
          do (cond ((equal option "--report")
                    (when report (reject :usage "--report duplicato."))
                    (setf report value))
                   ((equal option "--suite")
                    (when suite-seen (reject :usage "--suite duplicato."))
                    (setf suite-seen t
                          scope (cond ((equal value "closed") :closed)
                                      ((equal value "active") :active)
                                      (t (reject :usage "Suite ammessa: closed oppure active.")))))
                   (t (reject :usage "Opzione sconosciuta: ~S." option))))
    (unless report (reject :usage "--report è richiesto."))
    (values report scope)))

(multiple-value-bind (report-argument scope) (parse-arguments (uiop:command-line-arguments))
  (let* ((root (truename "./")) (directory (fresh-directory root report-argument))
         (summary (coverage root directory scope)))
    (format t "Copertura resolver ~A: ~S~%Rapporto: ~A~%"
            scope (getf summary :totals) (getf summary :html-index))))
