(in-package #:arcdocdb.fulltext.document)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text index index octets) boolean) chiave-documento-p))
(defun chiave-documento-p (task start end key)
  "Pre: payload UTF-8 verificato nel documento; chiave posseduta dalla configurazione.
Post: confronto esatto, budget per byte; nessuna normalizzazione delle chiavi."
  (lavoro-documento task)
  (unless (= (- end start) (length key)) (return-from chiave-documento-p nil))
  (loop for i below (length key) always
    (progn (lavoro-documento task) (= (aref (preparazione-full-text-input task) (+ start i)) (aref key i)))))

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text index index index boolean) null) seleziona-chiave-documento))
(defun seleziona-chiave-documento (task top start end tagged)
  "Pre: chiave testuale completata; TOP e il frame mappa prima dello step CBOR.
Post: mask dei percorsi corrispondenti, duplicati della chiave selezionata rifiutati.
Chiavi con tag non corrispondono a chiavi testuali semplici."
  (let ((mask 0) (active (aref (preparazione-full-text-masks task) top))
        (level (aref (preparazione-full-text-levels task) top))
        (fields (configurazione-full-text-fields (preparazione-full-text-config task))))
    (unless tagged
      (dotimes (i (length fields))
        (when (logbitp i active)
          (let ((path (campo-full-text-path (svref fields i))))
            (unless (< level (length path)) (error 'invariant-violation :reason :fulltext-path-level))
            (when (chiave-documento-p task start end (svref path level)) (setf mask (logior mask (ash 1 i))))))))
    (when (logtest mask (aref (preparazione-full-text-seen task) top))
      (error 'invalid-argument :reason :fulltext-duplicate-path-key :offset start))
    (setf (aref (preparazione-full-text-seen task) top)
          (logior mask (aref (preparazione-full-text-seen task) top))
          (aref (preparazione-full-text-pending task) top) mask))
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text index index index) null) conserva-campo-documento))
(defun conserva-campo-documento (task field start end)
  "Pre: foglia MT3 verificata. Post: span relativo e somma input entro limite dichiarato.
INVALID-ARGUMENT per doppia assegnazione; RESOURCE-EXHAUSTED prima di oltrepassare input."
  (unless (<= (preparazione-full-text-start task) start end (preparazione-full-text-end task))
    (error 'invariant-violation :reason :fulltext-document-field-span))
  (when (= 1 (sbit (preparazione-full-text-present task) field))
    (error 'invalid-argument :reason :fulltext-duplicate-field))
  (let ((limit (aref (configurazione-full-text-effective (preparazione-full-text-config task)) 0)))
    (when (> (- end start) (- limit (preparazione-full-text-input-bytes task)))
      (error 'resource-exhausted :reason :fulltext-document-input-budget)))
  (incf (preparazione-full-text-input-bytes task) (- end start))
  (setf (aref (preparazione-full-text-begins task) field) (- start (preparazione-full-text-start task))
        (aref (preparazione-full-text-ends task) field) (- end (preparazione-full-text-start task))
        (sbit (preparazione-full-text-present task) field) 1)
  nil)

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (preparazione-full-text index (unsigned-byte 3) index index boolean) null)
                seleziona-valore-documento))
(defun seleziona-valore-documento (task top major start end tagged)
  "Pre: valore completato o contenitore aperto dal kernel CBOR. Post: foglie conservate
o mask trasferita alla mappa figlia. Un antenato presente non mappa e un errore di tipo."
  (let ((active (aref (preparazione-full-text-pending task) top)) (children 0)
        (level (aref (preparazione-full-text-levels task) top))
        (fields (configurazione-full-text-fields (preparazione-full-text-config task))))
    (dotimes (i (length fields))
      (when (logbitp i active)
        (lavoro-documento task)
        (if (= (1+ level) (length (campo-full-text-path (svref fields i))))
            (progn
              (unless (and (= major 3) (not tagged))
                (error 'invalid-argument :reason :fulltext-document-field-type :offset start))
              (conserva-campo-documento task i start end))
            (progn
              (unless (and (= major 5) (not tagged))
                (error 'invalid-argument :reason :fulltext-document-path-type :offset start))
              (setf children (logior children (ash 1 i)))))))
    (when (plusp children)
      (unless (= (cb::spazio-cbor-top (preparazione-full-text-cbor task)) (1+ top))
        (error 'invariant-violation :reason :fulltext-document-child-frame))
      (setf (aref (preparazione-full-text-masks task) (1+ top)) children
            (aref (preparazione-full-text-levels task) (1+ top)) (1+ level)))
  (setf (aref (preparazione-full-text-pending task) top) 0)
  nil))
