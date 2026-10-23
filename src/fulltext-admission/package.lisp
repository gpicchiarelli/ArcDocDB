;;;; Riserve locali prima di append/SEAL/PREPARE, senza decisioni o I/O.
;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-010 REQ-CON-002
(defpackage #:arcdocdb.fulltext.admission
  (:use #:cl)
  (:local-nicknames (#:d #:arcdocdb.fulltext.document) (#:r #:arcdocdb.fulltext.index)
                    (#:ex #:arcdocdb.execution))
  (:import-from #:arcdocdb.binary #:index #:u32 #:octets #:leggi-u64)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted #:invariant-violation)
  (:export #:riserve-full-text #:riserva-full-text #:crea-riserve-full-text
           #:prenota-full-text #:passo-riserva-full-text #:annulla-riserva-full-text
           #:trasferisci-riserva-full-text #:leggi-run-riserva-full-text
           #:leggi-budget-riserve-full-text #:leggi-bound-riserve-full-text
           #:stato-riserva-full-text #:trova-riga-trasferita-full-text))
(in-package #:arcdocdb.fulltext.admission)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-010
(deftype contatori-full-text () '(simple-array fixnum (*)))
