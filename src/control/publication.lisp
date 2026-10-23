;;; OWNER: recovery esclusivo della Serie; CAS locale reclama una sola pubblicazione per risultato.
;;; SHARED: nessuna pubblicazione di indici/CSN o lock tra Serie; I/O solo nel pool dedicato.
(in-package #:arcdocdb.control)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (control-preparato) null) verifica-dipendenze-pubblicazione))
(defun verifica-dipendenze-pubblicazione (prepared)
  "Pre: capacità esclusivamente possedute e risultato completo. Post: stesso checkpoint fermo e durevole.
Prova dei FD, directory canonica, salute log e nuovo ACTIVE ancora header-only.
IO-FAULT/INVALID-ARGUMENT prima della rinomina; nessuna syscall o ricostruzione del manifest."
  (let* ((log (control-preparato-log prepared)) (file (arcdocdb.wal::log-io-file log))
         (association (control-preparato-association prepared)))
    (verifica-associazione-file association (arcdocdb.io::associazione-file-input association) file)
    (arcdocdb.io::esigi-aperto (control-preparato-directory prepared) :directory)
    (unless (eq (stato-log log) :open) (error 'invalid-argument :reason :control-publication-log))
    (unless (= (posizione-scritta file) (posizione-durevole file) (control-preparato-end prepared))
      (error 'invalid-argument :reason :control-publication-advanced))
    (verifica-active-checkpoint (control-preparato-active prepared)))
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (control-preparato file-io) null) verifica-pubblicazione-control))
(defun verifica-pubblicazione-control (prepared previous)
  "Pre: vecchio control log readonly già validato e autorevole; namespace congelato dal recovery.
Post: gettone disponibile, dipendenze, backend e callback ammessi senza I/O o mutazione.
INVALID-ARGUMENT/IO-FAULT/UNSUPPORTED-FORMAT: nessuna pubblicazione viene tentata."
  (unless (and (eq (control-preparato-publication-state prepared) :prepared)
               (null (control-preparato-publication-owner prepared)))
    (error 'invalid-argument :reason :control-publication-state))
  (verifica-dipendenze-pubblicazione prepared)
  (verifica-capacita-sostituzione (control-preparato-directory prepared)
                                 (arcdocdb.io::associazione-file-input (control-preparato-association prepared))
                                 previous "control.log.tmp" "control.log")
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (control-preparato file-io) control-pubblicato) pubblica-control-recuperato))
(defun pubblica-control-recuperato (prepared previous)
  "Pre: pool I/O, recovery esclusivo, vecchio log validato e nomi posseduti fino a fine chiamata.
Post: checkpoint installato tramite renameat verificata e directory fsync; risultato completo.
Punto di atomicità: rinomina su control.log; nessuna conferma prima del successivo fsync parent.
Errori dopo la presa rendono FAULTED il gettone; non ritenta, cancella, chiude o fa rollback.
UNWIND-PROTECT rilascia il gettone su ogni uscita non locale, senza mascherare la condizione."
  (verifica-pubblicazione-control prepared previous)
  (let ((result (%make-control-pubblicato prepared)) (complete nil))
    (unwind-protect
         (progn
           (unless (null (sb-ext:compare-and-swap (control-preparato-publication-owner prepared) nil result))
             (error 'invalid-argument :reason :control-publication-state))
           (setf (control-preparato-publication-state prepared) :publishing)
           (sostituisci-temporaneo (control-preparato-directory prepared)
                                  (arcdocdb.io::associazione-file-input (control-preparato-association prepared))
                                  previous "control.log.tmp" "control.log")
           (setf (control-preparato-rename-observed prepared) t)
           (unless (zerop (durable-flush (control-preparato-directory prepared)))
             (error 'invariant-violation :reason :control-publication-directory))
           (verifica-dipendenze-pubblicazione prepared)
           (arcdocdb.io::esigi-aperto previous :input)
           (setf (control-preparato-publication-state prepared) :published complete t)
           result)
      (when (and (eq (control-preparato-publication-owner prepared) result) (not complete))
        (setf (control-preparato-publication-state prepared) :faulted)))))
