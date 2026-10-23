;;; OWNER: recovery esclusivo mantiene vettore, CONTROL e tutti i FD readonly fino al termine del publisher.
;;; SHARED: tabella seen privata; unico punto atomico e gettone restano nel publisher CONTROL canonico.
(in-package #:arcdocdb.recovery.closed)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (control-recuperato simple-vector &key (:max-segmenti index)) null)
                verifica-closed-completi))
(defun verifica-closed-completi (control closed &key (max-segmenti 65536))
  "Pre: vettore completo e stabile di risultati readonly dello stesso CONTROL, controller esclusivo.
Post: tutti e soli i CLOSED del manifest, una volta per ID completo, con P esatto e FD aperti.
Budget prima della tabella seen; INVALID-ARGUMENT per count/autorità/duplicato/frontiera, IO-FAULT per lifetime.
Non verifica nomi/inode, rilegge file, ammette traffico o rende durevole un cambiamento."
  (arcdocdb.io::esigi-aperto (arcdocdb.control::control-recuperato-input control) :input)
  (let ((manifest (manifest-control-recuperato control)) (count (length closed)))
    (when (> count max-segmenti) (error 'resource-exhausted :reason :closed-recovery-set-budget))
    (unless (= count (numero-segmenti-chiusi manifest))
      (error 'invalid-argument :reason :closed-recovery-set-count))
    (let ((seen (make-hash-table :test 'eql :size (max 1 count))))
      (loop for item across closed
            do (let* ((entry (the closed-recuperato item)) (id (closed-recuperato-id entry)))
                 (unless (eq (closed-recuperato-control entry) control)
                   (error 'invalid-argument :reason :closed-recovery-set-control))
                 (arcdocdb.io::esigi-aperto (closed-recuperato-input entry) :input)
                 (multiple-value-bind (state prefix outcomes) (trova-segmento manifest id)
                   (declare (ignore outcomes)) ; già verificati nel lettore; nessun esito d'errore.
                   (unless (and (eq state :closed) (= prefix (closed-recuperato-prefix entry)))
                     (error 'invalid-argument :reason :closed-recovery-set-prefix)))
                 (when (gethash id seen) (error 'invalid-argument :reason :closed-recovery-set-duplicate))
                 (setf (gethash id seen) t)))
      (unless (= (hash-table-count seen) count)
        (error 'invariant-violation :reason :closed-recovery-set-consumption)))
    (arcdocdb.io::esigi-aperto (arcdocdb.control::control-recuperato-input control) :input))
  nil)

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-AFF-001 REQ-AFF-018
(declaim (ftype (function (control-preparato active-recuperato simple-vector &key (:max-segmenti index))
                         control-pubblicato) pubblica-control-con-closed))
(defun pubblica-control-con-closed (prepared active closed &key (max-segmenti 65536))
  "Pre: pool I/O, recovery esclusivo e inventario/namespaces riconciliati, capacità mantenute vive.
Post: insieme dei vecchi CLOSED verificato prima del claim, poi chiusura ACTIVE/transizione/publisher canonici.
Punto atomico: rinomina CONTROL; conferma dopo fsync parent, stessi errori/stati terminali del publisher.
Nessun nuovo gettone, lettura dei segmenti, CSN, dimenticanza decisioni o ammissione del traffico."
  (verifica-closed-completi (arcdocdb.recovery.active::active-recuperato-control active)
                          closed :max-segmenti max-segmenti)
  (pubblica-control-da-active prepared active))
