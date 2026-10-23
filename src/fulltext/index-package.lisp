;;;; Run invertito posizionale privato, sigillato prima della condivisione.
;;; REQ: REQ-SEC-003 REQ-SEC-004 REQ-SEC-007 REQ-SEC-010
(defpackage #:arcdocdb.fulltext.index
  (:use #:cl)
  (:local-nicknames (#:a #:arcdocdb.fulltext.analysis))
  (:import-from #:arcdocdb.binary #:index #:octets #:u16 #:u32)
  (:import-from #:arcdocdb.conditions #:arcdocdb-error #:invalid-argument
                #:resource-exhausted #:invariant-violation)
  (:export #:indice-posizionale #:crea-indice-posizionale #:inizia-campo-full-text
           #:passo-indice-posizionale #:sigilla-indice-posizionale #:corrisponde-riga-full-text))
(in-package #:arcdocdb.fulltext.index)
(deftype parole-u32 () '(simple-array (unsigned-byte 32) (*)))
(defconstant +token-width+ 5)
(defconstant +field+ 0)
(defconstant +row+ 1)
(defconstant +position+ 2)
(defconstant +offset+ 3)
(defconstant +length+ 4)
(defconstant +length-width+ 3)

;;; REQ: REQ-SEC-003 REQ-SEC-004 REQ-SEC-010
(defstruct (indice-posizionale (:constructor %crea-indice-posizionale (tokens bytes lengths)) (:copier nil))
  "Preallocato, un solo builder; dopo SEALED solo letture condivise.
Row e l'identita locale della versione, non una chiave logica o uno snapshot."
  (tokens (make-array 0 :element-type 'u32) :type parole-u32 :read-only t)
  (bytes (make-array 0 :element-type '(unsigned-byte 8)) :type octets :read-only t)
  (lengths (make-array 0 :element-type 'u32) :type parole-u32 :read-only t)
  (count 0 :type index) (byte-count 0 :type index) (field-count 0 :type index)
  (state :building :type keyword) (source nil :type (or null a:spazio-full-text))
  (pending-row 0 :type u32) (pending-field 0 :type u16)
  (source-token 0 :type index) (source-byte 0 :type index) (term-start 0 :type index)
  (heap 0 :type index) (heap-end 0 :type index)
  (work 0 :type index) (work-limit 268435456 :type index))

;;; REQ: REQ-SEC-003 REQ-SEC-010
(declaim (ftype (function (&key (:max-tokens t) (:max-bytes t) (:max-fields t) (:max-memory t))
                         indice-posizionale) crea-indice-posizionale))
(defun crea-indice-posizionale (&key (max-tokens 65536) (max-bytes 4194304)
                                   (max-fields 4096) (max-memory 67108864))
  "Pre: configurazione fredda. Post: run esclusivo con capacita fisse.
INVALID-ARGUMENT per capacita; RESOURCE-EXHAUSTED prima di allocare oltre MAX-MEMORY."
  (unless (and (typep max-tokens '(integer 1 4294967295))
               (typep max-bytes '(integer 1 4294967295)) (typep max-fields '(integer 1 4294967295))
               (typep max-memory 'index))
    (error 'invalid-argument :reason :fulltext-index-capacity))
  (when (> (+ (* 20 max-tokens) max-bytes (* 12 max-fields) 4096) max-memory)
    (error 'resource-exhausted :reason :fulltext-index-memory))
  (%crea-indice-posizionale
   (make-array (* +token-width+ max-tokens) :element-type 'u32 :initial-element 0)
   (make-array max-bytes :element-type '(unsigned-byte 8) :initial-element 0)
   (make-array (* +length-width+ max-fields) :element-type 'u32 :initial-element 0)))

;;; REQ: REQ-SEC-010
(declaim (ftype (function (indice-posizionale &optional index) null) consuma-lavoro-indice))
(defun consuma-lavoro-indice (run &optional (units 1))
  "Pre: builder esclusivo. Post: lavoro incrementato entro limite, altrimenti errore."
  (when (> units (- (indice-posizionale-work-limit run) (indice-posizionale-work run)))
    (error 'resource-exhausted :reason :fulltext-index-work))
  (incf (indice-posizionale-work run) units) nil)
