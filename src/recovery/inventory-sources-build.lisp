;;;; Preparazione privata dei soli nomi vivi di un piano directory completo.
;;; OWNER: manifest e namespace esclusivi/stabili del controller; workspace della chiamata.
;;; SHARED: nessuno stato mutabile fra Serie, nessun thread o effetto durevole.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-FOR-003 REQ-AFF-008
(declaim (ftype (function (u64 (member :temporary :final)) simple-base-string) nome-fonte-recovery))
(defun nome-fonte-recovery (id form)
  "Pre: ID u64 e forma viva. Post: nome canonico ASCII privato, senza restringere l'ID.
Sedici passi finiti, nessun FORMAT dipendente da impostazioni dinamiche o I/O."
  (let* ((suffix (if (eq form :temporary) ".seg.tmp" ".seg"))
         (name (make-string (+ 16 (length suffix)) :element-type 'base-char :initial-element #\0)))
    (dotimes (i 16)
      (setf (schar name (- 15 i)) (schar "0123456789abcdef" (ldb (byte 4 (* 4 i)) id))))
    (replace name suffix :start1 16)
    name))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-008
(declaim (ftype (function (reconciliation-plan) recovery-sources) prepara-fonti-recovery))
(defun prepara-fonti-recovery (plan)
  "Pre: piano directory completo/stabile. Post: sole entry ACTIVE/CLOSED ordinate e senza FD.
INVALID-ARGUMENT se piano non READY; INVARIANT-VIOLATION per riga viva privata incoerente."
  (unless (eq (stato-riconciliazione plan) :ready)
    (error 'invalid-argument :reason :recovery-sources-not-ready))
  (let ((entries nil))
    (dotimes (i (numero-azioni-riconciliazione plan))
      (multiple-value-bind (id form action state) (azione-riconciliazione plan i)
        (when (member state '(:active :closed))
          (unless (or (and (eq form :final) (eq action :use))
                      (and (eq form :temporary) (eq action :rename)))
            (error 'invariant-violation :reason :recovery-source-action))
          (push (%make-recovery-source id state form (nome-fonte-recovery id form)) entries))))
    (unless entries (error 'invariant-violation :reason :recovery-sources-empty))
    (%make-recovery-sources (coerce (nreverse entries) 'simple-vector))))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-008
(declaim (ftype (function (recovery-sources arcdocdb.io:file-io t t index) null)
                acquista-fonti-recovery))
(defun acquista-fonti-recovery (sources directory max-transfer max-file-bytes total-budget)
  "Pre: entry private complete, parent stabile, nessuna cancellazione asincrona. Post: tutti i child aperti.
Errori I/O propagati al coordinatore; RESOURCE-EXHAUSTED al budget cumulativo, senza wrap."
  (let ((total 0) (entries (%rss-entries sources)))
    (dotimes (i (length entries))
      (let ((entry (the recovery-source (aref entries i))))
        (multiple-value-bind (file size)
            (arcdocdb.io:apri-lettura-nella-directory
             directory (%rs-name entry) :max-transfer max-transfer :max-file-bytes max-file-bytes)
          (setf (%rs-file entry) file (%rs-size entry) size)
          (when (> size (- total-budget total))
            (error 'resource-exhausted :reason :recovery-sources-total-bytes))
          (incf total size))))
    (arcdocdb.io::esigi-aperto directory :directory))
  nil)
