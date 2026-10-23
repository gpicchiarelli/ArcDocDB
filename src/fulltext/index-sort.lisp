;;;; Ordinamento in-place: heap binario, profondita <= 32 con conteggi u32.
(in-package #:arcdocdb.fulltext.index)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function ((or indice-posizionale a:spazio-full-text)) null) lavoro-confronto))
(defun lavoro-confronto (owner)
  "Pre: budget esclusivo del builder o della query. Post: una unita consumata."
  (etypecase owner
    (indice-posizionale (consuma-lavoro-indice owner))
    (a:spazio-full-text (a::consuma-lavoro-full-text owner))))

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (octets index index octets index index
                                 (or indice-posizionale a:spazio-full-text)) (member -1 0 1)) confronta-termini))
(defun confronta-termini (a start-a size-a b start-b size-b owner)
  "Pre: span di termini validati. Post: confronto lessicografico UTF-8, senza locale.
Ogni byte confrontato consuma lavoro; RESOURCE-EXHAUSTED al limite."
  (loop for i below (min size-a size-b) do
    (lavoro-confronto owner)
    (let ((x (aref a (+ start-a i))) (y (aref b (+ start-b i))))
      (when (< x y) (return-from confronta-termini -1))
      (when (> x y) (return-from confronta-termini 1))))
  (lavoro-confronto owner)
  (cond ((< size-a size-b) -1) ((> size-a size-b) 1) (t 0)))

;;; REQ: REQ-SEC-003 REQ-SEC-004
(declaim (ftype (function (indice-posizionale index index) boolean) token-minore-p))
(defun token-minore-p (run first second)
  "Pre: due occorrenze entro COUNT. Post: ordine stretto (field,termine,riga,posizione).
Nessun oggetto per token; il confronto non cambia il contenuto."
  (consuma-lavoro-indice run)
  (let* ((data (indice-posizionale-tokens run)) (x (* first +token-width+)) (y (* second +token-width+))
         (fx (aref data (+ x +field+))) (fy (aref data (+ y +field+))))
    (unless (= fx fy) (return-from token-minore-p (< fx fy)))
    (let ((order (confronta-termini (indice-posizionale-bytes run) (aref data (+ x +offset+))
                                  (aref data (+ x +length+)) (indice-posizionale-bytes run)
                                  (aref data (+ y +offset+)) (aref data (+ y +length+)) run)))
      (unless (zerop order) (return-from token-minore-p (minusp order))))
    (let ((rx (aref data (+ x +row+))) (ry (aref data (+ y +row+))))
      (if (= rx ry) (< (aref data (+ x +position+)) (aref data (+ y +position+))) (< rx ry)))))

;;; REQ: REQ-SEC-003 REQ-SEC-004
(declaim (ftype (function (indice-posizionale index index) null) scambia-token))
(defun scambia-token (run first second)
  "Pre: indici di token ammessi. Post: cinque parole scambiate, payload invariato."
  (consuma-lavoro-indice run +token-width+)
  (let ((data (indice-posizionale-tokens run)) (x (* first +token-width+)) (y (* second +token-width+)))
    (dotimes (i +token-width+) (rotatef (aref data (+ x i)) (aref data (+ y i)))))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-004 REQ-SEC-010
(declaim (ftype (function (indice-posizionale index index) null) ripara-heap-token))
(defun ripara-heap-token (run root end)
  "Pre: sottoalberi gia heap, END esclusivo. Post: sottoalbero riparato entro 32 livelli.
RESOURCE-EXHAUSTED lascia run non leggibile; nessuna pubblicazione intermedia."
  (loop repeat 32 do
    (let ((child (1+ (* 2 root))))
      (when (>= child end) (return-from ripara-heap-token nil))
      (when (and (< (1+ child) end) (token-minore-p run child (1+ child))) (incf child))
      (unless (token-minore-p run root child) (return-from ripara-heap-token nil))
      (scambia-token run root child) (setf root child)))
  (error 'invariant-violation :reason :fulltext-heap-depth))

;;; REQ: REQ-SEC-003 REQ-SEC-004
(declaim (ftype (function (indice-posizionale) null) ordina-passo-full-text))
(defun ordina-passo-full-text (run)
  "Pre: fase heap BUILD/SORT. Post: un sottoalbero riparato o un massimo estratto.
La transizione SEALED avviene solo dopo l'ultimo elemento."
  (if (eq :heap-build (indice-posizionale-state run))
      (if (zerop (indice-posizionale-heap run)) (setf (indice-posizionale-state run) :heap-sort)
          (ripara-heap-token run (decf (indice-posizionale-heap run)) (indice-posizionale-count run)))
      (if (<= (indice-posizionale-heap-end run) 1) (setf (indice-posizionale-state run) :sealed)
          (let ((end (decf (indice-posizionale-heap-end run))))
            (scambia-token run 0 end) (ripara-heap-token run 0 end))))
  nil)
