;;; OWNER: controller distribuisce le capacità dopo bootstrap e completamento del recovery.
;;; SHARED: lettura acquire del binding; getter locali senza lock o allocazione esplicita.
(in-package #:arcdocdb.runtime)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-AFF-008
(declaim (ftype (function (archivio-recovery) (or null runtime-archivio)) trova-runtime-archivio))
(defun trova-runtime-archivio (archive)
  "Pre: oggetto Archivio canonico. Post: NIL o stesso binding immutabile dopo acquire.
Permette di ritrovare il binding se il caller è interrotto dopo il CAS, senza reset.
INVARIANT-VIOLATION :ARCHIVE-RUNTIME-BINDING per slot estraneo; non certifica salute runtime."
  (let ((runtime (arcdocdb.recovery.archive::archivio-recovery-runtime archive)))
    (sb-thread:barrier (:read))
    (unless (typep runtime '(or null runtime-archivio))
      (error 'invariant-violation :reason :archive-runtime-binding))
    runtime))

;;; REQ: REQ-MVC-008 REQ-AFF-008
(declaim (ftype (function (runtime-archivio) registro-csn) csn-runtime-archivio))
(defun csn-runtime-archivio (runtime)
  "Pre: capsula pubblicata. Post: registro unico da passare a writer e decisioni dell'Archivio.
TYPE-ERROR per tipo invalido; nessuna assegnazione o attestazione di salute."
  (runtime-archivio-csns runtime))

;;; REQ: REQ-CMP-007 REQ-MVC-007
(declaim (ftype (function (runtime-archivio) ambito-get) ambito-runtime-archivio))
(defun ambito-runtime-archivio (runtime)
  "Pre: capsula pubblicata. Post: ambito nuovo da usare per viste e contesti runtime GET.
TYPE-ERROR per tipo invalido; il vecchio ambito recovery non viene modificato."
  (runtime-archivio-scope runtime))

;;; REQ: REQ-MVC-007 REQ-MVC-008
(declaim (ftype (function (runtime-archivio) registro-snapshot) snapshot-runtime-archivio))
(defun snapshot-runtime-archivio (runtime)
  "Pre: capsula pubblicata. Post: registro snapshot dello stesso ambito e registro CSN.
TYPE-ERROR per tipo invalido; nessuno snapshot viene registrato."
  (arcdocdb.get::ambito-get-snapshots (runtime-archivio-scope runtime)))

;;; REQ: REQ-CMP-007 REQ-AFF-008
(declaim (ftype (function (runtime-archivio) registro-epoche) epoche-runtime-archivio))
(defun epoche-runtime-archivio (runtime)
  "Pre: capsula pubblicata. Post: dominio EBR dello stesso ambito, reader già preallocati.
TYPE-ERROR per tipo invalido; ID esclusivi dei worker assegnati dal controller."
  (arcdocdb.get::ambito-get-epochs (runtime-archivio-scope runtime)))
