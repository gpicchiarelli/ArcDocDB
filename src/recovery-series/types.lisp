;;; OWNER: configurazione costruita prima delle letture; campi scalari tutti readonly.
;;; SHARED: oggetto immutabile riusabile da Serie indipendenti, nessuna cache o mutex.
(in-package #:arcdocdb.recovery.series)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-008
(defstruct (limiti-recovery-serie
             (:constructor %make-limiti-recovery-serie
                 (segments references total-bytes chunk bytes batches records batch-records batch-bytes
                  prepared outcomes closure)) (:conc-name limits-) (:copier nil))
  "Pre: tutti i limiti validati dalla factory, senza I/O. Post: budget scalari immutabili.
Riferimenti: solo array del risultato, non RSS; byte totali: EOF ACTIVE più P dei CLOSED.
Oggetti, workspace dei reader, scratch prestato e GC non sono inclusi nel budget riferimenti."
  (segments 1 :type index :read-only t)
  (references 0 :type index :read-only t)
  (total-bytes 0 :type index :read-only t)
  (chunk 1 :type index :read-only t)
  (bytes 64 :type index :read-only t)
  (batches 1 :type index :read-only t)
  (records 0 :type index :read-only t)
  (batch-records 1 :type u32 :read-only t)
  (batch-bytes 64 :type index :read-only t)
  (prepared 0 :type u32 :read-only t)
  (outcomes 0 :type u32 :read-only t)
  (closure 0 :type u32 :read-only t))

;;; REQ: REQ-REC-001 REQ-REC-004 REQ-AFF-008
(declaim (ftype (function (&key (:max-segmenti index) (:budget-riferimenti index) (:max-byte-totali index)
                          (:chunk-bytes index) (:max-bytes index) (:max-batches index) (:max-records index)
                          (:max-batch-records u32) (:max-batch-bytes index) (:max-prepared u32)
                          (:max-outcomes u32) (:max-esiti-chiusura u32)) limiti-recovery-serie)
                crea-limiti-recovery-serie))
(defun crea-limiti-recovery-serie (&key (max-segmenti 65536) (budget-riferimenti 524288)
                                      (max-byte-totali #xffffffff) (chunk-bytes 65536)
                                      (max-bytes 268435456) (max-batches 65536) (max-records 1048576)
                                      (max-batch-records 65536) (max-batch-bytes 67108864)
                                      (max-prepared 65536) (max-outcomes 65536) (max-esiti-chiusura 65536))
  "Pre: capacità tipizzate finite. Post: configurazione readonly, limiti reader canonici verificati.
MAX-SEGMENTI include ACTIVE; record/prepared/outcome/esiti sono limiti per segmento, zero ammesso.
INVALID-ARGUMENT per geometria; TYPE-ERROR per tipi/range scalari. Nessun I/O o risultato parziale."
  (unless (plusp max-segmenti) (error 'invalid-argument :reason :series-recovery-configuration))
  (arcdocdb.recovery.closed::verifica-budget-closed
   chunk-bytes max-bytes max-batches max-batch-records max-batch-bytes)
  (%make-limiti-recovery-serie max-segmenti budget-riferimenti max-byte-totali chunk-bytes
                              max-bytes max-batches max-records max-batch-records max-batch-bytes
                              max-prepared max-outcomes max-esiti-chiusura))
