;;;; Bootstrap runtime da piani Archivio reali, con oracoli bytewise ACR.
;;; OWNER: runner seriale; fixture ACR possiede le sole fonti readonly e i relativi FD.
;;; SHARED: nessuna FI globale o costruzione privata di piani; nessun worker avviato.
;;; REQ: REQ-REC-001 REQ-MVC-005 REQ-MVC-006 REQ-MVC-007 REQ-AFF-008
(defpackage #:arcdocdb.runtime.tests
  (:use #:cl)
  (:local-nicknames (#:r #:arcdocdb.runtime) (#:a #:arcdocdb.recovery.archive.csn.tests)
                   (#:ac #:arcdocdb.recovery.archive.csn) (#:g #:arcdocdb.get)
                   (#:csn #:arcdocdb.csn) (#:mvcc #:arcdocdb.mvcc)
                   (#:ebr #:arcdocdb.epochs) (#:io #:arcdocdb.io)
                   (#:p #:arcdocdb.index.primary) (#:ct #:arcdocdb.control.tests)
                   (#:cd #:arcdocdb.recovery.closed.tests))
  (:import-from #:arcdocdb.foundation.tests #:is #:signals)
  (:import-from #:arcdocdb.conditions #:invalid-argument #:resource-exhausted
                #:invariant-violation #:error-reason)
  (:export #:run))
(in-package #:arcdocdb.runtime.tests)
(declaim (optimize (safety 3) (speed 2) (debug 2)))

(defvar *tests* nil)
(defmacro deftest (name &body body)
  `(progn (defun ,name () ,@body) (pushnew ',name *tests*)))
(defun run ()
  (dolist (test (reverse *tests*)) (funcall test) (format t "ok    ~A~%" test))
  (format t "~D test bootstrap runtime superati.~%" (length *tests*)) t)

;;; REQ: REQ-AFF-008
(declaim (notinline rbt-invoke))
(defun rbt-invoke (name &rest arguments)
  "Confine dinamico per tipi volutamente errati, senza avvisi statici del compilatore."
  (apply (symbol-function name) arguments))

;;; REQ: REQ-MVC-005 REQ-MVC-006 REQ-AFF-008
(declaim (notinline rbt-create))
(defun rbt-create (plan &rest options)
  "Capacita ridotte per le matrici; opzioni esplicite per i casi limite."
  (apply #'r:crea-runtime-archivio plan 20 5
         (append options '(:csn-capacity 2 :snapshot-capacity 2
                           :worker-capacity 2 :retirement-capacity 2))))

;;; REQ: REQ-REC-001 REQ-MVC-006
(defun rbt-plan (f)
  "Piano pubblico reale; ACR verifica gia EOF, P (secondo valore), stato e formato."
  (let ((plan (a::acr-plan f))) (a::acr-noeffects f) plan))

;;; REQ: REQ-MVC-005 REQ-MVC-006 REQ-MVC-007 REQ-CMP-007
(defun rbt-check (f runtime maximum)
  "Identita dei getter e frontiere da API pubbliche, senza mutare metadati."
  (let* ((archive (a::acr-fixture-archive f)) (scope (r:ambito-runtime-archivio runtime))
         (snapshots (r:snapshot-runtime-archivio runtime))
         (epochs (r:epoche-runtime-archivio runtime)) (csns (r:csn-runtime-archivio runtime))
         (words (list (ldb (byte 32 32) maximum) (ldb (byte 32 0) maximum))))
    (is (typep runtime 'r:runtime-archivio))
    (is (eq runtime (r:trova-runtime-archivio archive)))
    (is (eq scope (r:ambito-runtime-archivio runtime)))
    (is (eq snapshots (r:snapshot-runtime-archivio runtime)))
    (is (eq epochs (r:epoche-runtime-archivio runtime)))
    (is (eq csns (r:csn-runtime-archivio runtime)))
    (is (typep scope 'g:ambito-get)) (is (typep csns 'csn:registro-csn))
    (is (typep snapshots 'mvcc:registro-snapshot)) (is (typep epochs 'ebr:registro-epoche))
    ;; Accessori privati in sola lettura: controllano i legami, non producono l'oracolo CSN.
    (is (eq epochs (g::ambito-get-epochs scope)))
    (is (eq snapshots (g::ambito-get-snapshots scope)))
    (is (eq csns (mvcc::registro-snapshot-csns snapshots)))
    (is (not (eq scope (a::acr-fixture-scope f))))
    (is (equal (append words words) (multiple-value-list (csn:leggi-frontiere-csn csns))))
    (is (equal '(0 #xffffffffffffffff 0)
               (multiple-value-list (mvcc:leggi-registro-snapshot snapshots))))
    (is (equal '(1 1 0 0) (multiple-value-list (ebr:leggi-registro-epoche epochs))))
    (a::acr-noeffects f) runtime))

;;; REQ: REQ-MVC-006 REQ-MVC-008
(defun rbt-first (runtime maximum)
  "Prima assegnazione M+1; H resta M finche il token effettivo non viene risolto."
  (let* ((registry (r:csn-runtime-archivio runtime)) (next (1+ maximum))
         (high (ldb (byte 32 32) next)) (low (ldb (byte 32 0) next)))
    (multiple-value-bind (slot actual-high actual-low) (csn:prendi-csn registry)
      (is (= high actual-high)) (is (= low actual-low))
      (is (equal (list high low (ldb (byte 32 32) maximum) (ldb (byte 32 0) maximum))
                 (multiple-value-list (csn:leggi-frontiere-csn registry))))
      (is (equal (list high low)
                 (multiple-value-list (csn:risolvi-csn registry slot actual-high actual-low)))))
    (is (equal (list high low high low) (multiple-value-list (csn:leggi-frontiere-csn registry))))))

;;; REQ: REQ-REC-001 REQ-MVC-006
(defun rbt-series (maximum)
  (let ((record (cd::cdr-record :put maximum :value #(246))))
    (list (a::acr-serie 1 :active (list (cd::cdr-batch maximum record))))))

;;; REQ: REQ-AFF-008 REQ-MVC-005
(defun rbt-reject (f thunk &optional (reason :archive-runtime-configuration))
  (a::acr-expect 'invalid-argument reason thunk nil)
  (is (null (r:trova-runtime-archivio (a::acr-fixture-archive f))))
  (a::acr-noeffects f))

;;; REQ: REQ-MVC-005 REQ-IDX-001 REQ-FOR-004
(defstruct (rbt-get (:constructor %rbt-get)) view context segment prefix key value)

;;; REQ: REQ-IDX-001 REQ-MVC-001
(defun rbt-publish (view key value csn)
  "Unico PUT a offset 64 nel segmento ACTIVE9, definito dall'oracolo bytewise ACR."
  (let* ((primary (g::vista-get-serie-primary view))
         (payload (make-array 5 :element-type '(unsigned-byte 64)
                    :initial-contents (list csn (logior (ash 9 32) 64)
                                            (logior (ash (length key) 32) (ash 1 48))
                                            (+ 24 (length key) (length value)) 0))))
    (multiple-value-bind (high low) (p:digest-chiave-indice primary key 0 (length key))
      (p:pubblica-chiave-indice primary (p:frammento-corrente-indice primary high)
                               key 0 (length key) high low payload (p:crea-contesto-indice)))))

;;; REQ: REQ-MVC-005 REQ-FOR-002 REQ-IDX-001 REQ-CON-004
(defun rbt-get-target (f runtime)
  "Lega la stessa Serie al nuovo ambito e pubblica il primo PUT gia recuperato."
  (let* ((bootstrap (aref (a::acr-fixture-views f) 0))
         (spec (aref (a::acr-fixture-specs f) 0))
         (record (first (getf (first (getf spec :active)) :records)))
         (key (getf record :key)) (value (getf record :value))
         (scope (r:ambito-runtime-archivio runtime))
         (view (g:crea-vista-get-serie scope (g::vista-get-serie-primary bootstrap) nil
                                     (a::acr-identity (getf spec :number))))
         (input (aref (a::acr-fixture-active-inputs f) 0))
         (prefix (nth-value 1 (arcdocdb.recovery.active:frontiere-active-recuperato
                               (aref (a::acr-fixture-active f) 0))))
         (segment (g:crea-segmento-get view input 9 (ct::crr-bytes 64))))
    (is (= prefix (aref (a::acr-fixture-active-prefixes f) 0)))
    ;; La lettura dell'header appartiene alla costruzione della capacita, non al bootstrap.
    (is (equal (list (list :read (io::file-fd input) 0 64 0)) (a::acr-events f)))
    (a::acr-clear f) (a::acr-noeffects f)
    (rbt-publish view key value (getf record :stamp))
    (%rbt-get :view view :context (g:crea-contesto-get scope 0 :record-bytes 128 :budget-payload 280)
              :segment segment :prefix prefix :key key :value value)))

;;; REQ: REQ-MVC-004 REQ-FOR-004 REQ-CMP-007 REQ-AFF-002
(defun rbt-get-read (f runtime target snapshot generation &key (now 12))
  "Lettura e copia effettive: byte noti, doppia verifica snapshot e pin EBR fino alla consegna."
  (let* ((context (rbt-get-context target)) (value (rbt-get-value target))
         (output (ct::crr-bytes (length value) #xee))
         (epoch (ebr:contesto-epoca (r:epoche-runtime-archivio runtime) 0)))
    (a::acr-noeffects f)
    (unwind-protect
         (progn
           (is (eq :candidate (g:avvia-get context (rbt-get-view target) (rbt-get-key target)
                                          snapshot generation now)))
           (is (ebr:epoca-attiva-p epoch))
           (is (equal '(:segment :disabled :not-attempted nil nil)
                      (multiple-value-list (g:leggi-record-get context (rbt-get-segment target)
                                                              (rbt-get-prefix target) 0))))
           (let ((events (a::acr-events f)))
             (is (= 1 (length events)))
             (is (eq :read (first (first events))))
             (is (= (+ 24 (length (rbt-get-key target)) (length value)) (fourth (first events))))
             (is (= 64 (fifth (first events)))))
           (a::acr-clear f)
           (is (= (length output) (g:copia-valore-get context output 0)))
           (is (equalp value output)) (is (ebr:epoca-attiva-p epoch))
           (is (equal (list :found (length value))
                      (multiple-value-list (g:concludi-get context (1+ now)))))
           (is (eq :idle (g:stato-contesto-get context)))
           (is (not (ebr:epoca-attiva-p epoch)))
           (a::acr-noeffects f))
      (g:abbandona-get context))))
