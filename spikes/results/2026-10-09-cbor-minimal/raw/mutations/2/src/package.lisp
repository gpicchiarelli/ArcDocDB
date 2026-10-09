;;;; package.lisp — package radice di ArcDocDB.

(defpackage #:arcdocdb
  (:use #:cl)
  (:export #:*version*)
  (:documentation
   "Package radice di ArcDocDB. In Fase 0 contiene solo la versione: l'architettura è
    descritta in docs/ e le decisioni in docs/adr/."))

(in-package #:arcdocdb)

(defparameter *version* "0.0.0"
  "Versione del sistema. 0.0.0 finché il progetto è in fase di definizione architetturale.")
