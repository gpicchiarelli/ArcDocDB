(in-package #:arcdocdb.fulltext.codec)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index) index) meta-percorso))
(defun meta-percorso (buffer start end)
  "Pre: percorso META. Post: array non vuoto <=100 chiavi testuali minime, fine.
CORRUPTION-DETECTED per forma/profondita o UTF-8; chiavi vuote ammesse."
  (multiple-value-bind (count cursor) (meta-conteggio buffer start end 1 100)
    (dotimes (i count)
      (multiple-value-bind (begin next) (meta-testo buffer cursor end 0 65536)
        (unless (<= begin next end) (error 'invariant-violation :reason :fulltext-path-text))
        (setf cursor next)))
    (unless (< start cursor) (error 'invariant-violation :reason :fulltext-path-progress))
    cursor))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets vettore-u32 index index index index) null) meta-duplicati))
(defun meta-duplicati (buffer spans count alias-start alias-end path-start)
  "Pre: record precedenti a cinque parole; path termina nello slot corrente.
Post: nessun alias/percorso duplicato; al massimo 16 confronti bounded."
  (let ((path-end (aref spans (+ (* count 5) 4))))
    (dotimes (i count)
      (let ((p (* i 5)))
        (when (or (span-uguali-p buffer alias-start alias-end buffer (aref spans (1+ p)) (aref spans (+ p 2)))
                  (span-uguali-p buffer path-start path-end buffer (aref spans (+ p 3)) (aref spans (+ p 4))))
          (error 'corruption-detected :reason :fulltext-meta-duplicate-field)))))
  nil)

;;; REQ: REQ-SEC-008
(declaim (ftype (function (octets index index) (values vettore-u32 index &optional)) meta-campi))
(defun meta-campi (buffer start end)
  "Pre: META <=64KiB, percorso freddo. Post: ID ordinati e cursore; copie private.
CORRUPTION-DETECTED per duplicati, tipi o ordine; allocazioni solo nel descrittore."
  (multiple-value-bind (count cursor) (meta-conteggio buffer start end 1 65535)
    (when (> count 16) (error 'resource-exhausted :reason :fulltext-descriptor-fields))
    (let ((fields (make-array count :element-type 'u32 :initial-element 0))
          (spans (make-array (* count 5) :element-type 'u32 :initial-element 0)) (prior 0))
      (dotimes (i count)
        (multiple-value-bind (width next) (meta-conteggio buffer cursor end 3 3)
          (unless (= width 3) (error 'invariant-violation :reason :fulltext-field-width))
          (setf cursor next))
        (multiple-value-bind (high low next) (meta-positivo buffer cursor end)
          (unless (and (zerop high) (< prior low 65536))
            (error 'corruption-detected :reason :fulltext-meta-field-order))
          (setf prior low (aref fields i) low cursor next))
        (multiple-value-bind (begin next) (meta-testo buffer cursor end 1 64)
          (let* ((p (* i 5)) (path-end (meta-percorso buffer next end)))
            (setf (aref spans p) prior (aref spans (1+ p)) begin (aref spans (+ p 2)) next
                  (aref spans (+ p 3)) next (aref spans (+ p 4)) path-end)
            (meta-duplicati buffer spans i begin next next)
            (setf cursor path-end))))
      (unless (<= cursor end) (error 'invariant-violation :reason :fulltext-fields-result))
      (values fields cursor))))
