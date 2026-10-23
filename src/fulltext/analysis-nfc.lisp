;;;; NFC canonica riprendibile: decomposizione con stack, riordino stabile, composizione.
;;; OWNER: scratch esclusivo del compito; nessuna scrittura delle tabelle Unicode.
;;; SHARED: sole letture dei dati UCD 18.0.0 fra Serie.
(in-package #:arcdocdb.fulltext.analysis)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (spazio-full-text scalare) null) push-scalare-nfc))
(defun push-scalare-nfc (space scalar)
  "Pre: stack esclusivo. Post: scalare aggiunto entro la profondita fissata.
RESOURCE-EXHAUSTED se la decomposizione richiede piu di 64 elementi pendenti."
  (let ((top (spazio-full-text-stack-top space)))
    (when (= top +stack-capacity+) (error 'resource-exhausted :reason :fulltext-decomposition-stack))
    (consuma-lavoro-full-text space)
    (setf (aref (spazio-full-text-stack space) top) scalar
          (spazio-full-text-stack-top space) (1+ top)))
  nil)

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text scalare) boolean) espandi-scalare-nfc))
(defun espandi-scalare-nfc (space cp)
  "Pre: scalare estratto dallo stack. Post: T se espanso in ordine inverso nello stack.
Hangul algoritmico, altrimenti soli mapping canonici; lavoro e stack limitati."
  (cond ((<= #xac00 cp #xd7a3)
         (let* ((s (- cp #xac00)) (tail (mod s 28)))
           (unless (zerop tail) (push-scalare-nfc space (+ #x11a7 tail)))
           (push-scalare-nfc space (+ #x1161 (mod (floor s 28) 21)))
           (push-scalare-nfc space (+ #x1100 (floor s 588)))) t)
        (t (let ((entry (trova-mapping space +decomp-records+ cp)))
             (when (minusp entry) (return-from espandi-scalare-nfc nil))
             (let ((offset (aref +decomp-records+ (1+ entry)))
                   (count (aref +decomp-records+ (+ entry 2))))
               (loop for i downfrom (1- count) to 0 do
                 (push-scalare-nfc space (aref +decomp-data+ (+ offset i))))) t))))

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text) null) passo-decomposizione-nfc))
(defun passo-decomposizione-nfc (space)
  "Pre: fase DECOMPOSE, A sorgente stabile. Post: un'espansione o scalare in B.
Capacita e lavoro controllati; nessuna ricorsione o lista sul percorso caldo."
  (when (zerop (spazio-full-text-stack-top space))
    (when (= (spazio-full-text-cursor space) (spazio-full-text-a-count space))
      (setf (spazio-full-text-phase space) :reorder (spazio-full-text-cursor space) 1
            (spazio-full-text-order-pos space) 1)
      (return-from passo-decomposizione-nfc nil))
    (push-scalare-nfc space (aref (spazio-full-text-a space) (spazio-full-text-cursor space)))
    (incf (spazio-full-text-cursor space)))
  (let* ((top (decf (spazio-full-text-stack-top space)))
         (cp (aref (spazio-full-text-stack space) top)))
    (unless (espandi-scalare-nfc space cp)
      (setf (spazio-full-text-b-count space)
            (aggiungi-scalare space (spazio-full-text-b space) (spazio-full-text-b-count space) cp))))
  nil)

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text) null) prepara-composizione-nfc))
(defun prepara-composizione-nfc (space)
  "Pre: B decomposto e riordinato. Post: cursori iniziali della composizione.
Caso vuoto esplicito; nessuna lettura fuori dalla lunghezza corrente."
  (setf (spazio-full-text-phase space) :compose (spazio-full-text-cursor space) 1
        (spazio-full-text-write space) (min 1 (spazio-full-text-b-count space)))
  (let ((ccc (if (zerop (spazio-full-text-b-count space)) 0
                 (proprieta-unicode space +ccc-ranges+ (aref (spazio-full-text-b space) 0)))))
    (setf (spazio-full-text-starter space) (if (zerop ccc) 0 -1)
          (spazio-full-text-last-ccc space) ccc))
  nil)

;;; REQ: REQ-SEC-007 REQ-SEC-010
(declaim (ftype (function (spazio-full-text) null) passo-riordino-nfc))
(defun passo-riordino-nfc (space)
  "Pre: B decomposto. Post: al massimo uno scambio adiacente del riordino stabile.
Anche sequenze combinanti lunghe cedono il compito fra due confronti."
  (when (>= (spazio-full-text-cursor space) (spazio-full-text-b-count space))
    (prepara-composizione-nfc space) (return-from passo-riordino-nfc nil))
  (let* ((j (spazio-full-text-order-pos space)) (buffer (spazio-full-text-b space))
         (current (proprieta-unicode space +ccc-ranges+ (aref buffer j))))
    (if (and (plusp j) (plusp current)
             (> (proprieta-unicode space +ccc-ranges+ (aref buffer (1- j))) current))
        (progn (rotatef (aref buffer j) (aref buffer (1- j)))
               (decf (spazio-full-text-order-pos space)))
        (setf (spazio-full-text-order-pos space) (incf (spazio-full-text-cursor space)))))
  nil)

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text) null) termina-composizione-nfc))
(defun termina-composizione-nfc (space)
  "Pre: composizione conclusa. Post: lunghezza compatta e fase successiva esplicita."
  (setf (spazio-full-text-b-count space) (spazio-full-text-write space)
        (spazio-full-text-cursor space) 0)
  (cond ((spazio-full-text-nfc-only space) (setf (spazio-full-text-phase space) :done))
        ((= 1 (spazio-full-text-pass space))
         (setf (spazio-full-text-phase space) :fold (spazio-full-text-a-count space) 0))
        (t (setf (spazio-full-text-phase space) :left (spazio-full-text-significant space) +nessuno+
                 (spazio-full-text-ri-count space) 0)))
  nil)

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text) null) passo-composizione-nfc))
(defun passo-composizione-nfc (space)
  "Pre: B riordinato, cursori validi. Post: una composizione o copia, anche Hangul.
Si conserva il blocco CCC della norma; nessun dato viene pubblicato."
  (when (>= (spazio-full-text-cursor space) (spazio-full-text-b-count space))
    (termina-composizione-nfc space) (return-from passo-composizione-nfc nil))
  (let* ((source-position (spazio-full-text-cursor space)) (buffer (spazio-full-text-b space))
         (cp (aref buffer source-position)) (ccc (proprieta-unicode space +ccc-ranges+ cp))
         (starter (spazio-full-text-starter space))
         (composed (if (and (>= starter 0)
                            (or (zerop (spazio-full-text-last-ccc space))
                                (< (spazio-full-text-last-ccc space) ccc)))
                       (composizione-unicode space (aref buffer starter) cp) 0)))
    (if (plusp composed) (setf (aref buffer starter) composed)
        (let ((write (spazio-full-text-write space)))
          (setf (aref buffer write) cp (spazio-full-text-last-ccc space) ccc)
          (when (zerop ccc) (setf (spazio-full-text-starter space) write))
          (incf (spazio-full-text-write space))))
    (incf (spazio-full-text-cursor space)))
  nil)

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text) null) passo-case-folding))
(defun passo-case-folding (space)
  "Pre: B in NFC. Post: un mapping completo C/F in A, oppure avvio della seconda NFC.
Nessuna locale o mapping turco; array e lavoro limitati."
  (when (= (spazio-full-text-cursor space) (spazio-full-text-b-count space))
    (setf (spazio-full-text-phase space) :decompose (spazio-full-text-pass space) 2
          (spazio-full-text-cursor space) 0 (spazio-full-text-b-count space) 0)
    (return-from passo-case-folding nil))
  (let* ((cp (aref (spazio-full-text-b space) (spazio-full-text-cursor space)))
         (entry (trova-mapping space +fold-records+ cp)))
    (if (minusp entry)
        (setf (spazio-full-text-a-count space)
              (aggiungi-scalare space (spazio-full-text-a space) (spazio-full-text-a-count space) cp))
        (let ((offset (aref +fold-records+ (1+ entry))) (count (aref +fold-records+ (+ entry 2))))
          (dotimes (i count)
            (setf (spazio-full-text-a-count space)
                  (aggiungi-scalare space (spazio-full-text-a space) (spazio-full-text-a-count space)
                                    (aref +fold-data+ (+ offset i)))))))
    (incf (spazio-full-text-cursor space)))
  nil)
