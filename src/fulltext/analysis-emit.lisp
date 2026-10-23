;;;; Emissione UTF-8 dei segmenti contenenti almeno una lettera o un numero.
(in-package #:arcdocdb.fulltext.analysis)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (spazio-full-text scalare) null) emetti-scalare-full-text))
(defun emetti-scalare-full-text (space cp)
  "Pre: scalare normalizzato. Post: UTF-8 aggiunto entro budget prima della scrittura.
RESOURCE-EXHAUSTED per termine o buffer insufficienti; nessuna troncatura."
  (let* ((width (cond ((< cp #x80) 1) ((< cp #x800) 2) ((< cp #x10000) 3) (t 4)))
         (start (spazio-full-text-byte-count space)) (end (+ start width))
         (buffer (spazio-full-text-bytes space)))
    (when (> (- end (spazio-full-text-term-start space)) (spazio-full-text-term-limit space))
      (error 'resource-exhausted :reason :fulltext-term-bytes))
    (when (> end (length buffer)) (error 'resource-exhausted :reason :fulltext-token-bytes))
    (consuma-lavoro-full-text space width)
    (setf (aref buffer start) (if (= width 1) cp
                                (logior (ecase width (2 #xc0) (3 #xe0) (4 #xf0))
                                        (ash cp (- (* 6 (1- width)))))))
    (loop for i from 1 below width do
      (setf (aref buffer (+ start i)) (logior #x80 (logand #x3f (ash cp (- (* 6 (- width i 1))))))))
    (setf (spazio-full-text-byte-count space) end))
  nil)

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text) null) termina-analisi-full-text passo-emissione-full-text
                passo-confini-full-text))
(defun termina-analisi-full-text (space)
  "Pre: analisi conclusa. Post: DONE e rilascio del prestito input; nessuna pubblicazione."
  (setf (spazio-full-text-phase space) :done (spazio-full-text-input space) nil)
  nil)
(defun passo-emissione-full-text (space)
  "Pre: fase EMIT. Post: uno scalare o chiusura del token con posizione consecutiva.
Gli offset rimangono privati fino al completamento di tutti i token."
  (if (< (spazio-full-text-emit-pos space) (spazio-full-text-emit-end space))
      (progn (emetti-scalare-full-text space (aref (spazio-full-text-b space) (spazio-full-text-emit-pos space)))
             (incf (spazio-full-text-emit-pos space)))
      (let ((token (spazio-full-text-token-count space)) (end (spazio-full-text-emit-end space)))
        (setf (aref (spazio-full-text-begins space) token) (spazio-full-text-term-start space)
              (aref (spazio-full-text-ends space) token) (spazio-full-text-byte-count space))
        (incf (spazio-full-text-token-count space))
        (setf (spazio-full-text-phase space) :boundaries (spazio-full-text-word-start space) end
              (spazio-full-text-boundary space) (1+ end) (spazio-full-text-has-letter space) nil)))
  nil)
(defun passo-confini-full-text (space)
  "Pre: contesti costruiti. Post: un confine esaminato o avvio emissione.
RESOURCE-EXHAUSTED prima del token oltre limite; stringa vuota produce zero token."
  (let ((i (spazio-full-text-boundary space)) (n (spazio-full-text-b-count space)))
    (when (> i n) (termina-analisi-full-text space) (return-from passo-confini-full-text nil))
    (when (plusp (proprieta-unicode space +letter-ranges+ (aref (spazio-full-text-b space) (1- i))))
      (setf (spazio-full-text-has-letter space) t))
    (if (and (confine-parola-p space i) (spazio-full-text-has-letter space))
        (progn
          (when (= (spazio-full-text-token-count space) (spazio-full-text-token-limit space))
            (error 'resource-exhausted :reason :fulltext-token-count))
          (setf (spazio-full-text-phase space) :emit
                (spazio-full-text-emit-pos space) (spazio-full-text-word-start space)
                (spazio-full-text-emit-end space) i (spazio-full-text-term-start space) (spazio-full-text-byte-count space)))
        (progn
          (when (confine-parola-p space i)
            (setf (spazio-full-text-word-start space) i (spazio-full-text-has-letter space) nil))
          (incf (spazio-full-text-boundary space)))))
  nil)
