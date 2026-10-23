;;;; UAX #29 revisione 49: regole fra classi significative, WB5..WB16.
(in-package #:arcdocdb.fulltext.analysis)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-007
(declaim (ftype (function (u32 u32 u32 u32) boolean) unisci-lettere-p unisci-numeri-p))
(defun unisci-lettere-p (a b prior after)
  "Pre: classi sinistra/destra e contesto significativo. Post: regole WB5..WB7c.
Nessuna mutazione o segnalazione."
  (not (null
        (or (and (wb-lettera-p a) (wb-lettera-p b))
            (and (wb-lettera-p a) (wb-mezzo-lettera-p b) (wb-lettera-p after))
            (and (wb-lettera-p prior) (wb-mezzo-lettera-p a) (wb-lettera-p b))
            (and (= a +wb-hebrew-letter+) (= b +wb-single-quote+))
            (and (= a +wb-hebrew-letter+) (= b +wb-double-quote+) (= after +wb-hebrew-letter+))
            (and (= prior +wb-hebrew-letter+) (= a +wb-double-quote+) (= b +wb-hebrew-letter+))))))
(defun unisci-numeri-p (a b prior after)
  "Pre: classi sinistra/destra e contesto. Post: regole WB8..WB12.
Nessuna mutazione o segnalazione."
  (not (null
        (or (and (= a +wb-numeric+) (= b +wb-numeric+))
            (and (wb-lettera-p a) (= b +wb-numeric+))
            (and (= a +wb-numeric+) (wb-lettera-p b))
            (and (= prior +wb-numeric+) (wb-mezzo-numero-p a) (= b +wb-numeric+))
            (and (= a +wb-numeric+) (wb-mezzo-numero-p b) (= after +wb-numeric+))))))

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text index index) boolean) unisci-significativi-p))
(defun unisci-significativi-p (space left right)
  "Pre: destra significativa; sinistra significativa o sentinella. Post: WB5..WB16.
Le ricerche contano nel budget di lavoro."
  (let* ((a (classe-parola space left)) (b (classe-parola space right))
         (p (if (or (= left +nessuno+) (zerop left)) +nessuno+
                (aref (spazio-full-text-previous space) (1- left))))
         (q (if (= (1+ right) (spazio-full-text-b-count space)) +nessuno+
                (aref (spazio-full-text-next space) (1+ right))))
         (prior (classe-parola space p)) (after (classe-parola space q)))
    (not (null
          (or (unisci-lettere-p a b prior after) (unisci-numeri-p a b prior after)
              (and (= a +wb-katakana+) (= b +wb-katakana+))
              (and (or (wb-estendibile-p a) (= a +wb-extendnumlet+)) (= b +wb-extendnumlet+))
              (and (= a +wb-extendnumlet+) (wb-estendibile-p b))
              (and (= a +wb-regional-indicator+) (= b +wb-regional-indicator+)
                   (oddp (aref (spazio-full-text-ri space) left))))))))

;;; REQ: REQ-SEC-007
(declaim (ftype (function (spazio-full-text index) boolean) confine-parola-p))
(defun confine-parola-p (space right)
  "Pre: contesti costruiti, 0 <= RIGHT <= numero scalari. Post: confine UAX #29.
WB1/2/3 precedono WB4; i contesti successivi saltano Extend/Format/ZWJ."
  (let ((n (spazio-full-text-b-count space)))
    (when (or (zerop right) (= right n)) (return-from confine-parola-p t))
    (let* ((left (1- right)) (a (classe-parola space left)) (b (classe-parola space right)))
      (cond ((and (= a +wb-cr+) (= b +wb-lf+)) nil)
            ((or (wb-nuova-riga-p a) (wb-nuova-riga-p b)) t)
            ((and (= a +wb-zwj+)
                  (plusp (proprieta-unicode space +pict-ranges+ (aref (spazio-full-text-b space) right)))) nil)
            ((and (= a +wb-wsegspace+) (= b +wb-wsegspace+)) nil)
            ((wb-ignorato-p b) nil)
            (t (not (unisci-significativi-p space (aref (spazio-full-text-previous space) left) right)))))))
