;;; OWNER: scratch e budget esclusivi del worker; writer solo durante sonda-writer.
;;; SHARED: controlli senza reset EMPTY, chiavi pubblicate immutabili, seqlock a tentativo singolo.
(in-package #:arcdocdb.index.primary)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-LIM-003 REQ-AFF-004
(declaim (inline chiave-corrisponde-p inizio-gruppo copia-contenuto))
(declaim (ftype (function (frammento-indice contenuto-slot octets fixnum fixnum) boolean)
                chiave-corrisponde-p))
(defun chiave-corrisponde-p (fragment words key start end)
  "Pre: WORDS privati acquisiti coerentemente; chiave immutata. Post: uguaglianza binaria esatta.
Acquisisce l'arena dopo il payload; un intervallo stabile fuori arena rende FAULTED l'indice."
  (let* ((metadata (aref words 2)) (offset (ldb (byte 32 0) metadata))
         (size (ldb (byte 16 32) metadata)) (arena (frammento-indice-arena fragment)))
    (declare (type u64 metadata))
    (sb-thread:barrier (:read))
    (when (> (+ offset size) (length arena))
      (guasto-indice (frammento-indice-owner fragment) :primary-key-arena-range))
    (and (= size (- end start))
         (loop for i fixnum below size
               always (= (aref arena (+ offset i)) (aref key (+ start i)))))))

;;; REQ: REQ-IDX-001
(declaim (ftype (function (u32 fixnum) fixnum) inizio-gruppo))
(defun inizio-gruppo (low capacity)
  "Pre: capacità potenza di due >=16. Post: gruppo allineato di 16 scelto dopo i sette bit H2."
  (logand (ash low -7) (- capacity +group-size+)))

;;; REQ: REQ-IDX-003
(declaim (ftype (function (contenuto-slot contenuto-slot) null) copia-contenuto))
(defun copia-contenuto (source destination)
  "Pre: buffer privati di cinque u64. Post: payload copiato, nessun u64 restituito come valore Lisp."
  (dotimes (i 5) (setf (aref destination i) (aref source i)))
  nil)

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-AFF-008
(declaim (ftype (function (frammento-indice fixnum fixnum octets fixnum fixnum contesto-indice) fixnum)
                sonda-gruppo))
(defun sonda-gruppo (fragment base fingerprint key start end context)
  "Pre: gruppo valido e scratch privato. Post: slot >=0, -1 miss, -2 retry, -3 budget, -4 continua.
Esamina tutti i fingerprint del gruppo prima del miss; ogni campione consuma il budget comune."
  (let ((controls (frammento-indice-controls fragment)) (bank (frammento-indice-bank fragment))
        (words (contesto-indice-words context)) (empty nil))
    (dotimes (i +group-size+)
      (let* ((slot (+ base i)) (control (aref controls slot)))
        (unless (controllo-valido-p control)
          (guasto-indice (frammento-indice-owner fragment) :primary-control-corrupt))
        (when (= control +ctrl-empty+) (setf empty t))
        (when (= control fingerprint)
          (when (zerop (contesto-indice-remaining context)) (return-from sonda-gruppo -3))
          (decf (contesto-indice-remaining context))
          (sb-thread:barrier (:read))
          (case (tenta-lettura-slot bank (base-slot bank slot) words)
            (:retry (return-from sonda-gruppo -2))
            (:empty nil)
            (:live (when (chiave-corrisponde-p fragment words key start end)
                     (return-from sonda-gruppo slot)))
            (otherwise (guasto-indice (frammento-indice-owner fragment) :primary-read-state))))))
    (if empty -1 -4)))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-AFF-008
(declaim (ftype (function (frammento-indice octets fixnum fixnum u32 contesto-indice) fixnum)
                sonda-reader))
(defun sonda-reader (fragment key start end low context)
  "Pre: frammento acquisito dalla root, scratch privato. Post: ricerca limitata a C/16 gruppi.
Ogni slot viene campionato una sola volta per visita; collisioni e retry condividono otto campioni."
  (let* ((capacity (banco-slot-capacity (frammento-indice-bank fragment)))
         (mask (1- capacity)) (base (inizio-gruppo low capacity)) (fingerprint (logand low 127)))
    (dotimes (group (ash capacity -4) -1)
      (let ((result (sonda-gruppo fragment base fingerprint key start end context)))
        (unless (= result -4) (return result)))
      (setf base (logand (+ base +group-size+) mask)))))

;;; REQ: REQ-IDX-001 REQ-IDX-005 REQ-AFF-004
(declaim (ftype (function (frammento-indice octets fixnum fixnum u32 contenuto-slot)
                         (values fixnum boolean &optional)) sonda-writer))
(defun sonda-writer (fragment key start end low words)
  "Pre: writer esclusivo e frammento sano, chiave/digest coerenti. Post: slot e trovato-p.
Slot -1 se nessuna posizione; visita al massimo C slot, senza retry o crescita automatica."
  (let* ((bank (frammento-indice-bank fragment)) (controls (frammento-indice-controls fragment))
         (capacity (banco-slot-capacity bank)) (mask (1- capacity))
         (base (inizio-gruppo low capacity)) (fingerprint (logand low 127)) (deleted -1))
    (dotimes (group (ash capacity -4))
      (let ((empty -1))
        (dotimes (i +group-size+)
          (let* ((slot (+ base i)) (control (aref controls slot)))
            (unless (controllo-valido-p control)
              (guasto-indice (frammento-indice-owner fragment) :primary-control-corrupt))
            (when (and (= control +ctrl-deleted+) (minusp deleted)) (setf deleted slot))
            (when (and (= control +ctrl-empty+) (minusp empty)) (setf empty slot))
            (when (= control fingerprint)
              (unless (eq (tenta-lettura-slot bank (base-slot bank slot) words) :live)
                (guasto-indice (frammento-indice-owner fragment) :primary-writer-slot-state))
              (when (chiave-corrisponde-p fragment words key start end)
                (return-from sonda-writer (values slot t))))))
        (unless (minusp empty)
          (return-from sonda-writer (values (if (minusp deleted) empty deleted) nil))))
      (setf base (logand (+ base +group-size+) mask)))
    (values deleted nil)))
