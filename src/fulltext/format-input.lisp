;;;; Preflight completo prima di leggere intestazioni o modificare destinazioni.
;;; OWNER: buffer, identita e lunghezze sono del chiamante e stabili per la chiamata.
;;; SHARED: nessuno stato globale mutabile, lock o I/O tra Serie.
(in-package #:arcdocdb.fulltext.format)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-008 REQ-SEC-010
(declaim (ftype (function (t t t t t t) (values index &optional)) controlla-input-cornice))
(defun controlla-input-cornice (buffer start end identity segment-id max-bytes)
  "Pre: argomenti non fidati. Post: dimensione dello span simple u8 verificato.
INVALID-ARGUMENT per range, ID, segment-id o budget; nessun byte letto o modificato."
  (unless (and (typep buffer 'octets) (typep start 'index) (typep end 'index)
               (<= start end (length buffer)))
    (error 'invalid-argument :reason :fulltext-range))
  (unless (and (typep identity 'octets) (= (length identity) +identity-bytes+))
    (error 'invalid-argument :reason :fulltext-identity))
  (unless (typep segment-id 'u64)
    (error 'invalid-argument :reason :fulltext-segment))
  (unless (and (typep max-bytes 'index) (plusp max-bytes))
    (error 'invalid-argument :reason :fulltext-byte-budget))
  (- end start))

;;; REQ: REQ-SEC-008
(declaim (ftype (function (t index) (values index &optional)) controlla-lunghezze-cornice))
(defun controlla-lunghezze-cornice (lengths size)
  "Pre: SIZE dello span valido. Post: fine del payload relativa allo span.
INVALID-ARGUMENT per lunghezze/layout; RESOURCE-EXHAUSTED per capacita insufficiente.
Nessuna scrittura; sei iterazioni, somme successive solo entro SIZE."
  (unless (typep lengths '(simple-array (unsigned-byte 64) (6)))
    (error 'invalid-argument :reason :fulltext-section-lengths))
  (unless (<= 1 (aref lengths 0) +meta-max-bytes+)
    (error 'invalid-argument :reason :fulltext-meta-length))
  (when (< size (+ +sections-offset+ +footer-bytes+))
    (error 'resource-exhausted :reason :fulltext-capacity))
  (let ((cursor +sections-offset+) (limit (- size +footer-bytes+)))
    (dotimes (section +section-count+)
      (let ((length (aref lengths section)))
        (unless (zerop (mod length (larghezza-sezione-full-text section)))
          (error 'invalid-argument :reason :fulltext-section-width))
        (when (> length (- limit cursor))
          (error 'resource-exhausted :reason :fulltext-capacity))
        (incf cursor length)
        (when (< section (1- +section-count+))
          (when (> (- (allinea-indice-full-text cursor) cursor) (- limit cursor))
            (error 'resource-exhausted :reason :fulltext-capacity))
          (setf cursor (allinea-indice-full-text cursor)))))
    (unless (= cursor limit)
      (error 'invalid-argument :reason :fulltext-file-length))
    cursor))
