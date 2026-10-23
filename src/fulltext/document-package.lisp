;;;; Preparazione documentale prima di SEAL/PREPARE; nessun I/O o pubblicazione.
;;; REQ: REQ-SEC-003 REQ-SEC-006 REQ-SEC-007 REQ-SEC-010
(defpackage #:arcdocdb.fulltext.document
  (:use #:cl)
  (:local-nicknames (#:a #:arcdocdb.fulltext.analysis) (#:r #:arcdocdb.fulltext.index)
                    (#:c #:arcdocdb.fulltext.codec) (#:cb #:arcdocdb.cbor)
                    (#:f #:arcdocdb.fulltext.format))
  (:import-from #:arcdocdb.binary #:octets #:index #:u16 #:u32 #:u64 #:scrivi-u64)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument #:resource-exhausted
                #:unsupported-format #:invariant-violation)
  (:export #:configurazione-full-text #:crea-configurazione-full-text
           #:preparazione-full-text #:crea-preparazione-full-text
           #:inizia-preparazione-full-text #:passo-preparazione-full-text
           #:annulla-preparazione-full-text #:stato-preparazione-full-text
           #:risultati-preparazione-full-text #:limite-fisso-indice-full-text))
(in-package #:arcdocdb.fulltext.document)
(declaim (optimize (safety 3) (debug 2)))

;;; REQ: REQ-SEC-003 REQ-SEC-010
(defstruct (campo-full-text (:constructor %campo-full-text (id alias path)) (:copier nil))
  "Configurazione fredda copiata e immutabile: ID positivo, alias e percorso UTF-8."
  (id 1 :type u16 :read-only t)
  (alias (make-array 0 :element-type '(unsigned-byte 8)) :type octets :read-only t)
  (path #() :type simple-vector :read-only t))

;;; REQ: REQ-SEC-003 REQ-SEC-007 REQ-SEC-010
(defstruct (configurazione-full-text
             (:constructor %configurazione-full-text (identity fields declared effective meta-bound)) (:copier nil))
  "Dichiarazione posseduta, immutabile; ID codificati una volta, limiti caldi fixnum.
Non alloca ID del catalogo, non adotta contratti e non autorizza commit o readiness."
  (identity (make-array 24 :element-type '(unsigned-byte 8)) :type (simple-array (unsigned-byte 8) (24)) :read-only t)
  (fields #() :type simple-vector :read-only t)
  (declared (make-array 5 :element-type 'u64) :type (simple-array (unsigned-byte 64) (5)) :read-only t)
  (effective (make-array 5 :element-type 'fixnum) :type (simple-array fixnum (5)) :read-only t)
  (meta-bound 0 :type index :read-only t))
