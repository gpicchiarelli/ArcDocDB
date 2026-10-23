;;;; OWNER: builder unico; SOURCE resta esclusivo e DONE fino a fine copia.
;;; SHARED: nessuna scrittura tra Serie; run condivisibile solo dopo SEALED.
(in-package #:arcdocdb.fulltext.index)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (t t t t) keyword) inizia-campo-full-text))
(defun inizia-campo-full-text (run row field source)
  "Pre: run BUILDING, campi aggiunti in ordine stretto (riga,field-id), analisi DONE.
Post: COPYING, tutte le capacita riservate; nessun riferimento al testo originale.
Il chiamante non riusa SOURCE fino a BUILDING. Campo vuoto presente e conservato.
INVALID-ARGUMENT/RESOURCE-EXHAUSTED prima di cambiare il run."
  (unless (and (typep run 'indice-posizionale) (eq :building (indice-posizionale-state run))
               (typep row 'u32) (typep field '(integer 1 65535)) (typep source 'a:spazio-full-text)
               (eq :done (a::spazio-full-text-phase source)))
    (error 'invalid-argument :reason :fulltext-index-input))
  (let ((fields (indice-posizionale-field-count run)) (lengths (indice-posizionale-lengths run)))
    (when (plusp fields)
      (let* ((last (* (1- fields) +length-width+)) (prior-row (aref lengths last)))
        (unless (or (> row prior-row) (and (= row prior-row) (> field (aref lengths (1+ last)))))
          (error 'invalid-argument :reason :fulltext-field-order))))
    (unless (and (< (* fields +length-width+) (length lengths))
                 (<= (+ (indice-posizionale-count run) (a::spazio-full-text-token-count source))
                     (floor (length (indice-posizionale-tokens run)) +token-width+))
                 (<= (+ (indice-posizionale-byte-count run) (a::spazio-full-text-byte-count source))
                     (length (indice-posizionale-bytes run))))
      (error 'resource-exhausted :reason :fulltext-index-capacity)))
  (setf (indice-posizionale-source run) source (indice-posizionale-pending-row run) row
        (indice-posizionale-pending-field run) field (indice-posizionale-source-token run) 0
        (indice-posizionale-source-byte run) 0 (indice-posizionale-term-start run) (indice-posizionale-byte-count run)
        (indice-posizionale-state run) :copying)
  :copying)

;;; REQ: REQ-SEC-003 REQ-SEC-007
(declaim (ftype (function (indice-posizionale a:spazio-full-text) null) termina-campo-full-text))
(defun termina-campo-full-text (run source)
  "Pre: tutti i token copiati. Post: lunghezza per campo, rilascio SOURCE, BUILDING.
Il builder puo essere sigillato solo dopo questa transizione."
  (let ((i (* (indice-posizionale-field-count run) +length-width+)) (data (indice-posizionale-lengths run)))
    (setf (aref data i) (indice-posizionale-pending-row run)
          (aref data (1+ i)) (indice-posizionale-pending-field run)
          (aref data (+ i 2)) (a::spazio-full-text-token-count source)))
  (incf (indice-posizionale-field-count run))
  (setf (indice-posizionale-state run) :building (indice-posizionale-source run) nil) nil)

;;; REQ: REQ-SEC-003 REQ-SEC-007
(declaim (ftype (function (indice-posizionale) null) copia-passo-full-text))
(defun copia-passo-full-text (run)
  "Pre: capacita riservata; source ancora DONE e posseduto dal builder.
Post: un byte o un record di occorrenza copiato, oppure completamento campo."
  (let* ((source (indice-posizionale-source run)) (token (indice-posizionale-source-token run)))
    (unless (and source (eq :done (a::spazio-full-text-phase source)))
      (error 'invariant-violation :reason :fulltext-source-reused))
    (when (= token (a::spazio-full-text-token-count source))
      (termina-campo-full-text run source) (return-from copia-passo-full-text nil))
    (let ((position (indice-posizionale-source-byte run)) (end (aref (a::spazio-full-text-ends source) token)))
      (if (< position end)
          (progn (setf (aref (indice-posizionale-bytes run) (indice-posizionale-byte-count run))
                       (aref (a::spazio-full-text-bytes source) position))
                 (incf (indice-posizionale-byte-count run)) (incf (indice-posizionale-source-byte run)))
          (let ((i (* (indice-posizionale-count run) +token-width+)) (data (indice-posizionale-tokens run)))
            (setf (aref data (+ i +field+)) (indice-posizionale-pending-field run)
                  (aref data (+ i +row+)) (indice-posizionale-pending-row run)
                  (aref data (+ i +position+)) token
                  (aref data (+ i +offset+)) (indice-posizionale-term-start run)
                  (aref data (+ i +length+)) (- end (aref (a::spazio-full-text-begins source) token)))
            (incf (indice-posizionale-count run)) (incf (indice-posizionale-source-token run))
            (setf (indice-posizionale-term-start run) (indice-posizionale-byte-count run))))))
  nil)
