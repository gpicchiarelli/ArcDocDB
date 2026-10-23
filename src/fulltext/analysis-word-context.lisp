;;;; Contesto Word_Break costruito con due scansioni lineari riprendibili.
;;; OWNER: un compito per scratch. SHARED: sole tabelle UCD immutabili.
(in-package #:arcdocdb.fulltext.analysis)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-007
(declaim (ftype (function (u32) boolean) wb-ignorato-p wb-lettera-p wb-nuova-riga-p
                wb-mezzo-lettera-p wb-mezzo-numero-p wb-estendibile-p))
(defun wb-ignorato-p (class)
  "Pre: classe Word_Break. Post: T solo per Extend, Format, ZWJ. Nessun errore."
  (not (null (or (= class +wb-extend+) (= class +wb-format+) (= class +wb-zwj+)))))
(defun wb-lettera-p (class)
  "Pre: classe Word_Break. Post: T per AHLetter. Nessun errore."
  (not (null (or (= class +wb-aletter+) (= class +wb-hebrew-letter+)))))
(defun wb-nuova-riga-p (class)
  "Pre: classe Word_Break. Post: T per CR/LF/Newline. Nessun errore."
  (not (null (or (= class +wb-cr+) (= class +wb-lf+) (= class +wb-newline+)))))
(defun wb-mezzo-lettera-p (class)
  "Pre: classe Word_Break. Post: T per MidLetter o MidNumLetQ. Nessun errore."
  (not (null (or (= class +wb-midletter+) (= class +wb-midnumlet+) (= class +wb-single-quote+)))))
(defun wb-mezzo-numero-p (class)
  "Pre: classe Word_Break. Post: T per MidNum o MidNumLetQ. Nessun errore."
  (not (null (or (= class +wb-midnum+) (= class +wb-midnumlet+) (= class +wb-single-quote+)))))
(defun wb-estendibile-p (class)
  "Pre: classe Word_Break. Post: T per AHLetter, Numeric, Katakana. Nessun errore."
  (not (null (or (wb-lettera-p class) (= class +wb-numeric+) (= class +wb-katakana+)))))

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text index) u32) classe-parola))
(defun classe-parola (space i)
  "Pre: I entro B corrente. Post: classe Unicode, oppure Other per sentinella.
RESOURCE-EXHAUSTED se termina il lavoro."
  (if (= i +nessuno+) +wb-other+
      (proprieta-unicode space +word-ranges+ (aref (spazio-full-text-b space) i))))

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text) null) passo-contesto-sinistro passo-contesto-destro))
(defun passo-contesto-sinistro (space)
  "Pre: fase LEFT. Post: un predecessore significativo e conteggio RI inclusivo.
Ignorati conservano il contesto; capacita gia verificata durante la normalizzazione."
  (let ((i (spazio-full-text-cursor space)))
    (when (= i (spazio-full-text-b-count space))
      (setf (spazio-full-text-phase space) :right (spazio-full-text-significant space) +nessuno+)
      (return-from passo-contesto-sinistro nil))
    (let ((class (classe-parola space i)))
      (unless (wb-ignorato-p class)
        (setf (spazio-full-text-significant space) i
              (spazio-full-text-ri-count space)
              (if (= class +wb-regional-indicator+) (1+ (spazio-full-text-ri-count space)) 0)))
      (setf (aref (spazio-full-text-previous space) i) (spazio-full-text-significant space)
            (aref (spazio-full-text-ri space) i) (spazio-full-text-ri-count space)))
    (incf (spazio-full-text-cursor space)))
  nil)
(defun passo-contesto-destro (space)
  "Pre: fase RIGHT, cursore decrescente. Post: un successore significativo inclusivo.
A fine scansione avvia i confini, senza pubblicare risultati parziali."
  (when (zerop (spazio-full-text-cursor space))
    (setf (spazio-full-text-phase space) :boundaries (spazio-full-text-boundary space) 1
          (spazio-full-text-word-start space) 0 (spazio-full-text-has-letter space) nil)
    (return-from passo-contesto-destro nil))
  (let ((i (decf (spazio-full-text-cursor space))))
    (unless (wb-ignorato-p (classe-parola space i)) (setf (spazio-full-text-significant space) i))
    (setf (aref (spazio-full-text-next space) i) (spazio-full-text-significant space)))
  nil)
