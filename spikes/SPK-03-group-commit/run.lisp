;;;; Runner SPK-03 : compilazione rigorosa e una sola plist su stdout.
(defpackage #:arcdocdb.spk03.runner (:use #:cl))
(in-package #:arcdocdb.spk03.runner)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defun intero-positivo (testo)
  "Analizza cifre decimali senza reader Lisp."
  (unless (and (plusp (length testo)) (<= (length testo) 10)
               (every (lambda (carattere) (digit-char-p carattere 10)) testo))
    (error "Intero decimale non valido: ~S." testo))
  (let ((valore (parse-integer testo :radix 10 :junk-allowed nil)))
    (unless (plusp valore) (error "Serve un intero positivo: ~S." testo))
    valore))

(defun separare (testo)
  "Lista CSV corta, senza elementi vuoti."
  (unless (<= 1 (length testo) 256) (error "Lista troppo lunga o vuota."))
  (loop for inizio = 0 then (1+ fine)
        for fine = (position #\, testo :start inizio)
        collect (let ((elemento (subseq testo inizio fine)))
                  (when (zerop (length elemento)) (error "Elemento CSV vuoto."))
                  elemento)
        while fine))

(defun primitiva (testo)
  (cond ((string= testo "fsync") :fsync)
        ((string= testo "fullfsync") :fullfsync)
        ((string= testo "fdatasync") :fdatasync)
        (t (error "Primitiva sconosciuta: ~S." testo))))

(defun opzioni (argomenti)
  "Modalità e keyword per benchmark; respinge opzioni sconosciute."
  (let ((modo :bench) (parametri nil) (modo-esplicito nil))
    (loop while argomenti
          for argomento = (pop argomenti)
          do (cond
               ((member argomento '("--check" "--bench") :test #'string=)
                (when modo-esplicito (error "Modalità specificata due volte."))
                (setf modo-esplicito t
                      modo (if (string= argomento "--check") :check :bench)))
               (t
                (let* ((valore (or (pop argomenti)
                                   (error "Manca il valore per ~A." argomento)))
                       (chiave
                         (cond ((string= argomento "--files") :files)
                               ((string= argomento "--batches") :batches)
                               ((string= argomento "--samples") :samples)
                               ((string= argomento "--record-bytes") :record-bytes)
                               ((string= argomento "--seconds") :max-seconds)
                               ((string= argomento "--flush") :flush-modes)
                               (t (error "Opzione sconosciuta: ~A." argomento)))))
                  (when (member chiave parametri) (error "Opzione ripetuta: ~A." argomento))
                  (setf parametri
                        (append parametri
                                (list chiave
                                      (case chiave
                                        ((:files :batches)
                                         (mapcar #'intero-positivo (separare valore)))
                                        (:flush-modes (mapcar #'primitiva (separare valore)))
                                        (otherwise (intero-positivo valore))))))))))
    (when (and (eq modo :check) parametri)
      (error "--check non accetta parametri benchmark."))
    (values modo parametri)))

(defun compilare-caricare (directory)
  "Trova core rispetto al runner; warning/style-warning rendono il build fallito."
  (let ((source (merge-pathnames "core.lisp" directory))
        (destinazione (merge-pathnames "out/core.fasl" directory))
        (*compile-verbose* nil) (*compile-print* nil) (*load-verbose* nil)
        (*read-eval* nil))
    (ensure-directories-exist destinazione)
    (handler-bind
        ((style-warning (lambda (condizione)
                          (error "Style-warning in ~A: ~A." source condizione)))
         (warning (lambda (condizione)
                    (error "Warning in ~A: ~A." source condizione))))
      (multiple-value-bind (fasl avvisi fallito)
          (compile-file source :output-file destinazione)
        (unless (and fasl (not avvisi) (not fallito))
          (error "Compilazione fallita per ~A." source))
        (load fasl :verbose nil :print nil)))))

(defun api (nome)
  "Usa soltanto i nomi fissi dell'API del package compilato."
  (let ((simbolo (find-symbol nome "ARCDOCDB.SPK03")))
    (unless (and simbolo (fboundp simbolo)) (error "API mancante: ~A." nome))
    (symbol-function simbolo)))

(defun scrivere-risultato (risultato)
  (let ((*print-readably* nil) (*print-escape* t) (*print-pretty* t) (*print-circle* nil)
        (*print-length* nil) (*print-level* nil) (*print-right-margin* 100)
        (*package* (find-package :cl-user)))
    (write risultato)
    (terpri)
    (finish-output)))

(let ((directory (make-pathname :name nil :type nil :defaults *load-truename*))
      (*read-eval* nil))
  (handler-case
      (multiple-value-bind (modo parametri) (opzioni (cdr sb-ext:*posix-argv*))
        (compilare-caricare directory)
        (let* ((risultato
                 (if (eq modo :check)
                     (let ((verification (funcall (api "CHECK"))))
                       (list :spike "SPK-03" :mode :check
                             :status (getf verification :status) :check verification))
                     (append (list :mode :bench)
                             (apply (api "BENCHMARK") parametri))))
               (stato (getf risultato :status)))
          (scrivere-risultato risultato)
          (sb-ext:exit :code (if (member stato '(:ok :budget-exhausted)) 0 2))))
    (error (condizione)
      (scrivere-risultato
       (list :spike "SPK-03" :status :error
             :condition (princ-to-string (type-of condizione))
             :message (princ-to-string condizione)))
      (sb-ext:exit :code 1))))
