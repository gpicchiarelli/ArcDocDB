;;; OWNER: controller costruisce viste e capacità; scratch posseduto dal solo worker.
;;; SHARED: legami immutabili; nessun riferimento fisico attraversa una migrazione.
(in-package #:arcdocdb.get)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

;;; REQ: REQ-AFF-008 REQ-FOR-004
(defconstant +get-proof-bytes+ (+ +header-bytes+ +outcome-bytes+))
(defconstant +get-fixed-payload+ (+ (* (+ 5 1 5 4) 8) +get-proof-bytes+))
(deftype get-content () '(simple-array (unsigned-byte 64) (5)))
(deftype get-state () '(member :idle :starting :candidate :loading :verified :copied
                              :absent :history-required :retry :finishing :faulted))

;;; REQ: REQ-CMP-007 REQ-MVC-005 REQ-CON-004 REQ-AFF-008
(defstruct (ambito-get (:constructor crea-ambito-get (epochs snapshots)) (:copier nil))
  "Pre: controller associa una sola volta EBR e registro snapshot dello stesso Archivio.
Post: identità canonica immutabile condivisa dalle viste e dai worker dell'Archivio.
TYPE-ERROR per tipi invalidi; la correttezza dell'associazione iniziale è del controller."
  (epochs nil :type registro-epoche :read-only t)
  (snapshots nil :type registro-snapshot :read-only t))
(declaim (ftype (function (registro-epoche registro-snapshot) ambito-get) crea-ambito-get))

;;; REQ: REQ-IDX-001 REQ-CCH-002 REQ-FOR-001 REQ-CMP-007
(defstruct (vista-get-serie (:constructor %make-vista-get-serie (scope primary cache identity)) (:copier nil))
  "Pre: controller associa indice, cache e identità della stessa Serie.
Post: legami immutabili, identità copiata; nessun accessor di array esportato.
Non certifica la pubblicazione dei commit o la salute del controller."
  (scope nil :type ambito-get :read-only t)
  (primary nil :type indice-primario :read-only t)
  (cache nil :type (or null cache-serie) :read-only t)
  (identity #() :type (simple-array (unsigned-byte 8) (#.+serie-id-bytes+)) :read-only t))

;;; REQ: REQ-FOR-001 REQ-FOR-002 REQ-AFF-002 REQ-CMP-007
(defstruct (segmento-get (:constructor %make-segmento-get
                         (owner file high low version origin)) (:copier nil))
  "Pre: header letto da FILE e verificato contro identità autorevole della Serie/segmento.
Post: capacità readonly immutabile; file mantenuto aperto dal controller fino al reclaim EBR.
Non certifica il prefisso committed: la frontiera autorevole è richiesta a ogni accesso."
  (owner nil :type vista-get-serie :read-only t)
  (file nil :type file-io :read-only t)
  (high 0 :type u32 :read-only t)
  (low 0 :type u32 :read-only t)
  (version 2 :type (member 1 2) :read-only t)
  (origin 1 :type (member 1 2) :read-only t))

;;; REQ: REQ-CON-004 REQ-CCH-002 REQ-MVC-004 REQ-AFF-008
(defstruct (contesto-get (:constructor %make-contesto-get (scope reader probe content limit bytes proof))
                        (:copier nil))
  "Pre: registri dello stesso Archivio, scratch allocato prima dell'avvio del worker.
Post: IDLE, senza richiesta o location. Solo il worker modifica i campi e i buffer.
FAULTED terminale; buffer non esportati, nessuna continuazione o risorsa conservata in coda."
  (scope nil :type ambito-get :read-only t)
  (reader nil :type contesto-lettura :read-only t)
  (probe nil :type contesto-indice :read-only t)
  (content #() :type get-content :read-only t)
  (limit #() :type (simple-array (unsigned-byte 64) (1)) :read-only t)
  (bytes #() :type octets :read-only t)
  (proof #() :type (simple-array (unsigned-byte 8) (#.+get-proof-bytes+)) :read-only t)
  (view nil :type (or null vista-get-serie))
  (key nil :type (or null octets))
  (snapshot-p nil :type boolean)
  (value-start 0 :type index)
  (value-end 0 :type index)
  (state :idle :type get-state))

;;; REQ: REQ-CON-004 REQ-AFF-008
(declaim (ftype (function (contesto-get) index) payload-contesto-get))
(defun payload-contesto-get (context)
  "Pre: contesto costruito. Post: payload dei buffer propri e di scratch indice/read.
Esclude header/oggetti Lisp, EBR, registro snapshot, vista, cache, output e GC; non è RSS."
  (+ (length (contesto-get-bytes context)) +get-fixed-payload+))

;;; REQ: REQ-CON-004 REQ-AFF-004
(declaim (ftype (function (contesto-get) get-state) stato-contesto-get))
(defun stato-contesto-get (context)
  "Pre: worker proprietario o controller dopo join. Post: stato locale osservato senza attesa.
Non è un'autorizzazione concorrente a prendere o riusare il worker."
  (contesto-get-state context))
