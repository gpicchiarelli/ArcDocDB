;;;; Cohort full text su una sola cornice PUT posseduta, poi riserva e append esatto.
;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-WAL-005
(defpackage #:arcdocdb.fulltext.put
  (:use #:cl)
  (:local-nicknames (#:d #:arcdocdb.fulltext.document) (#:f #:arcdocdb.fulltext.admission)
                    (#:w #:arcdocdb.wal) (#:r #:arcdocdb.record))
  (:import-from #:arcdocdb.binary #:index #:octets #:u8 #:u32 #:leggi-u32)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument #:resource-exhausted #:invariant-violation)
  (:export #:preparazione-put-full-text #:crea-preparazione-put-full-text
           #:inizia-put-full-text #:passo-put-full-text #:annulla-put-full-text
           #:prenota-put-full-text #:passo-riserva-put-full-text #:annulla-riserva-put-full-text
           #:aggiungi-put-full-text #:leggi-legame-put-full-text #:stato-put-full-text
           #:cattura-riferimento-put-full-text #:leggi-riferimento-put-full-text
           #:leggi-riferimento-riga-full-text))
(in-package #:arcdocdb.fulltext.put)
(declaim (optimize (safety 3) (debug 2)))
