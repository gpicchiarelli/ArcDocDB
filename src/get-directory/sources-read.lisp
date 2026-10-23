;;; OWNER: worker GET nel compito EBR corrente; nessuna root attraversa le code.
;;; SHARED: una lettura acquire della root locale, nessun lock/heap esplicito sul percorso sano.
(in-package #:arcdocdb.get.directory)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007 REQ-AFF-002
(declaim (ftype (function (contesto-get controllore-serie)
                         (values fonti-get-serie (or null radice-get-attiva) &optional))
                acquisisci-fonti-serie-get))
(defun acquisisci-fonti-serie-get (context controller)
  "Pre: CANDIDATE, cleanup del chiamante installato. Post: fonti/root dalla STESSA lettura acquire.
Vista estranea INVALID-ARGUMENT; forma/root-controller/ID duplicato impossibili => GET FAULTED.
Non legge root pianificata, non rilegge root e non chiude/rimuove risorse."
  (let* ((root (leggi-radice-serie controller))
         (active (when (typep root 'radice-get-attiva) root))
         (sources (if active (contenuto-radice-get-attiva active) root)))
    (unless (typep sources 'fonti-get-serie) (guasto-get context :sources-published-root))
    (let ((directory (fonti-get-serie-directory sources)))
      (unless (eq (directory-get-serie-view directory) (contesto-get-view context))
        (error 'invalid-argument :reason :sources-owner))
      (when active
        (let* ((source (radice-get-attiva-source active)) (segment (sorgente-get-attiva-segment source)))
          (unless (eq (sorgente-get-attiva-controller source) controller)
            (guasto-get context :sources-active-controller))
          (unless (eq (segmento-get-owner segment) (directory-get-serie-view directory))
            (guasto-get context :sources-active-owner))
          (unless (and (zerop (segmento-get-high segment)) (plusp (segmento-get-low segment)))
            (guasto-get context :sources-active-id))
          (when (handler-case (contiene-segmento-directory-get directory (segmento-get-low segment))
                  (invariant-violation (condition) (guasto-get context (error-reason condition))))
            (guasto-get context :sources-active-duplicate))))
      (values sources active))))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007 REQ-AFF-002
(declaim (ftype (function (contesto-get controllore-serie)
                         (values segmento-get u32 arcdocdb.binary:u8 (or null u32) &optional))
                risolvi-candidato-serie-get))
(defun risolvi-candidato-serie-get (context controller)
  "Pre: AVVIA-GET ha prodotto CANDIDATE sotto EBR; controller della vista corrente.
Post: candidato da CLOSED o ACTIVE della singola root acquisita DOPO il lookup.
Fonti pubblicate prima delle location e mantenute per i reader ammessi: obbligo del writer.
Wrong-state respinto prima del cleanup; altri errori/uscite liberano pin, invarianti FAULTED."
  (esigi-stato-get context :candidate)
  (let ((complete nil))
    (unwind-protect
         (multiple-value-bind (sources active) (acquisisci-fonti-serie-get context controller)
           (multiple-value-bind (segment end flags proof)
               (if (and active
                        (= (ldb (byte 32 32) (aref (contesto-get-content context) 1))
                           (segmento-get-low (sorgente-get-attiva-segment (radice-get-attiva-source active)))))
                   (risolvi-candidato-radice-attiva-get context active)
                   (risolvi-candidato-directory-get context (fonti-get-serie-directory sources)))
             (setf complete t)
             (values segment end flags proof)))
      (unless complete (abbandona-get context)))))

;;; REQ: REQ-IDX-001 REQ-CCH-002 REQ-FOR-004 REQ-CMP-007
(declaim (ftype (function (contesto-get controllore-serie)
                         (member :hit :miss :verify-failed :disabled :proof-required :buffer-required))
                sonda-cache-serie-get))
(defun sonda-cache-serie-get (context controller)
  "Pre: CANDIDATE dopo AVVIA-GET. Post: sonda comune con fonti dalla root acquisita sotto EBR.
Prepared conserva proof-required; niente I/O o autorizzazione della risposta privata."
  (multiple-value-bind (segment end flags proof) (risolvi-candidato-serie-get context controller)
    (declare (ignore proof)) ; dato verificato; prepared restituisce proof-required nel nucleo GET.
    (sonda-cache-get context segment end flags)))

;;; REQ: REQ-IDX-001 REQ-CCH-002 REQ-FOR-004 REQ-CMP-007 REQ-CON-004
(declaim (ftype (function (contesto-get controllore-serie)
                         (values (member :cache :segment :buffer-required)
                                 (member :hit :miss :verify-failed :disabled :not-attempted)
                                 (member :inserted :present :busy :unavailable :bypassed :not-attempted)
                                 boolean boolean &optional)) leggi-record-serie-get))
(defun leggi-record-serie-get (context controller)
  "Pre: nuovo AVVIA-GET nel worker I/O; controller riacquisito, nessuna location/pin in coda.
Post: cinque esiti comuni GET; copia e CONCLUDI-GET con tempo fresco ancora obbligatori.
Prepared rilegge OUTCOME autorevole; errori/uscite liberano pin e preservano la causa."
  (multiple-value-bind (segment end flags proof) (risolvi-candidato-serie-get context controller)
    (leggi-record-get context segment end flags :outcome-offset proof)))
