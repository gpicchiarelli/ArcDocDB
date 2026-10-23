;;;; Analizzatore Unicode esplicito, dati immutabili e scratch privato riprendibile.
;;; REQ: REQ-SEC-007 REQ-SEC-010
(defpackage #:arcdocdb.fulltext.analysis
  (:use #:cl)
  (:import-from #:arcdocdb.binary #:octets #:index #:u32)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:invariant-violation #:corruption-detected)
  (:export #:spazio-full-text #:crea-spazio-full-text #:inizia-analisi-full-text
           #:passo-analisi-full-text #:risultati-analisi-full-text))
(in-package #:arcdocdb.fulltext.analysis)
(deftype scalare () '(integer 0 #x10ffff))
(deftype vettore-u32 () '(simple-array (unsigned-byte 32) (*)))
;;; REQ: REQ-SEC-007
(defconstant +nessuno+ #xffffffff)
(defconstant +stack-capacity+ 64)
