;;; OWNER: writer risolve la chiave nella root corrente; il messaggio non conserva slot/arena.
;;; SHARED: confronto e modifica seriali, stessa identità della versione, solo location diversa.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-004 REQ-LIM-003 REQ-AFF-004
(declaim (inline versione-corrisponde-p))
(declaim (ftype (function (contenuto-slot contenuto-slot) boolean) versione-corrisponde-p))
(defun versione-corrisponde-p (current expected)
  "Pre: buffer v2 privati validi della stessa chiave. Post: identità versione/location/contenuto.
Offset arena escluso: dopo rebuild viene risolto di nuovo, key-len rimane invariata."
  (and (= (aref current 0) (aref expected 0)) (= (aref current 1) (aref expected 1))
       (= (aref current 3) (aref expected 3)) (= (aref current 4) (aref expected 4))
       (= (ldb (byte 16 32) (aref current 2)) (ldb (byte 16 32) (aref expected 2)))))

;;; REQ: REQ-IDX-004 REQ-AFF-004
(declaim (ftype (function (indice-primario frammento-indice fixnum contenuto-slot) null)
                applica-rilocazione-writer))
(defun applica-rilocazione-writer (index fragment slot replacement)
  "Pre: writer, confronto sul corrente concluso e copia durevole verificata fuori dal modulo.
Post: location pubblicata, controllo/count/arena invariati; interruzione => FAULTED del dominio."
  (let ((bank (frammento-indice-bank fragment)) (complete nil))
    (unwind-protect
         (progn
           (incf (indice-primario-revision index))
           (pubblica-slot-v2 bank slot replacement)
           (esigi-frammento-sano index fragment)
           (setf complete t))
      (unless complete (invalida-banco-slot bank) (invalida-indice-primario index))))
  nil)

;;; REQ: REQ-IDX-004 REQ-LIM-003 REQ-AFF-008
(declaim (ftype (function (indice-primario octets integer integer u32 u32 contenuto-slot
                                         contenuto-slot contesto-indice) boolean) riloca-chiave-indice))
(defun riloca-chiave-indice (index key start end high low expected replacement context)
  "Pre: writer, copia identica durevole verificata; EXPECTED/REPLACEMENT privati del messaggio.
Post: T se applicabile (anche location identica), NIL su assenza/versione/location superate.
Risolve chiave nella root corrente; offset arena del messaggio ignorato e ricostruito dal lookup.
Non modifica CSN/length/end, non pubblica manifest o reclaim; nessun overwrite della versione nuova."
  (let* ((fragment (frammento-corrente-indice index high)) (bank (frammento-indice-bank fragment))
         (work (contesto-indice-words context)))
    (esigi-chiave key start end)
    (esigi-contenuto-slot bank expected)
    (esigi-contenuto-slot bank replacement)
    (unless (and (= (aref expected 0) (aref replacement 0))
                 (= (aref expected 3) (aref replacement 3)) (= (aref expected 4) (aref replacement 4))
                 (= (- end start) (ldb (byte 16 32) (aref expected 2)))
                 (= (- end start) (ldb (byte 16 32) (aref replacement 2)))
                 (not (eq expected work)) (not (eq replacement work)))
      (error 'invalid-argument :reason :primary-relocation-content))
    (esigi-contesto-libero context)
    (unwind-protect
         (progn
           (setf (contesto-indice-busy context) t)
           (multiple-value-bind (slot found) (sonda-writer fragment key start end low work)
             (esigi-frammento-sano index fragment)
             (unless (and found (versione-corrisponde-p work expected))
               (return-from riloca-chiave-indice nil))
             (unless (= (aref work 1) (aref replacement 1))
               (when (zerop (credito-scrittura-slot bank slot))
                 (error 'resource-exhausted :reason :primary-slot-rebuild-required))
               (esigi-revisione index)
               (setf (aref work 1) (aref replacement 1))
               (esigi-contenuto-slot bank work)
               (applica-rilocazione-writer index fragment slot work))
             t))
      (setf (contesto-indice-busy context) nil))))
