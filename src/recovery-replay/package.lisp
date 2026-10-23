;;; OWNER: compito I/O esclusivo della Serie; visitor e destinazioni private del bootstrap.
;;; SHARED: manifest e capacità readonly prestati; nessun nuovo stato o lock fra Serie.
;;; REQ: REQ-REC-001 REQ-STO-006 REQ-TXM-007 REQ-IDX-006 REQ-AFF-008
(defpackage #:arcdocdb.recovery.replay
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u8 #:u64 #:leggi-u64)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:invariant-violation)
  (:import-from #:arcdocdb.record #:+put+ #:+tombstone+ #:+outcome+ #:+seal+ #:+prepared+
                #:+header-bytes+ #:+stamp-offset+)
  (:import-from #:arcdocdb.storage.format #:+segment-header-bytes+)
  (:import-from #:arcdocdb.recovery.active #:workspace-active #:workspace-active-prepared #:workspace-active-outcomes
                #:cornice-active-verificata)
  (:import-from #:arcdocdb.recovery.closed #:closed-recuperato #:leggi-closed-con-workspace
                #:closed-recuperato-control #:closed-recuperato-input #:closed-recuperato-id
                #:closed-recuperato-prefix #:closed-recuperato-version #:closed-recuperato-origin
                #:closed-recuperato-batches #:closed-recuperato-records #:closed-recuperato-prepared
                #:closed-recuperato-local #:closed-recuperato-closure #:closed-recuperato-aborted
                #:closed-recuperato-csn-present #:closed-recuperato-max-csn)
  (:import-from #:arcdocdb.recovery.series #:limiti-recovery-serie #:limits-chunk #:limits-bytes
                #:limits-batches #:limits-records #:limits-batch-records #:limits-batch-bytes
                #:limits-prepared #:limits-outcomes #:limits-closure)
  (:export #:visita-record-closed-recuperato))
