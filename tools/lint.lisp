;;;; lint.lisp — linter dello standard di codifica (docs/affidabilita/standard-di-codifica.md).
;;;;
;;;; Uso:  sbcl --script tools/lint.lisp [dir ...]      (predefinito: src)
;;;;       sbcl --script tools/lint.lisp --self-test    (verifica il linter su fixture)
;;;; Esce con 1 se trova violazioni.
;;;;
;;;; Regole verificate:
;;;;   COD-02  safety inferiore a 2, o controlli dei limiti disattivati
;;;;   COD-03  truly-the
;;;;   COD-12  funzione più lunga di 60 righe
;;;;   COD-20  ignore-errors
;;;;   COD-22  (error "stringa") invece di una condizione tipizzata
;;;;   COD-34  eval, compile, load, intern, read, read-from-string
;;;;   COD-43  without-interrupts, without-gcing
;;;;   COD-50  defun/defmacro senza docstring
;;;;
;;;; Il linter non intern-a simboli: usa un proprio scanner, così legge anche codice che
;;;; cita package non ancora definiti.
;;;;
;;;; REQ: REQ-AFF-003
;;;; Solo Common Lisp (ADR-0001, ADR-0027).

(defstruct tok kind text line depth)

(defparameter *max-lines* 60)

;;; --- scanner ----------------------------------------------------------------

