;;; OWNER: il worker possiede DESTINATION; l'unico writer pubblica i campi con seqlock.
;;; SHARED: lettura di parole e salute; nessun lock, RMW o scrittura condivisa sul successo.
(in-package #:arcdocdb.index.slots)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-IDX-003 REQ-LIM-001 REQ-AFF-004
(declaim (inline tenta-lettura-slot))
(declaim (ftype (function (banco-slot fixnum contenuto-slot)
                         (member :live :empty :retry)) tenta-lettura-slot))
(defun tenta-lettura-slot (bank base destination)
  "Pre: base valida, DESTINATION privata; un tentativo nel budget esterno di otto.
Post: LIVE copia cinque parole coerenti; EMPTY/RETRY lasciano il buffer intatto.
Solo dati stabili vengono validati; una corruzione stabile rende FAULTED e segnala."
  (let* ((words (banco-slot-words bank)) (sequence (aref words (+ base +slot-sequence+))))
    (declare (type u64 sequence))
    (when (>= sequence +slot-sequence-limit+) (guasto-slot bank :index-slot-sequence-corrupt))
    (when (oddp sequence) (return-from tenta-lettura-slot :retry))
    (sb-thread:barrier (:read))
    (let ((csn (aref words (+ base +slot-csn+)))
          (location (aref words (+ base +slot-location+)))
          (key (aref words (+ base +slot-key+)))
          (length-word (aref words (+ base +slot-length+)))
          (end (if (banco-slot-retained bank) (aref words (+ base +slot-end+)) 0)))
      (declare (type u64 csn location key length-word end))
      (sb-thread:barrier (:read))
      (when (/= sequence (aref words (+ base +slot-sequence+)))
        (return-from tenta-lettura-slot :retry))
      (esigi-banco-sano bank)
      (let ((live (verifica-campi-slot bank csn location key length-word end)))
        (when live
          (setf (aref destination 0) csn (aref destination 1) location
                (aref destination 2) key (aref destination 3) length-word (aref destination 4) end))
        (esigi-banco-sano bank)
        (if live :live :empty)))))

;;; REQ: REQ-IDX-003 REQ-IDX-007 REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (banco-slot integer contenuto-slot) (member :live :empty :retry-limit))
                leggi-slot-v2))
(defun leggi-slot-v2 (bank slot destination)
  "Pre: DESTINATION privata di cinque u64; la root e l'identità della chiave sono del chiamante.
Post: LIVE/EMPTY coerente; RETRY-LIMIT dopo otto tentativi, senza attese o ripiego interno.
EMPTY/RETRY-LIMIT non scrivono DESTINATION. Ogni errore o uscita non locale invalida il risultato.
Il futuro sondaggio deve condividere questo budget e ricontrollare root/generazione anche su miss."
  (esigi-banco-sano bank)
  (let ((base (base-slot bank slot)))
    (dotimes (attempt +slot-attempts+)
      (case (tenta-lettura-slot bank base destination)
        (:live (return-from leggi-slot-v2 :live))
        (:empty (return-from leggi-slot-v2 :empty))
        (:retry (esigi-banco-sano bank))
        (otherwise (guasto-slot bank :index-slot-read-state))))
    (esigi-banco-sano bank)
    :retry-limit))
