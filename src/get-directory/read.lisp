;;; OWNER: worker GET nello stesso compito EBR del lookup e della risposta privata.
;;; SHARED: sola lettura degli array immutabili; nessun lock, I/O o scrittura globale.
(in-package #:arcdocdb.get.directory)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (contesto-get directory-get-serie u32) mappa-segmento-get)
                cerca-mappa-directory-get))
(defun cerca-mappa-directory-get (context directory id)
  "Pre: CANDIDATE, directory canonica acquisita sotto EBR. Post: mappa con ID esatto.
Al più diciassette passi per 65.536 segmenti; nessuna allocazione esplicita o I/O.
Forma impossibile o ID mancante rende GET FAULTED, mai documento assente."
  (let* ((ids (directory-get-serie-ids directory)) (maps (directory-get-serie-maps directory))
         (left 0) (right (length ids)))
    (declare (type index left right))
    (unless (and (= right (length maps)) (<= right +directory-max-segments+))
      (guasto-get context :directory-shape))
    (loop repeat +directory-search-attempts+
          do (when (= left right) (guasto-get context :directory-location-absent))
             (let* ((middle (+ left (floor (- right left) 2))) (actual (aref ids middle)))
               (cond ((< actual id) (setf left (1+ middle)))
                     ((> actual id) (setf right middle))
                     (t (let ((map (svref maps middle)))
                          (unless (typep map 'mappa-segmento-get)
                            (guasto-get context :directory-shape))
                          (return-from cerca-mappa-directory-get map))))))
    (guasto-get context :directory-location-absent)))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-002
(declaim (ftype (function (contesto-get directory-get-serie) mappa-segmento-get)
                trova-mappa-directory-get))
(defun trova-mappa-directory-get (context directory)
  "Pre: CANDIDATE; controller ha acquisito directory DOPO AVVIA-GET, nella stessa epoca.
Post: mappa scelta dal segmento del candidato; ordine errato rifiutato prima del cleanup.
Errori/uscite non locali liberano EBR; vista estranea INVALID-ARGUMENT, mancanza FAULTED.
La mappa non autorizza il valore: il resolver e GET verificano ancora fonte/record/prova."
  (esigi-stato-get context :candidate)
  (let ((complete nil))
    (unwind-protect
         (progn
           (unless (eq (directory-get-serie-view directory) (contesto-get-view context))
             (error 'invalid-argument :reason :directory-source-owner))
           (let* ((location (aref (contesto-get-content context) 1))
                  (map (cerca-mappa-directory-get context directory (ldb (byte 32 32) location))))
             (declare (type u64 location))
             (setf complete t)
             map))
      (unless complete (abbandona-get context)))))

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-CMP-007 REQ-AFF-002
(declaim (ftype (function (contesto-get directory-get-serie)
                         (values segmento-get u32 arcdocdb.binary:u8 (or null u32) &optional))
                risolvi-candidato-directory-get))
(defun risolvi-candidato-directory-get (context directory)
  "Pre: CANDIDATE e directory acquisita sotto EBR dopo il lookup del primary.
Post: capacità, frontiera, flag storage e prova del resolver CLOSED per il candidato.
Propaga guasti e cleanup; CSN/size/FD ancora verificati, nessuna risposta autorizzata."
  (risolvi-candidato-get context (trova-mappa-directory-get context directory)))

;;; REQ: REQ-IDX-001 REQ-CCH-002 REQ-FOR-004 REQ-CMP-007
(declaim (ftype (function (contesto-get directory-get-serie)
                         (member :hit :miss :verify-failed :disabled :proof-required :buffer-required))
                sonda-cache-directory-get))
(defun sonda-cache-directory-get (context directory)
  "Pre: CANDIDATE e directory nella stessa epoca. Post: esiti della sonda GET, nessun I/O.
Prepared richiede il pool I/O; risposta privata fino a copia e conclusione snapshot."
  (sonda-cache-risolta-get context (trova-mappa-directory-get context directory)))

;;; REQ: REQ-IDX-001 REQ-CCH-002 REQ-FOR-004 REQ-CMP-007 REQ-CON-004
(declaim (ftype (function (contesto-get directory-get-serie)
                         (values (member :cache :segment :buffer-required)
                                 (member :hit :miss :verify-failed :disabled :not-attempted)
                                 (member :inserted :present :busy :unavailable :bypassed :not-attempted)
                                 boolean boolean &optional)) leggi-record-directory-get))
(defun leggi-record-directory-get (context directory)
  "Pre: nuovo AVVIA-GET nel pool I/O, directory riacquisita sotto la nuova epoca.
Post: cinque esiti GET dalla mappa scelta; nessuna location o pin migra fra i pool.
Errori/uscite non locali liberano EBR; copia/conclusione col tempo fresco obbligatorie."
  (leggi-record-risolto-get context (trova-mappa-directory-get context directory)))
