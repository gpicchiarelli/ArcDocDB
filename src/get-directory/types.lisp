;;; OWNER: controller conserva directory e FD fino al reclaim EBR autorizzato.
;;; SHARED: gli array copiati sono privati e immutabili dopo la costruzione.
(in-package #:arcdocdb.get.directory)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(defconstant +directory-max-segments+ 65536)
(defconstant +directory-search-attempts+ 17)
(defconstant +directory-entry-bytes+ 12) ; u32 + riferimento su SBCL a 64 bit.
(deftype directory-ids () '(simple-array (unsigned-byte 32) (*)))

;;; REQ: REQ-IDX-001 REQ-CMP-007 REQ-AFF-008
(defstruct (directory-get-serie
             (:constructor %make-directory-get-serie (view ids maps)) (:copier nil))
  "Pre: mappe CLOSED canoniche e ID positivi distinti ordinati, array posseduti.
Post: directory immutabile della sola vista; nessun array o accessor pubblico.
Il controller pubblica prima delle location e conserva ogni FD fino al reclaim EBR."
  (view nil :type vista-get-serie :read-only t)
  (ids #() :type directory-ids :read-only t)
  (maps #() :type simple-vector :read-only t))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(declaim (ftype (function (directory-get-serie) index) conta-segmenti-directory-get)
         (ftype (function (directory-get-serie) index) payload-directory-get-serie))
(defun conta-segmenti-directory-get (directory)
  "Pre: directory completata. Post: cardinalità della vista, inclusa zero.
Non certifica il numero delle risorse vive o la pubblicazione del primary."
  (length (directory-get-serie-ids directory)))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(defun payload-directory-get-serie (directory)
  "Pre: directory completata. Post: payload dei due array, dodici byte per segmento su SBCL64.
Esclude header/oggetti Lisp, mappe, FD e radici trattenute; non misura RSS o picco globale."
  (* +directory-entry-bytes+ (conta-segmenti-directory-get directory)))
