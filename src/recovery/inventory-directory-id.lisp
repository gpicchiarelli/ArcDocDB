;;; OWNER: controller esclusivo mantiene manifest e namespace stabili fino al nuovo temporaneo.
;;; SHARED: directory prestata, piano posseduto; nessun nuovo lock o contatore fra Serie.
(in-package #:arcdocdb.recovery.manifest)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-002 REQ-FOR-003 REQ-AFF-001 REQ-AFF-004 REQ-AFF-008 REQ-AFF-018
(declaim (ftype (function (manifest arcdocdb.io:file-io
                          &key (:max-files integer) (:max-segmenti integer) (:max-names t)
                               (:max-total-name-bytes t) (:max-name-bytes t))
                         (values u64 u64 reconciliation-plan &optional))
                scegli-id-segmento-recovery-directory))
(defun scegli-id-segmento-recovery-directory
    (manifest directory &key (max-files 65536) (max-segmenti 65536) (max-names 65536)
                            (max-total-name-bytes 16777216) (max-name-bytes 255))
  "Pre: recovery esclusivo, manifest autorevole e directory aperta/prestata, namespace completo stabile.
Post: tre valori posseduti: ID fresco, successore u64, piano canonico; una sola enumerazione attestata.
Budget, nomi, identità e lifetime verificati dal planner prima della scelta con postcondizioni comuni.
Condizioni originali propagate, RESOURCE-EXHAUSTED se manca un successore u64; nessun esito parziale.
Nessuna apertura dei segmenti, mutazione, prenotazione o ammissione; :READY riguarda solo i nomi.
Allocazioni di apertura, nessun nuovo stato condiviso; punto durevole resta l'EDIT del protocollo."
  (let ((plan (pianifica-riconciliazione-directory
                manifest directory :max-files max-files :max-segmenti max-segmenti
                :max-names max-names :max-total-name-bytes max-total-name-bytes
                :max-name-bytes max-name-bytes)))
    (proponi-id-segmento-da-piano manifest plan)))
