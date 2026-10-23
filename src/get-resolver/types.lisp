;;; OWNER: pool I/O costruisce; controller pubblica e conserva fino al reclaim EBR.
;;; SHARED: array privati immutabili dopo il ritorno; nessun accessor pubblico.
(in-package #:arcdocdb.get.resolver)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-AFF-008
(defconstant +row-words+ 6)
(defconstant +row-offset+ 0)
(defconstant +row-size+ 1)
(defconstant +row-flags+ 2)
(defconstant +row-csn-low+ 3)
(defconstant +row-csn-high+ 4)
(defconstant +row-proof+ 5)
(defconstant +proof-words+ 5)
(defconstant +proof-txid-low+ 0)
(defconstant +proof-txid-high+ 1)
(defconstant +proof-csn-low+ 2)
(defconstant +proof-csn-high+ 3)
(defconstant +proof-offset+ 4)
(defconstant +radix-buckets+ 256)
(defconstant +binary-attempts+ 33)
(deftype resolver-words () '(simple-array (unsigned-byte 32) (*)))

;;; REQ: REQ-IDX-001 REQ-FOR-004 REQ-CMP-007 REQ-AFF-008
(defstruct (mappa-segmento-get (:constructor %make-mappa-segmento-get (segment end rows)) (:copier nil))
  "Pre: CLOSED attestato dal manifest oppure pagina di lotto ACTIVE verificato prima dell'adozione.
Post: tabella posseduta di soli PUT, ordinata per offset, immutabile e senza buffer sorgente.
Il controller pubblica prima delle location corrispondenti e protegge il FD con EBR."
  (segment nil :type segmento-get :read-only t)
  (end 0 :type u32 :read-only t)
  (rows #() :type resolver-words :read-only t))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (mappa-segmento-get) index) payload-mappa-segmento-get))
(defun payload-mappa-segmento-get (map)
  "Pre: mappa completata. Post: payload degli array permanenti, 24 byte per PUT.
Esclude oggetti/header Lisp, capacità/FD e buffer del costruttore; non misura RSS."
  (* 4 (length (mappa-segmento-get-rows map))))
