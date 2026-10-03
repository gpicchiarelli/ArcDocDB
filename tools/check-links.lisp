;;;; check-links.lisp — verifica i link relativi (file e ancore) nei file Markdown,
;;;; compresi gli attributi src e srcset delle parti HTML.
;;;;
;;;; Uso:  sbcl --script tools/check-links.lisp [directory-radice]
;;;; Esce con codice 1 se trova link rotti. Solo Common Lisp (ADR-0001, ADR-0027).

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
  (let* ((root (if (second sb-ext:*posix-argv*)
                   (directory-argument (second sb-ext:*posix-argv*))
                   (truename "./")))
         (files (markdown-files root))
         (heading-cache (make-hash-table :test #'equal))
         (broken 0) (checked 0))
    (flet ((anchors-of (path)
             (or (gethash (namestring path) heading-cache)
                 (setf (gethash (namestring path) heading-cache)
                       (let ((text (read-file path)))
                         (append (headings text) (explicit-ids text)))))))
      (dolist (file files)
        (let ((text (read-file file))
              (dir (make-pathname :name nil :type nil :defaults file)))
          (dolist (target (append (links text) (attribute-targets text)))
            (incf checked)
            (multiple-value-bind (rel anchor) (split-anchor target)
              (let* ((path (if (string= rel "") file
                               (merge-pathnames rel dir)))
                     (exists (probe-file path)))
                (cond ((not exists)
                       (incf broken)
                       (format t "ROTTO  ~A -> ~A (file mancante)~%"
                               (enough-namestring file root) target))
                      ((and anchor (equalp (pathname-type path) "md")
                            (not (member anchor (anchors-of exists) :test #'string=)))
                       (incf broken)
                       (format t "ROTTO  ~A -> ~A (ancora mancante)~%"
                               (enough-namestring file root) target)))))))))
    (format t "~D file, ~D link controllati, ~D rotti~%" (length files) checked broken)
    (sb-ext:exit :code (if (zerop broken) 0 1))))

(main)
