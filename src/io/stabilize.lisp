;;; OWNER: pool I/O, namespace esclusivo attraverso rinomina e fsync del parent.
;;; SHARED: solo stato della capacità directory; nessun contatore o attesa fra Serie.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (file-io file-io string string) boolean) stabilizza-nome-temporaneo))
(defun stabilizza-nome-temporaneo (directory file temporary final)
  "Pre: compito I/O, namespace esclusivo; FILE readonly già verificato e nominato dalla fonte autorevole.
Post: solo FINAL lega lo stesso FD, parent sincronizzato; T se rinominato, NIL se già definitivo.
Decisione atomica già nell'EDIT autorevole; rinomina esclusiva completa il nome, fsync la durability.
Non verifica manifest/CRC o durability dei dati. Non sostituisce target esistenti, non chiude/tronca file.
Rifiuti di preflight senza effetti; uscita incompleta dopo preflight => directory FAULTED, causa intatta.
Nessun retry/rollback: riacquisire capacità e namespace dalla fonte autorevole dopo un esito incerto."
  (multiple-value-bind (source target rename) (prepara-stabilizzazione-temporaneo directory file temporary final)
    (let ((complete nil))
      (unwind-protect
           (progn
             (when rename (pubblica-temporaneo directory file source target))
             ;; Verifica comune anche al ramo idempotente; non usa EOF come prova di identità.
             (when (verifica-nomi-stabilizzazione directory file source target)
               (error 'invariant-violation :reason :io-stabilization-post-name))
             (durable-flush directory)
             (esigi-aperto file :input)
             (setf complete t)
             rename)
        ;; Solo invalidazione locale: nessuna syscall/attesa nella regione protetta.
        (sb-sys:without-interrupts
          (when (and (not complete) (eq (file-state directory) :open))
            (setf (file-state directory) :faulted)))))))
