(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (r:indice-posizionale index index spazio-codec-full-text) (member -1 0 1))
                confronta-termini-run))
(defun confronta-termini-run (run first second space)
  "Pre: occorrenze valide del run. Post: ordine (campo,termine), senza mutare il run."
  (let* ((data (r::indice-posizionale-tokens run)) (x (* first r::+token-width+))
         (y (* second r::+token-width+)) (a (aref data (+ x r::+field+))) (b (aref data (+ y r::+field+))))
    (lavoro-codec space)
    (unless (= a b) (return-from confronta-termini-run (if (< a b) -1 1)))
    (let ((xs (aref data (+ x r::+offset+))) (ys (aref data (+ y r::+offset+)))
          (bytes (r::indice-posizionale-bytes run)))
      (confronta-span-codec bytes xs (+ xs (aref data (+ x r::+length+)))
                            bytes ys (+ ys (aref data (+ y r::+length+))) space))))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (r:indice-posizionale u32 u16 spazio-codec-full-text) index) cerca-lunghezza-run))
(defun cerca-lunghezza-run (run row field space)
  "Pre: LENGTHS del run ordinate. Post: indice esatto o corruzione; ricerca binaria bounded."
  (let ((low 0) (high (r::indice-posizionale-field-count run)) (data (r::indice-posizionale-lengths run)))
    (loop repeat (1+ high) while (< low high) do
      (lavoro-codec space)
      (let* ((mid (floor (+ low high) 2)) (i (* mid r::+length-width+)) (r (aref data i)) (f (aref data (1+ i))))
        (cond ((or (< r row) (and (= r row) (< f field))) (setf low (1+ mid)))
              ((or (> r row) (> f field)) (setf high mid))
              (t (return-from cerca-lunghezza-run mid)))))
    (error 'corruption-detected :reason :fulltext-missing-length)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (r:indice-posizionale descrittore-full-text spazio-codec-full-text) null)
                controlla-lunghezze-run))
(defun controlla-lunghezze-run (run descriptor space)
  "Pre: run SEALED, scratch riservato. Post: LENGTHS ordinate e prefissi entro COUNT.
Limite token per documento su tutti i campi; presenti vuoti conservati."
  (let ((data (r::indice-posizionale-lengths run)) (total 0) (prior-row -1) (prior-field 0) (row-tokens 0))
    (dotimes (i (r::indice-posizionale-field-count run))
      (lavoro-codec space)
      (let* ((p (* i r::+length-width+)) (row (aref data p)) (field (aref data (1+ p))) (n (aref data (+ p 2))))
        (unless (or (> row prior-row) (and (= row prior-row) (> field prior-field)))
          (error 'corruption-detected :reason :fulltext-length-order))
        (controlla-riga-campo descriptor row field)
        (when (/= row prior-row) (setf row-tokens 0))
        (incf row-tokens n)
        (when (> row-tokens (descrittore-full-text-token-limit descriptor))
          (error 'corruption-detected :reason :fulltext-document-tokens))
        (when (> n (- (r::indice-posizionale-count run) total))
          (error 'corruption-detected :reason :fulltext-length-total))
        (setf (aref (spazio-codec-full-text-prefix space) i) total prior-row row prior-field field)
        (incf total n)))
    (unless (= total (r::indice-posizionale-count run))
      (error 'corruption-detected :reason :fulltext-length-total)))
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (r:indice-posizionale index spazio-codec-full-text) null) controlla-posizione-run))
(defun controlla-posizione-run (run token space)
  "Pre: token del run. Post: posizione entro il campo e non condivisa con altre occorrenze."
  (let* ((data (r::indice-posizionale-tokens run)) (p (* token r::+token-width+))
         (i (cerca-lunghezza-run run (aref data (+ p r::+row+)) (aref data (+ p r::+field+)) space))
         (count (aref (r::indice-posizionale-lengths run) (+ (* i r::+length-width+) 2))))
    (marca-posizione space (aref (spazio-codec-full-text-prefix space) i) count (aref data (+ p r::+position+))))
  nil)
