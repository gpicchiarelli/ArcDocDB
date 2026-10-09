;;; OWNER: slot esclusivo del worker; la sezione non attraversa rete, parcheggio o migrazione.
;;; SHARED: E letto soltanto; un annuncio u64 per worker, nessun RMW o mutex sul percorso riuscito.
(in-package #:arcdocdb.epochs)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-CMP-005 REQ-CMP-007 REQ-AFF-008
(declaim (inline entra-epoca esci-epoca))
(declaim (ftype (function (lettore-epoca) boolean) entra-epoca))
(defun entra-epoca (reader)
  "Pre: worker proprietario esclusivo, nessuna location/root letta prima; slot inattivo.
Post: T consente una sezione, NIL se E cambia durante l'annuncio: riaccodare il compito.
Un solo tentativo. Uscita non locale prima dell'ammissione libera lo slot; niente retry interno."
  (let* ((registry (lettore-epoca-registry reader)) (offset (lettore-epoca-offset reader))
         (announcements (registro-epoche-announcements registry)) (words (registro-epoche-words registry)))
    (esigi-epoche-sane registry)
    (unless (zerop (aref announcements offset))
      (error 'invalid-argument :reason :epoch-reader-already-active))
    (let ((epoch (sb-thread:barrier (:read) (aref words +word-epoch+))) (admitted nil))
      (declare (type u64 epoch))
      (when (zerop epoch) (guasto-reader-epoca registry :epoch-zero))
      (unwind-protect
           (progn
             (setf (aref announcements offset) epoch)
             ;; Store->load: annuncio visibile PRIMA della conferma e di ogni accesso alla risorsa.
             (sb-thread:barrier (:memory))
             (let ((confirmed (sb-thread:barrier (:read) (aref words +word-epoch+))))
               (declare (type u64 confirmed))
               (when (< confirmed epoch) (guasto-reader-epoca registry :epoch-regression))
               (esigi-epoche-sane registry)
               (setf admitted (= confirmed epoch))))
        (unless admitted
          (sb-thread:barrier (:memory))
          (setf (aref announcements offset) 0)))
      admitted)))

;;; REQ: REQ-CMP-005 REQ-CMP-007
(declaim (ftype (function (lettore-epoca) null) esci-epoca))
(defun esci-epoca (reader)
  "Pre: stesso worker/compito ammesso, ultimo accesso terminato. Post: slot inattivo.
Cleanup consentito anche dopo FAULTED; INVALID-ARGUMENT per slot già inattivo.
Il chiamante usa UNWIND-PROTECT solo dopo T da ENTRA-EPOCA; niente sezioni annidate."
  (let ((announcements (registro-epoche-announcements (lettore-epoca-registry reader)))
        (offset (lettore-epoca-offset reader)))
    (when (zerop (aref announcements offset))
      (error 'invalid-argument :reason :epoch-reader-inactive))
    (sb-thread:barrier (:memory))
    (setf (aref announcements offset) 0))
  nil)
