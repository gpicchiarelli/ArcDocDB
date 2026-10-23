;;; OWNER: worker GET acquisisce la mappa dal controller sotto l'epoca corrente.
;;; SHARED: solo lettura di array posseduti dalla Serie; nessun lock, contatore o attesa.
(in-package #:arcdocdb.get.resolver)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (contesto-get resolver-words u32) index) trova-riga-resolver))
(defun trova-riga-resolver (context rows offset)
  "Pre: CANDIDATE sotto EBR, righe immutabili ordinate per offset. Post: base del PUT esatto.
Assenza non significa documento assente: location già pubblicata senza riga rende FAULTED.
Al più 33 passi su cardinalità u32; nessuna allocazione esplicita o I/O."
  (unless (zerop (mod (length rows) +row-words+)) (guasto-get context :resolver-row-shape))
  (let ((left 0) (right (floor (length rows) +row-words+)))
    (declare (type u32 left right))
    (loop repeat +binary-attempts+
          do (when (= left right) (guasto-get context :resolver-location-absent))
             (let* ((middle (+ left (floor (- right left) 2))) (base (* middle +row-words+))
                    (actual (aref rows (+ base +row-offset+))))
               (cond
                 ((< actual offset) (setf left (1+ middle)))
                 ((> actual offset) (setf right middle))
                 (t (return-from trova-riga-resolver base)))))
    (guasto-get context :resolver-row-search-bound)))

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (contesto-get resolver-words index) null) verifica-parole-resolver))
(defun verifica-parole-resolver (context rows base)
  "Pre: riga completa individuata sotto EBR. Post: lunghezza canonica e CSN in entrambe le word.
Ogni discordanza col candidato rende GET FAULTED; nessun boxing u64 necessario."
  (let ((content (contesto-get-content context)))
    (unless (and (= (aref rows (+ base +row-size+)) (ldb (byte 32 0) (aref content 3)))
                 (zerop (ldb (byte 32 32) (aref content 3))))
      (guasto-get context :resolver-candidate-size))
    (unless (and (= (aref rows (+ base +row-csn-low+)) (ldb (byte 32 0) (aref content 0)))
                 (= (aref rows (+ base +row-csn-high+)) (ldb (byte 32 32) (aref content 0))))
      (guasto-get context :resolver-candidate-csn)))
  nil)

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (contesto-get mappa-segmento-get index)
                         (values u8 (or null u32) &optional)) verifica-riga-resolver))
(defun verifica-riga-resolver (context map base)
  "Pre: riga individuata sotto la stessa epoca del candidato. Post: size/CSN/flag e prova concordi.
LIVE del primary non viene interpretato come flag storage; prova zero solo per ordinario.
Ogni discordanza rende GET FAULTED; il confine worker deve isolare la Serie."
  (let* ((rows (mappa-segmento-get-rows map))
         (flags (aref rows (+ base +row-flags+))) (proof (aref rows (+ base +row-proof+))))
    (verifica-parole-resolver context rows base)
    (unless (and (typep flags 'u8) (zerop (logand flags (logxor 255 (allowed-flags +put+)))))
      (guasto-get context :resolver-row-flags))
    (if (logtest flags +prepared+)
        (when (zerop proof) (guasto-get context :resolver-missing-outcome))
        (unless (zerop proof) (guasto-get context :resolver-unexpected-outcome)))
    (verifica-target-get context (mappa-segmento-get-segment map) (mappa-segmento-get-end map) flags)
    (let ((offset (if (zerop proof) nil proof)))
      (unless (eq (verifica-prova-target-get context (mappa-segmento-get-end map) flags offset)
                  (logtest flags +prepared+))
        (guasto-get context :resolver-proof-state))
      (values (the u8 flags) offset))))

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-CMP-007 REQ-AFF-002
(declaim (ftype (function (contesto-get mappa-segmento-get)
                         (values segmento-get u32 u8 (or null u32) &optional)) risolvi-candidato-get))
(defun risolvi-candidato-get (context map)
  "Pre: CANDIDATE, mappa CLOSED o pagina ACTIVE pubblicata acquisita DOPO AVVIA-GET sotto EBR.
Post: capacità, valid-bytes, flag e offset OUTCOME/NIL, solo per posizione/CSN concordi.
Non autorizza il valore: GET verifica ancora CRC/chiave/CSN e prova durevole dal file.
Errori/uscite non locali liberano EBR; ordine errato rifiutato prima di assumere il cleanup."
  (esigi-stato-get context :candidate)
  (let ((complete nil))
    (unwind-protect
         (let* ((segment (mappa-segmento-get-segment map)) (content (contesto-get-content context))
                (location (aref content 1)))
           (declare (type u64 location))
           (unless (eq (segmento-get-owner segment) (contesto-get-view context))
             (error 'invalid-argument :reason :resolver-source-owner))
           (unless (and (zerop (segmento-get-high segment))
                        (= (segmento-get-low segment) (ldb (byte 32 32) location)))
             (guasto-get context :resolver-source-segment))
           (unless (and (eq (mode-file (segmento-get-file segment)) :input)
                        (eq (stato-file (segmento-get-file segment)) :open))
             (guasto-get context :resolver-source-lifetime))
           (let ((base (trova-riga-resolver context (mappa-segmento-get-rows map)
                                           (ldb (byte 32 0) location))))
             (multiple-value-bind (flags proof) (verifica-riga-resolver context map base)
               (setf complete t)
               (values segment (mappa-segmento-get-end map) flags proof))))
      (unless complete (abbandona-get context)))))

;;; REQ: REQ-CCH-002 REQ-FOR-004 REQ-CMP-007
(declaim (ftype (function (contesto-get mappa-segmento-get)
                         (member :hit :miss :verify-failed :disabled :proof-required :buffer-required))
                sonda-cache-risolta-get))
(defun sonda-cache-risolta-get (context map)
  "Pre: CANDIDATE e mappa nella stessa epoca. Post: esito del nucleo GET con flag/frontiera risolti.
Nessun I/O; prepared richiede ancora prova dal pool I/O. Propaga errori e cleanup del GET."
  (multiple-value-bind (segment end flags proof) (risolvi-candidato-get context map)
    (declare (ignore proof)) ; dato verificato dal resolver, nessun esito d'errore scartato.
    (sonda-cache-get context segment end flags)))

;;; REQ: REQ-CCH-002 REQ-FOR-004 REQ-CMP-007 REQ-CON-004
(declaim (ftype (function (contesto-get mappa-segmento-get)
                         (values (member :cache :segment :buffer-required)
                                 (member :hit :miss :verify-failed :disabled :not-attempted)
                                 (member :inserted :present :busy :unavailable :bypassed :not-attempted)
                                 boolean boolean &optional)) leggi-record-risolto-get))
(defun leggi-record-risolto-get (context map)
  "Pre: nuovo AVVIA-GET nel pool I/O, nuova acquisizione della mappa sotto EBR.
Post: esiti del nucleo GET; OUTCOME riletto dal medesimo FD prima della cache prepared.
Propaga errori/cleanup; risposta privata fino a copia e CONCLUDI-GET con tempo fresco."
  (multiple-value-bind (segment end flags proof) (risolvi-candidato-get context map)
    (leggi-record-get context segment end flags :outcome-offset proof)))
