;;; OWNER: mutex della striscia, senza attesa; una mano CLOCK per insieme.
;;; SHARED: calore/rilettura approssimativi, scritti anche dai reader; nessuna correttezza dipende da essi.
(in-package #:arcdocdb.cache)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CCH-001 REQ-CCH-004
(declaim (ftype (function (classe-cache cache-set u32 u32 u32 u32) boolean) gia-in-cache-p))
(defun gia-in-cache-p (class set high low offset size)
  "Pre: mutex della striscia detenuto; input verificato separatamente.
Post: presenza di un posto leggibile per la stessa location, al massimo otto tag.
Nessuna prova dell'integrità dei byte in cache: ogni lettura li verifica di nuovo."
  (let ((base (* set +cache-ways+)))
    (dotimes (way +cache-ways+ nil)
      (let* ((slot (+ base way)) (sequence (aref (classe-cache-sequences class) slot)))
        (declare (type u64 sequence))
        (when (and (zerop (aref (classe-cache-disabled class) slot))
                   (zerop (aref (classe-cache-rejected class) slot))
                   (< sequence +cache-sequence-limit+) (evenp sequence)
                   (tag-cache-p class slot high low offset size))
          (return t))))))

;;; REQ: REQ-CCH-001 REQ-CCH-004 REQ-AFF-008
(declaim (ftype (function (classe-cache cache-slot) boolean) credito-posto-cache-p))
(defun credito-posto-cache-p (class slot)
  "Pre: mutex della striscia detenuto. Post: T se una nuova pubblicazione pari è possibile.
Sequenza dispari/esaurita o disable preesistente => posto disabilitato, senza wrap né errore del DB."
  (let ((sequence (aref (classe-cache-sequences class) slot)))
    (declare (type u64 sequence))
    (when (or (plusp (aref (classe-cache-disabled class) slot))
              (oddp sequence) (>= sequence (- +cache-sequence-limit+ 2)))
      (setf (aref (classe-cache-disabled class) slot) 1)
      (return-from credito-posto-cache-p nil))
    t))

;;; REQ: REQ-CCH-001 REQ-CCH-004
(declaim (ftype (function (classe-cache cache-set) (or null cache-slot)) scegli-vittima-cache))
(defun scegli-vittima-cache (class set)
  "Pre: mutex della striscia detenuto. Post: posto con credito, preferendo vuoto/rifiutato/freddo.
Al massimo due giri di otto posti; i reader possono riaccendere tutti i bit => NIL, mai attesa."
  (let ((base (* set +cache-ways+)) (hands (classe-cache-hands class)))
    (dotimes (visit (* 2 +cache-ways+) nil)
      (let* ((hand (logand (aref hands set) (1- +cache-ways+))) (slot (+ base hand)))
        (setf (aref hands set) (logand (1+ hand) (1- +cache-ways+)))
        (when (credito-posto-cache-p class slot)
          (when (or (zerop (aref (classe-cache-tags class)
                                (+ (* slot +cache-tag-words+) 3)))
                    (plusp (aref (classe-cache-rejected class) slot))
                    (zerop (aref (classe-cache-references class) slot)))
            (return slot))
          (setf (aref (classe-cache-references class) slot) 0))))))
