(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets spazio-codec-full-text r:indice-posizionale) null)
                scrivi-occorrenze-run scrivi-lunghezze-run))
(defun scrivi-occorrenze-run (buffer space run)
  "Pre: destinazione zero e piano verificato; costo interamente riservato.
Post: DICT/TERMS/POSTINGS/POSITIONS contigue, tutti i conteggi corrispondono al piano."
  (let ((dict 0) (term-bytes 0) (posts 0) (d-entry 0) (p-entry 0) (prior-row -1)
        (data (r::indice-posizionale-tokens run)))
    (dotimes (i (r::indice-posizionale-count run))
      (let* ((p (* i r::+token-width+)) (row (aref data (+ p r::+row+)))
             (new-term (or (zerop i) (not (stesso-termine-run-p run (1- i) i)))))
        (when new-term
          (multiple-value-setq (d-entry term-bytes) (scrivi-termine-run buffer space run i dict term-bytes posts))
          (incf dict))
        (when (or new-term (/= row prior-row))
          (setf p-entry (scrivi-posting-run buffer space row i posts d-entry)) (incf posts))
        (scrivi-u32 buffer (+ p-entry +posting-frequency+) (1+ (leggi-u32 buffer (+ p-entry +posting-frequency+))))
        (scrivi-u32 buffer (+ (aref (spazio-codec-full-text-starts space) 4) (* i +position-width+))
                    (aref data (+ p r::+position+)))
        (setf prior-row row)))
    (unless (and (= (* dict +dict-width+) (aref (spazio-codec-full-text-lengths space) 1))
                 (= term-bytes (aref (spazio-codec-full-text-lengths space) 2))
                 (= (* posts +posting-width+) (aref (spazio-codec-full-text-lengths space) 3)))
      (error 'invariant-violation :reason :fulltext-write-counts)))
  nil)
(defun scrivi-lunghezze-run (buffer space run)
  "Pre: LENGTHS del run ordinate e verificate. Post: entry wire da 16 byte, riservati zero."
  (let ((data (r::indice-posizionale-lengths run)) (base (aref (spazio-codec-full-text-starts space) 5)))
    (unless (<= (+ base (aref (spazio-codec-full-text-lengths space) 5)) (length buffer))
      (error 'invariant-violation :reason :fulltext-write-length-range))
    (dotimes (i (r::indice-posizionale-field-count run))
      (let ((source (* i r::+length-width+)) (target (+ base (* i +length-width+))))
        (scrivi-u32 buffer target (aref data source))
        (scrivi-u16 buffer (+ target +length-field+) (aref data (1+ source)))
        (scrivi-u32 buffer (+ target +length-count+) (aref data (+ source 2)))))
    (unless (= (* (r::indice-posizionale-field-count run) +length-width+)
               (aref (spazio-codec-full-text-lengths space) 5))
      (error 'invariant-violation :reason :fulltext-write-length-result)))
  nil)

;;; REQ: REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (t t t t t t &key (:max-bytes t) (:max-work t)) index) scrivi-indice-full-text))
(defun scrivi-indice-full-text (run descriptor space buffer start end
                              &key (max-bytes f::+default-file-budget+) (max-work 268435456))
  "Pre: run SEALED e descrittore autorevole, destinazione privata, scratch esclusivo.
Post: NEXT del file completo v2/type 5; byte prima/dopo il footprint invariati.
Preflight di contratto/capacita/alias/lavoro prima di scrivere; rifiuti senza modifiche.
Preparazione in memoria, nessun I/O o punto di atomicita durevole. Nessun rollback su
INVARIANT-VIOLATION interna; il proprietario scarta il buffer e applica fail-stop."
  (let ((size (dimensione-indice-full-text run descriptor space :max-bytes max-bytes :max-work max-work)))
    (controlla-buffer-codec buffer start end space descriptor)
    (when (eq buffer (r::indice-posizionale-bytes run))
      (error 'invalid-argument :reason :fulltext-codec-alias))
    (when (> size (- end start)) (error 'resource-exhausted :reason :fulltext-codec-destination))
    ;; Costo conservativo del secondo confronto, zero/copia/scrittura e CRC, prima di mutare.
    (lavoro-codec space (+ (spazio-codec-full-text-work space) (* 4 size)))
    (let ((next (+ start size)))
      (dotimes (i 6) (incf (aref (spazio-codec-full-text-starts space) i) start))
      (fill buffer 0 :start start :end next)
      (replace buffer (descrittore-full-text-meta descriptor) :start1 (aref (spazio-codec-full-text-starts space) 0))
      (scrivi-occorrenze-run buffer space run) (scrivi-lunghezze-run buffer space run)
      (let ((result (f:scrivi-cornice-indice-full-text buffer start next (descrittore-full-text-identity descriptor)
                                                    (car (descrittore-full-text-segment-box descriptor))
                                                    (spazio-codec-full-text-lengths space) :max-bytes max-bytes)))
        (unless (= result next) (error 'invariant-violation :reason :fulltext-write-result)))
      next)))
