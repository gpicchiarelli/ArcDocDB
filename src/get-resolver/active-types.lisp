;;; OWNER: writer con lease costruisce; ogni radice e pagina completata è immutabile.
;;; SHARED: radice locale della Serie via CAS esistente; GET non modifica il grafo.
(in-package #:arcdocdb.get.resolver)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-IDX-001 REQ-AFF-008
(defconstant +active-directory-width+ 16)
(defconstant +active-directory-levels+ 4)
(defconstant +active-directory-shift+ 12)
(defconstant +active-max-pages+ 65536)
(defconstant +active-page-attempts+ 17)
(defconstant +active-node-payload+ 128) ; sedici riferimenti, runtime SBCL a 64 bit.
(defconstant +active-row-payload+ (* 4 +row-words+))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-AFF-008
(defstruct (sorgente-get-attiva
             (:constructor %make-sorgente-get-attiva
                 (controller segment max-pages max-puts batch-records batch-bytes budget)) (:copier nil))
  "Pre: controller e FD readonly del medesimo nuovo ACTIVE, associazione fisica del caller.
Post: capacità/configurazione possedute e immutabili, nessuna frontiera inventata.
Creazione prima dei compiti; il FD vive fino al reclaim EBR dell'ultima radice."
  (controller nil :type controllore-serie :read-only t)
  (segment nil :type segmento-get :read-only t)
  (max-pages 1 :type (integer 1 65536) :read-only t)
  (max-puts 1 :type u32 :read-only t)
  (batch-records 1 :type u32 :read-only t)
  (batch-bytes 56 :type u32 :read-only t)
  (budget 0 :type index :read-only t))

;;; REQ: REQ-IDX-001 REQ-WAL-006 REQ-AFF-008
(defstruct (radice-get-attiva
             (:constructor %make-radice-get-attiva (source directory count puts nodes end content)) (:copier nil))
  "Pre: delta verificato o avvio vuoto a offset 64; directory persistente privata.
Post: niente riferimenti al lotto/evento riusabili o alla radice precedente.
Il CAS iniziale pubblica il solo header; i CAS successivi richiedono copertura WAL."
  (source nil :type sorgente-get-attiva :read-only t)
  (directory nil :type (or null simple-vector) :read-only t)
  (count 0 :type (integer 0 65536) :read-only t)
  (puts 0 :type u32 :read-only t)
  (nodes 0 :type index :read-only t)
  (end 64 :type u32 :read-only t)
  (content nil :type t :read-only t))

;;; REQ: REQ-WAL-006 REQ-IDX-001
(declaim (ftype (function (radice-get-attiva) t) contenuto-radice-get-attiva)
         (ftype (function (radice-get-attiva) index) payload-radice-get-attiva))
(defun contenuto-radice-get-attiva (root)
  "Pre: root preparata o acquisita sotto EBR. Post: payload immutabile del caller.
Non attesta pubblicazione, coerenza dell'indice concreto o lifetime delle risorse esterne."
  (radice-get-attiva-content root))

;;; REQ: REQ-AFF-008 REQ-IDX-001
(defun payload-radice-get-attiva (root)
  "Pre: root completa. Post: 24 byte/PUT più 128 byte/nodo nella vista, su SBCL 64 bit.
Esclude header/oggetti Lisp, radici ritirate, FD, lotto e payload del caller; non misura RSS."
  (+ (* +active-row-payload+ (radice-get-attiva-puts root))
     (* +active-node-payload+ (radice-get-attiva-nodes root))))
