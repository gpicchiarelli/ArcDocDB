(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (r:indice-posizionale descrittore-full-text spazio-codec-full-text)
                         (values index index index &optional)) conta-run))
(defun conta-run (run descriptor space)
  "Pre: run sigillato, LENGTHS verificate. Post: termini, byte unici e posting; ordini esatti.
Posizioni e righe validate prima di ammettere qualunque byte della destinazione."
  (let ((dict 0) (bytes 0) (postings 0) (data (r::indice-posizionale-tokens run)))
    (dotimes (i (r::indice-posizionale-count run))
      (lavoro-codec space)
      (let* ((p (* i r::+token-width+)) (size (aref data (+ p r::+length+)))
             (order (if (zerop i) -1 (confronta-termini-run run (1- i) i space)))
             (previous (- p r::+token-width+)))
        (unless (<= 1 size (descrittore-full-text-term-limit descriptor))
          (error 'corruption-detected :reason :fulltext-term-length))
        (when (plusp order) (error 'corruption-detected :reason :fulltext-dictionary-order))
        (if (minusp order) (progn (incf dict) (incf bytes size) (incf postings))
            (let ((a (aref data (+ previous r::+row+))) (b (aref data (+ p r::+row+))))
              (when (> a b) (error 'corruption-detected :reason :fulltext-posting-order))
              (when (and (= a b) (>= (aref data (+ previous r::+position+)) (aref data (+ p r::+position+))))
                (error 'corruption-detected :reason :fulltext-position-order))
              (when (< a b) (incf postings))))
        (controlla-posizione-run run i space)))
    (verifica-copertura space (r::indice-posizionale-count run))
    (values dict bytes postings)))

;;; REQ: REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (spazio-codec-full-text index) index) pianifica-sezioni))
(defun pianifica-sezioni (space max-bytes)
  "Pre: sei lunghezze calcolate da dati bounded. Post: offset relativi e dimensione file.
RESOURCE-EXHAUSTED prima della somma che supererebbe MAX-BYTES; nessuna scrittura esterna."
  (let ((cursor f::+sections-offset+))
    (dotimes (i 6)
      (lavoro-codec space)
      (let ((n (aref (spazio-codec-full-text-lengths space) i)))
        (when (> cursor max-bytes) (error 'resource-exhausted :reason :fulltext-file-budget))
        (when (> n (- max-bytes cursor)) (error 'resource-exhausted :reason :fulltext-file-budget))
        (setf (aref (spazio-codec-full-text-starts space) i) cursor)
        (incf cursor n)
        (when (< i 5) (setf cursor (f::allinea-indice-full-text cursor)))))
    (when (> (+ cursor f::+footer-bytes+) max-bytes)
      (error 'resource-exhausted :reason :fulltext-file-budget))
    (+ cursor f::+footer-bytes+)))

;;; REQ: REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (t t t &key (:max-bytes t) (:max-work t)) index) dimensione-indice-full-text))
(defun dimensione-indice-full-text (run descriptor space &key (max-bytes f::+default-file-budget+)
                                                           (max-work 268435456))
  "Pre: run SEALED immutabile e descrittore autorevole. Post: dimensione esatta e piano privato.
Verifica contratto locale, righe e copertura posizionale prima della serializzazione.
Nessuna destinazione modificata; errori di dominio espliciti, nessuna riserva nel writer."
  (prepara-codec descriptor space max-work max-bytes)
  (unless (and (typep run 'r:indice-posizionale) (eq :sealed (r::indice-posizionale-state run)))
    (error 'invalid-argument :reason :fulltext-codec-run))
  (prepara-copertura space (r::indice-posizionale-field-count run) (r::indice-posizionale-count run))
  (controlla-lunghezze-run run descriptor space)
  (multiple-value-bind (dict bytes postings) (conta-run run descriptor space)
    (let ((sizes (spazio-codec-full-text-lengths space)))
      (setf (aref sizes 0) (length (descrittore-full-text-meta descriptor))
            (aref sizes 1) (* dict +dict-width+) (aref sizes 2) bytes
            (aref sizes 3) (* postings +posting-width+)
            (aref sizes 4) (* (r::indice-posizionale-count run) +position-width+)
            (aref sizes 5) (* (r::indice-posizionale-field-count run) +length-width+))))
  (pianifica-sezioni space max-bytes))
