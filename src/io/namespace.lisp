;;; OWNER: controller possiede namespace e capacità per tutta verifica/rinomina.
;;; SHARED: nessun lock globale; verifica e mutazione nel medesimo compito I/O.
(in-package #:arcdocdb.io)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (string) null) esigi-nome-foglia))
(defun esigi-nome-foglia (name)
  "Pre: nome del controller. Post: foglia ASCII stampabile non vuota, senza separatori o dot path.
INVALID-ARGUMENT prima dell'I/O; massimo 255 byte, nessuna risoluzione di path."
  (unless (<= 1 (length name) +max-rename-name-bytes+)
    (error 'invalid-argument :reason :io-leaf-name))
  (when (or (member name '("." "..") :test #'string=)
            (find #\/ name) (find #\\ name)
            (not (every (lambda (c) (<= 32 (char-code c) 126)) name)))
    (error 'invalid-argument :reason :io-leaf-name))
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (string string) null) verifica-nomi-temporaneo))
(defun verifica-nomi-temporaneo (source-name target-name)
  "Pre: due foglie ASCII gia' validate. Post: sorgente esattamente target seguito da .tmp.
INVALID-ARGUMENT prima degli effetti; confronti limitati ai 255 caratteri delle foglie."
  (unless (and (= (length source-name) (+ (length target-name) 4))
               (string= source-name target-name :end1 (length target-name))
               (string= source-name ".tmp" :start1 (length target-name)))
    (error 'invalid-argument :reason :io-replacement-names))
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-008 REQ-REC-001
(declaim (ftype (function (file-io file-io file-io string string) null) verifica-capacita-sostituzione))
(defun verifica-capacita-sostituzione (directory source target source-name target-name)
  "Pre: nuova fonte durevole con stato completo; target autorevole verificato e namespace esclusivo.
Post: capacità, nomi .tmp/definitivo e callback ammessi, senza syscall/mutazione.
INVALID-ARGUMENT/IO-FAULT/UNSUPPORTED-FORMAT; non verifica applicabilità del manifest."
  (esigi-aperto directory :directory) (esigi-aperto source :input) (esigi-aperto target :input)
  (esigi-nome-foglia source-name) (esigi-nome-foglia target-name)
  (verifica-nomi-temporaneo source-name target-name)
  (unless (and (eq (file-backend directory) (file-backend source))
               (eq (file-backend directory) (file-backend target)))
    (error 'invalid-argument :reason :io-identity-backend))
  (let ((backend (file-backend directory)))
    (when (and backend (or (null (backend-identity backend))
                          (null (backend-entry-identity backend)) (null (backend-rename backend))))
      (error 'unsupported-format :reason :io-replacement-unavailable)))
  nil)

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-REC-001
(declaim (ftype (function (file-io string) (values identity-component identity-component &optional))
                leggi-identita-entry))
(defun leggi-identita-entry (directory name)
  "Pre: capacità/callback verificati e nome foglia stabile. Post: device/inode esatti del regolare.
Una fstatat/callback; tipi verificati, errno conservato. IO-FAULT/INVARIANT-VIOLATION senza retry."
  (handler-case
      (multiple-value-bind (device inode)
          (let ((backend (file-backend directory)))
            (if backend (funcall (backend-entry-identity backend) (file-fd directory) name)
                (native-entry-identity (file-fd directory) name)))
        (unless (and (typep device 'identity-component) (typep inode 'identity-component))
          (error 'invariant-violation :reason :io-entry-identity-result))
        (values device inode))
    (sb-posix:syscall-error (condition)
      (error 'io-fault :reason :io-syscall :operation :entry-identity
             :errno (sb-posix:syscall-errno condition)))))

;;; REQ: REQ-AFF-001 REQ-FOR-001 REQ-REC-001
(declaim (ftype (function (file-io file-io string) (values identity-component identity-component &optional))
                verifica-legame-nome-file))
(defun verifica-legame-nome-file (directory file name)
  "Pre: capacità e backend ammessi, namespace stabile. Post: nome e FD individuano lo stesso regolare.
INVALID-ARGUMENT per nome sostituito; guasti di identità propagati; due osservazioni senza retry."
  (multiple-value-bind (device inode) (leggi-identita-file file)
    (multiple-value-bind (entry-device entry-inode) (leggi-identita-entry directory name)
      (unless (and (= device entry-device) (= inode entry-inode))
        (error 'invalid-argument :reason :io-replacement-identity)))
    (esigi-aperto directory :directory) (esigi-aperto file :input)
    (values device inode)))

;;; REQ: REQ-AFF-001 REQ-AFF-004 REQ-REC-001
(declaim (ftype (function (file-io file-io file-io string string) null) sostituisci-temporaneo))
(defun sostituisci-temporaneo (directory source target source-name target-name)
  "Pre: stato completo durevole, target autorevole verificato, namespace posseduto e capacità esclusive.
Post: nomi legati ai due file distinti, una renameat; nessun flush/close/rollback implicito.
Punto di atomicità: rinomina, non i controlli di identità; directory fsync successiva è del caller.
Errori prima della syscall non cambiano nomi; errore durante rename richiede recovery, mai retry."
  (verifica-capacita-sostituzione directory source target source-name target-name)
  (let ((source-leaf (map 'simple-base-string #'identity source-name))
        (target-leaf (map 'simple-base-string #'identity target-name)))
    (multiple-value-bind (source-device source-inode) (verifica-legame-nome-file directory source source-leaf)
      (multiple-value-bind (target-device target-inode) (verifica-legame-nome-file directory target target-leaf)
        (when (and (= source-device target-device) (= source-inode target-inode))
          (error 'invalid-argument :reason :io-replacement-alias))))
    (esigi-aperto directory :directory) (esigi-aperto source :input) (esigi-aperto target :input)
    (rinomina-con-nomi-privati
     directory source-leaf target-leaf
     (lambda ()
       (verifica-legame-nome-file directory source target-leaf)
       (esigi-aperto directory :directory) (esigi-aperto source :input) (esigi-aperto target :input))))
  nil)