(defun delimiter-p (c)
  (or (member c '(#\Space #\Tab #\Newline #\Return #\Page #\( #\) #\" #\; #\' #\` #\,))
      nil))

(defun scan (text)
  "Trasforma TEXT in un vettore di token (:open :close :str :sym :chr)."
  (let ((toks (make-array 0 :adjustable t :fill-pointer t))
        (i 0) (n (length text)) (line 1) (depth 0))
    (labels ((peek (&optional (k 0)) (when (< (+ i k) n) (char text (+ i k))))
             (emit (kind txt dep) (vector-push-extend (make-tok :kind kind :text txt :line line :depth dep) toks))
             (newline-p (c) (char= c #\Newline)))
      (loop while (< i n)
            do (let ((c (char text i)))
                 (cond
                   ((newline-p c) (incf line) (incf i))
                   ((member c '(#\Space #\Tab #\Return #\Page #\' #\` #\,)) (incf i))
                   ((char= c #\;) (loop while (and (< i n) (not (newline-p (char text i)))) do (incf i)))
                   ((char= c #\")
                    (let ((start-line line) (buf (make-string-output-stream)))
                      (incf i)
                      (loop while (and (< i n) (char/= (char text i) #\"))
                            do (when (char= (char text i) #\\) (incf i))
                               (when (< i n)
                                 (when (newline-p (char text i)) (incf line))
                                 (write-char (char text i) buf))
                               (incf i))
                      (incf i)
                      (let ((save line)) (setf line start-line)
                        (emit :str (get-output-stream-string buf) depth)
                        (setf line save))))
                   ((and (char= c #\#) (eql (peek 1) #\|))
                    (let ((level 1)) (incf i 2)
                      (loop while (and (< i n) (> level 0))
                            do (cond ((and (eql (peek) #\|) (eql (peek 1) #\#)) (decf level) (incf i 2))
                                     ((and (eql (peek) #\#) (eql (peek 1) #\|)) (incf level) (incf i 2))
                                     (t (when (newline-p (char text i)) (incf line)) (incf i))))))
                   ((and (char= c #\#) (eql (peek 1) #\\))
                    (incf i 3)
                    (loop while (and (< i n) (not (delimiter-p (char text i)))) do (incf i))
                    (emit :chr "" depth))
                   ((char= c #\#) (incf i))
                   ((char= c #\() (emit :open "(" depth) (incf depth) (incf i))
                   ((char= c #\)) (decf depth) (emit :close ")" depth) (incf i))
                   ((char= c #\|)
                    (let ((start (incf i)))
                      (loop while (and (< i n) (char/= (char text i) #\|)) do (incf i))
                      (emit :sym (string-downcase (subseq text start i)) depth)
                      (incf i)))
                   (t (let ((start i))
                        (loop while (and (< i n) (not (delimiter-p (char text i)))) do (incf i))
                        (emit :sym (string-downcase (subseq text start i)) depth)))))))
    toks))

(defun base-name (sym)
  "Simbolo senza prefisso di package."
  (let ((p (position #\: sym :from-end t)))
    (if p (subseq sym (1+ p)) sym)))

;;; --- regole -------------------------------------------------------------------

(defvar *violations* '())

(defun add-violation (file line rule fmt &rest args)
  (push (list file line rule (apply #'format nil fmt args)) *violations*))

(defun tok-at (toks i) (when (and (>= i 0) (< i (length toks))) (aref toks i)))

(defun call-position-p (toks i)
  "Keyword nelle liste di opzioni non sono chiamate, anche dopo una parentesi."
  (let* ((prev (tok-at toks (1- i)))
         (text (tok-text (aref toks i)))
         (colon (position #\: text)))
    (and prev (eq (tok-kind prev) :open)
         (not (and colon (or (zerop colon) (string= text "keyword" :end1 colon)))))))

(defun integer-token (tk)
  (and tk (eq (tok-kind tk) :sym)
       (every #'digit-char-p (tok-text tk)) (plusp (length (tok-text tk)))
       (parse-integer (tok-text tk))))

(defun check-token-rules (file toks)
  (dotimes (i (length toks))
    (let ((tk (aref toks i)))
      (when (eq (tok-kind tk) :sym)
        (let ((name (base-name (tok-text tk))))
          (cond
            ((string= name "truly-the")
             (add-violation file (tok-line tk) "COD-03" "truly-the è vietato"))
            ((string= name "ignore-errors")
             (add-violation file (tok-line tk) "COD-20" "ignore-errors è vietato"))
            ((member name '("without-interrupts" "without-gcing") :test #'string=)
             (add-violation file (tok-line tk) "COD-43" "~A è vietato fuori dal modulo io" name))
            ((string= name "safety")
             (let ((n (integer-token (tok-at toks (1+ i)))))
               (when (and n (< n 2))
                 (add-violation file (tok-line tk) "COD-02" "safety ~D: ammesso solo safety >= 2" n))))
            ((string= name "insert-array-bounds-checks")
             (let ((n (integer-token (tok-at toks (1+ i)))))
               (when (and n (zerop n))
                 (add-violation file (tok-line tk) "COD-02" "controlli dei limiti disattivati"))))
            ((and (member name '("eval" "compile" "load" "intern" "read" "read-from-string")
                          :test #'string=)
                  (call-position-p toks i))
             (add-violation file (tok-line tk) "COD-34" "~A vietato nel codice di prodotto" name))
            ((and (string= name "error") (call-position-p toks i)
                  (let ((nx (tok-at toks (1+ i)))) (and nx (eq (tok-kind nx) :str))))
             (add-violation file (tok-line tk) "COD-22" "(error \"...\"): usare una condizione tipizzata"))))))))

(defun top-level-forms (toks)
  "Lista di (inizio . fine) degli indici dei token dei form di primo livello."
  (let ((acc '()) (start nil))
    (dotimes (i (length toks))
      (let ((tk (aref toks i)))
        (cond ((and (eq (tok-kind tk) :open) (zerop (tok-depth tk))) (setf start i))
              ((and (eq (tok-kind tk) :close) (zerop (tok-depth tk)) start)
               (push (cons start i) acc) (setf start nil)))))
    (nreverse acc)))

(defun matching-close (toks open-index)
  (let ((d (tok-depth (aref toks open-index))))
    (loop for j from (1+ open-index) below (length toks)
          when (and (eq (tok-kind (aref toks j)) :close) (= (tok-depth (aref toks j)) d))
            return j)))

(defun check-form-rules (file toks)
  (dolist (form (top-level-forms toks))
    (let* ((s (car form)) (e (cdr form))
           (head (tok-at toks (1+ s)))
           (name (and head (eq (tok-kind head) :sym) (base-name (tok-text head)))))
      (when (member name '("defun" "defmacro") :test #'equal)
        (let ((len (1+ (- (tok-line (aref toks e)) (tok-line (aref toks s)))))
              (fname (let ((n (tok-at toks (+ s 2)))) (if n (tok-text n) "?"))))
          (when (> len *max-lines*)
            (add-violation file (tok-line (aref toks s)) "COD-12" "~A: ~D righe (massimo ~D)" fname len *max-lines*))
          (let* ((ll (tok-at toks (+ s 3)))
                 (close (and ll (eq (tok-kind ll) :open) (matching-close toks (+ s 3))))
                 (after (and close (tok-at toks (1+ close)))))
            (unless (and after (eq (tok-kind after) :str))
              (add-violation file (tok-line (aref toks s)) "COD-50" "~A: manca la docstring" fname))))))))

(defun read-file (path)
  (with-open-file (in path :external-format :utf-8)
    (let ((s (make-string (file-length in))))
      (subseq s 0 (read-sequence s in)))))

(defun lint-file (path)
  (let ((toks (scan (read-file path))) (file (namestring path)))
    (check-token-rules file toks)
    (check-form-rules file toks)))

(defun lisp-files (dir)
  (directory (concatenate 'string dir "/**/*.lisp")))

;;; --- auto-verifica ---------------------------------------------------------------

(defun expected-rules (path)
  "Regole attese: riga ';;; EXPECT: COD-xx COD-yy' nel file di fixture."
  (let* ((text (read-file path)) (pos (search ";;; EXPECT:" text)))
    (when pos
      (let* ((eol (position #\Newline text :start pos))
             (line (subseq text (+ pos 11) eol)) (acc '()) (start 0))
        (loop for sp = (position #\Space line :start start)
              do (let ((w (string-trim " " (subseq line start sp))))
                   (when (plusp (length w)) (push w acc)))
                 (if sp (setf start (1+ sp)) (return)))
        (sort acc #'string<)))))

(defun self-test ()
  (let ((failures 0))
    (dolist (p (directory "tests/lint-fixtures/*.lisp"))
      (setf *violations* '())
      (lint-file p)
      (let ((found (sort (remove-duplicates (mapcar #'third *violations*) :test #'string=) #'string<))
            (expected (expected-rules p)))
        (if (equal found expected)
            (format t "ok    ~A: ~{~A~^ ~}~%" (file-namestring p) (or found '("nessuna violazione")))
            (progn (incf failures)
                   (format t "FAIL  ~A: attese ~S, trovate ~S~%" (file-namestring p) expected found)))))
    (sb-ext:exit :code (if (zerop failures) 0 1))))

(defun main ()
  (let ((args (rest sb-ext:*posix-argv*)))
    (when (member "--self-test" args :test #'string=) (self-test))
    (let ((dirs (or (remove-if (lambda (a) (char= (char a 0) #\-)) args) '("src"))) (n 0))
      (dolist (d dirs)
        (dolist (p (lisp-files d)) (incf n) (lint-file p)))
      (dolist (v (sort (copy-list *violations*)
                       (lambda (a b) (or (string< (first a) (first b))
                                         (and (string= (first a) (first b)) (< (second a) (second b)))))))
        (format t "~A:~D  ~A  ~A~%" (first v) (second v) (third v) (fourth v)))
      (format t "~D file, ~D violazioni~%" n (length *violations*))
      (sb-ext:exit :code (if *violations* 1 0)))))

(main)
