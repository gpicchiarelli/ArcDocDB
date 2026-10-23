;;; OWNER: compito I/O legge il CLOSED nominato dal CONTROL, poi costruisce soltanto un risultato completo.
;;; SHARED: nessun buffer o workspace condiviso; tutte le fonti congelate dal controller della Serie.
(in-package #:arcdocdb.recovery.closed)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-FOR-003 REQ-AFF-002 REQ-AFF-008
(declaim (ftype (function (control-recuperato file-io u64 index (member 1 2) octets
                          index index u32 index u32 u32)
                         (values closed-recuperato workspace-active &optional)) recupera-closed-writer))
(defun recupera-closed-writer (control input id prefix version scratch batches records batch-records
                              batch-bytes prepared outcomes)
  "Pre: header writer e corpo fino a P già letti. Post: prefisso e prepared risolti senza multiserie.log.
Parser semantico canonico riusato solo dopo CRC/SEAL integrali; nessuna classificazione EOF.
Errori originali propagati; prova senza scratch/workspace, workspace restituito solo al chiamante interno.
Entrambi privati fino al completamento del reader, nessun effetto durevole."
  (multiple-value-bind (actual-batches actual-records)
      (verifica-lotti-closed scratch prefix id version batches records batch-records batch-bytes)
    (let ((workspace (attraversa-active scratch prefix version actual-batches actual-records prepared outcomes)))
      (multiple-value-bind (count local closure aborted)
          (risolvi-prepared-closed workspace (manifest-control-recuperato control) id)
        (multiple-value-bind (present maximum)
            (massimo-csn-chiusura (manifest-control-recuperato control) id
                                 (arcdocdb.recovery.active::workspace-active-csn-present workspace)
                                 (arcdocdb.recovery.active::workspace-active-max-csn workspace))
          (arcdocdb.io::esigi-aperto input :input)
          (arcdocdb.io::esigi-aperto (arcdocdb.control::control-recuperato-input control) :input)
          (values (%make-closed-recuperato control input id prefix version +writer-origin+
                                          actual-batches actual-records count local closure aborted present maximum)
                  workspace))))))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-FOR-001 REQ-FOR-002 REQ-CMP-009 REQ-AFF-008
(declaim (ftype (function (control-recuperato file-io u64 octets
                          &key (:chunk-bytes index) (:max-bytes index) (:max-batches index)
                               (:max-records index) (:max-batch-records u32) (:max-batch-bytes index)
                               (:max-prepared u32) (:max-outcomes u32) (:max-esiti-chiusura u32))
                         (values closed-recuperato (or null workspace-active) &optional)) leggi-closed-con-workspace))
(defun leggi-closed-con-workspace (control input id scratch
                              &key (chunk-bytes 65536) (max-bytes 268435456) (max-batches 65536)
                                   (max-records 1048576) (max-batch-records 65536) (max-batch-bytes 67108864)
                                   (max-prepared 65536) (max-outcomes 65536) (max-esiti-chiusura 65536))
  "Pre: recovery esclusivo, CONTROL e FD CLOSED autorevoli, file/namespace congelati e scratch privato.
Post: stesso FD readonly, header e prefisso esatto dal manifest verificati; ID u64 senza restrizioni GET.
Writer: lotti interi e prepared risolti da OUTCOME/EDIT; compaction: soli record ordinari verificati.
Non legge oltre P, misura EOF, classifica TAIL, costruisce indici o modifica file/CSN/pubblicazione.
Condizioni originali propagate senza retry o close; dipendenze aperte prima della consegna.
Ingresso interno: seconda voce workspace semantico privato per writer, NIL per compaction."
  (let ((prefix (verifica-lettura-closed control input id scratch chunk-bytes max-bytes max-batches
                                        max-batch-records max-batch-bytes max-esiti-chiusura)))
    (multiple-value-bind (version origin) (leggi-header-closed control input id scratch)
      (leggi-corpo-closed input prefix scratch chunk-bytes)
      (case origin
        (#.+writer-origin+
         (recupera-closed-writer control input id prefix version scratch max-batches max-records
                                 max-batch-records max-batch-bytes max-prepared max-outcomes))
        (#.+compaction-origin+
         (let ((count (verifica-compattato-closed control scratch prefix id version max-bytes max-records)))
           (multiple-value-bind (present maximum) (massimo-csn-compattato scratch prefix version count)
             (multiple-value-bind (found csn)
                 (massimo-csn-chiusura (manifest-control-recuperato control) id present maximum)
               (arcdocdb.io::esigi-aperto input :input)
               (arcdocdb.io::esigi-aperto (arcdocdb.control::control-recuperato-input control) :input)
               (values (%make-closed-recuperato control input id prefix version origin 0 count 0 0 0 0
                                               found csn)
                       nil)))))
        (otherwise (error 'invariant-violation :reason :closed-recovery-origin))))))

;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-FOR-001 REQ-FOR-002 REQ-CMP-009 REQ-AFF-008
(declaim (ftype (function (control-recuperato file-io u64 octets
                          &key (:chunk-bytes index) (:max-bytes index) (:max-batches index)
                               (:max-records index) (:max-batch-records u32) (:max-batch-bytes index)
                               (:max-prepared u32) (:max-outcomes u32) (:max-esiti-chiusura u32))
                         closed-recuperato) leggi-closed-recuperato))
(defun leggi-closed-recuperato (control input id scratch
                              &key (chunk-bytes 65536) (max-bytes 268435456) (max-batches 65536)
                                   (max-records 1048576) (max-batch-records 65536) (max-batch-bytes 67108864)
                                   (max-prepared 65536) (max-outcomes 65536) (max-esiti-chiusura 65536))
  "Pre: recovery esclusivo, CONTROL autorevole, FD readonly e scratch stabili nel pool I/O.
Post: unico risultato completo da header/prefisso canonici, prepared risolti da OUTCOME/EDIT.
Il workspace interno non lascia questa API; condizioni originali propagate, nessun effetto durevole."
  (values (leggi-closed-con-workspace
           control input id scratch :chunk-bytes chunk-bytes :max-bytes max-bytes :max-batches max-batches
           :max-records max-records :max-batch-records max-batch-records :max-batch-bytes max-batch-bytes
           :max-prepared max-prepared :max-outcomes max-outcomes :max-esiti-chiusura max-esiti-chiusura)))
