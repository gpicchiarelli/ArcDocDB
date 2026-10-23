;;;; Ricerca numerica nelle tabelle UCD versionate, senza stringhe o locale del runtime.
(in-package #:arcdocdb.fulltext.analysis)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (spazio-full-text vettore-u32 scalare) u32) proprieta-unicode))
(defun proprieta-unicode (space ranges cp)
  "Pre: range immutabili ordinati a triple, scalare. Post: valore oppure zero.
Ricerca limitata dal numero di triple; RESOURCE-EXHAUSTED se termina il lavoro."
  (let ((low 0) (high (floor (length ranges) 3)))
    (loop repeat (1+ high) while (< low high) do
      (consuma-lavoro-full-text space)
      (let* ((mid (floor (+ low high) 2)) (position (* mid 3)))
        (cond ((< cp (aref ranges position)) (setf high mid))
              ((> cp (aref ranges (1+ position))) (setf low (1+ mid)))
              (t (return-from proprieta-unicode (aref ranges (+ position 2)))))))
    0))

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (spazio-full-text vettore-u32 scalare) fixnum) trova-mapping))
(defun trova-mapping (space records cp)
  "Pre: record a triple ordinati per scalare. Post: offset della tripla o -1.
Nessuna mutazione delle tabelle; ricerca e lavoro limitati."
  (let ((low 0) (high (floor (length records) 3)))
    (loop repeat (1+ high) while (< low high) do
      (consuma-lavoro-full-text space)
      (let* ((mid (floor (+ low high) 2)) (position (* mid 3)) (key (aref records position)))
        (cond ((< cp key) (setf high mid)) ((> cp key) (setf low (1+ mid)))
              (t (return-from trova-mapping position)))))
    -1))

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text scalare scalare) u32) composizione-unicode))
(defun composizione-unicode (space first second)
  "Pre: due scalari, spazio esclusivo. Post: composizione canonica o zero.
Hangul algoritmico, altre coppie UCD non escluse; nessun bignum o stato globale."
  (cond ((and (<= #x1100 first #x1112) (<= #x1161 second #x1175))
         (+ #xac00 (* (- first #x1100) 588) (* (- second #x1161) 28)))
        ((and (<= #xac00 first #xd7a3) (zerop (mod (- first #xac00) 28))
              (<= #x11a8 second #x11c2)) (+ first (- second #x11a7)))
        (t
         (let ((key (+ (ash first 21) second)) (low 0) (high (floor (length +compose-pairs+) 2)))
           (loop repeat (1+ high) while (< low high) do
             (consuma-lavoro-full-text space)
             (let* ((mid (floor (+ low high) 2)) (offset (* mid 2))
                    (candidate (aref +compose-pairs+ offset)))
               (cond ((< key candidate) (setf high mid)) ((> key candidate) (setf low (1+ mid)))
                     (t (return-from composizione-unicode (aref +compose-pairs+ (1+ offset)))))))
           0))))
