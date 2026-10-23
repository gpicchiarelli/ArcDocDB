;;; OWNER: candidato privato fino al CAS; dopo, legami immutabili della famiglia runtime.
;;; SHARED: solo i registri esistenti, con i rispettivi protocolli e frequenze di accesso.
(in-package #:arcdocdb.runtime)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-MVC-006 REQ-MVC-008 REQ-CMP-007 REQ-AFF-008
(defstruct (runtime-archivio (:constructor %make-runtime-archivio (csns scope)) (:copier nil))
  "Pre: registri nuovi, snapshot legato a CSNS, scope con quel registro ed EBR privato.
Post: legami readonly; nessun piano, vecchio ambito, risultato recovery, tabella o FD trattenuto.
La capsula configura il runtime; non certifica pubblicazione degli indici o ammissione."
  (csns nil :type registro-csn :read-only t)
  (scope nil :type ambito-get :read-only t))
