;;;; check-trace.lisp — controllo e generazione della matrice di tracciabilità.
;;;;
;;;; Uso:  sbcl --script tools/check-trace.lisp [--write]
;;;;   senza opzioni: verifica; esce con 1 se qualcosa è incoerente o la matrice
;;;;                  committata non coincide con quella generata
;;;;   --write:       rigenera docs/tracciabilita/matrice.md
;;;;
;;;; Controlli:
;;;;   1. forma di ogni requisito (campi, classe, stato, metodi di verifica)
;;;;   2. identificatori unici e ben formati
;;;;   3. ogni INV-, ADR-, FI- citato esiste nella documentazione
;;;;   4. ogni invariante e ogni scenario FI è coperto da almeno un requisito
;;;;   5. ogni requisito ha almeno un metodo di verifica
;;;;   6. i riferimenti REQ- nel codice (src, tests, tools) indicano requisiti esistenti
;;;;   7. un requisito :implementato o :verificato è citato nel codice (src o tools)
;;;;
;;;; REQ: REQ-AFF-005
;;;; Solo Common Lisp (ADR-0001, ADR-0027).

(setf *read-eval* nil)

(defparameter *classes* '("C1" "C2" "C3" "C4"))
(defparameter *stati* '(:specificato :progettato :implementato :verificato))
(defparameter *metodi* '(:test :prop :diff :model :fi :fuzz :corr :mut :soak :bench :rev :analisi))
(defparameter *req-file* "docs/tracciabilita/requisiti.lisp")
(defparameter *matrix-file* "docs/tracciabilita/matrice.md")

(defvar *errors* 0)

(defun fail (fmt &rest args)
  (incf *errors*)
  (format t "ERRORE  ~?~%" fmt args))

(defun read-lines (path)
  (with-open-file (in path :external-format :utf-8)
    (loop for line = (read-line in nil) while line collect line)))

(defun read-text (path)
  (with-open-file (in path :external-format :utf-8)
    (let ((s (make-string (file-length in))))
      (subseq s 0 (read-sequence s in)))))

(defun starts-with (prefix string)
  (and (>= (length string) (length prefix)) (string= prefix string :end2 (length prefix))))

(defun table-ids (path prefix)
  "Identificatori nella prima colonna delle righe di tabella che iniziano con PREFIX."
  (let ((marker (concatenate 'string "| " prefix)))
    (loop for line in (read-lines path)
          when (starts-with marker line)
            collect (let* ((start 2) (end (position #\Space line :start start)))
                      (subseq line start end)))))

(defun adr-table ()
  "Alist (ID . nome-file) per gli ADR esistenti, escluso il modello 0000."
  (let ((acc '()))
    (dolist (p (directory "docs/adr/0*.md"))
      (let ((name (file-namestring p)))
        (unless (starts-with "0000" name)
          (push (cons (concatenate 'string "ADR-" (subseq name 0 4)) name) acc))))
    (sort acc #'string< :key #'car)))

(defun req-id-p (s)
  (and (stringp s) (= (length s) 11) (starts-with "REQ-" s)
       (alpha-char-p (char s 4)) (alpha-char-p (char s 5)) (alpha-char-p (char s 6))
       (char= (char s 7) #\-)
       (every #'digit-char-p (subseq s 8))))

(defun area-of (id) (subseq id 4 7))

(defun load-requirements ()
  (with-open-file (in *req-file* :external-format :utf-8)
    (read in)))

(defun prop (req key) (getf req key))

(defun check-shape (reqs)
  (let ((seen (make-hash-table :test #'equal)))
    (dolist (r reqs)
      (let ((id (prop r :id)))
        (unless (req-id-p id) (fail "id non valido: ~S" id))
        (when (gethash id seen) (fail "~A duplicato" id))
        (setf (gethash id seen) t)
        (dolist (k '(:src :txt :cls :stato :ver))
          (unless (prop r k) (fail "~A: campo ~S mancante" id k)))
        (unless (member (prop r :cls) *classes* :test #'equal)
          (fail "~A: classe non valida ~S" id (prop r :cls)))
        (unless (member (prop r :stato) *stati*)
          (fail "~A: stato non valido ~S" id (prop r :stato)))
        (when (null (prop r :ver))
          (fail "~A: nessun metodo di verifica" id))
        (dolist (m (prop r :ver))
          (unless (member m *metodi*) (fail "~A: metodo di verifica sconosciuto ~S" id m)))
        (when (and (member :fi (prop r :ver)) (null (prop r :fi)))
          (fail "~A: verifica :fi senza scenari FI" id))))))

(defun check-references (reqs invs adrs fis)
  (dolist (r reqs)
    (let ((id (prop r :id)))
      (dolist (i (prop r :inv))
        (unless (member i invs :test #'string=) (fail "~A: invariante inesistente ~A" id i)))
      (dolist (a (prop r :adr))
        (unless (assoc a adrs :test #'string=) (fail "~A: ADR inesistente ~A" id a)))
      (dolist (f (prop r :fi))
        (unless (member f fis :test #'string=) (fail "~A: scenario FI inesistente ~A" id f))))))

(defun covered-by (reqs key value)
  (loop for r in reqs when (member value (prop r key) :test #'string=) collect (prop r :id)))

(defun check-coverage (reqs invs fis)
  (dolist (i invs)
    (unless (covered-by reqs :inv i) (fail "invariante ~A non coperto da alcun requisito" i)))
  (dolist (f fis)
    (unless (covered-by reqs :fi f) (fail "scenario ~A non coperto da alcun requisito" f))))

;;; --- riferimenti dal codice ------------------------------------------------

(defun lisp-files (dir)
  (loop for p in (directory (concatenate 'string dir "/**/*.lisp"))
        collect p))

(defun req-refs-in (text)
  "Tutti i REQ-xxx-nnn presenti nel TEXT."
  (let ((acc '()) (start 0))
    (loop for pos = (search "REQ-" text :start2 start) while pos
          do (let ((end (+ pos 11)))
               (when (and (<= end (length text)) (req-id-p (subseq text pos end)))
                 (push (subseq text pos end) acc))
               (setf start (+ pos 4))))
    acc))

(defun code-refs ()
  "Alist (dir . lista di REQ citati) per src, tests, tools. Il file dei requisiti è escluso."
  (loop for dir in '("src" "tests" "tools")
        collect (cons dir
                      (loop for p in (lisp-files dir)
                            append (req-refs-in (read-text p))))))

(defun check-code-refs (reqs)
  (let ((refs (code-refs)) (known (mapcar (lambda (r) (prop r :id)) reqs)))
    (dolist (entry refs)
      (dolist (id (cdr entry))
        (unless (member id known :test #'string=)
          (fail "riferimento a requisito inesistente ~A in ~A/" id (car entry)))))
    (dolist (r reqs)
      (when (member (prop r :stato) '(:implementato :verificato))
        (let ((id (prop r :id)))
          (unless (or (member id (cdr (assoc "src" refs :test #'string=)) :test #'string=)
                      (member id (cdr (assoc "tools" refs :test #'string=)) :test #'string=))
            (fail "~A è ~(~A~) ma non è citato nel codice (src/ o tools/)" id (prop r :stato)))
          (unless (or (string= (prop r :cls) "C4")
                      (member id (cdr (assoc "tests" refs :test #'string=)) :test #'string=))
            (fail "~A è ~(~A~) ma non è citato nei test (tests/)" id (prop r :stato))))))))

;;; --- generazione della matrice ---------------------------------------------

(defun join (items sep)
  (with-output-to-string (s)
    (loop for (x . rest) on items
          do (write-string x s)
             (when rest (write-string sep s)))))

(defun adr-link (id adrs)
  (let ((entry (assoc id adrs :test #'string=)))
    (format nil "[~A](../adr/~A)" (subseq id 4) (cdr entry))))

(defun keyword-names (list)
  (mapcar (lambda (k) (string-downcase (symbol-name k))) list))

(defun count-where (reqs key value)
  (count value reqs :key (lambda (r) (prop r key)) :test #'equal))

(defun render-matrix (reqs invs adrs fis)
  (with-output-to-string (s)
    (format s "# Matrice di tracciabilità~%~%")
    (format s "> **Generata** da [requisiti.lisp](requisiti.lisp) con `make trace-write`. Non modificare a mano: `make trace` fallisce se non coincide.~%~%")
    (format s "**Sommario.** ~D requisiti. Per classe: ~{~A~^, ~}. Per stato: ~{~A~^, ~}. Invarianti coperti: ~D/~D. Scenari FI coperti: ~D/~D.~%~%"
            (length reqs)
            (mapcar (lambda (c) (format nil "~A ~D" c (count-where reqs :cls c))) *classes*)
            (mapcar (lambda (st) (format nil "~(~A~) ~D" st (count-where reqs :stato st))) *stati*)
            (count-if (lambda (i) (covered-by reqs :inv i)) invs) (length invs)
            (count-if (lambda (f) (covered-by reqs :fi f)) fis) (length fis))
    (format s "## Requisiti~%~%")
    (format s "| ID | Enunciato | Fonte | Classe | Stato | Invarianti | ADR | Verifica | FI |~%")
    (format s "|---|---|---|---|---|---|---|---|---|~%")
    (dolist (r reqs)
      (format s "| ~A | ~A | ~A | ~A | ~(~A~) | ~A | ~A | ~A | ~A |~%"
              (prop r :id) (prop r :txt) (prop r :src) (prop r :cls) (prop r :stato)
              (join (prop r :inv) ", ")
              (join (mapcar (lambda (a) (adr-link a adrs)) (prop r :adr)) ", ")
              (join (keyword-names (prop r :ver)) ", ")
              (join (prop r :fi) ", ")))
    (format s "~%## Copertura degli invarianti~%~%| Invariante | Requisiti |~%|---|---|~%")
    (dolist (i invs)
      (format s "| ~A | ~A |~%" i (join (covered-by reqs :inv i) ", ")))
    (format s "~%## Copertura degli scenari di fault injection~%~%| Scenario | Requisiti |~%|---|---|~%")
    (dolist (f fis)
      (format s "| ~A | ~A |~%" f (join (covered-by reqs :fi f) ", ")))
    (format s "~%## Decisioni (ADR) e requisiti che le realizzano~%~%| ADR | Requisiti |~%|---|---|~%")
    (dolist (a adrs)
      (let ((rs (covered-by reqs :adr (car a))))
        (format s "| ~A | ~A |~%" (adr-link (car a) adrs)
                (if rs (join rs ", ") "—  (decisione senza requisito diretto)"))))))

(defun write-file (path text)
  (with-open-file (out path :direction :output :if-exists :supersede :external-format :utf-8)
    (write-string text out)))

(defun main ()
  (let* ((write-p (member "--write" sb-ext:*posix-argv* :test #'string=))
         (reqs (load-requirements))
         (invs (table-ids "docs/invarianti.md" "INV-"))
         (fis (table-ids "docs/14-fault-injection.md" "FI-"))
         (adrs (adr-table)))
    (check-shape reqs)
    (check-references reqs invs adrs fis)
    (check-coverage reqs invs fis)
    (check-code-refs reqs)
    (let ((generated (render-matrix reqs invs adrs fis)))
      (cond (write-p
             (write-file *matrix-file* generated)
             (format t "scritto ~A~%" *matrix-file*))
            ((not (probe-file *matrix-file*))
             (fail "~A non esiste: eseguire make trace-write" *matrix-file*))
            ((string/= generated (read-text *matrix-file*))
             (fail "~A non è aggiornata: eseguire make trace-write" *matrix-file*))))
    (format t "~D requisiti, ~D invarianti, ~D scenari FI, ~D ADR: ~D errori~%"
            (length reqs) (length invs) (length fis) (length adrs) *errors*)
    (sb-ext:exit :code (if (zerop *errors*) 0 1))))

(main)
