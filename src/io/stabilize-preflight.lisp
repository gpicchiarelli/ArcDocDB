;;; OWNER: compito I/O mantiene namespace esclusivo e capacità readonly fino al completamento.
;;; SHARED: osservazioni locali; nessun nuovo FD, registro o lock fra Serie.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004
(declaim (ftype (function (file-io simple-base-string)
                         (values boolean identity-component identity-component &optional))
                identita-entry-presente))
(defun identita-entry-presente (directory name)
  "Pre: callback e nome privato verificati, namespace esclusivo. Post: presenza e identità esatta.
Solo ENOENT dell'operazione ENTRY-IDENTITY diventa NIL/0/0; ogni altra condizione è propagata.
Una osservazione nofollow; symlink, tipo errato e guasti non diventano assenza."
  (handler-case
      (multiple-value-bind (device inode) (leggi-identita-entry directory name)
        (values t device inode))
    (io-fault (condition)
      (unless (and (eq (arcdocdb.conditions:error-operation condition) :entry-identity)
                   (eql (arcdocdb.conditions:error-errno condition) sb-posix:enoent))
        (error condition))
      (values nil 0 0))))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (file-io file-io string string) null) verifica-capacita-stabilizzazione))
(defun verifica-capacita-stabilizzazione (directory file temporary final)
  "Pre: capacità del controller e nomi stabili. Post: input/parent aperti, identità e coppia .tmp ammessi.
INVALID-ARGUMENT o UNSUPPORTED-FORMAT prima di osservazioni/effetti; nessun fallback nativo."
  (esigi-aperto directory :directory) (esigi-aperto file :input)
  (esigi-nome-foglia temporary) (esigi-nome-foglia final)
  (unless (and (= (length temporary) (+ 4 (length final)))
               (string= temporary final :end1 (length final))
               (string= temporary ".tmp" :start1 (length final)))
    (error 'invalid-argument :reason :io-stabilization-names))
  (unless (eq (file-backend directory) (file-backend file))
    (error 'invalid-argument :reason :io-identity-backend))
  (let ((backend (file-backend directory)))
    (when (and backend (or (null (backend-identity backend))
                          (null (backend-entry-identity backend))))
      (error 'unsupported-format :reason :io-stabilization-unavailable)))
  nil)

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-008
(declaim (ftype (function (file-io file-io simple-base-string simple-base-string) boolean)
                verifica-nomi-stabilizzazione))
(defun verifica-nomi-stabilizzazione (directory file temporary final)
  "Pre: capacità verificate e nomi privati, namespace esclusivo. Post: T rinomina, NIL già definitivo.
Deve esistere esattamente un nome, legato al medesimo FD regolare; entrambi rifiutati anche se alias.
INVALID-ARGUMENT prima dell'effetto per collisione/assenza/identità; guasti originali propagati."
  (multiple-value-bind (has-temporary temporary-device temporary-inode)
      (identita-entry-presente directory temporary)
    (multiple-value-bind (has-final final-device final-inode) (identita-entry-presente directory final)
      (when (eq has-temporary has-final)
        (error 'invalid-argument :reason :io-stabilization-presence))
      (multiple-value-bind (device inode) (leggi-identita-file file)
        (unless (and (= device (if has-temporary temporary-device final-device))
                     (= inode (if has-temporary temporary-inode final-inode)))
          (error 'invalid-argument :reason :io-stabilization-identity)))
      (esigi-aperto directory :directory) (esigi-aperto file :input)
      has-temporary)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (file-io file-io string string)
                         (values simple-base-string simple-base-string boolean &optional))
                prepara-stabilizzazione-temporaneo))
(defun prepara-stabilizzazione-temporaneo (directory file temporary final)
  "Pre: capacita' e nomi stabili del controller. Post: foglie private e ramo verificato senza effetti.
Identita' nofollow di entrambi i nomi e FD; esclusivita' richiesta solo per il temporaneo.
Condizioni originali prima di rinomina/flush; nessuna prenotazione o garanzia contro mutatori esterni."
  (verifica-capacita-stabilizzazione directory file temporary final)
  (let* ((source (map 'simple-base-string #'identity temporary))
         (target (map 'simple-base-string #'identity final))
         (rename (verifica-nomi-stabilizzazione directory file source target)))
    (when rename (verifica-capacita-pubblicazione directory file source target))
    (values source target rename)))

;;; REQ: REQ-REC-001 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008
(declaim (ftype (function (file-io file-io string string) boolean) verifica-stabilizzazione-temporaneo))
(defun verifica-stabilizzazione-temporaneo (directory file temporary final)
  "Pre: namespace esclusivo/stabile e FILE readonly verificato, stessa autorita' del completamento.
Post: T temporaneo o NIL definitivo, nomi/FD/callback verificati; nessuna rinomina, fsync o close.
Condizioni originali senza mutazioni; il booleano non e' una lease e non autorizza traffico."
  (multiple-value-bind (source target rename) (prepara-stabilizzazione-temporaneo directory file temporary final)
    (declare (ignore source target)) ; foglie private verificate, non esiti d'errore.
    rename))
