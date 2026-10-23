;;; OWNER: worker GET nel proprio EBR acquisisce la radice pubblicata, mai quella pianificata.
;;; SHARED: sola lettura controller locale/directory/righe; nessun lock o scrittura inter-Serie.
(in-package #:arcdocdb.get.resolver)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007 REQ-AFF-002
(declaim (ftype (function (contesto-get radice-get-attiva)
                         (values segmento-get u32 u8 null &optional)) risolvi-candidato-radice-attiva-get))
(defun risolvi-candidato-radice-attiva-get (context root)
  "Pre: CANDIDATE; ROOT pubblicata acquisita DOPO il pin nello stesso compito EBR.
Post: pagina della SOLA root catturata; prova NIL per ordinario, nessuna rilettura controller.
Il caller attesta pubblicazione e lifetime: una root pianificata non autorizza GET.
Vista estranea INVALID-ARGUMENT; invarianti FAULTED; errori/uscite liberano EBR."
  (esigi-stato-get context :candidate)
  (let ((complete nil))
    (unwind-protect
         (progn
           (unless (eq (segmento-get-owner (sorgente-get-attiva-segment (radice-get-attiva-source root)))
                       (contesto-get-view context))
             (error 'invalid-argument :reason :active-source-owner))
           (let ((page (trova-pagina-attiva context root (ldb (byte 32 0) (aref (contesto-get-content context) 1)))))
             (multiple-value-bind (segment end flags proof) (risolvi-candidato-get context page)
               (when proof (guasto-get context :active-unexpected-proof))
               (setf complete t)
               (values segment end flags nil))))
      (unless complete (abbandona-get context)))))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-CMP-007 REQ-AFF-002
(declaim (ftype (function (contesto-get sorgente-get-attiva)
                         (values segmento-get u32 u8 null &optional)) risolvi-candidato-attivo-get))
(defun risolvi-candidato-attivo-get (context source)
  "Pre: CANDIDATE sotto EBR, sorgente associata al segmento del candidato.
Post: root pubblicata con acquire, resolver della vista catturata; nessuna frontiera da H/EOF.
Salute controller propagata; root/fonte impossibili FAULTED; errori liberano EBR."
  (esigi-stato-get context :candidate)
  (let ((complete nil))
    (unwind-protect
         (progn
           (unless (eq (segmento-get-owner (sorgente-get-attiva-segment source)) (contesto-get-view context))
             (error 'invalid-argument :reason :active-source-owner))
           (let ((root (leggi-radice-serie (sorgente-get-attiva-controller source))))
             (unless (and (typep root 'radice-get-attiva) (eq (radice-get-attiva-source root) source))
               (guasto-get context :active-published-root))
             (multiple-value-bind (segment end flags proof) (risolvi-candidato-radice-attiva-get context root)
               (setf complete t)
               (values segment end flags proof))))
      (unless complete (abbandona-get context)))))

;;; REQ: REQ-CCH-002 REQ-IDX-001 REQ-WAL-006
(declaim (ftype (function (contesto-get sorgente-get-attiva)
                         (member :hit :miss :verify-failed :disabled :proof-required :buffer-required))
                sonda-cache-attiva-get))
(defun sonda-cache-attiva-get (context source)
  "Pre: CANDIDATE dopo AVVIA-GET sotto EBR. Post: sonda GET con pagina ordinaria pubblicata.
Nessun I/O/heap esplicito; il risultato resta provvisorio fino a copia e CONCLUDI-GET."
  (multiple-value-bind (segment end flags proof) (risolvi-candidato-attivo-get context source)
    (declare (ignore proof)) ; NIL già verificato: nessun esito d'errore scartato.
    (sonda-cache-get context segment end flags)))

;;; REQ: REQ-CCH-002 REQ-IDX-001 REQ-CON-004 REQ-WAL-006
(declaim (ftype (function (contesto-get sorgente-get-attiva)
                         (values (member :cache :segment :buffer-required)
                                 (member :hit :miss :verify-failed :disabled :not-attempted)
                                 (member :inserted :present :busy :unavailable :bypassed :not-attempted)
                                 boolean boolean &optional)) leggi-record-attivo-get))
(defun leggi-record-attivo-get (context source)
  "Pre: nuovo AVVIA-GET nel pool I/O e sorgente acquisita nella nuova epoca.
Post: lettura/cache dal FD readonly, byte soltanto entro la pagina pubblicata del candidato.
Non migra pin né autorizza risposta; copia e verifica finale con tempo fresco restano obbligatorie."
  (multiple-value-bind (segment end flags proof) (risolvi-candidato-attivo-get context source)
    (leggi-record-get context segment end flags :outcome-offset proof)))
