;;;; check-links.lisp — verifica i link relativi (file e ancore) nei file Markdown,
;;;; compresi gli attributi src e srcset delle parti HTML.
;;;;
;;;; Uso:  sbcl --script tools/check-links.lisp [directory-radice]
;;;;       --report FILE ammesso prima/dopo directory-radice; FILE esclusivo UTF-8.
;;;;       Report plist :kind :ci-check, indipendente dal package CI.
;;;; Esce con codice 1 se trova link rotti. Solo Common Lisp (ADR-0001, ADR-0027).

;;; REQ: REQ-VAL-001 REQ-AFF-012
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-VAL-001 REQ-AFF-012
(defun check-report-options (args)
  "Estrae --report FILE in qualsiasi posizione; rifiuta duplicati e FILE mancante."
  (let ((remaining nil) (report nil))
    (loop while args do
      (let ((argument (pop args)))
        (if (string= argument "--report")
            (progn
              (when (or report (null args) (zerop (length (first args)))
                        (and (>= (length (first args)) 2)
                             (string= "--" (first args) :end2 2)))
                (error 'simple-error :format-control "--report richiede un solo FILE."))
              (setf report (pop args)))
            (push argument remaining))))
    (values (nreverse remaining) report)))

(defun check-report-text (data)
  "Wire canonico limitato: liste proprie, keyword ASCII, stringhe, interi, NIL/T."
  (let ((nodes 0))
    (with-output-to-string (stream)
      (labels ((emit (value depth)
                 (when (or (> depth 16) (> (incf nodes) 10000))
                   (error 'simple-error :format-control "Budget del report superato."))
                 (cond
                   ((null value) (write-string "NIL" stream))
                   ((eq value t) (write-string "T" stream))
                   ((keywordp value)
                    (let ((name (symbol-name value)))
                      (unless (and (plusp (length name))
                                   (every (lambda (c) (or (find c "ABCDEFGHIJKLMNOPQRSTUVWXYZ")
                                                         (find c "0123456789-"))) name))
                        (error 'simple-error :format-control "Keyword wire non valida."))
                      (write-char #\: stream) (write-string name stream)))
                   ((integerp value)
                    (let ((*print-base* 10) (*print-radix* nil))
                      (format stream "~D" value)))
                   ((stringp value)
                    (write-char #\" stream)
                    (loop for c across value do
                      (when (find c '(#\\ #\")) (write-char #\\ stream))
                      (write-char c stream))
                    (write-char #\" stream))
                   ((consp value)
                    (write-char #\( stream)
                    (loop for tail = value then (cdr tail) while tail do
                      (unless (consp tail)
                        (error 'simple-error :format-control "Lista wire impropria."))
                      (unless (eq tail value) (write-char #\Space stream))
                      (emit (car tail) (1+ depth))
                      (when (> nodes 10000)
                        (error 'simple-error :format-control "Budget wire superato.")))
                    (write-char #\) stream))
                   (t (error 'simple-error :format-control "Tipo wire vietato.")))))
        (emit data 0))
      (terpri stream))))

(defun write-check-report (path check passed counts)
  "Scrive una plist primitiva in modo esclusivo; propaga gli errori seri."
  (let ((text (check-report-text
               (list :kind :ci-check :check check :status (if passed :passed :failed)
                     :counts counts))))
    (with-open-file (stream path :direction :output :if-exists :error
                           :if-does-not-exist :create :external-format :utf-8)
      (write-string text stream)
      (finish-output stream))))

(defun read-file (path)
  (with-open-file (in path :external-format :utf-8)
    (let ((s (make-string (file-length in))))
      (subseq s 0 (read-sequence s in)))))

(defun markdown-files (root)
  (let ((acc '()))
    (labels ((walk (dir)
               (dolist (p (directory (merge-pathnames "*.*" dir)))
                 (cond ((and (null (pathname-name p)) (null (pathname-type p)))
                        (let ((name (car (last (pathname-directory p)))))
                          (unless (member name '(".git" ".cache") :test #'string=)
                            (walk p))))
                       ((equalp (pathname-type p) "md") (push p acc))))))
      (walk root))
    (sort acc #'string< :key #'namestring)))

(defun slugify (heading)
  "Regola di GitHub: minuscole, via la punteggiatura, spazi -> trattini."
  (let ((out (make-string-output-stream)))
    (loop for ch across (string-downcase (string-trim " " heading))
          do (cond ((or (alphanumericp ch) (char= ch #\-) (char= ch #\_)) (write-char ch out))
                   ((char= ch #\Space) (write-char #\- out))))
    (get-output-stream-string out)))

(defun headings (text)
  "Ancore disponibili in un file: slug dei titoli, con suffissi -1, -2 per i duplicati."
  (let ((seen (make-hash-table :test #'equal)) (acc '()) (in-code nil))
    (with-input-from-string (in text)
      (loop for line = (read-line in nil) while line
            do (when (and (>= (length line) 3) (string= (subseq line 0 3) "```"))
                 (setf in-code (not in-code)))
               (when (and (not in-code) (plusp (length line)) (char= (char line 0) #\#))
                 (let* ((title (string-left-trim "# " line))
                        ;; rimuove il markup inline più comune
                        (title (remove-if (lambda (c) (member c '(#\` #\* #\[ #\]))) title))
                        (slug (slugify title))
                        (n (gethash slug seen 0)))
                   (setf (gethash slug seen) (1+ n))
                   (push (if (zerop n) slug (format nil "~A-~D" slug n)) acc)))))
    acc))

(defun explicit-ids (text)
  "Ancore esplicite <a id=\"x\"> (riconosciute da GitHub) presenti nel testo."
  (let ((acc '()) (marker "<a id=\"") (start 0))
    (loop for pos = (search marker text :start2 start) while pos
          do (let* ((b (+ pos (length marker))) (e (position #\" text :start b)))
               (when e (push (subseq text b e) acc))
               (setf start (1+ pos))))
    acc))

(defun links (text)
  "Tutti i target di link Markdown ](...) non assoluti."
  (let ((acc '()) (start 0))
    (loop for pos = (search "](" text :start2 start) while pos
          do (let ((end (position #\) text :start (+ pos 2))))
               (unless end (return))
               (let ((target (subseq text (+ pos 2) end)))
                 (unless (or (zerop (length target))
                             (search "://" target)
                             (char= (char target 0) #\#)
                             (string= target ""))
                   (push target acc)))
               (setf start (1+ end))))
    (nreverse acc)))

(defun attribute-targets (text)
  "Valori relativi degli attributi src e srcset nelle parti HTML di un Markdown."
  (let ((acc '()))
    (dolist (marker '("src=\"" "srcset=\""))
      (let ((start 0))
        (loop for pos = (search marker text :start2 start) while pos
              do (let* ((b (+ pos (length marker))) (e (position #\" text :start b)))
                   (when e
                     (let ((v (subseq text b e)))
                       (unless (or (zerop (length v)) (search "://" v)) (push v acc))))
                   (setf start (1+ pos))))))
    acc))

(defun split-anchor (target)
  (let ((h (position #\# target)))
    (if h (values (subseq target 0 h) (subseq target (1+ h))) (values target nil))))

(defun directory-argument (s)
  "Normalizza un argomento di directory senza dipendere da UIOP."
  (truename (if (char= (char s (1- (length s))) #\/) s (concatenate 'string s "/"))))

(defun main ()
  (multiple-value-bind (args report) (check-report-options (rest sb-ext:*posix-argv*))
  (let* ((root (if (first args)
                   (directory-argument (first args))
                   (truename "./")))
         (files (markdown-files root))
         (heading-cache (make-hash-table :test #'equal))
         (broken 0) (checked 0) (missing-files 0) (missing-anchors 0)
         (markdown-targets 0) (html-targets 0))
    (flet ((anchors-of (path)
             (or (gethash (namestring path) heading-cache)
                 (setf (gethash (namestring path) heading-cache)
                       (let ((text (read-file path)))
                         (append (headings text) (explicit-ids text)))))))
      (dolist (file files)
        (let* ((text (read-file file))
               (dir (make-pathname :name nil :type nil :defaults file))
               (markdown (links text)) (html (attribute-targets text)))
          (dolist (target (append markdown html))
            (incf checked)
            (multiple-value-bind (rel anchor) (split-anchor target)
              (let* ((path (if (string= rel "") file
                               (merge-pathnames rel dir)))
                     (exists (probe-file path)))
                (cond ((not exists)
                       (incf broken)
                       (incf missing-files)
                       (format t "ROTTO  ~A -> ~A (file mancante)~%"
                               (enough-namestring file root) target))
                      ((and anchor (equalp (pathname-type path) "md")
                            (not (member anchor (anchors-of exists) :test #'string=)))
                       (incf broken)
                       (incf missing-anchors)
                       (format t "ROTTO  ~A -> ~A (ancora mancante)~%"
                               (enough-namestring file root) target))))))
          (incf markdown-targets (length markdown))
          (incf html-targets (length html)))))
    (format t "~D file, ~D link controllati, ~D rotti~%" (length files) checked broken)
    (when report
      (write-check-report report :links (zerop broken)
                          (list :files (length files) :checked checked :broken broken
                                :passed (- checked broken) :missing-files missing-files
                                :missing-anchors missing-anchors :markdown-targets markdown-targets
                                :html-targets html-targets)))
    (sb-ext:exit :code (if (zerop broken) 0 1)))))

(main)
