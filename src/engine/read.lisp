;;; OWNER: stesso thread del writer e dell'attore I/O; contesto GET preallocato esclusivo.
;;; SHARED: nessun reader concorrente; target privato fino alla conclusione verificata.
(in-package #:arcdocdb.engine)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-CON-004 REQ-CMP-007 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (motore b:octets b:octets b:index)
                         (values (member :found :absent) b:index &optional))
                leggi-documento-corrente-motore))
(defun leggi-documento-corrente-motore (engine key target start)
  "Pre: owner, MOTORE-BUSY vero, input validati; vista senza cache e contesto GET esclusivo.
Post: FOUND con numero byte autorizzati dopo copia e conclusione; ABSENT con zero,
senza modificare TARGET. Clock del motore letto all'avvio e fresco alla conclusione.
Ogni uscita abbandona GET; un errore di cleanup non sostituisce l'uscita primaria."
  (let ((context (motore-get-context engine)) (clock (motore-clock engine)) (complete nil))
    (declare (type (function () b:u64) clock))
    (unwind-protect
         (multiple-value-prog1
             (let ((now (funcall clock)))
               (declare (type b:u64 now))
               (when (= now #xffffffffffffffff)
                 (error 'arcdocdb.conditions:resource-exhausted :reason :engine-get-deadline-overflow))
               ;; La firma attuale e' (context view key snapshot generation now):
               ;; per GET corrente GENERATION deve essere zero; non esiste DEADLINE.
               (case (g:avvia-get context (motore-view engine) key nil 0 now)
                 (:absent
                  (multiple-value-bind (status size) (g:concludi-get context (funcall clock))
                    (unless (and (eq status :absent) (zerop size))
                      (error 'arcdocdb.conditions:invariant-violation :reason :engine-get-absence))
                    (values :absent 0)))
                 (:candidate
                  (case (gd:leggi-record-serie-get context (motore-controller engine))
                    (:segment nil)
                    (:buffer-required
                     (error 'arcdocdb.conditions:resource-exhausted :reason :engine-get-record-buffer))
                    (otherwise
                     (error 'arcdocdb.conditions:invariant-violation :reason :engine-get-source)))
                  (let* ((end (g:copia-valore-get context target start)) (copied (- end start)))
                    (multiple-value-bind (status size) (g:concludi-get context (funcall clock))
                      (unless (and (eq status :found) (= size copied) (plusp size))
                        (error 'arcdocdb.conditions:invariant-violation :reason :engine-get-result))
                      (values :found size))))
                 (:retry
                  (error 'arcdocdb.conditions:resource-exhausted :reason :engine-get-retry))
                 (otherwise
                  (error 'arcdocdb.conditions:invariant-violation :reason :engine-get-candidate))))
           (setf complete t))
      (if complete
          (g:abbandona-get context)
          ;; Preserva anche THROW/RETURN se il cleanup incontra un secondo errore.
          (handler-case (g:abbandona-get context)
            (error (cleanup) (push cleanup (motore-cleanup-failures engine))))))))

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-CON-004 REQ-AFF-002 REQ-AFF-004 REQ-LIM-001
(declaim (ftype (function (motore b:octets b:octets &key (:start b:index))
                         (values (member :found :absent) b:index &optional))
                leggi-documento))
(defun leggi-documento (engine key target &key (start 0))
  "Pre: thread owner, motore READY; KEY stabile e TARGET esclusivo, distinto dalla chiave;
START indice nel target, capacità sufficiente per il valore. API seriale non rientrabile.
Post: (values :FOUND byte-copiati) in TARGET da START, oppure (:ABSENT 0) senza mutarlo.
Il clock predefinito è la funzione senza argomenti del motore; nessun clock/I/O aggiuntivo.
Input invalido prima del GET; ogni errore nella richiesta ammessa rende FAULTED e propaga
la stessa causa. Su errore il contenuto di TARGET non è un risultato autorizzato."
  (esigi-motore-pronto engine)
  (unless (<= 1 (length key) arcdocdb.record:+max-key-bytes+)
    (error 'arcdocdb.conditions:invalid-argument :reason :engine-key-length))
  (b:check-range target start (length target))
  (when (eq key target)
    (error 'arcdocdb.conditions:invalid-argument :reason :engine-get-output-alias))
  (let ((complete nil) (cause nil))
    (unwind-protect
         (handler-case
             (progn
               (setf (motore-busy engine) t)
               (multiple-value-prog1 (leggi-documento-corrente-motore engine key target start)
                 (unless (and (motore-busy engine) (eq (motore-state engine) :ready)
                              (eq (s:stato-controllore-serie (motore-controller engine)) :healthy))
                   (error 'arcdocdb.conditions:invariant-violation :reason :engine-read-state))
                 (setf complete t)))
           (error (condition)
             (setf cause condition)
             (handler-case (guasta-motore engine condition)
               (error (cleanup) (push cleanup (motore-cleanup-failures engine))))
             (error condition)))
      (unwind-protect
           (unless (or complete cause)
             (handler-case
                 (guasta-motore engine
                                (make-condition 'arcdocdb.conditions:invariant-violation
                                                :reason :engine-read-unwind))
               (error (cleanup) (push cleanup (motore-cleanup-failures engine)))))
        (setf (motore-busy engine) nil)))))
